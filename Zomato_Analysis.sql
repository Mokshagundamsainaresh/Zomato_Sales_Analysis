use zomato;

select * from goldusers_signup;
select * from product;
select * from sales;
select * from users;

-- 1) What is the total amount each customer spent on zomato?
SELECT 
    a.userid, SUM(b.price) AS Total_price
FROM
    sales a
        INNER JOIN
    product b
WHERE
    a.product_id = b.product_id
GROUP BY a.userid;


-- 2) How many days has each customer visited the zomato?
SELECT 
    userid, COUNT(DISTINCT created_date) AS number_of_days
FROM
    sales
GROUP BY userid;


-- 3) What was the first product customer purchased by each customer?
select * from (select *,rank() over (partition by userid order by created_date) as rnk from sales) a where rnk = 1 ;


-- 4) What is the most purchased item on the menu and how many times was it purchased by all the customers ?
SELECT 
    userid, COUNT(product_id) cnt
FROM
    sales
WHERE
    product_id = (SELECT 
            product_id
        FROM
            sales
        GROUP BY product_id
        ORDER BY COUNT(product_id) DESC
        LIMIT 1)
GROUP BY userid
ORDER BY userid;

-- 5) Which item was the most popular for each of the customer?
select * from (select *,rank() over(partition by userid order by cnt DESC) rnk from (select userid,product_id,count(product_id) as cnt from sales group by userid, product_id)a)b where rnk = 1;

-- 6) Which item was purchased first by the customer after they become a gold member ?
select * from(select *,rank() over(partition by userid order by created_date) rnk from (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b where a.userid = b.userid and created_date>gold_signup_date)c)d where rnk = 1;


-- 7) Which item was purchased just before the customer became a member?
select * from (select *,rank() over(partition by userid order by created_date DESC) rnk from (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join  goldusers_signup b where a.userid = b.userid and created_date <= gold_signup_date)c)d where rnk = 1;

-- 8) What is the total orders and amount spent for each member before they became a member ?
SELECT 
    userid,
    COUNT(created_date) AS order_count,
    SUM(price) AS total_amount_spent
FROM
    (SELECT 
        c.*, d.price
    FROM
        (SELECT 
        a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM
        sales a
    INNER JOIN goldusers_signup b
    WHERE
        a.userid = b.userid
            AND created_date <= gold_signup_date) c
    INNER JOIN product d ON c.product_id = d.product_id) e
GROUP BY userid;

/* 9) If buying each product generates points for eg 5rs 2 zomato point and each product has 
different purchasing points for eg for pl 5rs 1 zomato point for p2 10rs 5 zomato
 points and p3 5rs 1 zomato point */

-- Calculate the points collected by each customer and for which product most points have been given till now.

select userid,sum(total_points)*2.5 as total_money_earned from (select e.*, Round(amnt/points,0) as total_points from (select d.*,case when product_id = 1 then 5  when product_id = 2 then 2  when product_id = 3 then 5 else 0 end as points from (SELECT 
    c.userid, c.product_id, SUM(price) as amnt
FROM
    (SELECT 
        a.*, b.price
    FROM
        sales a
    INNER JOIN product b ON a.product_id = b.product_id) c
GROUP BY userid , product_id) d)e)f group by userid;


select h.* from (select g.*,rank() over(order by  total_points_earned DESC) as rnk from  (select product_id,sum(total_points) as total_points_earned from (select e.*, Round(amnt/points,0) as total_points from (select d.*,case when product_id = 1 then 5  when product_id = 2 then 2  when product_id = 3 then 5 else 0 end as points from (SELECT 
    c.userid, c.product_id, SUM(price) as amnt
FROM
    (SELECT 
        a.*, b.price
    FROM
        sales a
    INNER JOIN product b ON a.product_id = b.product_id) c
GROUP BY userid , product_id) d)e)f group by product_id)g)h where rnk = 1;

/* 10) In the first one year after a customer joins the gold program (including their join date)
 irrespective of what the customer has purchased they earn 5 zomato points for every 10 rs
 spent who earned more more 1 or 3 and what was their points earnings in thier first yr? */
 
SELECT 
    c.*, d.price * 0.5 AS total_points_earned
FROM
    (SELECT 
        a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM
        sales a
    INNER JOIN goldusers_signup b
    WHERE
        a.userid = b.userid
            AND created_date >= gold_signup_date
            AND created_date < DATE_ADD(gold_signup_date, INTERVAL 1 YEAR)) c
        INNER JOIN
    product d ON c.product_id = d.product_id;
 
 -- 11) Rank all the transactions of the customers ?
 
 select *,rank() over (partition by userid order by created_date) rnk from sales;
 
 -- 12) Rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as na ?
  
 SELECT 
    e.*, 
    CASE 
        WHEN rnk = 0 THEN 'na' 
        ELSE rnk 
    END AS rnkk
FROM (
    SELECT 
        c.*, 
        CAST(
            CASE 
                WHEN gold_signup_date IS NULL THEN 0 
                ELSE RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) 
            END AS CHAR
        ) AS rnk
    FROM (
        SELECT 
            a.userid, 
            a.created_date, 
            a.product_id, 
            b.gold_signup_date
        FROM 
            sales a
        LEFT JOIN 
            goldusers_signup b 
        ON 
            a.userid = b.userid 
            AND a.created_date > b.gold_signup_date
    ) AS c
) AS e;

 