---
name: ios-hig
description: >-
  Trigger for HIG compliance: 44pt targets, VoiceOver/Dynamic Type, dark mode
  contrast, haptics/animation feedback, empty-state copy, or permission UX.
  Router — load exactly one reference.
---

# iOS Human Interface Guidelines

## Load rule (required)

Load **exactly one** `references/*.md`. Do not preload the tree.

| Load this | When |
|---|---|
| [interaction](references/interaction.md) | Touch targets, nav, layout, gestures |
| [content](references/content.md) | Empty states, copy, typography |
| [visual-design](references/visual-design.md) | Color, materials, dark mode, symbols |
| [accessibility](references/accessibility.md) | VoiceOver, Dynamic Type, Reduce Motion |
| [feedback](references/feedback.md) | Animation, haptics, loading, errors |
| [performance-platform](references/performance-platform.md) | Responsiveness, launch, system UI |
| [privacy-permissions](references/privacy-permissions.md) | Permission prompts / privacy APIs |
