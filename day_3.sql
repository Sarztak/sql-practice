-- Find the last time each bike was in use. Output both the bike number and the date-timestamp
-- of the bike's last use (i.e., the date-time the bike was returned).
-- Order the results by bikes that were most recently used.
with tb1 as (
    select bike_number, max(end_time) as end_time from dc_bikeshare_q1_2012
    group by bike_number
)
select * from tb1
order by end_time desc;


-- Find libraries from the 2016 circulation year that have no email address provided
-- but have their notice preference set to email. Output their home library code.
select home_library_code from library_usage
where notice_preference_definition = 'email'
and not provided_email_address;


-- Given users' session logs, calculate how many hours each user was active in total
-- across all recorded sessions.
-- Note: The session starts when state=1 and ends when state=0.
with tb1 as (
    select *, lead(timestamp) over (partition by cust_id order by timestamp) as lead1
    from cust_tracking
),
tb2 as (
    select cust_id, lead1 - timestamp as diff from tb1
    where state != 0
)
select cust_id, sum(diff) / (60 * 60) as diff_in_hr from tb2
group by cust_id;


-- Given a table of purchases by date, calculate the month-over-month percentage change
-- in revenue. The output should include the year-month date (YYYY-MM) and percentage change,
-- rounded to the 2nd decimal point, and sorted from the beginning of the year to the end of
-- the year. The percentage change column will be populated from the 2nd month forward and
-- can be calculated as ((this month's revenue - last month's revenue) / last month's revenue)*100.
with tb1 as (
    select extract('year' from created_at) as year, extract('month' from created_at) as month, value
    from sf_transactions
),
tb2 as (
    select year, month, sum(value) as monthly_total from tb1
    group by year, month
),
tb3 as (
    select *, lag(monthly_total) over (order by year, month) as lag1 from tb2
),
tb4 as (
    select
        (monthly_total - lag1) / lag1 * 100 as pct_monthly_change,
        concat(year, '-', lpad(month::text, 2, '0')) as ym
    from tb3
)
select ym, pct_monthly_change from tb4;


-- Management wants to analyze only employees with official job titles. Find the job titles
-- of the employees with the highest salary. If multiple employees have the same highest
-- salary, include all their job titles.
with tb1 as (
    select a.worker_id, a.salary, b.worker_title from worker a
    join title b on a.worker_id = b.worker_ref_id
),
tb2 as (
    select worker_title, rank() over (order by salary desc) as rnk from tb1
)
select worker_title from tb2
where rnk = 1;