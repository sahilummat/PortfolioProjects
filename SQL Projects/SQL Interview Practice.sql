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


Amazon Medium Question 

select order_date,product_type,cum_purchased from (
    select * 
    ,sum(quantity)over(partition  by product_type order by order_date)as cum_purchased
    from total_trans )a
order by order_date

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


