-- ============================================================
-- STRATASCRATCH SQL PRACTICE
-- ============================================================


-- ============================================================
-- PROBLEM 1
-- Find the customers with the highest daily total order cost
-- between 2019-02-01 and 2019-05-01. If a customer had more
-- than one order on a certain day, sum the order costs on a
-- daily basis. Output each customer's first name, total cost
-- of their items, and the date. If multiple customers tie for
-- the highest daily total on the same date, return all of them.
-- ============================================================

with daily_totals as (
select cust_id, order_date, sum(total_order_cost) as max_cost from orders
where order_date between '2019-02-01' and '2019-05-01'
group by 1, 2
),
ranked as (
select *, rank() over (partition by order_date order by max_cost desc) as rnk from daily_totals
)
select c.first_name, r.order_date, r.max_cost from ranked r
join customers c on c.id = r.cust_id
where r.rnk = 1
order by r.order_date

-- ============================================================
-- PROBLEM 2
-- Calculate the net change in the number of products launched
-- by companies in 2020 compared to 2019. Your output should
-- include the company names and the net difference.
-- (Net difference = Number of products launched in 2020
-- - The number launched in 2019.)
-- ============================================================

select company_name,
count(distinct case when year = 2020 then product_name end) - 
count(distinct case when year = 2019 then product_name end) as diff from car_launches
group by company_name

-- ============================================================
-- PROBLEM 3
-- Find all the users who were active for 3 consecutive days
-- or more.
-- ============================================================

with lag_tb as (
select *, record_date - lag(record_date) over (partition by user_id order by record_date) as lag_1,
    record_date - lag(record_date, 2) over (partition by user_id order by record_date) as lag_2 from sf_events
),
lag_12 as (
select *, lag_1 - lag(lag_1) over (partition by user_id order by record_date) as lag_11 from lag_tb
)
select user_id from lag_12
where lag_11 = 0 and lag_2 = 2;

-- update to how I solved the second time
select user_id from 
(
select user_id, record_date - (row_number() over (partition by user_id order by record_date))::int as diff from sf_events
) as tb1
group by user_id, diff
having count(diff) >= 3

-- ============================================================
-- PROBLEM 4
-- Find the best-selling item for each month (no need to
-- separate months by year). The best-selling item is
-- determined by the highest total sales amount, calculated
-- as: total_paid = unitprice * quantity. A negative quantity
-- indicates a return or cancellation (the invoice number
-- begins with 'C'). To calculate sales, ignore returns and
-- cancellations. Output the month, description of the item,
-- and the total amount paid.
-- ============================================================

with tb1 as (
select extract(month from invoicedate) as month, description, sum(unitprice*quantity) as total_paid from online_retail
where invoiceno not like 'C%'
group by extract(month from invoicedate), description
),
tb2 as (
select description, month, rank() over (partition by month order by total_paid desc) as rnk, total_paid from tb1
)
select month, description, total_paid from tb2
where rnk = 1;


-- ============================================================
-- PROBLEM 5
-- Compare the total number of comments made by users in each
-- country during December 2019 and January 2020. For each
-- month, rank countries by their total number of comments in
-- descending order. Countries with the same total should share
-- the same rank, and the next rank should increase by one
-- (without skipping numbers). Return the names of the
-- countries whose rank improved from December to January
-- (that is, their rank number became smaller).
-- ============================================================

with tb1 as (
select * from fb_comments_count
where created_at between '2019-12-01' and '2020-01-31'
),
tb2 as (
select t.created_at, t.number_of_comments, t.user_id, u.country from tb1 t
join fb_active_users u on t.user_id = u.user_id
),
tb3 as (
select sum(number_of_comments) as total_comments, extract(month from created_at)::int as month, country from tb2
group by country, month
order by country, month desc
),
tb4 as (
select country, month, total_comments, dense_rank() over (partition by month order by total_comments desc) as rnk from tb3
),
tb5 as (
select country, rnk - lag(rnk) over (partition by country order by month desc) as rnk_diff from tb4 
)
select country from tb5
where rnk_diff < 0;

--updated attempt 2
with tb1 as (
select b.country, extract('year' from  a.created_at) as year,
sum(a.number_of_comments) as total_comments
from fb_comments_count a
join fb_active_users b on a.user_id = b.user_id
where a.created_at between '2019-12-01' and '2020-01-31'
group by 1, 2
),
tb2 as (
select country, year, dense_rank() over (partition by year order by total_comments desc) as rnk from tb1
)
select country from tb2
group by country
having max(case when year = 2020 then rnk end) < max(case when year = 2019 then rnk end)
-- earlier I had used then 0 which cause an error because Canada had no comments for the year 2020 and gave me a false position because of the comparision between 0 for year 2020 and its non-zero rank for year 2019

-- ============================================================
-- PROBLEM 6
-- Find wineries producing wines with aromas of plum, cherry,
-- rose, or hazelnut (singular form only). To make things
-- simpler, exclude any wine descriptions that contain the
-- plural forms (ex. cherries).
-- ============================================================

select winery from winemag_p1
where description ilike '% plum %' or
description ilike '% cherry %' or
description ilike '% rose %' or
description ilike '% hazelnut %';


-- ============================================================
-- PROBLEM 7
-- Find the 3-month rolling average of total revenue from
-- purchases given a table with users, their purchase amount,
-- and date purchased. Do not include returns which are
-- represented by negative purchase values. Output the
-- year-month (YYYY-MM) and 3-month rolling average of
-- revenue, sorted from earliest month to latest month.
-- A 3-month rolling average is defined by calculating the
-- average total revenue from all user purchases for the
-- current month and previous two months. The first two months
-- will not be a true 3-month rolling average since we are not
-- given data from last year. Assume each month has at least
-- one purchase.
-- ============================================================

with tb as (
select extract(year from created_at) as year, extract(month from created_at) as month, sum(purchase_amt) as total_sales from amazon_purchases
where purchase_amt > 0
group by year, month
order by year, month
),
tb2 as (
select year, month, avg(total_sales) over (order by year, month rows between 2 preceding and current row) as rolling_avg, concat(year::text, '-', lpad(month::text, 2, '0')) as year_month from tb
offset 2
)
select year_month, rolling_avg from tb2;

-- =======================================================================

-- Calculates the difference between the highest salaries in the marketing and engineering departments. Output just the absolute difference in salaries.

select
    abs(
        max(case when b.department = 'engineering' then a.salary end) - 
        max(case when b.department = 'marketing' then a.salary end)
    ) as abs_diff from db_employee a
join db_dept b on a.department_id = b.id

-- ==========================================================================

-- We have a table with employees and their salaries; however, some of the records are old and contain outdated salary information. Since there is no timestamp, assume salary is non-decreasing over time. You can consider the current salary for an employee is the largest salary value among their records. If multiple records share the same maximum salary, return any one of them. Output their id, first name, last name, department ID, and current salary. Order your list by employee ID in ascending order.
-- this is an easy question but I still spend time on it because of my assumption which were totally wrong. I just grouped by id, departmen_id, first_name, last_name and assumed that every record is unique but then there was one record where department_id was different for the same employee. The valid approach is quite simple don't assume things

with tb1 as (
select *, rank() over (partition by id order by salary desc) as rnk from ms_employee_salary
)
select id, first_name, last_name, department_id, salary from tb1
where rnk = 1