# Universal Harness Compatibility & Projection Reference

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/harnesses/compatibility-matrix.md`](../../es/harnesses/compatibility-matrix.md)  
> **Related Manuals:** [Architecture Overview](../architecture/overview.md) · [Installation & Configuration](../guides/installation-and-configuration.md) · [Developer Workflow Manual](../guides/developer-workflow-manual.md)

`aigile-forge-framework` treats AI coding environments (**harnesses**) as compilation targets of a single canonical repository contract (`aff.yaml` + `AGENTS.md`). This reference documents every file emitted by `scripts/aff-harness.sh` (`./aigile harness`), how YAML frontmatter and MCP descriptors are transformed per harness, when to use `--symlink` versus `--copy`, and how `zero-mcp` policy enforcement works.

---

## 1. Exact Projected Files Matrix Across All 5 Harnesses

| Canonical Source | Claude Code (`claude`) | OpenCode (`opencode`) | Google Antigravity (`antigravity`) | OpenAI Codex (`codex`) | GitHub Copilot (`copilot`) |
|---|---|---|---|---|---|
| `AGENTS.md` + `aff.yaml` | `CLAUDE.md` *(imports `@AGENTS.md`)* | `AGENTS.md` *(native)* | `AGENTS.md` *(native)* | `AGENTS.md` *(native)* | `.github/copilot-instructions.md` *(synthesized from `aff.yaml`)* |
| `agents/*.md` *(10 roles)* | `.claude/agents/<slug>.md` | `.opencode/agents/<slug>.md` & `.agents/agents/<slug>.md` | `.agents/agents/<slug>.md` | `.agents/agents/<slug>.md` | `.github/agents/aff-<slug>.agent.md` |
| `skills/*/SKILL.md` *(19 bundles)* | `.claude/skills/` *(link or copy)* | `.agents/skills/` *(link or copy)* | `.agents/skills/` *(link or copy)* | `.agents/skills/` *(link or copy)* | `.github/skills/` *(link or copy)* |
| `profiles/*.md` *(enabled in `aff.yaml`)* | Referenced via `AGENTS.md` + `profiles/*.md` | Referenced via `AGENTS.md` + `profiles/*.md` | Referenced via `AGENTS.md` + `profiles/*.md` | Referenced via `AGENTS.md` + `profiles/*.md` | `.github/instructions/<slug>.instructions.md` |
| `prompts/*.prompt.md` *(9 slash flows)* | `.claude/commands/<name>.md` *(native `/command`)* | `.opencode/prompts/` & `.agents/skills/<name>/` | `.agents/workflows/<name>.md` & `.agents/skills/<name>/` | `.agents/skills/<name>/` | `.github/prompts/<name>.prompt.md` *(native `/command`)* |
| `mcp/*.json` *(when `mode == "mcp"`)* | `.mcp.json` (`mcpServers`, `type: "stdio"`) | `opencode.json` (`mcp`, `type: "local"`) | `.agents/mcp_config.json` (`mcpServers`) | Local CLI / `AGENTS.md` | Declarative IDE native *(no MCP file)* |
| `mcp/*.json` *(when `mode == "zero-mcp"`)* | `.mcp.json` **removed / omitted** | `opencode.json` with `"mcp": {}` | `.agents/mcp_config.json` **removed / omitted** | None | None |

*Note: `claude-code` is accepted as a CLI alias for `claude` (e.g., `./aigile harness sync claude-code`).*

---

## 2. `./aigile harness` Subcommands Reference (`scripts/aff-harness.sh`)

```bash
# 1. Project all harnesses using symlinked skills (default on Linux/macOS/WSL)
./aigile harness sync all

# 2. Project a specific comma-separated subset using copied skills & connected MCP mode
./aigile harness sync claude,copilot --copy --mode mcp

# 3. Project into an external workspace directory
./aigile harness sync all --copy --target-dir ~/workspaces/checkout-api

# 4. Validate canonical structure, SKILL.md frontmatter, JSON syntax & zero-mcp compliance
./aigile harness check
./aigile harness check --mode mcp

# 5. Inspect installed harness CLIs in PATH and projected target state ([LINK], [DIR], [FILE], [----])
./aigile harness status

# 6. Print the exact resolved JSON projection summary for a single harness
./aigile harness print claude
./aigile harness print opencode
./aigile harness print copilot

# 7. Clean all generated projections without touching canonical Layer 1 files
./aigile harness clean
```

### What `./aigile harness clean` Removes Safely
`./aigile harness clean` deletes only generated Layer 2 outputs:
- `CLAUDE.md`, `.mcp.json`, `opencode.json`
- `.claude/skills`, `.claude/agents` (and empty `.claude/`)
- `.agents/skills`, `.agents/agents`, `.agents/mcp_config.json` (and empty `.agents/`)
- `.opencode/agents` (and empty `.opencode/`)
- `.github/copilot-instructions.md`, `.github/instructions`, `.github/agents`, `.github/prompts`, `.github/skills` (preserving any existing `.github/workflows/` CI pipelines!).

---

## 3. Frontmatter & JSON Schema Transformations

Different AI harnesses expect subtly incompatible YAML frontmatter keys and MCP JSON schemas. `aff-harness.sh` compiles canonical definitions into each exact target dialect:

### 3.1 Specialist Agents Transformation (`agents/<slug>.md`)

**Canonical Source (`agents/architect.md`):**
```yaml
---
name: architect
description: Designs API and event contracts, enforces N/N-1 backwards compatibility, data/cache models, and optional 1:1 multi-channel parity for Gate G2.
role: Principal Software Architect
recommended_tools: ["read", "search", "edit"]
---
```

**Projected for Claude Code / OpenCode / Antigravity / Codex (`.claude/agents/architect.md`, `.agents/agents/architect.md`):**
```yaml
---
name: architect
description: "Designs API and event contracts, enforces N/N-1 backwards compatibility, data/cache models, and optional 1:1 multi-channel parity for Gate G2."
mode: all
---
```

**Projected for GitHub Copilot (`.github/agents/aff-architect.agent.md`):**
```yaml
---
name: aff-architect
description: "Designs API and event contracts, enforces N/N-1 backwards compatibility, data/cache models, and optional 1:1 multi-channel parity for Gate G2."
tools: ['read', 'search', 'edit', 'execute']
---
```

### 3.2 Stack Profile Transformation (`profiles/<slug>.md` -> `.github/instructions/<slug>.instructions.md`)

Only profiles listed under `profiles.enabled` in `aff.yaml` are emitted to `.github/instructions/` (stale disabled `.instructions.md` files are automatically unlinked during `sync`). Each emitted file strips metadata extraneous to VS Code Copilot and retains a strict `applyTo` glob header:

```yaml
---
applyTo: "**/*.{java,kt,kts,xml,gradle}"
---
```
If a custom profile omits `applyTo` in its canonical frontmatter, `infer_apply_to()` in `aff-harness.sh` automatically infers a deterministic glob from the profile filename (`jvm`/`spring`, `node`/`ts`, `python`/`go`, `frontend`/`web`, `mobile`, `data`/`sql`/`cache`, `cicd`/`container`).

### 3.3 MCP Server Fragment Compilation (`mcp/*.json`)

When `effective_mode == "mcp"`, `aff-harness.sh` merges enabled JSON fragments in `mcp/*.json` (skipping entries with `"enabled": false` or `"managed": true`, and honoring optional per-server `"harnesses": [...]` filters) into three distinct schemas:

1. **Claude Code (`.mcp.json`):** Wraps servers under `"mcpServers"` with `"type": "stdio"`, `"command": "<exe>"`, `"args": [...]`, and `"env": {...}`.
2. **Google Antigravity (`.agents/mcp_config.json`):** Wraps servers under `"mcpServers"` with `"command": "<exe>"`, `"args": [...]`, and `"env": {...}` (omitting `"type"` per Antigravity's schema).
3. **OpenCode (`opencode.json`):** Emits `"$schema": "https://opencode.ai/config.json"` and maps each server under `"mcp"` using `"type": "local"`, `"command": ["<exe>", "<arg1>", ...]`, `"enabled": true`, and `"env": {...}`.

---

## 4. `--symlink` vs `--copy` Selection Guide

| Scenario | Recommended Flag | Behavior & Rationale |
|---|---|---|
| Developing inside the framework repository on Linux, macOS, or WSL2 | `--symlink` *(Default)* | Creates relative symlinks (`.claude/skills -> ../skills`, `.agents/skills -> ../skills`, `.github/skills -> ../skills`). Edits to canonical `skills/` reflect instantaneously without re-syncing. |
| Bootstrapping an external workspace (`./aigile init --workspace /other/dir`) | `--copy` *(Automatic)* | Copies canonical `skills/` into the target directory so the external repository has zero brittle cross-directory symlink dependencies. |
| Windows Git-Bash / MSYS / Cygwin without Windows Developer Mode | `--copy` *(Automatic)* | Avoids NTFS privilege errors (`SeCreateSymbolicLinkPrivilege`) and ensures VS Code and CLI tools resolve skill files natively. |
| Packaging or archiving a self-contained project template | `--copy` | Guarantees `tar`/`zip` archives and container builds include concrete files. |

---

## 5. `zero-mcp` Policy Enforcement (`./aigile harness check`)

In regulated environments, committing an unintended `.mcp.json` or `.agents/mcp_config.json` file can trigger endpoint security alerts or spawn unapproved subprocesses. `./aigile harness check` acts as a deterministic CI/local gatekeeper:

1. Verifies all 7 canonical anchors exist (`AGENTS.md`, `aff.yaml`, `agents/`, `skills/`, `profiles/`, `prompts/`, `mcp/`).
2. Validates every `skills/<slug>/SKILL.md` frontmatter (`name` equals `<slug>`, kebab-case regex `^[a-z0-9]+(?:-[a-z0-9]+)*$`, non-empty `description`).
3. Parses every JSON file across `mcp/`, `configs/`, `*.code-workspace`, `opencode.json`, `.mcp.json`, and `.agents/mcp_config.json`.
4. **Enforces `zero-mcp` purity:** Whenever the effective mode is `zero-mcp`, `./aigile harness check` exits `1` if `.mcp.json` exists, if `.agents/mcp_config.json` exists, or if `opencode.json` contains a non-empty `"mcp"` map.
