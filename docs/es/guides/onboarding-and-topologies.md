# Manual de Incorporación de Equipos y Topologías de Espacio de Trabajo

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/guides/onboarding-and-topologies.md`](../../en/guides/onboarding-and-topologies.md)

Este manual explica cómo incorporar cualquier equipo de desarrollo a **`aigile-forge-framework`** en pocos minutos: desde la inicialización técnica con `./aigile init` y la entrevista guiada de 6 dimensiones (`/init-team`), hasta la elección de topología de repositorios (`single-repo`, `worktrees`, `multi-root`), la conexión desacoplada con gestores de tickets y la calibración de estimaciones PERT de tres puntos.

---

## 1. Recetas Paso a Paso con `./aigile init`

El comando `./aigile init` prepara la estructura base del proyecto, renderiza `aff.yaml`, crea los documentos iniciales en `knowledge/`, configura `.git/info/exclude` y ejecuta la primera proyección hacia los harnesses seleccionados.

### 1.1 Modo Interactivo (Guiado en Consola)
Ideal cuando un Líder Técnico configura el espacio de trabajo por primera vez desde su terminal:

```bash
./aigile init --lang es
```
El asistente solicita secuencialmente:
1. Identificador del proyecto (`slug`, normalizado automáticamente a `kebab-case`, por ejemplo `motor-reservas`).
2. Nombre del equipo de desarrollo (por ejemplo, `Equipo de Reservas Digitales`).
3. Topología del espacio de trabajo (`single-repo`, `worktrees` o `multi-root`).
4. Modo de integración (`zero-mcp` o `mcp`).
5. Harnesses a proyectar (`all` o lista separada por comas como `claude,opencode,copilot`).
6. Gestor de tickets (`jira`, `linear`, `github`, `gitlab`, `azure-devops`, `monday` o `markdown`).
7. Prefijo de tickets (por ejemplo, `RES`).
8. Directorio destino del espacio de trabajo.

### 1.2 Modo No Interactivo (`--non-interactive` / `-y`)
Diseñado para scripts de aprovisionamiento interno, plantillas de plataforma (Internal Developer Platforms) o validación en integración continua:

```bash
# Receta 1: Equipo Full-Stack con Git worktrees y GitHub Issues
./aigile init \
  --name portal-proveedores \
  --team "Equipo Portal Proveedores" \
  --lang es \
  --topology worktrees \
  --mode zero-mcp \
  --harnesses claude,copilot \
  --tracker github \
  --prefix PRV \
  --workspace ~/workspaces/portal-proveedores \
  --non-interactive

# Receta 2: Arquitectura distribuida multi-root con modo MCP habilitado
./aigile init \
  --name logistica-global \
  --team "Equipo Plataforma Logística" \
  --lang es \
  --topology multi-root \
  --mode mcp \
  --harnesses all \
  --tracker linear \
  --prefix LOG \
  --workspace ~/workspaces/logistica-global \
  --copy \
  --non-interactive
```

Al concluir, `./aigile init` habrá generado:
- `aff.yaml` parametrizado con los valores elegidos.
- Cuatro documentos semilla en `knowledge/`: `team-roster.md`, `domain-overview.md`, `architecture-map.md` y `team-workflow.md` (a partir de `templates/*.template.md`).
- Las carpetas operativas `work/` y `sprints/` (más `worktrees/` o `repositories/` según la topología).
- El archivo `<project-slug>.code-workspace` si la topología es `multi-root`.

---

## 2. Entrevista de Descubrimiento de 6 Dimensiones (`/init-team`)

Mientras `./aigile init` crea el esqueleto físico, el comando slash **`/init-team`** (ejecutado por el agente **`onboarding`** junto con la habilidad `skills/team-onboarding-bootstrap/SKILL.md`) enriquece el conocimiento real del dominio y del equipo.

Invoque `/init-team` en su harness de IA preferido. El agente conducirá una entrevista concisa, **una dimensión a la vez**, esperando su confirmación antes de avanzar:

| Dimensión | Qué Releva el Agente `onboarding` | Artefactos Actualizados |
|---|---|---|
| **1. Identidad del Proyecto y Espacio de Trabajo** | `project.id`, `project.name`, `project.namespace` y confirmación de `workspace.topology`. | `aff.yaml` (`project`, `workspace`) |
| **2. Composición del Equipo e Idioma** | Roles del equipo, aprobadores de compuertas (`team.lead_role`, Product Owner, Seguridad) e idiomas `conversation` / `artifacts`. | `aff.yaml` (`team`), `knowledge/team-roster.md` |
| **3. Alcance de Gobernanza y Seguridad** | Compuertas activas (`G1`–`G4`), `dual_po_approval`, `multi_channel_parity` y categorías sensibles (`secrets`, `pii`, `pci`, `phi`). | `aff.yaml` (`governance`, `guardrails`) |
| **4. Dominio de Negocio** | Contextos acotados (Bounded Contexts), actores principales, invariantes de negocio y glosario ubicuo del proyecto. | `knowledge/domain-overview.md` |
| **5. Arquitectura, Repositorios y Perfiles** | Inventario de repositorios (`repositories`), carriles (`lanes`), motores de datos/caché, pipelines CI/CD y `profiles.enabled`. | `aff.yaml` (`profiles`, `lanes`, `repositories`), `knowledge/architecture-map.md` |
| **6. Forma de Trabajo, Tickets y Harnesses** | Flujo de ramas, proveedor de tickets (`tracker`), método de estimación (`pert`/`story-points`/`none`) y modo `zero-mcp` vs `mcp`. | `aff.yaml` (`tracker`, `estimation`, `harnesses`), `knowledge/team-workflow.md` |

> **Nota sobre organización de `knowledge/`:** `./aigile init` crea en la raíz de `knowledge/` los archivos planos `team-roster.md`, `domain-overview.md`, `architecture-map.md` y `team-workflow.md`. A medida que el proyecto crece, el agente `onboarding` o `curator` puede organizar subdirectorios temáticos (`knowledge/team/`, `knowledge/domain/`, `knowledge/architecture/`, `knowledge/adr/`) manteniendo todos los archivos Markdown bajo `knowledge/` incluidos automáticamente en `./aigile sync`.

Al finalizar las 6 dimensiones, el agente ejecuta `./aigile harness sync all` y `./aigile doctor` para dejar todo el entorno validado.

---

## 3. Elección de Topología del Espacio de Trabajo

Seleccione la topología en función de cuántos repositorios modifica su equipo y cuántas tareas en paralelo atiende cada desarrollador:

### 3.1 Topología `single-repo`
Recomendada para monolitos modulares, microservicios autónomos de un solo repositorio, bibliotecas o SDKs.

```text
mi-servicio/
├── .git/                      # info/exclude protege work/ y worktrees/ (y todo si --zero-footprint)
├── aigile                     # CLI local del espacio de trabajo
├── aff.yaml                   # Manifiesto del proyecto
├── AGENTS.md                  # Contrato universal
├── src/ & tests/              # Código fuente y pruebas del proyecto
├── odd/tasks/                 # Unidades de trabajo activas (ODD)
├── knowledge/                 # Documentación viva del proyecto
└── work/<TICKET-ID>/          # Especificaciones, contratos y recibos SHA256 (excluido de Git)
```

### 3.2 Topología `worktrees` (Recomendada para Equipos con Múltiples Tickets o Incidentes)
Permite trabajar en `PAG-101` y atender simultáneamente un incidente `PAG-205` en carpetas físicas independientes sin recurrir jamás a `git stash`:

```text
plataforma-pagos/
├── aigile
├── aff.yaml                   # workspace.topology: "worktrees"
├── knowledge/
├── repositories/              # (Opcional) Repositorios base limpios en su rama principal
│   ├── payments-api/
│   └── payments-web/
├── work/                      # Estado y gobernanza centralizados por ticket
│   ├── PAG-101/               # ticket-in.md, spec.md, contract.md, review-4r.md, evidence/
│   └── PAG-205/
└── worktrees/                 # Árboles Git aislados creados con ./aigile worktree create
    ├── PAG-101/
    │   ├── payments-api/      # Rama feat/PAG-101
    │   └── payments-web/      # Rama feat/PAG-101
    └── PAG-205/
        └── payments-api/      # Rama feat/PAG-205
```

### 3.3 Topología `multi-root` (Coordinador IDE Multirrepositorio)
Ideal para equipos que trabajan en VS Code o Cursor con repositorios separados (backend, web, Android, iOS, infraestructura) y desean un panel único gobernado por `<project-slug>.code-workspace`:

```text
suite-comercio/
├── suite-comercio.code-workspace   # Abre el Hub + todos los repositorios en VS Code
├── aigile
├── aff.yaml                        # workspace.topology: "multi-root"
├── AGENTS.md
├── .github/                        # Instrucciones, agentes, prompts y skills para Copilot
├── knowledge/                      # Conocimiento transversal a todos los repositorios
├── work/<TICKET-ID>/               # Especificaciones, slices por repo y recibos RDD
└── repositories/
    ├── backend-service/            # Repo Git independiente #1
    ├── frontend-web/               # Repo Git independiente #2
    └── mobile-app/                 # Repo Git independiente #3
```

### Matriz de Decisión Rápida

| Criterio | `single-repo` | `worktrees` | `multi-root` |
|---|---|---|---|
| **Cantidad de repositorios Git** | 1 | 1 o varios | 2 o más |
| **Cambio frecuente de contexto / soporte L3** | Moderado | Excelente (cero colisión de ramas) | Bueno (combinable con `worktrees`) |
| **Huella en repositorios de aplicación** | Opcional (`--zero-footprint`) | Nula fuera de commits de código | Nula (gobernanza vive en el Hub) |
| **Experiencia nativa en VS Code Multi-Folder** | Carpeta única | Carpeta por worktree o raíz | Nativa vía `<slug>.code-workspace` |

---

## 4. Integración Desacoplada con Gestores de Tickets

`aigile-forge-framework` soporta `jira`, `linear`, `github`, `gitlab`, `azure-devops`, `monday` y `markdown` sin requerir plugins propietarios ni acceso directo de red desde el agente:

1. **Entrada Normalizada (`work/<TICKET-ID>/ticket-in.md`):**
   Al iniciar un requerimiento con `/aff-intake`, usted pega el enlace, título y descripción del ticket (o lo exporta desde su CLI corporativa como `gh issue view`, `glab issue view` o `acli`). El agente `orchestrator` redacta cualquier dato sensible (`<REDACTED:...>`) y guarda una copia inmutable en `work/<TICKET-ID>/ticket-in.md` usando `templates/ticket-in.template.md`.
2. **Trazabilidad Interna:**
   El prefijo configurado en `tracker.ticket_prefix` (por ejemplo, `COM-412`) vincula el directorio `work/COM-412/`, la rama del árbol de trabajo `feat/COM-412`, el documento `odd/tasks/com-412-<slug>.md` y los recibos `receipt-G3.json` / `receipt-G4.json`.
3. **Salida Lista para Publicar (`work/<TICKET-ID>/ticket-out.md`):**
   Al cerrar la Fase 7, se genera `work/<TICKET-ID>/ticket-out.md` (basado en `templates/ticket-out.template.md`) con el resumen ejecutivo de cambios, enlaces a PRs, estado de criterios de aceptación `AC-#`, hashes SHA256 de los recibos y notas de despliegue, listo para pegar o publicar en Jira, Linear, GitHub, GitLab, Azure DevOps o Monday.

---

## 5. Estimación PERT de 3 Puntos y Calibración de Foco

Cuando `estimation.method` está configurado como `"pert"` en `aff.yaml`, el agente **`pm`** calcula durante `/elicit-ticket` una proyección transparente por carril técnico empleando tres escenarios en **días ideales**:

- **$O$ (Optimista):** Todo fluye sin fricciones técnicas ni dependencias externas imprevistas.
- **$M$ (Más Probable):** Esfuerzo realista considerando la complejidad habitual del repositorio.
- **$P$ (Pesimista):** Escenario con contratiempos de integración, refactorización previa o casos borde complejos.

### Fórmulas Aplicadas

1. **Esfuerzo Esperado ($E$) y Desviación Estándar ($\sigma$):**
   $$E = \frac{O + 4M + P}{6}, \qquad \sigma = \frac{P - O}{6}$$

2. **Conversión a Días Calendario Reales (Factor de Foco y Colchón de Riesgo):**
   $$\text{Duración Estimada (días)} = \frac{E}{\text{focus\_factor}} + \text{risk\_buffer\_days}$$

### Ejemplo Práctico de Calibración
Suponga un ticket `COM-412` evaluado con $O = 2.0$, $M = 3.5$ y $P = 8.0$ días ideales en un equipo con `focus_factor: 0.75` (el 25% del tiempo se dedica a ceremonias, revisiones de código y soporte) y `risk_buffer_days: 1.0`:
- $E = (2.0 + 4 \times 3.5 + 8.0) / 6 = 24.0 / 6 = 4.0$ días ideales.
- Duración ajustada $= (4.0 / 0.75) + 1.0 = 5.33 + 1.0 = \mathbf{6.3\text{ días hábiles}}$.

Si su equipo prefiere puntos de historia relativos o trabaja en flujo continuo Kanban sin estimación temporal, basta con definir `estimation.method: "story-points"` o `estimation.method: "none"` en `aff.yaml`.
