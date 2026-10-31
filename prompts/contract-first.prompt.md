---
name: contract-first
description: Design API/event contracts, error taxonomies, N/N-1 backwards compatibility, and indexed DB/TTL cache schemas for Gate G2.
agent: architect
---

# Contract-First Interface & Data Design (`/contract-first`)

Load `agents/architect.md`, `aff.yaml`, and `skills/contract-first-design/SKILL.md`.

Using approved `work/<TICKET-ID>/spec.md` and `knowledge/architecture/system-map.md`:

1. **Define Transport & Event Contracts:**
   - Specify exact endpoints/topics, methods, headers (`X-Correlation-Id`, idempotency keys), request/response JSON schemas, HTTP status codes, and machine-readable error codes.
   - Include sanitized synthetic payloads (`<REDACTED:id>`) for parallel producer/consumer TDD.
2. **Enforce N / N-1 Backwards Compatibility:**
   - Document additive vs breaking changes and expand-and-contract rollout steps.
3. **Verify Data & Cache Guardrails:**
   - Declare required database indexes for every query predicate (`guardrails.require_db_indexes`).
   - Specify cache keys matching `{namespace}:{domain}:{service}:{entity}:{id}` with explicit finite TTLs and zero plaintext sensitive fields.

Write the result to `work/<TICKET-ID>/contract.md` using `templates/contract.template.md` for Gate `G2` approval.
