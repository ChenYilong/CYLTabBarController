---
title: UIFont
description: An object that provides access to the font’s characteristics.
source: https://developer.apple.com/documentation/uikit/uifont
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uifont.json
timestamp: 2026-05-10T06:22:50.553Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIFont

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+, watchOS 2.0+

> An object that provides access to the font’s characteristics.

```swift
class UIFont
```

## Overview

Use `UIFont` to access your font’s characteristics within your app. It also provides the system with access to the glyph information, used during layout. Font objects are immutable, so it’s safe to use them from multiple threads in your app.

In Objective-C, don’t create font objects using the `alloc` and `init` methods. Instead, use class methods of [UIFont](/documentation/uikit/uifont), such as [preferredFont(forTextStyle:)](/documentation/uikit/uifont/preferredfont(fortextstyle:)), to look up and retrieve the desired font object. These methods check for an existing font object with the specified characteristics and return it if it exists. Otherwise, they create a new font object based on the desired font characteristics.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

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

## Creating Fonts

- [Scaling fonts automatically](/documentation/uikit/scaling-fonts-automatically) Scale text in your interface automatically using Dynamic Type.
- [Creating self-sizing table view cells](/documentation/uikit/creating-self-sizing-table-view-cells) Create table view cells that support Dynamic Type and use system spacing constraints to adjust the spacing surrounding text labels.
- [preferredFont(forTextStyle:)](/documentation/uikit/uifont/preferredfont(fortextstyle:)) Returns an instance of the system font for the specified text style with scaling for the user’s selected content size category.
- [preferredFont(forTextStyle:compatibleWith:)](/documentation/uikit/uifont/preferredfont(fortextstyle:compatiblewith:)) Returns an instance of the system font for the appropriate text style and traits.
- [UIFont.TextStyle](/documentation/uikit/uifont/textstyle) Constants that describe the preferred styles for fonts.
- [init(name:size:)](/documentation/uikit/uifont/init(name:size:)) Creates and returns a font object for the specified font name and size.
- [init(descriptor:size:)](/documentation/uikit/uifont/init(descriptor:size:)) Returns a font that matches the specified font descriptor.
- [withSize(_:)](/documentation/uikit/uifont/withsize(_:)) Returns a font object that is the same as the font, but has the specified size.

## Creating System Fonts

- [systemFont(ofSize:)](/documentation/uikit/uifont/systemfont(ofsize:)) Returns the font object for standard interface items in the specified size.
- [systemFont(ofSize:weight:)](/documentation/uikit/uifont/systemfont(ofsize:weight:)) Returns the font object for standard interface items in the specified size and weight.
- [UIFont.Weight](/documentation/uikit/uifont/weight) Constants that represent standard typeface styles.
- [systemFont(ofSize:weight:width:)](/documentation/uikit/uifont/systemfont(ofsize:weight:width:))
- [UIFont.Width](/documentation/uikit/uifont/width)
- [boldSystemFont(ofSize:)](/documentation/uikit/uifont/boldsystemfont(ofsize:)) Returns the font object for standard interface items in boldface type in the specified size.
- [italicSystemFont(ofSize:)](/documentation/uikit/uifont/italicsystemfont(ofsize:)) Returns the font object for standard interface items in italic type in the specified size.
- [monospacedSystemFont(ofSize:weight:)](/documentation/uikit/uifont/monospacedsystemfont(ofsize:weight:)) Returns the fixed-width font for standard interface text in the specified size.
- [monospacedDigitSystemFont(ofSize:weight:)](/documentation/uikit/uifont/monospaceddigitsystemfont(ofsize:weight:)) Returns the standard system font with all digits of consistent width.

## Getting the Available Font Names

- [familyNames](/documentation/uikit/uifont/familynames) Returns an array of font family names available on the system.
- [fontNames(forFamilyName:)](/documentation/uikit/uifont/fontnames(forfamilyname:)) Returns an array of font names available in a particular font family.

## Getting Font Name Attributes

- [familyName](/documentation/uikit/uifont/familyname) The font family name.
- [fontName](/documentation/uikit/uifont/fontname) The font face name.

## Getting Font Metrics

- [pointSize](/documentation/uikit/uifont/pointsize) The font’s point size, or the effective vertical point size for a font with a nonstandard matrix.
- [ascender](/documentation/uikit/uifont/ascender) The top y-coordinate, offset from the baseline, of the font’s longest ascender.
- [descender](/documentation/uikit/uifont/descender) The bottom y-coordinate, offset from the baseline, of the font’s longest descender.
- [leading](/documentation/uikit/uifont/leading) The font’s leading information.
- [capHeight](/documentation/uikit/uifont/capheight) The font’s cap height information.
- [xHeight](/documentation/uikit/uifont/xheight) The x-height of the font.
- [lineHeight](/documentation/uikit/uifont/lineheight) The height, in points, of text lines.

## Getting System Font Information

- [labelFontSize](/documentation/uikit/uifont/labelfontsize) The standard font size, in points, for labels.
- [buttonFontSize](/documentation/uikit/uifont/buttonfontsize) The standard font size, in points, for buttons.
- [smallSystemFontSize](/documentation/uikit/uifont/smallsystemfontsize) The size, in points, of the standard small system font.
- [systemFontSize](/documentation/uikit/uifont/systemfontsize) The size, in points, of the standard system font.

## Getting Font Descriptors

- [fontDescriptor](/documentation/uikit/uifont/fontdescriptor) A font descriptor for the font.
- [UIFontDescriptor](/documentation/uikit/uifontdescriptor) A collection of attributes that describes a font.

## Initializers

- [init(coder:)](/documentation/uikit/uifont/init(coder:))

## Fonts

- [Scaling fonts automatically](/documentation/uikit/scaling-fonts-automatically) Scale text in your interface automatically using Dynamic Type.
- [Adding a custom font to your app](/documentation/uikit/adding-a-custom-font-to-your-app) Add a custom font to your app and use it in your app’s interface.
- [UIFontDescriptor](/documentation/uikit/uifontdescriptor) A collection of attributes that describes a font.
- [UIFontDescriptor.SymbolicTraits](/documentation/uikit/uifontdescriptor/symbolictraits-swift.struct) Constants that describe the stylistic aspects of a font.
- [UIFontMetrics](/documentation/uikit/uifontmetrics) A utility object for obtaining custom fonts that scale to support Dynamic Type.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
