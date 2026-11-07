---
title: UIControl
description: The base class for controls, which are visual elements that convey a specific action or intention in response to user interactions.
source: https://developer.apple.com/documentation/uikit/uicontrol
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uicontrol.json
timestamp: 2026-06-26T06:39:36.948Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIControl

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> The base class for controls, which are visual elements that convey a specific action or intention in response to user interactions.

```swift
@MainActor class UIControl
```

## Overview

Controls implement elements such as buttons and sliders, which your app can use to facilitate navigation, gather user input, or manipulate content. Controls use the target-action mechanism to report user interactions to your app.

![Examples of UIKit controls.](https://docs-assets.developer.apple.com/published/6b1386718d569d3ca35a66e82a339ecc/media-1965830%402x.png)

You don’t create instances of this class directly. The [UIControl](/documentation/uikit/uicontrol) class is a subclassing point that you extend to implement custom controls. You can also subclass existing control classes to extend or modify their behaviors. For example, you might override the methods of this class to track touch events yourself or to determine when the state of the control changes.

A control’s state determines its appearance and its ability to support user interactions. Controls can be in one of several states, which the [UIControl.State](/documentation/uikit/uicontrol/state-swift.struct) type defines. You can change the state of a control programmatically according to your app’s needs. For example, you might disable a control to prevent the user from interacting with it. User interactions can also change the state of a control.

### Respond to user interaction

The target-action mechanism simplifies the code that you write to use controls in your app. Instead of writing code to track touch events, you write action methods to respond to control-specific events. For example, you might write an action method that responds to changes in the value of a slider. The control handles all the work of tracking incoming touch events and determining when to call your methods.

When adding an action method to a control, you specify both the action method and an object that defines that method to the [addTarget(_:action:for:)](/documentation/uikit/uicontrol/addtarget(_:action:for:)) method. (You can also configure the target and action of a control in Interface Builder.) The target object can be any object, but it’s typically the view controller’s root view that contains the control. If you specify `nil` for the target object, the control searches the responder chain for an object that defines the specified action method.

The signature of an action method takes one of three forms. The `sender` parameter corresponds to the control that calls the action method, and the `event` parameter corresponds to the [UIEvent](/documentation/uikit/uievent) object that triggered the control-related event.

### Swift

```swift
@IBAction func doSomething()
@IBAction func doSomething(sender: UIButton)
@IBAction func doSomething(sender: UIButton, forEvent event: UIEvent)
```

### Objective-C

```objc
- (IBAction)doSomething;
- (IBAction)doSomething:(id)sender;
- (IBAction)doSomething:(id)sender forEvent:(UIEvent*)event;
```

The system calls action methods when the user interacts with the control in specific ways. The [UIControl.Event](/documentation/uikit/uicontrol/event) type defines the types of user interactions that a control can report and those interactions mostly correlate to specific touch events within the control. When configuring a control, you must specify which events trigger the calling of your method. For a button control, you might use the [touchDown](/documentation/uikit/uicontrol/event/touchdown) or [touchUpInside](/documentation/uikit/uicontrol/event/touchupinside) event to trigger calls to your action method. For a slider, you might care only about changes to the slider’s value, so you might choose to attach your action method to [valueChanged](/documentation/uikit/uicontrol/event/valuechanged) events.

When a control-specific event occurs, the control calls any associated action methods immediately. The current [UIApplication](/documentation/uikit/uiapplication) object dispatches action methods and finds an appropriate object to handle the message, following the responder chain, if necessary. For more information about responders and the responder chain, see [Event Handling Guide for UIKit Apps](https://developer.apple.com/library/archive/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/index.html#//apple_ref/doc/uid/TP40009541).

### Configure control attributes in Interface Builder

The following table lists the attributes for instances of the [UIControl](/documentation/uikit/uicontrol) class.

| Attribute | Description |
| --- | --- |
| Alignment | The horizontal and vertical alignment of a control’s content. For controls that contain text or images, such as buttons and text fields, use these attributes to configure the position of that content within the control’s bounds. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) These alignment options apply to the content of a control and not to the control itself. For information about how to align controls with respect to other controls and views, see [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html#//apple_ref/doc/uid/TP40010853). |
| Content | The initial state of the control. Use the checkboxes to configure whether the control is in an enabled, selected, or highlighted state initially. |

### Support localization

Because [UIControl](/documentation/uikit/uicontrol) is an abstract class, you don’t internationalize it specifically. However, you do internationalize the content of subclasses like [UIButton](/documentation/uikit/uibutton). For information about internationalizing a specific control, see the reference for that control.

### Make controls accessible

Controls are accessible by default. To be useful, an accessible user interface element must provide accurate and helpful information about its screen position, name, behavior, value, and type. This is the information VoiceOver speaks to users. Users who are blind or have low vision can rely on VoiceOver to help them use their devices.

Controls support the following accessibility attributes:

- **Label.** A short, localized word or phrase that succinctly describes the control or view, but doesn’t identify the element’s type. Examples are *Add* and *Play*.
- **Traits.** A combination of one or more individual traits, each of which describes a single aspect of an element’s state, behavior, or usage. For example, you might use a combination of the Keyboard Key and the Selected traits to describe an element that behaves like a keyboard key and that’s in a selected state.
- **Hint.** A brief, localized phrase that describes the results of an action on an element. Examples are *Adds a title* and *Opens the shopping list*.
- **Frame.** The frame of the element in screen coordinates, which the `CGRect` structure specifies for an element’s screen location and size.
- **Value.** The current value of an element when the label doesn’t represent the value. For example, the label for a slider might be *Speed*, but its current value might be *50%*.

The `UIControl` class provides default content for the value and frame attributes. Many controls automatically enable additional specific traits as well. You can configure other accessibility attributes programmatically or with the Identity inspector in Interface Builder.

For more information about accessibility attributes, see [Accessibility Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008785).

### Subclassing notes

Subclassing [UIControl](/documentation/uikit/uicontrol) gives you access to the built-in target-action mechanism and simplified event-handling support. You can subclass existing controls and modify their behavior in one of two ways:

- Override the [sendAction(_:to:for:)](/documentation/uikit/uicontrol/sendaction(_:to:for:)) method of an existing subclass to observe or modify the dispatching of action methods to the control’s associated targets. You might use this method to modify the dispatch behavior for the specified object, selector, or event.
- Override the [beginTracking(_:with:)](/documentation/uikit/uicontrol/begintracking(_:with:)), [continueTracking(_:with:)](/documentation/uikit/uicontrol/continuetracking(_:with:)), [endTracking(_:with:)](/documentation/uikit/uicontrol/endtracking(_:with:)), and [cancelTracking(with:)](/documentation/uikit/uicontrol/canceltracking(with:)) methods to track touch events occurring in the control. You can use the tracking information to perform additional actions. Always use these methods to track touch events instead of the methods that the [UIResponder](/documentation/uikit/uiresponder) class defines.

If you subclass [UIControl](/documentation/uikit/uicontrol) directly, your subclass is responsible for setting up and managing your control’s visual appearance. Use the methods for tracking events to update your control’s state and to send an action when the control’s value changes.

## Inherits From

- [UIView](/documentation/uikit/uiview)

## Inherited By

- [UIButton](/documentation/uikit/uibutton)
- [UIColorWell](/documentation/uikit/uicolorwell)
- [UIDatePicker](/documentation/uikit/uidatepicker)
- [UIPageControl](/documentation/uikit/uipagecontrol)
- [UIPasteControl](/documentation/uikit/uipastecontrol)
- [UIRefreshControl](/documentation/uikit/uirefreshcontrol)
- [UISegmentedControl](/documentation/uikit/uisegmentedcontrol)
- [UISlider](/documentation/uikit/uislider)
- [UIStepper](/documentation/uikit/uistepper)
- [UISwitch](/documentation/uikit/uiswitch)
- [UITextField](/documentation/uikit/uitextfield)

## Conforms To

- [CALayerDelegate](/documentation/QuartzCore/CALayerDelegate)
- [CLBodyIdentifiable](/documentation/CoreLocation/CLBodyIdentifiable)
- [CMBodyIdentifiable](/documentation/CoreMotion/CMBodyIdentifiable)
- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIAccessibilityIdentification](/documentation/uikit/uiaccessibilityidentification)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIAppearance](/documentation/uikit/uiappearance)
- [UIAppearanceContainer](/documentation/uikit/uiappearancecontainer)
- [UIContextMenuInteractionDelegate](/documentation/uikit/uicontextmenuinteractiondelegate)
- [UICoordinateSpace](/documentation/uikit/uicoordinatespace)
- [UIDynamicItem](/documentation/uikit/uidynamicitem)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIFocusItem](/documentation/uikit/uifocusitem)
- [UIFocusItemContainer](/documentation/uikit/uifocusitemcontainer)
- [UILargeContentViewerItem](/documentation/uikit/uilargecontentvieweritem)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIPopoverPresentationControllerSourceItem](/documentation/uikit/uipopoverpresentationcontrollersourceitem)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating a control

- [init(frame:primaryAction:)](/documentation/uikit/uicontrol/init(frame:primaryaction:)) Creates a control with the specified frame and primary action.
- [init(frame:)](/documentation/uikit/uicontrol/init(frame:)) Creates a control with the specified frame.
- [init(coder:)](/documentation/uikit/uicontrol/init(coder:)) Creates a control from data in an unarchiver.

## Managing state

- [state](/documentation/uikit/uicontrol/state-swift.property) The state of the control, specified as a bit mask value.
- [UIControl.State](/documentation/uikit/uicontrol/state-swift.struct) Constants describing the state of a control.
- [isEnabled](/documentation/uikit/uicontrol/isenabled) A Boolean value indicating whether the control is in the enabled state.
- [isSelected](/documentation/uikit/uicontrol/isselected) A Boolean value indicating whether the control is in the selected state.
- [isHighlighted](/documentation/uikit/uicontrol/ishighlighted) A Boolean value indicating whether the control draws a highlight.

## Specifying content alignment

- [contentVerticalAlignment](/documentation/uikit/uicontrol/contentverticalalignment-swift.property) The vertical alignment of content within the control’s bounds.
- [UIControl.ContentVerticalAlignment](/documentation/uikit/uicontrol/contentverticalalignment-swift.enum) Constants for specifying the vertical alignment of content (text and images) in a control.
- [contentHorizontalAlignment](/documentation/uikit/uicontrol/contenthorizontalalignment-swift.property) The horizontal alignment of content within the control’s bounds.
- [effectiveContentHorizontalAlignment](/documentation/uikit/uicontrol/effectivecontenthorizontalalignment) The horizontal alignment currently in effect for the control.
- [UIControl.ContentHorizontalAlignment](/documentation/uikit/uicontrol/contenthorizontalalignment-swift.enum) The horizontal alignment of content (text and images) within a control.

## Managing the control’s targets and actions

- [addTarget(_:action:for:)](/documentation/uikit/uicontrol/addtarget(_:action:for:)) Associates a target object and action method with the control.
- [removeTarget(_:action:for:)](/documentation/uikit/uicontrol/removetarget(_:action:for:)) Stops the delivery of events to the specified target object.
- [allTargets](/documentation/uikit/uicontrol/alltargets) Returns all target objects associated with the control.
- [addAction(_:for:)](/documentation/uikit/uicontrol/addaction(_:for:)) Adds the UIAction to a given event. UIActions are uniqued based on their identifier, and subsequent actions with the same identifier replace previously added actions. You may add multiple UIActions for corresponding controlEvents, and you may add the same action to multiple controlEvents.
- [removeAction(_:for:)](/documentation/uikit/uicontrol/removeaction(_:for:)) Removes the action from the set of passed control events.
- [removeAction(identifiedBy:for:)](/documentation/uikit/uicontrol/removeaction(identifiedby:for:)) Removes the action with the provided identifier from the set of passed control events.
- [actions(forTarget:forControlEvent:)](/documentation/uikit/uicontrol/actions(fortarget:forcontrolevent:)) Returns the actions performed on a target object when the specified event occurs.
- [allControlEvents](/documentation/uikit/uicontrol/allcontrolevents) Returns the events for which the control has associated actions.
- [enumerateEventHandlers(_:)](/documentation/uikit/uicontrol/enumerateeventhandlers(_:))
- [UIControl.Event](/documentation/uikit/uicontrol/event) Constants describing the types of events possible for controls.

## Triggering actions

- [performPrimaryAction()](/documentation/uikit/uicontrol/performprimaryaction()) Calls the method associated with the control’s primary action.
- [sendAction(_:)](/documentation/uikit/uicontrol/sendaction(_:)) Like -sendAction:to:forEvent:, this method is called by -sendActionsForControlEvents:. You may override this method to observe or modify behavior. If you override this method, you should call super precisely once to dispatch the action, or not call super to suppress sending that action.
- [sendAction(_:to:for:)](/documentation/uikit/uicontrol/sendaction(_:to:for:)) Calls the specified action method.
- [sendActions(for:)](/documentation/uikit/uicontrol/sendactions(for:)) Calls the action methods associated with the specified events.

## Tracking touches and redrawing controls

- [beginTracking(_:with:)](/documentation/uikit/uicontrol/begintracking(_:with:)) Notifies the control when a touch event enters the control’s bounds.
- [continueTracking(_:with:)](/documentation/uikit/uicontrol/continuetracking(_:with:)) Notifies the control when a touch event for the control updates.
- [endTracking(_:with:)](/documentation/uikit/uicontrol/endtracking(_:with:)) Notifies the control when a touch event associated with the control ends.
- [cancelTracking(with:)](/documentation/uikit/uicontrol/canceltracking(with:)) Notifies the control to cancel tracking related to the specified event.
- [isTracking](/documentation/uikit/uicontrol/istracking) A Boolean value that indicates whether the control is currently tracking touch events.
- [isTouchInside](/documentation/uikit/uicontrol/istouchinside) A Boolean value that indicates whether a tracked touch event is currently inside the control’s bounds.

## Managing context menus

- [Adding context menus in your app](/documentation/uikit/adding-context-menus-in-your-app) Provide quick access to useful actions by adding context menus to your iOS app.
- [contextMenuInteraction](/documentation/uikit/uicontrol/contextmenuinteraction) A context menu interaction for the control.
- [isContextMenuInteractionEnabled](/documentation/uikit/uicontrol/iscontextmenuinteractionenabled) A Boolean value that determines whether the control enables its context menu interaction.
- [showsMenuAsPrimaryAction](/documentation/uikit/uicontrol/showsmenuasprimaryaction) A Boolean value that determines whether the context menu interaction is the control’s primary action.
- [contextMenuInteraction(_:configurationForMenuAtLocation:)](/documentation/uikit/uicontrol/contextmenuinteraction(_:configurationformenuatlocation:))
- [contextMenuInteraction(_:previewForDismissingMenuWithConfiguration:)](/documentation/uikit/uicontrol/contextmenuinteraction(_:previewfordismissingmenuwithconfiguration:))
- [contextMenuInteraction(_:previewForHighlightingMenuWithConfiguration:)](/documentation/uikit/uicontrol/contextmenuinteraction(_:previewforhighlightingmenuwithconfiguration:))
- [contextMenuInteraction(_:willDisplayMenuFor:animator:)](/documentation/uikit/uicontrol/contextmenuinteraction(_:willdisplaymenufor:animator:))
- [contextMenuInteraction(_:willEndFor:animator:)](/documentation/uikit/uicontrol/contextmenuinteraction(_:willendfor:animator:))
- [menuAttachmentPoint(for:)](/documentation/uikit/uicontrol/menuattachmentpoint(for:)) Return a point in this control’s coordinate space to which to attach the given configuration’s menu.

## Showing tooltips

- [toolTip](/documentation/uikit/uicontrol/tooltip) The default text to display in the control’s tooltip.
- [toolTipInteraction](/documentation/uikit/uicontrol/tooltipinteraction) The tooltip interaction associated with the control.

## Inspecting animation status

- [isSymbolAnimationEnabled](/documentation/uikit/uicontrol/issymbolanimationenabled) A Boolean value that indicates whether symbol effects animate.

## Controls

- [Responding to control-based events using target-action](/documentation/uikit/responding-to-control-based-events-using-target-action) Handle user input by connecting buttons, sliders, and other controls to your app’s code using the target-action design pattern.
- [UIButton](/documentation/uikit/uibutton) A control that executes your custom code in response to user interactions.
- [UIColorWell](/documentation/uikit/uicolorwell) A control that displays a color picker.
- [UIDatePicker](/documentation/uikit/uidatepicker) A control for inputting date and time values.
- [UIPageControl](/documentation/uikit/uipagecontrol) A control that displays a horizontal series of dots, each of which corresponds to a page in the app’s document or other data-model entity.
- [UISegmentedControl](/documentation/uikit/uisegmentedcontrol) A horizontal control that consists of multiple segments, each segment functioning as a discrete button.
- [UISlider](/documentation/uikit/uislider) A control for selecting a single value from a continuous range of values.
- [UIStepper](/documentation/uikit/uistepper) A control for incrementing or decrementing a value.
- [UISwitch](/documentation/uikit/uiswitch) A control that offers a binary choice, such as on/off.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
