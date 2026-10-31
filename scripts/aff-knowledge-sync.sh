#!/usr/bin/env bash
# ==============================================================================
# Script: aff-knowledge-sync.sh
# Purpose: Pluggable knowledge base synchronization for AIgile Forge Framework.
#          Supports 'local' (workspace-only), 'folder-sync' (shared/cloud-mounted
#          directory copy via rsync or cp), and 'cortex-ai' (MCP-backed guidance).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="${AFF_WORKSPACE_DIR:-$BASE_DIR}"

ACTION="status"
CLI_DEST=""
CLI_MODE=""
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: aff-knowledge-sync.sh [options]

Actions & Options:
  --status                 Display knowledge sync configuration and health (default)
  --sync                   Synchronize knowledge/ using the active sync mode
  --dest <dir>             Destination directory for folder-sync mode
  --mode <mode>            Override mode: local | folder-sync | cortex-ai
  --workspace-dir <dir>    Target workspace root (defaults to framework root)
  --dry-run                Preview synchronization actions without writing files
  -h, --help               Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status|status)
            ACTION="status"
            shift
            ;;
        --sync|sync)
            ACTION="sync"
            shift
            ;;
        --dest)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --dest requires a target directory path." >&2
                exit 1
            fi
            CLI_DEST="$2"
            shift 2
            ;;
        --mode)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --mode requires local, folder-sync, or cortex-ai." >&2
                exit 1
            fi
            CLI_MODE="$2"
            shift 2
            ;;
        --workspace-dir)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

MANIFEST_FILE="$WORKSPACE_DIR/aff.yaml"
KNOWLEDGE_DIR="$WORKSPACE_DIR/knowledge"

read_knowledge_config() {
    AFF_MANIFEST="$MANIFEST_FILE" python3 - <<'PY'
import os
import re
from pathlib import Path

manifest = Path(os.environ["AFF_MANIFEST"])
mode = "local"
sync_path = ""

if manifest.exists():
    text = manifest.read_text(encoding="utf-8", errors="replace")
    try:
        import yaml  # type: ignore
        data = yaml.safe_load(text) or {}
        k = data.get("knowledge") or {}
        if isinstance(k, dict):
            mode = str(k.get("mode") or "local").strip()
            sync_path = str(k.get("sync_path") or "").strip()
    except Exception:
        in_knowledge = False
        for line in text.splitlines():
            if re.match(r"^knowledge:\s*$", line):
                in_knowledge = True
                continue
            if in_knowledge and re.match(r"^[A-Za-z0-9_-]+:", line):
                in_knowledge = False
            if in_knowledge:
                m_mode = re.match(r"^\s+mode:\s*[\"']?([^\"'#\s]+)", line)
                if m_mode:
                    mode = m_mode.group(1)
                m_path = re.match(r"^\s+sync_path:\s*[\"']?([^\"'#\n]*?)[\"']?\s*$", line)
                if m_path:
                    sync_path = m_path.group(1).strip()

print(f"{mode}|{sync_path}")
PY
}

CFG_RAW="$(read_knowledge_config)"
CFG_MODE="${CFG_RAW%%|*}"
CFG_DEST="${CFG_RAW#*|}"

EFFECTIVE_MODE="${CLI_MODE:-$CFG_MODE}"
EFFECTIVE_DEST="${CLI_DEST:-${AFF_KNOWLEDGE_SYNC_DEST:-$CFG_DEST}}"

if [ -n "$CLI_DEST" ] && [ -z "$CLI_MODE" ] && [ "$EFFECTIVE_MODE" = "local" ]; then
    EFFECTIVE_MODE="folder-sync"
fi

case "$EFFECTIVE_MODE" in
    local|git)
        NORMALIZED_MODE="local"
        ;;
    folder-sync|cloud-folder)
        NORMALIZED_MODE="folder-sync"
        ;;
    cortex-ai)
        NORMALIZED_MODE="cortex-ai"
        ;;
    *)
        echo "ERROR: unsupported knowledge sync mode '$EFFECTIVE_MODE' (expected local, folder-sync, or cortex-ai)." >&2
        exit 1
        ;;
esac

if [ "$ACTION" = "status" ]; then
    DOC_COUNT=0
    if [ -d "$KNOWLEDGE_DIR" ]; then
        DOC_COUNT="$(find "$KNOWLEDGE_DIR" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
    fi
    echo "==> [AFF Knowledge Sync] Status"
    echo "    Workspace:      $WORKSPACE_DIR"
    echo "    Knowledge Dir:  $KNOWLEDGE_DIR ($DOC_COUNT markdown document(s))"
    echo "    Active Mode:    $NORMALIZED_MODE"
    if [ "$NORMALIZED_MODE" = "folder-sync" ]; then
        echo "    Destination:    ${EFFECTIVE_DEST:-<not configured>}"
    elif [ "$NORMALIZED_MODE" = "cortex-ai" ]; then
        echo "    Subsystem:      Cortex-AI MCP integration (Engram + Google Drive + NotebookLM)"
    fi
    exit 0
fi

# Security guardrail: scan knowledge/ before any synchronization operation
if [ -d "$KNOWLEDGE_DIR" ] && [ -x "$SCRIPT_DIR/aff-secret-scan.sh" ]; then
    "$SCRIPT_DIR/aff-secret-scan.sh" --path "$KNOWLEDGE_DIR"
fi

case "$NORMALIZED_MODE" in
    local)
        mkdir -p "$KNOWLEDGE_DIR"
        DOC_COUNT="$(find "$KNOWLEDGE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
        echo "==> [AFF Knowledge Sync] Local mode active ($DOC_COUNT file(s) in $KNOWLEDGE_DIR)."
        echo "    No external folder destination required. Knowledge stays local to workspace."
        ;;

    folder-sync)
        if [ -z "$EFFECTIVE_DEST" ]; then
            echo "ERROR: folder-sync mode requires --dest <dir> or knowledge.sync_path in aff.yaml." >&2
            exit 1
        fi
        EFFECTIVE_DEST="${EFFECTIVE_DEST/#\~/$HOME}"
        mkdir -p "$KNOWLEDGE_DIR"

        echo "==> [AFF Knowledge Sync] Synchronizing $KNOWLEDGE_DIR -> $EFFECTIVE_DEST/knowledge"
        if [ "$DRY_RUN" = true ]; then
            echo "    [DRY-RUN] Would synchronize knowledge/ to $EFFECTIVE_DEST/knowledge"
            exit 0
        fi

        mkdir -p "$EFFECTIVE_DEST/knowledge"
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --delete "$KNOWLEDGE_DIR/" "$EFFECTIVE_DEST/knowledge/"
        else
            rm -rf "$EFFECTIVE_DEST/knowledge"
            mkdir -p "$EFFECTIVE_DEST/knowledge"
            cp -R "$KNOWLEDGE_DIR"/. "$EFFECTIVE_DEST/knowledge"/
        fi

        date -u '+%Y-%m-%dT%H:%M:%SZ' > "$EFFECTIVE_DEST/.last-sync-timestamp"
        echo "  [OK] Synchronized knowledge directory to $EFFECTIVE_DEST/knowledge"
        ;;

    cortex-ai)
        echo "==> [AFF Knowledge Sync] Cortex-AI MCP Knowledge Guidance"
        echo "    1. Ensure harnesses.mode is set to 'mcp' in aff.yaml and run:"
        echo "       ./aigile harness sync all"
        echo "    2. Verify environment variables DRIVE_ROOT_FOLDER_ID and NOTEBOOKLM_NOTEBOOK_ID."
        echo "    3. Invoke procedural skills from your AI harness:"
        echo "       - skills/cortex-ai-pull/SKILL.md   (hydrate local knowledge/ cache)"
        echo "       - skills/cortex-ai-push/SKILL.md   (publish sanitized artifacts)"
        echo "       - skills/cortex-ai-sync/SKILL.md   (reconcile index & memory pointers)"
        ;;
esac
