---
title: UIKit updates
description: Learn about important changes to UIKit.
source: https://developer.apple.com/documentation/updates/uikit
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/updates/uikit.json
timestamp: 2026-06-26T06:39:37.055Z
---

**Navigation:** [Updates](/documentation/updates)

**Article**

# UIKit updates

> Learn about important changes to UIKit.

## Overview

Browse notable changes in [UIKit](/documentation/UIKit).

## June 2026

### General

- Align sensor data from Core Location and Core Motion with your app’s UI orientation by setting a [UIView](/documentation/UIKit/UIView) as the body of a [CLLocationManager](/documentation/CoreLocation/CLLocationManager) or [CMMotionManager](/documentation/CoreMotion/CMMotionManager) instance.
- Use [UICollectionViewCompositionalLayoutSectionProvider](/documentation/UIKit/UICollectionViewCompositionalLayoutSectionProvider) closures as part of automatic observation tracking to automatically invalidate and update compositional layouts when observable objects change.
- Use [UIRefreshControl](/documentation/UIKit/UIRefreshControl) and [UIStepper](/documentation/UIKit/UIStepper) in Mac apps built with Mac Catalyst. These controls are now fully supported in the Mac idiom.

### App life cycle

- Adopt the UIKit scene-based life cycle using the guidance in [Transitioning to the UIKit scene-based life cycle](/documentation/UIKit/transitioning-to-the-uikit-scene-based-life-cycle). Starting in iOS 27, apps built with the latest SDK must use the scene-based life cycle or they fail to launch.

### Drag and drop

- Control drag initiation timing in gesture-rich views by configuring [UIDragInteraction](/documentation/UIKit/UIDragInteraction). Use [allowsPointerDragBeforeLiftDelay](/documentation/UIKit/UIDragInteraction/allowsPointerDragBeforeLiftDelay) to independently control when pointer-initiated drags begin.

### Text views

- Override viewport layout methods directly in a [UITextView](/documentation/UIKit/UITextView) subclass by conforming to [NSTextViewportLayoutControllerDelegate](/documentation/UIKit/NSTextViewportLayoutControllerDelegate).
- Register a [UITextAttachmentViewProviderReusePolicy](/documentation/UIKit/UITextAttachmentViewProviderReusePolicy) on `UITextView` to retain attachment views during scrolling and editing, preventing flicker and preserving view state.
- Use [NSTextTable](/documentation/UIKit/NSTextTable), [NSTextBlock](/documentation/UIKit/NSTextBlock), and [NSTextTableBlock](/documentation/UIKit/NSTextTableBlock) to represent table structures in attributed strings.
- Access paragraph text blocks using [textBlocks](/documentation/UIKit/NSParagraphStyle/textBlocks).
- Use [NSTextViewportRenderingSurface](/documentation/UIKit/NSTextViewportRenderingSurface) to render text in custom views and layers, and [NSTextViewportRenderingSurfaceKey](/documentation/UIKit/NSTextViewportRenderingSurfaceKey) to identify them for caching.

## June 2025

### General

- Provide seamless immersive visuals by using [UIBackgroundExtensionView](/documentation/UIKit/UIBackgroundExtensionView) to extend a view’s content under sidebars and inspectors.
- Apply Liquid Glass effects to views using [UIGlassEffect](/documentation/UIKit/UIGlassEffect).
- Organize views together for morph animations in [UIGlassContainerEffect](/documentation/UIKit/UIGlassContainerEffect).
- Add or adjust effects at the edge of a scroll view with [UIScrollEdgeEffect](/documentation/UIKit/UIScrollEdgeEffect).
- Apply Liquid Glass effects to buttons with [glass()](/documentation/UIKit/UIButton/Configuration-swift.struct/glass()) and [prominentGlass()](/documentation/UIKit/UIButton/Configuration-swift.struct/prominentGlass()).
- UIKit now supports Swift Observable objects. Use observable objects in [layoutSubviews()](/documentation/UIKit/UIView/layoutSubviews()); then UIKit automatically invalidates and updates the UI when those objects change.
- Add a badge to a [UIBarButtonItem](/documentation/UIKit/UIBarButtonItem) with [badge](/documentation/UIKit/UIBarButtonItem/badge-4sz3f).
- Notification payloads are now strongly typed: [NotificationCenter.MessageIdentifier](/documentation/Foundation/NotificationCenter/MessageIdentifier).

### Menu bar in iPadOS

- Swipe from the top to reveal an iPad app’s full menu. Menus on iPad support images, submenus, inline sections, checkmarks, and more.
- Configure main menus with [UIMainMenuSystem](/documentation/UIKit/UIMainMenuSystem).

### High dynamic range (HDR)

- [UIColorPickerViewController](/documentation/UIKit/UIColorPickerViewController) supports picking HDR colors, with a maximum supported exposure value.
- Observe [UITraitHDRHeadroomUsageLimit](/documentation/UIKit/UITraitHDRHeadroomUsageLimit-swift.struct) to automatically adjust HDR usage when a view with HDR content is not in focus.

## June 2024

### General

- Leverage automatic trait usage tracking inside key update methods such as [layoutSubviews()](/documentation/UIKit/UIView/layoutSubviews()), eliminating the need for manual trait change registration and invalidation.
- Add repeat, wiggle, breathe, and rotate effects to [SF Symbols](https://developer.apple.com/sf-symbols/).
- Take advantage of enhancements to [UIListContentConfiguration](/documentation/UIKit/UIListContentConfiguration-swift.struct), which now automatically updates to match the style of the containing list by using the new [UIListEnvironment](/documentation/UIKit/UIListEnvironment) trait from the trait collection, removing the need to instantiate a configuration for a specific list style yourself.
- Opt out or restrict collaboration on certain types of data through the share sheet using [UIActivityCollaborationMode](/documentation/UIKit/UIActivityCollaborationMode).
- Select a specific week of the year in [UICalendarView](/documentation/UIKit/UICalendarView) using the new [UICalendarSelectionWeekOfYear](/documentation/UIKit/UICalendarSelectionWeekOfYear) selection option.
- Observe, participate in, and affect the UI update process using [UIUpdateLink](/documentation/UIKit/UIUpdateLink).

### Navigation

- Showcase your app and its unique identity with a new, customizable launch design for document-based apps. In UIKit, define [launchOptions](/documentation/UIKit/UIDocumentViewController/launchOptions-swift.property) on your [UIDocumentViewController](/documentation/UIKit/UIDocumentViewController).
- Make your app’s navigation more immersive by adopting the new tab bar on iPad. If your app presents a rich hierarchy of tab items, set the  [mode](/documentation/UIKit/UITabBarController/mode-swift.property) to [UITabBarController.Mode.tabSidebar](/documentation/UIKit/UITabBarController/Mode-swift.enum/tabSidebar) to automatically switch between the tab bar and sidebar representations. In SwiftUI, use [sidebarAdaptable](/documentation/SwiftUI/TabViewStyle/sidebarAdaptable).
- Transition between views in a way that feels fluid and consistent using a systemwide zoom transition. In UIKit, configure your view controller’s [preferredTransition](/documentation/UIKit/UIViewController/preferredTransition) to [zoom(options:sourceViewProvider:)](/documentation/UIKit/UIViewController/Transition/zoom(options:sourceViewProvider:)). In SwiftUI, use [zoom(sourceID:in:)](/documentation/SwiftUI/NavigationTransition/zoom(sourceID:in:)).

### Framework interoperability

- Reuse existing UIKit gesture recognizer code in SwiftUI. In SwiftUI, create UIKit gesture recognizers using [UIGestureRecognizerRepresentable](/documentation/SwiftUI/UIGestureRecognizerRepresentable). In UIKit, refer to SwiftUI gestures by name using [name](/documentation/UIKit/UIGestureRecognizer/name).

### visionOS

- Support more varieties of list layouts by configuring whether section headers stretch to fill the entire width of the list or shrink to tightly hug their content. For collection views, use [contentHuggingElements](/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct/contentHuggingElements-swift.property) on [UICollectionLayoutListConfiguration](/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct). For table views, use [contentHuggingElements](/documentation/UIKit/UITableView/contentHuggingElements) on [UITableView](/documentation/UIKit/UITableView).
- Animate SF Symbols on visionOS using the symbol effects API and [UIImageView](/documentation/UIKit/UIImageView).
- Apply hierarchical vibrant text color to labels using [UIColor.Prominence](/documentation/UIKit/UIColor/Prominence-swift.enum).
- Specify an action to perform without shifting the focus away from the keyboard using [keyboardAction](/documentation/UIKit/UITextInputAssistantItem/keyboardAction).
- Push a new scene in place of an existing scene using [UIWindowScenePushPlacement](/documentation/UIKit/UIWindowScenePushPlacement-swift.struct). The new scene appears in the same position as the original scene, hiding it. Closing the new scene makes the original scene reappear.

### tvOS

- Create a unifying color theme in your app by specifying an accent color in your app’s asset catalog, which is now supported in tvOS.

## June 2023

### General

- Preview your views and view controllers alongside your code using the new `#Preview` Swift macro.
- Take advantage of a new view controller appearance callback, [viewIsAppearing(_:)](/documentation/UIKit/UIViewController/viewIsAppearing(_:)), to run code that depends on the view’s initial geometry. The system calls this method when both the view and view controller have an up-to-date trait collection, and after the superview adds the view to the hierarchy and lays it out. This method deploys back to iOS 13.
- Learn about enhancements to the trait system, which let you define custom traits for your own data, quickly change trait values throughout the view hierarchy, and register for trait changes in more flexible ways. For more information, see WWDC23 session 10057: [Unleash the UIKit trait system](https://developer.apple.com/videos/play/wwdc2023/10057/).
- Display and manage empty state consistently in your app with [UIContentUnavailableConfiguration](/documentation/UIKit/UIContentUnavailableConfiguration-swift.struct), which provides new system standard styles and layouts for common empty states. Help people understand why no content is present, and when possible, provide guidance on how to add content.
- Create a powerful text experience in your app. Define richer interactions by changing the default tap or menu behavior when interacting with a text item. If you implement a custom UI for displaying text, support the redesigned text cursor by adopting the new text selection UI. Mark up text fields with additional text content types to help people fill out forms even faster. For more information, see WWDC23 session 10058: [What’s new with text and text interactions](https://developer.apple.com/videos/play/wwdc2023/10058/).
- Let people drop supported files and content onto your app icon on the Home Screen to open them in your app. To make sure your app is properly configured, verify that your `Info.plist` file specifies the file types your app supports using [CFBundleDocumentTypes](/documentation/BundleResources/Information-Property-List/CFBundleDocumentTypes).

### Accessibility and internationalization

- Simplify how you maintain your accessibility code with block-based setters for accessibility attributes. Make sure people receive the most important information first by specifying a default, low, or high priority for announcements. Enhance custom accessibility elements with the new toggle and zoom accessibility traits.
- Create a great text experience for international users by testing your UI in all languages. Adopt text styles to take advantage of enhancements to the font system, like improved wrapping and hyphenation for Chinese, German, Japanese, and Korean, as well as enhancements for variable line heights that improve legibility in several languages, including Arabic, Hindi, Thai, and Vietnamese. Access localized variants of symbol images by specifying a locale.

### iPadOS

- Help people customize their Stage Manager configuration by including a larger target area for dragging windows. Leverage new resizing behavior for split view controllers to get the most out of your UI in Stage Manager.
- Support scrolling of your scroll view content with hardware keyboard shortcuts. This behavior is enabled by default, which you can override using [allowsKeyboardScrolling](/documentation/UIKit/UIScrollView/allowsKeyboardScrolling).
- Simplify document management in your document-centric apps. Set your `UIDocument` subclass as the rename delegate of a navigation item to handle file renaming automatically. Build your content view controller from `UIDocumentViewController`, which provides a system default experience for managing documents: automatically configuring the title menu, sharing, drag and drop, key commands, and more. For more information, see WWDC23 session 10056: [Build better document-centric apps](https://developer.apple.com/videos/play/wwdc2023/10056/).
- Enhance the Apple Pencil experience in your iPadOS app. Give your app a sense of depth by using [UIHoverGestureRecognizer](/documentation/UIKit/UIHoverGestureRecognizer) to draw a preview of the stroke. Support the beautiful new inks in PencilKit, including monoline, fountain pen, watercolor, and crayon.

### Views and controls

- Animate symbol images with new symbol effects, including bounce, pulse, variable color, scale, appear, disappear, and replace.
- Build even more performant apps with flexible layouts using collection views. Apply diffable data source snapshots and perform batch updates with even better performance. Use the [uniformAcrossSiblings(estimate:)](/documentation/UIKit/NSCollectionLayoutDimension/uniformAcrossSiblings(estimate:)) dimension for compositional layouts to specify uniform size across sibling items, with smaller items increasing in size to match their largest sibling.
- Simplify spring animations by providing duration and bounce parameters for the new view animation method, [animate(springDuration:bounce:initialSpringVelocity:delay:options:animations:completion:)](/documentation/UIKit/UIView/animate(springDuration:bounce:initialSpringVelocity:delay:options:animations:completion:)).
- Represent fractional progress through a page of content with page controls.
- Display and manipulate high dynamic range (HDR) images.
- Display your menu as a palette with [displayAsPalette](/documentation/UIKit/UIMenu/Options-swift.struct/displayAsPalette) for it to appear as a row of menu elements for choosing from a collection of items.
- Take advantage of the [UIStatusBarStyle.default](/documentation/UIKit/UIStatusBarStyle/default) status bar style, which now automatically chooses a light or dark appearance that maintains contrast with the content underneath it.

## Technology and frameworks

- [Accelerate updates](/documentation/updates/accelerate) Learn about important changes to Accelerate.
- [Accessibility updates](/documentation/updates/accessibility) Learn about important changes to Accessibility.
- [ActivityKit updates](/documentation/updates/activitykit) Learn about important changes in ActivityKit.
- [AdAttributionKit Updates](/documentation/updates/adattributionkit) Learn about important changes to AdAttributionKit.
- [App Clips updates](/documentation/updates/appclips) Learn about important changes in App Clips.
- [App Intents updates](/documentation/updates/appintents) Learn about important changes in App Intents.
- [AppKit updates](/documentation/updates/appkit) Learn about important changes to AppKit.
- [Apple Intelligence updates](/documentation/updates/apple-intelligence) Learn about important changes to Apple Intelligence.
- [AppleMapsServerAPI Updates](/documentation/updates/applemapsserverapi) Learn about important changes to AppleMapsServerAPI.
- [Apple Pencil updates](/documentation/updates/applepencil) Learn about important changes to Apple Pencil.
- [ARKit updates](/documentation/updates/arkit) Learn about important changes to ARKit.
- [Audio Toolbox updates](/documentation/updates/audiotoolbox) Learn about important changes to Audio Toolbox.
- [AuthenticationServices updates](/documentation/updates/authenticationservices) Learn about important changes to AuthenticationServices.
- [AVFAudio updates](/documentation/updates/avfaudio) Learn about important changes to AVFAudio.
- [AVFoundation updates](/documentation/updates/avfoundation) Learn about important changes to AVFoundation.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
