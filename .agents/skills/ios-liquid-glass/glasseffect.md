---
title: glassEffect(_:in:)
description: Applies the Liquid Glass effect to a view.
source: https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/swiftui/view/glasseffect(_:in:).json
timestamp: 2026-06-26T06:39:36.371Z
---

**Navigation:** [SwiftUI](/documentation/swiftui) › [View](/documentation/swiftui/view)

**Instance Method**

# glassEffect(_:in:)

**Available on:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+

> Applies the Liquid Glass effect to a view.

```swift
nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View
```

## Discussion

When you use this effect, the system:

- Renders a shape anchored behind a view with the Liquid Glass material.
- Applies the foreground effects of Liquid Glass over a view.

For example, to add this effect to a [Text](/documentation/swiftui/text):

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()
```

SwiftUI uses the [regular](/documentation/swiftui/glass/regular) variant by default along with a [Capsule](/documentation/swiftui/capsule) shape.

SwiftUI anchors the Liquid Glass to a view’s bounds. For the example above, the material fills the entirety of the `Text` frame, which includes the padding.

You typically use this modifier with a [GlassEffectContainer](/documentation/swiftui/glasseffectcontainer) to combine multiple Liquid Glass shapes into a single shape that can morph into one another.

## Styling views with Liquid Glass

- [Applying Liquid Glass to custom views](/documentation/swiftui/applying-liquid-glass-to-custom-views) Configure, combine, and morph views using Liquid Glass effects.
- [Landmarks: Building an app with Liquid Glass](/documentation/swiftui/landmarks-building-an-app-with-liquid-glass) Enhance your app experience with system-provided and custom Liquid Glass.
- [glassEffectID(_:in:)](/documentation/swiftui/view/glasseffectid(_:in:)) Associates an identity value to Liquid Glass effects defined within this view.
- [glassEffectTransition(_:)](/documentation/swiftui/view/glasseffecttransition(_:)) Associates a glass effect transition with any glass effects defined within this view.
- [glassEffectUnion(id:namespace:)](/documentation/swiftui/view/glasseffectunion(id:namespace:)) Associates any Liquid Glass effects defined within this view to a union with the provided identifier.
- [interactive(_:)](/documentation/swiftui/glass/interactive(_:)) Returns a copy of the structure configured to be interactive.
- [GlassEffectContainer](/documentation/swiftui/glasseffectcontainer) A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another.
- [GlassEffectTransition](/documentation/swiftui/glasseffecttransition) A structure that describes changes to apply when a glass effect is added or removed from the view hierarchy.
- [GlassButtonStyle](/documentation/swiftui/glassbuttonstyle) A button style that applies glass border artwork based on the button’s context.
- [GlassProminentButtonStyle](/documentation/swiftui/glassprominentbuttonstyle) A button style that applies prominent glass border artwork based on the button’s context.
- [DefaultGlassEffectShape](/documentation/swiftui/defaultglasseffectshape) The default shape applied by glass effects, a capsule.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
