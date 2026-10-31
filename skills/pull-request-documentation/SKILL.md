---
name: pull-request-documentation
description: "Generates reviewer-ready Gate G4 Pull Request packages linking S# specs, contract compatibility notes, 4R review verdicts, SHA256 receipts, and rollback plans."
---

# Skill: Pull Request Packaging & Release Readiness (Gate G4)

## Purpose & Activation

Activate during Phase 7 (Delivery & Gate G4) via `/pr` or the `delivery` agent once implementation slices (`T#`) are complete and Gate `G3` (`adversarial-review-4r` + `rdd-receipts`) is `APPROVED`. Produces structured, high-signal Pull Request documentation tailored to human reviewers and release operators.

## Inputs

- Ticket identifier (`<TICKET-ID>`, e.g., `PROJ-101`) and `odd/tasks/<ticket>-<slug>.md`.
- Approved `spec.md` (`Gate G1`), `contract.md` (`Gate G2`, if applicable), and `review.md` (`Gate G3`).
- Verified RDD receipt metadata from `.aigile/receipts/<TICKET-ID>/`.
- Branch commit log (`git log <base>..HEAD --oneline`) and changed file summary (`git diff --stat <base>...HEAD`).

## Step-by-Step Workflow

### 1. Pre-PR Gate & Hygiene Audit
Verify all release prerequisites before generating the PR package:
1. `Gate G3` verdict in `review.md` is `APPROVED` (`0` unrefuted `CRITICAL` or `HIGH` findings).
2. `./aigile receipt verify --ticket <TICKET-ID>` passes against the exact current `HEAD` commit with `dirty_tree: false`.
3. `./aigile secret-scan` passes with `0` findings.
4. Commit messages on `<base>..HEAD` follow Conventional Commits and contain **zero** `Co-Authored-By` or AI attribution trailers.

### 2. Compose Structured PR Package (`pr.md`)
Generate `work/<TICKET-ID>/pr.md` (and PR body when publishing is explicitly authorized) using this canonical structure:

```markdown
# [<TICKET-ID>] <Concise Imperative Title>

## Summary & Motivation
- **Problem / Objective**: <1-3 sentences explaining business and technical why>
- **Approach**: <key architectural choices and touched modules>

## Specification Traceability
| Spec ID | Scenario Summary | Verification Test / File | Status |
|---------|------------------|--------------------------|--------|
| S1      | ...              | `path/to/test:testName`  | Passed |

## Contract & Multi-Channel Impact
- **API / Event Changes**: `None` | `Additive (N/N-1 compatible)` | `Breaking (Versioned)`
- **Channels Affected**: `Backend` / `Web` / `Android` / `iOS`

## Gate G3 — 4R Review & Security Summary
- **Verdict**: `APPROVED`
- **Confirmed CRITICAL / HIGH**: `0 / 0`
- **Refuted False Positives**: `<count>` (documented in `review.md`)
- **Secret Scan**: `CLEAN`

## Deterministic Execution Receipt (RDD)
- **Git Commit**: `<40-char-HEAD-SHA>`
- **Command**: `<exact test/build command>`
- **Exit Code**: `0`
- **Receipt SHA256**: `<64-hex-digest>`

## Deployment, Migration & Rollback Plan
1. **Pre-Deploy / Config / Feature Flags**: <env vars, secret keys by name only, flag defaults>
2. **Database / Cache Notes**: <migration idempotency, index impact, cache key version>
3. **Rollback Procedure**: <exact safe revert steps without data loss>
```

### 3. Multi-Repository Coordination (When Applicable)
When `aff.yaml` configures `topology: multi-root` or `worktrees` spanning multiple repositories:
- Cross-link companion PRs in deployment dependency order (e.g., `1. Schema/Backend N-1 PR` -> `2. Web & Mobile Client PRs`).
- Document explicit rollout sequencing so no consumer calls an undeployed endpoint.

## Hard Rules & Guardrails

- **Never Push or Open Remote PRs Without Authorization**: Generate `pr.md` locally first; execute `git push` or `gh pr create` / `glab mr create` only when explicitly authorized by the user and Gate `G4`.
- **Truthful Evidence Only**: Every linked test file, commit SHA, and `receipt_sha256` must match real artifacts on disk.
- **Zero Secrets in PR Descriptions**: Reference secret names (`PAYMENT_WEBHOOK_SECRET`), never values.

## Outputs

- Reviewer-ready `work/<TICKET-ID>/pr.md` (plus multi-repo rollout order when applicable).
- Updated `odd/tasks/<ticket>-<slug>.md` with final Gate `G4` summary.

## Verification Checklist

- [ ] Every `S#` requirement from `spec.md` appears in the Specification Traceability table.
- [ ] `receipt_sha256` and `40-char-HEAD-SHA` match the current branch tip (`dirty_tree: false`).
- [ ] Deployment order, feature flags, and safe rollback steps are explicitly documented.
