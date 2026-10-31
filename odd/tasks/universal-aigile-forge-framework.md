Objective: Create standalone universal AIgile Forge Framework (`aigile-forge-framework`) unifying Multi-Harness CLI/IDE (`claude`, `opencode`, `antigravity`, `codex`) and GitHub Copilot (`.github/`), adaptable to any development team with zero company or cell references.
Branch: `feat/universal-framework` | Delivery strategy: `single-pr` (greenfield local repository in atomic work-unit commits; forecast ~2,400 LoC)
Test runner: `bash tests/run-tests.sh` | Engram mirror: `odd/universal-aigile-forge-framework/tasks` (pending — Engram MCP unavailable in session)

## Specs

- **S1 — Standalone Repository & Non-Modification**:
  - User verbatim: `"Quiero crear un nuevo framework muy similares a los siguientes proyectos aigile-forge-framework-copilot y aigile-forge-framework-redSalud Este nuevo framework debe tener el nombre aigile-forge-framework."` and `"este debe ser uno nuevo, no modificar."`
  - Scope & Acceptance Criteria: Initialize independent git repository at `projects/aigile-forge-framework/`. Neither `projects/aigile-forge-framework-copilot/` nor `projects/aigile-forge-framework-redSalud/` may have any modified or untracked files introduced.
  - Applicable Check: `git -C projects/aigile-forge-framework rev-parse --is-inside-work-tree` succeeds; `git status --porcelain` in both sibling repos remains unchanged.

- **S2 — Universal Multi-Harness & Copilot Architecture**:
  - User verbatim: `"Este debe ser un Framework Unificado Universal es la mejor opcional"`
  - Scope & Acceptance Criteria: Provide a single canonical source (`aff.yaml`, `AGENTS.md`, `agents/`, `skills/`, `profiles/`, `prompts/`, `templates/`, `mcp/`, `configs/`) and a universal projector (`scripts/aff-harness.sh` + root `./aigile` CLI) that projects deterministically to `claude`, `opencode`, `antigravity`, `codex`, and `copilot` (`.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `.github/agents/aff-*.agent.md`, `.github/prompts/*.prompt.md`, `.github/skills/`). Support both `zero-mcp` mode and `mcp` / `cortex-ai` mode.
  - Applicable Check: `./aigile harness sync all --copy` and `./aigile harness check` succeed with exit code `0` in an isolated scratch workspace.

- **S3 — Adaptable to Any Development Team**:
  - User verbatim: `"Este framework debe ser capaz de adaptarse a cualquier equipo de desarrollo."`
  - Scope & Acceptance Criteria:
    - Pluggable stack profiles (`profiles/`): JVM/Spring, Node/TypeScript, Python/Go, Web Frontend, Native Mobile (Android/iOS 1:1 parity), SQL/NoSQL/Cache guardrails, and CI/CD & Containers.
    - Configurable workspace topology (`single-repo`, `worktrees`, `multi-root`), issue tracker (`jira`, `linear`, `github`, `gitlab`, `azure-devops`, `monday`, `markdown`), optional 3-point PERT focus-factor estimation, 8-phase lifecycle with proportional human gates (`G1`–`G4`), ODD native task tracking, 4R adversarial review (`Risk, Requirements, Regression, Resilience`), and SHA256 RDD receipts (`scripts/aff-receipt.sh`).
    - Interactive and non-interactive team/project onboarding (`./aigile init`, `agents/onboarding.md`, `prompts/init-team.prompt.md`, `skills/team-onboarding-bootstrap/SKILL.md`) supporting `--lang en|es`.
    - Assumption: Generated framework artifacts default to neutral English with bilingual `README.md` / `README.es.md` and `docs/{en,es}/` guides so English and Spanish teams adopt without friction.
  - Applicable Check: `bash tests/run-tests.sh` tests `aigile init` in both `zero-mcp` + `multi-root` and `mcp` + `worktrees` configurations, plus `aff-receipt.sh` and `aff-secret-scan.sh`.

- **S4 — Complete Elimination of Company & Cell References**:
  - User verbatim: `"Ademas debe eliminar cualquier referencia a empresa o celula."`
  - Scope & Acceptance Criteria: Zero occurrences of company identifiers (`RedSalud`, `Zenta`, `Scotiabank`, `FONASA`, `Isapre`, `Webpay`, `Ley 20.584`, `RS_TEL`, `RS_PWA`, `MON-`, live Google Drive folder IDs) or cell terminology (`célula`, `celula`, standalone `cell` word, `init-cell`, `cell.code-workspace`, `cell.config.yaml`) across all tracked framework files (excluding this verbatim spec quote file `odd/tasks/` and test regex fixtures in `tests/`). Use `project`, `team`, and `workspace` (`equipo`, `proyecto`, `espacio de trabajo` in Spanish docs).
  - Applicable Check: Case-insensitive regex audit across all framework files (`AGENTS.md`, `aff.yaml`, `aigile`, `agents/`, `skills/`, `profiles/`, `prompts/`, `scripts/`, `templates/`, `mcp/`, `configs/`, `README*`, `docs/`) returns zero matches.

- **S5 — Workspace Harness Registration (`Tools_Agents`)**:
  - Scope & Acceptance Criteria: Register `aigile-forge-framework` in `Tools_Agents` root harness (`context/aigile-forge-framework/context.md` with 8 normative sections in Spanish, `context/INDEX.md`, `AGENTS.md`, and `memory/NOW.md`) following `Tools_Agents/AGENTS.md` two-layer git rules.
  - Applicable Check: Structural readback and path verification against filesystem; clean `git status` in `Tools_Agents` after harness commit.

## Tasks

- [x] **T1** (`S1`, `S2`, `S3`, `S4`) | Route: `delegated` (Writer trigger: parallel unit 1/3 with disjoint surface; Risk: passive) | Core manifest (`aff.yaml`), canonical `AGENTS.md`, 10 `agents/*.md`, 9 slash `prompts/*.prompt.md`, 16 `templates/*`, and clean `mcp/*.json` + `configs/*.json` | Status: completed | Evidence: commit `5e905d5` (JSON/YAML schema & zero-coupling audit PASS)
- [x] **T2** (`S2`, `S3`, `S4`) | Route: `delegated` (Writer trigger: parallel unit 2/3 with disjoint surface; Risk: passive) | 14 core `skills/*/SKILL.md` + 5 optional `skills/cortex-ai-*/SKILL.md` + 7 pluggable stack `profiles/*.md` | Status: completed | Evidence: commit `3382bf2` (26 frontmatter schemas & zero-coupling audit PASS)
- [x] **T3** (`S2`, `S3`, `S4`) | Route: `delegated` (Writer trigger: parallel unit 3/3 with disjoint surface; Risk: items 2 & 5) | Unified `./aigile` CLI, universal projector `scripts/aff-harness.sh` (Claude, OpenCode, Antigravity, Codex, Copilot) + operational scripts (`aff-doctor.sh`, `aff-worktree.sh`, `aff-receipt.sh`, `aff-session.sh`, `aff-secret-scan.sh`, `aff-knowledge-sync.sh`), and bilingual `README.md`, `README.es.md`, `docs/{en,es}/` | Status: completed | Evidence: commit `cfc1e70` (`bash -n`, CLI smoke, `./aigile doctor`, `./aigile harness check`, `./aigile scan` PASS)
- [x] **T4** (`S1`, `S2`, `S3`, `S4`) | Route: `inline` + `independent verifier` (Verification trigger: High-risk items 2 security scanner & 5 installer/projector scripts) | Executable test suite `tests/run-tests.sh` (RED/GREEN & seam check across T1–T3), work-unit commits on `feat/universal-framework`, and independent scratch verification | Status: completed | Evidence: commit `cfc1e70` + `bash tests/run-tests.sh` (40/40 PASS) + independent verifier (`aff-verifier`) PASS on `S1`–`S4` in isolated `/tmp/aff-verifier.9Wfagm` (cleaned by parent)
- [x] **T5** (`S1`, `S5`) | Route: `inline` (Risk: passive) | Register `context/aigile-forge-framework/context.md`, update `context/INDEX.md`, `AGENTS.md`, and `memory/NOW.md` in `Tools_Agents` root | Status: completed | Evidence: committed in `Tools_Agents` root `main`

## Log

- **L1 (2026-10-30)**: `"Quiero crear un nuevo framework muy similares a los siguientes proyectos aigile-forge-framework-copilot y aigile-forge-framework-redSalud Este nuevo framework debe tener el nombre aigile-forge-framework. Este framework debe ser capaz de adaptarse a cualquier equipo de desarrollo. Ademas debe eliminar cualquier referencia a empresa o celula."`
- **L2 (2026-10-30)**: `"Este debe ser un Framework Unificado Universal es la mejor opcional y este debe ser uno nuevo, no modificar."`
- **L3 (2026-10-30)**: Mapped both sibling repos via read-only explorer (`aff-explorer`). Initialized standalone git repo `projects/aigile-forge-framework/` (`main` -> `feat/universal-framework`). Engram MCP unavailable in session; local feature document created and mirror marked pending.
- **L4 (2026-10-30)**: Executed `T1` (`5e905d5`), `T2` (`3382bf2`), `T3`+`T4` (`cfc1e70`). Caught and fixed `AFF_WORKSPACE_DIR` external-invocation seam in `aigile` during RED->GREEN run of `tests/run-tests.sh` (40/40 PASS). Independent `aff-verifier` verified `S1`–`S4` PASS (87 tracked + 274 generated files audited with 0 legacy/company hits); aligned two minor path/skill strings (`AGENTS.md`, `scripts/aff-knowledge-sync.sh`) and cleaned scratch `/tmp/aff-verifier.9Wfagm`.
