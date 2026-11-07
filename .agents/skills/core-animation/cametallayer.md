---
title: CAMetalLayer
description: A Core Animation layer that Metal can render into, typically displayed onscreen.
source: https://developer.apple.com/documentation/quartzcore/cametallayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/cametallayer.json
timestamp: 2026-05-13T20:41:34.070Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAMetalLayer

**Available on:** iOS 8.0+, iPadOS 8.0+, Mac Catalyst 13.1+, macOS 10.11+, tvOS 9.0+, visionOS 1.0+

> A Core Animation layer that Metal can render into, typically displayed onscreen.

```swift
class CAMetalLayer
```

## Overview

Use a [CAMetalLayer](/documentation/quartzcore/cametallayer) when you want to use Metal to render a layer’s contents; for example, to render into a view. Consider using [MTKView](/documentation/MetalKit/MTKView) instead, because this class automatically wraps a [CAMetalLayer](/documentation/quartzcore/cametallayer) object and provides a higher-level abstraction.

If you’re using UIKit, to create a view that uses a [CAMetalLayer](/documentation/quartzcore/cametallayer), create a subclass of [UIView](https://developer.apple.com/library/archive/releasenotes/iPhone/RN-iPhoneSDK/index.html#//apple_ref/doc/uid/TP40007428-CH1-SW18) and override its [layerClass](/documentation/UIKit/UIView/layerClass) class method to return a [CAMetalLayer](/documentation/quartzcore/cametallayer):

```objc
+ (Class) layerClass
{
    return [CAMetalLayer class];
}
```

If you’re using AppKit, configure an [NSView](/documentation/AppKit/NSView) object to use a backing layer and assign a [CAMetalLayer](/documentation/quartzcore/cametallayer) object to the view:

```objc
myView.wantsLayer = YES;
myView.layer = [CAMetalLayer layer];
```

Adjust the layer’s properties to configure its underlying pixel format and other display behaviors.

### Rendering the Layer’s Contents

A [CAMetalLayer](/documentation/quartzcore/cametallayer) creates a pool of Metal drawable objects ([CAMetalDrawable](/documentation/quartzcore/cametaldrawable)). At any given time, one of these drawable objects contains the contents of the layer. To change the layer’s contents, ask the layer for a drawable object, render into it, and then update the layer’s contents to point to the new drawable.

Call the layer’s [nextDrawable()](/documentation/quartzcore/cametallayer/nextdrawable()) method to obtain a drawable object. Get the drawable object’s texture and create a render pass that renders to that texture, as shown in the code below:

```objc
CAMetalLayer *metalLayer = (CAMetalLayer*)self.layer;
id<CAMetalDrawable> *drawable = [metalLayer nextDrawable];

MTLRenderPassDescriptor *renderPassDescriptor
                               = [MTLRenderPassDescriptor renderPassDescriptor];

renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0,0.0,0.0,1.0);
...
```

To change the layer’s contents to the new drawable, call the [present(_:)](/documentation/Metal/MTLCommandBuffer/present(_:)) method (or one of its variants) on the command buffer containing the encoded render pass, passing in the drawable object to present.

```objc
[commandBuffer presentDrawable:drawable];
```

### Keeping References to Drawables

The layer reuses a drawable only if it isn’t onscreen and there are no strong references to it. Further, if a drawable isn’t available when you call [nextDrawable()](/documentation/quartzcore/cametallayer/nextdrawable()), the system waits for one to become available. To avoid stalls in your app, request a new drawable only when you need it, and release any references to it as quickly as possible after you’re done with it.

For example, before retrieving a new drawable, you might perform other work on the CPU or submit commands to the GPU that don’t require the drawable. Then, obtain the drawable and encode a command buffer to render into it, as described above. After you commit this command buffer, release all strong references to the drawable. If you don’t release drawables correctly, the layer runs out of drawables, and future calls to [nextDrawable()](/documentation/quartzcore/cametallayer/nextdrawable()) return `nil`.

### Releasing the Drawable

Don’t release the drawable explicitly; instead, embed your render loop within an autorelease pool block:

### Swift

```swift
func draw(in view: MTKView) {
    autoreleasepool {
        render(view: view)
    }
}
```

### Objective-C

```objc
- (void)drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        [self render:view];
    }
}
```

This block releases drawables promptly and avoids possible deadlock situations with multiple drawables. Release drawables as soon as possible after committing your onscreen render pass.

> **Note:** As of iOS 10 and tvOS 10, you can safely retain a drawable to query its properties, such as [drawableID](/documentation/Metal/MTLDrawable/drawableID) and [presentedTime](/documentation/Metal/MTLDrawable/presentedTime), after the system has presented it. If you don’t need to query these properties, release the drawable when you no longer need it.

## Inherits From

- [CALayer](/documentation/quartzcore/calayer)

## Conforms To

- [CAMediaTiming](/documentation/quartzcore/camediatiming)
- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSSecureCoding](/documentation/Foundation/NSSecureCoding)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Configuring the Metal Device

- [device](/documentation/quartzcore/cametallayer/device) The Metal device responsible for the layer’s drawable resources.
- [preferredDevice](/documentation/quartzcore/cametallayer/preferreddevice) The device object that the system recommends using for this layer.

## Configuring the Layer’s Drawable Objects

- [pixelFormat](/documentation/quartzcore/cametallayer/pixelformat) The pixel format of the layer’s textures.
- [colorspace](/documentation/quartzcore/cametallayer/colorspace) The color space of the rendered content.
- [framebufferOnly](/documentation/quartzcore/cametallayer/framebufferonly) A Boolean value that determines whether the layer’s textures are used only for rendering.
- [drawableSize](/documentation/quartzcore/cametallayer/drawablesize) The size, in pixels, of textures for rendering layer content.

## Configuring Presentation Behavior

- [presentsWithTransaction](/documentation/quartzcore/cametallayer/presentswithtransaction) A Boolean value that determines whether the layer presents its content using a Core Animation transaction.
- [displaySyncEnabled](/documentation/quartzcore/cametallayer/displaysyncenabled) A Boolean value that determines whether the layer synchronizes its updates to the display’s refresh rate.

## Configuring Extended Dynamic Range Behavior

- [wantsExtendedDynamicRangeContent](/documentation/quartzcore/cametallayer/wantsextendeddynamicrangecontent) Enables extended dynamic range values onscreen.
- [edrMetadata](/documentation/quartzcore/cametallayer/edrmetadata) Metadata describing the tone mapping to apply to the extended dynamic range (EDR) values in the layer.

## Obtaining a Metal Drawable

- [nextDrawable()](/documentation/quartzcore/cametallayer/nextdrawable()) Waits until a Metal drawable is available, and then returns it.
- [maximumDrawableCount](/documentation/quartzcore/cametallayer/maximumdrawablecount) The number of Metal drawables in the resource pool managed by Core Animation.
- [allowsNextDrawableTimeout](/documentation/quartzcore/cametallayer/allowsnextdrawabletimeout) A Boolean value that determines whether requests for a new buffer expire if the system can’t satisfy them.

## Configuring the Metal Performance HUD

- [developerHUDProperties](/documentation/quartzcore/cametallayer/developerhudproperties) The properties of the Metal performance heads-up display.

## Instance Properties

- [residencySet](/documentation/quartzcore/cametallayer/residencyset)

## Metal and OpenGL

- [CAMetalDrawable](/documentation/quartzcore/cametaldrawable) A Metal drawable associated with a Core Animation layer.
- [CAEAGLLayer](/documentation/quartzcore/caeagllayer) A layer that supports drawing OpenGL content in iOS and tvOS applications.
- [CAEDRMetadata](/documentation/quartzcore/caedrmetadata) Metadata describing how extended dynamic range (EDR) values should be tone mapped.
- [CAOpenGLLayer](/documentation/quartzcore/caopengllayer) A layer that provides a layer suitable for rendering OpenGL content.
- [CARenderer](/documentation/quartzcore/carenderer) A layer that allows an application to render a layer tree into a Core OpenGL context.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
