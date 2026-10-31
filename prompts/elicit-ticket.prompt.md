---
name: elicit-ticket
description: Formulate domain hypotheses, up to 10 P1 clarification questions with recommended defaults, and an optional 3-point PERT estimate.
agent: pm
---

# Hypothesis Elicitation & PERT Estimation (`/elicit-ticket`)

Load `agents/pm.md`, `aff.yaml`, and `skills/bilingual-elicitation/SKILL.md`.

Using `work/<TICKET-ID>/ticket-in.md` and `knowledge/domain/overview.md`:

1. **Formulate Domain Hypotheses:**
   - State the core business goal, affected user personas, bounded contexts, and explicit out-of-scope boundaries.
2. **Generate Up to 10 P1 Clarification Questions:**
   - Focus strictly on blocking unknowns (edge cases, permissions, error handling, data retention, channel behavior).
   - Provide a concrete **Recommended Default Option** for every question.
   - Format in the team's configured artifact language (`aff.yaml -> team.language.artifacts`, or bilingual `EN/ES` when requested).
3. **Compute Optional 3-Point PERT Forecast (when `estimation.method: "pert"`):**
   - Estimate Optimistic ($O$), Most Likely ($M$), and Pessimistic ($P$) ideal days per lane.
   - Compute expected effort $E = (O + 4M + P) / 6$, apply `estimation.focus_factor`, and add `estimation.risk_buffer_days`.

Write the result to `work/<TICKET-ID>/elicitation.md` using `templates/elicitation.template.md`.
