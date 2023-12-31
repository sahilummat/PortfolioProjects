--Hard Interview Question Amazon

with cte as (
SELECT COALESCE(a.user_id,d.user_id)as user_id,a.status as status,
case when d.paid is null then 'Not Paid' else 'Paid' end as payment
FROM advertiser  a 
full outer join daily_pay d on a.user_id=d.user_id
)
select user_id,
case when payment='Not Paid' then 'CHURN' 
    when payment='Paid'and status='CHURN' then 'RESURRECT'
    when payment='Paid'and status is null then 'NEW'
    else 'EXISTING' end as new_status
from cte 
order by user_id

--Hard Interview Question Apple

with cte as (
select *  ,
lead(product_name)over(partition by customer_id order by transaction_id) as next_val
from transactions )
,total as (
select COUNT(distinct customer_id) as total_customer from transactions 
)

select round(count(distinct customer_id)*100.0/(select * from total) )as follow_up_percentage   from cte 
where product_name='iPhone' and next_val='AirPods'

--Hard Interview Question Facebook 

with cte as (
select user_id
,date_trunc('month',login_date) as current_val
,date_trunc('month',lag(login_date)over(partition by user_id order by  login_date))as prev_val
from user_logins )
select EXTRACT(month from current_val) as mth,SUM(flag) as reactivated_users from (
select * ,
case when prev_val is null then 1 
    when DATE_PART('month', AGE(current_val, prev_val))>1 then 1 else 0 end as flag
from cte )a
group by EXTRACT(month from current_val)
having SUM(flag)>0
order by mth

--HARD SNOWFLAKE

WITH consecutive_events_cte AS (
  SELECT
    event_id,
    contact_id, 
    event_type, 
    DATE_TRUNC('week', event_date) AS current_week,
    LAG(DATE_TRUNC('week', event_date)) OVER (
      PARTITION BY contact_id 
      ORDER BY DATE_TRUNC('week', event_date)) AS lag_week,
    LEAD(DATE_TRUNC('week', event_date)) OVER (
      PARTITION BY contact_id 
      ORDER BY DATE_TRUNC('week', event_date)) AS lead_week
FROM marketing_touches)

SELECT DISTINCT contacts.email
FROM consecutive_events_cte AS events
INNER JOIN crm_contacts AS contacts
  ON events.contact_id = contacts.contact_id
WHERE events.lag_week = events.current_week - INTERVAL '1 week'
  OR events.lead_week = events.current_week + INTERVAL '1 week'
  AND events.contact_id IN (
    SELECT contact_id 
    FROM marketing_touches 
    WHERE event_type = 'trial_request'
  );

  --HARD CRICKET ANALYSIS

  
;with cte as (
select *
,ROW_NUMBER() over(order by ball_no) as legal_del_number,
ceiling(ROW_NUMBER() over(order by ball_no)*1.0/6) as over_number
from cricket_runs
where delivery_type='legal')
,legal_cte as( 
select *,lag(last_ball,1,0)over(order by over_number)+1 as first_ball from(
select over_number , SUM(runs) as legal_runs,max(ball_no) as last_ball
from cte
group by over_number)a),
extra_cte as (
select * from cricket_runs where delivery_type!='legal')
select over_number,legal_runs+coalesce(SUM(e.runs),0) +count(e.runs) as total_runs from 
legal_cte l left join extra_cte e on e.ball_no between l.first_ball and l.last_ball
group by over_number,legal_runs

--Airbnb HARD QUESTION 

with cte as(
select rental_id,
string_agg(amenity,',' order by amenity)  as amen 
from rental_amenities 
group by rental_id),cte2 as (
select c1.rental_id as cr1,c2.rental_id as cr2,c1.amen as c1amen,c2.amen as c2amen  from cte c1
inner join cte c2 on c1.rental_id<c2.rental_id and c1.amen=c2.amen)
select count(*) as matching_airbnb from cte2

--Amazon Hard Question 
with cte as (
SELECT server_id,
session_status,lead(session_status)over(PARTITION BY server_id order by status_time ) as nextstatus
,status_time,lead(status_time)over(PARTITION BY server_id order by status_time ) as nexttime
FROM server_utilization
)
select sum(hours)/24 as total_uptime_days from (
select *,cast (EXTRACT(EPOCH FROM (nexttime -status_time ))/3600 as int)as hours
from cte where session_status='start' and nextstatus='stop')a

Salesforce Medium Question 
    
with cte as (
select customer_id,SUM(num_seats) as total_seats,MAX(yearly_seat_cost) 
as yearly_seat_cost
from contracts 
group by customer_id),final as (
select customer_id	,total_seats*yearly_seat_cost as t_revenue,
case when total_seats < 100 then 'SMB' 
when total_seats>=100 and total_seats<=999 then 'Mid'
when total_seats>=1000 then 'Enterprise' end as segment
from cte )
select 
floor(max(case when segment='SMB' then revenue/cnt else 0 end ))as smb_avg_revenue,
floor(max(case when segment='Mid' then revenue/cnt else 0 end ))as mid_avg_revenue,
floor(max(case when segment='Enterprise' then (revenue)/(cnt) else 0 end)) as enterprise_avg_revenue
from
(
select segment,sum(t_revenue) as revenue,count(*)as cnt from final 

group by segment
)a


Accenture Medium Question 

;with data as (
select * 
,row_number() over(order by product_id) as rn 
from products),
final as (
select *,
lead(rn,1,99999)over(order by product_id)-1 as nextrn
from data 
where category is not null)
select d.product_id,f.category,d.name
from data d left join final f on d.rn between f.rn and f.nextrn
    
Amazon Medium Question 

select order_date,product_type,cum_purchased from (
    select * 
    ,sum(quantity)over(partition  by product_type order by order_date)as cum_purchased
    from total_trans )a
order by order_date

Paypal Medium Question
with cte as (
select p1.payer_id as payer1,p1.recipient_id as receiver1
,p2.payer_id as payer2,p2.recipient_id as receiver2
from payments p1
inner join payments p2
on p1.recipient_id=p2.payer_id)
,cte2 as (
select payer1,receiver1,
case when payer1<receiver1 then payer1 else receiver1 end as flag1,
case when payer1>receiver1 then payer1 else receiver1 end as flag2
from cte where payer1=receiver2)
select count(*) as unique_relationships from (
select flag1,flag2
from cte2 
group by flag1,flag2)a

    
Adobe Medium Question 

with cte as (
select * from adobe_transactions 
where customer_id in 
(
select  customer_id from adobe_transactions  where product='Photoshop'
)
)
select customer_id,
SUM(case when product!='Photoshop' then revenue else 0 end )as revenue
from cte 
GROUP BY customer_id


Tiger Analytics Medium Complexity Question 

with cte as (
select *
,ROW_NUMBER()over(partition by cid order by fid) as rn 
from  flights )
select cid,max(case when rn=originf then origin else null end )as Origination 
,max(case when rn=destinationf then Destination else null end )as Desination
from (
select *,min(rn)over() as originf,
max(rn)over() as destinationf
from cte)a
group by cid

with cte as (
select * ,
min(order_date)over(partition by customer) as first_purchase
from sales)
select order_date,SUM(flag) as new_customers from (
select *, case when order_date=first_purchase then 1 else 0 end as flag
from cte )a
group by order_date


--Medium Difficaulty Google question

with cte as (
select country,
search_cat,num_search,invalid_result_pct
from search_category 
where invalid_result_pct is not null and invalid_result_pct is not null
),cte2 as (
select *,(num_search*invalid_result_pct)/100 as invalid_searches
from cte )
select country,SUM(num_search) as total_searches,
ROUND(SUM(invalid_searches)*100.0/SUM(num_search),2)as invalid_searches_pct
from cte2
group by country
order by country

--Hard Question Stripe 
with cte as (
SELECT *,
lead(transaction_timestamp)over
(partition by merchant_id,credit_card_id,amount order by transaction_id) as next_val
FROM transactions)
select count(*) as payment_count from (
select *,round(extract(epoch from 
        next_val::timestamp - transaction_timestamp::timestamp
    ) / 60) as time_diff from cte )a where time_diff<=10

    
--Hard Question ETSY

with cte as (
select s.user_id,s.signup_date ,u.purchase_date from signups s
left join 
(select * from (
select *,
row_number()over(partition by user_id order by purchase_date )as rn 
from user_purchases )a where rn=1)
u on s.user_id=u.user_id)
,total_count as (
select count(1) as total from cte 
),cond_met as (
select * from cte where purchase_date is not null
and purchase_date < signup_date + INTERVAL '7 days'

)
select round(count(*)*100.0/(select total from total_count ),2)as single_purchase_pct
from cond_met


