
create table df_orders (
order_id int primary key,
order_date date
,ship_mode varchar(20)
,segment  varchar(20)
,country varchar(20),
city varchar(20),
state varchar(20)
,postal_code varchar(20)
,region varchar(20)
,category varchar(20)
,sub_category varchar(20)
,product_id varchar(50)
,quantity int
,discount decimal(7,2)
,sale_price decimal(7,2)
,profit decimal(7,2)
)

select * from df_orders

--Finding top 10 highest revenue generating products

select top 10
product_id,SUM( sale_price) as revenue
from df_orders
group by product_id
order by revenue desc

--Finding top 5 selling products in each region
;with cte as (
select 
region,product_id,SUM(sale_price) as sales
from df_orders
group by region,product_id
)
select * from (
select *, ROW_NUMBER()over(partition by region order by sales desc) as rn 
from cte )a where rn<=5;


--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
;with year_mnth_sales as(
select YEAR(order_date) as yr
,month(order_date) as mnth, SUM(sale_price) as sales
from df_orders
group by YEAR(order_date),month(order_date)
--order by YEAR(order_date),month(order_date)
)
select mnth,
sum(case when yr=2022 then sales else 0 end )as sales_2022,
sum(case when yr=2023 then sales else 0 end )as sales_2023,
(sum(case when yr=2023 then sales else 0 end )-sum(case when yr=2022 then sales else 0 end ))*100.0/
sum(case when yr=2022 then sales else 0 end ) as momgrowthpercent
from year_mnth_sales
group by mnth

--for each category which month had highest sales 
;with cte as (
select format(order_date,'yyyyMM') as yr_mnth,category,SUM(sale_price) as sales
from df_orders
group by format(order_date,'yyyyMM'),category
--order by category,MONTH(order_date)
)
select yr_mnth,category,sales from (
select *,ROW_NUMBER()over(partition by category order by sales desc) as rn 
from cte )a where rn=1

--which sub category had highest growth by profit in 2023 compare to 2022
;with cte as (
select sub_category,YEAR(order_date) as yr, SUM(profit) as profit
from df_orders
group by sub_category,YEAR(order_date) 
)
,cte2 as (
select sub_category
,SUM(case when yr=2022 then profit else 0 end) as total_2022_profit,
SUM(case when yr=2023 then profit else 0 end) as total_2023_profit
from cte
group by sub_category)

select top 1 * , (total_2023_profit-total_2022_profit)*100.0/total_2022_profit as growth_rate
from cte2 
order by growth_rate desc

