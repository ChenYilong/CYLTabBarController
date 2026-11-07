---
name: sf-symbols
description: SF Symbols end-to-end — choosing and configuring the 7,000+ system symbols (rendering modes, variable color/draw, gradients), authoring custom symbols that interpolate across weights, and the animation preset vocabulary. Use when picking iconography, building custom symbols, animating symbol state changes, or rendering values as symbols.
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# SF Symbols

Over 7,000 system symbols with free platform consistency, Dynamic Type alignment, and
accessibility — the default answer to "we need an icon." This skill covers using them well,
authoring custom ones that behave like system ones, and the animation vocabulary.
(Animation *implementation patterns* live in `design/animation-patterns` → symbol-effects.md;
this skill owns selection, authoring, and rendering.)

## When This Skill Activates

- Choosing icons for tabs, toolbars, buttons, widgets ("should this be an SF Symbol?" — usually yes)
- A needed glyph doesn't exist → authoring a custom symbol
- Rendering a changing value (signal, progress, volume) as a symbol
- Symbol state changes that should animate (mute/unmute, play/pause)

## Using system symbols

- Prefer symbols over custom art for tab/toolbar icons — recognizability across the platform
  for free, and they scale with text styles (`imageScale`, weights match adjacent text).
- Keep platform-conventional symbols conventional: share, trash, search mean one thing each.
- **Rendering modes**: Monochrome · Hierarchical (one color, opacity-derived depth) ·
  Palette (2–3 explicit colors) · Multicolor (intrinsic colors). Pick per context — hierarchical
  shines in toolbars; multicolor in content.
- **Gradients** (SF Symbols 7-era): a smooth linear gradient generated from one source color,
  available in all rendering modes — use where depth helps, keep flat in dense UI.
- **Variable value**: pass `variableValue` (0–1) to render magnitude — signal bars, progress.
  Thresholds distribute evenly; 0% is the only "empty" state (a symbol reads "full" before 100%).
  **Variable Draw** (SF Symbols 7) renders the path at a percentage instead of activating
  layers — an alternative for progress/temperature; a symbol can carry both but renders one.

## Animation vocabulary

Presets: **Bounce · Pulse · Variable Color · Scale · Appear · Disappear · Replace · Draw On/Off**
(SF Symbols 7). Behavior classes: discrete (one-off), indefinite (until removed — always pair
with removal logic), transition, content transition.

- Swap symbol states with `.contentTransition(.symbolEffect(.replace))` — and prefer **Magic
  Replace** (preserves matching enclosures, uses Draw Off/On where supported) for state pairs
  like mute/unmute.
- Draw On/Off playback: By Layer (default) · Whole Symbol · Individually. Symbols define their
  own drawing direction (wind draws left→right; symmetric symbols from center).
- Effects propagate down the view hierarchy — `.symbolEffectsRemoved()` blocks them on subviews.
- Full API patterns (SwiftUI `symbolEffect`, UIKit `addSymbolEffect`) in
  `design/animation-patterns/symbol-effects.md`.

## Authoring custom symbols

The workflow that makes a custom glyph behave like a system one:

1. **Start from the closest system symbol** (prefer an unfilled base) — SF Symbols app →
   Export Template. Never draw from a blank canvas.
2. **Draw three sources**: Ultralight-Small, Regular-Small, Black-Small — the system
   interpolates all **27 variants** (9 weights × 3 scales) from them. Get Regular-Small right
   first, then copy its paths and only *move* points — all sources must keep the **same number
   and order of paths and points** (move, never add/remove).
3. **Outline everything**: convert live strokes to outlined paths once the design settles; no
   open paths (can't fill), no gradients or drop shadows baked in (they break multicolor/
   hierarchical rendering) — flat fills only.
4. **Annotate with unified annotation**: layers in explicit z-order; system colors for
   multicolor (they adapt to dark mode/contrast); primary→tertiary groups drive hierarchical
   and palette modes; `Erase` punches shapes out of layers behind; `Hidden` excludes a layer
   from a mode. For **variable color**, z-order = activation order (first-to-fill at bottom).
5. **Draw guide points** (SF Symbols 7 templates) for Draw On/Off: every path needs a start
   (open circle) and end (closed circle); corners marked with diamonds; annotate the Regular
   weight first (the only weight where guide points can be added/removed) and keep guide-point
   order identical across weights.
6. **Export the current template version** for Xcode. Legacy note: 2.0 templates are
   monochrome-only (needed only for very old deployment targets); 3.0+ carries all rendering
   modes; 4.0+ carries variable color.

❌ Common failures: baking effects into art (breaks rendering modes) · mismatched path counts
across sources (kills interpolation) · re-ordering paths after annotation (forces re-annotation)
· shipping a filled base variant as the only variant.

## Output Format

For icon reviews: `Location | Current | Symbol exists? (name) | Mode/config | Action`.
For custom-symbol requests: the 6-step authoring checklist above with per-step status.

## References

- https://developer.apple.com/sf-symbols/ (the SF Symbols app)
- https://developer.apple.com/videos/play/wwdc2025/337/ (What's new in SF Symbols 7)
- https://developer.apple.com/videos/play/wwdc2021/10250/ (Create custom symbols)
- https://developer.apple.com/videos/play/wwdc2023/10258/ (Animate symbols)
- https://developer.apple.com/videos/play/wwdc2022/10158/ (Variable Color)
- https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- Related skills: `design/animation-patterns` (symbol-effects implementation), `design/typography` (SF font pairing), `generators/app-icon-generator` (app icons are NOT symbols)
