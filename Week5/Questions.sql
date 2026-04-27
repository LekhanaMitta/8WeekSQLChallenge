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
