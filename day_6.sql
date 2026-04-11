-- dentify all products that experienced a turnaround in user engagement: at least 3 consecutive months of declining monthly active users followed by at least 3 consecutive months of growth.


-- For each product that matches this pattern, return the product name, the month when the decline started, the month when growth resumed, and the growth ratio from the lowest point to the most recent peak, calculated as: (peak_users - lowest_users) / lowest_users.

with tb1 as (
select *, row_number() over (partition by product_name order by month_start) as rn, monthly_active_users - lag(monthly_active_users) over (partition by product_name order by month_start) as diff from product_engagement
),
tb2 as (
select *,
case 
    when diff > 0 then 1
    when diff < 0 then -1
    else 0
end as sign from tb1
),
tb3 as (
select *,  rn - row_number() over (partition by product_name, sign order by month_start, sign) as rn_diff from tb2
),
tb4 as (
select product_name, sign, rn_diff, min(month_start) as start_run, max(month_start) as end_run, count(*) as run_len, min(monthly_active_users) as lowest_users, max(monthly_active_users) as peak_users from tb3
group by product_name, sign, rn_diff
),
tb5 as (
select a.product_name, a.start_run as decline_start_month, a.end_run as growth_resume_month, b.start_run, b.end_run, a.lowest_users, b.peak_users
from tb4 a
join (
select product_name, start_run, end_run, peak_users from tb4
where sign = 1 and run_len > 2
) b on a.product_name = b.product_name
where a.sign = -1 and a.run_len > 2 and a.end_run + interval '1 month' = b.start_run
),
tb6 as (
select product_name, decline_start_month, growth_resume_month, (peak_users - lowest_users)::float / lowest_users::float as growth_ratio from tb5
)
select * from product_engagement
where product_name = 'Instagram Reels'

--------------------------------------------------------------------


-- Calculate the daily ratio of posts removed by reviewers to posts reported by users. For each date in the dataset range, count unique posts reported (multiple reports of the same post count as one) and how many of those were removed the same day.


-- For dates with reported posts but no removals, show zero for removal metrics. Calculate removal ratio as removed posts divided by reported posts. Output the date, number of reported posts, number of removed posts, and the removal ratio.

with tb1 as (
select distinct a.post_id, a.date, b.reason, b.removal_date from user_actions a
left join post_removals b on a.post_id = b.post_id
where action = 'report'
), -- join by the post_id so that we know which posts were removed and filter by reported ones only and also keep only the unique posts
tb2 as (
select date, count(*) n_posts from tb1
group by date
), -- group by date to find the number of reported posts
tb3 as (
select date, sum(case when removal_date is not null then 1 else 0 end) as n_removed from tb1
group by date
), -- find how many posts were removed the same date
tb4 as (
select a.date, a.n_posts, b.n_removed from tb2 a 
join tb3 b on a.date = b.date
) -- join the tables together
select *, n_removed::float / n_posts::float as removed_ratio from tb4