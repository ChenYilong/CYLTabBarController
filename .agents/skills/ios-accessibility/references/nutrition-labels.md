# App Store Accessibility Nutrition Labels

App Store Connect lets you declare which accessibility features your app
supports. These labels appear on the product page and help users find apps
that support their needs before they download.

Docs:
- [Overview of Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
- [Manage Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/manage-accessibility-nutrition-labels)

## Contents

- [Current Label Categories](#current-label-categories)
- [Claim Rule](#claim-rule)
- [Evidence Matrix and Validation Loop](#evidence-matrix-and-validation-loop)
- [Pass / Fail Criteria](#pass--fail-criteria)
- [SwiftUI Audit Example](#swiftui-audit-example)
- [Related Non-Label Accessibility Work](#related-non-label-accessibility-work)

## Current Label Categories

Apple's current App Store Accessibility Nutrition Labels are:

| Label | What It Means | Key Implementation |
|-------|---------------|-------------------|
| **VoiceOver** | Users can navigate, understand, and operate the app with VoiceOver | Concise labels, values, traits, logical order, alternatives for images/charts, accessible custom controls |
| **Voice Control** | Users can navigate and operate the app with voice commands | Speakable visible/accessibility labels, `accessibilityInputLabels`, custom actions for hidden or gesture-only behavior |
| **Larger Text** | Text can scale to at least 200% where supported | Dynamic Type or an equivalent in-app scaling control, layouts that avoid clipping and overlap |
| **Dark Interface** | The app can keep common-task UI dark | System Dark Mode or an equivalent dark mode without bright flashes in common tasks |
| **Differentiate Without Color Alone** | Color is not the only way to convey information | Text, shape, icon, position, or pattern alternatives for color-coded state and data |
| **Sufficient Contrast** | Text, icons, controls, and state indicators have enough contrast | Semantic colors, high-contrast variants, Reduce Transparency handling, contrast checks in light and dark appearances |
| **Reduced Motion** | Problematic motion can be reduced or replaced | Respect Reduce Motion; replace parallax, spinning, scaling, depth, and ongoing motion with fades or static states where appropriate |
| **Captions** | Dialogue and relevant sounds are available as text for video or audio content | Captions, SDH, subtitles, or transcripts; detect and honor system caption settings |
| **Audio Descriptions** | Visual time-based content has narrated descriptions | Audio description tracks or equivalent narration for video, cut scenes, and visual-only cues |

Apple states these labels appear on Apple devices running iOS 26, iPadOS 26,
macOS 26, tvOS 26, visionOS 26, and watchOS 26 or later. App Store Connect asks
only for labels that apply to the device type.

## Claim Rule

Only claim a label when users can complete all common tasks of the app using
that feature. Build a task matrix per device and test the common workflows
before answering in App Store Connect.

Keep claims accurate over time and do not treat App Store accessibility answers
as marketing claims. Apple notes that App Review may contact developers to
update intentionally misleading or harmful accessibility labels.

## Evidence Matrix and Validation Loop

Create one row for every common task on every supported device type. Test only
the feature claims that apply to that task, and link each result to reproducible
evidence rather than a general statement that the app is accessible.

| Device | Common task | Feature claim | Evidence | Result | Owner |
|---|---|---|---|---|---|
| iPhone | Complete checkout | VoiceOver | Test steps, recording, and issue link | Pass/Fail | Team or person |

For each proposed label:

1. Inventory common tasks and applicable device types.
2. Test every applicable matrix cell against the criteria below.
3. Fix failed cells, then repeat the same task from its initial state.
4. Claim the label only when every applicable common-task cell passes.
5. Re-run the matrix after material UI or media changes and correct App Store
   Connect answers when support changes.

## Pass / Fail Criteria

### VoiceOver

- Every interactive element has a concise, meaningful label.
- Labels avoid control types and state words that VoiceOver already announces.
- Images and charts provide useful descriptions or text alternatives.
- Decorative images are hidden.
- Custom controls expose role, value, action, and traversal order.
- Dynamic content that matters is announced with the appropriate accessibility notification.

### Voice Control

- Common tasks work using only voice commands.
- Visible labels and Voice Control names match whenever practical.
- `accessibilityInputLabels` provide short spoken alternatives for long labels.
- "Show Names" and "Show Numbers" expose all interactive elements.
- Swipes, long presses, hover-only controls, and hidden actions have a speech-only path, usually through custom accessibility actions.

### Larger Text

- Text reaches at least 200% of the default size where the platform supports the label.
- Main workflows avoid clipped, overlapped, or severely truncated text.
- Layouts adapt at accessibility text sizes, often by switching from horizontal to vertical composition.
- Meaningful icons or text-like graphics scale or have an equivalent perceivable alternative.

### Dark Interface

- Common-task screens remain dark when the user selects a dark appearance or the app's dark setting.
- Bright loading flashes, interstitials, and modal surfaces are avoided.
- Dark mode is tested together with sufficient contrast settings.

### Differentiate Without Color Alone

- Status, validation, selection, chart series, and game/team state never rely on color alone.
- Use text, symbols, shape, order, pattern, or direct labels in addition to color.
- Test important workflows with grayscale or color filters to find hidden reliance on color.

### Sufficient Contrast

- Most text meets generally accepted contrast guidance, commonly 4.5:1 against its background.
- Non-text state indicators and custom controls have sufficient contrast, commonly 3:1.
- Test light mode, dark mode, Increase Contrast, Bold Text, and Reduce Transparency combinations.
- Custom colors provide high-contrast variants when semantic system colors are not enough.

### Reduced Motion

- Disable or replace parallax, spinning, scaling, vortex, multi-axis, multi-speed, and depth-simulating motion when Reduce Motion is enabled.
- Stop ongoing motion such as auto-advancing carousels or provide a user control to stop it.
- Preserve meaning when replacing motion; use fades, highlights, or instant transitions for state changes.

### Captions

- Video dialogue and comprehension-relevant sound effects are captioned.
- Captions are synchronized, readable, and identify speakers where needed.
- Audio-only dialogue has a transcript when time-synchronized captions do not apply.
- AVFoundation media uses appropriate characteristics such as `.transcribesSpokenDialogForAccessibility` and `.describesMusicAndSoundForAccessibility`.

### Audio Descriptions

- Visual-only story, instructions, scene changes, on-screen text, and important cues are narrated.
- Descriptions fit natural pauses and do not obscure essential dialogue.
- AVFoundation media uses `.describesVideoForAccessibility` for audio description options.

## SwiftUI Audit Example

```swift
struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack {
            Image("hero")
                .accessibilityLabel("Mountain landscape at sunset")

            Text("Welcome")
                .font(.title)

            Button("Get Started") { }
                .accessibilityHint("Opens the onboarding flow")
        }
        .animation(reduceMotion ? nil : .spring(), value: showContent)
    }
}
```

## Related Non-Label Accessibility Work

Switch Control and Full Keyboard Access remain important app accessibility
requirements, but they are not current App Store Accessibility Nutrition Label
categories. Keep their implementation guidance in `SKILL.md` and
`references/a11y-patterns.md`.
