---
name: multi-channel-parity
description: "1:1 behavioral, validation, contract, and error-handling parity audit across Web and Native Mobile (Android Kotlin and iOS Swift) channels."
---

# Skill: Multi-Channel Parity Audit (Web, Android, iOS)

## Purpose & Activation

Activate whenever `aff.yaml` sets `channels.parity_required: true` or a feature spans Web Frontend (`frontend-web`) and Native Mobile (`mobile-native` — Android Kotlin and/or iOS Swift). Prevents behavioral divergence, mismatched validation limits, inconsistent error handling, and duplicated client-side business logic.

## Inputs

- Approved `spec.md` and `contract.md` for `<TICKET-ID>` (e.g., `PROJ-101`).
- Implementation diffs or source modules across Web (Angular/React/Vue), Android (Kotlin), iOS (Swift), and Backend API layers.

## 5-Pillar Parity Audit Protocol

### 1. Server-Owned Domain Logic (Zero Client Formula Drift)
- Verify that pricing, fee calculations, quotas, state eligibility, and permission rules execute **exclusively on the backend**.
- Clients render server-provided amounts, state flags, and action availability without re-implementing domain arithmetic in TypeScript, Kotlin, or Swift.

### 2. DTO Field, Type & Nullability Alignment
- Compare serialized JSON property names, date/time ISO-8601 UTC formats, decimal representations (string or minor-unit integer to avoid IEEE-754 floating-point drift), and optionality across:
  - Backend DTOs / OpenAPI schema
  - Web TypeScript interfaces / Zod schemas
  - Android Kotlin `@Serializable` / Moshi / Gson data classes
  - iOS Swift `Codable` structs

### 3. Input Validation & Constraint Symmetry
- Ensure pre-submission UX guardrails match identically across channels and align with backend constraints:
  - Field min/max lengths and regex patterns
  - Allowed file types and upload size limits
  - Debounce, double-tap / double-click prevention, and disabled submit states while requests are in flight

### 4. Error Catalog & Resilience Symmetry
- Confirm every documented backend error code (`ERR_*`) maps to equivalent user-safe recovery messaging across Web, Android, and iOS.
- Verify offline/poor-network behavior, retry backoff, and idempotency key reuse on mobile transitions match backend idempotency guarantees.

### 5. Security & Storage Equivalence
- Verify session/token storage uses each platform's hardened mechanism rather than insecure convenience APIs:
  - **Web**: `HttpOnly; Secure; SameSite` cookies or short-lived memory tokens (never sensitive tokens in `localStorage`).
  - **Android**: `Android KeyStore` backed encrypted storage.
  - **iOS**: `Keychain Services` (never `UserDefaults` for credentials or tokens).

## Step-by-Step Execution

1. Build a **Cross-Channel Parity Matrix** mapping each `S#` acceptance scenario across `Backend | Web | Android | iOS`.
2. Flag any intentional platform-specific UX adaptation (e.g., native biometric prompt vs WebAuthn) explicitly in `spec.md` so intentional differences are distinguished from accidental drift.
3. Inspect unit/UI tests in each active channel repository to confirm equivalent happy-path and negative-path assertions exist.

## Hard Rules & Guardrails

- Never ship a backend contract change that breaks N-1 mobile app versions still active in app stores.
- Never represent monetary amounts as binary `float`/`double` in client DTOs; use integer minor units or exact decimal strings as specified in `contract.md`.
- Any unapproved behavioral discrepancy between Web, Android, and iOS is classified as at least `HIGH` severity during Gate `G3` review.

## Outputs

- Cross-Channel Parity Matrix attached to `contract.md` or `review.md`.
- Verified parity findings or remediation tasks per channel repository.

## Verification Checklist

- [ ] DTO field names, types, monetary precision, and nullability match `contract.md` 1:1 across Web, Android, and iOS.
- [ ] Zero core business calculations are duplicated in client code.
- [ ] Validation boundaries and error-code mappings behave consistently on every active channel.
