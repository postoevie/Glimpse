Project: Glimpse

**Save it in a glimpse. Actually find it and use it later.**

A personal vocabulary app — capture words and phrases in 0–1 taps, organize them automatically, find them fast, and get more out of them than a plain flashcard.

Built for personal use first, not a generic "language learner" product.

## One job

When you meet a word or phrase worth remembering, save it instantly, find it again easily, and get more out of it than a dead flashcard — without fighting the app.

## Hero mechanism v1: Frictionless personal vocab loop

The bottleneck is **capture**. Everything else — organizing, finding, studying — stays just as low-friction.

1. **Capture** — word or phrase in 0–1 taps; language + folder decided automatically, translation stays blank unless provided manually or generated in place on demand
2. **Organize** — auto-sorted into a per-language folder; add one free-form custom folder on top, optionally
3. **Find** — global search (keyword + meaning), folder browse, or shuffle within a folder
4. **Card** — saved translation, related items from your own vocabulary, examples (manual or generated) and "discover similar" suggestions
5. **Study** *(extra)* — Quizlet-style flip cards, scoped to a folder, shuffle, or search result

## Capture

- **Word or phrase** — including idioms and collocations, not just single words
- **Just two fields: word/phrase + translation** — either can be provided manually or generated in place
- **Translation is never auto-generated**, regardless of target language; if not provided manually, it's simply left blank until you generate it in place, whenever you want
- **Fire-and-forget** — language detection and folder are decided automatically; no confirmation step required
- **From anywhere** — in-app, Share Extension, Quick note widget

Goal: fewer taps than Quizlet (target 0–1 from widget or share).

## Organize

- Every item lives in its **language folder** automatically (e.g. "Spanish") — detected on capture, purely groups by source language
- Add it to **one custom folder** on top — optional; name required; source language from first item then locked; optional target syncs from cards and prefills new captures when folder is selected

## Find

- **Search** — one box, keyword or meaning, always searches your whole vocabulary
- **Folder browse** — by language or custom folder
- **Shuffle** — random pass through the items in one folder

## Card

- A card is **word/phrase + translation + example**, plus **`targetLanguage` selectable at creation and editable on the card** (default: source; prefilled from custom folder when selected at capture)
- Translation and example are both blank until provided manually or generated in place on demand, using the card's own target — generating a translation shows a few candidates to pick from; generating an example produces one result directly
- **Related items** — other saved words/phrases in the same language, from your own vocabulary, works offline
- **Discover similar (AI)** — on-demand button suggests new similar words/phrases (including idioms) to save
- **Example sentence** — type your own, or generate one in place on demand (sentence + translation), saved to the card

## Study

- Flip cards from a folder, a shuffled subset of a folder, or a search result
- Simple front/back — no spaced repetition in v1

## Not in v1

- No daily resurfacing / "why today" feed (shuffle is just a randomized view, not a discovery feed)
- No tags, multi-device sync, social features, or graph view
- No spaced repetition scheduling (v2)
- No duplicate detection — re-capturing something just creates a new entry (accepted limitation)

## v2 (after public showcase)

- Spaced repetition beyond simple flip cards
- Source word/phrase uniqueness — detect and merge/prevent exact re-captures
- **OCR capture** — photo or camera → extract text → same capture pipeline as Share/widget
- **Embedded chat** — AI chat scoped to one card, plus a global chat over the vocabulary
- Voice pronunciation practice
- Import/export

## Demo scenario (90 sec)

See a phrase elsewhere → capture in 1 tap → it lands in a folder automatically → find it again via search → open the card, see its translation and related items → discover and save a similar phrase → generate an example sentence. *(Extra: open study mode, shuffled within that folder, flip cards.)*
