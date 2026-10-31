---
name: parity-check
description: Audit 1:1 behavioral, validation, and error-code parity across Web, Android, and iOS client channels against contract.md.
agent: architect
---

# Multi-Channel 1:1 Parity Audit (`/parity-check`)

Load `agents/architect.md`, `skills/multi-channel-parity/SKILL.md`, and `profiles/mobile-native.md` + `profiles/frontend-web.md` when enabled.

Inspect `work/<TICKET-ID>/spec.md`, `work/<TICKET-ID>/contract.md`, and client slice definitions:

1. **Server-Side Domain Authority:** Verify zero pricing, authorization, eligibility, or core business calculations execute exclusively on Web, Android, or iOS clients.
2. **1:1 Field & Validation Matrix:** Confirm field names, nullability, input constraints, formatting rules, and state transitions match 1:1 across active client channels.
3. **Deterministic Error Mapping:** Verify every backend error code maps to consistent user-facing recovery states across channels.
4. **Secure Client Storage:** Confirm sensitive tokens use `EncryptedSharedPreferences`/Keystore on Android, `Keychain Services` on iOS, and hardened `HttpOnly` / memory-scoped patterns on Web.

Update the parity matrix section in `work/<TICKET-ID>/contract.md` and report any drift blocking Gate `G2` or `G3`.
