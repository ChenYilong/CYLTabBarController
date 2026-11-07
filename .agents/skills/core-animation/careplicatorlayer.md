---
title: CAReplicatorLayer
description: A layer that creates a specified number of sublayer copies with varying geometric, temporal, and color transformations.
source: https://developer.apple.com/documentation/quartzcore/careplicatorlayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/careplicatorlayer.json
timestamp: 2026-05-13T20:41:33.214Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAReplicatorLayer

**Available on:** iOS 3.0+, iPadOS 3.0+, Mac Catalyst 13.1+, macOS 10.6+, tvOS 9.0+, visionOS 1.0+

> A layer that creates a specified number of sublayer copies with varying geometric, temporal, and color transformations.

```swift
class CAReplicatorLayer
```

## Overview

You can use a [CAReplicatorLayer](/documentation/quartzcore/careplicatorlayer) object to build complex layouts based on a single source layer that is replicated with transformation rules that can affect the position, rotation color, and time.

The following shows a simple example: a red square is added to a replicator layer with an instance count of `5`. The position of each replicated instance is offset along the `x` axis so that it appears to the right of the previous instance. The blue and green color channels are offset so that their values reach `0` at the final instance.

```swift
let replicatorLayer = CAReplicatorLayer()
     
let redSquare = CALayer()
redSquare.backgroundColor = NSColor.white.cgColor
redSquare.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
     
let instanceCount = 5
     
replicatorLayer.instanceCount = instanceCount
replicatorLayer.instanceTransform = CATransform3DMakeTranslation(110, 0, 0)
     
let offsetStep = -1 / Float(instanceCount)
replicatorLayer.instanceBlueOffset = offsetStep
replicatorLayer.instanceGreenOffset = offsetStep
    
replicatorLayer.addSublayer(redSquare)
```

The result of the code above is a row of five squares, with colors graduating from white to red.

![Replicator layer example](https://docs-assets.developer.apple.com/published/5daf81d00b1e70e3aa842a38bd19a63a/media-2776906%402x.png)

Replicator layers can be nested. The following code adds `replicatorLayer` to a second replicator layer that offsets the position of each instance vertically and subtracts from the red channel.

```swift
let outerReplicatorLayer = CAReplicatorLayer()

outerReplicatorLayer.addSublayer(replicatorLayer)

outerReplicatorLayer.instanceCount = instanceCount
outerReplicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, 110, 0)
outerReplicatorLayer.instanceRedOffset = offsetStep
```

The result of adding this code is to create a grid with the value of the red channel being reduced in the vertical direction.

![Nested replicator layer example](https://docs-assets.developer.apple.com/published/7fc1110d14593942a632f25e1f3bdf2d/media-2776908%402x.png)

> **Note:** The [CAReplicatorLayer](/documentation/quartzcore/careplicatorlayer) implementation of [hitTest(_:)](/documentation/quartzcore/calayer/hittest(_:)) currently tests only the first instance of z replicator layer’s sublayers. This may change in the future.

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

## Setting Instance Display Properties

- [instanceCount](/documentation/quartzcore/careplicatorlayer/instancecount) The number of copies to create, including the source layers.
- [instanceDelay](/documentation/quartzcore/careplicatorlayer/instancedelay) Specifies the delay, in seconds, between replicated copies. Animatable.
- [instanceTransform](/documentation/quartzcore/careplicatorlayer/instancetransform) The transform matrix applied to the previous instance to produce the current instance. Animatable.

## Modifying Instance Layer Geometry

- [preservesDepth](/documentation/quartzcore/careplicatorlayer/preservesdepth) Defines whether this layer flattens its sublayers into its plane.

## Accessing Instance Color Values

- [instanceColor](/documentation/quartzcore/careplicatorlayer/instancecolor) Defines the color used to multiply the source object. Animatable.
- [instanceRedOffset](/documentation/quartzcore/careplicatorlayer/instanceredoffset) Defines the offset added to the red component of the color for each replicated instance. Animatable.
- [instanceGreenOffset](/documentation/quartzcore/careplicatorlayer/instancegreenoffset) Defines the offset added to the green component of the color for each replicated instance. Animatable.
- [instanceBlueOffset](/documentation/quartzcore/careplicatorlayer/instanceblueoffset) Defines the offset added to the blue component of the color for each replicated instance. Animatable.
- [instanceAlphaOffset](/documentation/quartzcore/careplicatorlayer/instancealphaoffset) Defines the offset added to the alpha component of the color for each replicated instance. Animatable.

## Advanced Layer Options

- [CAScrollLayer](/documentation/quartzcore/cascrolllayer) A layer that displays scrollable content larger than its own bounds.
- [CATiledLayer](/documentation/quartzcore/catiledlayer) A layer that provides a way to asynchronously provide tiles of the layer’s content, potentially cached at multiple levels of detail.
- [CATransformLayer](/documentation/quartzcore/catransformlayer) Objects used to create true 3D layer hierarchies, rather than the flattened hierarchy rendering model used by other layer types.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
