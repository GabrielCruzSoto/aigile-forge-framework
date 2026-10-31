# Business Domain Overview & Ubiquitous Glossary

- **Project:** `{{PROJECT_NAME}}` (`{{PROJECT_ID}}`)
- **Namespace:** `{{PROJECT_NAMESPACE}}`
- **Last Updated:** `YYYY-MM-DD`

---

## 1. Domain Mission & Strategic Objectives
- **Problem Statement:** Describe the core user and organizational problem solved by this project.
- **Target Personas:** List primary end-users, operators, and external partner systems.
- **Key Success Metrics:** Latency, conversion, reliability, or operational SLAs.

---

## 2. Bounded Contexts

| Bounded Context | Owning Lane | Core Responsibilities | Data Sensitivity (`public` / `internal` / `pii` / `pci` / `phi`) |
|---|---|---|---|
| `core-domain` | `backend` | Primary business invariants and state transitions | `internal` |
| `experience-portal` | `frontend` | User workflows and contract-driven presentation | `internal` |

---

## 3. Ubiquitous Language Glossary

| Canonical Term | Definition | Prohibited Synonyms / Ambiguities |
|---|---|---|
| `<DomainEntity>` | Exact business meaning across specs, APIs, and code | Avoid overloaded legacy aliases |
