# I1-T1 — Implementation plan

**Type:** Implementation plan  
**Task:** `I1-T1-add-word.md`  
**Epic:** `../I1-capture.md`  
**Product refs (consulted):** `docs/user-flows.md` (Flow 1 in-app), `docs/information-architecture.md` (root Add → sheet), `docs/feature-breakdown.md` (F1.1), `docs/technical-design.md` / `docs/architecture.md` (Core store, capture sheet, dependencies)

---

## Brief task description

Ship a simple flat list of saved **word pairs** (word + translation) plus in-app **Add** that opens a capture sheet. Required word/phrase, optional translation. Save dismisses without confirmation; Cancel discards. No AI translation, no dedup. Pairs remain after sheet dismiss and after app relaunch. **No folders, no word editing, no language fields in this slice** — languages deferred.

---

## Reference

- Product task: `I1-T1-add-word.md`
- Epic: `../I1-capture.md`

---

## Code

**Target layout in Glimpse** (types use `GLI` prefix). Paths below are the blueprint destinations for this slice — implement or land here under the packages / app:

Feature roots (breadcrumb):

- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/AddWord/GLIAddWordFeature.swift` — `GLIAddWordFeature` / view
- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/WordsFolder/GLIWordsFolderFeature.swift` — `GLIWordsFolderFeature` / view

Supporting (no breadcrumb):

- `Packages/GlimpseCore/Sources/GlimpseCore/Models/GLIWordPair.swift`
- `Packages/GlimpseCore/Sources/GlimpseCore/Clients/GLIWordPairsClient.swift`
- `Packages/GlimpseCore/Sources/GlimpseCore/Store/GLIWordPairsModelActor.swift`
- `Packages/GlimpseCore/Sources/GlimpseCore/Store/Models/GLIWordPairEntity.swift`
- `Packages/GlimpseCore/Sources/GlimpseCore/Store/GLIModelContainerFactory.swift`
- `Packages/GlimpseFeatures/Sources/GlimpseFeatures/App/GLIAppView.swift` — hosts words folder
- `Glimpse/GlimpseApp.swift` — live `wordPairs` dependency wiring
- Package / app tests for AddWord, WordsFolder, and WordPairsClient

---

## Implementation steps

- [x] Add a simple list of saved word pairs (word + translation text only): no folders, no row navigation, no edit/delete of existing pairs.
- [x] Defer all language handling (source/target pickers, detection, Unsorted): capture and persist **only** word + translation.
- [x] Define a lightweight word-pair value (id, word, translation; example empty / omitted) in **GlimpseCore** (`GLIWordPair`).
- [x] Add a minimal persist API: `save` + `loadAll` that survives process death via **GlimpseCore** SwiftData (`GLIWordPairsClient` / model actor).
- [x] Wire `@Dependency` (or equivalent) for that persist API with live + in-memory/test values.
- [x] Finish **AddWord** TCA feature (`tca-engineer`): draft state for word + translation only; bindings via `.sending`; Cancel → dismiss only; Done → validate trimmed word → `delegate` with pair; parent dismisses after successful save; Done disabled when word empty/whitespace; `var body: some Reducer<State, Action>`.
- [x] Finish **AddWord** SwiftUI (`swift-developer`): Word + Translation fields, Cancel / Done, no language UI, no auto-generated translation.
- [x] Parent list feature: present Add sheet on `+`; on delegate, persist and refresh list via `fetchAll` / `changes()` stream; dismiss sheet after successful save.
- [x] Ensure identical text can be saved twice (new id each time).
- [ ] **Verification (manual):** list shows pairs; Add → Cancel → nothing saved; empty word → Done blocked; word-only save → row with blank/empty translation; word + translation → both shown; duplicate text → two rows; kill app → relaunch → list restored; no translation auto-fill.
- [x] **Tests (after verification):** `TestStore` for AddWord (bindings, cancel, done validation/delegate); persist API unit tests (save/load, duplicate text allowed); parent reducer test that delegate saves then list refreshes via `fetchAll` / `changes()`.

---

## Out of scope (this slice)

- Source/target language UI and detection
- Language folders, Unsorted routing, custom folders
- Editing or deleting existing pairs; card detail; resume-last-folder
- Widget / Share capture, search, study, AI generation
- Full `CapturePipeline` / folder invariants

---

## Open questions

- Persist in **GlimpseCore** for T1. → **Decided** — implement in GlimpseCore (see `docs/STATUS.md` Q1).

Product task now records **Deferred acceptance** (languages → T2); keep this plan aligned with that narrowing.
