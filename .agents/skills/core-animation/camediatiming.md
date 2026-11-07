---
title: CAMediaTiming
description: Methods that model a hierarchical timing system, allowing objects to map time between their parent and local time.
source: https://developer.apple.com/documentation/quartzcore/camediatiming
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/camediatiming.json
timestamp: 2026-05-13T20:41:31.474Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Protocol**

# CAMediaTiming

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> Methods that model a hierarchical timing system, allowing objects to map time between their parent and local time.

```swift
protocol CAMediaTiming
```

## Overview

Absolute time is defined as mach time converted to seconds. The [CACurrentMediaTime()](/documentation/quartzcore/cacurrentmediatime()) function is provided as a convenience for getting the current absolute time.

The conversion from parent time to local time has two stages:

1. Conversion to “active local time.” This includes the point at which the object appears in the parent object’s timeline and how fast it plays relative to the parent.
2. Conversion from “active local time” to “basic local time.” The timing model allows for objects to repeat their basic duration multiple times and, optionally, to play backwards before repeating.

## Conforming Types

- [CAAnimation](/documentation/quartzcore/caanimation)
- [CAAnimationGroup](/documentation/quartzcore/caanimationgroup)
- [CABasicAnimation](/documentation/quartzcore/cabasicanimation)
- [CAEAGLLayer](/documentation/quartzcore/caeagllayer)
- [CAEmitterCell](/documentation/quartzcore/caemittercell)
- [CAEmitterLayer](/documentation/quartzcore/caemitterlayer)
- [CAGradientLayer](/documentation/quartzcore/cagradientlayer)
- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation)
- [CALayer](/documentation/quartzcore/calayer)
- [CAMetalLayer](/documentation/quartzcore/cametallayer)
- [CAOpenGLLayer](/documentation/quartzcore/caopengllayer)
- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation)
- [CAReplicatorLayer](/documentation/quartzcore/careplicatorlayer)
- [CAScrollLayer](/documentation/quartzcore/cascrolllayer)
- [CAShapeLayer](/documentation/quartzcore/cashapelayer)
- [CASpringAnimation](/documentation/quartzcore/caspringanimation)
- [CATextLayer](/documentation/quartzcore/catextlayer)
- [CATiledLayer](/documentation/quartzcore/catiledlayer)
- [CATransformLayer](/documentation/quartzcore/catransformlayer)
- [CATransition](/documentation/quartzcore/catransition)

## Animation Start Time

- [beginTime](/documentation/quartzcore/camediatiming/begintime) Specifies the begin time of the receiver in relation to its parent object, if applicable.
- [timeOffset](/documentation/quartzcore/camediatiming/timeoffset) Specifies an additional time offset in active local time.

## Repeating Animations

- [repeatCount](/documentation/quartzcore/camediatiming/repeatcount) Determines the number of times the animation will repeat.
- [repeatDuration](/documentation/quartzcore/camediatiming/repeatduration) Determines how many seconds the animation will repeat for.

## Duration and Speed

- [duration](/documentation/quartzcore/camediatiming/duration) Specifies the basic duration of the animation, in seconds.
- [speed](/documentation/quartzcore/camediatiming/speed) Specifies how time is mapped to receiver’s time space from the parent time space.

## Playback Modes

- [autoreverses](/documentation/quartzcore/camediatiming/autoreverses) Determines if the receiver plays in the reverse upon completion.
- [fillMode](/documentation/quartzcore/camediatiming/fillmode) Determines if the receiver’s presentation is frozen or removed once its active duration has completed.

## Constants

- [Fill Modes](/documentation/quartzcore/fill-modes) These constants determine how the timed object behaves once its active duration has completed. They are used with the [fillMode](/documentation/quartzcore/camediatiming/fillmode) property.

## Animation Timing

- [CACurrentMediaTime()](/documentation/quartzcore/cacurrentmediatime()) Returns the current absolute time, in seconds.
- [CAMediaTimingFunction](/documentation/quartzcore/camediatimingfunction) A function that defines the pacing of an animation as a timing curve.
- [CADisplayLink](/documentation/quartzcore/cadisplaylink) A timer object that allows your app to synchronize its drawing to the refresh rate of the display.
- [CAMetalDisplayLink](/documentation/quartzcore/cametaldisplaylink) A class your Metal app uses to register for callbacks to synchronize its animations for a display.
- [CAMetalDisplayLink.Update](/documentation/quartzcore/cametaldisplaylink/update) Stores information about a single update from a Metal display link instance.
- [CAMetalDisplayLinkDelegate](/documentation/quartzcore/cametaldisplaylinkdelegate) A protocol your app implements to respond to callbacks from Core Animation for a Metal display link.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
