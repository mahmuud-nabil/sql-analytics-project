SET search_path TO shop;

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
)

SELECT 'Customer email is not null' AS rule_name, 
    'Completeness' AS dimension, 
    total_rows AS total_checked,
    null_emails AS failed_count,
   ROUND( 100.0 * distinct_email /  total_rows , 2) AS pass_pct
FROM Profiling

UNION ALL

SELECT 'Customer email is unique (normalized)', 
    'Uniqueness',
    total_rows,
    distinct_email - distinct_email_normalized,
    ROUND( 100.0 * distinct_email /  total_rows , 2)
FROM Profiling;




