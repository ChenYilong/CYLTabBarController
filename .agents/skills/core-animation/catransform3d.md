---
title: CATransform3D
description: The standard transform matrix used throughout Core Animation.
source: https://developer.apple.com/documentation/quartzcore/catransform3d
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/catransform3d.json
timestamp: 2026-05-13T20:41:32.338Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Structure**

# CATransform3D

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> The standard transform matrix used throughout Core Animation.

```swift
struct CATransform3D
```

## Overview

The transform matrix is used to rotate, scale, translate, skew, and project the layer content. Functions are provided for creating, concatenating, and modifying CATransform3D data.

## Conforms To

- [BitwiseCopyable](/documentation/Swift/BitwiseCopyable)
- [Copyable](/documentation/Swift/Copyable)
- [Escapable](/documentation/Swift/Escapable)
- [Sendable](/documentation/Swift/Sendable)

## Initializers

- [init()](/documentation/quartzcore/catransform3d/init())
- [init(m11:m12:m13:m14:m21:m22:m23:m24:m31:m32:m33:m34:m41:m42:m43:m44:)](/documentation/quartzcore/catransform3d/init(m11:m12:m13:m14:m21:m22:m23:m24:m31:m32:m33:m34:m41:m42:m43:m44:))
- [init(_:)](/documentation/quartzcore/catransform3d/init(_:)-6awvy)
- [init(_:)](/documentation/quartzcore/catransform3d/init(_:)-6euzs)

## Instance Properties

- [m11](/documentation/quartzcore/catransform3d/m11) The entry at position 1,1 in the matrix.
- [m12](/documentation/quartzcore/catransform3d/m12) The entry at position 1,2 in the matrix.
- [m13](/documentation/quartzcore/catransform3d/m13) The entry at position 1,3 in the matrix.
- [m14](/documentation/quartzcore/catransform3d/m14) The entry at position 1,4 in the matrix.
- [m21](/documentation/quartzcore/catransform3d/m21) The entry at position 2,1 in the matrix.
- [m22](/documentation/quartzcore/catransform3d/m22) The entry at position 2,2 in the matrix.
- [m23](/documentation/quartzcore/catransform3d/m23) The entry at position 2,3 in the matrix.
- [m24](/documentation/quartzcore/catransform3d/m24) The entry at position 2,4 in the matrix.
- [m31](/documentation/quartzcore/catransform3d/m31) The entry at position 3,1 in the matrix.
- [m32](/documentation/quartzcore/catransform3d/m32) The entry at position 3,2 in the matrix.
- [m33](/documentation/quartzcore/catransform3d/m33) The entry at position 3,3 in the matrix.
- [m34](/documentation/quartzcore/catransform3d/m34) The entry at position 3,4 in the matrix.
- [m41](/documentation/quartzcore/catransform3d/m41) The entry at position 4,1 in the matrix.
- [m42](/documentation/quartzcore/catransform3d/m42) The entry at position 4,2 in the matrix.
- [m43](/documentation/quartzcore/catransform3d/m43) The entry at position 4,3 in the matrix.
- [m44](/documentation/quartzcore/catransform3d/m44) The entry at position 4,4 in the matrix.

## Constants

- [CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask) These constants are used by the [autoresizingMask](/documentation/quartzcore/calayer/autoresizingmask) property.
- [Action Identifiers](/documentation/quartzcore/action-identifiers) These constants are the predefined action identifiers used by [action(forKey:)](/documentation/quartzcore/calayer/action(forkey:)), [add(_:forKey:)](/documentation/quartzcore/calayer/add(_:forkey:)), [defaultAction(forKey:)](/documentation/quartzcore/calayer/defaultaction(forkey:)), [removeAnimation(forKey:)](/documentation/quartzcore/calayer/removeanimation(forkey:)), Layer Filters, and the [CAAction](/documentation/quartzcore/caaction) protocol method [run(forKey:object:arguments:)](/documentation/quartzcore/caaction/run(forkey:object:arguments:)).
- [CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask) This mask is used by the [edgeAntialiasingMask](/documentation/quartzcore/calayer/edgeantialiasingmask) property.
- [Identity Transform](/documentation/quartzcore/identity-transform) Defines the identity transform matrix used by Core Animation.
- [Scaling Filters](/documentation/quartzcore/scaling-filters) These constants specify the scaling filters used by [magnificationFilter](/documentation/quartzcore/calayer/magnificationfilter) and [minificationFilter](/documentation/quartzcore/calayer/minificationfilter).
- [CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange)

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
