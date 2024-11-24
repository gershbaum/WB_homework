-- Задание 1.

/*
 * Найдем клиента с самым долгим временем ожидания между заказом и доставкой. Будем работать с таблицами 'customers_new' и orders_new'.
 */

-- На пороге проверим, есть ли в наших таблцах пропущенные значения
select * from join_1.customers_new 
where customer_id is null 
	  or name is null;
	  
select * from join_1.orders_new  
where order_id is null 
	  or customer_id is null
	  or order_id is null
	  or shipment_date is null
	  or order_ammount is null
	  or order_status is null;
	  
-- Посмотрим на варианты статуса заказа
select distinct order_status from join_1.orders_new;

/*
 * Проанализируем данные, с которыми нам предстоит работать. 
 * 
 * Таблица 'customers_new' содержит следующую информацию:
 *    - 'customer_id' - уникальный id покупателя
 *    - 'name' - имя и фамилия покупателя
 * 
 * В таблице 'orders_new':
 *    - 'order_id' - уникальный id заказа
 *    - 'customer_id'
 *    - 'order_date' - дата и время покупки
 *    - 'shipment_date' - дата доставки заказа
 *    - 'order_ammount' - сумма заказа
 *    - 'order_status' - статус заказа
 * 
 * Во избежание путаниц, обусловимся: поскольку пропущенных значений нет ни в столбце 'shipment_date', ни в 'order_status', 
 * а также нигде не присутствуют такие слова, как "ожидаемая", "планируемая" и т.д., то данные в столбце 'shipment_date' мы принимаем 
 * за дату фактической доставки. И статус заказа ('Approved', 'Cancel') тоже будем понимать фактически - товар был доставлен до покупателя,
 * и уже "на месте" он определяет, забирает он его или нет.
 */

-- Определим максимальный срок ожидания заказа
select c.customer_id,   --
	   (o.shipment_date - o.order_date) as max_waiting_time
from join_1.customers_new c
join join_1.orders_new o on c.customer_id = o.customer_id   -- джойним наши таблицы по 'customer_id'
where (o.shipment_date - o.order_date) = (
	   select max(ord.shipment_date - ord.order_date)
	   from join_1.orders_new ord
	  )   -- используем подзапрос для определения покупателей, которые ждали свой заказ дольше остальных
order by c.customer_id;

/*
 * Такая ситуация не единична! Оптимизируем запрос для вывода результирующей таблицы. Также подсчитаем количество подобных случаев 
 * и количество таких покупателей.
 */

with max_time_calc as (
	 select max(shipment_date - order_date) as max_waiting_time_from_calc
	 from join_1.orders_new
),   -- подсчитываем максимальый срок ожидания товара
customers_with_max_wait as (
	 select c.customer_id,
	  		c.name,
	 		o.order_date,
	  		o.shipment_date,
	  		(o.shipment_date - o.order_date) as max_waiting_time
	 from join_1.customers_new c
	 join join_1.orders_new o on c.customer_id = o.customer_id 
	 -- условие на то, что срок ожидания соответствует рассчитаному максимальному (используем подзапрос):
	 where (o.shipment_date - o.order_date) = (select max_waiting_time_from_calc from max_time_calc)   
)   -- выбираем всех клиетов с максимальным сроком ожидания товара
select *,
	   (select count(distinct customer_id) from customers_with_max_wait) as total_customers_with_max_wait,   -- кол-во таких покупателей
	   (select count(*) from customers_with_max_wait) as total_cases   -- кол-во подобых случаев
from customers_with_max_wait
order by customer_id;

/*
 * Максимальное время ожидания заказа - 10 дней (результат отображается только с точностью до дней, поскольку для каждой строчки час, минуты и
 * секунды одинаковы относительно столбцов 'order_date' и 'shipment_date'. Покупателей с таким ожиданием заказа - 27, а количество подобных случаев - 31.
 */

-- Задание 2.

/*
 * Найдем клиентов с наибольшим количеством заказов. Для каждого из них расчитаем среднее время ожидания заказа, а также общую сумму всех заказов.
 */

with orders_calc as (
	 select o.customer_id,
	        c.name,
	        count(*) as total_orders
	 from join_1.orders_new o
	 join join_1.customers_new c on o.customer_id = c.customer_id 
	 group by o.customer_id, c.name
),   -- подсчитываем количество заказов для каждого клиента
max_total_orders_calc as (
	 select max(total_orders) as max_total_orders
	 from orders_calc
)   -- находим макс. количество заказов, чтобы выбрать покупателей с данным показателем и не выполнять агрегации для всех клиентов
select oc.customer_id,  
	   oc.name,
	   oc.total_orders,
	   avg(o.shipment_date - o.order_date),   -- если, например, данное поле необходимо для расчетов (в перспективе), покажем среднее время ожидания в станд. виде
	   -- применим extract(epoch from ...), найдем среднее время ожидания в секудах
	   avg(extract(epoch from (o.shipment_date - o.order_date)) / 3600.0) as avg_waiting_time_in_hours,   -- результат выведем в часах
	   -- и добавим отформатированный столбец. наглядно покажем среднее время ожидания в формате "_ дней _ часов _ минут"
	   TO_CHAR(avg(age(o.shipment_date, o.order_date)), 'DD "days" HH24 "hours" MI "minutes') as avg_waiting_time_formatted,
	   sum(order_ammount) as all_orders_sum   -- общая сумма заказов
from orders_calc oc
join join_1.orders_new o on oc.customer_id = o.customer_id
where oc.total_orders = (select max_total_orders from max_total_orders_calc)   -- работаем только с клиентами, у которых кол-во заказов соответствует максимальному
group by oc.customer_id, oc.name, oc.total_orders
order by all_orders_sum;

-- Наибольшее количество заказов - 5. Столько раз товары приобретали только 2 клиента.

-- Задание 3.

/*
 * Найдем клиентов у которых были заказы, доставленные с задержкой более чем на 5 дней (под этим будем понимать длительность доставки, превышающую срок в 5 дней),
 * и клиентов, у которых есть отмененные заказы.
 * 
 * Логика представленного ниже решения: 
 * 
 * Нам нужно отобрать две группы покупателей:
 *    1. Клиенты, у которых заказ доставлялся более 5 дней
 *    2. Клиенты, у которых есть отмененные заказы
 * 
 * Для подсчета количества клиентов каждой из групп воспользуемся оператором count в связке с case, поскольку у нас есть условия (длительность доставки, статус заказа).
 * Общую сумму заказов, которые были отменены, считаем по такому же принципу. 
 * 
 * В результирующей таблице указываем тех покупателей, которые либо ждали заказ более 5 дней, либо отменили свой заказ. 
 * Условие можно воспринять неоднозачно. Если же необходимо найти клиентов, которые столкулись и с длительной доставкой, и отменяли заказ (то есть исключить случаи, 
 * когда клиент столкнулся с длительной (в нашем случае > 5 дней) доставкой и не отменял заказы и наоборот), то в having'е следует изменить 'or' на 'and'.
 */

select c.name,
	   count(case when (o.shipment_date - o.order_date) > interval '5 days' then 1 end) as count_delayed_shipment,   -- кол-во длительных доставок
	   count(case when o.order_status = 'Cancel' then 1 end) as count_cancelled_order,   -- кол-во отмененных заказов
	   sum(case when o.order_status = 'Cancel' then o.order_ammount else 0 end) as total_amount_cancel   -- общая сумма отмененных заказов
from join_1.orders_new o
join join_1.customers_new c on o.customer_id = c.customer_id
group by c.name
having count(case when (o.shipment_date - o.order_date) > interval '5 days' then 1 end) > 0   -- либо длительная доставка
	   or count(case when o.order_status = 'Cancel' then 1 end) > 0   -- либо отменял заказ хотя бы раз
order by total_amount_cancel desc;




