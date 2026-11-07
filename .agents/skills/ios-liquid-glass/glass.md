---
title: Glass
description: A structure that defines the configuration of the Liquid Glass material.
source: https://developer.apple.com/documentation/swiftui/glass
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/swiftui/glass.json
timestamp: 2026-04-14T13:14:25.016Z
---

**Navigation:** [SwiftUI](/documentation/swiftui)

**Structure**

# Glass

**Available on:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+

> A structure that defines the configuration of the Liquid Glass material.

```swift
struct Glass
```

## Overview

You provide instances of a variant of Liquid Glass to the [glassEffect(_:in:)](/documentation/swiftui/view/glasseffect(_:in:)) view modifier:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()
```

You can combine Liquid Glass effects using a [GlassEffectContainer](/documentation/swiftui/glasseffectcontainer), which supports morphing views with this effect into each other based on the geometry of their associated views.

## Conforms To

- [Equatable](/documentation/Swift/Equatable)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Instance Methods

- [interactive(_:)](/documentation/swiftui/glass/interactive(_:)) Returns a copy of the structure configured to be interactive.
- [tint(_:)](/documentation/swiftui/glass/tint(_:)) Returns a copy of the structure with a configured tint color.

## Type Properties

- [clear](/documentation/swiftui/glass/clear) The clear variant of glass.
- [identity](/documentation/swiftui/glass/identity) The identity variant of glass. When applied, your content remains unaffected as if no glass effect was applied.
- [regular](/documentation/swiftui/glass/regular) The regular variant of the Liquid Glass material.

## Styling content

- [border(_:width:)](/documentation/swiftui/view/border(_:width:)) Adds a border to this view with the specified style and width.
- [foregroundStyle(_:)](/documentation/swiftui/view/foregroundstyle(_:)) Sets a view’s foreground elements to use a given style.
- [foregroundStyle(_:_:)](/documentation/swiftui/view/foregroundstyle(_:_:)) Sets the primary and secondary levels of the foreground style in the child view.
- [foregroundStyle(_:_:_:)](/documentation/swiftui/view/foregroundstyle(_:_:_:)) Sets the primary, secondary, and tertiary levels of the foreground style.
- [backgroundStyle(_:)](/documentation/swiftui/view/backgroundstyle(_:)) Sets the specified style to render backgrounds within the view.
- [backgroundStyle](/documentation/swiftui/environmentvalues/backgroundstyle) An optional style that overrides the default system background style when set.
- [ShapeStyle](/documentation/swiftui/shapestyle) A color or pattern to use when rendering a shape.
- [AnyShapeStyle](/documentation/swiftui/anyshapestyle) A type-erased ShapeStyle value.
- [Gradient](/documentation/swiftui/gradient) A color gradient represented as an array of color stops, each having a parametric location value.
- [MeshGradient](/documentation/swiftui/meshgradient) A two-dimensional gradient defined by a 2D grid of positioned colors.
- [AnyGradient](/documentation/swiftui/anygradient) A color gradient.
- [ShadowStyle](/documentation/swiftui/shadowstyle) A style to use when rendering shadows.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
