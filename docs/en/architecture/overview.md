# Universal Architecture & Deterministic Projection

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/architecture/overview.md`](../../es/architecture/overview.md)

## 1. Canonical Source Layout

AIgile Forge Framework separates **canonical engineering assets** from **projected harness targets** and **ephemeral runtime workspaces**:

```text
aigile-forge-framework/
├── aigile                     # Unified cross-platform CLI entrypoint
├── aff.yaml                   # Canonical project, team, topology & governance manifest
├── AGENTS.md                  # Universal AI engineering contract
├── agents/                    # 10 harness-neutral specialist role definitions
├── skills/                    # Procedural Agent Skills (SKILL.md bundles)
├── profiles/                  # 7 pluggable technology stack guardrail profiles
├── prompts/                   # Reusable slash-command prompt workflows (*.prompt.md)
├── templates/                 # Parameterized Markdown, YAML, and JSON workspace templates
├── mcp/                       # Parameterized MCP server descriptor fragments (*.json)
├── configs/                   # Canonical projector capability matrix (harnesses.json)
├── scripts/                   # Deterministic operational scripts (aff-*.sh)
├── knowledge/                 # Curated domain, architecture, roster & workflow docs
└── work/                      # Ephemeral ticket artifacts, session logs & RDD receipts
```

---

## 2. Deterministic Projector (`scripts/aff-harness.sh`)

Running `./aigile harness sync` reads `aff.yaml` and projects canonical assets into each enabled harness:

1. **Claude Code (`claude`)**
   - Generates `CLAUDE.md` importing `@AGENTS.md`.
   - Projects role agents to `.claude/agents/*.md` and links or copies `skills/` to `.claude/skills`.
   - Emits `.mcp.json` **only** when `harnesses.mode: "mcp"`; removes `.mcp.json` in `zero-mcp` mode.
2. **OpenCode (`opencode`)**
   - Reads `AGENTS.md` natively.
   - Projects role agents to `.agents/agents/` and `.opencode/agents/`, plus skills to `.agents/skills`.
   - Generates `opencode.json` with `"mcp": {}` in `zero-mcp` mode or merged server entries in `mcp` mode.
3. **Google Antigravity (`antigravity`)**
   - Reads `AGENTS.md` natively and loads `.agents/skills` and `.agents/agents`.
   - Emits `.agents/mcp_config.json` **only** when `harnesses.mode: "mcp"`.
4. **OpenAI Codex (`codex`)**
   - Uses `AGENTS.md` alongside `.agents/skills` and `.agents/agents`.
5. **GitHub Copilot (`copilot`)**
   - Synthesizes `.github/copilot-instructions.md` from `aff.yaml` context and global guardrails.
   - Projects each enabled stack profile in `profiles/*.md` to `.github/instructions/<profile>.instructions.md`, preserving `applyTo` file globs.
   - Emits custom Copilot agents `.github/agents/aff-<agent>.agent.md` with valid `description` and `tools: ['read', 'search', 'edit', 'execute']` frontmatter.
   - Copies slash workflows to `.github/prompts/*.prompt.md` and syncs `.github/skills/`.

---

## 3. Operational Modes (`zero-mcp` vs `mcp`)

- **`zero-mcp` (Default):** Designed for strict enterprise environments, air-gapped networks, or teams preferring zero external daemons. No MCP configuration files are left on disk, and knowledge stays local or syncs via filesystem directories (`./aigile sync --mode folder-sync`).
- **`mcp` (Connected / Cortex-AI):** Enables parameterized stdio MCP fragments from `mcp/*.json` (`engram`, `codegraph`, `google-drive`, `notebooklm`) using environment variable interpolation (`${ENGRAM_PROJECT}`, `${DRIVE_ROOT_FOLDER_ID}`) so zero live identifiers or secrets ever enter version control.

---

## 4. Schema Validation (`./aigile harness check`)

`./aigile harness check` validates:
- Presence of `AGENTS.md`, `aff.yaml`, `agents/`, `skills/`, `profiles/`, `prompts/`, and `mcp/`.
- `SKILL.md` YAML frontmatter conformance (`name` matching directory slug, non-empty `description`).
- Syntactic validity of all canonical and generated JSON files (`mcp/*.json`, `configs/*.json`, `opencode.json`, `.mcp.json`, `.agents/mcp_config.json`, `*.code-workspace`).
- Strict absence of MCP descriptor files when `harnesses.mode` is `zero-mcp`.
