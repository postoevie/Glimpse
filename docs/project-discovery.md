# Stage 1 — Product Discovery

**Status:** Revised (v2 — personal-use-first) — re-accept after review

---

## Problem

Existing vocab/flashcard tools (e.g. Quizlet) make **saving** too slow (3–4 taps) and **returning** to study awkward — no easy way to find a saved word again, no lightweight organization, no way to get more out of a saved word than a plain flip card.

Glimpse optimizes for **capture → organize → find → study**: save a word or phrase in as few taps as possible, drop it into an easy-access folder, find it again fast, and get more out of it (saved meaning, related phrases, on-demand examples) than a dead flashcard.

## Primary user

**The owner, building this for personal use first.** This is not designed around a hypothetical generic "language learner" — it's designed around real usage:

- captures single words **and** phrases/idioms/collocations, not just single-word vocab;
- wants near-zero friction to save (translation provided manually, or generated in place on demand);
- organizes captures into folders for easy access — one optional custom folder, manual assignment only;
- finds saved items primarily by browsing/shuffling through them, secondarily by folder or search (keyword + meaning combined);
- on a card, wants to see the saved translation, related items already saved (duplicates allowed), and a way to discover **new** similar phrases worth saving;
- wants example sentences typed manually or generated **on demand**, never automatically, saved once generated.

Portfolio narrative describes this same real usage — it is not a separate audience to design for.

## Hero hypothesis (the bet)

**Frictionless personal vocab loop** — capture is the bottleneck; organizing, finding, and studying should stay just as low-friction.


| Step                  | v1 approach                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Capture               | 0–1 taps, fully fire-and-forget by default — Quick note widget, Share Extension, in-app; **word/phrase + translation** — just two fields, filled manually or generated. Language detection and folder are auto-decided with zero confirmation step. **Translation is never auto-generated, regardless of target language** — if not provided manually, the field is simply left **blank**; the user can generate it in place whenever they want (same on-demand rule as everywhere else). Corrections happen later from the vocabulary/folder view                |
| Organize              | An item can belong to **at most two folders**: it always lives in its **built-in per-language folder** — automatic, permanent — plus **one optional custom folder** (manual only in v1). Custom folders: **name required**; `sourceLanguage` from first item, then locked; **`targetLanguage` optional**, syncs from card add/edit, prefills new captures when folder selected; may contain 0 items; after `sourceLanguage` set, only matching items can join |
| Find                  | Folder browse; unified search (keyword + meaning combined, one search box) — always **global**, searches the whole vocabulary regardless of current folder; shuffle — scoped to **one folder at a time**                                                                                                                                                                                                                                                                                                                                                            |
| Study                 | Quizlet-style flashcards; can study a folder, a shuffled set within a folder, or a search result                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Card content          | Word/phrase + translation + **example** — three fields total; the example, just like translation, can be **provided manually or generated in place on demand**, never automatic. Plus related items already in your vocabulary — **same language as the source card**, global across all your folders, instant and works without network, duplicates allowed                                                                                                                                                                                                                                 |
| Discover similar (AI) | On-demand button on a card generates similar words/phrases (including idioms/collocations) beyond your saved vocabulary, always in the **same language as the source card**, which you can choose to save                                                                                                                                                                                                                                                                                                                                                           |
| Examples              | Type your own example sentence, or generate one in place on demand — a sentence in the item's source language plus its translation. Same on-demand-only rule as translation; graceful fallback when generation is unavailable                                                                                                                                                                                                                                                                                                                                                                              |


**Every card has its own `targetLanguage`, user-selectable at creation and editable on the card** (default: source language). Selecting a custom folder at capture **prefills** target from that folder if set — overwriting any prior pick; user can change before save. Editing a card's target **updates** its custom folder's `targetLanguage`. Folder target does **not** retroactively change other cards.

**Just one field, called translation — a translation into whatever target language the card has, which can be any language, including the source language itself.** When the target equals the source, the result is simply the same-language definition/explanation — not a separate category, just what "translation" naturally produces in that case. Same field, same mechanism, no special case in storage.

**Nothing is ever generated automatically.** The translation field is blank unless the user types it themselves or explicitly taps to generate it — no exceptions based on target language, no exception at capture time. This matches the on-demand rule already locked for AI examples and discover-similar: every AI generation action in the app is user-triggered.

**Generating a translation surfaces a few candidates to choose from — not one auto-picked result.** Discover-similar already works this way (multiple suggestions, user picks what to save). Example generation stays single-result (one sentence, saved directly) to keep that interaction simple.

**Two distinct AI mechanisms:**

- **Instant matching** powers related-items-on-card and the "meaning" half of unified search — works without network, over your own vocabulary only, same-language-only, duplicates allowed (no dedup in v1).
- **On-demand generation** powers translation, AI examples, and "discover similar phrases" — triggered by a button press, result is saved once generated. May require network.

Together, this is the full **lightweight AI** scope — not chat, not auto-curriculum, not "AI replaces study."

## Job to be done (one sentence)

*When I meet a word or phrase I want to remember, let me save it instantly, find it again easily, and get more out of it than a plain flashcard — without fighting the app.*

## Success signals (showcase + demo)

**90s demo path (main flow):** see a phrase elsewhere → capture in 1 tap (widget or share) → it lands in a folder → find it later via global search or folder → open the card, see its saved translation and related saved items (global) → tap "discover similar" and save a new phrase it surfaces → tap to generate an example sentence for a card.

**Extra, shown after the main flow:** open study mode, shuffled within that folder → flip cards.

**Portfolio signals:**

- Hero is obvious in first 30 seconds: **save it, find it, get more out of it, study it.**
- Capture feels faster than Quizlet (measurable: taps to save).
- Engineering story: offline-first words + instant matching (related items, meaning search), on-demand AI generation (translation, examples, similar phrases), modern iOS (widgets, Share Extension) — without over-architecting.

## Constraints (locked)

- Showcase project, not startup; solo dev; impress with **decisions**, not feature count.
- Built for personal use first — the owner is the primary (and initially only) user.
- **Glimpse** is product name (vocabulary app).
- v1 focus: **words and phrases** — not a general link/photo archive.

## Non-goals (v1)

- **Daily Discovery** and **"why today"** resurfacing feed — dropped (narrative, push notifications, "why today" framing). **Not the same as** shuffle/random study order, which stays in scope as a plain randomized view over already-saved items.
- General-purpose save-for-later archive (links, photos as hero entry types).
- Tags, multi-device sync, social, graph view, markdown editor, import/export.
- **OCR capture** (photo/camera → text) — v2; v1 capture is widget, Share Extension, and in-app add only.
- **Embedded chat** — per-card chat and global vocabulary chat — v2; v1 AI is on-demand generation only (translation, examples, discover similar), not conversational.
- Full language course / grammar curriculum / chat tutor.
- Duplicate detection/merging — re-capturing the same item creates a separate entry, no dedup in v1. Known limitation: related-items may surface a near-duplicate as a "related" result — accepted limitation for v1. **Future improvement (v2 candidate): source word/phrase uniqueness** — detect and merge/prevent exact re-captures of the same source text.
- Spaced repetition (SM-2 or similar) — v1 study is simple flip cards ± shuffle; SRS scheduling is v2.

## Open decisions — resolved in PRD

All 4 are now answered in `docs/prd.md`; kept here for record:

1. **Custom folder assignment** → manual only in v1.
2. **Language detection fallback** → `null` source + "Unsorted" folder; user may optionally pick manually at capture when UI allows.
3. **Capture surfaces** → widget + Share Extension + in-app; clipboard-detection and OCR capture deferred to v2.
4. **AI generation** → behavior locked (on-demand only, graceful fallback, same-language constraint for discover-similar); on-device vs cloud implementation itself deferred to Technical Design.

---

## Why this stage matters

Without a tight problem + hero + user, PRD and architecture drift into "another flashcard app" or back into "another notes app." Discovery forces one bet: **fast capture + easy organizing/finding + study**, not a generic multi-user product.

## Definition of Done (Stage 1)

- [x] Primary user and pain accepted (revised: built for personal use first, not a generic persona).
- [x] Hero = frictionless capture → organize → find → study, with AI as a study aid — agreed.
- [x] Daily Discovery / "why today" — explicitly dropped; shuffle/random study order explicitly kept and distinguished from it.
- [x] Folders reintroduced into v1 scope — agreed, reversing the earlier non-goal.
- [x] Lightweight AI scoped to **instant matching (related items + meaning search) + on-demand generation (translation + examples + similar phrases)** — agreed.
- [x] v1 non-goals explicit — agreed.
- [x] Open decisions 1–4 answered in PRD (Stage 2) — see `docs/prd.md`.

## Common mistakes to avoid

- Treating AI as the product (it's a **study aid**, not the headline).
- Re-introducing resurfacing / "why today" **narrative** as a side feature (shuffle/random order is fine — narrative and push are not).
- Building general archive capture before word/phrase capture works end-to-end.
- Perfecting SRS algorithm before a working capture → organize → find → study loop.
- Letting folders grow into a full tagging/nesting system — "easy access," not a filing cabinet.

## Quality bar

A stranger reading the one-pager understands **who it's for**, **what's different**, and **what you'll demo in 90 seconds** — without seeing code.