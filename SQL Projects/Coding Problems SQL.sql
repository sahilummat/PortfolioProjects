--1 - Return Orders Customer Feedback
--https://www.namastesql.com/coding-problem/1-return-orders-customer-feedback

;with cte as (
select 
customer_name,
count(o.order_id) as number_of_orders,
count(r.order_id) as number_of_orders_returned
from orders o
left join returns r on o.order_id=r.order_id  
group by customer_name
)
select 
customer_name,round(number_of_orders_returned*100.0/number_of_orders,2) as return_percent
from cte 
where round(number_of_orders_returned*100.0/number_of_orders,2)>50
order by customer_name

--2 Product Category
--https://www.namastesql.com/coding-problem/2-product-category

select 
case when price < 100 then 'Low Price' 
when price >=100 and price <= 500 then 'Medium Price'
 when price > 500 then 'High Price' 
end as price_category,
count(1) as products_in_each_Category
from products
group by case when price < 100 then 'Low Price' 
when price >=100 and price <= 500 then 'Medium Price'
 when price > 500 then 'High Price' 
end 
order by products_in_each_Category desc


--3 - LinkedIn Top Voice
--https://www.namastesql.com/coding-problem/3-linkedin-top-voice

;with cte as (
select * from posts
where year(publish_date)=2023 and month(publish_date)=12
and creator_id  in (
select creator_id   from 
  posts
  where year(publish_date)=2023 and month(publish_date)=12
  group by creator_id
  having count(1)>=3 and sum(impressions)>100000
)
  )
  select a.creator_name,count(distinct c.post_id) as number_post
  ,sum(impressions) as total_impressions
  from cte c 
  left join (select * from creators 
where followers>50000  )a 
on c.creator_id=a.creator_id
group by a.creator_name

--4 - Premium Customers
--https://www.namastesql.com/coding-problem/4-premium-customers

;with cte as (
select customer_name 
,count(1) as orders
from orders
group by customer_name
  )
  select * from cte 
  where 
  orders > (
  select sum(orders)*1.0/count(orders) as avg_orders
  from cte )

--5 - CIBIL Score
--https://www.namastesql.com/coding-problem/5-cibil-score

;with loan_pay  as (
select ct.* ,coalesce(ccb.customer_id,l.customer_id) as customer_id,
coalesce(ccb.bill_due_date,l.loan_due_date) as due_date,ccb.balance_amount,
l.loan_id
,case when ct.transaction_date <= coalesce(ccb.bill_due_date,l.loan_due_date)
then 1 else 0 end as defaulter_flag
from customer_transactions ct 
left join credit_card_bills ccb on ct.loan_bill_id=ccb.bill_id 
left join loans l on ct.loan_bill_id=l.loan_id)

,final_loan_pay as (
  select customer_id,
sum(case when defaulter_flag =1 then defaulter_flag else 0 end) as successfull,
count(1) as total,
70*sum(case when defaulter_flag =1 then defaulter_flag else 0 end)*1.0/
count(1) as ratio2
from loan_pay
group by customer_id)

, spend_cte as (
select customer_id,sum(balance_amount) as total_spend
from credit_card_bills
group by customer_id)

,final_ratio as (
select sc.*,c.credit_limit,
sc.total_spend*100.0/c.credit_limit as Credit_Utilization
,30 * case when sc.total_spend*100.0/c.credit_limit < 30 then 1
when sc.total_spend*100.0/c.credit_limit >=30 and sc.total_spend*100.0/c.credit_limit<=50 then 0.7
when sc.total_spend*100.0/c.credit_limit >50 then 0.5 
end as ratio
from spend_cte sc 
join customers c on sc.customer_id=c.customer_id)
select fr.customer_id,cast (round(fr.ratio + flp.ratio2,1) as float)
                            as cibil_score from
final_ratio fr
join final_loan_pay flp on fr.customer_id=flp.customer_id
order by fr.customer_id


--6 - Electricity Consumption
--https://www.namastesql.com/coding-problem/6-electricity-consumption

;with cte as (
select household_id,
billing_period,left(billing_period,4) as yr,
consumption_kwh,total_cost
from electricity_bill)
select household_id,yr,sum(consumption_kwh) as total_consumption
,sum(total_cost) as total_costt,
avg(consumption_kwh) as avg_consumption_kwh                     from cte 
group by household_id,yr
order by household_id,yr


--7 - Airbnb Top Hosts
--https://www.namastesql.com/coding-problem/7-airbnb-top-hosts


;with cte as (
              select host_id,listing_id from listings 
              where host_id in 
  			 (
                      select  host_id
  
                      from listings
                      group by host_id
                      having count(distinct listing_id)>=2 
              )
)
  ,cte2 as (
              select c.*,r.rating,
              (sum(r.rating)over(partition by c.host_id)*1.0
              /count(1)over(partition by c.host_id)) as avg_rating
                            from cte c 
              join reviews r on c.listing_id =r.listing_id 
  )
  select host_id,number_of_listing,cast(round(avg_rating,2) as decimal(10,6))  as max_avg_rating
  from (
  select host_id,count(distinct listing_id) as number_of_listing,
  max(avg_rating) as avg_rating,
  row_number() over(order by max(avg_rating) desc) as rn 
  from cte2
  group by host_id)a
  where rn <=2
 
 
--8 - Library Borrowing Habits
--https://www.namastesql.com/coding-problem/8-library-borrowing-habits

select br.BorrowerName
,string_agg(bo.BookName,',') within group(order by bo.BookName) as books_borrowed 
from Borrowers br
join books bo on br.BookID=bo.BookID
group by br.BorrowerName
order by br.BorrowerName


--9 - New and Repeat Customers
--https://www.namastesql.com/coding-problem/9-new-and-repeat-customers

;with cte as (
select *
,min(order_date)over(partition by customer_id) as first_purchase
from customer_orders)
select order_date,
count(distinct case when order_date = first_purchase then customer_id else null end) as new_customers,
count(distinct case when order_date != first_purchase then customer_id else null end) as repeat_customers
from cte 
group by order_date
order by repeat_customers

--10 - The Little Master
--https://www.namastesql.com/coding-problem/10-the-little-master

;with cte as (
select *,
sum(runs_scored)over(order by match_no
                     rows between unbounded preceding and current row) as running_score,
sum(case when status ='out' then 1 else 0 end)
  over(order by match_no
                     rows between unbounded preceding and current row)  as out_time
 , sum(runs_scored)over(order by match_no
                     rows between unbounded preceding and current row)*1.0/sum(case when status ='out' then 1 else 0 end)
  over(order by match_no
                     rows between unbounded preceding and current row) as batting_avg
from sachin
  )
  select min(match_no) as match_no,
  round(min(batting_avg),2) as batting_average 
  from cte
  where running_score > 500


--11 - Math Champions
--https://www.namastesql.com/coding-problem/11-math-champions

;with cte as (
select * ,
round(avg(grade)over(),2) as avg_math_grade
from grades
where subject ='Math')
select s.student_name ,c.grade
from cte c join Students s on s.student_id =c.student_id 
where grade > avg_math_grade
order by c.grade

--12 - Deliveroo Top Customer
--https://www.namastesql.com/coding-problem/12-deliveroo-top-customer

select  top 1 customer_id,
sum(total_cost) as total_cost
from orders
group by customer_id
order by total_cost desc

--13 - Best Employee Award
--https://www.namastesql.com/coding-problem/13-best-employee-award

;with cte as (
select project_id 
,employee_name 
,datetrunc(month,project_completion_date ) as month_start
  ,project_completion_date
from projects)
,cte2 as (
select month_start,employee_name,
count(distinct project_id) as projects_completed,
row_number()over(partition by month_start order by 
                 count(distinct project_id) desc) as rn 
from cte 
  where project_completion_date is not null
group by month_start,employee_name)
select employee_name ,projects_completed, 
FORMAT(month_start,'yyyyMM') as month_start 

from cte2 
where rn=1
order by projects_completed desc
