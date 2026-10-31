# 8-Phase Lifecycle, Human Gates (`G1`–`G4`), 4R Review & RDD Receipts

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/guides/lifecycle-gates-and-4r.md`](../../es/guides/lifecycle-gates-and-4r.md)

## 1. Proportional Ticket Sizing (`S / M / L / H`)

Not every change requires full architectural ceremony. During **Phase 0**, the `orchestrator` classifies each ticket:

| Size | Typical Scope | Required Artifacts & Gates |
|---|---|---|
| **`S` (Small)** | Contained bug fix, documentation, or config tweak (< 80 LoC, single repo, no contract change) | `state.yaml`, automated tests, `G3` 4R check, `G4` receipt. |
| **`M` (Medium)** | Standard feature or refactor within one service/app (~80–300 LoC) | `spec.md` (`G1`), ODD tasks, tests, `review-4r.md` (`G3`), `G4` receipt. |
| **`L` (Large)** | Cross-repository feature, API/schema contract update, or web/mobile parity | Full `G1` -> `G2` (`contract.md`) -> worktree slices -> `G3` -> `G4`. |
| **`H` (Hotfix)** | Production incident remediation | Expedited root-cause spec, regression test, `G3` security/4R check, `G4` receipt, post-incident curation. |

---

## 2. Human Verification Gates (`G1`–`G4`)

1. **Gate `G1` — Discovery & Specification Sign-Off**
   - Confirms business acceptance criteria, edge cases, non-functional requirements, and PERT effort estimate in `work/<TICKET-ID>/spec.md`.
   - Teams requiring separate technical and product sign-off set `governance.dual_po_approval: true` to split `G1` into `G1a` (Technical Lead) and `G1b` (Product Owner).
2. **Gate `G2` — Architecture & Contract-First Sign-Off**
   - Freezes API schemas (OpenAPI/AsyncAPI/GraphQL), database migrations, and multi-channel parity contracts (`work/<TICKET-ID>/contract.md`) before parallel implementation starts.
3. **Gate `G3` — Clean-Session 4R & Security Sign-Off**
   - Requires an adversarial review (`work/<TICKET-ID>/review-4r.md`) and clean `./aigile scan` output prior to merge.
4. **Gate `G4` — Release Readiness & Cryptographic Receipt**
   - Verifies passing test suites and tamper-evident SHA256 execution receipts (`work/<TICKET-ID>/evidence/receipt-G4.json`).

---

## 3. Adversarial 4R Review Protocol

Before Gate `G3`, the `reviewer` agent evaluates the diff across four orthogonal dimensions:

- **Risk:** Authentication/authorization flaws, injection vectors, secret/PII exposure, unsafe migrations, or blast-radius hazards.
- **Requirements:** Traceability from every acceptance criterion in `spec.md` and `contract.md` to concrete code and assertions.
- **Regression:** Backward compatibility of APIs, database schemas, shared libraries, and existing test suites.
- **Resilience:** Timeouts, bounded retries, idempotency keys, graceful degradation, observability, and rollback safety.

---

## 4. Receipt-Driven Development (`./aigile receipt`)

AFF replaces unverified completion claims with deterministic SHA256 JSON receipts:

```bash
# Execute test suite and generate a signed Gate G4 receipt
./aigile receipt generate PROJ-101 G4 -- bash -c "npm test && npm run lint"

# Verify cryptographic integrity and current git HEAD alignment
./aigile receipt verify work/PROJ-101/evidence/receipt-G4.json --verify-head
```

Each receipt binds `ticket_id`, `gate`, `command`, `exit_code`, `timestamp_utc`, `git_head`, `working_tree_diff_sha256`, and `output_sha256` under a canonical `receipt_sha256` digest. Modifying any field invalidates verification with a non-zero exit code.

---

## 5. Session & Worktree Continuity

```bash
# Start a ticket session and isolated worktree
./aigile session start PROJ-101
./aigile worktree create PROJ-101

# Record a checkpoint before switching context (never use git stash)
./aigile worktree checkpoint PROJ-101 "Completed contract validation"
./aigile session checkpoint "Completed contract validation; ready for G3 review"

# Resume later from any harness
./aigile session resume PROJ-101
```
