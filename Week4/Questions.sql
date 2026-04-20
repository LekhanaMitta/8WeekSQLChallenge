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
-- 2. What is the average total historical deposit counts and amounts for all customers?
-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- 4. What is the closing balance for each customer at the end of the month?
-- 5. What is the percentage of customers who increase their closing balance by more than 5%?

-- C. Data Allocation Challenge
-- 1. To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
	-- Option 1: data is allocated based off the amount of money at the end of the previous month
	-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
	-- Option 3: data is updated real-time

-- 2. For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
	-- running customer balance column that includes the impact each transaction
	-- customer balance at the end of each month
	-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?
