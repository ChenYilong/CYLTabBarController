---
title: UIImage
description: An object that manages image data in your app.
source: https://developer.apple.com/documentation/uikit/uiimage
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiimage.json
timestamp: 2026-06-26T06:39:36.970Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIImage

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+, watchOS 2.0+

> An object that manages image data in your app.

```swift
class UIImage
```

## Overview

You use image objects to represent image data of all kinds, and the [UIImage](/documentation/uikit/uiimage) class is capable of managing data for all image formats supported by the underlying platform. Image objects are immutable, so you always create them from existing image data, such as an image file on disk or programmatically created image data. An image object may contain a single image or a sequence of images for use in an animation.

You can use image objects in several different ways:

- Assign an image to a [UIImageView](/documentation/uikit/uiimageview) object to display the image in your interface.
- Use an image to customize system controls such as buttons, sliders, and segmented controls.
- Draw an image directly into a view or other graphics context.
- Pass an image to other APIs that might require image data.

Although image objects support all platform-native image formats, it’s recommended that you use PNG or JPEG files for most images in your app. Image objects are optimized for reading and displaying both formats, and those formats offer better performance than most other image formats. Because the PNG format is lossless, it’s especially recommended for the images you use in your app’s interface.

### Create image objects

When creating image objects using the methods of this class, you must have existing image data located in a file or data structure. You can’t create an empty image and draw content into it. There are many options for creating image objects, each of which is best for specific situations:

- Use the [init(named:in:compatibleWith:)](/documentation/uikit/uiimage/init(named:in:compatiblewith:)) method (or the [init(named:)](/documentation/uikit/uiimage/init(named:)) method) to create an image from an image asset or image file located in your app’s main bundle (or some other known bundle). Because these methods cache the image data automatically, they’re especially recommended for images that you use frequently.
- Use the [imageWithContentsOfFile:](/documentation/uikit/uiimage/imagewithcontentsoffile:) or [init(contentsOfFile:)](/documentation/uikit/uiimage/init(contentsoffile:)) method to create an image object where the initial data isn’t in a bundle. These methods load the image data from disk each time, so don’t use them to load the same image repeatedly.
- Use the [animatedImage(with:duration:)](/documentation/uikit/uiimage/animatedimage(with:duration:)) and [animatedImageNamed(_:duration:)](/documentation/uikit/uiimage/animatedimagenamed(_:duration:)) methods to create a single [UIImage](/documentation/uikit/uiimage) object comprised of multiple sequential images. Install the resulting image in a [UIImageView](/documentation/uikit/uiimageview) object to create animations in your interface.

Other methods of the [UIImage](/documentation/uikit/uiimage) class let you create animations from specific types of data, such as Core Graphics images or image data you create yourself. UIKit also provides the [UIGraphicsGetImageFromCurrentImageContext()](/documentation/uikit/uigraphicsgetimagefromcurrentimagecontext()) function to create images from content you draw yourself. You use that function in conjunction with a bitmap-based graphics context, which you use to capture your drawing commands.

> **Note:** Because image objects are immutable, you can’t change their properties after creation. Most image properties are set automatically using metadata in the accompanying image file or image data. The immutable nature of image objects also means they’re safe to create and use from any thread.

Image assets are the easiest way to manage the images that ship with your app. Each new Xcode project contains an assets library, to which you can add multiple image sets. An image set contains the variations of a single image that your app uses. A single image set can provide different versions of an image for different platforms, for different trait environments (compact or regular), and for different scale factors.

In addition to loading images from disk, you can ask the user to supply images from an available camera or photo library using a [UIImagePickerController](/documentation/uikit/uiimagepickercontroller) object. An image picker displays a custom user interface for selecting images. Accessing user-supplied images requires explicit user permission. For more information about using an image picker, see [UIImagePickerController](/documentation/uikit/uiimagepickercontroller).

### Define a stretchable image

A stretchable image is one that defines regions where you can duplicate the underlying image data in an aesthetically pleasing way. Stretchable images are commonly used to create backgrounds that can grow or shrink to fill the available space.

Define a stretchable image by adding insets to an existing image using the [resizableImage(withCapInsets:)](/documentation/uikit/uiimage/resizableimage(withcapinsets:)) or [resizableImage(withCapInsets:resizingMode:)](/documentation/uikit/uiimage/resizableimage(withcapinsets:resizingmode:)) method. The insets subdivide the image into two or more parts. Specifying nonzero values for each inset yields an image divided into nine parts, as shown in the following image:

![An image that depicts how to use insets to define stretchable regions. The image on the left is stretched and shows Left, Right, Top, and Bottom insets. The image on the right is condensed and also shows Left, Right, Top, and Bottom insets.](https://docs-assets.developer.apple.com/published/a24122a4b3a9289007f9bcad22d8667d/media-1965929%402x.png)

Each inset defines the portion of the image that doesn’t stretch in the given dimension. The regions inside an image’s top and bottom insets maintain a fixed height, and the areas inside the left and right insets maintain a fixed width. The following image shows how each part of a nine-part image stretches as the image itself is stretched to fill the available space. The corners of the image don’t change size because they’re inside both a horizontal and vertical inset:

![An image that depicts the stretchable portions of a nine-part image. The image on the left is stretched. The image on the right is condensed. The corners of both images remain the same size.](https://docs-assets.developer.apple.com/published/dcf9ad7415ffdb2dd9a753a3be251cce/media-1965930%402x.png)

### Compare images

The [isEqual(_:)](/documentation/ObjectiveC/NSObjectProtocol/isEqual(_:)) method is the only reliable way to determine whether two image objects contain the same image data. The following code illustrates the correct and incorrect ways to compare images.

### Swift

```swift
// Load the same image twice.
let image1 = UIImage(named: "MyImage")
let image2 = UIImage(named: "MyImage") 

// The image objects may be different, but the contents are still equal.
if image1 != nil && image1!.isEqual(image2) {
    // Correct. This technique compares the image data correctly.
} 
if image1 == image2 {
    // Incorrect! Direct object comparisons may not work.
}
```

### Objective-C

```objc
// Load the same image twice.
UIImage* image1 = [UIImage imageNamed:@"MyImage"];
UIImage* image2 = [UIImage imageNamed:@"MyImage"];
 
// The image objects may be different, but the contents are still equal
if ([image1 isEqual:image2]) {
   // Correct. This technique compares the image data correctly.
}
 
if (image1 == image2) {
   // Incorrect! Direct object comparisons may not work.
}
```

### Access the image data

Image objects don’t provide direct access to their underlying image data. However, you can retrieve the image data in other formats for use in your app. Specifically, you can use the [cgImage](/documentation/uikit/uiimage/cgimage) and [ciImage](/documentation/uikit/uiimage/ciimage) properties to retrieve versions of the image that are compatible with Core Graphics and Core Image, respectively. You can also use the [pngData()](/documentation/uikit/uiimage/pngdata()) and [jpegData(compressionQuality:)](/documentation/uikit/uiimage/jpegdata(compressionquality:)) functions to generate an [NSData](/documentation/Foundation/NSData) object containing the image data in either the PNG or JPEG format.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [AttachableAsImage](/documentation/Testing/AttachableAsImage)
- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [JournalingSuggestionAsset](/documentation/JournalingSuggestions/JournalingSuggestionAsset)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSItemProviderReading](/documentation/Foundation/NSItemProviderReading)
- [NSItemProviderWriting](/documentation/Foundation/NSItemProviderWriting)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIAccessibilityIdentification](/documentation/uikit/uiaccessibilityidentification)
- [UIItemProviderPresentationSizeProviding](/documentation/uikit/uiitemproviderpresentationsizeproviding)

## Loading and caching images

- [Providing images for different appearances](/documentation/uikit/providing-images-for-different-appearances) Supply image resources appropriate for light and dark appearances and for high-contrast environments.
- [Configuring and displaying symbol images in your UI](/documentation/uikit/configuring-and-displaying-symbol-images-in-your-ui) Create scalable images that integrate with your app’s text, and adjust the appearance of those images dynamically.
- [Creating custom symbol images for your app](/documentation/uikit/creating-custom-symbol-images-for-your-app) Create, organize, and annotate symbol images using SF Symbols.
- [init(named:in:compatibleWith:)](/documentation/uikit/uiimage/init(named:in:compatiblewith:)) Creates an image object using the named image asset that’s compatible with the specified trait collection.
- [init(named:in:with:)](/documentation/uikit/uiimage/init(named:in:with:)) Creates an image by using the named image asset that’s compatible with the configuration you specify.
- [init(named:in:variableValue:configuration:)](/documentation/uikit/uiimage/init(named:in:variablevalue:configuration:)) Creates an image by using the name, configuration, and variable value you specify.
- [init(named:)](/documentation/uikit/uiimage/init(named:)) Creates an image object from the specified named asset.
- [init(imageLiteralResourceName:)](/documentation/uikit/uiimage/init(imageliteralresourcename:)) Returns the image object for the specified resource.
- [init(systemName:withConfiguration:)](/documentation/uikit/uiimage/init(systemname:withconfiguration:)) Creates an image object that contains a system symbol image with the specified configuration.
- [init(systemName:variableValue:configuration:)](/documentation/uikit/uiimage/init(systemname:variablevalue:configuration:)) Creates an image object that contains a system symbol image with the configuration and variable value you specify.
- [init(systemName:compatibleWith:)](/documentation/uikit/uiimage/init(systemname:compatiblewith:)) Creates an image object that contains a system symbol image appropriate for the specified traits.
- [init(systemName:)](/documentation/uikit/uiimage/init(systemname:)) Creates an image object that contains a system symbol image.
- [init(resource:)](/documentation/uikit/uiimage/init(resource:))
- [Building high-performance lists and collection views](/documentation/uikit/building-high-performance-lists-and-collection-views) Improve the performance of lists and collections in your app with prefetching and image preparation.

## Loading images for display

- [preparingForDisplay()](/documentation/uikit/uiimage/preparingfordisplay()) Decodes an image synchronously and provides a new one for display in views and animations.
- [prepareForDisplay(completionHandler:)](/documentation/uikit/uiimage/preparefordisplay(completionhandler:)) Decodes an image asynchronously and provides a new one for display in views and animations.
- [preparingThumbnail(of:)](/documentation/uikit/uiimage/preparingthumbnail(of:)) Returns a new thumbnail image at the specified size.
- [prepareThumbnail(of:completionHandler:)](/documentation/uikit/uiimage/preparethumbnail(of:completionhandler:)) Creates a thumbnail image at the specified size asynchronously on a background thread.

## Creating and initializing image objects

- [init(contentsOfFile:)](/documentation/uikit/uiimage/init(contentsoffile:)) Initializes and returns the image object with the contents of the specified file.
- [init(data:)](/documentation/uikit/uiimage/init(data:)) Initializes and returns the image object with the specified data.
- [init(data:scale:)](/documentation/uikit/uiimage/init(data:scale:)) Initializes and returns the image object with the specified data and scale factor.
- [init(cgImage:)](/documentation/uikit/uiimage/init(cgimage:)-14qlb) Initializes and returns the image object with the specified Quartz image reference.
- [init(cgImage:scale:orientation:)](/documentation/uikit/uiimage/init(cgimage:scale:orientation:)-2ouhh) Initializes and returns an image object with the specified scale and orientation factors.
- [init(ciImage:)](/documentation/uikit/uiimage/init(ciimage:)-93vu1) Initializes and returns an image object with the specified Core Image object.
- [init(ciImage:scale:orientation:)](/documentation/uikit/uiimage/init(ciimage:scale:orientation:)-9gpyn) Initializes and returns an image object with the specified Core Image object and properties.
- [UIImageReader](/documentation/uikit/uiimagereader-swift.struct)

## Creating animated images

- [animatedImageNamed(_:duration:)](/documentation/uikit/uiimage/animatedimagenamed(_:duration:)) Creates and returns an animated image.
- [animatedImage(with:duration:)](/documentation/uikit/uiimage/animatedimage(with:duration:)) Creates and returns an animated image from an existing set of images.
- [animatedResizableImageNamed(_:capInsets:duration:)](/documentation/uikit/uiimage/animatedresizableimagenamed(_:capinsets:duration:)) Creates and returns an animated image with end caps.
- [animatedResizableImageNamed(_:capInsets:resizingMode:duration:)](/documentation/uikit/uiimage/animatedresizableimagenamed(_:capinsets:resizingmode:duration:)) Creates and returns an animated image with end caps and a specific resizing mode.

## Changing the image attributes

- [withConfiguration(_:)](/documentation/uikit/uiimage/withconfiguration(_:)) Returns a new version of the current image, replacing the current configuration attributes with the specified attributes.
- [applyingSymbolConfiguration(_:)](/documentation/uikit/uiimage/applyingsymbolconfiguration(_:)) Returns a new version of the current image, applying the specified configuration attributes on top of the current attributes.
- [imageFlippedForRightToLeftLayoutDirection()](/documentation/uikit/uiimage/imageflippedforrighttoleftlayoutdirection()) Returns a new version of the current image that flips horizontally when it’s in a right-to-left layout.
- [withHorizontallyFlippedOrientation()](/documentation/uikit/uiimage/withhorizontallyflippedorientation()) Returns a new version of the image that’s a mirror of the original image.
- [withRenderingMode(_:)](/documentation/uikit/uiimage/withrenderingmode(_:)) Returns a new version of the image that uses the specified rendering mode.
- [withAlignmentRectInsets(_:)](/documentation/uikit/uiimage/withalignmentrectinsets(_:)) Returns a new version of the image that uses the specified alignment insets.
- [resizableImage(withCapInsets:)](/documentation/uikit/uiimage/resizableimage(withcapinsets:)) Returns a new version of the image with the specified cap insets.
- [resizableImage(withCapInsets:resizingMode:)](/documentation/uikit/uiimage/resizableimage(withcapinsets:resizingmode:)) Returns a new version of the image with the specified cap insets and options.
- [imageWithoutBaseline()](/documentation/uikit/uiimage/imagewithoutbaseline()) Creates a copy of the current image object without any baseline information.
- [withBaselineOffset(fromBottom:)](/documentation/uikit/uiimage/withbaselineoffset(frombottom:)) Creates a new image with a baseline at the specified offset from the bottom of the image.
- [UIImage.Configuration](/documentation/uikit/uiimage/configuration-swift.class) A configuration object that contains the traits that the system uses when selecting the current image variant.
- [UIImage.SymbolConfiguration](/documentation/uikit/uiimage/symbolconfiguration-swift.class) An object that contains the specific font, size, style, and weight attributes to apply to a symbol image.

## Getting standard system images

- [add](/documentation/uikit/uiimage/add) The standard image for indicating the addition of content.
- [remove](/documentation/uikit/uiimage/remove) The standard image for indicating the removal of content.
- [actions](/documentation/uikit/uiimage/actions) The standard image for indicating user-initiated actions.
- [checkmark](/documentation/uikit/uiimage/checkmark) The standard image for a checkmark on a filled-circle background.
- [strokedCheckmark](/documentation/uikit/uiimage/strokedcheckmark) The standard image for a checkmark on a tinted circle with a white-stroked border.

## Getting the image data

- [cgImage](/documentation/uikit/uiimage/cgimage) The underlying Quartz image data.
- [ciImage](/documentation/uikit/uiimage/ciimage) The underlying Core Image data.
- [images](/documentation/uikit/uiimage/images) The complete array of image objects that compose the animation of an animated object.
- [imageAsset](/documentation/uikit/uiimage/imageasset) The image asset (if any) for the image.

## Getting the image size and scale

- [scale](/documentation/uikit/uiimage/scale) The scale factor of the image.
- [size](/documentation/uikit/uiimage/size) The logical dimensions, in points, for the image.

## Accessing image attributes

- [imageOrientation](/documentation/uikit/uiimage/imageorientation) The orientation of the receiver’s image.
- [UIImage.Orientation](/documentation/uikit/uiimage/orientation) Constants that specify the intended display orientation for an image.
- [flipsForRightToLeftLayoutDirection](/documentation/uikit/uiimage/flipsforrighttoleftlayoutdirection) A Boolean value that indicates whether the image flips in a right-to-left layout.
- [resizingMode](/documentation/uikit/uiimage/resizingmode-swift.property) The resizing mode of the image.
- [UIImage.ResizingMode](/documentation/uikit/uiimage/resizingmode-swift.enum) Constants that specify the possible resizing modes for an image.
- [duration](/documentation/uikit/uiimage/duration) The time interval for displaying an animated image.
- [capInsets](/documentation/uikit/uiimage/capinsets) The end-cap insets.
- [alignmentRectInsets](/documentation/uikit/uiimage/alignmentrectinsets) The alignment metadata for positioning the image during layout.
- [isSymbolImage](/documentation/uikit/uiimage/issymbolimage) A Boolean value that indicates whether the image is a symbol.

## Getting the image configuration

- [configuration](/documentation/uikit/uiimage/configuration-swift.property) The configuration details for the image.
- [symbolConfiguration](/documentation/uikit/uiimage/symbolconfiguration-swift.property) The configuration details for a symbol image.
- [traitCollection](/documentation/uikit/uiimage/traitcollection) The trait collection that describes the current variant of the image.

## Specifying the dynamic range

- [isHighDynamicRange](/documentation/uikit/uiimage/ishighdynamicrange) Indicates that this image is tagged for display of high dynamic range content.
- [imageRestrictedToStandardDynamicRange()](/documentation/uikit/uiimage/imagerestrictedtostandarddynamicrange()) Returns a new image that will render within the standard range.
- [heicData()](/documentation/uikit/uiimage/heicdata()) Returns HEIC data representing the image, or nil if such a representation could not be generated. HEIC is recommended for efficiently storing all kinds of images, including those with high dynamic range content.
- [UIImage.DynamicRange](/documentation/uikit/uiimage/dynamicrange)

## Managing the baseline

- [baselineOffsetFromBottom](/documentation/uikit/uiimage/baselineoffsetfrombottom-3emg) The position of the baseline relative to the bottom of the image.

## Getting rendering information

- [renderingMode](/documentation/uikit/uiimage/renderingmode-swift.property) A setting that determines how the app renders an image.
- [UIImage.RenderingMode](/documentation/uikit/uiimage/renderingmode-swift.enum) Constants that specify the possible rendering modes for an image.
- [imageRendererFormat](/documentation/uikit/uiimage/imagerendererformat) The preferred image renderer format for the image.

## Tinting the image

- [withTintColor(_:)](/documentation/uikit/uiimage/withtintcolor(_:)) Returns a new version of the current image with the specified tint color.
- [withTintColor(_:renderingMode:)](/documentation/uikit/uiimage/withtintcolor(_:renderingmode:)) Returns a new version of the image with a tint color that uses the specified rendering mode.

## Drawing images

- [draw(at:)](/documentation/uikit/uiimage/draw(at:)) Draws the image at the specified point in the current context.
- [draw(at:blendMode:alpha:)](/documentation/uikit/uiimage/draw(at:blendmode:alpha:)) Draws the entire image at the specified point using the custom compositing options.
- [draw(in:)](/documentation/uikit/uiimage/draw(in:)) Draws the entire image in the specified rectangle, scaling it as necessary to fit.
- [draw(in:blendMode:alpha:)](/documentation/uikit/uiimage/draw(in:blendmode:alpha:)) Draws the entire image in the specified rectangle using the specified compositing options.
- [drawAsPattern(in:)](/documentation/uikit/uiimage/drawaspattern(in:)) Draws a tiled Quartz pattern using the receiver’s contents as the tile pattern.

## Exporting standard bitmap formats

- [jpegData(compressionQuality:)](/documentation/uikit/uiimage/jpegdata(compressionquality:)) Returns a data object that contains the image in JPEG format.
- [pngData()](/documentation/uikit/uiimage/pngdata()) Returns a data object that contains the specified image in PNG format.

## Deprecated

- [stretchableImage(withLeftCapWidth:topCapHeight:)](/documentation/uikit/uiimage/stretchableimage(withleftcapwidth:topcapheight:)) Creates and returns a new image object with the specified cap values.
- [leftCapWidth](/documentation/uikit/uiimage/leftcapwidth) The horizontal end-cap size.
- [topCapHeight](/documentation/uikit/uiimage/topcapheight) The vertical end-cap size.

## Initializers

- [init(CGImage:)](/documentation/uikit/uiimage/init(cgimage:)-8doi8)
- [init(CGImage:)](/documentation/uikit/uiimage/init(cgimage:)-g30x)
- [init(CGImage:scale:orientation:)](/documentation/uikit/uiimage/init(cgimage:scale:orientation:)-3mxey)
- [init(CGImage:scale:orientation:)](/documentation/uikit/uiimage/init(cgimage:scale:orientation:)-3xlco)
- [init(CIImage:)](/documentation/uikit/uiimage/init(ciimage:)-3kg9b)
- [init(CIImage:)](/documentation/uikit/uiimage/init(ciimage:)-8dq4u)
- [init(CIImage:scale:orientation:)](/documentation/uikit/uiimage/init(ciimage:scale:orientation:)-3742c)
- [init(CIImage:scale:orientation:)](/documentation/uikit/uiimage/init(ciimage:scale:orientation:)-wlzf)
- [init(coder:)](/documentation/uikit/uiimage/init(coder:))
- [init(named:inBundle:compatibleWithTraitCollection:)](/documentation/uikit/uiimage/init(named:inbundle:compatiblewithtraitcollection:))
- [init(named:inBundle:withConfiguration:)](/documentation/uikit/uiimage/init(named:inbundle:withconfiguration:))

## Representations

- [UIImage.SymbolConfiguration](/documentation/uikit/uiimage/symbolconfiguration-swift.class) An object that contains the specific font, size, style, and weight attributes to apply to a symbol image.
- [UIImage.Configuration](/documentation/uikit/uiimage/configuration-swift.class) A configuration object that contains the traits that the system uses when selecting the current image variant.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
