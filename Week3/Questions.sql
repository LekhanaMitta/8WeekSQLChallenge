-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT DATE_TRUNC('month', start_date) AS month_start,
       COUNT(customer_id) AS total_customers
FROM subscriptions
WHERE plan_id = 0
GROUP BY month_start
ORDER BY month_start;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT DISTINCT(plan_id), COUNT(customer_id) FROM subscriptions
WHERE start_date >= '01-01-2021'
GROUP BY plan_id
ORDER BY plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 100.0*(SELECT COUNT(DISTINCT(customer_id)) 
  			FROM subscriptions
		WHERE plan_id = 4)/
       COUNT(DISTINCT(customer_id)) AS churn_percentage
       FROM subscriptions;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH reduced AS (
  SELECT *, ROW_NUMBER() OVER (
  			PARTITION BY customer_id
  			ORDER BY start_date) as rn 
     FROM subscriptions),
finalise AS (
  SELECT r1.customer_id, 
	r1.start_date AS date1,
    r2.start_date AS date2,
    r1.plan_id AS plan1, 
    r2.plan_id AS plan2
FROM reduced r1
JOIN reduced r2 ON r1.customer_id = r2.customer_id
WHERE r1.rn = 1 AND r2.rn = 2)
SELECT COUNT(customer_id) AS churn_count,
	100*COUNT(customer_id)/
	(SELECT COUNT(DISTINCT(customer_id)) 
    	FROM subscriptions) AS churn_percentage
	FROM finalise
WHERE plan1 = 0 AND plan2 = 4;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH reduced AS (
  SELECT *, ROW_NUMBER() OVER
  			(PARTITION BY customer_id
             ORDER BY start_date) AS RN
  FROM subscriptions),
finalise AS (
  SELECT r1.customer_id,
  		 r1.start_date AS date1,
  		 r2.start_date AS date2,
  		 r1.plan_id AS plan1,
  		 r2.plan_id AS plan2
  FROM reduced r1
  JOIN reduced r2 ON r1.customer_id = r2.customer_id
  WHERE r1.RN = 1 AND r2.RN = 2)
SELECT 
	COUNT(CASE 
          	WHEN plan1 = 0 AND plan2 = 1 THEN 1 
          END) AS basic_monthly,
    COUNT(CASE 
          	WHEN plan1 = 0 AND plan2 = 2 THEN 1 
          END) AS pro_monthly,
    COUNT(CASE 
          	WHEN plan1 = 0 AND plan2 = 3 THEN 1 
          END) AS pro_annually,
    COUNT(CASE 
          	WHEN plan1 = 0 AND plan2 = 4 THEN 1 
          END) AS churn
FROM finalise;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH reduced AS (
  SELECT customer_id, start_date, plan_id,
	ROW_NUMBER() OVER 
    	(PARTITION BY customer_id 
         ORDER BY start_date DESC) AS rn
	FROM subscriptions
WHERE start_date <= '2020-12-31'),
finalise AS (
  SELECT customer_id, start_date, plan_id
	FROM reduced
WHERE rn = 1)
SELECT 
	COUNT(
      	CASE 
      		WHEN plan_id = 0 THEN 1
      	END) AS trial,
    COUNT(
      	CASE 
      		WHEN plan_id = 1 THEN 1
      	END) AS basic_monthly,  
    COUNT(
      	CASE 
      		WHEN plan_id = 2 THEN 1
      	END) AS pro_monthly,
    COUNT(
      	CASE 
      		WHEN plan_id = 3 THEN 1
      	END) AS pro_annualy,
    COUNT(
      	CASE 
      		WHEN plan_id = 4 THEN 1
      	END) AS churn
FROM finalise;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT(customer_id)) 
	FROM subscriptions
WHERE plan_id = 3 
	AND start_date BETWEEN '2020-01-01' AND '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT 
	-- s1.customer_id, 
	-- s1.plan_id AS plan1, 
	-- s2.plan_id  AS plan2,
	-- s1.start_date AS date1,
	-- s2.start_date AS date2,
    AVG(s2.start_date - s1.start_date) AS avg_days
	FROM subscriptions s1, subscriptions s2
WHERE s1.customer_id = s2.customer_id 
	AND (s1.plan_id = 0 AND s2.plan_id = 3);

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH day_diff AS (
    SELECT
        s1.customer_id,
        s2.start_date - s1.start_date AS days
    FROM subscriptions s1
    JOIN subscriptions s2
        ON s1.customer_id = s2.customer_id
    WHERE s1.plan_id = 0
      AND s2.plan_id = 3
)
SELECT
    CASE
        WHEN days BETWEEN 0 AND 30 THEN '0-30 days'
        WHEN days BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN days BETWEEN 61 AND 90 THEN '61-90 days'
        WHEN days BETWEEN 91 AND 120 THEN '91-120 days'
        ELSE '121+ days'
    END AS period,
    AVG(days) AS avg_days,
    COUNT(*) AS customer_count
FROM day_diff
GROUP BY
    CASE
        WHEN days BETWEEN 0 AND 30 THEN '0-30 days'
        WHEN days BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN days BETWEEN 61 AND 90 THEN '61-90 days'
        WHEN days BETWEEN 91 AND 120 THEN '91-120 days'
        ELSE '121+ days'
    END
ORDER BY MIN(days);

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
-- SELECT s1.customer_id,
-- 	s1.plan_id AS plan1,
--     s2.plan_id AS plan2,
--     s1.start_date AS date1,
--     s2.start_date AS date2
-- FROM subscriptions s1, subscriptions s2
-- WHERE (s2.plan_id = 2 AND s1.plan_id = 1)
-- 	AND s1.start_date < s2.start_date
--     AND s1.customer_id = s2.customer_id
--     AND s1.start_date BETWEEN '2020-01-01' AND '2020-12-31'
--     AND s2.start_date BETWEEN '2020-01-01' AND '2020-12-31'
-- ORDER BY s1.customer_id;
SELECT COUNT(*) AS downgrade_count
FROM subscriptions s1, subscriptions s2
WHERE (s2.plan_id = 2 AND s1.plan_id = 1)
	AND s1.start_date < s2.start_date
    AND s1.customer_id = s2.customer_id
    AND s1.start_date BETWEEN '2020-01-01' AND '2020-12-31'
    AND s2.start_date BETWEEN '2020-01-01' AND '2020-12-31';
