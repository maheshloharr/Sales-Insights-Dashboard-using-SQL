create database sales_data;

use sales_data;

-- Step 1 -> Data Exploration

# Total Counts 
select
	(select count(*) from Customers ) as total_customers,
    (select count(*) from products) as total_products,
    (select count(*) from orders )as total_orders;

# Most frequently ordered products
select p.product_name , sum(oi.quantity) as Total_quentity 
from order_items oi
join products p on oi.product_id = p.product_id
group by p.product_name
order by Total_quentity desc
limit 10;

# Average order values
SELECT AVG(order_total) AS avg_order_value
FROM (
    SELECT o.order_id, 
           SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.order_id
) t;

# Revenue Over Time (Monthly)
SELECT 
    date_format('month', o.order_date) AS month,
    SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY month
ORDER BY month;

# Top 5 States by Revenue
SELECT c.state,
       SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.state
ORDER BY revenue DESC
LIMIT 5;

-- STEP 2: Customer Analysis

# New vs Returning Customers (Monthly)
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order
    FROM Orders
    GROUP BY customer_id
)
SELECT 
    date_format('month', o.order_date) AS month,
    COUNT(DISTINCT CASE 
        WHEN o.order_date = f.first_order THEN o.customer_id 
    END) AS new_customers,
    COUNT(DISTINCT CASE 
        WHEN o.order_date > f.first_order THEN o.customer_id 
    END) AS returning_customers
FROM orders o
JOIN first_orders f ON o.customer_id = f.customer_id
GROUP BY month
ORDER BY month;


# Top 10 Customers by Lifetime Value
SELECT c.customer_id, c.first_name, c.last_name,
       SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC
LIMIT 10;

# Gender-wise Spending
SELECT c.gender,
       SUM(oi.quantity * p.unit_price * (1 - oi.discount)) AS total_spending
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.gender;

# Churn Prediction (Simple)
SELECT c.customer_id,
       MAX(o.order_date) AS last_order_date,
       CURRENT_DATE - MAX(o.order_date) AS days_inactive,
       CASE 
           WHEN CURRENT_DATE - MAX(o.order_date) > 90 THEN 'Churned'
           ELSE 'Active'
       END AS status
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;

-- STEP 3: Product Analysis
# Best-Selling Products
SELECT p.product_name,
       SUM(oi.quantity) AS total_sold,
       SUM(oi.quantity * p.unit_price) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;

# Category-wise Revenue
SELECT p.category,
       SUM(oi.quantity * p.unit_price) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;

# Profit Margin Analysis
SELECT p.product_name,
       (p.unit_price - p.cost_price) AS profit_per_unit,
       SUM(oi.quantity) AS total_units,
       SUM((p.unit_price - p.cost_price) * oi.quantity) AS total_profit
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name, p.unit_price, p.cost_price
ORDER BY total_profit DESC;

# Underperforming Products
SELECT p.product_name,
       SUM(oi.quantity) AS total_sales
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name
HAVING SUM(oi.quantity) < 10 OR SUM(oi.quantity) IS NULL;

-- STEP 4: Shipping & Fulfillment
# Average Shipping Time
SELECT AVG(shipping_date - order_date) AS avg_shipping_days
FROM orders o
JOIN Shipping s ON o.order_id = s.order_id;

# Shipping Cost Analysis
SELECT shipping_method,
       AVG(shipping_cost) AS avg_cost,
       SUM(shipping_cost) AS total_cost
FROM shipping
GROUP BY shipping_method;

# Delayed vs On-Time
SELECT shipping_status,
       COUNT(*) AS total_orders
FROM shipping
GROUP BY shipping_status;


-- STEP 5: Advanced SQL
# Ranking Customers
SELECT customer_id,
       SUM(oi.quantity * p.unit_price) AS total_spent,
       RANK() OVER (ORDER BY SUM(oi.quantity * p.unit_price) DESC) as rrank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY customer_id;

# ROW_NUMBER Example
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence
FROM orders;

# LAG / LEAD (Customer Purchase Gap)
SELECT customer_id, order_date,
       LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order,
       order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS gap_days
FROM orders;

# CASE WHEN Segmentation
SELECT customer_id,
       SUM(oi.quantity * p.unit_price) AS spending,
       CASE 
           WHEN SUM(oi.quantity * p.unit_price) > 1000 THEN 'High Value'
           WHEN SUM(oi.quantity * p.unit_price) > 500 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS segment
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY customer_id;