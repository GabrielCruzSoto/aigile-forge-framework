---
name: db-cache-guardrails
description: "Database query indexing, project-configured SQL/NoSQL dialect compliance, reversible migrations, finite cache TTL, and PII-safe caching rules."
---

# Skill: Database & Cache Engineering Guardrails

## Purpose & Activation

Activate whenever creating or modifying SQL queries, ORM entities/repositories, NoSQL document schemas/aggregations, schema migrations (Flyway, Liquibase, Prisma, Alembic, golang-migrate), or distributed/in-memory cache logic (Redis, Valkey, Memcached, Caffeine).

## Inputs

- Database engine, exact version, and cache provider declared in `aff.yaml` (`stack.databases`, `stack.cache`, `project.namespace`).
- Repository entity models, query files, index definitions, and migration scripts.

## Database Guardrails

### 1. Mandatory Query Index Verification
1. Every `WHERE`, `JOIN`, `ORDER BY`, or NoSQL filter predicate executing on transactional or high-volume tables/collections MUST be backed by a declared single-column or composite index matching leftmost-prefix selectivity rules.
2. Verify foreign keys explicitly declare supporting indexes (engines like PostgreSQL do not auto-index foreign key columns).
3. Reject full table or full collection scans on unbounded datasets (`CRITICAL`/`HIGH` in Gate `G3`).

### 2. Project-Configured Dialect & Engine Version Compliance
Read the target engine and version from `aff.yaml` before writing SQL or NoSQL syntax:
- Do not emit syntax unsupported by the project's declared production version (for example, avoid window functions `OVER()` or CTEs `WITH` if a legacy project configures MySQL `5.7`, or avoid PostgreSQL-only operators in ANSI/H2-shared suites unless Testcontainers matches production).
- Parameterize every dynamic input via prepared statements or bind parameters; string-concatenated queries are strictly forbidden.

### 3. Bounded Reads, Pagination & Projections
1. All list/search queries MUST enforce an explicit upper `LIMIT` / page size cap (`Pageable`, cursor pagination, or keyset pagination).
2. Prefer narrow DTO/column projections over hydrating wide ORM entity graphs with eager `N+1` relationships.

### 4. Expand-Contract Reversible Migrations
1. Migrations must be non-destructive and backward-compatible with `N-1` running application instances during rolling deploys (add nullable column -> dual write/backfill -> switch reads -> enforce constraint in a subsequent release).
2. Pair every forward migration with a documented rollback strategy or down-migration script, and avoid long table locks on hot production tables.

## Cache Guardrails

### 1. Mandatory Finite TTL
- Every cached entry (`SET`, `@Cacheable`, cache client wrapper) MUST configure an explicit, finite Time-To-Live (`TTL`) aligned with domain staleness budgets.
- Unbounded / infinite `TTL` keys (`TTL = -1` or omitted expiration) are strictly prohibited.

### 2. Canonical Key Namespace Convention
Format every cache key deterministically to prevent cross-service and cross-version collisions:

```text
{namespace}:{domain}:{service}:{entity}:{id}
```

Example: `acme:checkout:order-service:order:ord_98412` (append `:v1` when payload schema evolves).

### 3. Stampede & Miss Protection
- Guard hot keys against cache stampede using jittered TTLs, single-flight/locking loaders, or short-TTL negative caching for not-found lookups where appropriate.
- Define explicit cache invalidation or write-through behavior whenever underlying records mutate.

### 4. Zero Plaintext Sensitive Data
- Never store unencrypted PII, PHI, payment card data (PCI/PAN), raw credentials, or session secrets in shared cache values or cache keys. Hash, tokenize, or encrypt sensitive fields using approved KMS/application keys before caching.

## Outputs

- Indexed schema migrations, dialect-compliant queries, and bounded repository projections.
- Explicitly namespaced, TTL-bounded, PII-safe cache configurations.

## Verification Checklist

- [ ] Every new or modified query predicate maps to an existing or newly migrated index.
- [ ] Query syntax is 100% compatible with the database engine and version declared in `aff.yaml`.
- [ ] Every cache key follows `{namespace}:{domain}:{service}:{entity}:{id}` and sets an explicit finite `TTL`.
- [ ] Zero plaintext PII/PHI/PCI values appear in cache keys, cached payloads, or SQL debug logs.
