# I1-T2 — Implementation plan

**Type:** Implementation plan  
**Task:** `I1-T2-language-folders.md`  
**Epic:** `../I1-capture.md`  
**Product refs (consulted):** `docs/user-flows.md` (Flow 1–2), `docs/information-architecture.md` (root = folder list), `docs/domain-modeling.md` (Language Folder / Unsorted), `docs/technical-design.md` (`NLLanguageRecognizer`, `LanguageFolder`, item ↔ folder), `docs/architecture.md` (Core Models/Store/Services; Features per screen)

---

## Brief task description

Replace the T1 flat word list as the app root with a **language-folder list**. On in-app Add, detect or optionally set **source language**, default **target** to source when known (editable; translation still never auto-filled). Persist placement into the matching language folder or **Unsorted**; auto-create folders on first use. No rename/delete of language folders. Opening a folder’s word list is **I1-T3**.

---

## Reference

- Product task: `I1-T2-language-folders.md`
- Epic: `../I1-capture.md`
- Extends T1 in packages (`GLI*`).

---

## Implementation steps

### 1. Domain / Core (`GlimpseCore`) — ✅ completed

- Extend `GLIWordPair` with `sourceLanguage: String?`, `targetLanguage: String?`; keep word + translation.
- Add `GLILanguageFolder` model (`id`, `languageCode` including sentinel `unsorted`) and SwiftData entities + relationships (item → exactly one language folder).
- Persist API: save item with languages + folder assignment; `GLILanguageFoldersClient.fetchLanguageFolders`; ensure save auto-creates folder when missing.
- Add `GLILanguageDetectorType` / `GLILanguageDetector` using **`NLLanguageRecognizer`**: top hypothesis ≥ **0.9** → code; else `nil` → Unsorted.
- Wire detector via client or service used at capture; keep Core free of TCA.
- Shared store actor: `GLIModelActor` (word pairs + folders).

### 2. Root UI (`GlimpseFeatures`) — ✅ completed

**TCA — `GLILanguageFoldersFeature`** (renamed from `GLIWordsFolderFeature`; `GLIAppFeature` scoped):

- State: folder list (not flat words); Add sheet presentation (`@Presents`).
- Actions: load folders on appear / on store changes; present Add; handle Add delegate → persist → refresh folders.
- Effects: `fetchLanguageFolders` + `changes()` (or equivalent); save via existing word-pairs / vocabulary client.
- No navigation into a folder (I1-T3); tap is no-op or stub.

**View — `GLILanguageFoldersView`:**

- List of language folders; empty state when none yet.
- Folder row: display name (localized language or “Unsorted”); **no** rename/delete controls.
- Toolbar / FAB Add → sheet.
- Wire `StoreOf<…>` bindings only; no domain logic in the view.

App DI: inject `languageFolders` live client.

### 3. Capture UI (`GlimpseFeatures`) — ✅ completed

**TCA — `GLIAddWordFeature`:**

- Debounced detection on word text settle (400ms) + final sync detect on Done if source not manual; optional manual source override.
- When source becomes non-null, default `targetLanguage = source` unless user already changed target.
- Done: emit draft with languages; require non-empty word; translation optional; never generate translation.
- `@Dependency(\.languageDetector)` + live inject in app entry.

**View — `GLIAddWordView`:**

- Word + optional translation fields.
- Source / target pickers (system language codes; Source “Unsorted” → nil).
- Done / Cancel; no AI affordances.

### 4. App shell — ✅ completed

- `GlimpseApp`: inject `wordPairs`, `languageFolders`, `languageDetector` live values; App Group via `GLIAppGroup`.

### 5. Verification (manual AC) — pending owner

- Root is folder list, not flat words.
- Save with detected source → folder appears / word lands in that language folder.
- Fail/skip detection → Unsorted; save not blocked.
- Folders appear as languages are used; cannot rename/delete.
- Target settable at capture; translation blank unless typed.
- Word-only save still works.

### 6. Tests (after verify) — ✅ completed

- Core: word-pair persist / fetch tests green (`GlimpseCore`).
- `TestStore`: AddWord source/target + LanguageFolders root/save/refresh green (`GlimpseFeatures`, 13 tests).
- No UI tests required this slice.

---

## Out of scope (this slice)

- Folder detail / word list (I1-T3)
- Custom folders, default custom folder, Unsorted resolve
- Card detail, edit/delete, resume
- Widget / Share, search, study, AI generation

---

## Code

Feature roots (breadcrumb):

- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/LanguageFolders/GLILanguageFoldersFeature.swift`
- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/LanguageFolders/GLILanguageFoldersView.swift`
- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/AddWord/GLIAddWordFeature.swift`
- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/AddWord/GLIAddWordView.swift`

Supporting:

- `Packages/GlimpseCore/.../GLIWordPair.swift`, `GLILanguageFolder.swift`
- `Packages/GlimpseCore/.../GLILanguageDetector.swift`, `GLILanguageDetectorClient.swift`
- `Packages/GlimpseCore/.../GLILanguageFoldersClient.swift`, `GLIWordPairsClient.swift`, `GLIModelActor.swift`
- `Glimpse/GlimpseApp.swift`

---

## Status

**Implementation done** (steps 1–4, 6). Step 5 = owner manual AC verify before product-task close.
