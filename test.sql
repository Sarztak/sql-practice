with ranked as (SELECT emp, salary, rank() over (order by count desc)),
select emp, salary
from ranked
where rank = 2;

select fruits, count(*) as quantity
from fruit_inventory
group by fruits;

select age, count(customer_ids) as customers
from customers
group by 1;

with customer_order as (
    select customer_id, count(order_id) as orders
    from orders
    group by 1
),
select orders, count(*) as num_customers from customer_order
group by 1
order by 1;

-- profile customers by the sum of all their orders, their avg order size, their min order date, or their max (most recent) order date.

select customer_id, sum(amount) as amt, min(order_date) as min_order_date, max(order_date) as most_recent_order
from orders
group by 1;











