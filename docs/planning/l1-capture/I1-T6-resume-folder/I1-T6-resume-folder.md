# I1-T6 — Resume last opened folder

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — sixth in build order  
**Feature refs:** X4  
**Product refs:** `docs/user-flows.md` (Flow 3 launch), `docs/information-architecture.md` (resume rule), `docs/feature-breakdown.md` (X4)

---

## Outcome

After a cold relaunch, the app returns to the last opened folder (language folder or Unsorted), or to the root folder list if no folder was previously opened. Scroll position, card detail, search query, and mid-deck state are not restored. Background → foreground needs no special resume (the existing navigation stack remains).

**Scope note:** I1 delivers language folders + Unsorted only. IA’s “last folder” rule includes custom folders; **custom-folder cold resume is owned by I2-T1** (not this task).

---

## User story

As a user, I want the app to reopen where I left off in my folders, so I can continue browsing without hunting for the same folder.

---

## User steps (happy path)

1. User opens a folder from the root (language folder or Unsorted).
2. User force-quits the app (process terminated — cold start next launch).
3. User relaunches the app.
4. The app shows that same folder’s word list.
5. If the user had only been on the root (never opened a folder, or last left at root), relaunch shows the root folder list.

---

## Scope

- Remember last viewed folder (language or Unsorted) or root
- Restore that destination on cold start / relaunch only
- Do not restore scroll position
- Do not restore study deck position (study out of I1; rule still: no mid-deck resume)
- Do not restore card detail or search query
- No special handling for background → foreground

---

## Acceptance criteria

- [ ] Cold relaunch after viewing a folder (language or Unsorted) opens that folder.
- [ ] Cold relaunch when last screen was root opens the root folder list.
- [ ] Cold relaunch while a card was open resumes the containing folder (not the card).
- [ ] Cold relaunch while a capture sheet was open over a folder resumes that folder (not the sheet).
- [ ] Missing, malformed, or unknown stored folder destination falls back to root.
- [ ] Search query text is not restored.
- [ ] Scroll position inside a list is not required to restore.
- [ ] Behavior works offline and without an account.
- [ ] Background → foreground does not require a separate resume path.

---

## Edge cases

- Last folder had been emptied of words but still exists (language folder permanent; Unsorted as applicable) → still resume into it.
- Root → folder → card → force-quit (still on card) → resume folder, not card.
- Root → folder → card → back to folder → force-quit → resume folder.
- Folder open with Add/capture sheet presented → force-quit → resume the folder under the sheet; sheet is not restored.
- Root with an active search query → force-quit → resume root with empty/cleared search (no query restore).
- Stored folder ID no longer resolvable → root; clear the bad stored value.

---

## Dependencies

- I1-T3 (folder navigation exists); I1-T2 (root folder list)

---

## Out of scope (this task)

- Custom-folder cold resume (I2-T1)
- Resume to card detail
- Resume mid-study deck
- Resume search query
- Resume capture sheet / edit drafts
- Warm resume / state restoration beyond the normal in-memory stack

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included

---

## Code

| Area | Paths / types |
|---|---|
| Core | `GLILastOpenedFolderClient` — `Packages/GlimpseCore/.../Clients/GLILastOpenedFolderClient.swift` |
| Features | Resume merged into `GLIAppFeature`; `GLILastOpenedFolderClient+Dependency.swift` |
| App | `GlimpseApp` injects `$0.lastOpenedFolder = .live()` |
| Tests | `GLILastOpenedFolderClientTests`; `GLIAppFeatureResumeFolderTests` |
