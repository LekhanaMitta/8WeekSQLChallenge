-- Schema SQL Query SQL ResultsEdit on DB Fiddle
-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS number_of_Pizzas FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(customer_id)) AS number_of_customers 
	FROM customer_orders;
    
-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successful_deliveries
FROM runner_orders
WHERE cancellation NOT LIKE '%Cancellation%' 
	OR Cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT c.pizza_id, COUNT(c.pizza_id) FROM customer_orders c
JOIN runner_orders r 
ON r.order_id = c.order_id
WHERE cancellation NOT LIKE '%Cancellation%'
	OR cancellation IS NULL
GROUP BY c.pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(c.pizza_id) 
	FROM customer_orders c
JOIN pizza_names p
ON c.pizza_id = p.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT c.order_id, c.customer_id, COUNT(c.order_id) AS Pizza_count FROM customer_orders c
JOIN runner_orders r 
ON r.order_id = c.order_id
WHERE cancellation NOT LIKE '%Cancellation%'
	OR cancellation IS NULL
GROUP BY c.order_id, c.customer_id
ORDER BY Pizza_count DESC LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    c.customer_id,
    SUM(
        CASE 
            WHEN exclusions NOT IN ('', 'null') 
              OR extras NOT IN ('', 'null') THEN 1
            ELSE 0
        END
    ) AS changes,
    SUM(
        CASE 
            WHEN (exclusions IS NULL OR exclusions IN ('', 'null'))
             AND (extras IS NULL OR extras IN ('', 'null')) THEN 1
            ELSE 0
        END
    ) AS no_changes
FROM customer_orders c
JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE cancellation IS NULL 
   OR cancellation NOT LIKE '%Cancellation%'
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10. What was the volume of orders for each day of the week?
