# I1-T7 — End-to-end acceptance

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — last in I1 build order  
**Feature refs:** Epic AC (F1.1, F1.4, F2.1, F3.1, F4.1, X1, X3, X4)  
**Product refs:** `docs/user-flows.md` (Flows 1, 3, 4 as in I1 scope), `docs/planning/l1-capture/I1-capture.md` (epic journey + AC)

---

## Outcome

Owner verifies the full I1 journey on a device or simulator: add → place in language/Unsorted → browse folder → open card → edit/delete → relaunch resumes last folder — offline, no account, no out-of-scope features.

---

## User story

As the owner, I want one acceptance pass over the whole epic, so I know I1 is done before starting I2.

---

## User steps (happy path)

1. Cold start the app (offline / airplane mode acceptable).
2. Add a word with translation; confirm it lands in a language folder (or Unsorted if source unknown).
3. Add a word with blank translation and skipped/failed source → Unsorted.
4. Open a folder; confirm newest-first list.
5. Open a card; edit translation/example/target; confirm persistence after relaunch.
6. Delete a word; confirm it is gone.
7. Open a folder, kill the app, relaunch; confirm resume to that folder (or root if applicable).
8. Confirm no custom folders, search, study, widget, Share, or AI actions were required for this journey.

---

## Scope

- Manual verification against **Epic acceptance criteria** in `I1-capture.md`
- Confirm each I1-T1…T6 DoD was met
- Confirm out-of-scope I1 items are absent
- Record pass/fail in this task’s AC (and update `docs/STATUS.md`)

---

## Acceptance criteria

- [ ] All epic acceptance criteria in `I1-capture.md` are checked by the owner.
- [ ] Happy path matches the epic user journey for in-scope steps.
- [ ] Listed edge cases from T1–T6 that matter to the journey were spot-checked.
- [ ] No out-of-scope capability from the epic is included.
- [ ] App works offline and without an account for this journey.
- [ ] `docs/STATUS.md` updated: I1 exit or remaining gaps noted.

---

## Edge cases

- Mix of language-folder and Unsorted items in one session.
- Relaunch after delete of last viewed context (still coherent UI).

---

## Dependencies

- I1-T1 through I1-T6 accepted

---

## Out of scope (this task)

- New product behavior
- I2+ features
- Automated CI matrix (Stage 11)

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Owner sign-off recorded (date in STATUS or comment here)
- [ ] No out-of-scope behavior included
