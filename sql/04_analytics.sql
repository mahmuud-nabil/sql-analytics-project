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
