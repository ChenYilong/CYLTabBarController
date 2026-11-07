---
title: UIColor
description: An object that stores color data and sometimes opacity.
source: https://developer.apple.com/documentation/uikit/uicolor
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uicolor.json
timestamp: 2026-05-10T06:22:50.512Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIColor

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+, watchOS 2.0+

> An object that stores color data and sometimes opacity.

```swift
class UIColor
```

## Overview

Use color to customize your app’s appearance, communicate status, and help people visualize data. To learn more about using color in your apps, see [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/foundations/color/).

[UIColor](/documentation/uikit/uicolor) provides a list of class properties that create adaptable and fixed colors such as blue, green, purple, and more. [UIColor](/documentation/uikit/uicolor) also offers properties to specify system-provided colors for UI elements such as labels, text, and buttons. You can create color objects by specifying color component values such as RGB, hue, and saturation. You can also create colors from other color objects and even create a pattern-based color from an image.

> **Important:** Most developers have no need to subclass [UIColor](/documentation/uikit/uicolor). The only time subclassing might be necessary is if you require support for additional color spaces or color models. If you do subclass, the properties and methods you add must be safe to use from multiple threads.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSCopying](/documentation/Foundation/NSCopying)
- [NSItemProviderReading](/documentation/Foundation/NSItemProviderReading)
- [NSItemProviderWriting](/documentation/Foundation/NSItemProviderWriting)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Getting existing colors

- [UI element colors](/documentation/uikit/ui-element-colors) Choose colors for UI elements such as labels, text, backgrounds, and links.
- [Standard colors](/documentation/uikit/standard-colors) Define standard color objects for specific shades, such as red, blue, green, black, white, and more.
- [Color creation](/documentation/uikit/color-creation) Load colors from asset catalogs and create colors from raw component values.

## Applying the color to the drawing environment

- [Customizing drawings](/documentation/uikit/customizing-drawings) Create custom colors and patterns for drawing in your app.
- [set()](/documentation/uikit/uicolor/set()) Sets the color of subsequent stroke and fill operations to the color that the receiver represents.
- [setFill()](/documentation/uikit/uicolor/setfill()) Sets the color of subsequent fill operations to the color that the receiver represents.
- [setStroke()](/documentation/uikit/uicolor/setstroke()) Sets the color of subsequent stroke operations to the color that the receiver represents.

## Getting the color information

- [Determining color values with color spaces](/documentation/uikit/determining-color-values-with-color-spaces) Change the system’s interpretation of a color value for display by selecting a color space.
- [cgColor](/documentation/uikit/uicolor/cgcolor) The Quartz color that corresponds to the color object.
- [ciColor](/documentation/uikit/uicolor/cicolor) The Core Image color that corresponds to the color object.
- [getHue(_:saturation:brightness:alpha:)](/documentation/uikit/uicolor/gethue(_:saturation:brightness:alpha:)) Returns the components that form the color in the HSB color space.
- [getRed(_:green:blue:alpha:)](/documentation/uikit/uicolor/getred(_:green:blue:alpha:)) Returns the components that form the color in the RGB color space.
- [getWhite(_:alpha:)](/documentation/uikit/uicolor/getwhite(_:alpha:)) Returns the grayscale components of the color.
- [linearExposure](/documentation/uikit/uicolor/linearexposure) The linear brightness multiplier that was applied when generating this color. Colors created with an exposure by UIColor create CGColors that are tagged with a contentHeadroom value. While CGColors created without a contentHeadroom tag will return 0 from CGColorGetHeadroom, UIColors generated in a similar fashion return a linearExposure of 1.0.
- [accessibilityName](/documentation/uikit/uicolor/accessibilityname) A localized description of the color for accessibility attributes.

## Resolving a dynamically generated color

- [resolvedColor(with:)](/documentation/uikit/uicolor/resolvedcolor(with:)) Returns the version of the current color that results from the specified traits.

## Working with color prominence

- [prominence](/documentation/uikit/uicolor/prominence-swift.property)
- [withProminence(_:)](/documentation/uikit/uicolor/withprominence(_:)) Returns the version of the current color that results from applying the specified prominence.
- [UIColor.Prominence](/documentation/uikit/uicolor/prominence-swift.enum) A type that indicates the prominence of a color in the interface.

## Working with high dynamic range (HDR) colors

- [applyingContentHeadroom(_:)](/documentation/uikit/uicolor/applyingcontentheadroom(_:)) Reinterpret the color by applying a new `contentHeadroom` without changing the color components. Changing the `contentHeadroom` redefines the color relative to a different peak white, changing its behavior under tone mapping and the result of calling `standardDynamicRangeColor`. The new color will have a `contentHeadroom` >= 1.0.
- [standardDynamicRange](/documentation/uikit/uicolor/standarddynamicrange) In some cases it is useful to recover the color that was base SDR color that was exposed to generate the given HDR color. If a color’s `linearExposure` is >1, then this will return the base SDR color.

## Initializers

- [init(CGColor:)](/documentation/uikit/uicolor/init(cgcolor:)-58l83)
- [init(CGColor:)](/documentation/uikit/uicolor/init(cgcolor:)-9d9vs)
- [init(CIColor:)](/documentation/uikit/uicolor/init(cicolor:)-2b5ik)
- [init(CIColor:)](/documentation/uikit/uicolor/init(cicolor:)-5fqhu)
- [init(coder:)](/documentation/uikit/uicolor/init(coder:))
- [init(named:in:compatibleWith:)](/documentation/uikit/uicolor/init(named:in:compatiblewith:))

## Default Implementations

- [UIColor Implementations](/documentation/uikit/uicolor/uicolor-implementations)

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
