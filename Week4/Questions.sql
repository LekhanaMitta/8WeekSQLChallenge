-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT(node_id)) AS unique_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT region_id, COUNT(DISTINCT(node_id))
	FROM customer_nodes
GROUP BY region_id;

-- 3. How many customers are allocated to each region?
SELECT region_id, COUNT(DISTINCT(customer_id))
	FROM customer_nodes
GROUP BY region_id;

-- 4. How many days on average are customers reallocated to a different node? 
-- SELECT AVG(end_date - start_date) AS reallocation_days
-- 	FROM customer_nodes
-- WHERE end_date IS NOT NULL
--   	AND end_date != '9999-12-31';

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT region_id,
	AVG(end_date - start_date) AS avg_days,
	PERCENTILE_DISC(0.5) WITHIN GROUP(
      ORDER BY (end_date - start_date)) AS p_50,
    PERCENTILE_DISC(0.80) WITHIN GROUP(
      ORDER BY (end_date - start_date)) AS p_80,
    PERCENTILE_DISC(0.95) WITHIN GROUP(
      ORDER BY (end_date - start_date)) AS p_95
FROM customer_nodes
WHERE end_date IS NOT NULL
	AND end_date != '9999-12-31'
GROUP BY region_id
ORDER BY region_id;

-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
SELECT DISTINCT(txn_type), 
	COUNT(txn_type),
    SUM(txn_amount)
	FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
SELECT AVG(deposit_count) 
FROM (
		SELECT txn_date, COUNT(txn_type) AS deposit_count
            FROM customer_transactions
        WHERE txn_type = 'deposit'
        GROUP BY txn_type, txn_date) t;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
SELECT month, 
	COUNT(customer_id)
	FROM (
      	SELECT EXTRACT(MONTH FROM txn_date) AS month,
          customer_id,
          COUNT(
              CASE
                  WHEN txn_type = 'deposit' THEN 1 ELSE 0
              END) AS deposit_count,
          COUNT(
              CASE
                  WHEN txn_type = 'purchase' THEN 1 ELSE 0
              END) AS purchase_count,
          COUNT(
              CASE
                  WHEN txn_type = 'withdrawal' THEN 1 ELSE 0
              END) AS withdrawal_count
      FROM customer_transactions
      GROUP BY EXTRACT(MONTH FROM txn_date),
              customer_id
      ORDER BY EXTRACT(MONTH FROM txn_date),
              customer_id) t
	WHERE deposit_count > 1
    	AND (purchase_count>1 OR withdrawal_count>1)
GROUP BY month;

-- 4. What is the closing balance for each customer at the end of the month?
WITH monthly_savings AS (
  SELECT customer_id, 
          EXTRACT(MONTH FROM txn_date) AS txn_month,
          SUM(
            CASE 
              WHEN txn_type IN ('purchase', 'withdrawal') 
                  THEN -txn_amount
              ELSE txn_amount
          END) AS balance
  FROM customer_transactions
  GROUP BY customer_id, txn_month)
SELECT customer_id,
	txn_month,
	SUM(balance) OVER (
      	PARTITION BY customer_id
      	ORDER BY txn_month
      	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
    AS closing_balance
FROM monthly_savings
ORDER BY customer_id, txn_month;

WITH monthly_savings AS (
  SELECT customer_id, 
          EXTRACT(MONTH FROM txn_date) AS txn_month,
          SUM(
            CASE 
              WHEN txn_type IN ('purchase', 'withdrawal') 
                  THEN -txn_amount
              ELSE txn_amount
          END) AS balance
  FROM customer_transactions
  GROUP BY customer_id, txn_month)
SELECT customer_id,
	txn_month,
    SUM(balance) OVER (
      	PARTITION BY customer_id
      	ORDER BY txn_month
      	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
    AS closing_balance
FROM monthly_savings
ORDER BY customer_id, txn_month;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_savings AS (
  SELECT customer_id, 
          EXTRACT(MONTH FROM txn_date) AS txn_month,
          SUM(
            CASE 
              WHEN txn_type IN ('purchase', 'withdrawal') 
                  THEN -txn_amount
              ELSE txn_amount
          END) AS balance
  FROM customer_transactions
  GROUP BY customer_id, txn_month),
closing_monthly_balance AS (
  SELECT customer_id,
      txn_month,
  	  balance,
      SUM(balance) OVER (
          PARTITION BY customer_id
          ORDER BY txn_month
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS closing_balance
  FROM monthly_savings
  ORDER BY customer_id, txn_month),
balance_change AS (
  SELECT customer_id,
      txn_month,
      balance,
      closing_balance,
      COALESCE(LAG(closing_balance) OVER (
          PARTITION BY customer_id
          ORDER BY txn_month
      ),0) AS changes_balance
  FROM closing_monthly_balance
  ORDER BY customer_id, txn_month),
balance_increase AS (
  SELECT customer_id,
  	  CASE 
  		WHEN closing_balance > 1.05 * changes_balance THEN 1
  		ELSE 0
  	  END AS increased
  FROM balance_change
)
SELECT 
	ROUND(100*COUNT(CASE WHEN increased = 1 THEN 1 END)/
          	COUNT(DISTINCT customer_id),2) AS percentage
    FROM balance_increase;

-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
	-- Option 1: data is allocated based off the amount of money at the end of the previous month
	-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
	-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
	-- running customer balance column that includes the impact each transaction
	-- customer balance at the end of each month
	-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?
