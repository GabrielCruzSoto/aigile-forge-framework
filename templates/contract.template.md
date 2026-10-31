# Interface, Persistence & Parity Contract (`contract.md`)

- **Ticket ID:** `<TICKET-ID>` (e.g., `PROJ-101`)
- **Gate Status:** `[Draft | Ready for Gate G2 | Approved Gate G2]`
- **Backwards Compatibility:** `[Additive N/N-1 Safe | Expand-and-Contract Migration Required]`

---

## 1. API / Event Interface Specification
- **Method & Path / Topic:** `POST /api/v1/<resource>`
- **Required Headers:** `Authorization`, `X-Correlation-Id`, `Idempotency-Key`

### Synthetic Request Payload
```json
{
  "resourceId": "<REDACTED:id>",
  "amountMinor": 1500,
  "currency": "USD"
}
```

### Synthetic Response & Error Taxonomy

| HTTP Status | Error Code | Trigger Condition | Client Recovery Behavior |
|---|---|---|---|
| `200 / 201` | — | Valid request processed | Render updated state |
| `400` | `ERR_VALIDATION_FAILED` | Schema or business rule violation | Highlight invalid field |
| `409` | `ERR_IDEMPOTENCY_CONFLICT` | Duplicate concurrent mutation | Safely reconcile status |

---

## 2. Database Index & Cache TTL Guardrails

| Store | Collection / Table / Key Pattern | Predicate / Key Structure | Index / Finite TTL |
|---|---|---|---|
| Primary DB | `orders` | `(tenant_id, status, created_at)` | `idx_orders_tenant_status_created` |
| Cache | `{namespace}:{domain}:{service}:{entity}:{id}` | Sanitized read projection (zero PII/PCI/PHI) | `TTL = 300s` |

---

## 3. Multi-Channel 1:1 Parity Matrix (When Applicable)

| Rule / Field | Backend Authority | Web Client | Android Native | iOS Native |
|---|---|---|---|---|
| Validation & Calculations | Authoritative | Contract-driven | Contract-driven | Contract-driven |
| Token Storage | — | `HttpOnly` / memory | `EncryptedSharedPreferences` | `Keychain Services` |
