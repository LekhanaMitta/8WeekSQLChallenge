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
SELECT 
    c.pizza_id,
    SUM(
        CASE 
            WHEN exclusions NOT IN ('', 'null') 
              AND extras NOT IN ('', 'null') THEN 1
            ELSE 0
        END
    ) AS changes
FROM customer_orders c
JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE cancellation IS NULL 
   OR cancellation NOT LIKE '%Cancellation%'
GROUP BY c.pizza_id
ORDER BY c.pizza_id;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS Hours, 
	COUNT(*) FROM customer_orders
GROUP BY Hours
ORDER BY Hours;

-- 10. What was the volume of orders for each day of the week?
SELECT 
    TO_CHAR(order_time, 'Day') AS day_of_week,
    COUNT(DISTINCT order_id) AS total_orders
FROM customer_orders
GROUP BY day_of_week;

-- B. Runner and Customer Experience
-- 1.  How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT FLOOR((registration_date - DATE '2021-01-01') / 7) + 1 AS week,
       COUNT(runner_id)
FROM runners
GROUP BY week
ORDER BY week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT r.runner_id,
       AVG(
         NULLIF(r.pickup_time, 'null')::timestamp 
         - c.order_time::timestamp
       ) AS avg_pickup_time
FROM customer_orders c
JOIN runner_orders r
  ON c.order_id = r.order_id
WHERE NULLIF(r.pickup_time, 'null') IS NOT NULL
GROUP BY r.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?


-- 4. What was the average distance travelled for each customer?
SELECT 
    c.customer_id, 
    AVG(NULLIF(REPLACE(distance, 'km', ''), '')::NUMERIC) AS avg_distance
FROM runner_orders r
JOIN customer_orders c 
    ON r.order_id = c.order_id
WHERE r.distance IS NOT NULL
  AND r.distance <> 'null'
GROUP BY c.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT 
	MAX(NULLIF(REPLACE(distance, 'km', ''),'')::Numeric),
	MIN(NULLIF(REPLACE(distance, 'km', ''),'')::Numeric) 
    FROM runner_orders
WHERE distance <> 'null' 
	AND distance IS NOT NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, 
AVG(
        60*NULLIF(TRIM(REPLACE(distance, 'km', '')), '')::numeric
        /
        NULLIF(
                REPLACE(
                    REPLACE(
                        REPLACE(duration, 'minutes', ''),
                    'minute', ''),
                'mins', ''),
            '')::numeric
    ) AS avg_speed
FROM runner_orders
WHERE duration <> 'null'
AND distance <> 'null'
GROUP BY runner_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT a.runner_id, 
	(SELECT COUNT(order_id) 
     	FROM runner_orders b
    	WHERE a.runner_id = b.runner_id) AS assigned,
     (SELECT COUNT(order_id)
      	FROM runner_orders b
      	WHERE a.runner_id = b.runner_id
      		AND (cancellation IS NULL 
				OR cancellation NOT LIKE '%Cancellation%')) AS 		delivered, 
      (SELECT COUNT(order_id)
      	FROM runner_orders b
      	WHERE a.runner_id = b.runner_id
      		AND (cancellation IS NULL 
				OR cancellation NOT LIKE '%Cancellation%'))*100/(SELECT COUNT(order_id) 
     	FROM runner_orders b
    	WHERE a.runner_id = b.runner_id) AS delivery_percentage
FROM runner_orders a
GROUP BY runner_id;

-- 1. What are the standard ingredients for each pizza?
SELECT pizza_id,
    STRING_AGG(pt.topping_name, ', ' ORDER BY topps::int) AS toppings
FROM pizza_recipes pr
CROSS JOIN 
	unnest(string_to_array(toppings, ',')) AS topps
JOIN pizza_toppings pt
ON pt.topping_id = topps::int
GROUP BY pizza_id
ORDER BY pizza_id;

-- 2. What was the most commonly added extra?
SELECT extra_id
	FROM (SELECT order_id, 
          	unnest(string_to_array(extras,',')) AS extra_id 
          FROM customer_orders
			WHERE extras IS NOT NULL
				AND extras <> 'null'
    			AND extras <> '') AS t
GROUP BY extra_id
ORDER BY COUNT(extra_id) DESC LIMIT 1;

-- 3. What was the most common exclusion?
SELECT exclusion_id, 
	COUNT(exclusion_id)
    FROM (SELECT unnest(string_to_array(exclusions,',')) 
          	AS exclusion_id
          	FROM customer_orders
          WHERE exclusions IS NOT NULL 
          	AND exclusions <> ''
          	AND exclusions <> 'null') AS tab
GROUP BY exclusion_id
ORDER BY COUNT(exclusion_id) DESC LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT pizza_id, 
	STRING_AGG(pt.topping_name,', ' ORDER BY topps::int) AS toppings
FROM pizza_recipes pr
CROSS JOIN 
    unnest(string_to_array(toppings,',')) AS topps
JOIN pizza_toppings pt
ON pt.topping_id = topps::int
GROUP BY pr.pizza_id;

-- Meat Lovers - Exclude Beef
SELECT pizza_id,
	STRING_AGG(topping_name, ',' ORDER BY topps::int) AS topping
FROM pizza_recipes pr
CROSS JOIN unnest(string_to_array(toppings,',')) AS topps
JOIN pizza_toppings pt
ON pt.topping_id = topps::int
WHERE pt.topping_name <> 'Beef' AND pr.pizza_id = 1
GROUP BY pr.pizza_id;

-- Meat Lovers - Extra Bacon
SELECT pizza_id, pt.topping_name,
	COUNT(topps::int) + 
    (CASE
    	WHEN pt.topping_name = 'Bacon' THEN 1
        ELSE 0
    END) AS Counts 
FROM pizza_recipes pr
CROSS JOIN unnest(string_to_array(toppings,',')) AS topps
JOIN pizza_toppings pt
ON pt.topping_id = topps::int
WHERE pr.pizza_id = 1
GROUP BY pr.pizza_id, topps::int, pt.topping_name;

-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT pizza_id, pt.topping_name, 
COUNT(*) +
	(CASE 
    	WHEN pt.topping_name IN ('Cheese', 'Bacon') THEN -1
        WHEN pt.topping_name IN ('Mushrooms', 'Peppers') THEN 1
     	ELSE 0
    END) AS topping_count
FROM pizza_recipes pr
CROSS JOIN unnest(string_to_array(toppings,',')) AS topps
JOIN pizza_toppings pt
ON pt.topping_id = topps::int
WHERE pr.pizza_id = 1
GROUP BY pr.pizza_id, topps::int, pt.topping_name;
	



-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
