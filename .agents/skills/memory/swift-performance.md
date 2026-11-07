# Swift Performance Cost Model

How Swift code actually costs: calls, memory layout, allocation, copying, generics, closures, and async overhead — plus the ownership tools (`consuming`/`borrowing`/`~Copyable`) that remove those costs. Distilled from Apple's WWDC24 "Explore Swift performance" (10217), WWDC24 "Consume noncopyable types in Swift" (10170), WWDC25 "Improve memory usage and performance with Swift" (312), and WWDC26 "What's new in Swift" (262).

## The Four Cost Centers (WWDC24 10217)

Low-level Swift performance is dominated by: (1) **calls** not optimized effectively, (2) wasteful **data representation**, (3) too much **memory allocation**, (4) unnecessary **copying/destroying of values**. Work top-down with Instruments first; drop to this cost model only when a hot region has no algorithmic fix left. If performance matters, automate measurements of your hot spots so you catch regressions — "including you accidentally confused the optimizer."

## Reading a Time Profile (WWDC25 312)

| Symbol in the profile | What it means |
|---|---|
| `platform_memmove` | Excessive copying |
| `swift_retain` / `swift_release` | Reference-counting traffic (Apple's demo: 7% + 7% of all samples) |
| `swift_beginAccess` / `swift_endAccess` | Runtime exclusivity checks (often: mutable state in a **class**) |
| `malloc`/`free` on Array/Data internals | Transient allocations in a hot loop |

Workflow: right-click a test's run button → **Profile the test** → Time Profiler (add Allocations for memory); use Invert Call Tree, the flame graph, and Reveal in Xcode.

### The QOI-parser case study numbers (WWDC25 312)

1. **Algorithmic first**: a `readByte()` that copied the whole `Data` per call made parsing quadratic; fixing it made it linear — the largest single win.
2. **Allocation elimination**: replacing a chained `flatMap`/`prefix` pipeline (~1M transient 3–4-element arrays, one per pixel) with one preallocated `Data(repeating:count:)` + offset writes → **over 50% execution-time reduction**.
3. **Exclusivity checks**: moving mutable properties out of a helper *class* into the parser *struct* eliminated `swift_beginAccess`/`swift_endAccess` entirely.
4. **InlineArray + RawSpan/OutputRawSpan**: **6× faster** again (all retain/release blocks gone). Cumulative: **16× over the post-algorithmic version, 700× over the original**.

## Memory: Where Values Live

- Cost ladder (WWDC24 10217): **global** memory ≈ free (allocated at load, fixed size, program lifetime) → **stack** ≈ free (pointer arithmetic; scoped lifetimes) → **heap** "substantially more expensive," and usually shared → managed by reference counting (retain/release are what you see in profiles).
- **Type dictates representation; context dictates placement.** Structs, tuples, and enums store contents **inline** in their container (declaration order); classes and actors store **out-of-line** — the container holds only a pointer.
- A synchronous function's locals are allocated by a single stack-pointer adjustment ("as close as it gets to free"). `MemoryLayout.size(ofValue:)` measures only the *inline* representation — `[Double]` reports 8 bytes (one buffer pointer).
- **Dynamically-sized types**: SDK value types that may add stored fields across OS versions (e.g. Foundation `URL`) and unconstrained generic parameters get runtime layout; in fixed-size containers (globals, call frames) they're stored via pointer + separate allocation. Constraining a generic `where T: AnyObject` guarantees pointer representation — much more efficient even without specialization.

## Copying and Ownership (WWDC24 10217)

Three ways code interacts with a value:
- **consume** — take ownership (assigning into storage). `consume x` transfers explicitly; using `x` afterward is a compile error.
- **mutate** — temporary exclusive write access (`inout`, `mutating` methods); exclusivity enforced.
- **borrow** — read-only access asserting nobody consumes/mutates meanwhile; how typical arguments are passed.

Copy costs: copying a class reference = one retain. Copying a struct = recursively copying every stored property — **one retain per reference-typed field**. Apple's example: a `Person` struct holding two `String`s, a `Date`, and an array costs 3+ retains per copy *and* duplicates inline storage; a class would cost one retain and share storage. Large, frequently-copied structs can be worse than a class — there is "no hard-and-fast rule."

- **Defensive copies**: to borrow, Swift must prove no simultaneous mutation. It usually can for locals; for **class properties it often can't**, and inserts a defensive copy at calls like `print(object.array)`.
- Best-of-both pattern: **value semantics + out-of-line storage = struct wrapping a class with copy-on-write** — exactly how `Array`, `Dictionary`, and `String` are built.

## Calls, Generics, and Existentials (WWDC24 10217)

- Static dispatch's real win isn't the call itself — it's enabling **inlining and generic specialization**.
- A method declared **in the protocol body** is a requirement → dynamic dispatch through a witness table; the same-looking method declared **in a protocol extension** → static dispatch.
- Generic functions receive type metadata + witness tables as hidden parameters; when the concrete type is visible, the optimizer **specializes** — "removes any abstraction cost associated with generics."
- Existentials (`any P`) larger than the 3-word inline buffer are heap-allocated into the box. `[any DataModel]` boxes every element and defeats packing/specialization; `func update<Model: DataModel>(models: [Model])` keeps elements densely packed and specializable. Use `any` when you genuinely need heterogeneity — these are costs, not prohibitions.
- Forcing the optimizer's hand (WWDC26 262): `@specialized(where T == [UInt8])` (Swift 6.3) emits a specialization for hot instantiations; `@inline(always)` (Swift 6.4) is the forced-inlining counterpart to `@inline(never)` — pair with `final` for class methods.

## Closures (WWDC24 10217)

A function value is always a pair (function pointer, context pointer):
- **Non-escaping** closure → context stack-allocated, no memory management.
- **Escaping** closure → context heap-allocated + retain/release — "essentially an instance of an anonymous Swift class."
- **Captured `var`s are captured by reference**; an escaping capture forces the `var` itself into a heap box. `@escaping` + captured mutable locals = two-level heap traffic. Capture `let` copies where possible.

## Async Overhead (WWDC24 10217)

Async functions keep suspension-crossing state on task-owned heap slabs with stack discipline ("typically significantly faster than malloc") and are split into partial functions at suspension points. Net: performance ≈ synchronous code "just with a bit higher overhead for calls." Don't fear `async` in hot-ish paths; do fear per-element actor hops (see `../concurrency-patterns/concurrency-internals.md`).

## Noncopyable Types: Compile-Time Unique Ownership (WWDC24 10170)

`Copyable` is a real protocol that Swift infers on every type, generic parameter, and protocol; `~Copyable` **suppresses** that default.

Parameter conventions are mandatory for noncopyable parameters:

| Convention | Meaning | Constraint inside |
|---|---|---|
| `consuming` | Takes the value away from the caller | Yours to mutate; caller loses it |
| `borrowing` | Read-only, "like a let binding" | Cannot copy it |
| `inout` | Temporary write access | If you consume it, you must reinitialize before returning |

The bug-prevention case — runtime assertions become compile errors:

```swift
// ✅ run() statically cannot be called twice; abandoning the value cancels via deinit
struct BankTransfer: ~Copyable {
    consuming func run() {
        // ... perform transfer ...
        discard self                      // success: skip deinit's cancel
    }
    deinit { cancel() }                   // dropped on any other path → auto-cancel
}

func schedule(_ transfer: consuming BankTransfer, after delay: Duration) async throws {
    try await Task.sleep(for: delay)      // if this throws, transfer.deinit cancels it
    transfer.run()
}
```

Generics: a `~Copyable` constraint *broadens* the type universe (removes the implicit Copyable requirement) — lift the default at every level (`protocol Runnable: ~Copyable`, `func execute<T>(_ t: consuming T) where T: Runnable, T: ~Copyable`). Containers holding noncopyable values must themselves be `~Copyable`, with `extension Job: Copyable where Action: Copyable {}` restoring copyability conditionally. **Extension gotcha**: an unannotated `extension Job { }` implicitly constrains generic parameters to `Copyable` — write `where Action: ~Copyable` explicitly to cover noncopyable instantiations. (SE-0427, SE-0432, SE-0437; the standard library adopted `~Copyable` for `Optional`, `UnsafePointer`, `Result`.)

## Swift 6.4 Ownership Additions (WWDC26 262)

| API | Purpose |
|---|---|
| `borrow` / `mutate` accessors | Property accessors that hand out access without copying (replace get/set on hot properties) |
| `UniqueBox<Value: ~Copyable>` | Noncopyable heap box for large values — moves, never copies |
| `UniqueArray` | Array-like with noncopyable elements, no refcounting, dynamically sized |
| `Ref` / `MutableRef` | "Like Span but for one value" — non-escapable single-value references; hoist a repeated dictionary lookup: `var countRef = MutableRef(&counts[key, default: 0])` |
| `Iterable` protocol | for-in that **borrows** elements instead of copying (works with noncopyable elements; batch iteration via `nextSpan(maximumCount:)`) |
| `weak let` | Immutable weak reference — keeps real Sendable checking |

## Checklist

- [ ] Profiled before optimizing; hot symbols identified (`memmove`, `swift_retain`, `beginAccess`)
- [ ] Transient per-iteration allocations replaced with preallocated buffers
- [ ] Mutable hot-loop state lives in a struct, not a class (kills exclusivity checks)
- [ ] Hot protocol methods that don't need dynamism live in protocol extensions
- [ ] Homogeneous hot paths use generics (`some`/`<T: P>`), not `any P`
- [ ] Large frequently-copied structs weighed against class + COW wrapper
- [ ] Unique resources (file descriptors, transactions, tokens) modeled as `~Copyable` with `deinit` cleanup
- [ ] Escaping closures in hot paths audited for captured `var` heap boxes

## References

- [WWDC24 — Explore Swift performance](https://developer.apple.com/videos/play/wwdc2024/10217/)
- [WWDC24 — Consume noncopyable types in Swift](https://developer.apple.com/videos/play/wwdc2024/10170/)
- [WWDC25 — Improve memory usage and performance with Swift](https://developer.apple.com/videos/play/wwdc2025/312/)
- [WWDC26 — What's new in Swift](https://developer.apple.com/videos/play/wwdc2026/262/)
