SET search_path TO shop;
-- ##############
-- ## Exercise #1 
-- ###############

-----------------------------------
 ---- Customers Profile ------
 -----------------------------
WITH  Emails_null AS (
    SELECT COUNT(*) AS total_rows,
        SUM(
            CASE 
                WHEN email IS NULL THEN 1
                ELSE 0
            END 
        ) AS null_emails,
        COUNT(DISTINCT email) AS distinct_email,
        COUNT(DISTINCT LOWER(email)) AS distinct_email_normalized,
        COUNT(DISTINCT city) AS distinct_city
    FROM customers
)
SELECT total_rows,
    null_emails, 

    ROUND(
           100.0 * null_emails / total_rows , 
        2) AS null_email_pct,
    distinct_email,
    distinct_email_normalized,
    distinct_city
        
FROM Emails_null ;


------------------------------------------------------
-------------- Orders Profile ------------------------
------------------------------------------------------
SELECT status,
    COUNT(*) AS status_count,
    ROUND(
        100.0 * COUNT(status) / SUM(COUNT(*)) OVER() ,
        2) status_pct

FROM orders
Group BY status 
ORDER BY status_count Desc;


-----------------------------------------------------
------------------- DQ Scorecards ------------------
-----------------------------------------------------

WITH  Emails_null AS (
    SELECT COUNT(*) AS total_rows,
        SUM(
            CASE 
                WHEN email IS NULL THEN 1
                ELSE 0
            END 
        ) AS null_emails,
        COUNT(DISTINCT email) AS distinct_email,
        COUNT(DISTINCT LOWER(email)) AS distinct_email_normalized,
        COUNT(DISTINCT city) AS distinct_city
    FROM customers
),

Profiling AS(
    SELECT total_rows,
        null_emails, 

        ROUND(
            100.0 * null_emails / total_rows , 
            2) AS null_email_pct,
        distinct_email,
        distinct_email_normalized,
        distinct_city
    FROM Emails_null
),

Quality_Score As(
    SELECT 'Customer email is not null' AS rule_name, 
        'Completeness' AS dimension, 
        total_rows AS total_checked,
        null_emails AS failed_count,
        ROUND( 100.0 *  (total_rows - null_emails) / total_rows
        , 2) AS pass_pct
    FROM Profiling

    UNION ALL

    SELECT 'Customer email is unique (normalized)', 
        'Uniqueness',
        distinct_email,
        distinct_email - distinct_email_normalized,
        ROUND( 100.0 * distinct_email_normalized / distinct_email 
         , 2)
    FROM Profiling

    UNION ALL

    SELECT 'Order status is not null', 
        'Completeness', 
        Count(*) ,
        Count(*) - Count(status) ,
        ROUND(100.0 * COUNT(status) / Count(*),  2) 

    from orders
),

Payment_amount AS(
    SELECT order_id,
        SUM(quantity * unit_price) AS total_amount
    From order_items
    GROUP BY order_id
),

Check_Consistency AS (
    SELECT p_amt.order_id , 
        p_amt.total_amount,
        CASE 
            WHEN p_amt.total_amount = p.amount THEN 'Consistent'
            ELSE 'InConsistent'
        END AS checking
    FROM Payment_amount p_amt
    JOIN payments p
    ON p_amt.order_id = p.order_id
),

Check_validity As(
	SELECT 
	CASE
		WHEN o.order_date::date >= c.signup_date::date THEN 'Valid'
		ELSE 'Invalid'
	END as checking_v
FROM customers c
Join orders o
ON c.customer_id = o.customer_id
)

Select * 
FROM Quality_Score

UNION ALL

SELECT 'Payment amount equals order items total',
    'Consistency',
    COUNT(*), 
    COUNT(*) FILTER (WHERE checking = 'InConsistent'),
    ROUND( 100.0 * COUNT(*) FILTER (WHERE checking = 'Consistent') / COUNT(*)
        ,2)
FROM Check_Consistency

UNION ALL

select 'Order date is after customer signup',
    'Validity',
    COUNT(*) AS total_checked,
	COUNT(checking_v) filter (where checking_v = 'Invalid'),
	round(
	100.0 * Count(*) Filter(WHERE checking_v = 'Valid') / COUNT(*) 
	,2)
FROM Check_validity







