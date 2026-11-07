---
title: UINavigationController
description: A container view controller that defines a stack-based scheme for navigating hierarchical content.
source: https://developer.apple.com/documentation/uikit/uinavigationcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uinavigationcontroller.json
timestamp: 2026-04-14T13:14:52.415Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UINavigationController

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A container view controller that defines a stack-based scheme for navigating hierarchical content.

```swift
@MainActor class UINavigationController
```

## Overview

A navigation controller is a container view controller that manages one or more contained view controllers in a navigation interface. In this type of interface, only one contained view controller is visible at a time. Selecting an item in the view controller pushes a new view controller onscreen using an animation, hiding the previous view controller. Tapping the back button in the navigation bar at the top of the interface removes the top view controller, thereby revealing the view controller underneath.

Use a navigation interface to mimic the organization of hierarchical data managed by your app. At each level of the hierarchy, you provide an appropriate screen (managed by a custom view controller) to display the content at that level. The following image shows an example of the navigation interface presented by the Settings application in a simulated iOS device. The first screen presents the user with the list of groups that organize preferences. Selecting a group reveals individual settings and groups of settings for that application. For all but the root view, the navigation controller provides a back button to allow the user to move back up the hierarchy.

![A sample navigation interface](https://docs-assets.developer.apple.com/published/ec22a982d6cb1673c1190305d79cb382/media-1965789%402x.png)

A navigation controller object manages the view controllers it contains using an ordered array, known as the *navigation stack*. The first view controller in the array is the root view controller and represents the bottom of the stack. The last view controller in the array is the topmost item on the stack, and represents the view controller that the system is currently displaying. You add and remove view controllers from the stack using segues or using the methods of this class. The user can also remove the topmost view controller using the back button in the navigation bar or using a swipe gesture.

The navigation controller manages the navigation bar at the top of the interface and an optional toolbar at the bottom of the interface. The navigation bar is always present and is managed by the navigation controller itself, which updates the navigation bar using the content provided by its contained view controllers. When the [isToolbarHidden](/documentation/uikit/uinavigationcontroller/istoolbarhidden) property is [false](/documentation/Swift/false), the navigation controller similarly updates the toolbar with contents provided by the topmost view controller.

A navigation controller coordinates its behavior with its [delegate](/documentation/uikit/uinavigationcontroller/delegate) object. The delegate object can override the pushing or popping of view controllers, provide custom animation transitions, and specify the preferred orientation for the navigation interface. The delegate object you provide must conform to the [UINavigationControllerDelegate](/documentation/uikit/uinavigationcontrollerdelegate) protocol.

The following image shows the relationships between the navigation controller and the objects it manages. Use the specified properties of the navigation controller to access these objects.

![Diagram of objects managed by the navigation controller.](https://docs-assets.developer.apple.com/published/743ee76b71b9c1cc86c8e691d6bb17b7/media-1965791.jpg)

### Navigation controller views

A navigation controller is a container view controller — that is, it embeds the content of other view controllers inside of itself. You access a navigation controller’s view from its [view](/documentation/uikit/uiviewcontroller/view) property. This view incorporates the navigation bar, an optional toolbar, and the content view corresponding to the topmost view controller. The following image shows how these views assemble to present the overall navigation interface. In this figure, the navigation interface is further embedded inside a tab bar interface. Although the content of the navigation bar and toolbar views changes, the views themselves don’t. The only view that actually changes is the custom content view provided by the topmost view controller on the navigation stack.

![The views of a navigation controller](https://docs-assets.developer.apple.com/published/aaa68d2967e5dacf95bed1c774852347/media-1965793%402x.png)

> **Note:** Because the content view underlaps the navigation bar, consider that space when designing your view controller content.

The navigation controller manages the creation, configuration, and display of the navigation bar and optional navigation toolbar. Don’t change the navigation bar’s [frame](/documentation/uikit/uiview/frame), [bounds](/documentation/uikit/uiview/bounds), or [alpha](/documentation/uikit/uiview/alpha) values directly. If you subclass [UINavigationBar](/documentation/uikit/uinavigationbar), initialize your navigation controller using the [init(navigationBarClass:toolbarClass:)](/documentation/uikit/uinavigationcontroller/init(navigationbarclass:toolbarclass:)) method. To hide or show the navigation bar, use the [isNavigationBarHidden](/documentation/uikit/uinavigationcontroller/isnavigationbarhidden) property or [setNavigationBarHidden(_:animated:)](/documentation/uikit/uinavigationcontroller/setnavigationbarhidden(_:animated:)) method.

A navigation controller builds the contents of the navigation bar dynamically using the navigation item objects (instances of the [UINavigationItem](/documentation/uikit/uinavigationitem) class) associated with the view controllers on the navigation stack. To change the contents of the navigation bar, configure the navigation items of your custom view controllers. For more information about navigation items, see [UINavigationItem](/documentation/uikit/uinavigationitem).

> **Tip:** Avoid using custom backgrounds and [UIAppearance](/documentation/uikit/uiappearance) APIs to prevent interfering with Liquid Glass in your navigation bar.

### Updating the navigation bar

Each time the top-level view controller changes, the navigation controller updates the navigation bar accordingly. Specifically, the navigation controller updates the bar button items displayed in each of the three navigation bar positions: left, middle, and right. Bar button items are instances of the [UIBarButtonItem](/documentation/uikit/uibarbuttonitem) class. You can create items with custom content or create standard system items depending on your needs.

When your navigation bar displays with Liquid Glass, don’t add a background or apply a tint color. Add color to the text or image in a bar button item with [tintColor](/documentation/uikit/uibarbuttonitem/tintcolor). To add color to the background of a bar button item, set the [style](/documentation/uikit/uibarbuttonitem/style-swift.property) to [UIBarButtonItem.Style.prominent](/documentation/uikit/uibarbuttonitem/style-swift.enum/prominent).

For more information about the navigation bar, see [UINavigationBar](/documentation/uikit/uinavigationbar). For more information about how to create bar button items, see [UIBarButtonItem](/documentation/uikit/uibarbuttonitem).

#### The left item

For all but the root view controller on the navigation stack, the item on the left side of the navigation bar provides navigation back to the previous view controller. The contents of this left-most button are determined as follows:

- If the new top-level view controller has a custom left bar button item, that item is displayed. To specify a custom left bar button item, set the [leftBarButtonItem](/documentation/uikit/uinavigationitem/leftbarbuttonitem) property of the view controller’s navigation item.
- If the top-level view controller doesn’t have a custom left bar button item, but the navigation item of the previous view controller has an object in its [backBarButtonItem](/documentation/uikit/uinavigationitem/backbarbuttonitem) property, the navigation bar displays that item.
- If a custom bar button item isn’t specified by either of the view controllers, the system uses a default back button that displays a back image.
- If there’s only one view controller on the navigation stack, it doesn’t display a back button.

> **Note:** In cases where the title of a back button is too long to fit in the available space, the navigation bar may substitute the string “Back” for the actual button title. The navigation bar does this only if the back button is provided by the previous view controller. If the new top-level view controller has a custom left-bar button item — an object in the [leftBarButtonItem](/documentation/uikit/uinavigationitem/leftbarbuttonitem) or [leftBarButtonItems](/documentation/uikit/uinavigationitem/leftbarbuttonitems) property of its navigation item — the navigation bar doesn’t change the button title.

#### The middle item

The navigation controller updates the middle of the navigation bar as follows:

- If the new top-level view controller has a custom title view, the navigation bar displays that view in place of the default title view. To specify a custom title view, set the [titleView](/documentation/uikit/uinavigationitem/titleview) property of the view controller’s navigation item.
- If no custom title view is set, the navigation bar displays a label containing the view controller’s default title. The string for this label is usually obtained from the [title](/documentation/uikit/uiviewcontroller/title) property of the view controller itself. If you want to display a different title than the one associated with the view controller, set the [title](/documentation/uikit/uiviewcontroller/title) property of the view controller’s navigation item instead.

#### The right item

The navigation controller updates the right side of the navigation bar as follows:

- If the new top-level view controller has custom right bar button items, it displays those items. To specify a custom right-bar button item or items, set the [rightBarButtonItem](/documentation/uikit/uinavigationitem/rightbarbuttonitem) or [rightBarButtonItems](/documentation/uikit/uinavigationitem/rightbarbuttonitems) property of the view controller’s navigation item.
- If the view controller doesn’t have any custom right-bar button items, the navigation bar doesn’t display anything on the right side of the bar.

### Displaying a toolbar

A navigation controller object manages an optional toolbar in its view hierarchy. When displayed, this toolbar obtains its current set of items from the [toolbarItems](/documentation/uikit/uiviewcontroller/toolbaritems) property of the active view controller. When the active view controller changes, the navigation controller updates the toolbar items to match the new view controller, animating the new items into position when appropriate.

The navigation toolbar is hidden by default but you can show it for your navigation interface by calling the [setToolbarHidden(_:animated:)](/documentation/uikit/uinavigationcontroller/settoolbarhidden(_:animated:)) method of your navigation controller object. If not all of your view controllers support toolbar items, your delegate object can call this method to toggle the visibility of the toolbar during subsequent push and pop operations. To use a custom [UIToolbar](/documentation/uikit/uitoolbar) subclass, initialize the navigation controller using the [init(navigationBarClass:toolbarClass:)](/documentation/uikit/uinavigationcontroller/init(navigationbarclass:toolbarclass:)) method. If you use custom toolbar and navigation bar subclasses to create a navigation controller, note that you’re responsible for pushing and setting view controllers before presenting the navigation controller onscreen.

### Adapting to different environments

The navigation interface remains the same in both horizontally compact and horizontally regular environments. When toggling between the two environments, only the size of the navigation controller’s view changes. The navigation controller doesn’t change its view hierarchy or the layout of its views.

When configuring segues between view controllers on a navigation stack, the standard Show and Show Detail segues behave as follows:

The behaviors of other segue types are unchanged.

### Interface behaviors

A navigation controller supports the following behaviors for its interface:

### State preservation

When you assign a value to a navigation controller’s [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) property, it attempts to preserve itself and the contained view controllers on its navigation stack. The navigation controller starts at the bottom of the stack and moves upward, encoding each view controller that also has a valid restoration identifier string. During the next launch cycle, the navigation controller restores the preserved view controllers to the navigation stack in the same order that they were preserved.

The view controllers you push onto the navigation stack may use the same restoration identifiers. The navigation controller automatically stores additional information to ensure that each view controller’s restoration path is unique.

For more information about how state preservation and restoration works, see [Preserving your app’s UI across launches](/documentation/uikit/preserving-your-app-s-ui-across-launches).

## Inherits From

- [UIViewController](/documentation/uikit/uiviewcontroller)

## Inherited By

- [UIImagePickerController](/documentation/uikit/uiimagepickercontroller)
- [UIVideoEditorController](/documentation/uikit/uivideoeditorcontroller)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
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

## Creating a navigation controller

- [init(rootViewController:)](/documentation/uikit/uinavigationcontroller/init(rootviewcontroller:)) Initializes and returns a newly created navigation controller.
- [init(navigationBarClass:toolbarClass:)](/documentation/uikit/uinavigationcontroller/init(navigationbarclass:toolbarclass:)) Initializes and returns a newly created navigation controller that uses your custom bar subclasses.
- [init(nibName:bundle:)](/documentation/uikit/uinavigationcontroller/init(nibname:bundle:)) Creates a navigation controller with the nib file in the specified bundle.
- [init(coder:)](/documentation/uikit/uinavigationcontroller/init(coder:)) Creates a navigation controller from data in an unarchiver.

## Customizing the navigation interface behavior

- [delegate](/documentation/uikit/uinavigationcontroller/delegate) The delegate of the navigation controller object.
- [UINavigationControllerDelegate](/documentation/uikit/uinavigationcontrollerdelegate) The interface for an object that serves as a navigation controller’s delegate.

## Accessing items on the navigation stack

- [topViewController](/documentation/uikit/uinavigationcontroller/topviewcontroller) The view controller at the top of the navigation stack.
- [visibleViewController](/documentation/uikit/uinavigationcontroller/visibleviewcontroller) The view controller associated with the currently visible view in the navigation interface.
- [viewControllers](/documentation/uikit/uinavigationcontroller/viewcontrollers) The view controllers currently on the navigation stack.
- [setViewControllers(_:animated:)](/documentation/uikit/uinavigationcontroller/setviewcontrollers(_:animated:)) Replaces the view controllers currently managed by the navigation controller with the specified items.

## Pushing and popping stack items

- [pushViewController(_:animated:)](/documentation/uikit/uinavigationcontroller/pushviewcontroller(_:animated:)) Pushes a view controller onto the receiver’s stack and updates the display.
- [popViewController(animated:)](/documentation/uikit/uinavigationcontroller/popviewcontroller(animated:)) Pops the top view controller from the navigation stack and updates the display.
- [popToRootViewController(animated:)](/documentation/uikit/uinavigationcontroller/poptorootviewcontroller(animated:)) Pops all the view controllers on the stack except the root view controller and updates the display.
- [popToViewController(_:animated:)](/documentation/uikit/uinavigationcontroller/poptoviewcontroller(_:animated:)) Pops view controllers until the specified view controller is at the top of the navigation stack.
- [interactivePopGestureRecognizer](/documentation/uikit/uinavigationcontroller/interactivepopgesturerecognizer) The gesture recognizer responsible for popping the top view controller off the navigation stack when a person swipes from the leading screen edge.
- [interactiveContentPopGestureRecognizer](/documentation/uikit/uinavigationcontroller/interactivecontentpopgesturerecognizer) The gesture recognizer that handles interactively popping the top view controller off the navigation stack when a person pans horizontally in the view.

## Configuring navigation bars

- [navigationBar](/documentation/uikit/uinavigationcontroller/navigationbar) The navigation bar managed by the navigation controller.
- [setNavigationBarHidden(_:animated:)](/documentation/uikit/uinavigationcontroller/setnavigationbarhidden(_:animated:)) Sets whether the navigation bar is hidden.
- [Customizing your app’s navigation bar](/documentation/uikit/customizing-your-app-s-navigation-bar) Create custom titles, prompts, and buttons in your app’s navigation bar.

## Configuring custom toolbars

- [toolbar](/documentation/uikit/uinavigationcontroller/toolbar) The custom toolbar associated with the navigation controller.
- [setToolbarHidden(_:animated:)](/documentation/uikit/uinavigationcontroller/settoolbarhidden(_:animated:)) Changes the visibility of the navigation controller’s built-in toolbar.
- [isToolbarHidden](/documentation/uikit/uinavigationcontroller/istoolbarhidden) A Boolean indicating whether the navigation controller’s built-in toolbar is visible.
- [hideShowBarDuration](/documentation/uikit/uinavigationcontroller/hideshowbarduration) A variable that specifies the duration when animating the navigation bar.

## Hiding the navigation bar

- [hidesBarsOnTap](/documentation/uikit/uinavigationcontroller/hidesbarsontap) A Boolean value indicating whether the navigation controller allows hiding of its bars using a tap gesture.
- [hidesBarsOnSwipe](/documentation/uikit/uinavigationcontroller/hidesbarsonswipe) A Boolean value indicating whether the navigation bar hides its bars in response to a swipe gesture.
- [hidesBarsWhenVerticallyCompact](/documentation/uikit/uinavigationcontroller/hidesbarswhenverticallycompact) A Boolean value indicating whether the navigation controller hides its bars in a vertically compact environment.
- [hidesBarsWhenKeyboardAppears](/documentation/uikit/uinavigationcontroller/hidesbarswhenkeyboardappears) A Boolean value indicating whether the navigation controller hides its bars when the keyboard appears.
- [isNavigationBarHidden](/documentation/uikit/uinavigationcontroller/isnavigationbarhidden) A Boolean value that indicates whether the navigation bar is hidden.
- [barHideOnTapGestureRecognizer](/documentation/uikit/uinavigationcontroller/barhideontapgesturerecognizer) The gesture recognizer used to hide and show the navigation and toolbar.
- [barHideOnSwipeGestureRecognizer](/documentation/uikit/uinavigationcontroller/barhideonswipegesturerecognizer) The gesture recognizer used to hide the navigation bar and toolbar.

## Displaying view controllers

- [show(_:sender:)](/documentation/uikit/uinavigationcontroller/show(_:sender:)) Presents the specified view controller in the navigation interface.

## Container view controllers

- [Creating a custom container view controller](/documentation/uikit/creating-a-custom-container-view-controller) Create a composite interface by combining content from one or more view controllers with other custom views.
- [UISplitViewController](/documentation/uikit/uisplitviewcontroller) A container view controller that implements a hierarchical interface.
- [UINavigationBar](/documentation/uikit/uinavigationbar) Navigational controls that display in a bar along the top of the screen, usually in conjunction with a navigation controller.
- [UINavigationItem](/documentation/uikit/uinavigationitem) The items that a navigation bar displays when the associated view controller is visible.
- [UITabBarController](/documentation/uikit/uitabbarcontroller) A container view controller that manages a multiselection interface, where the selection determines which child view controller to display.
- [UITabBar](/documentation/uikit/uitabbar) A control that displays one or more buttons in a tab bar for selecting between different subtasks, views, or modes in an app.
- [UITabBarItem](/documentation/uikit/uitabbaritem) An object that describes an item in a tab bar.
- [UITab](/documentation/uikit/uitab) An object that manages a tab in a tab bar.
- [UITabAccessory](/documentation/uikit/uitabaccessory)
- [UISearchTab](/documentation/uikit/uisearchtab) A tab subclass that represents the system’s search tab.
- [UITabGroup](/documentation/uikit/uitabgroup) An object that manages a collection of tab objects.
- [UIPageViewController](/documentation/uikit/uipageviewcontroller) A container view controller that manages navigation between pages of content, where a subview controller manages each page.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
