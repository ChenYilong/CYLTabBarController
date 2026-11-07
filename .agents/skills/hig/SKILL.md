---
name: hig
user-invocable: true
description: "Fact lookup: Apple Human Interface Guidelines corpus (greppable markdown). Query on demand for accessibility and ergonomic minimums (hit-target sizes, Dynamic Type), platform terminology, system component capabilities, and App-Review-relevant conventions. Not design direction."
context: fork
agent: Explore
---

# Human Interface Guidelines Reference

Local greppable copy of Apple's Human Interface Guidelines — an on-demand fact
lookup, not design direction.

Use it to answer factual questions: what a system component can do, what Apple
calls something, accessibility and ergonomic minimums (44pt hit targets,
Dynamic Type behavior, contrast), and conventions App Review actually checks.

**Visual design in our repos is the designing model's own taste.** Consult the
HIG for facts, never for aesthetics — it describes what the system provides
and requires, not what your screen should look like.

## Downloaded Reference Files

All key HIG documentation is available locally (grep-friendly):

### Getting Started

| File | Content | Size |
|------|---------|------|
| [hig-index.md](hig-index.md) | Full HIG table of contents | 11KB |
| [designing-for-ios.md](designing-for-ios.md) | iOS design principles | 5KB |

### Foundations

| File | Content | Size |
|------|---------|------|
| [app-icons.md](app-icons.md) | App icon design guidelines | 14KB |
| [color.md](color.md) | Color usage and system colors | 17KB |
| [typography.md](typography.md) | Fonts, text styles, Dynamic Type | 17KB |
| [layout.md](layout.md) | Layout principles, safe areas | 21KB |
| [materials.md](materials.md) | Materials, blur effects, vibrancy | 14KB |
| [motion.md](motion.md) | Animation principles | 9KB |
| [accessibility.md](accessibility.md) | Accessibility best practices | 19KB |
| [sf-symbols.md](sf-symbols.md) | SF Symbols usage | 21KB |

### Patterns

| File | Content | Size |
|------|---------|------|
| [onboarding.md](onboarding.md) | Onboarding flows | 6KB |
| [modality.md](modality.md) | Modal presentations | 7KB |
| [launching.md](launching.md) | App launch experience | 6KB |
| [feedback.md](feedback.md) | User feedback patterns | 5KB |
| [playing-haptics.md](playing-haptics.md) | Haptic feedback | 10KB |
| [searching.md](searching.md) | Search patterns | 7KB |
| [settings.md](settings.md) | Settings patterns | 7KB |

### Components - Navigation

| File | Content | Size |
|------|---------|------|
| [tab-bars.md](tab-bars.md) | Tab bar design | 11KB |
| [navigation-bars.md](navigation-bars.md) | Navigation bar patterns | 17KB |
| [toolbars.md](toolbars.md) | Toolbar design | 17KB |
| [sidebars.md](sidebars.md) | Sidebar patterns | 8KB |

### Components - Presentation

| File | Content | Size |
|------|---------|------|
| [sheets.md](sheets.md) | Sheet presentations | 11KB |
| [alerts.md](alerts.md) | Alert dialogs | 10KB |
| [action-sheets.md](action-sheets.md) | Action sheets | 4KB |
| [menus.md](menus.md) | Menu design | 14KB |

### Components - Controls

| File | Content | Size |
|------|---------|------|
| [buttons.md](buttons.md) | Button styles and usage | 17KB |
| [lists-and-tables.md](lists-and-tables.md) | List and table patterns | 9KB |
| [toggles.md](toggles.md) | Toggle/switch design | 9KB |
| [pickers.md](pickers.md) | Picker controls | 6KB |
| [sliders.md](sliders.md) | Slider controls | 6KB |
| [steppers.md](steppers.md) | Stepper controls | 2KB |
| [text-fields.md](text-fields.md) | Text input fields | 6KB |

### Searching the Docs

```bash
# Find color guidance
grep -i "semantic" color.md

# Find button styles
grep -i "bordered" buttons.md

# Find haptic patterns
grep -i "notification" playing-haptics.md

# Browse the full HIG index
grep -i "navigation" hig-index.md
```

## Fetching More Docs

1. Search this skill's local `.md` files first.
2. If the topic is not here, check the other installed Apple skills you have available by their names, descriptions, or `SKILL.md` frontmatter, then grep their local files. This is faster and uses less context than fetching new docs from the internet.
3. If no installed skill has the page, use the relevant Human Interface Guidelines path with the `sosumi.ai` Markdown mirror. For example, `/design/human-interface-guidelines/buttons` maps to `https://sosumi.ai/design/human-interface-guidelines/buttons`.

### Common HIG Doc Paths

| Topic | URL Path |
|-------|----------|
| Full Index | `human-interface-guidelines` |
| iOS Design | `human-interface-guidelines/designing-for-ios` |
| iPadOS Design | `human-interface-guidelines/designing-for-ipados` |
| macOS Design | `human-interface-guidelines/designing-for-macos` |
| App Icons | `human-interface-guidelines/app-icons` |
| Color | `human-interface-guidelines/color` |
| Typography | `human-interface-guidelines/typography` |
| Layout | `human-interface-guidelines/layout` |
| Accessibility | `human-interface-guidelines/accessibility` |
| SF Symbols | `human-interface-guidelines/sf-symbols` |
| Buttons | `human-interface-guidelines/buttons` |
| Tab Bars | `human-interface-guidelines/tab-bars` |
| Navigation Bars | `human-interface-guidelines/navigation-bars` |
| Sheets | `human-interface-guidelines/sheets` |
| Alerts | `human-interface-guidelines/alerts` |

## Quick Facts

### System Button Styles (iOS)

What the system provides out of the box:

- **Plain** - Text only, minimal visual weight
- **Gray** - Gray background
- **Tinted** - Tinted background with accent color
- **Filled** - Solid background
- **Bordered** - Outlined with border
- **Bordered Prominent** - Filled background, high prominence

### Haptic Feedback Types

- **Selection** - Light tap for selection changes
- **Impact** - Light/medium/heavy/rigid/soft for collisions
- **Notification** - Success/warning/error for outcomes

### Safe Areas (ergonomic facts)

- Content outside safe areas can be clipped by the notch/Dynamic Island, home
  indicator, or rounded corners
- Interactive elements outside safe areas may be unreachable or intercepted by
  system gestures
- Backgrounds can extend edge-to-edge without those risks

## Sources

### Apple Documentation
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Design Resources](https://developer.apple.com/design/resources/)

### WWDC Sessions
- [Design for Liquid Glass - WWDC25](https://developer.apple.com/videos/play/wwdc2025/10156/)
- [What's new in UIKit - WWDC25](https://developer.apple.com/videos/play/wwdc2025/10144/)
