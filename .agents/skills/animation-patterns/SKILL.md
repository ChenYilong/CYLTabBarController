---
name: animation-patterns
description: SwiftUI animation patterns including springs, transitions, PhaseAnimator, KeyframeAnimator, SF Symbol effects, scroll-driven effects, mesh gradients, text renderers, and shader effects. Use when implementing, reviewing, or fixing animation or visual-effect code on iOS/macOS.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Animation Patterns

Correct API shapes and patterns for SwiftUI animations. Prevents the most common mistakes: mixed spring parameter generations, wrong PhaseAnimator/KeyframeAnimator closure signatures, and using matchedGeometryEffect where matchedTransitionSource is needed.

## When This Skill Activates

Use this skill when the user:
- Asks to add, fix, or review **animation** code
- Mentions **spring**, **bounce**, or **snappy** animations
- Wants **view transitions** (insertion/removal, hero, zoom)
- Asks about **PhaseAnimator** or **KeyframeAnimator**
- Wants **SF Symbol effects** (bounce, pulse, wiggle, breathe)
- Mentions **matchedGeometryEffect** or **matchedTransitionSource**
- Asks about **reduce motion** / animation accessibility
- Wants to sequence or chain animations
- Mentions **withAnimation**, **animation completions**, or **Transaction**
- Wants **scroll-driven effects** (parallax, carousels, `scrollTransition`, `visualEffect`)
- Mentions **MeshGradient**, **TextRenderer**, or **Metal shader effects** (`colorEffect`, `distortionEffect`, `layerEffect`)

## Decision Tree

Choose the right reference file based on what the user needs:

```
What are you animating?
│
├─ A state change (opacity, position, color)
│  └─ → core-animations.md
│     ├─ withAnimation { } — explicit animation
│     ├─ .animation(_:value:) — implicit animation
│     └─ Spring configuration — .spring, .bouncy, .snappy, .smooth
│
├─ A multi-step / sequenced animation
│  └─ → phase-keyframe-animators.md (PhaseAnimator)
│     └─ Cycles through discrete phases automatically or on trigger
│
├─ A complex multi-property animation (scale + rotation + offset)
│  └─ → phase-keyframe-animators.md (KeyframeAnimator)
│     └─ Timeline-based keyframes with per-property tracks
│
├─ A view appearing / disappearing
│  └─ → transitions.md
│     ├─ .transition() — insertion/removal
│     ├─ .contentTransition() — text/symbol changes
│     └─ .asymmetric() — different in/out
│
├─ A hero / zoom navigation transition
│  └─ → transitions.md (matchedTransitionSource section)
│     ├─ iOS 18+: matchedTransitionSource + .navigationTransition(.zoom)
│     ├─ UIKit: preferredTransition = .zoom (capture stable IDs, never views)
│     └─ iOS 14+: matchedGeometryEffect (NOT for NavigationStack)
│
├─ A UIKit view driven by SwiftUI state or gestures
│  └─ → transitions.md (Bridging UIKit and SwiftUI Animations)
│     └─ UIView.animate(.spring(...)) / context.animate in updateUIView
│
├─ An SF Symbol animation
│  └─ → symbol-effects.md
│     └─ .symbolEffect(.bounce), .pulse, .wiggle, .breathe, .rotate
│
├─ A scroll-driven, geometry-driven, or shader effect
│  └─ → visual-effects.md
│     ├─ .scrollTransition — carousel scale/parallax/caption fades
│     ├─ .visualEffect — position-based effects without GeometryReader
│     ├─ MeshGradient — animatable multi-point gradients
│     ├─ TextRenderer — per-line / per-glyph text animation
│     └─ ShaderLibrary + .colorEffect / .distortionEffect / .layerEffect
│
└─ Spring physics / timing configuration
   └─ → core-animations.md (Spring Configurations section)
```

## API Availability

| API | Minimum Version | Reference |
|-----|----------------|-----------|
| `withAnimation` | iOS 13 | core-animations.md |
| `.animation(_:value:)` | iOS 13 | core-animations.md |
| `.spring(response:dampingFraction:)` | iOS 13 | core-animations.md |
| `.matchedGeometryEffect` | iOS 14 | transitions.md |
| `.transition(.push(from:))` | iOS 16 | transitions.md |
| `.contentTransition(.numericText())` | iOS 16 | transitions.md |
| `PhaseAnimator` | iOS 17 | phase-keyframe-animators.md |
| `KeyframeAnimator` | iOS 17 | phase-keyframe-animators.md |
| `.spring(duration:bounce:)` | iOS 17 | core-animations.md |
| Spring presets (`.bouncy`, `.snappy`, `.smooth`) | iOS 17 | core-animations.md |
| `withAnimation(_:completionCriteria:_:completion:)` | iOS 17 | core-animations.md |
| `.symbolEffect()` | iOS 17 | symbol-effects.md |
| `.transition(.blurReplace)` | iOS 17 | transitions.md |
| `.contentTransition(.symbolEffect(.replace))` | iOS 17 | transitions.md |
| `Transition` protocol / `TransitionPhase` | iOS 17 | transitions.md |
| `TransactionKey`, scoped `.animation` / `.transaction` variants | iOS 17 | core-animations.md |
| `KeyframeTimeline`, `.mapCameraKeyframeAnimator` | iOS 17 | phase-keyframe-animators.md |
| `.scrollTransition`, `.visualEffect` | iOS 17 | visual-effects.md |
| Shaders: `.colorEffect` / `.distortionEffect` / `.layerEffect` | iOS 17 | visual-effects.md |
| `MeshGradient` | iOS 18 | visual-effects.md |
| `TextRenderer` / `TextAttribute` | iOS 18 | visual-effects.md |
| `.matchedTransitionSource` | iOS 18 | transitions.md |
| `.navigationTransition(.zoom)` — push, sheet, fullScreenCover | iOS 18 | transitions.md |
| `UIViewController.preferredTransition = .zoom` | iOS 18 | transitions.md |
| `UIView.animate(_: Animation)` / `context.animate` | iOS 18 | transitions.md |

## Top 5 Mistakes — Quick Reference

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | `spring(response:bounce:)` — mixing parameter generations | Use either `spring(response:dampingFraction:)` (iOS 13) or `spring(duration:bounce:)` (iOS 17) | core-animations.md |
| 2 | `.animation(.spring())` without `value:` parameter | Always pass `value:` — the no-value variant is deprecated (iOS 15) | core-animations.md |
| 3 | Wrong PhaseAnimator closure signature | `PhaseAnimator(phases) { content, phase in }` — not `{ phase in }` | phase-keyframe-animators.md |
| 4 | Using `matchedGeometryEffect` for NavigationStack transitions | Use `matchedTransitionSource` + `.navigationTransition(.zoom)` on iOS 18+ | transitions.md |
| 5 | Using `withAnimation` for SF Symbol effects | Use `.symbolEffect()` modifier instead | symbol-effects.md |

## Review Checklist

When reviewing animation code, verify:

- [ ] **Reduce motion** — animations respect `AccessibilityMotionEffect` or `UIAccessibility.isReduceMotionEnabled`; provide non-motion alternatives
- [ ] **Duration limits** — no animation exceeds ~0.5s for UI feedback; longer only for decorative/ambient effects
- [ ] **Spring vs linear** — springs for interactive/physical motion; linear/easeInOut only for opacity fades or progress indicators
- [ ] **No deprecated APIs** — `.animation(.spring())` without `value:` is deprecated; `.animation(nil)` is replaced by `withTransaction`
- [ ] **Correct spring generation** — parameter names match the same API generation (never mix `response` with `bounce`)
- [ ] **Completion handlers** — using `withAnimation(_:completionCriteria:_:completion:)` (iOS 17+), not inventing `.onAnimationCompleted`
- [ ] **Transition scope** — `.transition()` only affects views inside `if`/`switch` controlled by state; not for views that are always present
- [ ] **Per-frame closures stay cheap** — KeyframeAnimator `content` closures, `visualEffect` closures, `TextRenderer.draw`, and `Animatable` view bodies run every frame; no allocation, formatting, or layout math inside

## Reference Files

| File | Content |
|------|---------|
| [core-animations.md](core-animations.md) | withAnimation, springs, completions, transactions + TransactionKey, timing curves, Animatable mechanics, fluid-interface principles (momentum projection, rubber-banding, hysteresis) |
| [phase-keyframe-animators.md](phase-keyframe-animators.md) | PhaseAnimator, KeyframeAnimator, KeyframeTimeline, MapKit camera keyframes, custom animations |
| [transitions.md](transitions.md) | View transitions, custom Transition protocol, matched geometry, navigation/zoom transitions (SwiftUI + UIKit), interruptibility, UIKit↔SwiftUI bridging, gesture-driven springs |
| [symbol-effects.md](symbol-effects.md) | SF Symbol effects, accessibility |
| [visual-effects.md](visual-effects.md) | scrollTransition, visualEffect, MeshGradient, TextRenderer, shader effects (colorEffect/distortionEffect/layerEffect), effect pipelines, semantic alignment guides |
