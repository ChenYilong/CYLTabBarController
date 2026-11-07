---
title: CAPropertyAnimation
description: An abstract subclass for creating animations that manipulate the value of layer properties.
source: https://developer.apple.com/documentation/quartzcore/capropertyanimation
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/capropertyanimation.json
timestamp: 2026-05-13T20:41:24.408Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAPropertyAnimation

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> An abstract subclass for creating animations that manipulate the value of layer properties.

```swift
class CAPropertyAnimation
```

## Overview

The property to animate is specified using a key path that is relative to the layer using the animation.

You do not create instances of [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation): to animate the properties of a Core Animation layer, create instance of the concrete subclasses [CABasicAnimation](/documentation/quartzcore/cabasicanimation) or [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation).

## Inherits From

- [CAAnimation](/documentation/quartzcore/caanimation)

## Inherited By

- [CABasicAnimation](/documentation/quartzcore/cabasicanimation)
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation)

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

## Animated Key Path

- [keyPath](/documentation/quartzcore/capropertyanimation/keypath) Specifies the key path the receiver animates.

## Property Value Calculation Behavior

- [isCumulative](/documentation/quartzcore/capropertyanimation/iscumulative) Determines if the value of the property is the value at the end of the previous repeat cycle, plus the value of the current repeat cycle.
- [isAdditive](/documentation/quartzcore/capropertyanimation/isadditive) Determines if the value specified by the animation is added to the current render tree value to produce the new render tree value.
- [valueFunction](/documentation/quartzcore/capropertyanimation/valuefunction) An optional value function that is applied to interpolated values.

## Creating an Animation

- [init(keyPath:)](/documentation/quartzcore/capropertyanimation/init(keypath:)) Creates and returns an `CAPropertyAnimation` instance for the specified key path.

## Animation

- [CAAnimation](/documentation/quartzcore/caanimation) The abstract superclass for animations in Core Animation.
- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate) Methods your app can implement to respond when animations start and stop.
- [CABasicAnimation](/documentation/quartzcore/cabasicanimation) An object that provides basic, single-keyframe animation capabilities for a layer property.
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation) An object that provides keyframe animation capabilities for a layer object.
- [CASpringAnimation](/documentation/quartzcore/caspringanimation) An animation that applies a spring-like force to a layer’s properties.
- [CATransition](/documentation/quartzcore/catransition) An object that provides an animated transition between a layer’s states.
- [CAValueFunction](/documentation/quartzcore/cavaluefunction) An object that provides a flexible method of defining animated transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
