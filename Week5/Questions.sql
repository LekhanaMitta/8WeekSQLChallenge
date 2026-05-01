-- I. DATA CLEANING STEPS
-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

-- 1. Convert the week_date to a DATE format
-- 2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- 3. Add a month_number with the calendar month for each week_date value as the 3rd column
-- 4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- 5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
		-- segment	age_band
		-- 1		Young Adults
		-- 2		Middle Aged
		-- 3 or 4	Retirees
-- 6. Add a new demographic column using the following mapping for the first letter in the segment values:
		-- segment	demographic
		-- C		Couples
		-- F		Families
-- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- 7. Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales AS
SELECT 
	TO_DATE(week_date, 'DD/MM/YY') AS week_date,
    EXTRACT(WEEK FROM (TO_DATE(week_date, 'DD/MM/YY'))) AS week_number,
    EXTRACT(MONTH FROM (TO_DATE(week_date, 'DD/MM/YY'))) AS month,
    EXTRACT (YEAR FROM (TO_DATE(week_date, 'DD/MM/YY'))) AS year,
    (CASE 
      	WHEN segment LIKE '%1' THEN 'Young Adults'
      	WHEN segment LIKE '%2' THEN 'Middle Aged'
      	WHEN segment LIKE '%3' THEN 'Retirees'
     	WHEN segment LIKE '%3' THEN 'Retirees'
     	ELSE 'Unknown'
      END) AS age_band,
     (CASE
      	WHEN segment LIKE 'C%' THEN 'Couples'
      	WHEN segment LIKE 'F%' THEN 'Families'
      	ELSE 'Unknown'
      END) AS demographic,
     ROUND((sales/transactions), 2) AS avg_transaction
FROM weekly_sales;

SELECT * FROM clean_weekly_sales;
    

-- II. DATE EXPLORATION
-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT(EXTRACT(DOW FROM entry_date))
	FROM (SELECT TO_DATE(week_date, 'DD/MM/YY') 
          		AS entry_date
          	FROM weekly_sales) t;

-- 2. What range of week numbers are missing from the dataset?
SELECT total_weeks
	FROM (SELECT GENERATE_SERIES(1, 53) 
          	AS total_weeks) T1
WHERE total_weeks NOT IN 
  (SELECT DISTINCT(EXTRACT(WEEK FROM entry_date)) AS weeks
      FROM (SELECT TO_DATE(week_date, 'DD/MM/YY') 
                  AS entry_date
              FROM weekly_sales)
  ORDER BY weeks);

-- 3. How many total transactions were there for each year in the dataset?
WITH T AS (
  SELECT TO_DATE(week_date, 'DD/MM/YY')
    	AS order_date,
  		week_date,
  		transactions
  	FROM weekly_sales) 
SELECT DISTINCT(EXTRACT(YEAR FROM order_date)) AS year,
	SUM(transactions)
FROM T
GROUP BY year;

-- 4. What is the total sales for each region for each month?
WITH T AS (
  SELECT TO_DATE(week_date, 'DD/MM/YY') AS date,
  	region,
  	platform,
  	segment,
  	customer_type,
  	transactions,
  	sales
  FROM weekly_sales)
SELECT DISTINCT(EXTRACT(MONTH FROM date)) AS month,
	region,
    SUM(transactions)
FROM T
GROUP BY month, region
ORDER BY month, region;

-- 5. What is the total count of transactions for each platform
WITH T AS (
  SELECT TO_DATE(week_date, 'DD/MM/YY') AS date,
  	region,
  	platform,
  	segment,
  	customer_type,
  	transactions,
  	sales
  FROM weekly_sales)
SELECT DISTINCT(EXTRACT(MONTH FROM date)) AS month,
	platform,
    SUM(transactions)
FROM T
GROUP BY month, platform
ORDER BY month, platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
-- 7. What is the percentage of sales by demographic for each year in the dataset?
-- 8. Which age_band and demographic values contribute the most to Retail sales?
-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
