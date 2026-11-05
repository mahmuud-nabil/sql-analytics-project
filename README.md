# SQL Analytics Project — E-commerce (PostgreSQL)

Analytical SQL on a synthetic Saudi e-commerce dataset: window functions, data-quality checks, deduplication and query performance tuning.

Part of my Data Engineering learning roadmap (Phase 1 — Advanced SQL).

## Data model

```
customers 1──* orders 1──* order_items *──1 products
                  │
                  └──* payments
```

| Table | Rows | Description |
| --- | --- | --- |
| `customers` | 2,063 | Customer registrations (includes intentional duplicates) |
| `products` | 80 | 8 categories × 10 products |
| `orders` | 20,000 | Jan 2023 – Oct 2026 |
| `order_items` | ~50,000 | 1–4 lines per order, price captured at order time |
| `payments` | ~16,500 | One payment per paid / shipped / delivered / returned order |

The seed is deterministic (`setseed`), so every run produces the same data and the same query results.

### Intentional data-quality issues

The dataset includes realistic problems to practise detection and cleaning:

- ~60 duplicate customers (same person, email in different casing)
- ~3% customers with a missing email
- ~4% orders with an unknown (`NULL`) status

## How to run

Requires Docker.

```bash
# 1. Start PostgreSQL 16
docker run --name pg-docker -e POSTGRES_PASSWORD=postgres -p 5433:5432 \
  -v pgdata:/var/lib/postgresql/data -d postgres:16

# 2. Create the database
docker exec -it pg-docker psql -U postgres -c "CREATE DATABASE ecommerce;"

# 3. Build the schema and load the data
docker exec -i pg-docker psql -U postgres -d ecommerce < sql/01_schema.sql
docker exec -i pg-docker psql -U postgres -d ecommerce < sql/02_seed.sql
```

Connect with any SQL client: `localhost:5433`, database `ecommerce`, user `postgres`.

## Project structure

```
sql/
├── 01_schema.sql   # tables, constraints, indexes, comments
└── 02_seed.sql     # synthetic data generation
```

## Roadmap

- [x] Schema design and data generation
- [ ] Analytical queries: customer lifetime value, monthly revenue, running totals, MoM growth
- [ ] Data-quality checks and deduplication
- [ ] Performance tuning with `EXPLAIN ANALYZE` and indexes
