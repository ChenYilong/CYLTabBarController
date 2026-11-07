# Visual Effects

Scroll-driven effects, geometry-driven effects, mesh gradients, text renderers, and shader effects. The through-line (WWDC24, WWDC26): complex-looking effects are pipelines of simple stages — a blur, a shader, a time source, a scroll phase — each tunable in isolation.

## Scroll Transitions (iOS 17+)

`.scrollTransition` applies effects as an element enters, occupies, and leaves the visible region — the standard tool for carousels, parallax, and caption fades:

```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 16) {
        ForEach(photos) { photo in
            PhotoCard(photo: photo)
                .scrollTransition(axis: .horizontal) { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.85)
                        .opacity(phase.isIdentity ? 1 : 0.6)
                        // phase.value: -1 (entering) ... 0 (visible) ... 1 (leaving)
                        .offset(x: phase.value * -40)   // parallax drift
                }
        }
    }
}
```

- `phase.isIdentity` — fully on-screen; use for binary effects like caption opacity.
- `phase.value` — continuous `-1...1`; multiply into offsets/rotations for parallax that tracks scroll position.
- Apply a second `.scrollTransition` to a caption overlay to fade text on a different curve than its image.

## visualEffect — Geometry Without GeometryReader (iOS 17+)

`.visualEffect` hands you a `GeometryProxy` without inserting a `GeometryReader` into layout. Effects are visual-only (offset, scale, rotation, blur, hue — nothing that re-layouts), which is exactly why it stays fast inside scroll views:

```swift
Text(word)
    .visualEffect { content, proxy in
        content
            .hueRotation(.degrees(proxy.frame(in: .global).origin.y / 8))
    }
```

Use it when an effect depends on *where the view is* (screen position, distance from center) rather than on state.

## MeshGradient (iOS 18+)

A grid of control points, each with a color — SwiftUI interpolates between them. Animate by **moving control points**, not by swapping colors:

```swift
MeshGradient(
    width: 3, height: 3,
    points: [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], center, [1, 0.5],   // animate `center` for a lava-lamp drift
        [0, 1], [0.5, 1], [1, 1]
    ],
    colors: [
        .indigo, .purple, .pink,
        .blue, .purple, .orange,
        .teal, .blue, .indigo
    ]
)
```

Drive `center` from `TimelineView(.animation)` (e.g. `[0.5 + 0.3 * sin(t), 0.5 + 0.3 * cos(t)]`) for ambient motion, or animate it with a spring on state changes. Interior points can roam; keep the outer ring pinned at 0/1 so the gradient keeps covering its frame.

## TextRenderer — Per-Line and Per-Glyph Text (iOS 18+)

`TextRenderer` intercepts text drawing: `draw(layout:in:)` receives a `Text.Layout`, which decomposes as **Lines → Runs → Slices** (a slice ≈ a glyph cluster). Draw each element through a modified `GraphicsContext` copy:

```swift
struct AppearRenderer: TextRenderer, Animatable {
    var elapsedTime: TimeInterval

    // Forward time through Animatable so SwiftUI interpolates it
    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                if run[EmphasisAttribute.self] != nil {
                    for (index, slice) in run.enumerated() {
                        let progress = min(1, max(0, elapsedTime - Double(index) * 0.05) / 0.3)
                        var copy = context
                        copy.opacity = progress
                        copy.translateBy(x: 0, y: (1 - progress) * 8)
                        copy.draw(slice, options: .disablesSubpixelQuantization)
                    }
                } else {
                    context.draw(run)
                }
            }
        }
    }
}
```

- **Animate only marked words**: define an empty `struct EmphasisAttribute: TextAttribute {}`, tag spans with `Text("moonlight").customAttribute(EmphasisAttribute())`, and check `run[EmphasisAttribute.self]` in the renderer — the rest of the text draws untouched.
- **Conform to `Animatable`**, forwarding `elapsedTime` — then drive it from a keyframe or spring animation on the view that applies `.textRenderer(...)`.
- **Disable subpixel quantization** (`options: .disablesSubpixelQuantization`) on slices moved by springs — otherwise glyphs snap to pixel boundaries and jitter as the spring settles (WWDC24).

## Shader Effects (iOS 17+)

Call a Metal function via `ShaderLibrary` and attach it with one of three modifiers:

| Modifier | Shader signature (per pixel) | Use |
|----------|------------------------------|-----|
| `.colorEffect` | position + color + args → color | Tints, palettes, dissolves |
| `.distortionEffect` | position + args → new position | Ripples, waves, jelly |
| `.layerEffect` | position + layer + args → color | Anything — it can *sample* the layer; superset of the other two |

```swift
Image("cover")
    .layerEffect(
        ShaderLibrary.ripple(.float2(origin), .float(elapsedTime)),
        maxSampleOffset: CGSize(width: 24, height: 24)
    )
```

Rules that keep shaders correct:

- **Shaders are stateless, per-pixel functions.** There is no memory between frames — pass time explicitly, driven by `TimelineView(.animation)` or an `elapsedTime` fed from a keyframe animator, and derive everything from the arguments.
- **Stay within `maxSampleOffset`.** Sampling farther than declared gets clipped or clamped at the layer edge — declare the true maximum displacement.
- **Organic motion = noise + domain warping.** Sample a noise texture (pass one with `.image(...)`), then offset the lookup coordinates by *another* noise sample — warped noise reads as smoke/water/aurora rather than an obvious sine wave (WWDC26).
- **Build a debug scrub UI.** Sliders for shader parameters and a scrubber for time turn tuning from recompile-and-squint into direct manipulation — the workflow Apple's own demos use.

## Composing Effect Pipelines (WWDC26)

Advanced effects are stages, not monoliths. A hero treatment might be: `blur` (soften) → `layerEffect` shader (distort) → time from `TimelineView` (motion) → `scrollTransition` phase scaling the shader's amplitude (scroll-coupled). Each stage stays independently testable, and one shader can serve several effects just by changing which stage feeds its parameters.

## Semantic Alignment over Manual Offsets

For badge/annotation positioning that must survive Dynamic Type and content changes, override alignment guides in terms of the view's own `ViewDimensions` instead of eyeballed offsets:

```swift
// ❌ Magic numbers — break the moment type size or content changes
Avatar()
    .overlay(alignment: .topTrailing) {
        Badge().offset(x: 9, y: -9)
    }

// ✅ Semantic: expressed relative to the badge's own geometry
Avatar()
    .overlay(alignment: .topTrailing) {
        Badge()
            .alignmentGuide(.trailing) { d in d[.trailing] - d.width / 3 }
            .alignmentGuide(.top) { d in d[.top] + d.height / 3 }
    }
```

The badge now overhangs the corner by a third of *its own* size at every Dynamic Type setting.
