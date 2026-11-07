---
title: UIViewController
description: An object that manages a view hierarchy for your UIKit app.
source: https://developer.apple.com/documentation/uikit/uiviewcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiviewcontroller.json
timestamp: 2026-06-26T06:39:37.114Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIViewController

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> An object that manages a view hierarchy for your UIKit app.

```swift
@MainActor class UIViewController
```

## Overview

The [UIViewController](/documentation/uikit/uiviewcontroller) class defines the shared behavior that’s common to all view controllers. You rarely create instances of the [UIViewController](/documentation/uikit/uiviewcontroller) class directly. Instead, you subclass [UIViewController](/documentation/uikit/uiviewcontroller) and add the methods and properties needed to manage the view controller’s view hierarchy.

A view controller’s main responsibilities include the following:

- Updating the contents of the views, usually in response to changes to the underlying data
- Responding to user interactions with views
- Resizing views and managing the layout of the overall interface
- Coordinating with other objects — including other view controllers — in your app

A view controller is tightly bound to the views it manages and takes part in handling events in its view hierarchy. Specifically, view controllers are [UIResponder](/documentation/uikit/uiresponder) objects and are inserted into the responder chain between the view controller’s root view and that view’s superview, which typically belongs to a different view controller. If none of the view controller’s views handle an event, the view controller has the option of handling the event or passing it along to the superview.

View controllers are rarely used in isolation. Instead, you often use multiple view controllers, each of which owns a portion of your app’s user interface. For example, one view controller might display a table of items while a different view controller displays the selected item from that table. Usually, only the views from one view controller are visible at a time. A view controller may present a different view controller to display a new set of views, or it may act as a container for other view controllers’ content and animate views however it wants.

### Subclassing notes

Every app contains at least one custom subclass of [UIViewController](/documentation/uikit/uiviewcontroller). More often, apps contain many custom view controllers. Custom view controllers define the overall behaviors of your app, including the app’s appearance and how it responds to user interactions. The following sections provide a brief overview of some of the tasks your custom subclass performs. For detailed information about using and implementing view controllers, see [View Controller Programming Guide for iOS](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/index.html#//apple_ref/doc/uid/TP40007457).

#### Manage views

Each view controller manages a view hierarchy, the root view of which is stored in the [view](/documentation/uikit/uiviewcontroller/view) property of this class. The root view acts primarily as a container for the rest of the view hierarchy. The size and position of the root view is determined by the object that owns it, which is either a parent view controller or the app’s window. The view controller that’s owned by the window is the app’s root view controller and its view is sized to fill the window.

View controllers load their views lazily. Accessing the [view](/documentation/uikit/uiviewcontroller/view) property for the first time loads or creates the view controller’s views. There are several ways to specify the views for a view controller:

- Specify the view controller and its views in your app’s storyboard. Storyboards are the preferred way to specify your views. With a storyboard, you specify the views and their connections to the view controller. You also specify the relationships and segues between your view controllers, which makes it easier to see and modify your app’s behavior.

To load a view controller from a storyboard, call the [instantiateViewController(withIdentifier:)](/documentation/uikit/uistoryboard/instantiateviewcontroller(withidentifier:)) method of the appropriate [UIStoryboard](/documentation/uikit/uistoryboard) object. The storyboard object creates the view controller and returns it to your code.

- Specify the views for a view controller using a nib file. A nib file lets you specify the views of a single view controller but doesn’t let you define segues or relationships between view controllers. The nib file also stores only minimal information about the view controller itself.

To initialize a view controller object using a nib file, create your view controller class programmatically and initialize it using the [init(nibName:bundle:)](/documentation/uikit/uiviewcontroller/init(nibname:bundle:)) method. When its views are requested, the view controller loads them from the nib file.

- Specify the views for a view controller using the [loadView()](/documentation/uikit/uiviewcontroller/loadview()) method. In that method, create your view hierarchy programmatically and assign the root view of that hierarchy to the view controller’s [view](/documentation/uikit/uiviewcontroller/view) property.

All of these techniques have the same end result, which is to create the appropriate set of views and expose them through the [view](/documentation/uikit/uiviewcontroller/view) property.

> **Important:** A view controller is the sole owner of its view and any subviews it creates. It’s responsible for creating those views and for relinquishing ownership of them at the appropriate times such as when the view controller itself is released. If you use a storyboard or a nib file to store your view objects, each view controller object automatically gets its own copy of these views when the view controller asks for them. However, if you create your views manually, each view controller must have its own unique set of views. You can’t share views between view controllers.

A view controller’s root view is always sized to fit its assigned space. For other views in your view hierarchy, use Interface Builder to specify the Auto Layout constraints that govern how each view is positioned and sized within its superview’s bounds. You can also create constraints programmatically and add them to your views at appropriate times. For more information about how to create constraints, see [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html#//apple_ref/doc/uid/TP40010853).

##### Handle view-related notifications

When the visibility of its views changes, a view controller automatically calls its own methods so that subclasses can respond to the change. Use a method like [viewIsAppearing(_:)](/documentation/uikit/uiviewcontroller/viewisappearing(_:)) to prepare your views to appear onscreen, and use [viewWillDisappear(_:)](/documentation/uikit/uiviewcontroller/viewwilldisappear(_:)) to save changes or other state information. Use other methods to make appropriate changes.

The following image shows the possible visible states for a view controller’s views and the state transitions that can occur. Not all `will` callback methods are paired with only a `did` callback method. You need to ensure that if you start a process in a `will` callback method, you end the process in both the corresponding `did` and the opposite `will` callback method.

![A diagram of four spheres arranged in a circle. The sphere on the right is labeled Appearing and has a clockwise arrow leading to the bottom sphere, which is labeled Appeared. A small dot on the arrow is labeled viewDidAppear. A clockwise arrow leads from the bottom sphere to the left sphere, which is labeled Disappearing. A small dot along the arrow is labeled viewWillDisappear. A clockwise arrow leads from the left sphere to the top sphere, which is labeled Disappeared. Two small dots along the arrow are labeled viewDidDisappear and View removed. A clockwise arrow leads from the top sphere to the right sphere. Three small dots along the arrow are labeled viewWillAppear, View added, and viewIsAppearing.](https://docs-assets.developer.apple.com/published/a941e6911051bdb9476e5c7b33a7eea2/media-1965800%402x.png)

##### Handle view rotations

As of iOS 8, all rotation-related methods are deprecated. Instead, rotations are treated as a change in the size of the view controller’s view and are therefore reported using the [viewWillTransition(to:with:)](/documentation/uikit/uicontentcontainer/viewwilltransition(to:with:)) method. When the interface orientation changes, UIKit calls this method on the window’s root view controller. That view controller then notifies its child view controllers, propagating the message throughout the view controller hierarchy.

In iOS 6 and iOS 7, your app supports the interface orientations defined in your app’s `Info.plist` file. A view controller can override the [supportedInterfaceOrientations](/documentation/uikit/uiviewcontroller/supportedinterfaceorientations) method to limit the list of supported orientations. Typically, the system calls this method only on the root view controller of the window or a view controller presented to fill the entire screen; child view controllers use the portion of the window provided for them by their parent view controller and no longer participate directly in decisions about what rotations are supported. The intersection of the app’s orientation mask and the view controller’s orientation mask is used to determine which orientations a view controller can be rotated into.

You can override the [preferredInterfaceOrientationForPresentation](/documentation/uikit/uiviewcontroller/preferredinterfaceorientationforpresentation) for a view controller that’s intended to be presented full screen in a specific orientation.

When a rotation occurs for a visible view controller, the [willRotate(to:duration:)](/documentation/uikit/uiviewcontroller/willrotate(to:duration:)), [willAnimateRotation(to:duration:)](/documentation/uikit/uiviewcontroller/willanimaterotation(to:duration:)), and [didRotate(from:)](/documentation/uikit/uiviewcontroller/didrotate(from:)) methods are called during the rotation. The [viewWillLayoutSubviews()](/documentation/uikit/uiviewcontroller/viewwilllayoutsubviews()) method is also called after the view is resized and positioned by its parent. If a view controller isn’t visible when an orientation change occurs, then the rotation methods are never called. However, the [viewWillLayoutSubviews()](/documentation/uikit/uiviewcontroller/viewwilllayoutsubviews()) method is called when the view becomes visible.

> **Note:** At launch time, apps should always set up their interface in a portrait orientation. After the [application(_:didFinishLaunchingWithOptions:)](/documentation/uikit/uiapplicationdelegate/application(_:didfinishlaunchingwithoptions:)) method returns, the app uses the view controller rotation mechanism described above to rotate the views to the appropriate orientation prior to showing the window.

#### Implement a container view controller

A custom [UIViewController](/documentation/uikit/uiviewcontroller) subclass can also act as a container view controller. A container view controller manages the presentation of content of other view controllers it owns, also known as its child view controllers. A child’s view can be presented as-is or in conjunction with views owned by the container view controller.

Your container view controller subclass should declare a public interface to associate its children. The nature of these methods is up to you and depends on the semantics of the container you’re creating. You need to decide how many children can be displayed by your view controller at once, when those children are displayed, and where they appear in your view controller’s view hierarchy. Your view controller class defines what relationships, if any, are shared by the children. By establishing a clean public interface for your container, you ensure that children use its capabilities logically, without accessing too many private details about how your container implements the behavior.

Your container view controller must associate a child view controller with itself before adding the child’s root view to the view hierarchy. This allows iOS to properly route events to child view controllers and the views those controllers manage. Likewise, after it removes a child’s root view from its view hierarchy, it should disconnect that child view controller from itself. To make or break these associations, your container calls specific methods defined by the base class. These methods aren’t intended to be called by clients of your container class; they are to be used only by your container’s implementation to provide the expected containment behavior.

Here are the essential methods you might need to call:

- [addChild(_:)](/documentation/uikit/uiviewcontroller/addchild(_:))
- [removeFromParent()](/documentation/uikit/uiviewcontroller/removefromparent())
- [willMove(toParent:)](/documentation/uikit/uiviewcontroller/willmove(toparent:))
- [didMove(toParent:)](/documentation/uikit/uiviewcontroller/didmove(toparent:))

> **Note:** You’re not required to override any methods when creating a container view controller.
> 
> By default, rotation and appearance callbacks are automatically forwarded to children. You may optionally override the [shouldAutomaticallyForwardRotationMethods()](/documentation/uikit/uiviewcontroller/shouldautomaticallyforwardrotationmethods()) and [shouldAutomaticallyForwardAppearanceMethods](/documentation/uikit/uiviewcontroller/shouldautomaticallyforwardappearancemethods) methods to take control of this behavior yourself.

#### Manage memory

Memory is a critical resource in iOS, and view controllers provide built-in support for reducing their memory footprint at critical times. The [UIViewController](/documentation/uikit/uiviewcontroller) class provides some automatic handling of low-memory conditions through its [didReceiveMemoryWarning()](/documentation/uikit/uiviewcontroller/didreceivememorywarning()) method, which releases unneeded memory.

#### Support state preservation and restoration

If you assign a value to the view controller’s [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) property, the system may ask the view controller to encode itself when the app transitions to the background. When preserved, a view controller preserves the state of any views in its view hierarchy that also have restoration identifiers. View controllers don’t automatically save any other state. If you’re implementing a custom container view controller, you must encode any child view controllers yourself. Each child you encode must have a unique restoration identifier.

For more information about how the system determines which view controllers to preserve and restore, see [App Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007072). To see an example of state preservation and restoration, see [Restoring your app’s state](/documentation/uikit/restoring-your-app-s-state).

## Inherits From

- [UIResponder](/documentation/uikit/uiresponder)

## Inherited By

- [UIActivityViewController](/documentation/uikit/uiactivityviewcontroller)
- [UIAlertController](/documentation/uikit/uialertcontroller)
- [UICloudSharingController](/documentation/uikit/uicloudsharingcontroller)
- [UICollectionViewController](/documentation/uikit/uicollectionviewcontroller)
- [UIColorPickerViewController](/documentation/uikit/uicolorpickerviewcontroller)
- [UIDocumentBrowserViewController](/documentation/uikit/uidocumentbrowserviewcontroller)
- [UIDocumentMenuViewController](/documentation/uikit/uidocumentmenuviewcontroller)
- [UIDocumentPickerExtensionViewController](/documentation/uikit/uidocumentpickerextensionviewcontroller)
- [UIDocumentPickerViewController](/documentation/uikit/uidocumentpickerviewcontroller)
- [UIDocumentViewController](/documentation/uikit/uidocumentviewcontroller)
- [UIFontPickerViewController](/documentation/uikit/uifontpickerviewcontroller)
- [UIInputViewController](/documentation/uikit/uiinputviewcontroller)
- [UINavigationController](/documentation/uikit/uinavigationcontroller)
- [UIPageViewController](/documentation/uikit/uipageviewcontroller)
- [UIReferenceLibraryViewController](/documentation/uikit/uireferencelibraryviewcontroller)
- [UISearchContainerViewController](/documentation/uikit/uisearchcontainerviewcontroller)
- [UISearchController](/documentation/uikit/uisearchcontroller)
- [UISplitViewController](/documentation/uikit/uisplitviewcontroller)
- [UITabBarController](/documentation/uikit/uitabbarcontroller)
- [UITableViewController](/documentation/uikit/uitableviewcontroller)
- [UITextFormattingViewController](/documentation/uikit/uitextformattingviewcontroller)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSExtensionRequestHandling](/documentation/Foundation/NSExtensionRequestHandling)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIAppearanceContainer](/documentation/uikit/uiappearancecontainer)
- [UIContentContainer](/documentation/uikit/uicontentcontainer)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UIStateRestoring](/documentation/uikit/uistaterestoring)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating a view controller

- [init(nibName:bundle:)](/documentation/uikit/uiviewcontroller/init(nibname:bundle:)) Creates a view controller with the nib file in the specified bundle.
- [init(coder:)](/documentation/uikit/uiviewcontroller/init(coder:)) Creates a view controller with data in an unarchiver.

## Getting the storyboard and nib information

- [storyboard](/documentation/uikit/uiviewcontroller/storyboard) The storyboard from which the view controller originated.
- [nibName](/documentation/uikit/uiviewcontroller/nibname) The name of the view controller’s nib file, if one was specified.
- [nibBundle](/documentation/uikit/uiviewcontroller/nibbundle) The view controller’s nib bundle if it exists.

## Managing the view

- [view](/documentation/uikit/uiviewcontroller/view) The view that the controller manages.
- [viewIfLoaded](/documentation/uikit/uiviewcontroller/viewifloaded) The view controller’s view, or `nil` if the view isn’t yet loaded.
- [isViewLoaded](/documentation/uikit/uiviewcontroller/isviewloaded) A Boolean value indicating whether the view is currently loaded into memory.
- [loadView()](/documentation/uikit/uiviewcontroller/loadview()) Creates the view that the controller manages.
- [viewDidLoad()](/documentation/uikit/uiviewcontroller/viewdidload()) Called after the controller’s view is loaded into memory.
- [loadViewIfNeeded()](/documentation/uikit/uiviewcontroller/loadviewifneeded()) Loads the view controller’s view if it’s not loaded yet.
- [title](/documentation/uikit/uiviewcontroller/title) A localized string that represents the view this controller manages.
- [preferredContentSize](/documentation/uikit/uiviewcontroller/preferredcontentsize) The preferred size for the view controller’s view.
- [ornaments](/documentation/uikit/uiviewcontroller/ornaments) SwiftUI ornaments to display adjacent to the view controller.

## Responding to view-related events

- [viewWillAppear(_:)](/documentation/uikit/uiviewcontroller/viewwillappear(_:)) Notifies the view controller that its view is about to be added to a view hierarchy.
- [viewIsAppearing(_:)](/documentation/uikit/uiviewcontroller/viewisappearing(_:)) Notifies the view controller that the system is adding the view controller’s view to a view hierarchy.
- [viewDidAppear(_:)](/documentation/uikit/uiviewcontroller/viewdidappear(_:)) Notifies the view controller that its view was added to a view hierarchy.
- [viewWillDisappear(_:)](/documentation/uikit/uiviewcontroller/viewwilldisappear(_:)) Notifies the view controller that its view is about to be removed from a view hierarchy.
- [viewDidDisappear(_:)](/documentation/uikit/uiviewcontroller/viewdiddisappear(_:)) Notifies the view controller that its view was removed from a view hierarchy.
- [isBeingDismissed](/documentation/uikit/uiviewcontroller/isbeingdismissed) A Boolean value indicating whether the view controller is in the process of being dismissed by one of its ancestors.
- [isBeingPresented](/documentation/uikit/uiviewcontroller/isbeingpresented) A Boolean value indicating whether the view controller in the process of being presented by one of its ancestors.
- [isMovingFromParent](/documentation/uikit/uiviewcontroller/ismovingfromparent) A Boolean value indicating whether the view controller is moving from a parent view controller.
- [isMovingToParent](/documentation/uikit/uiviewcontroller/ismovingtoparent) A Boolean value indicating whether the view controller is moving to a parent view controller.

## Managing the view’s properties

- [UIViewController.ViewLoading](/documentation/uikit/uiviewcontroller/viewloading) A property wrapper that loads the view controller’s view before accessing the property.
- [updateProperties()](/documentation/uikit/uiviewcontroller/updateproperties()) Configures the view controller’s content and styling properties.
- [updatePropertiesIfNeeded()](/documentation/uikit/uiviewcontroller/updatepropertiesifneeded()) Forces an immediate properties update for this view controller and its view, including any view controllers and views in this subtree.
- [setNeedsUpdateProperties()](/documentation/uikit/uiviewcontroller/setneedsupdateproperties()) Call to manually request a properties update for the view controller. Multiple requests may be coalesced into a single update alongside the next layout pass.

## Extending the view’s safe area

- [Positioning content relative to the safe area](/documentation/uikit/positioning-content-relative-to-the-safe-area) Position views so that they aren’t obstructed by other content.
- [additionalSafeAreaInsets](/documentation/uikit/uiviewcontroller/additionalsafeareainsets) Custom insets that you specify to modify the view controller’s safe area.
- [viewSafeAreaInsetsDidChange()](/documentation/uikit/uiviewcontroller/viewsafeareainsetsdidchange()) Called to notify the view controller that the safe area insets of its root view changed.

## Managing the view’s margins

- [Positioning content within layout margins](/documentation/uikit/positioning-content-within-layout-margins) Position views so that they aren’t crowded by other content.
- [viewRespectsSystemMinimumLayoutMargins](/documentation/uikit/uiviewcontroller/viewrespectssystemminimumlayoutmargins) A Boolean value indicating whether the view controller’s view uses the system-defined minimum layout margins.
- [systemMinimumLayoutMargins](/documentation/uikit/uiviewcontroller/systemminimumlayoutmargins) The minimum layout margins for the view controller’s root view.
- [viewLayoutMarginsDidChange()](/documentation/uikit/uiviewcontroller/viewlayoutmarginsdidchange()) Called to notify the view controller that the layout margins of its root view changed.

## Configuring the view’s layout behavior

- [edgesForExtendedLayout](/documentation/uikit/uiviewcontroller/edgesforextendedlayout) The edges that you extend for your view controller.
- [UIRectEdge](/documentation/uikit/uirectedge) Constants that specify the edges of a rectangle.
- [extendedLayoutIncludesOpaqueBars](/documentation/uikit/uiviewcontroller/extendedlayoutincludesopaquebars) A Boolean value indicating whether or not the extended layout includes opaque bars.
- [viewWillLayoutSubviews()](/documentation/uikit/uiviewcontroller/viewwilllayoutsubviews()) Notifies the view controller that its view is about to lay out its subviews.
- [viewDidLayoutSubviews()](/documentation/uikit/uiviewcontroller/viewdidlayoutsubviews()) Notifies the view controller when its view finishes laying out its subviews.
- [updateViewConstraints()](/documentation/uikit/uiviewcontroller/updateviewconstraints()) Notifies the view controller when its view needs to update its constraints.

## Configuring the view rotation settings

- [supportedInterfaceOrientations](/documentation/uikit/uiviewcontroller/supportedinterfaceorientations) The interface orientations that the view controller supports.
- [preferredInterfaceOrientationForPresentation](/documentation/uikit/uiviewcontroller/preferredinterfaceorientationforpresentation) The interface orientation to use when presenting the view controller.
- [setNeedsUpdateOfSupportedInterfaceOrientations()](/documentation/uikit/uiviewcontroller/setneedsupdateofsupportedinterfaceorientations()) Notifies the view controller about a change in supported interface orientations or preferred interface orientation for presentation.
- [prefersInterfaceOrientationLocked](/documentation/uikit/uiviewcontroller/prefersinterfaceorientationlocked) A Boolean value that indicates whether the view controller prefers to lock the scene’s interface orientation when the scene is visible.
- [setNeedsUpdateOfPrefersInterfaceOrientationLocked()](/documentation/uikit/uiviewcontroller/setneedsupdateofprefersinterfaceorientationlocked()) Indicates that the view controller changed the interface orientation lock preference.
- [childForInterfaceOrientationLock](/documentation/uikit/uiviewcontroller/childforinterfaceorientationlock) A child view controller to query for the interface orientation lock preference.

## Performing segues

- [shouldPerformSegue(withIdentifier:sender:)](/documentation/uikit/uiviewcontroller/shouldperformsegue(withidentifier:sender:)) Determines whether the segue with the specified identifier should be performed.
- [prepare(for:sender:)](/documentation/uikit/uiviewcontroller/prepare(for:sender:)) Notifies the view controller that a segue is about to be performed.
- [performSegue(withIdentifier:sender:)](/documentation/uikit/uiviewcontroller/performsegue(withidentifier:sender:)) Initiates the segue with the specified identifier from the current view controller’s storyboard file.
- [allowedChildrenForUnwinding(from:)](/documentation/uikit/uiviewcontroller/allowedchildrenforunwinding(from:)) Returns an array of child view controllers to search for an unwind segue destination.
- [childContaining(_:)](/documentation/uikit/uiviewcontroller/childcontaining(_:)) Returns the child view controller that contains the source of the unwind segue.
- [canPerformUnwindSegueAction(_:from:sender:)](/documentation/uikit/uiviewcontroller/canperformunwindsegueaction(_:from:sender:)) Called on a view controller to determine whether it responds to an unwind action.
- [unwind(for:towards:)](/documentation/uikit/uiviewcontroller/unwind(for:towards:)) Called when an unwind segue transitions to a new view controller.

## Presenting a view controller

- [show(_:sender:)](/documentation/uikit/uiviewcontroller/show(_:sender:)) Presents a view controller in a primary context.
- [showDetailViewController(_:sender:)](/documentation/uikit/uiviewcontroller/showdetailviewcontroller(_:sender:)) Presents a view controller in a secondary (or detail) context.
- [UIViewController.ShowDetailTargetDidChangeMessage](/documentation/uikit/uiviewcontroller/showdetailtargetdidchangemessage)
- [present(_:animated:completion:)](/documentation/uikit/uiviewcontroller/present(_:animated:completion:)) Presents a view controller modally.
- [dismiss(animated:completion:)](/documentation/uikit/uiviewcontroller/dismiss(animated:completion:)) Dismisses the view controller that was presented modally by the view controller.
- [modalPresentationStyle](/documentation/uikit/uiviewcontroller/modalpresentationstyle) The presentation style for modal view controllers.
- [UIModalPresentationStyle](/documentation/uikit/uimodalpresentationstyle) Modal presentation styles available when presenting view controllers.
- [modalTransitionStyle](/documentation/uikit/uiviewcontroller/modaltransitionstyle) The transition style to use when presenting the view controller.
- [UIModalTransitionStyle](/documentation/uikit/uimodaltransitionstyle) Transition styles available when presenting view controllers.
- [isModalInPresentation](/documentation/uikit/uiviewcontroller/ismodalinpresentation) A Boolean value indicating whether the view controller enforces a modal behavior.
- [definesPresentationContext](/documentation/uikit/uiviewcontroller/definespresentationcontext) A Boolean value that indicates whether this view controller’s view is covered when the view controller or one of its descendants presents a view controller.
- [providesPresentationContextTransitionStyle](/documentation/uikit/uiviewcontroller/providespresentationcontexttransitionstyle) A Boolean value that indicates whether the view controller specifies the transition style for view controllers it presents.
- [disablesAutomaticKeyboardDismissal](/documentation/uikit/uiviewcontroller/disablesautomatickeyboarddismissal) Returns a Boolean indicating whether the current input view is dismissed automatically when changing controls.
- [showDetailTargetDidChangeNotification](/documentation/uikit/uiviewcontroller/showdetailtargetdidchangenotification) Posted when a split view controller is expanded or collapsed.

## Adding a custom transition or presentation

- [transitioningDelegate](/documentation/uikit/uiviewcontroller/transitioningdelegate) The delegate object that provides transition animator, interactive controller, and custom presentation controller objects.
- [transitionCoordinator](/documentation/uikit/uiviewcontroller/transitioncoordinator) Returns the active transition coordinator object.
- [targetViewController(forAction:sender:)](/documentation/uikit/uiviewcontroller/targetviewcontroller(foraction:sender:)) Returns the view controller that responds to the action.
- [presentationController](/documentation/uikit/uiviewcontroller/presentationcontroller) The presentation controller that’s managing the current view controller.
- [popoverPresentationController](/documentation/uikit/uiviewcontroller/popoverpresentationcontroller) The nearest popover presentation controller that is managing the current view controller.
- [sheetPresentationController](/documentation/uikit/uiviewcontroller/sheetpresentationcontroller) The sheet presentation controller for the view controller.
- [activePresentationController](/documentation/uikit/uiviewcontroller/activepresentationcontroller) The presentation controller that’s managing the view controller.
- [restoresFocusAfterTransition](/documentation/uikit/uiviewcontroller/restoresfocusaftertransition) A Boolean value that indicates whether an item that previously was focused should again become focused when the item’s view controller becomes visible and focusable.
- [Customizing and resizing sheets in UIKit](/documentation/uikit/customizing-and-resizing-sheets-in-uikit) Discover how to create a layered and customized sheet experience in UIKit.

## Adapting to environment changes

- [collapseSecondaryViewController(_:for:)](/documentation/uikit/uiviewcontroller/collapsesecondaryviewcontroller(_:for:)) Called when a split view controller transitions to a compact-width size class.
- [separateSecondaryViewController(for:)](/documentation/uikit/uiviewcontroller/separatesecondaryviewcontroller(for:)) Called when a split view controller transitions to a regular-width size class.

## Adjusting the interface style

- [overrideUserInterfaceStyle](/documentation/uikit/uiviewcontroller/overrideuserinterfacestyle) The user interface style adopted by the view controller and all of its children.
- [preferredUserInterfaceStyle](/documentation/uikit/uiviewcontroller/preferreduserinterfacestyle) The preferred interface style for this view controller.
- [childViewControllerForUserInterfaceStyle](/documentation/uikit/uiviewcontroller/childviewcontrollerforuserinterfacestyle) The child view controller that supports the preferred user interface style.
- [setNeedsUserInterfaceAppearanceUpdate()](/documentation/uikit/uiviewcontroller/setneedsuserinterfaceappearanceupdate()) Notifies the view controller that a change occurred that might affect the preferred interface style.
- [UIUserInterfaceStyle](/documentation/uikit/uiuserinterfacestyle) Constants that indicate the interface style for the app.

## Adjusting the container background style

- [preferredContainerBackgroundStyle](/documentation/uikit/uiviewcontroller/preferredcontainerbackgroundstyle)
- [childViewControllerForPreferredContainerBackgroundStyle](/documentation/uikit/uiviewcontroller/childviewcontrollerforpreferredcontainerbackgroundstyle)
- [setNeedsUpdateOfPreferredContainerBackgroundStyle()](/documentation/uikit/uiviewcontroller/setneedsupdateofpreferredcontainerbackgroundstyle())
- [UIContainerBackgroundStyle](/documentation/uikit/uicontainerbackgroundstyle)

## Observing trait changes

- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94) A type that calls your code in reaction to changes in the trait environment.

## Overriding trait values

- [traitOverrides](/documentation/uikit/uiviewcontroller/traitoverrides-1z1cc) A mutable container of traits you use to set trait changes for this view controller and its views.
- [UITraitOverrides](/documentation/uikit/uitraitoverrides-swift.struct) A mutable container of traits you use to set trait changes for an object and its descendants.
- [updateTraitsIfNeeded()](/documentation/uikit/uiviewcontroller/updatetraitsifneeded()) Updates traits immediately for this view controller and its view, including any view controllers and views in this subtree.

## Managing child view controllers in a custom container

- [children](/documentation/uikit/uiviewcontroller/children) An array of view controllers that are children of the current view controller.
- [addChild(_:)](/documentation/uikit/uiviewcontroller/addchild(_:)) Adds the specified view controller as a child of the current view controller.
- [removeFromParent()](/documentation/uikit/uiviewcontroller/removefromparent()) Removes the view controller from its parent.
- [transition(from:to:duration:options:animations:completion:)](/documentation/uikit/uiviewcontroller/transition(from:to:duration:options:animations:completion:)) Transitions between two of the view controller’s child view controllers.
- [shouldAutomaticallyForwardAppearanceMethods](/documentation/uikit/uiviewcontroller/shouldautomaticallyforwardappearancemethods) Returns a Boolean value indicating whether appearance methods are forwarded to child view controllers.
- [beginAppearanceTransition(_:animated:)](/documentation/uikit/uiviewcontroller/beginappearancetransition(_:animated:)) Tells a child controller its appearance is about to change.
- [endAppearanceTransition()](/documentation/uikit/uiviewcontroller/endappearancetransition()) Tells a child controller its appearance has changed.
- [hierarchyInconsistencyException](/documentation/uikit/uiviewcontroller/hierarchyinconsistencyexception) Raised if the view controller hierarchy is inconsistent with the view hierarchy.

## Responding to containment events

- [willMove(toParent:)](/documentation/uikit/uiviewcontroller/willmove(toparent:)) Called just before the view controller is added or removed from a container view controller.
- [didMove(toParent:)](/documentation/uikit/uiviewcontroller/didmove(toparent:)) Called after the view controller is added or removed from a container view controller.

## Getting other related view controllers

- [presentingViewController](/documentation/uikit/uiviewcontroller/presentingviewcontroller) The view controller that presented this view controller.
- [presentedViewController](/documentation/uikit/uiviewcontroller/presentedviewcontroller) The view controller that is presented by this view controller, or one of its ancestors in the view controller hierarchy.
- [parent](/documentation/uikit/uiviewcontroller/parent) The parent view controller of the recipient.
- [splitViewController](/documentation/uikit/uiviewcontroller/splitviewcontroller) The nearest ancestor in the view controller hierarchy that is a split view controller.
- [navigationController](/documentation/uikit/uiviewcontroller/navigationcontroller) The nearest ancestor in the view controller hierarchy that is a navigation controller.
- [tabBarController](/documentation/uikit/uiviewcontroller/tabbarcontroller) The nearest ancestor in the view controller hierarchy that is a tab bar controller.

## Configuring a navigation interface

- [navigationItem](/documentation/uikit/uiviewcontroller/navigationitem) The navigation item used to represent the view controller in a parent’s navigation bar.
- [hidesBottomBarWhenPushed](/documentation/uikit/uiviewcontroller/hidesbottombarwhenpushed) A Boolean value indicating whether the toolbar at the bottom of the screen is hidden when the view controller is pushed on to a navigation controller.
- [setToolbarItems(_:animated:)](/documentation/uikit/uiviewcontroller/settoolbaritems(_:animated:)) Sets the toolbar items to be displayed along with the view controller.
- [toolbarItems](/documentation/uikit/uiviewcontroller/toolbaritems) The toolbar items associated with the view controller.

## Configuring tab bar content

- [tab](/documentation/uikit/uiviewcontroller/tab) The `UITab` instance that was used to create the receiver, and represents the view controller. Default is nil.
- [tabBarItem](/documentation/uikit/uiviewcontroller/tabbaritem) The tab bar item that represents the view controller when added to a tab bar controller.
- [tabBarObservedScrollView](/documentation/uikit/uiviewcontroller/tabbarobservedscrollview) The full-screen scroll view to synchronize with a scrolling tab bar.

## Working with scrolling content

- [setContentScrollView(_:for:)](/documentation/uikit/uiviewcontroller/setcontentscrollview(_:for:)) Sets the scroll view that bars observe for the specified edge.
- [setContentScrollView(_:)](/documentation/uikit/uiviewcontroller/setcontentscrollview(_:)) Sets the scroll view that bars observe for all edges of the view.
- [contentScrollView(for:)](/documentation/uikit/uiviewcontroller/contentscrollview(for:)) Returns the scroll view the view controller observes for the specified edge.

## Indicating missing content

- [contentUnavailableConfiguration](/documentation/uikit/uiviewcontroller/contentunavailableconfiguration-4b95e) The current content-unavailable configuration of the view controller.
- [contentUnavailableConfigurationState](/documentation/uikit/uiviewcontroller/contentunavailableconfigurationstate-7sczw) The current configuration state of the content-unavailable view.
- [setNeedsUpdateContentUnavailableConfiguration()](/documentation/uikit/uiviewcontroller/setneedsupdatecontentunavailableconfiguration()) Requests that the system update the content-unavailable configuration for the latest state.
- [updateContentUnavailableConfiguration(using:)](/documentation/uikit/uiviewcontroller/updatecontentunavailableconfiguration(using:)) Updates the content-unavailable configuration for the provided state.
- [UIContentUnavailableConfiguration](/documentation/uikit/uicontentunavailableconfiguration-swift.struct) A content configuration for a content-unavailable view.

## Supporting app extensions

- [extensionContext](/documentation/uikit/uiviewcontroller/extensioncontext) Returns the extension context of the view controller.

## Coordinating with system gestures

- [preferredScreenEdgesDeferringSystemGestures](/documentation/uikit/uiviewcontroller/preferredscreenedgesdeferringsystemgestures) The screen edges for which you want your gestures to take precedence over the system gestures.
- [childForScreenEdgesDeferringSystemGestures](/documentation/uikit/uiviewcontroller/childforscreenedgesdeferringsystemgestures) Returns the child view controller that should be queried to see if its gestures should take precedence.
- [setNeedsUpdateOfScreenEdgesDeferringSystemGestures()](/documentation/uikit/uiviewcontroller/setneedsupdateofscreenedgesdeferringsystemgestures()) Notifies the system of changes to the screen edges that defer system gestures.
- [prefersHomeIndicatorAutoHidden](/documentation/uikit/uiviewcontroller/prefershomeindicatorautohidden) A Boolean that indicates whether the system is allowed to hide the visual indicator for returning to the Home Screen.
- [childForHomeIndicatorAutoHidden](/documentation/uikit/uiviewcontroller/childforhomeindicatorautohidden) Returns the child view controller that is consulted about its preference for displaying a visual indicator for returning to the Home screen.
- [setNeedsUpdateOfHomeIndicatorAutoHidden()](/documentation/uikit/uiviewcontroller/setneedsupdateofhomeindicatorautohidden()) Notifies UIKit that your view controller updated its preference regarding the visual indicator for returning to the Home screen.

## Working with transitions

- [preferredTransition](/documentation/uikit/uiviewcontroller/preferredtransition) An object that defines the transition animation when switching to the view controller.
- [UIViewController.Transition](/documentation/uikit/uiviewcontroller/transition) An object that defines the transition animation when switching to a new view controller.

## Working with focus

- [focusGroupIdentifier](/documentation/uikit/uiviewcontroller/focusgroupidentifier) The identifier of the focus group that the view controller belongs to.

## Managing pointer lock state

- [prefersPointerLocked](/documentation/uikit/uiviewcontroller/preferspointerlocked) A Boolean value that indicates whether the view controller prefers to lock the pointer to a specific scene.
- [setNeedsUpdateOfPrefersPointerLocked()](/documentation/uikit/uiviewcontroller/setneedsupdateofpreferspointerlocked()) Indicates that the view controller changed the pointer lock preference.
- [childViewControllerForPointerLock](/documentation/uikit/uiviewcontroller/childviewcontrollerforpointerlock) A child view controller to query for the pointer lock preference.

## Managing the status bar

- [prefersStatusBarHidden](/documentation/uikit/uiviewcontroller/prefersstatusbarhidden) Specifies whether the view controller prefers the status bar to be hidden or shown.
- [childForStatusBarHidden](/documentation/uikit/uiviewcontroller/childforstatusbarhidden) The view controller to use for determining the hidden state of the status bar.
- [childForStatusBarStyle](/documentation/uikit/uiviewcontroller/childforstatusbarstyle) Called when the system needs the view controller to use for determining status bar style.
- [preferredStatusBarStyle](/documentation/uikit/uiviewcontroller/preferredstatusbarstyle) The preferred status bar style for the view controller.
- [UIStatusBarStyle](/documentation/uikit/uistatusbarstyle) Constants that describe the style of the device’s status bar.
- [modalPresentationCapturesStatusBarAppearance](/documentation/uikit/uiviewcontroller/modalpresentationcapturesstatusbarappearance) Specifies whether a view controller, presented non-fullscreen, takes over control of status bar appearance from the presenting view controller.
- [preferredStatusBarUpdateAnimation](/documentation/uikit/uiviewcontroller/preferredstatusbarupdateanimation) Specifies the animation style to use for hiding and showing the status bar for the view controller.
- [setNeedsStatusBarAppearanceUpdate()](/documentation/uikit/uiviewcontroller/setneedsstatusbarappearanceupdate()) Indicates to the system that the view controller status bar attributes have changed.

## Managing the Touch Bar

- [childViewControllerForTouchBar](/documentation/uikit/uiviewcontroller/childviewcontrollerfortouchbar) The child view controller that the system uses to display content in the Touch Bar.
- [setNeedsTouchBarUpdate()](/documentation/uikit/uiviewcontroller/setneedstouchbarupdate()) Tells the system to update the Touch Bar.

## Accessing the available key commands

- [performsActionsWhilePresentingModally](/documentation/uikit/uiviewcontroller/performsactionswhilepresentingmodally) A Boolean value indicating whether the view controller performs menu-related actions.
- [addKeyCommand(_:)](/documentation/uikit/uiviewcontroller/addkeycommand(_:)) Associates the specified keyboard shortcut with the view controller.
- [removeKeyCommand(_:)](/documentation/uikit/uiviewcontroller/removekeycommand(_:)) Removes the key command from the view controller.

## Adding editing behaviors to your view controller

- [isEditing](/documentation/uikit/uiviewcontroller/isediting) A Boolean value indicating whether the view controller currently allows the user to edit the view contents.
- [setEditing(_:animated:)](/documentation/uikit/uiviewcontroller/setediting(_:animated:)) Sets whether the view controller shows an editable view.
- [editButtonItem](/documentation/uikit/uiviewcontroller/editbuttonitem) Returns a bar button item that toggles its title and associated state between Edit and Done.

## Handling memory warnings

- [didReceiveMemoryWarning()](/documentation/uikit/uiviewcontroller/didreceivememorywarning()) Sent to the view controller when the app receives a memory warning.

## Managing state restoration

- [Restoring your app’s state](/documentation/uikit/restoring-your-app-s-state) Provide continuity for the user by preserving current activities.
- [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) The identifier that determines whether the view controller supports state restoration.
- [restorationClass](/documentation/uikit/uiviewcontroller/restorationclass) The class responsible for recreating this view controller when restoring the app’s state.
- [encodeRestorableState(with:)](/documentation/uikit/uiviewcontroller/encoderestorablestate(with:)) Encodes state-related information for the view controller.
- [decodeRestorableState(with:)](/documentation/uikit/uiviewcontroller/decoderestorablestate(with:)) Decodes and restores state-related information for the view controller.
- [applicationFinishedRestoringState()](/documentation/uikit/uiviewcontroller/applicationfinishedrestoringstate()) Called on restored view controllers after other object decoding is complete.

## Logging user interaction intervals

- [interactionActivityTrackingBaseName](/documentation/uikit/uiviewcontroller/interactionactivitytrackingbasename) The base name the view controller uses for logging signposts that annotate user interactions.

## Deprecated

- [Deprecated symbols](/documentation/uikit/uiviewcontroller-deprecated-symbols) Symbols that view controllers no longer support.

## Instance Methods

- [registerSceneAccessory(_:)](/documentation/uikit/uiviewcontroller/registersceneaccessory(_:)) Registers a new scene accessory configuration associated with this view controller.
- [unregisterSceneAccessory(_:)](/documentation/uikit/uiviewcontroller/unregistersceneaccessory(_:)) Unregisters a scene accessory with the specified registration.

## Content view controllers

- [Displaying and managing views with a view controller](/documentation/uikit/displaying-and-managing-views-with-a-view-controller) Build a view controller in storyboards, configure it with custom views, and fill those views with your app’s data.
- [Showing and hiding view controllers](/documentation/uikit/showing-and-hiding-view-controllers) Display view controllers using different techniques, and pass data between them during transitions.
- [UITableViewController](/documentation/uikit/uitableviewcontroller) A view controller that specializes in managing a table view.
- [UICollectionViewController](/documentation/uikit/uicollectionviewcontroller) A view controller that specializes in managing a collection view.
- [UIContentContainer](/documentation/uikit/uicontentcontainer) A set of methods for adapting the contents of your view controllers to size and trait changes.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
