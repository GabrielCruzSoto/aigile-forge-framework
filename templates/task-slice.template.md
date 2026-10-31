# Repository Task Slice (`slices/<repo-id>.md`)

- **Ticket ID:** `<TICKET-ID>` (e.g., `PROJ-101`)
- **Repository:** `<repo-id>`
- **Delivery Lane & Stack Profile:** `<lane>` / `<profile-id>`
- **Execution Order:** `[1 - Upstream Producer | 2 - Downstream Consumer]`

---

## 1. Slice Objective & Traceability
- **Covered Acceptance Criteria:** `AC-1`, `AC-2`
- **Governing Contract Section:** `work/<TICKET-ID>/contract.md`

---

## 2. Allowed Edit Surfaces & Guardrails
- **Target Modules / Packages:** `<paths inside repository>`
- **Database / Cache Changes:** `<migrations, declared indexes, finite cache TTLs>`
- **Security Redaction Scope:** `<fields requiring log masking>`

---

## 3. Planned Atomic TDD Work Units (`<= 400` LoC each)

| Unit | `AC-#` | Red Test First | Implementation Summary | Verification Command |
|---|---|---|---|---|
| `T1` | `AC-1` | `<failing unit test>` | `<minimal domain/service logic>` | `<test runner command>` |
| `T2` | `AC-2` | `<failing contract/error test>` | `<transport/adapter handling>` | `<test runner command>` |
