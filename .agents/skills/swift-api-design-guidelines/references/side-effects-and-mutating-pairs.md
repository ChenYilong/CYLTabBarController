# Side Effects and Mutating Pairs

Extended examples for side-effect naming, the -ed/-ing decision tree, form- prefix patterns, Boolean naming, and factory methods.

## Contents

- [Side-Effect Naming Extended Examples](#side-effect-naming-extended-examples)
- [The -ed/-ing Decision Tree](#the--ed-ing-decision-tree)
- [Form- Prefix Patterns](#form--prefix-patterns)
- [Boolean Naming Patterns](#boolean-naming-patterns)
- [Factory Method Naming](#factory-method-naming)

## Side-Effect Naming Extended Examples

### Mutating — imperative verbs

Methods that change the receiver's state use imperative verb form.

```swift
array.sort()
array.append(newElement)
array.removeAll()
set.insert(member)
dictionary.updateValue(newValue, forKey: key)
buffer.replaceSubrange(range, with: newElements)
```

### Nonmutating — nouns, past participles, descriptions

Methods that return a value without changing the receiver use a form that describes the result.

```swift
let sorted = array.sorted()
let distance = point.distance(to: origin)
let trimmed = string.trimmingCharacters(in: .whitespaces)
let union = setA.union(setB)
let successor = index.advanced(by: 1)
let prefix = array.prefix(3)
```

### Mixed — same type, both variants

When both exist, the naming makes the difference obvious at every call site.

```swift
// Mutating
array.sort()
// Nonmutating — returns new value
let newArray = array.sorted()

// Mutating
set.formUnion(other)
// Nonmutating — returns new value
let combined = set.union(other)
```

## The -ed/-ing Decision Tree

Use this decision tree to choose between `-ed` and `-ing` for the nonmutating variant of a verb-described operation.

**Step 1: Try the past participle (`-ed`).** Read the phrase: "a [verb]-ed [noun]". If it sounds grammatical, use `-ed`.

```
sort → sorted          ✓  "a sorted array" sounds correct
sortLines → sortedLines ✓ "sorted lines" describes the result
reverse → reversed      ✓ "a reversed collection" sounds correct
shuffle → shuffled      ✓ "a shuffled deck" sounds correct
```

**Step 2: Does -ed fail the result-description test?**

Use the present participle (`-ing`) only when the `-ed` form is ungrammatical or describes the direct object rather than the returned receiver or result. A direct object is a clue to check the grammar, not the rule by itself.

```
append → appending                  "appended" does not describe the returned receiver clearly
stripNewlines → strippingNewlines   direct-object pattern from the guidelines
```

### Extended -ed/-ing examples and naming patterns

| Mutating | Nonmutating | Suffix | Reasoning |
|----------|-------------|--------|-----------|
| `sort()` | `sorted()` | -ed | "a sorted array" |
| `sortLines()` | `sortedLines()` | -ed | "sorted lines" describes the result |
| `reverse()` | `reversed()` | -ed | "a reversed collection" |
| `shuffle()` | `shuffled()` | -ed | "a shuffled deck" |
| `append(_:)` | `appending(_:)` | -ing | `appended` does not describe the returned receiver clearly |
| `filter(_:)` | `filter(_:)` | n/a | nonmutating only in stdlib |
| `drop(while:)` | `drop(while:)` | n/a | nonmutating only in stdlib |

## Form- Prefix Patterns

The `form` prefix applies only to noun-described operations where the nonmutating version is the noun itself.

### Standard library examples

| Nonmutating (noun) | Mutating (form- prefix) |
|---------------------|------------------------|
| `union(other)` | `formUnion(other)` |
| `intersection(other)` | `formIntersection(other)` |
| `symmetricDifference(other)` | `formSymmetricDifference(other)` |

### When NOT to use form-

Do not apply `form` to verb-described operations. The imperative verb form is already the mutating version.

```swift
// WRONG — sort is a verb, not a noun
mutating func formSort()       // ✗
mutating func sort()           // ✓

// WRONG — append is a verb
mutating func formAppend(_:)   // ✗
mutating func append(_:)       // ✓
```

The `form` prefix exists because the noun form (`union`) is naturally the nonmutating name, and the mutating version needs a distinct name. Verbs do not have this problem — the imperative (`sort`) and participle (`sorted`) are already distinct.

## Boolean Naming Patterns

Boolean properties and methods read as assertions about the receiver. They answer a yes/no question.

```swift
// Properties — "is" prefix for adjectives
line.isEmpty
url.isFileURL
connection.isSecure
view.isHidden
option.isEnabled

// Properties — no prefix for verb phrases
set.contains(element)        // "set contains element"
string.hasPrefix("https")    // "string has prefix"
array.canAppend(element)     // "array can append element"

// BAD patterns
line.empty          // is this a verb ("empty the line") or adjective?
list.include        // verb or boolean?
node.leaf           // noun, not an assertion
```

## Factory Method Naming

Factory methods that create and return a new value use the `make` prefix. This distinguishes them from initializers and from methods that return existing values.

```swift
// GOOD — factory creates a new value
let iterator = collection.makeIterator()
let buffer = parser.makeBuffer()
let snapshot = store.makeSnapshot()

// BAD — wrong prefix
let iterator = collection.createIterator()    // use "make"
let buffer = parser.buildBuffer()             // use "make"
let snapshot = store.getSnapshot()            // "get" implies retrieval, not creation
```

The `make` prefix signals to callers that the returned value is freshly created, distinct from any cached or shared state.
