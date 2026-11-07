# Swift Attributes and C Interoperability

Attributes and interoperability features for Swift. Covers C-calling-convention export, module disambiguation, performance annotations, and symbol visibility control.

## Contents

- [C Interoperability — `@c` Attribute](#c-interoperability--c-attribute)
- [Module Selectors](#module-selectors)
- [Performance Annotations](#performance-annotations)
- [Symbol Visibility and Layout](#symbol-visibility-and-layout)

## C Interoperability — `@c` Attribute

For functions, the `@c` attribute (SE-0495) marks a Swift declaration for direct C-calling-convention export. The function becomes callable from C, C++, and Objective-C without bridging headers or `@_cdecl`.

```swift
@c(MyLib_processBuffer)
public func processBuffer(_ buffer: UnsafePointer<UInt8>?, _ count: Int32) -> Int32 {
    guard let buffer else { return 0 }
    return buffer.pointee == 0 ? 0 : count
}
```

**Requirements:**
- Parameters and return types must be C-compatible (primitives, pointers, tuples of C-compatible types)
- No Swift-only types (`String`, `Array`, `UnsafeBufferPointer`, closures, generic placeholders, etc.) in the signature
- The function must be a module-level free function (not a method)
- Use `@c(CustomName)` when the C symbol should differ from the Swift function name
- SE-0495 also supports `@c` enums with C-compatible integer raw types; this section focuses on function export

## Module Selectors

SE-0491 adds `ModuleName::symbolName` syntax to disambiguate identically named symbols from different modules without `import` aliasing.

```swift
import NetworkingA
import NetworkingB

// Both modules export a top-level `configure()` function
func setup() {
    NetworkingA::configure()
    NetworkingB::configure()
}

// Works with types too
let client: NetworkingA::Client = .init()
```

## Performance Annotations

### `@specialized`

SE-0460 makes `@specialized` an official attribute (previously underscored as `@_specialize`). Forces the compiler to emit a specialized version of a generic function for specific concrete types.

```swift
@specialized(where T == Int)
@specialized(where T == Double)
func sum<T: Numeric>(_ values: [T]) -> T {
    values.reduce(.zero, +)
}
```

### `@inline(always)` Guarantee

SE-0496 makes `@inline(always)` a guaranteed inlining request for direct function references. Previously it was a hint the compiler could ignore. A compilation error is now emitted when the compiler can prove direct-call inlining is impossible (e.g., recursive calls).

```swift
@inline(always)
func fastPath(_ x: Int) -> Int {
    x &+ 1  // Guaranteed for direct calls that can be inlined
}
```

The guarantee does not apply to dynamic calls through first-class function
values, protocol values, generic constraints, or non-final class dispatch.

## Symbol Visibility and Layout

### `@export`

SE-0497 gives explicit control over symbol visibility and definition availability:

- `@export(interface)` — ensures a callable symbol exists in the binary but hides the definition from clients (no inlining/specialization by external callers). Replaces `@_neverEmitIntoClient`.
- `@export(implementation)` — makes the definition available for inlining/specialization but does not guarantee a callable symbol. Replaces `@_alwaysEmitIntoClient`.

```swift
@export(interface)
public func stableAPI() -> Int {
    // Callable symbol guaranteed; definition hidden from clients
    return computeValue()
}
```

### `@section` and `@used`

SE-0492 places global or static variables into named binary sections and prevents dead-stripping. Primarily for Embedded Swift and systems programming.

```swift
@section(".mydata") @used
var configFlag: Int32 = 1
```

Use it only on stored variables in non-generic contexts with compile-time-known
or static initialization.
