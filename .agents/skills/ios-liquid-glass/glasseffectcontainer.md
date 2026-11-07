---
title: GlassEffectContainer
description: A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another.
source: https://developer.apple.com/documentation/swiftui/glasseffectcontainer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/swiftui/glasseffectcontainer.json
timestamp: 2026-06-26T06:39:36.375Z
---

**Navigation:** [SwiftUI](/documentation/swiftui)

**Structure**

# GlassEffectContainer

**Available on:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+

> A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another.

```swift
@MainActor @preconcurrency struct GlassEffectContainer<Content> where Content : View
```

## Overview

Use a container with the [glassEffect(_:in:)](/documentation/swiftui/view/glasseffect(_:in:)) modifier. Each view with a Liquid Glass effect contributes a shape rendered with the effect to a set of shapes. SwiftUI renders the effects together, improving rendering performance and allowing the effects to interact with and morph into one another.

Configure how shapes interact with one another by customizing the default spacing value of the container. As shapes near one another, their paths start to blend into one another. The higher the spacing, the sooner blending begins as the shapes approach each other.

## Conforms To

- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [View](/documentation/swiftui/view)

## Initializers

- [init(spacing:content:)](/documentation/swiftui/glasseffectcontainer/init(spacing:content:)) Creates a glass effect container with the provided spacing, extracting glass shapes from the provided content.

## Styling views with Liquid Glass

- [Applying Liquid Glass to custom views](/documentation/swiftui/applying-liquid-glass-to-custom-views) Configure, combine, and morph views using Liquid Glass effects.
- [Landmarks: Building an app with Liquid Glass](/documentation/swiftui/landmarks-building-an-app-with-liquid-glass) Enhance your app experience with system-provided and custom Liquid Glass.
- [glassEffect(_:in:)](/documentation/swiftui/view/glasseffect(_:in:)) Applies the Liquid Glass effect to a view.
- [glassEffectID(_:in:)](/documentation/swiftui/view/glasseffectid(_:in:)) Associates an identity value to Liquid Glass effects defined within this view.
- [glassEffectTransition(_:)](/documentation/swiftui/view/glasseffecttransition(_:)) Associates a glass effect transition with any glass effects defined within this view.
- [glassEffectUnion(id:namespace:)](/documentation/swiftui/view/glasseffectunion(id:namespace:)) Associates any Liquid Glass effects defined within this view to a union with the provided identifier.
- [interactive(_:)](/documentation/swiftui/glass/interactive(_:)) Returns a copy of the structure configured to be interactive.
- [GlassEffectTransition](/documentation/swiftui/glasseffecttransition) A structure that describes changes to apply when a glass effect is added or removed from the view hierarchy.
- [GlassButtonStyle](/documentation/swiftui/glassbuttonstyle) A button style that applies glass border artwork based on the button’s context.
- [GlassProminentButtonStyle](/documentation/swiftui/glassprominentbuttonstyle) A button style that applies prominent glass border artwork based on the button’s context.
- [DefaultGlassEffectShape](/documentation/swiftui/defaultglasseffectshape) The default shape applied by glass effects, a capsule.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
