---
title: CABasicAnimation
description: An object that provides basic, single-keyframe animation capabilities for a layer property.
source: https://developer.apple.com/documentation/quartzcore/cabasicanimation
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/cabasicanimation.json
timestamp: 2026-05-13T20:41:21.672Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CABasicAnimation

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> An object that provides basic, single-keyframe animation capabilities for a layer property.

```swift
class CABasicAnimation
```

## Overview

You create an instance of  [CABasicAnimation](/documentation/quartzcore/cabasicanimation) using the inherited [init(keyPath:)](/documentation/quartzcore/capropertyanimation/init(keypath:)) method, specifying the key path of the property to be animated in the render tree.

For example, you can animate a layer’s scalar (i.e. containing a single value) properties such as its [opacity](/documentation/quartzcore/calayer/opacity). The following code fades in a layer by animating its opacity from `0` to `1`.

```swift
let animation = CABasicAnimation(keyPath: "opacity") 
animation.fromValue = 0 
animation.toValue = 1
```

Non-scalar properties, such as [backgroundColor](/documentation/quartzcore/calayer/backgroundcolor), can also be animated. Core Animation will interpolate between the [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) color and the [toValue](/documentation/quartzcore/cabasicanimation/tovalue) color. The animation created in the following code fades a layer’s background color from red to blue.

```swift
let animation = CABasicAnimation(keyPath: "backgroundColor")
animation.fromValue = NSColor.red.cgColor
animation.toValue = NSColor.blue.cgColor
```

If you want to animate the individual components of a non-scalar property with different values, you pass the values to [toValue](/documentation/quartzcore/cabasicanimation/tovalue) and [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) as arrays. The following animation moves a layer from `(0, 0)` to `(100, 100)`.

```swift
let animation = CABasicAnimation(keyPath: "position")
animation.fromValue = [0, 0]
animation.toValue = [100, 100]
```

The `keyPath` can access the individual components of a property. For example, the following animation stretches a layer by animating its [transform](/documentation/quartzcore/calayer/transform) object’s `x` from `1` to `2`.

```swift
let animation = CABasicAnimation(keyPath: "transform.scale.x")
animation.fromValue = 1
animation.toValue = 2
```

### Setting Interpolation Values

The [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue), [byValue](/documentation/quartzcore/cabasicanimation/byvalue) and [toValue](/documentation/quartzcore/cabasicanimation/tovalue) properties define the values being interpolated between. All are optional, and no more than two should be non-`nil`. The object type should match the type of the property being animated.

The interpolation values are used as follows:

- Both [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) and [toValue](/documentation/quartzcore/cabasicanimation/tovalue) are non-`nil`. Interpolates between [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) and [toValue](/documentation/quartzcore/cabasicanimation/tovalue).
- [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) and [byValue](/documentation/quartzcore/cabasicanimation/byvalue) are non-`nil`. Interpolates between [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) and ([fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) + [byValue](/documentation/quartzcore/cabasicanimation/byvalue)).
- [byValue](/documentation/quartzcore/cabasicanimation/byvalue) and [toValue](/documentation/quartzcore/cabasicanimation/tovalue) are non-`nil`. Interpolates between ([toValue](/documentation/quartzcore/cabasicanimation/tovalue) - [byValue](/documentation/quartzcore/cabasicanimation/byvalue)) and [toValue](/documentation/quartzcore/cabasicanimation/tovalue).
- [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) is non-`nil`. Interpolates between [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) and the current presentation value of the property.
- [toValue](/documentation/quartzcore/cabasicanimation/tovalue) is non-`nil`. Interpolates between the current value of `keyPath` in the target layer’s presentation layer and [toValue](/documentation/quartzcore/cabasicanimation/tovalue).
- [byValue](/documentation/quartzcore/cabasicanimation/byvalue) is non-`nil`. Interpolates between the current value of `keyPath` in the target layer’s presentation layer and that value plus [byValue](/documentation/quartzcore/cabasicanimation/byvalue).
- All properties are `nil`. Interpolates between the previous value of `keyPath` in the target layer’s presentation layer and the current value of  `keyPath` in the target layer’s presentation layer.

## Inherits From

- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation)

## Inherited By

- [CASpringAnimation](/documentation/quartzcore/caspringanimation)

## Conforms To

- [CAAction](/documentation/quartzcore/caaction)
- [CAMediaTiming](/documentation/quartzcore/camediatiming)
- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSCopying](/documentation/Foundation/NSCopying)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Interpolation values

- [fromValue](/documentation/quartzcore/cabasicanimation/fromvalue) Defines the value the receiver uses to start interpolation.
- [toValue](/documentation/quartzcore/cabasicanimation/tovalue) Defines the value the receiver uses to end interpolation.
- [byValue](/documentation/quartzcore/cabasicanimation/byvalue) Defines the value the receiver uses to perform relative interpolation.

## Animation

- [CAAnimation](/documentation/quartzcore/caanimation) The abstract superclass for animations in Core Animation.
- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate) Methods your app can implement to respond when animations start and stop.
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation) An abstract subclass for creating animations that manipulate the value of layer properties.
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation) An object that provides keyframe animation capabilities for a layer object.
- [CASpringAnimation](/documentation/quartzcore/caspringanimation) An animation that applies a spring-like force to a layer’s properties.
- [CATransition](/documentation/quartzcore/catransition) An object that provides an animated transition between a layer’s states.
- [CAValueFunction](/documentation/quartzcore/cavaluefunction) An object that provides a flexible method of defining animated transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
