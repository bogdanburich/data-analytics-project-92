-- Первый отчет в виде таблицы из трех колонок - данных о продавце, суммарной выручке с проданных товаров и количестве проведенных сделок.
select e.first_name || ' ' || e.last_name as name,
	   sum(s.quantity * p.price) as income,
	   count(s.sales_id) as operations
from employees e
left join sales s on e.employee_id = s.sales_person_id
left join products p on p.product_id = s.product_id
group by 1
having count(s.sales_id) > 0
order by 2 desc
limit 10

-- Проверяем, что сумма продаж по всем продавцам совпадает с общей суммой продаж
select sum(s.quantity * p.price)
from sales s
left join products p on s.product_id = p.product_id
> 26716587615.7600


-- Второй отчет содержит информацию о продавцах, чьи продажи меньше среднего уровня продаж по всем продавцам. Таблица отсортирована по продажам по убыванию.

-- считаем средний чек по всем продавцамs
with avg_income as (
select sum(p.price * s.quantity) / count (sales_id) as avg_income
from sales s
left join products p on s.product_id = p.product_id
)
select *
from avg_income
> 267165.876157600000

with avg_income as (
select sum(p.price * s.quantity) / count (sales_id) as avg_income
from sales s
left join products p on s.product_id = p.product_id
)
select s.sales_person_id as id,
	   e.first_name || ' ' || e.last_name as name,
	   floor(sum(s.quantity * p.price) / count(sales_id)) as average_income
from employees e
left join sales s on e.employee_id = s.sales_person_id
left join products p on p.product_id = s.product_id
left join avg_income ai on true
group by 1, 2, avg_income
having (sum(s.quantity * p.price) / count(sales_id)) < ai.avg_income
order by 3

-- Третий отчет содержит информацию о продажах по дням недели. Каждая запись одержит ФИО продавца, день недели и среднюю сумму продаж.

select e.first_name || ' ' || e.last_name as seller,
       to_char(s.sale_date, 'day') as weekday,
       sum(s.quantity * p.price)::integer as income
from employees e
join sales s on e.employee_id = s.sales_person_id
left join products p on p.product_id = s.product_id
group by 1, 2, extract(isodow from s.sale_date) 
order by extract(isodow from s.sale_date)


-- Анализ покупателей

-- Первый отчет - количество покупателей в разных возрастных группах: 10-15, 16-25, 26-40 и 40+.

select
	   case when c.age <= 15 then '10-15'
			when c.age between 16 and 25 then '16-25'
			when c.age between 26 and 40 then '26-40'
			else '40+'
		end as age_category,
		count(*) as count
from customers c
group by 1
order by 1

-- Во втором отчете предоставьте данные по количеству покупателей и выручке, которую они принесли. Сгруппируйте данные по месяцам. 

select to_char(s.sale_date, 'Month') as month,
	   count(distinct s.customer_id) as total_customers,
	   sum(p.price * s.quantity) as income
from sales s
join products p on s.product_id = p.product_id
group by 1, extract(month from s.sale_date) 
order by extract(month from s.sale_date)

-- Третий отчет следует составить о покупателях, первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0).

-- здесь можно было бы использовать оконную функцию, но distinct on лаконичнее на мой взгляд
with first_puchases as (
	select 
	distinct on (customer_id) customer_id,
	sales_id,
	sale_date,
	sales_person_id,
	product_id
	from sales s
	order by customer_id, sale_date 
)
select c.first_name || ' ' || c.last_name as customer,
	   fp.sale_date as sale_date,
	   e.first_name || ' ' || e.last_name as seller
from first_puchases fp
left join employees e on e.employee_id = fp.sales_person_id
left join customers c on c.customer_id = fp.customer_id
left join products p on p.product_id = fp.product_id
where p.price = 0
order by fp.customer_id, sale_date
