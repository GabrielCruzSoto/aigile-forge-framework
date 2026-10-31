# Ciclo de Vida de 8 Fases, Compuertas (`G1`–`G4`), Revisión 4R y Recibos RDD

> **Volver al Portal:** [`docs/es/index.md`](../index.md) | **English:** [`docs/en/guides/lifecycle-gates-and-4r.md`](../../en/guides/lifecycle-gates-and-4r.md)

## 1. Dimensionamiento Proporcional (`S / M / L / H`)

No todos los cambios requieren la misma ceremonia arquitectónica. En la **Fase 0**, el agente `orchestrator` clasifica cada ticket de forma proporcional:

| Tamaño | Alcance Típico | Artefactos y Compuertas Exigidas |
|---|---|---|
| **`S` (Pequeño)** | Corrección puntual, ajuste de configuración o documentación (< 80 líneas, un repositorio, sin cambio de contrato) | `state.yaml`, pruebas automatizadas, verificación 4R (`G3`) y recibo `G4`. |
| **`M` (Mediano)** | Funcionalidad estándar o refactorización acotada en un servicio (~80–300 líneas) | `spec.md` (`G1`), tareas ODD, pruebas, `review-4r.md` (`G3`) y recibo `G4`. |
| **`L` (Grande)** | Funcionalidad multirrepositorio, cambio en contratos API/esquemas o paridad web/móvil | Flujo completo `G1` -> `G2` (`contract.md`) -> particiones en worktrees -> `G3` -> `G4`. |
| **`H` (Incidente / Hotfix)** | Mitigación urgente en producción | Especificación de causa raíz, prueba de regresión, revisión de seguridad/4R (`G3`), recibo `G4` y curaduría posterior. |

---

## 2. Compuertas de Verificación Humana (`G1`–`G4`)

1. **Compuerta `G1` — Aprobación de Descubrimiento y Especificación**
   - Valida criterios de aceptación, casos borde, requisitos no funcionales y estimación PERT en `work/<TICKET-ID>/spec.md`.
   - Si el equipo requiere doble firma técnica y de producto, puede activar `governance.dual_po_approval: true` para desdoblar `G1` en `G1a` (Líder Técnico) y `G1b` (Product Owner).
2. **Compuerta `G2` — Aprobación de Arquitectura y Contratos Primero**
   - Congela esquemas API (OpenAPI/AsyncAPI/GraphQL), migraciones de datos y contratos de paridad multicanal (`work/<TICKET-ID>/contract.md`) antes de codificar en paralelo.
3. **Compuerta `G3` — Aprobación Adversarial 4R y Seguridad**
   - Exige dictamen `work/<TICKET-ID>/review-4r.md` en sesión limpia y resultado limpio de `./aigile scan` antes de integrar cambios.
4. **Compuerta `G4` — Preparación de Entrega y Recibo Criptográfico**
   - Comprueba la ejecución exitosa de pruebas y el recibo JSON sellado con SHA256 (`work/<TICKET-ID>/evidence/receipt-G4.json`).

---

## 3. Protocolo de Revisión Adversarial 4R

Antes de superar la compuerta `G3`, el agente `reviewer` inspecciona los cambios bajo cuatro dimensiones complementarias:

- **Risk (Riesgo):** Fallos de autenticación o autorización, vectores de inyección, exposición de secretos o datos sensibles, migraciones destructivas y radio de impacto.
- **Requirements (Requisitos):** Trazabilidad verificable entre cada criterio de `spec.md` y `contract.md` y su implementación con pruebas reales.
- **Regression (Regresión):** Compatibilidad hacia atrás en contratos API, esquemas de base de datos, librerías compartidas y suites existentes.
- **Resilience (Resiliencia):** Tiempos de espera acotados, reintentos seguros, claves de idempotencia, degradación controlada, observabilidad y plan de reversión.

---

## 4. Receipt-Driven Development (`./aigile receipt`)

aigile-forge-framework sustituye las declaraciones subjetivas de finalización por recibos JSON deterministas firmados con SHA256:

```bash
# Ejecutar pruebas y sellar el recibo de la compuerta G4
./aigile receipt generate PROJ-101 G4 -- bash -c "npm test && npm run lint"

# Verificar integridad criptográfica y coincidencia con el commit HEAD actual
./aigile receipt verify work/PROJ-101/evidence/receipt-G4.json --verify-head
```

Cada recibo vincula `ticket_id`, `gate`, `command`, `exit_code`, `timestamp_utc`, `git_head`, `working_tree_diff_sha256` y `output_sha256` dentro de la firma canónica `receipt_sha256`. Cualquier alteración posterior invalida la verificación con código de salida distinto de cero.

---

## 5. Continuidad de Sesión y Árboles de Trabajo

```bash
# Iniciar sesión y árbol de trabajo aislado para un ticket
./aigile session start PROJ-101
./aigile worktree create PROJ-101

# Registrar punto de control antes de cambiar de contexto (prohibido usar git stash)
./aigile worktree checkpoint PROJ-101 "Validación de contrato completada"
./aigile session checkpoint "Contrato validado; listo para revisión G3"

# Retomar posteriormente desde cualquier harness
./aigile session resume PROJ-101
```
