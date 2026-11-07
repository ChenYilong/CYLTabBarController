---
title: CALayer
description: An object that manages image-based content and allows you to perform animations on that content.
source: https://developer.apple.com/documentation/quartzcore/calayer
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/calayer.json
timestamp: 2026-05-13T20:41:19.971Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CALayer

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> An object that manages image-based content and allows you to perform animations on that content.

```swift
class CALayer
```

## Overview

Layers are often used to provide the backing store for views but can also be used without a view to display content. A layer’s main job is to manage the visual content that you provide but the layer itself has visual attributes that can be set, such as a background color, border, and shadow. In addition to managing visual content, the layer also maintains information about the geometry of its content (such as its position, size, and transform) that is used to present that content onscreen. Modifying the properties of the layer is how you initiate animations on the layer’s content or geometry. A layer object encapsulates the duration and pacing of a layer and its animations by adopting the [CAMediaTiming](/documentation/quartzcore/camediatiming) protocol, which defines the layer’s timing information.

If the layer object was created by a view, the view typically assigns itself as the layer’s delegate automatically, and you should not change that relationship. For layers you create yourself, you can assign a [delegate](/documentation/quartzcore/calayer/delegate) object and use that object to provide the contents of the layer dynamically and perform other tasks. A layer may also have a layout manager object (assigned to the [layoutManager](/documentation/quartzcore/calayer/layoutmanager) property) to manage the layout of subviews separately.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Inherited By

- [CAEAGLLayer](/documentation/quartzcore/caeagllayer)
- [CAEmitterLayer](/documentation/quartzcore/caemitterlayer)
- [CAGradientLayer](/documentation/quartzcore/cagradientlayer)
- [CAMetalLayer](/documentation/quartzcore/cametallayer)
- [CAOpenGLLayer](/documentation/quartzcore/caopengllayer)
- [CAReplicatorLayer](/documentation/quartzcore/careplicatorlayer)
- [CAScrollLayer](/documentation/quartzcore/cascrolllayer)
- [CAShapeLayer](/documentation/quartzcore/cashapelayer)
- [CATextLayer](/documentation/quartzcore/catextlayer)
- [CATiledLayer](/documentation/quartzcore/catiledlayer)
- [CATransformLayer](/documentation/quartzcore/catransformlayer)

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

## Creating a layer

- [init()](/documentation/quartzcore/calayer/init()) Returns an initialized `CALayer` object.
- [init(layer:)](/documentation/quartzcore/calayer/init(layer:)) Override to copy or initialize custom fields of the specified layer.
- [init(remoteClientId:)](/documentation/quartzcore/calayer/init(remoteclientid:)) Initializes a layer with a remote client ID.

## Accessing related layer objects

- [presentation()](/documentation/quartzcore/calayer/presentation()) Returns a copy of the presentation layer object that represents the state of the layer as it currently appears onscreen.
- [model()](/documentation/quartzcore/calayer/model()) Returns the model layer object associated with the receiver, if any.

## Accessing the delegate

- [delegate](/documentation/quartzcore/calayer/delegate) The layer’s delegate object.

## Providing the layer’s content

- [contents](/documentation/quartzcore/calayer/contents) An object that provides the contents of the layer. Animatable.
- [contentsRect](/documentation/quartzcore/calayer/contentsrect) The rectangle, in the unit coordinate space, that defines the portion of the layer’s contents that should be used. Animatable.
- [contentsCenter](/documentation/quartzcore/calayer/contentscenter) The rectangle that defines how the layer contents are scaled if the layer’s contents are resized. Animatable.
- [display()](/documentation/quartzcore/calayer/display()) Reloads the content of this layer.
- [draw(in:)](/documentation/quartzcore/calayer/draw(in:)) Draws the layer’s content using the specified graphics context.

## Modifying the layer’s appearance

- [contentsGravity](/documentation/quartzcore/calayer/contentsgravity) A constant that specifies how the layer’s contents are positioned or scaled within its bounds.
- [Contents Gravity Values](/documentation/quartzcore/contents-gravity-values) The contents gravity constants specify the position of the content object when the layer bounds is larger than the bounds of the content object. They are used by the [contentsGravity](/documentation/quartzcore/calayer/contentsgravity) property.
- [opacity](/documentation/quartzcore/calayer/opacity) The opacity of the receiver. Animatable.
- [isHidden](/documentation/quartzcore/calayer/ishidden) A Boolean indicating whether the layer is displayed. Animatable.
- [masksToBounds](/documentation/quartzcore/calayer/maskstobounds) A Boolean indicating whether sublayers are clipped to the layer’s bounds. Animatable.
- [mask](/documentation/quartzcore/calayer/mask) An optional layer whose alpha channel is used to mask the layer’s content.
- [isDoubleSided](/documentation/quartzcore/calayer/isdoublesided) A Boolean indicating whether the layer displays its content when facing away from the viewer. Animatable.
- [cornerRadius](/documentation/quartzcore/calayer/cornerradius) The radius to use when drawing rounded corners for the layer’s background. Animatable.
- [maskedCorners](/documentation/quartzcore/calayer/maskedcorners)
- [CACornerMask](/documentation/quartzcore/cacornermask)
- [borderWidth](/documentation/quartzcore/calayer/borderwidth) The width of the layer’s border. Animatable.
- [borderColor](/documentation/quartzcore/calayer/bordercolor) The color of the layer’s border. Animatable.
- [backgroundColor](/documentation/quartzcore/calayer/backgroundcolor) The background color of the receiver. Animatable.
- [shadowOpacity](/documentation/quartzcore/calayer/shadowopacity) The opacity of the layer’s shadow. Animatable.
- [shadowRadius](/documentation/quartzcore/calayer/shadowradius) The blur radius (in points) used to render the layer’s shadow. Animatable.
- [shadowOffset](/documentation/quartzcore/calayer/shadowoffset) The offset (in points) of the layer’s shadow. Animatable.
- [shadowColor](/documentation/quartzcore/calayer/shadowcolor) The color of the layer’s shadow. Animatable.
- [shadowPath](/documentation/quartzcore/calayer/shadowpath) The shape of the layer’s shadow. Animatable.
- [style](/documentation/quartzcore/calayer/style) An optional dictionary used to store property values that aren’t explicitly defined by the layer.
- [allowsEdgeAntialiasing](/documentation/quartzcore/calayer/allowsedgeantialiasing) A Boolean indicating whether the layer is allowed to perform edge antialiasing.
- [allowsGroupOpacity](/documentation/quartzcore/calayer/allowsgroupopacity) A Boolean indicating whether the layer is allowed to composite itself as a group separate from its parent.

## Layer filters

- [filters](/documentation/quartzcore/calayer/filters) An array of Core Image filters to apply to the contents of the layer and its sublayers. Animatable.
- [compositingFilter](/documentation/quartzcore/calayer/compositingfilter) A CoreImage filter used to composite the layer and the content behind it. Animatable.
- [backgroundFilters](/documentation/quartzcore/calayer/backgroundfilters) An array of Core Image filters to apply to the content immediately behind the layer. Animatable.
- [minificationFilter](/documentation/quartzcore/calayer/minificationfilter) The filter used when reducing the size of the content.
- [minificationFilterBias](/documentation/quartzcore/calayer/minificationfilterbias) The bias factor used by the minification filter to determine the levels of detail.
- [magnificationFilter](/documentation/quartzcore/calayer/magnificationfilter) The filter used when increasing the size of the content.

## Configuring the layer’s rendering behavior

- [isOpaque](/documentation/quartzcore/calayer/isopaque) A Boolean value indicating whether the layer contains completely opaque content.
- [edgeAntialiasingMask](/documentation/quartzcore/calayer/edgeantialiasingmask) A bitmask defining how the edges of the receiver are rasterized.
- [contentsAreFlipped()](/documentation/quartzcore/calayer/contentsareflipped()) Returns a Boolean indicating whether the layer content is implicitly flipped when rendered.
- [isGeometryFlipped](/documentation/quartzcore/calayer/isgeometryflipped) A Boolean that indicates whether the geometry of the layer and its sublayers is flipped vertically.
- [drawsAsynchronously](/documentation/quartzcore/calayer/drawsasynchronously) A Boolean indicating whether drawing commands are deferred and processed asynchronously in a background thread.
- [shouldRasterize](/documentation/quartzcore/calayer/shouldrasterize) A Boolean that indicates whether the layer is rendered as a bitmap before compositing. Animatable
- [rasterizationScale](/documentation/quartzcore/calayer/rasterizationscale) The scale at which to rasterize content, relative to the coordinate space of the layer. Animatable
- [contentsFormat](/documentation/quartzcore/calayer/contentsformat) A hint for the desired storage format of the layer contents.
- [render(in:)](/documentation/quartzcore/calayer/render(in:)) Renders the layer and its sublayers into the specified context.

## Modifying the layer geometry

- [frame](/documentation/quartzcore/calayer/frame) The layer’s frame rectangle.
- [bounds](/documentation/quartzcore/calayer/bounds) The layer’s bounds rectangle. Animatable.
- [position](/documentation/quartzcore/calayer/position) The layer’s position in its superlayer’s coordinate space. Animatable.
- [zPosition](/documentation/quartzcore/calayer/zposition) The layer’s position on the z axis. Animatable.
- [anchorPointZ](/documentation/quartzcore/calayer/anchorpointz) The anchor point for the layer’s position along the z axis. Animatable.
- [anchorPoint](/documentation/quartzcore/calayer/anchorpoint) Defines the anchor point of the layer’s bounds rectangle. Animatable.
- [contentsScale](/documentation/quartzcore/calayer/contentsscale) The scale factor applied to the layer.

## Managing the layer’s transform

- [transform](/documentation/quartzcore/calayer/transform) The transform applied to the layer’s contents. Animatable.
- [sublayerTransform](/documentation/quartzcore/calayer/sublayertransform) Specifies the transform to apply to sublayers when rendering. Animatable.
- [affineTransform()](/documentation/quartzcore/calayer/affinetransform()) Returns an affine version of the layer’s transform.
- [setAffineTransform(_:)](/documentation/quartzcore/calayer/setaffinetransform(_:)) Sets the layer’s transform to the specified affine transform.

## Managing the layer hierarchy

- [sublayers](/documentation/quartzcore/calayer/sublayers) An array containing the layer’s sublayers.
- [superlayer](/documentation/quartzcore/calayer/superlayer) The superlayer of the layer.
- [addSublayer(_:)](/documentation/quartzcore/calayer/addsublayer(_:)) Appends the layer to the layer’s list of sublayers.
- [removeFromSuperlayer()](/documentation/quartzcore/calayer/removefromsuperlayer()) Detaches the layer from its parent layer.
- [insertSublayer(_:at:)](/documentation/quartzcore/calayer/insertsublayer(_:at:)) Inserts the specified layer into the receiver’s list of sublayers at the specified index.
- [insertSublayer(_:below:)](/documentation/quartzcore/calayer/insertsublayer(_:below:)) Inserts the specified sublayer below a different sublayer that already belongs to the receiver.
- [insertSublayer(_:above:)](/documentation/quartzcore/calayer/insertsublayer(_:above:)) Inserts the specified sublayer above a different sublayer that already belongs to the receiver.
- [replaceSublayer(_:with:)](/documentation/quartzcore/calayer/replacesublayer(_:with:)) Replaces the specified sublayer with a different layer object.

## Updating layer display

- [setNeedsDisplay()](/documentation/quartzcore/calayer/setneedsdisplay()) Marks the layer’s contents as needing to be updated.
- [setNeedsDisplay(_:)](/documentation/quartzcore/calayer/setneedsdisplay(_:)) Marks the region within the specified rectangle as needing to be updated.
- [needsDisplayOnBoundsChange](/documentation/quartzcore/calayer/needsdisplayonboundschange) A Boolean indicating whether the layer contents must be updated when its bounds rectangle changes.
- [displayIfNeeded()](/documentation/quartzcore/calayer/displayifneeded()) Initiates the update process for a layer if it is currently marked as needing an update.
- [needsDisplay()](/documentation/quartzcore/calayer/needsdisplay()) Returns a Boolean indicating whether the layer has been marked as needing an update.
- [needsDisplay(forKey:)](/documentation/quartzcore/calayer/needsdisplay(forkey:)) Returns a Boolean indicating whether changes to the specified key require the layer to be redisplayed.

## Layer animations

- [add(_:forKey:)](/documentation/quartzcore/calayer/add(_:forkey:)) Add the specified animation object to the layer’s render tree.
- [animation(forKey:)](/documentation/quartzcore/calayer/animation(forkey:)) Returns the animation object with the specified identifier.
- [removeAllAnimations()](/documentation/quartzcore/calayer/removeallanimations()) Remove all animations attached to the layer.
- [removeAnimation(forKey:)](/documentation/quartzcore/calayer/removeanimation(forkey:)) Remove the animation object with the specified key.
- [animationKeys()](/documentation/quartzcore/calayer/animationkeys()) Returns an array of strings that identify the animations currently attached to the layer.

## Managing layer resizing and layout

- [layoutManager](/documentation/quartzcore/calayer/layoutmanager) The object responsible for laying out the layer’s sublayers.
- [setNeedsLayout()](/documentation/quartzcore/calayer/setneedslayout()) Invalidates the layer’s layout and marks it as needing an update.
- [layoutSublayers()](/documentation/quartzcore/calayer/layoutsublayers()) Tells the layer to update its layout.
- [layoutIfNeeded()](/documentation/quartzcore/calayer/layoutifneeded()) Recalculate the receiver’s layout, if required.
- [needsLayout()](/documentation/quartzcore/calayer/needslayout()) Returns a Boolean indicating whether the layer has been marked as needing a layout update.
- [autoresizingMask](/documentation/quartzcore/calayer/autoresizingmask) A bitmask defining how the layer is resized when the bounds of its superlayer changes.
- [resize(withOldSuperlayerSize:)](/documentation/quartzcore/calayer/resize(witholdsuperlayersize:)) Informs the receiver that the size of its superlayer changed.
- [resizeSublayers(withOldSize:)](/documentation/quartzcore/calayer/resizesublayers(witholdsize:)) Informs the receiver’s sublayers that the receiver’s size has changed.
- [preferredFrameSize()](/documentation/quartzcore/calayer/preferredframesize()) Returns the preferred size of the layer in the coordinate space of its superlayer.

## Managing layer constraints

- [constraints](/documentation/quartzcore/calayer/constraints) The constraints used to position current layer’s sublayers.
- [addConstraint(_:)](/documentation/quartzcore/calayer/addconstraint(_:)) Adds the specified constraint to the layer.

## Getting the layer’s actions

- [action(forKey:)](/documentation/quartzcore/calayer/action(forkey:)) Returns the action object assigned to the specified key.
- [actions](/documentation/quartzcore/calayer/actions) A dictionary containing layer actions.
- [defaultAction(forKey:)](/documentation/quartzcore/calayer/defaultaction(forkey:)) Returns the default action for the current class.

## Mapping between coordinate and time spaces

- [convert(_:from:)](/documentation/quartzcore/calayer/convert(_:from:)-8kl76) Converts the point from the specified layer’s coordinate system to the receiver’s coordinate system.
- [convert(_:to:)](/documentation/quartzcore/calayer/convert(_:to:)-7dcke) Converts the point from the receiver’s coordinate system to the specified layer’s coordinate system.
- [convert(_:from:)](/documentation/quartzcore/calayer/convert(_:from:)-4kx9l) Converts the rectangle from the specified layer’s coordinate system to the receiver’s coordinate system.
- [convert(_:to:)](/documentation/quartzcore/calayer/convert(_:to:)-tly5) Converts the rectangle from the receiver’s coordinate system to the specified layer’s coordinate system.
- [convertTime(_:from:)](/documentation/quartzcore/calayer/converttime(_:from:)) Converts the time interval from the specified layer’s time space to the receiver’s time space.
- [convertTime(_:to:)](/documentation/quartzcore/calayer/converttime(_:to:)) Converts the time interval from the receiver’s time space to the specified layer’s time space

## Hit testing

- [hitTest(_:)](/documentation/quartzcore/calayer/hittest(_:)) Returns the farthest descendant of the receiver in the layer hierarchy (including itself) that contains the specified point.
- [contains(_:)](/documentation/quartzcore/calayer/contains(_:)) Returns whether the receiver contains a specified point.

## Scrolling

- [visibleRect](/documentation/quartzcore/calayer/visiblerect) The visible region of the layer in its own coordinate space.
- [scroll(_:)](/documentation/quartzcore/calayer/scroll(_:)) Initiates a scroll in the layer’s closest ancestor scroll layer so that the specified point lies at the origin of the scroll layer.
- [scrollRectToVisible(_:)](/documentation/quartzcore/calayer/scrollrecttovisible(_:)) Initiates a scroll in the layer’s closest ancestor scroll layer so that the specified rectangle becomes visible.

## Identifying the layer

- [name](/documentation/quartzcore/calayer/name) The name of the receiver.

## Key-value coding extensions

- [shouldArchiveValue(forKey:)](/documentation/quartzcore/calayer/shouldarchivevalue(forkey:)) Returns a Boolean indicating whether the value of the specified key should be archived.
- [defaultValue(forKey:)](/documentation/quartzcore/calayer/defaultvalue(forkey:)) Specifies the default value associated with the specified key.

## High dynamic range

- [preferredDynamicRange](/documentation/quartzcore/calayer/preferreddynamicrange)
- [contentsHeadroom](/documentation/quartzcore/calayer/contentsheadroom)
- [wantsExtendedDynamicRangeContent](/documentation/quartzcore/calayer/wantsextendeddynamicrangecontent)

## Constants

- [CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask) These constants are used by the [autoresizingMask](/documentation/quartzcore/calayer/autoresizingmask) property.
- [Action Identifiers](/documentation/quartzcore/action-identifiers) These constants are the predefined action identifiers used by [action(forKey:)](/documentation/quartzcore/calayer/action(forkey:)), [add(_:forKey:)](/documentation/quartzcore/calayer/add(_:forkey:)), [defaultAction(forKey:)](/documentation/quartzcore/calayer/defaultaction(forkey:)), [removeAnimation(forKey:)](/documentation/quartzcore/calayer/removeanimation(forkey:)), Layer Filters, and the [CAAction](/documentation/quartzcore/caaction) protocol method [run(forKey:object:arguments:)](/documentation/quartzcore/caaction/run(forkey:object:arguments:)).
- [CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask) This mask is used by the [edgeAntialiasingMask](/documentation/quartzcore/calayer/edgeantialiasingmask) property.
- [Identity Transform](/documentation/quartzcore/identity-transform) Defines the identity transform matrix used by Core Animation.
- [Scaling Filters](/documentation/quartzcore/scaling-filters) These constants specify the scaling filters used by [magnificationFilter](/documentation/quartzcore/calayer/magnificationfilter) and [minificationFilter](/documentation/quartzcore/calayer/minificationfilter).
- [CATransform3D](/documentation/quartzcore/catransform3d) The standard transform matrix used throughout Core Animation.
- [CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange)

## Instance properties

- [cornerCurve](/documentation/quartzcore/calayer/cornercurve)
- [wantsDynamicContentScaling](/documentation/quartzcore/calayer/wantsdynamiccontentscaling)

## Type methods

- [cornerCurveExpansionFactor(_:)](/documentation/quartzcore/calayer/cornercurveexpansionfactor(_:))

## Initializers

- [init(coder:)](/documentation/quartzcore/calayer/init(coder:))

## Instance Properties

- [toneMapMode](/documentation/quartzcore/calayer/tonemapmode-swift.property)

## Layer Basics

- [CALayerDelegate](/documentation/quartzcore/calayerdelegate) Methods your app can implement to respond to layer-related events.
- [CAConstraint](/documentation/quartzcore/caconstraint) A representation of a single layout constraint between two layers.
- [CALayoutManager](/documentation/quartzcore/calayoutmanager) Methods that allow an object to manage the layout of a layer and its sublayers.
- [CAConstraintLayoutManager](/documentation/quartzcore/caconstraintlayoutmanager) An object that provides a constraint-based layout manager.
- [CAAction](/documentation/quartzcore/caaction) An interface that allows instances to respond to actions triggered by a Core Animation layer change.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
