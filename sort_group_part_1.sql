-- Задание 1.

/*
 * Для каждого города выведем число покупателей, сгруппируем по возрастным категориям и отсортируем 
 * по убыванию количества покупателей в каждой категории (работаем с таблицей users).
*/

-- а) Сгруппируем по возрасту в полных годах. нас интересуют city, age и количество покупателей (count(*))
select city, count(*) as count_users, age
from sort_group_1.users
group by city, age 
order by city, count_users desc; 

-- б) Теперь разделим пользователей на возрастые категории (<= 20, 21-49, >= 50) с помощью оператора 'case'
select city,
	   count(*) as count_users,
	   case when age <= 20 then 'young'
	   		when (age > 20 and age < 50) then 'adult'
	   		when age >= 50 then 'old'
	   end as age_category
from sort_group_1.users
group by city, age_category 
order by city, count_users desc; 

-- Задание 2.

/*
 * Рассчитаем среднюю цену категорий товаров в таблице products, в названиях товаров которых присутствуют слова «hair» или «home». 
 * Среднюю цену округлим до двух знаков после запятой.
*/

/*
 * Чтобы проверить наличие подстроки в столбце ("hair" и "home" в 'name', в нашем случае), удобнее всего будет использовать оператор 'ilike',
 * который нечувствителен к регистру (если же нужно учитывать товары, в наименовании которых присутствуют слова "hair" и "home" исключительно 
 * в нижнем регистре, следует использовать оператор 'like')
 */

select round(avg(price), 2) as avg_price,
	   category
from sort_group_1.products 
where name ilike '%hair%' or name ilike '%home%'
group by category;

/*
 * Таких категорий две: 'Home' и 'Beauty'. средняя цена товаров, подходящих под наше условие - 101 и 124 (допустим, что долларов). в каждой из 
 * категорий таких товаров по 3. цена товара округляется до целого числа, поскольку:
 */

select round(avg(price), 3) as avg_price,
	   category
from sort_group_1.products 
where name ilike '%hair%' or name ilike '%home%'
group by category;

/*
 * третий знак после запятой равен 7 (результат при округлении до 3-х знаков - 101,997 и 123,997 долларов). если необходимо оставлять даже нули 
 * после запятой, то можно использовать функцию 'to_char', которая предназначена для форматирования чисел в postgresql. правда в таком случае
 * числовой формат преобразуется в текстовый:
*/

select to_char(round(avg(price), 2), 'fm999.00') as avg_price,  -- fm заполняет пробелы в начале
	   category
from sort_group_1.products 
where name ilike '%hair%' or name ilike '%home%'
group by category;

