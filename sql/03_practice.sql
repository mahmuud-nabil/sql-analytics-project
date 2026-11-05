SET search_path TO shop;

-------------------------------------
-- Exercise #1  Window functions
------------------------------------
Select Category, product_name, unit_price,
ROW_NUMBER() OVER(   
    PARTITION BY category 
    ORDER BY unit_price DESC
    ) AS RowNumbers,

RANK() OVER(
    PARTITION BY category
    ORDER BY unit_price DESC
) AS RANK,

DENSE_RANK() OVER(
    PARTITION BY category
    ORDER BY unit_price DESC
) AS DENSRank
from products;

----------------------------
-- Exercise #2
----------------------------
WITH Category_orders AS (
    Select Category, product_name, unit_price,
        ROW_NUMBER() OVER(   
            PARTITION BY category 
            ORDER BY unit_price DESC
            ) AS RowNumbers,

        RANK() OVER(
            PARTITION BY category
            ORDER BY unit_price DESC
        ) AS RANK,

        DENSE_RANK() OVER(
            PARTITION BY category
            ORDER BY unit_price DESC
        ) AS DENSRank

    FROM products
) 
SELECT * 
from Category_orders
WHERE  DENSRank = 2;

-------------------------------------
-- Exercise #3
-------------------------------------
WITH CUSTOMERS_INFO AS(
    SELECT C.customer_id, 
        C.first_name, 
        C.last_name, 
        C.city, 
        O.order_id
    FROM customers C
    JOIN orders O
    ON C.customer_id = O.customer_id
),

Customers_Payments AS (
    SELECT CI.city, 
        CI.first_name, 
        CI.last_name,
        P.amount,
        DENSE_RANK() OVER(
            PARTITION BY CI.city
            ORDER BY P.amount DESC
        ) AS amount_orders
    FROM CUSTOMERS_INFO CI
    JOIN payments P
    ON CI.order_id = P.order_id
)

SELECT *
FROM Customers_Payments CP
WHERE CP.amount_orders <= 3;

-----------------------------------------
-- Exercise #3
-----------------------------------------

    -- Method #1
    -----------
SELECT COUNT(order_id) As NotCancelled_orders_count
FROM orders
WHERE status <> 'cancelled';

    -- Method #2
    -------------
SELECT COUNT(order_id) As NotCancelled_orders_count
FROM orders
WHERE status IS DISTINCT FROM 'cancelled';

 
SELECT 
    COUNT(*) FILTER (WHERE status <> 'cancelled') as WITH_NOT_EQUAL,
    COUNT(*) FILTER (WHERE status IS DISTINCT FROM 'cancelled') as WITH_Distinct_from,
    COUNT(*) FILTER (WHERE status IS NULL ) AS WITH_NULL
FROM orders;
 
---------------------------------------
--  EXERCISE #5
---------------------------------------

-- Num of orders not cancelled
-- Method 1: NOT IN
SELECT COUNT(*) AS customers_not_in
FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id
    FROM orders
    WHERE status = 'cancelled'
);

-- Method 2: NOT EXISTS (correlated)
SELECT COUNT(*) AS customers_not_exists
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id     -- الربط بالصف الخارجي
      AND o.status = 'cancelled'
);


----------------------------------------------------
-- Exercise #6
------------------------------------------------
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE EXTRACT (YEAR FROM order_date) = 2025;

EXPLAIN ANALYZE 
SELECT * FROM orders
WHERE order_date >= '2025-01-01' AND order_date <= '2026-01-01';

CREATE INDEX idx_orders_orderData ON orders(order_date);
ANALYZE orders;