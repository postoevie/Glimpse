# I1-T6 — Resume last opened folder

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — sixth in build order  
**Feature refs:** X4  
**Product refs:** `docs/user-flows.md` (Flow 3 launch), `docs/information-architecture.md` (resume rule), `docs/feature-breakdown.md` (X4)

---

## Outcome

After relaunch, the app returns to the last opened folder, or to the root folder list if no folder was previously opened. Scroll position and mid-deck state are not restored.

---

## User story

As a user, I want the app to reopen where I left off in my folders, so I can continue browsing without hunting for the same folder.

---

## User steps (happy path)

1. User opens a language folder from the root.
2. User leaves the app (or force-quits).
3. User relaunches the app.
4. The app shows that same folder’s word list.
5. If the user had only been on the root (never opened a folder, or last left at root), relaunch shows the root folder list.

---

## Scope

- Remember last viewed folder (or root)
- Restore that destination on cold start / relaunch
- Do not restore scroll position
- Do not restore study deck position (study out of I1; rule still: no mid-deck resume)

---

## Acceptance criteria

- [ ] Relaunch after viewing a folder opens that folder.
- [ ] Relaunch when last screen was root opens the root folder list.
- [ ] Scroll position inside a list is not required to restore.
- [ ] Behavior works offline and without an account.

---

## Edge cases

- Last folder had been emptied of words but still exists (language folder permanent) → still resume into it.
- User navigates root → folder → card → back to folder → kill app → resume folder (not card), unless product later specifies otherwise; for I1, resume **folder** (or root), not card detail.

---

## Dependencies

- I1-T3 (folder navigation exists); I1-T2 (root folder list)

---

## Out of scope (this task)

- Resume to card detail
- Resume mid-study deck
- Resume search query

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
