# System Architecture & Repository Map

- **Project:** `{{PROJECT_NAME}}` (`{{PROJECT_ID}}`)
- **Workspace Topology:** `{{TOPOLOGY}}`
- **Last Updated:** `YYYY-MM-DD`

---

## 1. Repository & Service Catalog

| Repository ID | Lane | Stack Profile | Runtime / Platform | Primary Data / Cache Store | Sensitive Scope |
|---|---|---|---|---|---|
| `backend-api` | `backend` | `backend-jvm-spring` / `backend-node-ts` | Container / Serverless | PostgreSQL + Redis | `none` |
| `web-app` | `frontend` | `frontend-web` | Static CDN / SSR | Browser session (contract-driven) | `none` |

---

## 2. Integration & Contract Boundaries
- **Synchronous APIs:** REST/OpenAPI or gRPC with `X-Correlation-Id` / `traceparent` propagation and explicit outbound timeouts.
- **Asynchronous Events:** Broker topics, schema evolution policy (N/N-1 backwards compatible), and consumer idempotency guarantees.

---

## 3. Data & Cache Invariants
- **Database Indexing:** Every transactional query predicate must map to a declared single or compound index.
- **Cache Key Namespace:** `{namespace}:{domain}:{service}:{entity}:{id}` with mandatory finite `TTL` and zero plaintext sensitive payloads.
