---
name: cortex-ai-ask
description: "Optional Cortex-AI skill (when knowledge.mode is cortex-ai) that answers historical, architectural, and domain questions using NotebookLM-first resolution with cited local fallback."
---

# Skill: Cortex-AI Cited Knowledge Query

## Purpose & Activation

Activate when `aff.yaml` sets `knowledge.mode: cortex-ai` and a user or agent asks about project history, prior architectural decisions, cross-repository domain rules, or approved specifications (`ask cortex`, `what was decided about`, `architecture history`). Do **not** activate for line-by-line source code inspection, which belongs to direct repository search.

## Inputs

- Natural-language question about domain rules, ADRs, contracts, or historical decisions.
- `aff.yaml` (`project.slug`, `knowledge.cortex.notebook_id`) and local `knowledge/` + `odd/tasks/` directories.

## Resolution Order & Decision Gates

| Condition | Action |
|-----------|--------|
| NotebookLM MCP available + project notebook indexed | Query NotebookLM **first**; cite claims as `[NotebookLM: <source-title>]` |
| NotebookLM answer incomplete or potentially stale | Supplement with local `knowledge/` and `odd/tasks/` search; label each claim `[NotebookLM]` vs `[local: <path>]` |
| NotebookLM MCP offline or `knowledge.mode != cortex-ai` | Fall back cleanly to local `knowledge/` + Engram search; state explicitly that response is `[local]` only |
| Local docs contain newer info absent from NotebookLM | Deliver accurate cited answer and recommend running `cortex-ai-sync` |
| Neither NotebookLM nor local docs support an answer | State `"No verified context available in NotebookLM or local knowledge/"` — never guess or fabricate |

## Step-by-Step Execution

### 1. Resolve Project Knowledge Coordinates
1. Read `aff.yaml` to obtain `project.slug` and `knowledge.cortex.notebook_id` (or resolve via Engram topic `cortex-ai/project/{project-slug}`).
2. Verify whether NotebookLM MCP is reachable in the current runtime.

### 2. Primary Query: NotebookLM Grounded Synthesis
1. Submit a focused, neutral query to the project's NotebookLM notebook requesting source-grounded citations.
2. Inspect returned passages and verify they address the exact domain entity, version, or decision asked about.

### 3. Secondary Verification & Local Fallback
1. Cross-check local `knowledge/architecture/`, `knowledge/business/`, and `odd/tasks/` whenever local commits post-date the last `.aigile/knowledge-sync-manifest.json` timestamp.
2. If local curated ADRs supersede an older NotebookLM source, prioritize the newer repository-committed ADR, cite `[local: knowledge/architecture/...]`, and flag sync drift.

### 4. Compose Cited Response
Present a concise answer structured as:
- **Answer**: Direct, unambiguous synthesis.
- **Sources**: Explicit `[NotebookLM: ...]` and/or `[local: ...]` provenance per claim.
- **Sync Health Note** (only when drift detected): Prompt to run `./aigile knowledge sync`.

## Hard Rules & Guardrails

- **Strict Provenance**: Every factual statement MUST carry `[NotebookLM: ...]` or `[local: ...]`.
- **Zero Hallucination on Missing Evidence**: Absence of documentation is reported transparently, never patched with plausible invention.
- **Read-Only Execution**: `cortex-ai-ask` never mutates repository files, Drive folders, or NotebookLM sources.

## Outputs

- Source-cited answer distinguishing indexed cloud knowledge from local repository files, plus drift advisory when unsynced local changes exist.

## Verification Checklist

- [ ] NotebookLM was queried first whenever `knowledge.mode: cortex-ai` and MCP was reachable.
- [ ] Every claim includes an explicit `[NotebookLM: ...]` or `[local: ...]` citation.
- [ ] Unverified or missing facts are explicitly declared rather than inferred.
