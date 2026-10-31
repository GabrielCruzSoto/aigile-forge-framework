# Procedural Skills & Pluggable Stack Profiles Catalog

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/catalog/skills-and-profiles.md`](../../es/catalog/skills-and-profiles.md)  
> **Related Manuals:** [Agents & Slash Prompts Catalog](agents-and-prompts.md) · [Harness Compatibility Matrix](../harnesses/compatibility-matrix.md) · [Security & Knowledge Sync](../governance/security-and-knowledge-sync.md)

While **agents** define *who* executes a responsibility and **prompts** define *user-triggered entrypoints*, **Procedural Skills (`skills/*/SKILL.md`)** define *repeatable step-by-step engineering methodologies*, and **Pluggable Stack Profiles (`profiles/*.md`)** enforce *file-scoped language, framework, data, and infrastructure guardrails*.

---

## 1. Fourteen Core Procedural Skills (`skills/*/SKILL.md`)

All 14 core skills work 100% locally in both `zero-mcp` and `mcp` modes and are projected to `.claude/skills/`, `.agents/skills/`, and `.github/skills/`:

| # | Skill Name (`name`) | Canonical Path | Primary Agent(s) | Core Engineering Procedure & Artifact Output |
|---|---|---|---|---|
| 1 | **`team-onboarding-bootstrap`** | `skills/team-onboarding-bootstrap/SKILL.md` | `onboarding` | Executes the 6-dimension team discovery workflow, renders `aff.yaml` v2.0, populates `knowledge/`, and runs `./aigile harness sync`. |
| 2 | **`bilingual-elicitation`** | `skills/bilingual-elicitation/SKILL.md` | `pm` | Converts sparse tickets into falsifiable domain hypotheses and `<= 10` prioritized `P1`–`P3` questions with defaults in `en` or `es` (`elicitation.md`). |
| 3 | **`spec-crafting-hydration`** | `skills/spec-crafting-hydration/SKILL.md` | `analyst` | Hydrates stakeholder answers into deterministic `S#` specs, Gherkin `Given/When/Then` `AC-#` criteria, PERT tables, and Gate `G1` checks (`spec.md`). |
| 4 | **`contract-first-design`** | `skills/contract-first-design/SKILL.md` | `architect` | Authors OpenAPI 3.1, AsyncAPI, GraphQL, or Protobuf schemas with RFC 7807 error taxonomies, N/N-1 compatibility, and mock payloads (`contract.md`). |
| 5 | **`multi-channel-parity`** | `skills/multi-channel-parity/SKILL.md` | `architect`, `qa` | Certifies 1:1 behavioral, field-validation, state-machine, and error-handling parity across Web, Android (Kotlin), and iOS (Swift). |
| 6 | **`odd-workflow`** | `skills/odd-workflow/SKILL.md` | `orchestrator`, `delivery` | Organic Driven Development protocol governing proportional sizing (`S/M/L/H`), single living task docs (`odd/tasks/<ticket>-<slug>.md`), and cold-resume state. |
| 7 | **`work-unit-tdd`** | `skills/work-unit-tdd/SKILL.md` | `delivery` | Enforces atomic `<= 400` LoC work slices, strict Red-Green-Refactor cycles, differential regression runs, and clean English Conventional Commits. |
| 8 | **`db-cache-guardrails`** | `skills/db-cache-guardrails/SKILL.md` | `architect`, `delivery`, `security` | Validates declared SQL/NoSQL query indexes, engine dialect rules, reversible migrations, finite cache TTLs, and `{namespace}:{domain}:{service}:{entity}:{id}` keys. |
| 9 | **`adversarial-review-4r`** | `skills/adversarial-review-4r/SKILL.md` | `reviewer` | Runs clean-session Pass 1 (**Risk, Requirements, Regression, Resilience**) followed by Pass 2 evidence-based false-positive refutation (`review-4r.md`). |
| 10 | **`rdd-receipts`** | `skills/rdd-receipts/SKILL.md` | `qa`, `delivery` | Executes gate verification commands via `./aigile receipt generate` and verifies canonical SHA256 + `git_head` seals (`receipt-<GATE>.json`). |
| 11 | **`security-compliance-audit`** | `skills/security-compliance-audit/SKILL.md` | `security` | Audits secret prevention, configurable `secrets`/`pii`/`pci`/`phi` masking, OWASP Top 10 controls, Web/Mobile secure token storage, and CI hardening (`security-review.md`). |
| 12 | **`incident-rca-debugging`** | `skills/incident-rca-debugging/SKILL.md` | `delivery`, `analyst` | Traces distributed correlation IDs, eliminates root-cause hypotheses, mandates an isolated failing reproduction test before fixes, and writes `rca.md`. |
| 13 | **`pull-request-documentation`** | `skills/pull-request-documentation/SKILL.md` | `delivery` | Generates reviewer-ready PR packages (`pr.md`) linking `S#` specs, N/N-1 contract notes, 4R verdicts, SHA256 receipts, and rollback runbooks. |
| 14 | **`knowledge-checkpoint-curation`** | `skills/knowledge-checkpoint-curation/SKILL.md` | `curator`, `orchestrator` | Manages cold-resume session checkpoints, authors ADRs in `knowledge/`, detects doc-vs-code drift, and coordinates `local`/`folder-sync`/`cortex-ai` sync. |

---

## 2. Five Optional Cortex-AI Knowledge Skills (`skills/cortex-ai-*/SKILL.md`)

Active when `harnesses.mode: "mcp"` and `knowledge.mode: "cortex-ai"` in `aff.yaml`:

| # | Skill Name (`name`) | Canonical Path | Purpose & Connected MCP Stores Used |
|---|---|---|---|
| 1 | **`cortex-ai-init`** | `skills/cortex-ai-init/SKILL.md` | Bootstraps a project/team folder hierarchy in Google Drive (`DRIVE_ROOT_FOLDER_ID`), initializes a NotebookLM notebook (`NOTEBOOKLM_NOTEBOOK_ID`), and records cross-reference pointers in Engram (`ENGRAM_PROJECT`). |
| 2 | **`cortex-ai-ask`** | `skills/cortex-ai-ask/SKILL.md` | Answers historical, architectural, and domain questions using NotebookLM-first grounded retrieval, Engram observation recall, and cited local `knowledge/` fallback. |
| 3 | **`cortex-ai-sync`** | `skills/cortex-ai-sync/SKILL.md` | Runs `./aigile scan --path knowledge` first, then reconciles curated `knowledge/` docs, ADRs, and specs with Google Drive and refreshes NotebookLM sources. |
| 4 | **`cortex-ai-onboard`** | `skills/cortex-ai-onboard/SKILL.md` | Accelerates engineer and agent onboarding onto an active stream by synthesizing Drive registries, NotebookLM briefings, Engram decisions, and local `./aigile doctor` readiness. |
| 5 | **`cortex-ai-status`** | `skills/cortex-ai-status/SKILL.md` | Audits synchronization freshness, NotebookLM indexing drift, and Engram project pointer consistency without mutating remote stores. |

---

## 3. Seven Pluggable Stack Profiles (`profiles/*.md`)

Enable only the profiles matching your team's stack under `profiles.enabled` in `aff.yaml`. When projected to GitHub Copilot (`.github/instructions/<slug>.instructions.md`), each profile attaches automatically via its exact `applyTo` file glob:

### 3.1 `backend-jvm-spring` (`profiles/backend-jvm-spring.md`)
- **`applyTo` Glob:** `**/*.{java,kt,kts,xml,gradle}`
- **Enforced Guardrails:** Respect target Java (`8`/`17`/`21+`) and Spring Boot (`2.x javax.*` vs `3.x/4.x jakarta.*`) namespaces; mandatory constructor injection (ban field `@Autowired`); immutable DTOs/records at controller boundaries (never expose JPA entities); RFC 7807 `ProblemDetail` error responses; MDC correlation ID logging without PII; bounded RestClient/WebClient timeouts; slice tests (`@WebMvcTest`, `@DataJpaTest`, Testcontainers).

### 3.2 `backend-node-ts` (`profiles/backend-node-ts.md`)
- **`applyTo` Glob:** `**/*.{ts,js,mjs,cjs,json}`
- **Enforced Guardrails:** TypeScript `strict: true` (ban unguarded `any` and unsafe casts); mandatory runtime schema validation at HTTP/queue boundaries (`zod`, `valibot`, `TypeBox`, `class-validator`); `AbortSignal` / explicit timeouts on all outbound I/O; zero unhandled floating promises; structured JSON logging (`pino` / `winston`) with secret/PII redaction; deterministic dependency lockfiles.

### 3.3 `backend-python-go` (`profiles/backend-python-go.md`)
- **`applyTo` Glob:** `**/*.{py,go,mod}`
- **Enforced Guardrails:**
  - *Python:* Full type annotations verified with `mypy`/`pyright`, `ruff` linting, Pydantic v2 boundary validation, parameterized SQLAlchemy/psycopg queries, async loop hygiene (never call blocking I/O inside `async def`), deterministic `pytest` fixtures.
  - *Go:* `context.Context` as first parameter across all I/O boundaries, explicit error wrapping (`fmt.Errorf("...: %w", err)`), zero silent `_` error drops, bounded goroutine lifecycles, `go test -race ./...` compliance.

### 3.4 `frontend-web` (`profiles/frontend-web.md`)
- **`applyTo` Glob:** `**/*.{tsx,jsx,ts,html,scss,css,vue}`
- **Enforced Guardrails:** Strict container-presentational separation; typed client consumption generated or aligned 1:1 with `contract.md`; **zero domain pricing/permission logic duplicated solely on the client**; WCAG 2.1 AA semantic HTML, keyboard navigation, and ARIA labels; explicit loading/empty/error UI states; ban storing sensitive auth tokens in `localStorage` when `HttpOnly` SameSite cookies apply.

### 3.5 `mobile-native` (`profiles/mobile-native.md`)
- **`applyTo` Glob:** `**/*.{kt,swift,xml,plist,pbxproj}`
- **Enforced Guardrails:**
  - *Android (Kotlin / Jetpack Compose):* Unidirectional ViewModel `StateFlow`, structured `viewModelScope` coroutines, credentials stored exclusively in Android Keystore / `EncryptedSharedPreferences` (never cleartext `SharedPreferences` or `Log.d`).
  - *iOS (Swift / SwiftUI):* `async/await` structured concurrency with cancellation handling, credentials stored exclusively in iOS `Keychain` (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, never `UserDefaults`).
  - *Cross-Platform:* Offline/retry resilience, N-1 API version tolerance during app-store review windows, and 1:1 parity with Web when `multi_channel_parity: true`.

### 3.6 `data-sql-nosql-cache` (`profiles/data-sql-nosql-cache.md`)
- **`applyTo` Glob:** `**/*.{sql,prisma,graphql,yaml,yml,json}`
- **Enforced Guardrails:** Every `WHERE`, `JOIN`, and `ORDER BY` predicate on transactional tables must map to a declared index (`EXPLAIN` verified); strict compliance with project's target engine version (e.g., PostgreSQL 15+, MySQL 5.7 vs 8.0, MongoDB, DynamoDB); expand-and-contract reversible migrations (ban destructive `DROP COLUMN` in single-step releases); mandatory finite `TTL` on every cache write; canonical cache key format `{namespace}:{domain}:{service}:{entity}:{id}`; zero unmasked PII/PCI/PHI in cache values.

### 3.7 `cicd-containers` (`profiles/cicd-containers.md`)
- **`applyTo` Glob:** `**/{Dockerfile*,*pipeline*,*.yml,*.yaml,*.sh,Jenkinsfile}`
- **Enforced Guardrails:** Multi-stage Docker builds running as explicit non-root `USER`; pinned base image tags/digests (ban `:latest` in production); `.dockerignore` excluding `.git`, `.env`, `work/`, and `worktrees/`; zero secrets passed via `ARG` or baked into image layers; pinned CI action versions, least-privilege `permissions:`, and secret-masked CI logs.

---

## 4. Authoring Custom Team Skills & Stack Profiles

Teams can extend `aigile-forge-framework` cleanly without modifying core scripts:

### 4.1 Creating a Custom Procedural Skill
1. Create a kebab-case directory `skills/<custom-slug>/SKILL.md` (`^[a-z0-9]+(?:-[a-z0-9]+)*$`).
2. Add mandatory YAML frontmatter where `name` matches `<custom-slug>` exactly:
   ```markdown
   ---
   name: graphql-federation-governance
   description: "Schema composition checks, @key entity invariants, and subgraph N/N-1 breaking-change rules."
   ---

   # Skill: GraphQL Federation Governance
   ## When to Use
   ...
   ## Step-by-Step Procedure
   ...
   ```
3. Run `./aigile harness sync all && ./aigile harness check` to project and validate the new skill across all 5 harnesses.

### 4.2 Creating a Custom Stack Profile
1. Create `profiles/<custom-profile>.md` (e.g., `profiles/backend-rust-axum.md`) with `name`, `description`, and `applyTo` frontmatter:
   ```markdown
   ---
   name: backend-rust-axum
   description: "Guardrails for Rust and Axum services: zero unwrap() in request handlers, bounded Tower timeouts, and sqlx compile-time checked queries."
   applyTo: "**/*.{rs,toml}"
   ---

   # Profile: Rust & Axum Backend Services
   ...
   ```
2. Add `"backend-rust-axum"` under `profiles.enabled` in `aff.yaml` and reference it in `AGENTS.md` if desired.
3. Run `./aigile harness sync all && ./aigile harness check`. GitHub Copilot immediately receives `.github/instructions/backend-rust-axum.instructions.md` scoped to `**/*.{rs,toml}`.

---

## 5. Recommended Stack Profile Bundles by Project Archetype

Use these ready-made `profiles.enabled` combinations in `aff.yaml` during onboarding:

```yaml
# Archetype A: Enterprise Java/Spring Microservice + Angular/React SPA + PostgreSQL/Redis
profiles:
  enabled:
    - "backend-jvm-spring"
    - "frontend-web"
    - "data-sql-nosql-cache"
    - "cicd-containers"

# Archetype B: Omnichannel Product (Node.js/TypeScript BFF + Web + Native Android & iOS)
# Pair with governance.multi_channel_parity: true
profiles:
  enabled:
    - "backend-node-ts"
    - "frontend-web"
    - "mobile-native"
    - "data-sql-nosql-cache"
    - "cicd-containers"

# Archetype C: Data / AI / High-Throughput Platform Services (Python FastAPI + Go Workers)
profiles:
  enabled:
    - "backend-python-go"
    - "data-sql-nosql-cache"
    - "cicd-containers"
```

### Skill & Profile Validation Checklist
- Every skill directory under `skills/` must contain `SKILL.md` with YAML frontmatter `name` matching the directory name (`^[a-z0-9]+(?:-[a-z0-9]+)*$`) and a non-empty `description`.
- Every profile under `profiles/` should declare an explicit `applyTo` glob so Copilot instruction scoping remains deterministic.
- Always run `./aigile harness check` and `./aigile scan --path skills --path profiles` before committing custom extensions.

