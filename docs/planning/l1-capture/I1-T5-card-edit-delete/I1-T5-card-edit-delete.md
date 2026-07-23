# I1-T5 — Manual card editing and deletion

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — fifth in build order  
**Feature refs:** F4.1 (mutate)  
**Product refs:** `docs/user-flows.md` (Flow 4 edit rules), `docs/information-architecture.md` (card detail), `docs/feature-breakdown.md` (F4.1), `docs/domain-modeling.md` (source locked on text edit)

---

## Outcome

On the word card, the user can manually edit word, translation, example, and target language, and can delete the word. Editing the word does not change source language or folder.

---

## User story

As a user, I want to fix or enrich a saved word on its card and remove words I no longer need, so my vocabulary stays accurate.

---

## User steps (happy path)

1. User opens a word card.
2. User edits word/phrase, translation, example, and/or target language.
3. Changes are kept (visible after leaving the card and after relaunch).
4. User deletes the word from the card; the word is gone from its folder list.
5. Editing the word text does not move the item to another language folder or change source language.

---

## Scope

- Edit word/phrase
- Edit translation (manual only; never auto-generated)
- Edit example (manual; may remain blank)
- Edit target language
- Delete word from card (with clear confirmation if the product UI uses one — prefer a deliberate delete action)
- Persist edits and delete across relaunch
- Source language and language folder unchanged when word text is edited

---

## Acceptance criteria

- [ ] User can edit word, translation, example, and target language on the card.
- [ ] Edits remain after leaving the card and after reopening the app.
- [ ] User can delete a word from its card; it no longer appears in the folder.
- [ ] Editing the word does not change source language or language folder.
- [ ] Translation is never generated automatically while editing.

---

## Edge cases

- Clear translation to blank.
- Clear example to blank.
- Delete the last word in a folder (folder may remain; language folders are permanent).
- Edit target language only.

---

## Dependencies

- I1-T4 (word card view)

---

## Out of scope (this task)

- Changing source language / Unsorted resolve (I2)
- Custom folder re-file
- AI generate translation / example / discover-similar
- Related items

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
