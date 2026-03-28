-- You are given a set of projects and employee data. Each project has a name, a budget, and a specific duration, while each employee has an annual salary and may be assigned to one or more projects for particular periods. The task is to identify which projects are overbudget. A project is considered overbudget if the prorated cost of all employees assigned to it exceeds the project’s budget.
-- To solve this, you must prorate each employee's annual salary based on the exact period they work on a given project, relative to a full year. For example, if an employee works on a six-month project, only half of their annual salary should be attributed to that project. Sum these prorated salary amounts for all employees assigned to a project and compare the total with the project’s budget.
-- Your output should be a list of overbudget projects, where each entry includes the project’s name, its budget, and the total prorated employee expenses for that project. The total expenses should be rounded up to the nearest dollar. Assume all years have 365 days and disregard leap years.

select a.*, b.salary from tb1 a
join linkedin_employees b on a.emp_id = b.id
),
tb3 as (
    select project_id, title, budget,
   ceil(sum(salary::numeric * (end_date - start_date) / 365)) as prorated_cost
    from tb2
    group by project_id, title, budget
)
select title, budget, prorated_cost from tb3
where budget < prorated_cost

----------------------------------------------------------------------------

-- For the video (or videos) that received the most user flags, how many of these flags were reviewed by YouTube? Output the video ID and the corresponding number of reviewed flags.  Ignore flags that do not have a corresponding flag_id.

with tb1 as (
select a.video_id, a.flag_id, b.reviewed_by_yt from user_flags a
join flag_review b on a.flag_id = b.flag_id
),
tb2 as (
select video_id, count(flag_id) as cnt from tb1
group by video_id
),
tb3 as (
select video_id from tb2
where cnt = (select max(cnt) from tb2)
),
tb4 as (
select video_id, flag_id, reviewed_by_yt from tb1
where video_id in (select video_id from tb3)
)
select video_id, sum(reviewed_by_yt::int) as n_reviewed from tb4

----------------------------------------------------------------------------

-- Write a query that identifies cities with higher than average home prices when compared to the national average. Output the city names.

with tb1 as (
select avg(mkt_price) as national_avg from zillow_transactions
),
tb2 as (
select city, avg(mkt_price) as city_avg from 
zillow_transactions
group by city
)
select city from tb2
where city_avg > (select national_avg from tb1)

----------------------------------------------------------------------------

