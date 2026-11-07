---
name: ios-accessibility
description: "Build and audit SwiftUI, UIKit, and AppKit accessibility for VoiceOver, Voice Control, Switch Control, Full Keyboard Access, Dynamic Type, focus restoration, labels/traits/actions, traversal, custom rotors, NSAccessibility, XCTest checks, adaptive system preferences, and App Store accessibility declarations. Use when implementing accessible UI, fixing an accessibility audit, testing assistive-technology behavior, or substantiating App Store Accessibility Nutrition Labels."
---

# iOS/macOS Accessibility - SwiftUI, UIKit, and AppKit

Build SwiftUI, UIKit, and AppKit interfaces that remain operable with VoiceOver, Switch Control, Voice Control, Full Keyboard Access, and adaptive accessibility settings.

## Contents

- [Core Principles](#core-principles)
- [How VoiceOver Reads Elements](#how-voiceover-reads-elements)
- [SwiftUI Accessibility Modifiers](#swiftui-accessibility-modifiers)
- [Focus Management](#focus-management)
- [Dynamic Type](#dynamic-type)
- [Custom Rotors](#custom-rotors)
- [System Accessibility Preferences](#system-accessibility-preferences)
- [Decorative Content](#decorative-content)
- [Voice Control](#voice-control)
- [Switch Control](#switch-control)
- [Full Keyboard Access](#full-keyboard-access)
- [Assistive Access (iOS 18+)](#assistive-access-ios-18)
- [UIKit Accessibility Patterns](#uikit-accessibility-patterns)
- [AppKit Accessibility Patterns](#appkit-accessibility-patterns)
- [Accessibility Custom Content](#accessibility-custom-content)
- [App Store Accessibility Nutrition Labels](#app-store-accessibility-nutrition-labels)
- [Testing Accessibility](#testing-accessibility)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

---

## Core Principles

1. Prefer semantic system controls; custom controls must expose the same name,
   role, value, state, and actions.
2. Preserve every task across assistive input: do not make a gesture, color,
   motion, hover state, or visual arrangement the only path to meaning or action.
3. Keep focus and traversal intentional across navigation, presentation, updates,
   and dismissal.
4. Let text, layout, contrast, transparency, and motion adapt to the user's
   accessibility settings.
5. Treat App Store accessibility declarations as evidence-backed product claims,
   not as a summary of isolated control-level support.

## How VoiceOver Reads Elements

VoiceOver reads element properties in a fixed, non-configurable order:

**Label -> Value -> Trait -> Hint**

Design your labels, values, and hints with this reading order in mind.

## SwiftUI Accessibility Modifiers

See [references/a11y-patterns.md](references/a11y-patterns.md) for detailed SwiftUI modifier examples (labels, hints, traits, grouping, custom controls, adjustable actions, and custom actions).

## Focus Management

Focus management is where most apps fail. When a sheet, alert, or popover is dismissed, VoiceOver focus MUST return to the element that triggered it.

This section is about accessibility focus for assistive technologies. For keyboard focus, directional focus, `focusSection()`, scene-focused values, and `UIFocusGuide`, use the `focus-engine` skill.

Audit element order and grouping in [Traversal Order](#traversal-order); route keyboard-focus mechanics to `focus-engine`.

### `@AccessibilityFocusState` (iOS 15+)

`@AccessibilityFocusState` is a property wrapper that reads and writes the current accessibility focus. It works with `Bool` for single-target focus or an optional `Hashable` enum for multi-target focus.

```swift
struct ContentView: View {
    @State private var showSheet = false
    @AccessibilityFocusState private var focusOnTrigger: Bool

    var body: some View {
        Button("Open Settings") { showSheet = true }
            .accessibilityFocused($focusOnTrigger)
            .sheet(isPresented: $showSheet) {
                SettingsSheet()
                    .onDisappear {
                        // Slight delay allows the transition to complete before moving focus
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(100))
                            focusOnTrigger = true
                        }
                    }
            }
    }
}
```

### Multi-Target Focus with Enum

```swift
enum A11yFocus: Hashable {
    case nameField
    case emailField
    case submitButton
}

struct FormView: View {
    @AccessibilityFocusState private var focus: A11yFocus?

    var body: some View {
        Form {
            TextField("Name", text: $name)
                .accessibilityFocused($focus, equals: .nameField)
            TextField("Email", text: $email)
                .accessibilityFocused($focus, equals: .emailField)
            Button("Submit") { validate() }
                .accessibilityFocused($focus, equals: .submitButton)
        }
    }

    func validate() {
        if name.isEmpty {
            focus = .nameField // Move VoiceOver to the invalid field
        }
    }
}
```

### Custom Modals

Custom overlay views need the `.isModal` trait to trap VoiceOver focus and an escape action for dismissal:

```swift
CustomDialog()
    .accessibilityAddTraits(.isModal)
    .accessibilityAction(.escape) { dismiss() }
```

Test dismissal as part of the modal contract: users must be able to dismiss the overlay with the relevant assistive-technology escape gesture or keyboard escape path, and focus should return to the trigger or next logical target.

### Accessibility Notifications (UIKit)

When you need to announce changes or move focus imperatively in UIKit contexts:

```swift
// Announce a status change (e.g., "Item deleted", "Upload complete")
UIAccessibility.post(notification: .announcement, argument: "Upload complete")

// Partial screen update -- move focus to a specific element
UIAccessibility.post(notification: .layoutChanged, argument: targetView)

// Full screen transition -- move focus to the new screen
UIAccessibility.post(notification: .screenChanged, argument: newScreenView)
```

## Dynamic Type

Scale text with system text styles. Scale non-text dimensions too: icon sizes, spacing, control heights, and custom hit-region dimensions should use `@ScaledMetric(relativeTo:)` where they need to track text size.

See [references/a11y-patterns.md](references/a11y-patterns.md) for Dynamic Type and adaptive layout examples, including `@ScaledMetric` and minimum tap target patterns.

## Custom Rotors

Rotors let VoiceOver users quickly navigate to specific content types. Add custom rotors for content-heavy screens. See [references/a11y-patterns.md](references/a11y-patterns.md) for complete rotor examples.

## System Accessibility Preferences

Always respect these environment values:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.colorSchemeContrast) var contrast         // .standard or .increased
@Environment(\.legibilityWeight) var legibilityWeight    // .regular or .bold
```

### Reduce Motion

Replace movement-based animations with crossfades or no animation:

```swift
withAnimation(reduceMotion ? nil : .spring()) {
    showContent.toggle()
}
content.transition(reduceMotion ? .opacity : .slide)
```

Review every moving transition, including row deletion, quantity changes, sheet or checkout presentation, and modal dismissal. Under Reduce Motion, replace slide, bounce, parallax, spring, and large spatial transitions with opacity changes, instant state changes, or no animation.

### Reduce Transparency, Increase Contrast, Bold Text

```swift
// Solid backgrounds when transparency is reduced
.background(reduceTransparency ? Color(.systemBackground) : Color(.systemBackground).opacity(0.85))

// Stronger colors when contrast is increased
.foregroundStyle(contrast == .increased ? .primary : .secondary)

// Bold weight when system bold text is enabled
.fontWeight(legibilityWeight == .bold ? .bold : .regular)
```

## Decorative Content

```swift
// Decorative images: hidden from VoiceOver
Image(decorative: "background-pattern")
Image("visual-divider").accessibilityHidden(true)

// Icon next to text: Label handles this automatically
Label("Settings", systemImage: "gear")

// Icon-only buttons: MUST have an accessibility label
Button(action: { }) {
    Image(systemName: "gear")
}
.accessibilityLabel("Settings")
```

Treat an image as decorative only when it adds no information beyond adjacent accessible text. If it communicates a product variant, state, chart point, user-generated content, or another distinguishing detail, provide a meaningful description instead of hiding it.

## Voice Control

Voice Control relies on accessibility labels to generate spoken tap targets. If a label is missing or unspeakable, Voice Control cannot target the element.

- Every interactive element MUST have a speakable accessibility label (no emoji-only, no symbol-only).
- Labels must be unique within the visible screen — duplicate labels force users to disambiguate with overlay numbers.
- Treat `accessibilityInputLabels` as pre-freeze accessibility work for long, awkward, localized, acronym-heavy, or commonly shortened spoken labels; do not defer it as polish. Voice Control and Full Keyboard Access use these. List alternatives in descending order of importance.
- Apply `accessibilityInputLabels` broadly to any visible target whose primary label is hard to say, including repeated row actions, quantity controls, account/settings links, media controls, and localized labels with acronyms or product names.
- Test with Voice Control enabled: say "Show Names" and "Show Numbers" to verify all interactive elements are targetable.
- For Voice Control reviews, verify both overlays: "Show Names" confirms speakable labels, and "Show Numbers" confirms every visible interactive target can still be reached when names are missing, duplicated, or awkward.

See [references/a11y-patterns.md](references/a11y-patterns.md) for `accessibilityInputLabels` examples and speakable label guidelines.

## Switch Control

Switch Control scans accessibility elements sequentially in reading order. Proper grouping and custom actions are critical for usability.

- Group related content with `.accessibilityElement(children: .combine)` to reduce scan stops.
- Every scan target should be meaningful and actionable. Decorative elements hidden from VoiceOver are also hidden from Switch Control.
- Switch Control users cannot perform swipe-to-delete, long-press, or multi-finger gestures. Expose these interactions as `.accessibilityAction(named:)` custom actions instead — Switch Control presents them as a menu.
- Custom controls with non-standard hit areas should ensure `accessibilityFrame` accurately reflects the tappable region (for point scanning mode).

See [references/a11y-patterns.md](references/a11y-patterns.md) for custom action and grouping examples.

## Full Keyboard Access

Full Keyboard Access (iOS/iPadOS 13.4+) lets users navigate and operate an app with a hardware keyboard.

Audit whether every control is reachable, labeled, visibly focused, and operable without touch. Route Tab/directional focus, `.focusable()`, `@FocusState`, `focusSection()`, scene-focused values, tvOS focus, and `UIFocusGuide` implementation to `focus-engine`.

- Every interactive element can be reached and activated with the keyboard.
- Traversal order is logical and does not trap focus.
- Focus indicators remain visible at all contrast and text-size settings.
- Gesture-only behavior has a keyboard-operable alternative.
- App shortcuts do not override system-defined shortcuts such as Cmd+C, Cmd+V, or Cmd+Tab.

See [references/a11y-patterns.md](references/a11y-patterns.md) for Full Keyboard Access audit checks.

## Traversal Order

Element order and grouping must follow visual and task order across VoiceOver swipe order, Switch Control scanning, Voice Control overlays, and Full Keyboard Access review. Check missing or duplicate labels, excessive row children, hidden custom controls, focus traps, and groups whose order diverges from the task. Keep keyboard or directional routing mechanics in `focus-engine`.

## Assistive Access (iOS 18+)

Assistive Access provides a simplified interface for users with cognitive disabilities. Apps should support this mode:

```swift
// Check if Assistive Access is active (iOS 18+)
@Environment(\.accessibilityAssistiveAccessEnabled) var isAssistiveAccessEnabled

var body: some View {
    if isAssistiveAccessEnabled {
        SimplifiedContentView()
    } else {
        FullContentView()
    }
}
```

Key guidelines:
- Reduce visual complexity: fewer controls, larger tap targets, simpler navigation
- Use clear, literal language for labels and instructions
- Minimize the number of choices presented at once
- Test with Assistive Access enabled in Settings > Accessibility > Assistive Access

## UIKit Accessibility Patterns

For custom UIKit views, expose meaningful elements, labels, values, traits, and actions; mutate traits with `insert`/`remove`; make custom overlays modal; and use the appropriate announcement, layout-changed, or screen-changed notification. Load [references/a11y-patterns.md](references/a11y-patterns.md) for complete UIKit examples.

## AppKit Accessibility Patterns

Prefer standard AppKit controls. For custom `NSView` or virtual elements, expose the correct `NSAccessibility` role, label, value, actions, and state-change notifications. Load [references/a11y-patterns.md](references/a11y-patterns.md) for `NSAccessibilityElement` and custom-control examples.

## Accessibility Custom Content

Use `.accessibilityCustomContent` for useful secondary facts without adding swipe stops; reserve high importance for content that should read automatically. See [references/a11y-patterns.md](references/a11y-patterns.md) for SwiftUI, UIKit, and AppKit examples.

## App Store Accessibility Nutrition Labels

For App Store accessibility nutrition labels, product-page claims, or App Store Connect accessibility answers, read [references/nutrition-labels.md](references/nutrition-labels.md).

Before recommending a claim, require evidence that users can complete all common tasks with that feature on the relevant device type. Use a structured common-task by accessibility-feature matrix, include media transcripts when captions for audio-only content are relevant, and explicitly warn that App Store accessibility answers must stay accurate and must not be treated as marketing claims.

## Testing Accessibility

### Manual Testing

- **Accessibility Inspector**: Audit labels, traits, and contrast against Simulator and devices.
- **VoiceOver testing**: Enable in Settings > Accessibility > VoiceOver. Navigate every screen with swipe gestures.
- **Voice Control testing**: Enable in Settings > Accessibility > Voice Control. Say both "Show Names" and "Show Numbers"; names verify speakable labels, while numbers verify every visible interactive target is reachable even when names are duplicated, missing, or awkward.
- **Full Keyboard Access testing**: Enable in Settings > Accessibility > Keyboards > Full Keyboard Access. Tab through every screen and verify all interactive elements receive focus.
- **Switch Control testing**: Enable in Settings > Accessibility > Switch Control. Verify scan order is logical and custom actions appear for gesture-based interactions.
- **Dynamic Type**: Test with all text sizes in Settings > Accessibility > Display & Text Size > Larger Text.

### Automated Testing with XCTest

Use stable accessibility identifiers to locate `XCUIElement` values, then assert existence, enabled/selected state, meaningful labels/values, and `hasFocus` where the test environment exposes focus. Cover dismissal focus restoration, every modal exit path, and gesture alternatives. UI automation complements—not replaces—VoiceOver, Voice Control, Switch Control, keyboard, Dynamic Type, contrast, Reduce Motion, and Reduce Transparency testing. Load [references/a11y-patterns.md](references/a11y-patterns.md) for XCTest examples.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Trait assignment overwrites behavior | Insert/remove UIKit traits or use SwiftUI accessibility trait modifiers. |
| Dismissal loses focus | Return accessibility focus to the trigger. |
| Rows create excessive swipe stops | Group related children deliberately. |
| Labels repeat control type or omit icon meaning | Use a concise, speakable action/name; traits announce type. |
| Motion, text size, contrast, or transparency is fixed | Respond to the matching accessibility preference and adaptive text styles. |
| Targets are small or color-only | Provide a 44×44 target plus text, shape, or icon semantics. |
| Custom overlay is not modal | Expose modal semantics, escape action, and restoration. |

## Review Checklist

For every common task, record evidence for these gates:

- [ ] Semantics: controls expose concise names, correct roles/states/values, and
  alternatives for decorative, color-only, gesture-only, or adjustable content.
- [ ] Navigation: grouping and traversal are intentional; modals expose modal and
  escape behavior; focus returns to the initiating control.
- [ ] Input: Voice Control names are speakable and unique, Show Names/Numbers both
  work, Switch Control exposes gesture alternatives, and Full Keyboard Access has
  no unreachable controls, traps, or overridden system shortcuts.
- [ ] Adaptation: Dynamic Type, Reduce Motion, Reduce Transparency, Increase
  Contrast, Bold Text, and 44x44-point targets are verified in representative
  layouts and states.
- [ ] Automation: XCTest covers stable identifiers, state, focus where available,
  and every modal exit path without substituting for manual assistive-technology
  testing.
- [ ] Concurrency: accessibility values and notification payloads crossing
  isolation boundaries are `Sendable`.
- [ ] Claims: each App Store accessibility declaration is supported by a completed
  common-task evidence matrix for every declared device type.

## References

- [references/a11y-patterns.md](references/a11y-patterns.md) — SwiftUI and UIKit modifier examples, grouping, custom actions, rotors, Dynamic Type
- [references/nutrition-labels.md](references/nutrition-labels.md) — App Store Accessibility Nutrition Labels: current categories with pass/fail criteria
- [references/media-accessibility.md](references/media-accessibility.md) — Captions, audio descriptions, AVMediaCharacteristic, SDH
