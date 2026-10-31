---
name: spec-crafting-hydration
description: "Hydrates answered elicitations into deterministic Given/When/Then specifications (spec.md), optional 3-point PERT estimates, and Gate G1 readiness checks."
---

# Skill: Specification Crafting & Hydration (Gate G1)

## Purpose & Activation

Activate during Phase 2 (Specification & Gate G1) via `/spec` or the `pm` / `analyst` agents once initial elicitation answers are collected (or directly when a ticket already provides complete requirements). Transforms raw inputs and resolved hypotheses into a testable, unambiguous `spec.md` specification.

## Inputs

- Ticket details (`<TICKET-ID>`, e.g., `PROJ-101`) and answered `elicitation.md` (if Phase 1 ran).
- `aff.yaml` configuration (`estimation.enabled`, `estimation.focus_factor`, `channels.parity_required`, `compliance` level).
- Affected components and domain glossary from `knowledge/`.

## Step-by-Step Workflow

### 1. Pre-Hydration Gate Check
1. Audit every `P1` question and `[HYPOTHESIS-H#]` item from elicitation.
2. If **any** `P1` question remains unanswered or any `HYPOTHESIS` affecting business logic, security, or persistence lacks human confirmation, mark `Gate G1: BLOCKED` and list the exact unresolved items. Never silently convert an unapproved hypothesis into a requirement.

### 2. Hydrate Functional Acceptance Scenarios (`Given / When / Then`)
Write deterministic scenarios grouped by capability (`S1`, `S2`, ...), covering:
- **Happy Path**: Primary user/system outcome with concrete input/output examples.
- **Validation & Domain Rejections**: Boundary values, missing fields, invalid state transitions, and expected standardized error codes.
- **Authorization & Tenant Isolation**: Role checks and cross-account access denial (`401` / `403` / `404` policy).
- **Idempotency & Concurrency**: Duplicate submission behavior, retry safety, and optimistic/pessimistic locking expectations.
- **Downstream Failure Modes**: Timeout, dependency unavailability, and graceful degradation behavior.

### 3. Declare Multi-Channel & Non-Functional Budgets
- **Channel Matrix**: Explicitly mark impact for `Backend`, `Web`, `Android`, `iOS`, and `Data/Batch` (`In Scope` vs `Out of Scope`). When both Web and Mobile are in scope, invoke `multi-channel-parity` invariants.
- **Security & Privacy Controls**: Identify fields requiring masking, encryption, or synthetic test tokens (`ID-MOCK-1001`).
- **Observability**: Required structured log events, correlation propagation, and business metrics.

### 4. Optional 3-Point PERT Estimation
When `estimation.enabled: true` in `aff.yaml`, compute transparent engineering effort per work stream:
- Formula: `Expected (E) = (Optimistic + 4 * MostLikely + Pessimistic) / 6`
- Standard Deviation: `SD = (Pessimistic - Optimistic) / 6`
- Effective Capacity Hours/Points: `Adjusted = E / focus_factor` (using `aff.yaml` `estimation.focus_factor`, e.g., `0.75`).

### 5. Gate G1 Human Sign-Off Envelope
Conclude `spec.md` with an explicit **Gate G1 Readiness Summary**:
- `Status`: `READY_FOR_G1_APPROVAL` | `APPROVED` | `BLOCKED`
- Open `P1` count (`0` required for approval)
- Unresolved `HYPOTHESIS` count (`0` required for approval)

## Hard Rules & Guardrails

- **Zero Unresolved Hypotheses in Approved Specs**: Every `[HYPOTHESIS]` must either be confirmed into a `S#` rule or explicitly deferred to `Out of Scope` with stakeholder approval.
- **Testable Predicates Only**: Ban vague adjectives ("fast", "user-friendly", "securely") unless paired with measurable criteria (e.g., "`HTTP 422` with `ERR_INVALID_AMOUNT` when `amount <= 0`").
- **Sync with ODD Task File**: Mirror approved `S#` identifiers directly into `odd/tasks/<ticket>-<slug>.md` under `## Specs`.

## Outputs

- `work/<TICKET-ID>/spec.md` (or linked specification section in `odd/tasks/<ticket>-<slug>.md`).
- Updated `## Specs` entries (`S1`..`Sn`) ready for Phase 3 (`contract-first-design`) and Phase 5 (`work-unit-tdd`).

## Verification Checklist

- [ ] Every `S#` requirement has at least one happy-path and one negative/edge `Given/When/Then` scenario.
- [ ] `Open P1 Questions == 0` and `Unconfirmed Hypotheses == 0` before Gate `G1` transitions to `APPROVED`.
- [ ] Channel scope (`Web`, `Mobile`, `Backend`, `Data`) and out-of-scope boundaries are explicitly stated.
