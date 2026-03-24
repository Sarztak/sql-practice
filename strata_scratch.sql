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

with temp_table as (
select *, rank() over (partition by order_date order by total_order_cost desc) from orders 
where order_date between '2019-02-01' and '2019-05-01')
select c.first_name, total_order_cost, order_date from temp_table
join customers c on c.id = cust_id
where rank = 1
order by order_date;


-- ============================================================
-- PROBLEM 2
-- Calculate the net change in the number of products launched
-- by companies in 2020 compared to 2019. Your output should
-- include the company names and the net difference.
-- (Net difference = Number of products launched in 2020
-- - The number launched in 2019.)
-- ============================================================

with total_prod as (
select year, company_name, count(*) as total_products from car_launches
where year in (2019, 2020)
group by company_name, year
),
net_prod as (
select company_name, total_products - lag(total_products) over (partition by company_name order by year) as net_products from total_prod
order by company_name
)
select * from net_prod where net_products is not null;


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


-- ============================================================
-- PROBLEM 6
-- Find wineries producing wines with aromas of plum, cherry,
-- rose, or hazelnut (singular form only). To make things
-- simpler, exclude any wine descriptions that contain the
-- plural forms (ex. cherries).
-- ============================================================

select winery from winemag_p1
where description like '% plum %' or
description like '% cherry %' or
description like '% rose %' or
description like '% hazelnut %';


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