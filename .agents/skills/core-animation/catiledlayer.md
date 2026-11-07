---
title: CATiledLayer
description: A layer that provides a way to asynchronously provide tiles of the layer’s content, potentially cached at multiple levels of detail.
source: https://developer.apple.com/documentation/quartzcore/catiledlayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/catiledlayer.json
timestamp: 2026-05-13T20:41:35.675Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CATiledLayer

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> A layer that provides a way to asynchronously provide tiles of the layer’s content, potentially cached at multiple levels of detail.

```swift
class CATiledLayer
```

## Overview

As more data is required by the renderer, the layer’s [draw(in:)](/documentation/quartzcore/calayer/draw(in:)) method is called on one or more background threads to supply the drawing operations to fill in one tile of data. The clip bounds and current transformation matrix (CTM) of the drawing context can be used to determine the bounds and resolution of the tile being requested.

Regions of the layer may be invalidated using the [setNeedsDisplay(_:)](/documentation/quartzcore/calayer/setneedsdisplay(_:)) method however the update will be asynchronous. While the next display update will most likely not contain the updated content, a future update will.

> **Important:** Do not attempt to directly modify the [contents](/documentation/quartzcore/calayer/contents) property of a [CATiledLayer](/documentation/quartzcore/catiledlayer) object. Doing so disables the ability of a tiled layer to asynchronously provide tiled content, effectively turning the layer into a regular [CALayer](/documentation/quartzcore/calayer) object.

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

## Visual Fade

- [fadeDuration()](/documentation/quartzcore/catiledlayer/fadeduration()) The time, in seconds, that newly added images take to “fade-in” to the rendered representation of the tiled layer.

## Levels of detail

- [levelsOfDetail](/documentation/quartzcore/catiledlayer/levelsofdetail) The number of levels of detail maintained by this layer.
- [levelsOfDetailBias](/documentation/quartzcore/catiledlayer/levelsofdetailbias) The number of magnified levels of detail for this layer.

## Layer tile size

- [tileSize](/documentation/quartzcore/catiledlayer/tilesize) The maximum size of each tile used to create the layer’s content.

## Advanced Layer Options

- [CAScrollLayer](/documentation/quartzcore/cascrolllayer) A layer that displays scrollable content larger than its own bounds.
- [CATransformLayer](/documentation/quartzcore/catransformlayer) Objects used to create true 3D layer hierarchies, rather than the flattened hierarchy rendering model used by other layer types.
- [CAReplicatorLayer](/documentation/quartzcore/careplicatorlayer) A layer that creates a specified number of sublayer copies with varying geometric, temporal, and color transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
