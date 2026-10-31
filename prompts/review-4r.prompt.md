---
name: review-4r
description: Execute Pass 1 clean-session deterministic 4R code audit across Risk, Requirements, Regression, and Resilience.
agent: reviewer
---

# Deterministic 4R Critical Audit — Pass 1 (`/review-4r`)

Load `agents/reviewer.md`, `skills/adversarial-review-4r/SKILL.md`, and active `profiles/*.md`.

Operate as an independent auditor in a clean review context. Inspect the repository diff against `work/<TICKET-ID>/spec.md` and `work/<TICKET-ID>/contract.md`:

1. **Risk:** Secret/PII/PCI/PHI leakage, OWASP vulnerabilities, missing authorization checks, unindexed DB predicates, cache keys missing finite TTLs, or insecure client storage.
2. **Requirements:** Incomplete or inaccurate implementation of any `AC-#` Given/When/Then scenario or `contract.md` schema/error code.
3. **Regression:** Breaking N/N-1 changes, unintended side effects, missing edge-case tests, or concurrency hazards.
4. **Resilience:** Missing timeouts, non-idempotent retries, unclosed resources, transaction boundary bugs, or swallowed errors.

Write Pass 1 findings (with exact `file:line`, dimension, severity `CRITICAL|HIGH|MEDIUM|LOW`, and failure proof) to `work/<TICKET-ID>/review-4r.md` using `templates/review-4r.template.md`, then proceed to `/review-refuter`.
