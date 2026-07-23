# I1-T2 — Language folders, detection, and placement

**Type:** Product task  
**Epic:** `../I1-capture.md`  
**Priority:** P0 — second in build order  
**Feature refs:** F1.4, F2.1, X3 (root = folder list)  
**Product refs:** `docs/user-flows.md` (Flow 1 steps 2–3, Flow 2 language folders), `docs/information-architecture.md` (root folder list), `docs/domain-modeling.md` (Unsorted / language folders), `docs/feature-breakdown.md` (F1.4, F2.1, X3)

---

## Outcome

At capture, source language is detected or optionally chosen; each save lands in the matching language folder or **Unsorted**. The app root becomes the language-folder list (no tabs).

---

## User story

As a user, I want saved words to land in the right language folder (or Unsorted), so I can find them by language without filing them by hand.

---

## User steps (happy path)

1. User opens the app and sees the **root list of language folders** (may include Unsorted once used).
2. User taps **Add**; capture sheet opens.
3. User enters a word/phrase and optional translation.
4. When offered, user may set or confirm **source language**; **target language** defaults to source when source is known and can still be changed before save.
5. User saves; sheet closes.
6. If source language is known, a matching language folder exists (created if needed) and the word is in that folder.
7. If detection fails and the user skips manual pick, the word is in **Unsorted** without blocking save.
8. User sees the new/updated folder on the root list.

---

## Scope

- Language detection at capture with optional manual source choice when offered
- Target language default to source when known; editable before save
- Auto-create language folders as needed
- Place each save into language folder or Unsorted
- Root screen = language folder list (single stack, no tabs)
- Language folders cannot be renamed or deleted
- Empty state when no folders exist yet (e.g. before first save)

---

## Acceptance criteria

- [ ] After this task, the app root is the language-folder list (not a flat word list as the long-term home).
- [ ] Detected non-null source places the word in the corresponding language folder.
- [ ] Failed or skipped detection places the word in Unsorted without blocking save.
- [ ] Language folders appear on the root as words are saved.
- [ ] Language folders cannot be renamed or deleted by the user.
- [ ] Target language can be set at capture when UI offers it; translation is still never auto-generated.
- [ ] Saving with only the word/phrase still works (translation optional).

---

## Edge cases

- Detection fails; user skips manual source → Unsorted.
- User manually picks source when offered.
- First word in a new language creates that folder.
- Multiple words in the same language share one folder.

---

## Dependencies

- I1-T1 (persist + in-app Add)

---

## Out of scope (this task)

- Opening a folder to browse its words (I1-T3)
- Custom folders, default custom folder, Unsorted resolve
- Card detail, edit/delete, resume
- Widget / Share, search, study, AI

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included
