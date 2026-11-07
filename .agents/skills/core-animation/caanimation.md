---
title: CAAnimation
description: The abstract superclass for animations in Core Animation.
source: https://developer.apple.com/documentation/quartzcore/caanimation
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/caanimation.json
timestamp: 2026-05-13T20:41:20.817Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAAnimation

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> The abstract superclass for animations in Core Animation.

```swift
class CAAnimation
```

## Overview

`CAAnimation` provides the basic support for the [CAMediaTiming](/documentation/quartzcore/camediatiming) and [CAAction](/documentation/quartzcore/caaction) protocols. You do not create instance of [CAAnimation](/documentation/quartzcore/caanimation): to animate Core Animation layers or SceneKit objects, create instances of the concrete subclasses [CABasicAnimation](/documentation/quartzcore/cabasicanimation), [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation), [CAAnimationGroup](/documentation/quartzcore/caanimationgroup), or [CATransition](/documentation/quartzcore/catransition).

### Animating Core Animation Layers

You can animate the contents of your iOS or macOS app’s user interface by attaching animations to [CALayer](/documentation/quartzcore/calayer) objects. For more information, see [Core Animation Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40004514).

### Animating Scene Kit Content

In Scene Kit, animation objects represent not only property-based animations, but also animations of geometry data created with external 3D authoring tools and loaded from a scene file. You use the properties of the [CAAnimation](/documentation/quartzcore/caanimation) object representing a geometry animation to control its timing, monitor its progress, and attach actions for Scene Kit to trigger during the animation. You can attach animations to Scene Kit objects that adopt the [SCNAnimatable](/documentation/SceneKit/SCNAnimatable) protocol, including nodes, geometries, and materials.

In a Scene Kit app, [CAAnimation](/documentation/quartzcore/caanimation) objects support additional methods and properties, listed under Controlling SceneKit Animation Timing, Fading between SceneKit Animations, and Attaching SceneKit Animation Events.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Inherited By

- [CAAnimationGroup](/documentation/quartzcore/caanimationgroup)
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation)
- [CATransition](/documentation/quartzcore/catransition)

## Conforms To

- [CAAction](/documentation/quartzcore/caaction)
- [CAMediaTiming](/documentation/quartzcore/camediatiming)
- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSCopying](/documentation/Foundation/NSCopying)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [SCNAnimationProtocol](/documentation/SceneKit/SCNAnimationProtocol)

## Creating an Animation

- [init(SCNAnimation:)](/documentation/quartzcore/caanimation/init(scnanimation:)) Creates an animation from a SceneKit animation.

## Animation Attributes

- [isRemovedOnCompletion](/documentation/quartzcore/caanimation/isremovedoncompletion) Determines if the animation is removed from the target layer’s animations upon completion.
- [timingFunction](/documentation/quartzcore/caanimation/timingfunction) An optional timing function defining the pacing of the animation.

## Providing Default Values

- [defaultValue(forKey:)](/documentation/quartzcore/caanimation/defaultvalue(forkey:)) Specifies the default value of the property with the specified key.

## Designating a Delegate

- [delegate](/documentation/quartzcore/caanimation/delegate) Specifies the receiver’s delegate object.

## Archiving Properties

- [shouldArchiveValue(forKey:)](/documentation/quartzcore/caanimation/shouldarchivevalue(forkey:)) Specifies whether the value of the property for a given key is archived.

## Controlling SceneKit Animation Timing

- [usesSceneTimeBase](/documentation/quartzcore/caanimation/usesscenetimebase) For animations attached to SceneKit objects, a Boolean value that determines whether the animation is evaluated using the scene time or the system time.

## Fading between SceneKit Animations

- [fadeInDuration](/documentation/quartzcore/caanimation/fadeinduration) For animations attached to SceneKit objects, the duration for transitioning into the animation’s effect as it begins.
- [fadeOutDuration](/documentation/quartzcore/caanimation/fadeoutduration) For animations attached to SceneKit objects, the duration for transitioning out of the animation’s effect as it ends.

## Attaching SceneKit Animation Events

- [animationEvents](/documentation/quartzcore/caanimation/animationevents) For animations attached to SceneKit objects, a list of events attached to an animation.

## Initializers

- [init(SCNAnimation:)](/documentation/quartzcore/caanimation/init(scnanimation:)) Creates an animation from a SceneKit animation.
- [init(coder:)](/documentation/quartzcore/caanimation/init(coder:))

## Instance Properties

- [preferredFrameRateRange](/documentation/quartzcore/caanimation/preferredframeraterange)

## Animation

- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate) Methods your app can implement to respond when animations start and stop.
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation) An abstract subclass for creating animations that manipulate the value of layer properties.
- [CABasicAnimation](/documentation/quartzcore/cabasicanimation) An object that provides basic, single-keyframe animation capabilities for a layer property.
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation) An object that provides keyframe animation capabilities for a layer object.
- [CASpringAnimation](/documentation/quartzcore/caspringanimation) An animation that applies a spring-like force to a layer’s properties.
- [CATransition](/documentation/quartzcore/catransition) An object that provides an animated transition between a layer’s states.
- [CAValueFunction](/documentation/quartzcore/cavaluefunction) An object that provides a flexible method of defining animated transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
