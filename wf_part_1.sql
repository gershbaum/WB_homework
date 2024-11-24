/*
 * Будем работать с таблицей 'salary':
 * 
 *    - id - id сотрудника/сотрудницы
 *    - first_name - имя сотрудника/сотрудницы
 *    - last_name - фамилия сотрудника/сотрудницы
 *    - salary - зарплата сотрудника/сотрудницы
 *    - industry - отдел, в котором работает сотрудник/сотрудница
 * 
 * Выведите список сотрудников с именами сотрудников, получающими самую высокую зарплату в отделе. 
 * Столбцы в результирующей таблице: first_name, last_name, salary, industry, name_highest_sal. 
 * Последний столбец - имя сотрудника для данного отдела с самой высокой зарплатой.
 * Выведите аналогичный список, но теперь укажите сотрудников с минимальной зарплатой.
 * В каждом случае реализуйте расчет двумя способами: 
 *    - с использованием функций min max (без оконных функций)
 *    - с использованием first/last value
 */

/*
 * Насчет формулировки задания: 
 * 
 *    - если необходимо вывести для каждого отдела только одну строку с тем человеком, который получает макс. зарплату,
 * то в основном запросе можно через where поставить условие на salary, что она равняется максимальной зарплате в конкретном
 * отделе (через подзапрос). Но поскольку мы выводим отдельный столбец с именем сотрудника, который получает макс. зарплату
 * в соответствующем отделе, этот подход кажется нелогичным. Логично тогда выводить для каждого отдела first_name, last_name 
 * и salary для сотрудника, получающего макс. зарплату
 * 
 *    - если необходимо вывести ВСЕХ сотрудников (это кажется более логичным), то условий на выборку определенных сотрудников
 * не требуется, а в столбце name_highest_sal будут указаны имена и фамилии самых высокооплачиваемых сотрудиков в каждом отделе.
 * Далее задание решается с применением этой логики.
 */

/*
 * Поскольку в задании сказано, что необходимо вывести именно две таблицы (отдельно с name_highest_sal, отдельно с name_lowest_sal),
 * создадим временную таблицу, где проведем все вычисления. А ниже приведем два запроса, для каждой задачи - свой.
 */

-- Расчет с использованием функций min/max
drop table if exists temp_sal_max_min;

create temp table temp_sal_max_min as
select s.*,

	   (select first_name || ' ' || last_name   -- объединяем строки (concat(_, ' ', _))
	   from wf_1.salary 
	   where industry = s.industry   -- отдел должен совпадать с рассматриваемым в основном запросе
	         and salary = (select max(s2.salary)
	         			  from wf_1.salary s2
	         			  where s2.industry = s.industry)   -- и зарпалата = макс. зарплата в рассматриваемом отделе
	   ) as name_highest_sal,
	   
	   (select first_name || ' ' || last_name
	   from wf_1.salary 
	   where industry = s.industry   -- фильтрация, аналогичная фильтрации выше, только зарплата должна быть мин.
	         and salary = (select min(s3.salary)
	         			  from wf_1.salary s3
	         			  where s3.industry = s.industry)
	   ) as name_lowest_sal
	   
from wf_1.salary s
order by s.industry;

-- первый запрос, выводим name_highest_sal - самые высокооплачиваемые сотрудники отделов
select first_name, last_name, salary, industry, name_highest_sal
from temp_sal_max_min
order by industry, salary desc;

-- второй запрос, выводим name_lowest_sal - самые низкооплачиваемые сотрудники отделов
select first_name, last_name, salary, industry, name_lowest_sal
from temp_sal_max_min
order by industry, salary;


 -- Теперь решим через оконные фукции, также создадим временную таблицу и напишем 2 запроса для 2-х результирующих таблиц.
 
drop table if exists temp_sal_window;

create temp table temp_sal_window as
select s.*,
	   first_value(s.first_name || ' ' || s.last_name) over w as name_highest_sal,
	   last_value(s.first_name || ' ' || s.last_name) over w as name_lowest_sal
from wf_1.salary s
window w as (
	   partition by s.industry   -- партиция по отделам
	   order by s.salary desc   -- сортировка по убыванию зарплаты
	   rows between unbounded preceding and unbounded following   -- необходимо для корректной работы last_value()
	   )
order by s.industry;

-- аналогично первому варианту решения, два запроса:
select first_name, last_name, salary, industry, name_highest_sal
from temp_sal_window
order by industry, salary desc;

select first_name, last_name, salary, industry, name_lowest_sal
from temp_sal_window
order by industry, salary;

/*
 * Оконные функции first/last_value() возвращают первую/последнюю строчку именно фрейма, а не секции. Мы сортируем зарплату по
 * убыванию, поэтому минимальное значение возвращается верно. По мере уменьшения зарплаты имя и фамилия в столбце 
 * name_lowest_sal будет меняться от сотрудника к сотруднику, "выхватывая" мин. значения зарплаты во фреймах внутри секции.
 * В связи с этим в 'w' присутствует строка:
 * 
 * rows between unbounded preceding and unbounded following
 * 
 * Это позволяет выровнить границы фрейма и секции и рассматривать весь отдел (в нашем случае) целиком.
 * Это необходимо при использовании функции last_value(), но поставленную нам задачу можно решить в обоих случаях и через 
 * first_value(), меняя порядок сортировки:
 */
	   
drop table if exists temp_sal_window;

create temp table temp_sal_window as
select s.*,
	   first_value(s.first_name || ' ' || s.last_name) over w1 as name_highest_sal,
	   first_value(s.first_name || ' ' || s.last_name) over w2 as name_lowest_sal
from wf_1.salary s
window w1 as (
	   partition by s.industry   -- партиция по отделам
	   order by s.salary desc    -- сортировка по убыванию зарплаты
	   ),
	   w2 as (
	   partition by s.industry
	   order by s.salary   -- сортируем по возрастанию и "хватаем" первое значение
	   )
order by s.industry;

select first_name, last_name, salary, industry, name_highest_sal
from temp_sal_window
order by industry, salary desc;

select first_name, last_name, salary, industry, name_lowest_sal
from temp_sal_window
order by industry, salary;



