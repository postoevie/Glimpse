# Stage 4 — Information Architecture

**Status:** Accepted — screen/navigation structure only, no visual design. Built on the accepted `docs/prd.md` and `docs/user-flows.md`; drives Stage 5 (Domain Modeling) below.

---

## Navigation model

- **No tabs, no `TabView`.** Single navigation stack, rooted at the folder list. Postponing tab-based navigation keeps v1 simple and avoids committing to a structure before it's earned.
- **Study is not a top-level destination.** It's reached per-folder ("Study this folder" on a folder detail screen) or per-search-result ("Study these results"). There is no standalone Study scope-picker screen — you're always already scoped by the time you enter it.
- **Resume rule:** app reopens on whichever folder (or the root folder list, if none was open) was last viewed — not scroll position, not mid-deck state. Since there's only one stack, this is the entire resume rule; no tab-choice concept exists.

## Root: folder list

- Built-in per-language folders (auto, permanent, listed first) and custom folders (user-created, flat, no nesting) below. A persistent search bar sits above the list.
  - Search is **always global** — typing here searches the whole vocabulary regardless of which folder you're looking at, per PRD §3. It's a bar on the root screen, not a separate screen you navigate into.
- **Capture entry (root):** a persistent "add" action opens the in-app capture sheet — **default custom folder prefilled** when language gate matches (folder source equals non-null pending source); optional translation, source/target pickers (source not editable while a custom folder is selected), folder picker (**all** custom folders — selection forces source). The **same sheet** is also opened from folder detail (see below).
- **"New folder"** action lives here too — **name and source language required**; `targetLanguage` optional (from cards later). Empty folders are valid.

## Folder detail screen

- Items inside one folder (language or custom), pushed from the root.
- Actions: **Add** (same capture sheet as root), **Shuffle**, **Study this folder**, and for custom folders, folder management — **rename or delete only** (`sourceLanguage` set at create, immutable, always a real language code; `targetLanguage` is optional and shown but not directly editable — it follows cards). Empty folders show an empty list.
- **Add from folder detail:** opens the same in-app capture sheet with **source (and default target) prefilled from this folder** when the folder has a `sourceLanguage` (language folder, or custom folder — always has source) — source not editable while that context applies. **Unsorted:** source stays unset / detectable as on root. Save still follows Flow 1 placement rules.
- Language folders have no management UI — they're auto-created and permanent; an item's language folder is set at capture and **may change once** via Unsorted resolve; otherwise fixed.

## Search results

- Replaces the list below the search bar while a query is active — same screen as the root, not a new destination.
- Carries a **"Study these results"** action, entering Flow 5 scoped to that result set.

## Card detail (shared screen)

Reached from folder detail, search results, or mid-study (Flow 5) — one screen regardless of entry point. Shows word/phrase, translation field, example field, related items, and the on-demand actions (generate/edit translation, generate/edit example, discover similar, edit target language) exactly as specified in PRD §4.

- **Unsorted cards** (`sourceLanguage` null, resolve not used): **Move to language folder** and **Move to custom folder** — Unsorted-only, **once per card** (see domain model). Normal custom-folder picker hidden until resolve is used (or source is set).
- **Non-Unsorted cards:** custom-folder re-file only; no move-to-language-folder action.
- **Generate translation** and **discover similar** each present a small picker of candidates before anything is saved — both require **non-null `sourceLanguage`**. **Generate example** saves its single result directly, no picker — same gate. Manual translation/example entry still allowed on `null`-source cards. Same screen hosts both patterns — no separate screen needed for the picker (e.g. an inline sheet or list).

- **Mid-study jump to Card detail** is a push on top of the deck, not a navigation reset — the deck position underneath is preserved for that session. This is distinct from the app-level resume rule, which only governs what happens on app relaunch, not same-session detours.
- **Saving a "discover similar" suggestion** stays on the current card (toast/confirmation) rather than navigating to the new item's own card — keeps the fire-and-forget philosophy; the new item is reachable afterward via folder/search like anything else.

## Study deck screen

- Pushed from a folder detail screen or search results — never entered any other way (no standalone destination, per the navigation model above).
- Front/back flip, one card at a time, exit control. No progress persistence — closing or exiting always starts fresh next time (no SRS, per PRD §5).
- Exiting returns to whichever folder/search screen it was launched from — that's what "resume" restores on a later app relaunch too, since it's the same stack position.

## Capture surfaces outside the app

- **Quick note widget** and **Share Extension** write directly to the store — **`text`**, optional **`translation`**, **default custom folder** only when detection is non-null and matches that folder's `sourceLanguage` (no picker). Opening the app afterward, the item is already in its language folder (and custom folder if default applied).

---

## Cross-cutting decisions

- **No settings/account screen in v1** — there's nothing to configure yet (no accounts, sync, or preferences); revisit if v2 features (export, SRS) need one.
- **No standalone search screen** — it's a bar on the root, always global, never folder-scoped.
- **One capture sheet in-app**, opened from **root** or **folder detail** (same Flow 1 sheet; folder entry prefills source/target when the open folder has a `sourceLanguage` — language or custom). Study never duplicates capture — it's a study-only destination.
- **Tabs are explicitly postponed, not ruled out** — if the app grows a second top-level concern later, revisit; v1 doesn't need it.

---

## Non-goals (this stage)

- Visual design, layout, component styling — Stage 13 (Polish).
- Any tab-based or drawer-based navigation.
- A standalone Study destination reachable without a folder/search scope already chosen.

---

## Definition of Done (Stage 4)

- [x] Navigation fixed at a single stack, no tabs — Study confirmed as per-folder/per-search only, not a destination of its own.
- [x] Every screen from `user-flows.md` placed into a concrete hierarchy (root, pushed, or presented).
- [x] Card detail confirmed as one shared screen, not per-entry-point variants.
- [x] Folder management placed on the folder detail screen, not a separate destination.
- [x] Resume rule reduced to "last folder viewed" — no tab-choice concept.
- [x] Owner review — accepted.
- [x] Proceed to Stage 5 — Domain Modeling.
