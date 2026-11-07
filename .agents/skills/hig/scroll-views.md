---
title: Scroll views
description: A scroll view lets people view content that’s larger than the view’s boundaries by moving the content vertically or horizontally.
source: https://developer.apple.com/design/human-interface-guidelines/scroll-views
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/scroll-views.json
timestamp: 2026-06-26T06:39:36.277Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Scroll views

> A scroll view lets people view content that’s larger than the view’s boundaries by moving the content vertically or horizontally.

![A stylized representation of a scrollable image view. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/e2b814efab83900282f34c04306401c1/components-scroll-view-intro%402x.png)

The scroll view itself has no appearance, but it can display a translucent *scroll indicator* that typically appears after people begin scrolling the view’s content. Although the appearance and behavior of scroll indicators can vary per platform, all indicators provide visual feedback about the scrolling action. For example, in iOS, iPadOS, macOS, visionOS, and watchOS, the indicator shows whether the currently visible content is near the beginning, middle, or end of the view.

## Best practices

**Support default scrolling gestures and keyboard shortcuts.** People are accustomed to the systemwide scrolling behavior and expect it to work everywhere. If you build custom scrolling for a view, make sure your scroll indicators use the elastic behavior that people expect.

**Make it apparent when content is scrollable.** Because scroll indicators aren’t always visible, it can be helpful to make it obvious when content extends beyond the view. For example, displaying partial content at the edge of a view indicates that there’s more content in that direction. Although most people immediately try scrolling a view to discover if additional content is available, it’s considerate to draw their attention to it.

**Avoid putting a scroll view inside another scroll view with the same orientation.** Nesting scroll views that have the same orientation can create an unpredictable interface that’s difficult to control. It’s alright to place a horizontal scroll view inside a vertical scroll view (or vice versa), however.

**Consider supporting page-by-page scrolling if it makes sense for your content.** In some situations, people appreciate scrolling by a fixed amount of content per interaction instead of scrolling continuously. On most platforms, you can define the size of such a *page* — typically the current height or width of the view — and define an interaction that scrolls one page at a time. To help maintain context during page-by-page scrolling, you can define a unit of overlap, such as a line of text, a row of glyphs, or part of a picture, and subtract the unit from the page size. For developer guidance, see [PagingScrollTargetBehavior](/documentation/SwiftUI/PagingScrollTargetBehavior).

**In some cases, scroll automatically to help people find their place.** Although people initiate almost all scrolling, automatic scrolling can be helpful when relevant content is no longer in view, such as when:

- Your app performs an operation that selects content or places the insertion point in an area that’s currently hidden. For example, when your app locates text that people are searching for, scroll the content to bring the new selection into view.
- People start entering information in a location that’s not currently visible. For example, if the insertion point is on one page and people navigate to another page, scroll back to the insertion point as soon as they begin to enter text.
- The pointer moves past the edge of the view while people are making a selection. In this case, follow the pointer by scrolling in the direction it moves.
- People select something and scroll to a new location before acting on the selection. In this case, scroll until the selection is in view before performing the operation.

In all cases, automatically scroll the content only as much as necessary to help people retain context. For example, if part of a selection is visible, you don’t need to scroll the entire selection into view.

**If you support zoom, set appropriate maximum and minimum scale values.** For example, zooming in on text until a single character fills the screen doesn’t make sense in most situations.

## Scroll edge effects

In iOS, iPadOS, and macOS, a *scroll edge effect* provides a visual separation between certain interface elements, such as [Toolbars](/design/human-interface-guidelines/toolbars), and the scrolling content area behind them. If you use custom bars, you might want to add this effect manually if the top layer of your interface needs extra clarity, or adjust its style from automatic to the hard or soft style.

![A screenshot of the top half of an iPhone app, with a photograph of a palm tree as the background and a top toolbar with a Back button, title label, and Add button. The transition between the toolbar and background uses a hard scroll edge effect, which applies a more opaque blur with a defined edge at the bottom of the bar.](https://docs-assets.developer.apple.com/published/82a59338e82cc9dea4063790f53e2e13/scroll-views-scroll-edge-effect-hard%402x.png)

![A screenshot of the top half of an iPhone app, with a photograph of a palm tree as the background and a top toolbar with a Back button, title label, and Add button. The transition between the toolbar and background uses a soft scroll edge effect, which applies a variable blur that provides a softer fade toward the bottom of the bar.](https://docs-assets.developer.apple.com/published/efdf39bd6f191c814326f8340c85955f/scroll-views-scroll-edge-effect-soft%402x.png)

**Prefer the automatic scroll edge effect style.** Where possible, use the default [automatic](/documentation/SwiftUI/ScrollEdgeEffectStyle/automatic) style of the scroll edge effect. This style provides a more opaque visual separation for top toolbars that contain a large number of controls, text that appears outside of [Liquid Glass](/design/human-interface-guidelines/materials#Liquid-Glass) controls, and pinned table headers. If you use the soft scroll edge effect style instead, thoroughly test your interface to ensure your controls maintain legibility in a variety of contexts.

**Only use a scroll edge effect when a scroll view is behind floating interface elements.** Scroll edge effects aren’t decorative. They don’t block or darken like overlays; they exist to ensure controls stay visually distinct.

**Apply one scroll edge effect per view.** In split view layouts on iPad and Mac, each pane can have its own scroll edge effect; in this case, keep them consistent in height to maintain alignment.

For developer guidance, see [ScrollEdgeEffectStyle](/documentation/SwiftUI/ScrollEdgeEffectStyle), [UIScrollEdgeEffect.Style](/documentation/UIKit/UIScrollEdgeEffect/Style-swift.class), and [NSScrollEdgeEffectStyle](/documentation/AppKit/NSScrollEdgeEffectStyle).

## Platform considerations

### iOS, iPadOS

**Consider showing a page control when a scroll view is in page-by-page mode.** [Page controls](/design/human-interface-guidelines/page-controls) show how many pages, screens, or other chunks of content are available and indicates which one is currently visible. For example, Weather uses a page control to indicate movement between people’s saved locations. If you show a page control with a scroll view, don’t show the scrolling indicator on the same axis to avoid confusing people with redundant controls.

### macOS

In macOS, a *scroll indicator* is commonly called a *scroll bar*.

**If necessary, use small or mini scroll bars in a panel.** When space is tight, you can use smaller scroll bars in panels that need to coexist with other windows. Be sure to use the same size for all controls in such a panel.

### tvOS

Views in tvOS can scroll, but they aren’t treated as distinct objects with scroll indicators. Instead, when content exceeds the size of the screen, the system automatically scrolls the interface to keep focused items visible.

### visionOS

In visionOS, the scroll indicator has a small, fixed size to help communicate that people can scroll efficiently without making large movements. To make it easy to find, the scroll indicator always appears in a predictable location with respect to the window: vertically centered at the trailing edge during vertical scrolling and horizontally centered at the window’s bottom edge during horizontal scrolling.

When people begin swiping content in the direction they want it to scroll, the scroll indicator appears at the window’s edge, visually reinforcing the effect of their gesture and providing feedback about the content’s current position and overall length. When people look at the scroll indicator and begin a drag gesture, the indicator enables a jog bar experience that lets people manipulate the scrolling speed instead of the content’s position. In this experience, the scroll indicator reveals tick marks that speed up or slow down as people make small adjustments to their gesture, providing visual feedback that helps people precisely control scrolling acceleration.

**If necessary, account for the size of the scroll indicator.** Although the indicator’s overall size is small, it’s a little thicker than the same component in iOS. If your content uses tight margins, consider increasing them to prevent the scroll indicator from overlapping the content.

#### Look to Scroll

In views that support Look to Scroll, people can scroll using only their eyes. Scrolling starts when people look near the boundary of the scroll view — along the top and bottom for vertical scroll views, or along the sides for horizontal scroll views. For example, a person can look at the bottom edge of a Safari window to scroll the page down, or look at an album on the trailing edge in the Music app to scroll it horizontally toward the center of the page. Look to Scroll works in conjunction with existing behavior, so someone can choose whether to use a gesture or their eyes to scroll. For developer guidance, see [look](/documentation/SwiftUI/ScrollInputKind/look).

**Support Look to Scroll for reading or browsing views.** Because Look to Scroll doesn’t work by default, you need to add support for it to each individual scroll view. If your app contains reading or browsing views, add support for Look to Scroll to provide a comfortable and hands-free experience. For developer guidance, see [ScrollInputKind](/documentation/SwiftUI/ScrollInputKind).

**Avoid using Look to Scroll for secondary content.** In general, support standard gestures — but not Look to Scroll — in views that contain UI controls or dense information that requires quick, precise scrolling. For example, the Notes app offers Look to Scroll within the main view to let people easily read their content, but doesn’t support it for the list of notes.

**Maintain consistency across content.** If you support Look to Scroll for one view in your app, make sure to support it for all similar views. For example, if you offer several collection views of videos throughout your app, support Look to Scroll for each of these views so people know what to expect.

**Define clear scroll areas within your app.** In views that support Look to Scroll, prefer making the view the full width or full height of the window. This gives people generous space to scroll and provides clear edges. If you inset a scroll view from a window, like in the Notes app, provide clear boundaries so people know where to look.

**If your app uses custom scroll effects or animations, remove them before supporting Look to Scroll.** Custom effects that use scroll position to change content, such as parallax effects and animations, can cause Look to Scroll to behave unexpectedly.

### watchOS

**Prefer vertically scrolling content.** People are accustomed to using the Digital Crown to navigate to and within apps on Apple Watch. If your app contains a single list or content view, rotating the Digital Crown scrolls vertically when your app’s content is taller than the height of the display.

**Use tab views to provide page-by-page scrolling.** watchOS displays tab views as pages. If you place tab views in a vertical stack, people can rotate the Digital Crown to move vertically through full-screen pages of content. In this scenario, the system displays a page indicator next to the Digital Crown that shows people where they are in the content, both within the current page and within a set of pages. For guidance, see [Tab views](/design/human-interface-guidelines/tab-views).

**When displaying paged content, consider limiting the content of an individual page to a single screen height.** Embracing this constraint clarifies the purpose of each page, helping you create a more glanceable design. However, if your app has long pages, people can still use the Digital Crown both to navigate between shorter pages and to scroll content in a longer page because the page indicator expands into a scroll indicator when necessary. Use variable-height pages judiciously and place them after fixed-height pages when possible.

## Resources

#### Related

[Page controls](/design/human-interface-guidelines/page-controls)

[Gestures](/design/human-interface-guidelines/gestures)

[Pointing devices](/design/human-interface-guidelines/pointing-devices)

#### Developer documentation

[ScrollView](/documentation/SwiftUI/ScrollView) — SwiftUI

[UIScrollView](/documentation/UIKit/UIScrollView) — UIKit

[NSScrollView](/documentation/AppKit/NSScrollView) — AppKit

[WKPageOrientation](/documentation/WatchKit/WKPageOrientation) — WatchKit

[look](/documentation/SwiftUI/ScrollInputKind/look) — SwiftUI

## Change log

| Date | Changes |
| --- | --- |
| June 8, 2026 | Updated guidance for scroll edge effects. |
| March 24, 2026 | Added guidance for Look to Scroll in visionOS. |
| July 28, 2025 | Added guidance for scroll edge effects. |
| February 2, 2024 | Added artwork showing the behavior of the visionOS scroll indicator. |
| December 5, 2023 | Described the visionOS scroll indicator and added guidance for integrating it with window layout. |
| June 5, 2023 | Updated guidance for using scroll views in watchOS. |

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
