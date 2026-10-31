# Human Quality Gate Approval Record (`gate-record.md`)

- **Ticket ID:** `<TICKET-ID>` (e.g., `PROJ-101`)
- **Gate:** `[G1 | G1a | G1b | G2 | G3 | G4]`
- **Timestamp (UTC):** `YYYY-MM-DDTHH:MM:SSZ`
- **Human Approver & Role:** `<Role / Handle>`

---

## 1. Verified Artifacts & Cryptographic Digests

| Gated Artifact | Relative Path | SHA256 Digest / Git Commit | Verification Status |
|---|---|---|---|
| Specification | `work/<TICKET-ID>/spec.md` | `<sha256>` | `[VERIFIED | N/A]` |
| Contract | `work/<TICKET-ID>/contract.md` | `<sha256>` | `[VERIFIED | N/A]` |
| 4R Audit Report | `work/<TICKET-ID>/review-4r.md` | `<sha256>` | `[VERIFIED | N/A]` |
| RDD Receipt | `work/<TICKET-ID>/receipts/<gate>.json` | `<sha256>` | `[VERIFIED | N/A]` |

---

## 2. Non-Negotiable Guardrail Checklist
- [ ] Zero secrets, tokens, PII, PCI, or PHI leaked (`./aigile scan` passed).
- [ ] Database query predicates backed by declared indexes; cache entries enforce finite TTLs (`{namespace}:{domain}:{service}:{entity}:{id}`).
- [ ] Optional 1:1 multi-channel parity verified across active clients (when enabled in `aff.yaml`).
- [ ] Clean-session 4R review + adversarial refutation closed with zero sustained `CRITICAL` or `HIGH` findings (for Gates `G3`/`G4`).
- [ ] SHA256 RDD receipt generated and verified via `./aigile receipt verify` (when `require_sha256_receipt: true`).

---

## 3. Human Sign-Off Decision
- **Decision:** `[APPROVED | REJECTED WITH OBSERVATIONS]`
- **Notes / Conditions:** `<Concise decision notes>`
