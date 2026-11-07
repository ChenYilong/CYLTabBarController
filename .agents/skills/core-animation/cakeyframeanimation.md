---
title: CAKeyframeAnimation
description: An object that provides keyframe animation capabilities for a layer object.
source: https://developer.apple.com/documentation/quartzcore/cakeyframeanimation
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/cakeyframeanimation.json
timestamp: 2026-05-13T20:41:22.585Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAKeyframeAnimation

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> An object that provides keyframe animation capabilities for a layer object.

```swift
class CAKeyframeAnimation
```

## Overview

You create a [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation) object using the inherited [init(keyPath:)](/documentation/quartzcore/capropertyanimation/init(keypath:)) method, specifying the key path of the property that you want to animate on the layer. You can then specify the keyframe values to use to control the timing and animation behavior.

For most types of animations, you specify the keyframe values using the [values](/documentation/quartzcore/cakeyframeanimation/values) and [keyTimes](/documentation/quartzcore/cakeyframeanimation/keytimes) properties. During the animation, Core Animation generates intermediate values by interpolating between the values you provide. When animating a value that is a coordinate point, such as the layer’s position, you can specify a [path](/documentation/quartzcore/cakeyframeanimation/path) for that point to follow instead of individual values. The pacing of the animation is controlled by the timing information you provide.

The following code shows how to create a keyframe animation that animates a layer’s background color from red to green to blue over a two second duration.

```swift
let colorKeyframeAnimation = CAKeyframeAnimation(keyPath: "backgroundColor")

colorKeyframeAnimation.values = [UIColor.red.cgColor,
                                 UIColor.green.cgColor,
                                 UIColor.blue.cgColor]
colorKeyframeAnimation.keyTimes = [0, 0.5, 1]
colorKeyframeAnimation.duration = 2
```

## Inherits From

- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation)

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

## Providing keyframe values

- [values](/documentation/quartzcore/cakeyframeanimation/values) An array of objects that specify the keyframe values to use for the animation.
- [path](/documentation/quartzcore/cakeyframeanimation/path) The path for a point-based property to follow.

## Keyframe timing

- [keyTimes](/documentation/quartzcore/cakeyframeanimation/keytimes) An optional array of `NSNumber` objects that define the time at which to apply a given keyframe segment.
- [timingFunctions](/documentation/quartzcore/cakeyframeanimation/timingfunctions) An optional array of `CAMediaTimingFunction` objects that define the pacing for each keyframe segment.
- [calculationMode](/documentation/quartzcore/cakeyframeanimation/calculationmode) Specifies how intermediate keyframe values are calculated by the receiver.

## Rotation Mode Attribute

- [rotationMode](/documentation/quartzcore/cakeyframeanimation/rotationmode) Determines whether objects animating along the path rotate to match the path tangent.

## Cubic Mode Attributes

- [tensionValues](/documentation/quartzcore/cakeyframeanimation/tensionvalues) An array of numbers that define the tightness of the curve.
- [continuityValues](/documentation/quartzcore/cakeyframeanimation/continuityvalues) An array of numbers that define the sharpness of the timing curve’s corners.
- [biasValues](/documentation/quartzcore/cakeyframeanimation/biasvalues) An array of numbers that define the position of the curve relative to a control point.

## Constants

- [Rotation Mode Values](/documentation/quartzcore/rotation-mode-values) These constants are used by the [rotationMode](/documentation/quartzcore/cakeyframeanimation/rotationmode) property.
- [Value calculation modes](/documentation/quartzcore/value-calculation-modes) These constants are used by the [calculationMode](/documentation/quartzcore/cakeyframeanimation/calculationmode) property.

## Animation

- [CAAnimation](/documentation/quartzcore/caanimation) The abstract superclass for animations in Core Animation.
- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate) Methods your app can implement to respond when animations start and stop.
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation) An abstract subclass for creating animations that manipulate the value of layer properties.
- [CABasicAnimation](/documentation/quartzcore/cabasicanimation) An object that provides basic, single-keyframe animation capabilities for a layer property.
- [CASpringAnimation](/documentation/quartzcore/caspringanimation) An animation that applies a spring-like force to a layer’s properties.
- [CATransition](/documentation/quartzcore/catransition) An object that provides an animated transition between a layer’s states.
- [CAValueFunction](/documentation/quartzcore/cavaluefunction) An object that provides a flexible method of defining animated transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
