---
title: NSLayoutConstraint
description: The relationship between two user interface objects that must be satisfied by the constraint-based layout system.
source: https://developer.apple.com/documentation/uikit/nslayoutconstraint
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/nslayoutconstraint.json
timestamp: 2026-04-14T13:14:47.808Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# NSLayoutConstraint

**Available on:** iOS 6.0+, iPadOS 6.0+, Mac Catalyst 13.1+, tvOS 9.0+, visionOS 1.0+

> The relationship between two user interface objects that must be satisfied by the constraint-based layout system.

```swift
@MainActor class NSLayoutConstraint
```

## Overview

Each constraint is a linear equation with the following format:

```objc
item1.attribute1 = multiplier × item2.attribute2 + constant
```

In this equation, `attribute1` and `attribute2` are the variables that Auto Layout can adjust when solving these constraints. The other values are defined when you create the constraint. For example, if you’re defining the relative position of two buttons, you might say “the leading edge of the second button should be 8 points after the trailing edge of the first button.” The linear equation for this relationship is shown below:

```objc
// positive values move to the right in left-to-right languages like English.
button2.leading = 1.0 × button1.trailing + 8.0
```

Auto Layout then modifies the values of the specified leading and trailing edges until both sides of the equation are equal. Note that Auto Layout does not simply assign the value of the right side of this equation to the left side. Instead, the system can modify either attribute or both attributes as needed to solve for this constraint.

The fact that constraints are equations (and not assignment operators) means that you can switch the order of the items in the equation as needed to more clearly express the desired relationship. However, if you switch the order, you must also invert the multiplier and constant. For example, the following two equations produce identical constraints:

```objc
// These equations produce identical constraints
button2.leading = 1.0 × button1.trailing + 8.0
button1.trailing = 1.0 × button2.leading - 8.0
```

A valid layout is defined as a set of constraints with one and only one possible solution. Valid layouts are also referred to as a nonambiguous, nonconflicting layouts. Constraints with more than one solution are ambiguous. Constraints with no valid solutions are conflicting. For more information on resolving ambiguous and conflicting constraints, see [Types of Errors](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/TypesofErrors.html#//apple_ref/doc/uid/TP40010853-CH17) in [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html#//apple_ref/doc/uid/TP40010853).

Additionally, constraints are not limited to equality relationships. They can also use greater than or equal to (>=) or less than or equal to (<=) to describe the relationship between the two attributes. Constraints also have priorities between 1 and 1,000. Constraints with a priority of 1,000 are required. All priorities less than 1,000 are optional. By default, all constraints are required (priority = 1,000).

After solving for the required constraints, Auto Layout tries to solve all the optional constraints in priority order from highest to lowest. If it cannot solve for an optional constraint, it tries to come as close as possible to the desired result, and then moves on to the next constraint.

This combination of inequalities, equalities, and priorities gives you a great amount of flexibility and power. By combining multiple constraints, you can define layouts that dynamically adapt as the size and location of the elements in your user interface change. For some example layouts, see [Stack Views](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html#//apple_ref/doc/uid/TP40010853-CH11) in [Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html#//apple_ref/doc/uid/TP40010853).

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [Sendable](/documentation/Swift/Sendable)

## Creating constraints

- [constraints(withVisualFormat:options:metrics:views:)](/documentation/uikit/nslayoutconstraint/constraints(withvisualformat:options:metrics:views:)) Creates constraints described by an ASCII art-like visual format string.
- [init(item:attribute:relatedBy:toItem:attribute:multiplier:constant:)](/documentation/uikit/nslayoutconstraint/init(item:attribute:relatedby:toitem:attribute:multiplier:constant:)) Creates a constraint that defines the relationship between the specified attributes of the given views.

## Activating and deactivating constraints

- [isActive](/documentation/uikit/nslayoutconstraint/isactive) The active state of the constraint.
- [activate(_:)](/documentation/uikit/nslayoutconstraint/activate(_:)) Activates each constraint in the specified array.
- [deactivate(_:)](/documentation/uikit/nslayoutconstraint/deactivate(_:)) Deactivates each constraint in the specified array.

## Accessing constraint data

- [firstItem](/documentation/uikit/nslayoutconstraint/firstitem) The first object participating in the constraint.
- [firstAttribute](/documentation/uikit/nslayoutconstraint/firstattribute) The attribute of the first object participating in the constraint.
- [relation](/documentation/uikit/nslayoutconstraint/relation-swift.property) The relation between the two attributes in the constraint.
- [secondItem](/documentation/uikit/nslayoutconstraint/seconditem) The second object participating in the constraint.
- [secondAttribute](/documentation/uikit/nslayoutconstraint/secondattribute) The attribute of the second object participating in the constraint.
- [multiplier](/documentation/uikit/nslayoutconstraint/multiplier) The multiplier applied to the second attribute participating in the constraint.
- [constant](/documentation/uikit/nslayoutconstraint/constant) The constant added to the multiplied second attribute participating in the constraint.
- [firstAnchor](/documentation/uikit/nslayoutconstraint/firstanchor) The first anchor that defines the constraint.
- [secondAnchor](/documentation/uikit/nslayoutconstraint/secondanchor) The second anchor that defines the constraint.

## Getting the layout priority

- [priority](/documentation/uikit/nslayoutconstraint/priority) The priority of the constraint.
- [UILayoutPriority](/documentation/uikit/uilayoutpriority) The layout priority is used to indicate to the constraint-based layout system which constraints are more important, allowing the system to make appropriate tradeoffs when satisfying the constraints of the system as a whole.
- [NSLayoutConstraint.Priority](/documentation/AppKit/NSLayoutConstraint/Priority-swift.struct) Layout priority used to indicate the relative importance of constraints, allowing Auto Layout to make appropriate tradeoffs when satisfying the constraints of the system as a whole.

## Identifying a constraint

- [identifier](/documentation/uikit/nslayoutconstraint/identifier) The name that identifies the constraint.

## Controlling constraint archiving

- [shouldBeArchived](/documentation/uikit/nslayoutconstraint/shouldbearchived) A Boolean value that determines whether the constraint should be archived by its owning view.

## Constants

- [NSLayoutConstraint.Relation](/documentation/uikit/nslayoutconstraint/relation-swift.enum) The relation between the first attribute and the modified second attribute in a constraint.
- [NSLayoutConstraint.Attribute](/documentation/uikit/nslayoutconstraint/attribute) The part of the object’s visual representation that should be used to get the value for the constraint.
- [NSLayoutConstraint.FormatOptions](/documentation/uikit/nslayoutconstraint/formatoptions) A bit mask that specifies both a part of an interface element to align and a direction for the alignment between two interface elements.
- [NSLayoutConstraint.Orientation](/documentation/AppKit/NSLayoutConstraint/Orientation) The layout constraint orientation, either horizontal or vertical, that the constraint uses to enforce layout between objects.
- [NSLayoutConstraint.Axis](/documentation/uikit/nslayoutconstraint/axis) Keys that specify a horizontal or vertical layout constraint between objects.
- [NSEdgeInsets](/documentation/Foundation/NSEdgeInsets) A description of the distance between the edges of two rectangles.
- [NSLAYOUTCONSTRAINT_H](/documentation/uikit/nslayoutconstraint_h)

## Constraints

- [Positioning content within layout margins](/documentation/uikit/positioning-content-within-layout-margins) Position views so that they aren’t crowded by other content.
- [Positioning content relative to the safe area](/documentation/uikit/positioning-content-relative-to-the-safe-area) Position views so that they aren’t obstructed by other content.
- [UILayoutSupport](/documentation/uikit/uilayoutsupport) A set of methods that provide layout support and access to layout anchors.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
