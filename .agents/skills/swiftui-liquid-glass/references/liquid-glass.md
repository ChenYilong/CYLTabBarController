# Liquid Glass API Reference for SwiftUI

## Contents

- [Overview](#overview)
- [glassEffect(_:in:)](#glasseffect_in)
- [Glass](#glass)
- [GlassEffectContainer](#glasseffectcontainer)
- [glassEffectID(_:in:)](#glasseffectid_in)
- [glassEffectUnion(id:namespace:)](#glasseffectunionidnamespace)
- [glassEffectTransition(_:)](#glasseffecttransition_)
- [GlassEffectTransition](#glasseffecttransition)
- [Button Styles](#button-styles)
- [DefaultGlassEffectShape](#defaultglasseffectshape)
- [Scroll Edge Effect](#scroll-edge-effect)
- [Background Extension (Split Views)](#background-extension-split-views)
- [Toolbar Spacing](#toolbar-spacing)
- [Availability Gating](#availability-gating)
- [Performance Guidelines](#performance-guidelines)
- [Accessibility Considerations](#accessibility-considerations)
- [Best Practices Summary](#best-practices-summary)
- [Apple Documentation Links](#apple-documentation-links)

## Overview

Liquid Glass is a dynamic translucent material available on iOS 26.0+, iPadOS 26.0+,
macOS 26.0+, Mac Catalyst 26.0+, tvOS 26.0+, and watchOS 26.0+. It blurs content
behind it, reflects color and light from surrounding content, and reacts to touch and
pointer interactions in real time. Standard SwiftUI components (tab bars, toolbars,
navigation bars, sheets, popovers) adopt Liquid Glass automatically when built with
the latest SDK.

This reference covers the complete API surface for applying Liquid Glass to custom views.

## glassEffect(_:in:)

Applies the Liquid Glass effect behind a view.

```swift
nonisolated func glassEffect(
    _ glass: Glass = .regular,
    in shape: some Shape = DefaultGlassEffectShape()
) -> some View
```

The system renders a shape anchored behind the view with the Liquid Glass material and
applies foreground effects over the view content. The default shape is `Capsule`.

Apply this modifier **after** other modifiers that affect the view's appearance (padding,
frame, font, foregroundStyle).

### Basic usage

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()
```

### Custom shape

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(in: .rect(cornerRadius: 16.0))
```

Common shapes: `.capsule` (default), `.rect(cornerRadius:)`, `.circle`.

### Tinted and interactive

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.tint(.orange).interactive())
```

Use `.interactive()` only when the custom component is actually tappable,
focusable, or otherwise interactive. For buttons, prefer the built-in glass button
styles in the Button Styles section.

## Glass

A structure that defines the configuration of the Liquid Glass material. Conforms to
`Equatable`, `Sendable`, and `SendableMetatype`.

### Type Properties

| Property | Description |
|---|---|
| `.regular` | Standard Liquid Glass material |
| `.clear` | Clear variant with high translucency; add dimming or other contrast treatment when legibility needs it |
| `.identity` | No-op; content appears as if no glass effect was applied |

### Instance Methods

| Method | Description |
|---|---|
| `.tint(_ color: Color)` | Returns a copy with a color tint to suggest prominence |
| `.interactive(_ isInteractive: Bool = true)` | Returns a copy that reacts to touch and pointer interactions |

Methods are chainable:

```swift
.glassEffect(.regular.tint(.blue).interactive())
```

When using `.clear`, verify foreground legibility over the actual background. Add a
dimming layer or another contrast treatment when bright or visually busy content sits
behind the glass.

```swift
ZStack {
    Capsule()
        .fill(.black.opacity(0.28))

    Label("Play", systemImage: "play.fill")
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.clear)
}
.fixedSize()
```

## GlassEffectContainer

A view that combines multiple Liquid Glass shapes into a single rendering pass. Enables
blending and morphing between individual shapes.

```swift
@MainActor @preconcurrency
struct GlassEffectContainer<Content> where Content : View
```

Conforms to `View`, `Sendable`, `SendableMetatype`.

### Initializer

```swift
init(spacing: CGFloat? = nil, @ContentBuilder content: () -> Content)
```

The `spacing` parameter controls how glass shapes interact:

- **Larger spacing**: Shapes begin blending at greater distances; morphing starts sooner.
- **Smaller spacing**: Shapes must be closer before blending occurs.

Match the container spacing to the interior layout spacing so shapes remain separate at
rest but merge during animated transitions.

### Example

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()

        Image(systemName: "eraser.fill")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()
    }
}
```

## glassEffectID(_:in:)

Associates a stable identity with a Liquid Glass effect for morphing during view
hierarchy transitions.

```swift
nonisolated func glassEffectID(
    _ id: (some Hashable & Sendable)?,
    in namespace: Namespace.ID
) -> some View
```

Use with `@Namespace`, `GlassEffectContainer`, and `withAnimation` to animate shapes
morphing into each other when views appear or disappear.

### Morphing example

```swift
@State private var isExpanded = false
@Namespace private var namespace

var body: some View {
    GlassEffectContainer(spacing: 40.0) {
        HStack(spacing: 40.0) {
            Image(systemName: "scribble.variable")
                .frame(width: 80.0, height: 80.0)
                .font(.system(size: 36))
                .glassEffect()
                .glassEffectID("pencil", in: namespace)

            if isExpanded {
                Image(systemName: "eraser.fill")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect()
                    .glassEffectID("eraser", in: namespace)
                    .glassEffectTransition(.matchedGeometry)
            }
        }
    }

    Button("Toggle") {
        withAnimation {
            isExpanded.toggle()
        }
    }
    .buttonStyle(.glass)
}
```

## glassEffectUnion(id:namespace:)

Merges multiple views into a single Liquid Glass shape. All effects with the same shape,
Glass variant, and union ID combine into one rendered shape.

```swift
@MainActor @preconcurrency func glassEffectUnion(
    id: (some Hashable & Sendable)?,
    namespace: Namespace.ID
) -> some View
```

Useful for dynamically created views or views outside a shared layout container.

### Example

```swift
@Namespace private var namespace
let symbols = ["cloud.bolt.rain.fill", "sun.rain.fill", "moon.stars.fill", "moon.fill"]

GlassEffectContainer(spacing: 20.0) {
    HStack(spacing: 20.0) {
        ForEach(symbols.indices, id: \.self) { i in
            Image(systemName: symbols[i])
                .frame(width: 80.0, height: 80.0)
                .font(.system(size: 36))
                .glassEffect()
                .glassEffectUnion(id: i < 2 ? "weather" : "night", namespace: namespace)
        }
    }
}
```

## glassEffectTransition(_:)

Controls how a glass effect appears or disappears during view hierarchy changes.

```swift
@MainActor @preconcurrency func glassEffectTransition(
    _ transition: GlassEffectTransition
) -> some View
```

Attach this modifier to the view whose glass effect is inserted or removed. Keep
`GlassEffectContainer` around the related group to define the blending/morphing
scope, but do not put the transition only on the always-present container.

## GlassEffectTransition

A structure describing changes when a glass effect is added to or removed from the
view hierarchy. Conforms to `Sendable` and `SendableMetatype`.

### Type Properties

| Transition | Behavior |
|---|---|
| `.matchedGeometry` | Morphs the shape to/from nearby glass effects. Default when within container spacing. |
| `.materialize` | Fades content and animates the glass material in/out without geometry matching. Use for distant effects. |
| `.identity` | No transition animation. |

### Example with explicit transition

```swift
if isExpanded {
    Image(systemName: "note")
        .frame(width: 20, height: 20)
        .glassEffect()
        .glassEffectID("note", in: namespace)
        .glassEffectTransition(.materialize)
}
```

## Button Styles

SwiftUI provides built-in Liquid Glass button styles plus a configurable style that
accepts a `Glass` value.

### GlassButtonStyle

Standard glass appearance for buttons.

```swift
Button("Action") { }
    .buttonStyle(.glass)
```

### GlassProminentButtonStyle

A more prominent glass appearance for primary actions.

```swift
Button("Confirm") { }
    .buttonStyle(.glassProminent)
```

### Configurable Glass Button Style

Use `.glass(_:)` when a button needs a specific `Glass` variant or tint:

```swift
Button("Media") { }
    .buttonStyle(.glass(.clear))
```

When the button sits over a bright or visually busy background, include a contrast
treatment underneath the clear glass or choose a more opaque style:

```swift
ZStack {
    Capsule()
        .fill(.black.opacity(0.28))

    Button {
        playRecap()
    } label: {
        Label("Play", systemImage: "play.fill")
            .font(.headline)
            .padding(.horizontal, 8)
    }
    .buttonStyle(.glass(.clear))
}
.fixedSize()
```

Use `.glass(.regular.tint(color))` for tinted tool controls. Reserve
`.glassProminent` for high-emphasis primary actions rather than using it as the
default answer whenever a button needs visual weight.

These button styles automatically include interactivity (touch/pointer reactions).
Prefer these over manually applying `.glassEffect(.regular.interactive())` to buttons.

## DefaultGlassEffectShape

The default shape used by `glassEffect(_:in:)` when no shape is specified. Resolves
to `Capsule`.

## Scroll Edge Effect

Configures the scroll edge effect style for scroll views within a view hierarchy.

```swift
nonisolated func scrollEdgeEffectStyle(
    _ style: ScrollEdgeEffectStyle?,
    for edges: Edge.Set
) -> some View
```

Available styles include `.soft` (soft edge) and `.hard`. System bars adopt this
automatically. Apply to custom bars that float over scrollable content.

```swift
.scrollEdgeEffectStyle(.soft, for: .top)
```

## Background Extension (Split Views)

Extend content visually under sidebars and inspectors by duplicating the view into
mirrored copies with a blur effect applied on top:

```swift
NavigationSplitView {
    // sidebar content
} detail: {
    ZStack {
        BannerView()
            .backgroundExtensionEffect()
    }
}
```

Also available as `backgroundExtensionEffect(isEnabled:)` for conditional use.
Apply with discretion — typically to a single background view in the detail column.

## Toolbar Spacing

Use `ToolbarSpacer` on iOS 26+ to create a visual break between toolbar items:

```swift
.toolbar {
    ToolbarItem { Button("Edit") { } }
    ToolbarSpacer(.fixed)
    ToolbarItem { Button("Share") { } }
}
```

## Availability Gating

All Liquid Glass APIs require iOS 26.0+. Always provide a fallback:

```swift
if #available(iOS 26, *) {
    content
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
} else {
    content
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
}
```

## Performance Guidelines

- Use `GlassEffectContainer` to batch multiple glass effects into a single render pass.
- Limit the total number of glass effects visible on screen at once.
- Avoid creating many separate `GlassEffectContainer` instances when one can suffice.
- Profile with Instruments to check rendering performance.

## Accessibility Considerations

- Test with **Reduce Transparency** enabled (glass effects adapt automatically for
  standard components; verify custom implementations).
- Test with **Reduce Motion** enabled (morphing and fluid animations are simplified).
- Ensure sufficient contrast for text and icons rendered over glass; clear glass may
  need a dimming layer or another contrast treatment.
- Standard components from SwiftUI adapt to these settings automatically.

## Best Practices Summary

1. Use `GlassEffectContainer` when multiple glass views coexist.
2. Apply `.glassEffect()` after layout and appearance modifiers.
3. Match container `spacing` to interior layout spacing.
4. Use `.interactive()` only on tappable/focusable elements.
5. Use `withAnimation` when toggling views with `glassEffectID` for morphing.
6. Prefer `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`, or configurable styles such as `.buttonStyle(.glass(.clear))` for buttons.
7. Avoid overusing Liquid Glass -- reserve it for key functional elements.
8. Always gate with `if #available(iOS 26, *)` and provide fallback UI.
9. Test with Reduce Transparency and Reduce Motion accessibility settings.
10. Apply `glassEffectTransition(_:)` to the conditional glass view that appears or disappears.

## Apple Documentation Links

- [Applying Liquid Glass to custom views](https://sosumi.ai/documentation/swiftui/Applying-Liquid-Glass-to-custom-views)
- [Adopting Liquid Glass](https://sosumi.ai/documentation/technologyoverviews/adopting-liquid-glass)
- [Landmarks: Building an app with Liquid Glass](https://sosumi.ai/documentation/swiftui/Landmarks-Building-an-app-with-Liquid-Glass)
- [View.glassEffect(_:in:)](https://sosumi.ai/documentation/swiftui/View/glassEffect(_:in:))
- [Glass](https://sosumi.ai/documentation/swiftui/Glass)
- [GlassEffectContainer](https://sosumi.ai/documentation/swiftui/GlassEffectContainer)
- [GlassEffectTransition](https://sosumi.ai/documentation/swiftui/GlassEffectTransition)
- [GlassButtonStyle](https://sosumi.ai/documentation/swiftui/GlassButtonStyle)
- [GlassProminentButtonStyle](https://sosumi.ai/documentation/swiftui/GlassProminentButtonStyle)
