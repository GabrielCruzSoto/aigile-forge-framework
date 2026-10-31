# 8-Phase Lifecycle, Human Gates (`G1`–`G4`), 4R Review & RDD Receipts

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/guides/lifecycle-gates-and-4r.md`](../../es/guides/lifecycle-gates-and-4r.md)  
> **Related Manuals:** [Developer Workflow Manual](developer-workflow-manual.md) · [Architecture Overview](../architecture/overview.md) · [Agents & Prompts Catalog](../catalog/agents-and-prompts.md)

`aigile-forge-framework` governs software delivery through an explicit **8-phase engineering lifecycle (Phases 0–7)**, proportional ceremony sizing (`S / M / L / H`), four human sign-off gates (`G1`–`G4`), a clean-session **Two-Pass 4R Adversarial Review**, and tamper-evident **SHA256 Receipt-Driven Development (RDD)** evidence.

---

## 1. Complete 8-Phase Lifecycle Reference (Phases 0–7)

| Phase | Phase Name | Primary Actor(s) | Inputs | Outputs | Exit Criteria |
|---|---|---|---|---|---|
| **0** | **Team & Workspace Onboarding** | `onboarding` + Tech Lead | Team context, repo layout, `templates/aff.template.yaml` | `aff.yaml`, `knowledge/*.md`, projected harnesses | `./aigile doctor` and `./aigile harness check` exit `0`. |
| **1** | **Intake, Triage & Isolation** | `orchestrator` (`/aff-intake`) | Raw tracker issue, `aff.yaml` | `work/<ID>/ticket-in.md`, `state.yaml`, `worktrees/<ID>/`, active `SES-*.md` | PII/secrets redacted; `size_class` (`S/M/L/H`) recorded; isolated worktree ready. |
| **2** | **Hypothesis Elicitation & PERT** | `pm` (`/elicit-ticket`) | `ticket-in.md`, `knowledge/domain-overview.md` | `work/<ID>/elicitation.md` (hypotheses, `<= 10` P1 questions + defaults, PERT) | Stakeholder answers captured or defaults explicitly accepted. |
| **3** | **Spec Hydration & Slice Cutting** | `analyst` (`/answers-to-spec`) | Answered `elicitation.md`, `knowledge/architecture-map.md` | `work/<ID>/spec.md` (`S#`, Gherkin `AC-#`), `work/<ID>/slices/*.md` | **Gate `G1`** (`G1a`/`G1b` when `dual_po_approval: true`) approved; `artifact_sha256` recorded in `state.yaml`. |
| **4** | **Contract-First & Channel Parity** | `architect`, `security` (`/contract-first`, `/parity-check`) | Approved `spec.md`, active `profiles/*.md` | `work/<ID>/contract.md` (OpenAPI/AsyncAPI, DB indexes, cache TTLs, parity matrix) | **Gate `G2`** approved; N/N-1 backward compatibility verified; `contract_sha256` recorded in `state.yaml`. |
| **5** | **Work-Unit Planning & TDD Execution** | `delivery` (`/work-units`, 7 sub-roles) | `spec.md`, `contract.md`, `slices/*.md` | `odd/tasks/<ID>-<slug>.md`, production code + automated tests | Every unit `<= 400` LoC; Red-Green-Refactor green; English Conventional Commits; `./aigile scan` clean. |
| **6** | **Clean-Session 4R Audit & Refutation** | `reviewer`, `security`, `qa` (`/review-4r`, `/review-refuter`) | Git diff, `spec.md`, `contract.md`, `profiles/*.md` | `work/<ID>/review-4r.md`, `pr.md`, `evidence/receipt-G3.json` | **Gate `G3`** approved: zero sustained `CRITICAL`/`HIGH` findings; valid SHA256 `G3` receipt. |
| **7** | **Release Verification & Curation** | `qa`, `curator`, `orchestrator` | Approved PR, `review-4r.md`, `knowledge/` | `evidence/receipt-G4.json`, `gate-record.md`, `ticket-out.md`, curated `knowledge/` | **Gate `G4`** approved; `--verify-head` receipt valid; session closed; worktree pruned. |

---

## 2. Proportional Ceremony Matrix (`S / M / L / H`)

Governance scales strictly with blast radius so small fixes never drown in paperwork while high-risk architectural changes never bypass contracts:

| Artifact / Gate | `S` — Small (`<= 150` LoC, 1 repo, no API/schema change) | `M` — Medium (1–2 repos, standard feature/refactor) | `L` — Large (Multi-repo, schema migration, or Web/Mobile parity) | `H` — Hotfix / Production Incident |
|---|---|---|---|---|
| `ticket-in.md` & `state.yaml` | Required | Required | Required | Required (sanitized) |
| `elicitation.md` + PERT | Skipped (inline notes) | Recommended / Required | Mandatory (with `risk_buffer_days`) | Replaced by `rca.md` |
| `spec.md` & **Gate `G1`** | Streamlined inline `AC-#` | **Mandatory (`G1`)** | **Mandatory (`G1` / `G1a`+`G1b`)** | Minimal defect spec in `rca.md` |
| `contract.md` & **Gate `G2`** | Skipped (zero contract delta) | Mandatory if API/DB/cache touched | **Mandatory (`G2` + N/N-1 + Parity)** | Required only if hotfix alters schema |
| `odd/tasks/*.md` (`<= 400` LoC TDD) | Inline single unit | Mandatory | Mandatory per repository slice | Mandatory failing regression test first |
| Clean-Session 4R & **Gate `G3`** | **Mandatory** | **Mandatory** | **Mandatory** (+ `/parity-check`) | **Mandatory** (`reviewer` + `security`) |
| SHA256 Receipt & **Gate `G4`** | **Mandatory (`receipt-G4.json`)** | **Mandatory (`G3` & `G4` receipts)** | **Mandatory (`G1`–`G4` receipts)** | **Mandatory (`G3` & `G4` receipts)** |
| Post-Release `knowledge/` Curation | Optional | When domain/arch evolves | Mandatory ADR / map update | **Mandatory within 24h** |

---

## 3. Human Verification Gates (`G1`–`G4`) Checklists

### Gate `G1` — Scope & Definition of Ready (DoR) Sign-Off
- [ ] Every requirement in `work/<TICKET-ID>/spec.md` has testable Given/When/Then `AC-#` acceptance criteria including negative/error paths.
- [ ] Zero unresolved `P1` ambiguity questions remain open without explicit stakeholder confirmation.
- [ ] Out-of-scope boundaries and PERT effort estimates (when enabled) are documented.
- [ ] **Dual Approval Option (`governance.dual_po_approval: true`):**
  - **`G1a` (Technical Feasibility Sign-Off):** Technical Lead confirms architectural viability and records `gates.G1a.artifact_sha256` in `state.yaml`.
  - **`G1b` (Product / Business Sign-Off):** Product Owner confirms business scope and records `gates.G1b.tracker_ref` in `state.yaml`.
- [ ] **Mutation Rule:** Any edit to `spec.md` after `G1` approval invalidates `artifact_sha256` and requires explicit re-approval before advancing.

### Gate `G2` — Contract-First, Data Guardrails & Parity Sign-Off
- [ ] `work/<TICKET-ID>/contract.md` defines complete request/response payloads, status codes, and RFC 7807 / domain error taxonomies.
- [ ] N/N-1 backward compatibility is proven for existing consumers and rolling deployments.
- [ ] Every new SQL/NoSQL query predicate maps to a declared index, and every cache key matches `{namespace}:{domain}:{service}:{entity}:{id}` with a finite TTL.
- [ ] When `governance.multi_channel_parity: true`, the Web + Android + iOS 1:1 parity table is complete.
- [ ] `gates.G2.contract_sha256` is recorded in `state.yaml`.

### Gate `G3` — Clean-Session 4R & Security Approval
- [ ] Clean-session Pass 1 (`/review-4r`) and Pass 2 (`/review-refuter`) are recorded in `work/<TICKET-ID>/review-4r.md`.
- [ ] **Zero** `CRITICAL` or `HIGH` findings remain in `SUSTAINED (ACTION REQUIRED)` state.
- [ ] `./aigile scan` reports `0 findings` across all modified repositories.
- [ ] `work/<TICKET-ID>/evidence/receipt-G3.json` passed with `exit_code: 0`.

### Gate `G4` — Release Readiness & Knowledge Closure
- [ ] Full regression/contract verification receipt `work/<TICKET-ID>/evidence/receipt-G4.json` passes `./aigile receipt verify ... --verify-head`.
- [ ] Pull Request package (`work/<TICKET-ID>/pr.md`) includes rollback instructions and links `S#` -> commits -> receipts.
- [ ] `knowledge/` updates and `ticket-out.md` status summary are completed.

---

## 4. Two-Pass 4R Adversarial Review + Refuter Protocol

Single-pass AI code reviews suffer from two opposite pathologies: **confirmation bias** when run inside the same session that wrote the code, and **noisy false positives** when run cold without checking upstream architecture. `aigile-forge-framework` solves both with a strict two-pass protocol (`agents/reviewer.md`, `skills/adversarial-review-4r/SKILL.md`):

### Pass 1: Deterministic 4R Critical Audit (`/review-4r` in a Clean Session)
Evaluates the Git diff against `spec.md`, `contract.md`, and active `profiles/*.md` across four orthogonal dimensions:
1. **Risk:** Hardcoded secrets, PII/PCI/PHI exposure in logs or responses, SQL/command injection, broken object-level authorization, unindexed queries, missing cache TTLs, or insecure mobile storage.
2. **Requirements:** Unimplemented or partially implemented `AC-#` criteria, status-code mismatches against `contract.md`, or client-side domain logic drift.
3. **Regression:** Breaking changes to N-1 API consumers, schema migration hazards, shared module side effects, race conditions, or missing test assertions.
4. **Resilience:** Missing outbound HTTP/DB timeouts, unbounded retry storms, non-idempotent state mutations, leaked connections, or swallowed exceptions.

Every Pass 1 candidate finding must record `ID`, `Dimension`, `Severity` (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`), `file:line`, and concrete failure mechanism.

### Pass 2: Adversarial False-Positive Refutation (`/review-refuter`)
Before blocking the developer, Pass 2 challenges every Pass 1 candidate by searching global exception handlers, auth interceptors, DTO validators, Flyway/Liquibase/Prisma migrations, and existing test suites:
- **`REFUTED (CLOSED)`:** Proven mitigated elsewhere in the repository, citing the exact `file:line` and symbol that neutralizes the hazard.
- **`SUSTAINED (ACTION REQUIRED)`:** Confirmed defect with no upstream mitigation. Any sustained `CRITICAL` or `HIGH` finding sets `gates.G3.review_4r_verdict: "blocked"` until fixed and re-verified.

---

## 5. SHA256 RDD Receipt Anatomy & Tamper Verification

Generate and inspect a cryptographic receipt via `scripts/aff-receipt.sh`:

```bash
# 1. Generate a Gate G4 receipt
./aigile receipt generate PROJ-210 G4 -- pytest -q

# 2. Verify payload signature + match against current git HEAD
./aigile receipt verify work/PROJ-210/evidence/receipt-G4.json --verify-head

# 3. List all receipts for a ticket
./aigile receipt list --ticket PROJ-210
```

### Canonical JSON Receipt Anatomy (`work/PROJ-210/evidence/receipt-G4.json`)

```json
{
  "schema_version": "1.0.0",
  "ticket_id": "PROJ-210",
  "gate": "G4",
  "command": "pytest -q",
  "command_argv": [
    "pytest",
    "-q"
  ],
  "exit_code": 0,
  "status": "passed",
  "timestamp_utc": "2026-10-31T14:20:05Z",
  "git_head": "9f8c7b6a5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f00",
  "working_tree_diff_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "output_sha256": "4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a",
  "receipt_sha256": "7d9a1c3e5f8b0a2d4e6f8c1a3b5d7e9f0c2a4b6d8e0f1a3c5e7b9d1f3a5c7e90"
}
```

### How Tamper Detection Works
- **`receipt_sha256` Integrity:** Computed over all other keys sorted lexicographically with compact ASCII separators (`sort_keys=True, separators=(",", ":")`). Editing `exit_code` from `1` to `0`, altering `command`, or changing `git_head` produces a `VERIFY FAILED: receipt_sha256 mismatch (tampering detected)` error (exit code `1`).
- **Clean Working Tree Proof:** When `working_tree_diff_sha256` equals `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (the SHA256 of an empty byte stream), reviewers have mathematical proof that zero uncommitted modifications existed when the test suite passed.
- **Post-Receipt Commit Detection (`--verify-head`):** Passing `--verify-head` compares `git_head` inside the receipt against `git rev-parse HEAD`. If code was committed after the receipt was generated, verification fails until the test suite is re-run on the new `HEAD`.
