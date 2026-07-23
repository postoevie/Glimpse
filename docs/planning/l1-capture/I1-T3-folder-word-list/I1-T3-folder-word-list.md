# I1-T3 — Folder word list

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — third in build order  
**Feature refs:** F3.1  
**Product refs:** `docs/user-flows.md` (Flow 3 browse), `docs/information-architecture.md` (folder detail), `docs/feature-breakdown.md` (F3.1)

---

## Outcome

User opens a language folder from the root and sees its words, newest first, on the single navigation stack.

---

## User story

As a user, I want to open a language folder and see the words inside it, so I can browse my vocabulary by language.

---

## User steps (happy path)

1. User is on the root language-folder list.
2. User taps a folder (language or Unsorted).
3. The folder’s word list opens (pushed on the stack).
4. Words appear newest first.
5. Empty folder shows an empty state (no crash, clear that there are no words).

---

## Scope

- Navigate from root folder list into a folder
- List words belonging to that folder
- Newest-first order
- Empty state for a folder with no words
- Back navigation to root on the single stack

---

## Acceptance criteria

- [ ] Tapping a folder opens its word list.
- [ ] Words in the list are ordered newest first.
- [ ] An empty folder shows an empty state.
- [ ] User can navigate back to the root folder list.
- [ ] No tabs; navigation stays on one stack.

---

## Edge cases

- Folder with one word.
- Folder with many words (scrollable list).
- Unsorted folder with items.

---

## Dependencies

- I1-T2 (folders + placement)

---

## Out of scope (this task)

- Opening a word card (I1-T4)
- Shuffle, Study, search
- Custom folders
- Edit/delete from the list

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
