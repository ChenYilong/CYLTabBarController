---
title: XCUIElement
description: A UI element in an application.
source: https://developer.apple.com/documentation/xcuiautomation/xcuielement
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuielement.json
timestamp: 2026-04-14T13:14:57.958Z
---

**Navigation:** [XCUIAutomation](/documentation/xcuiautomation)

**Class**

# XCUIElement

**Available on:** iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS, Xcode 16.3+

> A UI element in an application.

```swift
@MainActor class XCUIElement
```

## Overview

In macOS and iPadOS 15 and later, [XCUIElement](/documentation/xcuiautomation/xcuielement) provides a way to test your app with keyboard and mouse interactions, such as typing, clicking, scrolling, and moving and pausing the pointer. In iOS, [XCUIElement](/documentation/xcuiautomation/xcuielement) provides a way to test your app with gestures, such as tapping, swiping, pinching, and rotating.

> **Note:** [XCUIElement](/documentation/xcuiautomation/xcuielement) adopts the [XCUIElementAttributes](/documentation/xcuiautomation/xcuielementattributes) protocol, which provides additional properties for querying the current state of a UI element’s attributes.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Inherited By

- [XCUIApplication](/documentation/xcuiautomation/xcuiapplication)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [Sendable](/documentation/Swift/Sendable)
- [XCUIElementAttributes](/documentation/xcuiautomation/xcuielementattributes)
- [XCUIElementSnapshotProviding](/documentation/xcuiautomation/xcuielementsnapshotproviding)
- [XCUIElementTypeQueryProvider](/documentation/xcuiautomation/xcuielementtypequeryprovider)
- [XCUIScreenshotProviding](/documentation/xcuiautomation/xcuiscreenshotproviding)

## Querying element state

- [waitForExistence(timeout:)](/documentation/xcuiautomation/xcuielement/waitforexistence(timeout:)) Waits the specified amount of time for an element to exist.
- [waitForNonExistence(timeout:)](/documentation/xcuiautomation/xcuielement/waitfornonexistence(timeout:)) Waits the specified amount of time for an element to no longer exist.
- [wait(for:toEqual:timeout:)](/documentation/xcuiautomation/xcuielement/wait(for:toequal:timeout:)) Waits a specified amount of time for a property value to equal a specified value.
- [exists](/documentation/xcuiautomation/xcuielement/exists) Determines if the element exists.
- [isHittable](/documentation/xcuiautomation/xcuielement/ishittable) Determines if the system can compute a hit point for the element.
- [debugDescription](/documentation/xcuiautomation/xcuielement/debugdescription) Provides debugging information about the element.

## Querying descendant elements

- [children(matching:)](/documentation/xcuiautomation/xcuielement/children(matching:)) Returns a query for all direct children of the element matching the type you specify.
- [descendants(matching:)](/documentation/xcuiautomation/xcuielement/descendants(matching:)) Returns a query for all descendants of the element matching the type you specify.

## Typing text

- [typeText(_:)](/documentation/xcuiautomation/xcuielement/typetext(_:)) Types a string into the element.

## Combining keystrokes

- [typeKey(_:modifierFlags:)](/documentation/xcuiautomation/xcuielement/typekey(_:modifierflags:)-6gaoi) Types a single key from the XCUIKeyboardKey enumeration with the specified modifier flags.
- [typeKey(_:modifierFlags:)](/documentation/xcuiautomation/xcuielement/typekey(_:modifierflags:)-9ubn) Types a single key that a string represents with the flags you specify.
- [XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey) Constants to represent keys that have no typewritten equivalent.
- [perform(withKeyModifiers:block:)](/documentation/xcuiautomation/xcuielement/perform(withkeymodifiers:block:)) Executes a block of code while holding a combination keystroke.
- [XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags) Flags for simulating combination keystrokes with keys, such as Control, Option, Shift, and Command.

## Moving the pointer

- [hover()](/documentation/xcuiautomation/xcuielement/hover()) Moves the pointer over the element.

## Clicking

- [click()](/documentation/xcuiautomation/xcuielement/click()) Sends a click event to a hittable point computed for the element.
- [click(forDuration:thenDragTo:)](/documentation/xcuiautomation/xcuielement/click(forduration:thendragto:)) Clicks and holds an element for a duration you specify, and then drags it to another element.
- [click(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)](/documentation/xcuiautomation/xcuielement/click(forduration:thendragto:withvelocity:thenholdforduration:)) Clicks and holds an element for a duration, drags it at a velocity, and holds it over another element for a duration, all of which you specify.
- [doubleClick()](/documentation/xcuiautomation/xcuielement/doubleclick()) Sends a double-click event to a hittable point the system computes for the element.
- [rightClick()](/documentation/xcuiautomation/xcuielement/rightclick()) Sends a Control-click event to a hittable point the system computes for the element.

## Scrolling

- [scroll(byDeltaX:deltaY:)](/documentation/xcuiautomation/xcuielement/scroll(bydeltax:deltay:)) Scrolls the view by the number of x and y pixels you specify.

## Tapping and pressing

- [tap()](/documentation/xcuiautomation/xcuielement/tap()) Sends a tap event to a hittable point the system computes for the element.
- [doubleTap()](/documentation/xcuiautomation/xcuielement/doubletap()) Sends a double-tap event to a hittable point the system computes for the element.
- [press(forDuration:)](/documentation/xcuiautomation/xcuielement/press(forduration:)) Sends a press-and-hold gesture to a hittable point the system computes for the element, holding for the duration you specify.
- [press(forDuration:thenDragTo:)](/documentation/xcuiautomation/xcuielement/press(forduration:thendragto:)) Initiates a press-and-hold gesture, then drags to another element.
- [press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)](/documentation/xcuiautomation/xcuielement/press(forduration:thendragto:withvelocity:thenholdforduration:)) Initiates a press-and-hold gesture, drags to another element at a velocity, and holds for a duration, all of which you specify.

## Tapping multiple times

- [twoFingerTap()](/documentation/xcuiautomation/xcuielement/twofingertap()) Sends a two-finger tap event to a hittable point the system computes for the element.
- [tap(withNumberOfTaps:numberOfTouches:)](/documentation/xcuiautomation/xcuielement/tap(withnumberoftaps:numberoftouches:)) Sends one or more taps with one or more touch points.

## Performing gestures

- [swipeLeft()](/documentation/xcuiautomation/xcuielement/swipeleft()) Sends a swipe-left gesture.
- [swipeLeft(velocity:)](/documentation/xcuiautomation/xcuielement/swipeleft(velocity:)) Sends a swipe-left gesture with a velocity you specify.
- [swipeRight()](/documentation/xcuiautomation/xcuielement/swiperight()) Sends a swipe-right gesture.
- [swipeRight(velocity:)](/documentation/xcuiautomation/xcuielement/swiperight(velocity:)) Sends a swipe-right gesture with a velocity you specify.
- [swipeUp()](/documentation/xcuiautomation/xcuielement/swipeup()) Sends a swipe-up gesture.
- [swipeUp(velocity:)](/documentation/xcuiautomation/xcuielement/swipeup(velocity:)) Sends a swipe-up gesture with a velocity you specify.
- [swipeDown()](/documentation/xcuiautomation/xcuielement/swipedown()) Sends a swipe-down gesture.
- [swipeDown(velocity:)](/documentation/xcuiautomation/xcuielement/swipedown(velocity:)) Sends a swipe-down gesture with a velocity you specify.
- [pinch(withScale:velocity:)](/documentation/xcuiautomation/xcuielement/pinch(withscale:velocity:)) Sends a pinching gesture with two touches.
- [rotate(_:withVelocity:)](/documentation/xcuiautomation/xcuielement/rotate(_:withvelocity:)) Sends a rotation gesture with two touches.
- [XCUIGestureVelocity](/documentation/xcuiautomation/xcuigesturevelocity) A value that describes how fast a gesture moves across the screen, in pixels per second.

## Interacting with sliders

- [normalizedSliderPosition](/documentation/xcuiautomation/xcuielement/normalizedsliderposition) Returns the position of the slider’s indicator as a normalized value.
- [adjust(toNormalizedSliderPosition:)](/documentation/xcuiautomation/xcuielement/adjust(tonormalizedsliderposition:)) Manipulates the UI to change the value the slider displays to a new value, based on a normalized position.

## Interacting with pickers

- [adjust(toPickerWheelValue:)](/documentation/xcuiautomation/xcuielement/adjust(topickerwheelvalue:)) Changes the value that the picker wheel displays.

## Calculating coordinates

- [coordinate(withNormalizedOffset:)](/documentation/xcuiautomation/xcuielement/coordinate(withnormalizedoffset:)) Creates and returns a new coordinate with a normalized offset.

## Supporting types

- [XCUIElement.ElementType](/documentation/xcuiautomation/xcuielement/elementtype) The types of UI elements that you find, inspect, and interact with in a UI test.
- [XCUIElement.SizeClass](/documentation/xcuiautomation/xcuielement/sizeclass) The user interface size classes you can inspect in a UI test.
- [XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename) A set of string constants that serve as keys for storing element attributes in a dictionary.

## Deprecated methods

- [swipeDown(withVelocity:)](/documentation/xcuiautomation/xcuielement/swipedown(withvelocity:)) Sends a swipe-down gesture with a velocity you specify.
- [swipeUp(withVelocity:)](/documentation/xcuiautomation/xcuielement/swipeup(withvelocity:)) Sends a swipe-up gesture with a velocity you specify.
- [swipeLeft(withVelocity:)](/documentation/xcuiautomation/xcuielement/swipeleft(withvelocity:)) Sends a swipe-left gesture with a velocity you specify.
- [swipeRight(withVelocity:)](/documentation/xcuiautomation/xcuielement/swiperight(withvelocity:)) Sends a swipe-right gesture with a velocity you specify.

## UI elements

- [XCUIElementAttributes](/documentation/xcuiautomation/xcuielementattributes) Attributes exposed by UI elements.
- [XCUIElementSnapshot](/documentation/xcuiautomation/xcuielementsnapshot) A set of attributes to express a snapshot of an element’s attributes and descendant user interface hierarchy.
- [XCUIElementSnapshotProviding](/documentation/xcuiautomation/xcuielementsnapshotproviding) A method to capture a snapshot of an element’s attributes and descendant user interface hierarchy.
- [XCUICoordinate](/documentation/xcuiautomation/xcuicoordinate) A location on screen relative to a UI element.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
