# Catálogo de Habilidades (`Skills`) y Perfiles Tecnológicos (`Profiles`)

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/catalog/skills-and-profiles.md`](../../en/catalog/skills-and-profiles.md)

Este manual documenta las **14 habilidades procedimentales de núcleo**, las **5 habilidades opcionales `cortex-ai-*`**, los **7 perfiles tecnológicos enchufables (`profiles/*.md`)** con sus patrones exactos `applyTo`, sus comandos de verificación asociados y el procedimiento paso a paso para extender **`aigile-forge-framework`** con habilidades o perfiles propios de su equipo de desarrollo.

---

## 1. Las 14 Habilidades Procedimentales de Núcleo (`skills/*/SKILL.md`)

Cada habilidad encapsula un procedimiento repetible que los agentes cargan bajo demanda según la fase del ciclo de vida, manteniendo limpio el presupuesto de contexto cuando no se requieren:

| # | Identificador (`name`) | Ruta Canónica | Agente(s) Principal(es) | Fase / Disparador | Propósito y Entregable Clave |
|---|---|---|---|---|---|
| 1 | **`team-onboarding-bootstrap`** | `skills/team-onboarding-bootstrap/SKILL.md` | `onboarding` | Fase 0 (`/init-team`, `./aigile init`) | Ejecuta el relevamiento de 6 dimensiones, parametriza `aff.yaml`, inicializa `knowledge/` y proyecta harnesses. |
| 2 | **`bilingual-elicitation`** | `skills/bilingual-elicitation/SKILL.md` | `pm` | Fase 2 (`/elicit-ticket`) | Formula hipótesis de negocio, redacta hasta 10 preguntas `P1` con opción recomendada en `en`/`es` y estima con PERT. |
| 3 | **`spec-crafting-hydration`** | `skills/spec-crafting-hydration/SKILL.md` | `analyst` | Fase 3 (`/answers-to-spec`) | Transforma respuestas en criterios Gherkin `AC-#` (*Given/When/Then*), corta `slices/*.md` y evalúa la compuerta `G1`. |
| 4 | **`contract-first-design`** | `skills/contract-first-design/SKILL.md` | `architect` | Fase 4 (`/contract-first`) | Define contratos REST/GraphQL/AsyncAPI, códigos de error deterministas, compatibilidad N/N-1 y payloads sintéticos (`G2`). |
| 5 | **`multi-channel-parity`** | `skills/multi-channel-parity/SKILL.md` | `architect`, `qa` | Fase 4 y Fase 6 (`/parity-check`) | Certifica paridad funcional, de validaciones y de errores 1:1 entre Web, Android Kotlin e iOS Swift, sin lógica exclusiva en cliente. |
| 6 | **`odd-workflow`** | `skills/odd-workflow/SKILL.md` | `orchestrator`, `delivery` | Fases 1 y 5 (`/work-units`) | Gobierna Organic Driven Development mediante documentos vivos `odd/tasks/<ticket>-<slug>.md` reanudables en frío. |
| 7 | **`work-unit-tdd`** | `skills/work-unit-tdd/SKILL.md` | `delivery` | Fase 5 (`/work-units`) | Exige ciclo Red-Green-Refactor en unidades `<= 400` líneas, chequeo diferencial de regresión y Conventional Commits sin IA. |
| 8 | **`db-cache-guardrails`** | `skills/db-cache-guardrails/SKILL.md` | `architect`, `delivery`, `security` | Fases 4, 5 y 6 | Impone índices declarados en cada predicado SQL/NoSQL, migraciones reversibles, claves jerárquicas y TTL finito sin PII en caché. |
| 9 | **`adversarial-review-4r`** | `skills/adversarial-review-4r/SKILL.md` | `reviewer` | Fase 6 (`/review-4r`, `/review-refuter`) | Ejecuta la auditoría crítica en **Risk, Requirements, Regression, Resilience** y la segunda pasada de refutación de falsos positivos (`G3`). |
| 10 | **`rdd-receipts`** | `skills/rdd-receipts/SKILL.md` | `qa`, `delivery` | Fases 5, 6 y 7 (`./aigile receipt`) | Genera y verifica recibos JSON firmados con SHA256 vinculados al commit `HEAD` y a la salida exacta de las pruebas (`G3`/`G4`). |
| 11 | **`security-compliance-audit`** | `skills/security-compliance-audit/SKILL.md` | `security` | Transversal / Fase 6 | Audita prevención de secretos, enmascaramiento PII/PHI/PCI, controles OWASP Top 10, llaveros seguros Web/Móvil y CI/CD. |
| 12 | **`incident-rca-debugging`** | `skills/incident-rca-debugging/SKILL.md` | `delivery`, `analyst` | Tickets `H` (Incidentes / Hotfixes) | Guía el análisis de causa raíz con IDs de correlación, descarte de hipótesis, test de reproducción en rojo y postmortem `rca.md`. |
| 13 | **`pull-request-documentation`** | `skills/pull-request-documentation/SKILL.md` | `delivery` (`documenter`) | Fase 7 (Previo a `G4`) | Empaqueta `work/<ID>/pr.md` enlazando especificaciones `S#`/`AC-#`, notas de compatibilidad, dictamen 4R, recibos SHA256 y rollback. |
| 14 | **`knowledge-checkpoint-curation`** | `skills/knowledge-checkpoint-curation/SKILL.md` | `curator`, `orchestrator` | Fase 7 y Pausas de Sesión | Registra puntos de control de reanudación en frío, actualiza ADRs y mapas en `knowledge/` y sincroniza el almacén configurado. |

### Estructura Interna Estándar de Cada `SKILL.md`
Todas las habilidades del catálogo siguen una anatomía homogénea auditada por `./aigile harness check`:
1. **Frontmatter YAML obligatorio:** `name` (en `kebab-case` idéntico al nombre del directorio contenedor) y `description` concisa de disparo.
2. **Propósito y Activación (`Purpose & Activation`):** Señales exactas que indican al agente cuándo cargar el archivo.
3. **Entradas (`Inputs`):** Artefactos previos requeridos (`aff.yaml`, `spec.md`, `contract.md`, diff Git).
4. **Procedimiento Determinista Paso a Paso:** Secuencia numerada de verificaciones y transformaciones.
5. **Salidas y Criterios de Calidad (`Outputs & Guardrails`):** Artefacto final esperado y condiciones de bloqueo.

---

## 2. Las 5 Habilidades Opcionales `cortex-ai-*` (`skills/cortex-ai-*/SKILL.md`)

Estas habilidades permanecen inactivas en modo `zero-mcp` y se activan cuando el equipo configura `harnesses.mode: "mcp"` y `knowledge.mode: "cortex-ai"` en `aff.yaml`:

| # | Identificador (`name`) | Ruta Canónica | Servidores MCP Involucrados | Propósito Operativo |
|---|---|---|---|---|
| 1 | **`cortex-ai-init`** | `skills/cortex-ai-init/SKILL.md` | `google-drive`, `notebooklm`, `engram` | Inicializa la estructura jerárquica de carpetas del proyecto en Google Drive, vincula el cuaderno en NotebookLM y registra el namespace en Engram. |
| 2 | **`cortex-ai-ask`** | `skills/cortex-ai-ask/SKILL.md` | `notebooklm`, `engram`, `codegraph` | Consulta decisiones arquitectónicas previas, reglas de dominio e historial técnico combinando fuentes documentales, memoria de sesiones y grafo AST. |
| 3 | **`cortex-ai-sync`** | `skills/cortex-ai-sync/SKILL.md` | `google-drive`, `notebooklm`, `engram` | Ejecuta escaneo previo de secretos (`./aigile scan`), sube artefactos curados de `knowledge/` a Google Drive y refresca las fuentes en NotebookLM. |
| 4 | **`cortex-ai-onboard`** | `skills/cortex-ai-onboard/SKILL.md` | `notebooklm`, `engram`, `codegraph` | Sintetiza un dossier ejecutivo de contexto para desarrolladores que se integran al equipo o retoman un frente técnico tras varias semanas. |
| 5 | **`cortex-ai-status`** | `skills/cortex-ai-status/SKILL.md` | `google-drive`, `notebooklm`, `engram`, `codegraph` | Audita la salud de conexión de los servidores MCP, la frescura de sincronización y posibles divergencias entre `knowledge/` local y el índice remoto. |

---

## 3. Los 7 Perfiles Tecnológicos Enchufables (`profiles/*.md`)

Active en `aff.yaml -> profiles.enabled` únicamente los perfiles relevantes para su espacio de trabajo. Al ejecutar `./aigile harness sync`, los perfiles habilitados se proyectan en `.github/instructions/<perfil>.instructions.md` con su patrón glob `applyTo`:

### 3.1 `backend-jvm-spring` (`profiles/backend-jvm-spring.md`)
- **Glob `applyTo`:** `**/*.{java,kt,kts,xml,gradle}`
- **Reglas técnicas clave:**
  - Inspección obligatoria de `pom.xml` / `build.gradle(.kts)` para respetar la versión exacta de JDK (`8`, `17`, `21+`) y espacio de nombres Spring Boot (`2.x javax.*` frente a `3.x/4.x jakarta.*`).
  - Inyección por constructor exclusivamente (prohibido `@Autowired` sobre campos); inmutabilidad en DTOs (`record` en Java 17+ o `data class` en Kotlin).
  - Propagación de correlación en MDC (`X-Correlation-Id` / `traceparent`), timeouts explícitos en clientes HTTP, manejo global de errores RFC 7807 (`ProblemDetail`) y límites `@Transactional` fuera de llamadas remotas.
- **Comandos típicos para recibo RDD:** `./mvnw test`, `./mvnw verify`, `./gradlew check`.

### 3.2 `backend-node-ts` (`profiles/backend-node-ts.md`)
- **Glob `applyTo`:** `**/*.{ts,js,mjs,cjs,json}`
- **Reglas técnicas clave:**
  - `"strict": true`, `"noUncheckedIndexedAccess": true` y `"noImplicitOverride": true` en `tsconfig.json`; prohibido `any` sin justificación auditada.
  - Validación de esquemas en tiempo de ejecución en todos los bordes HTTP/colas (Zod, Valibot, TypeBox o `class-validator`).
  - Prohibición de promesas flotantes sin `await`/`.catch`, timeouts con `AbortSignal.timeout(...)` en llamadas salientes y cierre limpio ante `SIGTERM`.
- **Comandos típicos para recibo RDD:** `npm run typecheck && npm test`, `pnpm test --run`.

### 3.3 `backend-python-go` (`profiles/backend-python-go.md`)
- **Glob `applyTo`:** `**/*.{py,go,mod}`
- **Reglas técnicas clave:**
  - **Python (3.10+ / FastAPI / Django):** anotaciones de tipo completas verificadas con `mypy --strict` o `pyright`, validación Pydantic v2, cero llamadas bloqueantes dentro de corrutinas `async def` y pruebas deterministas con `pytest`.
  - **Go:** `context.Context` como primer parámetro en toda operación de E/S, envoltura explícita de errores (`fmt.Errorf("...: %w", err)`), control del ciclo de vida de goroutines y ejecución obligatoria del detector de condiciones de carrera.
- **Comandos típicos para recibo RDD:** `ruff check . && mypy . && pytest -q`, `go vet ./... && go test -race ./...`.

### 3.4 `frontend-web` (`profiles/frontend-web.md`)
- **Glob `applyTo`:** `**/*.{tsx,jsx,ts,html,scss,css,vue}`
- **Reglas técnicas clave:**
  - Separación estricta entre componentes contenedores (estado/datos) y presentacionales puros en Angular, React, Vue o Next.js.
  - Cero lógica de cálculo de precios, elegibilidad o permisos de seguridad confiada exclusivamente al navegador.
  - Cumplimiento de accesibilidad **WCAG 2.1 AA** (HTML semántico, navegación por teclado, estados de foco visibles, etiquetas ARIA) y prevención de XSS (prohibido `innerHTML` / `dangerouslySetInnerHTML` sin sanitizador aprobado).
- **Comandos típicos para recibo RDD:** `npm run lint && npm run test:ci && npm run build`.

### 3.5 `mobile-native` (`profiles/mobile-native.md`)
- **Glob `applyTo`:** `**/*.{kt,swift,xml,plist,pbxproj}`
- **Reglas técnicas clave:**
  - **Android (Kotlin / Compose):** corrutinas estructuradas (`viewModelScope`), estado unidireccional inmutable (`StateFlow`) y credenciales en `Android Keystore` / `EncryptedSharedPreferences`.
  - **iOS (Swift / SwiftUI):** concurrencia estructurada (`async/await`, `@MainActor`), cero desempaquetados forzados (`!`) en rutas productivas y almacenamiento sensible en `Keychain Services`.
  - Tolerancia a nuevos valores de enumeración del servidor (`UNKNOWN`) para compatibilidad N/N-1 y paridad 1:1 frente a `frontend-web`.
- **Comandos típicos para recibo RDD:** `./gradlew testDebugUnitTest`, `swift test` / `xcodebuild test`.

### 3.6 `data-sql-nosql-cache` (`profiles/data-sql-nosql-cache.md`)
- **Glob `applyTo`:** `**/*.{sql,prisma,graphql,yaml,yml,json}`
- **Reglas técnicas clave:**
  - Respeto estricto al dialecto y versión real del motor de base de datos; prohibición de consultas transaccionales sin índice, `SELECT *` y consultas N+1.
  - Migraciones versionadas, idempotentes y reversibles bajo el patrón *expand-and-contract* (cero `DROP COLUMN` destructivo directo en caliente).
  - Claves de caché alineadas a `{namespace}:{domain}:{service}:{entity}:{id}` con `TTL` finito obligatorio y cero PII/PCI/PHI en claro.
- **Comandos típicos para recibo RDD:** validación de migraciones en contenedor efímero + pruebas de repositorio.

### 3.7 `cicd-containers` (`profiles/cicd-containers.md`)
- **Glob `applyTo`:** `**/{Dockerfile*,*pipeline*,*.yml,*.yaml,*.sh,Jenkinsfile}`
- **Reglas técnicas clave:**
  - `Dockerfile` multietapa separando compilación de ejecución mínima, ejecutando siempre con directriz `USER` sin privilegios de `root`.
  - Imágenes base y acciones de CI con versión explícita o digest SHA256 fijado (prohibido `:latest`), cero secretos en capas de imagen (`ARG`/`ENV`) y scripts shell con `set -euo pipefail`.
- **Comandos típicos para recibo RDD:** `bash -n scripts/*.sh`, `hadolint Dockerfile`, `./aigile scan`.

---

## 4. Guía para Crear Habilidades y Perfiles Propios del Equipo

`aigile-forge-framework` permite incorporar convenciones propias de su equipo sin modificar los scripts del núcleo:

### 4.1 Crear una Habilidad Personalizada (`skills/<mi-habilidad>/SKILL.md`)
1. Cree un directorio en `kebab-case`: `mkdir -p skills/mensajeria-kafka-avro`.
2. Redacte `skills/mensajeria-kafka-avro/SKILL.md` garantizando que `name` coincida exactamente con el directorio:
   ```markdown
   ---
   name: mensajeria-kafka-avro
   description: "Reglas de evolucion compatible de esquemas Avro, claves de particion y consumidores idempotentes."
   ---

   # Skill: Mensajería Kafka y Esquemas Avro

   ## Purpose & Activation
   Activar siempre que un cambio cree o modifique topicos Kafka, esquemas .avsc o consumidores...
   ```
3. Ejecute `./aigile harness sync all && ./aigile harness check` para proyectar y validar el esquema automáticamente.

### 4.2 Crear un Perfil Tecnológico Propio (`profiles/<mi-perfil>.md`)
1. Cree `profiles/backend-dotnet-aspnet.md` definiendo `name`, `description` y el patrón `applyTo`:
   ```markdown
   ---
   name: backend-dotnet-aspnet
   description: "Perfil tecnologico para servicios .NET 8 y ASP.NET Core con nullable reference types y CancellationToken."
   applyTo: "**/*.{cs,csproj,sln,json}"
   ---

   # Stack Profile: Backend .NET & ASP.NET Core
   ...
   ```
2. Agregue `"backend-dotnet-aspnet"` a la lista `profiles.enabled` en `aff.yaml`.
3. Ejecute `./aigile harness sync all` para materializar `.github/instructions/backend-dotnet-aspnet.instructions.md` y validarlo con `./aigile harness check`.

### 4.3 Verificación Automática de Habilidades y Perfiles en CI
Para evitar que cambios futuros rompan el encabezado YAML de un `SKILL.md` o dejen desincronizadas las instrucciones de Copilot respecto de `aff.yaml`, incluya en su pipeline de integración continua:

```bash
./aigile harness sync all --copy
./aigile harness check
```
El comando fallará con código `1` si falta `SKILL.md`, si `name` difiere del directorio o si la sintaxis YAML/JSON contiene errores.

