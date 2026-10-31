---
name: security-compliance-audit
description: "Secrets prevention, configurable PII/PHI/PCI masking, OWASP Top 10 controls, hardened Web/Mobile token storage, and CI/CD pipeline security auditing."
---

# Skill: Security & Compliance Audit

## Purpose & Activation

Activate continuously during implementation and explicitly during Phase 6 (`security` agent or `/security-audit`) before Gate `G3` / `G4`. Enforces secret hygiene, configurable regulatory data masking (`pii`, `phi`, `pci`, `sox` in `aff.yaml`), OWASP Top 10 application controls, secure platform token storage, and pipeline isolation.

## Inputs

- Repository diff, configuration manifests, CI/CD workflow files, Dockerfiles, and test fixtures.
- Project compliance profile in `aff.yaml` (`security.compliance`, `security.sensitive_fields`).
- Output of `./aigile secret-scan` (`scripts/aff-secret-scan.sh`).

## 5-Layer Security Audit Protocol

### 1. Zero Embedded Secrets & Synthetic Fixtures
1. Run `./aigile secret-scan` across tracked and staged files before committing or opening a PR.
2. Prohibit hardcoded API keys, JWT signing keys, private PEM blocks, OAuth client secrets, webhook HMAC secrets, or database connection strings containing credentials.
3. Require synthetic mock tokens in tests, specs, and docs (`ID-MOCK-123456`, `PAN-MOCK-XXXX-XXXX-XXXX-1111`, `SECRET-MOCK-PLACEHOLDER`).

### 2. Configurable PII / PHI / PCI Redaction
1. Inspect serializers, structured loggers, audit trails, exception handlers, and analytics events against sensitive fields configured in `aff.yaml` (e.g., national IDs, tax IDs, email/phone, health records, payment card numbers, bank account numbers).
2. Enforce deterministic masking or irreversible hashing in application logs and error responses.
3. Prohibit logging full inbound request bodies or raw `Authorization` / `Cookie` headers.

### 3. OWASP Top 10 Application Defenses
- **Broken Access Control (A01)**: Enforce object-level and tenant-level authorization (`BOLA`/`IDOR` checks) on every read/write resource using authenticated principal claims, never client-supplied role flags.
- **Cryptographic Failures (A02)**: Enforce TLS 1.2+/1.3 in transit, strong password hashing (`Argon2id` / `bcrypt`), and authenticated encryption (`AES-256-GCM`) for sensitive stored fields.
- **Injection & XSS (A03)**: Parameterized queries only, strict boundary schema validation, HTML output encoding/sanitization, and Content Security Policy (`CSP`).
- **SSRF (A10)**: Validate and allowlist outbound URL hosts/schemes whenever fetching user-influenced URLs; block cloud metadata IP ranges (`169.254.169.254`).

### 4. Platform-Hardened Token & Credential Storage
- **Web Browsers**: Store session/refresh credentials in `HttpOnly; Secure; SameSite=Lax|Strict` cookies (with CSRF protection where applicable) or ephemeral in-memory state. Storing sensitive long-lived tokens or PII documents in `localStorage` or `sessionStorage` is prohibited.
- **Android Native**: Store tokens in encrypted storage backed by `Android KeyStore`.
- **iOS Native**: Store tokens in `Keychain Services` with appropriate `kSecAttrAccessible` protection; storing credentials in `UserDefaults` is strictly prohibited.

### 5. Infrastructure & Pipeline Isolation
- Never execute destructive or direct production cluster mutations (`kubectl`, `helm`, `terraform apply`, production DB shells) from developer or agent sessions without explicit human authorization and runbook gates.
- Verify CI/CD workflows inject secrets exclusively from managed vaults/secret stores, pin third-party actions/images, and run containers as non-root users.

## Hard Rules & Guardrails

- Any detected real credential requires **immediate rotation** in addition to git removal; deleting a secret in a follow-up commit does not neutralize exposure.
- Any unmitigated `CRITICAL` or `HIGH` security finding automatically blocks Gate `G3` and Gate `G4`.

## Outputs

- Clean `./aigile secret-scan` execution receipt.
- Security audit section in `work/<TICKET-ID>/review.md` classifying OWASP, privacy, storage, and pipeline checks.

## Verification Checklist

- [ ] `./aigile secret-scan` exits with status `0` across workspace changes.
- [ ] Sensitive domain fields are masked in logs, exceptions, and cache layers.
- [ ] Object-level authorization, parameterized queries, and platform-native token storage are verified.
