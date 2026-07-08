# Stage 7 — Technical Design

**Status:** Accepted — technology choices and system design. Module boundaries and folder layout are Stage 8 (Architecture). Drives Architecture below.

**Refs:** `docs/domain-modeling.md`, `docs/feature-breakdown.md`, `docs/prd.md`

---

## Why this stage

Feature Breakdown names *what* to ship. Technical Design locks *how* — frameworks, storage, extension sharing, AI stack, and detection/search mechanics — so Architecture (Stage 8) can define modules and Increment Planning (Stage 9) can sequence real work.

---

## Locked decisions (owner)

| Area | Choice |
|---|---|
| **Deployment target** | iOS **26.0** minimum |
| **Persistence** | **SwiftData** |
| **Shared store** | **App Group** + single **shared `ModelContainer`** (app, widget, Share Extension) |
| **UI** | **SwiftUI** (main app) |
| **App structure** | **TCA** (The Composable Architecture) |
| **Language detection** | **`NLLanguageRecognizer`** (NaturalLanguage); Apple default confidence → `null` / Unsorted when no dominant language |
| **Global search** | **SwiftData fetch + predicates** on `text` and `translation` |
| **Related items** | Same `sourceLanguage`, exclude self, order by **`createdAt` desc**; no fuzzy/embedding match in v1 |
| **AI strategy** | **Hybrid** — on-device when available, **OpenAI** cloud fallback |
| **On-device AI** | **Foundation Models / Apple Intelligence** when available *(default — confirm at implementation)* |
| **Cloud model** | **`gpt-4o-mini`** default |
| **API key** | Injected at **build time** (xcconfig / CI secret) → stored in **Keychain** on first launch; never committed |
| **Widget** | **Interactive widget + App Intent** — type and save without opening app |
| **Share Extension** | **SwiftUI** sheet — `text` + optional `translation` — confirmed in Architecture |
| **Preferences** | **`UserDefaults` in App Group** — resume (last folder), default custom folder ID |
| **Testing** | **Swift Testing** for unit/domain tests; XCTest for UI tests where needed |
| **Modularization** | **GlimpseCore** + **GlimpseAI** + **GlimpseFeatures** — see `docs/architecture.md` |

---

## Platform & targets

### Xcode targets (v1)

| Target | Role |
|---|---|
| **Glimpse** | Main SwiftUI app |
| **GlimpseWidget** | WidgetKit + App Intent capture |
| **GlimpseShare** | Share Extension |
| **GlimpseCore** (SPM) | SwiftData models, store, domain services, language detection, search |
| **GlimpseAI** (SPM) | Generation protocols, Foundation Models adapter, OpenAI client |
| **GlimpseFeatures** (SPM) | TCA features + shared SwiftUI views |
| **GlimpseTests** / **GlimpseUITests** | Swift Testing + UI tests |

All vocabulary-writing targets link **GlimpseCore** and use the **same App Group** identifier.

### App Group

- One shared **App Group** (e.g. `group.<bundle-id>.glimpse`).
- **`ModelContainer`** URL: App Group container directory.
- **`UserDefaults(suiteName:)`** for resume + default custom folder.
- Main app, widget, and Share Extension each construct the container with **identical schema + configuration** — single source of truth in `GlimpseCore`.

---

## Persistence (SwiftData)

Maps `docs/domain-modeling.md` entities to `@Model` types. Replaces the Xcode template `Item` (timestamp-only placeholder).

### `VocabItem`

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Stable identity |
| `text` | `String` | Required |
| `sourceLanguage` | `String?` | `nil` → Unsorted |
| `targetLanguage` | `String?` | User-owned |
| `translation` | `String` | Default `""` |
| `example` | `[String]` | SwiftData transformable / codable storage |
| `createdAt` | `Date` | Default ordering |
| `unsortedResolveUsed` | `Bool` | Default `false`; set `true` after Unsorted resolve |

**Relationships**

- `languageFolder` → **`LanguageFolder`** (required, inverse: items)
- `customFolder` → **`CustomFolder?`** (optional, inverse: items)

### `LanguageFolder`

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `languageCode` | `String` | e.g. `es`, `fr`, or sentinel **`unsorted`** for Unsorted bucket |
| `items` | `[VocabItem]` | Inverse |

Auto-created on first item with that source language (including Unsorted).

### `CustomFolder`

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `name` | `String` | Required |
| `sourceLanguage` | `String?` | `nil` until first item locks it |
| `targetLanguage` | `String?` | Optional cache; card → folder sync only |
| `items` | `[VocabItem]` | Inverse |

### Store access

- **`VocabularyStore`** (or equivalent) in **GlimpseCore**: single entry point for CRUD, folder assignment, re-file, Unsorted resolve, and invariant enforcement from domain doc.
- **Main app** uses `@ModelActor` or injected `ModelContext` from shared container.
- **Extensions** use lightweight async saves through the same store API — avoid duplicating business rules in extension targets.

### Migrations

- SwiftData **versioned schema** from first real schema — no pre-release data to preserve.
- Template schema (`timestamp`-only `Item`) is discarded before first feature increment.

---

## Language detection

**API:** `NLLanguageRecognizer` (NaturalLanguage framework).

**Capture pipeline (all entry points):**

1. Run recognizer on `text`.
2. If `dominantLanguage` is `nil` (or below Apple’s internal threshold — use library defaults, no custom cutoff) → `sourceLanguage = nil`, assign **Unsorted** folder.
3. Else → map `NLLanguage` to stored code (e.g. `es`, `fr`).
4. **Never re-run** on post-save `text` edits.

**In-app capture:** optional manual override before save (UI allows pick; locks on save).

**Widget / Share:** no manual pick — fire-and-forget to Unsorted on failure.

---

## Search

**Scope:** entire vocabulary (PRD §3).

**Implementation:**

- SwiftData `#Predicate` / fetch descriptor matching query against **`text`** and **`translation`** (case/diacritic-insensitive `localizedStandardContains`).
- Single combined result list — no separate “meaning mode.”
- Sorted by relevance heuristic for v1: prefix match first, then contains; tie-break `createdAt` desc.
- Runs **offline**; no Spotlight index in v1.

---

## Related items

**Query:** all `VocabItem` where `sourceLanguage == card.sourceLanguage` AND `id != card.id`, sorted by `createdAt` descending, capped (e.g. 20) for UI.

**Gate:** return empty if card `sourceLanguage == nil`.

No embeddings or substring scoring in v1.

---

## AI generation (hybrid)

### Protocol-first (GlimpseAI)

```
GenerationService
├── translate(text, sourceLanguage, targetLanguage) → [candidate strings]
├── example(text, sourceLanguage, targetLanguage) → [String]  // single result wrapped
└── discoverSimilar(text, sourceLanguage) → [candidate strings]
```

**Router:** `HybridGenerationService`

1. If **Foundation Models / Apple Intelligence** available on device → use on-device adapter.
2. Else → **OpenAI** adapter (`gpt-4o-mini`).
3. On any failure → surface error to UI; **no silent fallback** that overwrites user data.

All calls are **explicitly invoked from TCA effects** on button tap — never on appear, save, or background.

### OpenAI client

- HTTPS to OpenAI API; structured prompts per action.
- **Translation / discover similar:** request N candidates; UI picker before persist.
- **Example:** single JSON/array response → save to `example` as `[String]`; replace whole list.
- **Same-language gate** enforced in UI *and* service (reject if `sourceLanguage == nil`).

### API key lifecycle

1. Build injects `OPENAI_API_KEY` via **xcconfig** (local) / **CI secret** (pipeline) — **gitignored**.
2. On first launch (or first AI use), copy into **Keychain**; runtime reads Keychain only.
3. No key in repo, plist, or Swift source.

### On-device path *(open detail)*

- Use Apple **Foundation Models** APIs available on iOS 26 where supported.
- Capability check at runtime; treat “unavailable” same as network failure for UX (manual entry still works).
- Exact API surface to be confirmed against current Apple docs at implementation time.

---

## Capture surfaces

### In-app (F1.1)

- TCA feature: capture sheet from root add action.
- Runs detection → folder assignment → optional default custom folder pref (UserDefaults + language gate).
- Saves via `VocabularyStore`.

### Widget (F1.2)

- **WidgetKit** + **App Intent** — user enters text (optional translation) in-widget.
- Intent handler links GlimpseCore, runs same capture pipeline as app (no folder picker; default custom folder gate only).
- Reload timelines / open app optional — save must complete in-extension.

### Share Extension (F1.3)

- **SwiftUI** extension view: pre-filled shared text, optional translation field, Save.
- Same pipeline as widget; dismiss on success.

---

## Preferences (App Group UserDefaults)

| Key | Type | Purpose |
|---|---|---|
| `lastViewedFolderKind` | `String` | `language` \| `custom` \| `root` |
| `lastViewedFolderID` | `UUID?` | Folder to restore on launch |
| `defaultCustomFolderID` | `UUID?` | Sticky default; cleared if folder deleted |

Resume restores **navigation destination only** — not search text, scroll, or study deck index.

---

## TCA integration (main app)

- **One TCA `Store` per screen/feature** (folder list, folder detail, card detail, capture, study deck).
- **Dependencies** injected: `VocabularyStore`, `GenerationService`, `LanguageDetector`, `PreferencesClient`.
- **SwiftData** accessed from effects/reducers via `@Dependency` wrappers — keep `@Model` types out of view state where possible; use lightweight `Identifiable` structs for UI.
- Navigation: **`NavigationStack` + TCA `@Presents` / stack state** — single stack per IA; no tabs.

*(Module-per-feature layout → Stage 8.)*

---

## Testing strategy

| Layer | Tool | Focus |
|---|---|---|
| Domain / store | **Swift Testing** | Invariants, Unsorted resolve, folder rules, detection → folder mapping |
| AI adapters | **Swift Testing** + mocked HTTP | Prompt shaping, candidate parsing, nil-source gate |
| UI critical paths | **XCTest UI** | Capture save, folder browse, search, study entry |

In-memory **`ModelContainer`** for unit tests; App Group container for integration tests only when needed.

---

## Feature → component map

| Feature ID | Primary owner |
|---|---|
| X1 | `GlimpseCore` — `VocabularyStore`, shared `ModelContainer` |
| X2 | `GlimpseAI` — `HybridGenerationService` |
| X3, X4 | Main app TCA + `PreferencesClient` |
| F1.1 | App — `CaptureFeature` |
| F1.2 | Widget — App Intent + GlimpseCore |
| F1.3 | Share — `ShareView` + GlimpseCore |
| F1.4 | `GlimpseCore` — `LanguageDetector` |
| F2.x | `GlimpseCore` — folder + re-file + Unsorted resolve |
| F3.2 | `GlimpseCore` — `SearchService` |
| F4.2 | `GlimpseCore` — related-items query |
| F4.3–F4.5 | `GlimpseAI` + `CardDetailFeature` |
| F5.x | App — `StudyFeature` (in-memory deck shuffle) |

---

## Open items (resolve at implementation)

Resolved in `docs/architecture.md`: SPM split, App Group pattern, Share sheet, `example` storage, related-items cap (20), OpenAI retry (1×).

- [ ] **Foundation Models** API confirmation on iOS 26 SDK — adapter interface may need adjustment.
- [ ] Exact **bundle ID** → App Group string `group.<bundle-id>`.

---

## Non-goals (this stage)

- File/folder tree inside repo — Stage 8.
- Increment order — Stage 9.
- Visual design — Stage 13.
- v2: OCR capture, embedded chat — out of scope (see `feature-breakdown.md`).

---

## Definition of Done (Stage 7)

- [x] Persistence, sharing, detection, search, AI, extensions, and preferences decided.
- [x] Domain entities mapped to SwiftData shape at attribute level.
- [x] Feature IDs mapped to technical components.
- [x] Open items explicitly listed for Architecture / implementation.
- [x] Owner review — accepted.
- [x] Proceed to Stage 8 — Architecture.
