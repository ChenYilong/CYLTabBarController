---
name: swift-api-design-guidelines
description: "Apply Swift API Design Guidelines to name, label, and document Swift APIs. Covers argument label rules (prepositional phrase rule, grammatical phrase rule, first-label omission), mutating/nonmutating pair naming (-ed/-ing participle pattern, form- prefix, sort/sorted, formUnion/union), side-effect naming (noun for pure, verb for mutating), documentation comment structure (summary by declaration kind, O(1) complexity rule), clarity at call site, role-based naming, protocol naming (-able/-ible/-ing), default arguments over method families, casing conventions, and terminology. Use when designing new Swift APIs, reviewing naming and argument labels, writing documentation comments, or refactoring for call site clarity."
---

# Swift API Design Guidelines

Apply the Swift API Design Guidelines to naming, labels, documentation, and
call-site clarity. For mixed requests, handle the API-design portion here and
route language/type-system work to `swift-language`, concurrency to
`swift-concurrency`, and lint configuration to `swiftlint`.

## Contents

- [Argument Label Rules](#argument-label-rules)
- [Side-Effect Naming](#side-effect-naming)
- [Mutating and Nonmutating Pairs](#mutating-and-nonmutating-pairs)
- [Documentation Comments](#documentation-comments)
- [Clarity and Naming](#clarity-and-naming)
- [Fluent Usage and Protocols](#fluent-usage-and-protocols)
- [General Conventions](#general-conventions)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Argument Label Rules

Argument labels determine how a call site reads. Apply the first matching row:

| Situation | Rule | Example |
|-----------|------|---------|
| First arg completes grammatical phrase | Omit label, merge words into base name | `addSubview(y)` |
| Value-preserving init conversion | Omit first label | `Int64(someUInt32)` |
| Arguments are indistinguishable peers | Omit all labels | `min(x, y)` |
| First arg completes prepositional phrase | Label with preposition | `fade(from: red)` |
| First two args form a single abstraction | Fold preposition into base name | `moveTo(x: b, y: c)` |
| Everything else | Label it | `split(maxSplits: 2)` |

Load [Argument Labels and Parameters](references/argument-labels-and-parameters.md)
when resolving abstraction boundaries, multiple prepositions, conversion
initializers, indistinguishable peers, parameter naming, or default arguments.

## Side-Effect Naming

Use imperative verbs for operations with side effects, result-describing noun
or adjective phrases for operations without side effects, and assertion-style
names for Boolean APIs.

```swift
array.sort()
array.append(newElement)
let d = point.distance(to: origin)
line.isEmpty
set.contains(element)
```

Load [Side Effects and Mutating Pairs](references/side-effects-and-mutating-pairs.md)
when reviewing extended pure/mutating examples or Boolean naming.

## Mutating and Nonmutating Pairs

Name mutating/nonmutating pairs from the operation's natural description:

- For verb operations, use the imperative for mutation and a result-describing
  participle for the copy: `sort()/sorted()` or `append(_:)/appending(_:)`.
  Prefer `-ed`; use `-ing` only when `-ed` is ungrammatical or describes the
  direct object instead of the returned result.
- For noun operations, use the noun for the copy and `form` + noun for
  mutation: `union(_:)` / `formUnion(_:)`.
- Prefix factories that create new values with `make`.

Load the [`-ed`/`-ing` Decision Tree](references/side-effects-and-mutating-pairs.md#the--ed-ing-decision-tree)
when the returned-result grammar is unclear. The same reference contains
expanded `form`-prefix, Boolean, and factory patterns.

## Documentation Comments

Every public declaration must have a documentation comment.

### Summary rules by declaration kind

| Declaration | Summary describes |
|-------------|-------------------|
| Function / method | What it does and what it returns |
| Subscript | What it accesses |
| Initializer | What it creates |
| Type / property / variable | What it **is** |

Write summaries as a single sentence fragment, beginning with a verb (for actions) or a noun phrase (for entities), ending in a period.

```swift
/// Returns the element at the specified index.
func element(at index: Int) -> Element { ... }

/// The number of elements in the collection.
var count: Int { ... }

/// Creates a new array with the given elements.
init(_ elements: some Sequence<Element>) { ... }

/// Accesses the element at the specified position.
subscript(index: Int) -> Element { ... }
```

### Symbol markup

Use standard symbol markup after the summary when relevant:

- `- Parameter name:` for individual parameters
- `- Parameters:` block for multiple parameters
- `- Returns:` for the return value
- `- Throws:` for errors thrown
- `- Complexity:` for algorithmic complexity

```swift
/// Removes and returns the element at the specified position.
///
/// - Parameter index: The position of the element to remove.
/// - Returns: The removed element.
/// - Complexity: O(*n*), where *n* is the length of the collection.
mutating func remove(at index: Int) -> Element { ... }
```

### O(1) complexity rule

Document the complexity of any computed property that is not O(1). Callers assume properties are O(1) by default. If a property does more than constant-time work, state the complexity explicitly.

```swift
/// The total weight of all items.
///
/// - Complexity: O(*n*), where *n* is the number of items.
var totalWeight: Double {
    items.reduce(0) { $0 + $1.weight }
}
```

For documentation patterns and examples, see [references/conventions-and-special-rules.md](references/conventions-and-special-rules.md).

## Clarity and Naming

Clarity at the point of use is the most important goal. Every design decision serves the person reading a call site.

**Clarity over brevity.** Longer names are acceptable when they remove ambiguity. Do not abbreviate.

```swift
// GOOD
employees.remove(at: position)

// BAD — ambiguous: remove the element? remove at position?
employees.remove(position)
```

**Include words needed to avoid ambiguity.** If omitting a word makes the call site unclear, keep it.

```swift
// GOOD — "at" clarifies the argument's role
friends.remove(at: index)

// BAD — is "index" the element to remove or the position?
friends.remove(index)
```

**Omit needless words.** Do not repeat type information already available from the context.

```swift
// GOOD
allViews.remove(cancelButton)

// BAD — "Element" repeats the type
allViews.removeElement(cancelButton)
```

**Name variables and parameters by role, not type.** Use the entity's role in the current context, not its type name.

```swift
// GOOD — describes the role
var greeting: String
func add(_ observer: NSObject, for keyPath: String)

// BAD — names the type
var string: String
func add(_ object: NSObject, for string: String)
```

**Compensate for weak type information.** When a parameter type is `Any`, `AnyObject`, or a fundamental type like `Int` or `String`, add role-clarifying words to the name.

```swift
// GOOD — role is clear despite weak types
func addObserver(_ observer: NSObject, forKeyPath path: String)

// BAD — what does "string" mean here?
func add(_ object: NSObject, for string: String)
```

For extended naming examples and patterns, see [references/naming-and-clarity.md](references/naming-and-clarity.md).

## Fluent Usage and Protocols

**Call sites read as grammatical English.** Prefer names that form grammatical phrases at the point of use.

```swift
// GOOD — reads fluently
x.insert(y, at: z)          // "x, insert y at z"
x.subviews.remove(at: i)    // "x's subviews, remove at i"
x.makeIterator()             // "x, make iterator"

// BAD — ungrammatical
x.insert(y, position: z)
x.subviews.remove(i)
```

**Initializer first argument.** The first argument to an initializer should not form a phrase continuing the type name.

```swift
// GOOD
let foreground = Color(red: 32, green: 64, blue: 128)

// BAD — "Color with red" reads awkwardly
let foreground = Color(havingRGBValuesRed: 32, green: 64, blue: 128)
```

**Protocol naming conventions:**

| Protocol describes | Naming pattern | Examples |
|--------------------|----------------|----------|
| What something **is** | Noun | `Collection`, `IteratorProtocol` |
| A **capability** | `-able`, `-ible`, or `-ing` suffix | `Equatable`, `Hashable`, `Sendable` |

## General Conventions

**Casing.** Types and protocols use `UpperCamelCase`. Everything else uses `lowerCamelCase`. Acronyms that are commonly all-caps in American English appear uniformly upper- or lower-cased based on position.

```swift
var utf8Bytes: [UTF8.CodeUnit]
var isRepresentableAsASCII = true
var userSMTPServer: SMTPServer
```

**Methods and properties over free functions.** Prefer methods and properties. Use free functions only when:
1. There is no obvious `self` — `min(x, y)`
2. The function is an unconstrained generic — `print(value)`
3. The function syntax is established domain notation — `sin(x)`

**Default arguments over method families.** Prefer a single method with default parameters over a family of methods that differ only in which parameters they accept. Place defaulted parameters at the end. Parameters with default values should always have argument labels — defaulted parameters are usually omitted at call sites, so their labels must be clear when they do appear.

```swift
// GOOD — labeled with defaults
func decode(_ data: Data, encoding: String.Encoding = .utf8) -> String?

// BAD — method family
func decode(_ data: Data) -> String?
func decode(_ data: Data, encoding: String.Encoding) -> String?
```

**Overload safety.** Methods may share a base name when they operate in different type domains or when their meaning is clear from context. Avoid return-type-only overloads that cause ambiguity at the call site.

For casing edge cases, overload patterns, and tuple/closure naming, see [references/conventions-and-special-rules.md](references/conventions-and-special-rules.md).

## Common Mistakes

| Mistake | Correction |
|---|---|
| Ambiguous or missing labels | Make the call read grammatically, such as `remove(at:)`. |
| Wrong mutating/nonmutating form | Use imperative verbs for mutation and a grammatical `-ed`/`-ing` or noun form for copies. |
| Names describe types or implementation | Name roles and semantic effects. |
| Public API lacks purpose or complexity docs | Add a concise summary and document non-O(1) properties. |
| `form` or factory prefixes are misapplied | Reserve `form` for noun operations; use `make` for factories. |
| Type information is repeated | Remove words already clear from the declaration and context. |
| Overloads differ only by return type | Add a semantic name or parameter distinction. |
| Tuple or closure components are positional | Label public components and closure parameters. |

## Review Checklist

### Argument Labels
- [ ] First argument follows the correct label rule (grammatical phrase, prepositional, conversion, or labeled)
- [ ] Prepositional labels do not incorrectly group independent arguments
- [ ] Value-preserving conversion initializers omit the first label
- [ ] All non-special-case arguments have labels

### Naming Semantics
- [ ] Mutating methods use imperative verb form
- [ ] Nonmutating methods use -ed/-ing or noun form
- [ ] Mutating/nonmutating pairs follow the correct pattern (verb pair or noun/form-noun pair)
- [ ] Boolean properties read as assertions (`isEmpty`, `isValid`, `contains`)
- [ ] Variables and parameters are named by role, not type

### Documentation
- [ ] Every public declaration has a doc comment
- [ ] Summaries are single sentence fragments ending in a period
- [ ] Summaries describe the correct thing per declaration kind (action, access, creation, entity)
- [ ] Non-O(1) computed properties document their complexity
- [ ] Parameters, return values, and thrown errors are documented with symbol markup

### Conventions
- [ ] Types and protocols use UpperCamelCase; everything else uses lowerCamelCase
- [ ] Acronyms are uniformly cased based on position
- [ ] Default arguments are preferred over method families
- [ ] Overloads do not differ only in return type
- [ ] Protocol names follow the noun (is-a) or suffix (capability) convention

## References

- Naming clarity, role-based naming, weak-type compensation, and terminology: [references/naming-and-clarity.md](references/naming-and-clarity.md)
- Argument label edge cases, parameter naming, and default argument strategy: [references/argument-labels-and-parameters.md](references/argument-labels-and-parameters.md)
- Side-effect naming examples, -ed/-ing decision tree, form- prefix patterns, and factory methods: [references/side-effects-and-mutating-pairs.md](references/side-effects-and-mutating-pairs.md)
- Casing edge cases, complexity documentation, overload safety, tuple/closure naming, and free function exceptions: [references/conventions-and-special-rules.md](references/conventions-and-special-rules.md)
