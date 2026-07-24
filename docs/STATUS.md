# Project status

**Living board** — update this file when stage, increment, task, or blockers change. Do not put this status in `.cursor/rules/tech-lead.mdc`.

---

## Now

| | |
|---|---|
| **Process stage** | 10 — Development |
| **Active increment** | I1 — Capture → folder → card |
| **Active task** | I1-T2 — Language folders + placement (**code done**) |
| **Task AC** | Implementation done; product AC pending owner verify |
| **Impl plan** | Steps 1–4 + 6 ✓ — code + package tests |
| **Next gate** | Manual verify I1-T2 AC; then close → I1-T3 |

---

## Stage map (static order)

Canonical product docs: `docs/` (see `AGENTS.md`). Live checkmarks for *which stage we’re in* belong only here.

| # | Stage | Status |
|---|---|---|
| 1 | Product Discovery | Done |
| 2 | Product Requirements | Done |
| 3 | User Flows | Done |
| 4 | Information Architecture | Done |
| 5 | Domain Modeling | Done |
| 6 | Feature Breakdown | Done |
| 7 | Technical Design | Done |
| 8 | Architecture | Done |
| 9 | Increment Planning | Done |
| 10 | Development | **In progress** |
| 11 | Testing | Not started |
| 12 | Release | Not started |
| 13 | Polish | Not started |
| 14 | Portfolio Preparation | Not started |

---

## Increments

| Increment | Status | Exit / notes |
|---|---|---|
| I0 — Scaffold | Done in tree | Owner should confirm packages resolve + app launches |
| I1 — Core loop | **In progress** | Epic: `docs/planning/l1-capture/I1-capture.md` |
| I2 — Organize | Not started | |
| I3 — Find depth | Not started | |
| I4 — Related | Not started | |
| I5 — Study | Not started | |
| I6 — Widget + Share | Not started | |
| I7 — AI | Not started | |

Milestone: offline demo = I0–I5 complete.

---

## I1 task board

| Task | Product file | Status |
|---|---|---|
| T1 Add word + persist | `I1-T1-add-word/I1-T1-add-word.md` | **Verified** |
| T2 Language folders + placement | `I1-T2-language-folders/I1-T2-language-folders.md` | **Code done** (owner verify) |
| T3 Folder word list | `I1-T3-folder-word-list/I1-T3-folder-word-list.md` | Ready (not started) |
| T4 Word card | `I1-T4-word-card/I1-T4-word-card.md` | Ready (not started) |
| T5 Card edit + delete | `I1-T5-card-edit-delete/I1-T5-card-edit-delete.md` | Ready (not started) |
| T6 Resume last folder | `I1-T6-resume-folder/I1-T6-resume-folder.md` | Ready (not started) |
| T7 End-to-end acceptance | `I1-T7-e2e-acceptance/I1-T7-e2e-acceptance.md` | Ready (not started) |

---

## Open questions

| ID | Question | Affects | Decision |
|---|---|---|---|
| Q1 | Where does T1 persist live? | I1-T1 | **Decided** — GlimpseCore SwiftData |

---

## Deferred acceptance (intentional narrowing)

| Item | Deferred from | Lands in | Owner OK |
|---|---|---|---|
| Source/target language UI + detection at capture | I1-T1 (full F1.1) | I1-T2 | Yes — epic build order |

---

## Process docs

| Doc | Role |
|---|---|
| `docs/development-workflow.md` | Stage 10 per-task loop |
| `docs/testing-profiling.md` | Stage 11 tests / CI / profiling |

---

## How to update

1. Change **Now** when switching stage / increment / task.
2. Tick task/impl AC in the task and plan files; reflect counts here.
3. Resolve or assume open questions before coding past them.
4. On increment exit: note date + owner verification under **Increments**.
5. When entering a delivery gate (verify / review / close), optionally note it under **Next gate**.
