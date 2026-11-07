---
title: UITabBarController
description: A container view controller that manages a multiselection interface, where the selection determines which child view controller to display.
source: https://developer.apple.com/documentation/uikit/uitabbarcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uitabbarcontroller.json
timestamp: 2026-06-26T06:39:37.091Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UITabBarController

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A container view controller that manages a multiselection interface, where the selection determines which child view controller to display.

```swift
@MainActor class UITabBarController
```

## Overview

The tab bar interface displays tabs at the bottom of the window for selecting between the different modes and for displaying the views for that mode. This class is generally used as-is, but may also be subclassed.

Each tab of a tab bar controller interface is associated with a custom view controller. When the user selects a specific tab, the tab bar controller displays the root view of the corresponding view controller, replacing any previous views. (User taps always display the root view of the tab, regardless of which tab was previously selected. This is true even if the tab was already selected.) Because selecting a tab replaces the contents of the interface, the type of interface managed in each tab need not be similar in any way. In fact, tab bar interfaces are commonly used either to present different types of information or to present the same information using a completely different style of interface. The following image shows the tab bar interface presented by the Clock app, each tab of which presents a type of time based information.

![Four screenshots of the Clock app, showing the World Clock, Alarm, Stopwatch, and Timer tabs](https://docs-assets.developer.apple.com/published/9b792d41bfe1e8281689c4cba29bf0a0/media-2934713%402x.png)

You should never access the tab bar view of a tab bar controller directly. To configure the tabs of a tab bar controller, you assign the view controllers that provide the root view for each tab to the [viewControllers](/documentation/uikit/uitabbarcontroller/viewcontrollers) property. The order in which you specify the view controllers determines the order in which they appear in the tab bar. When setting this property, you should also assign a value to the [selectedViewController](/documentation/uikit/uitabbarcontroller/selectedviewcontroller) property to indicate which view controller is selected initially. (You can also select view controllers by array index using the [selectedIndex](/documentation/uikit/uitabbarcontroller/selectedindex) property.) When you embed the tab bar controller’s view (obtained using the inherited [view](/documentation/uikit/uiviewcontroller/view) property) in your app window, the tab bar controller automatically selects that view controller and displays its contents, resizing them as needed to fit the tab bar interface.

Tab bar items are configured through their corresponding view controller. To associate a tab bar item with a view controller, create a new instance of the [UITabBarItem](/documentation/uikit/uitabbaritem) class, configure it appropriately for the view controller, and assign it to the view controller’s [tabBarItem](/documentation/uikit/uiviewcontroller/tabbaritem) property. If you don’t provide a custom tab bar item for your view controller, the view controller creates a default item containing no image and the text from the view controller’s [title](/documentation/uikit/uiviewcontroller/title) property.

As the user interacts with a tab bar interface, the tab bar controller object sends notifications about the interactions to its delegate. The delegate can be any object you specify but must conform to the [UITabBarControllerDelegate](/documentation/uikit/uitabbarcontrollerdelegate) protocol. You can use the delegate to prevent specific tab bar items from being selected and to perform additional tasks when tabs are selected. You can also use the delegate to monitor changes to the tab bar that are made by the More navigation controller, which is described in more detail in [The More navigation controller](/documentation/uikit/uitabbarcontroller#The-More-navigation-controller).

### The views of a tab bar controller

Because the [UITabBarController](/documentation/uikit/uitabbarcontroller) class inherits from the [UIViewController](/documentation/uikit/uiviewcontroller) class, tab bar controllers have their own view that’s accessible through the [view](/documentation/uikit/uiviewcontroller/view) property. The view for a tab bar controller is just a container for a tab bar view and the view containing your custom content. The tab bar view provides the selection controls for the user and consists of one or more tab bar items. The following image shows how these views are assembled to present the overall tab bar interface. Although the items in the tab bar and toolbar views can change, the views that manage them don’t. Only the custom content view changes to reflect the view controller for the currently selected tab.

![A diagram of the views that are stacked together in a tab bar interface](https://docs-assets.developer.apple.com/published/5b64300bc1148d4c5228708f98e4fec5/media-2934714%402x.png)

You can use navigation controllers or custom view controllers as the root view controller for a tab. If the root view controller is a navigation controller, the tab bar controller makes further adjustments to the size of the displayed navigation content so that it doesn’t overlap the tab bar. Any views you display in a tab bar interface should therefore have their [autoresizingMask](/documentation/uikit/uiview/autoresizingmask-swift.property) property set to resize the view appropriately under any conditions.

### The More navigation controller

The tab bar has limited space for displaying your custom items. If you add six or more custom view controllers to a tab bar controller, the tab bar controller displays only the first four items plus the standard More item on the tab bar. Tapping the More item brings up a standard interface for selecting the remaining items.

The interface for the standard More item includes an Edit button that allows the user to reconfigure the tab bar. By default, the user is allowed to rearrange all items on the tab bar. If you do not want the user to modify some items, though, you can remove the appropriate view controllers from the array in the [customizableViewControllers](/documentation/uikit/uitabbarcontroller/customizableviewcontrollers) property.

> **Note:** Tab bar customization and the More interface are not available in tvOS.

### State preservation

When you assign a value to this view controller’s [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) property, it preserves a reference to the view controller in the selected tab. At restore time, it uses the reference to select the tab with the same view controller.

When preserving a tab bar controller, assign unique restoration identifiers to the child view controllers you want to preserve. Omitting a restoration identifier from a child view controller causes that tab to return to its default configuration. Although the tab bar controller saves its tabs in the same order that they are listed in the [viewControllers](/documentation/uikit/uitabbarcontroller/viewcontrollers) property, the save order is actually irrelevant. Your code is responsible for providing the new tab bar controller during the next launch cycle, so your code can adjust the order of the tabs as needed. The state preservation system restores the contents of each tab based on the assigned restoration identifier, not based on the position of the tab.

For more information about how state preservation and restoration works, see [App Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007072).

### Differences between iOS and tvOS

Tab bar controllers serve the same purpose in tvOS as in iOS, but provide slightly different user interface features:

- In tvOS, the tab bar interface appears at the top of the window. When focus leaves the tab bar, the tab bar remains fixed at the top of the screen by default. To create an interface where the tab bar doesn’t remain fixed, but instead scrolls with the content, set the [tabBarObservedScrollView](/documentation/uikit/uiviewcontroller/tabbarobservedscrollview) property to the appropriate scroll view. In iOS, the tab bar always stays pinned at the bottom of the screen.
- In tvOS, swiping down from the tab bar moves focus into the content view; specifically, to the first focusable view that’s visually below the selected tab. Swiping down behaves like a normal focus-changing gesture — that is, focus moves in the direction the user swiped. If nothing is focusable immediately below the selected tab, the closest focusable view is focused instead. In iOS, the tab bar always remains in focus at the bottom of the screen.
- In tvOS, pressing the Select button while a tab is focused moves focus into the content view. Because there’s no direction associated with this change, focus moves to the most appropriate view specified in the content view’s [preferredFocusEnvironments](/documentation/uikit/uifocusenvironment/preferredfocusenvironments) property. In iOS, there’s no notion of focusing between views.
- Tab bar controllers in tvOS don’t support customization. A tab bar controller displays only the number of view controllers from its [viewControllers](/documentation/uikit/uitabbarcontroller/viewcontrollers) array that fit on the screen, and doesn’t provide the More interface seen in iOS.

## Inherits From

- [UIViewController](/documentation/uikit/uiviewcontroller)

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
- [UITabBarDelegate](/documentation/uikit/uitabbardelegate)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating tab bar controllers

- [init(tabs:)](/documentation/uikit/uitabbarcontroller/init(tabs:)) Creates a tab bar controller with the specified tabs.

## Assigning tabs

- [tabs](/documentation/uikit/uitabbarcontroller/tabs) An array of tabs that the tab bar displays.
- [setTabs(_:animated:)](/documentation/uikit/uitabbarcontroller/settabs(_:animated:)) Sets the root tabs of the tab bar controller, with an option to animate the change.

## Supporting the sidebar

- [mode](/documentation/uikit/uitabbarcontroller/mode-swift.property) The display mode for a tab bar.
- [UITabBarController.Mode](/documentation/uikit/uitabbarcontroller/mode-swift.enum) A tab bar’s display mode.
- [sidebar](/documentation/uikit/uitabbarcontroller/sidebar-swift.property) A tab bar’s corresponding sidebar.
- [UITabBarController.Sidebar](/documentation/uikit/uitabbarcontroller/sidebar-swift.class) An object for managing and configuring the sidebar.
- [UITabSidebarItem](/documentation/uikit/uitabsidebaritem)
- [UITabSidebarItem.Request](/documentation/uikit/uitabsidebaritem/request)
- [UITabBarController.Sidebar.Animating](/documentation/uikit/uitabbarcontroller/sidebar-swift.class/animating)

## Adapting to the tab bar layout

- [contentLayoutGuide](/documentation/uikit/uitabbarcontroller/contentlayoutguide) The content layout guide provides the layout area for the UITabBarController unobscured by the tab bar or sidebar.

## Customizing the tab bar behavior

- [delegate](/documentation/uikit/uitabbarcontroller/delegate) The tab bar controller’s delegate object.
- [UITabBarControllerDelegate](/documentation/uikit/uitabbarcontrollerdelegate) A set of methods you implement to customize the behavior of a tab bar.
- [tabBarMinimizeBehavior](/documentation/uikit/uitabbarcontroller/tabbarminimizebehavior) Defines the minimize behavior for the tab bar, if it is supported.
- [UITabBarController.MinimizeBehavior](/documentation/uikit/uitabbarcontroller/minimizebehavior)

## Customizing the tab bar appearance

- [isTabBarHidden](/documentation/uikit/uitabbarcontroller/istabbarhidden) Determines if the active tab bar is currently hidden.
- [setTabBarHidden(_:animated:)](/documentation/uikit/uitabbarcontroller/settabbarhidden(_:animated:)) Changes the active tab bar’s visibility with an option to animate the change.
- [bottomAccessory](/documentation/uikit/uitabbarcontroller/bottomaccessory) An optional bottom accessory of the tab bar controller.
- [setBottomAccessory(_:animated:)](/documentation/uikit/uitabbarcontroller/setbottomaccessory(_:animated:)) Sets a bottom accessory with an option to animate the change.
- [compactTabIdentifiers](/documentation/uikit/uitabbarcontroller/compacttabidentifiers) An optional filter to display only select root-level tabs when in a compact appearance.
- [customizationIdentifier](/documentation/uikit/uitabbarcontroller/customizationidentifier) The customization identifier for the tab bar and sidebar for persistence.

## Accessing the tab bar controller properties

- [tabBar](/documentation/uikit/uitabbarcontroller/tabbar) The tab bar view associated with this controller.
- [tab(forIdentifier:)](/documentation/uikit/uitabbarcontroller/tab(foridentifier:)) Returns the `tab` matching the specified `identifier` in the tab bar controller’s tabs. Returns nil if no tab is found matching the `identifier`.

## Managing the view controllers

- [viewControllers](/documentation/uikit/uitabbarcontroller/viewcontrollers) An array of the root view controllers displayed by the tab bar interface.
- [setViewControllers(_:animated:)](/documentation/uikit/uitabbarcontroller/setviewcontrollers(_:animated:)) Sets the root view controllers of the tab bar controller.
- [customizableViewControllers](/documentation/uikit/uitabbarcontroller/customizableviewcontrollers) The subset of view controllers managed by this tab bar controller that can be customized.
- [moreNavigationController](/documentation/uikit/uitabbarcontroller/morenavigationcontroller) The view controller that manages the More navigation interface.

## Managing the selected tab

- [selectedTab](/documentation/uikit/uitabbarcontroller/selectedtab) The currently selected tab, which can be a root tab or any of their descendants.
- [selectedViewController](/documentation/uikit/uitabbarcontroller/selectedviewcontroller) The view controller associated with the currently selected tab item.
- [selectedIndex](/documentation/uikit/uitabbarcontroller/selectedindex) The index of the view controller associated with the currently selected tab item.

## Instance Properties

- [prominentTabIdentifier](/documentation/uikit/uitabbarcontroller/prominenttabidentifier) The identifier of the tab that should be displayed as prominent. Where supported, the specified tab receives enhanced visual emphasis in the tab bar. If this property is nil, and there is a `UISearchTab` that could become prominent (when `automaticallyActivatesSearch = true`), then the search tab will receive the prominent treatment by default.

## Instance Methods

- [performBatchUpdates(_:)](/documentation/uikit/uitabbarcontroller/performbatchupdates(_:)) Animates multiple tab changes as a single update.
- [setProminentTabIdentifier(_:animated:)](/documentation/uikit/uitabbarcontroller/setprominenttabidentifier(_:animated:)) Sets the prominent tab identifier with an option to animate the change.

## Container view controllers

- [Creating a custom container view controller](/documentation/uikit/creating-a-custom-container-view-controller) Create a composite interface by combining content from one or more view controllers with other custom views.
- [UISplitViewController](/documentation/uikit/uisplitviewcontroller) A container view controller that implements a hierarchical interface.
- [UINavigationController](/documentation/uikit/uinavigationcontroller) A container view controller that defines a stack-based scheme for navigating hierarchical content.
- [UINavigationBar](/documentation/uikit/uinavigationbar) Navigational controls that display in a bar along the top of the screen, usually in conjunction with a navigation controller.
- [UINavigationItem](/documentation/uikit/uinavigationitem) The items that a navigation bar displays when the associated view controller is visible.
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
