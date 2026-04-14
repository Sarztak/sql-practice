-- Identify returning active users by finding users who made a repeat purchase within 7 days or less of their previous transaction, excluding same-day purchases. Output a list of these user_id.

with tb1 as (
select user_id, created_at - lag(created_at) over (partition by user_id order by created_at) as diff from amazon_transactions
)
select distinct(user_id) from tb1
where diff between 1 and 7
-- between is inclusive on both the ends
-- within 7 days means the difference can be 1, 2, 3, 4, 5, 6, 7 
-- so the 7th day is included.

-----------------------------------------------------------------------------

-- You're analyzing employee performance at a customer support center. Management wants to identify which support agents are providing the best customer experience based on satisfaction scores.


-- Rank employees by their average customer satisfaction score for resolved tickets. Return the top 3 ranks, where ranks should be consecutive and should not skip numbers even if there are ties. For example, if the scores are [4.9, 4.7, 4.7, 4.5], the rankings would be [1, 2, 2, 3].


-- Return the employee ID, employee name, average satisfaction score, and employee rank.

with tb1 as (
select employee_id, employee_name, avg(customer_satisfaction) as avg_rating from amazon_support_tickets
where resolution_status = 'resolved'
group by employee_id, employee_name
),
tb2 as (
select *, dense_rank() over (order by avg_rating desc) as rnk from tb1
)
select * from tb2
where rnk < 4 

-- dense_rank does not skip values and rank does but both gives same values to same number so rank can be 1, 2, 2, 4 but dense_rank will be 1, 2, 2, 3

----------------------------------------------------------------------------------

-- Management wants to identify the most popular products within each category to optimize inventory and marketing strategies. Find the top 2 products with the highest total quantity sold in each category. If products within a category have the same total quantity, order them alphabetically by product name and assign consecutive ranks (1, 2, 3, etc.).


-- For example, if two products in the Electronics category both sold 15 units, then iPad Pro would get rank 1 (alphabetically first) and iPhone 14 would get rank 2 (alphabetically second).


-- Return the category, product name, total quantity sold, and rank within category. You should expect maximum 2 products per category in your results, though some categories might only have 1 product available.

with tb1 as (
select category, product_name, sum(quantity) as total_quantity_sold from ecommerce_transactions
group by category, product_name
),
tb2 as (
select category, product_name, total_quantity_sold, rank() over (partition by category order by total_quantity_sold desc, product_name) as rnk
from tb1
)
select * from tb2
where rnk < 3

-- don't forget to put desc

-----------------------------------------------------------------------------

-- You are monitoring a system where pages can be turned on or off at different times. The page status log records every state change event for each page. Find the number of pages that are currently active based on their most recent status change. Return the count of currently active pages.

select count(a.status) as active_page_count from page_status_log a
join (
select page_id, max(changed_at) as latest_change_date from page_status_log
group by page_id
) as b on a.page_id = b.page_id and a.changed_at = b.latest_change_date
where a.status = 'on'

