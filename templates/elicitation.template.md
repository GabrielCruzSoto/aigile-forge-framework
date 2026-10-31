# Hypothesis Elicitation & PERT Forecast (`elicitation.md`)

- **Ticket ID:** `<TICKET-ID>` (e.g., `PROJ-101`)
- **Authoring Agent:** `pm`
- **Date:** `YYYY-MM-DD`

---

## 1. Domain Hypotheses & Scope Framing
- **Business Goal Hypothesis:** `<What outcome this feature delivers>`
- **Primary Personas & Channels:** `<Roles and web/mobile/API channels touched>`
- **Explicit Out-of-Scope Boundaries:** `<What will NOT be changed in this iteration>`

---

## 2. Prioritized P1 Clarification Questions (`<= 10`)

| # | Blocking Question | Recommended Default Option | Stakeholder Decision |
|---|---|---|---|
| **Q1** | `<Concise functional or edge-case question>` | `<Concrete safe default>` | `[Pending | Accepted Default | Custom: ...]` |
| **Q2** | `<Permission, validation, or failure-mode question>` | `<Concrete safe default>` | `[Pending | Accepted Default | Custom: ...]` |

---

## 3. Optional 3-Point PERT Estimation (`focus_factor = 0.75`)

| Delivery Lane | Optimistic ($O$) | Most Likely ($M$) | Pessimistic ($P$) | Expected Ideal ($E = \frac{O+4M+P}{6}$) | Calendar Days ($E / f$) |
|---|---|---|---|---|---|
| `backend` | `0.5` | `1.0` | `2.0` | `1.08` | `1.44` |
| `frontend` | `0.5` | `1.0` | `1.5` | `1.00` | `1.33` |

- **Risk Buffer (`risk_buffer_days`):** `1.0` day
- **Committed Target Window:** `YYYY-MM-DD`
