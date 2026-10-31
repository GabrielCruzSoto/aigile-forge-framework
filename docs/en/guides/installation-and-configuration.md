# Installation & Configuration Manual (`aff.yaml` v1.0)

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/guides/installation-and-configuration.md`](../../es/guides/installation-and-configuration.md)  
> **Related Manuals:** [Architecture Overview](../architecture/overview.md) · [Onboarding & Topologies](onboarding-and-topologies.md) · [Harness Compatibility Matrix](../harnesses/compatibility-matrix.md)

This manual provides end-to-end instructions for installing **`aigile-forge-framework`** across major operating systems, deploying it into standalone, existing, or multi-repository workspaces, and configuring every field of the canonical `aff.yaml` (Schema v1.0) manifest.

---

## 1. Operating System Prerequisites & Runtime Setup

`aigile-forge-framework` intentionally keeps runtime dependencies minimal so it runs identically on developer workstations, locked-down corporate laptops, and CI containers.

### Required & Optional Runtimes

| Dependency | Requirement | Purpose |
|---|---|---|
| **`bash`** (`>= 4.x`, `3.2+` compatible) | **Required** | Executes `./aigile` and `scripts/aff-*.sh`. |
| **`git`** (`>= 2.25+`) | **Required** | Branching, `.git/info/exclude`, staged diff secret scanning, and `git worktree` isolation. |
| **`python3`** (`>= 3.8+`) | **Required** | Renders manifests/workspaces, projects harness schemas, computes canonical SHA256 receipts, and runs high-speed regex secret scans (`PyYAML` optional; pure-Python fallback included). |
| **`jq`** (`>= 1.6+`) | Optional | Secondary JSON utility recognized by `./aigile doctor`. |
| **`sha256sum` / `shasum`** | Optional | Digest utility (`aff-receipt.sh` automatically falls back to Python `hashlib` if absent). |
| **`rsync`** | Optional | Incremental directory mirroring for `folder-sync` mode (falls back to `cp -R`). |

### Platform-Specific Setup

- **Linux (Ubuntu/Debian/Fedora/Arch):**
  ```bash
  # Ubuntu / Debian
  sudo apt-get update && sudo apt-get install -y bash git python3 python3-yaml rsync
  ```
- **macOS (Apple Silicon & Intel):**
  ```bash
  xcode-select --install   # Provides git and python3
  brew install bash jq     # Optional modern bash & jq
  ```
- **Windows via WSL2 (Recommended on Windows):**
  Install Ubuntu inside WSL2 and keep your repositories inside the Linux filesystem (`~/workspaces/...`) rather than `/mnt/c/` for fast `git worktree` and symlink performance.
- **Windows via Git-Bash / MSYS2:**
  Install [Git for Windows](https://gitforwindows.org/) and Python 3 (`python3` in `PATH`). `./aigile init` automatically detects `MINGW*`/`MSYS*`/`CYGWIN*` via `uname -s` and switches skill projection from `--symlink` to `--copy` so Windows Developer Mode privileges are not required.

---

## 2. Installation Patterns

First, clone `aigile-forge-framework` to a local tools directory:

```bash
git clone <repository-url> ~/tools/aigile-forge-framework
cd ~/tools/aigile-forge-framework
chmod +x ./aigile scripts/*.sh
```

### Pattern A: Standalone Repository (In-Place)
Use `aigile-forge-framework` directly as the root of a brand-new project:
```bash
./aigile init --name core-service --team "Backend Platform Team" --topology worktrees --symlink
```
When initialized in-place on Linux/macOS/WSL, `--symlink` links `.claude/skills`, `.agents/skills`, and `.github/skills` directly to `../skills`.

### Pattern B: Installing Into an Existing Project Repository (`--copy` & `--zero-footprint`)
Project `aigile-forge-framework` into an existing application repository without altering tracked Git history for teammates:
```bash
~/tools/aigile-forge-framework/aigile init \
  --name checkout-api \
  --team "Checkout Engineering" \
  --topology single-repo \
  --mode zero-mcp \
  --workspace ~/projects/checkout-api \
  --zero-footprint \
  --copy \
  --non-interactive
```
- **External workspace behavior:** Because `--workspace` points outside the framework clone, `./aigile init` copies `agents/`, `skills/`, `profiles/`, `prompts/`, `templates/`, `mcp/`, `configs/`, `scripts/`, `AGENTS.md`, and `./aigile` into `~/projects/checkout-api` so the target workspace operates standalone, using `--copy` automatically.
- **`--zero-footprint`:** Appends `aff.yaml`, `CLAUDE.md`, `.claude/`, `.mcp.json`, `opencode.json`, `.agents/`, `.opencode/`, and `.github/{copilot-instructions.md,instructions/,agents/,prompts/,skills/}` (alongside `work/` and `worktrees/`) to `.git/info/exclude`.

### Pattern C: Multi-Repository Governance Hub (`multi-root`)
Create a dedicated governance hub folder that orchestrates multiple microservice, web, and mobile repositories:
```bash
~/tools/aigile-forge-framework/aigile init \
  --name omnichannel-suite \
  --team "Omnichannel Product Team" \
  --topology multi-root \
  --mode zero-mcp \
  --tracker jira \
  --prefix OMNI \
  --workspace ~/workspaces/omnichannel-suite \
  --non-interactive
```
This scaffolds `~/workspaces/omnichannel-suite/omnichannel-suite.code-workspace`, `knowledge/*.md`, and `repositories/`, keeping all AI harness definitions inside the hub and out of child microservice Git histories.

---

## 3. Complete `aff.yaml` v1.0 Field-by-Field Reference

`aff.yaml` is the single declarative configuration manifest at the workspace root. Whenever you modify `aff.yaml`, re-run `./aigile harness sync all` to propagate updates across all enabled harnesses.

### 3.1 `schema_version`, `project`, `team`, and `workspace`

```yaml
schema_version: "1.0"

project:
  id: "billing-platform"                # Kebab-case slug; names <id>.code-workspace in multi-root
  name: "Billing & Invoicing Platform"  # Human-readable title injected into Copilot instructions & docs
  namespace: "billing"                  # Prefix token used in cache_key_pattern ({namespace}:...)

team:
  name: "Revenue Core Team"             # Team display name across generated artifacts
  lead_role: "Technical Lead"           # Primary technical sign-off role for Gate G1 / G1a / G2
  language:
    conversation: "en"                  # Allowed: "en" | "es" (direct chat / elicitation language)
    artifacts: "en"                     # Allowed: "en" | "es" (language for spec.md, contract.md, ADRs)

workspace:
  topology: "worktrees"                 # Allowed: "single-repo" | "worktrees" | "multi-root"
  hub_name: "00-billing-platform-hub"   # Display root name inside multi-root .code-workspace
```

### 3.2 `harnesses`, `tracker`, and `knowledge`

```yaml
harnesses:
  mode: "zero-mcp"                      # Allowed: "zero-mcp" (default, 100% file-based) | "mcp"
  enabled:                              # Subset or all 5 supported harnesses:
    - "claude"                          #   Claude Code (CLAUDE.md, .claude/, .mcp.json*)
    - "opencode"                        #   OpenCode (AGENTS.md, opencode.json, .opencode/, .agents/)
    - "antigravity"                     #   Google Antigravity (AGENTS.md, .agents/, mcp_config.json*)
    - "codex"                           #   OpenAI Codex (AGENTS.md, .agents/)
    - "copilot"                         #   GitHub Copilot (.github/copilot-instructions.md, etc.)

tracker:
  provider: "linear"                    # Allowed: jira | linear | github | gitlab | azure-devops | monday | markdown
  ticket_prefix: "BILL"                 # Ticket ID prefix (e.g., BILL-101)

knowledge:
  mode: "local"                         # Allowed: local | git | folder-sync | cloud-folder | cortex-ai
  sync_path: ""                         # Target path when mode is folder-sync / cloud-folder
  cortex:                               # Used only when harnesses.mode == "mcp" and knowledge.mode == "cortex-ai"
    drive_root_folder_id: "${DRIVE_ROOT_FOLDER_ID}"
    notebook_id: "${NOTEBOOKLM_NOTEBOOK_ID}"
    engram_project: "billing-platform"
```

### 3.3 `governance` and `estimation`

```yaml
governance:
  phases: 8                             # Canonical 8-phase lifecycle (Phases 0..7)
  gates:                                # Active human verification gates
    - "G1"
    - "G2"
    - "G3"
    - "G4"
  dual_po_approval: false               # If true, splits Gate G1 into G1a (Tech Lead) + G1b (Product Owner)
  max_work_unit_loc: 400                # Maximum target LoC per atomic TDD work unit
  require_4r_review: true               # Enforces clean-session two-pass 4R review before Gate G3
  require_sha256_receipt: true          # Requires ./aigile receipt JSON proof for gate transitions
  multi_channel_parity: false           # Set true to enforce 1:1 Web + Android + iOS parity at Gate G2/G3

estimation:
  method: "pert"                        # Allowed: "pert" | "story-points" | "none"
  focus_factor: 0.75                    # Productive engineering capacity ratio (0.0 < focus_factor <= 1.0)
  risk_buffer_days: 1.0                 # Explicit schedule contingency added for L / cross-repo tickets
```

### 3.4 `profiles`, `lanes`, `repositories`, and `guardrails`

```yaml
profiles:
  enabled:                              # Projected to .github/instructions/*.instructions.md
    - "backend-jvm-spring"              #   Java/Kotlin & Spring Boot
    - "backend-node-ts"                 #   Node.js & strict TypeScript
    - "backend-python-go"               #   Python (FastAPI/Django) & Go
    - "frontend-web"                    #   Angular, React, Vue, Next.js
    - "mobile-native"                   #   Android (Kotlin) & iOS (Swift)
    - "data-sql-nosql-cache"            #   SQL/NoSQL indexing, migrations & cache TTLs
    - "cicd-containers"                 #   Rootless Docker & CI/CD pipelines

lanes:                                  # Optional delivery streams within the team
  - id: "core-api"
    description: "Backend ledger and invoicing APIs"
  - id: "client-experience"
    description: "Web portal and mobile apps"

repositories:                           # Registered repositories for multi-root / worktrees topologies
  - name: "billing-api"
    path: "repositories/billing-api"
    profile: "backend-jvm-spring"
  - name: "billing-web"
    path: "repositories/billing-web"
    profile: "frontend-web"

guardrails:
  redact_patterns:                      # Active data classification scopes audited by security & scanner
    - "secrets"
    - "pii"
    - "pci"
    - "phi"
  require_db_indexes: true              # Bans unindexed transactional query predicates
  require_cache_ttl: true               # Bans unbounded/infinite cache entries
  cache_key_pattern: "{namespace}:{domain}:{service}:{entity}:{id}"
  ban_git_stash: true                   # Enforces ./aigile worktree + ./aigile session over git stash
```

---

## 4. Environment Variables Reference

`aigile-forge-framework` honors environment variables for workspace resolution, folder synchronization, and parameterized MCP server fragments (`mcp/*.json`):

| Variable | Scope | Description |
|---|---|---|
| `AFF_WORKSPACE_DIR` | Core CLI (`./aigile`, `scripts/aff-*.sh`) | Overrides the active workspace root directory when invoking commands from outside the workspace. |
| `AFF_KNOWLEDGE_SYNC_DEST` | `aff-knowledge-sync.sh` | Overrides `knowledge.sync_path` destination directory in `folder-sync` mode. |
| `ENGRAM_BIN` | `mcp/engram.json` | Path to the `engram` executable (defaults to `engram`). |
| `ENGRAM_PROJECT` | `mcp/engram.json` | Canonical project identifier bound to Engram persistent memory. |
| `ENGRAM_DATA_DIR` | `mcp/engram.json` | Custom storage path for Engram SQLite/JSONL data. |
| `CODEGRAPH_BIN` | `mcp/codegraph.json` | Path to the `codegraph` binary (defaults to `codegraph`). |
| `CODEGRAPH_WORKSPACE` | `mcp/codegraph.json` | Target source directory indexed by CodeGraph AST server. |
| `GOOGLE_DRIVE_OAUTH_CREDENTIALS` | `mcp/google-drive.json` | Local filesystem path to Google OAuth client credentials JSON (never committed). |
| `DRIVE_ROOT_FOLDER_ID` | `aff.yaml` & `mcp/google-drive.json` | Root Google Drive folder identifier for `cortex-ai` synchronization. |
| `NOTEBOOKLM_MCP_BIN` | `mcp/notebooklm.json` | Path to the `notebooklm-mcp` binary (defaults to `notebooklm-mcp`). |
| `NOTEBOOKLM_NOTEBOOK_ID` | `aff.yaml` & `mcp/notebooklm.json` | Target NotebookLM notebook identifier for grounded semantic queries. |
| `NOTEBOOKLM_AUTH_PROFILE` | `mcp/notebooklm.json` | Named authentication profile for `notebooklm-mcp`. |

---

## 5. Pre-Commit Hook Installation & Diagnostics Troubleshooting

### Installing the Automated Pre-Commit Secret Scanner
Install the local Git `pre-commit` hook inside every Git repository you work on:

```bash
./aigile scan --install-hook
# Or target a specific child repository in a multi-root workspace:
./aigile scan --install-hook --target-dir repositories/billing-api
```
Once installed at `.git/hooks/pre-commit`, every `git commit` inspects staged additions (`git diff --cached`) and blocks private keys, AWS/GitHub/Google/Slack tokens, hardcoded secrets, and unmasked 16-digit payment card numbers before a commit is created.

### Troubleshooting with `./aigile doctor` and `./aigile harness check`

Run both diagnostic commands whenever onboarding a machine or modifying `aff.yaml`:

```bash
./aigile doctor
./aigile harness check
```

| Symptom / Error Message | Root Cause | Resolution |
|---|---|---|
| `[FAIL] Neither python3 nor jq is available` | Missing Python 3 runtime in `PATH`. | Install Python 3.8+ and verify `python3 --version`. |
| `[FAIL] aff.yaml missing at ...` | Command executed in an uninitialized folder. | Run `./aigile init` or set `export AFF_WORKSPACE_DIR=/path/to/workspace`. |
| `.mcp.json must not exist when harnesses.mode is 'zero-mcp'` | Workspace switched from `mcp` to `zero-mcp` in `aff.yaml` without re-syncing. | Run `./aigile harness sync all --mode zero-mcp` to purge stale MCP descriptors. |
| `skills/<slug>/SKILL.md: frontmatter name != directory` | Custom skill folder name does not match its YAML `name:` field. | Align the `name:` key in `skills/<slug>/SKILL.md` with `<slug>` (`^[a-z0-9]+(?:-[a-z0-9]+)*$`). |
| Symlink creation error on Windows | Running `--symlink` in Windows Git-Bash without Developer Mode. | Re-run `./aigile harness sync all --copy`. |
