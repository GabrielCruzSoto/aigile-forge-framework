#!/usr/bin/env bash
# ==============================================================================
# Script: aff-harness.sh
# Purpose: Universal deterministic harness projector for aigile-forge-framework.
#          Projects a single canonical source (aff.yaml, AGENTS.md, agents/,
#          skills/, profiles/, prompts/, mcp/) across Claude Code, OpenCode,
#          Google Antigravity, OpenAI Codex, and GitHub Copilot.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SUBCOMMAND="${1:-help}"
shift || true

LINK_MODE="symlink"
CLI_MCP_MODE=""
TARGET_DIR="$BASE_DIR"
HARNESS_ARG=""

usage() {
    cat <<'EOF'
Usage: aff-harness.sh <command> [harness] [options]

Commands:
  sync [harness]     Project canonical definitions to target harness(es)
                     Harnesses: all (default), claude, opencode, antigravity,
                     codex, copilot, or comma-separated list (e.g. claude,copilot)
  check              Validate canonical directories, YAML/JSON schemas, and projections
  status             Display detected harness CLIs, active mode, and projection status
  print <harness>    Print projected configuration summary for a single harness
  clean              Remove generated harness projections without touching canonical files
  help               Show this help message

Options:
  --copy                 Copy skills instead of creating symlinks
  --symlink              Symlink skills to canonical skills/ directory (default)
  --mode <zero-mcp|mcp>  Override harnesses.mode from aff.yaml
  --target-dir <dir>     Target workspace directory (defaults to repository root)
  -h, --help             Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --copy)
            LINK_MODE="copy"
            shift
            ;;
        --symlink)
            LINK_MODE="symlink"
            shift
            ;;
        --mode)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --mode requires 'zero-mcp' or 'mcp'." >&2
                exit 1
            fi
            CLI_MCP_MODE="$2"
            shift 2
            ;;
        --target-dir)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --target-dir requires a directory path." >&2
                exit 1
            fi
            mkdir -p "$2"
            TARGET_DIR="$(cd "$2" && pwd)"
            shift 2
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            if [ -z "$HARNESS_ARG" ]; then
                HARNESS_ARG="$1"
                shift
            else
                echo "ERROR: unexpected argument: $1" >&2
                usage >&2
                exit 1
            fi
            ;;
    esac
done

if [ -n "$CLI_MCP_MODE" ] && [ "$CLI_MCP_MODE" != "zero-mcp" ] && [ "$CLI_MCP_MODE" != "mcp" ]; then
    echo "ERROR: invalid --mode '$CLI_MCP_MODE' (expected 'zero-mcp' or 'mcp')." >&2
    exit 1
fi

# Resolve canonical source root (prefer TARGET_DIR when self-contained, fallback to BASE_DIR)
resolve_source_path() {
    local rel="$1"
    if [ -e "$TARGET_DIR/$rel" ]; then
        printf '%s' "$TARGET_DIR/$rel"
    else
        printf '%s' "$BASE_DIR/$rel"
    fi
}

sync_skills_dir() {
    local dest_rel="$1"
    local dest_path="$TARGET_DIR/$dest_rel"
    local src_skills
    src_skills="$(resolve_source_path "skills")"

    if [ ! -d "$src_skills" ]; then
        echo "ERROR: canonical skills directory not found: $src_skills" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$dest_path")"

    if [ -L "$dest_path" ]; then
        rm -f "$dest_path"
    elif [ -d "$dest_path" ]; then
        rm -rf "$dest_path"
    elif [ -e "$dest_path" ]; then
        rm -f "$dest_path"
    fi

    mkdir -p "$dest_path"

    if [ "$LINK_MODE" = "copy" ]; then
        cp -R "$src_skills"/. "$dest_path"/
        echo "  [OK] Copied skills -> $dest_rel"
    else
        for sdir in "$src_skills"/*; do
            [ -d "$sdir" ] || continue
            sname="$(basename "$sdir")"
            if [ "$src_skills" = "$TARGET_DIR/skills" ]; then
                ln -sf "../../skills/$sname" "$dest_path/$sname"
            else
                ln -sf "$sdir" "$dest_path/$sname"
            fi
        done
        echo "  [OK] Symlinked skills -> $dest_rel"
    fi
}

run_python_projector() {
    local action="$1"
    AFF_ACTION="$action" \
    AFF_BASE_DIR="$BASE_DIR" \
    AFF_TARGET_DIR="$TARGET_DIR" \
    AFF_HARNESS_ARG="${HARNESS_ARG:-all}" \
    AFF_CLI_MODE="$CLI_MCP_MODE" \
    AFF_LINK_MODE="$LINK_MODE" \
    python3 - <<'PY'
import json
import os
import re
import shutil
import sys
from pathlib import Path

action = os.environ["AFF_ACTION"]
base_dir = Path(os.environ["AFF_BASE_DIR"]).resolve()
target_dir = Path(os.environ["AFF_TARGET_DIR"]).resolve()
harness_arg = os.environ["AFF_HARNESS_ARG"].strip() or "all"
cli_mode = os.environ["AFF_CLI_MODE"].strip()
link_mode = os.environ["AFF_LINK_MODE"].strip()

VALID_HARNESSES = ("claude", "opencode", "antigravity", "codex", "copilot")
HARNESS_ALIASES = {"claude-code": "claude"}


def resolve_src(rel: str) -> Path:
    candidate = target_dir / rel
    if candidate.exists():
        return candidate
    return base_dir / rel


def load_yaml_manifest(path: Path) -> dict:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8", errors="replace")
    try:
        import yaml  # type: ignore
        loaded = yaml.safe_load(text)
        return loaded if isinstance(loaded, dict) else {}
    except ImportError:
        pass
    except Exception as exc:
        raise ValueError(f"Invalid YAML in {path}: {exc}") from exc

    # Minimal pure-Python fallback parser for core aff.yaml fields when PyYAML is absent
    data: dict = {"harnesses": {}, "profiles": {"enabled": []}, "project": {}, "team": {}, "workspace": {}, "tracker": {}}
    section = ""
    subsection = ""
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        top = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if top:
            section = top.group(1)
            subsection = ""
            continue
        sub = re.match(r"^  ([A-Za-z0-9_-]+):\s*(.*)$", line)
        if sub:
            key, val = sub.group(1), sub.group(2).strip().strip("\"'")
            subsection = key
            if val:
                data.setdefault(section, {})[key] = val
            continue
        item = re.match(r"^    -\s*[\"']?([^\"']+)[\"']?\s*$", line)
        if item and section == "profiles" and subsection == "enabled":
            data["profiles"]["enabled"].append(item.group(1).strip())
        elif item and section == "harnesses" and subsection == "enabled":
            data["harnesses"].setdefault("enabled", []).append(item.group(1).strip())
    return data


manifest_path = resolve_src("aff.yaml")
try:
    manifest = load_yaml_manifest(manifest_path)
except ValueError as exc:
    print(f"ERROR: {exc}", file=sys.stderr)
    sys.exit(1)

harnesses_cfg = manifest.get("harnesses") if isinstance(manifest.get("harnesses"), dict) else {}
effective_mode = cli_mode or str(harnesses_cfg.get("mode") or "zero-mcp").strip()
if effective_mode not in ("zero-mcp", "mcp"):
    effective_mode = "zero-mcp"

profiles_cfg = manifest.get("profiles")
enabled_profiles = None
if isinstance(profiles_cfg, dict) and isinstance(profiles_cfg.get("enabled"), list):
    enabled_profiles = [str(p).strip() for p in profiles_cfg["enabled"] if str(p).strip()]
elif isinstance(profiles_cfg, list):
    enabled_profiles = [str(p).strip() for p in profiles_cfg if str(p).strip()]


def parse_target_harnesses(raw: str, default_from_manifest: bool = True) -> list[str]:
    if raw == "all":
        if default_from_manifest and isinstance(harnesses_cfg.get("enabled"), list) and harnesses_cfg["enabled"]:
            items = [HARNESS_ALIASES.get(str(x).strip(), str(x).strip()) for x in harnesses_cfg["enabled"]]
            valid = [h for h in items if h in VALID_HARNESSES]
            if valid and raw != "all":
                return valid
        return list(VALID_HARNESSES)
    parts = [HARNESS_ALIASES.get(p.strip(), p.strip()) for p in raw.split(",") if p.strip()]
    for p in parts:
        if p not in VALID_HARNESSES:
            print(f"ERROR: unsupported harness '{p}' (expected one of: all, {', '.join(VALID_HARNESSES)})", file=sys.stderr)
            sys.exit(1)
    return parts


def split_frontmatter(md_text: str) -> tuple[dict[str, str], str, str]:
    match = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n?(.*)$", md_text, re.S)
    if not match:
        return {}, "", md_text
    fm_raw = match.group(1)
    body = match.group(2)
    meta: dict[str, str] = {}
    for line in fm_raw.splitlines():
        kv = re.match(r"^([A-Za-z0-9_-]+):\s*(.+)$", line.strip())
        if kv:
            meta[kv.group(1)] = kv.group(2).strip().strip("\"'")
    return meta, fm_raw, body


def load_mcp_fragments() -> dict[str, dict]:
    mcp_dir = resolve_src("mcp")
    merged: dict[str, dict] = {}
    if not mcp_dir.is_dir():
        return merged

    for jpath in sorted(mcp_dir.glob("*.json")):
        try:
            raw = json.loads(jpath.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"ERROR: invalid JSON in {jpath}: {exc}", file=sys.stderr)
            sys.exit(1)
        if not isinstance(raw, dict):
            continue

        entries = raw.get("mcpServers") if isinstance(raw.get("mcpServers"), dict) else raw.get("mcp")
        if not isinstance(entries, dict):
            entries = raw

        for name, spec in entries.items():
            if not isinstance(spec, dict) or spec.get("managed"):
                continue
            if spec.get("enabled") is False:
                continue
            cmd = spec.get("command", "")
            args = spec.get("args", [])
            if isinstance(cmd, list):
                if not cmd:
                    continue
                executable, cmd_args = str(cmd[0]), [str(x) for x in cmd[1:]]
            else:
                executable = str(cmd)
                cmd_args = [str(x) for x in args] if isinstance(args, list) else []
            if not executable:
                continue
            merged[name] = {
                "command": executable,
                "args": cmd_args,
                "env": spec.get("env") if isinstance(spec.get("env"), dict) else {},
                "harnesses": spec.get("harnesses") if isinstance(spec.get("harnesses"), list) else None,
            }
    return merged


def build_stdio_mcp(servers: dict[str, dict], harness: str, include_type: bool = True) -> dict:
    out = {}
    for name, spec in servers.items():
        if spec["harnesses"] is not None and harness not in spec["harnesses"]:
            continue
        entry: dict = {}
        if include_type:
            entry["type"] = "stdio"
        entry["command"] = spec["command"]
        if spec["args"]:
            entry["args"] = spec["args"]
        if spec["env"]:
            entry["env"] = spec["env"]
        out[name] = entry
    return out


def build_opencode_mcp(servers: dict[str, dict]) -> dict:
    out = {}
    for name, spec in servers.items():
        if spec["harnesses"] is not None and "opencode" not in spec["harnesses"]:
            continue
        entry: dict = {
            "type": "local",
            "command": [spec["command"], *spec["args"]],
            "enabled": True,
        }
        if spec["env"]:
            entry["env"] = spec["env"]
        out[name] = entry
    return out


def infer_apply_to(profile_slug: str) -> str:
    slug = profile_slug.lower()
    if "jvm" in slug or "spring" in slug or "java" in slug:
        return "**/*.{java,kt,kts,xml,gradle}"
    if "node" in slug or "ts" in slug or "typescript" in slug:
        return "**/*.{ts,tsx,js,mjs,cjs,json}"
    if "python" in slug or "go" in slug:
        return "**/*.{py,go,mod,toml}"
    if "frontend" in slug or "web" in slug:
        return "**/*.{ts,tsx,js,jsx,html,css,scss,vue,svelte}"
    if "mobile" in slug:
        return "**/*.{kt,kts,swift,xml,plist,dart}"
    if "data" in slug or "sql" in slug or "cache" in slug:
        return "**/*.{sql,prisma,yaml,yml,json}"
    if "cicd" in slug or "container" in slug or "devops" in slug:
        return "**/{Dockerfile*,docker-compose*,*.sh,.github/workflows/*.yml,.gitlab-ci.yml,Jenkinsfile}"
    return "**/*"


# ------------------------------------------------------------------------------
# Capability model (Ports & Adapters)
# Canonical agents declare abstract capabilities; each harness adapter translates
# them into its native schema. Golden rule: an allowlist is only emitted to
# RESTRICT an agent, never to enable it. Agents holding every write-class
# capability inherit the harness-native toolset (including delegation tools).
# ------------------------------------------------------------------------------
CAPABILITY_VOCAB = ("read", "search", "edit", "terminal", "delegate")
CAPABILITY_ALIASES = {
    "write": "edit",
    "execute": "terminal",
    "exec": "terminal",
    "bash": "terminal",
    "shell": "terminal",
    "agent": "delegate",
    "subagent": "delegate",
    "task": "delegate",
}
DEFAULT_CAPABILITIES = ["read", "search", "edit", "terminal"]


def _raw_capability_tokens(meta: dict) -> list[str]:
    raw = meta.get("capabilities") or meta.get("recommended_tools") or meta.get("tools") or ""
    if not raw:
        return []
    if isinstance(raw, list):
        return [str(x).strip().strip("\"'").lower() for x in raw if str(x).strip()]
    try:
        loaded = json.loads(raw)
        if isinstance(loaded, list):
            return [str(x).strip().strip("\"'").lower() for x in loaded if str(x).strip()]
    except Exception:
        pass
    return [t.lower() for t in re.findall(r"[a-zA-Z0-9_-]+", str(raw))]


def unknown_capabilities(meta: dict) -> list[str]:
    return [
        t for t in _raw_capability_tokens(meta)
        if CAPABILITY_ALIASES.get(t, t) not in CAPABILITY_VOCAB
    ]


def parse_recommended_tools(meta: dict) -> list[str]:
    tokens = _raw_capability_tokens(meta)
    if not tokens:
        return list(DEFAULT_CAPABILITIES)
    caps: list[str] = []
    for tok in tokens:
        cap = CAPABILITY_ALIASES.get(tok, tok)
        if cap in CAPABILITY_VOCAB and cap not in caps:
            caps.append(cap)
    return caps if caps else list(DEFAULT_CAPABILITIES)


def is_full_writer(caps: list[str]) -> bool:
    return "edit" in caps and "terminal" in caps


def build_claude_tools(caps: list[str]) -> "str | None":
    """Claude Code: omitting `tools` inherits every tool (Write, Agent, MCP...)."""
    if is_full_writer(caps):
        return None
    tools: list[str] = []
    if "read" in caps:
        tools.append("Read")
    if "search" in caps:
        tools.extend(["Grep", "Glob"])
    if "edit" in caps:
        tools.extend(["Write", "Edit"])
    if "terminal" in caps:
        tools.append("Bash")
    if "delegate" in caps:
        tools.append("Agent")
    if not tools:
        tools = ["Read", "Grep", "Glob"]
    return ", ".join(tools)


def build_antigravity_tools(caps: list[str]) -> bool:
    """Antigravity: `tools` is a strict allowlist with version-dependent names.

    Never emit it; rely solely on the native `readonly` flag. Returns readonly.
    """
    return not ("edit" in caps or "terminal" in caps)


def build_opencode_tools(caps: list[str]) -> dict[str, bool]:
    """OpenCode: `tools` is a boolean map; every tool is enabled by default.

    Only emit disabled entries, so unknown/new native tools stay available.
    """
    disabled: dict[str, bool] = {}
    if "edit" not in caps:
        disabled.update({"write": False, "edit": False, "patch": False})
    if "terminal" not in caps:
        disabled["bash"] = False
    if "delegate" not in caps:
        disabled["task"] = False
    return disabled


def build_copilot_tools(caps: list[str]) -> list[str]:
    gh_tools = []
    if "read" in caps:
        gh_tools.append("read")
    if "search" in caps:
        gh_tools.append("search")
    if "edit" in caps:
        gh_tools.append("edit")
    if "terminal" in caps:
        gh_tools.append("execute")
    if "delegate" in caps:
        gh_tools.append("agent")
    return gh_tools if gh_tools else ["read"]


def sync_claude_agents() -> int:
    src_agents = resolve_src("agents")
    if not src_agents.is_dir():
        print(f"ERROR: canonical agents directory not found: {src_agents}", file=sys.stderr)
        sys.exit(1)
    dest = target_dir / ".claude" / "agents"
    dest.mkdir(parents=True, exist_ok=True)
    count = 0
    for md in sorted(src_agents.glob("*.md")):
        if md.name.lower() == "readme.md":
            continue
        text = md.read_text(encoding="utf-8", errors="replace")
        meta, _, body = split_frontmatter(text)
        slug = meta.get("name") or md.stem
        desc = meta.get("description") or ""
        if not desc:
            m_role = re.search(r"^\s*-\s*\*\*(?:Role|Purpose):\*\*\s*(.+)$", body, re.M)
            desc = m_role.group(1).strip() if m_role else slug.replace("-", " ").title()
        desc_escaped = desc.replace('"', '\\"')
        rec_tools = parse_recommended_tools(meta)
        c_tools = build_claude_tools(rec_tools)
        tools_line = f"tools: {c_tools}\n" if c_tools else ""
        rendered = (
            "---\n"
            f"name: {slug}\n"
            f'description: "{desc_escaped}"\n'
            f"{tools_line}"
            "---\n\n"
            + body.lstrip("\r\n").rstrip()
            + "\n"
        )
        (dest / f"{slug}.md").write_text(rendered, encoding="utf-8")
        count += 1
    print(f"  [OK] Projected {count} agent(s) -> .claude/agents")
    return count


def sync_antigravity_agents() -> int:
    src_agents = resolve_src("agents")
    if not src_agents.is_dir():
        print(f"ERROR: canonical agents directory not found: {src_agents}", file=sys.stderr)
        sys.exit(1)
    dest = target_dir / ".agents" / "agents"
    dest.mkdir(parents=True, exist_ok=True)
    count = 0
    for md in sorted(src_agents.glob("*.md")):
        if md.name.lower() == "readme.md":
            continue
        text = md.read_text(encoding="utf-8", errors="replace")
        meta, _, body = split_frontmatter(text)
        slug = meta.get("name") or md.stem
        desc = meta.get("description") or ""
        if not desc:
            m_role = re.search(r"^\s*-\s*\*\*(?:Role|Purpose):\*\*\s*(.+)$", body, re.M)
            desc = m_role.group(1).strip() if m_role else slug.replace("-", " ").title()
        desc_escaped = desc.replace('"', '\\"')
        rec_tools = parse_recommended_tools(meta)
        is_readonly = build_antigravity_tools(rec_tools)
        rendered = (
            "---\n"
            f"name: {slug}\n"
            f'description: "{desc_escaped}"\n'
            f"readonly: {'true' if is_readonly else 'false'}\n"
            "---\n\n"
            + body.lstrip("\r\n").rstrip()
            + "\n"
        )
        (dest / f"{slug}.md").write_text(rendered, encoding="utf-8")
        agent_sub = dest / slug
        agent_sub.mkdir(parents=True, exist_ok=True)
        (agent_sub / "agent.md").write_text(rendered, encoding="utf-8")
        count += 1
    print(f"  [OK] Projected {count} agent(s) -> .agents/agents")
    return count


def sync_antigravity_rules() -> int:
    rules_dir = target_dir / ".agents" / "rules"
    rules_dir.mkdir(parents=True, exist_ok=True)
    rule_file = rules_dir / "antigravity-runtime.md"
    rule_content = """# Antigravity Runtime & Orchestration Rule

> Canonical reference: see [`AGENTS.md`](../../AGENTS.md) at the workspace root.
> Generated deterministically by `./aigile harness sync antigravity`.

## 1. Orchestrator Role & Tool Permissions
- The `orchestrator` agent in Antigravity is a **Lifecycle & Workspace Orchestrator**, responsible for ticket intake, worktree isolation, session continuity, and cryptographic human gate verification (`G1`–`G4`).
- The `orchestrator` must maintain active terminal execution and file write capabilities (`run_command`, `write_file`, `edit_file`) to execute `./aigile worktree`, `./aigile session`, Git operations, and maintain `work/<TICKET-ID>/state.yaml`.
- Never strip or deny write permissions from the orchestrator. It is not an advisory-only planner.

## 2. Dynamic Subagent Delegation Protocol
- Antigravity manages subagents dynamically in memory via `define_subagent` and `invoke_subagent`. Static markdown files under `.agents/agents/` serve as specification baselines, not auto-loaded workers.
- When delegating to sub-roles (`delivery`, `qa`, `analyst`, `architect`, `security`, `reviewer`, `curator`):
  1. Load role prompt from `agents/<role>.md` and primary skill from `skills/*/SKILL.md`.
  2. Call `define_subagent`:
     - Set `EnableWriteTools: true` for roles that perform code edits, create documentation, or execute verification commands (`delivery`, `qa`, `orchestrator`, `analyst`, `architect`, `curator`, `onboarding`, and for `reviewer`/`security` when running test/audit commands).
     - Set `EnableMCPTools: true` when `harnesses.mode` is `"mcp"` (for Engram, CodeGraph, Drive, NotebookLM).
     - Set `EnableSubagentTools: false` unless nested subagent delegation is explicitly required (max depth <= 10).
  3. Call `invoke_subagent` with the defined subagent name, scoped task instructions, and workspace path.
  4. Verify returned changes and test exit codes on disk before advancing `state.yaml` gates.
- **Inline Fallback**: If subagent delegation is unavailable, denied, or max nesting depth is reached, execute the role inline in the current session without failing or asking the user to change harness.

## 3. Skills as Native Slash Commands
- All workflow slash prompts (`/aff-intake`, `/elicit-ticket`, `/answers-to-spec`, `/contract-first`, `/parity-check`, `/work-units`, `/review-4r`, `/review-refuter`, `/init-team`) are migrated to first-class skills under `.agents/skills/<name>/SKILL.md`.
- Invoke slash commands directly via `/<name>` in the chat interface.
"""
    rule_file.write_text(rule_content, encoding="utf-8")
    print("  [OK] Generated .agents/rules/antigravity-runtime.md")
    return 1


def sync_opencode_agents() -> int:
    src_agents = resolve_src("agents")
    if not src_agents.is_dir():
        print(f"ERROR: canonical agents directory not found: {src_agents}", file=sys.stderr)
        sys.exit(1)
    dest = target_dir / ".opencode" / "agents"
    dest.mkdir(parents=True, exist_ok=True)
    count = 0
    for md in sorted(src_agents.glob("*.md")):
        if md.name.lower() == "readme.md":
            continue
        text = md.read_text(encoding="utf-8", errors="replace")
        meta, _, body = split_frontmatter(text)
        slug = meta.get("name") or md.stem
        desc = meta.get("description") or ""
        if not desc:
            m_role = re.search(r"^\s*-\s*\*\*(?:Role|Purpose):\*\*\s*(.+)$", body, re.M)
            desc = m_role.group(1).strip() if m_role else slug.replace("-", " ").title()
        desc_escaped = desc.replace('"', '\\"')
        rec_tools = parse_recommended_tools(meta)
        oc_disabled = build_opencode_tools(rec_tools)
        tools_block = (
            "tools:\n" + "".join(f"  {k}: false\n" for k in oc_disabled)
            if oc_disabled else ""
        )
        rendered = (
            "---\n"
            f"name: {slug}\n"
            f'description: "{desc_escaped}"\n'
            "mode: all\n"
            f"{tools_block}"
            "---\n\n"
            + body.lstrip("\r\n").rstrip()
            + "\n"
        )
        (dest / f"{slug}.md").write_text(rendered, encoding="utf-8")
        count += 1
    print(f"  [OK] Projected {count} agent(s) -> .opencode/agents")
    return count


def sync_copilot() -> None:
    src_agents = resolve_src("agents")
    src_profiles = resolve_src("profiles")
    src_prompts = resolve_src("prompts")

    proj = manifest.get("project") if isinstance(manifest.get("project"), dict) else {}
    team = manifest.get("team") if isinstance(manifest.get("team"), dict) else {}
    ws = manifest.get("workspace") if isinstance(manifest.get("workspace"), dict) else {}
    tracker = manifest.get("tracker") if isinstance(manifest.get("tracker"), dict) else {}

    proj_name = proj.get("name") or proj.get("id") or "Engineering Project"
    proj_id = proj.get("id") or "project"
    team_name = team.get("name") or "Engineering Team"
    topology = ws.get("topology") or "single-repo"
    tracker_provider = tracker.get("provider") or "markdown"
    ticket_prefix = tracker.get("ticket_prefix") or "PROJ"

    gh_dir = target_dir / ".github"
    gh_dir.mkdir(parents=True, exist_ok=True)

    copilot_md = f"""# GitHub Copilot Workspace Instructions — {proj_name}

> Generated deterministically by `./aigile harness sync copilot` from `aff.yaml` and `AGENTS.md`.
> Canonical contract: see [`AGENTS.md`](../AGENTS.md) at the workspace root.

## Project & Team Context
- **Project:** `{proj_id}` ({proj_name})
- **Team:** {team_name}
- **Workspace Topology:** `{topology}`
- **Issue Tracker:** `{tracker_provider}` (ticket prefix: `{ticket_prefix}-*`)
- **Harness Mode:** `{effective_mode}`

## Global Engineering Guardrails
1. **Canonical Contract:** Always follow `AGENTS.md` for role routing, 8-phase lifecycle execution, and artifact conventions.
2. **Proportional Human Gates (`G1`–`G4`):** Do not advance across gated lifecycle boundaries without verified gate evidence and SHA256 receipts (`./aigile receipt`).
3. **4R Adversarial Review:** Every implementation change requires structured review across **Risk, Requirements, Regression, and Resilience**.
4. **Zero Secrets & Sensitive Data:** Never hardcode credentials, private keys, API tokens, PII, PCI card numbers, or regulated health records. Run `./aigile scan` prior to commits.
5. **Context Continuity:** Never use `git stash` to switch tickets; use isolated worktrees (`./aigile worktree`) and session logs (`./aigile session`).
"""
    (gh_dir / "copilot-instructions.md").write_text(copilot_md, encoding="utf-8")
    print("  [OK] Generated .github/copilot-instructions.md")

    # Profile instructions
    instr_dir = gh_dir / "instructions"
    instr_dir.mkdir(parents=True, exist_ok=True)
    for stale in instr_dir.glob("*.instructions.md"):
        stale.unlink()

    prof_count = 0
    if src_profiles.is_dir():
        for pfile in sorted(src_profiles.glob("*.md")):
            if pfile.name.lower() == "readme.md":
                continue
            slug = pfile.stem
            if enabled_profiles is not None and "all" not in enabled_profiles and "*" not in enabled_profiles:
                if slug not in enabled_profiles:
                    continue
            ptext = pfile.read_text(encoding="utf-8", errors="replace")
            pmeta, fm_raw, pbody = split_frontmatter(ptext)
            apply_to = pmeta.get("applyTo")
            if not apply_to:
                m_apply = re.search(r"^applyTo:\s*(.+)$", fm_raw, re.M)
                apply_to = m_apply.group(1).strip().strip("\"'") if m_apply else infer_apply_to(slug)
            rendered_prof = (
                "---\n"
                f'applyTo: "{apply_to}"\n'
                "---\n\n"
                + pbody.lstrip("\r\n").rstrip()
                + "\n"
            )
            (instr_dir / f"{slug}.instructions.md").write_text(rendered_prof, encoding="utf-8")
            prof_count += 1
    print(f"  [OK] Generated {prof_count} profile instruction file(s) -> .github/instructions/")

    # Custom Copilot agents
    c_agents_dir = gh_dir / "agents"
    c_agents_dir.mkdir(parents=True, exist_ok=True)
    for stale_agent in c_agents_dir.glob("aff-*.agent.md"):
        stale_agent.unlink()

    ag_count = 0
    if src_agents.is_dir():
        for afile in sorted(src_agents.glob("*.md")):
            if afile.name.lower() == "readme.md":
                continue
            atext = afile.read_text(encoding="utf-8", errors="replace")
            ameta, _, abody = split_frontmatter(atext)
            raw_slug = ameta.get("name") or afile.stem
            clean_slug = raw_slug[4:] if raw_slug.startswith("aff-") else raw_slug
            agent_id = f"aff-{clean_slug}"
            desc = ameta.get("description") or f"aigile-forge-framework {clean_slug} specialist agent"
            desc_escaped = desc.replace('"', '\\"')
            rec_tools = parse_recommended_tools(ameta)
            gh_tools_str = json.dumps(build_copilot_tools(rec_tools))
            rendered_agent = (
                "---\n"
                f"name: {agent_id}\n"
                f'description: "{desc_escaped}"\n'
                f"tools: {gh_tools_str}\n"
                "---\n\n"
                + abody.lstrip("\r\n").rstrip()
                + "\n"
            )
            (c_agents_dir / f"{agent_id}.agent.md").write_text(rendered_agent, encoding="utf-8")
            ag_count += 1
    print(f"  [OK] Generated {ag_count} custom Copilot agent(s) -> .github/agents/")

    # Slash prompts
    c_prompts_dir = gh_dir / "prompts"
    c_prompts_dir.mkdir(parents=True, exist_ok=True)
    pr_count = 0
    if src_prompts.is_dir():
        for prfile in sorted(src_prompts.glob("*.prompt.md")):
            shutil.copy2(prfile, c_prompts_dir / prfile.name)
            pr_count += 1
    print(f"  [OK] Synced {pr_count} slash prompt(s) -> .github/prompts/")


def sync_claude_commands() -> int:
    src_prompts = resolve_src("prompts")
    if not src_prompts.is_dir():
        return 0
    c_cmd_dir = target_dir / ".claude" / "commands"
    c_cmd_dir.mkdir(parents=True, exist_ok=True)
    for stale in c_cmd_dir.glob("*.md"):
        stale.unlink()
    count = 0
    for prfile in sorted(src_prompts.glob("*.prompt.md")):
        slug = prfile.name[:-len(".prompt.md")] if prfile.name.endswith(".prompt.md") else prfile.stem
        shutil.copy2(prfile, c_cmd_dir / f"{slug}.md")
        count += 1
    print(f"  [OK] Projected {count} slash command(s) -> .claude/commands/")
    return count


def sync_antigravity_workflows() -> int:
    src_prompts = resolve_src("prompts")
    if not src_prompts.is_dir():
        return 0
    ag_wf_dir = target_dir / ".agents" / "workflows"
    ag_wf_dir.mkdir(parents=True, exist_ok=True)
    for stale in ag_wf_dir.glob("*.md"):
        stale.unlink()
    count = 0
    for prfile in sorted(src_prompts.glob("*.prompt.md")):
        slug = prfile.name[:-len(".prompt.md")] if prfile.name.endswith(".prompt.md") else prfile.stem
        raw_text = prfile.read_text(encoding="utf-8", errors="replace")
        meta, fm, body = split_frontmatter(raw_text)
        rendered = (
            "---\n"
            + fm.strip()
            + "\n---\n\n"
            + f"> [!NOTE]\n> **Deprecated workflow format:** This workflow is migrated to a native skill at `.agents/skills/{slug}/SKILL.md`.\n> Prefer invoking `/{slug}` as a native skill.\n\n"
            + body.lstrip("\r\n").rstrip()
            + "\n"
        )
        (ag_wf_dir / f"{slug}.md").write_text(rendered, encoding="utf-8")
        count += 1
    print(f"  [OK] Projected {count} workflow(s) -> .agents/workflows/ (migrated to .agents/skills/)")
    return count


def sync_opencode_prompts() -> int:
    src_prompts = resolve_src("prompts")
    if not src_prompts.is_dir():
        return 0
    oc_pr_dir = target_dir / ".opencode" / "prompts"
    oc_pr_dir.mkdir(parents=True, exist_ok=True)
    for stale in oc_pr_dir.glob("*.prompt.md"):
        stale.unlink()
    count = 0
    for prfile in sorted(src_prompts.glob("*.prompt.md")):
        shutil.copy2(prfile, oc_pr_dir / prfile.name)
        count += 1
    print(f"  [OK] Synced {count} prompt(s) -> .opencode/prompts/")
    return count


def sync_prompt_skills(skills_rel: str) -> int:
    src_prompts = resolve_src("prompts")
    if not src_prompts.is_dir():
        return 0
    skills_dir = target_dir / skills_rel
    skills_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for prfile in sorted(src_prompts.glob("*.prompt.md")):
        slug = prfile.name[:-len(".prompt.md")] if prfile.name.endswith(".prompt.md") else prfile.stem
        sdir = skills_dir / slug
        sdir.mkdir(parents=True, exist_ok=True)
        text = prfile.read_text(encoding="utf-8", errors="replace")
        meta, _, body = split_frontmatter(text)
        desc = meta.get("description") or f"Slash command {slug}"
        desc_escaped = desc.replace('"', '\\"')
        rendered = (
            "---\n"
            f"name: {slug}\n"
            f'description: "{desc_escaped}"\n'
            "---\n\n"
            + body.lstrip("\r\n").rstrip()
            + "\n"
        )
        (sdir / "SKILL.md").write_text(rendered, encoding="utf-8")
        count += 1
    print(f"  [OK] Projected {count} prompt skill(s) -> {skills_rel}/")
    return count


if action == "print":
    targets = parse_target_harnesses(harness_arg, default_from_manifest=False)
    if len(targets) != 1:
        print("ERROR: 'print' requires a single harness name (claude, opencode, antigravity, codex, copilot).", file=sys.stderr)
        sys.exit(1)
    h = targets[0]
    mcp_servers = load_mcp_fragments() if effective_mode == "mcp" else {}
    if h == "claude":
        payload = {
            "harness": "claude",
            "mode": effective_mode,
            "instructions": "CLAUDE.md -> @AGENTS.md",
            "skills": ".claude/skills",
            "agents": ".claude/agents",
            "commands_dir": ".claude/commands",
            "mcp_file": ".mcp.json" if effective_mode == "mcp" else None,
            "mcp": {"mcpServers": build_stdio_mcp(mcp_servers, "claude", include_type=True)} if effective_mode == "mcp" else None,
        }
    elif h == "opencode":
        payload = {
            "harness": "opencode",
            "mode": effective_mode,
            "instructions": "AGENTS.md",
            "skills": ".agents/skills",
            "agents": ".opencode/agents",
            "prompts_dir": ".opencode/prompts",
            "opencode_json": {
                "$schema": "https://opencode.ai/config.json",
                "mcp": build_opencode_mcp(mcp_servers) if effective_mode == "mcp" else {},
            },
        }
    elif h == "antigravity":
        payload = {
            "harness": "antigravity",
            "mode": effective_mode,
            "instructions": "AGENTS.md",
            "rules_dir": ".agents/rules",
            "skills": ".agents/skills",
            "agents": ".agents/agents",
            "workflows_dir": ".agents/workflows",
            "mcp_file": ".agents/mcp_config.json" if effective_mode == "mcp" else None,
            "mcp": {"mcpServers": build_stdio_mcp(mcp_servers, "antigravity", include_type=False)} if effective_mode == "mcp" else None,
        }
    elif h == "codex":
        payload = {
            "harness": "codex",
            "mode": effective_mode,
            "instructions": "AGENTS.md",
            "skills": ".agents/skills",
            "agents": ".agents/agents",
        }
    else:
        payload = {
            "harness": "copilot",
            "mode": effective_mode,
            "instructions": ".github/copilot-instructions.md",
            "profile_instructions_dir": ".github/instructions",
            "agents_dir": ".github/agents",
            "prompts_dir": ".github/prompts",
            "skills_dir": ".github/skills",
            "enabled_profiles": enabled_profiles if enabled_profiles is not None else "all",
        }
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    sys.exit(0)

if action == "sync_files":
    targets = parse_target_harnesses(harness_arg, default_from_manifest=False)
    mcp_servers = load_mcp_fragments() if effective_mode == "mcp" else {}

    src_agents_md = resolve_src("AGENTS.md")
    if src_agents_md.exists() and not (target_dir / "AGENTS.md").exists():
        shutil.copy2(src_agents_md, target_dir / "AGENTS.md")
        print("  [OK] Copied canonical AGENTS.md into target workspace")

    if "claude" in targets:
        claude_md_content = f"""@AGENTS.md

## Claude Code Integration

This entry point imports the canonical [`AGENTS.md`](AGENTS.md) contract shared across all aigile-forge-framework harnesses.

- **Mode:** `{effective_mode}`
- **Skills:** `.claude/skills/`
- **Role Agents:** `.claude/agents/`
- **Commands:** `.claude/commands/`
- **Regenerate:** `./aigile harness sync claude`
"""
        (target_dir / "CLAUDE.md").write_text(claude_md_content, encoding="utf-8")
        print("  [OK] Generated CLAUDE.md (referencing AGENTS.md)")
        sync_claude_agents()
        sync_claude_commands()

        mcp_json_path = target_dir / ".mcp.json"
        if effective_mode == "mcp":
            mcp_payload = {"mcpServers": build_stdio_mcp(mcp_servers, "claude", include_type=True)}
            mcp_json_path.write_text(json.dumps(mcp_payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            print("  [OK] Generated .mcp.json (mcp mode)")
        else:
            if mcp_json_path.exists():
                mcp_json_path.unlink()
                print("  [OK] Removed .mcp.json (zero-mcp mode)")
            else:
                print("  [OK] Skipped .mcp.json (zero-mcp mode)")

    if any(h in targets for h in ("antigravity", "codex")):
        sync_antigravity_agents()

    if "opencode" in targets:
        sync_opencode_agents()
        sync_opencode_prompts()
        opencode_payload = {
            "$schema": "https://opencode.ai/config.json",
            "mcp": build_opencode_mcp(mcp_servers) if effective_mode == "mcp" else {},
        }
        (target_dir / "opencode.json").write_text(
            json.dumps(opencode_payload, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"  [OK] Generated opencode.json (mode: {effective_mode})")

    if "antigravity" in targets:
        sync_antigravity_rules()
        sync_antigravity_workflows()
        ag_mcp_path = target_dir / ".agents" / "mcp_config.json"
        ag_mcp_path.parent.mkdir(parents=True, exist_ok=True)
        if effective_mode == "mcp":
            ag_payload = {"mcpServers": build_stdio_mcp(mcp_servers, "antigravity", include_type=False)}
            ag_mcp_path.write_text(json.dumps(ag_payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            print("  [OK] Generated .agents/mcp_config.json (mcp mode)")
        else:
            if ag_mcp_path.exists():
                ag_mcp_path.unlink()
                print("  [OK] Removed .agents/mcp_config.json (zero-mcp mode)")
            else:
                print("  [OK] Skipped .agents/mcp_config.json (zero-mcp mode)")

    if "copilot" in targets:
        sync_copilot()

    sys.exit(0)

if action == "sync_prompt_skills":
    targets = parse_target_harnesses(harness_arg, default_from_manifest=False)
    if any(h in targets for h in ("antigravity", "opencode", "codex")):
        sync_prompt_skills(".agents/skills")
    sys.exit(0)

if action == "check":
    errors: list[str] = []
    warnings: list[str] = []

    required_paths = [
        ("AGENTS.md", False),
        ("aff.yaml", False),
        ("agents", True),
        ("skills", True),
        ("profiles", True),
        ("prompts", True),
        ("mcp", True),
    ]
    for rel, is_dir in required_paths:
        p = target_dir / rel
        if not p.exists():
            errors.append(f"Missing canonical {'directory' if is_dir else 'file'}: {rel}")
        elif is_dir and not p.is_dir():
            errors.append(f"Expected directory but found file: {rel}")
        elif not is_dir and not p.is_file():
            errors.append(f"Expected file but found directory: {rel}")

    skills_root = target_dir / "skills"
    skill_dirs = sorted(d for d in skills_root.iterdir() if d.is_dir()) if skills_root.is_dir() else []
    if skills_root.is_dir() and not skill_dirs:
        errors.append("skills/ contains no skill subdirectories")

    slug_re = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    for sdir in skill_dirs:
        sfile = sdir / "SKILL.md"
        if not sfile.exists():
            errors.append(f"skills/{sdir.name}: missing SKILL.md")
            continue
        smeta, fm_raw, _ = split_frontmatter(sfile.read_text(encoding="utf-8", errors="replace"))
        if not fm_raw:
            errors.append(f"skills/{sdir.name}/SKILL.md: missing YAML frontmatter")
            continue
        sname = smeta.get("name", "")
        sdesc = smeta.get("description", "")
        if sname != sdir.name:
            errors.append(f"skills/{sdir.name}/SKILL.md: frontmatter name '{sname}' != directory '{sdir.name}'")
        if sname and not slug_re.match(sname):
            errors.append(f"skills/{sdir.name}/SKILL.md: invalid skill slug '{sname}'")
        if not sdesc:
            errors.append(f"skills/{sdir.name}/SKILL.md: missing description in frontmatter")

    for subdir, pattern, label in [
        ("agents", "*.md", "agent"),
        ("profiles", "*.md", "profile"),
        ("prompts", "*.prompt.md", "prompt"),
        ("mcp", "*.json", "MCP fragment"),
    ]:
        dpath = target_dir / subdir
        if dpath.is_dir():
            items = [x for x in dpath.glob(pattern) if x.name.lower() != "readme.md"]
            if not items:
                errors.append(f"{subdir}/ contains no {label} files matching {pattern}")

    json_candidates: list[Path] = []
    for folder in ("mcp", "configs"):
        fpath = target_dir / folder
        if fpath.is_dir():
            json_candidates.extend(sorted(fpath.glob("*.json")))
    for gen_rel in ("opencode.json", ".mcp.json", ".agents/mcp_config.json"):
        gp = target_dir / gen_rel
        if gp.exists():
            json_candidates.append(gp)
    json_candidates.extend(sorted(target_dir.glob("*.code-workspace")))

    for jp in json_candidates:
        try:
            parsed = json.loads(jp.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{jp.relative_to(target_dir)}: invalid JSON ({exc})")
            continue
        if jp.name == "opencode.json" and (not isinstance(parsed, dict) or "mcp" not in parsed):
            errors.append("opencode.json: missing 'mcp' key")
        if jp.name in (".mcp.json", "mcp_config.json") and (not isinstance(parsed, dict) or "mcpServers" not in parsed):
            errors.append(f"{jp.relative_to(target_dir)}: missing 'mcpServers' key")

    if effective_mode == "zero-mcp":
        if (target_dir / ".mcp.json").exists():
            errors.append(".mcp.json must not exist when harnesses.mode is 'zero-mcp'")
        if (target_dir / ".agents" / "mcp_config.json").exists():
            errors.append(".agents/mcp_config.json must not exist when harnesses.mode is 'zero-mcp'")
        oc_file = target_dir / "opencode.json"
        if oc_file.exists():
            try:
                oc_data = json.loads(oc_file.read_text(encoding="utf-8"))
                if isinstance(oc_data, dict) and oc_data.get("mcp"):
                    errors.append("opencode.json 'mcp' block must be empty {} in 'zero-mcp' mode")
            except Exception:
                pass

    # Capability model: canonical tokens + per-harness projection contracts.
    canonical_caps: dict[str, list[str]] = {}
    agents_root = target_dir / "agents"
    if agents_root.is_dir():
        for amd in sorted(agents_root.glob("*.md")):
            if amd.name.lower() == "readme.md":
                continue
            ameta, _, abody = split_frontmatter(amd.read_text(encoding="utf-8", errors="replace"))
            aslug = ameta.get("name") or amd.stem
            bad = unknown_capabilities(ameta)
            if bad:
                errors.append(
                    f"agents/{amd.name}: unknown capability token(s) {bad}; "
                    f"allowed: {list(CAPABILITY_VOCAB)}"
                )
            acaps = parse_recommended_tools(ameta)
            canonical_caps[aslug] = acaps
            if "delegate" in acaps and "## Delegation Fallback" not in abody:
                errors.append(
                    f"agents/{amd.name}: declares 'delegate' but lacks a '## Delegation Fallback' "
                    "section (required for harnesses without subagent support)"
                )

    def _projected_fm(path: Path) -> str:
        _, fm, _ = split_frontmatter(path.read_text(encoding="utf-8", errors="replace"))
        return fm

    for aslug, acaps in canonical_caps.items():
        c_file = target_dir / ".claude" / "agents" / f"{aslug}.md"
        if c_file.is_file():
            fm = _projected_fm(c_file)
            m_tools = re.search(r"^tools:\s*(.+)$", fm, re.M)
            if is_full_writer(acaps) and m_tools:
                errors.append(
                    f".claude/agents/{aslug}.md: full-capability agent must not restrict 'tools' "
                    "(re-run ./aigile harness sync claude)"
                )
            if m_tools and "edit" in acaps and "Write" not in m_tools.group(1):
                errors.append(f".claude/agents/{aslug}.md: 'edit' capability projected without Write tool")
        ag_file = target_dir / ".agents" / "agents" / f"{aslug}.md"
        if ag_file.is_file() and re.search(r"^tools:", _projected_fm(ag_file), re.M):
            errors.append(
                f".agents/agents/{aslug}.md: Antigravity 'tools' allowlist is forbidden "
                "(version-dependent names strip write/delegation tools); re-run ./aigile harness sync antigravity"
            )
        oc_file_agent = target_dir / ".opencode" / "agents" / f"{aslug}.md"
        if oc_file_agent.is_file():
            fm = _projected_fm(oc_file_agent)
            if re.search(r"^tools:\s*\r?\n\s+-\s", fm, re.M):
                errors.append(
                    f".opencode/agents/{aslug}.md: 'tools' must be a boolean map, not a list "
                    "(re-run ./aigile harness sync opencode)"
                )

    for w in warnings:
        print(f"  [WARN] {w}")
    for e in errors:
        print(f"  [ERROR] {e}", file=sys.stderr)

    if errors:
        print(f"==> [aigile-forge-framework:harness] Validation FAILED ({len(errors)} error(s)).", file=sys.stderr)
        sys.exit(1)

    print(
        f"==> [aigile-forge-framework:harness] Validation OK (mode={effective_mode}, "
        f"skills={len(skill_dirs)}, json_checked={len(json_candidates)})"
    )
    sys.exit(0)
PY
}

case "$SUBCOMMAND" in
    sync)
        HARNESS_LIST="${HARNESS_ARG:-all}"
        echo "==> [aigile-forge-framework:harness] Synchronizing harnesses (target_dir=$TARGET_DIR, link=$LINK_MODE, harnesses=$HARNESS_LIST)"

        # Project generated Markdown/JSON files first
        run_python_projector "sync_files"

        # Sync skill directories according to selected harnesses
        if [ "$HARNESS_LIST" = "all" ] || [[ ",$HARNESS_LIST," == *",claude,"* ]] || [[ ",$HARNESS_LIST," == *",claude-code,"* ]]; then
            sync_skills_dir ".claude/skills"
        fi
        if [ "$HARNESS_LIST" = "all" ] \
            || [[ ",$HARNESS_LIST," == *",opencode,"* ]] \
            || [[ ",$HARNESS_LIST," == *",antigravity,"* ]] \
            || [[ ",$HARNESS_LIST," == *",codex,"* ]]; then
            sync_skills_dir ".agents/skills"
            run_python_projector "sync_prompt_skills"
        fi
        if [ "$HARNESS_LIST" = "all" ] || [[ ",$HARNESS_LIST," == *",copilot,"* ]]; then
            sync_skills_dir ".github/skills"
        fi

        echo "==> [aigile-forge-framework:harness] Synchronization completed."
        ;;

    check)
        run_python_projector "check"
        ;;

    status)
        echo "==> [aigile-forge-framework:harness] Workspace Status ($TARGET_DIR)"
        echo ""
        echo "  Detected Harness CLIs:"
        for cli in claude opencode antigravity codex code; do
            if command -v "$cli" >/dev/null 2>&1; then
                printf "    [OK] %-14s %s\n" "$cli" "$(command -v "$cli")"
            else
                printf "    [--] %-14s not installed in PATH\n" "$cli"
            fi
        done

        echo ""
        echo "  Projected Targets:"
        for rel in \
            "CLAUDE.md" \
            ".claude/skills" \
            ".claude/agents" \
            ".claude/commands" \
            ".mcp.json" \
            "opencode.json" \
            ".opencode/agents" \
            ".opencode/prompts" \
            ".agents/skills" \
            ".agents/rules" \
            ".agents/agents" \
            ".agents/workflows" \
            ".agents/mcp_config.json" \
            ".github/copilot-instructions.md" \
            ".github/instructions" \
            ".github/agents" \
            ".github/prompts" \
            ".github/skills"; do
            full="$TARGET_DIR/$rel"
            if [ -L "$full" ]; then
                printf "    [LINK] %-34s -> %s\n" "$rel" "$(readlink "$full")"
            elif [ -d "$full" ]; then
                cnt="$(find "$full" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
                printf "    [DIR]  %-34s (%s item(s))\n" "$rel" "$cnt"
            elif [ -f "$full" ]; then
                printf "    [FILE] %-34s present\n" "$rel"
            else
                printf "    [----] %-34s absent\n" "$rel"
            fi
        done
        ;;

    print)
        if [ -z "$HARNESS_ARG" ]; then
            echo "ERROR: 'print' requires a harness name (claude, opencode, antigravity, codex, copilot)." >&2
            exit 1
        fi
        run_python_projector "print"
        ;;

    clean)
        echo "==> [aigile-forge-framework:harness] Cleaning generated harness projections in $TARGET_DIR..."
        rm -f "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/.mcp.json" "$TARGET_DIR/opencode.json"
        rm -rf "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.claude/agents" "$TARGET_DIR/.claude/commands"
        rm -rf "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.agents/rules" "$TARGET_DIR/.agents/agents" "$TARGET_DIR/.agents/workflows" "$TARGET_DIR/.agents/mcp_config.json"
        rm -rf "$TARGET_DIR/.opencode/agents" "$TARGET_DIR/.opencode/prompts"
        rm -f "$TARGET_DIR/.github/copilot-instructions.md"
        rm -rf "$TARGET_DIR/.github/instructions" "$TARGET_DIR/.github/agents" "$TARGET_DIR/.github/prompts" "$TARGET_DIR/.github/skills"
        rmdir "$TARGET_DIR/.claude" "$TARGET_DIR/.agents" "$TARGET_DIR/.opencode" "$TARGET_DIR/.github" 2>/dev/null || true
        echo "==> [aigile-forge-framework:harness] Clean completed."
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2
        usage >&2
        exit 1
        ;;
esac
