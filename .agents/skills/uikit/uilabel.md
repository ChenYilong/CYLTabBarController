---
title: UILabel
description: A view that displays one or more lines of informational text.
source: https://developer.apple.com/documentation/uikit/uilabel
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uilabel.json
timestamp: 2026-06-26T06:39:37.060Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UILabel

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A view that displays one or more lines of informational text.

```swift
@MainActor class UILabel
```

## Overview

You can configure the overall appearance of a label’s text, and use attributed strings to customize the appearance of substrings within the text. Add and customize labels in your interface programmatically, or with the Attributes inspector in Interface Builder.

Follow these steps to add a label to your interface:

- Supply either a string or an attributed string that represents the content.
- If you’re using a nonattributed string, configure the appearance of the label.
- Set up Auto Layout rules to govern the size and position of the label in your interface.
- Provide accessibility information and localized strings.

### Customize the label’s appearance

You provide the content for a label by assigning either a [NSString](/documentation/Foundation/NSString) object to the [text](/documentation/uikit/uilabel/text) property, or an [NSAttributedString](/documentation/Foundation/NSAttributedString) object to the [attributedText](/documentation/uikit/uilabel/attributedtext) property. The label displays the property set most recently.

The [attributedText](/documentation/uikit/uilabel/attributedtext) property allows you to control the appearance of individual characters and groups of characters, using the [NSAttributedString](/documentation/Foundation/NSAttributedString) API. The following image shows a label displaying an [NSAttributedString](/documentation/Foundation/NSAttributedString) that includes attributes to customize the font, color, and alignment of the string.

![A screenshot of a label showing text aligned to the left and formatted with different attributes. The first attribute changes the text color of the second word to a color different from the rest of the text. The second attribute applies a bold font to the fifth word. The third and final attribute highlights the last four words that the label displays. The display text ends with an ellipsis indicating that the label truncates the full text at the end due to its line break mode.](https://docs-assets.developer.apple.com/published/40ee9fac5632a81fcc433d85594290bd/media-2759882%402x.png)

If you want to format the label’s text in a uniform fashion, set the [text](/documentation/uikit/uilabel/text) property to an [NSString](/documentation/Foundation/NSString) object containing the content, and configure the [font](/documentation/uikit/uilabel/font), [textColor](/documentation/uikit/uilabel/textcolor), [textAlignment](/documentation/uikit/uilabel/textalignment), and [lineBreakMode](/documentation/uikit/uilabel/linebreakmode) properties. The following image shows a label displaying an [NSString](/documentation/Foundation/NSString) with a custom font, color, and alignment.

![A screenshot of a label displaying text with a center alignment and truncated in the middle, showing the beginning and ending of the full text, separated with an ellipsis.](https://docs-assets.developer.apple.com/published/056a9ff6d397d84c263077990f1cb109/media-2759883%402x.png)

If you set these appearance properties on a label that displays the content of the [attributedText](/documentation/uikit/uilabel/attributedtext) property, the label overrides the appropriate attributes and displays the attributed string with a uniform appearance. The following image shows the label from the first image with the [textColor](/documentation/uikit/uilabel/textcolor) property set to green.

![A screenshot of a label showing left aligned text. The color of the text is green.](https://docs-assets.developer.apple.com/published/8e72b904f736047642dea7ce807b13b9/media-2759884%402x.png)

Specify the maximum number of lines for the label to use when laying out the text with the [numberOfLines](/documentation/uikit/uilabel/numberoflines) property. Setting a value of `0` allows the label to use as many lines as necessary to lay out the text within the label’s width. Use the [lineBreakMode](/documentation/uikit/uilabel/linebreakmode) property to control how the label splits the text into multiple lines, and the truncation behavior associated with the final line.

Use Auto Layout to position and optionally size the label. The intrinsic content size for a label defaults to the size that displays the entirety of the content on a single line. If you provide Auto Layout constraints that define the width of the label but not the height, the label’s intrinsic content size adjusts the height to display the text completely.

When the label has its size completely defined externally, you can specify how it handles the situation when its content doesn’t fit within the bounds. To reduce the font size, set the [adjustsFontSizeToFitWidth](/documentation/uikit/uilabel/adjustsfontsizetofitwidth) property to [true](/documentation/Swift/true) and set the [minimumScaleFactor](/documentation/uikit/uilabel/minimumscalefactor) property to a value between `0` and `1`. The latter of these properties represents how much smaller than the requested font size the label scales the text. Setting the [allowsDefaultTighteningForTruncation](/documentation/uikit/uilabel/allowsdefaulttighteningfortruncation) property to [true](/documentation/Swift/true) instructs the label to reduce the spacing between characters before truncating the string. The following image shows a label that uses [minimumScaleFactor](/documentation/uikit/uilabel/minimumscalefactor) and [adjustsFontSizeToFitWidth](/documentation/uikit/uilabel/adjustsfontsizetofitwidth) to display the content of an entire string that would otherwise have overflowed.

![A screenshot showing two labels containing the same text, displayed side by side. The label on the left side truncates the text at the end. The label on the right side displays the full text in an adjusted, smaller font that fits within the display area of the label.](https://docs-assets.developer.apple.com/published/ef03caba2711ad3ab5f90f6569c85cce/media-2759885%402x.png)

### Design labels for a wide audience

Labels provide valuable information to your users. To make sure that information reaches a wide audience, internationalize text and support accessibility in your labels. For information about how to implement internationalization and localization, see [Internationalization](https://developer.apple.com/internationalization/). Labels are accessible to VoiceOver by default. The default accessibility traits for a label are Static Text and User Interaction Enabled. For more information, see [Supporting VoiceOver in your app](/documentation/uikit/supporting-voiceover-in-your-app). To learn about using text styles to support Dynamic Type, see [Scaling fonts automatically](/documentation/uikit/scaling-fonts-automatically).

For design guidance, see [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/components/layout-and-organization/labels/).

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
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIAccessibilityIdentification](/documentation/uikit/uiaccessibilityidentification)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIAppearance](/documentation/uikit/uiappearance)
- [UIAppearanceContainer](/documentation/uikit/uiappearancecontainer)
- [UIContentSizeCategoryAdjusting](/documentation/uikit/uicontentsizecategoryadjusting)
- [UICoordinateSpace](/documentation/uikit/uicoordinatespace)
- [UIDynamicItem](/documentation/uikit/uidynamicitem)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIFocusItem](/documentation/uikit/uifocusitem)
- [UIFocusItemContainer](/documentation/uikit/uifocusitemcontainer)
- [UILargeContentViewerItem](/documentation/uikit/uilargecontentvieweritem)
- [UILetterformAwareAdjusting](/documentation/uikit/uiletterformawareadjusting)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIPopoverPresentationControllerSourceItem](/documentation/uikit/uipopoverpresentationcontrollersourceitem)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Accessing the text attributes

- [text](/documentation/uikit/uilabel/text) The text that the label displays.
- [attributedText](/documentation/uikit/uilabel/attributedtext) The styled text that the label displays.
- [font](/documentation/uikit/uilabel/font) The font of the text.
- [textColor](/documentation/uikit/uilabel/textcolor) The color of the text.
- [textAlignment](/documentation/uikit/uilabel/textalignment) The technique for aligning the text.
- [lineBreakMode](/documentation/uikit/uilabel/linebreakmode) The technique for wrapping and truncating the label’s text.
- [lineBreakStrategy](/documentation/uikit/uilabel/linebreakstrategy) The strategy that the system uses to break lines when laying out multiple lines of text.
- [isEnabled](/documentation/uikit/uilabel/isenabled) A Boolean value that determines whether the label draws its text in an enabled state.
- [enablesMarqueeWhenAncestorFocused](/documentation/uikit/uilabel/enablesmarqueewhenancestorfocused) A Boolean value that determines whether the label scrolls its text while one of its containing views has focus.
- [showsExpansionTextWhenTruncated](/documentation/uikit/uilabel/showsexpansiontextwhentruncated) A Boolean value that determines whether the full text of the label displays when the pointer hovers over the truncated text.

## Sizing the label’s text

- [adjustsFontSizeToFitWidth](/documentation/uikit/uilabel/adjustsfontsizetofitwidth) A Boolean value that determines whether the label reduces the text’s font size to fit the title string into the label’s bounding rectangle.
- [allowsDefaultTighteningForTruncation](/documentation/uikit/uilabel/allowsdefaulttighteningfortruncation) A Boolean value that determines whether the label tightens text before truncating.
- [baselineAdjustment](/documentation/uikit/uilabel/baselineadjustment) An option that controls whether the text’s baseline remains fixed when text needs to shrink to fit in the label.
- [minimumScaleFactor](/documentation/uikit/uilabel/minimumscalefactor) The minimum scale factor for the label’s text.
- [numberOfLines](/documentation/uikit/uilabel/numberoflines) The maximum number of lines for rendering text.
- [sizingRule](/documentation/uikit/uiletterformawareadjusting/sizingrule) The typographic bounds-sizing behavior that handles text with fonts that contain oversize characters.

## Managing highlight values

- [highlightedTextColor](/documentation/uikit/uilabel/highlightedtextcolor) The highlight color for the label’s text.
- [isHighlighted](/documentation/uikit/uilabel/ishighlighted) A Boolean value that determines whether the label draws its text with a highlight.

## Managing vibrancy

- [preferredVibrancy](/documentation/uikit/uilabel/preferredvibrancy)
- [UILabelVibrancy](/documentation/uikit/uilabelvibrancy)

## Drawing a shadow

- [shadowColor](/documentation/uikit/uilabel/shadowcolor) The shadow color of the text.
- [shadowOffset](/documentation/uikit/uilabel/shadowoffset) The shadow offset, in points, for the text.

## Drawing and positioning overrides

- [textRect(forBounds:limitedToNumberOfLines:)](/documentation/uikit/uilabel/textrect(forbounds:limitedtonumberoflines:)) Returns the drawing rectangle for the label’s text.
- [drawText(in:)](/documentation/uikit/uilabel/drawtext(in:)) Draws the label’s text, or its shadow, in the specified rectangle.

## Getting the layout constraints

- [preferredMaxLayoutWidth](/documentation/uikit/uilabel/preferredmaxlayoutwidth) The preferred maximum width, in points, for a multiline label.

## Accessing additional attributes

- [isUserInteractionEnabled](/documentation/uikit/uilabel/isuserinteractionenabled) A Boolean value that determines whether the system ignores and removes user events for this label from the event queue.
- [clipsToBounds](/documentation/uikit/uilabel-clipstobounds) A Boolean value that determines whether subviews are confined to the bounds of the view.

## Supporting types

- [NSTextAlignment](/documentation/uikit/nstextalignment) Constants that specify text alignment.

## Text views

- [UITextField](/documentation/uikit/uitextfield) An object that displays an editable text area in your interface.
- [UITextView](/documentation/uikit/uitextview) A scrollable, multiline text region.
- [Drag and drop customization](/documentation/uikit/drag-and-drop-customization) Extend the standard drag and drop support for text views to include custom types of content.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
