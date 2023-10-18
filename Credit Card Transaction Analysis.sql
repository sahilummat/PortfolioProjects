select * from credit_card_transcations

-- DATA EXPLORATION 

--1. Which cities data do we have and also for how many cities do we have the data 

select distinct city from credit_card_transcations

select count(distinct city) from credit_card_transcations 

--2. Max ,Min and avg amount of transactions done .
select Max(amount) as max_amount,min(amount)as min_amount,avg(cast(amount as bigint))as avg_amount from credit_card_transcations

--3. What are the different card types and what is the perctange each card contributes to the total use 
;with data as (
select card_type,
count(1)over(partition by card_type order by card_type) as cards
,count(1)over() as total,
round(count(1)over(partition by card_type order by card_type)*100.0/count(1)over(),2) as percentage
from credit_card_transcations
)
select distinct * from data 

--4 which genders use the card more 
select gender, count(1)
from credit_card_transcations
group by gender 

--5 top 5 cities using credit cards
select top 5  city, count(1) as cnt
from credit_card_transcations
group by city 
order by cnt desc 

--6 Purpose the cards are used for 

select exp_type, count(1) as cnt
from credit_card_transcations
group by exp_type 
order by cnt desc 

--solve below questions
--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

;with data as (
select city ,
cast(sum(amount)over(partition by city order by city )as bigint) as city_wise_spend,
cast (sum(amount)over(order by city rows between unbounded preceding and unbounded following  ) as bigint)as total_spend
from credit_card_transcations)
,final as (
select distinct * from data)
select top 5 city,city_wise_spend,
(city_wise_spend*100.0/total_spend) as percent_of_total
from final
order by city_wise_spend desc 

--2- write a query to print highest spend month and amount spent in that month for each card type
;with data as (
select  card_type,DATEPART(year,transaction_date) as yr,DATEPART(month,transaction_date) as mnth,SUM(amount)  as amount_spend
from credit_card_transcations
group by card_type,DATEPART(year,transaction_date) ,DATEPART(month,transaction_date)
)
select card_type,yr,mnth,amount_spend
from (select *,
ROW_NUMBER()over(partition by card_type order by amount_spend desc) as rn 
from data)a where a.rn=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with data as (
select * 
,SUM(amount)over(partition by card_type order by transaction_date, transaction_id ) as rn_sum
from credit_card_transcations
)
select * from(
select *, ROW_NUMBER()over(partition by card_type order by rn_sum) as rn from data 
where rn_sum>=1000000)a where a.rn=1

--4- write a query to find city which had lowest percentage spend for gold card type
with data as (
select  * from credit_card_transcations where card_type='Gold')
select top 1 *,
sum(amount)over(partition by city) as city_wise_spend,
sum(amount)over(order by city rows between unbounded preceding and unbounded following ) as total_spend
,sum(amount)over(partition by city)*100.0/sum(amount)over(order by city rows between unbounded preceding and unbounded following ) as percent_spend
from data
order by percent_spend

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
;with data as (
select city,exp_type,SUM(amount) as spend from credit_card_transcations
group by city ,exp_type)
,highest_expense_type as (
select city,exp_type as highest_exp_type from (
select *,ROW_NUMBER()over(partition by city order by spend desc) as rn 
from data)a where a.rn=1
)
,lowest_expense_type as (
select city,exp_type as lowest_exp_type from (
select *,ROW_NUMBER()over(partition by city order by spend ) as rn 
from data)a where a.rn=1
)
select h.city,h.highest_exp_type,l.lowest_exp_type from highest_expense_type h inner join lowest_expense_type l
on h.city=l.city

--6- write a query to find percentage contribution of spends by females for each expense type
with data as (
select gender,exp_type,SUM(amount)as female_spend
from credit_card_transcations
where gender='F'
group by gender,exp_type)
select gender,d.exp_type,female_spend*1.0/a.total_spend as perc_spend
from data d  inner join (select exp_type,sum(amount) as total_spend from credit_card_transcations group by exp_type )a 
on d.exp_type=a.exp_type

--7- which card and expense type combination saw highest month over month growth in Jan-2014
with data as (
select card_type,exp_type,YEAR(transaction_date)as yr,Month(transaction_date)as mnth,sum(amount) as spend
from credit_card_transcations
group by card_type,exp_type,YEAR(transaction_date),Month(transaction_date) )
select top 1 *,spend-prev_spend as momgrowth 
from (
select *, lag(spend)over(partition by card_type,exp_type order by yr,mnth) as prev_spend
from data)a
where yr=2014 and mnth=1 and prev_spend is not null
order by momgrowth desc

--8- during weekends which city has highest total spend to total no of transcations ratio 


select top 1 city,SUM(amount)*1.0 /count(1) as spend_trans_ratio
from credit_card_transcations 
where datepart(weekday,transaction_date) in (1,7)
group by city
order by spend_trans_ratio desc 

--10- which city took least number of days to reach its 500th transaction after the first transaction in that city

;with data as (
select *
,ROW_NUMBER()over(partition by city order by transaction_date) as rn,
count(1)over(partition by city) as ttl_cnt
from credit_card_transcations)
select top 1 city ,no_days from (
select *
,LAG(transaction_date,1) over(partition by city order by rn ) as first_trans_date,
DATEDIFF(day,LAG(transaction_date,1) over(partition by city order by rn ),transaction_date) as no_days
from data where rn in (1,500) and ttl_cnt>=500)a
where a.no_days is not null 
order by a.no_days

