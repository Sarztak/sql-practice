-- Calculate the search success rate for new users versus existing users. A successful search is one where the first click event occurs within 30 seconds of the search event.


-- Group all users into two segments:
-- •  new (registered within the last 30 days covered by the dataset — that is, on or after 30 days before the most recent date in the dataset)
-- •  existing (registered earlier).


-- Return one row per user segment with total searches, successful searches, and success rate.

with tb1 as (
select a.user_id, a.session_id, a.query, a.event_timestamp as search_time, b.event_timestamp as click_time, c.registration_date,
case when c.registration_date <= (select max(registration_date) from accounts) - interval '30 days' then 'existing' else 'new' end as user_status,
case when b.event_timestamp between a.event_timestamp and a.event_timestamp + interval '30 seconds' then 'successful' else 'unsuccessful' end as search_status
from search_events a
join (
select user_id, session_id, query, event_timestamp, event_type from search_events
where event_type = 'click'
) b on a.user_id = b.user_id
join (
select user_id, registration_date from accounts
) c on a.user_id = c.user_id
where a.session_id = b.session_id and a.query = b.query and a.event_type = 'search'
),
tb2 as (select user_status, count(*) as successful_searches from tb1 where search_status = 'successful' group by user_status),
tb3 as (select user_status, count(*) as total_searches from tb1 group by user_status)
select a.*, b.total_searches, a.successful_searches::float / b.total_searches::float as success_rate from tb2 a
join tb3 b on a.user_status = b.user_status


-- Amazon tracks orders through multiple stages from placement to delivery. Each order has three key dates: when it was ordered, when it was shipped, and when it was received by the customer.


-- Create a weekly report showing how many orders are in their latest new status for that week, with weeks starting on Monday. An order should be counted from its order week through its delivery week only. Before shipment it counts as pending; after shipment and before delivery it counts as shipped; in the week it is received it counts as delivered. Do not continue counting delivered orders in subsequent weeks.

with tb1 as (
select order_id,
generate_series(
    date_trunc('week', ordered_date),
    date_trunc('week', delivered_date),
    interval '7 days'
) as week_start_date from shipment_tracking
),
tb2 as (
select b.week_start_date,
case
    when date_trunc('week', a.delivered_date) = b.week_start_date then 'delievered'
    when date_trunc('week', a.shipped_date) <= b.week_start_date then 'shipped'
    else 'pending'
end as order_status from shipment_tracking a
join tb1 b on a.order_id = b.order_id
)
select week_start_date,
sum(case when order_status = 'delievered' then 1 else 0 end) as delievered_orders,
sum(case when order_status = 'shipped' then 1 else 0 end) as shipped_orders,
sum(case when order_status = 'pending' then 1 else 0 end) as pending_orders
from tb2
group by week_start_date
order by week_start_date