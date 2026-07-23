# I1 — Capture → folder → card

**Type:** Product epic  
**Parent:** `docs/increment-planning.md` → I1  
**Product refs:** `docs/user-flows.md`, `docs/information-architecture.md`, `docs/feature-breakdown.md`

---

## Epic outcome

User adds a word in the app → it appears in the matching language folder or **Unsorted** → user opens its card → manually edits translation or example → after relaunch the app returns to the last opened folder.

---

## User problem

The user needs a complete first-use vocabulary loop, not isolated screens: save a word quickly, find it in a predictable place, open it, enrich it manually, and continue from the same folder later.

---



## User story

**As a** user collecting foreign words and phrases,  
**I want** to add a word, find it in its language folder, and edit its card,  
**so that** my vocabulary remains useful and available after I close the app.

---



## User journey (end state)

1. User opens the app and taps **Add**.
2. User enters a required word/phrase and may enter a translation.
3. The app determines the source language; the user may select it manually when offered.
4. User saves without an extra confirmation step.
5. The word appears in the corresponding language folder; if the language is unknown, it appears in **Unsorted**.
6. User opens the folder and sees its words.
7. User opens a word card.
8. User manually edits the word, translation, example, or target language.
9. User closes and relaunches the app.
10. The app returns to the last opened folder, or to the root if no folder was previously opened.

---



## Build order (product sequence)

Delivery order is **capture first**, then organization:

1. Persistable word pairs + in-app Add (word + translation only)
2. Language detection, root language-folder list, automatic placement (incl. Unsorted)
3. Browse words in a folder (single nav stack; root = folder list)
4. Word card
5. Manual edit and delete
6. Resume last opened folder
7. End-to-end acceptance

---



## In scope

- In-app Add entry point and capture form
- Required word/phrase; optional translation
- Automatic language detection with optional manual source choice
- Language folders created as needed
- Automatic placement into a language folder or Unsorted
- Root list of language folders
- List of words inside a folder
- Word card view
- Manual editing of word, translation, example, and target language
- Deleting a word from its card
- Restoring the last opened folder after relaunch
- Offline use without an account



## Out of scope

- Custom folders and default custom folder
- Resolving an Unsorted word into another folder
- Search and shuffle
- Related words
- Study mode
- Widget and Share Extension
- AI translation, examples, or similar-word generation

---



## Product requirements

- No tabs; the folder list is the root after organization ships.
- There is exactly one in-app Add action.
- Capture opens as a sheet.
- Saving requires a non-empty word/phrase.
- Translation is optional and is never generated automatically.
- Unknown source language never blocks saving; the word goes to Unsorted.
- A saved word appears immediately in its folder once placement ships.
- Language folders are created automatically and cannot be renamed or deleted.
- Words in a folder are ordered newest first.
- Editing the word later does not change its source language or folder.
- All in-scope actions work offline and without an account.

---



## Feature mapping


| Product capability                 | Source feature IDs |
| ---------------------------------- | ------------------ |
| Add a word in-app                  | F1.1               |
| Determine source language          | F1.4               |
| Automatic language folders         | F2.1               |
| Save and retain vocabulary offline | X1                 |
| Single-stack navigation            | X3                 |
| Browse folders and words           | F3.1               |
| View and edit a word card          | F4.1               |
| Resume last folder                 | X4                 |


---



## Tasks

1. **In-app word capture + persist (X1 start)** — `I1-T1-add-word/I1-T1-add-word.md`  
   Flat list of saved word pairs; Add sheet; required word, optional translation; survive relaunch. **No** source/target language UI, detection, or folders in this task (deferred to T2).

2. **Language folders, detection, and placement (F1.4, F2.1)** — `I1-T2-language-folders/I1-T2-language-folders.md`  
   Detect or allow manual source at capture when offered; create language folders as needed; place into language folder or **Unsorted**; show **root list of language folders** (becomes app root; no tabs / X3).

3. **Folder word list (F3.1)** — `I1-T3-folder-word-list/I1-T3-folder-word-list.md`  
   Open a folder → words newest first; navigate on the single stack from root folder list.

4. **Word card (F4.1 view)** — `I1-T4-word-card/I1-T4-word-card.md`  
   Open a word from a folder list; show word, translation, example, languages as stored.

5. **Manual card editing and deletion (F4.1 mutate)** — `I1-T5-card-edit-delete/I1-T5-card-edit-delete.md`  
   Edit word, translation, example, target language; delete from card. Editing word does not change source language or folder.

6. **Resume last opened folder (X4)** — `I1-T6-resume-folder/I1-T6-resume-folder.md`  
   After relaunch, return to last opened folder, or root if none.

7. **End-to-end acceptance** — `I1-T7-e2e-acceptance/I1-T7-e2e-acceptance.md`  
   Full epic journey offline, no account; verify against Epic acceptance criteria.

---



## Epic acceptance criteria

- [ ] User can save a word with only the required word/phrase filled.
- [ ] User can optionally enter a translation and choose source/target languages when available.
- [ ] A detected language places the word in the corresponding language folder.
- [ ] Failed or skipped detection places the word in Unsorted without blocking save.
- [ ] Language folders appear on the root as words are saved.
- [ ] User can open a folder and see its saved words.
- [ ] User can open a word card and manually edit word, translation, example, and target language.
- [ ] User can delete a word from its card.
- [ ] Changes remain after closing and reopening the app.
- [ ] Relaunch returns to the last opened folder, or root when no folder was opened.
- [ ] The complete journey works offline and without an account.

---



## Epic Definition of Done

- [ ] All product tasks are accepted.
- [ ] Happy path and listed edge cases match approved user flows.
- [ ] Every screen has loading, empty, and relevant error states defined in its task.
- [ ] No out-of-scope capability is included.
- [ ] Owner verifies the complete epic outcome on a device or simulator.