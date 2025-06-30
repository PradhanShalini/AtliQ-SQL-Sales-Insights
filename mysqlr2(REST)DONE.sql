select release_year 
,count(*) as movie_count
from movies 
group by release_year
having movie_count>2
order by movie_count desc;

select *, (revenue -budget) as profit from financials;
select 
movie_id,revenue,budget,
if (currency ="usd",revenue*88,revenue) as inr
from financials;

select movie_id,revenue,budget,
case
   when unit="thousands" then revenue/1000 
   when unit="billion" then revenue*1000
   else revenue
   end revenue_mlm
   from financials;
   
select movie_id,
      (revenue-budget) as profit,
     concat((revenue-budget)*100, "%" ) as profit_per
      from financials;
select *,      
      (revenue-budget) as profit,
      (revenue-budget)*100/budget as profit_per
      
         from financials;
      