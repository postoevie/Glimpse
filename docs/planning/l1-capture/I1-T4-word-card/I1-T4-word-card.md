# I1-T4 — Word card

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — fourth in build order  
**Feature refs:** F4.1 (view)  
**Product refs:** `docs/user-flows.md` (Flow 4 view), `docs/information-architecture.md` (card detail), `docs/feature-breakdown.md` (F4.1)

---

## Outcome

User opens a word from a folder list and sees its card: word, translation, example, and languages as stored (read-only in this task).

---

## User story

As a user, I want to open a saved word and see its details, so I can review what I captured.

---

## User steps (happy path)

1. User is in a folder word list.
2. User taps a word.
3. The word card opens (pushed on the stack).
4. Card shows word/phrase, translation (may be blank), example (may be blank), source language (or unknown if null), and target language as stored.
5. User can navigate back to the folder list.

---

## Scope

- Open card from folder list
- Display word, translation, example, source language, target language
- Blank translation/example shown clearly as empty
- Back to folder list
- Loading / empty-field presentation only (no edit UI in this task)

---

## Acceptance criteria

- [ ] Tapping a word in a folder list opens its card.
- [ ] Card shows word/phrase and translation as saved (translation may be blank).
- [ ] Example is shown (blank if none).
- [ ] Source language is visible (including unknown/null presentation).
- [ ] Target language is visible as stored.
- [ ] User can go back to the folder list.

---

## Edge cases

- Card with blank translation.
- Card with blank example.
- Unsorted / null source language presentation.

---

## Dependencies

- I1-T3 (folder word list)

---

## Out of scope (this task)

- Editing or deleting (I1-T5)
- Unsorted resolve, custom folder re-file
- Related items, AI actions, Study

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
