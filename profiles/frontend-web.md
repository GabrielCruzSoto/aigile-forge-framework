---
name: frontend-web
description: "Pluggable stack profile for Web Frontend applications (Angular, React, Vue, Next.js), enforcing container-presentational boundaries, typed contract consumption, WCAG accessibility, and zero domain logic duplication."
applyTo: "**/*.{tsx,jsx,ts,html,scss,css,vue}"
---

# Stack Profile: Web Frontend (Angular / React / Vue)

## 1. Component Architecture & Strict Typing
- **Strict TypeScript**: Enable `"strict": true`; ban `any` in props, component state, store slices, and API services.
- **Container vs Presentational Separation**:
  - **Container / Feature Components**: Coordinate route state, data fetching/caching hooks or services, and user action dispatch.
  - **Presentational / UI Components**: Pure, reusable components driven strictly by typed inputs/props and emitted events/callbacks, with zero direct HTTP client dependencies (`ChangeDetectionStrategy.OnPush` / Signals in Angular; memoized/pure composition in React; typed `defineProps`/`defineEmits` in Vue).
- **Subscription & Effect Hygiene**: Clean up subscriptions, timers, and `AbortController` requests on unmount (`takeUntilDestroyed` / `async` pipe in Angular; effect cleanup / TanStack Query cancellation in React; `onScopeDispose` in Vue).

## 2. Contract-Driven Integration & Zero Domain Calculation
- **Typed Contract Clients**: Consume backend endpoints exclusively through typed client interfaces generated or mapped 1:1 from `contract.md`. During parallel delivery after Gate `G2`, wire clients against synthetic mock fixtures (`ID-MOCK-1001`) without blocking on backend deployment.
- **Zero Client Business Formula Drift**: Never duplicate pricing, tax, fee, balance, eligibility, or authorization calculations in browser code. Render backend-computed values and enforce only UX-level input validation matching `contract.md` constraints.
- **Explicit UI States**: Every asynchronous view must deterministically handle `loading`, `empty`, `success`, and `error` (mapped via standardized backend `ERR_*` codes) plus double-submit protection while mutations are in flight.

## 3. Accessibility (WCAG 2.1 AA) & Performance
- Use semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<form>`, associated `<label>`) before reaching for `aria-*` attributes.
- Ensure complete keyboard navigation, visible `:focus-visible` indicators, accessible error announcements (`aria-live` / `aria-describedby`), and contrast compliance.
- Lazy-load route bundles and heavy assets; avoid layout thrashing and oversized unvirtualized lists.

## 4. Browser Security & Token Hygiene
- **XSS Prevention**: Rely on framework auto-escaping; never bind untrusted strings via `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, or `bypassSecurityTrustHtml` without strict allowlist sanitization (`DOMPurify` / framework sanitizer).
- **Hardened Session Storage**: Prefer `HttpOnly; Secure; SameSite` cookies managed by the backend/BFF or ephemeral in-memory access tokens. Never persist long-lived credentials, refresh tokens, or sensitive PII/PHI/PCI payloads in `localStorage` or `sessionStorage`.
- Forward `X-Correlation-Id` on outbound API calls for end-to-end incident traceability.

## Gate G3 Profile Checklist
- [ ] Presentational components are decoupled from HTTP services, strictly typed, and handle loading/empty/error states.
- [ ] Zero core business calculations are duplicated on the client, and DTOs match `contract.md` 1:1 (including mobile parity when enabled).
- [ ] Semantic WCAG accessibility, XSS sanitization, and zero sensitive data in `localStorage` are verified.
