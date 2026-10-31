---
name: rdd-receipts
description: "Receipt-Driven Development workflow that generates tamper-evident SHA256 test and verification receipts bound to the current git HEAD commit."
---

# Skill: Receipt-Driven Development (RDD) & Execution Receipts

## Purpose & Activation

Activate whenever completing a work unit (`T#`), validating Gate `G3`, or preparing a Pull Request (`G4`). Receipt-Driven Development ensures that test passes, lint checks, security scans, and build verifications are backed by deterministic cryptographic artifacts rather than conversational assertions.

## Inputs

- Exact verification command(s) declared in `aff.yaml` or `odd/tasks/<ticket>-<slug>.md` (e.g., unit tests, integration suites, static analysis, `./aigile secret-scan`).
- Clean or staged git working tree inside the target repository with a resolvable `HEAD` commit SHA.
- Ticket identifier (`<TICKET-ID>`, e.g., `PROJ-101`).

## Step-by-Step Workflow

### 1. Pre-Receipt Hygiene
1. Verify working directory and branch (`git rev-parse --abbrev-ref HEAD` and `git rev-parse HEAD`).
2. Confirm whether uncommitted modifications exist (`git status --porcelain`). Receipts generated for Gate `G3` / `G4` SHOULD run against a clean committed tree (`dirty: false`) so the `HEAD` SHA uniquely identifies the tested source snapshot.

### 2. Execute Deterministic Verification via Receipt Runner
Run verification commands through the framework CLI wrapper:

```bash
./aigile receipt run --ticket PROJ-101 --cmd "<verification-command>"
# Underlying script equivalent:
bash scripts/aff-receipt.sh run --ticket PROJ-101 --cmd "<verification-command>"
```

The receipt runner captures:
- `receipt_id`: timestamp + ticket slug identifier.
- `ticket`: `<TICKET-ID>`.
- `git_commit`: full 40-character `HEAD` SHA.
- `git_branch`: current branch name.
- `dirty_tree`: boolean flag indicating uncommitted changes at execution time.
- `command`: exact command string executed.
- `exit_code`: numeric process exit code (`0` required for passing gate).
- `duration_ms`: wall-clock execution duration.
- `output_sha256`: SHA256 digest of sanitized stdout/stderr log.
- `receipt_sha256`: canonical SHA256 signature over receipt metadata + `output_sha256`.

### 3. Verify Receipt Integrity Before Gate G3 / G4
Validate the generated receipt before attaching it to `odd/tasks/<ticket>-<slug>.md` or `pr.md`:

```bash
./aigile receipt verify --ticket PROJ-101
```

Verification confirms:
1. Receipt JSON/Markdown exists under `.aigile/receipts/<TICKET-ID>/` (or configured receipt directory).
2. `exit_code` equals `0`.
3. Recomputed `receipt_sha256` matches the recorded digest.
4. `git_commit` matches the current branch `HEAD` (`dirty_tree: false` for final PR receipts).

## Hard Rules & Guardrails

- **Never Fabricate Hashes or Output**: Never hand-write JSON receipts, invent SHA256 strings, or claim tests passed when the runner exited non-zero or could not run.
- **Unavailable Environment Disclosure**: If a required runtime (e.g., Docker daemon or language SDK) is unavailable in the current environment, record `Status: blocked (missing runtime)` explicitly instead of forging a receipt.
- **Sanitize Logs**: Ensure test runners use synthetic fixtures (`ID-MOCK-001`) so captured receipt logs never contain real credentials or production PII.
- **Stale Receipt Invalidation**: Any subsequent code edit or commit invalidates prior receipts because `git_commit` changes; re-run `./aigile receipt run` after any post-review remediation.

## Outputs

- Receipt metadata file and sanitized execution log in `.aigile/receipts/<TICKET-ID>/`.
- Compact receipt summary block (`commit`, `command`, `exit_code`, `receipt_sha256`) cited in `odd/tasks/<ticket>-<slug>.md` and `pr.md`.

## Verification Checklist

- [ ] `./aigile receipt run` executed in the foreground and exited with code `0`.
- [ ] `./aigile receipt verify` confirms `receipt_sha256` integrity and `HEAD` commit alignment.
- [ ] `dirty_tree` is `false` prior to Gate `G4` Pull Request publication.
