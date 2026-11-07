---
title: CATransaction
description: A mechanism for grouping multiple layer-tree operations into atomic updates to the render tree.
source: https://developer.apple.com/documentation/quartzcore/catransaction
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/catransaction.json
timestamp: 2026-05-13T20:41:27.118Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CATransaction

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, macOS 10.5+, tvOS 9.0+, visionOS 1.0+

> A mechanism for grouping multiple layer-tree operations into atomic updates to the render tree.

```swift
class CATransaction
```

## Overview

`CATransaction` is the Core Animation mechanism for batching multiple layer-tree operations into atomic updates to the render tree. Every modification to a layer tree must be part of a transaction. Nested transactions are supported.

Core Animation supports two types of transactions: *implicit* transactions and *explicit* transactions. Implicit transactions are created automatically when the layer tree is modified by a thread without an active transaction and are committed automatically when the thread’s runloop next iterates. Explicit transactions occur when the the application sends the [CATransaction](/documentation/quartzcore/catransaction) class a [begin()](/documentation/quartzcore/catransaction/begin()) message before modifying the layer tree, and a [commit()](/documentation/quartzcore/catransaction/commit()) message afterwards.

[CATransaction](/documentation/quartzcore/catransaction) allows you to override default animation properties that are set for animatable properties. You can customize duration, timing function, whether changes to properties trigger animations, and provide a handler that informs you when all animations from the transaction group are completed.

During a transaction you can temporarily acquire a recursive spin lock for managing property atomicity.

[CATransaction](/documentation/quartzcore/catransaction) supports nested transactions. The following code shows how you can fade out a layer (named `transitioningLayer`) over a 2 second duration while scaling it to three times its original size. The scale animation is within a nested transaction with its own duration of 1 second. After the outer transaction completes, a completion block removes `transitioningLayer` from its parent layer.

```swift
let transitioningLayer = CALayer()
     
// Outer transaction animates `opacity` to 0 over 2 seconds
CATransaction.begin()
CATransaction.setAnimationDuration(2)
CATransaction.setCompletionBlock {
    transitioningLayer.removeFromSuperlayer()
}
    
transitioningLayer.opacity = 0
     
// Inner transaction animates scale to (3, 3, 3) over 1 second
CATransaction.begin()
CATransaction.setAnimationDuration(1)
     
transitioningLayer.transform = CATransform3DMakeScale(3, 3, 3)
     
CATransaction.commit() // Commits inner transaction
CATransaction.commit() // Commits outer transaction
```

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)

## Creating and Committing Transactions

- [begin()](/documentation/quartzcore/catransaction/begin()) Begin a new transaction for the current thread.
- [commit()](/documentation/quartzcore/catransaction/commit()) Commit all changes made during the current transaction.
- [flush()](/documentation/quartzcore/catransaction/flush()) Flushes any extant implicit transaction.

## Overriding Animation Duration and Timing

- [animationDuration()](/documentation/quartzcore/catransaction/animationduration()) Returns the animation duration used by all animations within this transaction group.
- [setAnimationDuration(_:)](/documentation/quartzcore/catransaction/setanimationduration(_:)) Sets the animation duration used by all animations within this transaction group.
- [animationTimingFunction()](/documentation/quartzcore/catransaction/animationtimingfunction()) Returns the timing function used for all animations within this transaction group.
- [setAnimationTimingFunction(_:)](/documentation/quartzcore/catransaction/setanimationtimingfunction(_:)) Sets the timing function used for all animations within this transaction group.

## Temporarily Disabling Property Animations

- [disableActions()](/documentation/quartzcore/catransaction/disableactions()) Returns whether actions triggered as a result of property changes made within this transaction group are suppressed.
- [setDisableActions(_:)](/documentation/quartzcore/catransaction/setdisableactions(_:)) Sets whether actions triggered as a result of property changes made within this transaction group are suppressed.

## Getting and Setting Completion Block Objects

- [completionBlock()](/documentation/quartzcore/catransaction/completionblock()) Returns the completion block object.
- [setCompletionBlock(_:)](/documentation/quartzcore/catransaction/setcompletionblock(_:)) Sets the completion block object.

## Managing Concurrency

- [lock()](/documentation/quartzcore/catransaction/lock()) Attempts to acquire a recursive spin-lock lock, ensuring that returned layer values are valid until unlocked.
- [unlock()](/documentation/quartzcore/catransaction/unlock()) Relinquishes a previously acquired transaction lock.

## Getting and Setting Transaction Properties

- [setValue(_:forKey:)](/documentation/quartzcore/catransaction/setvalue(_:forkey:)) Sets the arbitrary keyed-data for the specified key.
- [value(forKey:)](/documentation/quartzcore/catransaction/value(forkey:)) Returns the arbitrary keyed-data specified by the given key.

## Constants

- [Transaction properties](/documentation/quartzcore/transaction-properties) These constants define the property keys used by [value(forKey:)](/documentation/quartzcore/catransaction/value(forkey:)) and [setValue(_:forKey:)](/documentation/quartzcore/catransaction/setvalue(_:forkey:)).

## Animation Groups

- [CAAnimationGroup](/documentation/quartzcore/caanimationgroup) An object that allows multiple animations to be grouped and run concurrently.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
