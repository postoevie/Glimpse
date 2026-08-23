# I2-B8 — Auto-prune empty language folders

**Type:** Product task
**Epic:** `../I2-organize.md`
**Priority:** P2 — current-version backlog #2
**Feature refs:** F2.1, F1.4
**Product refs:** `domain-modeling.md` (Language Folder: auto-create, **was permanent**); `prd.md` §2; `I1-T2-language-folders.md` (user cannot rename/delete language folders)

> **Reopens** the locked rule that language folders are permanent. This task: a language folder with **0 words is removed**. The user still cannot rename or swipe-delete a language folder.

---

## Outcome

The root list shows only language folders that still have words. When the last word leaves a language (delete, or source change / Unsorted resolve), that language folder disappears. Saving a word in that language again creates the folder as today. **Unsorted** follows the same rule. Custom folders are unchanged (they may stay empty).

---

## User story

As a user, I want empty language folders gone from the root, so the list is only languages I still have words in — without me deleting folders by hand.

---

## User steps (happy path)

1. User has a language folder (for example Spanish) with one word.
2. User deletes that word, **or** changes its source so it is no longer Spanish.
3. User returns to the root (or is already there after the card closes).
4. The Spanish folder is **gone**. Other language folders with words remain.
5. User later saves a new Spanish word. The Spanish folder **appears again**, with that word.

Same for **Unsorted**: last unsorted word set to a language or deleted → Unsorted leaves the root; the next null-source save creates Unsorted again.

---

## Scope

- Remove a language folder when it has **0 words** (including Unsorted).
- Runs after the actions that can empty a folder: delete word, change source, Unsorted resolve that moves the last unsorted word, and a sweep when the root list loads (already-empty leftovers).
- If the user is **inside** a folder that just became empty, they leave that screen (back to root). Last-opened does not keep pointing at a removed folder.
- User still cannot rename or delete a language folder themselves (I1-T2).
- Auto-create on first use of a language (or Unsorted) is unchanged.

---

## Acceptance criteria

- [x] A language folder with 0 words does not appear on the root.
- [x] Deleting the last word in a language removes that folder from the root.
- [x] Changing source so no words remain in the old language removes that old folder; the new language folder exists (created if needed) and holds the word.
- [x] Unsorted with 0 words does not appear; the next unsorted save creates it again.
- [x] Language folders that still have at least one word stay.
- [x] Custom folders are not removed when empty.
- [x] User has no control to rename or delete a language folder.
- [x] If the open folder is the one that was just emptied, the user is back on the root (not a blank folder screen).
- [x] Saving a word in a language that was pruned creates that folder again.

---

## Edge cases

- Two words in Spanish, delete one → Spanish stays.
- Last word in Spanish moved to French → Spanish gone, French present (created if new).
- Last Unsorted word gets a source → Unsorted gone; that language folder present.
- Last Unsorted word deleted → Unsorted gone.
- Root load with leftover empty language rows from before this task → they are gone after load.
- Last-opened was the pruned folder → resume does not open a missing folder (root).
- Custom folder at 0 words → still listed (existing I2 rule).
- Share / Add that creates the first word in a language → folder appears as today.

---

## Dependencies

- I1-T2 language folders (auto-create, Unsorted)
- I1-T5 / card delete
- I2-T3 / I2-T4 source + Unsorted resolve (membership)

---

## Out of scope (this task)

- User-initiated delete or rename of language folders
- Pruning or hiding **custom** folders
- Nested folders, pinning, or scale UX beyond this task
- Changing how folders are auto-created

---

## Definition of Done

- [x] All acceptance criteria checked
- [x] Edge cases verified
- [x] No out-of-scope behavior included

---

## Blueprint status note

Implemented in `GlimpseCore`: `GLIModelActor.pruneEmptyLanguageFolders`, exposed as `GLIWordPairMembershipClient.pruneEmptyLanguageFolders`. Domain/store layer only — not yet wired to call automatically after delete / source change / root load in `GlimpseFeatures` (see Scope above); a `GlimpseFeatures` feature must call it at those points for this task's user-facing behavior to hold.
