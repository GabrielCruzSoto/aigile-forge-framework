# Arquitectura Universal y Proyección Determinista

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/architecture/overview.md`](../../en/architecture/overview.md)

## 1. Estructura de la Fuente Canónica

aigile-forge-framework separa los **activos canónicos de ingeniería** de las **proyecciones específicas de cada harness** y de los **artefactos efímeros de ejecución**:

```text
aigile-forge-framework/
├── aigile                     # Punto de entrada CLI unificado multiplataforma
├── aff.yaml                   # Manifiesto canónico de proyecto, equipo, topología y gobierno
├── AGENTS.md                  # Contrato universal de ingeniería asistida por IA
├── agents/                    # 10 definiciones de agentes especializados neutrales al harness
├── skills/                    # Habilidades procedimentales (paquetes SKILL.md)
├── profiles/                  # 7 perfiles conectables de reglas por pila tecnológica
├── prompts/                   # Flujos reutilizables de comandos slash (*.prompt.md)
├── templates/                 # Plantillas parametrizadas en Markdown, YAML y JSON
├── mcp/                       # Fragmentos parametrizados de servidores MCP (*.json)
├── configs/                   # Matriz declarativa de capacidades por harness (harnesses.json)
├── scripts/                   # Scripts operativos deterministas (aff-*.sh)
├── knowledge/                 # Documentación curada de dominio, arquitectura, roles y flujo
└── work/                      # Artefactos por ticket, bitácoras de sesión y recibos RDD
```

---

## 2. Proyector Determinista (`scripts/aff-harness.sh`)

Al ejecutar `./aigile harness sync`, el proyector lee `aff.yaml` y genera las integraciones requeridas para cada harness habilitado:

1. **Claude Code (`claude`)**
   - Genera `CLAUDE.md` con importación directa hacia `@AGENTS.md`.
   - Proyecta los agentes en `.claude/agents/*.md` y enlaza o copia `skills/` hacia `.claude/skills`.
   - Emite `.mcp.json` **únicamente** cuando `harnesses.mode: "mcp"`; en modo `zero-mcp` omite o elimina `.mcp.json`.
2. **OpenCode (`opencode`)**
   - Lee `AGENTS.md` de manera nativa.
   - Proyecta agentes en `.agents/agents/` y `.opencode/agents/`, junto con `.agents/skills`.
   - Genera `opencode.json` con `"mcp": {}` en modo `zero-mcp` o con el mapa de servidores fusionado en modo `mcp`.
3. **Google Antigravity (`antigravity`)**
   - Utiliza `AGENTS.md`, `.agents/skills` y `.agents/agents`.
   - Emite `.agents/mcp_config.json` **únicamente** cuando `harnesses.mode: "mcp"`.
4. **OpenAI Codex (`codex`)**
   - Opera sobre `AGENTS.md` junto con `.agents/skills` y `.agents/agents`.
5. **GitHub Copilot (`copilot`)**
   - Genera `.github/copilot-instructions.md` combinando el contexto de `aff.yaml` y las reglas globales.
   - Proyecta cada perfil habilitado en `profiles/*.md` hacia `.github/instructions/<profile>.instructions.md`, conservando el encabezado `applyTo`.
   - Genera agentes personalizados `.github/agents/aff-<agent>.agent.md` con metadatos YAML válidos (`description` y `tools: ['read', 'search', 'edit', 'execute']`).
   - Copia los flujos interactivos a `.github/prompts/*.prompt.md` y sincroniza `.github/skills/`.

---

## 3. Modos Operativos (`zero-mcp` frente a `mcp`)

- **`zero-mcp` (Predeterminado):** Diseñado para entornos corporativos restringidos, redes aisladas o equipos que prefieren operar sin procesos externos. No deja archivos descriptores de MCP en el disco y mantiene el conocimiento local o sincronizado mediante directorios compartidos (`./aigile sync --mode folder-sync`).
- **`mcp` (Conectado / Cortex-AI):** Activa los fragmentos MCP parametrizados de `mcp/*.json` (`engram`, `codegraph`, `google-drive`, `notebooklm`) mediante variables de entorno (`${ENGRAM_PROJECT}`, `${DRIVE_ROOT_FOLDER_ID}`), evitando almacenar identificadores reales o credenciales en Git.

---

## 4. Validación de Integridad (`./aigile harness check`)

El comando `./aigile harness check` verifica:
- Existencia de `AGENTS.md`, `aff.yaml`, `agents/`, `skills/`, `profiles/`, `prompts/` y `mcp/`.
- Validez del encabezado YAML en cada `SKILL.md` (`name` coincidente con el directorio y `description` no vacía).
- Sintaxis JSON válida en `mcp/*.json`, `configs/*.json`, `opencode.json`, `.mcp.json`, `.agents/mcp_config.json` y `*.code-workspace`.
- Ausencia estricta de descriptores MCP cuando el modo activo es `zero-mcp`.
