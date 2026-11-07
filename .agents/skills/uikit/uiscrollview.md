---
title: UIScrollView
description: A view that allows the scrolling and zooming of its contained views.
source: https://developer.apple.com/documentation/uikit/uiscrollview
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiscrollview.json
timestamp: 2026-06-26T06:39:37.072Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIScrollView

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A view that allows the scrolling and zooming of its contained views.

```swift
@MainActor class UIScrollView
```

## Overview

[UIScrollView](/documentation/uikit/uiscrollview) is the superclass of several UIKit classes, including [UITableView](/documentation/uikit/uitableview) and [UITextView](/documentation/uikit/uitextview).

A scroll view is a view with an origin that’s adjustable over the content view. It clips the content to its frame, which generally (but not necessarily) coincides with that of the app’s main window. A scroll view tracks the movements of fingers, and adjusts the origin accordingly. The view that shows its content through the scroll view draws that portion of itself according to the new origin, which is pinned to an offset in the content view. The scroll view itself does no drawing except for displaying vertical and horizontal scroll indicators. The scroll view must know the size of the content view so it knows when to stop scrolling. By default, it *bounces* back when scrolling exceeds the bounds of the content.

The object that manages the drawing of content that displays in a scroll view needs to tile the content’s subviews so that no view exceeds the size of the screen. As users scroll in the scroll view, this object adds and removes subviews as necessary.

Because a scroll view has no scroll bars, it must know whether a touch signals an intent to scroll versus an intent to track a subview in the content. To make this determination, it temporarily intercepts a touch-down event by starting a timer and, before the timer fires, seeing if the touching finger makes any movement. If the timer fires without a significant change in position, the scroll view sends tracking events to the touched subview of the content view. If the user then drags their finger far enough before the timer elapses, the scroll view cancels any tracking in the subview and performs the scrolling itself. Subclasses can override the [touchesShouldBegin(_:with:in:)](/documentation/uikit/uiscrollview/touchesshouldbegin(_:with:in:)), [isPagingEnabled](/documentation/uikit/uiscrollview/ispagingenabled), and [touchesShouldCancel(in:)](/documentation/uikit/uiscrollview/touchesshouldcancel(in:)) methods (which the scroll view calls) to affect how the scroll view handles scrolling gestures.

A scroll view also handles zooming and panning of content. As the user makes a pinch-in or pinch-out gesture, the scroll view adjusts the offset and the scale of the content. When the gesture ends, the object managing the content view updates subviews of the content as necessary. (Note that the gesture can end and a finger might still be down.) While the gesture is in progress, the scroll view doesn’t send any tracking calls to the subview.

The [UIScrollView](/documentation/uikit/uiscrollview) class can have a delegate that must adopt the [UIScrollViewDelegate](/documentation/uikit/uiscrollviewdelegate) protocol. For zooming and panning to work, the delegate must implement both [viewForZooming(in:)](/documentation/uikit/uiscrollviewdelegate/viewforzooming(in:)) and [scrollViewDidEndZooming(_:with:atScale:)](/documentation/uikit/uiscrollviewdelegate/scrollviewdidendzooming(_:with:atscale:)). In addition, the [maximumZoomScale](/documentation/uikit/uiscrollview/maximumzoomscale) and [minimumZoomScale](/documentation/uikit/uiscrollview/minimumzoomscale) zoom scales must be different.

### State preservation

If you assign a value to this view’s [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) property, it attempts to preserve its scrolling-related information between app launches. Specifically, the values of the [zoomScale](/documentation/uikit/uiscrollview/zoomscale), [contentInset](/documentation/uikit/uiscrollview/contentinset), and [contentOffset](/documentation/uikit/uiscrollview/contentoffset) properties are preserved. During restoration, the scroll view restores these values so that the content appears scrolled to the same position as before. For more information about how state preservation and restoration works, see [App Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007072).

## Inherits From

- [UIView](/documentation/uikit/uiview)

## Inherited By

- [UICollectionView](/documentation/uikit/uicollectionview)
- [UITableView](/documentation/uikit/uitableview)
- [UITextView](/documentation/uikit/uitextview)

## Conforms To

- [CALayerDelegate](/documentation/QuartzCore/CALayerDelegate)
- [CLBodyIdentifiable](/documentation/CoreLocation/CLBodyIdentifiable)
- [CMBodyIdentifiable](/documentation/CoreMotion/CMBodyIdentifiable)
- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
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
- [UIFocusItemScrollableContainer](/documentation/uikit/uifocusitemscrollablecontainer)
- [UILargeContentViewerItem](/documentation/uikit/uilargecontentvieweritem)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIPopoverPresentationControllerSourceItem](/documentation/uikit/uipopoverpresentationcontrollersourceitem)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Responding to scroll view interactions

- [delegate](/documentation/uikit/uiscrollview/delegate) The delegate of the scroll view.
- [UIScrollViewDelegate](/documentation/uikit/uiscrollviewdelegate) The interface for the delegate of a scroll view.

## Managing the content size and offset

- [contentSize](/documentation/uikit/uiscrollview/contentsize) The size of the content view.
- [contentOffset](/documentation/uikit/uiscrollview/contentoffset) The point at which the origin of the content view is offset from the origin of the scroll view.
- [setContentOffset(_:animated:)](/documentation/uikit/uiscrollview/setcontentoffset(_:animated:)) Sets the offset from the content view’s origin that corresponds to the scroll view’s origin.

## Managing the content inset behavior

- [adjustedContentInset](/documentation/uikit/uiscrollview/adjustedcontentinset) The insets derived from the content insets and the safe area of the scroll view.
- [contentInset](/documentation/uikit/uiscrollview/contentinset) The custom distance that the content view is inset from the safe area or scroll view edges.
- [contentInsetAdjustmentBehavior](/documentation/uikit/uiscrollview/contentinsetadjustmentbehavior-swift.property) The behavior for determining the adjusted content offsets.
- [UIScrollView.ContentInsetAdjustmentBehavior](/documentation/uikit/uiscrollview/contentinsetadjustmentbehavior-swift.enum) Constants indicating how safe area insets are added to the adjusted content inset.
- [adjustedContentInsetDidChange()](/documentation/uikit/uiscrollview/adjustedcontentinsetdidchange()) Notifies the scroll view when the adjusted content insets of the scroll view change.

## Getting the layout guides

- [frameLayoutGuide](/documentation/uikit/uiscrollview/framelayoutguide) The layout guide based on the untransformed frame rectangle of the scroll view.
- [contentLayoutGuide](/documentation/uikit/uiscrollview/contentlayoutguide) The layout guide based on the untranslated content rectangle of the scroll view.

## Configuring the scroll view

- [isScrollEnabled](/documentation/uikit/uiscrollview/isscrollenabled) A Boolean value that determines whether scrolling is enabled.
- [isDirectionalLockEnabled](/documentation/uikit/uiscrollview/isdirectionallockenabled) A Boolean value that determines whether scrolling is disabled in a particular direction.
- [isPagingEnabled](/documentation/uikit/uiscrollview/ispagingenabled) A Boolean value that determines whether paging is enabled for the scroll view.
- [scrollsToTop](/documentation/uikit/uiscrollview/scrollstotop) A Boolean value that controls whether the scroll-to-top gesture is enabled.
- [bounces](/documentation/uikit/uiscrollview/bounces) A Boolean value that controls whether the scroll view bounces past the edge of content and back again.
- [bouncesHorizontally](/documentation/uikit/uiscrollview/bounceshorizontally) A Boolean value that determines whether the scroll view bounces when it reaches the ends of its horizontal axis.
- [bouncesVertically](/documentation/uikit/uiscrollview/bouncesvertically) A Boolean value that determines whether the scroll view bounces when it reaches the ends of its vertical axis.
- [alwaysBounceVertical](/documentation/uikit/uiscrollview/alwaysbouncevertical) A Boolean value that determines whether bouncing always occurs when vertical scrolling reaches the end of the content.
- [alwaysBounceHorizontal](/documentation/uikit/uiscrollview/alwaysbouncehorizontal) A Boolean value that determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view.

## Managing the scrolling state

- [isTracking](/documentation/uikit/uiscrollview/istracking) A Boolean value that indicates whether the user has touched the content to initiate scrolling.
- [isDragging](/documentation/uikit/uiscrollview/isdragging) A Boolean value that indicates whether the user has begun scrolling the content.
- [isDecelerating](/documentation/uikit/uiscrollview/isdecelerating) A Boolean value that indicates whether the content is moving in the scroll view after the user lifted their finger.
- [isScrollAnimating](/documentation/uikit/uiscrollview/isscrollanimating) A Boolean value that indicates whether the scroll view is currently animating a scroll update.
- [stopScrollingAndZooming()](/documentation/uikit/uiscrollview/stopscrollingandzooming()) Stops active scroll and zoom animations.
- [decelerationRate](/documentation/uikit/uiscrollview/decelerationrate-swift.property) A floating-point value that determines the rate of deceleration after the user lifts their finger.
- [UIScrollView.DecelerationRate](/documentation/uikit/uiscrollview/decelerationrate-swift.struct) Deceleration rates for the scroll view.

## Applying edge effects

- [bottomEdgeEffect](/documentation/uikit/uiscrollview/bottomedgeeffect) The effect for the bottom edge of the scroll view.
- [leftEdgeEffect](/documentation/uikit/uiscrollview/leftedgeeffect) The effect for the left edge of the scroll view.
- [rightEdgeEffect](/documentation/uikit/uiscrollview/rightedgeeffect) The effect for the right edge of the scroll view.
- [topEdgeEffect](/documentation/uikit/uiscrollview/topedgeeffect) The effect for the top edge of the scroll view.
- [UIScrollEdgeEffect](/documentation/uikit/uiscrolledgeeffect) Properties of the effect on a particular edge of the scroll view.
- [UIScrollEdgeEffect.Style](/documentation/uikit/uiscrolledgeeffect/style-swift.class) Styles for a scroll view’s edge effect.

## Managing the scroll indicator and refresh control

- [indicatorStyle](/documentation/uikit/uiscrollview/indicatorstyle-swift.property) The style of the scroll indicators.
- [UIScrollView.IndicatorStyle](/documentation/uikit/uiscrollview/indicatorstyle-swift.enum) Defines constants that represent the styles of the scroll indicators.
- [showsHorizontalScrollIndicator](/documentation/uikit/uiscrollview/showshorizontalscrollindicator) A Boolean value that controls whether the horizontal scroll indicator is visible.
- [showsVerticalScrollIndicator](/documentation/uikit/uiscrollview/showsverticalscrollindicator) A Boolean value that controls whether the vertical scroll indicator is visible.
- [horizontalScrollIndicatorInsets](/documentation/uikit/uiscrollview/horizontalscrollindicatorinsets) The horizontal distance the scroll indicators are inset from the edge of the scroll view.
- [verticalScrollIndicatorInsets](/documentation/uikit/uiscrollview/verticalscrollindicatorinsets) The vertical distance the scroll indicators are inset from the edge of the scroll view.
- [automaticallyAdjustsScrollIndicatorInsets](/documentation/uikit/uiscrollview/automaticallyadjustsscrollindicatorinsets) A Boolean value that indicates whether the system automatically adjusts the scroll indicator insets.
- [flashScrollIndicators()](/documentation/uikit/uiscrollview/flashscrollindicators()) Displays the scroll indicators momentarily.
- [withScrollIndicatorsShown(forContentOffsetChanges:)](/documentation/uikit/uiscrollview/withscrollindicatorsshown(forcontentoffsetchanges:)) Displays the scroll indicators during updates to the scroll view’s content offset.
- [refreshControl](/documentation/uikit/uiscrollview/refreshcontrol) The refresh control associated with the scroll view.
- [UIRefreshControl](/documentation/uikit/uirefreshcontrol) A standard control that can initiate the refreshing of a scroll view’s contents.

## Scrolling to a specific location

- [scrollRectToVisible(_:animated:)](/documentation/uikit/uiscrollview/scrollrecttovisible(_:animated:)) Scrolls a specific area of the content so that it’s visible in the scroll view.

## Managing touches

- [touchesShouldBegin(_:with:in:)](/documentation/uikit/uiscrollview/touchesshouldbegin(_:with:in:)) Overridden by subclasses to customize the default behavior when a finger touches down in displayed content.
- [touchesShouldCancel(in:)](/documentation/uikit/uiscrollview/touchesshouldcancel(in:)) Returns whether to cancel touches related to the content subview and start dragging.
- [canCancelContentTouches](/documentation/uikit/uiscrollview/cancancelcontenttouches) A Boolean value that controls whether touches in the content view always lead to tracking.
- [delaysContentTouches](/documentation/uikit/uiscrollview/delayscontenttouches) A Boolean value that determines whether the scroll view delays the handling of touch-down gestures.
- [directionalPressGestureRecognizer](/documentation/uikit/uiscrollview/directionalpressgesturerecognizer) The underlying gesture recognizer for directional button presses.

## Zooming and panning

- [panGestureRecognizer](/documentation/uikit/uiscrollview/pangesturerecognizer) The underlying gesture recognizer for pan gestures.
- [pinchGestureRecognizer](/documentation/uikit/uiscrollview/pinchgesturerecognizer) The underlying gesture recognizer for pinch gestures.
- [zoom(to:animated:)](/documentation/uikit/uiscrollview/zoom(to:animated:)) Zooms to a specific area of the content so that it’s visible in the scroll view.
- [zoomScale](/documentation/uikit/uiscrollview/zoomscale) A floating-point value that specifies the current scale factor applied to the scroll view’s content.
- [setZoomScale(_:animated:)](/documentation/uikit/uiscrollview/setzoomscale(_:animated:)) A floating-point value that specifies the current zoom scale.
- [maximumZoomScale](/documentation/uikit/uiscrollview/maximumzoomscale) A floating-point value that specifies the maximum scale factor that can apply to the scroll view’s content.
- [minimumZoomScale](/documentation/uikit/uiscrollview/minimumzoomscale) A floating-point value that specifies the minimum scale factor that can apply to the scroll view’s content.
- [isZoomBouncing](/documentation/uikit/uiscrollview/iszoombouncing) A Boolean value that indicates that zooming has exceeded the scaling limits specified for the scroll view.
- [isZooming](/documentation/uikit/uiscrollview/iszooming) A Boolean value that indicates whether the content view is currently zooming in or out.
- [isZoomAnimating](/documentation/uikit/uiscrollview/iszoomanimating) A Boolean value that indicates whether the scroll view is currently animating a zoom update.
- [bouncesZoom](/documentation/uikit/uiscrollview/bounceszoom) A Boolean value that determines whether the scroll view animates the content scaling when the scaling exceeds the maximum or minimum limits.

## Dismissing the keyboard

- [keyboardDismissMode](/documentation/uikit/uiscrollview/keyboarddismissmode-swift.property) The manner in which the system dismisses the keyboard when a drag begins in the scroll view.
- [UIScrollView.KeyboardDismissMode](/documentation/uikit/uiscrollview/keyboarddismissmode-swift.enum) Constants that determine how the system dismisses the keyboard when a drag begins in the scroll view.

## Managing the index

- [indexDisplayMode](/documentation/uikit/uiscrollview/indexdisplaymode-swift.property) The manner in which the index appears while the user is scrolling.
- [UIScrollView.IndexDisplayMode](/documentation/uikit/uiscrollview/indexdisplaymode-swift.enum) Defines constants that represent how the index appears while the user is scrolling.

## Controlling content alignment

- [contentAlignmentPoint](/documentation/uikit/uiscrollview/contentalignmentpoint) A point where the scroll view anchors content that’s smaller than the scroll view’s frame.

## Nesting scroll views

- [transfersHorizontalScrollingToParent](/documentation/uikit/uiscrollview/transfershorizontalscrollingtoparent) A Boolean value that determines whether the scroll view passes horizontal scroll events to a superview.
- [transfersVerticalScrollingToParent](/documentation/uikit/uiscrollview/transfersverticalscrollingtoparent) A Boolean value that determines whether the scroll view passes vertical scroll events to a superview.

## Deprecated

- [scrollIndicatorInsets](/documentation/uikit/uiscrollview/scrollindicatorinsets) The distance the scroll indicators are inset from the edge of the scroll view.

## Instance Properties

- [allowsKeyboardScrolling](/documentation/uikit/uiscrollview/allowskeyboardscrolling) A Boolean value that determines whether the scroll view allows scrolling its content with hardware keyboard input.
- [lookToScrollAxes](/documentation/uikit/uiscrollview/looktoscrollaxes) Setting lookToScrollAxes turns on Look to Scroll for the scroll view in directions of the defined axis

## Container views

- [Autosizing views for localization in iOS](/documentation/Xcode/autosizing-views-for-localization-in-ios) Add auto layout constraints to your app to achieve localizable views.
- [Collection views](/documentation/uikit/collection-views) Display nested views using a configurable and highly customizable layout.
- [Table views](/documentation/uikit/table-views) Display data in a single column of customizable rows.
- [UIStackView](/documentation/uikit/uistackview) A streamlined interface for laying out a collection of views in either a column or a row.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
