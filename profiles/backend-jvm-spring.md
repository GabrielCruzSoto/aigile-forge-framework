---
name: backend-jvm-spring
description: "Pluggable stack profile for Java and Kotlin backend services using Spring Boot (2.x javax.* and 3.x/4.x jakarta.*), enforcing constructor injection, MDC correlation logging, resilience, and slice testing."
applyTo: "**/*.{java,kt,kts,xml,gradle}"
---

# Stack Profile: Backend JVM & Spring Boot (Java / Kotlin)

## 1. Runtime & Framework Version Awareness
- Inspect `pom.xml`, `build.gradle`, `build.gradle.kts`, and `aff.yaml` (`stack.runtimes`) before writing code to honor the exact target **JDK (`8`, `17`, `21+`)** and **Spring Boot (`2.x` vs `3.x`/`4.x`)** baseline.
- **Strict Namespace Isolation**:
  - Spring Boot `2.x`: use `javax.persistence.*`, `javax.validation.*`, `javax.servlet.*`.
  - Spring Boot `3.x` / `4.x`: use `jakarta.persistence.*`, `jakarta.validation.*`, `jakarta.servlet.*`.
  - Never mix `javax.*` and `jakarta.*` imports in the same module.
- In Kotlin services, enable `-Xjsr305=strict` and `spring`/`jpa` compiler plugins so JPA entities remain open where required while preserving null-safety.

## 2. Architecture & Dependency Injection
- **Constructor Injection Only**: Declare dependencies as `private final` fields (Java) or `private val` constructor parameters (Kotlin). Field injection (`@Autowired` on attributes) is prohibited.
- **Transport vs Domain Separation**: Keep `@RestController` classes thin (request binding, `@Valid` boundary validation, HTTP status mapping). Never leak `HttpServletRequest` or JPA `@Entity` classes directly across public API responses; map explicitly to immutable DTOs (`record` in Java 17+ or `data class` in Kotlin).
- **Explicit API Versioning**: Prefix routes consistently (`/api/v1/...`) aligned with `contract.md`.

## 3. Error Handling & Resilience
- **Global Exception Envelope**: Centralize exception translation in `@RestControllerAdvice`, returning standardized error payloads (`code`, `message`, `correlationId`, `details[]`). Never expose raw JVM stacktraces, SQL state strings, or internal class names to clients.
- **Bounded Outbound I/O**: Configure explicit connect and read timeouts on every `RestClient`, `WebClient`, `RestTemplate`, Feign, or gRPC stub. Pair external dependencies with bounded retries (with jitter) and circuit breakers where appropriate.
- **Transactional Boundaries**: Annotate service-layer write methods with `@Transactional` and read-only queries with `@Transactional(readOnly = true)`. Never perform remote HTTP/RPC calls inside an open database transaction.

## 4. Structured Traceability & Privacy
- Extract or generate `X-Correlation-Id` (and W3C `traceparent` when present) in a servlet filter or reactive context hook and bind it to SLF4J `MDC` (`MDC.put("correlationId", correlationId)`), clearing `MDC` in a `finally` block.
- Emit structured parameterized logs (`log.info("Order created orderId={}", orderId)`). Mask or omit all configured PII/PHI/PCI fields (`aff.yaml` `security.sensitive_fields`).

## 5. Testing Standards
- **Domain Unit Tests**: Fast JUnit 5 + AssertJ/MockK tests without booting the Spring context.
- **Boundary Slice Tests**: `@WebMvcTest` for controller validation/serialization and `@DataJpaTest` / Testcontainers for persistence queries, index usage, and migrations.
- Use deterministic `Clock` injection instead of static `Instant.now()` / `LocalDateTime.now()` calls.

## Gate G3 Profile Checklist
- [ ] Zero `@Autowired` field injection and zero `javax.*` / `jakarta.*` namespace mixing.
- [ ] Outbound clients define explicit connect/read timeouts; no HTTP calls run inside `@Transactional`.
- [ ] `MDC` correlation propagation and `@RestControllerAdvice` error sanitization are verified by tests.
