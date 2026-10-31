# Team Onboarding & Workspace Topologies

> **Back to Portal:** [`docs/en/index.md`](../index.md) | **Español:** [`docs/es/guides/onboarding-and-topologies.md`](../../es/guides/onboarding-and-topologies.md)

## 1. Bootstrapping a Team Workspace (`./aigile init`)

AFF supports both interactive wizard onboarding and deterministic non-interactive automation:

```bash
# Interactive wizard (English or Spanish)
./aigile init --lang en

# Non-interactive bootstrap
./aigile init \
  --name order-management \
  --team "Order Fulfillment Team" \
  --topology worktrees \
  --mode zero-mcp \
  --harnesses claude,copilot \
  --tracker jira \
  --prefix ORD \
  --workspace ./order-management \
  --non-interactive
```

During initialization, `./aigile init`:
1. Renders `aff.yaml` from `templates/aff.template.yaml`.
2. Scaffolds `knowledge/{team-roster,domain-overview,architecture-map,team-workflow}.md` if absent.
3. Generates `<project-slug>.code-workspace` when `--topology multi-root` is selected.
4. Configures `.git/info/exclude` for runtime folders (`work/`, `worktrees/`) and optional `--zero-footprint` local mode.
5. Executes `scripts/aff-harness.sh sync` (`--copy` for external workspaces or Windows shells; `--symlink` in-place).

After CLI scaffolding, run the interactive `/init-team` prompt (backed by `agents/onboarding.md` and `skills/team-onboarding-bootstrap/SKILL.md`) inside your AI harness to interview the team and enrich `knowledge/*.md` and `profiles.enabled`.

---

## 2. Choosing a Workspace Topology

| Topology | Recommended Team Context | Directory Mechanics |
|---|---|---|
| **`single-repo`** | Monolith, modular monolith, library, or single microservice | Framework lives directly at the repository root (committed or excluded locally via `--zero-footprint`). |
| **`worktrees`** | High-concurrency teams handling parallel tickets or urgent hotfixes | `./aigile worktree create <TICKET-ID>` provisions isolated branches under `worktrees/<TICKET-ID>/` without `git stash`. |
| **`multi-root`** | Distributed architecture spanning API contracts, backend, web, and mobile repos | Hub directory holds `aff.yaml`, `knowledge/`, `work/`, and `<project-slug>.code-workspace` linking sibling or nested repositories. |

---

## 3. Issue Tracker & Estimation Adaptation

Configure `tracker.provider` (`jira`, `linear`, `github`, `gitlab`, `azure-devops`, `monday`, or `markdown`) and `tracker.ticket_prefix` in `aff.yaml`. Ticket intake (`work/<TICKET-ID>/ticket-in.md`) and status reporting (`work/<TICKET-ID>/ticket-out.md`) remain Markdown-native and tracker-agnostic.

Teams using **3-point PERT estimation** configure `estimation.focus_factor` (e.g., `0.75`) and `estimation.risk_buffer_days` in `aff.yaml`:

$$E = \frac{O + 4M + P}{6}, \qquad \text{Adjusted Effort} = \frac{E}{\text{focus\_factor}}$$

---

## 4. Knowledge Synchronization (`./aigile sync`)

- **`local`:** Keeps `knowledge/` inside the workspace filesystem.
- **`folder-sync`:** Mirrors sanitized `knowledge/` documents to any shared or cloud-mounted directory (`./aigile sync --sync --dest /mnt/shared/team-docs`), running `./aigile scan` prior to transfer.
- **`cortex-ai`:** Connects `knowledge/` and session journals to MCP-backed persistent memory and document stores when `harnesses.mode: "mcp"`.
