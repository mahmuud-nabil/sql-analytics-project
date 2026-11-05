-- =====================================================================
-- 01_schema.sql
-- E-commerce SQL Analytics Project — table definitions
-- Target: PostgreSQL 16
--
-- Run against the "ecommerce" database:
--   CREATE DATABASE ecommerce;   (once, from the "postgres" database)
--
-- Re-runnable: drops and recreates the "shop" schema.
-- =====================================================================

DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA shop;

SET search_path TO shop;

-- ---------------------------------------------------------------------
-- customers
-- NOTE: email is intentionally NOT unique. The seed data contains
-- duplicate customers (same person, different casing / later signup)
-- so we can practise data-quality checks and deduplication (Day 4).
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(120),                 -- nullable on purpose
    city          VARCHAR(50),
    country       VARCHAR(50)  NOT NULL DEFAULT 'Saudi Arabia',
    signup_date   DATE         NOT NULL,
    updated_at    TIMESTAMP    NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name  VARCHAR(100)  NOT NULL,
    category      VARCHAR(50)   NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- orders
-- status is nullable on purpose (some "unknown" statuses in the seed)
-- to practise NULL handling in comparisons (Day 2).
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   INTEGER   NOT NULL REFERENCES customers (customer_id),
    order_date    TIMESTAMP NOT NULL,
    status        VARCHAR(20)
                  CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'returned'))
);

-- ---------------------------------------------------------------------
-- order_items  (one row per product in an order)
-- unit_price is copied at order time: product prices can change later.
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      INTEGER       NOT NULL REFERENCES orders (order_id),
    product_id    INTEGER       NOT NULL REFERENCES products (product_id),
    quantity      INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);

-- ---------------------------------------------------------------------
-- payments
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id       INTEGER       NOT NULL REFERENCES orders (order_id),
    payment_date   TIMESTAMP     NOT NULL,
    amount         NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(20)   NOT NULL
                   CHECK (payment_method IN ('mada', 'credit_card', 'apple_pay', 'stc_pay', 'cash_on_delivery'))
);

-- ---------------------------------------------------------------------
-- Indexes on foreign keys only.
-- PostgreSQL does NOT index foreign keys automatically.
-- More indexes will be added on Day 5 after measuring with EXPLAIN ANALYZE.
-- ---------------------------------------------------------------------
CREATE INDEX idx_orders_customer_id      ON orders (customer_id);
CREATE INDEX idx_order_items_order_id    ON order_items (order_id);
CREATE INDEX idx_order_items_product_id  ON order_items (product_id);
CREATE INDEX idx_payments_order_id       ON payments (order_id);

-- ---------------------------------------------------------------------
-- Data dictionary (stored as metadata — visible in pgAdmin and catalogs)
-- ---------------------------------------------------------------------
COMMENT ON SCHEMA shop IS 'E-commerce source data for the SQL analytics project';
COMMENT ON TABLE customers   IS 'One row per customer registration. May contain duplicates (data-quality exercise).';
COMMENT ON TABLE products    IS 'Product catalogue with current list price.';
COMMENT ON TABLE orders      IS 'Order header: who ordered, when, and current status.';
COMMENT ON TABLE order_items IS 'Order lines. unit_price is the price at the time of the order.';
COMMENT ON TABLE payments    IS 'Payments received against orders.';
COMMENT ON COLUMN orders.status      IS 'Order lifecycle status. NULL = status unknown (legacy records).';
COMMENT ON COLUMN customers.email    IS 'Not unique and nullable — cleaned in the curated layer.';
