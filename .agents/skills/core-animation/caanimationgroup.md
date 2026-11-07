---
title: CAAnimationGroup
description: An object that allows multiple animations to be grouped and run concurrently.
source: https://developer.apple.com/documentation/quartzcore/caanimationgroup
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/caanimationgroup.json
timestamp: 2026-05-13T20:41:25.349Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAAnimationGroup

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> An object that allows multiple animations to be grouped and run concurrently.

```swift
class CAAnimationGroup
```

## Overview

The grouped animations run in the time space specified by the [CAAnimationGroup](/documentation/quartzcore/caanimationgroup) instance.

The duration of the grouped animations are not scaled to the duration of their [CAAnimationGroup](/documentation/quartzcore/caanimationgroup). Instead, the animations are clipped to the duration of the animation group. For example, a 10 second animation grouped within an animation group with a duration of 5 seconds displays only the first 5 seconds of the animation.

The following code shows how you can create a grouped animation containing  opacity and scale animations to fade out a layer while expanding it. The animation starts with an opacity of `1` and a scale of `1` on all axes. As the animation’s scale increases to `(3, 3, 3)`, the opacity drops to `0` and the animated layer vanishes.

```swift
let fadeOut = CABasicAnimation(keyPath: "opacity")
fadeOut.fromValue = 1
fadeOut.toValue = 0
fadeOut.duration = 1
     
let expandScale = CABasicAnimation()
expandScale.keyPath = "transform"
expandScale.valueFunction = CAValueFunction(name: kCAValueFunctionScale)
expandScale.fromValue = [1, 1, 1]
expandScale.toValue = [3, 3, 3]
     
let fadeAndScale = CAAnimationGroup()
fadeAndScale.animations = [fadeOut, expandScale]
fadeAndScale.duration = 1
```

> **Important:** The [delegate](/documentation/quartzcore/caanimation/delegate) and [isRemovedOnCompletion](/documentation/quartzcore/caanimation/isremovedoncompletion) properties of animations in the [animations](/documentation/quartzcore/caanimationgroup/animations) array are currently ignored. The [CAAnimationGroup](/documentation/quartzcore/caanimationgroup) delegate does receive these messages.

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

## Grouped animations

- [animations](/documentation/quartzcore/caanimationgroup/animations) An array of `CAAnimation` objects to be evaluated in the time space of the receiver.

## Animation Groups

- [CATransaction](/documentation/quartzcore/catransaction) A mechanism for grouping multiple layer-tree operations into atomic updates to the render tree.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
