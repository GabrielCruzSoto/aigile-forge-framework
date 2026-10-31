---
name: team-onboarding-bootstrap
description: "Interactive and non-interactive 6-dimension discovery workflow that configures aff.yaml, initializes curated knowledge directories, and projects AI harnesses for any software team."
---

# Skill: Team Onboarding & Workspace Bootstrap

## Purpose & Activation

Activate when onboarding a new development team, bootstrapping a greenfield or brownfield project, or reconfiguring an existing workspace via `./aigile init` or `/init-team`. This skill adapts AIgile Forge Framework to any team topology, stack combination, tracker, and AI harness mode without hardcoded organizational assumptions.

## Inputs

- Repository root path and optional sibling repository paths (for `worktrees` or `multi-root` topologies).
- User-selected interaction language (`en` or `es` via `--lang` or interactive prompt; generated technical configuration defaults to neutral English unless configured otherwise).
- Existing build manifests if present (`package.json`, `pom.xml`, `build.gradle*`, `pyproject.toml`, `go.mod`, `Dockerfile`, CI YAML) used to pre-detect stack profiles.

## 6-Dimension Discovery Protocol

Execute discovery sequentially (one concise question group per dimension in interactive mode, or flag/config driven in `--non-interactive` mode):

### Dimension 1: Identity & Roster
1. Capture `project.name`, `project.slug` (kebab-case), and `team.name`.
2. Record primary roles or sub-teams (backend, web, mobile, platform, QA, security) and optional code ownership boundaries.
3. Capture communication language (`language.conversation`: `en` | `es`) and artifact language (`language.artifacts`: default `en`).

### Dimension 2: Domain & Glossary
1. Identify industry vertical (e.g., e-commerce, fintech, SaaS, logistics, healthcare, developer tools) and regulatory sensitivity (`none`, `pii`, `pci`, `phi`, `sox`).
2. Extract 5–15 canonical domain terms and ubiquitous language definitions to prevent naming drift across services and UI channels.
3. Define cache/metric namespace prefix (`{namespace}` slug) for deterministic key conventions.

### Dimension 3: System Architecture & Repositories
1. Select workspace topology:
   - `single-repo`: monolith or monorepo inside a single git repository.
   - `worktrees`: isolated per-ticket git worktrees managed via `./aigile worktree`.
   - `multi-root`: coordinated multi-repository workspace generating `<project-slug>.code-workspace`.
2. Catalog active repositories, entry points, default branches, and inter-service communication styles (REST, GraphQL, gRPC, async events).

### Dimension 4: Stack Profiles & Delivery Channels
1. Auto-detect and confirm active profiles from `profiles/`:
   - `backend-jvm-spring`
   - `backend-node-ts`
   - `backend-python-go`
   - `frontend-web`
   - `mobile-native`
   - `data-sql-nosql-cache`
   - `cicd-containers`
2. Record runtime and database engine versions (e.g., JDK 21, Node 22, PostgreSQL 16, MySQL 8.0, Redis 7) in `aff.yaml` so downstream guardrails enforce exact dialect compatibility.
3. Flag multi-channel parity (`channels.parity_required: true`) whenever Web and Mobile clients consume shared backend capabilities.

### Dimension 5: Workflow, Issue Tracker & Estimation
1. Configure issue tracker adapter (`jira`, `linear`, `github`, `gitlab`, `azure-devops`, `monday`, or `markdown`) and ticket prefix example (e.g., `PROJ-101`).
2. Configure branching model (`trunk`, `github-flow`, or `gitflow`) and proportional human gates (`G1` Spec Approval, `G2` Contract Approval, `G3` 4R Review & Receipt Gate, `G4` Release/PR Readiness).
3. Configure optional 3-point PERT estimation (`estimation.enabled`, `estimation.focus_factor` default `0.75`).

### Dimension 6: AI Harnesses & Knowledge Mode
1. Select target AI harnesses to project (`claude`, `opencode`, `antigravity`, `codex`, `copilot`, or `all`).
2. Select operational capability mode:
   - `zero-mcp`: pure filesystem, git, and shell workflows with zero external MCP dependencies.
   - `mcp`: enables configured MCP servers (`engram`, `codegraph`, `github`, etc.).
3. Select knowledge persistence mode:
   - `local`: repository-tracked `knowledge/` directory only.
   - `folder-sync`: mirrors `knowledge/` to a local or mounted shared directory.
   - `cortex-ai`: synchronizes curated docs with Google Drive and NotebookLM via Cortex-AI skills.

## Hard Rules & Guardrails

- Never overwrite an existing `aff.yaml` without explicit confirmation or `--force`.
- Never store API tokens, database passwords, or cloud credentials inside `aff.yaml` or `knowledge/`; reference environment variable names only.
- Validate auto-detected stack versions against actual manifest files before writing `aff.yaml`.
- Ensure generated `.code-workspace` files use relative paths where possible so teammates can clone reproducibly.

## Outputs

1. Validated `aff.yaml` manifest at workspace root.
2. Seeded `knowledge/` hierarchy:
   - `knowledge/team/roster-and-ways-of-working.md`
   - `knowledge/business/domain-glossary.md`
   - `knowledge/architecture/system-landscape.md`
3. Workspace descriptor (`<project-slug>.code-workspace` when `topology: multi-root`).
4. Projected harness instructions via `./aigile harness sync`.

## Verification Checklist

- [ ] `aff.yaml` parses cleanly as valid YAML and contains all 6 configuration sections.
- [ ] Selected `profiles/*.md` entries exist on disk and match `aff.yaml` `stack.profiles`.
- [ ] `./aigile harness check` and `./aigile doctor` exit with status `0`.
- [ ] `./aigile secret-scan` confirms zero secrets in generated bootstrap files.
