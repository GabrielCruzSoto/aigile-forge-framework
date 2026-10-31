---
name: mobile-native
description: "Pluggable stack profile for Native Mobile applications (Android Kotlin and iOS Swift), enforcing KeyStore/Keychain storage, structured concurrency, offline/retry resilience, and 1:1 parity with Web."
applyTo: "**/*.{kt,swift,xml,plist,pbxproj}"
---

# Stack Profile: Native Mobile (Android Kotlin & iOS Swift)

## 1. Cross-Channel Parity & Server-Owned Domain Rules
- **1:1 Contract & Behavioral Parity**: JSON payload keys, enum fallbacks (`UNKNOWN` tolerance for forward compatibility), validation rules, monetary string/minor-unit representations, and `ERR_*` error code mappings MUST match `contract.md` and `frontend-web` 1:1.
- **Zero Client Domain Arithmetic**: Never calculate fees, pricing, taxes, balances, or business eligibility locally on the device. Display backend-evaluated values and submit user selections with `Idempotency-Key` headers on mutating requests.
- **N / N-1 Store Rollout Safety**: Mobile binaries remain active in the wild across phased store rollouts; parsers must ignore unknown JSON fields (`ignoreUnknownKeys = true` in Kotlinx Serialization) and gracefully handle additive schema evolution.

## 2. Android Native Standards (Kotlin / Jetpack Compose & Views)
- **Architecture**: MVVM / MVI + Clean Architecture separation (`UI` -> `ViewModel` -> `UseCase/Domain` -> `Repository/DataSource`). Never pass Android `Context` or `View` references into `ViewModel` or domain classes.
- **Structured Concurrency**: Use Kotlin Coroutines (`viewModelScope`) with immutable `StateFlow` for UI state and `SharedFlow`/channels for one-off navigation events. Never use `GlobalScope` or block `Dispatchers.Main`.
- **Hardened Storage**: Store access/refresh tokens and sensitive secrets exclusively using encryption backed by **`Android KeyStore`** (e.g., Tink + DataStore or `EncryptedSharedPreferences` where supported). Plaintext `SharedPreferences` or unencrypted SQLite/Room storage for credentials or PII/PHI/PCI is strictly prohibited.

## 3. iOS Native Standards (Swift / SwiftUI & UIKit)
- **Architecture**: MVVM / Clean Architecture using protocol-driven dependency injection for deterministic unit testing.
- **Modern Concurrency & Memory Safety**: Prefer Swift Structured Concurrency (`async`/`await`, `@MainActor` for UI updates, `Task` cancellation on view disappearance). Prevent retain cycles in closures via `[weak self]`.
- **Hardened Storage**: Store credentials, session tokens, and sensitive secrets exclusively in **`Keychain Services`** with appropriate accessibility protection (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`). Storing tokens or sensitive PII/PHI/PCI in **`UserDefaults`**, `Info.plist`, or unencrypted files is strictly prohibited.

## 4. Network Resilience, Privacy & Observability
- Enforce TLS 1.2+/1.3 (`App Transport Security` on iOS; `network_security_config.xml` disabling cleartext traffic in release builds on Android).
- Configure explicit connect/read timeouts, exponential backoff with jitter for transient network failures, offline state awareness, and duplicate-tap / in-flight submission guards.
- Propagate `X-Correlation-Id` on every API call and strip sensitive logs in release builds.

## Gate G3 Profile Checklist
- [ ] Tokens and secrets use `Android KeyStore` (Android) and `Keychain Services` (iOS) — zero sensitive data in `SharedPreferences` or `UserDefaults`.
- [ ] DTO schemas tolerate unknown fields (`N/N-1` safe) and maintain 1:1 behavioral parity with `contract.md` and Web.
- [ ] Structured concurrency (`viewModelScope` / `@MainActor` `Task` cancellation), timeouts, and idempotency keys are verified by unit tests.
