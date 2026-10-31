#!/usr/bin/env bash
# ==============================================================================
# Script: aff-doctor.sh
# Purpose: Read-only environment and workspace health diagnostic tool for
#          AIgile Forge Framework. Verifies OS, bash, git, python3/jq, aff.yaml,
#          active harness mode (zero-mcp vs mcp), and git pre-commit hook state.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${AFF_WORKSPACE_DIR:-}" ]; then
    TARGET_DIR="$AFF_WORKSPACE_DIR"
elif [ -f "$PWD/aff.yaml" ]; then
    TARGET_DIR="$PWD"
else
    TARGET_DIR="$BASE_DIR"
fi

usage() {
    cat <<'EOF'
Usage: aff-doctor.sh [options]

Options:
  --target-dir <dir>   Workspace directory to inspect (defaults to active workspace)
  -h, --help           Show this help message

Exit codes:
  0  Healthy baseline
  1  Missing critical prerequisite (bash, git, python3/jq, or aff.yaml)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-dir)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --target-dir requires a directory path." >&2
                exit 1
            fi
            TARGET_DIR="$2"
            shift 2
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

detect_os() {
    local uname_s
    uname_s="$(uname -s 2>/dev/null || echo 'Unknown')"
    case "$uname_s" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "Linux (WSL)"
            else
                echo "Linux"
            fi
            ;;
        Darwin*)
            echo "macOS (Darwin)"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows (Git-Bash / MSYS)"
            ;;
        *)
            echo "Unknown ($uname_s)"
            ;;
    esac
}

ERRORS=0
WARNINGS=0

OS_LABEL="$(detect_os)"

echo "======================================================================"
echo "  AIgile Forge Framework — Environment & Workspace Doctor"
echo "======================================================================"
echo "  Target Workspace: $TARGET_DIR"
echo "  Operating System: $OS_LABEL"
echo ""

echo "==> [1/4] Core Runtime Prerequisites"
if [ -n "${BASH_VERSION:-}" ]; then
    echo "  [OK] bash ($BASH_VERSION)"
else
    echo "  [FAIL] bash runtime not detected" >&2
    ERRORS=$((ERRORS + 1))
fi

if command -v git >/dev/null 2>&1; then
    echo "  [OK] git ($(git --version))"
else
    echo "  [FAIL] git is not installed in PATH" >&2
    ERRORS=$((ERRORS + 1))
fi

HAS_JSON_PARSER=false
if command -v python3 >/dev/null 2>&1; then
    echo "  [OK] python3 ($(python3 --version 2>&1))"
    HAS_JSON_PARSER=true
else
    echo "  [WARN] python3 not found in PATH"
    WARNINGS=$((WARNINGS + 1))
fi

if command -v jq >/dev/null 2>&1; then
    echo "  [OK] jq ($(jq --version 2>&1))"
    HAS_JSON_PARSER=true
else
    echo "  [INFO] jq not found (optional when python3 is installed)"
fi

if [ "$HAS_JSON_PARSER" = false ]; then
    echo "  [FAIL] Neither python3 nor jq is available for JSON/manifest processing" >&2
    ERRORS=$((ERRORS + 1))
fi

if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    echo "  [OK] SHA256 digest utility available"
else
    echo "  [WARN] sha256sum/shasum not found; python3 hashlib will be used"
fi

echo ""
echo "==> [2/4] Workspace Manifest & Harness Mode"
MANIFEST_PATH="$TARGET_DIR/aff.yaml"
ACTIVE_MODE="unknown"
TOPOLOGY="unknown"
PROJECT_ID="unknown"

if [ -f "$MANIFEST_PATH" ]; then
    echo "  [OK] aff.yaml found ($MANIFEST_PATH)"
    if command -v python3 >/dev/null 2>&1; then
        PARSED_META="$(AFF_M="$MANIFEST_PATH" python3 - <<'PY'
import os, re
from pathlib import Path
text = Path(os.environ["AFF_M"]).read_text(encoding="utf-8", errors="replace")
proj, topo, mode = "unknown", "single-repo", "zero-mcp"
try:
    import yaml  # type: ignore
    d = yaml.safe_load(text) or {}
    proj = str((d.get("project") or {}).get("id") or "unknown")
    topo = str((d.get("workspace") or {}).get("topology") or "single-repo")
    mode = str((d.get("harnesses") or {}).get("mode") or "zero-mcp")
except Exception:
    m1 = re.search(r"^\s+id:\s*[\"']?([^\"'#\s]+)", text, re.M)
    m2 = re.search(r"^\s+topology:\s*[\"']?([^\"'#\s]+)", text, re.M)
    m3 = re.search(r"^\s+mode:\s*[\"']?([^\"'#\s]+)", text, re.M)
    if m1: proj = m1.group(1)
    if m2: topo = m2.group(1)
    if m3: mode = m3.group(1)
print(f"{proj}|{topo}|{mode}")
PY
)"
        PROJECT_ID="${PARSED_META%%|*}"
        REST="${PARSED_META#*|}"
        TOPOLOGY="${REST%%|*}"
        ACTIVE_MODE="${REST#*|}"
    fi
    echo "  [OK] Project ID:          $PROJECT_ID"
    echo "  [OK] Workspace Topology:  $TOPOLOGY"
    echo "  [OK] Active Harness Mode: $ACTIVE_MODE"
else
    echo "  [FAIL] aff.yaml missing at $MANIFEST_PATH (run './aigile init' to initialize)" >&2
    ERRORS=$((ERRORS + 1))
fi

if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    echo "  [OK] Canonical AGENTS.md present"
else
    echo "  [WARN] AGENTS.md not found in $TARGET_DIR"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "==> [3/4] Git Repository & Pre-Commit Security Hook"
if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    HOOKS_DIR="$(git -C "$TARGET_DIR" rev-parse --git-path hooks)"
    if [[ "$HOOKS_DIR" != /* ]]; then
        HOOKS_DIR="$TARGET_DIR/$HOOKS_DIR"
    fi
    if [ -x "$HOOKS_DIR/pre-commit" ]; then
        echo "  [OK] Git pre-commit hook installed and executable ($HOOKS_DIR/pre-commit)"
    else
        echo "  [INFO] Git pre-commit hook not installed (optional: './aigile scan --install-hook')"
    fi
else
    echo "  [INFO] $TARGET_DIR is not a git repository (multi-root hub or uninitialized git)"
fi

echo ""
echo "==> [4/4] Canonical Directory Baseline"
for cdir in agents skills profiles prompts mcp; do
    if [ -d "$TARGET_DIR/$cdir" ]; then
        echo "  [OK] $cdir/ present"
    else
        echo "  [WARN] $cdir/ not present yet in $TARGET_DIR"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo ""
echo "======================================================================"
if [ "$ERRORS" -gt 0 ]; then
    echo "  [AFF Doctor] UNHEALTHY: $ERRORS critical issue(s), $WARNINGS warning(s)." >&2
    echo "  Action: Install missing prerequisites or run './aigile init'." >&2
    echo "======================================================================"
    exit 1
fi

echo "  [AFF Doctor] HEALTHY BASELINE ($WARNINGS advisory warning(s), mode=$ACTIVE_MODE)."
echo "  Next actions:"
echo "    - Project harnesses: ./aigile harness sync all"
echo "    - Validate schemas:  ./aigile harness check"
echo "    - Install hook:      ./aigile scan --install-hook"
echo "======================================================================"
exit 0
