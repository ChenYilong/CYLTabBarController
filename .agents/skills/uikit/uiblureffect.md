---
title: UIBlurEffect
description: An object that applies a blurring effect to the content layered behind a visual effect view.
source: https://developer.apple.com/documentation/uikit/uiblureffect
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiblureffect.json
timestamp: 2026-04-14T13:14:49.093Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIBlurEffect

**Available on:** iOS 8.0+, iPadOS 8.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> An object that applies a blurring effect to the content layered behind a visual effect view.

```swift
@MainActor class UIBlurEffect
```

## Overview

Views that you add to the [contentView](/documentation/uikit/uivisualeffectview/contentview) of a visual effect view aren’t affected by the blur effect.

## Inherits From

- [UIVisualEffect](/documentation/uikit/uivisualeffect)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSCopying](/documentation/Foundation/NSCopying)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Creating a blur effect

- [init(style:)](/documentation/uikit/uiblureffect/init(style:)) Creates a blur effect with the designated style.

## Constants

- [UIBlurEffect.Style](/documentation/uikit/uiblureffect/style) Blur styles available for blur effect objects.

## Visual effects

- [UIVisualEffect](/documentation/uikit/uivisualeffect) An initializer for visual effect views and blur and vibrancy effect objects.
- [UIVisualEffectView](/documentation/uikit/uivisualeffectview) An object that implements some complex visual effects.
- [UIVibrancyEffect](/documentation/uikit/uivibrancyeffect) An object that amplifies and adjusts the color of the content layered behind a visual effect view.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
