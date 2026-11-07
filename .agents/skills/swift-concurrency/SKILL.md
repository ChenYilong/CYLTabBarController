---
name: swift-concurrency
description: "Resolve Swift concurrency compiler errors, adopt approachable concurrency (SE-0466), and write data-race-safe async code. Use when fixing Sendable conformance errors, actor isolation warnings, or strict concurrency diagnostics; when adopting default MainActor isolation, @concurrent, nonisolated(nonsending), or Task.immediate; when designing actor-based architectures, structured concurrency with TaskGroup, or background work offloading; or when migrating from @preconcurrency to full Swift 6 strict concurrency."
---

# Swift Concurrency

Review, fix, and write concurrent Swift code targeting Swift 6.3+. Gate Swift
6.4 / Xcode 27 beta cleanup APIs behind explicit toolchain and availability
checks. Apply actor isolation, Sendable safety, and modern concurrency patterns
with minimal behavior changes.

## Contents

- [Triage Workflow](#triage-workflow)
- [Swift 6.2 Language Changes](#swift-62-language-changes)
- [Actor Isolation Rules](#actor-isolation-rules)
- [Sendable Rules](#sendable-rules)
- [Structured Concurrency Patterns](#structured-concurrency-patterns)
- [Task Cancellation](#task-cancellation)
- [Actor Reentrancy](#actor-reentrancy)
- [AsyncSequence and AsyncStream](#asyncsequence-and-asyncstream)
- [`@Observable and Concurrency`](#observable-and-concurrency)
- [Synchronization Primitives](#synchronization-primitives)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Triage Workflow

When diagnosing a concurrency issue, follow this sequence:

### Step 1: Capture context

- Copy the exact compiler diagnostic(s) and the offending symbol(s).
- Identify the project's concurrency settings:
  - Swift language version (must be 6.2+).
  - Xcode/toolchain version for version-specific features and release-note
    workarounds.
  - Whether Approachable Concurrency is enabled.
  - Whether Default Actor Isolation is set to `MainActor`.
  - Swift 6 strict concurrency status: complete/errors in Swift 6 language mode;
    Complete / Targeted / Minimal only when auditing Swift 5 migration settings.
- Determine the current actor context of the code (`@MainActor`, custom `actor`,
  `nonisolated`) and whether a default isolation mode is active.
- Confirm whether the code is UI-bound or intended to run off the main actor.

### Step 2: Apply the smallest safe fix

Prefer edits that preserve existing behavior while satisfying data-race safety.

| Situation | Recommended fix |
|---|---|
| UI-bound type | Annotate the type or relevant members with `@MainActor`. |
| Protocol conformance on MainActor type | Use an isolated conformance: `extension Foo: @MainActor Proto`. |
| Global / static state | Protect with `@MainActor` or move into an actor. |
| Background work needed | Use a `@concurrent` async function on a `nonisolated` type. |
| Sendable error | Prefer immutable value types. Add `Sendable` only when correct. |
| Cross-isolation callback | Use `sending` parameters (SE-0430) for finer control. |

### Step 3: Verify

- Rebuild and confirm the diagnostic is resolved.
- Check for new warnings introduced by the fix.
- Ensure no unnecessary `@unchecked Sendable` or `nonisolated(unsafe)` was added.
- For build-setting reviews, stop at settings plus the smallest code-level
  remediation. Do not add Thread Sanitizer, broad migration ordering, or
  architecture advice unless the prompt asks for diagnostics or migration.

## Swift 6.2 Language Changes

Swift 6.2 introduces "approachable concurrency" -- a set of language changes
that make concurrent code safer by default while reducing annotation burden.
In Xcode, Approachable Concurrency and Default Actor Isolation are separate
build settings: use Approachable Concurrency for the bundled upcoming-feature
flags, and set Default Actor Isolation to `MainActor` when you want unannotated
code inferred as `@MainActor`.

### SE-0466: Default MainActor Isolation

With the `-default-isolation MainActor` compiler flag, SwiftPM
`.defaultIsolation(MainActor.self)`, or Xcode's `Default Actor Isolation`
setting set to `MainActor`, unannotated declarations in the module are inferred
as `@MainActor` unless explicitly opted out.

**Effect:** Eliminates most data-race safety errors for UI-bound code and
global/static state without writing `@MainActor` everywhere.

```swift
// With default MainActor isolation enabled, these are implicitly @MainActor:
final class StickerLibrary {
    static let shared = StickerLibrary()  // safe -- on MainActor
    var stickers: [Sticker] = []
}

final class StickerModel {
    let photoProcessor = PhotoProcessor()
    var selection: [PhotosPickerItem] = []
}

// Conformances are also implicitly isolated:
extension StickerModel: Exportable {
    func export() {
        photoProcessor.exportAsPNG()
    }
}
```

**When to use:** Recommended for apps, scripts, and other executable targets
where most code is UI-bound. Not recommended for library targets that should
remain actor-agnostic.

### SE-0461: nonisolated(nonsending)

Nonisolated async functions now stay on the caller's actor by default instead
of hopping to the global concurrent executor. This is the
`nonisolated(nonsending)` behavior.

```swift
class PhotoProcessor {
    func extractSticker(data: Data, with id: String?) async -> Sticker? {
        // In Swift 6.2+, this runs on the caller's actor (e.g., MainActor)
        // instead of hopping to a background thread.
        // ...
    }
}

@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            return nil
        }
        // No data race -- photoProcessor stays on MainActor
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

Use `@concurrent` to explicitly request background execution when needed.

### `@concurrent` Attribute

`@concurrent` ensures a function always runs on the concurrent thread pool,
freeing the calling actor to run other tasks.

```swift
class PhotoProcessor {
    var cachedStickers: [String: Sticker] = [:]

    func extractSticker(data: Data, with id: String) async -> Sticker {
        if let sticker = cachedStickers[id] { return sticker }

        let sticker = await Self.extractSubject(from: data)
        cachedStickers[id] = sticker
        return sticker
    }

    @concurrent
    static func extractSubject(from data: Data) async -> Sticker {
        // Expensive image processing -- runs on background thread pool
        // ...
    }
}
```

To move a function to a background thread, show both opt-outs together:
1. Ensure the containing type is `nonisolated` or the function can be called
   from a nonisolated context.
2. Add `@concurrent` to the offloaded function. `nonisolated` alone does not
   move CPU-heavy work off the caller's actor.
3. Add `async` if not already asynchronous.
4. Add `await` at call sites.

```swift
nonisolated struct PhotoProcessor {
    @concurrent
    func process(data: Data) async -> ProcessedPhoto? { /* ... */ }
}

// Caller:
processedPhotos[item.id] = await PhotoProcessor().process(data: data)
```

### SE-0472: Task.immediate

`Task.immediate` starts executing synchronously on the current actor before
any suspension point, rather than being enqueued.

```swift
Task.immediate { await handleUserInput() }
```

Use for latency-sensitive work that should begin without delay. There is also
`Task.immediateDetached` which combines immediate start with detached semantics.

### SE-0475: Transactional Observation (Observations)

`Observations { }` provides async observation of `@Observable` types via
`AsyncSequence`, enabling transactional change tracking.

```swift
for await _ in Observations { model.count } {
    print("Count changed to \(model.count)")
}
```

### Isolated Conformances

A conformance that needs MainActor state is called an *isolated conformance*.
The compiler ensures it is only used in a matching isolation context.

```swift
protocol Exportable {
    func export()
}

// Isolated conformance: only usable on MainActor
extension StickerModel: @MainActor Exportable {
    func export() {
        photoProcessor.exportAsPNG()
    }
}

@MainActor
struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // OK -- ImageExporter is on MainActor
    }
}
```

If `ImageExporter` were `nonisolated`, adding a `StickerModel` would fail:
"Main actor-isolated conformance of 'StickerModel' to 'Exportable' cannot be
used in nonisolated context."

### Clock Epochs

`ContinuousClock` and `SuspendingClock` now expose `.epoch` (SE-0473), enabling instant comparison and conversion between clock types.

```swift
let continuous = ContinuousClock()
let elapsed = continuous.now - continuous.epoch  // Duration since system boot
```

## Actor Isolation Rules

1. All mutable shared state MUST be protected by an actor or global actor.
2. `@MainActor` for all UI-touching code. No exceptions.
   Global actors are actor isolation; use `@MainActor` as the standard pattern
   for UI-bound shared state.
3. Use `nonisolated` only for methods that access immutable (`let`) properties
   or are pure computations.
4. Use `@concurrent` to explicitly move work off the caller's actor.
5. Never use `nonisolated(unsafe)` unless you have proven data-race safety and
   exhausted safer alternatives. It is an unsafe audit boundary, not a
   synchronization primitive. For the narrow unsafe-pointer capture pattern in
   a synchronous parallel loop, follow the proof requirements in
   [bridging and interop](references/bridging-interop.md#synchronous-parallel-for-concurrentperform-versus-task-groups).
   Disjoint per-iteration access can eliminate conflicting concurrent access
   and the need for synchronization; disjointness is not itself synchronization.
6. Never add manual locks (`NSLock`, `DispatchSemaphore`) inside actors.

## Sendable Rules

1. Value types (structs, enums) are automatically `Sendable` when all stored
   properties are `Sendable`.
   For diagnostics on mutable reference types, first extract an immutable
   `Sendable` value snapshot or DTO instead of sharing the reference.
2. Actors are implicitly `Sendable`.
3. `@MainActor` classes are implicitly `Sendable`. Do NOT add redundant
   `Sendable` conformance.
4. Non-actor classes: must be `final` with all stored properties `let` and
   `Sendable`.
5. `@unchecked Sendable` is a last resort. Document why the compiler cannot
   prove safety.
6. Use `sending` parameters (SE-0430) for finer-grained isolation control.
7. Use `@preconcurrency import` only for third-party libraries you cannot
   modify. Plan to remove it.

## Structured Concurrency Patterns

### Async Defer (Swift 6.4+)

`defer` blocks in async contexts can contain `await` in Swift 6.4+ (SE-0493).
Use for async cleanup: closing connections, flushing buffers, or releasing
resources that require an async call.

The defer body inherits the surrounding isolation and is implicitly awaited at
scope exit. It does not suppress cancellation; cleanup that checks
`Task.isCancelled` or `Task.checkCancellation()` still observes cancellation.

```swift
func fetchData() async throws -> Data {
    let connection = try await openConnection()
    defer { await connection.close() }
    return try await connection.read()
}
```

**Task:** Unstructured, inherits caller context.
```swift
Task { await doWork() }
```

**Task.detached:** No inherited context. Use only when you explicitly need to
break isolation inheritance.

**Task.immediate:** Starts immediately on current actor. Use for
latency-sensitive work.
```swift
Task.immediate { await handleUserInput() }
```

**async let:** Fixed number of concurrent operations.
```swift
async let a = fetchA()
async let b = fetchB()
let result = try await (a, b)
```

**TaskGroup:** Dynamic number of concurrent operations.
```swift
try await withThrowingTaskGroup(of: Item.self) { group in
    for id in ids {
        group.addTask { try await fetch(id) }
    }
    for try await item in group { process(item) }
}
```

## Task Cancellation

- Cancellation is cooperative. Check `Task.isCancelled` or call
  `try Task.checkCancellation()` in loops.
- Use `.task` modifier in SwiftUI -- it handles cancellation on view disappear.
- Use `withTaskCancellationHandler` for cleanup.
- Swift 6.4 / iOS 27+ beta: use `withTaskCancellationShield` only for short
  cleanup or rollback that must complete after cancellation. Inside the shield,
  `Task.isCancelled` is false and `Task.checkCancellation()` does not throw;
  cancellation is observable again after the scope exits.
- Cancel stored tasks in `deinit` or `onDisappear`.

## Actor Reentrancy

Actors are reentrant. State can change across suspension points.

```swift
// WRONG: State may change during await
actor Counter {
    var count = 0
    func increment() async {
        let current = count
        await someWork()
        count = current + 1  // BUG: count may have changed
    }
}

// CORRECT: Mutate synchronously, no reentrancy risk
actor Counter {
    var count = 0
    func increment() { count += 1 }
}
```

## AsyncSequence and AsyncStream

Use `AsyncStream` to bridge callback/delegate APIs:

```swift
let stream = AsyncStream<Location> { continuation in
    let delegate = LocationDelegate { location in
        continuation.yield(location)
    }
    continuation.onTermination = { _ in delegate.stop() }
    delegate.start()
}
```

Use `withCheckedContinuation` / `withCheckedThrowingContinuation` for
single-value callbacks. Resume exactly once.

## `@Observable` and Concurrency

- `@Observable` classes should be `@MainActor` for view models.
- Use `@State` to own an `@Observable` instance (replaces `@StateObject`).
- Use `Observations { }` (SE-0475) for async observation of `@Observable`
  properties as an `AsyncSequence`.

## Synchronization Primitives

When actors are not the right fit — synchronous access, performance-critical
paths, or bridging C/ObjC — use low-level synchronization primitives:

- **Actors** remain the default for async shared state when callers can suspend;
  they give compiler-enforced isolation and structured-concurrency integration,
  but outside calls are async actor hops, require reentrancy care across
  `await`, and do not fit synchronous C callbacks. Use global actors such as
  `@MainActor` for UI-bound shared state; never use `nonisolated(unsafe)` as a
  synchronization substitute.
- **`Mutex<Value>`** (iOS 18+, `Synchronization` module): Preferred lock for
  new code. Stores protected state inside the lock. `withLock { }` pattern.
- **`OSAllocatedUnfairLock`** (iOS 16+, `os` module): Use when targeting
  older iOS versions. Supports ownership assertions for debugging.
- **`Atomic<Value>`** (iOS 18+, `Synchronization` module): Lock-free atomics
  for independent counters and flags. `Atomic` is `Sendable` and can be stored
  in `Sendable` holder types. Use `.relaxed` only for standalone metrics; use
  acquire/release ordering or a lock when coordinating other data.

**Key rule:** Never put locks inside actors (double synchronization), and never
hold a lock across `await` (blocks a thread through suspension and can starve
the cooperative pool or deadlock). See
[references/synchronization-primitives.md](references/synchronization-primitives.md) for full API details, code examples,
and a decision guide for choosing locks vs actors.
`Mutex.withLock` and `OSAllocatedUnfairLock.withLock` use synchronous closures;
that API shape is what keeps critical sections non-suspending.
Gate `Mutex` and `Atomic` with runtime `if #available(iOS 18, *)`, never
`#if swift(...)` or platform compile-time checks. For `NSLock`, correct only the
false Sendable premise and avoid explaining conformance mechanics.
If a legacy lock wrapper truly needs `@unchecked Sendable`, name the invariant:
all mutable state is private, all access uses one lock, no mutable references
escape, and no lock is held across `await`.

## Common Mistakes

1. **Blocking the main actor.** Heavy computation on `@MainActor` freezes UI.
   Move to a `@concurrent` function.
2. **Unnecessary @MainActor.** Network layers, data processing, and model code
   do not need `@MainActor`. Only UI-touching code does.
3. **Actors for stateless code.** No mutable state means no actor needed. Use a
   plain struct or function.
4. **Actors for immutable data.** Use a `Sendable` struct, not an actor.
5. **Task.detached without good reason.** Loses priority, task-local values,
   and cancellation propagation.
6. **Forgetting task cancellation.** Store `Task` references and cancel them, or
   use the `.task` view modifier.
7. **Retain cycles in Tasks.** Use `[weak self]` when capturing `self` in
   long-lived stored tasks.
8. **Semaphores in async context.** `DispatchSemaphore.wait()` can block a cooperative executor thread and can deadlock when the signaller needs the blocked executor. Use an async primitive or structured concurrency.
9. **Split isolation.** Mixing `@MainActor` and `nonisolated` properties in one
   type. Isolate the entire type consistently.
10. **MainActor.run instead of static isolation.** Prefer `@MainActor func`
    over `await MainActor.run { }`.
11. **Using GCD for new async orchestration by default.** Prefer async/await,
    actors, and task groups. Keep dispatch queues where an API requires a queue,
    for custom executors, or during bounded legacy interop. A measured,
    synchronous CPU-bound parallel-for can still use
    `DispatchQueue.concurrentPerform`; a task group is an async design
    alternative, not a drop-in replacement for a synchronous API. Follow the
    capture and memory-safety audit in
    [bridging and interop](references/bridging-interop.md#synchronous-parallel-for-concurrentperform-versus-task-groups).
    In every review of this diagnostic, explicitly connect its `@Sendable`
    operation to both non-`Sendable` unsafe buffer views, and confine any
    opt-out to proven local base-pointer bindings. Every review that retains the
    parallel path must require benchmark-versus-serial, serial-result, and
    nested-parallelism checks.

## Review Checklist

- [ ] All mutable shared state is actor-isolated
- [ ] No data races (no unprotected cross-isolation access)
- [ ] Tasks are cancelled when no longer needed
- [ ] No blocking calls on `@MainActor`
- [ ] No manual locks inside actors
- [ ] `Sendable` conformance is correct (no unjustified `@unchecked`)
- [ ] Actor reentrancy is handled (no state assumptions across awaits)
- [ ] `@preconcurrency` imports are documented with removal plan
- [ ] Heavy work uses `@concurrent`, not `@MainActor`
- [ ] `.task` modifier used in SwiftUI instead of manual Task management
- [ ] Synchronous parallel loops prove nonconflicting memory access and pointer
      lifetime invariants

## References

- [references/concurrency-patterns.md](references/concurrency-patterns.md) — detailed concurrency patterns and migration examples
- [references/approachable-concurrency.md](references/approachable-concurrency.md) — approachable concurrency mode quick-reference
- [references/swiftui-concurrency.md](references/swiftui-concurrency.md) — SwiftUI-specific concurrency guidance
- [references/synchronization-primitives.md](references/synchronization-primitives.md) — Mutex, OSAllocatedUnfairLock, locks vs actors
- [references/bridging-interop.md](references/bridging-interop.md) — checked continuations, delegate bridging, GCD migration table
- [references/diagnostics.md](references/diagnostics.md) — compiler diagnostic → fix reference, strict concurrency adoption
- [references/async-algorithms.md](references/async-algorithms.md) — swift-async-algorithms: debounce, throttle, merge, combineLatest, chunks
