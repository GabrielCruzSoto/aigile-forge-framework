# Team Onboarding, Workspace Topologies & Estimation Guide

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/guides/onboarding-and-topologies.md`](../../es/guides/onboarding-and-topologies.md)  
> **Related Manuals:** [Installation & Configuration](installation-and-configuration.md) · [Developer Workflow Manual](developer-workflow-manual.md) · [Agents & Prompts Catalog](../catalog/agents-and-prompts.md)

`aigile-forge-framework` adapts to any engineering organization—from a two-person startup building a single service to a distributed enterprise team coordinating backend APIs, web frontends, and native Android/iOS applications. This guide walks through interactive and automated team onboarding, selecting the right workspace topology, integrating your issue tracker, and calibrating 3-point PERT estimation.

---

## 1. Bootstrapping a Team Workspace (`./aigile init`)

Onboarding occurs in two complementary stages: **Stage A (Deterministic CLI Scaffolding)** followed by **Stage B (Interactive 6-Dimension Discovery via `/init-team`)**.

### Stage A.1: Interactive Wizard Mode
Run `./aigile init` from your terminal and choose English (`en`) or Spanish (`es`) prompts:

```bash
./aigile init --lang en
```

The wizard prompts sequentially with sensible defaults for:
1. Project slug (`starter-project` -> normalized kebab-case, e.g., `order-fulfillment`)
2. Development team name (`Core Engineering Team`)
3. Workspace topology (`single-repo` | `worktrees` | `multi-root`)
4. Harness integration mode (`zero-mcp` | `mcp`)
5. Target harnesses (`all` or comma-separated subset such as `claude,copilot`)
6. Issue tracker provider (`jira` | `linear` | `github` | `gitlab` | `azure-devops` | `monday` | `markdown`)
7. Ticket key prefix (`PROJ`)
8. Target workspace directory (`$PWD`)

### Stage A.2: Non-Interactive CI & Team Recipes (`--non-interactive`)

Platform leads can commit reproducible bootstrap commands in internal runbooks:

```bash
# Recipe 1: Multi-root enterprise hub for Jira + Copilot & Claude (Zero-MCP)
./aigile init \
  --name order-fulfillment \
  --team "Order Fulfillment Engineering" \
  --lang en \
  --topology multi-root \
  --mode zero-mcp \
  --harnesses claude,copilot \
  --tracker jira \
  --prefix ORD \
  --workspace ~/workspaces/order-fulfillment \
  --non-interactive

# Recipe 2: Parallel worktree workspace with full MCP / Cortex-AI support
./aigile init \
  --name ledger-core \
  --team "Ledger Core Team" \
  --lang en \
  --topology worktrees \
  --mode mcp \
  --harnesses all \
  --tracker linear \
  --prefix LDG \
  --workspace ~/workspaces/ledger-core \
  --non-interactive
```

What `./aigile init` creates deterministically:
- Renders `aff.yaml` from `templates/aff.template.yaml`.
- Initializes baseline knowledge files if absent: `knowledge/team-roster.md`, `knowledge/domain-overview.md`, `knowledge/architecture-map.md`, and `knowledge/team-workflow.md`.
- Generates `<project-slug>.code-workspace` when `--topology multi-root` is selected.
- Updates `.git/info/exclude` (`work/`, `worktrees/`, plus projected files when `--zero-footprint` is passed).
- Runs `scripts/aff-harness.sh sync` across the selected harnesses.

---

## 2. Running the 6-Dimension `/init-team` Discovery Interview

Once the workspace skeleton exists, open your preferred AI harness and invoke the **`/init-team`** slash prompt (backed by `agents/onboarding.md` and `skills/team-onboarding-bootstrap/SKILL.md`).

The `onboarding` agent conducts a structured, one-dimension-at-a-time interview—never dumping a giant questionnaire—and waits for confirmation after each step:

| Dimension | Discovery Questions Covered | Files Updated / Hydrated |
|---|---|---|
| **1. Project & Workspace Identity** | Project ID, display name, cache/resource namespace, and confirmation of `single-repo`, `worktrees`, or `multi-root` layout. | `aff.yaml` (`project`, `workspace`) |
| **2. Team Roster & Languages** | Team name, technical lead role, engineering sub-disciplines (Backend, Web, Mobile, QA, DevOps), conversation language (`en`/`es`), and artifact language (`en`/`es`). | `aff.yaml` (`team`), `knowledge/team-roster.md` |
| **3. Compliance, Gates & Guardrails** | Applicable redaction scopes (`secrets`, `pii`, `pci`, `phi`), Gate `G1` single vs dual sign-off (`dual_po_approval: true` -> `G1a`/`G1b`), and 1:1 channel parity (`multi_channel_parity`). | `aff.yaml` (`governance`, `guardrails`) |
| **4. Business Domain & Glossary** | Core capabilities, user personas, bounded contexts, ubiquitous domain terms, and invariants. | `knowledge/domain-overview.md` |
| **5. Architecture, Repos & Stack Profiles** | Service/client repositories, delivery `lanes`, databases, caches, CI/CD runners, and active `profiles.enabled` list. | `aff.yaml` (`profiles`, `lanes`, `repositories`), `knowledge/architecture-map.md` |
| **6. Ways of Working, Tracker & Mode** | Tracker workflow (`jira`, `linear`, `github`, etc.), PERT focus factor & risk buffer, branching rules, and `zero-mcp` vs `mcp`/`cortex-ai` sync. | `aff.yaml` (`tracker`, `estimation`, `knowledge`), `knowledge/team-workflow.md` |

After Dimension 6, re-run `./aigile harness sync all && ./aigile doctor` to compile the enriched manifest into all enabled harnesses.

---

## 3. Workspace Topologies: Decision Matrix & Directory Trees

Choose the topology that matches your repository boundaries and concurrency needs:

| Criterion | `single-repo` | `worktrees` *(Default)* | `multi-root` |
|---|---|---|---|
| **Best For** | Monolith, modular monolith, SDK, or single service | Engineers handling parallel features, reviews, and urgent hotfixes | Distributed systems spanning backend, web, mobile, and contract repos |
| **Parallel Tickets Without `git stash`** | Manual branch switching | Native (`./aigile worktree create <ID>`) | Native when combined with `worktrees/` or per-repo branches |
| **Governance Footprint in App Repos** | Tracked in repo or hidden via `--zero-footprint` | `work/` & `worktrees/` auto-excluded via `.git/info/exclude` | **Zero** footprint inside child repos under `repositories/` |
| **VS Code Multi-Root File** | Not required | Optional | Auto-generated `<project-id>.code-workspace` |

### Topology Directory Trees

```text
# 1. single-repo                         # 2. worktrees
my-service/                              ledger-core/
├── aigile                               ├── aigile
├── aff.yaml                             ├── aff.yaml
├── AGENTS.md                            ├── AGENTS.md
├── src/ & tests/                        ├── knowledge/
├── odd/tasks/                           ├── work/
└── work/             (git-excluded)     │   ├── sessions/
    └── PROJ-101/                        │   └── LDG-101/
                                         └── worktrees/        (git-excluded)
                                             ├── LDG-101/ledger-core/ (feat/LDG-101)
                                             └── LDG-104/ledger-core/ (feat/LDG-104)

# 3. multi-root
order-fulfillment/
├── order-fulfillment.code-workspace     # Opens Hub + all sibling/child repos in VS Code
├── aigile
├── aff.yaml
├── AGENTS.md
├── .github/                             # Copilot hub agents, prompts, instructions & skills
├── knowledge/
├── work/ORD-205/
└── repositories/
    ├── order-api/                       # Independent Git repo (Backend)
    ├── order-web/                       # Independent Git repo (Web Frontend)
    └── order-mobile/                    # Independent Git repo (Android / iOS)
```

---

## 4. Issue Tracker Integration (`ticket-in.md` & `ticket-out.md`)

`aigile-forge-framework` supports seven `tracker.provider` values in `aff.yaml` without requiring external API plugins or webhook tokens in `zero-mcp` mode:

- **`jira`** · **`linear`** · **`github`** · **`gitlab`** · **`azure-devops`** · **`monday`** · **`markdown`**

### Sanitized Markdown Boundary Workflow
1. **Inbound (`work/<TICKET-ID>/ticket-in.md`):** Paste the raw issue description from Jira, Linear, GitHub Issues, GitLab, Azure DevOps, or Monday (using `MND-101` or `PROJ-101` style prefixes), or invoke `/aff-intake`. Any real credentials, customer emails, national IDs, or payment card numbers are immediately replaced with `<REDACTED:token>` or `<REDACTED:pii>` placeholders before an AI model processes downstream steps.
2. **Lifecycle Execution (`work/<TICKET-ID>/state.yaml`):** Tracks `size_class`, current `phase` (`0..7`), gate approvals (`G1`–`G4`), `G1b.tracker_ref` (when `dual_po_approval: true`), and `G3.pr_urls`.
3. **Outbound (`work/<TICKET-ID>/ticket-out.md`):** Rendered from `templates/ticket-out.template.md` with current lifecycle status, gate progress, PERT risk-buffered delivery window, completed milestones, and open blockers—ready to paste directly into a tracker comment or sprint update.

---

## 5. 3-Point PERT Estimation & Focus-Factor Calibration

When `estimation.method: "pert"` is active in `aff.yaml`, the `pm` agent (`/elicit-ticket`) and `analyst` agent (`/answers-to-spec`) produce transparent, defensible effort ranges rather than single-point guesses.

### Canonical Formulas

For each slice or work stream, estimate **Optimistic ($O$)**, **Most Likely ($M$)**, and **Pessimistic ($P$)** ideal engineering days:

$$E = \frac{O + 4M + P}{6}, \qquad \sigma = \frac{P - O}{6}$$

Convert ideal effort $E$ into real calendar effort using the team's `focus_factor` (accounting for ceremonies, code reviews, support rotations, and context switches) and `risk_buffer_days`:

$$\text{Calendar Effort (Days)} = \frac{E}{\text{focus\_factor}} + \text{risk\_buffer\_days}$$

### Calibration Example (`ORD-205` — Multi-Repo Feature `L`)

Suppose `aff.yaml` defines `focus_factor: 0.75` and `risk_buffer_days: 1.0`:
- **Backend API slice:** $O = 1.5$, $M = 2.5$, $P = 4.5 \implies E_{\text{api}} = \frac{1.5 + 10.0 + 4.5}{6} = 2.67\text{ ideal days}$
- **Web Frontend slice:** $O = 1.0$, $M = 2.0$, $P = 3.0 \implies E_{\text{web}} = \frac{1.0 + 8.0 + 3.0}{6} = 2.00\text{ ideal days}$
- **Combined Ideal Effort ($E_{\text{total}}$):** $4.67\text{ ideal days}$
- **Focus-Adjusted Calendar Effort:** $\frac{4.67}{0.75} + 1.0 = 6.23 + 1.0 \approx \mathbf{7.25\text{ working days}}$

### Recommended `focus_factor` Baselines
- **`0.80` – `0.85`:** Dedicated platform or greenfield feature team with minimal production support interruptions.
- **`0.70` – `0.75` *(Default)*:** Standard product engineering team balancing sprint delivery, PR reviews, and routine ceremonies.
- **`0.55` – `0.65`:** Shared-services or rotating on-call team absorbing frequent operational inquiries and incident triage.
