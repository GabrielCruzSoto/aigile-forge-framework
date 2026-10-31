#!/usr/bin/env bash
# ==============================================================================
# Script: aff-secret-scan.sh
# Purpose: Security guardrail scanner for aigile-forge-framework workspaces.
#          Scans staged git changes (default) or an explicit --path target for
#          private keys, cloud/API tokens, hardcoded secrets, and raw 16-digit
#          payment card numbers. Supports --install-hook for .git/hooks/pre-commit.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SCAN_MODE="staged"
SCAN_PATH=""
TARGET_DIR="$PWD"
INSTALL_HOOK=false

usage() {
    cat <<'EOF'
Usage: aff-secret-scan.sh [options]

Options:
  --path <dir|file>      Scan a specific file or directory instead of staged git changes
  --staged               Scan staged git changes in the current repository (default)
  --target-dir <dir>     Git repository directory for --staged or --install-hook
  --install-hook         Install pre-commit hook into .git/hooks/pre-commit
  -h, --help             Show this help message

Exit codes:
  0  Clean (no secret or sensitive pattern detected)
  1  Security findings detected or invalid invocation
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --path requires a file or directory argument." >&2
                exit 1
            fi
            SCAN_MODE="path"
            SCAN_PATH="$2"
            shift 2
            ;;
        --staged)
            SCAN_MODE="staged"
            shift
            ;;
        --target-dir)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --target-dir requires a directory argument." >&2
                exit 1
            fi
            TARGET_DIR="$2"
            shift 2
            ;;
        --install-hook)
            INSTALL_HOOK=true
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

install_pre_commit_hook() {
    local repo_dir="$1"
    if ! git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1; then
        echo "ERROR: $repo_dir is not a git repository; cannot install pre-commit hook." >&2
        exit 1
    fi

    local hooks_dir
    hooks_dir="$(git -C "$repo_dir" rev-parse --git-path hooks)"
    if [[ "$hooks_dir" != /* ]]; then
        hooks_dir="$repo_dir/$hooks_dir"
    fi

    mkdir -p "$hooks_dir"
    local hook_file="$hooks_dir/pre-commit"

    cat > "$hook_file" <<'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -x "$REPO_ROOT/scripts/aff-secret-scan.sh" ]; then
    exec "$REPO_ROOT/scripts/aff-secret-scan.sh" --staged --target-dir "$REPO_ROOT"
elif command -v aigile >/dev/null 2>&1; then
    exec aigile scan --staged --target-dir "$REPO_ROOT"
else
    echo "[aigile-forge-framework:scanner] WARN: scripts/aff-secret-scan.sh not found; skipping scan." >&2
    exit 0
fi
HOOK_EOF

    chmod +x "$hook_file"
    echo "==> [aigile-forge-framework:scanner] Installed pre-commit security hook at: $hook_file"
}

if [ "$INSTALL_HOOK" = true ]; then
    install_pre_commit_hook "$TARGET_DIR"
    exit 0
fi

# Delegate pattern matching to Python 3 when available for deterministic, cross-platform
# regex accuracy without self-matching or binary noise; fallback to POSIX grep/awk.
run_python_scan() {
    AFF_SCAN_MODE="$SCAN_MODE" \
    AFF_SCAN_PATH="$SCAN_PATH" \
    AFF_TARGET_DIR="$TARGET_DIR" \
    AFF_SELF_PATH="$SCRIPT_DIR/aff-secret-scan.sh" \
    python3 - <<'PY'
import os
import re
import subprocess
import sys
from pathlib import Path

mode = os.environ["AFF_SCAN_MODE"]
scan_path_raw = os.environ["AFF_SCAN_PATH"]
target_dir = Path(os.environ["AFF_TARGET_DIR"]).resolve()
self_path = Path(os.environ["AFF_SELF_PATH"]).resolve()

EXCLUDED_DIRS = {
    ".git",
    "node_modules",
    "target",
    "build",
    "dist",
    ".venv",
    "venv",
    "__pycache__",
    ".gradle",
    ".idea",
}

RULES = [
    (
        "PRIVATE_KEY",
        "Private key block detected",
        re.compile(r"BEGIN (?:[A-Z0-9]+ )?PRIVATE KEY"),
    ),
    (
        "AWS_ACCESS_KEY",
        "AWS access key ID detected",
        re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    ),
    (
        "GITHUB_TOKEN",
        "GitHub personal/app token detected",
        re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{12,}\b"),
    ),
    (
        "GOOGLE_API_KEY",
        "Google API key detected",
        re.compile(r"\bAIza[0-9A-Za-z_-]{16,}\b"),
    ),
    (
        "SLACK_TOKEN",
        "Slack API token detected",
        re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{10,}\b"),
    ),
    (
        "HARDCODED_SECRET",
        "Hardcoded secret/password assignment detected",
        re.compile(
            r"(?i)\b(?:password|passwd|pwd|secret|api_key|apikey|access_token|auth_token|private_key|client_secret)"
            r"\s*[:=]\s*[\"']([^\"'\s$<{]{8,})[\"']"
        ),
    ),
    (
        "RAW_CARD_PAN",
        "Unmasked 16-digit payment card number detected",
        re.compile(r"(?<![0-9A-Za-z_-])(?:[3-6][0-9]{15}|[0-9]{16})(?![0-9A-Za-z_-])"),
    ),
]

PLACEHOLDER_VALUES = {
    "changeme",
    "change_me",
    "change-me",
    "placeholder",
    "your-secret-here",
    "your_secret_here",
    "your-api-key",
    "your_api_key",
    "example-secret",
    "redacted",
    "********",
    "xxxxxxxx",
}


def inspect_line(source_label: str, line_no: int, text: str, findings: list) -> None:
    if "aff-secret-scan:ignore" in text:
        return
    for code, message, pattern in RULES:
        match = pattern.search(text)
        if not match:
            continue
        if code == "HARDCODED_SECRET":
            val = match.group(1).strip().lower()
            if val in PLACEHOLDER_VALUES or val.startswith(("example", "dummy", "sample", "mock_")):
                continue
        findings.append((source_label, line_no, code, message))


def is_binary_bytes(sample: bytes) -> bool:
    return b"\x00" in sample


findings = []

if mode == "path":
    target = Path(scan_path_raw)
    if not target.exists():
        print(f"ERROR: scan path does not exist: {scan_path_raw}", file=sys.stderr)
        sys.exit(1)

    files_to_scan = []
    if target.is_file():
        files_to_scan.append(target)
    else:
        for root, dirs, files in os.walk(target):
            dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]
            root_path = Path(root)
            for fname in sorted(files):
                fpath = root_path / fname
                if fpath.is_symlink():
                    continue
                if fpath.resolve() == self_path:
                    continue
                files_to_scan.append(fpath)

    print(f"==> [aigile-forge-framework:scanner] Scanning path: {target} ({len(files_to_scan)} file(s))")
    for fpath in files_to_scan:
        try:
            raw = fpath.read_bytes()
        except OSError:
            continue
        if is_binary_bytes(raw[:4096]):
            continue
        text = raw.decode("utf-8", errors="replace")
        for idx, line in enumerate(text.splitlines(), start=1):
            inspect_line(str(fpath), idx, line, findings)
else:
    check = subprocess.run(
        ["git", "-C", str(target_dir), "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
    )
    if check.returncode != 0:
        print(f"ERROR: {target_dir} is not inside a git repository. Use --path <dir|file> instead.", file=sys.stderr)
        sys.exit(1)

    diff_proc = subprocess.run(
        ["git", "-C", str(target_dir), "diff", "--cached", "-U0", "--no-color", "--diff-filter=ACMR"],
        capture_output=True,
        text=True,
    )
    if diff_proc.returncode != 0:
        print("ERROR: failed to read staged git diff.", file=sys.stderr)
        sys.exit(1)

    diff_text = diff_proc.stdout
    if not diff_text.strip():
        print("==> [aigile-forge-framework:scanner] No staged git changes found. Clean.")
        sys.exit(0)

    print("==> [aigile-forge-framework:scanner] Scanning staged git changes...")
    current_file = "<staged>"
    current_line = 0
    for raw_line in diff_text.splitlines():
        if raw_line.startswith("+++ b/"):
            current_file = raw_line[6:]
            continue
        if raw_line.startswith("@@ "):
            hunk = re.search(r"\+(\d+)", raw_line)
            current_line = int(hunk.group(1)) if hunk else 1
            continue
        if raw_line.startswith("+") and not raw_line.startswith("+++"):
            added_text = raw_line[1:]
            if (target_dir / current_file).resolve() != self_path:
                inspect_line(current_file, current_line, added_text, findings)
            current_line += 1

if findings:
    for src, line_no, code, msg in findings:
        print(f"  [FAIL] {src}:{line_no} [{code}] {msg}", file=sys.stderr)
    print(f"==> [aigile-forge-framework:scanner] Scan FAILED with {len(findings)} finding(s).", file=sys.stderr)
    sys.exit(1)

print("==> [aigile-forge-framework:scanner] All security checks passed (0 findings).")
sys.exit(0)
PY
}

if command -v python3 >/dev/null 2>&1; then
    run_python_scan
    exit $?
fi

# Fallback shell scanner if python3 is unavailable
COMBINED_REGEX='BEGIN ([A-Z0-9]+ )?PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{12,}|AIza[0-9A-Za-z_-]{16,}|xox[baprs]-[0-9A-Za-z-]{10,}|(password|secret|api_key|access_token)[[:space:]]*[:=][[:space:]]*["'\''][^"'\''[:space:]]{8,}["'\'']|(^|[^0-9A-Za-z_-])[0-9]{16}([^0-9A-Za-z_-]|$)'

if [ "$SCAN_MODE" = "path" ]; then
    if [ ! -e "$SCAN_PATH" ]; then
        echo "ERROR: scan path does not exist: $SCAN_PATH" >&2
        exit 1
    fi
    echo "==> [aigile-forge-framework:scanner] Scanning path (shell fallback): $SCAN_PATH"
    if grep -r -I -E -n \
        --exclude="aff-secret-scan.sh" \
        --exclude-dir={.git,node_modules,target,build,dist,.venv} \
        "$COMBINED_REGEX" "$SCAN_PATH" >&2; then
        echo "==> [aigile-forge-framework:scanner] Scan FAILED." >&2
        exit 1
    fi
else
    echo "==> [aigile-forge-framework:scanner] Scanning staged git changes (shell fallback)..."
    DIFF_ADDED="$(git -C "$TARGET_DIR" diff --cached -U0 --no-color --diff-filter=ACMR | grep -E '^\+[^+]' || true)"
    if [ -n "$DIFF_ADDED" ] && printf '%s\n' "$DIFF_ADDED" | grep -E -n "$COMBINED_REGEX" >&2; then
        echo "==> [aigile-forge-framework:scanner] Scan FAILED." >&2
        exit 1
    fi
fi

echo "==> [aigile-forge-framework:scanner] All security checks passed (0 findings)."
exit 0
