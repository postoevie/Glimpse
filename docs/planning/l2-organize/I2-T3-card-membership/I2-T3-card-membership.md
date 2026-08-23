# I2-T3 — Card membership (custom folder, known source)

**Type:** Product task
**Epic:** `../I2-organize.md`
**Priority:** P0 — third in build order
**Feature refs:** F2.3, F2.5 (default updates on file-into)
**Product refs:** `user-flows.md` (Flow 2 / Flow 4), `information-architecture.md` (card detail), `domain-modeling.md` (custom membership), `feature-breakdown.md` (F2.3)

> Slice of **update membership** — same Source + Custom folder controls as I2-T4.

---

## Outcome

When the card has a **known** (non-null) source, the user can assign or remove a custom folder as part of **update membership**. Assigning/removing custom does not by itself change source language, language folder, or the item’s target language. Filing into a folder updates the default custom folder preference. **Changing Source** (same membership flow) clears custom membership when sources no longer match, including clearing Source to **Not set** (→ Unsorted).

---

## User story

As a user, I want to move a saved word into or out of a custom folder later, on the same organize controls I use for Unsorted — so organization stays flexible after capture.

---

## User steps (happy path)

1. User opens a card with a known source language (Source not **Not set**).
2. User assigns a custom folder (picker: folders whose `sourceLanguage` matches the item).
3. The word appears in that custom folder’s list and remains in its language folder.
4. Folder target may update from the item’s target; folder source is unchanged.
5. The default custom folder preference updates to the folder just filed into.
6. User clears custom-folder membership; the word leaves the custom folder but stays in its language folder.
7. Removing membership does not change the folder’s languages.

---

## Scope

- Assign one custom folder from card when source is non-null
- Remove custom folder membership from card
- At most one custom folder per item
- Picker: folders matching item source only (+ clear / None)
- Assign/remove custom does **not** by itself change item `sourceLanguage`, language folder, or item `targetLanguage`
- Does **not** change folder `sourceLanguage` (set at create)
- Adding may update folder target (from item target)
- File-into updates default custom folder preference
- Unsorted (null source) custom assign uses I2-T4 adopt-source transition — not this match-only assign

---

## Acceptance criteria

- [x] Cards with known source can assign a custom folder.
- [x] Cards with known source can remove custom-folder membership.
- [x] An item never has more than one custom folder.
- [x] Assign/remove custom does not by itself change source language or language folder.
- [x] Assign/remove custom does not change the item’s target language.
- [x] Assign only when item source equals folder source; membership update does not set or change folder `sourceLanguage`.
- [x] File-into a custom folder updates the default preference.
- [x] Null-source cards use the Unsorted → language + custom transition (I2-T4), not match-only assign.

---

## Edge cases

- Move from custom folder A to custom folder B (still ≤1 membership).
- Remove membership from the only item in a custom folder (folder remains; languages stay set).
- Attempt to file into a folder whose source conflicts — not offered / not allowed.
- Card already in a custom folder: changing assignment replaces membership.

---

## Dependencies

- I2-T1 (custom folders)
- I2-T2 (default preference exists; capture filing for comparison)
- I1 card detail (view + edit)

---

## Out of scope (this task)

- Unsorted → language / Unsorted → custom / → Unsorted transitions (I2-T4)
- Editing folder name (I2-T1)
- Widget / Share, AI

---

## Definition of Done

- [x] All acceptance criteria checked
- [x] Edge cases verified
- [x] No out-of-scope behavior included

---

## Blueprint status note

Implemented in `GlimpseCore`: `GLIModelActor.updateCustomFolder`, exposed as `GLIWordPairMembershipClient.updateCustomFolder`. Domain/store layer only — no `GlimpseFeatures` card UI calls this client yet.
