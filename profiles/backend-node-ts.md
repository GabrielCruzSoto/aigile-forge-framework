---
name: backend-node-ts
description: "Pluggable stack profile for Node.js and TypeScript backend services (NestJS, Fastify, Express, Serverless), enforcing strict typing, runtime schema validation, bounded async I/O, and structured logging."
applyTo: "**/*.{ts,js,mjs,cjs,json}"
---

# Stack Profile: Backend Node.js & TypeScript

## 1. Strict TypeScript & Module Hygiene
- Enforce `"strict": true`, `"noUncheckedIndexedAccess": true`, and `"noImplicitOverride": true` in `tsconfig.json`.
- **Ban `any` and Unsafe Casts**: Use `unknown` at untrusted boundaries and narrow via runtime schema validators or type guards. Avoid `as SomeType` casts on parsed JSON or external payloads.
- Honor the repository's module system (`ESM` vs `CommonJS`) and Node.js LTS engine version declared in `package.json` and `aff.yaml`.

## 2. Runtime Boundary Validation
- TypeScript types disappear at compile time; validate **every** inbound HTTP body, query string, path parameter, webhook payload, queue message, and environment variable (`process.env`) at startup/boundary using deterministic schemas (`Zod`, `TypeBox`, `Valibot`, or `class-validator` with `whitelist: true` and `forbidNonWhitelisted: true`).
- Align request/response schemas 1:1 with `contract.md` and return standardized error envelopes (`code`, `message`, `correlationId`, `details[]`) without leaking `Error.stack` to clients.

## 3. Bounded Async Concurrency & Timeouts
- **No Floating Promises**: Await, return, or explicitly handle every `Promise` (`@typescript-eslint/no-floating-promises`).
- **Mandatory `AbortSignal` Timeouts**: Pass `AbortSignal.timeout(ms)` (or client timeout options) to every `fetch`, `undici`, `axios`, gRPC, or SDK call. Unbounded external waits are prohibited.
- **Controlled Parallelism**: Avoid unbounded `Promise.all(hugeArray.map(...))` over large collections that can exhaust DB pools or downstream rate limits; batch or cap concurrency explicitly.
- **Event Loop Protection**: Never run synchronous filesystem (`fs.readFileSync`), CPU-heavy crypto, or catastrophic backtracking regexes on the hot request path.

## 4. Structured Correlation Logging & Redaction
- Propagate `X-Correlation-Id` across async call chains using `AsyncLocalStorage` (Node `node:async_hooks`) and attach `correlationId` automatically to structured JSON loggers (`pino` or `winston`).
- Configure logger redaction paths (`redact: ['req.headers.authorization', 'req.headers.cookie', ...]`) plus project-configured PII/PHI/PCI fields from `aff.yaml`.

## 5. Graceful Shutdown & Deterministic Testing
- Handle `SIGTERM` and `SIGINT` by draining in-flight HTTP requests and closing database/cache clients cleanly.
- Write deterministic `Vitest` or `Jest` unit and HTTP integration (`supertest` / Fastify `.inject()`) tests using injected clocks, isolated test schemas, and synthetic mock identifiers (`ID-MOCK-1001`).

## Gate G3 Profile Checklist
- [ ] Zero `any` types, zero floating promises, and runtime validation present on all external inputs and `process.env`.
- [ ] Every outbound network call enforces an explicit `AbortSignal` / client timeout.
- [ ] `AsyncLocalStorage` correlation logging and PII/header redaction are active.
