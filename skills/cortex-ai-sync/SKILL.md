---
name: cortex-ai-sync
description: "Optional Cortex-AI skill (when knowledge.mode is cortex-ai) that sanitizes and synchronizes curated knowledge/ docs, ADRs, and specs to Google Drive and NotebookLM."
---

# Skill: Cortex-AI Knowledge Synchronization

## Purpose & Activation

Activate when `aff.yaml` sets `knowledge.mode: cortex-ai` and the user or Phase 8 closure triggers knowledge synchronization (`./aigile knowledge sync`, `cortex-ai sync`, or post-ADR curation). Uploads modified curated artifacts from `knowledge/` (and approved milestone specs/ADRs) to the configured Google Drive folder and refreshes NotebookLM source indexing.

## Inputs

- `aff.yaml` (`project.slug`, `team.name`, `knowledge.mode`, `knowledge.cortex.project_folder_id`, `knowledge.cortex.notebook_id`).
- Curated Markdown files in `knowledge/business/`, `knowledge/architecture/`, and `knowledge/team/`.
- Local sync manifest (`.aigile/knowledge-sync-manifest.json`) tracking per-file SHA256 digests and last-synced timestamps.

## Decision Gates

| Condition | Action |
|-----------|--------|
| `knowledge.mode != cortex-ai` | Delegate to `scripts/aff-knowledge-sync.sh` for `local` or `folder-sync` handling; skip Cortex-AI MCP calls |
| `./aigile secret-scan` detects secrets or unmasked PII | **ABORT SYNC IMMEDIATELY**; report offending file and line |
| Project not yet initialized in Cortex-AI | Prompt to run `cortex-ai-init` first |
| Drive upload succeeds, NotebookLM MCP times out | Record state as `pending-indexing` in manifest/Engram; report partial completion accurately |

## Step-by-Step Execution

### 1. Pre-Sync Security & Sanitization Gate
1. Execute `./aigile secret-scan` across `knowledge/` and any candidate spec/ADR files.
2. Verify zero credentials, private keys, or live customer PII/PHI/PCI appear in candidate files.

### 2. Compute Content Delta (SHA256)
1. Compute SHA256 checksums for every Markdown file under `knowledge/`.
2. Compare against `.aigile/knowledge-sync-manifest.json` to select only `NEW` or `MODIFIED` files (skipping unchanged files for fast idempotent syncs unless `--force` is passed).

### 3. Synchronize to Drive & Refresh NotebookLM
1. Upload new files or update modified files inside `CORTEX-AI/{team-slug}/{project-slug}/`.
2. Update the remote registry `README.md` `last_synced_at` UTC timestamp and source inventory table.
3. Add or refresh changed documents as sources in the linked NotebookLM notebook (`knowledge.cortex.notebook_id`).

### 4. Update Sync Manifest & Engram Metadata
1. Write updated SHA256 digests, UTC timestamps, and `indexing_status` (`ok` or `pending-indexing`) to `.aigile/knowledge-sync-manifest.json`.
2. When Engram MCP is available, upsert `cortex-ai/project/{project-slug}` with latest sync metadata (`capture_prompt: false`).

## Hard Rules & Guardrails

- **Never Sync Ephemeral Scratch Files**: Exclude `.env`, `.aigile/receipts/` raw logs, `node_modules/`, build outputs, and unapproved draft notes.
- **Never Delete Remote Archives Automatically**: Removing a local file marks it `archived_candidate` in the sync report rather than destructively purging historical Drive records without confirmation.
- **Honest Status Reporting**: Distinguish `synced + indexed` from `uploaded (pending-indexing)`.

## Outputs

- Updated remote Drive artifacts and NotebookLM indexed sources.
- Updated `.aigile/knowledge-sync-manifest.json` and concise sync summary table (`Added`, `Updated`, `Unchanged`, `Indexing Status`).

## Verification Checklist

- [ ] `./aigile secret-scan` exited `0` prior to any external upload.
- [ ] Only SHA256-changed curated Markdown artifacts were uploaded (unless `--force`).
- [ ] Sync manifest accurately reflects Drive upload and NotebookLM indexing outcomes.
