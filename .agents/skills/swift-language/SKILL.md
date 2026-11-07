---
name: swift-language
description: "Apply modern Swift language patterns and idioms for non-concurrency, non-SwiftUI code. Covers if/switch expressions (Swift 5.9+), typed throws (Swift 6+), result builders, property wrappers, opaque and existential types (some vs any), guard patterns, Never type, Regex builders (Swift 5.7+), basic Codable shaping (CodingKeys, custom decoding, nested containers), modern collection APIs (count(where:), contains(where:), replacing()), basic FormatStyle usage, and string interpolation patterns. Use when writing core Swift code involving generics, protocols, enums, closures, or modern language features; route deep Codable to swift-codable, detailed formatting/localization to swift-formatstyle, and API naming to swift-api-design-guidelines."
---

# Swift Language Patterns

Apply current Swift language syntax without changing behavior or evaluation order.
Route deep decoding to `swift-codable`, formatting to `swift-formatstyle`, naming
to `swift-api-design-guidelines`, concurrency to `swift-concurrency`, and SwiftUI
state/view work to `swiftui-patterns`.

## Contents

- [If/Switch Expressions](#ifswitch-expressions)
- [Typed Throws](#typed-throws)
- [Result Builders](#result-builders)
- [Property Wrappers](#property-wrappers)
- [Opaque and Existential Types](#opaque-and-existential-types)
- [Guard Patterns](#guard-patterns)
- [Never Type](#never-type)
- [Regex Builders](#regex-builders)
- [Codable Best Practices](#codable-best-practices)
- [Modern Collection APIs](#modern-collection-apis)
- [FormatStyle](#formatstyle)
- [String Interpolation](#string-interpolation)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## If/Switch Expressions

For modernization, pin current behavior and evaluation order, make one semantic
rewrite, compile the affected module, and run focused fixtures/tests. Fix any
change before continuing; repeat until behavior is preserved.

Swift 5.9+ allows `if` and `switch` as expressions that return values. Use them
to assign, return, or initialize directly.

```swift
// Assign from if expression
let icon = if isComplete { "checkmark.circle.fill" } else { "circle" }

// Assign from switch expression
let label = switch status {
case .draft: "Draft"
case .published: "Published"
case .archived: "Archived"
}

// Works in return position
func badgeText(for priority: Priority) -> String {
    switch priority {
    case .high: "High"
    case .medium: "Medium"
    case .low: "Low"
    }
}
```

**Rules:**
- Every branch must produce a value of the same type.
- Multi-statement branches are not allowed -- each branch is a single expression.
- Wrap in parentheses when used as a function argument to avoid ambiguity.

## Typed Throws

Swift 6+ allows specifying the error type a function throws.

```swift
enum ValidationError: Error {
    case tooShort, invalidCharacters, alreadyTaken
}

func validate(username: String) throws(ValidationError) -> String {
    guard username.count >= 3 else { throw .tooShort }
    guard username.allSatisfy(\.isLetterOrDigit) else { throw .invalidCharacters }
    return username.lowercased()
}

// Caller gets typed error -- no cast needed
do {
    let name = try validate(username: input)
} catch {
    // error is ValidationError, not any Error
    switch error {
    case .tooShort: print("Too short")
    case .invalidCharacters: print("Invalid characters")
    case .alreadyTaken: print("Taken")
    }
}
```

**Rules:**
- Use `throws(SomeError)` only when callers benefit from exhaustive error
  handling. For mixed error sources, use untyped `throws`.
- When modernizing a helper with one local error enum, prefer `throws(ErrorEnum)` and note Swift 6+.
- `throws(Never)` marks a function that syntactically throws but never actually
  does -- useful in generic contexts.
- Typed throws propagate: a function calling `throws(A)` and `throws(B)` must
  itself throw a type that covers both (or use untyped `throws`).

## Result Builders

`@resultBuilder` enables DSL-style syntax. SwiftUI's `@ViewBuilder` is the most
common example, but you can create custom builders for any domain.

```swift
@resultBuilder
struct ArrayBuilder<Element> {
    static func buildBlock(_ components: [Element]...) -> [Element] {
        components.flatMap { $0 }
    }
    static func buildExpression(_ expression: Element) -> [Element] { [expression] }
    static func buildOptional(_ component: [Element]?) -> [Element] { component ?? [] }
    static func buildEither(first component: [Element]) -> [Element] { component }
    static func buildEither(second component: [Element]) -> [Element] { component }
    static func buildArray(_ components: [[Element]]) -> [Element] { components.flatMap { $0 } }
}

func makeItems(@ArrayBuilder<String> content: () -> [String]) -> [String] { content() }

let items = makeItems {
    "Always included"
    if showExtra { "Conditional" }
    for name in names { name.uppercased() }
}
```

**Builder methods:** `buildBlock` (combine statements), `buildExpression` (single value), `buildOptional` (`if` without `else`), `buildEither` (`if/else`), `buildArray` (`for..in`), `buildFinalResult` (optional post-processing).

## Property Wrappers

Custom `@propertyWrapper` types encapsulate storage and access patterns.

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    let range: ClosedRange<Value>

    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    var projectedValue: ClosedRange<Value> { range }

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

// Usage
struct Volume {
    @Clamped(0...100) var level: Int = 50
}

var v = Volume()
v.level = 150   // clamped to 100
print(v.$level) // projected value: 0...100
```

**Design rules:**
- `wrappedValue` is the primary getter/setter.
- `projectedValue` (accessed via `$property`) provides metadata or bindings.
- Property wrappers can be composed: `@A @B var x` applies outer wrapper first.
- Do not use property wrappers when a simple computed property suffices.

## Opaque and Existential Types

### `some Protocol` (Opaque Type)

The caller does not know the concrete type, but the compiler does. A `-> some P`
return has one fixed underlying concrete type across all return branches.

```swift
func makeCollection() -> some Collection<Int> {
    [1, 2, 3]  // Always returns Array<Int> -- compiler knows the concrete type
}
```

Use `some` for:
- Return types when you want to hide implementation but preserve type identity.
- Parameter types (Swift 5.7+): `some P` is shorthand for an unnamed generic
  parameter such as `<T: P>`.

### `any Protocol` (Existential Type)

An existential box that can hold any conforming type at runtime. It uses dynamic
dispatch and may allocate when the value does not fit in the inline buffer.

```swift
func process(items: [any StringProtocol]) {
    for item in items {
        print(item.uppercased())
    }
}
```

### When to choose

| Use `some` | Use `any` |
|---|---|
| Return type hiding concrete type | Heterogeneous collections |
| Function parameters (replaces simple generics) | Dynamic type erasure needed |
| Better performance (static dispatch) | Protocol has `Self` or associated type requirements you need to erase |

**Rule of thumb:** Default to `some`. Use `any` only when you need a
heterogeneous collection or runtime type flexibility.

## Guard Patterns

`guard` enforces preconditions and enables early exit. It keeps the happy path
left-aligned and reduces nesting.

```swift
func processOrder(_ order: Order?) throws -> Receipt {
    // Unwrap optionals
    guard let order else { throw OrderError.missing }

    // Validate conditions
    guard order.items.isEmpty == false else { throw OrderError.empty }
    guard order.total > 0 else { throw OrderError.invalidTotal }

    // Boolean checks
    guard order.isPaid else { throw OrderError.unpaid }

    // Pattern matching
    guard case .confirmed(let date) = order.status else {
        throw OrderError.notConfirmed
    }

    return Receipt(order: order, confirmedAt: date)
}
```

**Best practices:**
- Use `guard` for preconditions, `if` for branching logic.
- Combine related guards: `guard let a, let b else { return }`.
- The `else` block must exit scope: `return`, `throw`, `continue`, `break`, or
  `fatalError()`.
- Use shorthand unwrap: `guard let value else { ... }` (Swift 5.7+).

## Never Type

`Never` is an uninhabited type for code paths that never produce a value. It
behaves like Swift's bottom type only where a value expression can be used or
inferred; it is not a universal type witness, does not implicitly conform to
arbitrary protocols, and cannot satisfy generic constraints such as `T: P`
unless the constraint is otherwise valid for `Never`.

```swift
// Function that terminates the program
func crashWithDiagnostics(_ message: String) -> Never {
    let diagnostics = gatherDiagnostics()
    logger.critical("\(message): \(diagnostics)")
    fatalError(message)
}

enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
}
// Result<String, Never> -- a result that can never fail

// Exhaustive switch: no default needed since Never has no cases
func handle(_ result: Result<String, Never>) {
    switch result {
    case .success(let value): print(value)
    // No .failure case needed -- compiler knows it's impossible
    }
}
```

## Regex Builders

Swift 5.7+ Regex builder DSL provides compile-time checked, readable patterns.

```swift
import Foundation
import RegexBuilder

// Parse "2024-03-15" into components
let dateRegex = Regex {
    Capture { /\d{4}/ }; "-"; Capture { /\d{2}/ }; "-"; Capture { /\d{2}/ }
}

if let match = "2024-03-15".firstMatch(of: dateRegex) {
    let (_, year, month, day) = match.output
    _ = (year, month, day)
}

// TryCapture with transform
let priceRegex = Regex {
    "$"
    TryCapture { OneOrMore(.digit); "."; Repeat(.digit, count: 2) }
        transform: { Decimal(string: String($0)) }
}
```

**When to use builder vs. literal:**
- Builder: complex patterns, reusable components, strong typing on captures.
- Literal (`/pattern/`): simple patterns, familiarity with regex syntax.
- Both can be mixed: embed `/.../` literals inside builder blocks.

## Codable Best Practices

Use `CodingKeys` for simple renames and custom decoding only for real payload
shape or transformation mismatches. Load
[extended Swift patterns](references/swift-patterns-extended.md) for a compact
language example; use `swift-codable` for implementation and verification.

## Modern Collection APIs

Prefer these modern APIs over manual loops:

```swift
let numbers = [1, 2, 3, 4, 5, 6, 7, 8]

// count(where:) -- use instead of .filter { }.count
let evenCount = numbers.count(where: { $0.isMultiple(of: 2) })

// contains(where:) -- short-circuits on first match
let hasNegative = numbers.contains(where: { $0 < 0 })

// first(where:) / last(where:)
let firstEven = numbers.first(where: { $0.isMultiple(of: 2) })

// String replacing() -- Swift 5.7+, returns new string
let cleaned = rawText.replacing(/\s+/, with: " ")
let snakeCase = name.replacing("_", with: " ")

// compactMap -- unwrap optionals from a transform
let ids = strings.compactMap { Int($0) }

// flatMap -- flatten nested collections
let allTags = articles.flatMap(\.tags)

// Dictionary(grouping:by:)
let byCategory = Dictionary(grouping: items, by: \.category)

// reduce(into:) -- efficient accumulation
let freq = words.reduce(into: [:]) { counts, word in
    counts[word, default: 0] += 1
}
```

## FormatStyle

Use `.formatted()` and `Text(_:format:)` for basic display. Route style
selection, parsing, localization testing, and reusable formatter design to
`swift-formatstyle`.

## String Interpolation

Extend `DefaultStringInterpolation` for domain-specific formatting. Use `"""` for multi-line strings (indentation is relative to the closing `"""`). See [references/swift-patterns-extended.md](references/swift-patterns-extended.md) for custom interpolation examples.

## Common Mistakes

1. **Using `any` when `some` works.** Default to `some` for return types and
   parameters, but every `-> some P` branch must return the same concrete type.
2. **Manual loops or `.filter { }.count` instead of collection APIs.** Use
   `count(where:)` for conditional counts, plus `contains(where:)`,
   `compactMap`, and `flatMap` instead of extra iteration or arrays.
3. **`DateFormatter` instead of FormatStyle.** `.formatted()` is simpler,
   type-safe, and handles localization automatically.
4. **Force-unwrapping Codable decodes.** Use `decodeIfPresent` with defaults
   for optional or missing keys.
5. **Reordering preconditions during modernization.** Use `guard` without moving
   normalization or transformations before validation.
6. **Invalid `@c` signatures.** Say `UnsafeBufferPointer` is a Swift struct/value
   wrapper, then reject `String`, `Array`, closures, and generic placeholders.
7. **Ignoring typed throws.** When a function has a single, clear error type,
   typed throws give callers exhaustive switch without casting.
8. **Overusing property wrappers.** A computed property is simpler when there
   is no reuse or projected value needed.
9. **Underspecifying `Never`.** For `Result<T, Never>` or `throws(Never)`, write the caveat explicitly: Never does not implicitly conform to arbitrary protocols, cannot satisfy arbitrary `T: P` constraints, and is bottom-like only in valid expression/inference contexts.
10. **Owning sibling implementation.** Name the owner skill and stop. Avoid
    snippets for `CodingKeys`, decoders, formatters, SwiftUI, or concurrency.

## Review Checklist

- [ ] `some` used only when every opaque-return branch has one concrete type
- [ ] `guard` for preconditions; `count(where:)` instead of manual counting or `.filter { }.count`
- [ ] `.formatted()` used instead of `DateFormatter`/`NumberFormatter`
- [ ] Codable types use `CodingKeys` for API mapping; `decodeIfPresent` with defaults for optional fields
- [ ] if/switch expressions for conditional assignment; property wrappers have clear reuse justification
- [ ] Regex builder used for complex patterns (literal OK for simple ones)
- [ ] Typed throws used for single local error domains, with Swift 6+ compatibility noted
- [ ] `@c` corrections call `UnsafeBufferPointer` a Swift struct/value wrapper and enumerate rejected Swift-only types by name
- [ ] `Never` guidance uses uninhabited and bottom-like, and says no implicit arbitrary protocol/generic conformance
- [ ] deep Codable to `swift-codable`; FormatStyle APIs to `swift-formatstyle`; market/localized-display QA to `ios-localization`; naming/concurrency/SwiftUI routed to sibling skills

## References

- Extended patterns and Codable examples: [references/swift-patterns-extended.md](references/swift-patterns-extended.md)
- Attributes and C interop: [references/swift-attributes-interop.md](references/swift-attributes-interop.md)
