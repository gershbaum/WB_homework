/*
 * Будем работать с двумя таблицами.
 * 
 * 'orders' содержит следующие поля:
 *    - order_id (идентификатор заказа)
 *    - order_date (дата заказа)
 *    - product_id (идентификатор продукта)
 *    - order_ammount (сумма заказа)
 * 
 * 'products' содержит следующие поля:
 *    - product_id (идентификатор продукта)
 *    - product_name (наименование продукта)
 *    - product_category (категория продукта)
 */
 
/*
 * Необходимо написать SQL-запрос, который выполнит следующие задачи:
 * 
 * 1. Вычислит общую сумму продаж для каждой категории продуктов.
 * 2. Определит категорию продукта с наибольшей общей суммой продаж.
 * 3. Для каждой категории продуктов, определит продукт с максимальной суммой продаж в этой категории.
 * 
 * Как требует условие, в данной задаче будем использовать подзапросы.
 */
 
select p1.product_category,
	   sum(o1.order_ammount) as total_amount_by_category,   -- реализация 1-го пункта, вычисляем сумму продаж по категориям
	   
	   	-- реализация 3-го пункта (поменяем 2-й и 3-й пункт местами только лишь для более наглядного и логичного представления рез. таблицы)
	   (select p3.product_name   -- выборка по продуктам
	   from join_2.orders o3
	   join join_2.products p3 on o3.product_id = p3.product_id   -- джойним
	   where p3.product_category = p1.product_category   -- смотрим только на те продукты, которые относятся к текущей категории (из осн. запроса)
	   group by p3.product_name
	   order by sum(o3.order_ammount) desc   -- сортируем по общей сумме продаж
	   limit 1   -- и выбираем продукт с макс. суммой продаж
	   ) as top_product_in_category_by_amount,
	   
	   -- реализация 2-го пункта
	   (select p2.product_category   -- выборка по категориям продуктов
	   from join_2.orders o2
	   join join_2.products p2 on o2.product_id = p2.product_id   -- джойним
	   group by p2.product_category
	   order by sum(o2.order_ammount) desc   -- сортируем по общей сумме продаж
	   limit 1   -- и выбираем категорию с наибольшей общей суммой продаж
	   ) as top_category_by_amount
	   
from join_2.orders o1
join join_2.products p1 on o1.product_id = p1.product_id 
group by p1.product_category
order by total_amount_by_category desc;   -- отсортируем по общей сумме выручки каждой из категорий
 
-- Категория 'Напитки' самая прибыльная - суммарная выручка составила 4 707 321.

--------------------------------------------------------------------------------------------------------------------------------------------------

/*
 * Условие задачи звучит строго, но так и напрашивается дополительно вывести для самого прибыльного продукта в каждой из категорий его суммарую
 * выручку. Просто дополительно напишем еще один запрос; вместо столбца 'top_category_by_amount' (итог нам уже известен) запишем суммарую выручку
 * топ-товара по прибыли в каждой категории. Поскольку в запросе наши таблицы мы джойним 3 раза, можно воспользоваться временной таблицей и cte,
 * где мы выполним подготовителные расчеты.
 * 
 * P.S.: поскольку этот запрос импровизированный, если позволите, я воспользуюсь оконной функцией (всего разок!) в ste. Это существенно сократит 
 * весь запрос. 
 */

drop table if exists temp_join;

create temp table temp_join as   -- создаем временную таблицу "под join"
select o.*, p.product_name, p.product_category
from join_2.orders o 
join join_2.products p on o.product_id = p.product_id;

with top_product_by_category as (
	 select tj.product_category,
	 	    tj.product_name,
	 	    sum(tj.order_ammount) as total_amount_by_product,   -- вычисляем сумму продаж каждого продукта
	 	    
	 	    -- ранжируем продукты по общей сумме продаж (в порядке убывания) в категориях
	 	    rank() over (partition by tj.product_category order by sum(tj.order_ammount) desc) as rank_product_by_category
     from temp_join tj
     group by tj.product_category, tj.product_name
)
select tj.product_category,
	   sum(tj.order_ammount) as total_amount_by_category,   -- сумма продаж в каждой категории
	   
	   (select tpc.product_name   -- выборка по названию продукта
	   from top_product_by_category tpc
	   where tpc.product_category = tj.product_category   -- находим название топ-продукта в каждой категории:
	   	     and tpc.rank_product_by_category = 1   -- а) категория из основного запроса, б) продукт на 1-м месте по сумме продаж
	   ) as top_product_in_category_by_amount,  
	   	     
	   (select tpc.total_amount_by_product   -- выборка по сумме продаж продуктов
	   from top_product_by_category tpc
	   where tpc.product_category = tj.product_category   -- аналогично предыдущему подзапросу
	   	     and tpc.rank_product_by_category = 1
	   ) as total_amount_of_the_top_product
	   
from temp_join tj   -- наша временная таблица
group by tj.product_category
order by total_amount_by_category desc;   -- отсортируем по сумме продаж категорий

--------------------------------------------------------------------------------------------------------------------------------------------------

-- либо же... в первый наш запрос можно добавить один подзапрос для подсчета общей суммы продаж самого популярного продукта в категории:

select p1.product_category,
	   sum(o1.order_ammount) as total_amount_by_category,   -- реализация 1-го пункта, вычисляем сумму продаж по категориям
	   
	   -- подзапрос для поиска названия топ-продукта в каждой категории, без изменений
	   (select p2.product_name   -- выборка по продуктам
	   from join_2.orders o2
	   join join_2.products p2 on o2.product_id = p2.product_id
	   where p2.product_category = p1.product_category   
	   group by p2.product_name
	   order by sum(o2.order_ammount) desc 
	   limit 1) as top_product_in_category_by_amount,
	   
	   -- подзапрос для вычисления суммы продаж топ-продуктов
	   (select sum(o3.order_ammount)   -- выборка по сумме продаж
	   from join_2.orders o3
	   join join_2.products p3 on o3.product_id = p3.product_id
	   where p3.product_category = p1.product_category
	   group by p3.product_name
	   order by sum(o3.order_ammount) desc
	   limit 1) as total_amount_of_the_top_product
	   
from join_2.orders o1
join join_2.products p1 on o1.product_id = p1.product_id 
group by p1.product_category
order by total_amount_by_category desc;   -- отсортируем по общей сумме продаж каждой из категорий  


