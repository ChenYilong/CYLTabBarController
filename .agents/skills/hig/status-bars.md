---
title: Status bars
description: A status bar appears along the upper edge of the screen and displays information about the device’s current state, like the time, cellular carrier, and battery level.
source: https://developer.apple.com/design/human-interface-guidelines/status-bars
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/status-bars.json
timestamp: 2026-04-14T13:14:22.175Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Status bars

> A status bar appears along the upper edge of the screen and displays information about the device’s current state, like the time, cellular carrier, and battery level.

![A stylized representation of an iPhone status bar with labels showing the time and cellular, Wi-Fi, and battery levels. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/40c473cb5ee61ef7713a4ec2949aadb5/components-status-bar-intro%402x.png)

## Best practices

**Obscure content under the status bar.** By default, the background of the status bar is transparent, allowing content beneath to show through. This transparency can make it difficult to see information presented in the status bar. If controls are visible behind the status bar, people may attempt to interact with them and be unable to do so. Be sure to keep the status bar readable, and don’t imply that content behind it is interactive. Prefer using a scroll edge effect to place a blurred view behind the status bar. For developer guidance, see [ScrollEdgeEffectStyle](/documentation/SwiftUI/ScrollEdgeEffectStyle) and [UIScrollEdgeEffect](/documentation/UIKit/UIScrollEdgeEffect).

**Consider temporarily hiding the status bar when displaying full-screen media.** A status bar can be distracting when people are paying attention to media. Temporarily hide these elements to provide a more immersive experience. The Photos app, for example, hides the status bar and other interface elements when people browse full-screen photos.

![A screenshot of the top half of the Photos app on iPhone, showing a photo filling the screen. The status bar is visible at the top of the screen.](https://docs-assets.developer.apple.com/published/7312261e2309c5707b50e5361375c651/status-bar-visible%402x.png)

![A screenshot of the top half of the Photos app on iPhone, showing a photo filling the screen. The status bar is hidden, and only the photo is visible.](https://docs-assets.developer.apple.com/published/546831607b77b71bf7928e60e9949e9b/status-bar-hidden%402x.png)

**Avoid permanently hiding the status bar.** Without a status bar, people have to leave your app to check the time or see if they have a Wi-Fi connection. Let people redisplay a hidden status bar with a simple, discoverable gesture. For example, when browsing full-screen photos in the Photos app, a single tap shows the status bar again.

## Platform considerations

*No additional considerations for iOS or iPadOS. Not supported in macOS, tvOS, visionOS, or watchOS.*

## Resources

#### Developer documentation

[UIStatusBarStyle](/documentation/UIKit/UIStatusBarStyle) — UIKit

[preferredStatusBarStyle](/documentation/UIKit/UIViewController/preferredStatusBarStyle) — UIKit

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
