---
name: cortex-ai-status
description: "Optional Cortex-AI skill (when knowledge.mode is cortex-ai) that audits sync drift, NotebookLM indexing health, and Engram cross-reference integrity for a project or team."
---

# Skill: Cortex-AI Sync & Indexing Health Audit

## Purpose & Activation

Activate when auditing the health and synchronization state of Cortex-AI knowledge indexing for the current project or across a team namespace (`cortex-ai status`, `knowledge status`). Detects drift between local `knowledge/` files, Google Drive mirrors, NotebookLM sources, and Engram cross-references.

## Inputs

- `aff.yaml` (`project.slug`, `team.name`, `knowledge.mode`, `knowledge.cortex`).
- `.aigile/knowledge-sync-manifest.json` and SHA256 hashes of current local `knowledge/**/*.md` files.
- Reachability and metadata from Drive, NotebookLM, and Engram MCP servers (when `capabilities.mode: mcp`).

## Health Classification Taxonomy

Classify each audited project deterministically into one of six states:
- `ok`: Local `knowledge/` SHA256 digests match `.aigile/knowledge-sync-manifest.json`, remote Drive files match, and NotebookLM sources are indexed.
- `desync`: One or more local `knowledge/` files were added or modified since `last_synced_at`.
- `pending-indexing`: Drive mirror is current, but NotebookLM source indexing is incomplete or stale.
- `init-incomplete`: `knowledge.mode: cortex-ai` is enabled, but `project_folder_id` or `notebook_id` is missing.
- `disabled`: `knowledge.mode` is `local` or `folder-sync` (informational, non-error).
- `unreachable`: Required Drive or NotebookLM MCP server is offline or timed out; local drift is still reported accurately.

## Step-by-Step Execution

### 1. Local Checksum & Manifest Audit
1. Inspect `aff.yaml` `knowledge.mode`. If `local` or `folder-sync`, report `disabled (active mode: <mode>)` and verify local `knowledge/` file integrity.
2. Compute SHA256 hashes for all Markdown files in `knowledge/` and compare against `.aigile/knowledge-sync-manifest.json` to count locally modified or unsynced files.

### 2. Remote Drive & NotebookLM Verification
1. Query the configured Drive folder (`knowledge.cortex.project_folder_id`) to confirm registry `README.md` validity and remote file count.
2. Query NotebookLM (`knowledge.cortex.notebook_id`) to obtain indexed source count and latest source update timestamp.
3. If a team-wide status report was requested, enumerate sibling project folders under `CORTEX-AI/{team-slug}/` and compute normalized health percentages across projects.

### 3. Engram Cross-Reference Check (Optional)
When Engram MCP is enabled, verify `cortex-ai/project/{project-slug}` matches the `project_folder_id` and `notebook_id` in `aff.yaml`, flagging any stale pointer.

### 4. Emit Deterministic Status Report
```text
CORTEX-AI Status — {team-slug}/{project-slug}
  Knowledge Mode   : cortex-ai
  Overall Health   : ok | desync | pending-indexing | init-incomplete | unreachable
  Local Docs       : {count} files ({unsynced_count} unsynced changes)
  Drive Registry   : verified | missing | unreachable (Last Sync: {iso_timestamp})
  NotebookLM Brain : {source_count} indexed sources | unreachable
  Recommended Next : <none | ./aigile knowledge sync | cortex-ai-init>
```

## Hard Rules & Guardrails

- **Never Fabricate Remote Telemetry**: When Drive or NotebookLM MCP is unreachable, report `unreachable` rather than assuming `ok`.
- **Read-Only Audit**: `cortex-ai-status` inspects and reports; it never uploads files or modifies remote folders.

## Outputs

- Deterministic project (or cross-project team) health report with exact unsynced file counts and actionable remediation command.

## Verification Checklist

- [ ] Local SHA256 drift against `.aigile/knowledge-sync-manifest.json` is computed deterministically.
- [ ] Offline or unreachable MCP servers are reported honestly as `unreachable` without fake counts.
- [ ] Every non-`ok` status provides the exact command needed to restore synchronization.
