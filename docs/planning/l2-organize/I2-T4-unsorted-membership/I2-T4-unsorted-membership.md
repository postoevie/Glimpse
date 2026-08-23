# I2-T4 — Card membership (Unsorted transitions)

**Type:** Product task
**Epic:** `../I2-organize.md`
**Priority:** P0 — fourth in build order
**Feature refs:** F2.4
**Product refs:** `user-flows.md` (Flow 2 / Flow 4), `information-architecture.md` (card), `domain-modeling.md` (source + custom membership; invariant 3), `feature-breakdown.md` (F2.4)

> Slice of **update membership** — same Source + Custom folder controls as I2-T3.

---

## Outcome

On the word card, **update membership** covers Unsorted transitions:

| Transition | User action | Result |
|---|---|---|
| **Unsorted → language only** | Source = a language; Custom folder = None | Leaves Unsorted; no custom membership |
| **Unsorted → language + custom** | Pick a Custom folder | Adopts folder `sourceLanguage`; matching language folder + custom membership |
| **→ Unsorted** | Source = **Not set** | Language folder Unsorted; custom membership cleared |

Source stays editable after save; language folder always follows Source; custom membership clears on source mismatch / Not set.

---

## User story

As a user, I want one clear way to fix a word in Unsorted and to move it back if I clear source — on the same membership controls as the rest of card organize.

---

## User steps (happy path)

1. User opens a card in Unsorted (`sourceLanguage` null — Source shows **Not set**).
2. Card shows inline **Source** and **Custom folder**.
3. **Unsorted → language only:** Custom folder is None; user picks a source language → leaves Unsorted; custom membership unchanged.
4. **Unsorted → language + custom:** user picks a custom folder → item filed there; Source adopts the folder’s required language; matching language folder. Item target unchanged.
5. Later, with a known source, I2-T3 membership (assign/clear custom when sources match) applies on the same controls.
6. **→ Unsorted:** user sets Source to **Not set** → Unsorted language folder; custom membership cleared.
7. Changing Source while filed in a custom folder whose language no longer matches → custom membership cleared; language folder follows.

---

## Scope

- Inline Source + Custom folder on the word card (shared update-membership surface)
- Unsorted → language only; Unsorted → language + custom (adopt folder source); → Unsorted via Source Not set
- Do not change item `targetLanguage` on these transitions
- Folder target may sync from item target when filing into custom (card → folder)

---

## Acceptance criteria

- [x] Unsorted cards show Source (**Not set** when null) and Custom folder.
- [x] Unsorted → language only: set Source, Custom None → leaves Unsorted; custom membership unchanged.
- [x] Unsorted → language + custom: pick Custom folder → adopts folder source; always leaves source non-null; files into that folder.
- [x] → Unsorted: Source Not set → Unsorted folder; custom membership cleared.
- [x] Neither transition changes the item’s target language.
- [x] Changing source when custom folder selected and sources no longer match → custom membership cleared; language folder follows.

---

## Edge cases

- Pick any custom folder while Unsorted → adopt that folder’s source (no separate language pick).
- Leave Source / Custom on None → still Unsorted.
- Source may be disabled briefly while a custom folder pick is applying (folder owns source for that transition).
- Change source `es` → `fr` while in an `es` custom folder → membership cleared; French language folder.

---

## Dependencies

- I2-T1 (custom folders)
- I2-T3 (known-source custom assign/clear on same surface)
- I1 Unsorted language folder + card

---

## Out of scope (this task)

- Search, study, AI
- Full card Edit-mode draft gating for source/folder

---

## Definition of Done

- [x] All acceptance criteria checked
- [x] Edge cases verified
- [x] No out-of-scope behavior included

---

## Blueprint status note

Implemented in `GlimpseCore`: `GLIModelActor.updateSource` / `updateCustomFolder`, exposed as `GLIWordPairMembershipClient`. Domain/store layer only — no `GlimpseFeatures` card UI calls this client yet.
