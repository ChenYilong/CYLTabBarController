---
title: UIGestureRecognizer
description: The base class for concrete gesture recognizers.
source: https://developer.apple.com/documentation/uikit/uigesturerecognizer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uigesturerecognizer.json
timestamp: 2026-04-14T13:14:50.619Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIGestureRecognizer

**Available on:** iOS 3.2+, iPadOS 3.2+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> The base class for concrete gesture recognizers.

```swift
@MainActor class UIGestureRecognizer
```

## Overview

A *gesture recognizer* decouples the logic for recognizing a sequence of touches (or other input) and acting on that recognition. When one of these objects recognizes a common gesture or, in some cases, a change in the gesture, it sends an action message to each designated target object.

The concrete subclasses of [UIGestureRecognizer](/documentation/uikit/uigesturerecognizer) are the following:

- [UITapGestureRecognizer](/documentation/uikit/uitapgesturerecognizer)
- [UIPinchGestureRecognizer](/documentation/uikit/uipinchgesturerecognizer)
- [UIRotationGestureRecognizer](/documentation/uikit/uirotationgesturerecognizer)
- [UISwipeGestureRecognizer](/documentation/uikit/uiswipegesturerecognizer)
- [UIPanGestureRecognizer](/documentation/uikit/uipangesturerecognizer)
- [UIScreenEdgePanGestureRecognizer](/documentation/uikit/uiscreenedgepangesturerecognizer)
- [UILongPressGestureRecognizer](/documentation/uikit/uilongpressgesturerecognizer)
- [UIHoverGestureRecognizer](/documentation/uikit/uihovergesturerecognizer)

The [UIGestureRecognizer](/documentation/uikit/uigesturerecognizer) class defines a set of common behaviors that can be configured for all concrete gesture recognizers. It can also communicate with its delegate (an object that adopts the [UIGestureRecognizerDelegate](/documentation/uikit/uigesturerecognizerdelegate) protocol), thereby enabling finer-grained customization of some behaviors.

A gesture recognizer operates on touches hit-tested to a specific view and all of that view’s subviews. It thus must be associated with that view. To make that association you must call the [UIView](/documentation/uikit/uiview) method [addGestureRecognizer(_:)](/documentation/uikit/uiview/addgesturerecognizer(_:)). A gesture recognizer doesn’t participate in the view’s responder chain.

A gesture recognizer has one or more target-action pairs associated with it. If there are multiple target-action pairs, they’re discrete, and not cumulative. Recognition of a gesture results in the dispatch of an action message to a target for each of the associated pairs. The action methods invoked must conform to one of the following signatures:

### Swift

```swift
@IBAction func myActionMethod()
@IBAction func myActionMethod(_ sender: UIGestureRecognizer)
```

### Objective-C

```objc
- (IBAction)handleGesture;
- (IBAction)handleGesture:(UIGestureRecognizer *)gestureRecognizer;
```

Methods conforming to the latter signature permit the target in some cases to query the gesture recognizer sending the message for additional information. For example, the target could ask a [UIRotationGestureRecognizer](/documentation/uikit/uirotationgesturerecognizer) object for the angle of rotation (in radians) since the last invocation of the action method for this gesture. Clients of gesture recognizers can also ask for the location of a gesture by calling [location(in:)](/documentation/uikit/uigesturerecognizer/location(in:)) or [location(ofTouch:in:)](/documentation/uikit/uigesturerecognizer/location(oftouch:in:)).

The gesture interpreted by a gesture recognizer can be either discrete or continuous. A discrete gesture, such as a double tap, occurs but once in a multi-touch sequence and results in a single action sent. However, when a gesture recognizer interprets a continuous gesture such as a rotation gesture, it sends an action message for each incremental change until the multi-touch sequence concludes.

A window delivers touch events to a gesture recognizer before it delivers them to the hit-tested view attached to the gesture recognizer. Generally, if a gesture recognizer analyzes the stream of touches in a multi-touch sequence and doesn’t recognize its gesture, the view receives the full complement of touches. If a gesture recognizer recognizes its gesture, the remaining touches for the view are canceled. The usual sequence of actions in gesture recognition follows a path determined by default values of the [cancelsTouchesInView](/documentation/uikit/uigesturerecognizer/cancelstouchesinview), [delaysTouchesBegan](/documentation/uikit/uigesturerecognizer/delaystouchesbegan), [delaysTouchesEnded](/documentation/uikit/uigesturerecognizer/delaystouchesended) properties:

- [cancelsTouchesInView](/documentation/uikit/uigesturerecognizer/cancelstouchesinview) — If a gesture recognizer recognizes its gesture, it unbinds the remaining touches of that gesture from their view (so the window won’t deliver them). The window cancels the previously delivered touches with a ([touchesCancelled(_:with:)](/documentation/uikit/uiresponder/touchescancelled(_:with:))) message. If a gesture recognizer doesn’t recognize its gesture, the view receives all touches in the multi-touch sequence.
- [delaysTouchesBegan](/documentation/uikit/uigesturerecognizer/delaystouchesbegan) — As long as a gesture recognizer, when analyzing touch events, hasn’t failed recognition of its gesture, the window withholds delivery of touch objects in the [UITouch.Phase.began](/documentation/uikit/uitouch/phase-swift.enum/began) phase to the attached view. If the gesture recognizer subsequently recognizes its gesture, the view doesn’t receive these touch objects. If the gesture recognizer doesn’t recognize its gesture, the window delivers these objects in an invocation of the view’s [touchesBegan(_:with:)](/documentation/uikit/uiresponder/touchesbegan(_:with:)) method (and possibly a follow-up [touchesMoved(_:with:)](/documentation/uikit/uiresponder/touchesmoved(_:with:)) invocation to inform it of the touches current location).
- [delaysTouchesEnded](/documentation/uikit/uigesturerecognizer/delaystouchesended) — As long as a gesture recognizer, when analyzing touch events, hasn’t failed recognition of its gesture, the window withholds delivery of touch objects in the [UITouch.Phase.ended](/documentation/uikit/uitouch/phase-swift.enum/ended) phase to the attached view. If the gesture recognizer subsequently recognizes its gesture, the touches are canceled (in a [touchesCancelled(_:with:)](/documentation/uikit/uiresponder/touchescancelled(_:with:)) message). If the gesture recognizer doesn’t recognize its gesture, the window delivers these objects in an invocation of the view’s [touchesEnded(_:with:)](/documentation/uikit/uiresponder/touchesended(_:with:)) method.

Note that “recognize” in the above descriptions doesn’t necessarily equate to a transition to the Recognized state.

### Subclassing notes

You may create a subclass of [UIGestureRecognizer](/documentation/uikit/uigesturerecognizer) that recognizes a distinctive gesture — for example, a “check mark” gesture. If you’re going to create such a concrete gesture recognizer, be sure to import the `UIGestureRecognizerSubclass.h` header file (for Objective-C) or the `UIKit.UIGestureRecognizerSubclass` module (for Swift). This file declares all the methods and properties a subclass must either override, call, or reset.

Gesture recognizers operate within a predefined state machine, transitioning to subsequent states as they handle multi-touch events. The states and their possible transitions differ for continuous and discrete gestures. All gesture recognizers begin a multi-touch sequence in the Possible state ([UIGestureRecognizer.State.possible](/documentation/uikit/uigesturerecognizer/state-swift.enum/possible)). Discrete gestures transition from Possible to either Recognized ([recognized](/documentation/uikit/uigesturerecognizer/state-swift.enum/recognized)) or Failed ([UIGestureRecognizer.State.failed](/documentation/uikit/uigesturerecognizer/state-swift.enum/failed)), depending on whether they successfully interpret the gesture or not. If the gesture recognizer transitions to Recognized, it sends its action message to its target.

For continuous gestures, the state transitions a gesture recognizer might make are more numerous, as indicated in the following sequence:

- Possible —> Began —> [Changed] —> Cancelled
- Possible —> Began —> [Changed] —> Ended

The Changed state is optional and may occur multiple times before the Cancelled or Ended state is reached. The gesture recognizer sends action messages at each state transition. Thus for a continuous gesture such as a pinch, action messages are sent as the two fingers move toward or away from each other. The `enum` constants representing these states are of type [UIGestureRecognizer.State](/documentation/uikit/uigesturerecognizer/state-swift.enum). (Note that the constants for Recognized and Ended states are synonymous.)

Subclasses must set the [state](/documentation/uikit/uigesturerecognizer/state-swift.property) property to the appropriate value when they transition between states.

#### Methods to override

The methods that subclasses must override are described in [Implementing subclasses](/documentation/uikit/uigesturerecognizer#Implementing-subclasses). Subclasses must also periodically reset the [state](/documentation/uikit/uigesturerecognizer/state-swift.property) property (as described above) and may call the [ignore(_:for:)](/documentation/uikit/uigesturerecognizer/ignore(_:for:)-5f685) method.

#### Special considerations

The [state](/documentation/uikit/uigesturerecognizer/state-swift.property) property is declared in `UIGestureRecognizer.h` as being read-only. This property declaration is intended for clients of gesture recognizers. Subclasses of `UIGestureRecognizer` must import the `UIGestureRecognizerSubclass.h` header file (for Objective-C) or the `UIKit.UIGestureRecognizerSubclass` module (for Swift). This file contains a redeclaration of `state` that makes it read-write.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Inherited By

- [UIHoverGestureRecognizer](/documentation/uikit/uihovergesturerecognizer)
- [UILongPressGestureRecognizer](/documentation/uikit/uilongpressgesturerecognizer)
- [UIPanGestureRecognizer](/documentation/uikit/uipangesturerecognizer)
- [UIPinchGestureRecognizer](/documentation/uikit/uipinchgesturerecognizer)
- [UIRotationGestureRecognizer](/documentation/uikit/uirotationgesturerecognizer)
- [UISwipeGestureRecognizer](/documentation/uikit/uiswipegesturerecognizer)
- [UITapGestureRecognizer](/documentation/uikit/uitapgesturerecognizer)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [Sendable](/documentation/Swift/Sendable)

## Initializing a gesture recognizer

- [init(target:action:)](/documentation/uikit/uigesturerecognizer/init(target:action:)) Creates a gesture recognizer with a target and an action selector.
- [init(coder:)](/documentation/uikit/uigesturerecognizer/init(coder:)) Creates a gesture recognizer from data in an unarchiver.
- [init()](/documentation/uikit/uigesturerecognizer/init()) Creates a gesture recognizer.

## Managing gesture-related interactions

- [delegate](/documentation/uikit/uigesturerecognizer/delegate) The delegate of the gesture recognizer.
- [UIGestureRecognizerDelegate](/documentation/uikit/uigesturerecognizerdelegate) A set of methods implemented by the delegate of a gesture recognizer to fine-tune an app’s gesture-recognition behavior.

## Adding and removing targets and actions

- [addTarget(_:action:)](/documentation/uikit/uigesturerecognizer/addtarget(_:action:)) Adds a target and an action to a gesture-recognizer object.
- [removeTarget(_:action:)](/documentation/uikit/uigesturerecognizer/removetarget(_:action:)) Removes a target and an action from a gesture-recognizer object.

## Getting the touches and location of a gesture

- [location(in:)](/documentation/uikit/uigesturerecognizer/location(in:)) Returns the point computed as the location in a given view of the gesture represented by the gesture recognizer.
- [location(ofTouch:in:)](/documentation/uikit/uigesturerecognizer/location(oftouch:in:)) Returns the location of one of the gesture’s touches in the local coordinate system of a given view.
- [numberOfTouches](/documentation/uikit/uigesturerecognizer/numberoftouches) The number of touches involved in the gesture represented by the gesture recognizer.

## Getting the recognizer’s state and view

- [state](/documentation/uikit/uigesturerecognizer/state-swift.property) The current state of the gesture recognizer.
- [UIGestureRecognizer.State](/documentation/uikit/uigesturerecognizer/state-swift.enum) Constants that represent the current state a gesture recognizer is in.
- [view](/documentation/uikit/uigesturerecognizer/view) The view the gesture recognizer is attached to.
- [isEnabled](/documentation/uikit/uigesturerecognizer/isenabled) A Boolean property that indicates whether the gesture recognizer is enabled.
- [buttonMask](/documentation/uikit/uigesturerecognizer/buttonmask) A bit mask of the buttons in the gesture represented by the gesture recognizer.
- [modifierFlags](/documentation/uikit/uigesturerecognizer/modifierflags) The bit mask of modifier flags in the gesture represented by the gesture recognizer.

## Canceling and delaying touches

- [cancelsTouchesInView](/documentation/uikit/uigesturerecognizer/cancelstouchesinview) A Boolean value that determines whether touches are delivered to a view when a gesture is recognized.
- [delaysTouchesBegan](/documentation/uikit/uigesturerecognizer/delaystouchesbegan) A Boolean value that determines whether the gesture recognizer delays sending touches in a begin phase to its view.
- [delaysTouchesEnded](/documentation/uikit/uigesturerecognizer/delaystouchesended) A Boolean value that determines whether the gesture recognizer delays sending touches in an end phase to its view.

## Specifying dependencies between gesture recognizers

- [require(toFail:)](/documentation/uikit/uigesturerecognizer/require(tofail:)) Creates a dependency relationship between the gesture recognizer and another gesture recognizer when the objects are created.

## Recognizing different gestures

- [allowedPressTypes](/documentation/uikit/uigesturerecognizer/allowedpresstypes) An array of press types used to distinguish the type of button press.
- [allowedTouchTypes](/documentation/uikit/uigesturerecognizer/allowedtouchtypes) An array of touch types used to distinguish type of touches.
- [requiresExclusiveTouchType](/documentation/uikit/uigesturerecognizer/requiresexclusivetouchtype) A Boolean value that indicates whether the gesture recognizer considers touches of different types simultaneously.

## Debugging gesture recognizers

- [name](/documentation/uikit/uigesturerecognizer/name) The unique name of the gesture recognizer.

## Implementing subclasses

- [touchesBegan(_:with:)](/documentation/uikit/uigesturerecognizer/touchesbegan(_:with:)) Sent to the gesture recognizer when one or more fingers touch down in the associated view.
- [touchesMoved(_:with:)](/documentation/uikit/uigesturerecognizer/touchesmoved(_:with:)) Sent to the gesture recognizer when one or more fingers move in the associated view.
- [touchesEnded(_:with:)](/documentation/uikit/uigesturerecognizer/touchesended(_:with:)) Sent to the gesture recognizer when one or more fingers lift from the associated view.
- [touchesCancelled(_:with:)](/documentation/uikit/uigesturerecognizer/touchescancelled(_:with:)) Sent to the gesture recognizer when a system event (such as an incoming phone call) cancels a touch event.
- [touchesEstimatedPropertiesUpdated(_:)](/documentation/uikit/uigesturerecognizer/touchesestimatedpropertiesupdated(_:)) Sent to the gesture recognizer when the estimated properties for a touch have changed so that they are no longer estimated, or an update is no longer expected.
- [reset()](/documentation/uikit/uigesturerecognizer/reset()) Overridden to reset internal state when a gesture recognition attempt completes.
- [ignore(_:for:)](/documentation/uikit/uigesturerecognizer/ignore(_:for:)-5f685) Tells the gesture recognizer to ignore a specific touch of the given event.
- [canBePrevented(by:)](/documentation/uikit/uigesturerecognizer/canbeprevented(by:)) Overridden to indicate that the specified gesture recognizer can prevent the receiver from recognizing a gesture.
- [canPrevent(_:)](/documentation/uikit/uigesturerecognizer/canprevent(_:)) Overridden to indicate that the receiver can prevent the specified gesture recognizer from recognizing its gesture.
- [shouldReceive(_:)](/documentation/uikit/uigesturerecognizer/shouldreceive(_:))
- [shouldRequireFailure(of:)](/documentation/uikit/uigesturerecognizer/shouldrequirefailure(of:)) Overridden to indicate that the receiver requires the specified gesture recognizer to fail.
- [shouldBeRequiredToFail(by:)](/documentation/uikit/uigesturerecognizer/shouldberequiredtofail(by:)) Overridden to indicate that the receiver should be required to fail by the specified gesture recognizer.
- [ignore(_:for:)](/documentation/uikit/uigesturerecognizer/ignore(_:for:)-8qqor) Tells the gesture recognizer to ignore a specific press of the given event.
- [pressesBegan(_:with:)](/documentation/uikit/uigesturerecognizer/pressesbegan(_:with:)) Sent to the receiver when a physical button is pressed in the associated view.
- [pressesChanged(_:with:)](/documentation/uikit/uigesturerecognizer/presseschanged(_:with:)) Sent to the receiver when the [force](/documentation/uikit/uipress/force) of the press has changed in the associated view.
- [pressesEnded(_:with:)](/documentation/uikit/uigesturerecognizer/pressesended(_:with:)) Sent to the receiver when a button is released from the associated view.
- [pressesCancelled(_:with:)](/documentation/uikit/uigesturerecognizer/pressescancelled(_:with:)) Sent to the receiver when a system event (such as a low-memory warning) cancels a press event.

## Custom gestures

- [Implementing a custom gesture recognizer](/documentation/uikit/implementing-a-custom-gesture-recognizer) Discover when and how to build your own gesture recognizers.
- [UIGestureRecognizerDelegate](/documentation/uikit/uigesturerecognizerdelegate) A set of methods implemented by the delegate of a gesture recognizer to fine-tune an app’s gesture-recognition behavior.
- [Supporting gesture interaction in your apps](/documentation/uikit/supporting-gesture-interaction-in-your-apps) Enrich your app’s user experience by supporting standard and custom gesture interaction.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
