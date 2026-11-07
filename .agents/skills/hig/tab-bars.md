---
title: Tab bars
description: A tab bar lets people navigate between top-level sections of your app.
source: https://developer.apple.com/design/human-interface-guidelines/tab-bars
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/tab-bars.json
timestamp: 2026-06-26T06:39:36.324Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Tab bars

> A tab bar lets people navigate between top-level sections of your app.

![A stylized representation of a tab bar containing four placeholder icons with names. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/ee5f6d676c6e45e45a667fe8d30b392d/components-tab-bar-intro%402x.png)

Tab bars help people understand the different types of information or functionality that an app provides. They also let people quickly switch between sections of the view while preserving the current navigation state within each section.

## Best practices

**Use a tab bar to support navigation, not to provide actions.** A tab bar lets people navigate among different sections of an app, like the Alarm, Stopwatch, and Timer tabs in the Clock app. If you need to provide controls that act on elements in the current view, use a [Toolbars](/design/human-interface-guidelines/toolbars) instead.

**Make sure the tab bar is visible when people navigate to different sections of your app.** If you hide the tab bar, people can forget which area of the app they’re in. The exception is when a modal view covers the tab bar, because a modal is temporary and self-contained.

**Use the appropriate number of tabs required to help people navigate your app.** As a representation of your app’s hierarchy, it’s important to weigh the complexity of additional tabs against the need for people to frequently access each section; keep in mind that it’s generally easier to navigate among fewer tabs. Where available, consider a sidebar or a tab bar that adapts to a sidebar as an alternative for an app with a complex information structure.

**Avoid overflow tabs.** Depending on device size and orientation, the number of visible tabs can be smaller than the total number of tabs. If horizontal space limits the number of visible tabs, the trailing tab becomes a More tab in iOS and iPadOS, revealing the remaining items in a separate list. The More tab makes it harder for people to reach and notice content on tabs that are hidden, so limit scenarios in your app where this can happen.

**Don’t disable or hide tab bar buttons, even when their content is unavailable.** Having tab bar buttons available in some cases but not others makes your app’s interface appear unstable and unpredictable. If a section is empty, explain why its content is unavailable.

**Include tab labels to help with navigation.** A tab label appears beneath or beside a tab bar icon, and can aid navigation by clearly describing the type of content or functionality the tab contains. Use single words whenever possible.

**Consider using SF Symbols to provide familiar, scalable tab bar icons.** When you use [SF Symbols](/design/human-interface-guidelines/sf-symbols), tab bar icons automatically adapt to different contexts. For example, the tab bar can be regular or compact, depending on the device and orientation. Tab bar icons appear above tab labels in compact views, whereas in regular views, the icons and labels appear side by side. Prefer filled symbols or icons for consistency with the platform.

![An illustration of two iPhone devices side by side. The first iPhone is in landscape orientation with a tab bar at the bottom of the screen, with tab bar icons on the leading edge of each tab and tab labels on the trailing edge. The second iPhone is in portrait orientation with a tab bar at the bottom of the screen, with tab bar icons above their respective tab labels.](https://docs-assets.developer.apple.com/published/e6f172f7ff4866fe757937dae03e2868/tab-bar-landscape%402x.png)

If you’re creating custom tab bar icons, see [Apple Design Resources](https://developer.apple.com/design/resources/) for tab bar icon dimensions.

![A diagram of a tab bar, with callouts indicating the location of the tab bar icon and tab label.](https://docs-assets.developer.apple.com/published/375cf01f8d10756d740ba2bdbe8f72c6/tab-bar-anatomy-callouts%402x.png)

**Use a badge to indicate that critical information is available.** You can display a badge — a red oval containing white text and either a number or an exclamation point — on a tab to indicate that there’s new or updated information in the section that warrants a person’s attention. Reserve badges for critical information so you don’t dilute their impact and meaning. For guidance, see [Notifications](/design/human-interface-guidelines/notifications).

![An illustration of the bottom half of an iPhone in portrait orientation, with a tab bar at the bottom of the screen. Two of the tabs have red circular badges attached, indicating the presence of critical information.](https://docs-assets.developer.apple.com/published/29a93bc69eaa415e2e3d5440474a8d36/tab-bar-badges-iphone%402x.png)

**Avoid applying a similar color to tab labels and content layer backgrounds.** If your app already has bright, colorful content in the content layer, prefer a monochromatic appearance for tab bars, or choose an accent color with sufficient visual differentiation. For more guidance, see [Liquid Glass color](/design/human-interface-guidelines/color#Liquid-Glass-color).

## Platform considerations

*No additional considerations for macOS. Not supported in watchOS.*

### iOS

A tab bar floats above content at the bottom of the screen. Its items rest on a [Liquid Glass](/design/human-interface-guidelines/materials#Liquid-Glass) background that allows content beneath to peek through.

For tab bars with an attached accessory, like the MiniPlayer in Music, you can choose to minimize the tab bar and move the accessory inline with it when a person scrolls down. A person can exit the minimized state by tapping a tab or scrolling to the top of the view. For developer guidance, see [TabBarMinimizeBehavior](/documentation/SwiftUI/TabBarMinimizeBehavior) and [UITabBarController.MinimizeBehavior](/documentation/UIKit/UITabBarController/MinimizeBehavior).

![An illustration of the bottom half of an iPhone in portrait orientation, with the Music app open. The MiniPlayer is open above the tab bar at the bottom of the screen.](https://docs-assets.developer.apple.com/published/fa928910fce5a5a6714124eb177171c1/tab-bar-with-accessory-expanded%402x.png)

![An illustration of the bottom half of an iPhone in portrait orientation, with the Music app open. The tab bar is minimized into the currently open tab at the leading bottom corner of the screen, with the MiniPlayer at the bottom center, and the search tab in the trailing corner.](https://docs-assets.developer.apple.com/published/b4d31e52ed5203c363b2a83aee77bcbd/tab-bar-with-accessory-collapsed%402x.png)

A tab bar can include a dedicated search tab at the trailing end. For guidance, see [Search fields](/design/human-interface-guidelines/search-fields).

### iPadOS

The system displays a tab bar near the top of the screen. You can choose to have the tab bar appear as a fixed element, or with a button that converts it to a sidebar. For developer guidance, see [tabBarOnly](/documentation/SwiftUI/TabViewStyle/tabBarOnly) and [sidebarAdaptable](/documentation/SwiftUI/TabViewStyle/sidebarAdaptable).

### Tab bar

![A screenshot showing the Music app on iPad with the tab bar near the top of the screen.](https://docs-assets.developer.apple.com/published/d6d8af003e21e73ed30da055d0210830/ipad-tab-bar-music-app%402x.png)

### Sidebar

![A screenshot showing the Music app on iPad with the tab bar converted to a sidebar on the leading edge of the screen.](https://docs-assets.developer.apple.com/published/a9182de73bd7815ee23d95f73de20915/ipad-sidebar-music-app%402x.png)

> **Note:** To present a sidebar without the option to convert it to a tab bar, use a [navigation split view](https://developer.apple.com/documentation/swiftui/navigationsplitview) instead of a tab view. For guidance, see [Sidebars](/design/human-interface-guidelines/sidebars).

**Prefer a tab bar for navigation.** A tab bar provides access to the sections of your app that people use most. If your app is more complex, you can provide the option to convert the tab bar to a sidebar so people can access a wider set of navigation options.

**Let people customize the tab bar.** In apps with a lot of sections that people might want to access, it can be useful to let people select items that they use frequently and add them to the tab bar, or remove items that they use less frequently. For example, in the Music app, a person can choose a favorite playlist to display in the tab bar. If you let people select their own tabs, aim for a default list of five or fewer to preserve continuity between compact and regular view sizes. For developer guidance, see [TabViewCustomization](/documentation/SwiftUI/TabViewCustomization) and [UITab.Placement](/documentation/UIKit/UITab/Placement).

### tvOS

A tab bar is highly customizable. For example, you can:

- Specify a tint, color, or image for the tab bar background
- Choose a font for tab items, including a different font for the selected item
- Specify tints for selected and unselected items
- Add button icons, like settings and search

By default, a tab bar is translucent, and only the selected tab is opaque. When people use the remote to focus on the tab bar, the selected tab includes a drop shadow that emphasizes its selected state. The height of a tab bar is 68 points, and its top edge is 46 points from the top of the screen; you can’t change either of these values.

If there are more items than can fit in the tab bar, the system truncates the rightmost item by applying a fade effect that begins at the right side of the tab bar. If there are enough items to cause scrolling, the system also applies a truncating fade effect that starts from the left side.

**Be aware of tab bar scrolling behaviors.** By default, people can scroll the tab bar offscreen when the current tab contains a single main view. You can see examples of this behavior in the Watch Now, Movies, TV Show, Sports, and Kids tabs in the TV app. The exception is when a screen contains a split view, such as the TV app’s Library tab or an app’s Settings screen. In this case, the tab bar remains pinned at the top of the view while people scroll the content within the primary and secondary panes of the split view. Regardless of a tab’s contents, focus always returns to the tab bar at the top of the page when people press Menu on the remote.

**In a live-viewing app, organize tabs in a consistent way.** For the best experience, organize content in live-streaming apps with tabs in the following order:

- Live content
- Cloud DVR or other recorded content
- Other content

For additional guidance, see [Live-viewing apps](/design/human-interface-guidelines/live-viewing-apps).

### visionOS

In visionOS, a tab bar is always vertical, floating in a position that’s fixed relative to the window’s leading side. When people look at a tab bar, it automatically expands; to open a specific tab, people look at the tab and tap. While a tab bar is expanded, it can temporarily obscure the content behind it.

**Supply a symbol and a text label for each tab.** A tab’s symbol is always visible in the tab bar. When people look at the tab bar, the system reveals tab labels, too. Even though the tab bar expands, you need to keep tab labels short so people can read them at a glance.

![A screenshot showing a collapsed tab bar containing only symbols.](https://docs-assets.developer.apple.com/published/e3841d7f6231fc5a1fc03b88337cc83f/visionos-tab-bar-collapsed%402x.png)

![A screenshot showing an expanded tab bar containing both symbols and labels.](https://docs-assets.developer.apple.com/published/ae30c6b5bfaf91fc871e720bb236f543/visionos-tab-bar-expanded%402x.png)

**If it makes sense in your app, consider using a sidebar within a tab.** If your app’s hierarchy is deep, you might want to use a [Sidebars](/design/human-interface-guidelines/sidebars) to support secondary navigation within a tab. If you do this, be sure to prevent selections in the sidebar from changing which tab is currently open.

## Resources

#### Related

[Tab views](/design/human-interface-guidelines/tab-views)

[Toolbars](/design/human-interface-guidelines/toolbars)

[Sidebars](/design/human-interface-guidelines/sidebars)

[Materials](/design/human-interface-guidelines/materials)

#### Developer documentation

[TabView](/documentation/SwiftUI/TabView) — SwiftUI

[TabViewBottomAccessoryPlacement](/documentation/SwiftUI/TabViewBottomAccessoryPlacement) — SwiftUI

[Enhancing your app’s content with tab navigation](/documentation/SwiftUI/Enhancing-your-app-content-with-tab-navigation) — SwiftUI

[UITabBar](/documentation/UIKit/UITabBar) — UIKit

[Elevating your iPad app with a tab bar and sidebar](/documentation/UIKit/elevating-your-ipad-app-with-a-tab-bar-and-sidebar) — UIKit

#### Videos

- [Get to know the new design system](https://developer.apple.com/videos/play/wwdc2025/356) - Dive deeper into the new design system to explore key changes to visual design, information architecture, and core system components. Learn how the system reshapes the relationship between interface and content, enabling you to create designs that are dynamic, harmonious, and consistent across devices, screen sizes, and input modes.
- [Elevate the design of your iPad app](https://developer.apple.com/videos/play/wwdc2025/208) - Make your app look and feel great on iPadOS. Learn best practices for designing a responsive layout for resizable app windows. Get familiar with window controls and explore the best ways to accommodate them. Discover the building blocks of a great menu bar. And meet the new pointer and its updated effects.

## Change log

| Date | Changes |
| --- | --- |
| June 8, 2026 | Updated terminology and art. |
| December 16, 2025 | Updated guidance for Liquid Glass. |
| July 28, 2025 | Added guidance for Liquid Glass. |
| September 9, 2024 | Added art representing the tab bar in iPadOS 18. |
| August 6, 2024 | Updated with guidance for the tab bar in iPadOS 18. |
| June 21, 2023 | Updated to include guidance for visionOS. |

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
