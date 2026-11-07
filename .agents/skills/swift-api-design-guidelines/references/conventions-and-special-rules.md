# Conventions and Special Rules

Casing conventions, complexity documentation, free function exceptions, overload safety, and tuple/closure naming.

## Contents

- [Casing Conventions](#casing-conventions)
- [Complexity Documentation](#complexity-documentation)
- [Free Function Exceptions](#free-function-exceptions)
- [Overload Safety](#overload-safety)
- [Tuple Member and Closure Parameter Naming](#tuple-member-and-closure-parameter-naming)
- [Unconstrained Polymorphism](#unconstrained-polymorphism)

## Casing Conventions

Types and protocols use `UpperCamelCase`. Everything else — functions, methods, properties, variables, constants, enum cases, argument labels — uses `lowerCamelCase`.

### Acronym handling

Acronyms that appear as all-uppercase in common American English usage are uniformly upper- or lower-cased based on their position in the name.

```swift
// At the start of a lowerCamelCase name — all lowercase
var utf8Bytes: [UTF8.CodeUnit]
var htmlParser: HTMLParser
var urlSession: URLSession

// In the middle or end — follows the case of its position
var isRepresentableAsASCII = true
var userSMTPServer: SMTPServer

// Type names — acronym stays uppercase
struct HTTPRequest { ... }
class URLSessionTask { ... }
enum UTF8 { ... }
```

Words that started as acronyms but are now common words follow standard casing:

```swift
// These are words, not acronyms
var radarDetector: RadarDetector   // not "RADARDetector"
var laserPrinter: LaserPrinter     // not "LASERPrinter"
var scubaGear: ScubaGear           // not "SCUBAGear"
```

## Complexity Documentation

Callers assume computed properties are O(1). Document the complexity of any computed property or subscript that does more work.

```swift
/// The total number of nodes in the tree.
///
/// - Complexity: O(*n*), where *n* is the number of nodes.
var nodeCount: Int {
    root.descendants.count
}
```

```swift
/// The element at the given offset from the start.
///
/// - Complexity: O(*k*), where *k* is the offset.
subscript(offset: Int) -> Element {
    var current = startIndex
    for _ in 0..<offset { current = index(after: current) }
    return self[current]
}
```

Properties that are genuinely O(1) do not need a complexity note — the default assumption is correct.

```swift
// O(1) — no note needed
var count: Int { storage.count }
var isEmpty: Bool { count == 0 }
var first: Element? { storage.first }
```

## Free Function Exceptions

Prefer methods and properties to free functions. Use a free function only when one of these three conditions holds:

**1. No obvious `self`**

```swift
// GOOD — neither argument is more "self" than the other
min(x, y)
max(a, b)
zip(sequence1, sequence2)
```

**2. Unconstrained generic**

```swift
// GOOD — works on anything
print(value)
debugPrint(value)
```

**3. Established domain notation**

```swift
// GOOD — mathematical convention
sin(x)
cos(x)
abs(value)
```

If none of these apply, make it a method.

```swift
// BAD — has an obvious self
calculateDistance(from: pointA, to: pointB)

// GOOD
pointA.distance(to: pointB)
```

## Overload Safety

Methods may share a base name when they operate in different type domains or when their meaning is clear from context.

```swift
// GOOD — different parameter types, same semantic operation
extension Collection {
    func contains(_ element: Element) -> Bool
    func contains(where predicate: (Element) -> Bool) -> Bool
}
```

### Avoid return-type-only overloads

Overloads that differ only in return type create ambiguity when the compiler cannot infer the expected type.

```swift
// BAD — ambiguous at call site
func transform() -> Int { ... }
func transform() -> String { ... }

let result = transform()  // error: ambiguous
```

### Safe overloading patterns

```swift
// GOOD — different first argument labels disambiguate
func fetch(id: Int) -> User
func fetch(name: String) -> User

// GOOD — different argument types
func draw(_ rect: CGRect)
func draw(_ path: CGPath)
```

## Tuple Member and Closure Parameter Naming

Label tuple members and closure parameters in public API signatures. Positional access (`.0`, `.1`) is fragile and unreadable.

### Tuple members

```swift
// GOOD — labeled
func position() -> (x: Double, y: Double)
func range() -> (lower: Int, upper: Int)

let pos = item.position()
pos.x   // clear
pos.y   // clear

// BAD — unlabeled
func position() -> (Double, Double)

let pos = item.position()
pos.0   // what is this?
pos.1   // what is this?
```

### Closure parameters

Name closure parameters where they appear in the API, especially for higher-order functions.

```swift
// GOOD
func filter(_ isIncluded: (Element) -> Bool) -> [Element]
func map<T>(_ transform: (Element) -> T) -> [T]
func sort(by areInIncreasingOrder: (Element, Element) -> Bool)

// BAD
func filter(_ predicate: (Element) -> Bool) -> [Element]  // acceptable but less descriptive
func sort(by compare: (Element, Element) -> Bool)          // "compare" is vague
```

## Unconstrained Polymorphism

Be careful with overloads involving `Any`, `AnyObject`, or unconstrained generics. They can silently match when a more specific overload was intended.

```swift
// DANGEROUS — both overloads match array literals
struct Container {
    func append(_ element: Element)
    func append(_ sequence: some Sequence<Element>)
}

values.append([2, 3, 4])  // which overload? ambiguous if Element is Array
```

Resolve with distinct argument labels:

```swift
// GOOD — unambiguous
struct Container {
    func append(_ element: Element)
    func append(contentsOf sequence: some Sequence<Element>)
}

values.append(singleValue)
values.append(contentsOf: [2, 3, 4])  // always clear
```
