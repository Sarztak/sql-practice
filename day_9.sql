-- You are given a dataset of actors and the films they have been involved in, including each film's release date and rating. For each actor, calculate the difference between the rating of their most recent film and their average rating across all previous films (the average rating excludes the most recent one).


-- Return a list of actors along with their average lifetime rating, the rating of their most recent film, and the difference between the two ratings. Round the difference calculation to 2 decimal places. If an actor has only one film, return 0 for the difference and their only film’s rating for both the average and latest rating fields.

with tb1 as (
select actor_name, film_rating, rank() over (partition by actor_name order by release_date desc) as rnk from actor_rating_shift
),
tb2 as (
select actor_name, sum(film_rating) as total_rating, count(actor_name) as cnt from tb1
group by actor_name
),
tb3 as (
select actor_name, film_rating as latest_rating from tb1
where rnk = 1
),
tb4 as (
select a.actor_name, a.latest_rating, b.total_rating, b.cnt from tb3 a
join tb2 b on a.actor_name = b.actor_name
),
tb5 as (
select actor_name, 
case when cnt > 1 then (total_rating - latest_rating) / (cnt - 1) else latest_rating end as avg_rating,
latest_rating from tb4
)
select actor_name, round(avg_rating::numeric, 2), round(latest_rating::numeric, 2), round((latest_rating - avg_rating)::numeric, 2) as rating_difference from tb5
order by actor_name

-- attempt 2: when I tried to do this again, I took a different approach and learned new thing. When I used inner join, in case if there was just one row the condidtion rn != 1 failed and therefore there were no rows to group by hence group by didn't include the keys, hence the inner join found no keys to match on, hence the results were there was just one film was totally excluded. The solution was simply to use left join

tb2 as (
select a.actor_name, a.film_rating as latest_film_rating, b.avg_film_rating from tb1 a
left join (
select actor_name, avg(film_rating) as avg_film_rating from tb1
where rn != 1
group by actor_name
) b on a.actor_name = b.actor_name
where rn = 1
)
select actor_name, latest_film_rating,
(
case when avg_film_rating is not NULL then avg_film_rating else latest_film_rating end 
) as avg_film_rating,
round(
(
case when avg_film_rating is not NULL then avg_film_rating - latest_film_rating else 0 end)::numeric
, 2) as diff 
from tb2