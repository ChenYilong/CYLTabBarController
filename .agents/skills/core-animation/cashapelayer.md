---
title: CAShapeLayer
description: A layer that draws a cubic Bezier spline in its coordinate space.
source: https://developer.apple.com/documentation/quartzcore/cashapelayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/cashapelayer.json
timestamp: 2026-05-13T20:41:27.835Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CAShapeLayer

**Available on:** iOS 3.0+, iPadOS 3.0+, Mac Catalyst 13.1+, macOS 10.6+, tvOS 9.0+, visionOS 1.0+

> A layer that draws a cubic Bezier spline in its coordinate space.

```swift
class CAShapeLayer
```

## Overview

The shape is composited between the layer’s contents and its first sublayer.

The shape will be drawn antialiased, and whenever possible it will be mapped into screen space before being rasterized to preserve resolution independence. However, certain kinds of image processing operations, such as CoreImage filters, applied to the layer or its ancestors may force rasterization in a local coordinate space.

The following code shows how you can build complex, composite paths and display them using a shape layer. In this example, a series of progressively transformed ellipses form a simple flower shape. The shape layer that displays the path has its [fillRule](/documentation/quartzcore/cashapelayer/fillrule) set to [evenOdd](/documentation/quartzcore/cashapelayerfillrule/evenodd) which stops the overlapping “petals” from filling with the yellow [fillColor](/documentation/quartzcore/cashapelayer/fillcolor).

```swift
let width: CGFloat = 640
let height: CGFloat = 640
     
let shapeLayer = CAShapeLayer()
shapeLayer.frame = CGRect(x: 0, y: 0,
                          width: width, height: height)
     
let path = CGMutablePath()
     
stride(from: 0, to: CGFloat.pi * 2, by: CGFloat.pi / 6).forEach {
    angle in 
    var transform  = CGAffineTransform(rotationAngle: angle)
        .concatenating(CGAffineTransform(translationX: width / 2, y: height / 2))
    
    let petal = CGPath(ellipseIn: CGRect(x: -20, y: 0, width: 40, height: 100),
                       transform: &transform)
    
    path.addPath(petal)
}
    
shapeLayer.path = path
shapeLayer.strokeColor = UIColor.red.cgColor
shapeLayer.fillColor = UIColor.yellow.cgColor
shapeLayer.fillRule = kCAFillRuleEvenOdd
```

The following figure shows the resulting shape layer.

![Composite path displayed in a shape layer](https://docs-assets.developer.apple.com/published/67723bba6f48e3e15851ddfb2c5a2a8c/media-2825196%402x.png)

> **Note:** Shape rasterization may favor speed over accuracy. For example, pixels with multiple intersecting path segments may not give exact results.

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

## Specifying the Shape Path

- [path](/documentation/quartzcore/cashapelayer/path) The path defining the shape to be rendered. Animatable.

## Accessing Shape Style Properties

- [fillColor](/documentation/quartzcore/cashapelayer/fillcolor) The color used to fill the shape’s path. Animatable.
- [fillRule](/documentation/quartzcore/cashapelayer/fillrule) The fill rule used when filling the shape’s path.
- [lineCap](/documentation/quartzcore/cashapelayer/linecap) Specifies the line cap style for the shape’s path.
- [lineDashPattern](/documentation/quartzcore/cashapelayer/linedashpattern) The dash pattern applied to the shape’s path when stroked.
- [lineDashPhase](/documentation/quartzcore/cashapelayer/linedashphase) The dash phase applied to the shape’s path when stroked. Animatable.
- [lineJoin](/documentation/quartzcore/cashapelayer/linejoin) Specifies the line join style for the shape’s path.
- [lineWidth](/documentation/quartzcore/cashapelayer/linewidth) Specifies the line width of the shape’s path. Animatable.
- [miterLimit](/documentation/quartzcore/cashapelayer/miterlimit) The miter limit used when stroking the shape’s path. Animatable.
- [strokeColor](/documentation/quartzcore/cashapelayer/strokecolor) The color used to stroke the shape’s path. Animatable.
- [strokeStart](/documentation/quartzcore/cashapelayer/strokestart) The relative location at which to begin stroking the path. Animatable.
- [strokeEnd](/documentation/quartzcore/cashapelayer/strokeend) The relative location at which to stop stroking the path. Animatable.

## Constants

- [Shape Fill Mode Values](/documentation/quartzcore/shape-fill-mode-values) These constants specify the possible fill modes for [fillRule](/documentation/quartzcore/cashapelayer/fillrule).
- [Line Join Values](/documentation/quartzcore/line-join-values) These constants specify the shape of the joints between connected segments of a stroked path.
- [Line Cap Values](/documentation/quartzcore/line-cap-values) These constants specify the shape of endpoints for an open path when stroked.

## Text, Shapes, and Gradients

- [CATextLayer](/documentation/quartzcore/catextlayer) A layer that provides simple text layout and rendering of plain or attributed strings.
- [CAGradientLayer](/documentation/quartzcore/cagradientlayer) A layer that draws a color gradient over its background color, filling the shape of the layer.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
