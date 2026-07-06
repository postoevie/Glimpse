# Stage 1 — Product Discovery

**Status:** Revised (v2 — personal-use-first) — re-accept after review

---

## Problem

Existing vocab/flashcard tools (e.g. Quizlet) make **saving** too slow (3–4 taps) and **returning** to study awkward — no easy way to find a saved word again, no lightweight organization, no way to get more out of a saved word than a plain flip card.

Glimpse optimizes for **capture → organize → find → study**: save a word or phrase in as few taps as possible, drop it into an easy-access folder, find it again fast, and get more out of it (saved meaning, related phrases, on-demand examples) than a dead flashcard.

## Primary user

**The owner, building this for personal use first.** This is not designed around a hypothetical generic "language learner" — it's designed around real usage:

- captures single words **and** phrases/idioms/collocations, not just single-word vocab;
- wants near-zero friction to save (manually typed or AI-generated explanation/translation);
- organizes captures into folders for easy access — needs to decide manual vs automatic assignment;
- finds saved items primarily by browsing/shuffling through them, secondarily by folder or search (keyword + meaning combined);
- on a card, wants to see the saved explanation/translation, related items already saved (duplicates allowed), and a way to discover **new** similar phrases worth saving;
- wants example sentences generated **on demand**, not automatically, and saved once generated.

Portfolio narrative describes this same real usage — it is not a separate audience to design for.

## Hero hypothesis (the bet)

**Frictionless personal vocab loop** — capture is the bottleneck; organizing, finding, and studying should stay just as low-friction.


| Step                  | v1 approach                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Capture               | 0–1 taps, fully fire-and-forget by default — Quick note widget, Share Extension, in-app; language detection, folder, and translation are all auto-decided with zero confirmation step. User can optionally type their own explanation/translation/folder at capture time instead of relying on auto-detection, but it's never required — corrections otherwise happen later from the vocabulary/folder view                                                                                                                                                                                                                                     |
| Organize              | An item can belong to **multiple folders at once**: it always lives in its **built-in per-language folder** (e.g. "Spanish") — automatic, permanent, like a smart folder — plus any number of free-form **custom folders** (topic, theme, anything) added on top, optionally. Each per-language folder has its own **translation/output language** (e.g. Spanish → English) — AI-guessed by default, user can change it manually; changing it only affects new captures going forward, existing items keep their original translation unless manually regenerated. Manual vs automatic assignment method for custom folders — **open decision** |
| Find                  | Folder browse; unified search (keyword + meaning combined, one search box) — always **global**, searches the whole vocabulary regardless of current folder; shuffle — scoped to **one folder at a time**                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Study                 | Quizlet-style flashcards; can study a folder, a shuffled set within a folder, or a search result                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Card content          | Shows saved explanation/translation; related items already in your vocabulary — **same language as the source card**, global across all your folders, instant and works without network, duplicates allowed                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Discover similar (AI) | On-demand button on a card generates similar words/phrases (including idioms/collocations) beyond your saved vocabulary, always in the **same language as the source card**, which you can choose to save                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| AI examples           | On-demand button generates an example sentence in the item's source language **plus its translation** (using the folder's output language), then saves both to the card; graceful fallback when unavailable                                                                                                                                                                                                                                                                                                                                                                                                                                     |


**Two distinct AI mechanisms:**

- **Instant matching** powers related-items-on-card and the "meaning" half of unified search — works without network, over your own vocabulary only, same-language-only, duplicates allowed (no dedup in v1).
- **On-demand generation** powers AI examples and "discover similar phrases" — triggered by a button press, result is saved once generated; on-device vs cloud is still open (see Open decisions). May not be fully offline.

Together, this is the full **lightweight AI** scope — not chat, not auto-curriculum, not "AI replaces study."

## Job to be done (one sentence)

*When I meet a word or phrase I want to remember, let me save it instantly, find it again easily, and get more out of it than a plain flashcard — without fighting the app.*

## Success signals (showcase + demo)

**90s demo path (main flow):** see a phrase elsewhere → capture in 1 tap (widget or share) → it lands in a folder → find it later via global search or folder → open the card, see its saved translation and related saved items (global) → tap "discover similar" and save a new phrase it surfaces → tap to generate an example sentence for a card.

**Extra, shown after the main flow:** open study mode, shuffled within that folder → flip cards.

**Portfolio signals:**

- Hero is obvious in first 30 seconds: **save it, find it, get more out of it, study it.**
- Capture feels faster than Quizlet (measurable: taps to save).
- Engineering story: offline-first words + instant matching (related items, meaning search), on-demand AI generation (examples, similar phrases), modern iOS (widgets, Share Extension) — without over-architecting.



## Constraints (locked)

- Showcase project, not startup; solo dev; impress with **decisions**, not feature count.
- Built for personal use first — the owner is the primary (and initially only) user.
- **Glimpse** is product name (vocabulary app).
- v1 focus: **words and phrases** — not a general link/photo archive.



## Non-goals (v1)

- **Daily Discovery** and **"why today"** resurfacing feed — dropped (narrative, push notifications, "why today" framing). **Not the same as** shuffle/random study order, which stays in scope as a plain randomized view over already-saved items.
- General-purpose save-for-later archive (links, photos as hero entry types).
- Tags, multi-device sync, social, graph view, markdown editor, import/export.
- Full language course / grammar curriculum / chat tutor.
- Duplicate detection/merging — re-capturing the same item creates a separate entry, no dedup in v1. Known limitation: related-items may surface a near-duplicate as a "related" result — acceptable trade-off for v1.
- Spaced repetition (SM-2 or similar) — v1 study is simple flip cards ± shuffle; SRS scheduling is v2.



## Open decisions (resolve before PRD)

1. **Custom folder assignment** — beyond the automatic, permanent per-language folder, does the user additionally get manual-only vs AI-suggested/automatic vs hybrid assignment into custom folders; how many folders is "easy access" (flat list vs any nesting).
2. **Language detection fallback** — what happens when language can't be confidently detected (ambiguous, mixed, or unsupported language) — separate "Unsorted" bucket vs best-guess folder vs prompt the user.
3. **Capture surfaces** — widget-only vs widget + clipboard detection vs Share from browser; minimum fields per item (text, explanation/translation, source context).
4. **AI generation** — on-device vs cloud, for both example sentences and "discover similar phrases"; offline behavior when unavailable.

---



## Why this stage matters

Without a tight problem + hero + user, PRD and architecture drift into "another flashcard app" or back into "another notes app." Discovery forces one bet: **fast capture + easy organizing/finding + study**, not a generic multi-user product.

## Definition of Done (Stage 1)

- [x] Primary user and pain accepted (revised: built for personal use first, not a generic persona).
- [x] Hero = frictionless capture → organize → find → study, with AI as a study aid — agreed.
- [x] Daily Discovery / "why today" — explicitly dropped; shuffle/random study order explicitly kept and distinguished from it.
- [x] Folders reintroduced into v1 scope — agreed, reversing the earlier non-goal.
- [x] Lightweight AI scoped to **instant matching (related items + meaning search) + on-demand generation (examples + similar phrases)** — agreed.
- [x] v1 non-goals explicit — agreed.
- [ ] Open decisions 1–4 answered **in PRD** (Stage 2) — required before requirements are finalized, not deferred to Technical Design.



## Common mistakes to avoid

- Treating AI as the product (it's a **study aid**, not the headline).
- Re-introducing resurfacing / "why today" **narrative** as a side feature (shuffle/random order is fine — narrative and push are not).
- Building general archive capture before word/phrase capture works end-to-end.
- Perfecting SRS algorithm before a working capture → organize → find → study loop.
- Letting folders grow into a full tagging/nesting system — "easy access," not a filing cabinet.



## Quality bar

A stranger reading the one-pager understands **who it's for**, **what's different**, and **what you'll demo in 90 seconds** — without seeing code.