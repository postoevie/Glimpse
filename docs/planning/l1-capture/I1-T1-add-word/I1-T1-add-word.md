# I1-T1 — Add a word in the app

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — first in build order  
**Feature refs:** F1.1 (in-app capture, narrowed), X1 (persist start)  
**Product refs:** `docs/user-flows.md` (Flow 1, in-app entry), `docs/information-architecture.md` (root Add → capture sheet), `docs/prd.md` (§ capture), `docs/feature-breakdown.md` (F1.1)

---

## Outcome

The user can capture a word or phrase from inside the app, with an optional translation, see it in a simple list, and keep that save after leaving the capture sheet and after relaunching the app.

**No languages in this task.** Source/target language UI, detection, Unsorted, and language folders are **deferred to I1-T2**.

---

## User story

As a user collecting vocabulary, I want to add a word or phrase quickly from the app, so I can save it without organizing folders first.

---

## User steps (happy path)

1. User opens the app and sees a clear **Add** action and a list of already saved word pairs (may be empty).
2. User taps **Add**.
3. A capture sheet opens (**word + translation only** — no language fields).
4. User enters a required word or phrase.
5. Optionally, user enters a translation.
6. User taps **Save** / **Done** (no extra confirmation step).
7. The sheet closes; the new word appears in the list.
8. User force-quits and relaunches the app; the saved word is still in the list.

---

## Scope

- One clear in-app Add entry point
- Capture opens as a sheet
- Required word/phrase field
- Optional translation
- Save and Cancel
- Flat list of saved word pairs (word + translation) as the interim home before folders ship
- Saved words remain after closing the sheet and after app relaunch
- Example starts blank (no example entry required in this task)
- Same text may be saved again as a new word (no duplicate warning)
- **NO languages:** no source/target pickers, no detection, no language on the saved pair UI

---

## Acceptance criteria

- [x] Tapping Add opens the capture sheet.
- [x] Capture sheet shows only word and translation fields (no language controls).
- [x] Save is unavailable (or does nothing) while the word/phrase is empty or whitespace only.
- [x] Translation may be left blank.
- [x] Example is blank for a newly captured word.
- [x] Cancel closes the sheet without saving.
- [x] Save closes the sheet without another confirmation step.
- [x] Capturing the same text again creates another word; no duplicate warning appears.
- [x] Translation is never generated automatically at capture.
- [x] A successfully saved word is still present after closing and reopening the app.

---

## Deferred to I1-T2 (not in T1)

- Source-language detection or manual pick at capture
- Target-language default / edit at capture
- Language folders, Unsorted, and root folder list

---

## Edge cases

- User enters only spaces in the word field.
- User cancels after typing values.
- User saves a word identical to one already saved.
- User saves with translation blank.

---

## Dependencies

—

---

## Out of scope (this task)

- **All language handling** — source/target UI, detection, Unsorted, language folders (I1-T2)
- Custom folders and default custom folder
- Folder word list, card detail, edit/delete, resume last folder (later I1 tasks)
- Widget and Share Extension capture
- Search, study, related words
- AI translation, examples, or discover-similar

---

## Definition of Done

- [x] All acceptance criteria checked
- [x] Edge cases verified
- [x] No language UI or detection shipped in this task (deferred to I1-T2)
- [x] No out-of-scope behavior included
