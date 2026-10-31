---
name: answers-to-spec
description: Hydrate stakeholder answers from elicitation.md into a Gherkin Given/When/Then specification, repository slices, and Gate G1 readiness check.
agent: analyst
---

# Specification Hydration & Slice Cutting (`/answers-to-spec`)

Load `agents/analyst.md`, `aff.yaml`, and `skills/spec-crafting-hydration/SKILL.md`.

Given `work/<TICKET-ID>/elicitation.md` (with stakeholder responses or confirmed defaults):

1. **Author `work/<TICKET-ID>/spec.md` (from `templates/spec.template.md`):**
   - Summarize confirmed business rules and explicit non-goals.
   - Write numbered Gherkin acceptance criteria (`AC-1`, `AC-2`, …) in *Given / When / Then* form covering happy paths, boundary conditions, validation errors, and failure modes.
   - Specify non-functional requirements (security classification, observability, performance, accessibility).
2. **Cut Repository Slices:**
   - For each impacted repository in `aff.yaml`, generate `work/<TICKET-ID>/slices/<repo-id>.md` from `templates/task-slice.template.md` with clear dependency ordering.
3. **Evaluate Gate `G1` (Definition of Ready):**
   - Confirm zero open `P1` blockers remain and prepare `work/<TICKET-ID>/gate-record.md` for human `G1` (or `G1a`/`G1b`) sign-off.
