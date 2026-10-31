---
name: aff-intake
description: Ingest a raw backlog ticket, strip sensitive data, classify proportional size (S/M/L/H), and initialize work/<TICKET-ID>/ and state.yaml.
agent: orchestrator
---

# Ticket Intake & Proportional Triage (`/aff-intake`)

Load `agents/orchestrator.md`, `aff.yaml`, and `skills/odd-workflow/SKILL.md`.

Given the incoming ticket identifier (e.g., `PROJ-101`) and raw description:

1. **Sanitize Input:** Strip any secrets, tokens, PII, PCI, or PHI using `<REDACTED:...>` placeholders before persisting `work/<TICKET-ID>/ticket-in.md` (based on `templates/ticket-in.template.md`).
2. **Classify Change Size (`S / M / L / H`):**
   - `S`: Single-repo tweak/fix, `<= 150` LoC, zero API/schema contract changes.
   - `M`: Standard single or dual-repository feature.
   - `L`: Cross-repository feature, schema migration, or multi-channel contract impact.
   - `H`: Production incident / hotfix requiring immediate `incident-rca-debugging`.
3. **Initialize Governance State:** Create `work/<TICKET-ID>/state.yaml` from `templates/state.template.yaml` recording size class, affected lanes/repositories, and Phase `1`.
4. **Prepare Isolation:** If `workspace.topology` is `worktrees`, list or create the target worktree paths via `./aigile worktree` and start session tracking via `./aigile session start <TICKET-ID>`.
