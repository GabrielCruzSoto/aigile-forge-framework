---
name: init-team
description: Conduct the structured 6-dimension discovery interview to configure aff.yaml, workspace topology, and knowledge base artifacts for any development team.
agent: onboarding
---

# Team & Project Onboarding Interview (`/init-team`)

Load `agents/onboarding.md` and `skills/team-onboarding-bootstrap/SKILL.md`.

Guide the user one concise dimension at a time (waiting for confirmation after each step):

1. **Project & Workspace Identity:** `project.id`, `project.name`, `project.namespace`, and `workspace.topology` (`single-repo`, `worktrees`, or `multi-root` using `00-Project-Hub`).
2. **Team Roster & Language:** `team.name`, `team.lead_role`, key roles, and `team.language` (`conversation` and `artifacts`: `en` | `es`).
3. **Governance & Security Scope:** Gates (`G1`–`G4`, `dual_po_approval`), `multi_channel_parity`, and active redaction scopes (`secrets`, `pii`, `pci`, `phi`).
4. **Business Domain:** Core bounded contexts, personas, and domain glossary terms.
5. **Architecture, Repositories & Stack Profiles:** Repository inventory, lanes, databases/caches, CI/CD, and `profiles.enabled`.
6. **Ways of Working, Tracker & Harness Mode:** `tracker.provider`, `tracker.ticket_prefix`, `estimation` (`pert` / `story-points` / `none`), `harnesses.mode` (`zero-mcp` | `mcp`), and `harnesses.enabled`.

## Expected Deliverables
- Update `aff.yaml` (preserving valid YAML schema `"2.0"`).
- Populate `knowledge/team/roster.md`, `knowledge/team/workflow.md`, `knowledge/domain/overview.md`, and `knowledge/architecture/system-map.md` from `templates/`.
- If `workspace.topology` is `multi-root`, generate `<project-id>.code-workspace`.
- Run `./aigile harness sync` and `./aigile doctor` to confirm readiness.
