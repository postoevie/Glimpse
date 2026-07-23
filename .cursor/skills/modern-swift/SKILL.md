---
name: modern-swift
description: >-
  Trigger for Swift concurrency work: async/await, @MainActor, actors,
  Sendable errors, TaskGroup, cancellation, Swift 6 strict concurrency,
  or migrating off completion handlers. Router — load exactly one reference.
---

# Modern Swift (concurrency)

Prefer `async/await`, `@MainActor` for UI, `actor` for shared mutable state. Prefer Context7 for current API details.

## Load rule (required)

Load **exactly one** `references/*.md` for the active concern. Do not load the whole tree.

| Load this | When |
|---|---|
| [concurrency-essentials](references/concurrency-essentials.md) | Writing async code / await basics |
| [swift6-concurrency](references/swift6-concurrency.md) | `@concurrent`, actor patterns |
| [task-groups](references/task-groups.md) | Parallel `TaskGroup` work |
| [task-cancellation](references/task-cancellation.md) | Cancellable / long-running tasks |
| [strict-concurrency](references/strict-concurrency.md) | Enabling strict mode / Sendable fixes |
| [macros](references/macros.md) | Swift macros (e.g. `@Observable`) |
| [modern-attributes](references/modern-attributes.md) | `@preconcurrency`, `@backDeployed` |
| [migration-patterns](references/migration-patterns.md) | Modernizing delegates / UIKit |
