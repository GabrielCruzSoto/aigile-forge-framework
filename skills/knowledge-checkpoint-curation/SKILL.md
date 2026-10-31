---
name: knowledge-checkpoint-curation
description: "Cold-resume session checkpoints, Architecture Decision Record (ADR) curation in knowledge/, drift detection, and pluggable sync across local, folder-sync, and cortex-ai modes."
---

# Skill: Knowledge Curation & Cold-Resume Checkpointing

## Purpose & Activation

Activate during Phase 8 (Knowledge Closure) via `/curate` or `/checkpoint` (`curator` agent), before ending an extended work session, or after merging significant architectural changes. Preserves durable institutional knowledge in `knowledge/`, writes deterministic session checkpoints so any engineer or AI harness resumes cold in seconds, and synchronizes knowledge via the backend configured in `aff.yaml`.

## Inputs

- Current `odd/tasks/<ticket>-<slug>.md`, completed `spec.md`, `contract.md`, `review.md`, or `rca.md`.
- Repository state (`git status`, current branch, latest commit SHA, latest RDD receipt).
- `aff.yaml` knowledge configuration (`knowledge.mode`: `local` | `folder-sync` | `cortex-ai`).

## Step-by-Step Workflow

### 1. Deterministic Cold-Resume Session Checkpoint
Run or update the session snapshot via `./aigile session save` (`scripts/aff-session.sh`) and synchronize `odd/tasks/<ticket>-<slug>.md`:
1. **Current State**: Active branch, `HEAD` commit SHA, completed `T#` units, and in-progress `T#` unit.
2. **Exact Next Cold-Executable Step**: Concrete file path, function/test target, and verification command a fresh session can execute immediately without re-discovering context.
3. **Active Blockers & Open Questions**: Unresolved human gates (`G1`–`G4`) or external dependencies.
4. **Discarded Approaches**: Failed hypotheses or rejected designs so the next session never repeats dead ends.

### 2. Distill Durable Knowledge into `knowledge/`
Separate volatile in-flight state (`odd/tasks/`, `.aigile/sessions/`) from permanent project knowledge (`knowledge/`):
- **Architecture Decision Records (`knowledge/architecture/adr-NNNN-<slug>.md`)**: Record Context, Decision, Alternatives Considered, Tradeoffs, and Consequences whenever introducing new libraries, patterns, schemas, or integration topologies.
- **Domain Glossary (`knowledge/business/domain-glossary.md`)**: Add newly clarified ubiquitous language terms, state machine rules, or error catalog invariants.
- **Team Runbooks (`knowledge/team/`)**: Add non-obvious build/test gotchas, migration procedures, or incident playbooks discovered during delivery.

### 3. Drift Detection Audit
Verify that updated documentation matches the actual filesystem and code:
- Confirm every file path, CLI flag, script name, and endpoint cited in `knowledge/` exists in the repository.
- Remove or supersede obsolete instructions rather than appending contradictory notes.

### 4. Pluggable Knowledge Synchronization
Dispatch synchronization according to `aff.yaml` `knowledge.mode`:
- `local`: Keep curated Markdown committed cleanly inside repository `knowledge/`.
- `folder-sync`: Execute `./aigile knowledge sync` (`scripts/aff-knowledge-sync.sh`) to mirror sanitized `knowledge/` artifacts to the configured shared directory path.
- `cortex-ai`: Delegate to `cortex-ai-sync` (and optional Engram `mem_save` when `capabilities.mode: mcp`) to index curated documents into the team's Drive + NotebookLM knowledge graph.

## Hard Rules & Guardrails

- **Pointer Over Duplication**: Link authoritative source schemas/configs rather than copy-pasting large code blocks that will drift.
- **Essentiality Filter**: Promote to `knowledge/` only facts that would cause a teammate or agent to make an error or waste investigation cycles if omitted.
- **Sanitize Before Sync**: Run `./aigile secret-scan` before syncing `knowledge/` to any external folder or cloud backend.

## Outputs

- Cold-resumable session state via `./aigile session` and `odd/tasks/<ticket>-<slug>.md`.
- Curated ADRs, glossary updates, or runbooks under `knowledge/`.
- Synchronized external knowledge mirror when `folder-sync` or `cortex-ai` is active.

## Verification Checklist

- [ ] Next step in checkpoint is cold-executable with exact paths and commands.
- [ ] All paths, endpoints, and commands referenced in `knowledge/` exist on disk.
- [ ] `./aigile secret-scan` passes before any `folder-sync` or `cortex-ai` synchronization.
