/* 	case study link : https://8weeksqlchallenge.com/case-study-1/

														Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.
Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

															Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.
He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.
Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions! 
Danny has shared with you 3 key datasets for this case study:
sales
menu
members
*/

/* --------------------
   Case Study Questions
   --------------------*/
   
use dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
    s.customer_id, SUM(me.price) AS total_amount
FROM
    sales s
        JOIN
    menu me ON me.product_id = s.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
    customer_id, COUNT(order_date) AS number_of_days_visited
FROM
    sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte as (select s.*, m.product_name, row_number() over (partition by customer_id order by order_date) as row_num from sales s join menu m on s.product_id = m.product_id)
SELECT 
    customer_id, product_name
FROM
    cte
WHERE
    row_num = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with cte as (SELECT 
    product_id, COUNT(product_id) AS purchase_count
FROM
    sales
GROUP BY product_id
ORDER BY purchase_count DESC
LIMIT 1)

SELECT 
    m.product_name, c.purchase_count
FROM
    cte c
        JOIN
    menu m ON c.product_id = m.product_id;

-- 5. Which item was the most popular for each customer?

with cte1 as (SELECT 
    s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS purchase_count
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)

select *, rank () over (partition by customer_id order by purchase_count desc) as rank_num from cte1;

-- 6. Which item was purchased first by the customer after they became a member?

 with cte as (select m.customer_id, m.join_date, s.product_id, me.product_name, s.order_date, rank () over (partition by s.customer_id order by s.order_date) as rank_num from members m join sales s on m.customer_id = s.customer_id join menu me on s.product_id = me.product_id where s.order_date > m.join_date)
SELECT 
    customer_id, join_date, order_date, product_name
FROM
    cte
WHERE
    rank_num = 1;

-- 7. Which item was purchased just before the customer became a member?

 with cte as (select m.customer_id, m.join_date, s.product_id, me.product_name, s.order_date, rank () over (partition by s.customer_id order by s.order_date desc) as rank_num from members m join sales s on m.customer_id = s.customer_id join menu me on s.product_id = me.product_id where s.order_date < m.join_date)
SELECT 
    customer_id, join_date, order_date, product_name
FROM
    cte
WHERE
    rank_num = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
    s.customer_id,
    SUM(me.price) AS total_amount,
    COUNT(s.product_id) AS total_items
FROM
    sales s
        LEFT JOIN
    members m ON s.customer_id = m.customer_id
        JOIN
    menu me ON s.product_id = me.product_id
WHERE
   m.join_date > s.order_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
    s.customer_id,
    SUM(CASE
        WHEN m.product_name = 'sushi' THEN (m.price * 10 * 2)
        ELSE m.price * 10
    END) AS total_points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
    s.customer_id,
    SUM(CASE
        WHEN
            m.product_name = 'sushi'
                AND s.order_date BETWEEN me.join_date AND DATE_ADD(me.join_date, INTERVAL 6 DAY)
        THEN
            (m.price * 10 * 2 * 2)
		WHEN
            m.product_name != 'sushi'
                AND s.order_date BETWEEN me.join_date AND DATE_ADD(me.join_date, INTERVAL 6 DAY)
        THEN
            (m.price * 10 * 2)
        WHEN m.product_name = 'sushi' AND s.order_date NOT BETWEEN me.join_date AND DATE_ADD(me.join_date, INTERVAL 6 DAY) THEN (m.price * 10 * 2)
        ELSE m.price * 10
    END) AS total_points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members me ON s.customer_id = me.customer_id
GROUP BY s.customer_id;

-- Bonus questions

-- 1. Join All The Things

SELECT 
    s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    CASE
        WHEN s.order_date >= m.join_date THEN 'Y'
        WHEN m.join_date IS NULL THEN 'N'
        ELSE 'N'
    END AS member
FROM
    sales s
        JOIN
    menu me ON s.product_id = me.product_id
        LEFT JOIN
    members m ON s.customer_id = m.customer_id
ORDER BY s.customer_id , s.order_date;


-- 2. Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

with cte as (SELECT 
    s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    CASE
        WHEN s.order_date >= m.join_date THEN 'Y'
        WHEN m.join_date IS NULL THEN 'N'
        ELSE 'N'
    END AS member
FROM
    sales s
        JOIN
    menu me ON s.product_id = me.product_id
        LEFT JOIN
    members m ON s.customer_id = m.customer_id
ORDER BY s.customer_id , s.order_date)
select *, case when member = 'N' then null else rank() over(partition by customer_id, member order by order_date) end as ranking from cte;