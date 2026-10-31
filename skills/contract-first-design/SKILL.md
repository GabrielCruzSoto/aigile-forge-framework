---
name: contract-first-design
description: "Contract-first API and event design across OpenAPI 3.1, AsyncAPI, GraphQL, and Protobuf with N/N-1 backward compatibility and synthetic mocks for parallel execution."
---

# Skill: Contract-First Design & Mock-Driven Parallelism (Gate G2)

## Purpose & Activation

Activate during Phase 3 (Architecture & Contract Design) via `/contract` or the `architect` agent whenever a change introduces or modifies an HTTP endpoint, GraphQL schema, gRPC service, webhook, or asynchronous event message. Approving `contract.md` at **Gate G2** decouples backend, web, and mobile engineering streams so teams build in parallel against deterministic contracts.

## Inputs

- Approved `spec.md` (`Gate G1: APPROVED`) for `<TICKET-ID>` (e.g., `PROJ-101`).
- Existing API specs, DTO definitions, event schemas, and consumer matrix across workspace repositories.
- `aff.yaml` communication conventions (correlation headers, versioning rules, error envelope schema).

## Step-by-Step Workflow

### 1. Select Canonical Contract Formalism
Match the protocol used by the target service:
- **REST / HTTP JSON**: OpenAPI `3.1.0` YAML/JSON snippet with explicit path versioning (`/api/v1/...`), HTTP methods, status codes, and JSON Schema constraints.
- **Event / Messaging (Kafka, RabbitMQ, Pub/Sub, SQS)**: AsyncAPI `2.6+` / `3.0` channel definition with event name, schema version, partition/routing key, and `idempotencyKey`.
- **GraphQL**: SDL type/input/mutation definitions with explicit nullability (`!`) and pagination connections.
- **gRPC**: `.proto` (`proto3`) service and message definitions with reserved field numbers for retired attributes.

### 2. Enforce N / N-1 Backward Compatibility
Audit existing consumers (Web, Android, iOS, partner integrations, async workers):
1. **Additive-Only Evolution**: New request fields MUST be optional or carry safe server defaults; new response fields MUST not remove, rename, or change the type of existing fields.
2. **Breaking Change Protocol**: If a breaking change is unavoidable, introduce a new versioned route/topic (`/api/v2/...`), document the deprecation sunset timeline, and explicitly flag `BREAKING_CHANGE: true` for Gate `G2` sign-off.
3. **Enum Tolerance**: Instruct client parsers to handle unknown future enum values gracefully (`UNKNOWN` fallback).

### 3. Standardize Headers, Idempotency & Error Catalog
- **Traceability Headers**: Require `X-Correlation-Id` (or W3C `traceparent`) propagation on every request and error response.
- **State-Mutating Idempotency**: Require `Idempotency-Key` header or payload key on non-idempotent `POST` / payment / order / provisioning operations.
- **Canonical Error Envelope**: Define deterministic machine-readable `code`, localized-key or safe `message`, `correlationId`, and field-level `details[]` without exposing internal stacktraces or SQL errors.

### 4. Generate Synthetic Mock Fixtures
Provide ready-to-consume mock payloads (`200/201` success, `400/422` validation failure, `401/403` auth failure, `409` conflict, `503` downstream timeout) using synthetic data (`ID-MOCK-1001`) so Frontend and Mobile teams start implementation immediately after Gate `G2`.

## Hard Rules & Guardrails

- **No Implementation Before Gate G2 on Cross-Boundary Work**: Do not write controller, client SDK, or UI integration code that invents undocumented payload fields outside `contract.md`.
- **Server-Owned Calculations**: Pricing, taxes, discounts, eligibility, balances, and authorization decisions belong in backend responses; never require clients to compute domain formulas locally.
- **Zero Sensitive Examples**: Mock payloads must use synthetic identifiers (`USER-MOCK-01`, `TOKEN-MOCK-REDACTED`).

## Outputs

- `work/<TICKET-ID>/contract.md` (plus updated OpenAPI / AsyncAPI / GraphQL / `.proto` spec files in target repositories when applicable).
- Synthetic mock fixtures for Web, Mobile, and Backend contract tests.
- Explicit **Gate G2 Readiness Verdict** (`READY_FOR_G2_APPROVAL` | `APPROVED` | `BLOCKED`).

## Verification Checklist

- [ ] Every endpoint/event in `spec.md` has exact request, response, header, and error definitions in `contract.md`.
- [ ] `N/N-1` backward compatibility is verified against existing Web and Mobile consumers (especially phased mobile store rollouts).
- [ ] Synthetic mock fixtures cover both happy-path and documented error codes.
