--Modifying the tables to change datatypes---

UPDATE ecom2.dbo.product
SET price = 59.99,quantity = 36,cogs = 29.99
WHERE sku = 'jP3ft'


ALTER TABLE ecom2.dbo.product 
ALTER COLUMN price DECIMAL(18,2)
ALTER TABLE ecom2.dbo.product 
ALTER COLUMN quantity DECIMAL(18,2)
ALTER TABLE ecom2.dbo.orders
ALTER COLUMN amount_ordered DECIMAL(18,2)
ALTER TABLE ecom2.dbo.orders 
ALTER COLUMN created_at DATETIME
ALTER TABLE ecom2.dbo.ordereditems
ALTER COLUMN quantity_ordered INT

------------------------------------------------

select *
from ecom2.dbo.product

-- 1. What are the top sellers? What are the worst
select top 5 p.name, sum(quantity_ordered) as total_ordered
from ecom2.dbo.ordereditems as oi
inner join ecom2.dbo.product as p
on oi.sku = p.sku
group by p.name
order by total_ordered ASC

-- 2. What is the average order size
select avg(amount_ordered) as avg_order
from ecom2.dbo.orders



with new_table as 
(select p.sku, sum(quantity_ordered) as total_ordered
	from ecom2.dbo.ordereditems as oi
	inner join ecom2.dbo.product as p
	on oi.sku = p.sku
	group by p.sku)
select *
from new_table
inner join ecom2.dbo.product as p1
on new_table.sku = p1.sku
 

 --3. When are most orders placed? (time of year)
select sum(case when datepart(QUARTER,o.created_at) = 1 then quantity_ordered else null end) as q1,
sum(case when datepart(QUARTER,o.created_at) = 2 then quantity_ordered else null end) as q2,
sum(case when datepart(QUARTER,o.created_at) = 3 then quantity_ordered else null end) as q3,
sum(case when datepart(QUARTER,o.created_at) = 4 then quantity_ordered else null end) as q4
from ecom2.dbo.orders as o
inner join ecom2.dbo.ordereditems as oi
on o.order_id = oi.order_id

-- 4. What is the profit? profit by time?
with new_table as 
(select p.sku, sum(quantity_ordered) as total_ordered
	from ecom2.dbo.ordereditems as oi
	inner join ecom2.dbo.product as p
	on oi.sku = p.sku
	group by p.sku)
select sum(case when datepart(QUARTER,o.created_at) = 1 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q1,
sum(case when datepart(QUARTER,o.created_at) = 2 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q2,
sum(case when datepart(QUARTER,o.created_at) = 3 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q3,
sum(case when datepart(QUARTER,o.created_at) = 4 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q4
from new_table
inner join ecom2.dbo.product as p1
on new_table.sku = p1.sku
inner join ecom2.dbo.ordereditems as oi
on p1.sku = oi.sku
inner join ecom2.dbo.orders as o
on oi.order_id = o.order_id
