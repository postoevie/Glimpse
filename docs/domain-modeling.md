# Stage 5 — Domain Modeling

**Status:** Accepted — conceptual entities and rules only. No Swift types, no persistence framework, no DB schema — that's Stage 7 (Technical Design). Drives Stage 6 (Feature Breakdown) below.

---

## Entities

### Item (the "card")

The one entity everything else hangs off. A saved word or phrase.

| Attribute | Notes |
|---|---|
| `text` | The captured word/phrase as typed/pasted/shared. Required. **Editable after save** — `sourceLanguage` does **not** re-detect or change; mismatch with edited text is the user's responsibility. |
| `sourceLanguage` | **`null` if auto-detection fails and the user does not pick manually**; otherwise the detected or manually chosen code (e.g. `es`, `fr`). User **may** pick manually at capture when the UI allows — optional, not required — **except** while a custom folder is selected (including default-prefilled): then pending source **is** that folder's `sourceLanguage` and is **not** editable or clearable to `null` until the folder selection is cleared. **Immutable after save**, except **one Unsorted resolve** (below). Drives Language Folder assignment. |
| `targetLanguage` | **Owned by the Item.** User-selectable at creation — default = `sourceLanguage` when non-null. **At capture:** if a custom folder is selected (or default-prefilled), copy that folder's `targetLanguage` onto the pending Item target when the folder has one (**overwrites** prior pick; user can still change before save). **After save:** editable on the card; generation uses whatever the card holds. **Card → folder:** editing a card's target, or adding a card with a target, updates its custom folder's `targetLanguage`. **Not vice versa** — folder target never changes saved Items. |
| `translation` | Blank by default. Manual entry or on-demand generation only — never automatic. **Generation requires non-null `sourceLanguage`**; manual entry allowed on `null`-source cards. When `targetLanguage == sourceLanguage`, this is effectively a same-language definition, not a different field or category. |
| `example` | Blank by default (`[]`). **One field, `[String]`** — list of strings representing the example (typically `[sourceSentence, translation]` as two elements). Manual entry or on-demand generation only; **generation requires non-null `sourceLanguage`**; a new example **replaces** the whole list. |
| `createdAt` | For default ordering. |

**Not modeled as attributes** (computed, not stored): related items, discover-similar suggestions — these are query results (instant matching / on-demand generation), not persisted relationships on the Item itself, except that a *saved* discover-similar suggestion becomes an ordinary new Item via the normal capture path.

### Language Folder

Auto-managed grouping by source language.

| Attribute | Notes |
|---|---|
| `languageCode` | e.g. `es`, `fr`. One special case: **"Unsorted"** — for Items whose `sourceLanguage` is `null`. |
| — no `targetLanguage` | Language Folders never carry a target language; they exist purely to group by detected source language. |

Rules: auto-created on first use of a language (including **"Unsorted"** for `null` source); permanent. Assigned at capture from `sourceLanguage` — **`null` → Unsorted**, non-null → matching language folder. **Changes only via one-time Unsorted resolve** (below); otherwise never changes after capture.

### Custom Folder

User-created, optional, free-form. May contain **zero items**.

| Attribute | Notes |
|---|---|
| `name` | Required. Free-form, user-set. |
| `sourceLanguage` | **Required language code**, set when the folder is **created** (create UI collects name **and** source language). Always a real language code — **never** `null`, empty, or “unlocked.” **Immutable** after creation. **Only Items whose `sourceLanguage` equals this code may be filed in.** An Item with `sourceLanguage == null` (Unsorted) **cannot** join without Unsorted resolve adopting this folder’s code. |
| `targetLanguage` | **Optional cache derived from Items — not user-set on the folder.** **Written by Items (card → folder):** set/updated when an Item with a `targetLanguage` is added to this folder, or when any Item in the folder has its `targetLanguage` edited. **Read at capture (folder → pending Item):** when this folder is selected (or default-prefilled), copy onto the **new Item's pending `targetLanguage`** if present (overwrites; user can change before save). Does **not** retroactively change existing Items. Remains when the folder has 0 items. |

Rules: flat list (no nesting); user can **rename or delete** a Custom Folder — **delete removes custom-folder membership from all Items** (Items remain in their language folders). If the deleted folder was the **default custom folder**, clear that default. **`sourceLanguage`** is set at **create** and stays set **even when the folder returns to 0 items**. **`targetLanguage`** is optional, syncs from card add/edit (card → folder only) — never user-set directly on the folder after create. Membership always requires matching non-null Item `sourceLanguage`.

### Default custom folder (user preference — not an entity attribute)

Sticky convenience for capture; **not** automatic filing without user action at save.

| Rule | Detail |
|---|---|
| **What it is** | Reference to one Custom Folder — the **last folder the user filed an Item into** (at capture or re-file) **or chose manually** on the add/capture view. |
| **When it updates** | On save with a custom folder chosen; on re-file into a custom folder; when user manually picks a different folder on the add view (even before save). |
| **In-app add view** | **Prefilled** with the default custom folder only when its `sourceLanguage` equals the card's pending non-null `sourceLanguage`. Pending `null` never auto-prefills a default. Picker offers **all** custom folders; selecting one **forces** pending source to that folder's code (even if pending was `null` or different). User can change or clear before save. |
| **Widget / Share Extension** | No folder picker — **uses default custom folder on save** only when detection yields a **non-null** source that matches the default folder's `sourceLanguage`; otherwise **no custom folder** (Item still saves to language folder only). |
| **Language gate** | Apply default only when pending/detected `sourceLanguage` is non-null and equals the default folder's `sourceLanguage`. Pending `null` never auto-prefills. Manual selection still forces source from the chosen folder. |

### Unsorted resolve (one-time per Item)

While an Item's `sourceLanguage` is **`null`** and it has **not yet used its one Unsorted resolve**, the user may intentionally move it **once** via Unsorted-only actions (not available on other cards):

| Action | Effect |
|---|---|
| **Move to language folder** | User picks a language → `sourceLanguage` set → Item moves to that language folder. Custom folder unchanged. |
| **Move to custom folder** | User picks a custom folder → Item filed in. Item **always adopts** that folder’s (required) `sourceLanguage` and moves to the matching language folder. Folder `targetLanguage` sync from Item's target if present (card → folder). **Does not change Item `targetLanguage`** (same as re-file). This path always leaves Item `sourceLanguage` non-null. |

After either action, the Item **has used its Unsorted resolve** — these actions disappear. **`sourceLanguage` remains immutable** afterward (and after Move to custom folder it is always a non-null code). Normal custom-folder re-file applies only to Items that already have non-null `sourceLanguage` (or after resolve).

---

## Relationships

- **Item → Language Folder**: exactly one, required, auto-assigned at capture; **may change once** via Unsorted resolve (move to language folder, or move to custom folder when that sets/adopts `sourceLanguage`).
- **Item → Custom Folder**: zero or one, optional, manual assignment only. **Unsorted Items (`sourceLanguage` null, resolve not used):** assign only via **Move to custom folder** (Unsorted resolve) — not the normal re-file picker; that path always adopts the folder’s required source. **At in-app capture:** picker offers **all** custom folders; default is prefilled only when pending non-null source **equals** the folder’s `sourceLanguage`; while any custom folder is selected, Item source is that folder's code (non-null) and files into the folder on save. **Add from a custom folder detail** always assigns that folder and prefills/locks source from it. **After resolve or when source is non-null:** normal re-file (assign/remove); re-file does **not** change Item `sourceLanguage` or language folder; assign only when Item source **equals** folder `sourceLanguage`.
- **Item → targetLanguage**: owned by the Item; editable on the card after save. **Card → folder:** editing a card's target or adding a card with a target updates the custom folder's `targetLanguage`. **Not vice versa** — folder target never retroactively changes Items. **Re-file (post-capture):** moving an Item into/out of a custom folder does **not** change the Item's `targetLanguage`; adding to a folder may update folder `targetLanguage` (from item's target) — **never** changes folder `sourceLanguage` (set at create).
- **Item → sourceLanguage**: set at capture (auto-detected, manual if UI allows, or **`null`** if detection fails and user skips manual pick); **immutable after save**, except **one Unsorted resolve** may set it. **`null` → Unsorted** language folder. While a custom folder is selected at capture (including default-prefilled), pending source **is defined by** `CustomFolder.sourceLanguage` — not user-editable and not clearable to `null`; clearing the folder selection restores normal detect / optional manual / null rules. **Editing `text` does not change `sourceLanguage`.**
- **Related items**, **discover-similar**, **translation generation**, and **example generation** require **non-null `sourceLanguage`**; Items with `null` source get none of these (accepted limitation). Manual translation and example entry on such cards is allowed.
- **Discover-similar save:** new Item via normal capture with **suggested `text` only** pre-filled — everything else (source/target, folders, translation) follows the standard capture path.
- **Widget / Share Extension capture fields:** **`text`**, optional **`translation`**. **Custom folder:** no picker — apply **default custom folder** on save only when detected source is **non-null** and matches that folder's `sourceLanguage`; otherwise none. No source/target language pickers; auto-detection as usual (`null` + Unsorted on failure).

---

## Invariants (consolidated from PRD — enforce these regardless of implementation)

1. An Item always has exactly one Language Folder; never zero, never more than one.
2. An Item has at most one Custom Folder.
3. An Item's `sourceLanguage` is **`null` or a language code after capture**. **`null` → Unsorted** language folder; non-null → matching language folder. **`sourceLanguage` may change only via one Unsorted resolve**; otherwise never changes after capture.
4. An Item's `targetLanguage` is **user-editable** on the card; editing it updates the parent Custom Folder's `targetLanguage` if filed in one — **never the reverse**.
5. **`text` is editable** after save; **`sourceLanguage` does not change** when `text` is edited.
6. `translation` and `example` are never populated except by manual entry or an explicit on-demand generation action.
7. No uniqueness constraint on `text` — duplicates are valid, separate Items.
8. Custom folder **`sourceLanguage`** is a **required non-null language code** set at create — never `null`/empty/unlocked. **`sourceLanguage` and optional `targetLanguage` remain** even when the folder has 0 items after all Items are removed. Folder `sourceLanguage` is **immutable** after create.
9. **Re-file:** assigning/removing an Item's custom folder does not change the Item's `targetLanguage` or `sourceLanguage`. Assign only when Item `sourceLanguage` equals folder `sourceLanguage`. **Unsorted resolve** is separate — **once per Item**, Unsorted-only; may set `sourceLanguage` and/or custom folder per rules above. **Removing** an Item from a custom folder does not change that folder's languages. **Deleting** a custom folder clears custom-folder membership on affected Items only.
10. **Related items**, **discover-similar**, **translation generation**, and **example generation** require non-null `sourceLanguage`.
11. At in-app capture, picker offers **all** custom folders. Selecting one **forces** pending `sourceLanguage` to the folder's code (not editable / not clearable to `null` while selected); `targetLanguage` may prefill from the folder and remain editable before save. User may clear the custom-folder selection to restore normal source rules. Default prefill applies only when pending non-null source equals folder source.
12. **Default custom folder** — last folder used or manually chosen; prefilled on in-app add only when folder source equals pending non-null source; pending `null` never auto-prefills; widget/Share same non-null match gate; cleared if that folder is deleted.
13. **Unsorted resolve** — at most **once per Item** while `sourceLanguage` is `null`; Unsorted-only UI (**Move to language folder** / **Move to custom folder**). Move to custom folder always adopts the folder’s required source (Item source becomes non-null). After use, normal re-file rules apply; `sourceLanguage` still immutable except what resolve already set.

---

## Lifecycle (not yet specified elsewhere — filling the gap here)

- **Create Item**: via capture (Flow 1) — the only Item creation path. **Discover-similar save** pre-fills **`text` only**; then normal capture rules apply.
- **Create Custom Folder**: **name + `sourceLanguage` required**; `targetLanguage` optional/empty until cards sync.
- **Edit**: Item — `text`, `translation`, `example`, `targetLanguage` (card → folder target sync). **Custom folder membership:** normal re-file when Item `sourceLanguage` is non-null; **Unsorted resolve** (once) when Item `sourceLanguage` is `null` and resolve not yet used. Custom Folder — **rename/delete** (`name` only after create); folder `sourceLanguage` immutable; `targetLanguage` syncs from cards only, never edited directly on folder.
- **Delete Item**: removes it from language folder and custom folder (if any).
- **Delete Custom Folder**: Items lose custom-folder membership; language folders and Item data otherwise unchanged.

---

## Non-goals (this stage)

- Concrete types, persistence framework, schema/migrations — Stage 7 (Technical Design).
- Sync/multi-device conflict resolution — not in v1 at any layer.
- Search index shape, resume preference storage, study deck session state, default custom folder persistence — Stage 7 (Technical Design).

---

## Definition of Done (Stage 5)

- [x] Every entity from IA/PRD named with attributes (Item, Language Folder, Custom Folder).
- [x] Relationships stated, including folder `targetLanguage` as optional prefill cache (syncs from cards; prefills new captures; not retroactive).
- [x] Invariants consolidated in one place for later stages to enforce.
- [x] Gap filled: Item deletion, not specified in any prior stage.
- [x] Owner review — accepted.
- [x] Proceed to Stage 6 — Feature Breakdown.
