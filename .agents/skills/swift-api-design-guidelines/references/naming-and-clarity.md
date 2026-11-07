# Naming and Clarity

Extended examples for name selection, role-based naming, weak-type compensation, and terminology.

## Contents

- [Include Words Needed for Clarity](#include-words-needed-for-clarity)
- [Omit Needless Words](#omit-needless-words)
- [Name by Role Not Type](#name-by-role-not-type)
- [Compensate for Weak Type Information](#compensate-for-weak-type-information)
- [Terminology Selection](#terminology-selection)

## Include Words Needed for Clarity

If omitting a word makes the call site ambiguous, keep it. The test: can a reader unfamiliar with the declaration understand the call site?

```swift
// GOOD — "for" distinguishes key lookup from index lookup
dictionary.removeValue(forKey: key)

// BAD — is key the value or the lookup key?
dictionary.remove(key)
```

```swift
// GOOD — "for" clarifies the relationship
extension List {
    func member(for key: Key) -> Value?
}

// BAD — what is "key" relative to the list?
extension List {
    func member(_ key: Key) -> Value?
}
```

```swift
// GOOD — preposition clarifies direction
view.fade(from: previousColor)

// BAD — is this the target or the source?
view.fade(previousColor)
```

## Omit Needless Words

Remove words that merely restate type information. Every word in a name should convey information not already available.

```swift
// GOOD
allViews.remove(cancelButton)

// BAD — "Element" repeats the type constraint
allViews.removeElement(cancelButton)
```

```swift
// GOOD
let result = parser.parse(data)

// BAD — "Data" is already the parameter type
let result = parser.parseData(data)
```

```swift
// GOOD
func move(to point: CGPoint)

// BAD — "point" is already in the type
func moveToPoint(_ point: CGPoint)
```

## Name by Role Not Type

Variables, parameters, and associated types should describe the entity's role in the current context.

```swift
// GOOD — describes the role
var greeting: String
var bodyText: String
let widthConstraint: NSLayoutConstraint
func restock(from supplier: Warehouse)

// BAD — describes the type
var string: String
var text: String
let constraint: NSLayoutConstraint
func restock(from warehouse: Warehouse)
```

For associated types in protocols, name by the role in the protocol's semantics:

```swift
// GOOD
protocol Container {
    associatedtype Element
    associatedtype Index
}

// BAD — names the constraint, not the role
protocol Container {
    associatedtype ItemType
    associatedtype IntegerIndex
}
```

## Compensate for Weak Type Information

When a parameter type is `Any`, `AnyObject`, `NSObject`, or a fundamental type (`Int`, `String`, `Double`), the call site may lack enough context to convey meaning. Add clarifying words to the name.

```swift
// GOOD — role words compensate for weak types
func addObserver(_ observer: NSObject, forKeyPath path: String)
func fill(with color: UIColor, alpha: Double)
func setTag(_ tag: Int, for view: UIView)

// BAD — weak types make the call site opaque
func add(_ object: NSObject, for string: String)
func fill(with any: UIColor, _ value: Double)
func set(_ value: Int, for object: UIView)
```

For function return types, the same principle applies:

```swift
// GOOD — return context clarifies weak type
func maximumScore() -> Int
func playerName() -> String

// BAD — generic return with no context
func value() -> Int
func name() -> String
```

## Terminology Selection

### Prefer common words over obscure terms

Use a common English word when it works. Reserve terms of art for situations where the precise technical meaning matters and no common word captures it.

```swift
// GOOD — common word suffices
skin                // not "epidermis"
beginners           // not "neophytes"

// GOOD — term of art is precise and necessary
func sin(_ angle: Double) -> Double  // "sine" is the term of art
```

### Preserve established meanings

Never use a term of art with a non-standard meaning. Anyone who knows the term expects its conventional definition.

```swift
// GOOD — Array is the established term
struct Array<Element> { ... }

// BAD — "List" means something different in CS (linked list)
struct List<Element> { ... }  // if it's really an array
```

### Avoid abbreviations

Do not abbreviate unless the abbreviation is universally understood in the domain. Spell words out.

```swift
// GOOD
var backgroundColor: UIColor
var characterIndex: Int

// BAD
var bgColor: UIColor
var charIdx: Int
```

### Embrace precedent

Follow naming conventions already established in the ecosystem, even if they conflict with a "purer" design.

```swift
// GOOD — matches existing Swift/Cocoa convention
Array, Dictionary, Set       // not Vector, Map, HashSet
sin(x), cos(x)              // not sine(x), cosine(x)
```
