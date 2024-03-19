----------------------------------
-- CASE STUDY #1: DANNY'S DINER --
----------------------------------

-- Author: Moses Tega Ziregbe 
-- Tool used: MySQL Server
--------------------------

-- Case Study Questions

-- 1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, 
	   SUM(menu.price) AS total_spent
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY customer_id;



-- 2. How many days has each customer visited the restaurant?

-- Use COUNT DISTINCT to avoid duplicates for Customers visiting the
-- restaurants multiple times in the same day.

SELECT customer_id, 
COUNT(DISTINCT order_date) AS total_num_days 
FROM sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?

-- Using Common Table Expressions (CTEs) and the RANK() function with PARTITION BY and ORDER BY clauses,
-- this query ranks the products based on the order date for each customer.

WITH menu_sales_cte AS
(
SELECT customer_id, 
	   order_date, 
       product_name,
       RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS Rnk
       FROM sales
JOIN menu
ON sales.product_id = menu.product_id
)
SELECT customer_id,
	   product_name,
       Rnk
FROM menu_sales_cte
WHERE Rnk = 1
GROUP BY customer_id, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- Use GROUP BY statement to group the products ordered by a customer and LIMIT clause to retrieve 
-- the highest count of a product ordered.

SELECT m.product_name, COUNT(*) AS purchase_count
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?

-- Assumption: Products with the highest count are considered the most popuplar for each customer
-- Compute the most popular menu item for each customer by counting the occurrences of each item and ranking them.
-- Use common table expression (CTE) to calculate item counts and rankings partitioned by customer.

WITH ranked_items AS
(
SELECT sales.customer_id, 
	   menu.product_name, 
	   COUNT(menu.product_name) AS count_of_item,
       RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(menu.product_name) DESC) AS Rnk
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_name
)
SELECT customer_id, 
	   product_name AS most_popular_item,
       count_of_item
FROM ranked_items
WHERE Rnk = 1;


-- 6. Which item was purchased first by the customer after they became a member?

-- Using Common Table Expression (CTE) named 'member_purchases' to gather data 
-- on the first purchases made by customers after joining the membership program.
-- By joining the 'sales', 'members', and 'menu' tables, then rank the purchases based on order date for each customer, 
-- ensuring only purchases made after joining are considered. The final result retrieves the customer ID 
-- and the name of the menu item representing their initial purchase after joining.


WITH member_purchases AS
(
SELECT sales.customer_id,
	   sales.order_date,
       menu.product_name,
       sales.product_id,
       members.join_date,
       RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS Rnk
FROM members
JOIN sales
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date > members.join_date
)
SELECT customer_id,
       product_name AS first_purchase
FROM member_purchases
WHERE Rnk = 1;



-- 7. Which item was purchased just before the customer became a member?

-- Using a Common Table Expression(CTE) named 'customer_purchases', we identify the 
-- item purchased just before a customer joined the membership program.
-- next, retrieve the customer ID and the name of the menu item representing their last purchase before becoming a member.

WITH customer_purchases AS
(
SELECT sales.customer_id,
	   sales.order_date,
       members.join_date,
       menu.product_name,
       sales.product_id,
       RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS Rnk
FROM members
JOIN sales
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
)
SELECT customer_id,
       product_name AS last_purchase_before_membership
FROM customer_purchases
WHERE Rnk = 1;



-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
	members.customer_id,
    COUNT(*) AS total_items,
    COALESCE(SUM(menu.price), 0) AS total_amount_spent_before_membership
FROM members
JOIN sales
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY members.customer_id
ORDER BY customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?

-- Use SUM function to calculate the total points earned by each customer 
-- based on their purchases, applying a 10x points multiplier for standard items and a 20x multiplier for sushi.
-- Results are grouped by customer ID to provide the total points earned for each customer.


SELECT 
    sales.customer_id,
    SUM(CASE
        WHEN menu.product_id = 1 THEN price * 20
        ELSE price * 10 
	 END) AS total_points
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

-- Step 1: Calculate points earned during the first week after joining with a 2x multiplier
-- Step 2: Calculate points earned for sushi purchases with a 2x multiplier
-- Step 3: Calculate points earned for other items with a regular 10x multiplier
-- Join the 'members', 'sales', and 'menu' tables to get relevant data
-- Filter the data for the period up to January 31st, 2021
-- Group the results by customer ID

SELECT 
	members.customer_id,
    SUM(CASE
			WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY) THEN price*20
            WHEN product_name = "sushi" THEN price*10*2
            ELSE price*10
            END) AS points
FROM members
JOIN sales
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date <= "2021-01-31"
GROUP BY sales.customer_id;



