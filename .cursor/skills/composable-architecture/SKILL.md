---
name: composable-architecture
description: >-
  Trigger when building or changing TCA features: @Reducer, State/Action,
  Effects, @Dependency, NavigationStack path, @Presents sheets, TestStore.
  Router only — load exactly one references/*.md for the current concern.
---

# The Composable Architecture (TCA)

Glimpse uses TCA for features. Canonical example: `Packages/GlimpseFeatures/Sources/GlimpseFeatures/WordsFolder/GLIWordsFolderFeature.swift`.

## Load rule (required)

1. Pick **exactly one** reference that matches the current task.
2. **Read that file** with the Read tool before coding.
3. Do **not** preload the whole `references/` tree. If a second topic appears, load a second file then — never all at once.

| Load this | When |
|---|---|
| [reducer-structure](references/reducer-structure.md) | New `@Reducer`, State, Action, `@ViewAction` |
| [views-binding](references/views-binding.md) | `@Bindable`, `store.send`, `.task` / appear |
| [views-composition](references/views-composition.md) | `ForEach` stores, child scoping |
| [navigation-basics](references/navigation-basics.md) | `NavigationStack`, path push/pop |
| [navigation-advanced](references/navigation-advanced.md) | Deep link, recursive nav, stack+sheet |
| [shared-state](references/shared-state.md) | `@Shared`, appStorage |
| [dependencies](references/dependencies.md) | `@DependencyClient`, test deps |
| [effects](references/effects.md) | `.run`, cancel, merge, timers |
| [presentation](references/presentation.md) | `@Presents`, alerts, Destination |
| [testing-fundamentals](references/testing-fundamentals.md) | TestStore setup |
| [testing-patterns](references/testing-patterns.md) | Action/state/error/presentation tests |
| [testing-advanced](references/testing-advanced.md) | TestClock, exhaustivity off |
| [testing-utilities](references/testing-utilities.md) | Factories, LockIsolated |
| [performance](references/performance.md) | High-frequency actions, scoping |
