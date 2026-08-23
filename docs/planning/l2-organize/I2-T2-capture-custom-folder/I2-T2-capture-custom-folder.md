# I2-T2 — Capture with custom folder + default preference

**Type:** Product task
**Epic:** `../I2-organize.md`
**Priority:** P0 — second in build order
**Feature refs:** F2.5, F1.1 (custom-folder slice)
**Product refs:** `user-flows.md` (Flow 1 step 2–3), `information-architecture.md` (capture entry, Add from folder), `domain-modeling.md` (default custom folder, capture prefill), `feature-breakdown.md` (F2.5, F1.1)

---

## Outcome

At in-app capture, the user can pick any custom folder (or clear it). On **Add from root** (and Unsorted), the **default custom folder** is **always** prefilled when one exists (forces pending source) so repeat capture stays fast. Language-folder Add prefills the default only when sources match. While a folder is selected, pending source is that folder’s code (not editable). Saving into a folder places the word there, may update folder target from the item, and updates the default preference.

---

## User story

As a user, I want capture to remember and offer my usual custom folder, and to take source (and optional target) from that folder when selected, so filing is fast and consistent.

---

## User steps (happy path)

1. User has at least one custom folder (created in I2-T1 with name + source language) and has a default custom folder preference.
2. User taps **Add** from root.
3. Capture sheet shows a custom-folder control; the **default** folder is **always** prefilled when one exists (pending source forced to that folder’s code); user may change or clear it.
4. Picker offers **all** custom folders; selecting one forces pending source to that folder’s code.
5. While a custom folder is selected: pending source is `CustomFolder.sourceLanguage` — **not editable** and **not clearable to null**; target may prefill from the folder and remain editable before save. Clearing the custom-folder selection restores normal detect / optional manual / null source rules.
6. User saves; the word appears in the correct language folder **and** in the chosen custom folder (source is non-null from the folder). Folder target updates from the item’s target when present.
7. The default custom folder preference now points at the folder used on save (or the one manually chosen on the sheet).
8. Next root Add prefills that default again.

---

## Scope

- Custom folder picker on in-app capture (root Add and folder-detail Add)
- **Root / Unsorted Add:** always prefill default custom folder when one exists (forces pending source)
- **Language-folder Add:** prefill default only when default folder source matches that language folder’s language
- **Custom-folder Add:** that folder always assigned
- User can change or clear custom folder before save
- Picker: **all** custom folders (selection forces source)
- Selecting a folder sets pending source from folder (not editable while selected); may prefill target; target still editable before save
- Save files into chosen custom folder (≤1); updates default preference; folder `targetLanguage` updates from item target (card → folder)
- Manual pick of a different folder on the add sheet updates the remembered default even before save (per domain)
- Persist default preference across relaunch
- Empty target defaults to the pending source when a custom folder is selected and the folder has no cached target
- Editing target on an already-filed card updates the custom folder’s cached `targetLanguage` (card → folder), not just on capture

---

## Acceptance criteria

- [ ] Capture offers a custom-folder choice the user can set or clear.
- [ ] Add from **root** (and Unsorted): default custom folder is **always** prefilled when one exists; pending source is forced to that folder’s code.
- [ ] Add from **language-folder** detail: default is prefilled only when its source matches that language; otherwise no default unless the user picks.
- [ ] Picker offers all custom folders; selecting a folder forces pending source to that folder’s code.
- [ ] Selecting / prefilling a folder sets pending source to that folder’s code; source control not editable and not clearable to null while selected; target may prefill and stays changeable before save.
- [ ] Clearing the custom folder restores normal source rules (detect / optional manual / null).
- [ ] Saving with a custom folder selected places the word in that folder and in the matching language folder.
- [ ] Saving with a custom folder updates the default preference; next root Add prefills it.
- [ ] Clearing the custom folder before save leaves the word in language folder / Unsorted only (no custom membership).
- [ ] Add from custom folder detail always assigns that folder and locks source from it.
- [ ] Default preference survives relaunch.
- [ ] With a custom folder selected and the folder has no cached target, an unset pending target defaults to the pending source; a manually picked target is kept.
- [ ] Editing target on a card already filed into a custom folder updates that folder’s cached `targetLanguage`.

---

## Edge cases

- Root Add; default exists; pending source null at open → **still** prefill default; source becomes the folder’s code.
- Language-folder Add; default folder is a different language → skip default prefill.
- User changes folder on the sheet before save → default updates to the chosen folder; source forced to new folder’s source.
- Add from language folder vs custom vs Unsorted (prefill / assignment rules differ).

---

## Dependencies

- I2-T1 (custom folders exist on root with required source language)

---

## Out of scope (this task)

- Card membership — known source (I2-T3)
- Card membership — Unsorted transitions (I2-T4)
- Widget / Share silent default apply (I6) — still uses match gate on save
- AI generation

---

## Definition of Done

- [ ] All acceptance criteria checked
- [ ] Edge cases verified
- [ ] No out-of-scope behavior included

---

## Blueprint status note

The filing half of this task (assigning a word to a custom folder and syncing the folder's cached target language) is implemented in `GlimpseCore`: `GLIModelActor.assignCustomFolder`, exposed as `GLIWordPairMembershipClient.assignCustomFolder`. The capture-sheet UI (default prefill, picker, source-lock behavior) is not yet implemented in `GlimpseFeatures`.
