---
name: backend-python-go
description: "Pluggable stack profile for Python (FastAPI, Pydantic, Django) and Go backend services, enforcing strict typing, context cancellation, explicit error wrapping, and deterministic tests."
applyTo: "**/*.{py,go,mod}"
---

# Stack Profile: Backend Python & Go

## 1. Python Standards (Python 3.10+ / FastAPI / Pydantic / Async & Sync)
- **Strict Type Annotations**: Annotate all function signatures, return types, and domain models; keep code clean under `mypy --strict` or `pyright`.
- **Boundary Validation**: Validate inbound payloads, query parameters, and settings (`pydantic-settings`) using **Pydantic v2** (`model_config = ConfigDict(extra="forbid", strict=...)`) aligned with `contract.md`.
- **Async Event Loop Safety**: Never invoke blocking synchronous I/O (`requests`, blocking DB drivers, `time.sleep`) inside `async def` endpoints. Use native async clients (`httpx.AsyncClient` with explicit `httpx.Timeout`, `asyncpg` / async SQLAlchemy) or run unavoidable blocking work in bounded threadpools.
- **Resource Lifecycle**: Manage HTTP clients, DB sessions, and file handles via context managers (`with` / `async with` / FastAPI `lifespan`). Never instantiate a new `httpx.AsyncClient` per request without pooling.

## 2. Go Standards (Go 1.21+ / Idiomatic Service Engineering)
- **Mandatory `context.Context` Propagation**: Accept `ctx context.Context` as the first parameter on every I/O, repository, cache, and outbound RPC function. Derive explicit deadlines (`context.WithTimeout`) for downstream calls and honor `ctx.Done()`. Never store `context.Context` inside a struct.
- **Explicit Error Wrapping & Domain Mapping**: Check every returned `err != nil`, wrap with operational context (`fmt.Errorf("fetch order %s: %w", orderID, err)`), and map domain sentinel/typed errors (`errors.Is` / `errors.As`) to standardized HTTP/gRPC error codes without leaking internal error strings to clients.
- **Bounded Goroutines & Zero Data Races**: Every spawned goroutine MUST have a deterministic termination condition, panic safety where appropriate, and bounded concurrency (`errgroup.WithContext` + `SetLimit`). Never use `http.DefaultClient` (which has zero timeout); configure `http.Client{Timeout: ...}` explicitly.

## 3. Shared Traceability, Security & Error Envelopes
- Extract or generate `X-Correlation-Id` (and `traceparent`) in middleware and attach `correlationId` to structured JSON logs (`structlog` / Python `logging` JSON formatter; Go `log/slog` or `zap`).
- Redact sensitive PII/PHI/PCI fields and authorization headers before logging or returning standardized error envelopes.

## 4. Testing Standards
- **Python**: Deterministic `pytest` + `pytest-asyncio` tests with isolated fixtures, `freezegun`/injected clocks, and synthetic mock payloads (`ID-MOCK-1001`).
- **Go**: Table-driven unit/integration tests executed with `go test -race ./...` to prove race-free concurrency.

## Gate G3 Profile Checklist
- [ ] Python code passes strict type/schema checks with zero blocking calls inside `async def` handlers and explicit `httpx`/DB timeouts.
- [ ] Go code propagates `context.Context` deadlines, wraps errors with `%w`, avoids `http.DefaultClient`, and passes `go test -race`.
- [ ] Standardized error responses include `correlationId` and leak zero stacktraces or raw PII.
