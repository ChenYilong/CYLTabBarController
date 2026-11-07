---
title: Core Animation
source: https://developer.apple.com/documentation/quartzcore
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/index/quartzcore
timestamp: 2026-05-13T20:40:21.941Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

## Layer Basics

- [CALayer](/documentation/quartzcore/calayer)
### Creating a layer

- [init()](/documentation/quartzcore/calayer/init())
- [init(layer: Any)](/documentation/quartzcore/calayer/init(layer:))
- [init(remoteClientId: UInt32)](/documentation/quartzcore/calayer/init(remoteclientid:))
### Accessing related layer objects

- [func presentation() -> Self?](/documentation/quartzcore/calayer/presentation())
- [func model() -> Self](/documentation/quartzcore/calayer/model())
### Accessing the delegate

- [var delegate: (any CALayerDelegate)?](/documentation/quartzcore/calayer/delegate)
### Providing the layer’s content

- [var contents: Any?](/documentation/quartzcore/calayer/contents)
- [var contentsRect: CGRect](/documentation/quartzcore/calayer/contentsrect)
- [var contentsCenter: CGRect](/documentation/quartzcore/calayer/contentscenter)
- [func display()](/documentation/quartzcore/calayer/display())
- [func draw(in: CGContext)](/documentation/quartzcore/calayer/draw(in:))
### Modifying the layer’s appearance

- [var contentsGravity: CALayerContentsGravity](/documentation/quartzcore/calayer/contentsgravity)
- [Contents Gravity Values](/documentation/quartzcore/contents-gravity-values)
#### Constants

- [static let center: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/center)
- [static let top: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/top)
- [static let bottom: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/bottom)
- [static let left: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/left)
- [static let right: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/right)
- [static let topLeft: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/topleft)
- [static let topRight: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/topright)
- [static let bottomLeft: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/bottomleft)
- [static let bottomRight: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/bottomright)
- [static let resize: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/resize)
- [static let resizeAspect: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/resizeaspect)
- [static let resizeAspectFill: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/resizeaspectfill)

- [var opacity: Float](/documentation/quartzcore/calayer/opacity)
- [var isHidden: Bool](/documentation/quartzcore/calayer/ishidden)
- [var masksToBounds: Bool](/documentation/quartzcore/calayer/maskstobounds)
- [var mask: CALayer?](/documentation/quartzcore/calayer/mask)
- [var isDoubleSided: Bool](/documentation/quartzcore/calayer/isdoublesided)
- [var cornerRadius: CGFloat](/documentation/quartzcore/calayer/cornerradius)
- [var maskedCorners: CACornerMask](/documentation/quartzcore/calayer/maskedcorners)
- [CACornerMask](/documentation/quartzcore/cacornermask)
#### Constants

- [init(rawValue: UInt)](/documentation/quartzcore/cacornermask/init(rawvalue:))
- [static var layerMaxXMaxYCorner: CACornerMask](/documentation/quartzcore/cacornermask/layermaxxmaxycorner)
- [static var layerMaxXMinYCorner: CACornerMask](/documentation/quartzcore/cacornermask/layermaxxminycorner)
- [static var layerMinXMaxYCorner: CACornerMask](/documentation/quartzcore/cacornermask/layerminxmaxycorner)
- [static var layerMinXMinYCorner: CACornerMask](/documentation/quartzcore/cacornermask/layerminxminycorner)

- [var borderWidth: CGFloat](/documentation/quartzcore/calayer/borderwidth)
- [var borderColor: CGColor?](/documentation/quartzcore/calayer/bordercolor)
- [var backgroundColor: CGColor?](/documentation/quartzcore/calayer/backgroundcolor)
- [var shadowOpacity: Float](/documentation/quartzcore/calayer/shadowopacity)
- [var shadowRadius: CGFloat](/documentation/quartzcore/calayer/shadowradius)
- [var shadowOffset: CGSize](/documentation/quartzcore/calayer/shadowoffset)
- [var shadowColor: CGColor?](/documentation/quartzcore/calayer/shadowcolor)
- [var shadowPath: CGPath?](/documentation/quartzcore/calayer/shadowpath)
- [var style: [AnyHashable : Any]?](/documentation/quartzcore/calayer/style)
- [var allowsEdgeAntialiasing: Bool](/documentation/quartzcore/calayer/allowsedgeantialiasing)
- [var allowsGroupOpacity: Bool](/documentation/quartzcore/calayer/allowsgroupopacity)
### Layer filters

- [var filters: [Any]?](/documentation/quartzcore/calayer/filters)
- [var compositingFilter: Any?](/documentation/quartzcore/calayer/compositingfilter)
- [var backgroundFilters: [Any]?](/documentation/quartzcore/calayer/backgroundfilters)
- [var minificationFilter: CALayerContentsFilter](/documentation/quartzcore/calayer/minificationfilter)
- [var minificationFilterBias: Float](/documentation/quartzcore/calayer/minificationfilterbias)
- [var magnificationFilter: CALayerContentsFilter](/documentation/quartzcore/calayer/magnificationfilter)
### Configuring the layer’s rendering behavior

- [var isOpaque: Bool](/documentation/quartzcore/calayer/isopaque)
- [var edgeAntialiasingMask: CAEdgeAntialiasingMask](/documentation/quartzcore/calayer/edgeantialiasingmask)
- [func contentsAreFlipped() -> Bool](/documentation/quartzcore/calayer/contentsareflipped())
- [var isGeometryFlipped: Bool](/documentation/quartzcore/calayer/isgeometryflipped)
- [var drawsAsynchronously: Bool](/documentation/quartzcore/calayer/drawsasynchronously)
- [var shouldRasterize: Bool](/documentation/quartzcore/calayer/shouldrasterize)
- [var rasterizationScale: CGFloat](/documentation/quartzcore/calayer/rasterizationscale)
- [var contentsFormat: CALayerContentsFormat](/documentation/quartzcore/calayer/contentsformat)
- [func render(in: CGContext)](/documentation/quartzcore/calayer/render(in:))
### Modifying the layer geometry

- [var frame: CGRect](/documentation/quartzcore/calayer/frame)
- [var bounds: CGRect](/documentation/quartzcore/calayer/bounds)
- [var position: CGPoint](/documentation/quartzcore/calayer/position)
- [var zPosition: CGFloat](/documentation/quartzcore/calayer/zposition)
- [var anchorPointZ: CGFloat](/documentation/quartzcore/calayer/anchorpointz)
- [var anchorPoint: CGPoint](/documentation/quartzcore/calayer/anchorpoint)
- [var contentsScale: CGFloat](/documentation/quartzcore/calayer/contentsscale)
### Managing the layer’s transform

- [var transform: CATransform3D](/documentation/quartzcore/calayer/transform)
- [var sublayerTransform: CATransform3D](/documentation/quartzcore/calayer/sublayertransform)
- [func affineTransform() -> CGAffineTransform](/documentation/quartzcore/calayer/affinetransform())
- [func setAffineTransform(CGAffineTransform)](/documentation/quartzcore/calayer/setaffinetransform(_:))
### Managing the layer hierarchy

- [var sublayers: [CALayer]?](/documentation/quartzcore/calayer/sublayers)
- [var superlayer: CALayer?](/documentation/quartzcore/calayer/superlayer)
- [func addSublayer(CALayer)](/documentation/quartzcore/calayer/addsublayer(_:))
- [func removeFromSuperlayer()](/documentation/quartzcore/calayer/removefromsuperlayer())
- [func insertSublayer(CALayer, at: UInt32)](/documentation/quartzcore/calayer/insertsublayer(_:at:))
- [func insertSublayer(CALayer, below: CALayer?)](/documentation/quartzcore/calayer/insertsublayer(_:below:))
- [func insertSublayer(CALayer, above: CALayer?)](/documentation/quartzcore/calayer/insertsublayer(_:above:))
- [func replaceSublayer(CALayer, with: CALayer)](/documentation/quartzcore/calayer/replacesublayer(_:with:))
### Updating layer display

- [func setNeedsDisplay()](/documentation/quartzcore/calayer/setneedsdisplay())
- [func setNeedsDisplay(CGRect)](/documentation/quartzcore/calayer/setneedsdisplay(_:))
- [var needsDisplayOnBoundsChange: Bool](/documentation/quartzcore/calayer/needsdisplayonboundschange)
- [func displayIfNeeded()](/documentation/quartzcore/calayer/displayifneeded())
- [func needsDisplay() -> Bool](/documentation/quartzcore/calayer/needsdisplay())
- [class func needsDisplay(forKey: String) -> Bool](/documentation/quartzcore/calayer/needsdisplay(forkey:))
### Layer animations

- [func add(CAAnimation, forKey: String?)](/documentation/quartzcore/calayer/add(_:forkey:))
- [func animation(forKey: String) -> CAAnimation?](/documentation/quartzcore/calayer/animation(forkey:))
- [func removeAllAnimations()](/documentation/quartzcore/calayer/removeallanimations())
- [func removeAnimation(forKey: String)](/documentation/quartzcore/calayer/removeanimation(forkey:))
- [func animationKeys() -> [String]?](/documentation/quartzcore/calayer/animationkeys())
### Managing layer resizing and layout

- [var layoutManager: (any CALayoutManager)?](/documentation/quartzcore/calayer/layoutmanager)
- [func setNeedsLayout()](/documentation/quartzcore/calayer/setneedslayout())
- [func layoutSublayers()](/documentation/quartzcore/calayer/layoutsublayers())
- [func layoutIfNeeded()](/documentation/quartzcore/calayer/layoutifneeded())
- [func needsLayout() -> Bool](/documentation/quartzcore/calayer/needslayout())
- [var autoresizingMask: CAAutoresizingMask](/documentation/quartzcore/calayer/autoresizingmask)
- [func resize(withOldSuperlayerSize: CGSize)](/documentation/quartzcore/calayer/resize(witholdsuperlayersize:))
- [func resizeSublayers(withOldSize: CGSize)](/documentation/quartzcore/calayer/resizesublayers(witholdsize:))
- [func preferredFrameSize() -> CGSize](/documentation/quartzcore/calayer/preferredframesize())
### Managing layer constraints

- [var constraints: [CAConstraint]?](/documentation/quartzcore/calayer/constraints)
- [func addConstraint(CAConstraint)](/documentation/quartzcore/calayer/addconstraint(_:))
### Getting the layer’s actions

- [func action(forKey: String) -> (any CAAction)?](/documentation/quartzcore/calayer/action(forkey:))
- [var actions: [String : any CAAction]?](/documentation/quartzcore/calayer/actions)
- [class func defaultAction(forKey: String) -> (any CAAction)?](/documentation/quartzcore/calayer/defaultaction(forkey:))
### Mapping between coordinate and time spaces

- [func convert(CGPoint, from: CALayer?) -> CGPoint](/documentation/quartzcore/calayer/convert(_:from:)-8kl76)
- [func convert(CGPoint, to: CALayer?) -> CGPoint](/documentation/quartzcore/calayer/convert(_:to:)-7dcke)
- [func convert(CGRect, from: CALayer?) -> CGRect](/documentation/quartzcore/calayer/convert(_:from:)-4kx9l)
- [func convert(CGRect, to: CALayer?) -> CGRect](/documentation/quartzcore/calayer/convert(_:to:)-tly5)
- [func convertTime(CFTimeInterval, from: CALayer?) -> CFTimeInterval](/documentation/quartzcore/calayer/converttime(_:from:))
- [func convertTime(CFTimeInterval, to: CALayer?) -> CFTimeInterval](/documentation/quartzcore/calayer/converttime(_:to:))
### Hit testing

- [func hitTest(CGPoint) -> CALayer?](/documentation/quartzcore/calayer/hittest(_:))
- [func contains(CGPoint) -> Bool](/documentation/quartzcore/calayer/contains(_:))
### Scrolling

- [var visibleRect: CGRect](/documentation/quartzcore/calayer/visiblerect)
- [func scroll(CGPoint)](/documentation/quartzcore/calayer/scroll(_:))
- [func scrollRectToVisible(CGRect)](/documentation/quartzcore/calayer/scrollrecttovisible(_:))
### Identifying the layer

- [var name: String?](/documentation/quartzcore/calayer/name)
### Key-value coding extensions

- [func shouldArchiveValue(forKey: String) -> Bool](/documentation/quartzcore/calayer/shouldarchivevalue(forkey:))
- [class func defaultValue(forKey: String) -> Any?](/documentation/quartzcore/calayer/defaultvalue(forkey:))
### High dynamic range

- [var preferredDynamicRange: CALayer.DynamicRange](/documentation/quartzcore/calayer/preferreddynamicrange)
- [var contentsHeadroom: CGFloat](/documentation/quartzcore/calayer/contentsheadroom)
- [var wantsExtendedDynamicRangeContent: Bool](/documentation/quartzcore/calayer/wantsextendeddynamicrangecontent)
### Constants

- [CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask)
#### Constants

- [init(rawValue: UInt32)](/documentation/quartzcore/caautoresizingmask/init(rawvalue:))
- [static var layerMinXMargin: CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask/layerminxmargin)
- [static var layerWidthSizable: CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask/layerwidthsizable)
- [static var layerMaxXMargin: CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask/layermaxxmargin)
- [static var layerMinYMargin: CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask/layerminymargin)
- [static var layerHeightSizable: CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask/layerheightsizable)
- [static var layerMaxYMargin: CAAutoresizingMask](/documentation/quartzcore/caautoresizingmask/layermaxymargin)

- [Action Identifiers](/documentation/quartzcore/action-identifiers)
#### Constants

- [let kCAOnOrderIn: String](/documentation/quartzcore/kcaonorderin)
- [let kCAOnOrderOut: String](/documentation/quartzcore/kcaonorderout)
- [let kCATransition: String](/documentation/quartzcore/kcatransition)

- [CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask)
#### Constants

- [init(rawValue: UInt32)](/documentation/quartzcore/caedgeantialiasingmask/init(rawvalue:))
- [static var layerLeftEdge: CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask/layerleftedge)
- [static var layerRightEdge: CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask/layerrightedge)
- [static var layerBottomEdge: CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask/layerbottomedge)
- [static var layerTopEdge: CAEdgeAntialiasingMask](/documentation/quartzcore/caedgeantialiasingmask/layertopedge)

- [Identity Transform](/documentation/quartzcore/identity-transform)
#### Constants

- [let CATransform3DIdentity: CATransform3D](/documentation/quartzcore/catransform3didentity)

- [Scaling Filters](/documentation/quartzcore/scaling-filters)
#### Constants

- [static let linear: CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter/linear)
- [static let nearest: CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter/nearest)
- [static let trilinear: CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter/trilinear)

- [CATransform3D](/documentation/quartzcore/catransform3d)
#### Initializers

- [init()](/documentation/quartzcore/catransform3d/init())
- [init(m11: CGFloat, m12: CGFloat, m13: CGFloat, m14: CGFloat, m21: CGFloat, m22: CGFloat, m23: CGFloat, m24: CGFloat, m31: CGFloat, m32: CGFloat, m33: CGFloat, m34: CGFloat, m41: CGFloat, m42: CGFloat, m43: CGFloat, m44: CGFloat)](/documentation/quartzcore/catransform3d/init(m11:m12:m13:m14:m21:m22:m23:m24:m31:m32:m33:m34:m41:m42:m43:m44:))
- [init(float4x4)](/documentation/quartzcore/catransform3d/init(_:)-6awvy)
- [init(double4x4)](/documentation/quartzcore/catransform3d/init(_:)-6euzs)
#### Instance Properties

- [var m11: CGFloat](/documentation/quartzcore/catransform3d/m11)
- [var m12: CGFloat](/documentation/quartzcore/catransform3d/m12)
- [var m13: CGFloat](/documentation/quartzcore/catransform3d/m13)
- [var m14: CGFloat](/documentation/quartzcore/catransform3d/m14)
- [var m21: CGFloat](/documentation/quartzcore/catransform3d/m21)
- [var m22: CGFloat](/documentation/quartzcore/catransform3d/m22)
- [var m23: CGFloat](/documentation/quartzcore/catransform3d/m23)
- [var m24: CGFloat](/documentation/quartzcore/catransform3d/m24)
- [var m31: CGFloat](/documentation/quartzcore/catransform3d/m31)
- [var m32: CGFloat](/documentation/quartzcore/catransform3d/m32)
- [var m33: CGFloat](/documentation/quartzcore/catransform3d/m33)
- [var m34: CGFloat](/documentation/quartzcore/catransform3d/m34)
- [var m41: CGFloat](/documentation/quartzcore/catransform3d/m41)
- [var m42: CGFloat](/documentation/quartzcore/catransform3d/m42)
- [var m43: CGFloat](/documentation/quartzcore/catransform3d/m43)
- [var m44: CGFloat](/documentation/quartzcore/catransform3d/m44)

- [CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange)
#### Constants

- [static let automatic: CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange/automatic)
- [static let standard: CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange/standard)
- [static let constrainedHigh: CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange/constrainedhigh)
- [static let high: CALayer.DynamicRange](/documentation/quartzcore/calayer/dynamicrange/high)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/calayer/dynamicrange/init(rawvalue:))

### Instance properties

- [var cornerCurve: CALayerCornerCurve](/documentation/quartzcore/calayer/cornercurve)
- [var wantsDynamicContentScaling: Bool](/documentation/quartzcore/calayer/wantsdynamiccontentscaling)
### Type methods

- [class func cornerCurveExpansionFactor(CALayerCornerCurve) -> CGFloat](/documentation/quartzcore/calayer/cornercurveexpansionfactor(_:))
### Initializers

- [init?(coder: NSCoder)](/documentation/quartzcore/calayer/init(coder:))
### Instance Properties

- [var toneMapMode: CALayer.ToneMapMode](/documentation/quartzcore/calayer/tonemapmode-swift.property)

- [CALayerDelegate](/documentation/quartzcore/calayerdelegate)
### Providing the Layer’s Content

- [func display(CALayer)](/documentation/quartzcore/calayerdelegate/display(_:))
- [func draw(CALayer, in: CGContext)](/documentation/quartzcore/calayerdelegate/draw(_:in:))
- [func layerWillDraw(CALayer)](/documentation/quartzcore/calayerdelegate/layerwilldraw(_:))
### Laying Out Sublayers

- [func layoutSublayers(of: CALayer)](/documentation/quartzcore/calayerdelegate/layoutsublayers(of:))
### Providing a Layer’s Actions

- [func action(for: CALayer, forKey: String) -> (any CAAction)?](/documentation/quartzcore/calayerdelegate/action(for:forkey:))

- [CAConstraint](/documentation/quartzcore/caconstraint)
### Create a New Constraint

- [convenience init(attribute: CAConstraintAttribute, relativeTo: String, attribute: CAConstraintAttribute, offset: CGFloat)](/documentation/quartzcore/caconstraint/init(attribute:relativeto:attribute:offset:))
- [convenience init(attribute: CAConstraintAttribute, relativeTo: String, attribute: CAConstraintAttribute)](/documentation/quartzcore/caconstraint/init(attribute:relativeto:attribute:))
- [init(attribute: CAConstraintAttribute, relativeTo: String, attribute: CAConstraintAttribute, scale: CGFloat, offset: CGFloat)](/documentation/quartzcore/caconstraint/init(attribute:relativeto:attribute:scale:offset:))
### Accessing Constraint Values

- [var attribute: CAConstraintAttribute](/documentation/quartzcore/caconstraint/attribute)
- [var offset: CGFloat](/documentation/quartzcore/caconstraint/offset)
- [var scale: CGFloat](/documentation/quartzcore/caconstraint/scale)
- [var sourceAttribute: CAConstraintAttribute](/documentation/quartzcore/caconstraint/sourceattribute)
- [var sourceName: String](/documentation/quartzcore/caconstraint/sourcename)
### Constants

- [CAConstraintAttribute](/documentation/quartzcore/caconstraintattribute)
#### Enumeration Cases

- [case height](/documentation/quartzcore/caconstraintattribute/height)
- [case maxX](/documentation/quartzcore/caconstraintattribute/maxx)
- [case maxY](/documentation/quartzcore/caconstraintattribute/maxy)
- [case midX](/documentation/quartzcore/caconstraintattribute/midx)
- [case midY](/documentation/quartzcore/caconstraintattribute/midy)
- [case minX](/documentation/quartzcore/caconstraintattribute/minx)
- [case minY](/documentation/quartzcore/caconstraintattribute/miny)
- [case width](/documentation/quartzcore/caconstraintattribute/width)
#### Initializers

- [init?(rawValue: Int32)](/documentation/quartzcore/caconstraintattribute/init(rawvalue:))

### Initializers

- [init?(coder: NSCoder)](/documentation/quartzcore/caconstraint/init(coder:))

- [CALayoutManager](/documentation/quartzcore/calayoutmanager)
### Managing Layout

- [func invalidateLayout(of: CALayer)](/documentation/quartzcore/calayoutmanager/invalidatelayout(of:))
- [func layoutSublayers(of: CALayer)](/documentation/quartzcore/calayoutmanager/layoutsublayers(of:))
- [func preferredSize(of: CALayer) -> CGSize](/documentation/quartzcore/calayoutmanager/preferredsize(of:))

- [CAConstraintLayoutManager](/documentation/quartzcore/caconstraintlayoutmanager)
- [CAAction](/documentation/quartzcore/caaction)
### Responding to an action

- [func run(forKey: String, object: Any, arguments: [AnyHashable : Any]?)](/documentation/quartzcore/caaction/run(forkey:object:arguments:))

## Text, Shapes, and Gradients

- [CATextLayer](/documentation/quartzcore/catextlayer)
### Getting and Setting the Text

- [var string: Any?](/documentation/quartzcore/catextlayer/string)
### Text Visual Properties

- [var font: CFTypeRef?](/documentation/quartzcore/catextlayer/font)
- [var fontSize: CGFloat](/documentation/quartzcore/catextlayer/fontsize)
- [var foregroundColor: CGColor?](/documentation/quartzcore/catextlayer/foregroundcolor)
- [var allowsFontSubpixelQuantization: Bool](/documentation/quartzcore/catextlayer/allowsfontsubpixelquantization)
### Text Alignment and Truncation

- [var isWrapped: Bool](/documentation/quartzcore/catextlayer/iswrapped)
- [var alignmentMode: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayer/alignmentmode)
- [var truncationMode: CATextLayerTruncationMode](/documentation/quartzcore/catextlayer/truncationmode)
### Constants

- [Truncation modes](/documentation/quartzcore/truncation-modes)
#### Constants

- [static let none: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/none)
- [static let start: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/start)
- [static let end: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/end)
- [static let middle: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/middle)

- [Horizontal alignment modes](/documentation/quartzcore/horizontal-alignment-modes)
#### Constants

- [static let natural: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/natural)
- [static let left: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/left)
- [static let right: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/right)
- [static let center: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/center)
- [static let justified: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/justified)


- [CAShapeLayer](/documentation/quartzcore/cashapelayer)
### Specifying the Shape Path

- [var path: CGPath?](/documentation/quartzcore/cashapelayer/path)
### Accessing Shape Style Properties

- [var fillColor: CGColor?](/documentation/quartzcore/cashapelayer/fillcolor)
- [var fillRule: CAShapeLayerFillRule](/documentation/quartzcore/cashapelayer/fillrule)
- [var lineCap: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayer/linecap)
- [var lineDashPattern: [NSNumber]?](/documentation/quartzcore/cashapelayer/linedashpattern)
- [var lineDashPhase: CGFloat](/documentation/quartzcore/cashapelayer/linedashphase)
- [var lineJoin: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayer/linejoin)
- [var lineWidth: CGFloat](/documentation/quartzcore/cashapelayer/linewidth)
- [var miterLimit: CGFloat](/documentation/quartzcore/cashapelayer/miterlimit)
- [var strokeColor: CGColor?](/documentation/quartzcore/cashapelayer/strokecolor)
- [var strokeStart: CGFloat](/documentation/quartzcore/cashapelayer/strokestart)
- [var strokeEnd: CGFloat](/documentation/quartzcore/cashapelayer/strokeend)
### Constants

- [Shape Fill Mode Values](/documentation/quartzcore/shape-fill-mode-values)
#### Constants

- [static let nonZero: CAShapeLayerFillRule](/documentation/quartzcore/cashapelayerfillrule/nonzero)
- [static let evenOdd: CAShapeLayerFillRule](/documentation/quartzcore/cashapelayerfillrule/evenodd)

- [Line Join Values](/documentation/quartzcore/line-join-values)
#### Constants

- [static let miter: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin/miter)
- [static let round: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin/round)
- [static let bevel: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin/bevel)

- [Line Cap Values](/documentation/quartzcore/line-cap-values)
#### Constants

- [static let butt: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap/butt)
- [static let round: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap/round)
- [static let square: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap/square)


- [CAGradientLayer](/documentation/quartzcore/cagradientlayer)
### Gradient Style Properties

- [var colors: [Any]?](/documentation/quartzcore/cagradientlayer/colors)
- [var locations: [NSNumber]?](/documentation/quartzcore/cagradientlayer/locations)
- [var endPoint: CGPoint](/documentation/quartzcore/cagradientlayer/endpoint)
- [var startPoint: CGPoint](/documentation/quartzcore/cagradientlayer/startpoint)
- [var type: CAGradientLayerType](/documentation/quartzcore/cagradientlayer/type)
### Constants

- [Gradient Types](/documentation/quartzcore/gradient-types)
#### Constants

- [static let axial: CAGradientLayerType](/documentation/quartzcore/cagradientlayertype/axial)


## Animation

- [CAAnimation](/documentation/quartzcore/caanimation)
### Creating an Animation

- [init(SCNAnimation: SCNAnimation)](/documentation/quartzcore/caanimation/init(scnanimation:))
### Animation Attributes

- [var isRemovedOnCompletion: Bool](/documentation/quartzcore/caanimation/isremovedoncompletion)
- [var timingFunction: CAMediaTimingFunction?](/documentation/quartzcore/caanimation/timingfunction)
### Providing Default Values

- [class func defaultValue(forKey: String) -> Any?](/documentation/quartzcore/caanimation/defaultvalue(forkey:))
### Designating a Delegate

- [var delegate: (any CAAnimationDelegate)?](/documentation/quartzcore/caanimation/delegate)
### Archiving Properties

- [func shouldArchiveValue(forKey: String) -> Bool](/documentation/quartzcore/caanimation/shouldarchivevalue(forkey:))
### Controlling SceneKit Animation Timing

- [var usesSceneTimeBase: Bool](/documentation/quartzcore/caanimation/usesscenetimebase)
### Fading between SceneKit Animations

- [var fadeInDuration: CGFloat](/documentation/quartzcore/caanimation/fadeinduration)
- [var fadeOutDuration: CGFloat](/documentation/quartzcore/caanimation/fadeoutduration)
### Attaching SceneKit Animation Events

- [var animationEvents: [SCNAnimationEvent]?](/documentation/quartzcore/caanimation/animationevents)
### Initializers

- [init(SCNAnimation: SCNAnimation)](/documentation/quartzcore/caanimation/init(scnanimation:))
- [init?(coder: NSCoder)](/documentation/quartzcore/caanimation/init(coder:))
### Instance Properties

- [var preferredFrameRateRange: CAFrameRateRange](/documentation/quartzcore/caanimation/preferredframeraterange)

- [CAAnimationDelegate](/documentation/quartzcore/caanimationdelegate)
### Customizing Start and Stop Times

- [func animationDidStart(CAAnimation)](/documentation/quartzcore/caanimationdelegate/animationdidstart(_:))
- [func animationDidStop(CAAnimation, finished: Bool)](/documentation/quartzcore/caanimationdelegate/animationdidstop(_:finished:))

- [CAPropertyAnimation](/documentation/quartzcore/capropertyanimation)
### Animated Key Path

- [var keyPath: String?](/documentation/quartzcore/capropertyanimation/keypath)
### Property Value Calculation Behavior

- [var isCumulative: Bool](/documentation/quartzcore/capropertyanimation/iscumulative)
- [var isAdditive: Bool](/documentation/quartzcore/capropertyanimation/isadditive)
- [var valueFunction: CAValueFunction?](/documentation/quartzcore/capropertyanimation/valuefunction)
### Creating an Animation

- [convenience init(keyPath: String?)](/documentation/quartzcore/capropertyanimation/init(keypath:))

- [CABasicAnimation](/documentation/quartzcore/cabasicanimation)
### Interpolation values

- [var fromValue: Any?](/documentation/quartzcore/cabasicanimation/fromvalue)
- [var toValue: Any?](/documentation/quartzcore/cabasicanimation/tovalue)
- [var byValue: Any?](/documentation/quartzcore/cabasicanimation/byvalue)

- [CAKeyframeAnimation](/documentation/quartzcore/cakeyframeanimation)
### Providing keyframe values

- [var values: [Any]?](/documentation/quartzcore/cakeyframeanimation/values)
- [var path: CGPath?](/documentation/quartzcore/cakeyframeanimation/path)
### Keyframe timing

- [var keyTimes: [NSNumber]?](/documentation/quartzcore/cakeyframeanimation/keytimes)
- [var timingFunctions: [CAMediaTimingFunction]?](/documentation/quartzcore/cakeyframeanimation/timingfunctions)
- [var calculationMode: CAAnimationCalculationMode](/documentation/quartzcore/cakeyframeanimation/calculationmode)
### Rotation Mode Attribute

- [var rotationMode: CAAnimationRotationMode?](/documentation/quartzcore/cakeyframeanimation/rotationmode)
### Cubic Mode Attributes

- [var tensionValues: [NSNumber]?](/documentation/quartzcore/cakeyframeanimation/tensionvalues)
- [var continuityValues: [NSNumber]?](/documentation/quartzcore/cakeyframeanimation/continuityvalues)
- [var biasValues: [NSNumber]?](/documentation/quartzcore/cakeyframeanimation/biasvalues)
### Constants

- [Rotation Mode Values](/documentation/quartzcore/rotation-mode-values)
#### Constants

- [static let rotateAuto: CAAnimationRotationMode](/documentation/quartzcore/caanimationrotationmode/rotateauto)
- [static let rotateAutoReverse: CAAnimationRotationMode](/documentation/quartzcore/caanimationrotationmode/rotateautoreverse)

- [Value calculation modes](/documentation/quartzcore/value-calculation-modes)
#### Constants

- [static let linear: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/linear)
- [static let discrete: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/discrete)
- [static let paced: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/paced)
- [static let cubic: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/cubic)
- [static let cubicPaced: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/cubicpaced)


- [CASpringAnimation](/documentation/quartzcore/caspringanimation)
### Configuring Physical Attributes

- [var damping: CGFloat](/documentation/quartzcore/caspringanimation/damping)
- [var initialVelocity: CGFloat](/documentation/quartzcore/caspringanimation/initialvelocity)
- [var mass: CGFloat](/documentation/quartzcore/caspringanimation/mass)
- [var settlingDuration: CFTimeInterval](/documentation/quartzcore/caspringanimation/settlingduration)
- [var stiffness: CGFloat](/documentation/quartzcore/caspringanimation/stiffness)
### Initializers

- [init(perceptualDuration: CFTimeInterval, bounce: CGFloat)](/documentation/quartzcore/caspringanimation/init(perceptualduration:bounce:))
### Instance Properties

- [var allowsOverdamping: Bool](/documentation/quartzcore/caspringanimation/allowsoverdamping)
- [var bounce: CGFloat](/documentation/quartzcore/caspringanimation/bounce)
- [var perceptualDuration: CFTimeInterval](/documentation/quartzcore/caspringanimation/perceptualduration)

- [CATransition](/documentation/quartzcore/catransition)
### Transition start and end point

- [var startProgress: Float](/documentation/quartzcore/catransition/startprogress)
- [var endProgress: Float](/documentation/quartzcore/catransition/endprogress)
### Transition Properties

- [var type: CATransitionType](/documentation/quartzcore/catransition/type)
- [var subtype: CATransitionSubtype?](/documentation/quartzcore/catransition/subtype)
### Custom transition filter

- [var filter: Any?](/documentation/quartzcore/catransition/filter)
### Constants

- [Common Transition Types](/documentation/quartzcore/common-transition-types)
#### Constants

- [static let fade: CATransitionType](/documentation/quartzcore/catransitiontype/fade)
- [static let moveIn: CATransitionType](/documentation/quartzcore/catransitiontype/movein)
- [static let push: CATransitionType](/documentation/quartzcore/catransitiontype/push)
- [static let reveal: CATransitionType](/documentation/quartzcore/catransitiontype/reveal)

- [Common Transition Subtypes](/documentation/quartzcore/common-transition-subtypes)
#### Constants

- [static let fromRight: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/fromright)
- [static let fromLeft: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/fromleft)
- [static let fromTop: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/fromtop)
- [static let fromBottom: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/frombottom)


- [CAValueFunction](/documentation/quartzcore/cavaluefunction)
### Getting Value Function Properties

- [var name: CAValueFunctionName](/documentation/quartzcore/cavaluefunction/name)
### Creating and Initializing Value Functions

- [convenience init?(name: CAValueFunctionName)](/documentation/quartzcore/cavaluefunction/init(name:))
### Constants

- [Rotate Value Functions](/documentation/quartzcore/rotate-value-functions)
#### Constants

- [static let rotateX: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/rotatex)
- [static let rotateY: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/rotatey)
- [static let rotateZ: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/rotatez)

- [Scale Value Functions](/documentation/quartzcore/scale-value-functions)
#### Constants

- [static let scale: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scale)
- [static let scaleX: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scalex)
- [static let scaleY: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scaley)
- [static let scaleZ: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scalez)

- [Translate Functions](/documentation/quartzcore/translate-functions)
#### Constants

- [static let translate: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translate)
- [static let translateX: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translatex)
- [static let translateY: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translatey)
- [static let translateZ: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translatez)

### Initializers

- [init?(coder: NSCoder)](/documentation/quartzcore/cavaluefunction/init(coder:))

## Animation Groups

- [CAAnimationGroup](/documentation/quartzcore/caanimationgroup)
### Grouped animations

- [var animations: [CAAnimation]?](/documentation/quartzcore/caanimationgroup/animations)

- [CATransaction](/documentation/quartzcore/catransaction)
### Creating and Committing Transactions

- [class func begin()](/documentation/quartzcore/catransaction/begin())
- [class func commit()](/documentation/quartzcore/catransaction/commit())
- [class func flush()](/documentation/quartzcore/catransaction/flush())
### Overriding Animation Duration and Timing

- [class func animationDuration() -> CFTimeInterval](/documentation/quartzcore/catransaction/animationduration())
- [class func setAnimationDuration(CFTimeInterval)](/documentation/quartzcore/catransaction/setanimationduration(_:))
- [class func animationTimingFunction() -> CAMediaTimingFunction?](/documentation/quartzcore/catransaction/animationtimingfunction())
- [class func setAnimationTimingFunction(CAMediaTimingFunction?)](/documentation/quartzcore/catransaction/setanimationtimingfunction(_:))
### Temporarily Disabling Property Animations

- [class func disableActions() -> Bool](/documentation/quartzcore/catransaction/disableactions())
- [class func setDisableActions(Bool)](/documentation/quartzcore/catransaction/setdisableactions(_:))
### Getting and Setting Completion Block Objects

- [class func completionBlock() -> (() -> Void)?](/documentation/quartzcore/catransaction/completionblock())
- [class func setCompletionBlock((() -> Void)?)](/documentation/quartzcore/catransaction/setcompletionblock(_:))
### Managing Concurrency

- [class func lock()](/documentation/quartzcore/catransaction/lock())
- [class func unlock()](/documentation/quartzcore/catransaction/unlock())
### Getting and Setting Transaction Properties

- [class func setValue(Any?, forKey: String)](/documentation/quartzcore/catransaction/setvalue(_:forkey:))
- [class func value(forKey: String) -> Any?](/documentation/quartzcore/catransaction/value(forkey:))
### Constants

- [Transaction properties](/documentation/quartzcore/transaction-properties)
#### Constants

- [let kCATransactionAnimationDuration: String](/documentation/quartzcore/kcatransactionanimationduration)
- [let kCATransactionDisableActions: String](/documentation/quartzcore/kcatransactiondisableactions)
- [let kCATransactionAnimationTimingFunction: String](/documentation/quartzcore/kcatransactionanimationtimingfunction)
- [let kCATransactionCompletionBlock: String](/documentation/quartzcore/kcatransactioncompletionblock)


## Animation Timing

- [func CACurrentMediaTime() -> CFTimeInterval](/documentation/quartzcore/cacurrentmediatime())
- [CAMediaTimingFunction](/documentation/quartzcore/camediatimingfunction)
### Creating Timing Functions

- [convenience init(name: CAMediaTimingFunctionName)](/documentation/quartzcore/camediatimingfunction/init(name:))
- [init(controlPoints: Float, Float, Float, Float)](/documentation/quartzcore/camediatimingfunction/init(controlpoints:_:_:_:))
### Accessing the Control Points

- [func getControlPoint(at: Int, values: UnsafeMutablePointer<Float>)](/documentation/quartzcore/camediatimingfunction/getcontrolpoint(at:values:))
### Constants

- [Predefined Timing Functions](/documentation/quartzcore/predefined-timing-functions)
#### Constants

- [static let linear: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/linear)
- [static let easeIn: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/easein)
- [static let easeOut: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/easeout)
- [static let easeInEaseOut: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/easeineaseout)
- [static let `default`: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/default)

### Initializers

- [init?(coder: NSCoder)](/documentation/quartzcore/camediatimingfunction/init(coder:))

- [CAMediaTiming](/documentation/quartzcore/camediatiming)
### Animation Start Time

- [var beginTime: CFTimeInterval](/documentation/quartzcore/camediatiming/begintime)
- [var timeOffset: CFTimeInterval](/documentation/quartzcore/camediatiming/timeoffset)
### Repeating Animations

- [var repeatCount: Float](/documentation/quartzcore/camediatiming/repeatcount)
- [var repeatDuration: CFTimeInterval](/documentation/quartzcore/camediatiming/repeatduration)
### Duration and Speed

- [var duration: CFTimeInterval](/documentation/quartzcore/camediatiming/duration)
- [var speed: Float](/documentation/quartzcore/camediatiming/speed)
### Playback Modes

- [var autoreverses: Bool](/documentation/quartzcore/camediatiming/autoreverses)
- [var fillMode: CAMediaTimingFillMode](/documentation/quartzcore/camediatiming/fillmode)
### Constants

- [Fill Modes](/documentation/quartzcore/fill-modes)
#### Constants

- [static let removed: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/removed)
- [static let forwards: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/forwards)
- [static let backwards: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/backwards)
- [static let both: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/both)


- [CADisplayLink](/documentation/quartzcore/cadisplaylink)
### Creating a Display Link

- [init(target: Any, selector: Selector)](/documentation/quartzcore/cadisplaylink/init(target:selector:))
### Configuring a Display Link

- [var duration: CFTimeInterval](/documentation/quartzcore/cadisplaylink/duration)
- [var preferredFrameRateRange: CAFrameRateRange](/documentation/quartzcore/cadisplaylink/preferredframeraterange)
- [var preferredFramesPerSecond: Int](/documentation/quartzcore/cadisplaylink/preferredframespersecond)
- [var isPaused: Bool](/documentation/quartzcore/cadisplaylink/ispaused)
- [var timestamp: CFTimeInterval](/documentation/quartzcore/cadisplaylink/timestamp)
- [var targetTimestamp: CFTimeInterval](/documentation/quartzcore/cadisplaylink/targettimestamp)
- [var frameInterval: Int](/documentation/quartzcore/cadisplaylink/frameinterval)
### Scheduling a Display Link to Send Notifications

- [func add(to: RunLoop, forMode: RunLoop.Mode)](/documentation/quartzcore/cadisplaylink/add(to:formode:))
- [func remove(from: RunLoop, forMode: RunLoop.Mode)](/documentation/quartzcore/cadisplaylink/remove(from:formode:))
- [func invalidate()](/documentation/quartzcore/cadisplaylink/invalidate())

- [CAMetalDisplayLink](/documentation/quartzcore/cametaldisplaylink)
### Creating a Display Link

- [init(metalLayer: CAMetalLayer)](/documentation/quartzcore/cametaldisplaylink/init(metallayer:))
### Configuring a Display Link

- [var preferredFrameRateRange: CAFrameRateRange](/documentation/quartzcore/cametaldisplaylink/preferredframeraterange)
- [var preferredFrameLatency: Float](/documentation/quartzcore/cametaldisplaylink/preferredframelatency)
- [var delegate: (any CAMetalDisplayLinkDelegate)?](/documentation/quartzcore/cametaldisplaylink/delegate)
### Registering for Callbacks

- [func add(to: RunLoop, forMode: RunLoop.Mode)](/documentation/quartzcore/cametaldisplaylink/add(to:formode:))
### Pausing Callbacks

- [var isPaused: Bool](/documentation/quartzcore/cametaldisplaylink/ispaused)
### Deregistering for callbacks

- [func remove(from: RunLoop, forMode: RunLoop.Mode)](/documentation/quartzcore/cametaldisplaylink/remove(from:formode:))
- [func invalidate()](/documentation/quartzcore/cametaldisplaylink/invalidate())
### Classes

- [CAMetalDisplayLink.Update](/documentation/quartzcore/cametaldisplaylink/update)
#### Timing the Next Animation Frame

- [var targetPresentationTimestamp: CFTimeInterval](/documentation/quartzcore/cametaldisplaylink/update/targetpresentationtimestamp)
#### Drawing the Next Frame

- [var targetTimestamp: CFTimeInterval](/documentation/quartzcore/cametaldisplaylink/update/targettimestamp)
- [var drawable: any CAMetalDrawable](/documentation/quartzcore/cametaldisplaylink/update/drawable)


- [CAMetalDisplayLink.Update](/documentation/quartzcore/cametaldisplaylink/update)
### Timing the Next Animation Frame

- [var targetPresentationTimestamp: CFTimeInterval](/documentation/quartzcore/cametaldisplaylink/update/targetpresentationtimestamp)
### Drawing the Next Frame

- [var targetTimestamp: CFTimeInterval](/documentation/quartzcore/cametaldisplaylink/update/targettimestamp)
- [var drawable: any CAMetalDrawable](/documentation/quartzcore/cametaldisplaylink/update/drawable)

- [CAMetalDisplayLinkDelegate](/documentation/quartzcore/cametaldisplaylinkdelegate)
### Receiving Display Updates

- [func metalDisplayLink(CAMetalDisplayLink, needsUpdate: CAMetalDisplayLink.Update)](/documentation/quartzcore/cametaldisplaylinkdelegate/metaldisplaylink(_:needsupdate:))

## Particle Systems

- [CAEmitterLayer](/documentation/quartzcore/caemitterlayer)
### Specifying Particle Emitter Cells

- [var emitterCells: [CAEmitterCell]?](/documentation/quartzcore/caemitterlayer/emittercells)
### Emitter Geometry

- [var renderMode: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayer/rendermode)
- [var emitterPosition: CGPoint](/documentation/quartzcore/caemitterlayer/emitterposition)
- [var emitterShape: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayer/emittershape)
- [var emitterZPosition: CGFloat](/documentation/quartzcore/caemitterlayer/emitterzposition)
- [var emitterDepth: CGFloat](/documentation/quartzcore/caemitterlayer/emitterdepth)
- [var emitterSize: CGSize](/documentation/quartzcore/caemitterlayer/emittersize)
### Emitter Cell Attribute Multipliers

- [var scale: Float](/documentation/quartzcore/caemitterlayer/scale)
- [var seed: UInt32](/documentation/quartzcore/caemitterlayer/seed)
- [var spin: Float](/documentation/quartzcore/caemitterlayer/spin)
- [var velocity: Float](/documentation/quartzcore/caemitterlayer/velocity)
- [var birthRate: Float](/documentation/quartzcore/caemitterlayer/birthrate)
- [var emitterMode: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayer/emittermode)
- [var lifetime: Float](/documentation/quartzcore/caemitterlayer/lifetime)
- [var preservesDepth: Bool](/documentation/quartzcore/caemitterlayer/preservesdepth)
### Constants

- [Emitter Shape](/documentation/quartzcore/emitter-shape)
#### Constants

- [static let point: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/point)
- [static let line: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/line)
- [static let rectangle: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/rectangle)
- [static let cuboid: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/cuboid)
- [static let circle: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/circle)
- [static let sphere: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/sphere)

- [Emitter Modes](/documentation/quartzcore/emitter-modes)
#### Constants

- [static let points: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/points)
- [static let outline: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/outline)
- [static let surface: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/surface)
- [static let volume: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/volume)

- [Emitter Render Order](/documentation/quartzcore/emitter-render-order)
#### Constants

- [static let unordered: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/unordered)
- [static let oldestFirst: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/oldestfirst)
- [static let oldestLast: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/oldestlast)
- [static let backToFront: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/backtofront)
- [static let additive: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/additive)


- [CAEmitterCell](/documentation/quartzcore/caemittercell)
### Providing Emitter Cell Content

- [var contents: Any?](/documentation/quartzcore/caemittercell/contents)
- [var contentsRect: CGRect](/documentation/quartzcore/caemittercell/contentsrect)
- [var emitterCells: [CAEmitterCell]?](/documentation/quartzcore/caemittercell/emittercells)
### Setting Emitter Cell Visual Attributes

- [var isEnabled: Bool](/documentation/quartzcore/caemittercell/isenabled)
- [var color: CGColor?](/documentation/quartzcore/caemittercell/color)
- [var redRange: Float](/documentation/quartzcore/caemittercell/redrange)
- [var greenRange: Float](/documentation/quartzcore/caemittercell/greenrange)
- [var blueRange: Float](/documentation/quartzcore/caemittercell/bluerange)
- [var alphaRange: Float](/documentation/quartzcore/caemittercell/alpharange)
- [var redSpeed: Float](/documentation/quartzcore/caemittercell/redspeed)
- [var greenSpeed: Float](/documentation/quartzcore/caemittercell/greenspeed)
- [var blueSpeed: Float](/documentation/quartzcore/caemittercell/bluespeed)
- [var alphaSpeed: Float](/documentation/quartzcore/caemittercell/alphaspeed)
- [var magnificationFilter: String](/documentation/quartzcore/caemittercell/magnificationfilter)
- [var minificationFilter: String](/documentation/quartzcore/caemittercell/minificationfilter)
- [var minificationFilterBias: Float](/documentation/quartzcore/caemittercell/minificationfilterbias)
- [var scale: CGFloat](/documentation/quartzcore/caemittercell/scale)
- [var scaleRange: CGFloat](/documentation/quartzcore/caemittercell/scalerange)
- [var contentsScale: CGFloat](/documentation/quartzcore/caemittercell/contentsscale)
- [var name: String?](/documentation/quartzcore/caemittercell/name)
- [var style: [AnyHashable : Any]?](/documentation/quartzcore/caemittercell/style)
### Setting Emitter Cell Motion Attributes

- [var spin: CGFloat](/documentation/quartzcore/caemittercell/spin)
- [var spinRange: CGFloat](/documentation/quartzcore/caemittercell/spinrange)
- [var emissionLatitude: CGFloat](/documentation/quartzcore/caemittercell/emissionlatitude)
- [var emissionLongitude: CGFloat](/documentation/quartzcore/caemittercell/emissionlongitude)
- [var emissionRange: CGFloat](/documentation/quartzcore/caemittercell/emissionrange)
### Setting Emitter Cell Temporal Attributes

- [var lifetime: Float](/documentation/quartzcore/caemittercell/lifetime)
- [var lifetimeRange: Float](/documentation/quartzcore/caemittercell/lifetimerange)
- [var birthRate: Float](/documentation/quartzcore/caemittercell/birthrate)
- [var scaleSpeed: CGFloat](/documentation/quartzcore/caemittercell/scalespeed)
- [var velocity: CGFloat](/documentation/quartzcore/caemittercell/velocity)
- [var velocityRange: CGFloat](/documentation/quartzcore/caemittercell/velocityrange)
- [var xAcceleration: CGFloat](/documentation/quartzcore/caemittercell/xacceleration)
- [var yAcceleration: CGFloat](/documentation/quartzcore/caemittercell/yacceleration)
- [var zAcceleration: CGFloat](/documentation/quartzcore/caemittercell/zacceleration)
### Using Key-Value Coding Extensions

- [class func defaultValue(forKey: String) -> Any?](/documentation/quartzcore/caemittercell/defaultvalue(forkey:))
- [func shouldArchiveValue(forKey: String) -> Bool](/documentation/quartzcore/caemittercell/shouldarchivevalue(forkey:))
### Initializers

- [init?(coder: NSCoder)](/documentation/quartzcore/caemittercell/init(coder:))

## Advanced Layer Options

- [CAScrollLayer](/documentation/quartzcore/cascrolllayer)
### Scrolling constraints

- [var scrollMode: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayer/scrollmode)
### Scrolling the layer

- [func scroll(to: CGPoint)](/documentation/quartzcore/cascrolllayer/scroll(to:)-37q0p)
- [func scroll(to: CGRect)](/documentation/quartzcore/cascrolllayer/scroll(to:)-782vd)
### Constants

- [Scroll Modes](/documentation/quartzcore/scroll-modes)
#### Constants

- [static let none: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/none)
- [static let vertically: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/vertically)
- [static let horizontally: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/horizontally)
- [static let both: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/both)


- [CATiledLayer](/documentation/quartzcore/catiledlayer)
### Visual Fade

- [class func fadeDuration() -> CFTimeInterval](/documentation/quartzcore/catiledlayer/fadeduration())
### Levels of detail

- [var levelsOfDetail: Int](/documentation/quartzcore/catiledlayer/levelsofdetail)
- [var levelsOfDetailBias: Int](/documentation/quartzcore/catiledlayer/levelsofdetailbias)
### Layer tile size

- [var tileSize: CGSize](/documentation/quartzcore/catiledlayer/tilesize)

- [CATransformLayer](/documentation/quartzcore/catransformlayer)
- [CAReplicatorLayer](/documentation/quartzcore/careplicatorlayer)
### Setting Instance Display Properties

- [var instanceCount: Int](/documentation/quartzcore/careplicatorlayer/instancecount)
- [var instanceDelay: CFTimeInterval](/documentation/quartzcore/careplicatorlayer/instancedelay)
- [var instanceTransform: CATransform3D](/documentation/quartzcore/careplicatorlayer/instancetransform)
### Modifying Instance Layer Geometry

- [var preservesDepth: Bool](/documentation/quartzcore/careplicatorlayer/preservesdepth)
### Accessing Instance Color Values

- [var instanceColor: CGColor?](/documentation/quartzcore/careplicatorlayer/instancecolor)
- [var instanceRedOffset: Float](/documentation/quartzcore/careplicatorlayer/instanceredoffset)
- [var instanceGreenOffset: Float](/documentation/quartzcore/careplicatorlayer/instancegreenoffset)
- [var instanceBlueOffset: Float](/documentation/quartzcore/careplicatorlayer/instanceblueoffset)
- [var instanceAlphaOffset: Float](/documentation/quartzcore/careplicatorlayer/instancealphaoffset)

## Metal and OpenGL

- [CAMetalLayer](/documentation/quartzcore/cametallayer)
### Configuring the Metal Device

- [var device: (any MTLDevice)?](/documentation/quartzcore/cametallayer/device)
- [var preferredDevice: (any MTLDevice)?](/documentation/quartzcore/cametallayer/preferreddevice)
### Configuring the Layer’s Drawable Objects

- [var pixelFormat: MTLPixelFormat](/documentation/quartzcore/cametallayer/pixelformat)
- [var colorspace: CGColorSpace?](/documentation/quartzcore/cametallayer/colorspace)
- [var framebufferOnly: Bool](/documentation/quartzcore/cametallayer/framebufferonly)
- [var drawableSize: CGSize](/documentation/quartzcore/cametallayer/drawablesize)
### Configuring Presentation Behavior

- [var presentsWithTransaction: Bool](/documentation/quartzcore/cametallayer/presentswithtransaction)
- [var displaySyncEnabled: Bool](/documentation/quartzcore/cametallayer/displaysyncenabled)
### Configuring Extended Dynamic Range Behavior

- [var wantsExtendedDynamicRangeContent: Bool](/documentation/quartzcore/cametallayer/wantsextendeddynamicrangecontent)
- [var edrMetadata: CAEDRMetadata?](/documentation/quartzcore/cametallayer/edrmetadata)
### Obtaining a Metal Drawable

- [func nextDrawable() -> (any CAMetalDrawable)?](/documentation/quartzcore/cametallayer/nextdrawable())
- [var maximumDrawableCount: Int](/documentation/quartzcore/cametallayer/maximumdrawablecount)
- [var allowsNextDrawableTimeout: Bool](/documentation/quartzcore/cametallayer/allowsnextdrawabletimeout)
### Configuring the Metal Performance HUD

- [var developerHUDProperties: [AnyHashable : Any]?](/documentation/quartzcore/cametallayer/developerhudproperties)
### Instance Properties

- [var residencySet: any MTLResidencySet](/documentation/quartzcore/cametallayer/residencyset)

- [CAMetalDrawable](/documentation/quartzcore/cametaldrawable)
### Getting the Drawable’s Texture

- [var texture: any MTLTexture](/documentation/quartzcore/cametaldrawable/texture)
### Getting the Owning Layer

- [var layer: CAMetalLayer](/documentation/quartzcore/cametaldrawable/layer)

- [CAEAGLLayer](/documentation/quartzcore/caeagllayer)
### Accessing the Layer Properties

- [var drawableProperties: [String : Any]?](/documentation/opengles/eagldrawable/drawableproperties)
- [var presentsWithTransaction: Bool](/documentation/quartzcore/caeagllayer/presentswithtransaction)

- [CAEDRMetadata](/documentation/quartzcore/caedrmetadata)
### Retrieving Hybrid-Log Gamma Metadata

- [class var hlg: CAEDRMetadata](/documentation/quartzcore/caedrmetadata/hlg)
### Retrieving HDR10 Metadata

- [class func hdr10(displayInfo: Data?, contentInfo: Data?, opticalOutputScale: Float) -> CAEDRMetadata](/documentation/quartzcore/caedrmetadata/hdr10(displayinfo:contentinfo:opticaloutputscale:))
- [class func hdr10(minLuminance: Float, maxLuminance: Float, opticalOutputScale: Float) -> CAEDRMetadata](/documentation/quartzcore/caedrmetadata/hdr10(minluminance:maxluminance:opticaloutputscale:))
### Type Properties

- [class var isAvailable: Bool](/documentation/quartzcore/caedrmetadata/isavailable)
### Type Methods

- [class func hlg(ambientViewingEnvironment: Data) -> CAEDRMetadata](/documentation/quartzcore/caedrmetadata/hlg(ambientviewingenvironment:))
### Initializers

- [init?(coder: NSCoder)](/documentation/quartzcore/caedrmetadata/init(coder:))

- [CAOpenGLLayer](/documentation/quartzcore/caopengllayer)
### Determining Layer Properties

- [var colorspace: CGColorSpace?](/documentation/quartzcore/caopengllayer/colorspace)
- [var wantsExtendedDynamicRangeContent: Bool](/documentation/quartzcore/caopengllayer/wantsextendeddynamicrangecontent)
### Drawing Layer Content

- [var isAsynchronous: Bool](/documentation/quartzcore/caopengllayer/isasynchronous)
- [func canDraw(inCGLContext: CGLContextObj, pixelFormat: CGLPixelFormatObj, forLayerTime: CFTimeInterval, displayTime: UnsafePointer<CVTimeStamp>?) -> Bool](/documentation/quartzcore/caopengllayer/candraw(incglcontext:pixelformat:forlayertime:displaytime:))
- [func draw(inCGLContext: CGLContextObj, pixelFormat: CGLPixelFormatObj, forLayerTime: CFTimeInterval, displayTime: UnsafePointer<CVTimeStamp>?)](/documentation/quartzcore/caopengllayer/draw(incglcontext:pixelformat:forlayertime:displaytime:))
### Managing Pixel Format

- [func copyCGLPixelFormat(forDisplayMask: UInt32) -> CGLPixelFormatObj](/documentation/quartzcore/caopengllayer/copycglpixelformat(fordisplaymask:))
- [func releaseCGLPixelFormat(CGLPixelFormatObj)](/documentation/quartzcore/caopengllayer/releasecglpixelformat(_:))
### Managing the Rendering Context

- [func copyCGLContext(forPixelFormat: CGLPixelFormatObj) -> CGLContextObj](/documentation/quartzcore/caopengllayer/copycglcontext(forpixelformat:))
- [func releaseCGLContext(CGLContextObj)](/documentation/quartzcore/caopengllayer/releasecglcontext(_:))

- [CARenderer](/documentation/quartzcore/carenderer)
### Creating a Renderer

- [init(cglContext: UnsafeMutableRawPointer, options: [AnyHashable : Any]?)](/documentation/quartzcore/carenderer/init(cglcontext:options:)-1l3m2)
- [init(mtlTexture: any MTLTexture, options: [AnyHashable : Any]?)](/documentation/quartzcore/carenderer/init(mtltexture:options:)-1cr0b)
### Getting the Rendered Layer

- [var layer: CALayer?](/documentation/quartzcore/carenderer/layer)
### Determining Layer Bounds

- [var bounds: CGRect](/documentation/quartzcore/carenderer/bounds)
### Rendering a Frame

- [func beginFrame(atTime: CFTimeInterval, timeStamp: UnsafeMutablePointer<CVTimeStamp>?)](/documentation/quartzcore/carenderer/beginframe(attime:timestamp:))
- [func updateBounds() -> CGRect](/documentation/quartzcore/carenderer/updatebounds())
- [func addUpdate(CGRect)](/documentation/quartzcore/carenderer/addupdate(_:))
- [func render()](/documentation/quartzcore/carenderer/render())
- [func nextFrameTime() -> CFTimeInterval](/documentation/quartzcore/carenderer/nextframetime())
- [func endFrame()](/documentation/quartzcore/carenderer/endframe())
### Instance Methods

- [func setDestination(any MTLTexture)](/documentation/quartzcore/carenderer/setdestination(_:))
### Initializers

- [init(CGLContext: UnsafeMutableRawPointer, options: [AnyHashable : Any]?)](/documentation/quartzcore/carenderer/init(cglcontext:options:)-6ywk8)
- [init(MTLTexture: any MTLTexture, options: [AnyHashable : Any]?)](/documentation/quartzcore/carenderer/init(mtltexture:options:)-51l7q)

## ProMotion

- [Optimizing iPhone and iPad apps to support ProMotion displays](/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays)
## Remote Display of Layer Content

- [CARemoteLayerClient](/documentation/quartzcore/caremotelayerclient)
### Creating a Client

- [init(serverPort: mach_port_t)](/documentation/quartzcore/caremotelayerclient/init(serverport:))
### Retrieving Client Properties

- [var clientId: UInt32](/documentation/quartzcore/caremotelayerclient/clientid)
- [var layer: CALayer?](/documentation/quartzcore/caremotelayerclient/layer)
### Invalidating a Client

- [func invalidate()](/documentation/quartzcore/caremotelayerclient/invalidate())

- [CARemoteLayerServer](/documentation/quartzcore/caremotelayerserver)
### Creating a Server

- [var serverPort: mach_port_t](/documentation/quartzcore/caremotelayerserver/serverport)
### Getting a Server Instance

- [class func shared() -> CARemoteLayerServer](/documentation/quartzcore/caremotelayerserver/shared())

## Transforms

- [Transforms](/documentation/quartzcore/transforms)
### Creating Transforms

- [func CATransform3DMakeTranslation(CGFloat, CGFloat, CGFloat) -> CATransform3D](/documentation/quartzcore/catransform3dmaketranslation(_:_:_:))
- [func CATransform3DMakeScale(CGFloat, CGFloat, CGFloat) -> CATransform3D](/documentation/quartzcore/catransform3dmakescale(_:_:_:))
- [func CATransform3DMakeRotation(CGFloat, CGFloat, CGFloat, CGFloat) -> CATransform3D](/documentation/quartzcore/catransform3dmakerotation(_:_:_:_:))
### Chaining Transforms

- [func CATransform3DConcat(CATransform3D, CATransform3D) -> CATransform3D](/documentation/quartzcore/catransform3dconcat(_:_:))
- [func CATransform3DTranslate(CATransform3D, CGFloat, CGFloat, CGFloat) -> CATransform3D](/documentation/quartzcore/catransform3dtranslate(_:_:_:_:))
- [func CATransform3DScale(CATransform3D, CGFloat, CGFloat, CGFloat) -> CATransform3D](/documentation/quartzcore/catransform3dscale(_:_:_:_:))
- [func CATransform3DRotate(CATransform3D, CGFloat, CGFloat, CGFloat, CGFloat) -> CATransform3D](/documentation/quartzcore/catransform3drotate(_:_:_:_:_:))
### Inverting a Transform

- [func CATransform3DInvert(CATransform3D) -> CATransform3D](/documentation/quartzcore/catransform3dinvert(_:))
### Determining Transform Properties

- [func CATransform3DIsAffine(CATransform3D) -> Bool](/documentation/quartzcore/catransform3disaffine(_:))
- [func CATransform3DIsIdentity(CATransform3D) -> Bool](/documentation/quartzcore/catransform3disidentity(_:))
- [func CATransform3DEqualToTransform(CATransform3D, CATransform3D) -> Bool](/documentation/quartzcore/catransform3dequaltotransform(_:_:))
### Converting to and from Core Graphics Affine Transforms

- [func CATransform3DMakeAffineTransform(CGAffineTransform) -> CATransform3D](/documentation/quartzcore/catransform3dmakeaffinetransform(_:))
- [func CATransform3DGetAffineTransform(CATransform3D) -> CGAffineTransform](/documentation/quartzcore/catransform3dgetaffinetransform(_:))
### Data Types

- [CATransform3D](/documentation/quartzcore/catransform3d)
#### Initializers

- [init()](/documentation/quartzcore/catransform3d/init())
- [init(m11: CGFloat, m12: CGFloat, m13: CGFloat, m14: CGFloat, m21: CGFloat, m22: CGFloat, m23: CGFloat, m24: CGFloat, m31: CGFloat, m32: CGFloat, m33: CGFloat, m34: CGFloat, m41: CGFloat, m42: CGFloat, m43: CGFloat, m44: CGFloat)](/documentation/quartzcore/catransform3d/init(m11:m12:m13:m14:m21:m22:m23:m24:m31:m32:m33:m34:m41:m42:m43:m44:))
- [init(float4x4)](/documentation/quartzcore/catransform3d/init(_:)-6awvy)
- [init(double4x4)](/documentation/quartzcore/catransform3d/init(_:)-6euzs)
#### Instance Properties

- [var m11: CGFloat](/documentation/quartzcore/catransform3d/m11)
- [var m12: CGFloat](/documentation/quartzcore/catransform3d/m12)
- [var m13: CGFloat](/documentation/quartzcore/catransform3d/m13)
- [var m14: CGFloat](/documentation/quartzcore/catransform3d/m14)
- [var m21: CGFloat](/documentation/quartzcore/catransform3d/m21)
- [var m22: CGFloat](/documentation/quartzcore/catransform3d/m22)
- [var m23: CGFloat](/documentation/quartzcore/catransform3d/m23)
- [var m24: CGFloat](/documentation/quartzcore/catransform3d/m24)
- [var m31: CGFloat](/documentation/quartzcore/catransform3d/m31)
- [var m32: CGFloat](/documentation/quartzcore/catransform3d/m32)
- [var m33: CGFloat](/documentation/quartzcore/catransform3d/m33)
- [var m34: CGFloat](/documentation/quartzcore/catransform3d/m34)
- [var m41: CGFloat](/documentation/quartzcore/catransform3d/m41)
- [var m42: CGFloat](/documentation/quartzcore/catransform3d/m42)
- [var m43: CGFloat](/documentation/quartzcore/catransform3d/m43)
- [var m44: CGFloat](/documentation/quartzcore/catransform3d/m44)

### Constants

- [let CATransform3DIdentity: CATransform3D](/documentation/quartzcore/catransform3didentity)

## Quartz Composer

- [QCCompositionLayer](/documentation/quartz/qccompositionlayer)
## Reference

- [Core Animation Structures](/documentation/quartzcore/core-animation-structures)
### Structures

- [CAFrameRateRange](/documentation/quartzcore/caframeraterange)
#### Initializers

- [init()](/documentation/quartzcore/caframeraterange/init())
- [init(minimum: Float, maximum: Float, preferred: Float?)](/documentation/quartzcore/caframeraterange/init(minimum:maximum:preferred:))
#### Instance Properties

- [var maximum: Float](/documentation/quartzcore/caframeraterange/maximum)
- [var minimum: Float](/documentation/quartzcore/caframeraterange/minimum)
- [var preferred: Float?](/documentation/quartzcore/caframeraterange/preferred-7l3ki)
#### Type Properties

- [static let `default`: CAFrameRateRange](/documentation/quartzcore/caframeraterange/default)


- [Core Animation Constants](/documentation/quartzcore/core-animation-constants)
### Constants

- [let kCARendererColorSpace: String](/documentation/quartzcore/kcarenderercolorspace)
- [let kCARendererMetalCommandQueue: String](/documentation/quartzcore/kcarenderermetalcommandqueue)

- [QuartzCore Functions](/documentation/quartzcore/quartzcore-functions)
- [Core Animation Data Types](/documentation/quartzcore/core-animation-data-types)
### Data Types

- [CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/caanimationcalculationmode/init(rawvalue:))
#### Type Properties

- [static let cubic: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/cubic)
- [static let cubicPaced: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/cubicpaced)
- [static let discrete: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/discrete)
- [static let linear: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/linear)
- [static let paced: CAAnimationCalculationMode](/documentation/quartzcore/caanimationcalculationmode/paced)

- [CAAnimationRotationMode](/documentation/quartzcore/caanimationrotationmode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/caanimationrotationmode/init(rawvalue:))
#### Type Properties

- [static let rotateAuto: CAAnimationRotationMode](/documentation/quartzcore/caanimationrotationmode/rotateauto)
- [static let rotateAutoReverse: CAAnimationRotationMode](/documentation/quartzcore/caanimationrotationmode/rotateautoreverse)

- [CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/caemitterlayeremittermode/init(rawvalue:))
#### Type Properties

- [static let outline: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/outline)
- [static let points: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/points)
- [static let surface: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/surface)
- [static let volume: CAEmitterLayerEmitterMode](/documentation/quartzcore/caemitterlayeremittermode/volume)

- [CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/caemitterlayeremittershape/init(rawvalue:))
#### Type Properties

- [static let circle: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/circle)
- [static let cuboid: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/cuboid)
- [static let line: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/line)
- [static let point: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/point)
- [static let rectangle: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/rectangle)
- [static let sphere: CAEmitterLayerEmitterShape](/documentation/quartzcore/caemitterlayeremittershape/sphere)

- [CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/caemitterlayerrendermode/init(rawvalue:))
#### Type Properties

- [static let additive: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/additive)
- [static let backToFront: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/backtofront)
- [static let oldestFirst: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/oldestfirst)
- [static let oldestLast: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/oldestlast)
- [static let unordered: CAEmitterLayerRenderMode](/documentation/quartzcore/caemitterlayerrendermode/unordered)

- [CAGradientLayerType](/documentation/quartzcore/cagradientlayertype)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/cagradientlayertype/init(rawvalue:))
#### Type Properties

- [static let axial: CAGradientLayerType](/documentation/quartzcore/cagradientlayertype/axial)
- [static let conic: CAGradientLayerType](/documentation/quartzcore/cagradientlayertype/conic)
- [static let radial: CAGradientLayerType](/documentation/quartzcore/cagradientlayertype/radial)

- [CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/calayercontentsfilter/init(rawvalue:))
#### Type Properties

- [static let linear: CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter/linear)
- [static let nearest: CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter/nearest)
- [static let trilinear: CALayerContentsFilter](/documentation/quartzcore/calayercontentsfilter/trilinear)

- [CALayerContentsFormat](/documentation/quartzcore/calayercontentsformat)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/calayercontentsformat/init(rawvalue:))
#### Type Properties

- [static let RGBA16Float: CALayerContentsFormat](/documentation/quartzcore/calayercontentsformat/rgba16float)
- [static let RGBA8Uint: CALayerContentsFormat](/documentation/quartzcore/calayercontentsformat/rgba8uint)
- [static let gray8Uint: CALayerContentsFormat](/documentation/quartzcore/calayercontentsformat/gray8uint)
- [static let automatic: CALayerContentsFormat](/documentation/quartzcore/calayercontentsformat/automatic)

- [CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/calayercontentsgravity/init(rawvalue:))
#### Type Properties

- [static let bottom: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/bottom)
- [static let bottomLeft: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/bottomleft)
- [static let bottomRight: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/bottomright)
- [static let center: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/center)
- [static let left: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/left)
- [static let resize: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/resize)
- [static let resizeAspect: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/resizeaspect)
- [static let resizeAspectFill: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/resizeaspectfill)
- [static let right: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/right)
- [static let top: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/top)
- [static let topLeft: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/topleft)
- [static let topRight: CALayerContentsGravity](/documentation/quartzcore/calayercontentsgravity/topright)

- [CALayerCornerCurve](/documentation/quartzcore/calayercornercurve)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/calayercornercurve/init(rawvalue:))
#### Type Properties

- [static let circular: CALayerCornerCurve](/documentation/quartzcore/calayercornercurve/circular)
- [static let continuous: CALayerCornerCurve](/documentation/quartzcore/calayercornercurve/continuous)

- [CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/camediatimingfillmode/init(rawvalue:))
#### Type Properties

- [static let backwards: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/backwards)
- [static let both: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/both)
- [static let forwards: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/forwards)
- [static let removed: CAMediaTimingFillMode](/documentation/quartzcore/camediatimingfillmode/removed)

- [CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/camediatimingfunctionname/init(rawvalue:))
#### Type Properties

- [static let `default`: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/default)
- [static let easeIn: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/easein)
- [static let easeInEaseOut: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/easeineaseout)
- [static let easeOut: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/easeout)
- [static let linear: CAMediaTimingFunctionName](/documentation/quartzcore/camediatimingfunctionname/linear)

- [CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/cascrolllayerscrollmode/init(rawvalue:))
#### Type Properties

- [static let both: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/both)
- [static let horizontally: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/horizontally)
- [static let none: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/none)
- [static let vertically: CAScrollLayerScrollMode](/documentation/quartzcore/cascrolllayerscrollmode/vertically)

- [CAShapeLayerFillRule](/documentation/quartzcore/cashapelayerfillrule)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/cashapelayerfillrule/init(rawvalue:))
#### Type Properties

- [static let evenOdd: CAShapeLayerFillRule](/documentation/quartzcore/cashapelayerfillrule/evenodd)
- [static let nonZero: CAShapeLayerFillRule](/documentation/quartzcore/cashapelayerfillrule/nonzero)

- [CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/cashapelayerlinecap/init(rawvalue:))
#### Type Properties

- [static let butt: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap/butt)
- [static let round: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap/round)
- [static let square: CAShapeLayerLineCap](/documentation/quartzcore/cashapelayerlinecap/square)

- [CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/cashapelayerlinejoin/init(rawvalue:))
#### Type Properties

- [static let bevel: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin/bevel)
- [static let miter: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin/miter)
- [static let round: CAShapeLayerLineJoin](/documentation/quartzcore/cashapelayerlinejoin/round)

- [CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/catextlayeralignmentmode/init(rawvalue:))
#### Type Properties

- [static let center: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/center)
- [static let justified: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/justified)
- [static let left: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/left)
- [static let natural: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/natural)
- [static let right: CATextLayerAlignmentMode](/documentation/quartzcore/catextlayeralignmentmode/right)

- [CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/catextlayertruncationmode/init(rawvalue:))
#### Type Properties

- [static let end: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/end)
- [static let middle: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/middle)
- [static let none: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/none)
- [static let start: CATextLayerTruncationMode](/documentation/quartzcore/catextlayertruncationmode/start)

- [CATransitionSubtype](/documentation/quartzcore/catransitionsubtype)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/catransitionsubtype/init(rawvalue:))
#### Type Properties

- [static let fromBottom: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/frombottom)
- [static let fromLeft: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/fromleft)
- [static let fromRight: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/fromright)
- [static let fromTop: CATransitionSubtype](/documentation/quartzcore/catransitionsubtype/fromtop)

- [CATransitionType](/documentation/quartzcore/catransitiontype)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/catransitiontype/init(rawvalue:))
#### Type Properties

- [static let fade: CATransitionType](/documentation/quartzcore/catransitiontype/fade)
- [static let moveIn: CATransitionType](/documentation/quartzcore/catransitiontype/movein)
- [static let push: CATransitionType](/documentation/quartzcore/catransitiontype/push)
- [static let reveal: CATransitionType](/documentation/quartzcore/catransitiontype/reveal)

- [CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/cavaluefunctionname/init(rawvalue:))
#### Type Properties

- [static let rotateX: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/rotatex)
- [static let rotateY: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/rotatey)
- [static let rotateZ: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/rotatez)
- [static let scale: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scale)
- [static let scaleX: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scalex)
- [static let scaleY: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scaley)
- [static let scaleZ: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/scalez)
- [static let translate: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translate)
- [static let translateX: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translatex)
- [static let translateY: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translatey)
- [static let translateZ: CAValueFunctionName](/documentation/quartzcore/cavaluefunctionname/translatez)

### Variables

- [static let automatic: CALayer.ToneMapMode](/documentation/quartzcore/calayer/tonemapmode-swift.struct/automatic)
- [static let ifSupported: CALayer.ToneMapMode](/documentation/quartzcore/calayer/tonemapmode-swift.struct/ifsupported)
- [static let never: CALayer.ToneMapMode](/documentation/quartzcore/calayer/tonemapmode-swift.struct/never)
### Macros

- [var CA_WARN_DEPRECATED: Int32](/documentation/quartzcore/ca_warn_deprecated)
### Type Aliases

- [CALayer.ToneMapMode](/documentation/quartzcore/calayer/tonemapmode-swift.struct)
#### Initializers

- [init(rawValue: String)](/documentation/quartzcore/calayer/tonemapmode-swift.struct/init(rawvalue:))

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
