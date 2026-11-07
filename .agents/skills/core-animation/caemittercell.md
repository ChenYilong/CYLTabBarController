---
title: CAEmitterCell
description: The definition of a particle emitted by a particle layer.
source: https://developer.apple.com/documentation/quartzcore/caemittercell
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/caemittercell.json
timestamp: 2026-05-13T20:41:30.590Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAEmitterCell

**Available on:** iOS 5.0+, iPadOS 5.0+, Mac Catalyst 13.1+, macOS 10.6+, tvOS 9.0+, visionOS 1.0+

> The definition of a particle emitted by a particle layer.

```swift
class CAEmitterCell
```

## Overview

The [CAEmitterCell](/documentation/quartzcore/caemittercell) class represents one source of particles being emitted by a [CAEmitterLayer](/documentation/quartzcore/caemitterlayer) object. An emitter cell defines the direction and properties of the emitted particles. Emitter cells can have an array of sub-cells, which lets the particles themselves emit particles.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

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

## Providing Emitter Cell Content

- [contents](/documentation/quartzcore/caemittercell/contents) An object that provides the contents of the layer. Animatable.
- [contentsRect](/documentation/quartzcore/caemittercell/contentsrect) A rectangle (in the unit coordinate space) that specifies the portion of [contents](/documentation/quartzcore/caemittercell/contents) that the receiver should draw. Animatable.
- [emitterCells](/documentation/quartzcore/caemittercell/emittercells) An optional array containing the sub-cells of this cell.

## Setting Emitter Cell Visual Attributes

- [isEnabled](/documentation/quartzcore/caemittercell/isenabled) A Boolean value indicating whether or not cells from this emitter are rendered.
- [color](/documentation/quartzcore/caemittercell/color) The color of each emitted object. Animatable.
- [redRange](/documentation/quartzcore/caemittercell/redrange) The amount by which the red color component of the cell can vary. Animatable.
- [greenRange](/documentation/quartzcore/caemittercell/greenrange) The amount by which the green color component of the cell can vary. Animatable.
- [blueRange](/documentation/quartzcore/caemittercell/bluerange) The amount by which the blue color component of the cell can vary. Animatable.
- [alphaRange](/documentation/quartzcore/caemittercell/alpharange) The amount by which the alpha component of the cell can vary. Animatable.
- [redSpeed](/documentation/quartzcore/caemittercell/redspeed) The speed, in seconds, at which the red color component changes over the lifetime of the cell. Animatable.
- [greenSpeed](/documentation/quartzcore/caemittercell/greenspeed) The speed, in seconds, at which the green color component changes over the lifetime of the cell. Animatable.
- [blueSpeed](/documentation/quartzcore/caemittercell/bluespeed) The speed, in seconds, at which the blue color component changes over the lifetime of the cell. Animatable.
- [alphaSpeed](/documentation/quartzcore/caemittercell/alphaspeed) The speed, in seconds, at which the alpha component changes over the lifetime of the cell. Animatable.
- [magnificationFilter](/documentation/quartzcore/caemittercell/magnificationfilter) The filter used when increasing the size of the content.
- [minificationFilter](/documentation/quartzcore/caemittercell/minificationfilter) The filter used when reducing the size of the content.
- [minificationFilterBias](/documentation/quartzcore/caemittercell/minificationfilterbias) The bias factor used by the minification filter to determine the levels of detail.
- [scale](/documentation/quartzcore/caemittercell/scale) Specifies the scale factor applied to the cell. Animatable.
- [scaleRange](/documentation/quartzcore/caemittercell/scalerange) Specifies the range over which the scale value can vary. Animatable.
- [contentsScale](/documentation/quartzcore/caemittercell/contentsscale) The scale factor of the cell contents.
- [name](/documentation/quartzcore/caemittercell/name) The name of the cell.
- [style](/documentation/quartzcore/caemittercell/style) An optional dictionary containing additional style values that are not explicitly defined by the receiver.

## Setting Emitter Cell Motion Attributes

- [spin](/documentation/quartzcore/caemittercell/spin) The rotational velocity, measured in radians per second, to apply to the cell. Animatable.
- [spinRange](/documentation/quartzcore/caemittercell/spinrange) The amount by which the spin of the cell can vary over its lifetime. Animatable.
- [emissionLatitude](/documentation/quartzcore/caemittercell/emissionlatitude) The latitudinal orientation of the emission angle. Animatable.
- [emissionLongitude](/documentation/quartzcore/caemittercell/emissionlongitude) The longitudinal orientation of the emission angle. Animatable.
- [emissionRange](/documentation/quartzcore/caemittercell/emissionrange) The angle, in radians, defining a cone around the emission angle. Animatable.

## Setting Emitter Cell Temporal Attributes

- [lifetime](/documentation/quartzcore/caemittercell/lifetime) The lifetime of the cell, in seconds. Animatable.
- [lifetimeRange](/documentation/quartzcore/caemittercell/lifetimerange) The mean value by which the [lifetime](/documentation/quartzcore/caemittercell/lifetime) of the cell can vary. Animatable.
- [birthRate](/documentation/quartzcore/caemittercell/birthrate) The number of emitted objects created every second. Animatable.
- [scaleSpeed](/documentation/quartzcore/caemittercell/scalespeed) The speed at which the scale changes over the lifetime of the cell. Animatable.
- [velocity](/documentation/quartzcore/caemittercell/velocity) The initial velocity of the cell. Animatable.
- [velocityRange](/documentation/quartzcore/caemittercell/velocityrange) The amount by which the velocity of the cell can vary. Animatable.
- [xAcceleration](/documentation/quartzcore/caemittercell/xacceleration) The x component of an acceleration vector applied to cell.
- [yAcceleration](/documentation/quartzcore/caemittercell/yacceleration) The y component of an acceleration vector applied to cell.
- [zAcceleration](/documentation/quartzcore/caemittercell/zacceleration) The z component of an acceleration vector applied to cell.

## Using Key-Value Coding Extensions

- [defaultValue(forKey:)](/documentation/quartzcore/caemittercell/defaultvalue(forkey:)) Returns the default value of the property with the specified key.
- [shouldArchiveValue(forKey:)](/documentation/quartzcore/caemittercell/shouldarchivevalue(forkey:)) Returns a Boolean value indicating whether the value for a given key should be archived.

## Initializers

- [init(coder:)](/documentation/quartzcore/caemittercell/init(coder:))

## Particle Systems

- [CAEmitterLayer](/documentation/quartzcore/caemitterlayer) A layer that emits, animates, and renders a particle system.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
