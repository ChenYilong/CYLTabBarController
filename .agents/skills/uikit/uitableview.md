---
title: UITableView
description: A view that presents data using rows in a single column.
source: https://developer.apple.com/documentation/uikit/uitableview
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uitableview.json
timestamp: 2026-06-26T06:39:37.098Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UITableView

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A view that presents data using rows in a single column.

```swift
@MainActor class UITableView
```

## Overview

Table views in iOS display rows of vertically scrolling content in a single column. Each row in the table contains one piece of your app’s content. You can configure a table to display a single long list of rows, or you can group related rows into sections to make navigating the content easier.

When you organize rows into sections in a table, you can choose to present sections in a plain or grouped visual [UITableView.Style](/documentation/uikit/uitableview/style-swift.enum). For example, the Contacts app displays the name of each contact in a separate row, organized into sections by the first letter of each contact’s last name. It presents the sections with a plain style. The main page of the Settings app displays the available settings organized into related sections, and presents those sections in a grouped visual style.

![A screenshot of the Contacts app, which uses a table to organize the user's individual contacts in a scrolling list.](https://docs-assets.developer.apple.com/published/c3bbc132299c757114b6ed3a962aa36a/uitableview-1%402x.png)

![A screenshot of the Settings app, which displays different groups of settings in a scrolling list.](https://docs-assets.developer.apple.com/published/d618cc39d84078ae829191d1669c213d/uitableview-2%402x.png)

Tables are common in apps with data that’s highly structured or organized hierarchically. Apps that contain hierarchical data often use tables in conjunction with a navigation view controller, which facilitates navigation between different levels of the hierarchy. For example, the Settings app uses tables and a navigation controller to organize the system settings.

[UITableView](/documentation/uikit/uitableview) manages the basic appearance of the table, but your app provides the cells ([UITableViewCell](/documentation/uikit/uitableviewcell) objects) that display the actual content. The standard cell configurations display a simple combination of text and images, but you can define custom cells that display any content you want. You can also supply header and footer views to provide additional information for groups of cells.

### Add a table view to your interface

To add a table view to your interface, drag a table view controller ([UITableViewController](/documentation/uikit/uitableviewcontroller)) object to your storyboard. Xcode creates a new scene that includes both the view controller and a table view, ready for you to configure and use.

Table views are data-driven, normally getting their data from a data source object that you provide. The data source object manages your app’s data and is responsible for creating and configuring the table’s cells. If the content of your table never changes, you can configure that content in your storyboard file instead.

For information about how to specify your table’s data, see [Filling a table with data](/documentation/uikit/filling-a-table-with-data).

### Save and restore the table’s current state

Table views support UIKit app restoration. To save and restore the table’s data, assign a nonempty value to the table view’s [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) property. When you save its parent view controller, the table view automatically saves the index paths for the currently selected and visible rows. If the table’s data source object adopts the [UIDataSourceModelAssociation](/documentation/uikit/uidatasourcemodelassociation) protocol, the table stores the unique IDs that you provide for those items instead of their index paths.

For information about how to save and restore your app’s state information, see [Preserving your app’s UI across launches](/documentation/uikit/preserving-your-app-s-ui-across-launches).

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

## Creating a table view

- [init(frame:style:)](/documentation/uikit/uitableview/init(frame:style:)) Creates and returns a table view with the specified frame and style.
- [init(coder:)](/documentation/uikit/uitableview/init(coder:)) Creates a table view object from data in an unarchiver.

## Providing the data and cells

- [dataSource](/documentation/uikit/uitableview/datasource) The object that acts as the data source of the table view.
- [prefetchDataSource](/documentation/uikit/uitableview/prefetchdatasource) The object that acts as the prefetching data source for the table view, receiving notifications of upcoming cell data requirements.
- [isPrefetchingEnabled](/documentation/uikit/uitableview/isprefetchingenabled) A Boolean value that indicates whether to allow cell and data prefetching.
- [UITableViewDataSource](/documentation/uikit/uitableviewdatasource) The methods that an object adopts to manage data and provide cells for a table view.
- [UITableViewDataSourcePrefetching](/documentation/uikit/uitableviewdatasourceprefetching) A protocol that provides advance warning of the data requirements for a table view, allowing you to start potentially long-running data operations early.

## Recycling table view cells

- [register(_:forCellReuseIdentifier:)](/documentation/uikit/uitableview/register(_:forcellreuseidentifier:)-5q6bo) Registers a nib object that contains a cell with the table view under a specified identifier.
- [register(_:forCellReuseIdentifier:)](/documentation/uikit/uitableview/register(_:forcellreuseidentifier:)-3l3ct) Registers a class to use in creating new table cells.
- [dequeueReusableCell(withIdentifier:for:)](/documentation/uikit/uitableview/dequeuereusablecell(withidentifier:for:)) Returns a reusable table-view cell object for the specified reuse identifier and adds it to the table.
- [dequeueReusableCell(withIdentifier:)](/documentation/uikit/uitableview/dequeuereusablecell(withidentifier:)) Returns a reusable table-view cell object after locating it by its identifier.

## Recycling section headers and footers

- [register(_:forHeaderFooterViewReuseIdentifier:)](/documentation/uikit/uitableview/register(_:forheaderfooterviewreuseidentifier:)-1rgvc) Registers a nib object that contains a header or footer with the table view under a specified identifier.
- [register(_:forHeaderFooterViewReuseIdentifier:)](/documentation/uikit/uitableview/register(_:forheaderfooterviewreuseidentifier:)-20ybb) Registers a class to use in creating new table header or footer views.
- [dequeueReusableHeaderFooterView(withIdentifier:)](/documentation/uikit/uitableview/dequeuereusableheaderfooterview(withidentifier:)) Returns a reusable header or footer view after locating it by its identifier.

## Managing interactions with the table

- [delegate](/documentation/uikit/uitableview/delegate) The object that acts as the delegate of the table view.
- [UITableViewDelegate](/documentation/uikit/uitableviewdelegate) Methods for managing selections, configuring section headers and footers, deleting and reordering cells, and performing other actions in a table view.

## Configuring the table’s appearance

- [style](/documentation/uikit/uitableview/style-swift.property) The style of the table view.
- [UITableView.Style](/documentation/uikit/uitableview/style-swift.enum) Constants for the table view styles.
- [tableHeaderView](/documentation/uikit/uitableview/tableheaderview) The view that displays above the table’s content.
- [tableFooterView](/documentation/uikit/uitableview/tablefooterview) The view that displays below the table’s content.
- [backgroundView](/documentation/uikit/uitableview/backgroundview) The background view of the table view.

## Configuring cell height and layout

- [rowHeight](/documentation/uikit/uitableview/rowheight) The default height in points of each row in the table view.
- [estimatedRowHeight](/documentation/uikit/uitableview/estimatedrowheight) The estimated height of rows in the table view.
- [fillerRowHeight](/documentation/uikit/uitableview/fillerrowheight) The height for empty rows that fill the table view.
- [cellLayoutMarginsFollowReadableWidth](/documentation/uikit/uitableview/celllayoutmarginsfollowreadablewidth) A Boolean value that indicates whether the cell margins derive from the width of the readable content guide.
- [insetsContentViewsToSafeArea](/documentation/uikit/uitableview/insetscontentviewstosafearea) A Boolean value that indicates whether the table view adjusts the content views of its cells, headers, and footers to fit within the safe area.

## Configuring header and footer appearance

- [sectionHeaderHeight](/documentation/uikit/uitableview/sectionheaderheight) The height of section headers in the table view.
- [sectionFooterHeight](/documentation/uikit/uitableview/sectionfooterheight) The height of section footers in the table view.
- [estimatedSectionHeaderHeight](/documentation/uikit/uitableview/estimatedsectionheaderheight) The estimated height of section headers in the table view.
- [estimatedSectionFooterHeight](/documentation/uikit/uitableview/estimatedsectionfooterheight) The estimated height of section footers in the table view.
- [sectionHeaderTopPadding](/documentation/uikit/uitableview/sectionheadertoppadding) The amount of padding above each section header.

## Customizing the separator appearance

- [separatorStyle](/documentation/uikit/uitableview/separatorstyle) The style for table cells to use as separators.
- [UITableViewCell.SeparatorStyle](/documentation/uikit/uitableviewcell/separatorstyle) The style for cells to use as separators.
- [separatorColor](/documentation/uikit/uitableview/separatorcolor) The color of separator rows in the table view.
- [separatorEffect](/documentation/uikit/uitableview/separatoreffect) The effect to apply to table separators.
- [separatorInset](/documentation/uikit/uitableview/separatorinset) The default inset of cell separators.
- [separatorInsetReference](/documentation/uikit/uitableview/separatorinsetreference-swift.property) An indicator of how to interpret the separator inset value.
- [UITableView.SeparatorInsetReference](/documentation/uikit/uitableview/separatorinsetreference-swift.enum) Constants that indicate how to interpret the separator inset value of a table view.

## Getting the number of rows and sections

- [numberOfRows(inSection:)](/documentation/uikit/uitableview/numberofrows(insection:)) Returns the number of rows (table cells) in a specified section.
- [numberOfSections](/documentation/uikit/uitableview/numberofsections) The number of sections in the table view.

## Getting cells and section-based views

- [cellForRow(at:)](/documentation/uikit/uitableview/cellforrow(at:)) Returns the table cell at the index path you specify.
- [headerView(forSection:)](/documentation/uikit/uitableview/headerview(forsection:)) Returns the header view for the specified section.
- [footerView(forSection:)](/documentation/uikit/uitableview/footerview(forsection:)) Returns the footer view for the specified section.
- [indexPath(for:)](/documentation/uikit/uitableview/indexpath(for:)) Returns an index path that represents the row and section of a specified table-view cell.
- [indexPathForRow(at:)](/documentation/uikit/uitableview/indexpathforrow(at:)) Returns an index path that identifies the row and section at the specified point.
- [indexPathsForRows(in:)](/documentation/uikit/uitableview/indexpathsforrows(in:)) Returns an array of index paths, each representing a row that the specified rectangle encloses.
- [visibleCells](/documentation/uikit/uitableview/visiblecells) The table cells that are visible in the table view.
- [indexPathsForVisibleRows](/documentation/uikit/uitableview/indexpathsforvisiblerows) An array of index paths, each identifying a visible row in the table view.

## Selecting rows

- [indexPathForSelectedRow](/documentation/uikit/uitableview/indexpathforselectedrow) An index path that identifies the row and section of the selected row.
- [indexPathsForSelectedRows](/documentation/uikit/uitableview/indexpathsforselectedrows) The index paths that represent the selected rows.
- [selectRow(at:animated:scrollPosition:)](/documentation/uikit/uitableview/selectrow(at:animated:scrollposition:)) Selects a row in the table view that an index path identifies, optionally scrolling the row to a location in the table view.
- [deselectRow(at:animated:)](/documentation/uikit/uitableview/deselectrow(at:animated:)) Deselects a row that an index path identifies, with an option to animate the deselection.
- [allowsSelection](/documentation/uikit/uitableview/allowsselection) A Boolean value that determines whether users can select a row.
- [allowsMultipleSelection](/documentation/uikit/uitableview/allowsmultipleselection) A Boolean value that determines whether users can select more than one row outside of editing mode.
- [allowsSelectionDuringEditing](/documentation/uikit/uitableview/allowsselectionduringediting) A Boolean value that determines whether users can select cells while the table view is in editing mode.
- [allowsMultipleSelectionDuringEditing](/documentation/uikit/uitableview/allowsmultipleselectionduringediting) A Boolean value that controls whether users can select more than one cell simultaneously in editing mode.
- [selectionFollowsFocus](/documentation/uikit/uitableview/selectionfollowsfocus) A Boolean value that triggers an automatic selection when focus moves to a cell.
- [selectionDidChangeNotification](/documentation/uikit/uitableview/selectiondidchangenotification) A notification that posts when the selected row in the posting table view changes.

## Inserting, deleting, and moving rows and sections

- [insertRows(at:with:)](/documentation/uikit/uitableview/insertrows(at:with:)) Inserts rows in the table view at the locations that an array of index paths identifies, with an option to animate the insertion.
- [deleteRows(at:with:)](/documentation/uikit/uitableview/deleterows(at:with:)) Deletes the rows that an array of index paths identifies, with an option to animate the deletion.
- [insertSections(_:with:)](/documentation/uikit/uitableview/insertsections(_:with:)) Inserts one or more sections in the table view, with an option to animate the insertion.
- [deleteSections(_:with:)](/documentation/uikit/uitableview/deletesections(_:with:)) Deletes one or more sections in the table view, with an option to animate the deletion.
- [UITableView.RowAnimation](/documentation/uikit/uitableview/rowanimation) The type of animation to use when inserting or deleting rows.
- [moveRow(at:to:)](/documentation/uikit/uitableview/moverow(at:to:)) Moves the row at a specified location to a destination location.
- [moveSection(_:toSection:)](/documentation/uikit/uitableview/movesection(_:tosection:)) Moves a section to a new location in the table view.

## Performing batch updates to rows and sections

- [performBatchUpdates(_:completion:)](/documentation/uikit/uitableview/performbatchupdates(_:completion:)) Animates multiple insert, delete, reload, and move operations as a group.
- [beginUpdates()](/documentation/uikit/uitableview/beginupdates()) Begins a series of method calls that insert, delete, or select rows and sections of the table view.
- [endUpdates()](/documentation/uikit/uitableview/endupdates()) Concludes a series of method calls that insert, delete, select, or reload rows and sections of the table view.

## Reloading the table view

- [hasUncommittedUpdates](/documentation/uikit/uitableview/hasuncommittedupdates) A Boolean value that indicates whether the table view’s appearance contains changes that aren’t present in its data source.
- [reconfigureRows(at:)](/documentation/uikit/uitableview/reconfigurerows(at:)) Updates the data for the rows at the index paths you specify, preserving the existing cells for the rows.
- [reloadData()](/documentation/uikit/uitableview/reloaddata()) Reloads the rows and sections of the table view.
- [reloadRows(at:with:)](/documentation/uikit/uitableview/reloadrows(at:with:)) Reloads the specified rows using the provided animation effect.
- [reloadSections(_:with:)](/documentation/uikit/uitableview/reloadsections(_:with:)) Reloads the specified sections using the provided animation effect.
- [reloadSectionIndexTitles()](/documentation/uikit/uitableview/reloadsectionindextitles()) Reloads the items in the index bar along the right side of the table view.

## Managing drag interactions

- [dragDelegate](/documentation/uikit/uitableview/dragdelegate) The delegate object that manages the dragging of items from the table view.
- [UITableViewDragDelegate](/documentation/uikit/uitableviewdragdelegate) The interface for initiating drags from a table view.
- [hasActiveDrag](/documentation/uikit/uitableview/hasactivedrag) A Boolean value that indicates whether the table view is currently tracking a drag session.
- [dragInteractionEnabled](/documentation/uikit/uitableview/draginteractionenabled) A Boolean value that indicates whether the table view supports dragging content.

## Managing drop interactions

- [dropDelegate](/documentation/uikit/uitableview/dropdelegate) The delegate object that manages the dropping of content into the table view.
- [UITableViewDropDelegate](/documentation/uikit/uitableviewdropdelegate) The interface for handling drops in a table view.
- [hasActiveDrop](/documentation/uikit/uitableview/hasactivedrop) A Boolean value that indicates whether the table view is currently tracking a drop session.

## Scrolling the table view

- [scrollToRow(at:at:animated:)](/documentation/uikit/uitableview/scrolltorow(at:at:animated:)) Scrolls through the table view until a row that an index path identifies is at a particular location on the screen.
- [scrollToNearestSelectedRow(at:animated:)](/documentation/uikit/uitableview/scrolltonearestselectedrow(at:animated:)) Scrolls the table view so that the selected row nearest to a specified position in the table view is at that position.
- [UITableView.ScrollPosition](/documentation/uikit/uitableview/scrollposition) The position in the table view (top, middle, bottom) to scroll a specified row to.

## Putting the table into edit mode

- [setEditing(_:animated:)](/documentation/uikit/uitableview/setediting(_:animated:)) Toggles the table view into and out of editing mode.
- [isEditing](/documentation/uikit/uitableview/isediting) A Boolean value that determines whether the table view is in editing mode.

## Configuring the table index

- [sectionIndexMinimumDisplayRowCount](/documentation/uikit/uitableview/sectionindexminimumdisplayrowcount) The number of table rows at which to display the index list on the right edge of the table.
- [sectionIndexColor](/documentation/uikit/uitableview/sectionindexcolor) The color to use for the table view’s index text.
- [sectionIndexBackgroundColor](/documentation/uikit/uitableview/sectionindexbackgroundcolor) The color to use for the background of the table view’s section index.
- [sectionIndexTrackingBackgroundColor](/documentation/uikit/uitableview/sectionindextrackingbackgroundcolor) The color to use for the table view’s index background area.
- [indexSearch](/documentation/uikit/uitableview/indexsearch) A constant for adding the magnifying glass icon to the section index of a table view.

## Getting the drawing areas for the table

- [rect(forSection:)](/documentation/uikit/uitableview/rect(forsection:)) Returns the drawing area for a specified section of the table view.
- [rectForRow(at:)](/documentation/uikit/uitableview/rectforrow(at:)) Returns the drawing area for a row that an index path identifies.
- [rectForFooter(inSection:)](/documentation/uikit/uitableview/rectforfooter(insection:)) Returns the drawing area for the footer of the specified section.
- [rectForHeader(inSection:)](/documentation/uikit/uitableview/rectforheader(insection:)) Returns the drawing area for the header of the specified section.

## Working with focus

- [allowsFocus](/documentation/uikit/uitableview/allowsfocus) A Boolean value that determines whether the table view allows its cells to become focused.
- [allowsFocusDuringEditing](/documentation/uikit/uitableview/allowsfocusduringediting) A Boolean value that determines whether the table view allows its cells to become focused in edit mode.
- [selectionFollowsFocus](/documentation/uikit/uitableview/selectionfollowsfocus) A Boolean value that triggers an automatic selection when focus moves to a cell.
- [remembersLastFocusedIndexPath](/documentation/uikit/uitableview/rememberslastfocusedindexpath) A Boolean value that indicates whether the table view automatically returns the focus to the cell at the last focused index path.

## Managing context menus

- [contextMenuInteraction](/documentation/uikit/uitableview/contextmenuinteraction) The table view’s context menu interaction.

## Resizing self-sizing cells

- [selfSizingInvalidation](/documentation/uikit/uitableview/selfsizinginvalidation-swift.property) The mode that the table view uses for invalidating the size of self-sizing cells.
- [UITableView.SelfSizingInvalidation](/documentation/uikit/uitableview/selfsizinginvalidation-swift.enum) Constants that describe modes for invalidating the size of self-sizing table view cells.

## Managing content-hugging behavior

- [contentHuggingElements](/documentation/uikit/uitableview/contenthuggingelements) A setting that determines which type of items tightly hug their content.
- [UITableViewContentHuggingElements](/documentation/uikit/uitableviewcontenthuggingelements) Constants that determine which types of items in a table view tightly hug their content.

## Structures

- [UITableView.SelectionDidChangeMessage](/documentation/uikit/uitableview/selectiondidchangemessage)

## Instance Properties

- [appIntentsDataSource](/documentation/uikit/uitableview/appintentsdatasource) The object acting as the table view’s data source for app entity identifiers that make a cell’s content discoverable by Apple Intelligence and Siri.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
