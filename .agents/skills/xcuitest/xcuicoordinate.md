---
title: XCUICoordinate
description: A location on screen relative to a UI element.
source: https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuicoordinate.json
timestamp: 2026-04-14T13:14:57.667Z
---

**Navigation:** [XCUIAutomation](/documentation/xcuiautomation)

**Class**

# XCUICoordinate

**Available on:** iOS, iPadOS, Mac Catalyst, macOS, visionOS, watchOS, Xcode 16.3+

> A location on screen relative to a UI element.

```swift
@MainActor class XCUICoordinate
```

## Overview

Coordinates are dynamic, like the elements to which they refer, and may compute different screen locations at different times, or be invalid if the element they reference doesn’t exist.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCopying](/documentation/Foundation/NSCopying)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [Sendable](/documentation/Swift/Sendable)

## Getting coordinate properties

- [referencedElement](/documentation/xcuiautomation/xcuicoordinate/referencedelement) The element that the coordinate is based on, either directly or through the coordinate from which it was derived.
- [screenPoint](/documentation/xcuiautomation/xcuicoordinate/screenpoint) The dynamically computed value of the coordinate’s location on screen.

## Moving the pointer

- [hover()](/documentation/xcuiautomation/xcuicoordinate/hover()) Moves the pointer to the coordinate.

## Clicking

- [click()](/documentation/xcuiautomation/xcuicoordinate/click()) Sends a click event at the coordinate.
- [click(forDuration:thenDragTo:)](/documentation/xcuiautomation/xcuicoordinate/click(forduration:thendragto:)) Clicks and holds for a duration you specify, then drags to the other coordinate.
- [click(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)](/documentation/xcuiautomation/xcuicoordinate/click(forduration:thendragto:withvelocity:thenholdforduration:)) Clicks and holds for a duration, drags at a velocity, and holds over the other coordinate for a duration, all of which you specify.
- [doubleClick()](/documentation/xcuiautomation/xcuicoordinate/doubleclick()) Sends a double-click event at the coordinate.
- [rightClick()](/documentation/xcuiautomation/xcuicoordinate/rightclick()) Sends a Control-click event at the coordinate.

## Scrolling

- [scroll(byDeltaX:deltaY:)](/documentation/xcuiautomation/xcuicoordinate/scroll(bydeltax:deltay:)) Scrolls the view by the number of x and y pixels you specify.

## Tapping and pressing

- [tap()](/documentation/xcuiautomation/xcuicoordinate/tap()) Sends a tap event at the coordinate.
- [doubleTap()](/documentation/xcuiautomation/xcuicoordinate/doubletap()) Sends a double-tap event at the coordinate.
- [press(forDuration:)](/documentation/xcuiautomation/xcuicoordinate/press(forduration:)) Initiates a press-and-hold gesture at the coordinate, holding for the duration you specify.
- [press(forDuration:thenDragTo:)](/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:)) Initiates a press-and-hold gesture at the coordinate, then drags to another coordinate.
- [press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)](/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:withvelocity:thenholdforduration:)) Initiates a press-and-hold gesture, drags to another coordinate with a velocity you specify, and holds for a duration you specify.

## Performing gestures

- [swipeLeft()](/documentation/xcuiautomation/xcuicoordinate/swipeleft()) Sends a swipe-left gesture.
- [swipeLeft(velocity:)](/documentation/xcuiautomation/xcuicoordinate/swipeleft(velocity:)) Sends a swipe-left gesture with a velocity you specify.
- [swipeRight()](/documentation/xcuiautomation/xcuicoordinate/swiperight()) Sends a swipe-right gesture.
- [swipeRight(velocity:)](/documentation/xcuiautomation/xcuicoordinate/swiperight(velocity:)) Sends a swipe-right gesture with a velocity you specify.
- [swipeUp()](/documentation/xcuiautomation/xcuicoordinate/swipeup()) Sends a swipe-up gesture.
- [swipeUp(velocity:)](/documentation/xcuiautomation/xcuicoordinate/swipeup(velocity:)) Sends a swipe-up gesture with a velocity you specify.
- [swipeDown()](/documentation/xcuiautomation/xcuicoordinate/swipedown()) Sends a swipe-down gesture.
- [swipeDown(velocity:)](/documentation/xcuiautomation/xcuicoordinate/swipedown(velocity:)) Sends a swipe-down gesture with a velocity you specify.

## Creating relative coordinates

- [withOffset(_:)](/documentation/xcuiautomation/xcuicoordinate/withoffset(_:)) Creates a new coordinate with an absolute offset in points from the original coordinate.

## UI elements

- [XCUIElement](/documentation/xcuiautomation/xcuielement) A UI element in an application.
- [XCUIElementAttributes](/documentation/xcuiautomation/xcuielementattributes) Attributes exposed by UI elements.
- [XCUIElementSnapshot](/documentation/xcuiautomation/xcuielementsnapshot) A set of attributes to express a snapshot of an element’s attributes and descendant user interface hierarchy.
- [XCUIElementSnapshotProviding](/documentation/xcuiautomation/xcuielementsnapshotproviding) A method to capture a snapshot of an element’s attributes and descendant user interface hierarchy.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
