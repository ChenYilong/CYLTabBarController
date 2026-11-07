---
title: Sidebars
description: A sidebar appears on the leading side of a view and lets people navigate between areas of your app or top-level collections of content, like folders and playlists.
source: https://developer.apple.com/design/human-interface-guidelines/sidebars
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/sidebars.json
timestamp: 2026-06-26T06:39:36.308Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Sidebars

> A sidebar appears on the leading side of a view and lets people navigate between areas of your app or top-level collections of content, like folders and playlists.

![A stylized representation of the top portion of a window's sidebar displaying a section and some folders. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/db15975aff9a1ef03b7d799b10bf0947/components-sidebar-intro%402x.png)

A sidebar requires a large amount of vertical and horizontal space. When space is limited or you want to devote more of the screen to other information or functionality, a more compact control such as a tab bar may provide a better navigation experience. For many apps, you don’t need to choose between a tab bar or sidebar for navigation; instead, you can adopt a style of tab bar that provides both. For guidance, see [Tab bars](/design/human-interface-guidelines/tab-bars) and [Layout](/design/human-interface-guidelines/layout).

## Best practices

**Extend visually rich content beneath the sidebar.** In iOS, iPadOS, and macOS, as with other controls such as toolbars and tab bars, sidebars can float above content in the [Liquid Glass](/design/human-interface-guidelines/materials#Liquid-Glass) layer. To reinforce the separation, you can extend content beneath the sidebar either by letting it horizontally scroll or by applying a *background extension effect*. A background extension effect mirrors adjacent content to give the impression of stretching it under the sidebar. For developer guidance, see [backgroundExtensionEffect()](/documentation/SwiftUI/View/backgroundExtensionEffect()).

![A screenshot of the leading side of an app on iPad. An image spans the upper part of the window, stopping at the edge of the sidebar.](https://docs-assets.developer.apple.com/published/2998d80d2d5891977dc3774166b786c9/sidebars-extend-content-beneath-sidebar-incorrect%402x.png)

![An X in a circle to indicate incorrect usage.](https://docs-assets.developer.apple.com/published/209f6f0fc8ad99d9bf59e12d82d06584/crossout%402x.png)

![A screenshot of the leading side of an app on iPad. An image spans the upper part of the window, and uses a background extension effect to flip, blur, and extend the image beneath the sidebar to the edge of the window.](https://docs-assets.developer.apple.com/published/ea3adff86d3af258c4bde48160ceb273/sidebars-extend-content-beneath-sidebar-correct%402x.png)

![A checkmark in a circle to indicate correct usage.](https://docs-assets.developer.apple.com/published/88662da92338267bb64cd2275c84e484/checkmark%402x.png)

**When possible, let people customize the contents of a sidebar.** A sidebar lets people navigate to important areas in your app, so it works well when people can decide which areas are most important and in what order they appear.

**Group hierarchy with disclosure controls if your app has a lot of content.** Using [Disclosure controls](/design/human-interface-guidelines/disclosure-controls) helps keep the sidebar’s vertical space to a manageable level.

**Consider using familiar symbols to represent items in the sidebar.** [SF Symbols](/design/human-interface-guidelines/sf-symbols) provides a wide range of customizable symbols you can use to represent items in your app. If you need to use a custom icon, consider creating a [Custom symbols](/design/human-interface-guidelines/sf-symbols#Custom-symbols) rather than using a bitmap image. Download the SF Symbols app from [Apple Design Resources](https://developer.apple.com/design/resources/#sf-symbols).

**Consider letting people hide the sidebar.** People sometimes want to hide the sidebar to create more room for content details or to reduce distraction. When possible, let people hide and show the sidebar using the platform-specific interactions they already know. For example, in iPadOS, people expect to use the built-in edge swipe gesture; in macOS, you can include a show/hide button or add Show Sidebar and Hide Sidebar commands to your app’s View menu. In visionOS, a window typically expands to accommodate a sidebar, so people rarely need to hide it. Avoid hiding the sidebar by default to ensure that it remains discoverable.

**In general, show no more than two levels of hierarchy in a sidebar.** When a data hierarchy is deeper than two levels, consider using a split view interface that includes a content list between the sidebar items and detail view.

**If you need to include two levels of hierarchy in a sidebar, use succinct, descriptive labels to title each group.** To help keep labels short, omit unnecessary words.

**Make sure any sidebar icon colors you choose serve a clear purpose.** By default, sidebar icons use your app’s [App accent colors](/design/human-interface-guidelines/color#App-accent-colors). In macOS, people can change the system accent color, which applies to all apps. When they do this, they expect all sidebar icons to appear in that color, so make sure your sidebar icons display the color people choose. However, if you use them sparingly, fixed colors can help clarify the meaning of an icon or draw attention to it. For example, the VIP icon in Mail uses a yellow color to set it apart from other sidebar icons, providing a visual cue about its importance.

## Platform considerations

*No additional considerations for tvOS. Not supported in watchOS.*

### iOS, iPadOS

When you use the [sidebarAdaptable](/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) style of tab view to present a sidebar, you choose whether to display a sidebar or a tab bar when your app opens. Both variations include a button that people can use to switch between them. This style also adapts its appearance depending on the platform, and responds automatically to rotation and window resizing, providing a version of the control that’s appropriate to the width of the view.

> **Developer note:** To display a sidebar only, use [NavigationSplitView](/documentation/SwiftUI/NavigationSplitView) to present a sidebar in the primary pane of a split view, or use [UISplitViewController](/documentation/UIKit/UISplitViewController).

**Consider using a tab bar first.** A tab bar provides more space to feature content, and offers enough flexibility to navigate between many apps’ main areas. If you need to expose more areas than fit in a tab bar, the tab bar’s convertible sidebar-style appearance can provide access to content that people use less frequently. For guidance, see [Tab bars](/design/human-interface-guidelines/tab-bars).

**If necessary, apply the correct appearance to a sidebar.** If you’re not using SwiftUI to create a sidebar, you can use the [UICollectionLayoutListConfiguration.Appearance.sidebar](/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct/Appearance-swift.enum/sidebar) appearance of a collection view list layout. For developer guidance, see [UICollectionLayoutListConfiguration.Appearance](/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct/Appearance-swift.enum).

### macOS

A sidebar’s row height, text, and glyph size depend on its overall size, which can be small, medium, or large. You can set the size programmatically, but people can also change it by selecting a different sidebar icon size in General settings.

**Consider automatically hiding and revealing a sidebar when its container window resizes.** For example, reducing the size of a Mail viewer window can automatically collapse its sidebar, making more room for message content.

**Avoid putting critical information or actions at the bottom of a sidebar.** People often relocate a window in a way that hides its bottom edge.

### visionOS

**If your app’s hierarchy is deep, consider using a sidebar within a tab in a tab bar.** In this situation, a sidebar can support secondary navigation within the tab. If you do this, be sure to prevent selections in the sidebar from changing which tab is currently open.

![A partial screenshot of the Music app in visionOS. The app's window includes a sidebar for navigating the music library, and the secondary pane includes a grid of playlists.](https://docs-assets.developer.apple.com/published/4c166ae0e198642b7f73ee07fb579346/visionos-sidebar-music%402x.png)

## Resources

#### Related

[Split views](/design/human-interface-guidelines/split-views)

[Tab bars](/design/human-interface-guidelines/tab-bars)

[Layout](/design/human-interface-guidelines/layout)

#### Developer documentation

[sidebarAdaptable](/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) — SwiftUI

[NavigationSplitView](/documentation/SwiftUI/NavigationSplitView) — SwiftUI

[sidebar](/documentation/SwiftUI/ListStyle/sidebar) — SwiftUI

[UICollectionLayoutListConfiguration](/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct) — UIKit

[NSSplitViewController](/documentation/AppKit/NSSplitViewController) — AppKit

#### Videos

- [Elevate the design of your iPad app](https://developer.apple.com/videos/play/wwdc2025/208) - Make your app look and feel great on iPadOS. Learn best practices for designing a responsive layout for resizable app windows. Get familiar with window controls and explore the best ways to accommodate them. Discover the building blocks of a great menu bar. And meet the new pointer and its updated effects.

## Change log

| Date | Changes |
| --- | --- |
| June 8, 2026 | Updated guidance for sidebar icon colors, and clarified guidance for the adaptable sidebar style. |
| June 9, 2025 | Added guidance for extending content beneath the sidebar. |
| August 6, 2024 | Updated guidance to include the SwiftUI adaptable sidebar style. |
| December 5, 2023 | Added artwork for iPadOS. |
| June 21, 2023 | Updated to include guidance for visionOS. |

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
