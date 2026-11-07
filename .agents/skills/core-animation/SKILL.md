---
name: core-animation
user-invocable: true
description: "API reference: Core Animation (QuartzCore). Query for CALayer, CAAnimation, CABasicAnimation, CAKeyframeAnimation, CASpringAnimation, CATransaction, CAShapeLayer, CAGradientLayer, CAEmitterLayer, CATransform3D, CADisplayLink."
context: fork
agent: Explore
---

# Core Animation Reference

Search these docs to answer questions about Core Animation (the QuartzCore framework). Use this skill when working directly with `CALayer`, layer-backed UIKit/AppKit views, explicit keyframe or spring animations on layer properties, particle systems, or per-frame callbacks via `CADisplayLink`.

For SwiftUI's declarative animation API (`withAnimation`, `Animation`, `.animation(_:value:)`, transitions), use Apple's `swiftui-specialist` skill (its animations reference) instead. For SwiftUI immediate-mode drawing, use `swiftui/canvas.md` and `swiftui/graphicscontext.md`.

## Return Format

Always include:
1. **Summary** — answer the question concisely.
2. **File paths** — list relevant files for full details, e.g.:
   - `calayer.md` for layer geometry, contents, hierarchy
   - `cabasicanimation.md` for animating a single property between two values
   - `catransaction.md` for batching, disabling implicit animations, or changing default duration

## Files

| File | Content |
|------|---------|
| `core-animation-index.md` | Full QuartzCore framework index — layer basics, animation classes, transactions, layer subclasses |
| `calayer.md` | `CALayer` — the root layer class: geometry, contents, hierarchy, layout, animations |
| `caanimation.md` | `CAAnimation` — abstract base class for all Core Animation animation types |
| `capropertyanimation.md` | `CAPropertyAnimation` — abstract subclass animating a single layer property |
| `cabasicanimation.md` | `CABasicAnimation` — interpolate a layer property between two values |
| `cakeyframeanimation.md` | `CAKeyframeAnimation` — animate a property through a sequence of keyframes |
| `caspringanimation.md` | `CASpringAnimation` — spring-based interpolation with mass, stiffness, damping |
| `caanimationgroup.md` | `CAAnimationGroup` — run multiple animations together with a shared duration |
| `catransition.md` | `CATransition` — fade, push, reveal, and move-in transitions between layer states |
| `camediatiming.md` | `CAMediaTiming` — protocol shared by layers and animations (beginTime, duration, repeat, speed) |
| `catransaction.md` | `CATransaction` — batch property changes, disable implicit animations, set default duration/timing |
| `catransform3d.md` | `CATransform3D` — 4×4 matrix used by `CALayer.transform` for 3D transforms |
| `cashapelayer.md` | `CAShapeLayer` — vector-shape layer driven by a `CGPath` (stroke, fill, line dash) |
| `cagradientlayer.md` | `CAGradientLayer` — axial, radial, and conic gradient layers |
| `caemitterlayer.md` | `CAEmitterLayer` — particle emitter layer (fire, smoke, confetti, sparkles) |
| `caemittercell.md` | `CAEmitterCell` — individual particle definition used by `CAEmitterLayer` |
| `careplicatorlayer.md` | `CAReplicatorLayer` — replicate a sublayer with offsets and transforms |
| `cametallayer.md` | `CAMetalLayer` — layer backed by a Metal drawable for GPU-rendered content |
| `catextlayer.md` | `CATextLayer` — layer that renders plain or attributed text |
| `catiledlayer.md` | `CATiledLayer` — tile-based asynchronous content rendering for large or zoomable layers |
| `cadisplaylink.md` | `CADisplayLink` — timer synchronized to the display's refresh rate |

## When to Reach for Core Animation

- You need to animate a layer property SwiftUI/UIKit doesn't expose declaratively (e.g., `CAGradientLayer.colors`, `CAShapeLayer.strokeEnd`, `CAEmitterLayer.birthRate`).
- You need explicit keyframe or spring control with timing functions (`CAMediaTimingFunction`) per segment.
- You want to batch implicit animations off (`CATransaction.setDisableActions(true)`).
- You need a `CADisplayLink` per-frame callback (custom drawing loops, scrubbing, physics).
- You're rendering thousands of particles with `CAEmitterLayer` or replicating sublayers with `CAReplicatorLayer`.

If your problem fits inside `withAnimation { ... }` in SwiftUI or `UIView.animate { ... }` in UIKit, prefer those — Core Animation sits underneath both and is rarely the right starting point in 2026-era code.

## Fetching More Docs

1. Search this skill's local `.md` files first.
2. If the topic is not here, check the other installed Apple skills, then grep their local files.
3. If no installed skill has the page, the QuartzCore path on Apple's site is `/documentation/quartzcore/<symbol>` — fetch via the `sosumi.ai` Markdown mirror (e.g. `https://sosumi.ai/documentation/quartzcore/camediatimingfunction`) or by running `pnpm fetch-doc` against the apple-skills tooling.
