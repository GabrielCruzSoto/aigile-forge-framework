# Incorporación de Equipos y Topologías de Espacio de Trabajo

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/guides/onboarding-and-topologies.md`](../../en/guides/onboarding-and-topologies.md)

## 1. Inicialización del Espacio de Trabajo (`./aigile init`)

aigile-forge-framework admite tanto un asistente interactivo como ejecución desatendida para automatización:

```bash
# Asistente interactivo en español
./aigile init --lang es

# Inicialización no interactiva
./aigile init \
  --name gestion-pedidos \
  --team "Equipo de Pedidos" \
  --lang es \
  --topology worktrees \
  --mode zero-mcp \
  --harnesses claude,copilot \
  --tracker jira \
  --prefix PED \
  --workspace ./gestion-pedidos \
  --non-interactive
```

Durante la ejecución, `./aigile init`:
1. Genera `aff.yaml` a partir de `templates/aff.template.yaml`.
2. Crea los documentos base `knowledge/{team-roster,domain-overview,architecture-map,team-workflow}.md` si aún no existen.
3. Genera el archivo `<project-slug>.code-workspace` cuando se selecciona `--topology multi-root`.
4. Configura `.git/info/exclude` para directorios de ejecución (`work/`, `worktrees/`) y el modo opcional `--zero-footprint`.
5. Ejecuta `scripts/aff-harness.sh sync` (`--copy` en espacios de trabajo externos o entornos Windows; `--symlink` en el propio repositorio).

Posteriormente, ejecute el prompt `/init-team` (respaldado por `agents/onboarding.md` y `skills/team-onboarding-bootstrap/SKILL.md`) en su harness de IA para completar el relevamiento del dominio y ajustar `knowledge/*.md` y `profiles.enabled`.

---

## 2. Selección de Topología del Espacio de Trabajo

| Topología | Escenario Recomendado | Mecánica de Directorios |
|---|---|---|
| **`single-repo`** | Monolito, monolito modular, librería o servicio individual | El framework opera en la raíz del repositorio (versionado o excluido localmente con `--zero-footprint`). |
| **`worktrees`** | Equipos con múltiples tickets en paralelo o atención frecuente de incidentes | `./aigile worktree create <TICKET-ID>` crea ramas aisladas bajo `worktrees/<TICKET-ID>/` sin usar `git stash`. |
| **`multi-root`** | Arquitecturas distribuidas con repositorios separados de contratos API, backend, web y móvil | Un directorio coordinador concentra `aff.yaml`, `knowledge/`, `work/` y `<project-slug>.code-workspace`. |

---

## 3. Adaptación al Gestor de Tickets y Estimación

Configure `tracker.provider` (`jira`, `linear`, `github`, `gitlab`, `azure-devops`, `monday` o `markdown`) y `tracker.ticket_prefix` en `aff.yaml`. La entrada (`work/<TICKET-ID>/ticket-in.md`) y el reporte de avance (`work/<TICKET-ID>/ticket-out.md`) se mantienen en Markdown estándar independiente de la herramienta externa.

Los equipos que emplean **estimación PERT de 3 puntos** ajustan `estimation.focus_factor` (por ejemplo, `0.75`) y `estimation.risk_buffer_days` en `aff.yaml`:

$$E = \frac{O + 4M + P}{6}, \qquad \text{Esfuerzo Ajustado} = \frac{E}{\text{focus\_factor}}$$

---

## 4. Sincronización de Conocimiento (`./aigile sync`)

- **`local`:** Conserva `knowledge/` exclusivamente en el sistema de archivos del espacio de trabajo.
- **`folder-sync`:** Replica `knowledge/` hacia cualquier directorio compartido o montado en red (`./aigile sync --sync --dest /mnt/compartido/documentacion`), ejecutando `./aigile scan` antes de copiar.
- **`cortex-ai`:** Integra `knowledge/` y las bitácoras de sesión con memoria persistente e índices documentales vía MCP cuando `harnesses.mode: "mcp"`.
