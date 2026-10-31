---
name: data-sql-nosql-cache
description: "Pluggable stack profile for SQL, NoSQL, GraphQL, schema migrations, and distributed cache layers, enforcing declared query indexes, engine version compliance, reversible migrations, finite TTLs, and namespaced keys."
applyTo: "**/*.{sql,prisma,graphql,yaml,yml,json}"
---

# Stack Profile: Data Persistence, Migrations & Distributed Cache

## 1. Engine & Dialect Version Compliance
- Read `aff.yaml` (`stack.databases`) before authoring DDL, DML, ORM mappings, or aggregation pipelines to enforce exact engine and version compatibility (e.g., PostgreSQL 14/16, MySQL 5.7 vs 8.0, SQL Server, MongoDB, DynamoDB).
- Never emit version-incompatible features against older configured production engines (such as window functions or CTEs on MySQL `5.7`), and never use string interpolation to construct queries — bind parameters are mandatory everywhere.

## 2. Mandatory Index Coverage & Bounded Reads
- **Zero Unindexed Transactional Scans**: Every query predicate (`WHERE`, `JOIN`, `ORDER BY`, MongoDB `$match`/sort, DynamoDB partition/sort keys) hitting transactional or high-cardinality tables/collections MUST match a declared single-column or composite index following leftmost-prefix selectivity.
- **Explicit Foreign Key Indexes**: Declare supporting indexes on foreign key columns in migration scripts or schema files (`schema.prisma`, Liquibase/Flyway SQL).
- **Pagination & Narrow Projections**: Enforce bounded page limits (cursor/keyset pagination preferred for deep datasets) and select only required columns/fields; prevent `SELECT *` on wide tables and `N+1` GraphQL/ORM resolver loops (use DataLoader / batch joins).

## 3. Expand-Contract Reversible Migrations
- Author forward-compatible migrations safe for zero-downtime rolling deployments (`N` and `N-1` application versions running concurrently):
  1. **Expand**: Add nullable columns, new tables, or concurrent/online indexes (`CREATE INDEX CONCURRENTLY` where supported) without locking hot tables.
  2. **Migrate**: Dual-write and backfill in bounded batches.
  3. **Contract**: Drop deprecated columns or tighten `NOT NULL` constraints only in a subsequent release after `N-1` readers are retired.
- Pair every migration with a verified rollback script or documented non-destructive recovery procedure. Never checksum-tamper already-applied migration files.

## 4. Distributed & In-Memory Cache Standards
- **Canonical Key Convention**: Structure every cache key using the project's deterministic 5-segment hierarchy:
  ```text
  {namespace}:{domain}:{service}:{entity}:{id}
  ```
  Example: `acme:catalog:pricing-service:tier:gold_v1`.
- **Mandatory Finite `TTL`**: Every cached entry MUST specify a finite Time-To-Live (`TTL`) with optional jitter to prevent synchronized expiration stampedes. Infinite keys (`TTL` omitted or `-1`) are prohibited.
- **Invalidation & Privacy**: Document explicit invalidation/eviction triggers on writes, and never store plaintext PII, PHI, payment card numbers (PAN), or raw credentials inside cache payloads or keys.

## Gate G3 Profile Checklist
- [ ] Every query filter, join, and sort predicate is backed by a declared index, with pagination caps and narrow projections.
- [ ] SQL/NoSQL syntax matches the exact engine version configured in `aff.yaml`, and migrations follow non-locking expand-contract rules.
- [ ] Every cache operation uses `{namespace}:{domain}:{service}:{entity}:{id}`, enforces a finite `TTL`, and excludes plaintext PII/PHI/PCI.
