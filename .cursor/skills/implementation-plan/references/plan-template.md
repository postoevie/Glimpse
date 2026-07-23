# Implementation plan template

## Plan contents (required)

Keep the plan short. Required sections:

1. **Brief task description** — 2–5 sentences summarizing the product outcome (paraphrase the task; do not paste the whole task).
2. **Reference** — link/path to the product task file (and epic if useful).
3. **Implementation steps** — bullet list of concrete build steps. **Technical details allowed** here (features, reducers, views, services, persistence, packages, test approach).

Optional short sections if useful:

- **Out of scope (engineering)** — what not to build in this slice
- **Deps / sequencing** — blocked by other tasks
- **Open questions** — only if blocking

Do **not** require long design essays, full class listings, or copy-paste of Glimpse docs.

---

## Template

```markdown
# I<n>-T<m> — Implementation plan

**Type:** Implementation plan  
**Task:** `<task-file>.md`  
**Epic:** `<epic-file>.md` (if applicable)  
**Product refs (if consulted):** Glimpse `<docs>`

---

## Brief task description

<Short paraphrase of the user-facing outcome and constraints from the task.>

---

## Reference

- Product task: `<relative path to task md>`
- Epic: `<relative path>` (optional)

---

## Implementation steps

- …
- … (build toward AC)
- … verification against task AC …
- … automated tests (after verification) …

---

## Out of scope (this slice)

- …

---

## Open questions

- … (omit section if none)
```

---

## How to write steps

- Order steps so each leaves the app closer to the task’s acceptance criteria.
- Split by concern when helpful (e.g. domain/service → TCA feature → SwiftUI → persistence → verification).
- Name package / app targets when architecture docs apply (`GlimpseCore`, `GlimpseFeatures`, `Glimpse` app).
- Suggest agent split only if helpful: `tca-engineer` (reducers), `swift-developer` (views/services) — optional, not required.
- End with a few **verification** bullets tied to task AC (still fine as tech checklist).
- **After verification steps**, add **test** steps (unit / reducer / UI as appropriate for the slice). Tests come after manual or checklist verification in the plan order — not instead of verification.

---

## Workflow

1. Resolve which task (path from user or open file).
2. Read task (+ epic).
3. Skim Glimpse docs only for gaps / stack placement.
4. Write `<task-basename>-implementation.md` in the same directory as the task file.
5. Do **not** edit the product task unless the user explicitly asks.

---

## Anti-patterns

- Putting the plan inside the product task file
- Replacing AC with a rewrite of the product story
- Ignoring task **Out of scope**
- Huge dumps of TD/architecture prose — link and extract only what the steps need
