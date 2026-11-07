# Accessibility Nutrition Labels

App Store product-page declarations of which accessibility features your app supports — so people know the app works for them **before** downloading. Sourced from Apple's WWDC25 "Evaluate your app for Accessibility Nutrition Labels" (224) and the 2026 Tech Talk "Prepare your app for Accessibility Nutrition Labels" (111433).

The core requirement is **accuracy**: claim a feature only if people can truly complete ALL common tasks with it, on every device family the app supports.

## The Three-Step Process (WWDC25 224)

1. **Define common tasks** — the primary functionality people download the app for, PLUS the fundamentals: first-launch experience, login, purchase, settings.
2. **Evaluate each common task against each feature**, on every supported device family (iPhone, iPad, Mac, Watch…). Only claim features relevant to your app's functionality.
3. **Declare in App Store Connect** — the app's accessibility settings → select supported features → optionally link your accessibility webpage → publish.

## The Nine Features and Their Criteria

Grouped into three categories (Tech Talk 111433):

### Interaction methods

| Feature | You may claim it when… |
|---|---|
| **VoiceOver** | All common tasks are completable with VoiceOver gestures/keyboard alone — no sight, no direct touch. Every element has a descriptive `accessibilityLabel`, correct traits, and a value where stateful (the **Label + Traits + Value** contract). |
| **Voice Control** | All common tasks are completable by voice only. Labels drive what users can say; add `accessibilityInputLabels` synonyms ("Favorite", "Heart", "Like") where one name isn't obvious. ❌ Icon-only buttons with no label are instant disqualifiers. |

### Visual

| Feature | You may claim it when… |
|---|---|
| **Larger Text** | Text scales to **at least 200%** throughout all common tasks; text wraps to more lines (never truncates), fields **grow** (scrolling alone is insufficient), no overlap. Context: standard Dynamic Type spans 100–135%; accessibility sizes reach **310%** (body: 17pt → 28pt → 53pt). |
| **Sufficient Contrast** | High foreground/background contrast by default — or verified with **Increase Contrast** on. Test light AND dark appearance. |
| **Dark Interface** | Common tasks work in dark mode; with **Smart Invert**, photos/video must NOT invert (`accessibilityIgnoresInvertColors`). |
| **Differentiate Without Color Alone** | Color is never the only channel — add shapes, icons, or text (Swift Charts: `.symbol(by:)` so series differ by shape too). |
| **Reduced Motion** | No dizziness/nausea triggers during common tasks: zoom/slide transitions, flashing, auto-playing animation, parallax. With the setting on, **modify animations, don't just remove them** (cross-fade instead of zoom). |

### Media

| Feature | You may claim it when… |
|---|---|
| **Captions** | Users can enable captions for ALL video/audio-only content — speech, nonverbal communication, music, sound effects. **No media content → do NOT claim** (not applicable ≠ supported). |
| **Audio Descriptions** | Users can find and enable spoken descriptions of visual content (the "AD" pattern). Same N/A rule. |

## The Worked Example (WWDC25 224 — Landmarks)

Claimed: Sufficient Contrast, Dark Interface, Differentiate Without Color Alone, Reduced Motion, Voice Control, VoiceOver. **Not claimed**: Larger Text — live testing at 235% and 310% found a misaligned label, truncated description, and a text field that didn't grow; the team **fixed first, deferred the claim**. Not claimed: Captions + Audio Descriptions (no media content). That's the model behavior.

## Build-Side Quick Fixes (Tech Talk 111433)

```swift
// Voice Control synonyms
Button { addFavorite() } label: { Image(systemName: "heart") }
    .accessibilityLabel("Favorite")
    .accessibilityInputLabels(["Favorite", "Heart", "Like", "Love"])

// Custom control → borrow a system control's accessibility wholesale
.accessibilityRepresentation {
    Slider(value: $badgeProgress.rating, in: 0...5, step: 1.0) { Text("Rating") }
}

// Gesture-only interactions must be re-exposed
.onTapGesture(count: 2) { modelData.addFavorite(landmark) }
.accessibilityAction(named: "Favorite") { modelData.addFavorite(landmark) }

// Larger Text anti-truncation: scroll the content, pin the actions
ScrollView { content }
    .scrollBounceBehavior(.basedOnSize)
    .safeAreaBar(edge: .bottom) { actionButtons }   // iOS 26

// Never cap lines
Text(longText).lineLimit(nil)     // SwiftUI
label.numberOfLines = 0           // UIKit

// Respond to the visual settings
@Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
@Environment(\.colorSchemeContrast) var colorSchemeContrast
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
```

## Process Principles

- "**Nothing about us without us**" — the most effective validation is testing with people who use these features daily (WWDC25 224).
- Test yourself first: enable each feature and run every common task before claiming.
- Re-evaluate on every release that touches the common-task screens — a truncation regression silently invalidates a published claim.
- No enforcement deadline is stated in either session; accuracy is the standing requirement.

## Checklist

- [ ] Common-task list written down (incl. first launch, login, purchase, settings)
- [ ] Each candidate feature tested per task, per device family
- [ ] Larger Text verified at 200% AND the largest accessibility size (310%)
- [ ] Dark Interface verified with Smart Invert (media not inverted)
- [ ] Media features left unclaimed when not applicable
- [ ] Findings fixed BEFORE declaring (fix first, claim after)
- [ ] Declaration completed in App Store Connect; accessibility webpage linked if available
- [ ] Re-evaluation added to the release checklist

## References

- [WWDC25 — Evaluate your app for Accessibility Nutrition Labels](https://developer.apple.com/videos/play/wwdc2025/224/)
- [Tech Talk — Prepare your app for Accessibility Nutrition Labels](https://developer.apple.com/videos/play/tech-talks/111433/)
- [Overview of Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
