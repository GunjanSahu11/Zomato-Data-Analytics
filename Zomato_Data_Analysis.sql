use github;

-- ZOMATO Data Analysis

-- Create the goldusers_signup table:

DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup (userid INTEGER, gold_signup_date DATE);

INSERT INTO goldusers_signup (userid, gold_signup_date)
VALUES (1, '2017-09-22'),
       (3, '2017-04-21');

-- Create the users table:

DROP TABLE IF EXISTS users;
CREATE TABLE users (userid INTEGER, signup_date DATE);

INSERT INTO users (userid, signup_date)
VALUES (1, '2014-09-02'),
       (2, '2015-01-15'),
       (3, '2014-04-11');
       
-- Create the sales table:
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (userid INTEGER, created_date DATE, product_id INTEGER);

INSERT INTO sales (userid, created_date, product_id)
VALUES (1, '2017-04-19', 2),
       (3, '2019-12-18', 1),
       (2, '2020-07-20', 3),
       (1, '2019-10-23', 2),
       (1, '2018-03-19', 3),
       (3, '2016-12-20', 2),
       (1, '2016-11-09', 1),
       (1, '2016-05-20', 3),
       (2, '2017-09-24', 1),
       (1, '2017-03-11', 2),
       (1, '2016-03-11', 1),
       (3, '2016-11-10', 1),
       (3, '2017-12-07', 2),
       (3, '2016-12-15', 2),
       (2, '2017-11-08', 2),
       (2, '2018-09-10', 3);

-- Create the product table:
DROP TABLE IF EXISTS product;
CREATE TABLE product (product_id INTEGER, product_name TEXT, price INTEGER);

INSERT INTO product (product_id, product_name, price)
VALUES (1, 'p1', 980),
       (2, 'p2', 870),
       (3, 'p3', 330);

SELECT * FROM sales;
SELECT * FROM product;
SELECT * FROM goldusers_signup;
SELECT * FROM users;

-- 1. Total amount each customer spent on Zomato:
SELECT a.userid, SUM(b.price) AS total_amt_spent
FROM sales a
INNER JOIN product b ON a.product_id = b.product_id
GROUP BY a.userid;

-- 2. How many days has each customer visited Zomato:
SELECT userid, COUNT(DISTINCT created_date) AS distinct_days
FROM sales
GROUP BY userid;

-- 3. What was the first product purchased by each customer:
SELECT *
FROM (
  SELECT *, RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
  FROM sales
) a
WHERE rnk = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers:
SELECT product_id, COUNT(product_id) AS cnt
FROM sales
GROUP BY product_id
ORDER BY cnt DESC
LIMIT 1;

-- 5.Which item was most popular for each customer:
SELECT *
FROM (
  SELECT *,
         RANK() OVER (PARTITION BY userid ORDER BY cnt DESC) AS rnk
  FROM (
    SELECT userid, product_id, COUNT(product_id) AS cnt
    FROM sales
    GROUP BY userid, product_id
  ) a
) b
WHERE rnk = 1;

-- 6. Which item was purchased first by customers after they become a member:
SELECT *
FROM (
  SELECT c.*, RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
  FROM (
    SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM sales a
    INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date >= b.gold_signup_date
  ) c
) d
WHERE rnk = 1;

-- 7.Which item was purchased just before customers became a member:

SELECT *
FROM (
  SELECT c.*, RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) AS rnk
  FROM (
    SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM sales a
    INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date <= b.gold_signup_date
  ) c
) d
WHERE rnk = 1;

-- 8. What is the total number of orders and the amount spent for each member before they became a member:

SELECT userid, COUNT(created_date) AS order_purchased, SUM(price) AS total_amt_spent
FROM (
  SELECT c.*, d.price
  FROM (
    SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM sales a
    INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date <= b.gold_signup_date
  ) c
  INNER JOIN product d ON c.product_id = d.product_id
) e
GROUP BY userid;

-- 9. Calculate points collected by each customer and which product earned the most points till now:

SELECT userid, SUM(total_points) * 2.5 AS total_point_earned
FROM (
  SELECT e.*, amt / points AS total_points
  FROM (
    SELECT d.*, CASE 
                   WHEN product_id = 1 THEN 5
                   WHEN product_id = 2 THEN 2
                   WHEN product_id = 3 THEN 5
                   ELSE 0
                 END AS points
    FROM (
      SELECT c.userid, c.product_id, SUM(price) AS amt
      FROM (
        SELECT a.*, b.price
        FROM sales a
        INNER JOIN product b ON a.product_id = b.product_id
      ) c
      GROUP BY userid, product_id
    ) d
  ) e
) f
GROUP BY userid;

-- 10. To find which product earned the most points:
SELECT *
FROM (
  SELECT *, RANK() OVER (ORDER BY total_point_earned DESC) AS rnk
  FROM (
    SELECT product_id, SUM(total_points) AS total_point_earned
    FROM (
      SELECT e.*, amt / points AS total_points
      FROM (
        SELECT d.*, CASE 
                       WHEN product_id = 1 THEN 5
                       WHEN product_id = 2 THEN 2
                       WHEN product_id = 3 THEN 5
                       ELSE 0
                     END AS points
        FROM (
          SELECT c.userid, c.product_id, SUM(price) AS amt
          FROM (
            SELECT a.*, b.price
            FROM sales a
            INNER JOIN product b ON a.product_id = b.product_id
          ) c
          GROUP BY userid, product_id
        ) d
      ) e
    ) f
    GROUP BY product_id
  ) g
) h
WHERE rnk = 1;

-- 11.Calculate the total points earned by each customer in the first year after joining the gold program, and find out who earned more points, 1 or 3:
SELECT c.userid, SUM(d.price * 0.5) AS total_points_earned
FROM (
  SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
  FROM sales a
  INNER JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date >= b.gold_signup_date AND a.created_date <= DATE_ADD(b.gold_signup_date, INTERVAL 1 YEAR)
) c
INNER JOIN product d ON c.product_id = d.product_id
GROUP BY c.userid;

-- 12. Rank all transactions of the customers:
SELECT *, RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
FROM sales;

-- 13. Rank all transactions for each member whenever they are Zomato gold members; for every non-gold member transaction, mark it as "na":
SELECT e.*, CASE WHEN rnk = 0 THEN 'na' ELSE CAST(rnk AS VARCHAR) END AS rnkk
FROM (
  SELECT c.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) END) AS VARCHAR) AS rnk
  FROM (
    SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM sales a
    LEFT JOIN goldusers_signup b ON a.userid = b.userid AND a.created_date >= b.gold_signup_date
  ) c
) e;


