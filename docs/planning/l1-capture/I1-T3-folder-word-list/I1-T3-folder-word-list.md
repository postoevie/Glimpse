# I1-T3 — Folder word list

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — third in build order  
**Feature refs:** F3.1, F1.1 (folder Add entry)  
**Product refs:** `docs/user-flows.md` (Flow 3 browse + Add), `docs/information-architecture.md` (folder detail), `docs/feature-breakdown.md` (F3.1, F1.1)

---

## Outcome

User opens a language folder from the root, sees its words newest first, and can **Add** a word from that list with source language prefilled from the folder (when known).

---

## User story

As a user, I want to open a language folder, see the words inside it, and add another word into that language context without going back to root, so I can browse and grow vocabulary by language in one place.

---

## User steps (happy path)

1. User is on the root language-folder list.
2. User taps a folder (language or Unsorted).
3. The folder’s word list opens (pushed on the stack).
4. Words appear newest first.
5. Empty folder shows an empty state (no crash, clear that there are no words).
6. User taps **Add** on the folder word list → same capture sheet as root.
7. For a **language folder**, source (and default target) are prefilled / locked to that language; user enters text, saves → word appears in this folder’s list.
8. For **Unsorted**, source is not forced (detection / manual as on root).

---

## Scope

- Navigate from root folder list into a folder
- List words belonging to that folder
- Newest-first order
- Empty state for a folder with no words
- Back navigation to root on the single stack
- **Add** on folder word list → same capture sheet; prefill source/target from folder when `sourceLanguage` is set

---

## Acceptance criteria

- [ ] Tapping a folder opens its word list.
- [ ] Words in the list are ordered newest first.
- [ ] An empty folder shows an empty state.
- [ ] User can navigate back to the root folder list.
- [ ] No tabs; navigation stays on one stack.
- [ ] Folder word list has **Add** opening the same in-app capture sheet as root.
- [ ] Language folder Add prefills source (and default target) to that folder’s language; source locked.
- [ ] Unsorted Add does not force source (same rules as root capture).
- [ ] After save from folder Add, the new word appears in that folder’s list (or Unsorted when source is null).

---

## Edge cases

- Folder with one word.
- Folder with many words (scrollable list).
- Unsorted folder with items.
- Add from empty language folder (still prefills that language).
- Add from Unsorted with detection → may leave Unsorted or land in a language folder.

---

## Dependencies

- I1-T1 (in-app Add sheet)
- I1-T2 (folders + placement)

---

## Out of scope (this task)

- Opening a word card (I1-T4)
- Shuffle, Study, search
- Custom folders
- Edit/delete from the list
- Prefilling / filing into a custom folder from this entry (v1 custom folder UI later)

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
