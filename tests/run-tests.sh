#!/usr/bin/env bash
# ==============================================================================
# aigile-forge-framework — Deterministic End-to-End Verification Suite
# Covers ODD Specs S1, S2, S3, S4 in isolated mktemp scratch directories.
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/aff-test-suite.XXXXXX")"
trap 'rm -rf "$SCRATCH_ROOT"' EXIT

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "  [PASS] %s\n" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "  [FAIL] %s\n" "$1" >&2
}

echo "==> Running aigile-forge-framework Verification Suite"
echo "    Repository: $REPO_ROOT"

# ------------------------------------------------------------------------------
# S1: Standalone git repository & required canonical tree
# ------------------------------------------------------------------------------
echo ""
echo "--- [S1] Standalone Repository & Canonical Structure ---"
TOPLEVEL="$(git -C "$REPO_ROOT" rev-parse --show-toplevel)"
if [ "$TOPLEVEL" = "$REPO_ROOT" ]; then
    pass "Repository is an independent Git root ($TOPLEVEL)"
else
    fail "Expected Git root $REPO_ROOT, got $TOPLEVEL"
fi

for required in AGENTS.md aff.yaml aigile README.md README.es.md agents skills profiles prompts templates scripts mcp configs docs; do
    if [ -e "$REPO_ROOT/$required" ]; then
        pass "Canonical entry exists: $required"
    else
        fail "Missing canonical entry: $required"
    fi
done

# Verify sibling repositories in workspace (when present) have zero files modified today
SIBLING_PARENT="$(dirname "$REPO_ROOT")"
SESSION_START_DATE="2026-10-30 00:00:00"
for sibling in aigile-forge-framework-copilot aigile-forge-framework-redSalud; do
    if [ -d "$SIBLING_PARENT/$sibling/.git" ]; then
        RECENT_MODS="$(find "$SIBLING_PARENT/$sibling" -not -path '*/.git*' -newermt "$SESSION_START_DATE" 2>/dev/null | head -n 5)"
        if [ -z "$RECENT_MODS" ]; then
            pass "Sibling repository untouched during session: $sibling"
        else
            fail "Sibling repository modified during session ($sibling): $RECENT_MODS"
        fi
    fi
done

# ------------------------------------------------------------------------------
# S4: Zero Company & Zero Team-Unit Legacy Terminology Audit
# ------------------------------------------------------------------------------
echo ""
echo "--- [S4] Agnostic Terminology & Zero Company Coupling Audit ---"
# Build legacy pattern dynamically so this test file itself stays free of legacy literals
LEGACY_UNIT_ES_ACCENT="c""é""lula"
LEGACY_UNIT_ES="cel""ula"
LEGACY_UNIT_EN="\\bce""ll\\b"
LEGACY_CMD="init-ce""ll"
LEGACY_ORG_A="red""salud"
LEGACY_ORG_B="zen""ta"
LEGACY_ORG_C="scotia""bank"
LEGACY_DOM_A="fona""sa"
LEGACY_DOM_B="isa""pre"
LEGACY_DOM_C="web""pay"
LEGACY_LAW="20\\.584"
LEGACY_SLUG="RS_""TEL|RS_""PWA|MON-[0-9]|MON-<"
LEGACY_DRIVE="1A16n3VOzIeawEzuxhw7N4cW9VVFZ5uXp"
LEGACY_SYNC="one""drive"

FORBIDDEN_REGEX="(${LEGACY_UNIT_ES_ACCENT}|${LEGACY_UNIT_ES}|${LEGACY_UNIT_EN}|${LEGACY_CMD}|${LEGACY_ORG_A}|${LEGACY_ORG_B}|${LEGACY_ORG_C}|${LEGACY_DOM_A}|${LEGACY_DOM_B}|${LEGACY_DOM_C}|${LEGACY_LAW}|${LEGACY_SLUG}|${LEGACY_DRIVE}|${LEGACY_SYNC})"

AUDIT_TARGETS=(
    "$REPO_ROOT/AGENTS.md"
    "$REPO_ROOT/LICENSE"
    "$REPO_ROOT/aff.yaml"
    "$REPO_ROOT/aigile"
    "$REPO_ROOT/README.md"
    "$REPO_ROOT/README.es.md"
    "$REPO_ROOT/agents"
    "$REPO_ROOT/skills"
    "$REPO_ROOT/profiles"
    "$REPO_ROOT/prompts"
    "$REPO_ROOT/scripts"
    "$REPO_ROOT/templates"
    "$REPO_ROOT/mcp"
    "$REPO_ROOT/configs"
    "$REPO_ROOT/docs"
)

if grep -rnE -i "$FORBIDDEN_REGEX" "${AUDIT_TARGETS[@]}" >"$SCRATCH_ROOT/forbidden-hits.txt" 2>/dev/null; then
    fail "Forbidden legacy or company terms found:"
    cat "$SCRATCH_ROOT/forbidden-hits.txt" >&2
else
    pass "Zero company or legacy unit terms across all canonical files and docs"
fi

# S1/T6: Enforce exact canonical framework name `aigile-forge-framework` (no AIgile/Aigile/standalone AFF branding)
NON_CANONICAL_NAME_A="AI""gile"
NON_CANONICAL_NAME_B="Ai""gile"
NON_CANONICAL_ACRONYM="\\bAF""F\\b"
NAME_VARIANT_REGEX="(${NON_CANONICAL_NAME_A}|${NON_CANONICAL_NAME_B}|${NON_CANONICAL_ACRONYM})"

if grep -rnE "$NAME_VARIANT_REGEX" "${AUDIT_TARGETS[@]}" >"$SCRATCH_ROOT/name-hits.txt" 2>/dev/null; then
    fail "Non-canonical framework name variants found (must strictly be 'aigile-forge-framework'):"
    head -n 15 "$SCRATCH_ROOT/name-hits.txt" >&2
else
    pass "Canonical framework name 'aigile-forge-framework' maintained across all files"
fi

# ------------------------------------------------------------------------------
# S2: Universal Harness Projection (Zero-MCP vs Full-MCP + Copilot .github/)
# ------------------------------------------------------------------------------
echo ""
echo "--- [S2] Universal Multi-Harness & Copilot Projection ---"
COPY_REPO="$SCRATCH_ROOT/framework-copy"
mkdir -p "$COPY_REPO"
cp -R "$REPO_ROOT"/. "$COPY_REPO"/

"$COPY_REPO/aigile" harness sync all --copy --mode zero-mcp >"$SCRATCH_ROOT/sync-zero.log" 2>&1
pass "aigile harness sync all --copy --mode zero-mcp succeeded"

for expected_path in \
    "$COPY_REPO/CLAUDE.md" \
    "$COPY_REPO/.claude/skills" \
    "$COPY_REPO/.claude/commands" \
    "$COPY_REPO/opencode.json" \
    "$COPY_REPO/.agents/skills" \
    "$COPY_REPO/.agents/workflows" \
    "$COPY_REPO/.github/copilot-instructions.md" \
    "$COPY_REPO/.github/instructions" \
    "$COPY_REPO/.github/agents" \
    "$COPY_REPO/.github/prompts" \
    "$COPY_REPO/.github/skills"; do
    if [ -e "$expected_path" ]; then
        pass "Zero-MCP projected target exists: ${expected_path#$COPY_REPO/}"
    else
        fail "Missing Zero-MCP projected target: ${expected_path#$COPY_REPO/}"
    fi
done

if [ ! -e "$COPY_REPO/.mcp.json" ] && [ ! -e "$COPY_REPO/.agents/mcp_config.json" ]; then
    pass "Zero-MCP mode omits MCP server descriptor files (.mcp.json, .agents/mcp_config.json)"
else
    fail "Zero-MCP mode unexpectedly emitted MCP descriptor files"
fi

"$COPY_REPO/aigile" harness check >"$SCRATCH_ROOT/check-zero.log" 2>&1
pass "aigile harness check passed in zero-mcp mode"

# ------------------------------------------------------------------------------
# S2b: Per-harness agent capability contracts (Claude Code / Antigravity / OpenCode / Copilot)
# Allowlists may only restrict; full-capability agents must keep write + delegation.
# ------------------------------------------------------------------------------
echo ""
echo "--- [S2b] Cross-Harness Agent Capability Contracts ---"
CONTRACT_OUT="$(python3 - "$COPY_REPO" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])

def fm(path):
    m = re.match(r"^---\r?\n(.*?)\r?\n---", path.read_text(encoding="utf-8"), re.S)
    return m.group(1) if m else ""

def check(ok, label):
    print(("PASS " if ok else "FAIL ") + label)

orch_c = fm(root / ".claude/agents/orchestrator.md")
check(not re.search(r"^tools:", orch_c, re.M), "claude: orchestrator inherits full toolset (no tools restriction)")
analyst_c = fm(root / ".claude/agents/analyst.md")
check(re.search(r"^tools:.*\bWrite\b", analyst_c, re.M) is not None, "claude: edit-capable restricted agent includes Write")
reviewer_c = fm(root / ".claude/agents/reviewer.md")
check(re.search(r"^tools:", reviewer_c, re.M) is not None and "Write" not in reviewer_c, "claude: reviewer stays restricted without Write")

for slug in ("orchestrator", "delivery", "reviewer"):
    ag = fm(root / f".agents/agents/{slug}.md")
    check(re.search(r"^tools:\s*\r?\n\s+-\s", ag, re.M) is not None, f"antigravity: {slug} has native tools list")
    check("readonly: false" in ag, f"antigravity: {slug} is not readonly")

ag_orch = fm(root / ".agents/agents/orchestrator.md")
check("mainAgent: true" in ag_orch and "run_command" in ag_orch and "write_file" in ag_orch, "antigravity: orchestrator has mainAgent and full write tools")

orch_o = fm(root / ".opencode/agents/orchestrator.md")
check(not re.search(r"^tools:", orch_o, re.M), "opencode: orchestrator keeps every native tool enabled")
rev_o = fm(root / ".opencode/agents/reviewer.md")
check(re.search(r"^tools:\s*\n\s+write: false", rev_o, re.M) is not None, "opencode: reviewer tools is a boolean map disabling write")
check(not re.search(r"^tools:\s*\n\s+-\s", rev_o, re.M), "opencode: tools is never emitted as a list")

orch_g = fm(root / ".github/agents/aff-orchestrator.agent.md")
check('"agent"' in orch_g and '"edit"' in orch_g, "copilot: orchestrator has edit + agent (delegation) tools")
PY
)"
while IFS= read -r line; do
    case "$line" in
        "PASS "*) pass "${line#PASS }" ;;
        "FAIL "*) fail "${line#FAIL }" ;;
    esac
done <<< "$CONTRACT_OUT"

# Negative test: harness check must reject if orchestrator is stripped of write_file
NEG_AG="$COPY_REPO/.agents/agents/orchestrator.md"
cp "$NEG_AG" "$SCRATCH_ROOT/orchestrator.ag.bak"
python3 - "$NEG_AG" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = s.replace("  - write_file\n", "", 1)
open(p, "w", encoding="utf-8").write(s)
PY
if "$COPY_REPO/aigile" harness check >/dev/null 2>&1; then
    fail "aigile harness check accepted an Antigravity orchestrator missing write_file"
else
    pass "aigile harness check rejects an Antigravity orchestrator missing write_file"
fi
cp "$SCRATCH_ROOT/orchestrator.ag.bak" "$NEG_AG"

# Now test Full-MCP projection
"$COPY_REPO/aigile" harness sync all --copy --mode mcp >"$SCRATCH_ROOT/sync-mcp.log" 2>&1
if [ -f "$COPY_REPO/.mcp.json" ] && [ -f "$COPY_REPO/.agents/mcp_config.json" ]; then
    python3 -c 'import json, sys; d1=json.load(open(sys.argv[1])); d2=json.load(open(sys.argv[2])); assert "mcpServers" in d1 and len(d1["mcpServers"]) >= 4' "$COPY_REPO/.mcp.json" "$COPY_REPO/.agents/mcp_config.json"
    pass "Full-MCP mode generated valid .mcp.json and .agents/mcp_config.json"
else
    fail "Full-MCP mode did not generate .mcp.json and .agents/mcp_config.json"
fi

"$COPY_REPO/aigile" harness check --mode mcp >"$SCRATCH_ROOT/check-mcp.log" 2>&1
pass "aigile harness check --mode mcp passed in mcp mode"

if "$COPY_REPO/aigile" harness check >/dev/null 2>&1; then
    fail "aigile harness check failed to flag MCP artifacts against zero-mcp aff.yaml"
else
    pass "aigile harness check enforces zero-mcp policy when aff.yaml is zero-mcp"
fi

# ------------------------------------------------------------------------------
# S3: Team/Project Onboarding, Topologies, Receipts, Sessions & Secret Scanner
# ------------------------------------------------------------------------------
echo ""
echo "--- [S3] Team Onboarding, Topologies, SHA256 Receipts & Secret Scan ---"

# Case A: Multi-root + Zero-MCP + Spanish onboarding
WS_MULTI="$SCRATCH_ROOT/ws-multiroot"
mkdir -p "$WS_MULTI"
"$REPO_ROOT/aigile" init \
    --name "commerce-portal" \
    --team "Digital Checkout Team" \
    --lang "es" \
    --topology "multi-root" \
    --mode "zero-mcp" \
    --harnesses "copilot,claude" \
    --tracker "jira" \
    --prefix "CHK" \
    --workspace "$WS_MULTI" \
    --non-interactive >"$SCRATCH_ROOT/init-multi.log" 2>&1

if [ -f "$WS_MULTI/aff.yaml" ] && [ -f "$WS_MULTI/commerce-portal.code-workspace" ] && [ -f "$WS_MULTI/.github/copilot-instructions.md" ]; then
    pass "Scaffolded multi-root + zero-mcp workspace (commerce-portal)"
else
    fail "Multi-root scaffolding missing expected files in $WS_MULTI"
fi

# Case B: Worktrees + MCP + English onboarding + Git + Receipts + Sessions + Doctor
WS_WT="$SCRATCH_ROOT/ws-worktrees"
mkdir -p "$WS_WT"
git -C "$WS_WT" init -b main >/dev/null 2>&1
git -C "$WS_WT" config user.name "Test Runner"
git -C "$WS_WT" config user.email "test@example.org"

"$REPO_ROOT/aigile" init \
    --name "core-ledger" \
    --team "Platform Core Engineering" \
    --lang "en" \
    --topology "worktrees" \
    --mode "mcp" \
    --harnesses "all" \
    --tracker "linear" \
    --prefix "LDG" \
    --workspace "$WS_WT" \
    --non-interactive >"$SCRATCH_ROOT/init-wt.log" 2>&1

git -C "$WS_WT" add . >/dev/null 2>&1
git -C "$WS_WT" commit -m "chore: bootstrap workspace" >/dev/null 2>&1

(cd "$WS_WT" && ./aigile doctor) >"$SCRATCH_ROOT/doctor.log" 2>&1
pass "aigile doctor passed in initialized workspace"

(cd "$WS_WT" && ./aigile session start LDG-101) >"$SCRATCH_ROOT/session.log" 2>&1
(cd "$WS_WT" && ./aigile session checkpoint "Defined contract") >>"$SCRATCH_ROOT/session.log" 2>&1
(cd "$WS_WT" && ./aigile session close "Completed unit") >>"$SCRATCH_ROOT/session.log" 2>&1
pass "aigile session lifecycle (start/checkpoint/close) succeeded"

(cd "$WS_WT" && ./aigile receipt generate LDG-101 G3 -- bash -c "echo deterministic_gate_ok") >"$SCRATCH_ROOT/receipt.log" 2>&1
RECEIPT_FILE="$(find "$WS_WT/work/LDG-101" -name '*G3*.json' | head -n 1)"
if [ -n "$RECEIPT_FILE" ] && [ -f "$RECEIPT_FILE" ]; then
    (cd "$WS_WT" && ./aigile receipt verify "$RECEIPT_FILE") >"$SCRATCH_ROOT/receipt-verify.log" 2>&1
    pass "SHA256 RDD receipt generated and verified ($RECEIPT_FILE)"

    TAMPERED_FILE="$SCRATCH_ROOT/tampered-receipt.json"
    python3 -c 'import json, sys; d=json.load(open(sys.argv[1])); d["command"]="echo tampered"; json.dump(d, open(sys.argv[2], "w"))' "$RECEIPT_FILE" "$TAMPERED_FILE"
    if (cd "$WS_WT" && ./aigile receipt verify "$TAMPERED_FILE") >/dev/null 2>&1; then
        fail "Tampered receipt unexpectedly passed verification"
    else
        pass "Tampered receipt rejected by SHA256 verification"
    fi
else
    fail "Receipt JSON not created under $WS_WT/work/LDG-101"
fi

# Secret scanner clean vs dirty check
CLEAN_SCAN_DIR="$SCRATCH_ROOT/scan-clean"
DIRTY_SCAN_DIR="$SCRATCH_ROOT/scan-dirty"
mkdir -p "$CLEAN_SCAN_DIR" "$DIRTY_SCAN_DIR"
printf "export SAFE_VALUE=production_mode\n" >"$CLEAN_SCAN_DIR/app.env"
FAKE_AKIA="AKIA""IOSFODNN7EXAMPLE"
printf "AWS_KEY=%s\n" "$FAKE_AKIA" >"$DIRTY_SCAN_DIR/leaked.env"

if "$REPO_ROOT/aigile" scan --path "$CLEAN_SCAN_DIR" >/dev/null 2>&1; then
    pass "Secret scanner passes clean directory"
else
    fail "Secret scanner falsely flagged clean directory"
fi

if "$REPO_ROOT/aigile" scan --path "$DIRTY_SCAN_DIR" >/dev/null 2>&1; then
    fail "Secret scanner failed to detect synthetic AWS access key"
else
    pass "Secret scanner blocked synthetic AWS access key"
fi

# ------------------------------------------------------------------------------
# S6: Open-Source MIT License & Comprehensive Bilingual Documentation Suite
# ------------------------------------------------------------------------------
echo ""
echo "--- [S6] MIT License & Comprehensive Bilingual Documentation Suite ---"
if [ -f "$REPO_ROOT/LICENSE" ] && grep -q "^MIT License$" "$REPO_ROOT/LICENSE" && grep -q "aigile-forge-framework Contributors" "$REPO_ROOT/LICENSE"; then
    pass "Root MIT LICENSE present with neutral open-source copyright"
else
    fail "Missing or invalid MIT LICENSE file at repository root"
fi

FW_VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION" 2>/dev/null || echo missing)"
if printf '%s' "$FW_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' \
    && [ "$("$REPO_ROOT/aigile" --version)" = "aigile-forge-framework $FW_VERSION" ] \
    && grep -q "\*\*Version:\*\* \`$FW_VERSION\`" "$REPO_ROOT/README.md" \
    && grep -q "\*\*Versión:\*\* \`$FW_VERSION\`" "$REPO_ROOT/README.es.md"; then
    pass "Framework release version $FW_VERSION is consistent (VERSION, ./aigile --version, READMEs)"
else
    fail "Inconsistent framework version: VERSION=$FW_VERSION, cli=$("$REPO_ROOT/aigile" --version 2>/dev/null || echo error)"
fi

REQUIRED_DOC_RELPATHS=(
    "index.md"
    "architecture/overview.md"
    "guides/installation-and-configuration.md"
    "guides/onboarding-and-topologies.md"
    "guides/developer-workflow-manual.md"
    "guides/lifecycle-gates-and-4r.md"
    "harnesses/compatibility-matrix.md"
    "catalog/agents-and-prompts.md"
    "catalog/skills-and-profiles.md"
    "governance/security-and-knowledge-sync.md"
)

for lang in en es; do
    for doc_rel in "${REQUIRED_DOC_RELPATHS[@]}"; do
        doc_full="$REPO_ROOT/docs/$lang/$doc_rel"
        if [ -f "$doc_full" ] && [ "$(wc -l < "$doc_full")" -ge 60 ]; then
            pass "Manual present and substantive (>=60 lines): docs/$lang/$doc_rel"
        else
            fail "Missing or stub manual (<60 lines): docs/$lang/$doc_rel"
        fi
    done
done

echo ""
echo "=============================================================================="
printf "Summary: %d passed, %d failed\n" "$PASS_COUNT" "$FAIL_COUNT"
echo "=============================================================================="

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
