---
title: UISplitViewController
description: A container view controller that implements a hierarchical interface.
source: https://developer.apple.com/documentation/uikit/uisplitviewcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uisplitviewcontroller.json
timestamp: 2026-04-14T13:14:52.945Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UISplitViewController

**Available on:** iOS 3.2+, iPadOS 3.2+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A container view controller that implements a hierarchical interface.

```swift
@MainActor class UISplitViewController
```

## Overview

A split view controller is a container view controller that manages child view controllers in a hierarchical interface. In this type of interface, changes in one view controller drive changes in the content of another.

Split view interfaces are most suitable for filterable content or navigating content hierarchies, like traversing the folders and notes within the Notes app to view each note. In the Notes app, selecting a folder in the primary sidebar shows the list of notes in that folder, and selecting a note from the list shows the contents of that specific note in the secondary view.

![Diagram showing a triple-column split view interface with the primary, supplementary, secondary, and inspector columns labeled.](https://docs-assets.developer.apple.com/published/6a0c2099a8b42457fdfbcbd3c18c695b/UISplitViewController-1%402x.png)

When you build your app’s user interface, the split view controller is typically the root view controller of your app’s window. The split view controller has no significant appearance of its own. Most of its appearance is defined by the child view controllers you install.

> **Note:** You can’t push a split view controller onto a navigation stack. Although it’s possible to install a split view controller as a child in some other container view controllers, doing so isn’t recommended in most cases. For design guidance, see [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views/).

### Split view styles

In iOS 14 and later, [UISplitViewController](/documentation/uikit/uisplitviewcontroller) supports column-style layouts. A column-style split view controller lets you create an interface with two or three columns by using [init(style:)](/documentation/uikit/uisplitviewcontroller/init(style:)) with the appropriate [style](/documentation/uikit/uisplitviewcontroller/style-swift.property):

- Use the [UISplitViewController.Style.doubleColumn](/documentation/uikit/uisplitviewcontroller/style-swift.enum/doublecolumn) style to create a split view interface with a two-column layout. This style of split view controller manages two child view controllers, placed in the primary and secondary columns.
- Use the [UISplitViewController.Style.tripleColumn](/documentation/uikit/uisplitviewcontroller/style-swift.enum/triplecolumn) style to create a split view interface with a three-column layout. This style of split view controller manages three child view controllers, placed in the primary, supplementary, and secondary columns.

![Diagram showing a double-column and a triple-column split view interface, each with an inspector.](https://docs-assets.developer.apple.com/published/23c5e4fd7c1663d788630da117b02829/UISplitViewController-2%402x.png)

In either the two-column or three-column layout, [UISplitViewController](/documentation/uikit/uisplitviewcontroller) supports an inspector column on the trailing edge of the view. Use the inspector column to provide auxiliary information related to the secondary column, or for controls that affect content in the secondary column.

Before iOS 14, [UISplitViewController](/documentation/uikit/uisplitviewcontroller) supported just one split view interface style with a primary view controller and a secondary view controller. This classic interface style applies to split view controllers created using any other approach than [init(style:)](/documentation/uikit/uisplitviewcontroller/init(style:)). Split view controllers with the classic interface have a [style](/documentation/uikit/uisplitviewcontroller/style-swift.property) of [UISplitViewController.Style.unspecified](/documentation/uikit/uisplitviewcontroller/style-swift.enum/unspecified) and they don’t respond to any of the column-style APIs introduced in iOS 14 and later.

### Child view controllers

In a column-style split view interface, use the [setViewController(_:for:)](/documentation/uikit/uisplitviewcontroller/setviewcontroller(_:for:)) and [viewController(for:)](/documentation/uikit/uisplitviewcontroller/viewcontroller(for:)) methods to set and get view controllers for each column. The split view controller wraps all of its child view controllers in navigation controllers. If you set a child view controller that’s not a navigation controller, the split view controller creates a navigation controller for it. The split view controller returns your original view controller through [viewController(for:)](/documentation/uikit/uisplitviewcontroller/viewcontroller(for:)), but its [children](/documentation/uikit/uiviewcontroller/children) property contains the navigation controller it used to wrap your view controller. After you assign view controllers to specific columns, you can show and hide those columns using [show(_:)](/documentation/uikit/uisplitviewcontroller/show(_:)) or [hide(_:)](/documentation/uikit/uisplitviewcontroller/hide(_:)).

In a classic split view interface, you can configure the child view controllers using Interface Builder or programmatically by assigning the view controllers to the [viewControllers](/documentation/uikit/uisplitviewcontroller/viewcontrollers) property. In cases where you need to change either the primary or secondary view controller, it’s recommended that you do so using the [show(_:sender:)](/documentation/uikit/uisplitviewcontroller/show(_:sender:)) and [showDetailViewController(_:sender:)](/documentation/uikit/uisplitviewcontroller/showdetailviewcontroller(_:sender:)) methods. Using these methods (instead of modifying the [viewControllers](/documentation/uikit/uisplitviewcontroller/viewcontrollers) property directly) lets the split view controller present the specified view controller in a way that’s most appropriate for the current display mode and size class.

### Interface transitions

The split view controller performs collapse and expand transitions in response to certain changes in its interface. For example, transitions occur when the interface’s size class toggles between horizontally regular and horizontally compact, when a user interaction hides or shows a column, or when you hide or show columns programmatically. The split view controller works with its [delegate](/documentation/uikit/uisplitviewcontroller/delegate) object to perform collapse and expand transitions. The delegate is an object you provide that adopts the [UISplitViewControllerDelegate](/documentation/uikit/uisplitviewcontrollerdelegate) protocol.

In a column-style split view interface, when the interface is collapsed, you can show a different view controller than your primary, supplementary, or secondary. Set the desired view controller for the [UISplitViewController.Column.compact](/documentation/uikit/uisplitviewcontroller/column/compact) column using [setViewController(_:for:)](/documentation/uikit/uisplitviewcontroller/setviewcontroller(_:for:)). If you want to further customize transitions for collapsing and expanding the interface, see [Column-style split views](/documentation/uikit/uisplitviewcontrollerdelegate#Column-style-split-views).

Configure your own custom views and interactions to show or hide the inspector column. When the interface is collapsed, the split view controller displays the inspector as a sheet over the secondary column.

For information about managing transitions in classic split view interfaces, see [Classic split views](/documentation/uikit/uisplitviewcontrollerdelegate#Classic-split-views).

### Display mode

A split view controller’s current display mode represents the visual arrangement of its child view controllers. It determines how many of its child view controllers are shown, and how they’re positioned in relation to each other. For example, you can arrange the child view controllers so that they appear side-by-side, so that only one at a time is visible, or so that one is partially obscured by the others.

You don’t set the display mode directly; instead, you set a preferred display mode by using the [preferredDisplayMode](/documentation/uikit/uisplitviewcontroller/preferreddisplaymode) property. The split view controller makes every effort to respect the display mode you specify, but it may not be able to accommodate that mode visually because of space constraints. For example, the split view controller can’t display its child view controllers side-by-side in a horizontally compact environment. For possible configurations, see [UISplitViewController.DisplayMode](/documentation/uikit/uisplitviewcontroller/displaymode-swift.enum).

![Flow diagram showing the possible state transitions between display modes, based on split behavior and column style.](https://docs-assets.developer.apple.com/published/3ca2e98704a9ec01f1bc5c968908aaf7/UISplitViewController-3%402x.png)

After you set the preferred display mode, the split view controller updates itself and reflects the actual display mode in the [displayMode](/documentation/uikit/uisplitviewcontroller/displaymode-swift.property) property. If you just want to change which columns are shown, try using [show(_:)](/documentation/uikit/uisplitviewcontroller/show(_:)) or [hide(_:)](/documentation/uikit/uisplitviewcontroller/hide(_:)). The split view controller will determine how to update the display mode to display the desired columns.

### Gesture and button support

There are several ways for user interaction to change the current display mode.

The split view controller installs a built-in gesture recognizer that lets the user change the display mode using a swipe. You can suppress this gesture recognizer by setting the [presentsWithGesture](/documentation/uikit/uisplitviewcontroller/presentswithgesture) property to [false](/documentation/Swift/false). For example, you might set this property to [false](/documentation/Swift/false) if you want your primary view controller to always be visible.

If [presentsWithGesture](/documentation/uikit/uisplitviewcontroller/presentswithgesture) is [true](/documentation/Swift/true), the split view controller also presents a special bar button item for changing the display mode. The split view controller manages the behavior, appearance, and positioning of this item. It appears as a sidebar toggle icon for [UISplitViewController.SplitBehavior.tile](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.enum/tile) and as a back-chevron icon for [UISplitViewController.SplitBehavior.overlay](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.enum/overlay) and [UISplitViewController.SplitBehavior.displace](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.enum/displace). Tapping this button transitions to a new display mode based on the current display mode and split behavior.

For three-column split view interfaces—those with a [style](/documentation/uikit/uisplitviewcontroller/style-swift.property) of [UISplitViewController.Style.tripleColumn](/documentation/uikit/uisplitviewcontroller/style-swift.enum/triplecolumn)—another property that affects display mode is [showsSecondaryOnlyButton](/documentation/uikit/uisplitviewcontroller/showssecondaryonlybutton). When this property is [true](/documentation/Swift/true), the split view controller presents another bar button item for toggling the display mode to and from [UISplitViewController.DisplayMode.secondaryOnly](/documentation/uikit/uisplitviewcontroller/displaymode-swift.enum/secondaryonly). The split view controller manages the behavior, appearance, and positioning of this item. It appears as a double-arrow icon. When a user taps this button, it toggles the display mode to or from [UISplitViewController.DisplayMode.secondaryOnly](/documentation/uikit/uisplitviewcontroller/displaymode-swift.enum/secondaryonly).

### Split behavior

A split view controller’s split behavior controls how its secondary view controller appears in relation to the others. You can configure this behavior so that the secondary view controller always appears side-by-side with the others, so that it’s partially obscured by the others, or so that it’s displaced offscreen opposite the others to make space for them.

You don’t set the split behavior directly; instead, you set a preferred split behavior by using the [preferredSplitBehavior](/documentation/uikit/uisplitviewcontroller/preferredsplitbehavior) property. This change takes effect after the next layout occurs. The split view controller reflects the actual split behavior in the [splitBehavior](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.property) property. The value of the [splitBehavior](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.property) property affects which display modes are available for the split view controller. For possible configurations, see [UISplitViewController.SplitBehavior](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.enum).

![Diagram showing a triple-column split view interface using the tile, overlay, and displace split behaviors.](https://docs-assets.developer.apple.com/published/21d48e2a49ece64105122059913f0374/UISplitViewController-4%402x.png)

### Column-width customization

You can specify custom widths for the primary, supplementary, secondary, and inspector columns of the split view interface by setting their respective minimum, maximum, and preferred width properties listed in [Managing column dimensions](/documentation/uikit/uisplitviewcontroller#Managing-column-dimensions). If you don’t specify values for these properties, they default to [automaticDimension](/documentation/uikit/uisplitviewcontroller/automaticdimension).

### Message forwarding

A split view controller interposes itself between the app’s window and its child view controllers. As a result, all messages to the child view controllers must flow through the split view controller. Messages are forwarded as appropriate. For example, view appearance and disappearance messages are sent only when the corresponding child view controller actually appears onscreen.

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
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating a split view controller

- [init(style:)](/documentation/uikit/uisplitviewcontroller/init(style:)) Creates a split view controller with the specified column style.
- [init(nibName:bundle:)](/documentation/uikit/uisplitviewcontroller/init(nibname:bundle:)) Creates a split view controller with the nib file in the specified bundle.
- [init(coder:)](/documentation/uikit/uisplitviewcontroller/init(coder:)) Creates a split view controller from data in an unarchiver.

## Getting the split view style

- [style](/documentation/uikit/uisplitviewcontroller/style-swift.property) The style that determines the number of columns that the split view interface displays.
- [UISplitViewController.Style](/documentation/uikit/uisplitviewcontroller/style-swift.enum) Constants that describe the number of columns the split view interface displays.

## Customizing the split view transitions

- [delegate](/documentation/uikit/uisplitviewcontroller/delegate) The delegate you use to manage changes to a split view interface.
- [UISplitViewControllerDelegate](/documentation/uikit/uisplitviewcontrollerdelegate) The methods adopted by the object you use to manage changes to a split view interface.

## Managing the child view controllers

- [UISplitViewController.Column](/documentation/uikit/uisplitviewcontroller/column) Constants that describe the columns within the split view interface.
- [setViewController(_:for:)](/documentation/uikit/uisplitviewcontroller/setviewcontroller(_:for:)) Presents the provided view controller in the specified column of the split view interface.
- [viewController(for:)](/documentation/uikit/uisplitviewcontroller/viewcontroller(for:)) Returns the view controller associated with the specified column of the split view interface.
- [viewControllers](/documentation/uikit/uisplitviewcontroller/viewcontrollers) The array of view controllers the split view controller manages.

## Displaying the child view controllers

- [show(_:)](/documentation/uikit/uisplitviewcontroller/show(_:)) Presents the view controller in the specified column of the split view interface.
- [hide(_:)](/documentation/uikit/uisplitviewcontroller/hide(_:)) Dismisses the view controller in the specified column of the split view interface.
- [isShowing(_:)](/documentation/uikit/uisplitviewcontroller/isshowing(_:)) A Boolean value that indicates whether the split view interface is showing the specified column.
- [show(_:sender:)](/documentation/uikit/uisplitviewcontroller/show(_:sender:)) Presents the specified view controller as the primary view controller in the split view interface.
- [showDetailViewController(_:sender:)](/documentation/uikit/uisplitviewcontroller/showdetailviewcontroller(_:sender:)) Presents the specified view controller as the secondary view controller of the split view interface.

## Managing the display mode

- [preferredDisplayMode](/documentation/uikit/uisplitviewcontroller/preferreddisplaymode) The preferred arrangement of the split view interface.
- [displayMode](/documentation/uikit/uisplitviewcontroller/displaymode-swift.property) The current arrangement of the split view interface.
- [displayModeButtonItem](/documentation/uikit/uisplitviewcontroller/displaymodebuttonitem) A button that changes the display mode of the split view controller.
- [presentsWithGesture](/documentation/uikit/uisplitviewcontroller/presentswithgesture) Specifies whether a hidden view controller can be presented and dismissed using a swipe gesture.
- [showsSecondaryOnlyButton](/documentation/uikit/uisplitviewcontroller/showssecondaryonlybutton) Specifies whether the secondary view controller shows a button to toggle to and from the secondary-only display mode.
- [UISplitViewController.DisplayMode](/documentation/uikit/uisplitviewcontroller/displaymode-swift.enum) Constants that describe the possible arrangements for a split view interface.
- [displayModeButtonVisibility](/documentation/uikit/uisplitviewcontroller/displaymodebuttonvisibility-swift.property) A setting that determines whether the display mode button is visible in the interface.
- [UISplitViewController.DisplayModeButtonVisibility](/documentation/uikit/uisplitviewcontroller/displaymodebuttonvisibility-swift.enum) Constants that determine the visibility of the display mode button.

## Managing the split behavior

- [preferredSplitBehavior](/documentation/uikit/uisplitviewcontroller/preferredsplitbehavior) The preferred behavior that determines how the child view controllers appear in relation to each other.
- [splitBehavior](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.property) The current behavior that determines how the child view controllers appear in relation to each other.
- [UISplitViewController.SplitBehavior](/documentation/uikit/uisplitviewcontroller/splitbehavior-swift.enum) Constants that describe the possible ways that the child view controllers appear in relation to each other.

## Managing column dimensions

- [isCollapsed](/documentation/uikit/uisplitviewcontroller/iscollapsed) A Boolean value that indicates whether only one of the child view controllers displays.
- [preferredPrimaryColumnWidthFraction](/documentation/uikit/uisplitviewcontroller/preferredprimarycolumnwidthfraction) The relative width of the primary view controller’s content.
- [preferredPrimaryColumnWidth](/documentation/uikit/uisplitviewcontroller/preferredprimarycolumnwidth) The preferred width, in points, of the primary view controller’s content.
- [primaryColumnWidth](/documentation/uikit/uisplitviewcontroller/primarycolumnwidth) The width, in points, of the primary view controller’s content.
- [minimumPrimaryColumnWidth](/documentation/uikit/uisplitviewcontroller/minimumprimarycolumnwidth) The minimum width, in points, for the primary view controller’s content.
- [maximumPrimaryColumnWidth](/documentation/uikit/uisplitviewcontroller/maximumprimarycolumnwidth) The maximum width, in points, for the primary view controller’s content.
- [preferredSupplementaryColumnWidthFraction](/documentation/uikit/uisplitviewcontroller/preferredsupplementarycolumnwidthfraction) The relative width of the supplementary view controller’s content.
- [preferredSupplementaryColumnWidth](/documentation/uikit/uisplitviewcontroller/preferredsupplementarycolumnwidth) The preferred width, in points, of the supplementary view controller’s content.
- [supplementaryColumnWidth](/documentation/uikit/uisplitviewcontroller/supplementarycolumnwidth) The width, in points, of the supplementary view controller’s content.
- [minimumSupplementaryColumnWidth](/documentation/uikit/uisplitviewcontroller/minimumsupplementarycolumnwidth) The minimum width, in points, for the supplementary view controller’s content.
- [maximumSupplementaryColumnWidth](/documentation/uikit/uisplitviewcontroller/maximumsupplementarycolumnwidth) The maximum width, in points, for the supplementary view controller’s content.
- [preferredSecondaryColumnWidth](/documentation/uikit/uisplitviewcontroller/preferredsecondarycolumnwidth) The preferred width, in points, for the secondary view controller’s content.
- [preferredSecondaryColumnWidthFraction](/documentation/uikit/uisplitviewcontroller/preferredsecondarycolumnwidthfraction) The relative width of the secondary view controller’s content.
- [minimumSecondaryColumnWidth](/documentation/uikit/uisplitviewcontroller/minimumsecondarycolumnwidth) The minimum width, in points, for the secondary view controller’s content.
- [preferredInspectorColumnWidth](/documentation/uikit/uisplitviewcontroller/preferredinspectorcolumnwidth) The preferred width, in points, for the inspector view controller’s content.
- [preferredInspectorColumnWidthFraction](/documentation/uikit/uisplitviewcontroller/preferredinspectorcolumnwidthfraction) The relative width of the inspector view controller’s content.
- [maximumInspectorColumnWidth](/documentation/uikit/uisplitviewcontroller/maximuminspectorcolumnwidth) The maximum width, in points, for the inspector view controller’s content.
- [minimumInspectorColumnWidth](/documentation/uikit/uisplitviewcontroller/minimuminspectorcolumnwidth) The minimum width, in points, for the inspector view controller’s content.
- [automaticDimension](/documentation/uikit/uisplitviewcontroller/automaticdimension) The default value to apply to a dimension.

## Inspecting the layout environment

- [UISplitViewController.LayoutEnvironment](/documentation/uikit/uisplitviewcontroller/layoutenvironment) Constants that indicate the current layout of the containing split view controller.

## Positioning the primary view controller

- [primaryEdge](/documentation/uikit/uisplitviewcontroller/primaryedge-swift.property) The side on which the primary view controller sits.
- [UISplitViewController.PrimaryEdge](/documentation/uikit/uisplitviewcontroller/primaryedge-swift.enum) Constants that indicate the side on which the primary view controller sits.

## Managing the background style

- [primaryBackgroundStyle](/documentation/uikit/uisplitviewcontroller/primarybackgroundstyle) The background style of the primary view controller.
- [UISplitViewController.BackgroundStyle](/documentation/uikit/uisplitviewcontroller/backgroundstyle) Styles that apply a visual effect to the background of a primary view controller.

## Container view controllers

- [Creating a custom container view controller](/documentation/uikit/creating-a-custom-container-view-controller) Create a composite interface by combining content from one or more view controllers with other custom views.
- [UINavigationController](/documentation/uikit/uinavigationcontroller) A container view controller that defines a stack-based scheme for navigating hierarchical content.
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
