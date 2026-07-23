---
name: swift-diagnostics
description: >-
  Trigger when debugging: NavigationStack hangs/pops, SPM/"No such module",
  retain cycles/leaks, slow builds, or LLDB/view debugging. Router — load
  exactly one reference and follow its checks before changing code.
---

# Swift diagnostics

## Load rule (required)

1. Classify the symptom.
2. Load **exactly one** matching reference.
3. Run that file’s mandatory first checks **before** editing code.

| Load this | When |
|---|---|
| [navigation](references/navigation.md) | NavStack stuck, unexpected pops, deep links |
| [build-issues](references/build-issues.md) | SPM, missing modules, dep conflicts |
| [memory](references/memory.md) | Retain cycles, growth, missing deinit |
| [build-performance](references/build-performance.md) | Slow builds, DerivedData, Xcode hangs |
| [xcode-debugging](references/xcode-debugging.md) | LLDB, breakpoints, view debugger |
