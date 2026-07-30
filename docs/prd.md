# Stage 2 — Product Requirements (PRD)

**Status:** Accepted — resolves the 4 open decisions from `project-discovery.md`. Drives Stage 3 User Flows (final) below and Stage 4 Domain Modeling next.

---

## Scope recap

Full context lives in `project-discovery.md`. Locked: personal-use-first, capture → organize → find → study loop, folders (per-language auto + custom), global search, folder-scoped shuffle, on-demand AI (translation, examples, discover similar), no SRS/tags/sync/social in v1.

---

## 1. Capture

**Requirements:**

- An item is just **two fields**: word/phrase + translation. Both can be filled manually or generated — nothing more complex than that.
- Accept a word or phrase as plain text via three entry points: Quick note widget, Share Extension, in-app add.
- On save, without any confirmation step:
  - Detect the item's language.
  - Assign it to that language's built-in folder (creating the folder on first use of a language).
  - Translation is **never auto-generated**, regardless of target language. If not provided manually, the field is simply left **blank** — the user can generate it in place at any time (§4).
- User may optionally choose a custom folder and/or type their own translation at capture time — never required. The **add view prefills the default custom folder** (last used or last manually chosen) only when its `sourceLanguage` matches the card's pending **non-null** source; pending `null` never auto-prefills a default; user can change or clear. User may **optionally pick source and target language** when the UI allows (source: auto-detected, or manual override; if detection fails and user skips manual pick, source stays **`null`**) — **except** while a custom folder is selected (including default-prefilled): then pending `sourceLanguage` **is** that folder's code and is **not** editable or clearable to `null` until the folder selection is cleared. **Selecting a custom folder sets source from the folder and may prefill `targetLanguage`** — source not editable while selected; target can still change before save. Choosing/saving with a folder updates the default. Custom folder picker offers **all** custom folders; selecting one forces pending source to that folder's code.
- No duplicate check — re-capturing existing text always creates a new item.

**Resolved — minimum field set:** text only is required. Translation, source context, and custom folder are all optional at capture time.

**Resolved — capture surfaces for v1:** Quick note widget, Share Extension, in-app add. **Widget/Share Extension:** `text`, optional `translation` — **no folder picker**; applies **default custom folder** on save only when detection is **non-null** and matches that folder's `sourceLanguage`, otherwise no custom folder. **In-app add:** optional source/target pickers (source picker gated while a custom folder is selected); default custom folder **prefilled** on add view (same match language gate). Clipboard-detection deferred to v2.

---

## 2. Organize (folders)

**Requirements:**

- Every item always belongs to exactly one **language folder**, assigned at capture from `sourceLanguage`: **non-null → that language's folder**; **`null` → "Unsorted"**. Language folder **does not change** after capture **except via one-time Unsorted resolve** (below).
- User may additionally file an item into **at most one custom folder** — free-form **name and `sourceLanguage` required at creation**, flat list only (no nesting, no multi-membership). A custom folder may contain **zero items**. Its **`sourceLanguage` is a required language code set at create** — never `null`/empty/unlocked — and **immutable** afterward (even at 0 items). Only items with the same **non-null** `sourceLanguage` can join; Unsorted (`null` source) items cannot join without Unsorted resolve adopting the folder’s code. Its **`targetLanguage` is optional** — updated when a card with a target is added, or when any card in the folder has its target edited (**card → folder only, not vice versa**); remains even at 0 items. **Deleting a custom folder** removes custom-folder membership from affected items only.
- **A card's `sourceLanguage` is `null` or a language code after capture — not editable afterward**, except **one Unsorted resolve** may set it once. User may optionally set it manually at capture when the UI allows. **`text` is editable; `sourceLanguage` does not re-detect.** **`targetLanguage` is user-selectable at creation and editable afterward** — editing updates custom folder's `targetLanguage` if filed in one (**not vice versa**). Normal re-filing does not change the card's `targetLanguage` or `sourceLanguage`. Default target is `sourceLanguage` when non-null.
- **Unsorted resolve (once per card, Unsorted-only UI):** while `sourceLanguage` is **`null`** and resolve not yet used, the user may **Move to language folder** (pick language → sets `sourceLanguage`, moves language folder) **or Move to custom folder** (pick folder → files item; item **always adopts** that folder’s required `sourceLanguage` and moves language folder). Move to custom folder always leaves item source non-null. **At most once per card** — then normal custom-folder re-file only (when source is non-null). These move actions are **not shown on non-Unsorted cards**.
- **There's one field, called translation — not a separate "explanation" concept.** It's a translation into whatever target language is set on the card, which can be **any language**, including the source language itself. When target equals source, the result is simply the same-language definition/explanation — that's not a distinct category, just what translation naturally produces in that case. Applies identically to on-demand generation from the card and to AI examples (§4).
- **Nothing is ever generated automatically — no exceptions.** The translation field is blank unless provided manually; the user can generate it in place via an on-demand action, whether that's at capture or later.
- **No source-text uniqueness check in v1** — re-capturing the same word/phrase always creates a new item; accepted limitation (see Non-goals). **v2 candidate**: source word/phrase uniqueness — detect and merge/prevent exact re-captures.

**Resolved — custom folder assignment:** **manual only** in v1 — no AI-suggested folder. **Default custom folder** (last used or manually chosen, prefilled on in-app add / auto-applied on widget/Share only when folder source matches pending/detected non-null source) is sticky convenience, not a separate assignment rule.

**Resolved — language detection fallback:** when auto-detection fails, `sourceLanguage` is **`null`** and the item lands in **"Unsorted"** — unless the user **optionally picks a language manually at capture** (when the UI allows), in which case `sourceLanguage` is filled and the item goes to that language folder instead. **Otherwise immutable after save** — **`null` stays `null`** until **one Unsorted resolve** (above). Fire-and-forget preserved on widget/Share Extension when detection fails (`null` + Unsorted).

---

## 3. Find

**Requirements:**

- **Search** — single box, matches keyword or meaning together (no separate "search by meaning" UI); always searches the entire vocabulary regardless of which folder is currently open.
- **Folder browse** — list language folders and custom folders; open one to see its items.
- **Shuffle** — randomized view of items within **one folder at a time** (language or custom); not a global cross-folder shuffle.

---

## 4. Card

**Requirements:**

- A card is **word/phrase + translation + example** — three fields, not separate "explanation" slots — plus its own **`target language`**, user-selectable at creation and editable on the card (default: source language; prefilled from custom folder if one is selected at capture — see §2).
- **Translation and example are both blank unless provided manually.** Either can be typed by the user, or generated in place via an explicit on-demand action — never automatic, no exceptions, same rule for both fields. Generation always uses the card's own target language, whatever it is (per §2).
- **Translation generation presents several candidates; the user taps one to save it** — not a single auto-filled result. Requires **non-null `sourceLanguage`** (same gate as related items, discover-similar, and example generation). If none fit, regenerate for a new set, or type one manually instead — manual entry still allowed on `null`-source cards.
- **Example generation stays single-result** — saves to `example` as **`[String]`** (typically `[sourceSentence, translation]`); replaces the whole list. Requires **non-null `sourceLanguage`** (same gate). No candidate picker. Manual example entry still allowed on `null`-source cards.
- **`text` is editable** on the card; **`sourceLanguage` does not change** when edited.
- **Discover similar save** pre-fills **suggested `text` only** — normal capture rules apply for everything else.
- The user can manually edit a card's target language at any time — doing so doesn't touch existing translation/example content until the user explicitly regenerates it; **if the card is in a custom folder, the folder's `targetLanguage` updates to match**.
- **Related items** — other saved items in the **same language** (`sourceLanguage` non-null), surfaced automatically, works without network. Duplicates may appear (no dedup in v1 — accepted limitation).
- **Discover similar (AI)** — on-demand button; suggests words/phrases in the **same language** as the card (non-null `sourceLanguage`). Presents multiple suggestions; user picks which to save; saving one runs capture with **pre-filled `text` only**.
- All on-demand generation must **fail gracefully** when unavailable — rest of the card (existing translation, example, related items) stays fully usable; manual entry is unaffected either way.

---

## 5. Study

**Requirements:**

- Quizlet-style flip cards: front = original text, back = the card's translation field, whatever target language it holds — may be empty if none provided/generated yet.
- Study scope options: one folder, a shuffled subset within one folder, or the current search result set.
- No scheduling/spaced repetition — every session is a fresh, non-persisted pick from the chosen scope (exiting mid-deck does not resume mid-deck; app returns to whatever folder/list was open beforehand — no tabs, single navigation stack, per the resume rule).
- Positioned as a secondary action from a folder/search view — not the first thing surfaced after capture (matches the "extra" demo framing agreed in discovery).

---

## 6. AI generation (translation, examples, discover similar)

**Requirements:**

- Three things use this mechanism: translation (to any target language, including same-language), example sentences, and "discover similar phrases." **All three are on-demand only** — triggered by explicit button press, never automatic, never on card load, never a capture-time side effect. **Translation, example, and discover-similar generation all require non-null `sourceLanguage`**; manual translation/example entry still allowed on `null`-source cards.
- **Result presentation differs by action, not the on-demand trigger itself:** translation and discover-similar each present **multiple candidates** for the user to pick from; example generation produces a **single result** saved directly. This is a UI-complexity call (§4), not a change to the on-demand rule.
- App must remain fully functional (capture, organize, find, study, related items) when generation is unavailable.
- **On-device vs cloud implementation is deferred to Technical Design** — that's a framework/API choice, not a product requirement. What's locked here is the *behavior*: everything generation-related is on-demand, graceful fallback, and same-language constraint for "discover similar."

---

## Non-functional requirements

- **Capture latency**: perceptible as instant (0–1 taps) even though language detection + folder assignment happen synchronously in the background — these must not block or delay the save confirmation.
- **Single user, local data**: no accounts, no login, no multi-device sync in v1 — data lives on one device.
- **Offline-first for the core loop**: capture, organize, find, study, and related items must all work with no network connection. Only the on-demand AI actions (translation, examples, discover similar) may depend on connectivity (if cloud-based — see §6).

---

## Out of scope (v1) — recap

See `project-discovery.md` Non-goals for full list: no resurfacing/"why today" feed, no tags, no multi-device sync, no social, no graph view, no spaced repetition, no duplicate detection, no folder nesting, no OCR capture (v2), no embedded chat per card or global (v2).

---

## Definition of Done (Stage 2)

- [x] Every discovery-stage open decision resolved above.
- [x] Requirements stated per feature area (Capture, Organize, Find, Card, Study, AI generation).
- [x] Non-functional requirements stated (latency, single-user/local, offline-first core loop).
- [x] Owner review — accepted.
- [x] `user-flows.md` finalized against these requirements.
