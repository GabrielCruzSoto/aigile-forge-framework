---
name: review-refuter
description: Execute Pass 2 adversarial refutation to challenge Pass 1 4R findings against codebase evidence and issue the final Gate G3 verdict.
agent: reviewer
---

# Adversarial False-Positive Refutation — Pass 2 (`/review-refuter`)

Load `agents/reviewer.md` and `skills/adversarial-review-4r/SKILL.md`.

Given Pass 1 findings in `work/<TICKET-ID>/review-4r.md`:

1. **Challenge Every Candidate Finding:**
   - Inspect surrounding modules, global exception handlers, middleware, authentication filters, migration indexes, configuration defaults, and test suites for existing mitigations.
2. **Classify with Hard Repository Proof:**
   - Mark `REFUTED (CLOSED)` **only** when concrete codebase evidence (`file:line`) proves the risk or gap is already mitigated.
   - Mark `SUSTAINED (ACTION REQUIRED)` when the defect remains reproducible or unmitigated.
3. **Issue Gate `G3` Verdict:**
   - `APPROVED FOR GATE G3` if and only if sustained `CRITICAL` count == `0` and sustained `HIGH` count == `0`.
   - `BLOCKED` otherwise, listing exact remediation steps per sustained finding.

Update `work/<TICKET-ID>/review-4r.md` with Pass 2 evidence and the final Gate `G3` verdict.
