-- =====================================================================
-- 02_seed.sql
-- Generates realistic synthetic e-commerce data (Saudi market).
-- Run AFTER 01_schema.sql, in the same "ecommerce" database.
--
-- Deterministic: setseed() makes every run produce the same data,
-- so query results are reproducible on any machine.
--
-- Intentional data-quality issues (for later exercises):
--   * ~60 duplicate customers (same person, different email casing)
--   * ~3% customers with NULL email
--   * ~4% orders with NULL status
-- =====================================================================

SET search_path TO shop;
SELECT setseed(0.42);

-- ---------------------------------------------------------------------
-- 1. Products (80 rows: 8 categories x 10 products)
-- ---------------------------------------------------------------------
INSERT INTO products (product_name, category, unit_price, is_active)
SELECT
    c.category || ' Item ' || lpad(n::text, 2, '0'),
    c.category,
    round((c.min_price + random() * (c.max_price - c.min_price))::numeric, 2),
    random() > 0.08                                   -- ~8% inactive
FROM (VALUES
        ('Electronics',     150, 4500),
        ('Mobile Phones',   600, 6000),
        ('Home & Kitchen',   25,  900),
        ('Fashion',          40,  700),
        ('Beauty',           15,  350),
        ('Books',            20,  150),
        ('Sports',           30, 1200),
        ('Groceries',         5,  120)
     ) AS c(category, min_price, max_price)
CROSS JOIN generate_series(1, 10) AS n
ORDER BY c.category, n;

-- ---------------------------------------------------------------------
-- 2. Customers (2,000 base rows)
-- ---------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, city, signup_date, updated_at)
SELECT
    fn,
    ln,
    CASE WHEN random() < 0.03 THEN NULL               -- ~3% missing email
         ELSE lower(fn || '.' || ln || i || '@example.com')
    END,
    (ARRAY['Riyadh','Riyadh','Riyadh','Jeddah','Jeddah','Dammam','Makkah',
           'Madinah','Khobar','Taif','Abha','Tabuk','Buraidah'])[1 + floor(random() * 13)::int],
    sd,
    sd + (random() * 30 || ' days')::interval
FROM (
    SELECT
        i,
        (ARRAY['Mohammed','Ahmed','Abdullah','Omar','Khalid','Faisal','Saad','Nasser',
               'Fahad','Sultan','Nora','Sara','Fatimah','Reem','Lama','Hala',
               'Aisha','Maha','Dana','Yousef'])[1 + floor(random() * 20)::int]       AS fn,
        (ARRAY['Alqahtani','Alotaibi','Alghamdi','Alzahrani','Alharbi','Aldosari',
               'Alshehri','Almutairi','Alanazi','Alshammari','Hassan','Ibrahim'])[1 + floor(random() * 12)::int] AS ln,
        DATE '2023-01-01' + floor(random() * (DATE '2026-09-30' - DATE '2023-01-01'))::int AS sd
    FROM generate_series(1, 2000) AS i
) AS base;

-- ---------------------------------------------------------------------
-- 3. Duplicate customers (~60 rows)
-- Same person registered again: email in different casing,
-- later signup and later updated_at.
-- ---------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, city, signup_date, updated_at)
SELECT
    c.first_name,
    c.last_name,
    initcap(c.email),                                  -- e.g. Mohammed.Alharbi12@Example.Com
    c.city,
    c.signup_date + 30 + floor(random() * 200)::int,
    c.updated_at  + ((30 + random() * 200) || ' days')::interval
FROM customers c
WHERE c.email IS NOT NULL
  AND random() < 0.03;

-- ---------------------------------------------------------------------
-- 4. Orders (20,000 rows, placed after each customer's signup)
-- ---------------------------------------------------------------------
INSERT INTO orders (customer_id, order_date, status)
SELECT
    c.customer_id,
    c.signup_date
      + floor(random() * GREATEST(DATE '2026-10-31' - c.signup_date, 1))::int
      + (random() * 86399 || ' seconds')::interval,
    CASE
        WHEN r < 0.60 THEN 'delivered'
        WHEN r < 0.70 THEN 'shipped'
        WHEN r < 0.78 THEN 'paid'
        WHEN r < 0.83 THEN 'pending'
        WHEN r < 0.91 THEN 'cancelled'
        WHEN r < 0.96 THEN 'returned'
        ELSE NULL                                      -- ~4% unknown status
    END
FROM (
    SELECT 1 + floor(random() * 2000)::int AS cust,    -- base customers only
           random() AS r
    FROM generate_series(1, 20000)
) AS o
JOIN customers c ON c.customer_id = o.cust;

-- ---------------------------------------------------------------------
-- 5. Order items (1–4 lines per order)
-- ---------------------------------------------------------------------
WITH order_sizes AS (
    SELECT order_id, 1 + floor(random() * 4)::int AS n_items
    FROM orders
),
lines AS (
    SELECT
        os.order_id,
        1 + floor(random() * 80)::int AS product_id,
        CASE WHEN random() < 0.75 THEN 1
             WHEN random() < 0.80 THEN 2
             ELSE 3 END                AS quantity
    FROM order_sizes os
    CROSS JOIN LATERAL generate_series(1, os.n_items)
)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT l.order_id, l.product_id, l.quantity, p.unit_price
FROM lines l
JOIN products p ON p.product_id = l.product_id
ORDER BY l.order_id;

-- ---------------------------------------------------------------------
-- 6. Payments (one per paid / shipped / delivered / returned order)
-- ---------------------------------------------------------------------
INSERT INTO payments (order_id, payment_date, amount, payment_method)
SELECT
    o.order_id,
    o.order_date + (random() * 120 || ' minutes')::interval,
    t.total,
    CASE
        WHEN r < 0.40 THEN 'mada'
        WHEN r < 0.65 THEN 'apple_pay'
        WHEN r < 0.85 THEN 'credit_card'
        WHEN r < 0.95 THEN 'stc_pay'
        ELSE 'cash_on_delivery'
    END
FROM orders o
JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS total
    FROM order_items
    GROUP BY order_id
) t ON t.order_id = o.order_id
CROSS JOIN LATERAL (SELECT random() + o.order_id * 0 AS r) rnd
WHERE o.status IN ('paid', 'shipped', 'delivered', 'returned')
ORDER BY o.order_id;

-- ---------------------------------------------------------------------
-- 7. Refresh planner statistics after the bulk load
-- ---------------------------------------------------------------------
ANALYZE;

-- ---------------------------------------------------------------------
-- 8. Row-count summary (quick sanity check)
-- ---------------------------------------------------------------------
SELECT 'customers'   AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments',    COUNT(*) FROM payments;
