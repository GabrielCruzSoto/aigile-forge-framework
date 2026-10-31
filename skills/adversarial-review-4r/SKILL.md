---
name: adversarial-review-4r
description: "Deterministic two-pass Gate G3 code review auditing Risk, Requirements, Regression, and Resilience, followed by an evidence-based false-positive refuter."
---

# Skill: Two-Pass Adversarial 4R Review (Gate G3)

## Purpose & Activation

Activate during Phase 6 (Verification & Gate G3) via `/review-4r` or the `qa` / `security` agents before any Pull Request is approved for release. Combines an uncompromising 4-dimension audit (**Pass 1**) with an adversarial technical defense (**Pass 2**) that eliminates speculative false positives using line-level codebase proof.

## Inputs

- Git diff of the feature branch against target base branch (`git diff <base>...HEAD`).
- Approved `spec.md`, `contract.md`, `odd/tasks/<ticket>-<slug>.md`, and active `profiles/*.md`.
- Latest RDD verification receipt from `.aigile/receipts/<TICKET-ID>/`.

## The 4R Audit Dimensions

### 1. Risk (Security, Privacy & Data Safety)
- Exposed secrets, hardcoded tokens, or unmasked PII/PHI/PCI in code, logs, exceptions, or cache payloads.
- Unindexed queries on transactional tables/collections, dialect incompatibilities against configured DB engine version, or cache writes without finite `TTL`.
- Injection vectors (SQLi, NoSQLi, SSRF, XSS, command injection) or missing authorization/tenant boundary checks.

### 2. Requirements (Behavioral Completeness)
- Every `S#` `Given / When / Then` scenario in `spec.md` is implemented and covered by meaningful assertions.
- Boundary conditions: null/empty inputs, timezone/decimal edge cases, duplicate webhook/request idempotency, and multi-channel parity (`Web`, `Android`, `iOS`).

### 3. Regression (Contracts & Existing Consumers)
- `N/N-1` backward compatibility preserved on REST, GraphQL, gRPC, and async event contracts.
- Shared module edits preserve behavior for existing callers; namespace rules respected (e.g., no `javax.*` / `jakarta.*` mixing).
- Existing unit and integration suites pass without skipped or weakened assertions.

### 4. Resilience (Failure Modes & Operability)
- Explicit connect/read timeouts, bounded retries, and circuit-breaker or fallback handling on outbound network calls.
- Global exception handling returns standardized error envelopes with `correlationId` and zero internal stacktrace leakage.
- Resource cleanup (streams, DB connections, goroutines, reactive subscriptions) and safe rollback/feature-flag paths.

## Deterministic Two-Pass Execution Protocol

```text
[Branch Diff + spec.md + contract.md]
                 │
                 ▼
  ┌──────────────────────────────┐
  │ Pass 1: 4R Critical Auditor  │ ──► Candidate Findings (CRITICAL / HIGH / MEDIUM / LOW)
  └──────────────────────────────┘     with exact file:line citations
                 │
                 ▼
  ┌──────────────────────────────┐
  │ Pass 2: Adversarial Refuter  │ ──► Inspects surrounding code, middleware, migrations,
  └──────────────────────────────┘     and global handlers to confirm or refute with proof
                 │
                 ▼
  ┌──────────────────────────────┐
  │ Gate G3 Verdict              │ ──► BLOCKED if any unrefuted CRITICAL or HIGH remains;
  └──────────────────────────────┘     APPROVED when 0 unrefuted CRITICAL/HIGH + valid receipt
```

### Pass 1: Critical 4R Audit
Inspect every changed file and classify candidate findings:
- `CRITICAL`: Secret/PII exposure, auth bypass, data corruption/loss, breaking production DB/contract change.
- `HIGH`: Unindexed transactional query, infinite cache TTL, missing timeout on external call, uncovered core `S#` requirement, broken N-1 client parity.
- `MEDIUM`: Missing correlation log context, suboptimal error code mapping, moderate test gap.
- `LOW`: Minor readability, dead import, non-blocking documentation polish.

### Pass 2: Adversarial False-Positive Refuter
For **every** candidate finding from Pass 1, attempt to disprove it by checking concrete repository evidence:
- Is input validation or exception masking already enforced by an upstream middleware, filter, `@ControllerAdvice`, or serializer?
- Is the database index already declared in an earlier migration script or entity annotation?
- Is timeout configuration inherited from a shared HTTP client factory?

Record one of three outcomes per finding:
- `CONFIRMED`: Risk is real; requires code remediation.
- `DOWNGRADED`: Mitigated partially; severity adjusted with cited `file:line` evidence.
- `REFUTED`: False positive disproven with exact `file:line` citation of existing safeguard.

## Hard Rules & Guardrails

- **Never Refute Without Line-Level Proof**: "Probably handled elsewhere" is invalid; cite exact file path and line numbers (`path/to/file.ext:L42-L55`).
- **Automatic Gate G3 Block**: Any `CONFIRMED` finding of severity `CRITICAL` or `HIGH`, or a missing/failing RDD receipt, sets `Gate G3: BLOCKED`.
- **Fresh Receipt After Fixes**: Remediating a confirmed finding requires re-running tests and regenerating the RDD receipt before re-evaluating Gate `G3`.

## Outputs

- `work/<TICKET-ID>/review.md` containing Pass 1 table, Pass 2 refutation proofs, final confirmed findings, and **Gate G3 Verdict** (`APPROVED` | `BLOCKED`).

## Verification Checklist

- [ ] All four dimensions (`Risk`, `Requirements`, `Regression`, `Resilience`) audited against the full diff.
- [ ] Every `REFUTED` or `DOWNGRADED` finding cites concrete `file:line` evidence in the repository.
- [ ] `Gate G3` is marked `APPROVED` only when unrefuted `CRITICAL == 0`, unrefuted `HIGH == 0`, and `./aigile receipt verify` exits `0`.
