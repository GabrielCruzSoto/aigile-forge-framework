# Team Ways of Working, Branching & Gate Protocol

- **Project:** `{{PROJECT_NAME}}` (`{{PROJECT_ID}}`)
- **Team:** `{{TEAM_NAME}}`
- **Issue Tracker:** `{{TRACKER_PROVIDER}}` (Prefix: `{{TICKET_PREFIX}}`)

---

## 1. Iteration Cadence & Branching Model
- **Cadence:** Sprint / continuous flow cadence configured by the team.
- **Branch Naming:** `feat/<TICKET-ID>-<slug>`, `fix/<TICKET-ID>-<slug>`, `hotfix/<TICKET-ID>-<slug>`.
- **Commit Standard:** Atomic English Conventional Commits (`<= 400` LoC target per work unit), zero AI attribution (`Co-Authored-By` prohibited), zero `git stash` (`./aigile session checkpoint` or worktree commit instead).

---

## 2. Definition of Ready (Gate `G1`)
- [ ] Sanitized `ticket-in.md` and confirmed `elicitation.md` answers (zero open `P1` blockers).
- [ ] `spec.md` completed with numbered *Given / When / Then* acceptance criteria (`AC-#`).
- [ ] Optional PERT estimate and affected repository slices (`slices/*.md`) approved.

---

## 3. Definition of Done (Gates `G2`, `G3`, `G4`)
- [ ] **Gate `G2`:** `contract.md` approved (N/N-1 compatibility, DB indexes, cache TTLs, optional 1:1 channel parity).
- [ ] **Gate `G3`:** Red-Green-Refactor TDD tests green, `./aigile scan` clean, clean-session `review-4r.md` has zero sustained `CRITICAL`/`HIGH` findings, and `G3` SHA256 receipt verified.
- [ ] **Gate `G4`:** Release smoke checks verified, `G4` SHA256 receipt sealed, and `knowledge/` curated.
