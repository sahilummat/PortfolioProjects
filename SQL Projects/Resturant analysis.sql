select * from menu_items
select * from order_details

--View the menu_items table and write a query to find the number of items on the menu

select count(item_name)
from menu_items

--What are the least and most expensive items on the menu?
--Shrimp Scampi Most expensive
--Edamame Least expensive
select top 1 item_name from menu_items 
order by price desc

select top 1 item_name from menu_items 
order by price asc

--How many Italian dishes are on the menu? What are the least and most expensive Italian dishes on the menu?
--9 Itanlian Dishes

select category,count(1) as number_of_dishes 
from menu_items
where category='Italian'
group by category 

--Shrimp Scampi
select top 1 category,item_name from menu_items 
where category='Italian'
order by price desc

--Spaghetti
select top 1 category,item_name from menu_items 
where category='Italian'
order by price 

--How many dishes are in each category? What is the average dish price within each category?

select category , count(1) total_dishes,round(avg(price),2) as avg_dish_price
from menu_items
group by category


--View the order_details table. What is the date range of the table?
select * from order_details

select min(order_date) as first_date,max(order_date) as last_date from 
order_details

--How many orders were made within this date range? How many items were ordered within this date range?
--5370 total_orders

select count(distinct order_id) 
from order_details
--12097
select count( item_id) 
from order_details

--Which orders had the most number of items?
--330,3473,2675,1957,440,443,4305

select order_id,count(item_id) as total_items
from order_details
group by order_id
order by total_items desc

--How many orders had more than 12 items?
--20 orders
select count(*) from (
select order_id,count(item_id) as total_items
from order_details
group by order_id
having count(item_id)>12
)a


--Combine the menu_items and order_details tables into a single table

select *
from menu_items m
left join order_details o on m.menu_item_id=o.item_id

--What were the least and most ordered items? What categories were they in?
select * from menu_items
select m.category from menu_items m
inner join 
(select top 1 item_id,count(1) as item_count from 
order_details
group by item_id
order by item_count desc)o on m.menu_item_id=o.item_id 

select m.category from menu_items m
inner join 
(select top 1 item_id,count(1) as item_count from 
order_details
group by item_id
order by item_count )o on m.menu_item_id=o.item_id 

--What were the top 5 orders that spent the most money?
select * from order_details

select top 5  o.order_id,sum(m.price) as total_spend
from order_details o inner join menu_items m on o.item_id=m.menu_item_id
group by o.order_id
order by total_spend desc


--View the details of the highest spend order. Which specific items were purchased?



;with cte as (
select * from order_details o inner join menu_items m on o.item_id=m.menu_item_id
),topfive as (
select *, sum(price)over(partition by order_id) as total_spend 
from cte 
)
select * from (
select * ,DENSE_RANK()over(order by total_spend desc) as drnk
from topfive)a where drnk<=5