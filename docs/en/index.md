# aigile-forge-framework — Documentation Portal

> **Idioma / Language:** English | [Español (`docs/es/index.md`)](../es/index.md)

Welcome to the **`aigile-forge-framework`** documentation portal. aigile-forge-framework unifies multi-harness CLI/IDE engineering (`Claude Code`, `OpenCode`, `Google Antigravity`, `OpenAI Codex`) and declarative IDE governance (`GitHub Copilot`) under a single canonical contract.

---

## Navigation

### 1. Architecture
- **[Universal Architecture & Deterministic Projection](architecture/overview.md)**
  Explains the single-source-of-truth directory layout, `aff.yaml` schema, harness projection mechanics (`./aigile harness`), and `zero-mcp` vs `mcp` operational modes.

### 2. Team & Workspace Guides
- **[Team Onboarding & Workspace Topologies](guides/onboarding-and-topologies.md)**
  Covers interactive and automated initialization (`./aigile init`), choosing between `single-repo`, `worktrees`, and `multi-root` topologies, issue tracker integration, and pluggable knowledge synchronization.
- **[8-Phase Lifecycle, Human Gates (`G1`–`G4`), 4R Review & RDD Receipts](guides/lifecycle-gates-and-4r.md)**
  Details proportional ticket sizing (`S/M/L/H`), the 8-phase delivery flow, clean-session **4R adversarial review** (`Risk, Requirements, Regression, Resilience`), and SHA256-sealed **Receipt-Driven Development (RDD)** verification.

---

## Core Design Principles

1. **Single Canonical Source, Five Harnesses:** Maintain rules, agents, skills, and stack profiles once; project deterministically without drift.
2. **Vendor & Organization Neutrality:** Zero hardcoded company, client, or proprietary workflow dependencies.
3. **Proportional Governance:** Lightweight flow for small fixes (`S`); rigorous contract-first design and multi-stage human gates for complex cross-repository features (`L`/`H`).
4. **Cryptographic Verification Over Claims:** Phase gates require tamper-evident SHA256 execution receipts (`./aigile receipt`) and automated secret scanning (`./aigile scan`).
