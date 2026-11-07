---
title: CATransition
description: An object that provides an animated transition between a layer’s states.
source: https://developer.apple.com/documentation/quartzcore/catransition
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/catransition.json
timestamp: 2026-05-13T20:41:26.216Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CATransition

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> An object that provides an animated transition between a layer’s states.

```swift
class CATransition
```

## Overview

You can transition between a layer’s states by creating and adding a [CATransition](/documentation/quartzcore/catransition) object to it. The default transition is a cross fade, but you can specify different effects from a set of predefined transitions.

The following code shows how you can transition between the two states of a [CATextLayer](/documentation/quartzcore/catextlayer) named `transitioningLayer`. When the layer is first created, its [backgroundColor](/documentation/quartzcore/calayer/backgroundcolor) is set to red and its [string](/documentation/quartzcore/catextlayer/string) property is set to `Red`. When the `runTransition()` function is called, a new [CATransition](/documentation/quartzcore/catransition) object is created and added to `transitioningLayer`, and the state of the layer is changed so that its background color is blue and its rendered text reads `Blue`.

The end result is that the push transition animates the red state from left to right with the blue state entering the scene from the left.

```swift
let transitioningLayer = CATextLayer()
     
override func viewDidLoad() {
    super.viewDidLoad()
    transitioningLayer.frame = CGRect(x: 10, y: 10,
                                      width: 320, height: 160)
    
    view.layer.addSublayer(transitioningLayer)
    
    // Initial "red" state
    transitioningLayer.backgroundColor = UIColor.red.cgColor
    transitioningLayer.string = "Red"
}
      
   
func runTransition() {
    let transition = CATransition()
    transition.duration = 2
    
    transition.type = kCATransitionPush
    
    transitioningLayer.add(transition,
                           forKey: "transition")
    
    // Transition to "blue" state
    transitioningLayer.backgroundColor = UIColor.blue.cgColor
    transitioningLayer.string = "Blue"
}
```

## Inherits From

- [CAAnimation](/documentation/quartzcore/caanimation)

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

## Transition start and end point

- [startProgress](/documentation/quartzcore/catransition/startprogress) Indicates the start point of the receiver as a fraction of the entire transition.
- [endProgress](/documentation/quartzcore/catransition/endprogress) Indicates the end point of the receiver as a fraction of the entire transition.

## Transition Properties

- [type](/documentation/quartzcore/catransition/type) Specifies the predefined transition type.
- [subtype](/documentation/quartzcore/catransition/subtype) Specifies an optional subtype that indicates the direction for the predefined motion-based transitions.

## Custom transition filter

- [filter](/documentation/quartzcore/catransition/filter) An optional Core Image filter object that provides the transition.

## Constants

- [Common Transition Types](/documentation/quartzcore/common-transition-types) These constants specify the transition types that can be used with the [type](/documentation/quartzcore/catransition/type) property.
- [Common Transition Subtypes](/documentation/quartzcore/common-transition-subtypes) These constants specify the direction of motion-based transitions. They are used with the [subtype](/documentation/quartzcore/catransition/subtype) property.

## Animation

- [CAAnimation](/documentation/quartzcore/caanimation) The abstract superclass for animations in Core Animation.
- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate) Methods your app can implement to respond when animations start and stop.
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation) An abstract subclass for creating animations that manipulate the value of layer properties.
- [CABasicAnimation](/documentation/quartzcore/cabasicanimation) An object that provides basic, single-keyframe animation capabilities for a layer property.
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation) An object that provides keyframe animation capabilities for a layer object.
- [CASpringAnimation](/documentation/quartzcore/caspringanimation) An animation that applies a spring-like force to a layer’s properties.
- [CAValueFunction](/documentation/quartzcore/cavaluefunction) An object that provides a flexible method of defining animated transformations.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
