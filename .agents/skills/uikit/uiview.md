---
title: UIView
description: An object that manages the content for a rectangular area on the screen.
source: https://developer.apple.com/documentation/uikit/uiview
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiview.json
timestamp: 2026-06-26T06:39:37.106Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIView

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> An object that manages the content for a rectangular area on the screen.

```swift
@MainActor class UIView
```

## Overview

Views are the fundamental building blocks of your app’s user interface, and the [UIView](/documentation/uikit/uiview) class defines the behaviors that are common to all views. A view object renders content within its bounds rectangle, and handles any interactions with that content. The [UIView](/documentation/uikit/uiview) class is a concrete class that you can instantiate and use to display a fixed background color. You can also subclass it to draw more sophisticated content. To display labels, images, buttons, and other interface elements commonly found in apps, use the view subclasses that the UIKit framework provides rather than trying to define your own.

Because view objects are the main way your application interacts with the user, they have a number of responsibilities. Here are just a few:

- Drawing and animation
   
   - Views draw content in their rectangular area using UIKit or Core Graphics.
   - You can animate some view properties to new values.
- Layout and subview management
   
   - Views may contain zero or more subviews.
   - Views can adjust the size and position of their subviews.
   - Use Auto Layout to define the rules for resizing and repositioning your views in response to changes in the view hierarchy.
- Event handling
   
   - A view is a subclass of [UIResponder](/documentation/uikit/uiresponder) and can respond to touches and other types of events.
   - Views can install gesture recognizers to handle common gestures.

Views can nest inside other views to create view hierarchies, which offer a convenient way to organize related content. Nesting a view creates a parent-child relationship between the nested child view (known as the *subview*) and the parent (known as the *superview*). A parent view may contain any number of subviews, but each subview has only one superview. By default, when a subview’s visible area extends outside of the bounds of its superview, no clipping of the subview’s content occurs. Use the [clipsToBounds](/documentation/uikit/uiview/clipstobounds) property to change that behavior.

The [frame](/documentation/uikit/uiview/frame) and [bounds](/documentation/uikit/uiview/bounds) properties define the geometry of each view. The [frame](/documentation/uikit/uiview/frame) property defines the origin and dimensions of the view in the coordinate system of its superview. The [bounds](/documentation/uikit/uiview/bounds) property defines the internal dimensions of the view as it sees them, and its use is almost exclusive to custom drawing code. The center property provides a convenient way to reposition a view without changing its [frame](/documentation/uikit/uiview/frame) or [bounds](/documentation/uikit/uiview/bounds) properties directly.

### Create a view

Normally, you create views in your storyboards by dragging them from the library to your canvas. You can also create views programmatically. When creating a view, you typically specify its initial size and position relative to its future superview. For example, the following example creates a view and places its top-left corner at the point (10, 10) in the superview’s coordinate system (once it is added to that superview).

### Swift

```swift
let rect = CGRect(x: 10, y: 10, width: 100, height: 100)
let myView = UIView(frame: rect)
```

### Objective-C

```objc
CGRect  viewRect = CGRectMake(10, 10, 100, 100);
UIView* myView = [[UIView alloc] initWithFrame:viewRect];
```

To add a subview to another view, call the [addSubview(_:)](/documentation/uikit/uiview/addsubview(_:)) method on the superview. You may add any number of subviews to a view, and sibling views may overlap each other without any issues in iOS. Each call to the [addSubview(_:)](/documentation/uikit/uiview/addsubview(_:)) method places the new view on top of all other siblings. You can specify the relative z-order of subview by adding it using the [insertSubview(_:aboveSubview:)](/documentation/uikit/uiview/insertsubview(_:abovesubview:)) and [insertSubview(_:belowSubview:)](/documentation/uikit/uiview/insertsubview(_:belowsubview:)) methods. You can also exchange the position of already added subviews using the [exchangeSubview(at:withSubviewAt:)](/documentation/uikit/uiview/exchangesubview(at:withsubviewat:)) method.

After creating a view, create Auto Layout rules to govern how the size and position of the view change in response to changes in the rest of the view hierarchy.

### Draw views

View drawing occurs on an as-needed basis. When a view is first shown, or when all or part of it becomes visible due to layout changes, the system asks the view to draw its contents. For views that contain custom content using UIKit or Core Graphics, the system calls the view’s [draw(_:)](/documentation/uikit/uiview/draw(_:)) method. Your implementation of this method is responsible for drawing the view’s content into the current graphics context, which is set up by the system automatically prior to calling this method. This creates a static visual representation of your view’s content that can then be displayed on the screen.

When the actual content of your view changes, it’s your responsibility to notify the system that your view needs to be redrawn. You do this by calling your view’s [setNeedsDisplay()](/documentation/uikit/uiview/setneedsdisplay()) or [setNeedsDisplay(_:)](/documentation/uikit/uiview/setneedsdisplay(_:)) method of the view. These methods let the system know that it should update the view during the next drawing cycle. Because it waits until the next drawing cycle to update the view, you can call these methods on multiple views to update them at the same time.

### Animate views

Changes to several view properties can be animated — that is, changing the property creates an animation starting at the current value and ending at the new value that you specify. The following properties of the [UIView](/documentation/uikit/uiview) class are animatable:

- [frame](/documentation/uikit/uiview/frame)
- [bounds](/documentation/uikit/uiview/bounds)
- [center](/documentation/uikit/uiview/center)
- [transform](/documentation/uikit/uiview/transform)
- [alpha](/documentation/uikit/uiview/alpha)
- [backgroundColor](/documentation/uikit/uiview/backgroundcolor)

To animate your changes, create a [UIViewPropertyAnimator](/documentation/uikit/uiviewpropertyanimator) object and use its handler block to change the values of your view’s properties. The [UIViewPropertyAnimator](/documentation/uikit/uiviewpropertyanimator) class lets you specify the duration and timing of your animations, but it performs the actual animations. You can pause a property-based animator that’s currently running to interrupt the animation and drive it interactively. For more information, see [UIViewPropertyAnimator](/documentation/uikit/uiviewpropertyanimator).

### Threading considerations

Manipulations to your app’s user interface must occur on the main thread. Thus, you should always call the methods of the [UIView](/documentation/uikit/uiview) class from code running in the main thread of your app. The only time this may not be strictly necessary is when creating the view object itself, but all other manipulations should occur on the main thread.

### Subclassing notes

The [UIView](/documentation/uikit/uiview) class is a key subclassing point for visual content that also requires user interactions. Although there are many good reasons to subclass [UIView](/documentation/uikit/uiview), it is recommended that you do so only when the basic [UIView](/documentation/uikit/uiview) class or the standard system views do not provide the capabilities that you need. Subclassing requires more work on your part to implement the view and to tune its performance.

For information about ways to avoid subclassing, see [Alternatives to subclassing](/documentation/uikit/uiview#Alternatives-to-subclassing).

#### Methods to override

When subclassing [UIView](/documentation/uikit/uiview), there are only a handful of methods you should override and many methods that you might override depending on your needs. Because [UIView](/documentation/uikit/uiview) is a highly configurable class, there are also many ways to implement sophisticated view behaviors without overriding custom methods, which are discussed in the Alternatives to Subclassing section. In the meantime, the following list includes the methods you might consider overriding in your [UIView](/documentation/uikit/uiview) subclasses:

- Initialization:
   
   - [init(frame:)](/documentation/uikit/uiview/init(frame:)) - It is recommended that you implement this method. You can also implement custom initialization methods in addition to, or instead of, this method.
   - [init(coder:)](/documentation/uikit/uiview/init(coder:)) - Implement this method if you load your view from storyboards or nib files and your view requires custom initialization.
   - [layerClass](/documentation/uikit/uiview/layerclass) Use this property only if you want your view to use a different Core Animation layer for its backing store. For example, if your view uses tiling to display a large scrollable area, you might want to set the property to the [CATiledLayer](/documentation/QuartzCore/CATiledLayer) class.
- Drawing and printing:
   
   - [draw(_:)](/documentation/uikit/uiview/draw(_:)) - Implement this method if your view draws custom content. If your view does not do any custom drawing, avoid overriding this method.
   - [draw(_:for:)](/documentation/uikit/uiview/draw(_:for:)) - Implement this method only if you want to draw your view’s content differently during printing.
- Layout and Constraints:
   
   - [requiresConstraintBasedLayout](/documentation/uikit/uiview/requiresconstraintbasedlayout) Use this property if your view class requires constraints to work properly.
   - [updateConstraints()](/documentation/uikit/uiview/updateconstraints()) - Implement this method if your view needs to create custom constraints between your subviews.
   - [alignmentRect(forFrame:)](/documentation/uikit/uiview/alignmentrect(forframe:)), [frame(forAlignmentRect:)](/documentation/uikit/uiview/frame(foralignmentrect:)) - Implement these methods to override how your views are aligned to other views.
   - [didAddSubview(_:)](/documentation/uikit/uiview/didaddsubview(_:)), [willRemoveSubview(_:)](/documentation/uikit/uiview/willremovesubview(_:)) - Implement these methods as needed to track the additions and removals of subviews.
   - [willMove(toSuperview:)](/documentation/uikit/uiview/willmove(tosuperview:)), [didMoveToSuperview()](/documentation/uikit/uiview/didmovetosuperview()) - Implement these methods as needed to track the movement of the current view in your view hierarchy.
- Event Handling:
   
   - [gestureRecognizerShouldBegin(_:)](/documentation/uikit/uiview/gesturerecognizershouldbegin(_:)) - Implement this method if your view handles touch events directly and might want to prevent attached gesture recognizers from triggering additional actions.
   - [touchesBegan(_:with:)](/documentation/uikit/uiresponder/touchesbegan(_:with:)), [touchesMoved(_:with:)](/documentation/uikit/uiresponder/touchesmoved(_:with:)), [touchesEnded(_:with:)](/documentation/uikit/uiresponder/touchesended(_:with:)), [touchesCancelled(_:with:)](/documentation/uikit/uiresponder/touchescancelled(_:with:)) - Implement these methods if you need to handle touch events directly. (For gesture-based input, use gesture recognizers.)

#### Alternatives to subclassing

Many view behaviors can be configured without the need for subclassing. Before you start overriding methods, consider whether modifying the following properties or behaviors would provide the behavior you need.

- [addConstraint(_:)](/documentation/uikit/uiview/addconstraint(_:)) - Define automatic layout behavior for the view and its subviews.
- [autoresizingMask](/documentation/uikit/uiview/autoresizingmask-swift.property) - Provides automatic layout behavior when the superview’s frame changes. These behaviors can be combined with constraints.
- [contentMode](/documentation/uikit/uiview/contentmode-swift.property) - Provides layout behavior for the view’s content, as opposed to the [frame](/documentation/uikit/uiview/frame) of the view. This property also affects how the content is scaled to fit the view and whether it is cached or redrawn.
- [isHidden](/documentation/uikit/uiview/ishidden) or [alpha](/documentation/uikit/uiview/alpha) - Change the transparency of the view as a whole rather than hiding or applying alpha to your view’s rendered content.
- [backgroundColor](/documentation/uikit/uiview/backgroundcolor) - Set the view’s color rather than drawing that color yourself.
- Subviews - Rather than draw your content using a [draw(_:)](/documentation/uikit/uiview/draw(_:)) method, embed image and label subviews with the content you want to present.
- Gesture recognizers - Rather than subclass to intercept and handle touch events yourself, you can use gesture recognizers to send an action to a target object.
- Animations - Use the built-in animation support rather than trying to animate changes yourself. The animation support provided by Core Animation is fast and easy to use.
- Image-based backgrounds - For views that display relatively static content, consider using a [UIImageView](/documentation/uikit/uiimageview) object with gesture recognizers instead of subclassing and drawing the image yourself. Alternatively, you can also use a generic [UIView](/documentation/uikit/uiview) object and assign your image as the content of the view’s [CALayer](/documentation/QuartzCore/CALayer) object.

Animations are another way to make visible changes to a view without requiring you to subclass and implement complex drawing code. Many properties of the [UIView](/documentation/uikit/uiview) class are animatable, which means changes to those properties can trigger system-generated animations. Starting animations requires as little as one line of code to indicate that any changes that follow should be animated. For more information about animation support for views, see [Animate views](/documentation/uikit/uiview#Animate-views).

### Sensor coordinate orientation

`UIView` conforms to [CLBodyIdentifiable](/documentation/CoreLocation/CLBodyIdentifiable) and [CMBodyIdentifiable](/documentation/CoreMotion/CMBodyIdentifiable), informing Core Location and Core Motion how the app’s UI and this view are situated with respect to reference physical orientations. They use this information to transform the sensor values they provide, such as compass headings and device motion data, so those values align with your UI’s actual orientation. Without this association, Core Location and Core Motion report sensor values relative to the device’s physical orientation, which can produce unexpected results, such as a navigation map that appears rotated.

To use this approach, set any view as the body on a `CLLocationManager` or `CMMotionManager` instance. The system tracks orientation changes through the view and applies the correct transformation automatically.

```swift
let motionManager = CMMotionManager()

override func viewDidLoad() {
    super.viewDidLoad()
    motionManager.deviceMotionBody = view
}
```

## Inherits From

- [UIResponder](/documentation/uikit/uiresponder)

## Inherited By

- [UIActionSheet](/documentation/uikit/uiactionsheet)
- [UIActivityIndicatorView](/documentation/uikit/uiactivityindicatorview)
- [UIAlertView](/documentation/uikit/uialertview)
- [UIBackgroundExtensionView](/documentation/uikit/uibackgroundextensionview)
- [UICalendarView](/documentation/uikit/uicalendarview)
- [UICollectionReusableView](/documentation/uikit/uicollectionreusableview)
- [UIContentUnavailableView](/documentation/uikit/uicontentunavailableview)
- [UIControl](/documentation/uikit/uicontrol)
- [UIEventAttributionView](/documentation/uikit/uieventattributionview)
- [UIImageView](/documentation/uikit/uiimageview)
- [UIInputView](/documentation/uikit/uiinputview)
- [UILabel](/documentation/uikit/uilabel)
- [UIListContentView](/documentation/uikit/uilistcontentview)
- [UINavigationBar](/documentation/uikit/uinavigationbar)
- [UIPickerView](/documentation/uikit/uipickerview)
- [UIPopoverBackgroundView](/documentation/uikit/uipopoverbackgroundview)
- [UIProgressView](/documentation/uikit/uiprogressview)
- [UIScrollView](/documentation/uikit/uiscrollview)
- [UISearchBar](/documentation/uikit/uisearchbar)
- [UIStackView](/documentation/uikit/uistackview)
- [UIStandardTextCursorView](/documentation/uikit/uistandardtextcursorview)
- [UITabBar](/documentation/uikit/uitabbar)
- [UITableViewCell](/documentation/uikit/uitableviewcell)
- [UITableViewHeaderFooterView](/documentation/uikit/uitableviewheaderfooterview)
- [UIToolbar](/documentation/uikit/uitoolbar)
- [UIVisualEffectView](/documentation/uikit/uivisualeffectview)
- [UIWebView](/documentation/uikit/uiwebview)
- [UIWindow](/documentation/uikit/uiwindow)

## Conforms To

- [AppEntityAnnotatable](/documentation/AppIntents/AppEntityAnnotatable)
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

## Creating a view object

- [init(frame:)](/documentation/uikit/uiview/init(frame:)) Creates a view with the specified frame rectangle.
- [init(coder:)](/documentation/uikit/uiview/init(coder:)) Creates a view from data in an unarchiver.

## Configuring a view’s visual appearance

- [backgroundColor](/documentation/uikit/uiview/backgroundcolor) The view’s background color.
- [isHidden](/documentation/uikit/uiview/ishidden) A Boolean value that determines whether the view is hidden.
- [alpha](/documentation/uikit/uiview/alpha) The view’s alpha value.
- [isOpaque](/documentation/uikit/uiview/isopaque) A Boolean value that determines whether the view is opaque.
- [tintColor](/documentation/uikit/uiview/tintcolor) The first nondefault tint color value in the view’s hierarchy, ascending from and starting with the view itself.
- [tintAdjustmentMode](/documentation/uikit/uiview/tintadjustmentmode-swift.property) The first non-default tint adjustment mode value in the view’s hierarchy, ascending from and starting with the view itself.
- [clipsToBounds](/documentation/uikit/uiview/clipstobounds) A Boolean value that determines whether subviews are confined to the bounds of the view.
- [clearsContextBeforeDrawing](/documentation/uikit/uiview/clearscontextbeforedrawing) A Boolean value that determines whether the view’s bounds should be automatically cleared before drawing.
- [mask](/documentation/uikit/uiview/mask) An optional view whose alpha channel is used to mask a view’s content.
- [layerClass](/documentation/uikit/uiview/layerclass) Returns the class used to create the layer for instances of this class.
- [layer](/documentation/uikit/uiview/layer) The view’s Core Animation layer to use for rendering.

## Configuring a view’s corners

- [cornerConfiguration](/documentation/uikit/uiview/cornerconfiguration-7l0ja) A configuration that defines the corners of the view.
- [UICornerConfiguration](/documentation/uikit/uicornerconfiguration-swift.struct) A configuration that defines how corner radii are mapped to the corners of a rectangle.
- [UICornerRadius](/documentation/uikit/uicornerradius-swift.struct) A type that represents the radius the system uses to round a corner.
- [effectiveRadius(corner:)](/documentation/uikit/uiview/effectiveradius(corner:)) Returns the effective radius for the corner you provide, calculated using the view’s current corner configuration.

## Configuring the event-related behavior

- [isUserInteractionEnabled](/documentation/uikit/uiview/isuserinteractionenabled) A Boolean value that determines whether user events are ignored and removed from the event queue.
- [isMultipleTouchEnabled](/documentation/uikit/uiview/ismultipletouchenabled) A Boolean value that indicates whether the view receives more than one touch at a time.
- [isExclusiveTouch](/documentation/uikit/uiview/isexclusivetouch) A Boolean value that indicates whether the receiver handles touch events exclusively.

## Configuring the bounds and frame rectangles

- [frame](/documentation/uikit/uiview/frame) The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
- [bounds](/documentation/uikit/uiview/bounds) The bounds rectangle, which describes the view’s location and size in its own coordinate system.
- [center](/documentation/uikit/uiview/center) The center point of the view’s frame rectangle.
- [transform](/documentation/uikit/uiview/transform) Specifies the transform applied to the view, relative to the center of its bounds.
- [transform3D](/documentation/uikit/uiview/transform3d) The three-dimensional transform to apply to the view.
- [anchorPoint](/documentation/uikit/uiview/anchorpoint) The anchor point of the view’s bounds rectangle.

## Managing the view hierarchy

- [superview](/documentation/uikit/uiview/superview) The receiver’s superview, or `nil` if it has none.
- [subviews](/documentation/uikit/uiview/subviews) The receiver’s immediate subviews.
- [window](/documentation/uikit/uiview/window) The receiver’s window object, or `nil` if it has none.
- [addSubview(_:)](/documentation/uikit/uiview/addsubview(_:)) Adds a view to the end of the receiver’s list of subviews.
- [bringSubviewToFront(_:)](/documentation/uikit/uiview/bringsubviewtofront(_:)) Moves the specified subview so that it appears on top of its siblings.
- [sendSubviewToBack(_:)](/documentation/uikit/uiview/sendsubviewtoback(_:)) Moves the specified subview so that it appears behind its siblings.
- [removeFromSuperview()](/documentation/uikit/uiview/removefromsuperview()) Unlinks the view from its superview and its window, and removes it from the responder chain.
- [insertSubview(_:at:)](/documentation/uikit/uiview/insertsubview(_:at:)) Inserts a subview at the specified index.
- [insertSubview(_:aboveSubview:)](/documentation/uikit/uiview/insertsubview(_:abovesubview:)) Inserts a view above another view in the view hierarchy.
- [insertSubview(_:belowSubview:)](/documentation/uikit/uiview/insertsubview(_:belowsubview:)) Inserts a view below another view in the view hierarchy.
- [exchangeSubview(at:withSubviewAt:)](/documentation/uikit/uiview/exchangesubview(at:withsubviewat:)) Exchanges the subviews at the specified indices.
- [isDescendant(of:)](/documentation/uikit/uiview/isdescendant(of:)) Returns a Boolean value indicating whether the receiver is a subview of a given view or identical to that view.

## Observing view-related changes

- [didAddSubview(_:)](/documentation/uikit/uiview/didaddsubview(_:)) Tells the view that a subview was added.
- [willRemoveSubview(_:)](/documentation/uikit/uiview/willremovesubview(_:)) Tells the view that a subview is about to be removed.
- [willMove(toSuperview:)](/documentation/uikit/uiview/willmove(tosuperview:)) Tells the view that its superview is about to change to the specified superview.
- [didMoveToSuperview()](/documentation/uikit/uiview/didmovetosuperview()) Tells the view that its superview changed.
- [willMove(toWindow:)](/documentation/uikit/uiview/willmove(towindow:)) Tells the view that its window object is about to change.
- [didMoveToWindow()](/documentation/uikit/uiview/didmovetowindow()) Tells the view that its window object changed.

## Observing trait changes

- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94) A type that calls your code in reaction to changes in the trait environment.

## Requesting trait updates

- [updateTraitsIfNeeded()](/documentation/uikit/uiview/updatetraitsifneeded()) Forces an immediate trait update for this view (and its view controller, if applicable) and any subviews, including any view controllers or views in its subtree. Any trait change callbacks are sent synchronously.

## Overriding trait values

- [traitOverrides](/documentation/uikit/uiview/traitoverrides-fd9z)
- [UITraitOverrides](/documentation/uikit/uitraitoverrides-swift.struct) A mutable container of traits you use to set trait changes for an object and its descendants.

## Configuring content margins

- [Positioning content within layout margins](/documentation/uikit/positioning-content-within-layout-margins) Position views so that they aren’t crowded by other content.
- [directionalLayoutMargins](/documentation/uikit/uiview/directionallayoutmargins) The default spacing to use when laying out content in a view, taking into account the current language direction.
- [layoutMargins](/documentation/uikit/uiview/layoutmargins) The default spacing to use when laying out content in the view.
- [preservesSuperviewLayoutMargins](/documentation/uikit/uiview/preservessuperviewlayoutmargins) A Boolean value indicating whether the current view also respects the margins of its superview.
- [layoutMarginsDidChange()](/documentation/uikit/uiview/layoutmarginsdidchange()) Notifies the view that the layout margins changed.

## Getting the safe area

- [Positioning content relative to the safe area](/documentation/uikit/positioning-content-relative-to-the-safe-area) Position views so that they aren’t obstructed by other content.
- [safeAreaInsets](/documentation/uikit/uiview/safeareainsets) The insets that you use to determine the safe area for this view.
- [safeAreaLayoutGuide](/documentation/uikit/uiview/safearealayoutguide) The layout guide representing the portion of your view that is unobscured by bars and other content.
- [safeAreaInsetsDidChange()](/documentation/uikit/uiview/safeareainsetsdidchange()) Called when the safe area of the view changes.
- [insetsLayoutMarginsFromSafeArea](/documentation/uikit/uiview/insetslayoutmarginsfromsafearea) A Boolean value indicating whether the view’s layout margins are updated automatically to reflect the safe area.

## Managing the view’s constraints

- [constraints](/documentation/uikit/uiview/constraints) The constraints held by the view.
- [addConstraint(_:)](/documentation/uikit/uiview/addconstraint(_:)) Adds a constraint on the layout of the receiving view or its subviews.
- [addConstraints(_:)](/documentation/uikit/uiview/addconstraints(_:)) Adds multiple constraints on the layout of the receiving view or its subviews.
- [removeConstraint(_:)](/documentation/uikit/uiview/removeconstraint(_:)) Removes the specified constraint from the view.
- [removeConstraints(_:)](/documentation/uikit/uiview/removeconstraints(_:)) Removes the specified constraints from the view.

## Creating constraints using layout anchors

- [bottomAnchor](/documentation/uikit/uiview/bottomanchor) A layout anchor representing the bottom edge of the view’s frame.
- [centerXAnchor](/documentation/uikit/uiview/centerxanchor) A layout anchor representing the horizontal center of the view’s frame.
- [centerYAnchor](/documentation/uikit/uiview/centeryanchor) A layout anchor representing the vertical center of the view’s frame.
- [firstBaselineAnchor](/documentation/uikit/uiview/firstbaselineanchor) A layout anchor representing the baseline for the topmost line of text in the view.
- [heightAnchor](/documentation/uikit/uiview/heightanchor) A layout anchor representing the height of the view’s frame.
- [lastBaselineAnchor](/documentation/uikit/uiview/lastbaselineanchor) A layout anchor representing the baseline for the bottommost line of text in the view.
- [leadingAnchor](/documentation/uikit/uiview/leadinganchor) A layout anchor representing the leading edge of the view’s frame.
- [leftAnchor](/documentation/uikit/uiview/leftanchor) A layout anchor representing the left edge of the view’s frame.
- [rightAnchor](/documentation/uikit/uiview/rightanchor) A layout anchor representing the right edge of the view’s frame.
- [topAnchor](/documentation/uikit/uiview/topanchor) A layout anchor representing the top edge of the view’s frame.
- [trailingAnchor](/documentation/uikit/uiview/trailinganchor) A layout anchor representing the trailing edge of the view’s frame.
- [widthAnchor](/documentation/uikit/uiview/widthanchor) A layout anchor representing the width of the view’s frame.

## Working with layout guides

- [addLayoutGuide(_:)](/documentation/uikit/uiview/addlayoutguide(_:)) Adds the specified layout guide to the view.
- [layoutGuides](/documentation/uikit/uiview/layoutguides) The array of layout guide objects owned by this view.
- [layoutMarginsGuide](/documentation/uikit/uiview/layoutmarginsguide) A layout guide representing the view’s margins.
- [readableContentGuide](/documentation/uikit/uiview/readablecontentguide) A layout guide representing an area with a readable width within the view.
- [removeLayoutGuide(_:)](/documentation/uikit/uiview/removelayoutguide(_:)) Removes the specified layout guide from the view.

## Measuring in Auto Layout

- [systemLayoutSizeFitting(_:)](/documentation/uikit/uiview/systemlayoutsizefitting(_:)) Returns the optimal size of the view based on its current constraints.
- [systemLayoutSizeFitting(_:withHorizontalFittingPriority:verticalFittingPriority:)](/documentation/uikit/uiview/systemlayoutsizefitting(_:withhorizontalfittingpriority:verticalfittingpriority:)) Returns the optimal size of the view based on its constraints and the specified fitting priorities.
- [intrinsicContentSize](/documentation/uikit/uiview/intrinsiccontentsize) The natural size for the receiving view, considering only properties of the view itself.
- [invalidateIntrinsicContentSize()](/documentation/uikit/uiview/invalidateintrinsiccontentsize()) Invalidates the view’s intrinsic content size.
- [contentCompressionResistancePriority(for:)](/documentation/uikit/uiview/contentcompressionresistancepriority(for:)) Returns the priority with which a view resists being made smaller than its intrinsic size.
- [setContentCompressionResistancePriority(_:for:)](/documentation/uikit/uiview/setcontentcompressionresistancepriority(_:for:)) Sets the priority with which a view resists being made smaller than its intrinsic size.
- [contentHuggingPriority(for:)](/documentation/uikit/uiview/contenthuggingpriority(for:)) Returns the priority with which a view resists being made larger than its intrinsic size.
- [setContentHuggingPriority(_:for:)](/documentation/uikit/uiview/setcontenthuggingpriority(_:for:)) Sets the priority with which a view resists being made larger than its intrinsic size.

## Aligning views in Auto Layout

- [alignmentRect(forFrame:)](/documentation/uikit/uiview/alignmentrect(forframe:)) Returns the view’s alignment rectangle for a given frame.
- [frame(forAlignmentRect:)](/documentation/uikit/uiview/frame(foralignmentrect:)) Returns the view’s frame for a given alignment rectangle.
- [alignmentRectInsets](/documentation/uikit/uiview/alignmentrectinsets) The insets from the view’s frame that define its alignment rectangle.
- [forFirstBaselineLayout](/documentation/uikit/uiview/forfirstbaselinelayout) Returns a view used to satisfy first baseline constraints.
- [forLastBaselineLayout](/documentation/uikit/uiview/forlastbaselinelayout) Returns a view used to satisfy last baseline constraints.

## Triggering Auto Layout

- [needsUpdateConstraints()](/documentation/uikit/uiview/needsupdateconstraints()) A Boolean value that determines whether the view’s constraints need updating.
- [setNeedsUpdateConstraints()](/documentation/uikit/uiview/setneedsupdateconstraints()) Controls whether the view’s constraints need updating.
- [updateConstraints()](/documentation/uikit/uiview/updateconstraints()) Updates constraints for the view.
- [updateConstraintsIfNeeded()](/documentation/uikit/uiview/updateconstraintsifneeded()) Updates the constraints for the receiving view and its subviews.

## Debugging Auto Layout

- [constraintsAffectingLayout(for:)](/documentation/uikit/uiview/constraintsaffectinglayout(for:)) Returns the constraints impacting the layout of the view for a given axis.
- [hasAmbiguousLayout](/documentation/uikit/uiview/hasambiguouslayout) A Boolean value that determines whether the constraints impacting the layout of the view incompletely specify the location of the view.
- [exerciseAmbiguityInLayout()](/documentation/uikit/uiview/exerciseambiguityinlayout()) Randomly changes the frame of a view with an ambiguous layout between the different valid values.

## Configuring the resizing behavior

- [contentMode](/documentation/uikit/uiview/contentmode-swift.property) A flag used to determine how a view lays out its content when its bounds change.
- [UIView.ContentMode](/documentation/uikit/uiview/contentmode-swift.enum) Options to specify how a view adjusts its content when its size changes.
- [sizeThatFits(_:)](/documentation/uikit/uiview/sizethatfits(_:)) Asks the view to calculate and return the size that best fits the specified size.
- [sizeToFit()](/documentation/uikit/uiview/sizetofit()) Resizes and moves the receiver view so it just encloses its subviews.
- [autoresizesSubviews](/documentation/uikit/uiview/autoresizessubviews) A Boolean value that determines whether the receiver automatically resizes its subviews when its bounds change.
- [autoresizingMask](/documentation/uikit/uiview/autoresizingmask-swift.property) An integer bit mask that determines how the receiver resizes itself when its superview’s bounds change.

## Laying out subviews

- [layoutSubviews()](/documentation/uikit/uiview/layoutsubviews()) Lays out subviews.
- [setNeedsLayout()](/documentation/uikit/uiview/setneedslayout()) Invalidates the current layout of the receiver and triggers a layout update during the next update cycle.
- [layoutIfNeeded()](/documentation/uikit/uiview/layoutifneeded()) Lays out the subviews immediately, if layout updates are pending.
- [requiresConstraintBasedLayout](/documentation/uikit/uiview/requiresconstraintbasedlayout) A Boolean value that indicates whether the receiver depends on the constraint-based layout system.
- [translatesAutoresizingMaskIntoConstraints](/documentation/uikit/uiview/translatesautoresizingmaskintoconstraints) A Boolean value that determines whether the view’s autoresizing mask converts to Auto Layout constraints.

## Accessing insets and layout guides

- [UIView.LayoutRegion](/documentation/uikit/uiview/layoutregion)
- [directionalEdgeInsets(for:)](/documentation/uikit/uiview/directionaledgeinsets(for:))
- [edgeInsets(for:)](/documentation/uikit/uiview/edgeinsets(for:))
- [layoutGuide(for:)](/documentation/uikit/uiview/layoutguide(for:))

## Adjusting the user interface

- [overrideUserInterfaceStyle](/documentation/uikit/uiview/overrideuserinterfacestyle) The user interface style adopted by the view and all of its subviews.
- [semanticContentAttribute](/documentation/uikit/uiview/semanticcontentattribute) A semantic description of the view’s contents, used to determine whether the view should be flipped when switching between left-to-right and right-to-left layouts.
- [effectiveUserInterfaceLayoutDirection](/documentation/uikit/uiview/effectiveuserinterfacelayoutdirection) The user interface layout direction appropriate for arranging the immediate content of the view.
- [userInterfaceLayoutDirection(for:)](/documentation/uikit/uiview/userinterfacelayoutdirection(for:)) Returns the user interface direction for the given semantic content attribute.
- [userInterfaceLayoutDirection(for:relativeTo:)](/documentation/uikit/uiview/userinterfacelayoutdirection(for:relativeto:)) Returns the layout direction implied by the specified semantic content attribute, relative to the specified layout direction.

## Constraining views to the keyboard

- [keyboardLayoutGuide](/documentation/uikit/uiview/keyboardlayoutguide) A layout guide that tracks the keyboard’s position in your app’s layout.

## Adding and removing interactions

- [addInteraction(_:)](/documentation/uikit/uiview/addinteraction(_:)) Adds an interaction to the view.
- [removeInteraction(_:)](/documentation/uikit/uiview/removeinteraction(_:)) Removes an interaction from the view.
- [interactions](/documentation/uikit/uiview/interactions) The array of interactions for the view.
- [UIInteraction](/documentation/uikit/uiinteraction) The protocol that an interaction implements to access the view that owns it.

## Drawing and updating the view

- [draw(_:)](/documentation/uikit/uiview/draw(_:)) Draws the view’s image within the passed-in rectangle.
- [setNeedsDisplay()](/documentation/uikit/uiview/setneedsdisplay()) Marks the receiver’s entire bounds rectangle as needing to be redrawn.
- [setNeedsDisplay(_:)](/documentation/uikit/uiview/setneedsdisplay(_:)) Marks the specified rectangle of the receiver as needing to be redrawn.
- [contentScaleFactor](/documentation/uikit/uiview/contentscalefactor) The scale factor applied to the view.
- [tintColorDidChange()](/documentation/uikit/uiview/tintcolordidchange()) Called by the system when the tint color property changes.

## Updating the view when property values change

- [UIView.Invalidating](/documentation/uikit/uiview/invalidating) A property wrapper that notifies the system that a property value change has invalidated an aspect of the containing view.
- [UIViewInvalidating](/documentation/uikit/uiviewinvalidating) Implements a type of invalidation that can occur on a view that requires an update.

## Formatting printed view content

- [viewPrintFormatter()](/documentation/uikit/uiview/viewprintformatter()) Returns a print formatter for the receiving view.
- [draw(_:for:)](/documentation/uikit/uiview/draw(_:for:)) Implemented to draw the view’s content for printing.

## Managing gesture recognizers

- [addGestureRecognizer(_:)](/documentation/uikit/uiview/addgesturerecognizer(_:)) Attaches a gesture recognizer to the view.
- [removeGestureRecognizer(_:)](/documentation/uikit/uiview/removegesturerecognizer(_:)) Detaches a gesture recognizer from the receiving view.
- [gestureRecognizers](/documentation/uikit/uiview/gesturerecognizers) The gesture-recognizer objects currently attached to the view.
- [gestureRecognizerShouldBegin(_:)](/documentation/uikit/uiview/gesturerecognizershouldbegin(_:)) Asks the view if the gesture recognizer should continue tracking touch events.

## Working with focus

- [canBecomeFocused](/documentation/uikit/uiview/canbecomefocused) A Boolean value that indicates whether the view is currently capable of being focused.
- [inheritedAnimationDuration](/documentation/uikit/uiview/inheritedanimationduration) Returns the inherited duration of the current animation.
- [isFocused](/documentation/uikit/uiview/isfocused) A Boolean value that indicates whether the item is currently focused.
- [focusGroupIdentifier](/documentation/uikit/uiview/focusgroupidentifier) The identifier of the focus group that this view belongs to.
- [focusEffect](/documentation/uikit/uiview/focuseffect) The visual effect to apply when the view becomes focused.
- [focusGroupPriority](/documentation/uikit/uiview/focusgrouppriority) The importance of the item within a focus group, used by the focus system to determine the group’s primary item.

## Using motion effects

- [addMotionEffect(_:)](/documentation/uikit/uiview/addmotioneffect(_:)) Begins applying a motion effect to the view.
- [motionEffects](/documentation/uikit/uiview/motioneffects) The array of motion effects for the view.
- [removeMotionEffect(_:)](/documentation/uikit/uiview/removemotioneffect(_:)) Stops applying a motion effect to the view.

## Managing the hover appearance

- [hoverStyle](/documentation/uikit/uiview/hoverstyle) The hover style for the view.
- [UIHoverStyle](/documentation/uikit/uihoverstyle) The hover style to apply to a view, including an effect and a shape to use for displaying that effect.
- [UIHoverEffectLayer](/documentation/uikit/uihovereffectlayer) A layer type that can be used to apply a hover effect to its sublayers.

## Managing font-sizing preferences

- [minimumContentSizeCategory](/documentation/uikit/uiview/minimumcontentsizecategory) The minimum content size category for the view and its subviews.
- [maximumContentSizeCategory](/documentation/uikit/uiview/maximumcontentsizecategory) The maximum content size category for the view and its subviews.
- [appliedContentSizeCategoryLimitsDescription](/documentation/uikit/uiview/appliedcontentsizecategorylimitsdescription) A string that lists each of the view’s superviews, its content size category, and whether that view has content size category limits.

## Preserving and restoring state

- [restorationIdentifier](/documentation/uikit/uiview/restorationidentifier) The identifier that determines whether the view supports state restoration.
- [encodeRestorableState(with:)](/documentation/uikit/uiview/encoderestorablestate(with:)) Encodes state-related information for the view.
- [decodeRestorableState(with:)](/documentation/uikit/uiview/decoderestorablestate(with:)) Decodes and restores state-related information for the view.

## Capturing a view snapshot

- [snapshotView(afterScreenUpdates:)](/documentation/uikit/uiview/snapshotview(afterscreenupdates:)) Returns a snapshot view based on the contents of the current view.
- [resizableSnapshotView(from:afterScreenUpdates:withCapInsets:)](/documentation/uikit/uiview/resizablesnapshotview(from:afterscreenupdates:withcapinsets:)) Returns a snapshot view based on the specified contents of the current view, with stretchable insets.
- [drawHierarchy(in:afterScreenUpdates:)](/documentation/uikit/uiview/drawhierarchy(in:afterscreenupdates:)) Renders a snapshot of the complete view hierarchy as visible onscreen into the current context.

## Identifying the view at runtime

- [tag](/documentation/uikit/uiview/tag) An integer that you can use to identify view objects in your application.
- [viewWithTag(_:)](/documentation/uikit/uiview/viewwithtag(_:)) Returns the view whose tag matches the specified value.

## Converting between view coordinate systems

- [convert(_:to:)](/documentation/uikit/uiview/convert(_:to:)-1xizt) Converts a point from the receiver’s coordinate system to that of the specified view.
- [convert(_:from:)](/documentation/uikit/uiview/convert(_:from:)-8neo1) Converts a point from the coordinate system of a given view to that of the receiver.
- [convert(_:to:)](/documentation/uikit/uiview/convert(_:to:)-2kf3d) Converts a rectangle from the receiver’s coordinate system to that of another view.
- [convert(_:from:)](/documentation/uikit/uiview/convert(_:from:)-7irzk) Converts a rectangle from the coordinate system of another view to that of the receiver.

## Hit-testing in a view

- [hitTest(_:with:)](/documentation/uikit/uiview/hittest(_:with:)) Returns the farthest descendant in the view hierarchy of the current view, including itself, that contains the specified point.
- [point(inside:with:)](/documentation/uikit/uiview/point(inside:with:)) Returns a Boolean value indicating whether the receiver contains the specified point.

## Ending a view-editing session

- [endEditing(_:)](/documentation/uikit/uiview/endediting(_:)) Causes the view (or one of its embedded text fields) to resign the first responder status.

## Modifying the accessibility behavior

- [accessibilityIgnoresInvertColors](/documentation/uikit/uiview/accessibilityignoresinvertcolors) A Boolean value indicating whether the view ignores an accessibility request to invert its colors.
- [largeContentImage](/documentation/uikit/uiview/largecontentimage) An image that represents the view in the large content viewer.
- [largeContentImageInsets](/documentation/uikit/uiview/largecontentimageinsets) Insets to adjust the position of the view’s image so it appears centered in the large content viewer.
- [largeContentTitle](/documentation/uikit/uiview/largecontenttitle) A string that describes the view in the large content viewer.
- [scalesLargeContentImage](/documentation/uikit/uiview/scaleslargecontentimage) A Boolean value that indicates whether the large content viewer scales the item’s image to a larger size.
- [showsLargeContentViewer](/documentation/uikit/uiview/showslargecontentviewer) A Boolean value that indicates whether to show the view in the large content viewer.

## Animating views

- [animate(_:changes:completion:)](/documentation/uikit/uiview/animate(_:changes:completion:))
- [animate(springDuration:bounce:initialSpringVelocity:delay:options:animations:completion:)](/documentation/uikit/uiview/animate(springduration:bounce:initialspringvelocity:delay:options:animations:completion:)) Animates changes to one or more views using a spring animation with the specified duration, bounce, initial velocity, delay, options, and completion handler.
- [animate(withDuration:delay:options:animations:completion:)](/documentation/uikit/uiview/animate(withduration:delay:options:animations:completion:)) Animate changes to one or more views using the specified duration, delay, options, and completion handler.
- [animate(withDuration:animations:completion:)](/documentation/uikit/uiview/animate(withduration:animations:completion:)) Animate changes to one or more views using the specified duration and completion handler.
- [animate(withDuration:animations:)](/documentation/uikit/uiview/animate(withduration:animations:)) Animate changes to one or more views using the specified duration.
- [transition(with:duration:options:animations:completion:)](/documentation/uikit/uiview/transition(with:duration:options:animations:completion:)) Creates a transition animation for the specified container view.
- [transition(from:to:duration:options:completion:)](/documentation/uikit/uiview/transition(from:to:duration:options:completion:)) Creates a transition animation between the specified views using the given parameters.
- [animateKeyframes(withDuration:delay:options:animations:completion:)](/documentation/uikit/uiview/animatekeyframes(withduration:delay:options:animations:completion:)) Creates an animation block object that can be used to set up keyframe-based animations for the current view.
- [addKeyframe(withRelativeStartTime:relativeDuration:animations:)](/documentation/uikit/uiview/addkeyframe(withrelativestarttime:relativeduration:animations:)) Specifies the timing and animation values for a single frame of a keyframe animation.
- [perform(_:on:options:animations:completion:)](/documentation/uikit/uiview/perform(_:on:options:animations:completion:)) Performs a specified system-provided animation on one or more views, along with optional parallel animations that you define.
- [animate(withDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)](/documentation/uikit/uiview/animate(withduration:delay:usingspringwithdamping:initialspringvelocity:options:animations:completion:)) Performs a view animation using a timing curve corresponding to the motion of a physical spring.
- [performWithoutAnimation(_:)](/documentation/uikit/uiview/performwithoutanimation(_:)) Disables a view transition animation.
- [modifyAnimations(withRepeatCount:autoreverses:animations:)](/documentation/uikit/uiview/modifyanimations(withrepeatcount:autoreverses:animations:)) Repeats the specified animations a specific number of times, optionally running the animation forward and backward.

## Sensor coordinate orientation

- [CLBodyIdentifiable](/documentation/CoreLocation/CLBodyIdentifiable)
- [CMBodyIdentifiable](/documentation/CoreMotion/CMBodyIdentifiable)

## Constants

- [UIView.AnimationCurve](/documentation/uikit/uiview/animationcurve) Specifies the supported animation curves.
- [UIView.AnimationOptions](/documentation/uikit/uiview/animationoptions) Options for animating views using block objects.
- [UIView.AnimationTransition](/documentation/uikit/uiview/animationtransition) Animation transition options for use in an animation block object.
- [UIView.SystemAnimation](/documentation/uikit/uiview/systemanimation) Option to remove the views from the hierarchy when animation is complete.
- [UIView.KeyframeAnimationOptions](/documentation/uikit/uiview/keyframeanimationoptions) Options for configuring keyframe-based animations.
- [NSLayoutConstraint.Axis](/documentation/uikit/nslayoutconstraint/axis) Keys that specify a horizontal or vertical layout constraint between objects.
- [UIView.TintAdjustmentMode](/documentation/uikit/uiview/tintadjustmentmode-swift.enum) The tint adjustment mode for the view.
- [layoutFittingCompressedSize](/documentation/uikit/uiview/layoutfittingcompressedsize) The option to use the smallest possible size.
- [layoutFittingExpandedSize](/documentation/uikit/uiview/layoutfittingexpandedsize) The option to use the largest possible size.
- [noIntrinsicMetric](/documentation/uikit/uiview/nointrinsicmetric) The absence of an intrinsic metric for a given numeric view property.
- [UIView.AutoresizingMask](/documentation/uikit/uiview/autoresizingmask-swift.struct) Options for automatic view resizing.
- [UISemanticContentAttribute](/documentation/uikit/uisemanticcontentattribute) A semantic description of the view’s contents, used to determine whether the view should be flipped when switching between left-to-right and right-to-left layouts.

## Deprecated

- [Deprecated symbols](/documentation/uikit/uiview-deprecated-symbols) Symbols that views no longer support.

## Initializers

- [init()](/documentation/uikit/uiview/init())

## Instance Properties

- [appEntityUIElementProvider](/documentation/uikit/uiview/appentityuielementprovider) return AppEntityUIElement( identifier: EntityIdentifier( for: PhotoModel.self, identifier: photo.id ), bounds: photo.frame, state: State(isSelected: photo.isSelected) ) } } } }

## Instance Methods

- [setNeedsUpdateProperties()](/documentation/uikit/uiview/setneedsupdateproperties()) Call to manually request a properties update for the view. Multiple requests may be coalesced into a single update alongside the next layout pass.
- [updateProperties()](/documentation/uikit/uiview/updateproperties()) Configures the view’s content and styling properties before layout.
- [updatePropertiesIfNeeded()](/documentation/uikit/uiview/updatepropertiesifneeded()) Forces an immediate properties update for this view (and its view controller, if applicable) and any subviews, including any view controllers or views in its subtree.

## Enumerations

- [UIView.Invalidations](/documentation/uikit/uiview/invalidations) Changes that cause an aspect of a view to be invalid and require an update.

## Default Implementations

- [AppEntityAnnotatable Implementations](/documentation/uikit/uiview/appentityannotatable-implementations)

## View fundamentals

- [UIKit Catalog: Creating and customizing views and controls](/documentation/uikit/uikit-catalog-creating-and-customizing-views-and-controls) Customize your app’s user interface with views and controls.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
