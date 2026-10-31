# Day-to-Day Developer Operational Manual

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/guides/developer-workflow-manual.md`](../../es/guides/developer-workflow-manual.md)  
> **Related Manuals:** [Lifecycle, Gates & 4R](lifecycle-gates-and-4r.md) · [Agents & Prompts Catalog](../catalog/agents-and-prompts.md) · [Skills & Profiles Catalog](../catalog/skills-and-profiles.md)

This manual is the practical daily runbook for software engineers, technical leads, and QA engineers working inside an **`aigile-forge-framework`** workspace. It shows exactly how to invoke role agents, skills, and slash prompts across all **five supported harnesses**, followed by four concrete operational playbooks you can execute step by step.

---

## 1. Invoking Agents, Skills & Prompts Across the 5 Harnesses

After running `./aigile harness sync all`, every harness reads the exact same canonical contracts (`aff.yaml` + `AGENTS.md`). Here is how you interact with them day to day:

### 1.1 Claude Code (`claude`)
- **Contract Loaded Automatically:** `CLAUDE.md` imports `@AGENTS.md` on startup.
- **Role Agents:** Stored in `.claude/agents/*.md` (`onboarding`, `orchestrator`, `pm`, `analyst`, `architect`, `security`, `qa`, `curator`, `delivery`, `reviewer`). Delegate to or invoke a subagent by name (e.g., *"Use the `architect` agent to run `prompts/contract-first.prompt.md` for `PROJ-101`"*).
- **Procedural Skills:** Linked at `.claude/skills/<skill-name>/SKILL.md`.
- **Clean-Session 4R Review Tip:** Open a fresh `claude` terminal session with zero prior implementation history before running Pass 1 (`/review-4r`) and Pass 2 (`/review-refuter`).

### 1.2 OpenCode (`opencode`)
- **Contract & Config:** Reads `AGENTS.md` and `opencode.json` automatically at workspace launch.
- **Role Agents:** Projected to `.opencode/agents/*.md` and `.agents/agents/*.md`. Switch agents in OpenCode's agent selector (`Tab` or `@reviewer`, `@architect`, `@delivery`) or reference `prompts/<name>.prompt.md`.
- **Procedural Skills:** Loaded from `.agents/skills/*/SKILL.md`.

### 1.3 Google Antigravity (`antigravity`)
- **Contract & Skills:** Reads `AGENTS.md` as workspace rules and loads procedural skills from `.agents/skills/*/SKILL.md` plus specialist role definitions in `.agents/agents/*.md` (and `.agents/mcp_config.json` when `harnesses.mode: "mcp"`).
- **Prompt Invocation:** Reference slash workflows directly in chat (e.g., *"Follow `prompts/aff-intake.prompt.md` as `orchestrator` for ticket `PROJ-101`"*). Antigravity can also delegate clean-session 4R reviews or parallel repository slices to bounded subagents.

### 1.4 OpenAI Codex (`codex`)
- **Contract & Skills:** Automatically discovers `AGENTS.md` at the workspace root alongside `.agents/agents/*.md` and `.agents/skills/*/SKILL.md`.
- **CLI Execution:** Pass explicit workflow prompts from the terminal or interactive prompt:
  ```bash
  codex "Act as agents/delivery.md and execute prompts/work-units.prompt.md for work/PROJ-101"
  ```

### 1.5 GitHub Copilot in VS Code (`copilot`)
- **Global & Stack Guardrails:** `.github/copilot-instructions.md` applies workspace-wide; `.github/instructions/<profile>.instructions.md` attaches automatically via `applyTo` globs whenever you edit matching `.java`, `.ts`, `.py`, `.go`, `.tsx`, `.kt`, `.swift`, `.sql`, or `Dockerfile` files.
- **Custom Agents (`@aff-*` / Agent Picker):** Select `aff-onboarding`, `aff-orchestrator`, `aff-pm`, `aff-analyst`, `aff-architect`, `aff-delivery`, `aff-reviewer`, `aff-security`, `aff-qa`, or `aff-curator` from the Copilot Chat agent mode dropdown (`.github/agents/aff-*.agent.md`).
- **Slash Prompts (`/command`):** Type `/` in Copilot Chat to invoke `.github/prompts/*.prompt.md` directly:
  - `/init-team`, `/aff-intake`, `/elicit-ticket`, `/answers-to-spec`, `/contract-first`, `/parity-check`, `/work-units`, `/review-4r`, `/review-refuter`.

---

## 2. Workflow 1: End-to-End Feature Delivery (`M` / `L`)

Suppose you pick up ticket **`PROJ-210`** (*"Add idempotent invoice refund endpoint and customer refund status view"*).

### Step 1 — Start Session & Provision Isolated Worktree
Never work directly on `main` or mix uncommitted changes with another ticket:

```bash
./aigile session start PROJ-210
./aigile worktree create PROJ-210
```
- Creates `work/sessions/SES-YYYYMMDD-HHMMSS.md` (marked `ACTIVE`).
- Creates `work/PROJ-210/evidence/` and isolated branch `feat/PROJ-210` under `worktrees/PROJ-210/<repo>/`.

### Step 2 — Intake & Proportional Triage (`/aff-intake`)
Paste the sanitized issue description into `work/PROJ-210/ticket-in.md` (or pass it to the `orchestrator` agent with `/aff-intake`):
- Strips any sensitive tokens or customer PII (`<REDACTED:pii>`).
- Classifies `PROJ-210` as size **`M`** (touches API contract + frontend view).
- Initializes `work/PROJ-210/state.yaml` at `phase: 1`.

### Step 3 — Hypothesis Elicitation & PERT Estimate (`/elicit-ticket`)
Invoke `/elicit-ticket` with the `pm` agent (`aff-pm`):
- Generates `work/PROJ-210/elicitation.md` containing domain hypotheses, at most 10 prioritized `P1` clarification questions (each with a recommended engineering default so you are never blocked indefinitely), and a 3-point PERT estimate ($E = (O + 4M + P)/6$ adjusted by `focus_factor`).
- Review answers with your Product Owner or Technical Lead and record them in `elicitation.md`.

### Step 4 — Specification Hydration & Gate `G1` (`/answers-to-spec`)
Invoke `/answers-to-spec` with the `analyst` agent (`aff-analyst`):
- Produces `work/PROJ-210/spec.md` with numbered specifications (`S1`, `S2`, ...) and deterministic Gherkin `Given / When / Then` acceptance criteria (`AC-1`, `AC-2`, ...).
- Cuts repository slice files under `work/PROJ-210/slices/` when multiple components are involved.
- **Gate `G1` Sign-Off:** Once approved by the Technical Lead (or `G1a` + `G1b` when `dual_po_approval: true`), record the `spec.md` SHA256 digest in `work/PROJ-210/state.yaml` and log a session checkpoint:
  ```bash
  ./aigile session checkpoint "Gate G1 approved for PROJ-210 spec.md"
  ```

### Step 5 — Contract-First Design & Gate `G2` (`/contract-first`)
Invoke `/contract-first` with the `architect` agent (`aff-architect`):
- Authors `work/PROJ-210/contract.md` specifying the `POST /v1/invoices/{id}/refunds` OpenAPI 3.1 schema, `Idempotency-Key` header behavior, RFC 7807 error codes, N/N-1 backward compatibility, database index on `(invoice_id, idempotency_key)`, and Redis cache key `{namespace}:billing:invoice-svc:refund:{id}` with finite TTL (`300s`).
- **Gate `G2` Sign-Off:** Architect and `security` validate `contract.md`; record `contract_sha256` in `state.yaml`.

### Step 6 — Atomic Work-Unit Planning & Red-Green-Refactor TDD (`/work-units`)
Invoke `/work-units` with the `delivery` agent (`aff-delivery`):
- Generates `odd/tasks/PROJ-210-invoice-refunds.md`, partitioning the work into cohesive units (`T1`, `T2`, `T3`), each **`<= 400` LoC** with an explicit runnable test command.
- Inside `worktrees/PROJ-210/<repo>/`, execute each unit using strict **Red-Green-Refactor**:
  1. **RED:** Write the failing unit/integration test asserting `AC-#` and `contract.md` rules; run the test runner and observe the expected failure.
  2. **GREEN:** Write the minimal production code satisfying active stack profiles (`profiles/*.md`) and `db-cache-guardrails`.
  3. **REFACTOR & SCAN:** Clean up duplication, run `./aigile scan`, and create an English Conventional Commit with **zero AI attribution**:
     ```bash
     ./aigile scan --path worktrees/PROJ-210
     git -C worktrees/PROJ-210/billing-api add -A
     git -C worktrees/PROJ-210/billing-api commit -m "feat(refunds): enforce idempotency key on refund creation"
     ```

### Step 7 — Clean-Session Two-Pass 4R Audit & Gate `G3` (`/review-4r` + `/review-refuter`)
Open a **clean session** in your harness (so the reviewer has zero self-justification bias from writing the code):
1. Run **`/review-4r`** (`reviewer` / `aff-reviewer`) to inspect the diff against `spec.md`, `contract.md`, and stack profiles across **Risk, Requirements, Regression, and Resilience**.
2. Run **`/review-refuter`** to challenge every Pass 1 candidate finding against upstream middleware, validators, migrations, and tests—marking mitigated items `REFUTED (CLOSED)` and real defects `SUSTAINED (ACTION REQUIRED)` in `work/PROJ-210/review-4r.md`.
3. Resolve any `CRITICAL` or `HIGH` sustained findings, then seal the **Gate `G3`** cryptographic receipt:
   ```bash
   ./aigile receipt generate PROJ-210 G3 -- bash -c "cd worktrees/PROJ-210/billing-api && ./mvnw test"
   ./aigile receipt verify work/PROJ-210/evidence/receipt-G3.json
   ```

### Step 8 — Release Readiness Receipt (`G4`), PR Package & Curation
1. Generate the Pull Request package (`work/PROJ-210/pr.md`) via `skills/pull-request-documentation/SKILL.md`, linking `S#` specs, contract compatibility notes, 4R verdict, and rollback steps.
2. Seal the final **Gate `G4`** release verification receipt and verify HEAD alignment:
   ```bash
   ./aigile receipt generate PROJ-210 G4 -- bash -c "./aigile scan --path worktrees/PROJ-210 && ./aigile harness check"
   ./aigile receipt verify work/PROJ-210/evidence/receipt-G4.json --verify-head
   ```
3. Update `knowledge/` via `curator` if architecture changed, render `work/PROJ-210/ticket-out.md` for your tracker, close the session, and clean up the merged worktree:
   ```bash
   ./aigile session close "PROJ-210 merged and Gate G4 verified"
   ./aigile worktree remove PROJ-210
   ```

---

## 3. Workflow 2: Urgent Context Switch in `<30` Seconds (Zero `git stash`)

`aff.yaml` enforces `guardrails.ban_git_stash: true` because unnamed stashes silently drop untracked files, conflict across branches, and lose architectural context. When an urgent request interrupts **`PROJ-210`**, freeze and switch deterministically:

```bash
# 1. Freeze in-flight code inside PROJ-210's isolated worktree (<10s)
./aigile worktree checkpoint PROJ-210 "wip(PROJ-210): completed repository layer; controller validation next"

# 2. Record exact cold-resume pointer in the session journal & close/pause (<10s)
./aigile session checkpoint "Paused PROJ-210 at T2; next step: RefundController 409 conflict test"
./aigile session close "Paused PROJ-210 to handle urgent ticket PROJ-911"

# 3. Spin up a completely isolated parallel session & worktree for PROJ-911 (<10s)
./aigile session start PROJ-911
./aigile worktree create PROJ-911
./aigile worktree list
```

Notice that `worktrees/PROJ-210/` and `worktrees/PROJ-911/` sit side by side on disk—neither branch touches the other's build cache, environment, or working tree.

### Cold-Resuming `PROJ-210` Later (Even Days Later or in a Different Harness)
```bash
./aigile session resume PROJ-210
```
`./aigile session resume PROJ-210` reactivates the exact `SES-*.md` log for `PROJ-210`, appends a UTC resume timestamp with current Git branch/SHA state, and prints the full checkpoint history to stdout so you or any AI harness can continue immediately at `T2` with zero lost context.

---

## 4. Workflow 3: Production Incident / Hotfix (`H`)

When a P1 production defect (`PROJ-911`) strikes, full `M`/`L` ceremony is compressed into a surgical, evidence-backed fast track governed by `skills/incident-rca-debugging/SKILL.md`:

1. **Isolate Immediately:**
   ```bash
   ./aigile session start PROJ-911
   ./aigile worktree create PROJ-911
   ```
2. **Triage as `H` (`/aff-intake`):** Classify `size_class: "H"` in `work/PROJ-911/state.yaml`. Ensure zero live production secrets, tokens, or customer PII from incident logs enter `ticket-in.md` (mask with `<REDACTED:...>`).
3. **Structured RCA (`incident-rca-debugging`):** Use `delivery` (`code-analyzer` read-only sub-role) to trace `X-Correlation-Id` / `traceparent` call paths, formulate falsifiable root-cause hypotheses, and document the confirmed mechanism in `work/PROJ-911/rca.md`.
4. **Mandatory Reproduction Test First (RED):** Write a minimal automated test that reproduces the exact production failure before changing a single line of production logic.
5. **Surgical Fix (GREEN):** Apply the smallest safe code change (`<= 100` LoC ideal) without bundling unrelated refactoring.
6. **Expedited Clean-Session 4R + Security Gate (`G3` & `G4`):**
   - Run `/review-4r` + `/review-refuter` in a clean session focusing on blast radius, regression risk, and rollback safety.
   - Generate tamper-evident receipts:
     ```bash
     ./aigile receipt generate PROJ-911 G3 -- bash -c "pytest tests/regression/test_proj_911.py"
     ./aigile receipt generate PROJ-911 G4 -- bash -c "./aigile scan --path worktrees/PROJ-911"
     ```
7. **24-Hour Postmortem Curation:** Within 24 hours of deployment, invoke the `curator` agent (`knowledge-checkpoint-curation`) to fold non-sensitive lessons and prevention guardrails into `knowledge/` and synchronize (`./aigile sync --sync`).

---

## 5. Workflow 4: Multi-Repository & Web/Mobile 1:1 Parity (`L`)

When `governance.multi_channel_parity: true` in `aff.yaml` and a feature (`PROJ-350`) spans a backend API plus Web, Android (Kotlin), and iOS (Swift) repositories:

```mermaid
sequenceDiagram
    participant Arch as architect (/contract-first)
    participant G2 as Human Gate G2
    participant API as delivery (Backend Repo)
    participant Web as delivery (Web Repo)
    participant Mob as delivery (Android & iOS Repos)
    participant Par as architect/qa (/parity-check)

    Arch->>G2: Freeze contract.md (OpenAPI + Parity Matrix + Mock Payloads)
    G2->>API: Approve contract_sha256 -> Provision worktrees/PROJ-350/*
    par Parallel Slice Execution Against Frozen Contract
        G2->>API: Implement API + Contract Tests
    and
        G2->>Web: Implement Web Slice Against Contract Mocks
    and
        G2->>Mob: Implement Android & iOS Slices Against Contract Mocks
    end
    API-->>Par: Slices Ready
    Web-->>Par: Slices Ready
    Mob-->>Par: Slices Ready
    Par->>Par: Execute /parity-check (Field Rules, Error Codes, Empty/Loading States, Secure Storage)
```

1. **Freeze Contract First (`/contract-first` -> Gate `G2`):** Before writing any client UI code, `contract.md` locks request/response schemas, synthetic mock payloads, validation constraints, RFC 7807 error codes, and an explicit **Cross-Channel Parity Matrix**. No client computes pricing, permissions, or business invariants locally.
2. **Provision Multi-Repo Worktrees in One Command:**
   ```bash
   ./aigile worktree create PROJ-350 repositories/core-api repositories/web-app repositories/mobile-android repositories/mobile-ios
   ```
3. **Execute Parallel Slices (`/work-units`):** Backend, Web (`frontend-web` profile), and Native Mobile (`mobile-native` profile — enforcing Android Keystore/`EncryptedSharedPreferences` and iOS `Keychain`) implement their `<= 400` LoC work units concurrently against the frozen `contract.md`.
4. **Run the Parity Audit (`/parity-check`):** Before Gate `G3`, run `/parity-check` (`skills/multi-channel-parity/SKILL.md`) to verify 1:1 alignment across Web, Android, and iOS on field validation rules, HTTP/domain error code handling, retry/timeout behavior, and accessibility semantics, then seal per-slice receipts via `./aigile receipt generate`.

---

## 6. Daily Operational Cheat Sheet & Pre-PR Self-Check

Before requesting human review at **Gate `G3`** or merging at **Gate `G4`**, run this 6-command verification sequence from your workspace root:

```bash
# 1. Confirm harness projections and canonical JSON/YAML schemas remain valid
./aigile harness check

# 2. Scan all ticket artifacts and code worktrees for accidental secrets or raw PANs
./aigile scan --path work/PROJ-210
./aigile scan --path worktrees/PROJ-210

# 3. Verify clean-session 4R review has zero sustained CRITICAL or HIGH findings
grep -E "SUSTAINED|Verdict" work/PROJ-210/review-4r.md

# 4. Generate and verify the SHA256-sealed Gate G4 test receipt against current HEAD
./aigile receipt generate PROJ-210 G4 -- bash -c "cd worktrees/PROJ-210/billing-api && ./mvnw verify"
./aigile receipt verify work/PROJ-210/evidence/receipt-G4.json --verify-head

# 5. Inspect active sessions and managed worktrees
./aigile session status
./aigile worktree list

# 6. Post-merge cleanup and knowledge synchronization
./aigile session close "Completed PROJ-210; PR merged and Gate G4 verified"
./aigile worktree remove PROJ-210
./aigile sync --sync
```

