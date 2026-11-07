# Argument Labels and Parameters

Extended examples for argument label rules, edge cases, parameter naming, and default argument strategy.

## Contents

- [Prepositional Phrase Rule Edge Cases](#prepositional-phrase-rule-edge-cases)
- [Grammatical Phrase Rule Extended Examples](#grammatical-phrase-rule-extended-examples)
- [Value-Preserving vs Narrowing Conversions](#value-preserving-vs-narrowing-conversions)
- [Indistinguishable Peer Arguments](#indistinguishable-peer-arguments)
- [Parameter Naming for Documentation](#parameter-naming-for-documentation)
- [Default Arguments Over Method Families](#default-arguments-over-method-families)

## Prepositional Phrase Rule Edge Cases

The base rule: when the first argument completes a prepositional phrase with the base name, use the preposition as the argument label.

```swift
// Standard cases — preposition is the label
x.removeBoxes(havingLength: 12)
view.fade(from: red)
path.relativePath(from: root)
```

### Abstraction boundary exception

When the first two arguments represent parts of a single abstraction, fold the preposition into the base name so each component gets its own label.

```swift
// GOOD — x and y are parts of a single abstraction (a point)
a.moveTo(x: b, y: c)

// BAD — forces x and y into a single prepositional phrase
a.move(toX: b, y: c)
```

```swift
// GOOD — row and column are parts of a single abstraction (a cell position)
table.cellAt(row: r, column: c)

// BAD
table.cell(atRow: r, column: c)
```

### Multiple prepositional phrases

When a method involves multiple prepositions, each argument gets its own prepositional label.

```swift
// GOOD
database.move(item, from: source, to: destination)

// GOOD
view.transition(from: oldState, to: newState, duration: 0.3)
```

## Grammatical Phrase Rule Extended Examples

When the first argument and base name form a grammatical phrase, omit the first label and absorb any leading words into the base name.

```swift
// GOOD — "add subview"
view.addSubview(child)

// GOOD — "contains element"
array.contains(element)
```

### Absorbing leading words

If the label would start with words that belong in the base name, move them.

```swift
// GOOD — "having length" absorbed into base name
removeBoxes(havingLength: 12)

// BAD — should be part of the base name
remove(boxesHavingLength: 12)
```

## Value-Preserving vs Narrowing Conversions

**Value-preserving (widening)** — the conversion cannot lose information. Omit the first label.

```swift
Int64(someUInt32)           // UInt32 always fits in Int64
String(someCharacter)       // Character is always a valid String
Double(someFloat)           // Float always fits in Double
```

**Narrowing or lossy** — the conversion may lose information or change representation. Use a descriptive label.

```swift
Int64(truncating: someDecimal)      // may lose precision
UInt32(clamping: someLargeInt)      // may clamp to bounds
String(describing: someObject)      // uses debug representation
Int(exactly: someDouble)            // may return nil
```

**Representation change** — the conversion changes how the value is viewed. Use a label that describes the interpretation.

```swift
String(utf8String: cString)         // interprets as UTF-8
Data(contentsOf: url)               // reads from file
URL(string: urlString)              // parses string as URL
```

## Indistinguishable Peer Arguments

Omit all labels when arguments are peers that cannot be usefully distinguished:

```swift
let smaller = min(x, y)
zip(sequence1, sequence2)
```

Keep labels when the values have distinct semantic roles, even if their types
match.

## Parameter Naming for Documentation

Parameter names drive the clarity of generated documentation, even though they do not appear at most call sites. Choose names that read well in a doc comment.

```swift
/// Finds the index of the equivalent element.
///
/// - Parameter element: The element to search for.
/// - Returns: The index of `element`, or `nil` if not found.
func index(of element: Element) -> Int?
```

Compare with a poorly named parameter:

```swift
/// Finds the index of the equivalent element.
///
/// - Parameter e: ???
func index(of e: Element) -> Int?
```

Name parameters as complete English words. Single letters and abbreviations damage documentation quality.

## Default Arguments Over Method Families

Prefer a single method with default parameter values over a family of methods.

```swift
// GOOD — one method, sensible defaults
func decode(
    _ data: Data,
    encoding: String.Encoding = .utf8,
    allowLossyConversion: Bool = false
) -> String?
```

```swift
// BAD — method family that differs only in which parameters are present
func decode(_ data: Data) -> String?
func decode(_ data: Data, encoding: String.Encoding) -> String?
func decode(_ data: Data, encoding: String.Encoding, allowLossyConversion: Bool) -> String?
```

### Ordering defaulted parameters

Place parameters with defaults at the end. Parameters without defaults typically carry more meaning and form the grammatical base of the call site.

```swift
// GOOD — required parameters first
func search(
    query: String,
    in scope: SearchScope = .all,
    limit: Int = 50,
    offset: Int = 0
) -> [Result]
```

Exception: when a trailing closure is the most common override, it may come after defaulted parameters.
