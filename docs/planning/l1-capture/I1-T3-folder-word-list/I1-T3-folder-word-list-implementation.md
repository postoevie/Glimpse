# I1-T3 — Implementation plan

**Type:** Implementation plan  
**Task:** `I1-T3-folder-word-list.md`  
**Epic:** `../I1-capture.md`  
**Product refs (consulted):** `docs/user-flows.md` (Flow 3 + Flow 1 folder Add), `docs/information-architecture.md` (folder detail Add), `docs/feature-breakdown.md` (F3.1, F1.1), `docs/architecture.md` (`AppFeature` owns `NavigationStack` path)

---

## Brief task description

From the root language-folder list, tapping a folder (language or Unsorted) pushes that folder’s **word list** on the single nav stack. Words newest first; empty folder shows an empty state; back returns to root.

**Add** on the folder word list opens the **same** in-app capture sheet as root. Language folder → prefill/lock source (+ default target) to that folder’s language. Unsorted → no forced source (detection/manual as root). After save, list refreshes via existing `wordPairs.changes()`.

No card open, shuffle, study, search, custom folders, or list edit/delete.

---

## Reference

- Product task: `I1-T3-folder-word-list.md`
- Epic: `../I1-capture.md`
- Extends T1–T2 in packages (`GLI*`).

---

## Implementation steps

### 1. Domain / Core (`GlimpseCore`) — ✅ completed

- Persist API: `GLIModelActor.fetchWordPairs(inFolderID:)` + `GLIWordPairsClient.fetchWordPairsInFolder` — by folder **id**, sorted newest first (`createdAt` desc).
- Reuses T2 folder relationship; no schema change. Empty / unknown id → `[]`.
- Core unit tests added (empty, scoped, order). Keep Core free of TCA.

### 2. Folder word list UI (`GlimpseFeatures`) — ✅ completed

**TCA — `GLIFolderWordsFeature`:**

- State: folder `id` + `languageCode` + `words`; load on appear + refetch on `wordPairs.changes()`.
- `wordTapped` no-op stub for I1-T4. Failures → `reportIssue`.
- Breadcrumb: `// Task: I1-T3 — docs/planning/l1-capture/I1-T3-folder-word-list/`
- File: `FolderWords/GLIFolderWordsFeature.swift`

**View — `GLIFolderWordsView`:**

- Title Unsorted / localized language; list word + optional translation; empty state; taps send `wordTapped`.
- File: `FolderWords/GLIFolderWordsView.swift`

### 3. Navigation wiring (`GlimpseFeatures`) — ✅ completed

**TCA — `GLIAppFeature` owns path:**

- `StackState<Path.State>` with `.folderWords(GLIFolderWordsFeature)`.
- Parent handles `.languageFolders(.folderTapped(id))` → lookup folder → `path.append`; missing id → `reportIssue`.
- Child `folderTapped` remains no-op.

**View:**

- `GLIAppView`: `NavigationStack(path:)` + destination → `GLIFolderWordsView`.
- `GLILanguageFoldersView`: rows send `.folderTapped(folder.id)`.

### 4. Add from folder word list (`GlimpseFeatures`) — ✅ completed

Reuse existing Add capture feature/sheet from T1 — same `@Presents` pattern as `GLILanguageFoldersFeature`.

**TCA — `GLIFolderWordsFeature`:**

- `@Presents addWord`; `addButtonTapped`; save on `.delegate(.wordAdded)` then dismiss.
- Language folder: prefill source + target to `languageCode`, `didManuallySetSource: true`.
- Unsorted: blank draft (detection/manual as root).
- List refreshes via existing `wordPairs.changes()` observation.

**View — `GLIFolderWordsView`:**

- Toolbar + empty-state **Add** → `addButtonTapped`.
- Sheet → `GLIAddWordView`.

### 5. App shell

- Blueprint app: no new dependencies expected if Add reuses existing `wordPairs` + capture feature.

### 6. Verification (manual AC)

- Tap folder → word list opens.
- Newest first.
- Empty folder → empty state.
- Back → root folder list.
- Single stack, no tabs.
- Unsorted + one-word + many-word folders behave.
- **Add from language folder** → source locked to that language; save → word appears in list.
- **Add from Unsorted** → no forced source; save follows placement rules.
- Root Add still works unchanged.

### 7. Tests (after verify) — ✅ completed

- Core: fetch-by-folder scoped / newest-first / empty / unknown → `[]` (`GLIWordPairsClientTests`).
- `TestStore`: `GLIAppFeature` path push; `GLIFolderWordsFeature` load/empty/refresh; Add prefill language vs Unsorted; save+dismiss.
- No UI tests this slice.

---

## Out of scope (this slice)

- Word card (I1-T4)
- Shuffle, Study, search
- Custom folders (including Add prefilling a custom folder membership)
- Edit/delete from the list
- Resume last folder (I1-T6)

---

## Open questions

- None blocking — destination lives under `GLIAppFeature` path per architecture; Add sheet ownership (child vs app) chosen to match root Add pattern.
