#!/usr/bin/env bash
# ==============================================================================
# Script: aff-worktree.sh
# Purpose: Ticket-isolated Git worktree lifecycle manager for AIgile Forge
#          Framework workspaces. Creates, lists, checkpoints, and removes
#          per-ticket worktrees under worktrees/<ticket-id>/.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="${AFF_WORKSPACE_DIR:-$PWD}"

SUBCOMMAND="${1:-help}"
shift || true

usage() {
    cat <<'EOF'
Usage: aff-worktree.sh <command> [arguments]

Commands:
  create <ticket-id> [repo-paths...]
      Create isolated git worktree(s) under worktrees/<ticket-id>/ on branch
      feat/<ticket-id>. If no repo-paths are supplied, discovers git repos in
      repositories/* or uses the current git repository.

  list
      List managed ticket worktree directories and git worktree registrations.

  checkpoint <ticket-id> [message]
      Stage and commit uncommitted changes across all worktrees for <ticket-id>.

  remove <ticket-id>
      Detach and clean up all worktrees under worktrees/<ticket-id>/.

  help
      Show this help message.

Ticket ID format:
  Must match ^[A-Za-z0-9._-]+$ (e.g., PROJ-101, FEAT_42, issue-7).
EOF
}

validate_ticket_id() {
    local tid="${1:-}"
    if [ -z "$tid" ]; then
        echo "ERROR: <ticket-id> is required." >&2
        usage >&2
        exit 1
    fi
    if [[ ! "$tid" =~ ^[A-Za-z0-9._-]+$ ]] || [[ "$tid" == "." ]] || [[ "$tid" == ".." ]]; then
        echo "ERROR: invalid ticket-id '$tid' (must match ^[A-Za-z0-9._-]+$)." >&2
        exit 1
    fi
}

add_repo_worktree() {
    local repo_path="$1"
    local ticket_id="$2"
    local wt_root="$3"
    local wt_name="$4"
    local target_wt="$wt_root/$wt_name"
    local branch_name="feat/$ticket_id"

    if [ -e "$target_wt" ]; then
        echo "  [OK] Worktree already exists: $target_wt"
        return 0
    fi

    if ! git -C "$repo_path" rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "  [WARN] Repository $repo_path has no initial commit yet; creating placeholder directory $target_wt"
        mkdir -p "$target_wt"
        return 0
    fi

    if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$branch_name"; then
        git -C "$repo_path" worktree add "$target_wt" "$branch_name"
    else
        git -C "$repo_path" worktree add -b "$branch_name" "$target_wt" HEAD
    fi
    echo "  [OK] Created worktree $target_wt (branch: $branch_name)"
}

case "$SUBCOMMAND" in
    create)
        TICKET_ID="${1:-}"
        validate_ticket_id "$TICKET_ID"
        shift || true

        REPO_ARGS=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                *)
                    REPO_ARGS+=("$1")
                    shift
                    ;;
            esac
        done

        WORKTREES_ROOT="$WORKSPACE_DIR/worktrees"
        TICKET_WT_DIR="$WORKTREES_ROOT/$TICKET_ID"
        mkdir -p "$TICKET_WT_DIR"
        mkdir -p "$WORKSPACE_DIR/work/$TICKET_ID/evidence"

        echo "==> [AFF Worktree] Provisioning isolated worktree(s) for $TICKET_ID..."

        if [ "${#REPO_ARGS[@]}" -gt 0 ]; then
            for rpath in "${REPO_ARGS[@]}"; do
                if [[ "$rpath" != /* ]]; then
                    RESOLVED_REPO="$WORKSPACE_DIR/$rpath"
                else
                    RESOLVED_REPO="$rpath"
                fi
                if [ ! -d "$RESOLVED_REPO" ] || ! git -C "$RESOLVED_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                    echo "ERROR: '$rpath' is not a valid git repository." >&2
                    exit 1
                fi
                REPO_NAME="$(basename "$(cd "$RESOLVED_REPO" && pwd)")"
                add_repo_worktree "$RESOLVED_REPO" "$TICKET_ID" "$TICKET_WT_DIR" "$REPO_NAME"
            done
        else
            DISCOVERED=0
            if [ -d "$WORKSPACE_DIR/repositories" ]; then
                for candidate in "$WORKSPACE_DIR"/repositories/*; do
                    [ -d "$candidate" ] || continue
                    if git -C "$candidate" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                        REPO_NAME="$(basename "$candidate")"
                        add_repo_worktree "$candidate" "$TICKET_ID" "$TICKET_WT_DIR" "$REPO_NAME"
                        DISCOVERED=$((DISCOVERED + 1))
                    fi
                done
            fi

            if [ "$DISCOVERED" -eq 0 ]; then
                if git -C "$WORKSPACE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                    TOPLEVEL="$(git -C "$WORKSPACE_DIR" rev-parse --show-toplevel)"
                    REPO_NAME="$(basename "$TOPLEVEL")"
                    add_repo_worktree "$TOPLEVEL" "$TICKET_ID" "$TICKET_WT_DIR" "$REPO_NAME"
                else
                    echo "  [INFO] No git repositories found in $WORKSPACE_DIR; created workspace folder $TICKET_WT_DIR"
                fi
            fi
        fi

        echo "==> [AFF Worktree] Ready at $TICKET_WT_DIR"
        ;;

    list)
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done

        WORKTREES_ROOT="$WORKSPACE_DIR/worktrees"
        echo "==> [AFF Worktree] Managed ticket worktrees in $WORKTREES_ROOT:"
        if [ ! -d "$WORKTREES_ROOT" ]; then
            echo "  (no active worktrees)"
            exit 0
        fi

        COUNT=0
        for tdir in "$WORKTREES_ROOT"/*; do
            [ -d "$tdir" ] || continue
            tname="$(basename "$tdir")"
            sub_count="$(find "$tdir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
            echo "  - $tname ($sub_count repo worktree(s)) -> $tdir"
            COUNT=$((COUNT + 1))
        done

        if [ "$COUNT" -eq 0 ]; then
            echo "  (no active worktrees)"
        fi
        ;;

    checkpoint)
        TICKET_ID="${1:-}"
        validate_ticket_id "$TICKET_ID"
        shift || true

        MSG=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                *)
                    if [ -z "$MSG" ]; then
                        MSG="$1"
                    else
                        MSG="$MSG $1"
                    fi
                    shift
                    ;;
            esac
        done

        TICKET_WT_DIR="$WORKSPACE_DIR/worktrees/$TICKET_ID"
        if [ ! -d "$TICKET_WT_DIR" ]; then
            echo "ERROR: worktree directory not found for ticket '$TICKET_ID': $TICKET_WT_DIR" >&2
            exit 1
        fi

        COMMIT_MSG="${MSG:-chore($TICKET_ID): checkpoint work-in-progress}"
        echo "==> [AFF Worktree] Checkpointing ticket $TICKET_ID..."

        CHECKPOINTED=0
        for wt in "$TICKET_WT_DIR"/*; do
            [ -d "$wt" ] || continue
            if git -C "$wt" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                git -C "$wt" add -A
                if [ -n "$(git -C "$wt" status --porcelain)" ]; then
                    AUTHOR_NAME="$(git -C "$wt" config user.name 2>/dev/null || true)"
                    AUTHOR_EMAIL="$(git -C "$wt" config user.email 2>/dev/null || true)"
                    git -C "$wt" \
                        -c user.name="${AUTHOR_NAME:-AIgile Developer}" \
                        -c user.email="${AUTHOR_EMAIL:-developer@example.local}" \
                        commit -m "$COMMIT_MSG" >/dev/null
                    echo "  [OK] Committed checkpoint in $(basename "$wt"): $COMMIT_MSG"
                    CHECKPOINTED=$((CHECKPOINTED + 1))
                else
                    echo "  [OK] $(basename "$wt") working tree is already clean."
                fi
            fi
        done

        echo "==> [AFF Worktree] Checkpoint complete ($CHECKPOINTED commit(s) created)."
        ;;

    remove)
        TICKET_ID="${1:-}"
        validate_ticket_id "$TICKET_ID"
        shift || true

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --workspace-dir)
                    WORKSPACE_DIR="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done

        TICKET_WT_DIR="$WORKSPACE_DIR/worktrees/$TICKET_ID"
        if [ ! -d "$TICKET_WT_DIR" ]; then
            echo "  [INFO] No worktree directory present at $TICKET_WT_DIR"
            exit 0
        fi

        echo "==> [AFF Worktree] Removing worktrees for $TICKET_ID..."
        for wt in "$TICKET_WT_DIR"/*; do
            [ -d "$wt" ] || continue
            if [ -f "$wt/.git" ] || [ -d "$wt/.git" ]; then
                COMMON_GIT_DIR="$(git -C "$wt" rev-parse --git-common-dir 2>/dev/null || true)"
                if [ -n "$COMMON_GIT_DIR" ] && [ -d "$COMMON_GIT_DIR" ]; then
                    PARENT_REPO="$(cd "$COMMON_GIT_DIR/.." 2>/dev/null && pwd || true)"
                    if [ -n "$PARENT_REPO" ]; then
                        git -C "$PARENT_REPO" worktree remove --force "$wt" 2>/dev/null || true
                        git -C "$PARENT_REPO" worktree prune 2>/dev/null || true
                    fi
                fi
            fi
        done

        rm -rf "$TICKET_WT_DIR"
        echo "==> [AFF Worktree] Removed $TICKET_WT_DIR"
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
