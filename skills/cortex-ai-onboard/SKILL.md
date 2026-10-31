---
name: cortex-ai-onboard
description: "Optional Cortex-AI skill (when knowledge.mode is cortex-ai) that accelerates developer and agent onboarding by synthesizing Drive registries, NotebookLM context, and local workspace readiness."
---

# Skill: Cortex-AI Developer & Agent Onboarding

## Purpose & Activation

Activate when a new engineer or fresh agent session joins an existing project configured with `knowledge.mode: cortex-ai` (`cortex-ai onboard`, `onboard me to this project`). Synthesizes curated architecture, domain glossary, active contracts, recent ADRs, and local environment checks into an actionable onboarding briefing.

## Inputs

- `aff.yaml` (`project.name`, `project.slug`, `team.name`, `workspace.topology`, `stack.profiles`, `knowledge.cortex`).
- Remote registry in Google Drive + indexed NotebookLM notebook (with automatic fallback to local `knowledge/` when running offline or in `zero-mcp` mode).
- Local diagnostics from `./aigile doctor` (`scripts/aff-doctor.sh`).

## Step-by-Step Execution

### 1. Pull Authoritative Project Context
1. Read `aff.yaml` and local `AGENTS.md` to identify topology (`single-repo`, `worktrees`, `multi-root`), active stack profiles, and configured harnesses.
2. When Cortex-AI MCP servers are reachable, query the project NotebookLM notebook and Drive registry `README.md` for:
   - Domain overview and ubiquitous language top terms.
   - System architecture boundaries, upstream/downstream services, and active API contracts.
   - Most recent Architecture Decision Records (ADRs) and operational gotchas.
3. Supplement (or fall back if offline) with local `knowledge/business/`, `knowledge/architecture/`, `knowledge/team/`, and active `odd/tasks/*.md`.

### 2. Validate Local Environment Readiness
1. Run `./aigile doctor` in the foreground to verify required CLI tools (`git`, configured language runtimes, test runners, harness projection status).
2. Run `./aigile harness check` to confirm the developer's chosen AI harness (`claude`, `opencode`, `antigravity`, `codex`, or `copilot`) is synchronized with canonical rules.

### 3. Deliver Role-Aware Onboarding Briefing
Generate a concise, structured briefing tailored to the engineer's role (Backend, Web, Mobile, QA, Platform, or Full-Stack):
1. **Project & Team Snapshot**: Purpose, domain invariants, topology, and branch/PR rules.
2. **Architecture & Contracts Map**: Repositories, runtime versions, databases/caches, and key entry points.
3. **Active Stack Guardrails**: Summary of enforced `profiles/*.md` rules and human gates (`G1`–`G4`).
4. **In-Flight Work**: Open items in `odd/tasks/` (if any).
5. **Environment Readiness Verdict**: Output of `./aigile doctor` with exact commands to fix any missing local dependency or unsynced harness.

## Hard Rules & Guardrails

- **Never Mutate Remote Knowledge During Onboarding**: Onboarding is read-only externally; local changes are limited to `./aigile harness sync` if requested by the developer.
- **Verify Paths Against Local Disk**: Confirm every cited repository entry point and command exists locally before recommending it.
- **Zero Secret Display**: Never print environment secret values while checking local setup; check variable presence (`SET` vs `MISSING`) only.

## Outputs

- Structured onboarding briefing with cited `[NotebookLM]` / `[local]` architecture facts and verified `./aigile doctor` readiness checklist.

## Verification Checklist

- [ ] `./aigile doctor` and `./aigile harness check` were executed and reported accurately.
- [ ] Briefing covers domain glossary, repo topology, active `profiles/*.md`, and `G1`–`G4` workflow gates.
- [ ] Offline fallback works seamlessly using local `knowledge/` if MCP servers are unreachable.
