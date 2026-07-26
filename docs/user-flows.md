# Stage 3 — User Flows

**Status:** Final — written against the accepted `docs/prd.md`. No open decisions remain; this supersedes the earlier pre-PRD skeleton.

---

## How to use this doc

Each flow: **Entry points** → numbered **Steps** → **Outcome**. Details (field names, on-demand rules, folder model) follow `docs/prd.md` exactly — this doc sequences them into user-facing steps, it doesn't redefine them.

---

## Flow 1 — Capture

**Entry points:** Quick note widget · Share Extension · in-app "add" on **root** or **folder detail** — widget/Share have no folder picker; they use **default custom folder on save** when language matches (otherwise language folder only).

1. User provides text (word or phrase) — typed, pasted, or shared from another app.
2. Optional, never required: type a translation; **source language** (auto-detected, **`null` if detection fails and user skips manual pick**, or manual when UI allows); **target language** (default: source when non-null); **custom folder prefilled with default** (last used or manually chosen) when language matches — user can change or clear. Picker shows folders empty or matching source (including `null`). **Selecting a folder prefills source and target if set — source locked after prefill; target can still change before save.** **Add from folder detail** prefills the same way from the open folder when it has a `sourceLanguage` (language folder or locked custom folder); Unsorted / unlocked empty custom → no forced source. Saving with a folder updates the default.
3. On save:
   - Language folder: **`null` source → "Unsorted"**; non-null → that language's folder.
   - The card's **target language** is whatever the user left selected (after any folder prefill).
   - If filed into a custom folder: folder's `sourceLanguage` is set from this item if still empty (first item); folder's `targetLanguage` updates to this item's target. Translation is **never auto-generated** — blank unless typed in step 2; generate later in Flow 4.
4. Item saved — appears in its language folder, its custom folder (if any), and the global vocabulary/search index immediately.

**Outcome:** New item = word/phrase + translation (often blank) + example (blank) + user-selected target language + language folder + at most one custom folder. No dedup check — re-capturing the same text always creates a new item.

---

## Flow 2 — Organize (folders)

**Entry points:** From capture (Flow 1, step 2) · vocabulary list (re-file an existing item) · folder management screen · **Unsorted resolve** on card detail (Unsorted cards only)

1. User views the folder list: built-in per-language folders (auto-created, permanent, no target language) and custom folders (user-created, flat list, no nesting).
2. User creates a custom folder with a **required name only** — no language fields at creation. Empty folders (0 items) are valid and accept **any** item as their first; that item's **source language** locks the folder. **`targetLanguage` on the folder is optional** — set/updated when cards with a target are added or when any card's target is edited. After `sourceLanguage` is set, **only matching items** can be added. Rename or delete anytime; `sourceLanguage` cannot change — create a new folder for a different source language.
3. **Normal re-file** (non-Unsorted cards): user manually files an item into a custom folder, or removes it — **at most one custom folder per item**, manual only. **Re-file into a folder updates the default custom folder.** Does **not** change `sourceLanguage` or language folder.
4. **Unsorted resolve** (Unsorted cards only, **once per item**): **Move to language folder** — pick language → `sourceLanguage` set → item leaves Unsorted. **Or Move to custom folder** — pick folder → item filed in; adopts folder's locked `sourceLanguage` if set (and moves language folder), or user picks source language if folder is empty. **Does not change item `targetLanguage`.** After resolve, normal re-file applies (when source is non-null); Unsorted-only actions hidden.
5. Language folder follows **`sourceLanguage`** — set at capture, or changed **once** via Unsorted resolve; fixed otherwise.

**Outcome:** Every item belongs to exactly one language folder (`null` source → Unsorted until resolve), plus at most one custom folder on top.

---

## Flow 3 — Find

**Entry points:** App launch (resumes last folder viewed) · folder list root

1. User lands on whichever folder (or the root folder list, if none) was open last — no tabs, single navigation stack; not scroll position or mid-deck state.
2. Find method:
   - **Browse a folder** — tap a language or custom folder, see its items. From folder detail, **Add** opens Flow 1 (same capture sheet; source/target prefilled from this folder when it has a `sourceLanguage`).
   - **Search** — one box, keyword or meaning combined; always searches the **entire vocabulary**, regardless of which folder is currently open.
   - **Shuffle** — randomized view of items within **one folder at a time** (language or custom) — not a global cross-folder shuffle.
3. Tap an item → Flow 4 (Card detail).

**Outcome:** User reaches a specific saved item via folder browse, global search, or folder-scoped shuffle; may also capture into the open folder’s language context via Add.

---

## Flow 4 — Card detail

**Entry points:** Tapped from Find (Flow 3) · tapped from Study (Flow 5)

1. Card shows: word/phrase, translation, example, **source language** (read-only — may show as unknown if `null`), **target language** (editable), and folder(s). **Unsorted cards (`sourceLanguage` null, resolve not used):** show **Move to language folder** and **Move to custom folder** — **once per card** (user picks one path). **Non-Unsorted cards:** normal custom-folder re-file only — no move-to-language-folder action.
2. **Related items** — same-language saved items, automatic, offline — **requires non-null `sourceLanguage`**; Unsorted/`null` cards show none.
3. If translation is blank (or the user wants to redo it), tap **"Generate translation"** → on-demand action presents **several candidate translations** in the card's own target language; user taps one to save it into the field — **requires non-null `sourceLanguage`** (Unsorted/`null` cards: manual entry only). If none fit, regenerate for a new set, or type one manually instead.
4. Tap **"Discover similar"** → on-demand AI suggests new words/phrases (including idioms/collocations), always in the **same language** as the card, beyond the user's own vocabulary — **requires non-null `sourceLanguage`** (Unsorted/`null` cards: button hidden or disabled).
   - 4a. User reviews suggestions, taps to save any of them → capture with **pre-filled `text` only**; normal capture rules for source/target/folders.
5. Tap **"Generate example"**, or type one manually → **`[String]`** (typically `[sourceSentence, translation]`); replaces whole list. **Generate** requires non-null `sourceLanguage` (Unsorted/`null` cards: manual entry only).
6. User can edit **`text`** and **target language** — target edit updates custom folder's `targetLanguage` if filed in one (**not vice versa**); **`sourceLanguage` stays locked** when `text` is edited.

**Outcome:** Card enriched with a translation and/or example (manual or generated) and/or newly captured related items via "discover similar."

---

## Flow 5 — Study (secondary, "extra")

**Entry points:** "Study this folder" from Flow 3 (folder detail) · "Study these results" from an active search — **no standalone Study destination**; always entered already scoped to a folder or search result set.

1. Deck scope is whatever the entry point implies: one folder, a shuffled subset within one folder, or the current search result set — no separate scope-picker screen.
2. Flashcard shown front (original text) → user flips → back (the card's translation field, whatever target language it holds — may be empty if none saved yet).
3. User can jump into Card detail (Flow 4) mid-study to generate/edit a translation or example, or discover similar phrases, then return to the deck.
4. User finishes the deck or exits — app returns to the folder/list it was launched from, per the resume rule (no mid-deck position saved).

**Outcome:** User reviewed a set of cards. No spaced repetition — every session is a fresh, non-persisted pick from the chosen scope.

---

## Cross-cutting: on-demand AI generation (Flows 1 & 4)

Translation, example generation, and "discover similar" all share one mechanism:

- Triggered by an explicit button press only — never automatic, never on card load, never a capture-time side effect.
- Result is persisted once generated (not regenerated silently on later views).
- Presentation differs by action: translation and discover-similar surface **multiple candidates** for the user to pick from; example generation is **single-result**, saved directly — a UI-complexity choice, not a different on-demand rule.
- **Related items**, **discover similar**, **translation generation**, and **example generation** require **non-null `sourceLanguage`**. Manual translation and example entry still allowed on `null`-source cards.
- Graceful fallback when generation is unavailable — rest of the app (capture, organize, find, study, related items) stays fully usable; manual entry is unaffected.
- On-device vs cloud implementation is a Technical Design decision, not defined here.

---

## Next steps

- Proceed to Stage 4 — Information Architecture (screen structure and navigation stack — no tabs; where folder management, Study entry points, and card detail live).
- Domain Modeling (Stage 5) can follow directly from the entities implied here: Item/Card, Language Folder, Custom Folder, with the target-language-at-creation rule as a core invariant.
