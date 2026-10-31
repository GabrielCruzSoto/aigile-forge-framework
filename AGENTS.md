# AGENTS.md — aigile-forge-framework (Universal Operational Contract)

> Canonical operational contract, architecture specification, and catalog index for the **`aigile-forge-framework`**.
> Natively compatible with **Claude Code**, **OpenCode**, **Google Antigravity**, **OpenAI Codex**, and **GitHub Copilot** through a single declarative source of truth (`aff.yaml` + `AGENTS.md`).
> Strictly agnostic to any specific company, vendor, industry domain, or team structure.

---

## 1. Universal Architecture & Operating Modes

aigile-forge-framework unifies CLI/agentic harnesses and IDE-native assistants around one canonical repository tree (`aff.yaml`, `AGENTS.md`, `agents/`, `skills/`, `profiles/`, `prompts/`, `templates/`, `mcp/`, `configs/`). Deterministic projection via `./aigile harness sync` (backed by `scripts/aff-harness.sh`) materializes native configuration paths without manual duplication:

| Harness | Projected Instructions | Projected Agents & Prompts | Projected Skills | MCP Descriptor (`mcp` mode) |
|---|---|---|---|---|
| **Claude Code** | `CLAUDE.md` (`@AGENTS.md`) | `.claude/agents/*.md` | `.claude/skills/` | `.mcp.json` |
| **OpenCode** | `AGENTS.md` | `.opencode/agents/*.md` | `.agents/skills/` | `opencode.json` |
| **Antigravity** | `AGENTS.md` | `.agents/rules/` + `agents/*.md` | `.agents/skills/` | `.agents/mcp_config.json` |
| **Codex** | `AGENTS.md` | `agents/*.md` | `.agents/skills/` | `configs/harnesses.json` / MCP env |
| **GitHub Copilot** | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` | `.github/agents/aff-*.agent.md` + `.github/prompts/*.prompt.md` | `.github/skills/` | Zero-MCP native (IDE declarative) |

### Operating Modes (`harnesses.mode` in `aff.yaml`)
1. **`zero-mcp` Mode (Default — Strict Corporate / Air-Gapped Ready):**
   - Operates 100% declaratively with local Markdown contracts, slash prompts, procedural skills, and POSIX shell scripts.
   - Emits **zero** external MCP server descriptors (`.mcp.json` and `.agents/mcp_config.json` are omitted), requires zero background daemons, and leaves zero unapproved network footprint.
2. **`mcp` / `cortex-ai` Mode (Connected Second-Brain Mode):**
   - Activates parameterized MCP server fragments from `mcp/*.json` (`engram`, `codegraph`, `google-drive`, `notebooklm`) using environment variable placeholders (`${ENV_VAR}`).
   - Enables persistent cross-session memory pointers via Engram, semantic AST impact analysis via CodeGraph, canonical document storage in Google Drive, and derived semantic indexing in NotebookLM (`skills/cortex-ai-*`).

---

## 2. Workspace Topologies (`workspace.topology` in `aff.yaml`)

Teams select the isolation topology that matches their repository architecture:

1. **`single-repo`:** Framework governance, `odd/tasks/`, `work/<TICKET-ID>/`, and application source code coexist inside a single repository using standard feature branches.
2. **`worktrees` (Default for Multi-Stream / Parallel Tickets):** Each active ticket (`PROJ-101`) isolates code execution inside dedicated Git worktrees under `worktrees/<TICKET-ID>/<repo>/`, managed via `./aigile worktree` (`scripts/aff-worktree.sh`), while planning and governance artifacts remain in `work/<TICKET-ID>/`.
3. **`multi-root` (IDE Multi-Repository Hub):** Generates `<project-id>.code-workspace` from `templates/workspace.code-workspace.template.json` with `00-Project-Hub` as the governance hub alongside sibling service, web, and mobile repositories, keeping AI governance out of remote application Git history when required.

---

## 3. Core Agents (`agents/*.md`) & Delivery Sub-Roles

### 3.1 Ten Core Role Agents

| Agent | Canonical File | Copilot Projection | Primary Responsibility |
|---|---|---|---|
| **`onboarding`** | `agents/onboarding.md` | `.github/agents/aff-onboarding.agent.md` | Conducts the 6-dimension team and project discovery interview to bootstrap `aff.yaml` and `knowledge/`. |
| **`orchestrator`** | `agents/orchestrator.md` | `.github/agents/aff-orchestrator.agent.md` | Triages incoming tickets (`S/M/L/H`), manages workspace/worktree isolation, checkpoints, and enforces `G1`–`G4` gate SHAs in `state.yaml`. |
| **`pm`** | `agents/pm.md` | `.github/agents/aff-pm.agent.md` | Formulates domain hypotheses, up to 10 P1 clarification questions with recommended defaults, and optional 3-point PERT estimates with focus factor. |
| **`analyst`** | `agents/analyst.md` | `.github/agents/aff-analyst.agent.md` | Hydrates refined answers into `spec.md` with Given/When/Then acceptance criteria, cuts cross-repo `slices/`, and validates Gate `G1` (DoR). |
| **`architect`** | `agents/architect.md` | `.github/agents/aff-architect.agent.md` | Designs API/event contracts (`contract.md`), enforces N/N-1 backwards compatibility, certifies optional 1:1 multi-channel parity, and prepares Gate `G2`. |
| **`security`** | `agents/security.md` | `.github/agents/aff-security.agent.md` | Audits OWASP controls, zero secret/PII/PCI/PHI leakage, DB query indexing, finite cache TTLs, container hardening, and mobile secure storage. |
| **`qa`** | `agents/qa.md` | `.github/agents/aff-qa.agent.md` | Builds requirement-traceable test matrices (`test-plan.md`), validates 4R review completion, and seals SHA256 RDD quality receipts (`aff-receipt.sh`). |
| **`curator`** | `agents/curator.md` | `.github/agents/aff-curator.agent.md` | Maintains `knowledge/` architecture/domain docs, detects documentation drift, authors ADRs, and curates Engram / Cortex-AI knowledge sync. |
| **`delivery`** | `agents/delivery.md` | `.github/agents/aff-delivery.agent.md` | Executes repository task slices via ODD + strict TDD + RDD receipts, coordinating the 7 specialized delivery sub-roles below. |
| **`reviewer`** | `agents/reviewer.md` | `.github/agents/aff-reviewer.agent.md` | Executes clean-session two-pass deterministic 4R code audits (`Risk, Requirements, Regression, Resilience`) plus adversarial false-positive refutation for Gate `G3`. |

### 3.2 Seven Specialized Delivery Sub-Roles (inside `agents/delivery.md`)

1. **`code-analyzer` (Read-Only):** Inspects language/runtime versions, dependency manifests, database schemas, and distributed trace logs (`X-Correlation-Id` / `traceparent`) for impact and incident RCA.
2. **`designer`:** Models slice-level technical changes inside `odd/tasks/<ticket>-<slug>.md` in strict alignment with `contract.md` and active stack profiles.
3. **`planner`:** Partitions slice changes into atomic work units (`<= 400` LoC) with an explicit, runnable verification command per unit.
4. **`implementer`:** Executes strict Red-Green-Refactor TDD, enforces active `profiles/*.md` and DB/cache guardrails, and writes clean Conventional Commits.
5. **`tester`:** Runs unit, integration, contract, and idempotency test suites locally, capturing deterministic exit codes and outputs.
6. **`reviewer`:** Triggers or delegates to the clean-session `reviewer` agent for two-pass 4R auditing + adversarial refutation before opening or approving a PR.
7. **`documenter`:** Updates OpenAPI/AsyncAPI schemas, authors traceable pull request descriptions (`pr.md`), and documents release and rollback procedures.

---

## 4. Skills, Stack Profiles & Slash Prompts Index

### 4.1 Fourteen Core Procedural Skills (`skills/*/SKILL.md`)

| # | Skill | Directory | Primary Agent(s) | Key Output |
|---|---|---|---|---|
| 1 | **`team-onboarding-bootstrap`** | `skills/team-onboarding-bootstrap/` | `onboarding` | `aff.yaml`, `knowledge/**`, workspace file |
| 2 | **`bilingual-elicitation`** | `skills/bilingual-elicitation/` | `pm` | `work/<TICKET-ID>/elicitation.md` |
| 3 | **`spec-crafting-hydration`** | `skills/spec-crafting-hydration/` | `analyst` | `work/<TICKET-ID>/spec.md`, `slices/*.md` |
| 4 | **`contract-first-design`** | `skills/contract-first-design/` | `architect` | `work/<TICKET-ID>/contract.md` |
| 5 | **`multi-channel-parity`** | `skills/multi-channel-parity/` | `architect`, `qa` | `contract.md#parity` (Web/Android/iOS 1:1) |
| 6 | **`odd-workflow`** | `skills/odd-workflow/` | `orchestrator`, `delivery` | `odd/tasks/<ticket>-<slug>.md` |
| 7 | **`work-unit-tdd`** | `skills/work-unit-tdd/` | `delivery` (`planner`, `implementer`) | Atomic TDD commits (`<= 400` LoC) |
| 8 | **`db-cache-guardrails`** | `skills/db-cache-guardrails/` | `architect`, `delivery`, `security` | Indexed queries & finite-TTL cache keys |
| 9 | **`adversarial-review-4r`** | `skills/adversarial-review-4r/` | `reviewer` | `work/<TICKET-ID>/review-4r.md` |
| 10 | **`rdd-receipts`** | `skills/rdd-receipts/` | `qa`, `delivery` | `work/<TICKET-ID>/evidence/receipt-<GATE>.json` (SHA256) |
| 11 | **`security-compliance-audit`** | `skills/security-compliance-audit/` | `security` | `work/<TICKET-ID>/security-review.md` |
| 12 | **`incident-rca-debugging`** | `skills/incident-rca-debugging/` | `delivery`, `analyst` | `work/<TICKET-ID>/rca.md` + failing test |
| 13 | **`pull-request-documentation`** | `skills/pull-request-documentation/` | `delivery` (`documenter`) | `work/<TICKET-ID>/pr.md` |
| 14 | **`knowledge-checkpoint-curation`** | `skills/knowledge-checkpoint-curation/` | `curator`, `orchestrator` | `knowledge/**`, ADRs, `state.yaml#checkpoint` |

### 4.2 Five Optional Cortex-AI Knowledge Skills (`skills/cortex-ai-*/SKILL.md`)

Active when `harnesses.mode: "mcp"` and `knowledge.mode: "cortex-ai"`:

| # | Skill | Directory | Purpose |
|---|---|---|---|
| 1 | **`cortex-ai-init`** | `skills/cortex-ai-init/` | Bootstrap project/team folders in Google Drive, NotebookLM index, and Engram project namespace. |
| 2 | **`cortex-ai-ask`** | `skills/cortex-ai-ask/` | Query grounded domain, architectural, and historical project context across NotebookLM and Engram. |
| 3 | **`cortex-ai-sync`** | `skills/cortex-ai-sync/` | Redact-scan, push, and reconcile curated `knowledge/`, `work/`, and session journals with Drive + NotebookLM. |
| 4 | **`cortex-ai-onboard`** | `skills/cortex-ai-onboard/` | Synthesize executive context briefings for engineers onboarding onto or resuming a project stream. |
| 5 | **`cortex-ai-status`** | `skills/cortex-ai-status/` | Verify knowledge store health, sync queue state, and index drift across connected MCP stores. |

### 4.3 Seven Pluggable Stack Profiles (`profiles/*.md`)

Enabled selectively per team in `aff.yaml` (`profiles.enabled`) and projected to `.github/instructions/*.instructions.md` for Copilot:

| # | Profile ID | Canonical File | Stack Scope |
|---|---|---|---|
| 1 | **`backend-jvm-spring`** | `profiles/backend-jvm-spring.md` | Java 8/17/21+, Kotlin, Spring Boot 2.x/3.x (`javax.*` vs `jakarta.*`), Maven/Gradle. |
| 2 | **`backend-node-ts`** | `profiles/backend-node-ts.md` | Node.js LTS, TypeScript strict mode, NestJS/Fastify/Express, async boundaries & schema validation. |
| 3 | **`backend-python-go`** | `profiles/backend-python-go.md` | Python (FastAPI/Django, mypy/ruff/pytest) & Go (context propagation, explicit error wrapping, race detector). |
| 4 | **`frontend-web`** | `profiles/frontend-web.md` | Angular, React, Vue, Next.js — accessibility (WCAG AA), state isolation, contract-driven clients. |
| 5 | **`mobile-native`** | `profiles/mobile-native.md` | Android (Kotlin/Compose, `EncryptedSharedPreferences`/Keystore) & iOS (Swift/SwiftUI, `Keychain`), 1:1 parity. |
| 6 | **`data-sql-nosql-cache`** | `profiles/data-sql-nosql-cache.md` | PostgreSQL/MySQL, MongoDB/DynamoDB, Redis — mandatory query indexes, migrations, finite TTL, key namespaces. |
| 7 | **`cicd-containers`** | `profiles/cicd-containers.md` | Docker multi-stage rootless builds, GitHub Actions/GitLab CI/Jenkins/Cloud Build, pinned digests, zero build secrets. |

### 4.4 Nine Slash Command Prompts (`prompts/*.prompt.md`)

| # | Slash Command | Canonical File | Target Agent | Purpose |
|---|---|---|---|---|
| 1 | **`/init-team`** | `prompts/init-team.prompt.md` | `onboarding` | Run the 6-dimension interactive team and project onboarding interview. |
| 2 | **`/aff-intake`** | `prompts/aff-intake.prompt.md` | `orchestrator` | Ingest a raw ticket (`PROJ-101`), classify size (`S/M/L/H`), initialize `work/<TICKET-ID>/` and `state.yaml`. |
| 3 | **`/elicit-ticket`** | `prompts/elicit-ticket.prompt.md` | `pm` | Generate domain hypotheses, `<= 10` P1 questions with defaults, and optional 3-point PERT estimate. |
| 4 | **`/answers-to-spec`** | `prompts/answers-to-spec.prompt.md` | `analyst` | Hydrate stakeholder answers into `spec.md` (Given/When/Then) and verify Gate `G1` readiness. |
| 5 | **`/contract-first`** | `prompts/contract-first.prompt.md` | `architect` | Produce `contract.md` (OpenAPI/AsyncAPI, error taxonomy, N/N-1 compatibility, data/cache models). |
| 6 | **`/parity-check`** | `prompts/parity-check.prompt.md` | `architect` | Audit 1:1 functional, validation, and error-code parity across Web, Android, and iOS channels. |
| 7 | **`/work-units`** | `prompts/work-units.prompt.md` | `delivery` | Partition `spec.md` + `contract.md` into `<= 400` LoC TDD work units inside `odd/tasks/` and `slices/`. |
| 8 | **`/review-4r`** | `prompts/review-4r.prompt.md` | `reviewer` | Run Pass 1 deterministic 4R critical audit (*Risk, Requirements, Regression, Resilience*). |
| 9 | **`/review-refuter`** | `prompts/review-refuter.prompt.md` | `reviewer` | Run Pass 2 adversarial refutation to eliminate false positives before Gate `G3`. |

---

## 5. Eight-Phase Lifecycle (Phases 0–7), Sizing (`S/M/L/H`) & Human Gates

### 5.1 Phases 0 to 7

| Phase | Name | Lead Agent(s) | Core Artifacts | Quality Gate |
|---|---|---|---|---|
| **Phase 0** | **Team & Workspace Onboarding** | `onboarding` | `aff.yaml`, `knowledge/{team,domain,architecture}/*` | Initial setup verified via `./aigile doctor` |
| **Phase 1** | **Intake, Triage & Isolation** | `orchestrator` | `work/<TICKET-ID>/ticket-in.md`, `state.yaml`, worktree | Size class (`S/M/L/H`) assigned |
| **Phase 2** | **Hypothesis Elicitation & PERT Estimation** | `pm` | `work/<TICKET-ID>/elicitation.md` (incl. PERT) | Stakeholder / PO answers collected |
| **Phase 3** | **Functional Spec Hydration & Slice Cutting** | `analyst` | `work/<TICKET-ID>/spec.md`, `slices/*.md` | **Gate `G1`** (or `G1a` Tech Lead + `G1b` PO when `dual_po_approval: true`) |
| **Phase 4** | **Contract-First Design & Channel Parity** | `architect`, `security` | `work/<TICKET-ID>/contract.md` | **Gate `G2`** (Contract & Security/Parity sign-off) |
| **Phase 5** | **Atomic Work-Unit Planning & TDD Execution** | `delivery` | `odd/tasks/<ticket>-<slug>.md`, code + tests | Every unit `<= 400` LoC, Red-Green-Refactor green |
| **Phase 6** | **Clean-Session 4R Audit & Adversarial Refutation** | `reviewer`, `qa` | `work/<TICKET-ID>/review-4r.md`, `pr.md`, `G3` SHA256 receipt | **Gate `G3`** (Zero open `CRITICAL`/`HIGH` findings; PR approved) |
| **Phase 7** | **Release Verification, RDD Receipt & Curation** | `qa`, `curator`, `orchestrator` | `work/<TICKET-ID>/receipts/*G4*.json`, `gate-record.md`, updated `knowledge/` | **Gate `G4`** (Production release & knowledge sync) |

### 5.2 Proportional Sizing Matrix (`S / M / L / H`)

Ceremony scales strictly with risk and blast radius — never bureaucracy for its own sake:

- **`S` (Small — Single-repo bugfix/tweak, no contract change, `<= 150` LoC):** Inline ODD execution; streamlined `spec.md`, TDD fix, 4R review, and `G3` receipt (`G2` skipped if zero API/schema change).
- **`M` (Medium — Standard single/dual-repo feature):** Full Phases 1–7 with `spec.md` (`G1`), `contract.md` (`G2` when API/schema touched), `odd/tasks/` units, 4R review + `G3` receipt, and `G4`.
- **`L` (Large — Multi-repo / cross-channel / schema migration):** Full Phases 1–7, mandatory `contract.md` + N/N-1 plan + parity audit (`G2`), per-repo slices/worktrees, PERT risk buffer, and full `G1`–`G4` SHA256 receipts.
- **`H` (Hotfix / Production Incident):** Fast-track via `incident-rca-debugging`: reproduce with failing test, minimal surgical fix, mandatory `security` + `reviewer` 4R pass (`G3` + `G4` receipts), and post-deployment `rca.md` curation within 24 hours.

### 5.3 Cryptographic Gate Integrity (SHA256 RDD Receipts)

When `governance.require_sha256_receipt: true`, gate transitions execute verification commands through `./aigile receipt generate <TICKET-ID> <GATE> -- <command>` (`scripts/aff-receipt.sh`). Each receipt records the command, exit code, UTC timestamp, artifact digests, and tamper-evident SHA256 seal verified via `./aigile receipt verify <receipt.json>`.

---

## 6. Non-Negotiable Engineering Guardrails

1. **Zero Secret, PII, PCI, and PHI Leakage:** Never hardcode, log, commit, or index credentials, tokens, national IDs, payment card numbers (PAN), or protected health/customer records. Use synthetic placeholders (`<REDACTED:id>`, `<REDACTED:token>`) and run `./aigile scan` (`scripts/aff-secret-scan.sh`) prior to commits and knowledge syncs.
2. **Database Indexing & Finite Cache TTLs:** Transactional queries on unindexed predicates are prohibited. Every cache entry must declare a finite `TTL`, contain zero plaintext sensitive data, and follow the canonical key pattern `{namespace}:{domain}:{service}:{entity}:{id}`.
3. **Client-Side Domain Purity & Optional 1:1 Parity:** Never compute pricing, authorization, or core domain invariants exclusively on web or mobile clients. When `governance.multi_channel_parity: true`, Web, Android, and iOS must preserve 1:1 validation rules, field semantics, and error codes.
4. **Atomic TDD Work Units (`<= 400` LoC) & Conventional Commits:** Follow Red-Green-Refactor discipline. Keep work units reviewable (`<= 400` LoC target). Write Conventional Commits in English with zero AI attribution (`Co-Authored-By` is strictly forbidden).
5. **No `git stash` Context Switching (`ban_git_stash: true`):** Preserve in-flight state deterministically via worktrees (`./aigile worktree`) or explicit session checkpoints (`./aigile session checkpoint "<note>"`), never hidden stashes.
6. **Mandatory Clean-Session 4R Review & Gate SHA Integrity:** No pull request passes Gate `G3` with unrefuted `CRITICAL` or `HIGH` 4R findings, and no phase advances if a gated artifact was mutated after its recorded approval SHA.
7. **Canonical Single Source of Truth:** Never hand-edit generated harness files (`CLAUDE.md`, `.claude/`, `.agents/`, `.opencode/`, `.github/`, `.mcp.json`, `opencode.json`). Edit `aff.yaml`, `AGENTS.md`, `agents/`, `skills/`, `profiles/`, `prompts/`, or `mcp/` and run `./aigile harness sync`.
