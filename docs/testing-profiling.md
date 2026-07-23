# Testing & profiling (Stage 11)

**Status:** Process contract for Stage 11 — Testing (and performance profiling gates).  
**Not yet the active process stage** while Stage 10 Development is in progress — see `docs/STATUS.md`.  
**Related:** `docs/development-workflow.md` (per-task verify + slice tests during Development)

---

## Purpose

Define **what “tested” and “performant enough” mean** for Glimpse (packages + app), beyond the per-task loop:

- Test layers and ownership
- When integration / UI tests are required
- CI expectations (when introduced)
- Profiling gates (when and what to measure)

Product AC remain the source of user-visible truth. This doc owns engineering quality strategy.

---

## Relationship to Stage 10

| Stage 10 (Development) | Stage 11 (Testing & profiling) |
|---|---|
| Manual verify against task AC | Regression suites, CI, coverage expectations |
| Slice tests named in the impl plan | Cross-feature integration, UI smoke, broader matrix |
| Optional review agents | Formal quality exit before Release (Stage 12) |
| No mandatory profiling | Profiling gates at defined milestones |

During Stage 10, still write the tests the plan lists. Stage 11 organizes, expands, and gates them.

---

## Test layers

| Layer | What it proves | Typical home | When required |
|---|---|---|---|
| **Unit** | Store invariants, pure logic, detection/placement rules | `GlimpseCore` tests | Every Core behavior that has AC |
| **Reducer / feature** | TCA state transitions, effects, dependencies | `GlimpseFeatures` tests | Every non-trivial TCA feature in the plan |
| **Integration** | App Group / shared store, capture pipeline across surfaces, persist round-trip | Package or app tests with in-memory or temp store | After I1 store lands; required before I6 (Widget/Share) exit |
| **UI / UITest** | Critical happy paths (add word, open folder, open card) | `Glimpse` UITests (when present) | Smoke before offline demo (I0–I5) and before release |
| **Manual** | AC, UX judgment, offline / permission edges | Owner + task checklists | Every task (Stage 10); epic/increment exit |

**Rule:** Prefer tests next to the code that owns the behavior (Core logic → Core tests; Features → Features tests).

---

## Package tests & SPM artifacts

Packages under `Packages/` (`GlimpseCore`, `GlimpseAI`, `GlimpseFeatures`) **can and should** be tested on their own (`swift test` / `xcodebuild test` from the package folder, or the package scheme).

Package-level runs create **generated** dirs (`.build/`, `.swiftpm/`). Those are fine while testing the package. They can confuse Xcode when **`Glimpse.xcodeproj`** also links the same packages as local SPM — e.g. duplicate top-level package names.

**Agent / owner workflow:**

1. Run package tests as needed.
2. **Ask:** clean `.build` / `.swiftpm` under the tested package(s) before returning to `Glimpse.xcodeproj`?
3. Yes → delete those dirs (do not commit them; already gitignored).
4. No → leave them; avoid opening the app project until cleaned, or accept resolve risk.

Cursor rule: `.cursor/rules/package-test-hygiene.mdc`.

---

## Integration tests (focus)

Prioritize integrations that historically break portfolio apps:

1. **Persist round-trip** — save → kill process model → load (X1).
2. **Placement** — capture → language folder / Unsorted (F1.4, F2.1).
3. **App Group** — Widget/Share write visible to main app (I6) — required before I6 exit.
4. **Resume** — last folder preference survives relaunch (X4).
5. **AI gate** — null `sourceLanguage` does not call generation; failure leaves app usable (I7) — with mocks.

Use fakes/mocks for network and generation. Do not require live cloud AI for CI.

---

## UI / smoke tests

Minimum smoke set (Stage 11 DoD candidate):

- Launch → Add → save word → appears in expected place (list or folder, per current increment)
- Open folder → open card
- Edit translation → relaunch → still edited
- (Later) Study entry from folder returns cleanly
- (Later) Widget/Share save appears in app

Keep UITests few and stable; put logic assertions in unit/integration layers.

---

## CI (when introduced)

Deferred until Stage 11 is active (see increment planning: CI under Stages 11–13). Target shape:

| Job | Runs |
|---|---|
| Build Glimpse (simulator) | PRs / main |
| Unit + reducer tests (Core / Features) | PRs / main |
| Integration subset (no device-only) | PRs / main |
| UITests | Nightly or pre-release initially (flaky cost) |

Exact tooling and badges are chosen when Stage 11 starts — record decisions here then; do not invent CI in Stage 10 unless the owner asks.

---

## Profiling

### When to profile

| Gate | Trigger | Focus |
|---|---|---|
| **P0 — before offline demo (I5 exit)** | First time the personal loop is “done” | Cold launch, folder list scroll with realistic N words, capture sheet open/save |
| **P1 — before I6 exit** | Widget / Share | Extension launch cost; App Group write latency; main-app refresh after background save |
| **P2 — before I7 exit** | AI on-demand | UI remains responsive while generating; cancel/failure paths; no main-thread stalls |
| **P3 — before Release (Stage 12)** | Shipping | Instruments pass on launch, scroll, capture; memory footprint sanity on a mid-size library |

Ad-hoc profiling during Stage 10 is fine when the owner hits a jank bug; it does not replace these gates.

### What “good enough” means (v1)

- Capture sheet and save feel immediate on a recent iPhone simulator/device (no multi-second hitch on local save).
- Folder lists remain scrollable with hundreds of items (exact N to be measured at P0 — record result in `STATUS.md` or a short note here).
- Generations never block the whole app; user can leave the card / cancel where supported.
- No Instruments red flags for obvious main-thread I/O on the hot path (capture save, folder open).

Exact numeric budgets can be filled in when first profiling runs; until then use qualitative gates above.

### How to profile

- Xcode Instruments: Time Profiler, SwiftUI, Allocations (as needed).
- Reproduce with a seeded vocabulary size (document seed size next to results).
- Fix only regressions that violate the gates or user-reported jank — avoid premature optimization (tech-lead scope rule).

---

## Stage 11 Definition of Done (draft)

- [ ] Test layers documented and applied to I0–current increment.
- [ ] Integration suite covers persist, placement, and (when I6 exists) App Group.
- [ ] UI smoke set exists for the offline demo path.
- [ ] CI plan agreed (or explicitly deferred with owner OK and a date/criterion).
- [ ] Profiling gates P0–P3 defined; P0 run before claiming offline demo ready.
- [ ] Owner review — accepted.
- [ ] Proceed to Stage 12 — Release when Development milestones allow.

---

## Non-goals (this doc)

- Replacing product AC with engineering metrics
- Spaced-repetition / sync / multi-device test matrices (out of v1)
- Mandating coverage % before Stage 11 is active

---

## Quick reference

| Doc | Role |
|---|---|
| `development-workflow.md` | Per-task: verify then test then review |
| This doc | Strategy: layers, integration, CI, profiling gates |
| `STATUS.md` | Whether Stage 11 is active; profiling results notes |
| Increment planning | Which features exist to test at each Ix |
