---
title: CASpringAnimation
description: An animation that applies a spring-like force to a layer’s properties.
source: https://developer.apple.com/documentation/quartzcore/caspringanimation
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/caspringanimation.json
timestamp: 2026-05-13T20:41:23.518Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CASpringAnimation

**Available on:** iOS 9.0+, iPadOS 9.0+, Mac Catalyst 13.1+, macOS 10.11+, tvOS 9.0+, visionOS 1.0+

> An animation that applies a spring-like force to a layer’s properties.

```swift
class CASpringAnimation
```

## Overview

You would typically use a spring animation to animate a layer’s position so that it appears to be pulled towards a target by a spring. The further the layer is from the target, the greater the acceleration towards it is.

[CASpringAnimation](/documentation/quartzcore/caspringanimation) allows control over physically based attributes such as the spring’s damping and stiffness.

You can use a spring animation to animation properties of a layer other than its position. The following code shows how to create a spring animation that bounces a layer into view by animating its scale from `0` to `1`. Because the spring animation can overshoot its [toValue](/documentation/quartzcore/cabasicanimation/tovalue), the animated layer may exceed its frame.

```swift
let springAnimation = CASpringAnimation(keyPath: "transform.scale")

springAnimation.fromValue = 0
springAnimation.toValue = 1
```

## Inherits From

- [CABasicAnimation](/documentation/quartzcore/cabasicanimation)

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

## Configuring Physical Attributes

- [damping](/documentation/quartzcore/caspringanimation/damping) Defines how the spring’s motion should be damped due to the forces of friction.
- [initialVelocity](/documentation/quartzcore/caspringanimation/initialvelocity) The initial velocity of the object attached to the spring.
- [mass](/documentation/quartzcore/caspringanimation/mass) The mass of the object attached to the end of the spring.
- [settlingDuration](/documentation/quartzcore/caspringanimation/settlingduration) The estimated duration required for the spring system to be considered at rest.
- [stiffness](/documentation/quartzcore/caspringanimation/stiffness) The spring stiffness coefficient.

## Initializers

- [init(perceptualDuration:bounce:)](/documentation/quartzcore/caspringanimation/init(perceptualduration:bounce:))

## Instance Properties

- [allowsOverdamping](/documentation/quartzcore/caspringanimation/allowsoverdamping)
- [bounce](/documentation/quartzcore/caspringanimation/bounce)
- [perceptualDuration](/documentation/quartzcore/caspringanimation/perceptualduration)

## Animation

- [CAAnimation](/documentation/quartzcore/caanimation) The abstract superclass for animations in Core Animation.
- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate) Methods your app can implement to respond when animations start and stop.
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation) An abstract subclass for creating animations that manipulate the value of layer properties.
- [CABasicAnimation](/documentation/quartzcore/cabasicanimation) An object that provides basic, single-keyframe animation capabilities for a layer property.
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation) An object that provides keyframe animation capabilities for a layer object.
- [CATransition](/documentation/quartzcore/catransition) An object that provides an animated transition between a layer’s states.
- [CAValueFunction](/documentation/quartzcore/cavaluefunction) An object that provides a flexible method of defining animated transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
