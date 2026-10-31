# aigile-forge-framework

> **Spanish documentation:** [`README.es.md`](README.es.md) | **Documentation Portal:** [`docs/en/index.md`](docs/en/index.md)

**`aigile-forge-framework`** is a universal, declarative engineering harness and governance framework for software development teams. From a single canonical source (`aff.yaml`, `AGENTS.md`, `agents/`, `skills/`, `profiles/`, `prompts/`, `templates/`, and `mcp/`), aigile-forge-framework deterministically projects instructions, specialist role agents, procedural skills, stack guardrails, and optional MCP descriptors across **Claude Code**, **OpenCode**, **Google Antigravity**, **OpenAI Codex**, and **GitHub Copilot**.

aigile-forge-framework adapts to any team size, technology stack, repository topology, and issue tracker without coupling your codebase to a specific AI vendor or organization.

---

## Quickstart

### 1. Interactive Initialization

Run the unified CLI wizard from the repository root to initialize a new or existing project workspace:

```bash
./aigile init
```

### 2. Non-Interactive Scaffolding

Provision a multi-root or worktree-based workspace in CI or automated scripts:

```bash
# Declarative Zero-MCP multi-root workspace
./aigile init \
  --name billing-platform \
  --team "Platform Engineering" \
  --lang en \
  --topology multi-root \
  --mode zero-mcp \
  --harnesses all \
  --tracker linear \
  --prefix BILL \
  --workspace ~/workspaces/billing-platform \
  --non-interactive

# Connected MCP + Git worktree workspace
./aigile init \
  --name core-api \
  --team "Core API Team" \
  --topology worktrees \
  --mode mcp \
  --tracker github \
  --prefix API \
  --workspace ~/workspaces/core-api \
  --non-interactive
```

### 3. Verify Baseline Health

```bash
./aigile doctor
./aigile harness check
./aigile scan --install-hook
```

---

## Architecture Overview

```mermaid
flowchart TD
    M["aff.yaml + AGENTS.md<br/>Single Canonical Contract"] --> P["./aigile harness sync<br/>Deterministic Projector"]
    A["agents/*.md (10 Roles)"] --> P
    S["skills/*/SKILL.md (Procedural Skills)"] --> P
    PR["profiles/*.md (7 Stack Profiles)"] --> P
    PM["prompts/*.prompt.md (Slash Prompts)"] --> P
    MC["mcp/*.json (Optional MCP Fragments)"] --> P

    P --> C["Claude Code<br/>CLAUDE.md, .claude/{agents,skills}, .mcp.json*"]
    P --> O["OpenCode<br/>AGENTS.md, .agents/{agents,skills}, opencode.json"]
    P --> G["Antigravity<br/>AGENTS.md, .agents/{agents,skills}, .agents/mcp_config.json*"]
    P --> X["Codex<br/>AGENTS.md, .agents/{agents,skills}"]
    P --> GH["GitHub Copilot<br/>.github/copilot-instructions.md<br/>.github/{instructions,agents,prompts,skills}"]
```

*\*MCP configuration files (`.mcp.json`, `.agents/mcp_config.json`, populated `opencode.json`) are emitted exclusively when `harnesses.mode: "mcp"`.*

---

## Universal Harness Matrix

| Harness | Root Contract | Specialist Agents | Procedural Skills | Scoped Stack Profiles | MCP Configuration (`mcp` mode) |
|---|---|---|---|---|---|
| **Claude Code** | `CLAUDE.md` (`@AGENTS.md`) | `.claude/agents/*.md` | `.claude/skills/` | Loaded via `AGENTS.md` + `profiles/` | `.mcp.json` |
| **OpenCode** | `AGENTS.md` | `.agents/agents/*.md` & `.opencode/agents/*.md` | `.agents/skills/` | Loaded via `AGENTS.md` + `profiles/` | `opencode.json` (`"mcp"`) |
| **Antigravity** | `AGENTS.md` | `.agents/agents/*.md` | `.agents/skills/` | Loaded via `AGENTS.md` + `profiles/` | `.agents/mcp_config.json` |
| **Codex** | `AGENTS.md` | `.agents/agents/*.md` | `.agents/skills/` | Loaded via `AGENTS.md` + `profiles/` | Native `AGENTS.md` + local CLI |
| **GitHub Copilot** | `.github/copilot-instructions.md` | `.github/agents/aff-*.agent.md` | `.github/skills/` | `.github/instructions/*.instructions.md` (`applyTo`) | Pure declarative (`.github/prompts/*.prompt.md`) |

---

## Zero-MCP vs Full-MCP Modes

aigile-forge-framework supports two operational modes controlled by `harnesses.mode` in `aff.yaml` or `--mode` on the CLI:

| Capability | `zero-mcp` Mode (Default) | `mcp` Mode (Connected / Cortex-AI) |
|---|---|---|
| **External Daemons / Binaries** | None required (100% file-based) | Parameterized stdio MCP servers |
| **Enterprise Firewall / Restricted VDI** | Works out of the box | Requires approved MCP binaries/tokens |
| **Claude `.mcp.json` / Antigravity `mcp_config.json`** | Omitted / removed cleanly | Generated from `mcp/*.json` |
| **OpenCode `opencode.json`** | `"mcp": {}` | Populated `"mcp"` server map |
| **Knowledge Synchronization** | `local` or `folder-sync` (`./aigile sync`) | `cortex-ai` skills (Engram, CodeGraph, Drive, NotebookLM) |

Switch modes at any time and re-project deterministically:

```bash
./aigile harness sync all --mode zero-mcp
./aigile harness sync all --mode mcp
```

---

## 8-Phase Engineering Lifecycle & Proportional Gates (`G1`–`G4`)

Work items are triaged proportionally (`S`, `M`, `L`, `H`) across an 8-phase lifecycle governed by four human verification gates and cryptographic **Receipt-Driven Development (RDD)** evidence:

| Phase | Name | Primary Role Agent | Key Artifact(s) | Gate |
|---|---|---|---|---|
| **0** | Intake & Triage (`S/M/L/H`) | `orchestrator` | `work/<ID>/ticket-in.md`, `state.yaml` | — |
| **1** | Discovery & Specification | `pm` / `analyst` | `elicitation.md`, `spec.md`, PERT estimate | **`G1`** — Scope & DoR Sign-Off (`G1a`/`G1b` optional) |
| **2** | Architecture & Contract-First | `architect` | `contract.md`, OpenAPI/AsyncAPI/Schema specs | **`G2`** — Contract & Cross-Channel Parity Sign-Off |
| **3** | Task Slicing & Worktree Isolation | `orchestrator` / `delivery` | `odd/tasks/*.md`, `worktrees/<ID>/` | — |
| **4** | Test-First Implementation | `delivery` | Production code + automated unit/integration tests | — |
| **5** | Adversarial 4R & Security Review | `reviewer` / `security` / `qa` | `review-4r.md` (**Risk, Requirements, Regression, Resilience**) | **`G3`** — Clean-Session 4R & Security Approval |
| **6** | Release Verification & Receipts | `qa` / `delivery` | `work/<ID>/evidence/receipt-G4.json` | **`G4`** — Release Readiness & Receipt Verification |
| **7** | Knowledge Curation & Closure | `curator` / `orchestrator` | `knowledge/*.md`, `ticket-out.md`, session close | — |

---

## Pluggable Stack Profiles (`profiles/`)

Enable or disable technology guardrails in `aff.yaml` under `profiles.enabled`:

1. **`backend-jvm-spring`** — Java 17/21, Kotlin null-safety, Spring Boot, constructor injection, RFC 7807 error contracts.
2. **`backend-node-ts`** — Strict TypeScript, Node.js async boundaries, schema validation, structured logging.
3. **`backend-python-go`** — Typed Python (`mypy`/`ruff`) and idiomatic Go (`context.Context`, explicit error wrapping).
4. **`frontend-web`** — Modern Angular/React/Vue/Web standards, WCAG accessibility, state isolation, bundle discipline.
5. **`mobile-native`** — Kotlin/Jetpack Compose (Android) & Swift/SwiftUI (iOS) with optional 1:1 API and UX parity.
6. **`data-sql-nosql-cache`** — Relational indexing, execution-plan validation, safe migrations, NoSQL patterns, and explicit cache TTLs.
7. **`cicd-containers`** — Multi-stage non-root container builds, pinned pipelines, secret-free build logs, and rollback safety.

---

## CLI Reference (`./aigile`)

| Command | Description |
|---|---|
| `./aigile init [options]` | Interactive or non-interactive workspace bootstrapper (`--name`, `--team`, `--lang`, `--topology`, `--mode`, `--harnesses`, `--tracker`, `--prefix`, `--workspace`, `--non-interactive`). |
| `./aigile harness <sync\|check\|status\|print\|clean>` | Project canonical sources to target harnesses, validate schemas, inspect status, or clean generated projections. |
| `./aigile doctor` | Verify OS, `bash`, `git`, `python3`/`jq`, `aff.yaml`, harness mode, and git pre-commit hook status. |
| `./aigile worktree <create\|list\|checkpoint\|remove>` | Manage ticket-isolated git worktrees under `worktrees/<ticket-id>/`. |
| `./aigile receipt <generate\|verify\|list>` | Generate SHA256-sealed JSON execution receipts (`generate <id> <gate> -- <cmd...>`) and verify integrity (`verify <file> [--verify-head]`). |
| `./aigile session <start\|checkpoint\|close\|resume>` | Maintain structured Markdown session journals under `work/sessions/`. |
| `./aigile scan [--path <p>\|--install-hook]` | Scan staged git diffs or paths for private keys, cloud/API tokens, hardcoded secrets, and raw 16-digit card numbers. |
| `./aigile sync [--status\|--sync [--dest <dir>]]` | Inspect or synchronize `knowledge/` via `local`, `folder-sync`, or `cortex-ai` modes. |

---

## Documentation Portal

- [Documentation Index (`docs/en/index.md`)](docs/en/index.md)
- [Architecture & Projector Overview (`docs/en/architecture/overview.md`)](docs/en/architecture/overview.md)
- [Team Onboarding & Workspace Topologies (`docs/en/guides/onboarding-and-topologies.md`)](docs/en/guides/onboarding-and-topologies.md)
- [8-Phase Lifecycle, Gates G1–G4, 4R Review & RDD Receipts (`docs/en/guides/lifecycle-gates-and-4r.md`)](docs/en/guides/lifecycle-gates-and-4r.md)
