---
title: UIImageView
description: A view that displays a single image or a sequence of animated images in your interface.
source: https://developer.apple.com/documentation/uikit/uiimageview
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiimageview.json
timestamp: 2026-06-26T06:39:36.976Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIImageView

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A view that displays a single image or a sequence of animated images in your interface.

```swift
@MainActor class UIImageView
```

## Overview

Image views let you efficiently draw any image that can be specified using a [UIImage](/documentation/uikit/uiimage) object. For example, you can use the [UIImageView](/documentation/uikit/uiimageview) class to display the contents of many standard image files, such as JPEG and PNG files. You can configure image views programmatically or in your storyboard file and change the images they display at runtime. For animated images, you can also use the methods of this class to start and stop the animation and specify other animation parameters.

![An image view](https://docs-assets.developer.apple.com/published/707440cc50954c46cf2c38fbab7cd76b/media-2923882%402x.png)

### Understand how images are scaled

An image view uses its [contentMode](/documentation/uikit/uiview/contentmode-swift.property) property and the configuration of the image itself to determine how to display the image. It’s best to specify images whose dimensions match the dimensions of the image view exactly, but image views can scale your images to fit all or some of the available space. If the size of the image view itself changes, it automatically scales the image as needed.

For an image without cap insets, the presentation of the image is determined solely by the image view’s [contentMode](/documentation/uikit/uiview/contentmode-swift.property) property. The [UIView.ContentMode.scaleAspectFit](/documentation/uikit/uiview/contentmode-swift.enum/scaleaspectfit) and [UIView.ContentMode.scaleAspectFill](/documentation/uikit/uiview/contentmode-swift.enum/scaleaspectfill) modes scale the image to fit or fill the space while maintaining the image’s original aspect ratio. The [UIView.ContentMode.scaleToFill](/documentation/uikit/uiview/contentmode-swift.enum/scaletofill) value scales the image without regard to the original aspect ratio, which can cause the image to appear distorted. Other content modes place the image at the appropriate location in the image view’s bounds without scaling it.

For a resizable image with cap insets, those insets affect the final appearance of the image. Specifically, cap insets define which parts of the image may be scaled and in which directions. You can create a resizable image that stretches using the [resizableImage(withCapInsets:resizingMode:)](/documentation/uikit/uiimage/resizableimage(withcapinsets:resizingmode:)) method of [UIImage](/documentation/uikit/uiimage). When using an image of this type, you typically set the image view’s content mode to [UIView.ContentMode.scaleToFill](/documentation/uikit/uiview/contentmode-swift.enum/scaletofill) so that the image stretches in the appropriate places and fills the image view’s bounds.

For tips on how to prepare images, see [Debug issues with your image view](/documentation/uikit/uiimageview#Debug-issues-with-your-image-view). For more information on creating resizable images with cap insets, see [UIImage](/documentation/uikit/uiimage).

### Determine the final transparency of the image

Images are composited onto the image view’s background and are then composited into the rest of the window. Any transparency in the image allows the image view’s background to show through. Similarly, any further transparency in the background of the image is dependent on the transparency of the image view and the transparency of the [UIImage](/documentation/uikit/uiimage) object it displays. When the image view and its image both have transparency, the image view uses alpha blending to combine the two.

- The image is composited onto the image view’s background.
- If the image view’s [isOpaque](/documentation/uikit/uiview/isopaque) property is [true](/documentation/Swift/true), the image’s pixels are composited on top of the image view’s background color and the [alpha](/documentation/uikit/uiview/alpha) property of the image view is ignored.
- If the image view’s [isOpaque](/documentation/uikit/uiview/isopaque) property is [false](/documentation/Swift/false), the alpha value of each pixel is multiplied by the image view’s [alpha](/documentation/uikit/uiview/alpha) value, with the resulting value becoming the actual transparency value for that pixel. If the image doesn’t have an alpha channel, the alpha value of each pixel is assumed to be `1.0`.

> **Important:** It’s computationally expensive to composite the alpha channel of an image with the alpha channel of a non-opaque image view. The performance impact is further magnified if you use Core Animation shadows, because the shape of the shadow is then based on the contents of the view and must be dynamically computed. If you aren’t intentionally using the alpha channel of the image or the alpha channel of the image view, set the [isOpaque](/documentation/uikit/uiview/isopaque) property to [true](/documentation/Swift/true) to improve performance. For additional optimization tips, see [Improve performance](/documentation/uikit/uiimageview#Improve-performance).

### Animate a sequence of images

An image view can store an animated image sequence and play all or part of that sequence. You specify an image sequence as an array of [UIImage](/documentation/uikit/uiimage) objects and assign them to the [animationImages](/documentation/uikit/uiimageview/animationimages) property. Once assigned, you can use the methods and properties of this class to configure the animation timing and to start and stop the animation.

> **Note:** You can also construct a single [UIImage](/documentation/uikit/uiimage) object from a sequence of individual images using the [animatedImage(with:duration:)](/documentation/uikit/uiimage/animatedimage(with:duration:)) method. Doing so yields the same results as assigning the individual images to the [animationImages](/documentation/uikit/uiimageview/animationimages) property.

Consider the following tips when displaying a sequence of animated images:

- **All images in the sequence should have the same size.** When scaling is required, the image view scales each image in the sequence separately. If the images are different sizes, scaling may not yield the results you want.
- **All images in the sequence should use the same content scale factor.** Make sure the [scale](/documentation/uikit/uiimage/scale) property of each image contains the same value.

### Respond to touch events

Image views ignore user events by default. Normally, you use image views only to present visual content in your interface. If you want an image view to handle user interactions as well, change the value of its [isUserInteractionEnabled](/documentation/uikit/uiimageview/isuserinteractionenabled) property to [true](/documentation/Swift/true). After doing that, you can attach gesture recognizers or use any other event handling techniques to respond to touch events or other user-initiated events.

For more information about handling events, see [Event Handling Guide for UIKit Apps](https://developer.apple.com/library/archive/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/index.html#//apple_ref/doc/uid/TP40009541).

### Improve performance

Image scaling and alpha blending are two relatively expensive operations that can impact your app’s performance. To maximize performance of your image view code, consider the following tips:

- **Cache scaled versions of frequently used images.** If you expect certain large images to be displayed frequently in a scaled-down thumbnail view, consider creating the scaled-down images in advance and storing them in a thumbnail cache. Doing so alleviates the need for each image view to scale them separately.
- **Use images whose size is close to the size of the image view.** Rather than assigning a large image to an image view, created a scaled version that matches the current size of the image view. You can also create a resizable image object using the [UIImage.ResizingMode.tile](/documentation/uikit/uiimage/resizingmode-swift.enum/tile) option, which tiles the image instead of scaling it.
- **Make your image view opaque whenever possible.** Unless you’re intentionally working with images that contain transparency (drawing UI elements, for example), make sure the [isOpaque](/documentation/uikit/uiview/isopaque) property of your image view is set to [true](/documentation/Swift/true). For more information about how transparency is determined, see [Determine the final transparency of the image](/documentation/uikit/uiimageview#Determine-the-final-transparency-of-the-image).

### Debug issues with your image view

If your image view isn’t displaying what you expected, use the following tips to help diagnose the problem:

- **Load images using the correct method.** Use the [init(named:in:compatibleWith:)](/documentation/uikit/uiimage/init(named:in:compatiblewith:)) method of [UIImage](/documentation/uikit/uiimage) to load images from asset catalogs or your app’s bundle. For images outside of your app’s bundle, use the [imageWithContentsOfFile:](/documentation/uikit/uiimage/imagewithcontentsoffile:) method.
- **Don’t use image views for custom drawing.** The [UIImageView](/documentation/uikit/uiimageview) class doesn’t draw its content using the [draw(_:)](/documentation/uikit/uiview/draw(_:)) method. Use image views only to present images. To do custom drawing involving images, subclass [UIView](/documentation/uikit/uiview) directly and draw your image there.

### Interface Builder attributes

The following table lists the attributes that you configure for image views in Interface Builder.

| Attribute | Discussion |
| --- | --- |
| Image | The image to display. You can specify any image in your Xcode project, including standalone images and those in image assets. To set this attribute programmatically, use the [image](/documentation/uikit/uiimageview/image) or [animationImages](/documentation/uikit/uiimageview/animationimages) property. |
| Highlighted | The image to display when the image view is highlighted. To set this attribute programmatically, use the [highlightedImage](/documentation/uikit/uiimageview/highlightedimage) or [highlightedAnimationImages](/documentation/uikit/uiimageview/highlightedanimationimages) property. |
| State | The initial state of the image. Use this attribute to mark the image as highlighted. To set this attribute programmatically, use the [isHighlighted](/documentation/uikit/uiimageview/ishighlighted) property. |

### Internationalization

Internationalization of image views is automatic if your view displays only static images loaded from your app bundle. If you’re loading images programmatically, you’re at least partially responsible for loading the correct image.

- For resources in your app bundle, you do this by specifying the name in the attributes inspector or by calling the [init(named:)](/documentation/uikit/uiimage/init(named:)) class method on [UIImage](/documentation/uikit/uiimage) to obtain the localized version of each image.
- For images that aren’t in your app bundle, your code must do the following:

1. Determine which image to load in a manner specific to your app, such as providing a localized string that contains the URL.
2. Load that image by passing the URL or data for the correct image to an appropriate [UIImage](/documentation/uikit/uiimage) class method, such as [imageWithData:](/documentation/uikit/uiimage/imagewithdata:) or [imageWithContentsOfFile:](/documentation/uikit/uiimage/imagewithcontentsoffile:).

> **Note:** Screen metrics and layout may also change depending on the language and locale, particularly if the internationalized versions of your images have different dimensions. Where possible, you should try to make minimize dimension differences in internationalized versions of image resources.

For more information, see [Localization](/documentation/Xcode/localization).

### Accessibility

Image views are accessible by default. The default accessibility traits for an image view are Image and User Interaction Enabled.

For more information about making iOS controls accessible, see the accessibility information in [UIControl](/documentation/uikit/uicontrol). For general information about making your interface accessible, see [Accessibility for UIKit](/documentation/uikit/accessibility-for-uikit).

### State preservation

When you assign a value to an image view’s [restorationIdentifier](/documentation/uikit/uiviewcontroller/restorationidentifier) property, it attempts to preserve the frame of the displayed image. Specifically, the class preserves the values of the [bounds](/documentation/uikit/uiview/bounds), [center](/documentation/uikit/uiview/center), and [transform](/documentation/uikit/uiview/transform) properties of the view and the [anchorPoint](/documentation/QuartzCore/CALayer/anchorPoint) property of the underlying layer. During restoration, the image view restores these values so that the image appears exactly as before. For more information about how state preservation and restoration works, see [Restoring your app’s state](/documentation/uikit/restoring-your-app-s-state).

## Inherits From

- [UIView](/documentation/uikit/uiview)

## Conforms To

- [CALayerDelegate](/documentation/QuartzCore/CALayerDelegate)
- [CLBodyIdentifiable](/documentation/CoreLocation/CLBodyIdentifiable)
- [CMBodyIdentifiable](/documentation/CoreMotion/CMBodyIdentifiable)
- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIAccessibilityContentSizeCategoryImageAdjusting](/documentation/uikit/uiaccessibilitycontentsizecategoryimageadjusting)
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

## Creating an image view

- [init(image:)](/documentation/uikit/uiimageview/init(image:)) Returns an image view initialized with the specified image.
- [init(image:highlightedImage:)](/documentation/uikit/uiimageview/init(image:highlightedimage:)) Returns an image view initialized with the specified regular and highlighted images.

## Accessing the displayed images

- [image](/documentation/uikit/uiimageview/image) The image displayed in the image view.
- [highlightedImage](/documentation/uikit/uiimageview/highlightedimage) The highlighted image displayed in the image view.

## Animating a sequence of images

- [animationImages](/documentation/uikit/uiimageview/animationimages) An array of [UIImage](/documentation/uikit/uiimage) objects to use for an animation.
- [highlightedAnimationImages](/documentation/uikit/uiimageview/highlightedanimationimages) An array of [UIImage](/documentation/uikit/uiimage) objects to use for an animation when the view is highlighted.
- [animationDuration](/documentation/uikit/uiimageview/animationduration) The amount of time it takes to go through one cycle of the images.
- [animationRepeatCount](/documentation/uikit/uiimageview/animationrepeatcount) Specifies the number of times to repeat the animation.
- [startAnimating()](/documentation/uikit/uiimageview/startanimating()) Starts animating the images in the receiver.
- [stopAnimating()](/documentation/uikit/uiimageview/stopanimating()) Stops animating the images in the receiver.
- [isAnimating](/documentation/uikit/uiimageview/isanimating) Returns a Boolean value indicating whether the animation is running.

## Configuring the image view

- [isUserInteractionEnabled](/documentation/uikit/uiimageview/isuserinteractionenabled) A Boolean value that determines whether user events are ignored and removed from the event queue.
- [isHighlighted](/documentation/uikit/uiimageview/ishighlighted) A Boolean value that determines whether the image is highlighted.
- [tintColor](/documentation/uikit/uiimageview/tintcolor) A color used to tint template images in the view hierarchy.

## Configuring the appearance of symbol images

- [Configuring and displaying symbol images in your UI](/documentation/uikit/configuring-and-displaying-symbol-images-in-your-ui) Create scalable images that integrate with your app’s text, and adjust the appearance of those images dynamically.
- [preferredSymbolConfiguration](/documentation/uikit/uiimageview/preferredsymbolconfiguration) The configuration values to use when rendering the image.

## Configuring symbol effects

- [addSymbolEffect(_:options:animated:completion:)](/documentation/uikit/uiimageview/addsymboleffect(_:options:animated:completion:)-18jqj) Adds a discrete symbol effect to the image view with the specified options and animation.
- [addSymbolEffect(_:options:animated:completion:)](/documentation/uikit/uiimageview/addsymboleffect(_:options:animated:completion:)-2ixnm) Adds a discrete, indefinite symbol effect to the image view with the specified options and animation.
- [addSymbolEffect(_:options:animated:completion:)](/documentation/uikit/uiimageview/addsymboleffect(_:options:animated:completion:)-896qd) Adds an indefinite symbol effect to the image view with the specified options and animation.
- [setSymbolImage(_:contentTransition:options:completion:)](/documentation/uikit/uiimageview/setsymbolimage(_:contenttransition:options:completion:)) Sets a symbol image using the specified content-transition effect, options, and completion handler.
- [removeSymbolEffect(ofType:options:animated:completion:)](/documentation/uikit/uiimageview/removesymboleffect(oftype:options:animated:completion:)-218lh) Removes the symbol effect that matches the specified indefinite effect type, using the specified options and animation setting.
- [removeSymbolEffect(ofType:options:animated:completion:)](/documentation/uikit/uiimageview/removesymboleffect(oftype:options:animated:completion:)-31zec) Removes the symbol effect that matches the specified discrete, indefinite effect type, using the specified options and animation setting.
- [removeSymbolEffect(ofType:options:animated:completion:)](/documentation/uikit/uiimageview/removesymboleffect(oftype:options:animated:completion:)-2boi2) Removes the symbol effect that matches the specified discrete effect type, using the specified options and animation setting.
- [removeAllSymbolEffects(options:animated:)](/documentation/uikit/uiimageview/removeallsymboleffects(options:animated:)) Removes all symbol effects from the image view, using the specified options and animation setting.
- [UISymbolEffectCompletion](/documentation/uikit/uisymboleffectcompletion-7qt7g) A completion handler for adding and removing symbol effects and transitions.
- [UISymbolEffectCompletionContext](/documentation/uikit/uisymboleffectcompletioncontext-swift.struct) Information about a symbol effect’s addition or removal.

## Transitioning between symbol effects

- [UISymbolContentTransition](/documentation/uikit/uisymbolcontenttransition) Represents a symbol content transition and options.

## Managing focus-related behaviors

- [adjustsImageWhenAncestorFocused](/documentation/uikit/uiimageview/adjustsimagewhenancestorfocused) A Boolean value that determines whether the image view responds when an ancestor gains focus.
- [focusedFrameGuide](/documentation/uikit/uiimageview/focusedframeguide) The layout guide to use when the image view is focused.
- [masksFocusEffectToContents](/documentation/uikit/uiimageview/masksfocuseffecttocontents) A Boolean value indicating whether the floating focused appearance uses the image’s alpha channel.

## Layering content on top of the image view

- [overlayContentView](/documentation/uikit/uiimageview/overlaycontentview) A view for hosting layered content on top of the image view.

## Specifying the dynamic range

- [imageDynamicRange](/documentation/uikit/uiimageview/imagedynamicrange) The resolved treatment to use for HDR images.
- [preferredImageDynamicRange](/documentation/uikit/uiimageview/preferredimagedynamicrange) The preferred treatment to use for HDR images. By default the image view will defer to the value from its traitCollection.
- [UIImage.DynamicRange](/documentation/uikit/uiimage/dynamicrange)

## Content views

- [UIActivityIndicatorView](/documentation/uikit/uiactivityindicatorview) A view that shows that a task is in progress.
- [UICalendarView](/documentation/uikit/uicalendarview) A view that displays a calendar with date-specific decorations, and provides for user selection of a single date or multiple dates.
- [UIContentUnavailableView](/documentation/uikit/uicontentunavailableview) A view that indicates there’s no content to display.
- [UIPickerView](/documentation/uikit/uipickerview) A view that uses a spinning-wheel or slot-machine metaphor to show one or more sets of values.
- [UIProgressView](/documentation/uikit/uiprogressview) A view that depicts the progress of a task over time.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
