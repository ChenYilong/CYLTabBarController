---
name: ui-review
description: Review SwiftUI code for iOS/watchOS Human Interface Guidelines compliance, font usage, Dynamic Type support, and accessibility. Use when user mentions UI review, HIG, accessibility audit, font checks, or wants to verify interface design against Apple standards.
allowed-tools: [Read, Glob, Grep, WebFetch]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# UI Review Skill

Performs comprehensive UI/UX review of SwiftUI code against Apple's Human Interface Guidelines, font best practices, and accessibility standards for iOS and watchOS.

## When This Skill Activates

Use this skill when the user:
- Asks to review UI/UX code
- Mentions HIG compliance or Apple guidelines
- Requests accessibility audit
- Wants font usage checked
- Asks about Dynamic Type support
- Requests design review against Apple standards

## Review Process

### 1. Identify Files to Review

- If user specifies files/views, review those
- Otherwise, ask which views to review or scan recent SwiftUI files
- Prioritize user-facing views over components

### 2. Load Reference Materials

Before starting the review, familiarize yourself with the reference materials by reading the following files in `.claude/skills/ui-review/`:

- **hig-checklist.md** - Comprehensive HIG compliance checklist for iOS and watchOS
- **font-guidelines.md** - Font usage, Dynamic Type, and typography best practices
- **accessibility-quick-ref.md** - Quick reference for accessibility implementation

You may also reference the official Apple guidelines using WebFetch when needed:
- **iOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- **watchOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos

### 3. Review Categories

Apply these review categories based on the code type:

**HIG Compliance:**
- Layout & spacing (tap targets, safe areas, padding)
- Navigation patterns (NavigationStack, sheets, alerts)
- Colors & visuals (semantic colors, dark mode, contrast)
- Platform-specific requirements (iOS vs watchOS)
- Loading/empty/error states

**Font Usage:**
- Dynamic Type support
- System text styles vs fixed sizes
- Font hierarchy and semantic usage
- Custom fonts scaling properly
- Text formatting and truncation

**Accessibility:**
- Labels and hints for interactive elements
- Traits and roles
- VoiceOver navigation order
- Custom actions
- Dynamic content announcements
- Testing with assistive technologies

### 4. Common Issues to Flag

**Anti-patterns:**
- Hardcoded colors (`.foregroundColor(.black)`)
- Fixed font sizes (`.font(.system(size: 14))`)
- Missing accessibility labels on icon-only buttons
- Tap targets smaller than 44pt (iOS) or 40pt (watchOS)
- Important info conveyed by color only
- Missing loading/error states
- Direct UIColor usage (use `Color(.systemBackground)`)
- `.frame()` without considering Dynamic Type expansion
- Missing keyboard shortcuts (iPad/Mac)

**Good Patterns:**
- Semantic color usage
- System font styles with Dynamic Type
- Comprehensive accessibility labels
- Clear visual hierarchy
- Consistent spacing
- Proper error handling
- Responsive layouts

### 5. Component Checklists

Apply when the reviewed code contains the component.

**Search UX (WWDC26):**
- [ ] Standard Search Field anatomy intact — leading magnifying-glass icon, placeholder, clear button; on iOS a Cancel button appears while focused. Don't rebuild these from scratch
- [ ] iOS placement: prefer the bottom toolbar — it animates above the keyboard and stays within thumb reach
- [ ] Tab apps: exactly one primary Search tab, not a search field per tab
- [ ] iPad/Mac placement: trailing side of the toolbar, or pinned at the top of the sidebar
- [ ] Recent searches shown on focus, with per-item removal and a clear-all affordance
- [ ] Suggestions correspond to the typed text, visually distinguish the user's input from the predicted part, and are limited in count
- [ ] Scope Bar used for lightweight filtering of where to search (e.g. All / Sender / Subject)
- [ ] Search Tokens supplement — never replace — visible filter UI (tokens are less discoverable)
- [ ] Empty results show a Content Unavailable view (`ContentUnavailableView.search`), not a blank list

**Menus & Pickers (WWDC20):**
- [ ] Menus preferred over action sheets/popovers for NON-destructive actions — the menu opens adjacent to the tap (less eye/finger travel) and doesn't dim the screen
- [ ] Action sheets kept for destructive confirmation — their friction is deliberate
- [ ] Never ALL primary actions hidden in a menu or "more" (ellipsis) button — menus hold secondary actions only
- [ ] Each menu fits one of four uses: disambiguation, navigation, selection (check marks required), or secondary actions
- [ ] Menu anatomy: label on the left, icon on the right, separators to group — and NO Cancel item (tapping outside cancels)
- [ ] Date pickers: inline (calendar) when space allows, compact style when constrained

## Output Format

Provide review in this structure:

### ✅ HIG Compliance
- List items that comply well
- Highlight good practices

### ⚠️ HIG Issues Found
- Specific line references: `filename.swift:lineNumber`
- Description of issue
- Suggested fix with code example

### ✅ Font Usage
- Proper Dynamic Type usage
- Good font hierarchy

### ⚠️ Font Issues Found
- Hardcoded sizes or missing Dynamic Type support
- Suggested fixes

### ✅ Accessibility
- Well-implemented accessibility features
- Good label/hint usage

### ⚠️ Accessibility Issues Found
- Missing labels or hints
- Incorrect traits
- Navigation problems
- Suggested fixes with code examples

### 📋 Testing Recommendations
- Specific tests to run (VoiceOver, Dynamic Type, Dark Mode)
- Accessibility Inspector checks
- Device/simulator testing suggestions

## Example Review Output

```
Reviewing: AddOrUpdateExpenseView.swift

✅ HIG Compliance
- Good use of semantic colors throughout
- Proper NavigationStack implementation
- Safe area handling is correct

⚠️ HIG Issues Found
1. AddOrUpdateExpenseView.swift:145 - Delete button tap target may be small
   Suggested fix: Ensure .frame(minWidth: 44, minHeight: 44)

2. AddOrUpdateExpenseView.swift:203 - Hardcoded color
   Current: .foregroundColor(.red)
   Suggested: .foregroundColor(Color(.systemRed))

✅ Font Usage
- Excellent use of .headline for section headers
- Proper .body for content text

⚠️ Font Issues Found
1. AddOrUpdateExpenseView.swift:178 - Hardcoded font size
   Current: .font(.system(size: 14))
   Suggested: .font(.subheadline)

✅ Accessibility
- Good labels on most form fields
- Proper form structure

⚠️ Accessibility Issues Found
1. AddOrUpdateExpenseView.swift:92 - Icon button missing label
   Current: Button { } label: { Image(systemName: "calendar") }
   Suggested: Add .accessibilityLabel("Select date")

📋 Testing Recommendations
1. Test with VoiceOver enabled
2. Test at largest Dynamic Type size (Accessibility → Display)
3. Verify in Dark Mode
4. Use Accessibility Inspector to check contrast ratios
```

## References

Always reference these when in doubt:
- [iOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [watchOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Accessibility on Apple platforms](https://developer.apple.com/accessibility/)

## Notes

- Be constructive and specific
- Provide code examples for fixes
- Reference exact line numbers
- Prioritize user-impacting issues
- Consider context (some exceptions are valid)
