---
title: UICollectionView
description: An object that manages an ordered collection of data items and presents them using customizable layouts.
source: https://developer.apple.com/documentation/uikit/uicollectionview
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uicollectionview.json
timestamp: 2026-06-26T06:39:36.937Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UICollectionView

**Available on:** iOS 6.0+, iPadOS 6.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> An object that manages an ordered collection of data items and presents them using customizable layouts.

```swift
@MainActor class UICollectionView
```

## Overview

When you add a collection view to your user interface, your app’s main job is to manage the data associated with that collection view. The collection view gets its data from the data source object, stored in the collection view’s [dataSource](/documentation/uikit/uicollectionview/datasource) property. For your data source, you can use a [UICollectionViewDiffableDataSource](/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa) object, which provides the behavior you need to simply and efficiently manage updates to your collection view’s data and user interface. Alternatively, you can create a custom data source object by adopting the [UICollectionViewDataSource](/documentation/uikit/uicollectionviewdatasource) protocol.

Data in the collection view is organized into individual items, which you can group into sections for presentation. An item is the smallest unit of data you want to present. For example, in a photos app, an item might be a single image. The collection view presents items onscreen using a cell, which is an instance of the [UICollectionViewCell](/documentation/uikit/uicollectionviewcell) class that your data source configures and provides.

![A collection view using the flow layout.](https://docs-assets.developer.apple.com/published/6b21b5041dface01efa4373940c4c7b7/uicollectionview-1%402x.png)

In addition to its cells, a collection view can present data using other types of views. These supplementary views can be, for example, section headers and footers that are separate from the individual cells but still convey information. Support for supplementary views is optional and defined by the collection view’s layout object, which is also responsible for defining the placement of those views.

Besides embedding a [UICollectionView](/documentation/uikit/uicollectionview) in your user interface, you use the methods of the collection view to ensure that the visual presentation of items matches the order in your data source object. A [UICollectionViewDiffableDataSource](/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa) object manages this process automatically. If you’re using a custom data source, then whenever you add, delete, or rearrange data in your collection, you use the methods of [UICollectionView](/documentation/uikit/uicollectionview) to insert, delete, and rearrange the corresponding cells.

You also use the collection view object to manage the selected items, although for this behavior the collection view works with its associated [delegate](/documentation/uikit/uicollectionview/delegate) object.

### Layouts

A layout object defines the visual arrangement of the content in the collection view. A subclass of the [UICollectionViewLayout](/documentation/uikit/uicollectionviewlayout) class, the layout object defines the organization and location of all cells and supplementary views inside the collection view. Although it defines their locations, the layout object doesn’t actually apply that information to the corresponding views. The collection view applies layout information to the corresponding views because the creation of cells and supplementary views involves coordination between the collection view and your data source object. The layout object is like another data source, except it provides visual information instead of item data.

You typically specify a layout object when you create a collection view, but you can also change the layout of a collection view dynamically. The layout object is stored in the [collectionViewLayout](/documentation/uikit/uicollectionview/collectionviewlayout) property. Setting this property directly updates the layout immediately, without animating the changes. If you want to animate the changes, call the [setCollectionViewLayout(_:animated:completion:)](/documentation/uikit/uicollectionview/setcollectionviewlayout(_:animated:completion:)) method instead.

To create an interactive transition — one that is driven by a gesture recognizer or touch events — use the [startInteractiveTransition(to:completion:)](/documentation/uikit/uicollectionview/startinteractivetransition(to:completion:)) method to change the layout object. That method installs an intermediate layout object, which works with your gesture recognizer or event-handling code to track the transition progress. When your event-handling code determines that the transition is finished, it calls the [finishInteractiveTransition()](/documentation/uikit/uicollectionview/finishinteractivetransition()) or [cancelInteractiveTransition()](/documentation/uikit/uicollectionview/cancelinteractivetransition()) method to remove the intermediate layout object and install the intended target layout object.

For more information, see [Layouts](/documentation/uikit/layouts).

### Cells and supplementary views

The collection view’s data source object provides both the content for items and the views used to present that content. When the collection view first loads its content, it asks its data source to provide a view for each visible item. The collection view maintains a queue or list of view objects that the data source has marked for reuse. Instead of creating new views explicitly in your code, you always dequeue views.

There are two methods for dequeueing views. The one you use depends on which type of view has been requested:

- Use the [dequeueReusableCell(withReuseIdentifier:for:)](/documentation/uikit/uicollectionview/dequeuereusablecell(withreuseidentifier:for:)) to get a cell for an item in the collection view.
- Use the [dequeueReusableSupplementaryView(ofKind:withReuseIdentifier:for:)](/documentation/uikit/uicollectionview/dequeuereusablesupplementaryview(ofkind:withreuseidentifier:for:)) method to get a supplementary view requested by the layout object.

Before you call either of these methods, you must tell the collection view how to create the corresponding view if one doesn’t already exist. For this, you must register either a class or a nib file with the collection view. For example, when registering cells, you use the [register(_:forCellWithReuseIdentifier:)](/documentation/uikit/uicollectionview/register(_:forcellwithreuseidentifier:)-3vaho) method to register a class or the [register(_:forCellWithReuseIdentifier:)](/documentation/uikit/uicollectionview/register(_:forcellwithreuseidentifier:)-6z6t4) method to register a nib file. As part of the registration process, you specify the reuse identifier that identifies the purpose of the view. This is the same string you use when dequeueing the view later.

After dequeueing the appropriate view in your data source method, configure its content and return it to the collection view for use. After getting the layout information from the layout object, the collection view applies it to the view and displays it.

### Data prefetching

Collection views provide two prefetching techniques you can use to improve responsiveness:

- *Cell prefetching* prepares cells in advance of the time they’re required. When a collection view requires a large number of cells simultaneously — for example, a new row of cells in grid layout — the cells are requested earlier than the time required for display. Cell rendering is therefore spread across multiple layout passes, resulting in a smoother scrolling experience. Cell prefetching is enabled by default.
- *Data prefetching* provides a mechanism whereby you’re notified of the data requirements of a collection view in advance of the requests for cells. This is useful if the content of your cells relies on an expensive data loading process, such as a network request. Assign an object that conforms to the [UICollectionViewDataSourcePrefetching](/documentation/uikit/uicollectionviewdatasourceprefetching) protocol to the [prefetchDataSource](/documentation/uikit/uicollectionview/prefetchdatasource) property to receive notifications of when to prefetch data for cells.

### Reorder items interactively

Collection views allow you to move items around based on user interactions. Typically, the order of items in a collection view is defined by your data source. If you allow users to reorder items, you can configure a gesture recognizer to track the user’s interactions with a collection view item and update that item’s position.

To begin the interactive repositioning of an item, call the [beginInteractiveMovementForItem(at:)](/documentation/uikit/uicollectionview/begininteractivemovementforitem(at:)) method of the collection view. While your gesture recognizer is tracking touch events, call the [updateInteractiveMovementTargetPosition(_:)](/documentation/uikit/uicollectionview/updateinteractivemovementtargetposition(_:)) method to report changes in the touch location. When you’re done tracking the gesture, call the [endInteractiveMovement()](/documentation/uikit/uicollectionview/endinteractivemovement()) or [cancelInteractiveMovement()](/documentation/uikit/uicollectionview/cancelinteractivemovement()) method to conclude the interactions and update the collection view.

During user interactions, the collection view invalidates its layout dynamically to reflect the current position of the item. If you do nothing, the default layout behavior repositions the items for you, but you can customize the layout animations if you want. When interactions finish, the collection view updates its data source object with the new location of the item.

The [UICollectionViewController](/documentation/uikit/uicollectionviewcontroller) class provides a default gesture recognizer that you can use to rearrange items in its managed collection view. To install this gesture recognizer, set the [installsStandardGestureForInteractiveMovement](/documentation/uikit/uicollectionviewcontroller/installsstandardgestureforinteractivemovement) property of the collection view controller to [true](/documentation/Swift/true).

### Interface Builder attributes

The following table lists the attributes that you configure for collection views in Interface Builder.

| Attribute | Description |
| --- | --- |
| Items | The number of prototype cells. This property controls the specified number of prototype cells for you to configure in your storyboard. Collection views must always have at least one cell and may have multiple cells for displaying different types of content or for displaying the same content in different ways. |
| Layout | The layout object to use. Use this control to select between the [UICollectionViewFlowLayout](/documentation/uikit/uicollectionviewflowlayout) object and a custom layout object that you define. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) When the flow layout is selected, you can also configure the scrolling direction for the collection view’s content and whether the flow layout has header and footer views. Enabling header and footer views adds reusable views to your storyboard that you can configure with your header and footer content. You can also create those views programmatically. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) When a custom layout is selected, you must specify the [UICollectionViewLayout](/documentation/uikit/uicollectionviewlayout) subclass to use. |

When the Flow layout is selected, the Size inspector for the collection view contains additional attributes for configuring flow layout metrics. Use those attributes to configure the size of your cells, the size of headers and footers, the minimum spacing between cells, and any margins around each section of cells. For more information about the meaning of the flow layout metrics, see [UICollectionViewFlowLayout](/documentation/uikit/uicollectionviewflowlayout).

### Internationalization

A collection view has no direct content of its own to internationalize. Instead, you internationalize the cells and reusable views of the collection view. For more information about internationalization, see [Localization](https://developer.apple.com/localization/).

### Accessibility

A collection view has no content of its own to make accessible. If your cells and reusable views contain standard UIKit controls such as [UILabel](/documentation/uikit/uilabel) and [UITextField](/documentation/uikit/uitextfield), you can make those controls accessible. When a collection view changes its onscreen layout, it posts the [layoutChanged](/documentation/uikit/uiaccessibility/notification/layoutchanged) notification.

For general information about making your interface accessible, see [Accessibility for UIKit](/documentation/uikit/accessibility-for-uikit).

## Inherits From

- [UIScrollView](/documentation/uikit/uiscrollview)

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
- [UICoordinateSpace](/documentation/uikit/uicoordinatespace)
- [UIDataSourceTranslating](/documentation/uikit/uidatasourcetranslating)
- [UIDynamicItem](/documentation/uikit/uidynamicitem)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIFocusItem](/documentation/uikit/uifocusitem)
- [UIFocusItemContainer](/documentation/uikit/uifocusitemcontainer)
- [UIFocusItemScrollableContainer](/documentation/uikit/uifocusitemscrollablecontainer)
- [UILargeContentViewerItem](/documentation/uikit/uilargecontentvieweritem)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIPopoverPresentationControllerSourceItem](/documentation/uikit/uipopoverpresentationcontrollersourceitem)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UISpringLoadedInteractionSupporting](/documentation/uikit/uispringloadedinteractionsupporting)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating a collection view

- [init(frame:collectionViewLayout:)](/documentation/uikit/uicollectionview/init(frame:collectionviewlayout:)) Creates a collection view object with the specified frame and layout.
- [init(coder:)](/documentation/uikit/uicollectionview/init(coder:)) Creates a collection view object from data in a given unarchiver.

## Providing the collection view data

- [dataSource](/documentation/uikit/uicollectionview/datasource) The object that provides the data for the collection view.
- [UICollectionViewDiffableDataSource](/documentation/uikit/uicollectionviewdiffabledatasource-9tqpa) The object you use to manage data and provide cells for a collection view.
- [UICollectionViewDataSource](/documentation/uikit/uicollectionviewdatasource) The methods adopted by the object you use to manage data and provide cells for a collection view.
- [Building high-performance lists and collection views](/documentation/uikit/building-high-performance-lists-and-collection-views) Improve the performance of lists and collections in your app with prefetching and image preparation.

## Prefetching collection view cells and data

- [isPrefetchingEnabled](/documentation/uikit/uicollectionview/isprefetchingenabled) A Boolean value that indicates whether cell and data prefetching are enabled.
- [prefetchDataSource](/documentation/uikit/uicollectionview/prefetchdatasource) The object that acts as the prefetching data source for the collection view, receiving notifications of upcoming cell data requirements.
- [UICollectionViewDataSourcePrefetching](/documentation/uikit/uicollectionviewdatasourceprefetching) A protocol that provides advance warning of the data requirements for a collection view, allowing the triggering of asynchronous data load operations.

## Managing collection view interactions

- [delegate](/documentation/uikit/uicollectionview/delegate) The object that acts as the delegate of the collection view.
- [UICollectionViewDelegate](/documentation/uikit/uicollectionviewdelegate) The methods adopted by the object you use to manage user interactions with items in a collection view.

## Creating cells

- [UICollectionView.CellRegistration](/documentation/uikit/uicollectionview/cellregistration) A registration for the collection view’s cells.
- [dequeueConfiguredReusableCell(using:for:item:)](/documentation/uikit/uicollectionview/dequeueconfiguredreusablecell(using:for:item:)) Dequeues a configured reusable cell object.
- [register(_:forCellWithReuseIdentifier:)](/documentation/uikit/uicollectionview/register(_:forcellwithreuseidentifier:)-3vaho) Registers a class for use in creating new collection view cells.
- [register(_:forCellWithReuseIdentifier:)](/documentation/uikit/uicollectionview/register(_:forcellwithreuseidentifier:)-6z6t4) Registers a nib file for use in creating new collection view cells.
- [dequeueReusableCell(withReuseIdentifier:for:)](/documentation/uikit/uicollectionview/dequeuereusablecell(withreuseidentifier:for:)) Dequeues a reusable cell object located by its identifier.

## Creating headers and footers

- [UICollectionView.SupplementaryRegistration](/documentation/uikit/uicollectionview/supplementaryregistration) A registration for the collection view’s supplementary views.
- [dequeueConfiguredReusableSupplementary(using:for:)](/documentation/uikit/uicollectionview/dequeueconfiguredreusablesupplementary(using:for:)) Dequeues a configured reusable supplementary view object.
- [register(_:forSupplementaryViewOfKind:withReuseIdentifier:)](/documentation/uikit/uicollectionview/register(_:forsupplementaryviewofkind:withreuseidentifier:)-661io) Registers a class for use in creating supplementary views for the collection view.
- [register(_:forSupplementaryViewOfKind:withReuseIdentifier:)](/documentation/uikit/uicollectionview/register(_:forsupplementaryviewofkind:withreuseidentifier:)-9hn73) Registers a nib file for use in creating supplementary views for the collection view.
- [dequeueReusableSupplementaryView(ofKind:withReuseIdentifier:for:)](/documentation/uikit/uicollectionview/dequeuereusablesupplementaryview(ofkind:withreuseidentifier:for:)) Dequeues a reusable supplementary view located by its identifier and kind.

## Configuring the background view

- [backgroundView](/documentation/uikit/uicollectionview/backgroundview) The view that provides the background appearance.

## Changing the layout

- [collectionViewLayout](/documentation/uikit/uicollectionview/collectionviewlayout) The layout used to organize the collected view’s items.
- [setCollectionViewLayout(_:animated:)](/documentation/uikit/uicollectionview/setcollectionviewlayout(_:animated:)) Changes the collection view’s layout and optionally animates the change.
- [setCollectionViewLayout(_:animated:completion:)](/documentation/uikit/uicollectionview/setcollectionviewlayout(_:animated:completion:)) Changes the collection view’s layout and notifies you when the animations complete.
- [startInteractiveTransition(to:completion:)](/documentation/uikit/uicollectionview/startinteractivetransition(to:completion:)) Changes the collection view’s current layout using an interactive transition effect.
- [finishInteractiveTransition()](/documentation/uikit/uicollectionview/finishinteractivetransition()) Tells the collection view to finish an interactive transition by installing the intended target layout.
- [cancelInteractiveTransition()](/documentation/uikit/uicollectionview/cancelinteractivetransition()) Tells the collection view to cancel an interactive transition and return to its original layout object.
- [UICollectionView.LayoutInteractiveTransitionCompletion](/documentation/uikit/uicollectionview/layoutinteractivetransitioncompletion) The completion block called at the end of an interactive transition for a collection view.

## Getting the state of the collection view

- [numberOfSections](/documentation/uikit/uicollectionview/numberofsections) The number of sections displayed by the collection view.
- [numberOfItems(inSection:)](/documentation/uikit/uicollectionview/numberofitems(insection:)) Fetches the count of items in the specified section.
- [visibleCells](/documentation/uikit/uicollectionview/visiblecells) An array of visible cells currently displayed by the collection view.

## Inserting, moving, and deleting Items

- [insertItems(at:)](/documentation/uikit/uicollectionview/insertitems(at:)) Inserts new items at the specified index paths.
- [moveItem(at:to:)](/documentation/uikit/uicollectionview/moveitem(at:to:)) Moves an item from one location to another in the collection view.
- [deleteItems(at:)](/documentation/uikit/uicollectionview/deleteitems(at:)) Deletes the items at the specified index paths.

## Inserting, moving, and deleting sections

- [insertSections(_:)](/documentation/uikit/uicollectionview/insertsections(_:)) Inserts new sections at the specified indexes.
- [moveSection(_:toSection:)](/documentation/uikit/uicollectionview/movesection(_:tosection:)) Moves a section from one location to another in the collection view.
- [deleteSections(_:)](/documentation/uikit/uicollectionview/deletesections(_:)) Deletes the sections at the specified indexes.

## Reordering items interactively

- [beginInteractiveMovementForItem(at:)](/documentation/uikit/uicollectionview/begininteractivemovementforitem(at:)) Initiates the interactive movement of the item at the specified index path.
- [updateInteractiveMovementTargetPosition(_:)](/documentation/uikit/uicollectionview/updateinteractivemovementtargetposition(_:)) Updates the position of the item within the collection view’s bounds.
- [endInteractiveMovement()](/documentation/uikit/uicollectionview/endinteractivemovement()) Ends interactive movement tracking and moves the target item to its new location.
- [cancelInteractiveMovement()](/documentation/uikit/uicollectionview/cancelinteractivemovement()) Ends interactive movement tracking and returns the target item to its original location.

## Managing drag interactions

- [dragDelegate](/documentation/uikit/uicollectionview/dragdelegate) The delegate object that manages the dragging of items from the collection view.
- [UICollectionViewDragDelegate](/documentation/uikit/uicollectionviewdragdelegate) The interface for initiating drags from a collection view.
- [hasActiveDrag](/documentation/uikit/uicollectionview/hasactivedrag) A Boolean value that indicates whether items were lifted from the collection view and have not yet been dropped.
- [dragInteractionEnabled](/documentation/uikit/uicollectionview/draginteractionenabled) A Boolean value that indicates whether the collection view supports dragging content.

## Managing drop interactions

- [dropDelegate](/documentation/uikit/uicollectionview/dropdelegate) The delegate object that manages the dropping of items into the collection view.
- [UICollectionViewDropDelegate](/documentation/uikit/uicollectionviewdropdelegate) The interface for handling drops in a collection view.
- [hasActiveDrop](/documentation/uikit/uicollectionview/hasactivedrop) A Boolean value that indicates whether the collection view is currently tracking a drop session.
- [reorderingCadence](/documentation/uikit/uicollectionview/reorderingcadence-swift.property) The speed at which items in the collection view are reordered to show potential drop locations.
- [UICollectionView.ReorderingCadence](/documentation/uikit/uicollectionview/reorderingcadence-swift.enum) Constants indicating the speed at which collection view items are reorganized during a drop.

## Selecting cells

- [indexPathsForSelectedItems](/documentation/uikit/uicollectionview/indexpathsforselecteditems) The index paths for the selected items.
- [selectItem(at:animated:scrollPosition:)](/documentation/uikit/uicollectionview/selectitem(at:animated:scrollposition:)) Selects the item at the specified index path and optionally scrolls it into view.
- [deselectItem(at:animated:)](/documentation/uikit/uicollectionview/deselectitem(at:animated:)) Deselects the item at the specified index.
- [allowsSelection](/documentation/uikit/uicollectionview/allowsselection) A Boolean value that indicates whether users can select items in the collection view.
- [allowsMultipleSelection](/documentation/uikit/uicollectionview/allowsmultipleselection) A Boolean value that determines whether users can select more than one item in the collection view.
- [allowsSelectionDuringEditing](/documentation/uikit/uicollectionview/allowsselectionduringediting) A Boolean value that determines whether users can select cells while the collection view is in editing mode.
- [allowsMultipleSelectionDuringEditing](/documentation/uikit/uicollectionview/allowsmultipleselectionduringediting) A Boolean value that controls whether users can select more than one cell simultaneously in editing mode.
- [selectionFollowsFocus](/documentation/uikit/uicollectionview/selectionfollowsfocus) A Boolean value that triggers an automatic selection when focus moves to a cell.

## Putting the collection view into edit mode

- [isEditing](/documentation/uikit/uicollectionview/isediting) A Boolean value that determines whether the collection view is in editing mode.

## Locating items and views in the collection view

- [indexPathForItem(at:)](/documentation/uikit/uicollectionview/indexpathforitem(at:)) Gets the index path of the item at the specified point in the collection view.
- [indexPathsForVisibleItems](/documentation/uikit/uicollectionview/indexpathsforvisibleitems) An array of the visible items in the collection view.
- [indexPath(for:)](/documentation/uikit/uicollectionview/indexpath(for:)) Gets the index path of the specified cell.
- [cellForItem(at:)](/documentation/uikit/uicollectionview/cellforitem(at:)) Gets the cell object at the index path you specify.
- [indexPathsForVisibleSupplementaryElements(ofKind:)](/documentation/uikit/uicollectionview/indexpathsforvisiblesupplementaryelements(ofkind:)) Gets the index paths of all visible supplementary views of the specified type.
- [supplementaryView(forElementKind:at:)](/documentation/uikit/uicollectionview/supplementaryview(forelementkind:at:)) Gets the supplementary view at the specified index path.
- [visibleSupplementaryViews(ofKind:)](/documentation/uikit/uicollectionview/visiblesupplementaryviews(ofkind:)) Gets an array of the visible supplementary views of the specified kind.

## Getting layout information

- [layoutAttributesForItem(at:)](/documentation/uikit/uicollectionview/layoutattributesforitem(at:)) Gets the layout information for the item at the specified index path.
- [layoutAttributesForSupplementaryElement(ofKind:at:)](/documentation/uikit/uicollectionview/layoutattributesforsupplementaryelement(ofkind:at:)) Gets the layout information for the specified supplementary view.

## Scrolling an item into view

- [scrollToItem(at:at:animated:)](/documentation/uikit/uicollectionview/scrolltoitem(at:at:animated:)) Scrolls the collection view contents until the specified item is visible.
- [UICollectionView.ScrollPosition](/documentation/uikit/uicollectionview/scrollposition) Constants that indicate how to scroll an item into the visible portion of the collection view.
- [UICollectionView.ScrollDirection](/documentation/uikit/uicollectionview/scrolldirection) Constants that indicate the direction of scrolling for the layout.

## Animating multiple changes to the collection view

- [performBatchUpdates(_:completion:)](/documentation/uikit/uicollectionview/performbatchupdates(_:completion:)) Animates multiple insert, delete, reload, and move operations as a group.

## Reloading content

- [hasUncommittedUpdates](/documentation/uikit/uicollectionview/hasuncommittedupdates) A Boolean value that indicates whether the collection view contains drop placeholders or is reordering its items as part of handling a drop.
- [reconfigureItems(at:)](/documentation/uikit/uicollectionview/reconfigureitems(at:)) Updates the data for the items at the index paths you specify, preserving the existing cells for the items.
- [reloadData()](/documentation/uikit/uicollectionview/reloaddata()) Reloads all of the data for the collection view.
- [reloadSections(_:)](/documentation/uikit/uicollectionview/reloadsections(_:)) Reloads the data in the specified sections of the collection view.
- [reloadItems(at:)](/documentation/uikit/uicollectionview/reloaditems(at:)) Reloads just the items at the specified index paths.

## Identifying collection view elements

- [UICollectionView.ElementCategory](/documentation/uikit/uicollectionview/elementcategory) Constants specifying the type of view.
- [elementKindSectionFooter](/documentation/uikit/uicollectionview/elementkindsectionfooter) A supplementary view that identifies the footer for a given section.
- [elementKindSectionHeader](/documentation/uikit/uicollectionview/elementkindsectionheader) A supplementary view that identifies the header for a given section.

## Working with focus

- [allowsFocus](/documentation/uikit/uicollectionview/allowsfocus) A Boolean value that determines whether the collection view allows its cells to become focused.
- [allowsFocusDuringEditing](/documentation/uikit/uicollectionview/allowsfocusduringediting) A Boolean value that determines whether the collection view allows its cells to become focused in edit mode.
- [selectionFollowsFocus](/documentation/uikit/uicollectionview/selectionfollowsfocus) A Boolean value that triggers an automatic selection when focus moves to a cell.
- [remembersLastFocusedIndexPath](/documentation/uikit/uicollectionview/rememberslastfocusedindexpath) A Boolean value that indicates whether the collection view automatically assigns the focus to the item at the last focused index path.

## Managing context menus

- [contextMenuInteraction](/documentation/uikit/uicollectionview/contextmenuinteraction) The collection view’s context menu interaction.

## Resizing self-sizing cells

- [selfSizingInvalidation](/documentation/uikit/uicollectionview/selfsizinginvalidation-swift.property) The mode that the collection view uses for invalidating the size of self-sizing cells.
- [UICollectionView.SelfSizingInvalidation](/documentation/uikit/uicollectionview/selfsizinginvalidation-swift.enum) Constants that describe modes for invalidating the size of self-sizing collection view cells.

## Instance Properties

- [appIntentsDataSource](/documentation/uikit/uicollectionview/appintentsdatasource) The object acting as the collection view’s data source for app entity identifiers that make a cell’s content avdiscoverable by Apple Intelligence and Siri.

## Instance Methods

- [indexPath(forSupplementaryView:)](/documentation/uikit/uicollectionview/indexpath(forsupplementaryview:)) Gets the index path of the specified supplementary view.

## View

- [UICollectionViewController](/documentation/uikit/uicollectionviewcontroller) A view controller that specializes in managing a collection view.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
