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


def sync_standard_agents(dest_rel: str) -> int:
    src_agents = resolve_src("agents")
    if not src_agents.is_dir():
        print(f"ERROR: canonical agents directory not found: {src_agents}", file=sys.stderr)
        sys.exit(1)
    dest = target_dir / dest_rel
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
        rendered = (
            "---\n"
            f"name: {slug}\n"
            f'description: "{desc_escaped}"\n'
            "mode: all\n"
            "---\n\n"
            + body.lstrip("\r\n").rstrip()
            + "\n"
        )
        (dest / f"{slug}.md").write_text(rendered, encoding="utf-8")
        count += 1
    print(f"  [OK] Projected {count} agent(s) -> {dest_rel}")
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
            rendered_agent = (
                "---\n"
                f"name: {agent_id}\n"
                f'description: "{desc_escaped}"\n'
                "tools: ['read', 'search', 'edit', 'execute']\n"
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
        shutil.copy2(prfile, ag_wf_dir / f"{slug}.md")
        count += 1
    print(f"  [OK] Projected {count} workflow(s) -> .agents/workflows/")
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
            "agents": ".agents/agents",
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
        sync_standard_agents(".claude/agents")
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

    if any(h in targets for h in ("opencode", "antigravity", "codex")):
        sync_standard_agents(".agents/agents")

    if "opencode" in targets:
        sync_standard_agents(".opencode/agents")
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
        rm -rf "$TARGET_DIR/.agents/skills" "$TARGET_DIR/.agents/agents" "$TARGET_DIR/.agents/workflows" "$TARGET_DIR/.agents/mcp_config.json"
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
