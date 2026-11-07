---
title: scrollEdgeEffectStyle(_:for:)
description: Configures the scroll edge effect style for scroll views within this hierarchy.
source: https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/swiftui/view/scrolledgeeffectstyle(_:for:).json
timestamp: 2026-06-26T06:39:36.413Z
---

**Navigation:** [SwiftUI](/documentation/swiftui) › [View](/documentation/swiftui/view)

**Instance Method**

# scrollEdgeEffectStyle(_:for:)

**Available on:** iOS 26.0+, iPadOS 26.0+, Mac Catalyst 26.0+, macOS 26.0+, tvOS 26.0+, watchOS 26.0+

> Configures the scroll edge effect style for scroll views within this hierarchy.

```swift
nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View
```

## Discussion

By default, a scroll view renders an automatic edge effect. Use this modifier to change the scroll edge effect style.

```swift
ScrollView {
    LazyVStack {
        ForEach(data) { item in
            RowView(item)
        }
    }
}
.scrollEdgeEffectStyle(.hard, for: .all)
```

## Configuring scroll edge effects

- [scrollEdgeEffectHidden(_:for:)](/documentation/swiftui/view/scrolledgeeffecthidden(_:for:)) Hides any scroll edge effects for scroll views within this hierarchy.
- [ScrollEdgeEffectStyle](/documentation/swiftui/scrolledgeeffectstyle) A structure that specifies blur transitions between scrolling content and an area with controls, such as toolbars.
- [safeAreaBar(edge:alignment:spacing:content:)](/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)) Shows the specified content as a custom bar beside the modified view.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
