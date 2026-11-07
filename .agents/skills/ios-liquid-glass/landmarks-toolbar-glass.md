---
title: Landmarks: Refining the system provided Liquid Glass effect in toolbars
description: Organize toolbars into related groupings to improve their appearance and utility.
source: https://developer.apple.com/documentation/swiftui/landmarks-refining-the-system-provided-glass-effect-in-toolbars
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/swiftui/landmarks-refining-the-system-provided-glass-effect-in-toolbars.json
timestamp: 2026-04-14T13:14:26.604Z
---

**Navigation:** [SwiftUI](/documentation/swiftui)

**Sample Code**

# Landmarks: Refining the system provided Liquid Glass effect in toolbars

**Available on:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, Xcode 26.0+

> Organize toolbars into related groupings to improve their appearance and utility.

## Overview

The Landmarks app lets people explore interesting sites around the world. Whether it’s a national park near their home or a far-flung location on a different continent, the app provides a way for people to organize and mark their adventures and receive custom activity badges along the way.

This sample demonstrates how to refine the system provided glass effect in toolbars. In `LandmarkDetailView`, the sample adds toolbar items for:

- sharing a landmark
- adding or removing a landmark from a list of Favorites
- adding or removing a landmark from Collections
- showing or hiding the inspector

The system applies Liquid Glass to the toolbar items automatically.

![An image of the landmark detail view for Mount Fuji on an iPad, with the toolbar and a portion of the sidebar visible. The toolbar items show the Liquid Glass effect. From the leading to trailing edge, there is a back button, share button, favorite button, collections button, info button, and a search bar.](https://docs-assets.developer.apple.com/published/d57c72c1a92b1dcdd763b4a22670a4db/Landmarks-Building-an-app-with-Liquid-Glass-4%402x.png)

## Organize the toolbar items into logical groupings

To organize the toolbar items into logical groupings, the sample adds [ToolbarSpacer](/documentation/swiftui/toolbarspacer) items and passes [fixed](/documentation/swiftui/spacersizing/fixed) as the `sizing` parameter to divide the toolbar into sections:

```swift
.toolbar {
    ToolbarSpacer(.flexible)

    ToolbarItem {
        ShareLink(item: landmark, preview: landmark.sharePreview)
    }

    ToolbarSpacer(.fixed)
    
    ToolbarItemGroup {
        LandmarkFavoriteButton(landmark: landmark)
        LandmarkCollectionsMenu(landmark: landmark)
    }
    
    ToolbarSpacer(.fixed)

    ToolbarItem {
        Button("Info", systemImage: "info") {
            modelData.selectedLandmark = landmark
            modelData.isLandmarkInspectorPresented.toggle()
        }
    }
}
```

## App features

- [Landmarks: Applying a background extension effect](/documentation/swiftui/landmarks-applying-a-background-extension-effect) Configure an image to blur and extend under a sidebar or inspector panel.
- [Landmarks: Extending horizontal scrolling under a sidebar or inspector](/documentation/swiftui/landmarks-extending-horizontal-scrolling-under-a-sidebar-or-inspector) Improve your horizontal scrollbar’s appearance by extending it under a sidebar or inspector.
- [Landmarks: Displaying custom activity badges](/documentation/swiftui/landmarks-displaying-custom-activity-badges) Provide people with a way to mark their adventures by displaying animated custom activity badges.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
