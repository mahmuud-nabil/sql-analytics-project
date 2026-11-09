SET search_path TO shop;

-- =========================================
-- Exercise 1 + 2 + 3: Monthly revenue & running total (2025)
-- =========================================
WITH monthly_revenue AS (
    SELECT
        date_trunc('month', payment_date)::date AS month,
        SUM(amount)                             AS revenue
    FROM payments
    WHERE payment_date >= '2025-01-01'
      AND payment_date <  '2026-01-01'
    GROUP BY 1
),

monthly_metrics AS(
    SELECT month,
        revenue,

        SUM(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,

        LAG(revenue, 1) OVER( 
        ORDER BY month
        ) AS prev_month_revenue,

        AVG(revenue) OVER (
        ORDER BY month  
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3m

    FROM monthly_revenue
)

SELECT month,
    revenue,
    prev_month_revenue,
    running_total,
    ROUND(
        (revenue - prev_month_revenue)/ NULLIF(prev_month_revenue,0) *100 , 
        1
        ) AS mom_growth_pct,

        CASE 
            WHEN COUNT(*) OVER(
                    ORDER BY month 
                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) =3
            THEN ROUND(moving_avg_3m,2)
        END AS moving_avg_3m
    
FROM monthly_metrics
ORDER BY month;

--------------------------------------------------------
 ----------------- EXERCISE #5 LTV --------------------
 -----------------------------------------------------
WITH customer_ltv AS (
    SELECT
        o.customer_id                AS customer_id,
        SUM(p.amount)                AS ltv,
        COUNT(DISTINCT o.order_id) AS orders_count
    FROM payments p
    JOIN orders o ON p.order_id = o.order_id
    GROUP BY customer_id
),

customer_segments AS (
    SELECT
        customer_id,
        ltv,
        orders_count,
        NTILE(4) OVER (ORDER BY ltv DESC) AS quartile
    FROM customer_ltv
)

SELECT
    customer_id,
    ltv,
    orders_count,
    CASE quartile
        WHEN 1 THEN 'Top'
        WHEN 2 THEN 'High'
        WHEN 3 THEN 'Medium'
        WHEN 4 THEN 'Low'
    END AS segment
FROM customer_segments
ORDER BY ltv DESC;

--------------------------------------------------------------------------------
 ------------ EXERCISE #6 Num of Days between orders --------------------
 ----------------------------------------------------------------------------

WITH Customers_orders AS(
    SELECT customer_id,
    order_date as cur_ord_date,

    LAG(order_date) over(
        PARTITION BY customer_id
        ORDER BY order_date
    ) prev_ord_date

FROM orders
),

Period_Diff AS(
    SELECT customer_id,
        cur_ord_date ::date - prev_ord_date ::date AS days_diff
    FROM Customers_orders
)
SELECT ROUND(AVG(days_diff), 1) AS avg_days_between_orders
FROM Period_Diff;
/*
SELECT customer_id,
     COUNT(days_diff) AS gaps_count,
     ROUND(AVG(days_diff),1) as avg_days_between_orders
FROM Period_Diff
Group by customer_id
ORDER BY customer_id;
*/
 



