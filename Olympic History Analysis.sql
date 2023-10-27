select * from athlete_events
select * from athletes


--1 which team has won the maximum gold medals over the years.

select top 1  team,count(distinct event) as cnt from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Gold'
group by team
order by cnt desc


--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

with cte as (
select team,year,count(distinct event) as no_of_medals from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Silver'
group by team,year
),maxsilver as (
select *,
row_number()over(partition by team order by no_of_medals desc ) as rn 
from cte 
),tmedals as (
select team,
sum(no_of_medals) as total_medals 
from cte 
group by team
)
select tm.*,ms.year
from tmedals tm inner join maxsilver ms 
on tm.team=ms.team and ms.rn=1
order by tm.total_medals desc ;

--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years
;with cte as (
select a.name,ae.medal
from athlete_events ae inner join athletes a on 
a.id=ae.athlete_id)
select top 1 name ,count(1) max_gold_medals
from cte where name not in (select distinct name from cte where medal in ('Silver','Bronze')) and medal='Gold'
group by name 
order by count(1) desc

--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.

;with cte as (
select a.name,ae.year,COUNT(distinct event) as number_of_medal  from
athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Gold'
group by a.name,ae.year
 ),final as (
 select * from (
select *, RANK()over(partition by year order by number_of_medal desc) as rnk 
from cte)a where a.rnk=1)

select STRING_AGG(name,',') within group (order by name)as player_name , year ,number_of_medal
from final 
group by year ,number_of_medal


--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport
;with cte as (
select *
,MIN(year) over(partition by medal )as medal_year
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id and a.team='India')
select distinct medal,year,event from cte
where year=medal_year and medal!='NA'


--or

select distinct * from (
select medal,year,event,rank() over(partition by medal order by year) rn
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where team='India' and medal != 'NA'
) A
where rn=1

--6 find players who won gold medal in summer and winter olympics both.

select a.name from athlete_events ae 
inner join athletes a on ae.athlete_id=a.id
where medal='Gold'
group by a.name
having count(distinct season)=2

--or

;with cte as (
select a.name,ae.season from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Gold' )
,winter as (
select name from cte where season='Winter' )
,summer as (
select name from cte where season='Summer')
select  distinct * from summer
intersect
select  distinct * from winter

--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

select year,a.name
from athlete_events ae inner join athletes a on ae.athlete_id=a.id
where medal!='NA'
group by year,a.name
having COUNT(distinct medal )=3


--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.
with cte as (
select name,year,event
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where year >=2000 and season='Summer'and medal = 'Gold'
group by name,year,event)
select * from
(select *, lag(year,1) over(partition by name,event order by year ) as prev_year
, lead(year,1) over(partition by name,event order by year ) as next_year
from cte) A
where year=prev_year+4 and year=next_year-4
