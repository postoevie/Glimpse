# I2 — Organize (custom folders + update membership)

**Type:** Product epic
**Parent:** `docs/increment-planning.md` → I2
**Product refs:** `user-flows.md` (Flow 1 custom folder, Flow 2), `information-architecture.md` (root, folder detail, card), `domain-modeling.md` (Custom Folder, default custom folder, source + membership), `feature-breakdown.md` (F2.2–F2.5)

---

## Epic outcome

User creates custom folders, files words into them at capture or from the card, keeps a sticky default custom folder for repeat capture, and **updates membership** on the card (Source + Custom folder): Unsorted → language only, Unsorted → language + custom, or back → Unsorted.

---

## User problem

Language folders alone are not enough for personal groupings (topics, trips, courses). Words that landed in Unsorted need a clear way to set source and optional custom folder — and to return to Unsorted if source is cleared. Repeat captures should not force re-picking the same custom folder every time.

---

## User story

**As a** user collecting vocabulary across languages,
**I want** custom folders, card update membership, a remembered default folder, and a clear way to leave or return to Unsorted,
**so that** my words stay organized the way I think about them — without fighting language folders.

---

## User journey (end state)

1. User opens the app root and sees language folders, then custom folders below.
2. User creates a custom folder with a **name and source language** (source required at create; immutable afterward).
3. User captures a word with a custom folder selected (or default always-prefilled on root Add); pending source is forced from the folder.
4. On a later **root Add**, capture offers a custom-folder picker of **all** custom folders; the **default** is **always** prefilled when one exists; user can change or clear.
5. While a custom folder is selected (including default-prefilled), pending source is that folder’s code (not editable); target may prefill and stay editable; user saves.
6. The word appears in its language folder **and** in the chosen custom folder; folder target may update; the default preference updates.
7. On any saved card, user **updates membership** via Source + Custom folder (one flow):
   - **Unsorted → language only:** set Source to a language (Custom folder None) → leaves Unsorted; no custom membership.
   - **Unsorted → language + custom:** pick a Custom folder → item adopts that folder’s source, moves to the matching language folder, and gains custom membership.
   - **→ Unsorted:** set Source to **Not set** → language folder Unsorted; custom membership cleared.
   - With a known source: assign/clear custom folder when sources match; changing Source clears custom membership on mismatch.
8. User renames or deletes a custom folder; delete only clears custom membership (words stay in language folders); if it was the default, the default clears.
9. After relaunch, folders, membership, and the default preference remain; cold relaunch also restores the last opened folder, including a custom folder.

---

## Build order (product sequence)

1. Custom folder create / rename / delete + root listing + open/browse + resume extends to custom folders (create collects name **and** source language)
2. Capture: custom-folder picker (**all** folders), source forced from selected folder, default custom folder preference
3. Card membership — assign / remove custom folder when source is known (match folder source only)
4. Card membership — Unsorted transitions (null source): Source → language only, or Custom folder (adopts source); Source editable later including back to Not set / Unsorted
5. End-to-end acceptance

---

## In scope

- Custom folders: create (name + source language required), rename, delete
- Custom folders on root (below language folders); open and browse words
- Empty custom folders valid and openable
- Folder `sourceLanguage` / `targetLanguage` rules (source set at create, immutable; target optional cache from cards; not user-edited on the folder after create)
- Custom folder picker at in-app capture (**all** folders); root/Unsorted always-prefill default; language-folder Add match gate; selected folder defines pending source (not editable); target may prefill
- Default custom folder preference (prefill on add when source match; update on save / file-into / manual pick; clear on delete)
- **Update membership** on card (single flow): Source + Custom folder drive language folder and optional custom membership
  - Unsorted → language only | Unsorted → language + custom | → Unsorted (Source Not set)
  - Known source: assign/remove custom when sources match; clear custom on source mismatch
- Offline use without an account

---

## Out of scope

- Search and shuffle (I3)
- Related words (I4)
- Study mode (I5)
- Widget and Share Extension (I6) — including silent default-folder apply on those surfaces
- AI translation, examples, or discover-similar (I7)
- Changing how language folders are auto-created (already I1)
- Nested folders, tags, multi-custom membership

---

## Product requirements

- Custom folders are flat; **name and `sourceLanguage` required at creation**; folder source is a real language code and immutable afterward.
- Only items whose **non-null** `sourceLanguage` equals the folder’s code may join; Unsorted items join a custom folder only via membership that adopts the folder’s source.
- While a custom folder is selected at capture (including default-prefilled), pending source is that folder’s code — not editable / not clearable to null; clearing the folder restores normal source rules. Target may prefill and stay editable. Picker offers **all** custom folders; selection forces source.
- Folder `targetLanguage` is optional and follows cards (card → folder only); never edited directly on the folder.
- An item has at most one custom folder.
- **Update membership** is one card flow (Source + Custom folder). Setting custom folder while source is null **adopts** the folder’s required source. Assigning custom while source is non-null requires a source match and does not by itself change source. Clearing Source to null → Unsorted and clears custom membership. Language folder always follows Source. Folder `sourceLanguage` is never changed by membership updates. Item `targetLanguage` is not changed by membership updates (folder target may sync card → folder when filing into custom).
- Default custom folder is prefilled on in-app add only when folder source equals pending non-null source; pending `null` never auto-prefills; user may change or clear before save (manual select still forces source).
- Deleting a custom folder clears custom membership only; language folders and item content otherwise unchanged; clears default if that folder was default.
- Language folders remain non-renamable / non-deletable.
- Cold relaunch restores the last opened folder, including custom folders (same resume surface as I1: not card, sheet, or scroll; stale/deleted → root).

---

## Feature mapping

| Product capability | Source feature IDs |
|---|---|
| Custom folder management | F2.2 |
| Card membership (known source) | F2.3 |
| Card membership (Unsorted transitions) | F2.4 |
| Default custom folder preference | F2.5 |
| Browse custom folders (extends folder browse) | F3.1 |
| Capture filing into custom folder | F1.1 (custom-folder slice) |

---

## Tasks

1. **Custom folder management** — `I2-T1-custom-folders/I2-T1-custom-folders.md`
   Create (name + source language) / rename / delete; list on root below language folders; open empty or filled custom folders; resume extends to custom folders.

2. **Capture with custom folder + default preference** — `I2-T2-capture-custom-folder/I2-T2-capture-custom-folder.md`
   Picker (**all** folders), root always-prefill default, language-folder match gate, source forced from selected folder, sticky default on save / manual pick.

3. **Card membership — custom folder (known source)** — `I2-T3-card-membership/I2-T3-card-membership.md`
   Slice of update-membership: assign/remove custom when sources match; updates default.

4. **Card membership — Unsorted transitions** — `I2-T4-unsorted-membership/I2-T4-unsorted-membership.md`
   Slice of update-membership: Unsorted → language only, Unsorted → language + custom, and later → Unsorted via Source Not set.

5. **End-to-end acceptance** — `I2-T5-e2e-acceptance/I2-T5-e2e-acceptance.md`
   Full epic journey offline; verify against Epic acceptance criteria.

6. **Auto-prune empty language folders** — `I2-B8-auto-prune-language-folders/I2-B8-auto-prune-language-folders.md`
   Language folder with 0 words (including Unsorted) is removed; next save recreates it. User still cannot delete language folders.

---

## Epic acceptance criteria

- [x] User can create a custom folder with a name **and** source language and see it on the root below language folders.
- [x] User can rename and delete a custom folder; delete removes custom membership only; words remain in language folders.
- [x] Deleting the default custom folder clears the default preference.
- [x] Empty custom folders open and show an empty list.
- [x] At capture, user can pick (or clear) any custom folder; selecting a folder forces pending source.
- [x] Default custom folder is **always** prefilled on root / Unsorted Add when one exists; language-folder Add prefills default only when sources match.
- [x] Selecting a custom folder at capture sets pending source to the folder’s code (not editable / not clearable to null while selected); target may prefill and stay editable before save.
- [x] Saving into a custom folder places the word there and updates the default preference.
- [x] **Update membership:** Unsorted → language only (Source set, custom None); Unsorted → language + custom (custom pick adopts folder source); → Unsorted (Source Not set clears custom); known-source assign/remove custom when sources match.
- [x] Membership updates do not change item target language; folder source stays immutable (set at create).
- [x] Changes remain after relaunch; cold relaunch restores the last opened folder including a custom folder.
- [x] The complete journey works offline and without an account.

---

## Epic Definition of Done

- [x] All product tasks are accepted.
- [x] Happy path and listed edge cases match approved user flows (Flow 2 + capture custom-folder rules).
- [x] Every screen has loading, empty, and relevant error states defined in its task.
- [x] No out-of-scope capability is included.
- [x] Owner verifies the complete epic outcome on a device or simulator.

---

## Blueprint status note

Tasks 2, 3, 4, and 6 (capture filing + card membership + auto-prune) are implemented in `GlimpseCore` — `GLIModelActor.assignCustomFolder` / `updateSource` / `updateCustomFolder` / `pruneEmptyLanguageFolders`, exposed as `GLIWordPairMembershipClient`. This covers the domain/store layer only; no TCA feature UI in `GlimpseFeatures` calls this client yet. Task 1 (custom-folder CRUD) has separate existing support via `GLICustomFoldersClient`. Confirm task 5 (end-to-end acceptance) status before treating this epic as fully accepted.
