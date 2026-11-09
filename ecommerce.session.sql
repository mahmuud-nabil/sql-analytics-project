SET search_path TO shop;

-- =========================================
-- Exercise 1 + 2: Monthly revenue & running total (2025)
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

Runing_Total AS(
    SELECT month,
        revenue,

        SUM(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,

        LAG(revenue, 1) OVER( 
        ORDER BY month
    ) AS prev_month_revenue

    FROM monthly_revenue
    ORDER BY month
)

SELECT month,
    revenue,
    prev_month_revenue,
    running_total,
    (revenue - prev_month_revenue)/ prev_month_revenue *100 AS mom_growth_pct

FROM Runing_Total;
