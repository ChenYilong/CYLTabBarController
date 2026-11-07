---
title: UIVisualEffectView
description: An object that implements some complex visual effects.
source: https://developer.apple.com/documentation/uikit/uivisualeffectview
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uivisualeffectview.json
timestamp: 2026-06-26T06:39:37.120Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIVisualEffectView

**Available on:** iOS 8.0+, iPadOS 8.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> An object that implements some complex visual effects.

```swift
@MainActor class UIVisualEffectView
```

## Overview

Depending on the desired effect, the effect may affect content layered behind the view or content added to the visual effect view’s [contentView](/documentation/uikit/uivisualeffectview/contentview). Apply a visual effect view to an existing view and then apply a [UIBlurEffect](/documentation/uikit/uiblureffect) or [UIVibrancyEffect](/documentation/uikit/uivibrancyeffect) object to apply a blur or vibrancy effect to the existing view. After you add the visual effect view to the view hierarchy, add any subviews to the [contentView](/documentation/uikit/uivisualeffectview/contentview) property of the visual effect view. Don’t add subviews directly to the visual effect view itself.

### Set the correct alpha value

When using the [UIVisualEffectView](/documentation/uikit/uivisualeffectview) class, avoid alpha values that are less than 1. Creating views that are partially transparent causes the system to combine the view and all the associated subviews during an offscreen render pass. [UIVisualEffectView](/documentation/uikit/uivisualeffectview) objects need to be combined as part of the content they’re layered on top of in order to look correct. Setting the alpha to less than 1 on the visual effect view or any of its superviews causes many effects to look incorrect or not show up at all.

### Use masks with a visual effect view

Masks directly applied to a [UIVisualEffectView](/documentation/uikit/uivisualeffectview) are forwarded to the internal views that provide the visual effect, including the [contentView](/documentation/uikit/uivisualeffectview/contentview) itself. You can also apply masks directly to the [contentView](/documentation/uikit/uivisualeffectview/contentview). Applying a mask to a superview of a [UIVisualEffectView](/documentation/uikit/uivisualeffectview) object causes the effect to fail, and an exception is thrown.

Any mask provided to [UIVisualEffectView](/documentation/uikit/uivisualeffectview) isn’t the view that actually performs the mask. UIKit makes a copy of the view and applies it to each subview. To reflect a size change to the mask, you must apply the change to the original mask and reset it on the effect view.

### Capture a snapshot of a visual effect view

Many effects require support from the window that hosts the [UIVisualEffectView](/documentation/uikit/uivisualeffectview). Attempting to take a snapshot of only the [UIVisualEffectView](/documentation/uikit/uivisualeffectview) results in a snapshot that doesn’t contain the effect. To take a snapshot of a view hierarchy that contains a [UIVisualEffectView](/documentation/uikit/uivisualeffectview), you must take a snapshot of the entire [UIWindow](/documentation/uikit/uiwindow) or [UIScreen](/documentation/uikit/uiscreen) that contains it.

## Inherits From

- [UIView](/documentation/uikit/uiview)

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
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
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
- [UILargeContentViewerItem](/documentation/uikit/uilargecontentvieweritem)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIPopoverPresentationControllerSourceItem](/documentation/uikit/uipopoverpresentationcontrollersourceitem)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating a visual effect view

- [init(effect:)](/documentation/uikit/uivisualeffectview/init(effect:)) Creates a new visual effect view with the designated visual effect.
- [init(coder:)](/documentation/uikit/uivisualeffectview/init(coder:)) Creates a visual effect view from data in an unarchiver.

## Retrieving view information

- [contentView](/documentation/uikit/uivisualeffectview/contentview) A view object that can have a visual effect view added to it.
- [effect](/documentation/uikit/uivisualeffectview/effect) The visual effect provided by the view.

## Visual effects

- [UIVisualEffect](/documentation/uikit/uivisualeffect) An initializer for visual effect views and blur and vibrancy effect objects.
- [UIVibrancyEffect](/documentation/uikit/uivibrancyeffect) An object that amplifies and adjusts the color of the content layered behind a visual effect view.
- [UIBlurEffect](/documentation/uikit/uiblureffect) An object that applies a blurring effect to the content layered behind a visual effect view.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
