---
name: memory
description: Swift 6.2 InlineArray and Span types for zero-overhead memory access, fixed-size collections, and safe pointer alternatives. Use when optimizing performance-critical code paths.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# InlineArray and Span

Guidance for Swift 6.2's low-level memory types: `InlineArray` for fixed-size inline storage without heap allocation, and `Span` for safe, zero-cost access to contiguous memory. These replace common uses of `UnsafeBufferPointer` and hand-tuned tuple storage with compiler-checked alternatives.

## When This Skill Activates

Use this skill when the user:
- Asks about **InlineArray**, **fixed-size arrays**, or **stack-allocated collections**
- Mentions **Span**, **MutableSpan**, **RawSpan**, or **UTF8Span**
- Wants to **eliminate heap allocations** in hot paths
- Is replacing **UnsafeBufferPointer** or **UnsafePointer** with safe alternatives
- Asks about **value generics** or `let count: Int` generic parameters
- Needs **zero-copy** access to collection storage
- Mentions **inline storage**, **contiguous memory**, or **memory layout**
- Is doing **binary parsing**, **signal processing**, or **embedded Swift** work
- Wants to avoid **copy-on-write overhead** for small fixed collections
- Asks about **non-escapable types** or **lifetime dependencies** in Swift

## Decision Tree

```
What memory optimization do you need?
│
├─ A fixed-size collection that never grows/shrinks
│  │
│  ├─ Size known at compile time, stored on stack
│  │  └─ InlineArray<N, Element>
│  │     ├─ No heap allocation
│  │     ├─ No reference counting
│  │     └─ No copy-on-write (eager copies)
│  │
│  └─ Size may vary at runtime
│     └─ Array<Element> (standard library)
│
├─ Safe read access to contiguous memory
│  │
│  ├─ Read-only access to typed elements
│  │  └─ Span<Element>
│  │
│  ├─ Mutable access to typed elements
│  │  └─ MutableSpan<Element>
│  │
│  ├─ Read-only access to raw bytes
│  │  └─ RawSpan
│  │
│  ├─ Mutable access to raw bytes
│  │  └─ MutableRawSpan
│  │
│  ├─ Unicode text processing
│  │  └─ UTF8Span
│  │
│  └─ Initializing a new collection's storage
│     └─ OutputSpan
│
├─ Unsafe pointer access (legacy or interop)
│  └─ UnsafeBufferPointer / UnsafeMutableBufferPointer
│     └─ Prefer Span instead for new code
│
└─ Standard dynamic collection
   └─ Array<Element>
      ├─ Heap-allocated, copy-on-write
      └─ Grows/shrinks dynamically
```

## API Availability

| API | Minimum Version | Notes |
|-----|----------------|-------|
| `InlineArray<let count: Int, Element>` | Swift 6.2 | Uses value generics; `@frozen` struct |
| `Span<Element>` | Swift 6.2 | Non-escapable, lifetime-dependent |
| `MutableSpan<Element>` | Swift 6.2 | Mutable variant of Span |
| `RawSpan` | Swift 6.2 | Untyped byte-level access |
| `MutableRawSpan` | Swift 6.2 | Mutable untyped byte access |
| `UTF8Span` | Swift 6.2 | Unicode-aware text processing |
| `OutputSpan` | Swift 6.2 | For initializing collection storage |
| `.span` property on `Array` / `ArraySlice` / `InlineArray` | Swift 6.2 | Returns `Span<Element>` |
| `.bytes` property on `Data` | Swift 6.2 | Returns `RawSpan` (byte-level access) |
| `[N of T]` sugar, `InlineArray(repeating:)`, closure init | Swift 6.4 | `[256 of Int]` as a type; `InlineArray { i in … }` (WWDC26 262) |
| `UniqueArray` / `UniqueBox` / `Ref` / `MutableRef` | Swift 6.4 | Noncopyable containers + single-value spans — see `swift-performance.md` |

## Top 5 Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Trying to append/remove elements on `InlineArray` | `InlineArray` is fixed-size; use `Array` if you need dynamic sizing |
| 2 | Returning a `Span` from a function | `Span` is non-escapable and cannot outlive its source; restructure to process data within the same scope |
| 3 | Capturing a `Span` in a closure | `Span` cannot be captured; pass the span as a parameter or use `Array` for escaped contexts |
| 4 | Using `InlineArray` for large or frequently copied collections | `InlineArray` copies eagerly (no COW); use `Array` for large data that is shared or copied often |
| 5 | Accessing a `Span` after mutating the source container | Mutation invalidates the span; re-acquire the span after any modification |

## InlineArray

### Declaration

```swift
@frozen struct InlineArray<let count: Int, Element> where Element: ~Copyable
```

### Initialization

```swift
// Explicit count
let a: InlineArray<4, Int> = [1, 2, 4, 8]

// Count inferred from literal
let b: InlineArray<_, Int> = [1, 2, 4, 8]  // count = 4

// Element type inferred from literal
let c: InlineArray<4, _> = [1, 2, 4, 8]    // Element = Int

// Both inferred
let d: InlineArray = [1, 2, 4, 8]           // InlineArray<4, Int>
```

### Memory Layout

Elements are stored contiguously with no overhead. Size equals `count * MemoryLayout<Element>.stride`:

```swift
MemoryLayout<InlineArray<0, UInt16>>.size       // 0
MemoryLayout<InlineArray<0, UInt16>>.stride      // 1
MemoryLayout<InlineArray<3, UInt16>>.size        // 6  (2 bytes x 3)
MemoryLayout<InlineArray<3, UInt16>>.stride       // 6
MemoryLayout<InlineArray<3, UInt16>>.alignment   // 2  (same as UInt16)
```

### Basic Usage

```swift
var array: InlineArray<3, Int> = [1, 2, 3]

// Subscript access
array[0] = 4

// Iterate via indices
for i in array.indices {
    print(array[i])
}

// Copies are eager (no copy-on-write)
var copy = array
copy[0] = 99
// array[0] is still 4
```

### InlineArray vs Array

| Characteristic | InlineArray | Array |
|---------------|-------------|-------|
| Storage | Inline (stack or enclosing type) | Heap-allocated buffer |
| Size | Fixed at compile time | Dynamic |
| Copy semantics | Eager (full copy) | Copy-on-write |
| Reference counting | None | Yes (buffer reference) |
| Exclusivity checks | None | Yes |
| Append/remove | Not supported | Supported |

## Span Family

### Span (Read-Only)

Provides safe, direct access to contiguous typed memory. Non-escapable -- cannot outlive the source.

```swift
let array = [1, 2, 3, 4]
let span = array.span  // Span<Int>

// Access elements
let first = span[0]
let count = span.count

// Iterate
for element in span {
    print(element)
}
```

### MutableSpan

Mutable access to contiguous storage:

```swift
var array = [1, 2, 3, 4]
array.withMutableSpan { span in
    for i in span.indices {
        span[i] *= 2
    }
}
// array is now [2, 4, 6, 8]
```

### RawSpan

Untyped byte-level access for binary data:

```swift
let data = Data([0xFF, 0x00, 0xAB, 0xCD])
let rawSpan = data.bytes  // RawSpan over the bytes
let value = rawSpan.unsafeLoadUnaligned(as: UInt8.self)  // loading integers is safe
```

For **writing** into uninitialized memory, `OutputRawSpan` builds a `Data` incrementally with no manual offset tracking (WWDC25 312):

```swift
let output = Data(rawCapacity: totalBytes) { outputSpan in
    // append bytes; outputSpan.count tracks what's been written
}
```

For binary parsers, Apple ships the open-source **swift-binary-parsing** library (`ParserSpan`, overflow-safe parsing initializers by signedness/bit-width/byte-order, validating parsers for RawRepresentable) — already used inside Apple (WWDC25 312).

### UTF8Span

Specialized for safe and efficient Unicode processing of UTF-8 encoded text.

## Safety Constraints

### Non-Escapable: Cannot Return from Functions

`Span` has a lifetime dependency on the container it was derived from. It cannot be returned:

```swift
// ❌ Wrong -- Span cannot escape the function
func getSpan() -> Span<UInt8> {
    let array: [UInt8] = Array(repeating: 0, count: 128)
    return array.span  // Compiler error
}

// ✅ Right -- process within the same scope
func processData(_ array: [UInt8]) {
    let span = array.span
    // Use span here
    let sum = span.reduce(0, +)
}
```

### Invalidation on Mutation

Modifying the source container invalidates any existing span:

```swift
// ❌ Wrong -- span is invalidated after mutation
var array = [1, 2, 3]
let span = array.span
array.append(4)        // Invalidates span
// let x = span[0]     // Undefined behavior

// ✅ Right -- re-acquire span after mutation
var array = [1, 2, 3]
array.append(4)
let span = array.span  // Fresh span after mutation
let x = span[0]        // Safe
```

## Performance Considerations

### When InlineArray Wins

- **Small, fixed-size data** (e.g., color components, matrix rows, coordinate tuples)
- **Hot loops** where heap allocation / ARC overhead is measurable
- **Embedded Swift** or contexts with no allocator
- **Struct fields** that should be stored inline rather than behind a pointer

### When Array Wins

- Collection size is unknown or variable
- Collection is large and frequently shared (COW avoids full copies)
- Collection is passed across module boundaries where dynamic sizing is needed

### When Span Wins Over UnsafePointer

- **All new code** that needs contiguous memory access -- Span provides the same performance with compile-time safety
- **Binary parsing** where you read structured data from a byte buffer
- **Algorithm implementations** that operate on slices of memory

### When UnsafePointer Is Still Needed

- C interop requiring raw pointer parameters
- Legacy APIs that predate Span adoption
- Interfacing with system calls that take pointer arguments

## When to Use / When NOT to Use

### Use InlineArray When

- You know the exact element count at compile time
- You need zero heap allocation (stack storage)
- The collection is small (< ~64 elements as a guideline)
- You modify in place but rarely copy the whole collection
- You are writing performance-critical or embedded code

### Do NOT Use InlineArray When

- The collection size varies at runtime
- The collection is large and frequently copied (no COW means expensive copies)
- You need to append, insert, or remove elements
- You benefit from sharing storage across variables

### Use Span When

- You need fast, safe, read-only access to contiguous memory
- You want to replace `UnsafeBufferPointer` with a safe alternative
- You are processing data in place without needing to escape the reference
- You are implementing high-performance algorithms on collection storage

### Do NOT Use Span When

- You need to store the reference for later use (Span is non-escapable)
- You need to pass memory access across async boundaries
- You need mutable access (use `MutableSpan` instead)
- C interop requires actual `UnsafePointer` arguments

## Review Checklist

### InlineArray

- [ ] Count is a compile-time constant (value generic), not a runtime variable
- [ ] Collection size is genuinely fixed and will not need dynamic resizing
- [ ] No code attempts to `append`, `insert`, or `remove` elements
- [ ] Copies are intentional -- each assignment copies all elements eagerly
- [ ] Large `InlineArray` values are not copied in hot loops (pass by `inout` or reference)
- [ ] `MemoryLayout` is verified if precise byte layout matters (e.g., GPU buffers, file formats)

### Span

- [ ] Span is never returned from a function or stored in a property
- [ ] Span is never captured in an escaping closure
- [ ] Source container is not mutated while a span is in use
- [ ] Span is re-acquired after any mutation to the source
- [ ] Correct span variant is used: `Span` (read), `MutableSpan` (write), `RawSpan` (bytes)
- [ ] `UnsafeBufferPointer` is only used where C interop requires it; prefer `Span` otherwise

### General Performance

- [ ] Profile before optimizing -- confirm heap allocation or ARC is the actual bottleneck
- [ ] Small fixed collections use `InlineArray` instead of `Array` in measured hot paths
- [ ] `Span` is used instead of `UnsafeBufferPointer` for safe contiguous access
- [ ] No premature optimization -- `Array` is correct default for most code

What the payoff can look like when profiling confirms the bottleneck — Apple's QOI-parser case study (WWDC25 312): preallocating one buffer instead of ~1M transient arrays cut execution time over 50%; adopting InlineArray + RawSpan/OutputRawSpan made it another 6× faster by eliminating all retain/release traffic. See **swift-performance.md** for the full cost model (calls, copying, generics/existentials, closures, noncopyable ownership) and the profiling-symptom table.

## References

- **swift-performance.md** (this skill) — the Swift cost model: allocation, ARC, exclusivity, dispatch, `~Copyable` ownership
- [Swift Standard Library - InlineArray](https://developer.apple.com/documentation/swift/inlinearray)
- [Swift Standard Library - Span](https://developer.apple.com/documentation/swift/span)
- [Value Generics in Swift](https://www.swift.org/blog/value-generics/)
- [SE-0453: Vector (InlineArray)](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0453-vector.md)
- [SE-0447: Span](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0447-span-access-shared-contiguous-storage.md)
- [WWDC25 — Improve memory usage and performance with Swift](https://developer.apple.com/videos/play/wwdc2025/312/)
