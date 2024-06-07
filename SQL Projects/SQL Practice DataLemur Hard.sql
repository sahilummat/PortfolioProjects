***Active User Retention [Facebook SQL Interview Question]
https://datalemur.com/questions/user-retention

;with cte as (
SELECT user_id,COUNT(DISTINCT date_part('month',event_date)) as monthly_active_users
,MAX(date_part('month',event_date)) as mth
FROM user_actions
where event_date >='06/01/2022' and event_date<='07/31/2022'
group by user_id)
select mth,count(*) from cte 
where monthly_active_users>=2
group by mth


***Y-on-Y Growth Rate [Wayfair SQL Interview Question]
https://datalemur.com/questions/yoy-growth-rate

with cte as (
SELECT 
date_part('year',transaction_date) as year,
product_id,spend as curr_year_spend
,lag(spend)over(partition by product_id order by date_part('year',transaction_date))
as prev_year_spend
FROM user_transactions)
select * ,
ROUND((curr_year_spend-prev_year_spend)*100.0/prev_year_spend,2) as yoy_rate
from cte 


***Maximize Prime Item Inventory [Amazon SQL Interview Question]
https://datalemur.com/questions/prime-warehouse-storage

with cte as (
SELECT item_type
,count(*) as batch_size,
SUM(square_footage) as area_per_item_type
FROM inventory
group by item_type)
,prime_item as ( 
select item_type,
area_per_item_type,
floor(500000/area_per_item_type) as prime_item_batch_count,
floor(500000/area_per_item_type)*batch_size as prime_item_count
from cte where item_type='prime_eligible')
,non_prime as (

select item_type,
area_per_item_type,
floor((500000-(select area_per_item_type *prime_item_batch_count from prime_item))/area_per_item_type) as non_prime_item_batch_count,
floor((500000-(select area_per_item_type *prime_item_batch_count from prime_item))/area_per_item_type)*batch_size as non_prime_item_count
from cte where item_type='not_prime'
)
select item_type,non_prime_item_count as item_count from (
select * from non_prime
union all 
select * from prime_item)a
order by item_count desc 


***Median Google Search Frequency [Google SQL Interview Question]
https://datalemur.com/questions/median-search-freq

with cte as (
SELECT searches
  FROM search_frequency
  GROUP BY 
    searches,GENERATE_SERIES(1, num_users))
    
    select ROUND(PERCENTILE_CONT(.50) WITHIN GROUP (order by searches ):: decimal,1)
    as median
    from cte 
 
***Advertiser Status [Facebook SQL Interview Question]
https://datalemur.com/questions/updated-status

with cte as (
SELECT COALESCE(a.user_id,dp.user_id) as user_id,a.status
,dp.paid as payment
from 
advertiser  a  
full outer join daily_pay dp on a.user_id=dp.user_id)
,cte2 as (
select *,
case when payment is null then 'Not Paid' else 'Paid' end as paymentt
from cte )
select user_id,new_status from (
select *,
case when paymentt ='Not Paid' then 'CHURN' 
      when paymentt='Paid' and status='CHURN' then 'RESURRECT'
      when status is null then 'NEW'
      else 'EXISTING'
 end as new_status
from cte2)a
order by a.user_id



***Consecutive Filing Years [Intuit SQL Interview Question]
https://datalemur.com/questions/consecutive-filing-years

with cte as (
select * from filed_taxes
where user_id in (
select user_id
from filed_taxes
group by user_id having count(1)>=3
)
),final as (
select *,
lag(product) over (partition by user_id order by filing_date) as prev_prod,
lead(product) over (partition by user_id order by filing_date) as next_prod
from cte )
select  DISTINCT user_id from (
select *,
Case when left(product,8)=left(prev_prod,8) and left(product,8)=left(next_prod,8) then 1 else 0 end as flag
from final)a where a.flag=1


***Marketing Touch Streak [Snowflake SQL Interview Question]
https://datalemur.com/questions/marketing-touch-streak

;with cte as (
select *
from marketing_touches 
where contact_id in 
(select contact_id from marketing_touches group by contact_id HAVING
count(1)>=3)
),final as (
select *, date_trunc('week',event_date) as start_of_week
from cte 
where contact_id IN
(select DISTINCT contact_id from cte where event_type='trial_request'))
,final2 as (
select *,
lead(start_of_week,1)over(PARTITION BY contact_id order by start_of_week) as next_week,
lag(start_of_week,1)over(PARTITION BY contact_id order by start_of_week) as prev_week
from final)
select cc.email as email
from final2 ff
inner join crm_contacts cc on ff.contact_id=cc.contact_id
where 
DATE_PART('week', start_of_week::date)-DATE_PART('week', prev_week::date)=1
and 
DATE_PART('week', next_week::date)-DATE_PART('week', start_of_week::date)=1


***3-Topping Pizzas [McKinsey SQL Interview Question]
https://datalemur.com/questions/pizzas-topping-cost

;with master as (
SELECT *
FROM pizza_toppings)

select 
m1.topping_name || ',' || m2.topping_name||','|| m3.topping_name as pizza,
m1.ingredient_cost+m2.ingredient_cost+m3.ingredient_cost as total_cost
from master m1 inner join master m2 on m1.topping_name < m2.topping_name
inner join master m3 on m2.topping_name < m3.topping_name
order by total_cost desc,pizza


***Compressed Median [Alibaba SQL Interview Question]
https://datalemur.com/questions/alibaba-compressed-median

WITH summary AS (
SELECT item_count
FROM items_per_order
GROUP BY
  item_count,
  GENERATE_SERIES(1, order_occurrences)
)

SELECT 
  ROUND(
    PERCENTILE_CONT(0.50) WITHIN GROUP (
    ORDER BY item_count)::DECIMAL, 1) AS median
FROM summary;

***Average Vacant Days [Airbnb SQL Interview Question]
https://datalemur.com/questions/average-vacant-days

;with cte as (
select l.listing_id as lid,b.*,
case when checkin_date < '1/1/2021 00:00:00' then '1/1/2021 00:00:00' 
else  checkin_date end as correct_checkin,
case when checkout_date > '12/31/2021 00:00:00' then '12/31/2021 00:00:00' 
else  checkout_date end as correct_checkout
from listings l
LEFT JOIN bookings b on l.listing_id=b.listing_id 
where  l.is_active=1)
,final as (
select lid, cast((correct_checkout-correct_checkin)as int) as number_of_days
from cte)
select ROUND(SUM(total_vacant_days)*1.0/COUNT(DISTINCT lid) ) as avg_vacant_days
from (
select lid,365-COALESCE(SUM(number_of_days),0) as total_vacant_days
from final
group by lid
)a


***Patient Support Analysis (Part 3) [UnitedHealth SQL Interview Question]
https://datalemur.com/questions/patient-call-history

WITH call_history AS (
  SELECT
    policy_holder_id,
    call_date AS current_call, -- Remove this column
    LAG(call_date) OVER (
  	  PARTITION BY policy_holder_id ORDER BY call_date) AS previous_call, -- Remove this column
    ROUND(EXTRACT(EPOCH FROM call_date 
      - LAG(call_date) OVER (
  	    PARTITION BY policy_holder_id ORDER BY call_date)
    )/(24*60*60),2) AS time_diff_days
  FROM callers
)
SELECT COUNT(DISTINCT policy_holder_id) AS policy_holder_count
FROM call_history
WHERE time_diff_days <= 7;


***Patient Support Analysis (Part 4) [UnitedHealth SQL Interview Question]
https://datalemur.com/questions/long-calls-growth

;with cte as (
select EXTRACT(year from call_date) as yr,
EXTRACT(month from call_date) as mnth,
count(case_id) as call_duration_secs,
lag(count(case_id))OVER
(order by EXTRACT(year from call_date),EXTRACT(month from call_date)) as prev_month_duration
from callers 
where call_duration_secs >=300
group by yr,mnth)
select yr,mnth as mth,
ROUND((call_duration_secs-prev_month_duration)*100.0/prev_month_duration,1) as long_calls_growth_pct
from cte 


***Same Week Purchases [Etsy SQL Interview Question]
https://datalemur.com/questions/same-week-purchases

;with cte as (
select s.user_id,s.signup_date,a.purchase_date
from signups s
left join (
select *
,row_number()over(PARTITION BY  user_id order by purchase_date) as rn 
from user_purchases )a on s.user_id=a.user_id and a.rn=1)
select ROUND(SUM(number_of_days)*100.0/count(1),2) as single_purchase_pct
from (
select *,
case when 
EXTRACT(EPOCH FROM (purchase_date - signup_date))/(24*60*60) <=7 then 1 else 0 END
as number_of_days
from cte )a


***Follow-Up Airpod Percentage [Apple SQL Interview Question]
https://datalemur.com/questions/follow-up-airpod-percentage

;with cte as (
select *,
lag(product_name)over(PARTITION BY customer_id order by transaction_id)
as prev_item_bought,
case 
when product_name='AirPods' and 
lag(product_name)over(PARTITION BY customer_id order by transaction_id)='iPhone'
then 1 else 0 end as flag
from transactions )
select ROUND(SUM(flag)*100.0/count(DISTINCT customer_id)) as round
from cte 


***Repeated Payments [Stripe SQL Interview Question]
https://datalemur.com/questions/repeated-payments

with cte as (
select *,
EXTRACT(EPOCH FROM transaction_timestamp -
LAG(transaction_timestamp)over(PARTITION BY
merchant_id,credit_card_id,amount order by transaction_timestamp)
)/60 as rn 
from transactions )
select count(merchant_id) as payment_count from cte where rn<=10


***User Concurrent Sessions [Pinterest SQL Interview Question]
https://datalemur.com/questions/concurrent-user-sessions

select s1.session_id,count(s2.session_id ) as ttl_cnt from sessions s1
inner join sessions s2
on s1.session_id <> s2.session_id
and (s2.start_time between s1.start_time and s1.end_time
or
s1.start_time between s2.start_time and s2.end_time)
group by s1.session_id
order by ttl_cnt desc


***Monthly Merchant Balance [Visa SQL Interview Question]
https://datalemur.com/questions/sql-monthly-merchant-balance

;with cte as (
select transaction_date::date,
SUM(case when type='deposit' then amount
else -amount end) as total_sum from transactions
group by transaction_date::date)
select transaction_date as transaction_day,
SUM(total_sum)over(PARTITION BY EXTRACT(month from transaction_date) order by transaction_date) 
as balance
from cte 
order by transaction_date


***Bad Delivery Rate [DoorDash SQL Interview Question]
https://datalemur.com/questions/sql-bad-experience


with final_cust as (
select * from customers
where EXTRACT(month from signup_timestamp)=6
and EXTRACT(year from signup_timestamp)=2022)
, final as (
select o.*,f.signup_timestamp,t.estimated_delivery_timestamp,t.actual_delivery_timestamp,
case when t.actual_delivery_timestamp>t.estimated_delivery_timestamp
or o.status in ('completed incorrectly','never received')
then 1 else 0 end as late_order_flag,
EXTRACT(EPOCH FROM (o.order_timestamp - f.signup_timestamp))/(60*60*24)
from orders o 
left join final_cust f on o.customer_id=f.customer_id
left join trips t on t.trip_id=o.trip_id
where o.customer_id in (select DISTINCT customer_id from final_cust)
and EXTRACT(EPOCH FROM (o.order_timestamp - f.signup_timestamp))/(60*60*24) <=14)
select ROUND(SUM(late_order_flag)*100.0/COUNT(late_order_flag),2) as bad_experience_pct
from final


***Page Recommendation [Facebook SQL Interview Question]
https://datalemur.com/questions/page-recommendation

;with friend_list as (
select user_id,friend_id from friendship   
UNION ALL
select friend_id,user_id from friendship   )
, final as (
select fl.user_id,fl.friend_id,pf.page_id from  friend_list
fl
inner join page_following pf
on fl.friend_id=pf.user_id)
,final_data as (
select user_id,page_id,count(1),
rank()over(partition by user_id order by count(1) desc)
as page_count from final f
where not EXISTS (
select 1 from page_following pp where f.user_id=pp.user_id 
and f.page_id=pp.page_id
)
group by user_id,page_id
)
select user_id,page_id from final_data where page_count=1


***Reactivated Users [Facebook SQL Interview Question]
https://datalemur.com/questions/reactivated-users


;with cte as (
select *,
date_trunc('month',login_date) as month_start,
lag(date_trunc('month',login_date))over(PARTITION BY user_id
order by date_trunc('month',login_date)) as prev_login
from user_logins )
select EXTRACT(month from month_start) as mth,
sum(case when prev_login is null OR
DATE_PART('Month', month_start :: DATE) - 
DATE_PART('Month', prev_login :: DATE) >=2 then 1 else 0 end ) as reactivated_users
from cte 
group by EXTRACT(month from month_start)
having SUM(case when prev_login is null OR
DATE_PART('Month', month_start :: DATE) - 
DATE_PART('Month', prev_login :: DATE) >=2 then 1 else 0 end )>=1
order by mth

***Senior Managers [Google SQL Interview Question]
https://datalemur.com/questions/senior-managers-reportees

select m.manager_name,count(DISTINCT e.manager_name)as direct_reportees from employees e  
inner join employees as m on e.manager_id=m.emp_id
inner join employees as sm on m.manager_id=sm.emp_id
group by m.manager_name



***Event Friends Recommendation [Facebook SQL Interview Question]
https://datalemur.com/questions/event-friends-rec


;with cte as (
select user_id,event_id from event_rsvp 
where event_type ='private' and attendance_status in ('going','maybe')
)
select distinct c1.user_id as user_a_id ,c2.user_id as user_b_id
from cte c1 inner join cte c2 on c1.event_id=c2.event_id
and c1.user_id!=c2.user_id
inner join friendship_status fs 
on c1.user_id=fs.user_a_id and c2.user_id=fs.user_b_id
where fs.status='not_friends'

***Matching Rental Amenities [Airbnb SQL Interview Question]
https://datalemur.com/questions/matching-rental-amenities

;with cte as (
select rental_id
,string_agg(amenity,',' order by amenity)   as amenityyy
from rental_amenities 
group by rental_id
)
select count(1) as matching_airbnb from cte c1
inner join cte c2 on c1.amenityyy=c2.amenityyy 
where c1.rental_id<c2.rental_id


***Weekly Churn Rates [Facebook SQL Interview Question]

https://datalemur.com/questions/first-month-retention

;
with cte as (
select *,
date_trunc('week',signup_date),
case when DATE_PART('week', signup_date)=22 then 1
when DATE_PART('week', signup_date)=23 then 2
when DATE_PART('week', signup_date)=24 then 3
when DATE_PART('week', signup_date)=25 then 4 end as week_num,
extract (day from last_login-signup_date) as num_days,
case when extract (day from last_login-signup_date)<=28 then 1 else 0 end as churn_flag
from users 
where EXTRACT(year from signup_date)=2022 and
EXTRACT(month from signup_date)=6)

select  week_num as signup_week,ROUND(sum(churn_flag)*100.0/COUNT(1),2) as signup_week from cte 
group by week_num


***Uniquely Staffed Consultants [Accenture SQL Interview Question]
https://datalemur.com/questions/uniquely-staffed-consultants

;with final1 as (
select employee_id,MAX(client_name) as client from employees e inner join consulting_engagements  ce 
on e.engagement_id=ce.engagement_id
group by employee_id
having count(DISTINCT client_name)=1)
,exclsuive as (
select client,count(1) as exc_con
from final1
group by client)
select ce.client_name,COUNT(distinct employee_id)as total_staffed,COALESCE(MAX(exc_con),0)as exclusive_staffed
from employees e inner join consulting_engagements  ce 
on e.engagement_id=ce.engagement_id
left join exclsuive ee on ee.client=ce.client_name
group by ce.client_name


***Server Utilization Time [Amazon SQL Interview Question]

https://datalemur.com/questions/total-utilization-time

;with cte as (
select *,
lag(status_time,1)over(partition by server_id order by status_time) as stop_time
,lead(session_status,1,'start')over(partition by server_id order by status_time) as status
from server_utilization )
--order by server_id,status_time)
select SUM(
EXTRACT(hour from status_time-stop_time)) as total_uptime_days
from cte 
where status='start' and session_status='stop'



***FAANG Stock Identify Underperforming Stocks (Part 3) [SQL Interview Question]
https://datalemur.com/questions/sql-bloomberg-underperforming-stocks

;with cte as (
SELECT date as datee,
EXTRACT(month from date) as mon
,EXTRACT(year from date) as yr,
ticker,
open
FROM stock_prices 
--order by yr,mon
),final as (
select *,
lag(open)over(partition by ticker order by yr,mon) as prev_open,
open-lag(open)over(partition by ticker order by yr,mon) as diff
from cte)
--select mon,yr,ticker,diff from (
,final_data as (
select *, SUM(diff_flag)over(partition by yr,mon order by yr,mon) as summ from (
select *
,case when diff < 0 then 1 else 0 end as diff_flag
from final)A
)
select 
 Left(TO_CHAR(datee::date, 'Month'),3) || '-'|| (cast (yr as varchar(20))) AS mth_yr,ticker as 
underperforming_stock
from final_data where summ=1 and diff_flag=1
order by yr,mon,ticker

