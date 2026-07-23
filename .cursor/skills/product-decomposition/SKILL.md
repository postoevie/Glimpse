---
name: product-decomposition
description: >-
  Trigger when the user asks to create an epic, break an increment into tasks,
  write a product task (e.g. I1-T1), or decompose product docs into
  planning artifacts. Product language only — no impl plans or tech in tasks.
---

# Product decomposition (epics & tasks)

## Purpose

On user request: turn product docs into planning epics/tasks under `docs/planning/`.

## Load rule (required)

1. Open the product docs you need (`AGENTS.md` table) — prefer flows, IA, PRD, domain, feature-breakdown, increment-planning.
2. Load **exactly one** workflow reference:
   - **[epic](references/epic.md)** — create/update an epic
   - **[task](references/task.md)** — create/update a task (own folder required)
3. Do not load both unless the user asked for epic **and** tasks in the same turn (then load epic first, then task).

## Hard rules (always)

- One folder per task: `docs/planning/<slug>/I<n>-T<m>-<slug>/I<n>-T<m>-<slug>.md`
- Task bodies: **product language only** — no TCA/SwiftUI/SwiftData/file paths/agent owners/test matrices
- Do not invent rules that contradict product docs; if conflict, quote and ask
- Write planning artifacts in this repo only

## Anti-patterns

- Duplicating entire product docs into planning task bodies
- Tasks shaped from code structure instead of user journeys
- Adding “Implementation plan” inside product tasks
