# Create a task

## Workflow B — Create a task

Trigger examples: “write I1-T1”, “decompose epic into tasks”, “detail add-word task”.

1. Read the **parent epic** fully.
2. Re-read Glimpse sections that apply to this slice (especially user-flows + IA + PRD).
3. Choose one coherent piece of the journey (one primary user outcome).
4. Create the task folder `I<n>-T<m>-<slug>/`.
5. Write task file using **Task template** below, inside that folder.
6. Prefer **numbered user steps** for the happy path; also allow scope bullets, AC checkboxes, edge cases.
7. Link task from the epic’s Tasks section (path includes the task folder).
8. **No** implementation plan section.

When decomposing a whole epic into tasks: propose ordered T1…Tn titles first if useful, then write each file (or only those the user names).

---

## Task template

```markdown
# I<n>-T<m> — <Short product title>

**Type:** Product task  
**Epic:** `<epic-file>.md`  
**Priority:** <e.g. P0 — order in build sequence>  
**Feature refs:** <F/X ids from feature-breakdown>  
**Product refs:** Glimpse `<flows / IA / PRD sections used>`

---

## Outcome

<User-visible result of this task alone>

---

## User story

As a …, I want …, so that …

---

## User steps (happy path)

1. …
2. …
3. …

(Use step notation actively. Add extra subsections only if they clarify product behavior — still user-facing.)

---

## Scope

- …

---

## Acceptance criteria

- [ ] …

---

## Edge cases

- …

---

## Dependencies

<Other tasks or —>

---

## Out of scope (this task)

- …

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
```

---

## Quality bar

- Epic without a clear end-state journey → incomplete  
- Task that only restates the epic without a narrower outcome → split or rewrite  
- Task that mentions Swift/TCA/persistence APIs → remove; rephrase as user-visible rules  
- Task AC not observable by a human on device/simulator → rewrite  

---

## Anti-patterns

- Duplicating entire product docs into planning task bodies  
- Creating tasks from code structure (screens/classes) instead of journeys  
- Mixing I2+ scope into an I1 task without labeling out of scope  
- Adding “Implementation plan” to tasks (forbidden in this skill)
