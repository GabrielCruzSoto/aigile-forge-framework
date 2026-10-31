# Manual de Instalación y Configuración

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/guides/installation-and-configuration.md`](../../en/guides/installation-and-configuration.md)

Este manual detalla los prerrequisitos de sistema operativo, los escenarios de instalación paso a paso, la referencia completa campo por campo del manifiesto `aff.yaml` (esquema `1.0`), las variables de entorno soportadas, el despliegue del hook de seguridad `pre-commit` y la guía de resolución de problemas mediante `./aigile doctor` y `./aigile harness check`.

---

## 1. Prerrequisitos por Sistema Operativo

`aigile-forge-framework` está construido sobre utilidades estándar para garantizar portabilidad inmediata y cero dependencias de compilación complejas:

| Componente | Requisito Mínimo | Propósito Operativo |
|---|---|---|
| **`bash`** | `>= 4.0` (o Bash 3.2+ en macOS con herramientas POSIX) | Ejecución de `./aigile` y de los scripts deterministas `scripts/aff-*.sh`. |
| **`git`** | `>= 2.25` (con soporte de `git worktree`) | Aislamiento de ramas por ticket, cálculo de diffs para recibos y hook `pre-commit`. |
| **`python3`** | `>= 3.8` (`PyYAML` opcional; incluye analizador nativo de respaldo) | Proyección de manifiestos, validación de esquemas JSON/YAML, escaneo regex y firmas SHA256. |
| **`jq`** | Opcional (`>= 1.6`) | Analizador JSON complementario verificado por `./aigile doctor` si `python3` no estuviera presente. |
| **Utilidad SHA256** | `sha256sum` (Linux), `shasum -a 256` (macOS) o `python3 hashlib` | Sellado criptográfico determinista en `scripts/aff-receipt.sh`. |
| **`rsync`** | Opcional | Sincronización incremental rápida en modo `folder-sync` (usa `cp -R` automáticamente si falta). |

### Notas Específicas por Plataforma

1. **Linux (Debian/Ubuntu, RHEL/Fedora, Arch):**
   ```bash
   sudo apt-get update && sudo apt-get install -y bash git python3 python3-yaml rsync
   ```
   Soporta enlaces simbólicos nativos (`--symlink`) sin privilegios adicionales.

2. **macOS (Intel y Apple Silicon):**
   Incluye `bash`, `git`, `python3` (vía Command Line Tools: `xcode-select --install`) y `shasum` de fábrica. Se recomienda instalar `python3` y `git` actualizados mediante Homebrew (`brew install git python`). Soporta `--symlink` de forma nativa.

3. **Windows con WSL2 (Recomendado en Windows):**
   Ejecute el espacio de trabajo dentro del sistema de archivos Linux de WSL2 (`~/workspaces/...` en lugar de `/mnt/c/...`) para obtener máximo rendimiento de E/S en `git worktree` y soporte completo de `--symlink`.

4. **Windows con Git-Bash / MSYS2:**
   `./aigile` detecta automáticamente `MINGW*` / `MSYS*` / `CYGWIN*` y selecciona por defecto **`--copy`** en lugar de enlaces simbólicos para evitar errores de permisos de administrador (`SeCreateSymbolicLinkPrivilege`) en Windows. Asegúrese de que `python3` esté disponible en el `PATH` de Git-Bash.

---

## 2. Escenarios de Instalación

Primero clone el repositorio fuente de `aigile-forge-framework` en su estación de trabajo:

```bash
git clone <URL_DEL_REPOSITORIO_AIGILE_FORGE_FRAMEWORK> ~/herramientas/aigile-forge-framework
chmod +x ~/herramientas/aigile-forge-framework/aigile ~/herramientas/aigile-forge-framework/scripts/*.sh
```

A continuación elija el escenario que corresponda a su proyecto:

### Escenario A: Proyecto Nuevo (Greenfield)
```bash
~/herramientas/aigile-forge-framework/aigile init \
  --name motor-facturacion \
  --team "Equipo de Facturación" \
  --lang es \
  --topology worktrees \
  --mode zero-mcp \
  --harnesses all \
  --tracker github \
  --prefix FAC \
  --workspace ~/proyectos/motor-facturacion \
  --non-interactive
```
Cuando `--workspace` apunta a un directorio externo distinto del clon original del framework, `./aigile init` copia automáticamente los activos canónicos (`agents/`, `skills/`, `profiles/`, `prompts/`, `templates/`, `mcp/`, `configs/`, `scripts/`, `AGENTS.md` y el ejecutable `aigile`) dentro del nuevo directorio para que opere de forma completamente autónoma.

### Escenario B: Repositorio Existente (Brownfield) con Adopción Compartida o `--zero-footprint`
Si su equipo desea incorporar el framework a un repositorio existente:

```bash
# Opción B1: Adopción compartida por todo el equipo (versionable en Git)
~/herramientas/aigile-forge-framework/aigile init \
  --name api-clientes \
  --team "Equipo Clientes" \
  --lang es \
  --topology single-repo \
  --workspace ~/proyectos/api-clientes

# Opción B2: Adopción individual silenciosa sin ensuciar git status (--zero-footprint)
~/herramientas/aigile-forge-framework/aigile init \
  --name api-clientes \
  --team "Equipo Clientes" \
  --lang es \
  --topology single-repo \
  --zero-footprint \
  --workspace ~/proyectos/api-clientes
```
Con `--zero-footprint`, `./aigile init` añade `aff.yaml`, `CLAUDE.md`, `.claude/`, `.mcp.json`, `opencode.json`, `.agents/`, `.opencode/` y las rutas generadas en `.github/` dentro de `.git/info/exclude` (además de `work/` y `worktrees/`, que se excluyen siempre).

### Escenario C: Hub Multirrepositorio (`multi-root`)
Ideal cuando backend, frontend web y aplicaciones móviles residen en repositorios Git independientes:

```bash
~/herramientas/aigile-forge-framework/aigile init \
  --name suite-comercio \
  --team "Equipo Omnicanal" \
  --lang es \
  --topology multi-root \
  --mode zero-mcp \
  --tracker jira \
  --prefix COM \
  --workspace ~/workspaces/suite-comercio \
  --non-interactive
```
Esto crea `~/workspaces/suite-comercio/repositories/` (donde usted clona sus repositorios de servicio) y genera `suite-comercio.code-workspace` listo para abrir en VS Code o Cursor.

### Cuándo Elegir `--symlink` frente a `--copy`
- **`--symlink` (Predeterminado dentro del propio repositorio en Linux/macOS/WSL2):** Enlaza `.claude/skills`, `.agents/skills` y `.github/skills` hacia `../skills`. Cualquier ajuste en `skills/*/SKILL.md` se refleja instantáneamente.
- **`--copy` (Predeterminado en espacios externos y en Windows Git-Bash):** Crea copias físicas de las carpetas de habilidades. Úselo siempre en contenedores CI, volúmenes compartidos o entornos Windows sin enlaces simbólicos POSIX.

---

## 3. Referencia Campo por Campo de `aff.yaml` (Esquema v1.0)

El archivo `aff.yaml` en la raíz del espacio de trabajo gobierna el comportamiento de todos los scripts y agentes:

| Sección / Clave | Tipo | Valores Admitidos / Ejemplo | Descripción Técnica |
|---|---|---|---|
| `schema_version` | `string` | `"1.0"` | Versión normativa del esquema del manifiesto. |
| `project.id` | `string` | `"plataforma-pagos"` | Identificador único en formato `kebab-case` (usado también para `<id>.code-workspace`). |
| `project.name` | `string` | `"Plataforma de Pagos"` | Nombre legible del proyecto inyectado en encabezados e instrucciones de Copilot. |
| `project.namespace` | `string` | `"pagos"` | Prefijo corto para nombres de recursos y primer segmento del patrón de claves de caché. |
| `team.name` | `string` | `"Equipo Core de Pagos"` | Nombre del equipo de desarrollo responsable del proyecto. |
| `team.lead_role` | `string` | `"Technical Lead"` | Rol responsable de las aprobaciones técnicas en compuertas (`G1`/`G1a`, `G2`, `G3`). |
| `team.language.conversation` | `string` | `"en"` \| `"es"` | Idioma predeterminado de interacción conversacional de los agentes con el ingeniero. |
| `team.language.artifacts` | `string` | `"en"` \| `"es"` | Idioma objetivo para especificaciones de negocio (`elicitation.md`, `spec.md`, `knowledge/`). |
| `workspace.topology` | `string` | `"single-repo"` \| `"worktrees"` \| `"multi-root"` | Estrategia de aislamiento físico de repositorios y tareas paralelas. |
| `workspace.hub_name` | `string` | `"00-Project-Hub"` | Etiqueta de la carpeta coordinadora en espacios de trabajo `multi-root`. |
| `harnesses.mode` | `string` | `"zero-mcp"` \| `"mcp"` | Controla si se omiten/eliminan descriptores MCP (`zero-mcp`) o se proyectan (`mcp`). |
| `harnesses.enabled` | `list[str]` | `["claude","opencode","antigravity","codex","copilot"]` | Lista de harnesses objetivo cuando se sincroniza el espacio de trabajo. |
| `tracker.provider` | `string` | `"jira"` \| `"linear"` \| `"github"` \| `"gitlab"` \| `"azure-devops"` \| `"monday"` \| `"markdown"` | Herramienta de gestión de tickets empleada por el equipo de desarrollo. |
| `tracker.ticket_prefix` | `string` | `"PAG"` | Prefijo de identificadores de tickets (ejemplo: `PAG-101`). |
| `knowledge.mode` | `string` | `"local"` \| `"git"` \| `"folder-sync"` \| `"cloud-folder"` \| `"cortex-ai"` | Modo de persistencia y sincronización de `knowledge/` (`git` normaliza a `local`; `cloud-folder` a `folder-sync`). |
| `knowledge.sync_path` | `string` | `"/mnt/compartido/pagos-kb"` | Ruta de destino en disco o carpeta montada cuando se utiliza `folder-sync`. |
| `knowledge.cortex.drive_root_folder_id` | `string` | `"${DRIVE_ROOT_FOLDER_ID}"` | Variable de entorno con el ID de carpeta raíz en Google Drive (solo modo `cortex-ai`). |
| `knowledge.cortex.notebook_id` | `string` | `"${NOTEBOOKLM_NOTEBOOK_ID}"` | Variable de entorno con el ID del cuaderno semántico en NotebookLM. |
| `knowledge.cortex.engram_project` | `string` | `"plataforma-pagos"` | Nombre canónico del proyecto en Engram para memoria persistente entre sesiones. |
| `governance.phases` | `integer` | `8` | Número de fases del ciclo de vida (`0` a `7`). |
| `governance.gates` | `list[str]` | `["G1", "G2", "G3", "G4"]` | Compuertas humanas activas para el proyecto. |
| `governance.dual_po_approval` | `boolean` | `false` \| `true` | Si es `true`, divide `G1` en `G1a` (aprobación técnica) y `G1b` (aprobación de producto). |
| `governance.max_work_unit_loc` | `integer` | `400` | Límite orientativo de líneas de código por unidad de trabajo atómica TDD (`T#`). |
| `governance.require_4r_review` | `boolean` | `true` | Exige dictamen limpio de revisión 4R de dos pasadas antes de aprobar `G3`. |
| `governance.require_sha256_receipt` | `boolean` | `true` | Exige recibos JSON sellados con SHA256 (`./aigile receipt`) en compuertas de calidad. |
| `governance.multi_channel_parity` | `boolean` | `false` \| `true` | Activa la auditoría obligatoria 1:1 entre canales Web, Android e iOS (`/parity-check`). |
| `estimation.method` | `string` | `"pert"` \| `"story-points"` \| `"none"` | Método de estimación utilizado durante la Fase 2 (`/elicit-ticket`). |
| `estimation.focus_factor` | `float` | `0.75` | Factor de foco real del equipo (`0.0`–`1.0`) para convertir días ideales en días calendario. |
| `estimation.risk_buffer_days` | `float` | `1.0` | Colchón explícito en días agregado para mitigar incertidumbre técnica o de integración. |
| `profiles.enabled` | `list[str]` | Ver 7 perfiles en `profiles/*.md` | Perfiles tecnológicos activos que se exigen e inyectan en `.github/instructions/`. |
| `lanes` | `list[map]` | Lista de carriles técnicos | Define carriles de trabajo del equipo (por ejemplo: `backend`, `web`, `mobile`, `datos`). |
| `repositories` | `list[map]` | Inventario de repositorios | Describe cada repositorio gestionado (`id`, `path`, `lane`, `profile`, `default_branch`). |
| `guardrails.redact_patterns` | `list[str]` | `["secrets", "pii", "pci", "phi"]` | Categorías de datos sensibles sujetas a redacción obligatoria (`<REDACTED:...>`). |
| `guardrails.require_db_indexes` | `boolean` | `true` | Prohíbe consultas transaccionales sobre columnas o campos sin índice declarado. |
| `guardrails.require_cache_ttl` | `boolean` | `true` | Exige TTL finito explícito en toda escritura de caché distribuida o en memoria. |
| `guardrails.cache_key_pattern` | `string` | `"{namespace}:{domain}:{service}:{entity}:{id}"` | Convención obligatoria de nombres jerárquicos de claves de caché. |
| `guardrails.ban_git_stash` | `boolean` | `true` | Prohíbe el uso de `git stash`, exigiendo `./aigile worktree` y `./aigile session`. |

### Ejemplo Completo de `aff.yaml` en Producción

```yaml
schema_version: "1.0"

project:
  id: "comercio-omnicanal"
  name: "Plataforma de Comercio Omnicanal"
  namespace: "comercio"

team:
  name: "Equipo de Ingeniería Transaccional"
  lead_role: "Arquitecto Principal"
  language:
    conversation: "es"
    artifacts: "es"

workspace:
  topology: "worktrees"
  hub_name: "00-comercio-omnicanal-hub"

harnesses:
  mode: "zero-mcp"
  enabled:
    - "claude"
    - "opencode"
    - "antigravity"
    - "codex"
    - "copilot"

tracker:
  provider: "jira"
  ticket_prefix: "COM"

knowledge:
  mode: "folder-sync"
  sync_path: "/mnt/conocimiento-equipos/comercio-omnicanal"
  cortex:
    drive_root_folder_id: "${DRIVE_ROOT_FOLDER_ID}"
    notebook_id: "${NOTEBOOKLM_NOTEBOOK_ID}"
    engram_project: "comercio-omnicanal"

governance:
  phases: 8
  gates:
    - "G1"
    - "G2"
    - "G3"
    - "G4"
  dual_po_approval: true
  max_work_unit_loc: 400
  require_4r_review: true
  require_sha256_receipt: true
  multi_channel_parity: true

estimation:
  method: "pert"
  focus_factor: 0.75
  risk_buffer_days: 1.5

profiles:
  enabled:
    - "backend-jvm-spring"
    - "frontend-web"
    - "mobile-native"
    - "data-sql-nosql-cache"
    - "cicd-containers"

lanes:
  - id: "backend"
    name: "Servicios API y Dominio"
  - id: "clientes"
    name: "Canales Web y Móvil Nativo"

repositories:
  - id: "orders-service"
    path: "repositories/orders-service"
    lane: "backend"
    profile: "backend-jvm-spring"
    default_branch: "main"
  - id: "storefront-web"
    path: "repositories/storefront-web"
    lane: "clientes"
    profile: "frontend-web"
    default_branch: "main"
  - id: "storefront-mobile"
    path: "repositories/storefront-mobile"
    lane: "clientes"
    profile: "mobile-native"
    default_branch: "main"

guardrails:
  redact_patterns:
    - "secrets"
    - "pii"
    - "pci"
  require_db_indexes: true
  require_cache_ttl: true
  cache_key_pattern: "{namespace}:{domain}:{service}:{entity}:{id}"
  ban_git_stash: true
```

---

## 4. Variables de Entorno

Nunca almacene rutas personales ni credenciales dentro de `aff.yaml` o `mcp/*.json`. Utilice las siguientes variables en su perfil de shell (`~/.bashrc`, `~/.zshrc` o gestor seguro de secretos local):

| Variable de Entorno | Ámbito | Propósito |
|---|---|---|
| `AFF_WORKSPACE_DIR` | Core CLI (`./aigile`) | Fuerza el directorio raíz del espacio de trabajo activo cuando se invoca `./aigile` desde otra ruta. |
| `AFF_KNOWLEDGE_SYNC_DEST` | `aff-knowledge-sync.sh` | Sobrescribe `knowledge.sync_path` como directorio destino en modo `folder-sync`. |
| `ENGRAM_BIN` | `mcp/engram.json` | Ruta opcional al ejecutable de Engram (por defecto `engram`). |
| `ENGRAM_PROJECT` | `mcp/engram.json` | Clave del proyecto en Engram para aislar observaciones y memoria persistente. |
| `ENGRAM_DATA_DIR` | `mcp/engram.json` | Directorio local de almacenamiento SQLite/datos de Engram. |
| `CODEGRAPH_BIN` | `mcp/codegraph.json` | Ruta opcional al binario `codegraph` (por defecto `codegraph`). |
| `CODEGRAPH_WORKSPACE` | `mcp/codegraph.json` | Ruta raíz indexada por el grafo AST de código. |
| `GOOGLE_DRIVE_OAUTH_CREDENTIALS` | `mcp/google-drive.json` | Ruta al archivo local de credenciales OAuth (fuera del repositorio Git) para Google Drive MCP. |
| `DRIVE_ROOT_FOLDER_ID` | `aff.yaml` / `google-drive.json` | Identificador sintético o real de la carpeta raíz del proyecto en Google Drive (solo en entorno local). |
| `NOTEBOOKLM_MCP_BIN` | `mcp/notebooklm.json` | Ejecutable del servidor MCP de NotebookLM (por defecto `notebooklm-mcp`). |
| `NOTEBOOKLM_NOTEBOOK_ID` | `aff.yaml` / `notebooklm.json` | Identificador del cuaderno de NotebookLM asociado al proyecto. |
| `NOTEBOOKLM_AUTH_PROFILE` | `mcp/notebooklm.json` | Perfil local de autenticación para NotebookLM MCP. |

---

## 5. Instalación del Hook `pre-commit` y Diagnóstico de Problemas

### Activación del Escáner Preventivo en Git
Para bloquear automáticamente commits que contengan claves privadas, tokens de nube/API, contraseñas fijas o números de tarjeta de 16 dígitos:

```bash
./aigile scan --install-hook
```
En topologías `multi-root` o `worktrees` con múltiples repositorios en `repositories/*`, puede instalar el hook en cada repositorio individual indicando `--target-dir`:

```bash
./aigile scan --install-hook --target-dir repositories/orders-service
```

### Resolución de Problemas Frecuentes (`./aigile doctor` y `./aigile harness check`)

| Síntoma o Mensaje de Error | Causa Raíz | Solución Exacta |
|---|---|---|
| `[FAIL] aff.yaml missing at ...` en `./aigile doctor` | El directorio actual no ha sido inicializado o `AFF_WORKSPACE_DIR` apunta a otra ruta. | Ejecute `./aigile init` en el directorio deseado o exporte `AFF_WORKSPACE_DIR=/ruta/al/espacio`. |
| `.mcp.json must not exist when harnesses.mode is 'zero-mcp'` en `./aigile harness check` | Se cambió `aff.yaml` a `zero-mcp` manualmente sin volver a ejecutar el proyector, o alguien creó `.mcp.json` a mano. | Ejecute `./aigile harness sync all --mode zero-mcp` para limpiar descriptores residuales. |
| `frontmatter name '...' != directory '...'` en `./aigile harness check` | Se agregó una habilidad personalizada en `skills/<nombre>/SKILL.md` cuyo campo `name:` no coincide con la carpeta. | Iguale el valor `name: <nombre>` en el encabezado YAML al nombre exacto del subdirectorio. |
| Error de permisos al crear enlaces simbólicos en Windows | Ejecución en Git-Bash sin permisos elevados de creación de symlinks NTFS. | Reejecute con copia explícita: `./aigile harness sync all --copy`. |
| Los nuevos perfiles en `aff.yaml` no aparecen en VS Code Copilot | `aff.yaml` fue editado pero no se regeneraron las instrucciones `.github/instructions/`. | Ejecute `./aigile harness sync copilot` y recargue la ventana de VS Code si es necesario. |
