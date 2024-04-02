--Uber User's Third Transaction [Uber SQL Interview Question]


select user_id,spend,transaction_date from (
select *
,rank()over(partition by user_id order by transaction_date) as rnk
from transactions )a 
where rnk=3

--Snapchat Sending vs. Opening Snaps [Snapchat SQL Interview Question]

with cte as (
select a.*,ab.age_bucket from activities a 
inner join age_breakdown ab on a.user_id=ab.user_id
where a.activity_type!='chat')
select age_bucket,
ROUND((sum(case when activity_type='send' then time_spent else 0 end )/sum(time_spent))*100.0,2) as send_perc
,ROUND((sum(case when activity_type='open' then time_spent else 0 end )/sum(time_spent))*100.0,2) as open_perc
from cte
group by age_bucket

--Tweets' Rolling Averages [Twitter SQL Interview Question]

select user_id,tweet_date
,ROUND(AVG(tweet_count)OVER(partition by user_id order by 
tweet_date rows between 2 preceding and current row),2) as rolling_avg_3d
from tweets 

--Highest-Grossing Items [Amazon SQL Interview Question]

select category,product,total_spend from (
SELECT category,product,sum(spend) as total_spend,
RANK()OVER(partition by category order by SUM(spend) desc)as rnk 
FROM product_spend
where EXTRACT(year from transaction_date)=2022
group by category,product)a where a.rnk IN (1,2)


--Top 5 Artists [Spotify SQL Interview Question]

WITH top_10_cte AS (
  SELECT 
    artists.artist_name,
    DENSE_RANK() OVER (
      ORDER BY COUNT(songs.song_id) DESC) AS artist_rank
  FROM artists
  INNER JOIN songs
    ON artists.artist_id = songs.artist_id
  INNER JOIN global_song_rank AS ranking
    ON songs.song_id = ranking.song_id
  WHERE ranking.rank <= 10
  GROUP BY artists.artist_name
)

SELECT artist_name, artist_rank
FROM top_10_cte
WHERE artist_rank <= 5;

--Signup Activation Rate [TikTok SQL Interview Question]

with cte as (
select e.email_id,e.user_id,t.signup_action from emails e 
left join texts t on e.email_id=t.email_id 
)
select 
round(SUM(case when signup_action='Confirmed' then 1 else 0 end  )*1.0/
(select COUNT(distinct c.email_id) from cte c),2)
from cte 

--Fill Missing Client Data [Accenture SQL Interview Question]

with cte as (
select *,
row_number()over(order by product_id ) as rn 
from products ),final as (
select *
,lead(rn,1,9999999)over(order by product_id)-1 as next_val
from cte where category is not null
)
select c.product_id,f.category,c.name from cte c left join final f on c.rn between f.rn and f.next_val


--Spotify Streaming History [Spotify SQL Interview Question]

with cte as (
select user_id,song_id,song_plays
from songs_history 

UNION ALL

select user_id,song_id,count(1) as total_times_played
from songs_weekly 
where listen_time <'08/05/2022'
group by user_id,song_id)

select user_id,song_id,SUM(song_plays) as song_plays
from cte 
group by user_id,song_id
order by song_plays desc

--Mean, Median, Mode [Microsoft SQL Interview Question]

with means as (
select sum(email_count)/count(DISTINCT user_id) as mean 
from inbox_stats )
, medians as (
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY email_count) 
as median FROM inbox_stats 
)
,modes as (
select email_count,count(1) as cnt from inbox_stats 
group by email_count
)
select means.mean,medians.median,modes.email_count as mode
from modes cross join  means cross JOIN medians
order by cnt desc limit 1  


--Pharmacy Analytics (Part 4) [CVS Health SQL Interview Question]

with cte as (
select *,
row_number()over(partition by manufacturer	order by units_sold desc) as rn 
from pharmacy_sales )
select manufacturer,drug as top_drugs
from cte
where rn in (1,2)
order by manufacturer

--Frequently Purchased Pairs [Walmart SQL Interview Question]

with cte as (
select transaction_id,
STRING_AGG(CAST(product_id as varchar),',' order by product_id) as comb
from transactions 
group by transaction_id
having count(1)>1)
select DISTINCT comb from cte order by comb

--Supercloud Customer [Microsoft SQL Interview Question]

;with cte as (
SELECT * FROM customer_contracts cc 
left join products p on cc.product_id=p.product_id)
,final as (
select customer_id,count(distinct product_category)
from cte 
group by customer_id)
select customer_id from (
select * from final cross join (select count(distinct product_category) as cnt
from products)a)b where count=cnt

--Odd and Even Measurements [Google SQL Interview Question]

with cte as (
select *,measurement_time::date as dates from measurements )
select dates as measurement_day,
SUM(case when rn%2!=0 then measurement_value else 0 end ) as odd_sum,
SUM(case when rn%2=0 then measurement_value else 0 end ) as even_sum
from (
select *,
row_number()over(partition by dates order by measurement_time) as rn 
from cte )a
group by dates

--Booking Referral Source [Airbnb SQL Interview Question]

with cte as (
select b.booking_id,b.user_id,b.booking_date,ba.channel from bookings b 
inner join booking_attribution  ba on b.booking_id=ba.booking_id)
,final as (
select *,row_number()over(PARTITION BY user_id order by booking_date ) 
as rn
from cte )

select channel,
round(count(1)over(partition by channel)*100.0/count(1)over() )as first_booking_pct
from final where rn =1
limit 1

--User Shopping Sprees [Amazon SQL Interview Question]

SELECT DISTINCT T1.user_id
FROM transactions AS T1
INNER JOIN transactions AS T2
  ON DATE(T2.transaction_date) = DATE(T1.transaction_date) + 1
INNER JOIN transactions AS T3
  ON DATE(T3.transaction_date) = DATE(T1.transaction_date) + 2
ORDER BY T1.user_id;

--2nd Ride Delay [Uber SQL Interview Question]

;with cte as (
select u.user_id,u.registration_date,r.ride_id,r.ride_date
from users u 
inner join rides r on u.user_id=r.user_id
),final as (
select *, 
row_number()over(partition by user_id order by registration_date) as rn
from cte 
where user_id in (
select user_id from cte where registration_date = ride_date 
)
)
select 
ROUND(sum(days)*1.0/count(days),2) as average_delay 
from (
select *,
 ride_date-registration_date AS days
from final where rn =2)a

--Histogram of Users and Purchases [Walmart SQL Interview Question]

;with cte as (
select *
,MAX(transaction_date)over(partition by user_id) as latest_date
from user_transactions )
select transaction_date,user_id,count(product_id) as purchase_count
from (
select product_id,user_id,transaction_date
from cte where transaction_date=latest_date)a 
group by transaction_date,user_id
order by transaction_date,user_id,purchase_count

--Google Maps Flagged UGC [Google SQL Interview Question]

;with cte as (
SELECT
  ugc.content_id,
  place.place_name,
  place.place_category
FROM place_info AS place
JOIN maps_ugc_review AS ugc
  ON place.place_id = ugc.place_id
WHERE LOWER(content_tag) = 'off-topic')
select place_category as off_topic_places from (
select  place_category ,rank()over(order by count(1) desc ) as rnk
from cte
group by place_category)a where rnk=1


--Compressed Mode [Alibaba SQL Interview Question]

SELECT item_count  as mode FROM items_per_order
where order_occurrences in (select MAX(order_occurrences) from items_per_order )
order by item_count


--Card Launch Success [JPMorgan Chase SQL Interview Question]
select card_name,issued_amount from (
SELECT *
,row_number()over(PARTITION BY card_name order by 
issue_year,issue_month) as rn 
FROM monthly_cards_issued)A
where a.rn=1
order by issued_amount desc

--International Call Percentage [Verizon SQL Interview Question]
with cte as (
SELECT p.*,cii.country_id as caller_country,rii.country_id
as receiver_country
FROM phone_calls p
left join phone_info  cii on p.caller_id= cii.caller_id
left join phone_info  rii on p.receiver_id= rii.caller_id)
select ROUND(
SUM(case when caller_country!=receiver_country then 1 else 0 end)*100.0/COUNT(1),1) as international_calls_pct
from cte 

--LinkedIn Power Creators (Part 2) [LinkedIn SQL Interview Question]
with cte as (
select ec.personal_profile_id,pp.name,pp.followers p_follower,
ec.company_id,cp.name,cp.followers as c_follower
from employee_company  ec
left join personal_profiles pp on ec.personal_profile_id=profile_id
left join company_pages  cp on ec.company_id=cp.company_id)
,final as (
select * ,
MAX(c_follower)OVER(PARTITION BY personal_profile_id) AS max_c_follower
from cte )
select DISTINCT personal_profile_id as profile_id 
from final 
where p_follower>max_c_follower
order by personal_profile_id

--Unique Money Transfer Relationships [PayPal SQL Interview Question]

with cte as (
select payer_id,recipient_id from payments 
UNION ALL
select recipient_id,payer_id from payments )
select count(1) as unique_relationships from (
select payer_id,recipient_id,count(1) as cnt
from cte 
group by payer_id,recipient_id)A
where cnt>2

--User Session Activity [Twitter SQL Interview Question]

with cte as (
select user_id,session_type,SUM(duration) as total_duration  from sessions 
where start_date>='2022-01-01 12:00:00' and
start_date<='2022-02-01 12:00:00'
group by user_id,session_type
)
select user_id,session_type,
RANK()over(PARTITION BY session_type order by total_duration desc) as rnk 
from cte 

--First Transaction [Etsy SQL Interview Question]

with cte as (
select *,
MIN(transaction_date)over(PARTITION BY user_id) as first_order_date
from user_transactions )
select COUNT(DISTINCT user_id) from cte 
where transaction_date=first_order_date and spend>=50


--Email Table Transformation [Facebook SQL Interview Question]

select user_id,
max(case when email_type='personal' then email end) as personal,
max(case when email_type='business' then email end) as business,
max(case when email_type='recovery' then email end) as business
from users 
group by user_id
order by user_id


--Photoshop Revenue Analysis [Adobe SQL Interview Question]

select customer_id,
SUM(case when product!='Photoshop' then revenue else 0 end) as revenue
from adobe_transactions 
where customer_id in (select DISTINCT customer_id from adobe_transactions
where product='Photoshop'
)
group by customer_id


--Consulting Bench Time [Google SQL Interview Question]

with cte as (
select *,end_date - start_date + 1 number_of_days from staffing s 
inner join consulting_engagements ce 
on s.job_id = ce.job_id and s.is_consultant='true')
select employee_id,365- SUM(number_of_days) as bench_days
from cte 
group by employee_id

--Sales Team Compensation [Oracle SQL Interview Question]

with cte as (
select employee_id,SUM(deal_size) as total_deal
from deals
group by employee_id)
,final as(  
select ec.*,cte.total_deal from cte 
inner join employee_contract ec on cte.employee_id=ec.employee_id )
select 
employee_id,
case when total_deal < quota  then base+commission*total_deal 
when  total_deal >= quota then base + commission*quota + 
accelerator*commission*(total_deal-quota)
end as total_compensation
from final
order by total_compensation desc, employee_id


--Average Deal Size (Part 2) [Salesforce SQL Interview Question]

with cte as (
select customer_id,SUM(num_seats) as seats
,MAX(yearly_seat_cost) as yearly_seat_cost
from contracts
group by customer_id),final as (
select *,
case when seats <100 then 'SMB' 
when seats>=100 and seats <=999 then 'Mid-Market'
when seats >=1000 then 'Enterprise'
end as market_segment
from cte c 
inner join customers cc on c.customer_id=cc.customer_id)
select MAX(smb_avg_revenue)as smb_avg_revenue,
MAX(mid_avg_revenue)as mid_avg_revenue,
MAX(enterprise_avg_revenue)as enterprise_avg_revenue
from 
(select 
floor(SUM(case when market_segment ='SMB' then seats*yearly_seat_cost else 0 end)/
(select count(*) from final where seats <100)) as smb_avg_revenue,
floor(SUM(case when market_segment ='Mid-Market' then seats*yearly_seat_cost else 0 end)/
(select count(*) from final where seats>=100 and seats <=999)) as mid_avg_revenue,
floor(SUM(case when market_segment ='Enterprise' then seats*yearly_seat_cost else 0 end)/
(select count(*) from final where seats >=1000))
as enterprise_avg_revenue
from final 
group by market_segment)a


--Cumulative Purchases by Product Type [Amazon SQL Interview Question]

select order_date,product_type
,SUM(quantity)over(partition by product_type order by order_date)as cum_purchased
from total_trans 
order by order_date


--Invalid Search Results [Google SQL Interview Question]

with cte as (
select *, 
(invalid_result_pct/100.0) * num_search as total_invalid_search 
from search_category 
where num_search is not null AND
invalid_result_pct is not null )

select country,SUM(num_search) as total_search
,ROUND(SUM(total_invalid_search)*100.0/SUM(num_search),2) as invalid_searches_pct
from cte 
group by country
order by country


--Repeat Purchases on Multiple Days [Stitch Fix SQL Interview Question]

select count(DISTINCT user_id ) as repeat_purchasers from (
select 
user_id,product_id ,count(DISTINCT(date(purchase_date))) as cnt
from purchases 
group by user_id,product_id)A
where cnt>=2

--Compensation Outliers [Accenture SQL Interview Question]

;with cte as (
select *
,ROUND(AVG(salary)over(partition by title)) as avg_sal_title
from employee_pay)
select employee_id,salary,comp_flag as status from (
select *,
case when salary >= 2*avg_sal_title then 'Overpaid'
when salary < 0.5*avg_sal_title then 'Underpaid'
else 'normal' end as comp_flag
from cte )a 
where comp_flag in ('Overpaid','Underpaid')

