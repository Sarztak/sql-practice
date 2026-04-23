-- ============================================================
-- SQL Practice Problems & Solutions
-- ============================================================


-- ------------------------------------------------------------
-- 1. Find the total cost of each customer's orders.
--    Output customer's id, first name, and the total order cost.
--    Order records by customer's first name alphabetically.
-- ------------------------------------------------------------
with tb1 as (
    select cust_id, sum(total_order_cost) as total_order_cost from orders
    group by cust_id
)
select a.cust_id, b.first_name, a.total_order_cost from tb1 a
join customers b on a.cust_id = b.id
order by b.first_name;


-- ------------------------------------------------------------
-- 2. Write a query that returns the user ID of all users that
--    have created at least one 'Refinance' submission and at
--    least one 'InSchool' submission.
-- ------------------------------------------------------------
with tb1 as (
    select user_id,
    sum(case when type = 'Refinance' then 1 else 0 end) as count_Refinance,
    sum(case when type = 'InSchool' then 1 else 0 end) as count_InSchool
    from loans
    group by user_id
)
select user_id from tb1
where count_Refinance >= 1 and count_InSchool >= 1;


-- ------------------------------------------------------------
-- 3. Identify returning active users by finding users who made
--    a second purchase within 1 to 7 days after their first
--    purchase. Ignore same-day purchases.
--    Output a list of these user_ids.
-- ------------------------------------------------------------
with tb1 as (
    select user_id, created_at from amazon_transactions
    group by user_id, created_at
),
tb2 as (
    select *, created_at - lag(created_at) over (partition by user_id order by created_at) as diff,
    row_number() over (partition by user_id order by created_at)
    from tb1
),
tb3 as (
    select user_id, min(diff) as min_days_diff from tb2
    where row_number = 2
    group by user_id
)
select user_id from tb3
where min_days_diff between 1 and 7;


-- ------------------------------------------------------------
-- 4. Calculate the friend acceptance rate for each date when
--    friend requests were sent. A request is sent if action =
--    'sent' and accepted if action = 'accepted'. Only include
--    dates where requests were sent and at least one was accepted.
-- ------------------------------------------------------------
with tb1 as (
    select user_id_sender, user_id_receiver,
    sum(case when action = 'sent' then 1 else 0 end) as sent,
    sum(case when action = 'accepted' then 1 else 0 end) as accepted
    from fb_friend_requests
    group by user_id_sender, user_id_receiver
),
tb2 as (
    select a.user_id_sender, a.user_id_receiver, a.date, b.sent, b.accepted from fb_friend_requests a
    join tb1 b on a.user_id_sender = b.user_id_sender and a.user_id_receiver = b.user_id_receiver
    where action = 'sent'
)
select date, sum(accepted) / sum(sent) as acceptance_rate from tb2
group by date;


-- ------------------------------------------------------------
-- 5. Calculate each user's average session time, where a session
--    is the time difference between a page_load and page_exit.
--    Assume each user has only one session per day. Use the latest
--    page_load and earliest page_exit per day. Only consider
--    sessions where page_load occurs before page_exit.
--    Output user_id and their average session time.
-- ------------------------------------------------------------
with tb1 as (
    select user_id,
    max(case when action = 'page_load' then timestamp else null end) as page_load,
    min(case when action = 'page_exit' then timestamp else null end) as page_exit
    from facebook_web_log
    where action in ('page_load', 'page_exit')
    group by user_id, timestamp::date
),
tb2 as (
    select *, page_exit - page_load as diff from tb1
    where page_load < page_exit
)
select user_id, avg(diff) as avg_diff from tb2
group by user_id;

--second attempt to learn something new 
select user_id, avg(session_time) as avg_session_time from 
(
select user_id, to_char(timestamp, 'yyyy-mm-dd') as date_time, 
min(case when action = 'page_exit' then timestamp end) -
max(case when action = 'page_load' then timestamp end) as session_time
from facebook_web_log
group by 1, 2
) as tb1
where extract(epoch from session_time) > 0
group by user_id


-- ------------------------------------------------------------
-- 6. Find the base pay for Police Captains.
--    Output the employee name along with the corresponding base pay.
-- ------------------------------------------------------------
select employeename, basepay from sf_public_salaries
where jobtitle ilike '%captain%';


-- ------------------------------------------------------------
-- 7. Find the genre of the person with the most number of oscar
--    winnings. If there are more than one person with the same
--    number of oscar wins, return the first one alphabetically.
--    Use the names as keys when joining the tables.
-- ------------------------------------------------------------
with tb1 as (
    select nominee, sum(winner::int) as total_wins from oscar_nominees
    group by nominee
),
tb2 as (
    select *, rank() over (order by total_wins desc) as rnk from tb1
),
tb3 as (
    select nominee, total_wins, top_genre from tb2
    join nominee_information on nominee = name
    where rnk = 1
)
select top_genre from tb3;


-- ------------------------------------------------------------
-- 8. Return the total number of comments received for each user
--    in the 30-day period up to and including 2020-02-10.
--    Don't output users who haven't received any comments in
--    the defined time period.
-- ------------------------------------------------------------
with tb1 as (
    select user_id, sum(number_of_comments) as total_comments from fb_comments_count
    where created_at between '2020-02-10'::date - interval '29 days' and '2020-02-10'
    group by user_id
)
select * from tb1
where total_comments > 0
order by total_comments desc;


-- ------------------------------------------------------------
-- 9. Find the longest streak of wins for tennis players.
--    A streak is a set of consecutive won matches of one player.
--    The streak ends once a player loses their next match.
--    Disregard edge cases such as players who never lose.
-- ------------------------------------------------------------
with tb1 as (
    select *,
    case when match_result = 'L' then 1 else 0 end as col
    from players_results
),
tb2 as (
    select *, sum(col) over (partition by player_id order by match_date) as cum_sum from tb1
),
tb3 as (
    select player_id, count(col) - 1 as ans from tb2
    group by player_id, cum_sum
),
tb4 as (
    select player_id, max(ans) max_streak from tb3
    group by player_id
),
tb5 as (
    select player_id, max_streak, rank() over (order by max_streak desc) as rnk from tb4
)
select player_id, max_streak from tb5
where rnk = 1;


-- ------------------------------------------------------------
-- 10. For each actor, calculate the difference between the rating
--     of their most recent film and their average rating across
--     all previous films (excluding the most recent one).
--     Return actor name, average lifetime rating, latest film
--     rating, and the difference rounded to 2 decimal places.
--     If an actor has only one film, return 0 for the difference
--     and their only film's rating for both average and latest.
-- ------------------------------------------------------------
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
select actor_name,
    round(avg_rating::numeric, 2),
    round(latest_rating::numeric, 2),
    round((latest_rating - avg_rating)::numeric, 2) as rating_difference
from tb5
order by actor_name;