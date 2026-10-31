---
name: bilingual-elicitation
description: "Hypothesis-driven requirement elicitation for sparse or ambiguous tickets, generating at most 10 prioritized P1-P3 questions in the team's configured language."
---

# Skill: Bilingual Hypothesis-Driven Elicitation

## Purpose & Activation

Activate during Phase 1 (Discovery & Elicitation) via `/elicitate` or the `analyst` agent whenever a ticket (`<TICKET-ID>`, e.g., `PROJ-101`) has a missing, one-line, or ambiguous description, or lacks explicit edge-case, security, or multi-channel behavior definitions.

## Inputs

- Ticket title, raw description, acceptance notes, or user prompt.
- `aff.yaml` settings: `language.conversation` (`en` or `es`), `language.artifacts` (`en` or `es`), active `stack.profiles`, and `channels.parity_required`.
- Curated context in `knowledge/business/` and `knowledge/architecture/` plus affected codebase entry points.

## Step-by-Step Workflow

### 1. Silent Context & Codebase Reconnaissance
Before asking the human a single question, inspect local sources to answer whatever the repository already knows:
1. Read `knowledge/business/domain-glossary.md` and `knowledge/architecture/system-landscape.md`.
2. Inspect existing endpoints, schemas, validation rules, and UI flows related to the ticket topic.
3. Separate **Confirmed Facts** (backed by code or curated docs) from **Explicit Hypotheses** (`HYPOTHESIS: ...` requiring human confirmation).

### 2. Gap Analysis Across 6 Engineering Lenses
Scan for unstated ambiguity across:
1. **Actor & Authorization**: Who can trigger this action, under what roles/permissions, and what happens on unauthorized access?
2. **State Transitions & Idempotency**: Valid initial states, duplicate request handling, retries, and partial failures.
3. **Validation & Domain Boundaries**: Required fields, min/max bounds, currency/timezone/locale rules, and server-side ownership.
4. **Multi-Channel Impact**: Does this apply identically to Web and Native Mobile (Android/iOS), or is one channel out of scope?
5. **Data & Privacy**: New persistence fields, indexing impact, cache invalidation, and PII/PHI/PCI masking requirements.
6. **Non-Functional & Rollout**: Latency/SLAs, feature flags, backward compatibility (`N/N-1`), and observability events.

### 3. Formulate Prioritized Questions (Max 10)
Produce **at most 10 concise, high-leverage questions** ordered strictly by priority:
- **P1 (Gate G1 Blocker)**: Changes domain behavior, data schema, security posture, or public API contract. Cannot draft final `spec.md` without an answer.
- **P2 (Important Clarification)**: Affects UX edge states, error messages, or operational defaults; propose a sensible recommended default alongside the question.
- **P3 (Optional / Deferred)**: Cosmetic or future-phase detail that carries a safe default.

### 4. Language Adaptation Contract
- Render user-facing elicitation prompts and explanations in `language.conversation` (`en` = crisp professional English; `es` = neutral professional Spanish without regional slang).
- Write persistent repository artifacts (`elicitation.md`) in `language.artifacts` (default `en` unless `aff.yaml` specifies `es`), preserving verbatim user quotes in their original language.

## Hard Rules & Guardrails

- **Never Exceed 10 Questions**: Consolidate related sub-questions; never dump an unprioritized checklist of 25 generic questions.
- **Never Ask What the Repo Already Answers**: If an existing schema or controller already defines an enum or endpoint path, cite it as a Confirmed Fact or verify whether it changes instead of asking from scratch.
- **Explicit Hypothesis Tagging**: Every unconfirmed assumption MUST carry `[HYPOTHESIS-H#]` until the Product Owner, Tech Lead, or user confirms or overrides it.
- **Stop and Wait on P1**: When P1 blockers exist, emit the structured questionnaire with recommended options and wait for human input before passing Gate `G1`.

## Outputs

Structured elicitation artifact (`work/<TICKET-ID>/elicitation.md` or inline section linked from `odd/tasks/<ticket>-<slug>.md`) containing:
1. Ticket Summary & Scope Boundary.
2. Confirmed Codebase & Domain Facts (with file references).
3. Explicit Hypotheses (`H1`..`Hn`) with proposed defaults.
4. Prioritized Questionnaire (`Q1`..`Q10` max, tagged `P1`/`P2`/`P3`).

## Verification Checklist

- [ ] Total question count is `<= 10` and every question has a `P1`, `P2`, or `P3` priority tag.
- [ ] Every question states *why* the answer affects behavior, contract, or risk, plus a concrete recommended option where applicable.
- [ ] Conversation language matches `aff.yaml` `language.conversation` with zero company-coupled assumptions.
