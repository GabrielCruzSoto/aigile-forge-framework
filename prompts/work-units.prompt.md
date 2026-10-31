---
name: work-units
description: Decompose approved spec.md and contract.md into atomic TDD work units (<= 400 LoC) with runnable verification commands.
agent: delivery
---

# Atomic TDD Work-Unit Decomposition (`/work-units`)

Load `agents/delivery.md`, `skills/odd-workflow/SKILL.md`, and `skills/work-unit-tdd/SKILL.md`.

Given Gate `G1`/`G2`-approved `work/<TICKET-ID>/spec.md` and `work/<TICKET-ID>/contract.md`:

1. **Create or Update ODD Feature Document:**
   - Author `odd/tasks/<ticket-id-lower>-<slug>.md` from `templates/odd-task.template.md` preserving verbatim `S#` requirement trace links to `AC-#`.
2. **Partition into Atomic Work Units (`T1`, `T2`, …):**
   - Keep each work unit cohesive, independently verifiable, and within `governance.max_work_unit_loc` (`<= 400` LoC target).
   - Order units strictly from domain/contract tests -> persistence/adapters -> transport/UI -> integration verification.
3. **Define Red-Green-Refactor & Verification Commands:**
   - For every `T#`, specify the exact failing test to write first (RED), the minimal implementation surface, and the foreground test command that proves GREEN.
