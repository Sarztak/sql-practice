-- Provided a table with user ID and the dates they visited the platform, find the top 3 users with the longest continuous streak of visiting the platform up to August 10, 2022. Output the user ID and the length of the streak.
-- In case of a tie, display all users with the top three longest streak lengths.

with tb1 as (
select distinct user_id, date_visited from user_streaks
where date_visited <= '2022-08-10'
order by user_id, date_visited
),
tb2 as (
select user_id, date_visited, date_visited - (row_number() over (partition by user_id order by date_visited)::int) as rn from tb1
),
tb3 as (
select user_id, rn, count(*) as streak from tb2
group by user_id, rn
),
tb4 as (
select user_id, max(streak) as max_streak from tb3
group by user_id 
),
tb5 as (
select user_id, max_streak, dense_rank() over (order by max_streak desc) as rn from tb4
)
select user_id, max_streak from tb5
where rn in (1, 2, 3)

------------------------------------------------------------------------------
-- Find the total number of downloads for paying and non-paying users by date. Include only records where non-paying customers have more downloads than paying customers. The output should be sorted by earliest date first and contain 3 columns date, non-paying downloads, paying downloads. 
with tb1 as (
select a.acc_id, a.user_id, c.date, c.downloads from ms_user_dimension a
join ms_download_facts c on a.user_id = c.user_id
),
tb2 as (
select a.acc_id, a.user_id, a.date, a.downloads, b.paying_customer from tb1 a
join ms_acc_dimension b on a.acc_id = b.acc_id
),
tb3 as (
select date, paying_customer,
sum(case when paying_customer = 'yes' then downloads else 0 end) as paying,
sum(case when paying_customer = 'no' then downloads else 0 end) as non_paying
from tb2
group by date, paying_customer
),
tb4 as (
select date, sum(paying) as paying, sum(non_paying) as non_paying from tb3
group by date
order by date
)
select * from tb4
where non_paying > paying
order by date

------------------------------------------------------------------------------
-- You have the marketing_campaign table, which records in-app purchases by users. Users making their first in-app purchase enter a marketing campaign, where they see call-to-actions for more purchases. Find how many users made additional purchases due to the campaign's success.
-- The campaign starts one day after the first purchase. Users with only one or multiple purchases on the first day do not count, nor do users who later buy only the same products from their first day.

with tb1 as (
select user_id, created_at, product_id, 
rank() over (partition by user_id order by created_at) as rn from marketing_campaign
),
tb2 as (
select user_id, created_at, product_id from tb1
where rn = 1
), -- purchases made during the first day
tb3 as (
select user_id, created_at, product_id from tb1
where rn > 1
), -- purchases made during the campaign
tb4 as (
-- for a particular user when products on the campaign days not in first day products that user has made additional purchases so mark that user as yes
select a.user_id,
case when a.product_id not in (
   select b.product_id from tb2 b
   where a.user_id = b.user_id
) then 'yes' else 'no' end as additional_purchase
from tb3 a
)
select count(distinct user_id) as user_count from tb4
where additional_purchase = 'yes'

------------------------------------------------------------------------------
-- Compare each employee's salary with the average salary of the corresponding department.
-- Output the department, first name, and salary of employees along with the average salary of that department.
with tb1 as (
select department, avg(salary) as avg_salary from employee
group by department
)
select a.department, a.first_name, a.salary,
(select b.avg_salary from tb1 b where b.department = a.department) as avg_salary from employee a

------------------------------------------------------------------------------
-- Find the details of each customer regardless of whether the customer made an order. Output the customer's first name, last name, and the city along with the order details.
-- Sort records based on the customer's first name and the order details in ascending order.
select a.first_name, a.last_name, a.city, b.order_details from customers a
left join orders b on a.id = b.cust_id
order by a.first_name, b.order_details

------------------------------------------------------------------------------
-- Find the average number of bathrooms and bedrooms for each city’s property types. Output the result along with the city name and the property type.
select city, property_type, avg(bathrooms), avg(bedrooms) from airbnb_search_details
group by city, property_type
------------------------------------------------------------------------------

------------------------------------------------------------------------------

------------------------------------------------------------------------------

------------------------------------------------------------------------------
