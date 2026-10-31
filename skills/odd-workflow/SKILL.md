---
name: odd-workflow
description: "Organic Driven Development protocol for proportional feature sizing, single living task documents (odd/tasks/<ticket>-<slug>.md), and cold-resumable execution."
---

# Skill: Organic Driven Development (ODD) Workflow

## Purpose & Activation

Activate at the beginning of every feature, bugfix, refactoring, or architectural initiative to determine proportional ceremony and maintain a single source of truth in `odd/tasks/<ticket>-<slug>.md`. ODD replaces rigid boilerplate pipelines with adaptive rigor scaled by comprehension, risk, and resumability.

## Inputs

- User request or issue ticket identifier (e.g., `PROJ-101` or `<TICKET-ID>`).
- Project configuration in `aff.yaml` (topology, branch rules, active profiles, test runner, and gates `G1`–`G4`).
- Current repository state (`git status`, active branch, existing `odd/tasks/*.md` files).

## Sizing & Routing Protocol

Evaluate three orthogonal axes before choosing the workflow path:

1. **Comprehension**: Are acceptance criteria, edge cases, and domain invariants unambiguous, or do hidden assumptions exist?
2. **Risk**: Does the change touch authentication, secrets, payment/financial calculations, PII/PHI/PCI handling, schema migrations, shared contracts, or CI/CD pipelines?
3. **Resumability**: Would a fresh engineer or clean agent session lose critical context if execution stopped mid-flight?

### Routing Matrix

| Tier | Condition | Required Artifacts & Gates |
|------|-----------|----------------------------|
| **Direct (Micro)** | Clear scope, single module, low risk, trivial rollback | Inline TDD + verification check; no `odd/tasks/` file needed unless requested |
| **Standard ODD** | Multi-step change, moderate risk, needs cold-resume tracking | `odd/tasks/<ticket>-<slug>.md` + Gate `G1` (if elicited) + Gate `G3` (4R + receipt) |
| **Full Lifecycle ODD** | Cross-repo/multi-channel, contract changes, high-risk domain or schema | `odd/tasks/<ticket>-<slug>.md` + `spec.md` (`G1`) + `contract.md` (`G2`) + 4R & receipt (`G3`) + PR package (`G4`) |

## Canonical Feature Document Schema

Every tracked feature document at `odd/tasks/<ticket>-<slug>.md` MUST contain these three verbatim level-2 headings in order:

```markdown
Objective: <single-sentence verifiable outcome>
Branch: `<type>/<ticket>-<slug>` | Delivery strategy: `single-pr` | `stacked-prs`
Test runner: `<exact test command>` | Engram mirror: `odd/<slug>/tasks` (optional)

## Specs

- **S1 — <Requirement Title>**:
  - User verbatim: "<exact quote or ticket statement>"
  - Scope & Acceptance Criteria: <observable behavior and invariants>
  - Applicable Check: `<deterministic command or assertion>`

## Tasks

- [ ] **T1** (`S1`) | Route: `inline` | <bounded work unit description> | Status: pending | Evidence: pending

## Log

- **L1 (YYYY-MM-DD)**: "<initial request and key architectural decisions>"
```

## Step-by-Step Execution Rules

1. **Inspect Existing Tasks First**: Check `odd/tasks/` before creating a new file to avoid duplicate tracking for the same ticket.
2. **Capture Verbatim Intent**: Record exact user statements or ticket acceptance criteria under `## Specs` (`S1`, `S2`, ...) before decomposing `## Tasks`.
3. **Decompose Atomic Tasks**: Map every `T#` to one or more `S#` identifiers, declare execution route (`inline` by default; `delegated` only for genuinely independent parallel surfaces or isolated adversarial verification), and define verification commands.
4. **Update State Continuously**: Transition each `T#` through `pending` -> `in-progress` -> `done` with concrete verification output recorded in `Evidence:`.
5. **Append Chronological Log**: Record scope clarifications, gate approvals (`G1`–`G4`), blockers, and commit SHAs in `## Log` so any session can cold-resume without re-reading chat history.
6. **Optional Memory Mirror**: When `capabilities.mode: mcp` includes Engram, mirror updated task state to topic key `odd/<slug>/tasks` with `capture_prompt: false`.

## Hard Rules & Guardrails

- Never rename or omit the verbatim headers `## Specs`, `## Tasks`, or `## Log`.
- Never mark a task `[x]` or `Status: done` while its `Applicable Check` is failing or unexecuted.
- Never bypass Gate `G1` when open P1 questions exist, Gate `G2` when cross-service contracts change, or Gate `G3` before opening a Pull Request.

## Outputs

- Living feature tracking file `odd/tasks/<ticket>-<slug>.md`.
- Traceable mapping from `S#` specifications to `T#` tasks, commits, and SHA256 execution receipts.

## Verification Checklist

- [ ] `odd/tasks/<ticket>-<slug>.md` contains verbatim `## Specs`, `## Tasks`, and `## Log` sections.
- [ ] Every `S#` item is covered by at least one `T#` task and has a runnable `Applicable Check`.
- [ ] Completed tasks include observed command evidence rather than unverified claims.
