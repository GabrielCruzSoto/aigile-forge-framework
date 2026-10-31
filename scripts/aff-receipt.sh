#!/usr/bin/env bash
# ==============================================================================
# Script: aff-receipt.sh
# Purpose: Deterministic SHA256 Receipt-Driven Development (RDD) evidence tool.
#          Generates tamper-evident JSON receipts from verification commands and
#          recomputes canonical SHA256 signatures during verification.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="${AFF_WORKSPACE_DIR:-$PWD}"

SUBCOMMAND="${1:-help}"
shift || true

usage() {
    cat <<'EOF'
Usage: aff-receipt.sh <command> [options]

Commands:
  generate <ticket-id> <gate> [--out <file>] -- <command...>
      Execute <command...>, capture exit code, UTC timestamp, git HEAD SHA,
      working-tree diff SHA256, and command output SHA256, then write
      work/<ticket-id>/evidence/receipt-<gate>.json (or --out <file>) sealed
      with an overall receipt_sha256 signature. Exits with the command's code.

  verify <receipt-file> [--verify-head]
      Recompute receipt_sha256 from the JSON payload fields and optionally
      compare git_head against current git rev-parse HEAD. Exits 0 if authentic
      and non-zero if tampered or invalid.

  list [--ticket <ticket-id>]
      List generated JSON receipts under work/*/evidence/.

  help
      Show this help message.
EOF
}

validate_slug() {
    local label="$1"
    local value="$2"
    if [[ ! "$value" =~ ^[A-Za-z0-9._-]+$ ]] || [[ "$value" == "." ]] || [[ "$value" == ".." ]]; then
        echo "ERROR: invalid $label '$value' (must match ^[A-Za-z0-9._-]+$)." >&2
        exit 1
    fi
}

sha256_file() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$file" <<'PY'
import hashlib, pathlib, sys
print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
PY
    else
        echo "ERROR: no SHA256 utility found (need sha256sum, shasum, or python3)." >&2
        exit 1
    fi
}

case "$SUBCOMMAND" in
    generate)
        OUT_FILE=""
        TICKET_ID=""
        GATE=""
        CMD_ARGS=()

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --out)
                    if [[ $# -lt 2 ]]; then
                        echo "ERROR: --out requires a file path." >&2
                        exit 1
                    fi
                    OUT_FILE="$2"
                    shift 2
                    ;;
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                --)
                    shift
                    CMD_ARGS=("$@")
                    break
                    ;;
                -h|--help)
                    usage
                    exit 0
                    ;;
                *)
                    if [ -z "$TICKET_ID" ]; then
                        TICKET_ID="$1"
                        shift
                    elif [ -z "$GATE" ]; then
                        GATE="$1"
                        shift
                    else
                        CMD_ARGS=("$@")
                        break
                    fi
                    ;;
            esac
        done

        if [ -z "$TICKET_ID" ] || [ -z "$GATE" ] || [ "${#CMD_ARGS[@]}" -eq 0 ]; then
            echo "ERROR: generate requires <ticket-id> <gate> -- <command...>." >&2
            usage >&2
            exit 1
        fi

        validate_slug "ticket-id" "$TICKET_ID"
        validate_slug "gate" "$GATE"

        if [ -z "$OUT_FILE" ]; then
            OUT_FILE="$WORKSPACE_DIR/work/$TICKET_ID/evidence/receipt-$GATE.json"
        fi
        mkdir -p "$(dirname "$OUT_FILE")"

        TMP_OUT="$(mktemp)"
        TMP_DIFF="$(mktemp)"
        trap 'rm -f "$TMP_OUT" "$TMP_DIFF"' EXIT

        TIMESTAMP_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

        GIT_HEAD="NONE"
        if git -C "$WORKSPACE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            if git -C "$WORKSPACE_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
                GIT_HEAD="$(git -C "$WORKSPACE_DIR" rev-parse HEAD)"
                git -C "$WORKSPACE_DIR" diff HEAD --no-ext-diff > "$TMP_DIFF" 2>/dev/null || true
            else
                GIT_HEAD="UNCOMMITTED"
                git -C "$WORKSPACE_DIR" status --porcelain > "$TMP_DIFF" 2>/dev/null || true
            fi
        else
            : > "$TMP_DIFF"
        fi
        DIFF_SHA256="$(sha256_file "$TMP_DIFF")"

        set +e
        "${CMD_ARGS[@]}" > "$TMP_OUT" 2>&1
        CMD_EXIT=$?
        set -e

        if [ -s "$TMP_OUT" ]; then
            cat "$TMP_OUT"
        fi
        OUTPUT_SHA256="$(sha256_file "$TMP_OUT")"

        AFF_OUT_FILE="$OUT_FILE" \
        AFF_TICKET_ID="$TICKET_ID" \
        AFF_GATE="$GATE" \
        AFF_CMD_STR="${CMD_ARGS[*]}" \
        AFF_EXIT_CODE="$CMD_EXIT" \
        AFF_TIMESTAMP="$TIMESTAMP_UTC" \
        AFF_GIT_HEAD="$GIT_HEAD" \
        AFF_DIFF_SHA="$DIFF_SHA256" \
        AFF_OUTPUT_SHA="$OUTPUT_SHA256" \
        python3 - "${CMD_ARGS[@]}" <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path

payload = {
    "schema_version": "1.0.0",
    "ticket_id": os.environ["AFF_TICKET_ID"],
    "gate": os.environ["AFF_GATE"],
    "command": os.environ["AFF_CMD_STR"],
    "command_argv": sys.argv[1:],
    "exit_code": int(os.environ["AFF_EXIT_CODE"]),
    "status": "passed" if int(os.environ["AFF_EXIT_CODE"]) == 0 else "failed",
    "timestamp_utc": os.environ["AFF_TIMESTAMP"],
    "git_head": os.environ["AFF_GIT_HEAD"],
    "working_tree_diff_sha256": os.environ["AFF_DIFF_SHA"],
    "output_sha256": os.environ["AFF_OUTPUT_SHA"],
}

canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
receipt_sha = hashlib.sha256(canonical).hexdigest()
payload["receipt_sha256"] = receipt_sha

out_path = Path(os.environ["AFF_OUT_FILE"])
out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
print(f"==> [AFF Receipt] Generated {out_path} (exit={payload['exit_code']}, sha256={receipt_sha[:16]}...)")
PY

        exit "$CMD_EXIT"
        ;;

    verify)
        RECEIPT_FILE=""
        VERIFY_HEAD=false

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --verify-head)
                    VERIFY_HEAD=true
                    shift
                    ;;
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                -h|--help)
                    usage
                    exit 0
                    ;;
                *)
                    if [ -z "$RECEIPT_FILE" ]; then
                        RECEIPT_FILE="$1"
                        shift
                    else
                        echo "ERROR: unexpected argument: $1" >&2
                        exit 1
                    fi
                    ;;
            esac
        done

        if [ -z "$RECEIPT_FILE" ]; then
            echo "ERROR: verify requires <receipt-file>." >&2
            usage >&2
            exit 1
        fi
        if [ ! -f "$RECEIPT_FILE" ]; then
            echo "ERROR: receipt file not found: $RECEIPT_FILE" >&2
            exit 1
        fi

        CURRENT_HEAD=""
        if [ "$VERIFY_HEAD" = true ]; then
            if ! git -C "$WORKSPACE_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
                echo "ERROR: --verify-head requested, but $WORKSPACE_DIR has no git HEAD commit." >&2
                exit 1
            fi
            CURRENT_HEAD="$(git -C "$WORKSPACE_DIR" rev-parse HEAD)"
        fi

        AFF_RECEIPT_FILE="$RECEIPT_FILE" \
        AFF_VERIFY_HEAD="$VERIFY_HEAD" \
        AFF_CURRENT_HEAD="$CURRENT_HEAD" \
        python3 - <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path

receipt_path = Path(os.environ["AFF_RECEIPT_FILE"])
verify_head = os.environ["AFF_VERIFY_HEAD"] == "true"
current_head = os.environ["AFF_CURRENT_HEAD"]

try:
    data = json.loads(receipt_path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"==> [AFF Receipt] VERIFY FAILED: invalid JSON in {receipt_path}: {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(data, dict):
    print("==> [AFF Receipt] VERIFY FAILED: receipt root must be a JSON object.", file=sys.stderr)
    sys.exit(1)

required_fields = [
    "schema_version",
    "ticket_id",
    "gate",
    "command",
    "exit_code",
    "timestamp_utc",
    "git_head",
    "working_tree_diff_sha256",
    "output_sha256",
    "receipt_sha256",
]
missing = [k for k in required_fields if k not in data]
if missing:
    print(f"==> [AFF Receipt] VERIFY FAILED: missing required field(s): {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

expected_sha = data.get("receipt_sha256")
payload = {k: v for k, v in data.items() if k != "receipt_sha256"}
canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
actual_sha = hashlib.sha256(canonical).hexdigest()

if actual_sha != expected_sha:
    print("==> [AFF Receipt] VERIFY FAILED: receipt_sha256 mismatch (tampering detected).", file=sys.stderr)
    print(f"    Expected: {expected_sha}", file=sys.stderr)
    print(f"    Actual:   {actual_sha}", file=sys.stderr)
    sys.exit(1)

if verify_head and data.get("git_head") != current_head:
    print("==> [AFF Receipt] VERIFY FAILED: git_head does not match current HEAD.", file=sys.stderr)
    print(f"    Receipt HEAD: {data.get('git_head')}", file=sys.stderr)
    print(f"    Current HEAD: {current_head}", file=sys.stderr)
    sys.exit(1)

print(
    f"==> [AFF Receipt] VERIFY OK: ticket={data['ticket_id']} gate={data['gate']} "
    f"status={data.get('status', 'unknown')} sha256={actual_sha}"
)
PY
        ;;

    list)
        FILTER_TICKET=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --ticket)
                    FILTER_TICKET="$2"
                    shift 2
                    ;;
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done

        echo "==> [AFF Receipt] Stored receipts in $WORKSPACE_DIR/work:"
        FOUND=0
        if [ -d "$WORKSPACE_DIR/work" ]; then
            while IFS= read -r rfile; do
                [ -z "$rfile" ] && continue
                if [ -n "$FILTER_TICKET" ] && [[ "$rfile" != *"/work/$FILTER_TICKET/"* ]]; then
                    continue
                fi
                echo "  - $rfile"
                FOUND=1
            done < <(find "$WORKSPACE_DIR/work" -path '*/evidence/receipt-*.json' 2>/dev/null | sort)
        fi
        if [ "$FOUND" -eq 0 ]; then
            echo "  (no receipts found)"
        fi
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
