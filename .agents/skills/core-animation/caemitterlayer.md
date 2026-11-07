---
title: CAEmitterLayer
description: A layer that emits, animates, and renders a particle system.
source: https://developer.apple.com/documentation/quartzcore/caemitterlayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/caemitterlayer.json
timestamp: 2026-05-13T20:41:29.594Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAEmitterLayer

**Available on:** iOS 5.0+, iPadOS 5.0+, Mac Catalyst 13.1+, macOS 10.6+, tvOS 9.0+, visionOS 1.0+

> A layer that emits, animates, and renders a particle system.

```swift
class CAEmitterLayer
```

## Overview

The particles, defined by instances of [CAEmitterCell](/documentation/quartzcore/caemittercell), are drawn above the layer’s background color and border.

The following code shows how to set up a simple point (the default [emitterShape](/documentation/quartzcore/caemitterlayer/emittershape) is [point](/documentation/quartzcore/caemitterlayeremittershape/point)) particle emitter. It uses an image named `RadialGradient.png` as the cell contents and, by setting the emitter cell’s [emissionRange](/documentation/quartzcore/caemittercell/emissionrange) to `2` × [pi](/documentation/Swift/FloatingPoint/pi), the particles are emitted in all directions.

```swift
let emitterLayer = CAEmitterLayer()
    
emitterLayer.emitterPosition = CGPoint(x: 320, y: 320)
    
let cell = CAEmitterCell()
cell.birthRate = 100
cell.lifetime = 10
cell.velocity = 100
cell.scale = 0.1
    
cell.emissionRange = CGFloat.pi * 2.0
cell.contents = UIImage(named: "RadialGradient.png")!.cgImage
    
emitterLayer.emitterCells = [cell]
    
view.layer.addSublayer(emitterLayer)
```

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

## Specifying Particle Emitter Cells

- [emitterCells](/documentation/quartzcore/caemitterlayer/emittercells) The array emitter cells attached to the layer.

## Emitter Geometry

- [renderMode](/documentation/quartzcore/caemitterlayer/rendermode) Defines how particle cells are rendered into the layer.
- [emitterPosition](/documentation/quartzcore/caemitterlayer/emitterposition) The position of the center of the particle emitter. Animatable.
- [emitterShape](/documentation/quartzcore/caemitterlayer/emittershape) Specifies the emitter shape.
- [emitterZPosition](/documentation/quartzcore/caemitterlayer/emitterzposition) Specifies the center of the particle emitter shape along the z-axis. Animatable.
- [emitterDepth](/documentation/quartzcore/caemitterlayer/emitterdepth) Determines the depth of the emitter shape.
- [emitterSize](/documentation/quartzcore/caemitterlayer/emittersize) Determines the size of the particle emitter shape. Animatable.

## Emitter Cell Attribute Multipliers

- [scale](/documentation/quartzcore/caemitterlayer/scale) Defines a multiplier applied to the cell-defined particle scale.
- [seed](/documentation/quartzcore/caemitterlayer/seed) Specifies the seed used to initialize the random number generator.
- [spin](/documentation/quartzcore/caemitterlayer/spin) Defines a multiplier applied to the cell-defined particle spin. Animatable.
- [velocity](/documentation/quartzcore/caemitterlayer/velocity) Defines a multiplier applied to the cell-defined particle velocity. Animatable.
- [birthRate](/documentation/quartzcore/caemitterlayer/birthrate) Defines a multiplier that is applied to the cell-defined birth rate. Animatable
- [emitterMode](/documentation/quartzcore/caemitterlayer/emittermode) Specifies the emitter mode.
- [lifetime](/documentation/quartzcore/caemitterlayer/lifetime) Defines a multiplier applied to the cell-defined lifetime range when particles are created. Animatable.
- [preservesDepth](/documentation/quartzcore/caemitterlayer/preservesdepth) Defines whether the layer flattens the particles into its plane.

## Constants

- [Emitter Shape](/documentation/quartzcore/emitter-shape) The emission shape is a one, two or three dimensional shape that defines where the emitted particles originate. The shapes are defined by a subset of [emitterPosition](/documentation/quartzcore/caemitterlayer/emitterposition), [emitterZPosition](/documentation/quartzcore/caemitterlayer/emitterzposition), [emitterSize](/documentation/quartzcore/caemitterlayer/emittersize) and [emitterDepth](/documentation/quartzcore/caemitterlayer/emitterdepth) properties.
- [Emitter Modes](/documentation/quartzcore/emitter-modes) These constants specify the possible emitter modes. They are used by the [emitterMode](/documentation/quartzcore/caemitterlayer/emittermode) property.
- [Emitter Render Order](/documentation/quartzcore/emitter-render-order) These constants specify the order that emitter cells are composited. They are used by the [renderMode](/documentation/quartzcore/caemitterlayer/rendermode) property.

## Particle Systems

- [CAEmitterCell](/documentation/quartzcore/caemittercell) The definition of a particle emitted by a particle layer.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
