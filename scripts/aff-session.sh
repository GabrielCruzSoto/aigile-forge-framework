#!/usr/bin/env bash
# ==============================================================================
# Script: aff-session.sh
# Purpose: Structured Markdown session lifecycle journal for AIgile Forge
#          Framework workspaces. Persists incremental context under work/sessions/
#          so interrupted or multi-day tickets resume cleanly across harnesses.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="${AFF_WORKSPACE_DIR:-$PWD}"

SUBCOMMAND="${1:-help}"
shift || true

usage() {
    cat <<'EOF'
Usage: aff-session.sh <command> [arguments]

Commands:
  start [ticket-id]
      Start a new structured session log under work/sessions/ and mark it active.

  checkpoint [note]
      Append a timestamped git/progress checkpoint entry to the active session log.

  close [summary]
      Close the active session log with a final summary.

  resume [ticket-id]
      Print and reactivate the active or most recent session log (filtered by
      ticket-id when provided).

  status
      Show the currently active session identifier and file path.

  list
      List all recorded session logs under work/sessions/.

  help
      Show this help message.
EOF
}

now_utc() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

parse_workspace_opt() {
    REMAINING_ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workspace-dir)
                WORKSPACE_DIR="$2"
                shift 2
                ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

git_summary() {
    local dir="$1"
    if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch sha
        branch="$(git -C "$dir" branch --show-current 2>/dev/null || echo 'detached')"
        sha="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo 'uncommitted')"
        printf 'branch=%s sha=%s' "${branch:-detached}" "$sha"
    else
        printf 'non-git-workspace'
    fi
}

append_to_section() {
    local file="$1"
    local heading="$2"
    local line_text="$3"
    awk -v hdr="## $heading" -v entry="$line_text" '
        $0 == hdr { print; print entry; inserted=1; next }
        { print }
        END { if (!inserted) { print ""; print hdr; print entry } }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

REMAINING_ARGS=()
parse_workspace_opt "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

SESSIONS_DIR="$WORKSPACE_DIR/work/sessions"
CURRENT_FILE="$SESSIONS_DIR/current"
LATEST_FILE="$SESSIONS_DIR/latest"

mkdir -p "$SESSIONS_DIR"

case "$SUBCOMMAND" in
    start)
        TICKET_ID="${1:-general}"
        if [[ ! "$TICKET_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
            echo "ERROR: invalid ticket-id '$TICKET_ID'." >&2
            exit 1
        fi

        BASE_SID="SES-$(date -u '+%Y%m%d-%H%M%S')"
        SID="$BASE_SID"
        SEQ=1
        while [ -f "$SESSIONS_DIR/$SID.md" ]; do
            SID="${BASE_SID}-${SEQ}"
            SEQ=$((SEQ + 1))
        done

        SESSION_FILE="$SESSIONS_DIR/$SID.md"
        STARTED_AT="$(now_utc)"
        GIT_INFO="$(git_summary "$WORKSPACE_DIR")"

        cat > "$SESSION_FILE" <<EOF
# Session $SID

- **Ticket:** $TICKET_ID
- **Status:** ACTIVE
- **Started (UTC):** $STARTED_AT
- **Git Context:** $GIT_INFO

## Initial Context
- Workspace: \`$WORKSPACE_DIR\`
- Initial git state: \`$GIT_INFO\`

## Checkpoints

## Summary & Closure
EOF

        printf '%s\n' "$SID" > "$CURRENT_FILE"
        printf '%s\n' "$SID" > "$LATEST_FILE"
        printf '%s\n' "$SID" > "$SESSIONS_DIR/latest-$TICKET_ID"

        echo "==> [AFF Session] Started session $SID (ticket: $TICKET_ID)"
        echo "    Log file: $SESSION_FILE"
        ;;

    checkpoint)
        if [ ! -f "$CURRENT_FILE" ]; then
            echo "ERROR: no active session found. Run 'aff-session.sh start [ticket-id]' first." >&2
            exit 1
        fi
        SID="$(cat "$CURRENT_FILE")"
        SESSION_FILE="$SESSIONS_DIR/$SID.md"
        if [ ! -f "$SESSION_FILE" ]; then
            echo "ERROR: active session log missing: $SESSION_FILE" >&2
            exit 1
        fi

        NOTE="${*:-Periodic session checkpoint}"
        ENTRY="- [$(now_utc)] $NOTE ($(git_summary "$WORKSPACE_DIR"))"
        append_to_section "$SESSION_FILE" "Checkpoints" "$ENTRY"
        echo "==> [AFF Session] Recorded checkpoint in $SID"
        ;;

    close)
        if [ ! -f "$CURRENT_FILE" ]; then
            echo "ERROR: no active session to close." >&2
            exit 1
        fi
        SID="$(cat "$CURRENT_FILE")"
        SESSION_FILE="$SESSIONS_DIR/$SID.md"
        if [ ! -f "$SESSION_FILE" ]; then
            echo "ERROR: active session log missing: $SESSION_FILE" >&2
            exit 1
        fi

        SUMMARY="${*:-Session completed normally.}"
        CLOSED_AT="$(now_utc)"

        awk '
            /^- \*\*Status:\*\* / { print "- **Status:** CLOSED"; next }
            { print }
        ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"

        append_to_section "$SESSION_FILE" "Summary & Closure" "- **Closed (UTC):** $CLOSED_AT"
        append_to_section "$SESSION_FILE" "Summary & Closure" "- **Summary:** $SUMMARY"

        rm -f "$CURRENT_FILE"
        printf '%s\n' "$SID" > "$LATEST_FILE"

        echo "==> [AFF Session] Closed session $SID"
        echo "    Archived log: $SESSION_FILE"
        ;;

    resume)
        FILTER_TICKET="${1:-}"
        SID=""

        if [ -n "$FILTER_TICKET" ]; then
            if [ -f "$SESSIONS_DIR/latest-$FILTER_TICKET" ]; then
                CANDIDATE="$(cat "$SESSIONS_DIR/latest-$FILTER_TICKET")"
                [ -f "$SESSIONS_DIR/$CANDIDATE.md" ] && SID="$CANDIDATE"
            fi
            if [ -z "$SID" ]; then
                for f in $(ls -1t "$SESSIONS_DIR"/SES-*.md 2>/dev/null || true); do
                    if grep -q "^- \*\*Ticket:\*\* ${FILTER_TICKET}$" "$f" 2>/dev/null; then
                        SID="$(basename "$f" .md)"
                        break
                    fi
                done
            fi
        else
            if [ -f "$CURRENT_FILE" ]; then
                CANDIDATE="$(cat "$CURRENT_FILE")"
                [ -f "$SESSIONS_DIR/$CANDIDATE.md" ] && SID="$CANDIDATE"
            fi
            if [ -z "$SID" ] && [ -f "$LATEST_FILE" ]; then
                CANDIDATE="$(cat "$LATEST_FILE")"
                [ -f "$SESSIONS_DIR/$CANDIDATE.md" ] && SID="$CANDIDATE"
            fi
            if [ -z "$SID" ]; then
                FIRST_MATCH="$(ls -1t "$SESSIONS_DIR"/SES-*.md 2>/dev/null | head -n1 || true)"
                [ -n "$FIRST_MATCH" ] && SID="$(basename "$FIRST_MATCH" .md)"
            fi
        fi

        if [ -z "$SID" ] || [ ! -f "$SESSIONS_DIR/$SID.md" ]; then
            echo "ERROR: no matching session log found in $SESSIONS_DIR" >&2
            exit 1
        fi

        SESSION_FILE="$SESSIONS_DIR/$SID.md"
        awk '
            /^- \*\*Status:\*\* / { print "- **Status:** ACTIVE"; next }
            { print }
        ' "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"
        append_to_section "$SESSION_FILE" "Checkpoints" "- [$(now_utc)] Session resumed ($(git_summary "$WORKSPACE_DIR"))"
        printf '%s\n' "$SID" > "$CURRENT_FILE"

        echo "==> [AFF Session] Resumed session $SID"
        echo ""
        cat "$SESSION_FILE"
        ;;

    status)
        if [ -f "$CURRENT_FILE" ]; then
            SID="$(cat "$CURRENT_FILE")"
            echo "==> [AFF Session] Active session: $SID ($SESSIONS_DIR/$SID.md)"
        else
            echo "==> [AFF Session] No active session."
        fi
        ;;

    list)
        ACTIVE_SID=""
        [ -f "$CURRENT_FILE" ] && ACTIVE_SID="$(cat "$CURRENT_FILE")"
        echo "==> [AFF Session] Recorded sessions in $SESSIONS_DIR:"
        FOUND=0
        for f in $(ls -1t "$SESSIONS_DIR"/SES-*.md 2>/dev/null || true); do
            [ -f "$f" ] || continue
            sid="$(basename "$f" .md)"
            ticket="$(grep -m1 '^- \*\*Ticket:\*\* ' "$f" | sed 's/^- \*\*Ticket:\*\* //' || echo 'unknown')"
            st="$(grep -m1 '^- \*\*Status:\*\* ' "$f" | sed 's/^- \*\*Status:\*\* //' || echo 'UNKNOWN')"
            marker=""
            [ "$sid" = "$ACTIVE_SID" ] && marker=" (current)"
            echo "  - $sid [ticket=$ticket, status=$st]$marker"
            FOUND=1
        done
        if [ "$FOUND" -eq 0 ]; then
            echo "  (no sessions recorded)"
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
