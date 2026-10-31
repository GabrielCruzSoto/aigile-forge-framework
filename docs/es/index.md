# aigile-forge-framework — Portal de Documentación

> **Idioma / Language:** Español | [English (`docs/en/index.md`)](../en/index.md)

Bienvenido al portal de documentación de **`aigile-forge-framework`**. aigile-forge-framework unifica la ingeniería multi-harness en línea de comandos e IDE (`Claude Code`, `OpenCode`, `Google Antigravity`, `OpenAI Codex`) y el gobierno declarativo en IDE (`GitHub Copilot`) bajo un único contrato canónico.

---

## Navegación

### 1. Arquitectura
- **[Arquitectura Universal y Proyección Determinista](architecture/overview.md)**
  Describe la estructura de directorios de fuente única, el manifiesto `aff.yaml`, el funcionamiento del proyector (`./aigile harness`) y la diferencia entre los modos `zero-mcp` y `mcp`.

### 2. Guías de Equipo y Espacio de Trabajo
- **[Incorporación de Equipos y Topologías de Espacio de Trabajo](guides/onboarding-and-topologies.md)**
  Detalla la inicialización interactiva y automatizada (`./aigile init`), la selección entre topologías `single-repo`, `worktrees` y `multi-root`, la integración con gestores de tickets y la sincronización de conocimiento.
- **[Ciclo de Vida de 8 Fases, Compuertas (`G1`–`G4`), Revisión 4R y Recibos RDD](guides/lifecycle-gates-and-4r.md)**
  Explica el dimensionamiento proporcional (`S/M/L/H`), las 8 fases de entrega, la **revisión adversarial 4R** (`Risk, Requirements, Regression, Resilience`) y los recibos criptográficos SHA256 (**Receipt-Driven Development**).

---

## Principios Fundamentales

1. **Fuente Canónica Única, Cinco Harnesses:** Mantenga reglas, agentes, habilidades y perfiles tecnológicos en un solo lugar y proyéctelos sin divergencias.
2. **Neutralidad Organizacional y de Proveedor:** Cero dependencias rígidas hacia empresas, clientes o herramientas propietarias específicas.
3. **Gobierno Proporcional:** Flujo ágil para correcciones acotadas (`S`); diseño guiado por contratos y compuertas formales para funcionalidades multirrepositorio (`L`/`H`).
4. **Verificación Criptográfica sobre Afirmaciones:** Las compuertas exigen recibos de ejecución sellados con SHA256 (`./aigile receipt`) e inspección automática de secretos (`./aigile scan`).
