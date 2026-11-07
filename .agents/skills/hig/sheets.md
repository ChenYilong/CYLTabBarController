---
title: Sheets
description: A sheet helps people perform a scoped task that’s closely related to their current context.
source: https://developer.apple.com/design/human-interface-guidelines/sheets
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/sheets.json
timestamp: 2026-04-14T13:14:21.275Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Sheets

> A sheet helps people perform a scoped task that’s closely related to their current context.

![A stylized representation of a sheet extending down from the top of a window. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/56b1f2417f35468434a5cb9bb0ea6653/components-sheet-intro%402x.png)

A sheet is useful for requesting specific information from people or presenting a simple task that they can complete before returning to the parent view. For example, a sheet might let people supply information needed to complete an action, such as attaching a file or choosing a location to save it.

## Anatomy

In macOS, tvOS, visionOS, and watchOS, a sheet is always *modal*. A modal sheet presents a targeted experience that prevents people from interacting with the parent view until they dismiss the sheet (for more on modal presentation, see [Modality](/design/human-interface-guidelines/modality)).

In iOS and iPadOS, a sheet can be either modal or *nonmodal*. When a nonmodal sheet is onscreen, people use its functionality to affect the parent view without dismissing the sheet. For example, Notes on iPhone and iPad uses a nonmodal sheet to let people format various text selections as they edit a note.

![A screenshot of an in-progress note on iPhone. Several words are selected and highlighted. In the bottom half of the screen, the format sheet shows that the selected words use the regular body font.](https://docs-assets.developer.apple.com/published/731fe7f99a8c2ea9cfd6fd8cd2fb8f14/sheets-nonmodal-notes-text-regular%402x.png)

![A screenshot of the same in-progress note on iPhone. Different words are selected and highlighted. The format sheet shows that the selected words use the body font in italics.](https://docs-assets.developer.apple.com/published/78fb0b5df5fe8601d09ca62211ab12dc/sheets-nonmodal-notes-text-italic%402x.png)

There are several common buttons that help people navigate through and dismiss sheets.

- The **Cancel** (or Close) button dismisses a sheet without saving any changes. This type of button is common in most sheets.
- The **Done** button dismisses a sheet after completing a task or explicitly saving changes.
- The **Back** button lets people navigate to a previous step in a multi-step flow or to a parent view in a hierarchy. It isn’t intended to dismiss a sheet.

The placement of these buttons varies between platforms; see [Platform considerations](/design/human-interface-guidelines/sheets#Platform-considerations).

## Best practices

**For complex or prolonged user flows, consider alternatives to sheets.** For example, iOS and iPadOS offer a full-screen style of modal view that can work well to display content like videos, photos, or camera views or to help people perform multistep tasks like document or photo editing. (For developer guidance, see [UIModalPresentationStyle.fullScreen](/documentation/UIKit/UIModalPresentationStyle/fullScreen).) In a macOS experience, you might want to open a new window or let people enter full-screen mode instead of using a sheet. For example, a self-contained task like editing a document tends to work well in a separate window, whereas [Going full screen](/design/human-interface-guidelines/going-full-screen) can help people view media. In visionOS, you can give people a way to transition your app to a Full Space where they can dive into content or a task; for guidance, see [Immersive experiences](/design/human-interface-guidelines/immersive-experiences).

**Display only one sheet at a time from the main interface.** When people close a sheet, they expect to return to the parent view or window. If closing a sheet takes people back to another sheet, they can lose track of where they are in your app. If something people do within a sheet results in another sheet appearing, close the first sheet before displaying the new one. If necessary, you can display the first sheet again after people dismiss the second one.

**Use a nonmodal view when you want to present supplementary items that affect the main task in the parent view.** To give people access to information and actions they need while continuing to interact with the main window, consider using a [Split views](/design/human-interface-guidelines/split-views) in visionOS or a [Panels](/design/human-interface-guidelines/panels) in macOS; in iOS and iPadOS, you can use a nonmodal sheet for this workflow. For guidance, see [iOS, iPadOS](/design/human-interface-guidelines/sheets#iOS-iPadOS).

**Provide an alternative to the Done button.** If you provide a Done button, always pair it with a Cancel button to give people a clear way to dismiss the sheet without confirming or saving their changes, or a Back button to move to a previous step in the sheet. Relying solely on the Done button implies that completing the task is the only way to exit the sheet, which can feel restrictive or misleading.

![An illustration of the top half of a sheet on iPhone. A Done button appears in the top-right corner on its own.](https://docs-assets.developer.apple.com/published/ad0fbb0adb9fa95e2ff290511dbb23d5/sheets-buttons-placement-done-incorrect%402x.png)

![An X in a circle to indicate incorrect usage.](https://docs-assets.developer.apple.com/published/209f6f0fc8ad99d9bf59e12d82d06584/crossout%402x.png)

![An illustration of the top half of a sheet on iPhone. A Cancel button appears in the top-left corner of the view, and a Done button appears in the top-right corner.](https://docs-assets.developer.apple.com/published/c25b642725d9fae7c94db8e1bc61f6c5/sheets-buttons-placement-cancel-done%402x.png)

![A checkmark in a circle to indicate correct usage.](https://docs-assets.developer.apple.com/published/88662da92338267bb64cd2275c84e484/checkmark%402x.png)

Avoid showing all three buttons — Cancel, Done, and Back — together.

![An illustration of the top half of a sheet on iPhone. A Back button appears in the top-left corner of the view, and Cancel and Done buttons appear together in the top-right corner.](https://docs-assets.developer.apple.com/published/d0af7675c1758bba37ef872b8a95cc69/sheets-buttons-placement-back-cancel-done-incorrect%402x.png)

![An X in a circle to indicate incorrect usage.](https://docs-assets.developer.apple.com/published/209f6f0fc8ad99d9bf59e12d82d06584/crossout%402x.png)

## Platform considerations

*No additional considerations for tvOS.*

### iOS, iPadOS

In iOS and iPadOS, for sheets with a single view, the Cancel button belongs on the leading edge of the top toolbar. When present, the Done button belongs on the trailing edge.

![An illustration of the top half of a sheet on iPhone. A Cancel button appears in the top-left corner of the view, and a Done button appears in the top-right corner.](https://docs-assets.developer.apple.com/published/c25b642725d9fae7c94db8e1bc61f6c5/sheets-buttons-placement-cancel-done%402x.png)

For sheets with a multi-step flow, the placement of buttons can vary across steps.

### First step

![An illustration of the top half of a sheet on iPhone. A Cancel button appears in the top-left corner of the view, and an inactive Done button appears in the top-right corner.](https://docs-assets.developer.apple.com/published/cf1486ad40bc9a9049496c80307c9c29/sheets-buttons-placement-navigation-first-page%402x.png)

### Subsequent step

![An illustration of the top half of a sheet on iPhone. A Back button appears in the top-left corner of the view, and an inactive Done button appears in the top-right corner.](https://docs-assets.developer.apple.com/published/11e302162744b049b4bd12dc4e32e981/sheets-buttons-placement-navigation-subsequent-page%402x.png)

### Final step

![An illustration of the top half of a sheet on iPhone. A Back button appears in the top-left corner of the view, and a Done button appears in the top-right corner.](https://docs-assets.developer.apple.com/published/aa372d9eb2dd5f0a60643a268403831f/sheets-buttons-placement-navigation-final-page%402x.png)

A resizable sheet expands when people scroll its contents or drag the *grabber*, which is a small horizontal indicator that can appear at the top edge of a sheet. Sheets resize according to their *detents*, which are particular heights at which a sheet naturally rests. Designed for iPhone, detents specify particular heights at which a sheet naturally rests. The system defines two detents: *large* is the height of a fully expanded sheet and *medium* is about half of the fully expanded height. Sheets can have one or more custom detent values.

![An illustration showing an iPhone screen in portrait orientation containing a solid rounded rectangle that occupies almost all of the screen, representing a full-screen sheet. A rounded close button appears in the upper-left corner of the sheet.](https://docs-assets.developer.apple.com/published/f9ff6598276d795965351a853fdf234f/sheets-large-detent%402x.png)

![An illustration showing an iPhone screen in portrait orientation containing a solid rounded rectangle that occupies half of the screen, representing a half-screen sheet. A rounded close button appears in the upper-left corner of the sheet.](https://docs-assets.developer.apple.com/published/a41afbccdaa0d56ebbb42cde950b5143/sheets-medium-detent%402x.png)

Sheets automatically support the large detent. Adding the medium detent allows the sheet to rest at both heights, whereas specifying only medium prevents the sheet from expanding to full height. For developer guidance, see [detents](/documentation/UIKit/UISheetPresentationController/detents).

**In an iPhone app, consider supporting the medium detent to allow progressive disclosure of the sheet’s content.** For example, a share sheet displays the most relevant items within the medium detent, where they’re visible without resizing. To view more items, people can scroll or expand the sheet. In contrast, you might not want to support the medium detent if a sheet’s content is more useful when it displays at full height. For example, the compose sheets in Messages and Mail display only at full height to give people enough room to create content.

**Include a grabber in a resizable sheet.** A grabber shows people that they can drag the sheet to resize it; they can also tap it to cycle through the detents. In addition to providing a visual indicator of resizability, a grabber also works with VoiceOver so people can resize the sheet without seeing the screen. For developer guidance, see [prefersGrabberVisible](/documentation/UIKit/UISheetPresentationController/prefersGrabberVisible).

**Support swiping to dismiss a sheet.** People expect to swipe vertically to dismiss a sheet instead of tapping a dismiss button. If people have unsaved changes in the sheet when they begin swiping to dismiss it, use an action sheet to let them confirm their action.

**Prefer using the page or form sheet presentation styles in an iPadOS app.** Each style uses a default size for the sheet, centering its content on top of a dimmed background view and providing a consistent experience. For developer guidance, see [UIModalPresentationStyle](/documentation/UIKit/UIModalPresentationStyle).

### macOS

In macOS, a sheet is a cardlike view with rounded corners that floats on top of its parent window. The parent window is dimmed while the sheet is onscreen, signaling that people can’t interact with it until they dismiss the sheet. However, people expect to interact with other app windows before dismissing a sheet.

![A screenshot of the Notes app, with the What's New in Notes sheet centered on top of a dimmed Notes document in the background.](https://docs-assets.developer.apple.com/published/339b6c6484dfa55c1fe44780e42d5b6e/sheets-macos-notes%402x.png)

**Present a sheet in a reasonable default size.** People don’t generally expect to resize sheets, so it’s important to use a size that’s appropriate for the content you display. In some cases, however, people appreciate a resizable sheet — such as when they need to expand the contents for a clearer view — so it’s a good idea to support resizing.

**Let people interact with other app windows without first dismissing a sheet.** When a sheet opens, you bring its parent window to the front — if the parent window is a document window, you also bring forward its modeless document-related panels. When people want to interact with other windows in your app, make sure they can bring those windows forward even if they haven’t dismissed the sheet yet.

**Use a panel instead of a sheet if people need to repeatedly provide input and observe results.** A find and replace panel, for example, might let people initiate replacements individually, so they can observe the result of each search for correctness. For guidance, see [Panels](/design/human-interface-guidelines/panels).

### visionOS

While a sheet is visible in a visionOS app, it floats in front of its parent window, dimming it, and becoming the target of people’s interactions with the app.

**Avoid displaying a sheet that emerges from the bottom edge of a window.** To help people view the sheet, prefer centering it in their [Field of view](/design/human-interface-guidelines/spatial-layout#Field-of-view).

**Present a sheet in a default size that helps people retain their context.** Avoid displaying a sheet that covers most or all of its window, but consider letting people resize the sheet if they want.

### watchOS

In watchOS, a sheet is a full-screen view that slides over your app’s current content. The sheet is semitransparent to help maintain the current context, but the system applies a material to the background that blurs and desaturates the covered content.

![A screenshot of a sheet with a primary Action button and a default cancel button on Apple Watch.](https://docs-assets.developer.apple.com/published/e7ccbf2fa71e59c375c0005ffb77e892/sheets-watch-overlay%402x.png)

**Use a sheet only when your modal task requires a custom title or custom content presentation.** If you need to give people important information or present a set of choices, consider using an [Alerts](/design/human-interface-guidelines/alerts) or [Action sheets](/design/human-interface-guidelines/action-sheets).

**Keep sheet interactions brief and occasional.** Use a sheet only as a temporary interruption to the current workflow, and only to facilitate an important task. Avoid using a sheet to help people navigate your app’s content.

**If you change the default label, prefer using SF Symbols to represent the action.** Avoid using a label that might mislead people into thinking that the sheet is part of a hierarchical navigation interface. Also, if the text in the top-leading corner looks like a page or app title, people won’t know how to dismiss the sheet. For guidance, see [Standard icons](/design/human-interface-guidelines/icons#Standard-icons).

![A screenshot that shows a top toolbar with a custom Back button at the top of the screen on Apple Watch.](https://docs-assets.developer.apple.com/published/dcac6924e3fb5c84a977b9e6e39765c8/modal-sheet-watchos-do-not-1%402x.png)

![An X in a circle to indicate incorrect usage.](https://docs-assets.developer.apple.com/published/209f6f0fc8ad99d9bf59e12d82d06584/crossout%402x.png)

![A screenshot that shows a top toolbar with a button with the words Page title at the top of the screen on Apple Watch.](https://docs-assets.developer.apple.com/published/ae642c639962d013bd5ca533945541c4/modal-sheet-watchos-do-not-2%402x.png)

![An X in a circle to indicate incorrect usage.](https://docs-assets.developer.apple.com/published/209f6f0fc8ad99d9bf59e12d82d06584/crossout%402x.png)

![A screenshot that shows a top toolbar with the default Cancel button at the top of the screen on Apple Watch.](https://docs-assets.developer.apple.com/published/84b92411cfe67d5bb4798a6c3a86cb4c/modal-sheet-watchos-do%402x.png)

![A checkmark in a circle to indicate correct usage.](https://docs-assets.developer.apple.com/published/88662da92338267bb64cd2275c84e484/checkmark%402x.png)

## Resources

#### Related

[Modality](/design/human-interface-guidelines/modality)

[Action sheets](/design/human-interface-guidelines/action-sheets)

[Popovers](/design/human-interface-guidelines/popovers)

[Panels](/design/human-interface-guidelines/panels)

#### Developer documentation

[sheet(item:onDismiss:content:)](/documentation/SwiftUI/View/sheet(item:onDismiss:content:)) — SwiftUI

[UISheetPresentationController](/documentation/UIKit/UISheetPresentationController) — UIKit

[presentAsSheet(_:)](/documentation/AppKit/NSViewController/presentAsSheet(_:)) — AppKit

## Change log

| Date | Changes |
| --- | --- |
| March 24, 2026 | Updated guidance for button placement. |
| March 29, 2024 | Added guidance to use form or page sheet styles in iPadOS apps. |
| December 5, 2023 | Recommended using a split view to offer supplementary items in a visionOS app. |
| June 21, 2023 | Updated to include guidance for visionOS. |
| June 5, 2023 | Updated guidance for using sheets in watchOS. |

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
