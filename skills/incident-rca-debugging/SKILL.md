---
name: incident-rca-debugging
description: "Structured Root Cause Analysis workflow using correlation IDs, hypothesis elimination, isolated failing reproduction tests, blast-radius audits, and postmortem curation."
---

# Skill: Incident Root Cause Analysis (RCA) & Deterministic Debugging

## Purpose & Activation

Activate via `/rca` or `/hotfix` whenever triaging a production incident, regression defect, flaky test failure, latency spike, or cross-service integration bug (`<TICKET-ID>`, e.g., `PROJ-101`). Replaces trial-and-error patching with evidence-driven Root Cause Analysis.

## Inputs

- Incident symptom description, sanitized error payload, HTTP status code, and correlation identifier (`X-Correlation-Id`, `X-Request-Id`, or `traceparent`).
- Affected repository versions, recent deployment commit range (`git log`), `contract.md`, and curated runbooks in `knowledge/`.

## 5-Step RCA & Remediation Protocol

### Step 1: Sanitize & Reconstruct the Timeline
1. Strip any customer PII/PHI/PCI or live tokens from pasted stacktraces, payloads, or log excerpts before storing them in `odd/tasks/` or `work/<TICKET-ID>/rca.md`.
2. Trace the request path across client -> gateway -> backend service -> database/cache/downstream dependency using the correlation ID and exact UTC timestamps.
3. Check `git log` across affected components to correlate symptom onset with recent code, config, dependency, or schema changes.

### Step 2: Build a Falsifiable Hypothesis Matrix
List 2–4 concrete candidate root causes (`H1`..`H4`) and test each against code and trace evidence:

| ID | Candidate Root Cause | Expected Evidence if True | Observed Evidence | Status |
|----|----------------------|---------------------------|-------------------|--------|
| H1 | Null nested field on legacy N-1 payload | `NullPointerException` / `TypeError` at mapper line | Confirmed at `OrderMapper:L48` | **ROOT CAUSE** |
| H2 | Downstream timeout under burst load | `504` / timeout log > 3000ms | Upstream responded in 18ms | Disproven |

Never propose a code fix until at least one hypothesis is **proven** against exact code lines and execution state.

### Step 3: Write Isolated Reproduction Test First (RED)
1. Encode the exact failing input, timing race, or boundary condition in an automated unit or integration test using synthetic fixtures.
2. Run the test in the foreground and confirm it reproduces the exact failure deterministically.

### Step 4: Minimal Fix & Blast-Radius Audit (GREEN)
1. Apply the smallest architectural fix that eliminates the root cause (not merely catching and swallowing the symptom).
2. Audit **sibling call sites and channels**:
   - Do other endpoints, consumers, or mobile/web clients exhibit the same pattern?
   - Does the fix preserve `N/N-1` contract compatibility?
3. Run the reproduction test plus full module regression tests and generate a SHA256 receipt via `./aigile receipt run`.

### Step 5: Postmortem & Preventive Guardrail Curation
Document blameless lessons learned so the failure class cannot recur silently:
- **Root Cause**: Technical mechanism (5 Whys).
- **Detection Gap**: Why existing tests, linters, or alerts missed it.
- **Preventive Action**: New test case, updated `profiles/*.md` rule, schema constraint, or alert threshold curated into `knowledge/`.

## Hard Rules & Guardrails

- **No Blind Speculative Fixes**: Never stack "try adding a null check / retry / sleep" edits without proving the failure mechanism first.
- **Never Delete or Weaken Failing Tests**: Fix the defect or update tests only when requirements intentionally changed with human approval.
- **Zero Production Secret/PII Ingestion**: Redact live identifiers immediately (`USER-MOCK-REDACTED`).

## Outputs

- `work/<TICKET-ID>/rca.md` (timeline, hypothesis matrix, root cause proof, blast-radius check, rollback plan, and preventive actions).
- Automated regression test + minimal verified fix backed by an RDD receipt.
- Optional runbook or ADR update in `knowledge/architecture/`.

## Verification Checklist

- [ ] Root cause proven with exact `file:line` evidence rather than guesswork.
- [ ] Automated reproduction test failed before the fix (`RED`) and passes after the fix (`GREEN`).
- [ ] Sibling call sites and multi-channel consumers audited for identical vulnerability or regression impact.
