---
title: CATextLayer
description: A layer that provides simple text layout and rendering of plain or attributed strings.
source: https://developer.apple.com/documentation/quartzcore/catextlayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/catextlayer.json
timestamp: 2026-05-13T20:41:34.791Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CATextLayer

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> A layer that provides simple text layout and rendering of plain or attributed strings.

```swift
class CATextLayer
```

## Overview

The first line is aligned to the top of the layer.

> **Note:** `CATextLayer` disables sub-pixel antialiasing when rendering text. Text can only be drawn using sub-pixel antialiasing when it is composited into an existing opaque background at the same time that it’s rasterized. There is no way to draw text with sub-pixel antialiasing by itself, whether into an image or a layer, in advance of having the background pixels to weave the text pixels into. Setting the `opacity` property of the layer to [true](/documentation/Swift/true) does not change the rendering mode.

> **Note:** In macOS, when a `CATextLayer` instance is positioned using the [CAConstraintLayoutManager](/documentation/quartzcore/caconstraintlayoutmanager) class the bounds of the layer is resized to fit the text content.

## Inherits From

- [CALayer](/documentation/quartzcore/calayer)

## Conforms To

- [CAMediaTiming](/documentation/quartzcore/camediatiming)
- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Getting and Setting the Text

- [string](/documentation/quartzcore/catextlayer/string) The text to be rendered by the receiver.

## Text Visual Properties

- [font](/documentation/quartzcore/catextlayer/font) The font used to render the receiver’s text.
- [fontSize](/documentation/quartzcore/catextlayer/fontsize) The font size used to render the receiver’s text. Animatable.
- [foregroundColor](/documentation/quartzcore/catextlayer/foregroundcolor) The color used to render the receiver’s text. Animatable.
- [allowsFontSubpixelQuantization](/documentation/quartzcore/catextlayer/allowsfontsubpixelquantization) Determines whether to allow subpixel quantization for the graphics context used for text rendering.

## Text Alignment and Truncation

- [isWrapped](/documentation/quartzcore/catextlayer/iswrapped) Determines whether the text is wrapped to fit within the receiver’s bounds.
- [alignmentMode](/documentation/quartzcore/catextlayer/alignmentmode) Determines how individual lines of text are horizontally aligned within the receiver’s bounds.
- [truncationMode](/documentation/quartzcore/catextlayer/truncationmode) Determines how the text is truncated to fit within the receiver’s bounds.

## Constants

- [Truncation modes](/documentation/quartzcore/truncation-modes) These constants are used by the [truncationMode](/documentation/quartzcore/catextlayer/truncationmode) property.
- [Horizontal alignment modes](/documentation/quartzcore/horizontal-alignment-modes) These constants are used by the [alignmentMode](/documentation/quartzcore/catextlayer/alignmentmode) property.

## Text, Shapes, and Gradients

- [CAShapeLayer](/documentation/quartzcore/cashapelayer) A layer that draws a cubic Bezier spline in its coordinate space.
- [CAGradientLayer](/documentation/quartzcore/cagradientlayer) A layer that draws a color gradient over its background color, filling the shape of the layer.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
