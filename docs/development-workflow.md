# Development workflow (Stage 10)

**Status:** Active process contract for Development.  
**Live progress:** `docs/STATUS.md`  
**Related:** `docs/testing-profiling.md` (Stage 11 — broader test/CI/profiling strategy)

---

## Purpose

Define the **per-task delivery loop** so coding stays controlled, clear, and transparent:

**plan → code → verify → test → review → close**

This is Stage 10. Do not put mutable “where we are” here — update `STATUS.md`.

---

## Preconditions (before code)

1. **Product task** exists under `docs/planning/…` with frozen acceptance criteria (AC).
2. **Implementation plan** exists beside the task (`*-implementation.md`) unless the owner explicitly skips planning for a tiny change.
3. **Open questions** that block AC are resolved or explicitly assumed (record in `STATUS.md`).
4. If the impl plan **narrows** the product task: update the task’s deferred AC (or get owner OK) before coding.

Do not invent product rules that contradict product docs or the task. If conflict: stop and ask.

---

## Loop (one product task)

```text
┌─────────────────────────────────────────────────────────┐
│ 1. Plan approved (or skip agreed)                       │
│ 2. Code (minimal diff; this repo)                       │
│ 3. Verify — manual AC on device/simulator               │
│ 4. Test — automated tests named in the plan             │
│ 5. Review — owner and/or agents (see below)             │
│ 6. Close — tick AC / DoD; update STATUS.md              │
└─────────────────────────────────────────────────────────┘
```

### 1. Plan

- Skill: `implementation-plan` when creating/updating the plan (if present).
- Plan must list verify steps tied to task AC, then test steps.
- Agent split optional (`tca-architect` → design only; `tca-engineer` / `swift-developer` → implement).

### 2. Code

- Write in this repo: `Packages/GlimpseCore`, `GlimpseAI`, `GlimpseFeatures`, and the `Glimpse` app (`AGENTS.md`).
- New types use the **`GLI`** prefix.
- Match existing style; no drive-by refactors.
- Do not run project builds/tests unless the owner explicitly asks in that turn (agent rule).

### 3. Verify (manual)

- Walk the task’s **Acceptance criteria** and relevant **Edge cases** on simulator or device.
- Prefer the owner for final “looks right”; agents may prepare a checklist from the task AC.
- Verification **before** treating automated tests as sufficient.

### 4. Test (automated)

- Add/run only what the implementation plan named for this slice (e.g. `TestStore`, store unit tests).
- Tests support AC; they do not redefine product scope.
- Broader integration / UI / CI / profiling strategy → `docs/testing-profiling.md` (Stage 11). During Stage 10, still add slice-level tests when the plan calls for them.

### 5. Review

Pick what applies; not every gate every time:

| Gate | When |
|---|---|
| Owner skim / AC spot-check | Every task before close |
| Swift / TCA code review agent | Non-trivial reducer/view/service changes |
| Bugbot-style review | When owner asks |
| Security review | Persistence, App Group, Keychain, network/AI, entitlements |

Fix blocking findings; re-verify affected AC.

### 6. Close

- Check off task AC and DoD in the product task file.
- Update implementation plan checkboxes if used.
- **Traceability (light):**
  - Add a `## Code` section to the implementation plan listing this slice’s main files/types (forward map — source of truth).
  - Optionally add a one-line breadcrumb at the top of each **feature root** only (TCA `@Reducer` / main view), e.g. `// Task: I1-T1 — docs/planning/l1-capture/I1-T1-add-word/`. Skip helpers, models, clients, tests.
  - Multi-task file: prefer origin task, or list ids briefly. Do this on close, not mid-WIP. No CI enforcement.
- Update `docs/STATUS.md`: active task, AC counts, next gate, resolve/close open questions.
- Epic/increment exit only when epic DoD / increment exit criteria are met (see increment planning + epic).

---

## Definition of Verified (task-level, Stage 10)

A task is **verified** when:

- [ ] All product AC checked (or explicitly deferred with owner OK + pointer to later task)
- [ ] Listed edge cases for this task spot-checked
- [ ] Plan’s automated tests added (and run when the owner requests a test run)
- [ ] Review gates chosen for the change are done or waived by owner
- [ ] `STATUS.md` reflects closed or blocked state

---

## Anti-patterns

- Coding without a product task (or rewriting AC silently to match the code)
- “Tests pass” without manual verify of user-visible AC
- Putting stage/task status into `tech-lead.mdc`
- Implementing I2+ scope inside an I1 task without labeling out of scope
- Running builds/tests “just to check” without an explicit owner ask

---

## Quick reference

| Artifact | Role |
|---|---|
| Product task | What “done” means (AC) |
| Implementation plan | How to build + verify + test list; on close, `## Code` file map |
| Feature-root comment | Optional reverse link to task folder (breadcrumb only) |
| `STATUS.md` | Where we are now |
| This doc | How we deliver each task |
| `testing-profiling.md` | Stage 11 quality / CI / profiling |
