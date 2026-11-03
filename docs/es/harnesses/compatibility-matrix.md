# Matriz de Compatibilidad Multi-Harness y GitHub Copilot

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/harnesses/compatibility-matrix.md`](../../en/harnesses/compatibility-matrix.md)

Este manual detalla cómo **`aigile-forge-framework`** proyecta su fuente canónica hacia cinco harnesses de asistencia por IA (**Claude Code**, **OpenCode**, **Google Antigravity**, **OpenAI Codex** y **GitHub Copilot**), las rutas exactas generadas en cada uno, las transformaciones de encabezados YAML y esquemas JSON ejecutadas por `scripts/aff-harness.sh`, y los controles estrictos del modo `zero-mcp`.

---

## 1. Tabla Completa de Rutas Proyectadas por Harness

Todos los archivos de la tabla siguiente son materializados de forma determinista por `./aigile harness sync`:

| Activo Canónico | Claude Code (`claude`) | OpenCode (`opencode`) | Google Antigravity (`antigravity`) | OpenAI Codex (`codex`) | GitHub Copilot (`copilot`) |
|---|---|---|---|---|---|
| **Contrato Raíz (`AGENTS.md` + `aff.yaml`)** | `CLAUDE.md` (importa `@AGENTS.md`) | `AGENTS.md` (lectura nativa) | `AGENTS.md` (lectura nativa) | `AGENTS.md` (lectura nativa) | `.github/copilot-instructions.md` |
| **10 Agentes (`agents/*.md`)** | `.claude/agents/<rol>.md` | `.agents/agents/<rol>.md` y `.opencode/agents/<rol>.md` | `.agents/agents/<rol>.md` | `.agents/agents/<rol>.md` | `.github/agents/aff-<rol>.agent.md` |
| **19 Habilidades (`skills/*/SKILL.md`)** | `.claude/skills/` | `.agents/skills/` | `.agents/skills/` | `.agents/skills/` | `.github/skills/` |
| **7 Perfiles (`profiles/*.md`)** | Vía `AGENTS.md` + carga directa | Vía `AGENTS.md` + carga directa | Vía `AGENTS.md` + carga directa | Vía `AGENTS.md` + carga directa | `.github/instructions/<perfil>.instructions.md` |
| **9 Prompts Slash (`prompts/*.prompt.md`)** | `.claude/commands/<cmd>.md` (`/comando` nativo) | `.opencode/prompts/` y `.agents/skills/<cmd>/` | `.agents/workflows/<cmd>.md` y `.agents/skills/<cmd>/` | `.agents/skills/<cmd>/` | `.github/prompts/*.prompt.md` (`/comando` nativo) |
| **Descriptor MCP (`harnesses.mode: "mcp"`)** | `.mcp.json` | `opencode.json` (`"mcp"` poblado) | `.agents/mcp_config.json` | Variables de entorno / CLI local | 100% declarativo IDE (sin archivo MCP generado) |
| **Descriptor MCP (`harnesses.mode: "zero-mcp"`)** | `.mcp.json` **eliminado/omitido** | `opencode.json` con `"mcp": {}` | `.agents/mcp_config.json` **eliminado/omitido** | Ninguno | Ninguno |

> **Alias soportado:** El proyector reconoce `claude-code` como alias directo de `claude` en la línea de comandos y en `aff.yaml`.

---

## 2. Subcomandos y Opciones de `./aigile harness` (`scripts/aff-harness.sh`)

```bash
./aigile harness <subcomando> [harness] [opciones]
```

### Referencia de Subcomandos
1. **`sync [all | lista-separada-por-comas]`**
   Proyecta los archivos canónicos hacia los harnesses indicados (`all` por defecto, o combinaciones como `claude,copilot` u `opencode,antigravity`).
   ```bash
   ./aigile harness sync all
   ./aigile harness sync claude,copilot --copy --mode zero-mcp
   ./aigile harness sync opencode --mode mcp --target-dir ~/workspaces/api-central
   ```
2. **`check`**
   Ejecuta la auditoría estática e integral del espacio de trabajo (código de salida `0` si es válido, `1` ante cualquier incumplimiento):
   - Comprueba la existencia de `AGENTS.md`, `aff.yaml`, `agents/`, `skills/`, `profiles/`, `prompts/` y `mcp/`.
   - Valida que cada subdirectorio en `skills/*/` contenga un `SKILL.md` con frontmatter YAML válido, `name` en formato `kebab-case` idéntico al nombre del directorio y `description` no vacía.
   - Parsea como JSON estricto todos los archivos en `mcp/*.json`, `configs/*.json`, `*.code-workspace` y los descriptores generados (`opencode.json`, `.mcp.json`, `.agents/mcp_config.json`).
   - En modo `zero-mcp`, falla inmediatamente si detecta `.mcp.json`, `.agents/mcp_config.json` o un objeto `"mcp"` no vacío en `opencode.json`.
3. **`status`**
   Muestra qué binarios CLI (`claude`, `opencode`, `antigravity`, `codex`, `code`) están instalados en el `PATH` del sistema y el estado físico (`[LINK]`, `[DIR]`, `[FILE]` o `[----]`) de las 13 rutas de proyección en el espacio de trabajo.
4. **`print <harness>`**
   Imprime en formato JSON legible el resumen exacto de rutas y configuración MCP que recibiría un harness individual sin escribir archivos en disco:
   ```bash
   ./aigile harness print claude
   ./aigile harness print copilot --mode zero-mcp
   ```
5. **`clean`**
   Elimina de forma segura todas las proyecciones generadas (`CLAUDE.md`, `.mcp.json`, `opencode.json`, `.claude/{skills,agents}`, `.agents/{skills,agents,mcp_config.json}`, `.opencode/agents` y `.github/{copilot-instructions.md,instructions,agents,prompts,skills}`) sin tocar ningún archivo canónico ni flujos de GitHub Actions que pudieran existir en `.github/workflows/`.

---

## 3. Transformación Determinista de Encabezados YAML y Descriptores JSON

Dado que cada herramienta exige metadatos distintos, `scripts/aff-harness.sh` transforma automáticamente el frontmatter canónico durante la proyección:

### 3.1 Agentes Estándar (`claude`, `opencode`, `antigravity`, `codex`)

#### Modelo de Capacidades (Puertos y Adaptadores)

`recommended_tools` (alias: `capabilities`) declara **capacidades abstractas**, nunca nombres de herramientas de un harness. Vocabulario permitido: `read`, `search`, `edit`, `terminal`, `delegate` (alias: `write`->`edit`, `execute`/`bash`->`terminal`, `agent`/`task`->`delegate`). `./aigile harness check` rechaza tokens desconocidos.

**Regla de oro:** una lista de herramientas permitidas solo se emite para **restringir** a un agente, nunca para habilitarlo. Los agentes con `edit` y `terminal` heredan el conjunto nativo del harness, incluida la creación de archivos y la delegación a subagentes.

| Capacidades | Claude Code (`.claude/agents/`) | Antigravity (`.agents/agents/`) | OpenCode (`.opencode/agents/`) | Copilot (`.github/agents/`) |
|---|---|---|---|---|
| Completo (`edit` + `terminal`) | se omite `tools` (hereda todo, incl. `Agent`) | `readonly: false`, sin `tools` | sin mapa `tools` (todo habilitado) | `read, search, edit, execute` |
| Parcial (p. ej. `edit` sin `terminal`) | `tools: Read, Grep, Glob, Write, Edit` | `readonly: false`, sin `tools` | `tools: {bash: false}` | `read, search, edit` |
| Solo lectura (sin `edit` ni `terminal`) | `tools: Read, Grep, Glob` | `readonly: true` | `tools: {write: false, edit: false, patch: false, bash: false}` | `read, search` |
| `delegate` | nativo vía `Agent` heredado | herramientas nativas de subagentes (heredadas) | `task` nativo (heredado) | agrega `agent` |

> Antigravity nunca recibe una lista `tools`: sus nombres de herramientas dependen de la versión y una lista restrictiva elimina silenciosamente la escritura y la delegación. En OpenCode, `tools` siempre es un mapa de booleanos, nunca una lista.

Los agentes que declaran `delegate` (`orchestrator`, `delivery`) deben incluir una sección `## Delegation Fallback`: si el harness no puede crear subagentes, el rol se ejecuta en la misma sesión y registra `mode: delegated | inline | blocked` en `state.yaml#execution_log`.

Ejemplo a partir de `agents/reviewer.md` (`read`, `search`, `terminal`) proyectado en `.opencode/agents/reviewer.md`:
```yaml
---
name: reviewer
description: "Clean-session two-pass deterministic 4R code auditor and adversarial false-positive refuter..."
mode: all
tools:
  write: false
  edit: false
  patch: false
---
```

### 3.2 Agentes Personalizados de GitHub Copilot (`.github/agents/aff-*.agent.md`)
Para evitar conflictos de nombres en VS Code y habilitar las capacidades de lectura, búsqueda, edición y ejecución en modo Agent, el proyector emite `.github/agents/aff-reviewer.agent.md`:
```yaml
---
name: aff-reviewer
description: "Clean-session two-pass deterministic 4R code auditor and adversarial false-positive refuter..."
tools: ['read', 'search', 'execute']
---
```
Antes de regenerar, el proyector limpia cualquier `aff-*.agent.md` obsoleto respetando posibles agentes externos que no usen el prefijo `aff-`.

### 3.3 Instrucciones por Extensión en Copilot (`.github/instructions/*.instructions.md`)
Solo los perfiles listados en `aff.yaml -> profiles.enabled` se proyectan en `.github/instructions/<perfil>.instructions.md`, conservando únicamente la clave `applyTo` exigida por VS Code:
```yaml
---
applyTo: "**/*.{java,kt,kts,xml,gradle}"
---
```

### 3.4 Esquemas JSON de Servidores MCP (Cuando `harnesses.mode: "mcp"`)
A partir de un mismo fragmento en `mcp/*.json`, `scripts/aff-harness.sh` adapta la estructura exacta que espera cada cliente:

- **Claude Code (`.mcp.json`)** — Incluye `"type": "stdio"` explícito bajo `"mcpServers"`:
  ```json
  {
    "mcpServers": {
      "engram": {
        "type": "stdio",
        "command": "${ENGRAM_BIN:-engram}",
        "args": ["mcp", "--tools=agent"],
        "env": {
          "ENGRAM_PROJECT": "${ENGRAM_PROJECT}",
          "ENGRAM_DATA_DIR": "${ENGRAM_DATA_DIR}"
        }
      }
    }
  }
  ```
- **Google Antigravity (`.agents/mcp_config.json`)** — Misma raíz `"mcpServers"` omitiendo la propiedad `"type"` para compatibilidad directa con el cargador stdio de Antigravity.
- **OpenCode (`opencode.json`)** — Transforma `command` + `args` en un arreglo único bajo `"type": "local"` y `"enabled": true`:
  ```json
  {
    "$schema": "https://opencode.ai/config.json",
    "mcp": {
      "engram": {
        "type": "local",
        "command": ["${ENGRAM_BIN:-engram}", "mcp", "--tools=agent"],
        "enabled": true,
        "env": {
          "ENGRAM_PROJECT": "${ENGRAM_PROJECT}",
          "ENGRAM_DATA_DIR": "${ENGRAM_DATA_DIR}"
        }
      }
    }
  }
  ```
Si un fragmento en `mcp/*.json` declara opcionalmente un arreglo `"harnesses": ["claude", "antigravity"]`, el proyector lo filtra únicamente hacia esos destinos; si declara `"enabled": false` o `"managed": true`, lo omite.

---

## 4. Estrategias de Enlace (`--symlink` vs `--copy`) y Garantía `zero-mcp`

| Aspecto | `--symlink` | `--copy` |
|---|---|---|
| **Mecanismo en disco** | Crea enlaces simbólicos relativos (`../skills`) o absolutos en `.claude/skills`, `.agents/skills` y `.github/skills`. | Copia recursivamente `skills/` dentro de cada carpeta de destino. |
| **Ventaja principal** | Cero duplicación de archivos; editar una habilidad en `skills/` surte efecto inmediato. | Portabilidad total en sistemas sin soporte de symlinks (Windows Git-Bash, contenedores Docker aislados, artefactos empaquetados). |
| **Selección automática en `./aigile init`** | Por defecto al inicializar in-situ en Linux, macOS y WSL2. | Por defecto al inicializar hacia un directorio `--workspace` externo o sobre Windows (`MINGW`/`MSYS`/`CYGWIN`). |

### Garantía de Cumplimiento en Modo `zero-mcp`
En organizaciones reguladas (banca, seguros, salud, telecomunicaciones o sector público) donde conectar demonios MCP no homologados infringe políticas de seguridad:
1. Mantenga `harnesses.mode: "zero-mcp"` en `aff.yaml`.
2. Al ejecutar `./aigile harness sync`, cualquier `.mcp.json` o `.agents/mcp_config.json` preexistente es **borrado automáticamente**, y `opencode.json` queda fijado en `"mcp": {}`.
3. Agregue `./aigile harness check` en su pipeline de CI para garantizar matemáticamente que ningún cambio introduzca descriptores MCP no autorizados.
