/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS Total_price FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY Total_price;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT s1.customer_id, MIN(s1.product_id) FROM sales s1
WHERE s1.order_date = (SELECT MIN(order_date) FROM sales s
                      WHERE s1.customer_id = s.customer_id)
GROUP BY s1.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT customer_id, COUNT(product_id) FROM sales
WHERE product_id = 
(SELECT product_id FROM sales
GROUP BY product_id
ORDER BY product_id DESC LIMIT 1)
GROUP BY customer_id;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_id, cnt FROM 
(	
    SELECT customer_id, product_id, 
  	COUNT(product_id) AS cnt, 
  	DENSE_RANK() OVER (PARTITION BY customer_id 
                       ORDER BY COUNT(product_id) DESC) AS r 	 
  	FROM sales
  	GROUP BY customer_id, product_id
) t
WHERE r = 1;

WITH r AS
(
  SELECT s.customer_id, m.product_name, 
  	COUNT(m.product_name) AS cnt,
  	DENSE_RANK() OVER (PARTITION BY s.customer_id
                       	ORDER BY COUNT(m.product_name) DESC) AS r
  	FROM sales s
  	INNER JOIN menu m ON m.product_id = s.product_id
  	GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, cnt FROM r
WHERE r = 1;

-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
