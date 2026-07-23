---
name: swiftui-patterns
description: >-
  Trigger for iOS 17+ SwiftUI: @Observable/@Bindable, NavigationStack,
  .task/.refreshable, environment injection, UIKit interop, a11y, or
  migrating off ObservableObject. Router — load exactly one reference.
---

# SwiftUI patterns (iOS 17+)

Prefer `@Observable` + `.task` over `ObservableObject` / `onAppear { Task {} }`. Glimpse features use TCA stores — use this skill for view-layer patterns, not reducer design (`composable-architecture`).

## Load rule (required)

Load **exactly one** `references/*.md`. Do not preload the tree.

| Load this | When |
|---|---|
| [observable](references/observable.md) | New `@Observable` models |
| [state-management](references/state-management.md) | `@State` / `@Bindable` / `@Environment` choice |
| [environment](references/environment.md) | Injecting into the hierarchy |
| [view-modifiers](references/view-modifiers.md) | `onChange`, `task`, modern modifiers |
| [migration-guide](references/migration-guide.md) | iOS 16 → 17+ migration |
| [mvvm-observable](references/mvvm-observable.md) | Non-TCA MVVM setup |
| [navigation](references/navigation.md) | Programmatic / deep-link nav |
| [performance](references/performance.md) | Large lists / excess re-renders |
| [uikit-interop](references/uikit-interop.md) | UIViewRepresentable wrappers |
| [accessibility](references/accessibility.md) | VoiceOver / Dynamic Type |
| [async-patterns](references/async-patterns.md) | Loading / refresh / background |
| [composition](references/composition.md) | Reusable modifiers / conditional UI |
