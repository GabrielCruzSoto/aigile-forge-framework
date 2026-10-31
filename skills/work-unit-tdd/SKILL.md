---
name: work-unit-tdd
description: "Atomic Red-Green-Refactor implementation workflow enforcing cohesive slices, differential regression checks, and Conventional Commits without AI attribution."
---

# Skill: Atomic Work-Unit TDD & Clean Commits

## Purpose & Activation

Activate during Phase 5 (Implementation) via `/implement` or the `delivery` agent for every task `T#` defined in `odd/tasks/<ticket>-<slug>.md`. Enforces disciplined Red-Green-Refactor execution, bounded blast radius, active stack profile compliance, and clean git history.

## Inputs

- Target task `T#` and linked `S#` acceptance scenarios from `odd/tasks/<ticket>-<slug>.md` (e.g., `PROJ-101`).
- Approved `spec.md` (`Gate G1`) and `contract.md` (`Gate G2` when applicable).
- Active stack profiles from `profiles/*.md` declared in `aff.yaml`.

## Step-by-Step Red-Green-Refactor Loop

### 1. Scope & Baseline Check
1. Confirm active branch follows project branching rules (never commit directly to protected branches such as `main`, `master`, `develop`, or `production` when branch protection applies).
2. Load only the stack profiles (`profiles/*.md`) matching the files touched by the current `T#` work unit.
3. Size the slice cohesively: aim for **<= 400 lines of changed code** as an advisory readability heuristic. Split large features into sequential vertical slices (`T1`, `T2`, `T3`), but never minify code, strip comments, or split cohesive functions artificially just to hit a line count.

### 2. RED — Write Failing Behavioral Test First
1. Translate each `Given / When / Then` scenario covered by `T#` into an automated unit, slice, or integration test.
2. Execute the targeted test suite and observe it **fail for the expected behavioral reason** (not syntax or import errors).
3. Use deterministic clocks, isolated test databases/containers or in-memory fakes, and synthetic test identifiers (`ID-MOCK-1001`).

### 3. GREEN — Minimum Clean Implementation
1. Implement the domain, adapter, or UI logic required to satisfy the failing test and `contract.md`.
2. Enforce stack guardrails inline:
   - Constructor dependency injection and explicit timeouts.
   - Correlation ID propagation (`X-Correlation-Id`).
   - Indexed queries and explicit cache `TTL` where persistence/cache is touched.
3. Re-run the targeted test suite until `GREEN` (`exit_code == 0`).

### 4. REFACTOR & Differential Regression Check
1. Remove duplication, sharpen naming, and verify architectural boundaries (domain layer free of transport/framework leakage).
2. If shared utilities, base classes, schemas, or common components were modified, identify downstream callers and run their regression test suites.
3. Capture a deterministic verification receipt via `./aigile receipt run --ticket <TICKET-ID> --cmd "<test-command>"`.

### 5. Atomic Conventional Commit
When authorized to commit the completed work unit inside the target repository:
- Format: `<type>(<scope>): <concise imperative summary>` (e.g., `feat(orders): enforce idempotency key on checkout`).
- **Strictly Forbidden**: Never add `Co-Authored-By`, model names, or AI attribution trailers to commit messages.
- Stage only files belonging to the current work unit (`git status` check before commit; never stage secrets, `.env`, or unrelated untracked artifacts).

## Hard Rules & Guardrails

- **No Production Code Without Verification**: If a change alters runtime behavior, write or update automated tests before marking `T#` complete.
- **Zero Company or Environment Hardcoding**: Externalize endpoints, timeouts, and credentials to configuration.
- **One Work Unit = One Cohesive Commit**: Do not bundle unrelated formatting sweeps or opportunistic refactors into a feature slice.

## Outputs

- Clean, tested source and test changes satisfying `T#` (`S#`).
- Updated task status and observed test/receipt evidence in `odd/tasks/<ticket>-<slug>.md`.
- Atomic Conventional Commit on the feature branch (when git commit is authorized for the session).

## Verification Checklist

- [ ] RED -> GREEN test progression observed with exit code `0`.
- [ ] Differential regression tests pass for all touched shared modules.
- [ ] Commit message follows Conventional Commits with zero `Co-Authored-By` or AI trailers.
