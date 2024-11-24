/*
 * Будем работать с тремя таблицами.
 * 
 * Столбцы 'goods':
 *    - ID_GOOD - id товара
 *    - CATEGORY - категория товара
 *    - GOOD_NAME - название товара
 *    - PRICE - цена товара
 * 
 * Столбцы 'sales':
 *    - DATE - дата покупки
 *    - SHOPNUMBER - номер магазина
 *    - ID_GOOD - id товара
 *    - QTY - количество приобретенного товара в штуках
 * 
 * Столбцы 'shops':
 *    - SHOPNUMBER - номер магазина
 *    - CITY - город, в котором находится магазин
 *    - ADDRESS - улица и номер дома магазина
 */

-- Задание 1.

/*
 * Отберем данные по продажам за 2.01.2016. 
 * Столбцы в результирующей таблице:
 * 
 * SHOPNUMBER , CITY , ADDRESS, SUM_QTY, SUM_QTY_PRICE
 */

select distinct sa."SHOPNUMBER",   -- уберем дубли, поскольку в нашем случае повт. строки для каждого из магазинов не отличаются между собой
	   sh."CITY",
	   sh."ADDRESS",
	   sum(sa."QTY") over (partition by sh."SHOPNUMBER") as "SUM_QTY",   -- количество приобретеных товаров
	   sum(sa."QTY" * g."PRICE") over (partition by sh."SHOPNUMBER") as "SUM_QTY_PRICE"   -- сумма приобретенных товаров в рублях
from wf_2.sales sa
join wf_2.goods g on sa."ID_GOOD" = g."ID_GOOD"
join wf_2.shops sh on sa."SHOPNUMBER" = sh."SHOPNUMBER"
where sa."DATE" = '2016-01-02'
order by sa."SHOPNUMBER";

-- Задание 2

/*
 * Отберем за каждую дату долю от суммарных продаж (в рублях на дату). Учтем только товары направления ЧИСТОТА.
 * Столбцы в результирующей таблице:
 * 
 * DATE_, CITY, SUM_SALES_REL
 */

-- Посчитаем долю от суммарых продаж - отношение продаж в рублях в каждом из городов к общему объему продаж в рублях за каждый из трех дней.

select sa."DATE" as "DATE_",
	   sh."CITY",
	   -- sum(sa."QTY" * g."PRICE") = сумма продаж в каждом из городов
	   -- sum(sum(sa."QTY" * g."PRICE")) over (partition by sa."DATE") = общая сумма продаж по всем городам за конкретную дату
	   round(sum(sa."QTY" * g."PRICE") / sum(sum(sa."QTY" * g."PRICE")) over (partition by sa."DATE"), 3) as "SUM_SALES_REL"   -- округлим до 3 знаков после запятой
from wf_2.sales sa
join wf_2.goods g on sa."ID_GOOD" = g."ID_GOOD"
join wf_2.shops sh on sa."SHOPNUMBER" = sh."SHOPNUMBER"
where g."CATEGORY" = 'ЧИСТОТА'   -- учитываем продажи товаров только из категории "ЧИСТОТА"
group by sa."DATE", sh."CITY"
order by sa."DATE", sh."CITY"
	   
-- Задание 3   

/*
 * Выведем информацию о топ-3 товарах по продажам в штуках в каждом магазине в каждую дату.
 * Столбцы в результирующей таблице:
 * 
 * DATE_ , SHOPNUMBER, ID_GOOD
 */

select "DATE_", "SHOPNUMBER", "ID_GOOD"
from (select sa."DATE" as "DATE_",   -- используем подзапрос для ранжирования товаров по датам и магазинам
		     sa."SHOPNUMBER",
		     sa."ID_GOOD",
		     --sa."QTY",   -- количество проданных товаров
		     rank() over w as "rank"
	 from wf_2.sales sa
     group by sa."DATE", sa."SHOPNUMBER", sa."ID_GOOD", sa."QTY"
     window w as (partition by sa."DATE", sa."SHOPNUMBER" order by sa."QTY" desc)   -- партиция по датам и магазинам, сортируем по количеству продаж в шт. 
	 )
where "rank" <= 3   -- выводим только для топ-3 продуктов в каждом магазине
order by "DATE_", "SHOPNUMBER", "rank"   -- сортируем по дате, № магазина и рангу продукта по кол-ву продаж в шт.

-- Задание 4

/*
 * Выведем для каждого магазина и товарного направления сумму продаж в рублях за предыдущую дату. Только для магазинов Санкт-Петербурга.
 * Столбцы в результирующей таблице:
 * 
 * DATE_, SHOPNUMBER, CATEGORY, PREV_SALES
 */

select sa."DATE",
	   sa."SHOPNUMBER",
	   g."CATEGORY",
	   --sum(sa."QTY" * g."PRICE") as "CUR_SALES",
	   lag(sum(sa."QTY" * g."PRICE")) over w as "PREV_SALES"   -- пользуемся функцией lag(), которая ищет строку перед последней строкой фрейма
from wf_2.sales sa
join wf_2.goods g on sa."ID_GOOD" = g."ID_GOOD" 
join wf_2.shops sh on sa."SHOPNUMBER" = sh."SHOPNUMBER" 
where sh."CITY" = 'СПб'   -- только Питерские магазины!
group by sa."DATE", sa."SHOPNUMBER", g."CATEGORY"
window w as (partition by sa."SHOPNUMBER", g."CATEGORY" order by sa."DATE")   -- партиция по номеру магазина и направлению, сортировка по дате
order by sa."SHOPNUMBER", sa."DATE", g."CATEGORY";   -- отсортируем для наглядости: по магазинам, по дате и по категориям товаров

/*
 * В данном запросе работает следующая логика: например, сумма продаж товаров из направления ДЕКОР за 1-е число в первом магазине составляет 286 000 р. 2-го числа
 * товары из данного направления в 1-м магазине не покупались, а за 3-е число сумма продаж равна 224 000 р. Данный запрос работает так, что в столбце PREV_SALES 
 * за 1-е число для 1-го магазина будет NULL, за 2-е число данное направление отсутствует, а за 3-е число будет записано значение 286 000 р. То есть, под суммой 
 * продаж за предыдущую дату понимается сумма продаж за дату, в которую товары из соответствующего направления покупались крайний раз.
 */
