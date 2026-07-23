---
name: implementation-plan
description: >-
  Trigger when the user asks for an implementation plan, tech plan, or how to
  implement an existing Glimpse product task (e.g. I1-T1). Writes
  *-implementation.md beside the task; does not rewrite the product task body.
---

# Implementation plan (from product task)

## Purpose

On user request only: write a **technical** plan next to an **existing** product task.

- Input: task file (+ epic if useful)
- Output: `docs/planning/.../I*-T*-*/I*-T*-*-implementation.md`
- Never merge the plan into the product task `.md`

## Load rule (required)

1. Read the **task file** (and epic if linked).
2. Skim product docs from `AGENTS.md` **only for gaps** (flows, IA, PRD, domain, TD/architecture for placement).
3. Load **[plan-template](references/plan-template.md)** once — required sections + template.
4. Write the plan in this repo. Do not invent product rules that contradict the task or product docs; if conflict, ask.

## Related

| Skill | Role |
|---|---|
| `product-decomposition` | Creates product task (no tech) |
| `development-workflow` | Gates after the plan |
