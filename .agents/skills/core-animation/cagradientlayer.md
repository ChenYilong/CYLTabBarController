---
title: CAGradientLayer
description: A layer that draws a color gradient over its background color, filling the shape of the layer.
source: https://developer.apple.com/documentation/quartzcore/cagradientlayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/cagradientlayer.json
timestamp: 2026-05-13T20:41:28.718Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAGradientLayer

**Available on:** iOS 3.0+, iPadOS 3.0+, Mac Catalyst 13.1+, macOS 10.6+, tvOS 9.0+, visionOS 1.0+

> A layer that draws a color gradient over its background color, filling the shape of the layer.

```swift
class CAGradientLayer
```

## Overview

You use a gradient layer to create a color gradient containing an arbitrary number of colors. By default, the colors are spread uniformly across the layer, but you can optionally specify locations for control over the color positions through the gradient.

The following code shows how to create a gradient layer containing four colors that are evenly distributed through the gradient. Rotating the layer by 90° ([pi](/documentation/Swift/FloatingPoint/pi) ⁄ `2` radians) gives a horizontal gradient.

```objc
gradientLayer.colors = [UIColor.red.cgColor,
                        UIColor.yellow.cgColor,
                        UIColor.green.cgColor,
                        UIColor.blue.cgColor]
     
gradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
```

The following figure shows the appearance of the gradient layer.

![Color gradient layer](https://docs-assets.developer.apple.com/published/44142ddb755d778cdadae1874f04dc62/media-2825193%402x.png)

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

## Gradient Style Properties

- [colors](/documentation/quartzcore/cagradientlayer/colors) An array of `CGColorRef` objects defining the color of each gradient stop. Animatable.
- [locations](/documentation/quartzcore/cagradientlayer/locations) An optional array of NSNumber objects defining the location of each gradient stop. Animatable.
- [endPoint](/documentation/quartzcore/cagradientlayer/endpoint) The end point of the gradient when drawn in the layer’s coordinate space. Animatable.
- [startPoint](/documentation/quartzcore/cagradientlayer/startpoint) The start point of the gradient when drawn in the layer’s coordinate space. Animatable.
- [type](/documentation/quartzcore/cagradientlayer/type) Style of gradient drawn by the layer.

## Constants

- [Gradient Types](/documentation/quartzcore/gradient-types) The style of gradient drawn by the layer.

## Text, Shapes, and Gradients

- [CATextLayer](/documentation/quartzcore/catextlayer) A layer that provides simple text layout and rendering of plain or attributed strings.
- [CAShapeLayer](/documentation/quartzcore/cashapelayer) A layer that draws a cubic Bezier spline in its coordinate space.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
