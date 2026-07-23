---
name: development-workflow
description: >-
  Trigger for Stage 10 delivery: implement/ship/close a planning task, verify
  vs AC, review order. Enforces plan → code → verify → test → review → close.
  Canonical: docs/development-workflow.md.
---

# Development workflow (agent)

## Canonical

Read **`docs/development-workflow.md`** for full gates. Live status: **`docs/STATUS.md`**. Stage 11: `docs/testing-profiling.md`.

## Order (do not skip)

1. Preconditions — task + AC; impl plan (unless owner skips); blockers in `STATUS.md`
2. Code — this repo (`Packages/…`, `Glimpse/` app per `AGENTS.md`)
3. Verify — manual AC (owner final say)
4. Test — only tests named in the impl plan (**do not** run builds/tests unless the user explicitly asks)
5. Review — owner skim; optional specialist / Bugbot / security
6. Close — tick AC; `## Code` on impl plan; optional `// Task:` breadcrumb; update `STATUS.md`

## Related skills

| Need | Skill |
|---|---|
| Epic / product task | `product-decomposition` |
| Tech plan beside task | `implementation-plan` |

## Anti-patterns

- Skipping verify because “tests later”
- Running `xcodebuild` / tests without an explicit user ask
- Putting current stage/task into `tech-lead.mdc`
- Coding without a task file or silently dropping AC
