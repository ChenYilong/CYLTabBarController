# Synchronization Primitives

Low-level synchronization tools for protecting shared mutable state when actors
are not the right fit. All primitives discussed here are `Sendable` and safe
to use from multiple threads.

## Contents

- [Mutex](#mutex)
- [OSAllocatedUnfairLock](#osallocatedunfairlock)
- [Atomic](#atomic)
- [Locks vs Actors: When to Use Each](#locks-vs-actors-when-to-use-each)

## Mutex

**Module:** `Synchronization` · **Availability:** iOS 18.0+

`Mutex<Value>` is a synchronization primitive that protects shared mutable
state via mutual exclusion. It blocks threads attempting to acquire the lock,
ensuring only one execution context accesses the protected value at a time.

**Documentation:**
[sosumi.ai/documentation/synchronization/mutex](https://sosumi.ai/documentation/synchronization/mutex)

### Basic Usage

```swift
import Synchronization

class ImageCache: Sendable {
    let storage = Mutex<[String: UIImage]>([:])

    func image(forKey key: String) -> UIImage? {
        storage.withLock { $0[key] }
    }

    func store(_ image: UIImage, forKey key: String) {
        storage.withLock { $0[key] = image }
    }

    func removeAll() {
        storage.withLock { $0.removeAll() }
    }
}
```

### withLockIfAvailable

Use `withLockIfAvailable` to attempt acquisition without blocking. Returns
`nil` if the lock is already held.

```swift
let counter = Mutex<Int>(0)

// Non-blocking attempt — returns nil if lock is contended
if let value = counter.withLockIfAvailable({ $0 }) {
    print("Current count: \(value)")
} else {
    print("Lock was busy, skipping")
}
```

### Key Properties

- **Generic over `Value`:** The protected state is stored inside the mutex,
  making it clear what the lock protects.
- **`Sendable`:** `Mutex` conforms to `Sendable`, so it can be stored in
  `Sendable` types (classes, actors, global state).
- **Non-recursive:** Attempting to lock a `Mutex` that you already hold on the
  same thread is undefined behavior.
- **Synchronous only:** Do not `await` inside `withLock`. The lock is held for
  the duration of the closure — blocking across a suspension point will
  deadlock or starve other threads.

## OSAllocatedUnfairLock

**Module:** `os` · **Availability:** iOS 16.0+

`OSAllocatedUnfairLock<State>` wraps `os_unfair_lock` in a safe Swift API.
It heap-allocates the underlying lock, avoiding the unsound address-of
problem that makes raw `os_unfair_lock` unusable from Swift.

**Documentation:**
[sosumi.ai/documentation/os/osallocatedunfairlock](https://sosumi.ai/documentation/os/osallocatedunfairlock)

### State-Protecting Lock

```swift
import os

enum LoadState: Sendable {
    case idle
    case loading
    case complete(Data)
    case failed(Error)
}

final class ResourceLoader: Sendable {
    let state = OSAllocatedUnfairLock(initialState: LoadState.idle)

    func beginLoading() {
        state.withLock { $0 = .loading }
    }

    func completeLoading(with data: Data) {
        state.withLock { $0 = .complete(data) }
    }

    var currentState: LoadState {
        state.withLock { $0 }
    }
}
```

### Stateless Lock

When protecting external state or a code section rather than a specific value:

```swift
let lock = OSAllocatedUnfairLock()

lock.withLock {
    // Critical section — no associated state
    writeToSharedFile(data)
}
```

### Manual lock/unlock

Available but discouraged. Must unlock from the same thread that locked.
**Never** use across `await` suspension points.

```swift
lock.lock()
defer { lock.unlock() }
// Critical section
```

### Mutex vs OSAllocatedUnfairLock

| | `Mutex<Value>` | `OSAllocatedUnfairLock<State>` |
|---|---|---|
| **Availability** | iOS 18+ | iOS 16+ |
| **Module** | `Synchronization` | `os` |
| **State model** | Value stored inside lock (generic `Value`) | Optional state via `initialState:` |
| **`withLockIfAvailable`** | Returns `nil` on contention | Returns `nil` on contention |
| **Ownership assertions** | Not available | `precondition(.owner)` / `precondition(.notOwner)` |
| **Manual lock/unlock** | Not available | Available (`lock()` / `unlock()`) |
| **Recommendation** | Preferred for iOS 18+ code | Use when targeting iOS 16–17 |

**Guideline:** Use `Mutex` for new code targeting iOS 18+. For apps that run on
iOS 16 through current releases, either keep the shared abstraction backed by
`OSAllocatedUnfairLock` or branch with `#available(iOS 18, *)` so iOS 18+ uses
`Mutex` and iOS 16–17 uses `OSAllocatedUnfairLock`. Prefer
`OSAllocatedUnfairLock` when you need ownership assertions for debugging.
Do not introduce a broad generic lock wrapper with `@unchecked Sendable` just to
hide the deployment-target branch; keep the protected state inside the concrete
primitive. If a legacy wrapper truly needs `@unchecked Sendable`, document the
invariant: all mutable state is private, every access uses the same lock, no
mutable references escape the wrapper, and no lock is held across `await`.

When showing an availability branch, use runtime availability and concrete
implementations. Do not use `#if swift(...)`, `#if os(...)`, or Catalyst checks
as substitutes for API availability:

```swift
protocol MetricsStore: Sendable {
    func increment(_ key: String)
}

func makeMetricsStore() -> any MetricsStore {
    if #available(iOS 18, *) {
        return MutexMetricsStore()
    } else {
        return UnfairLockMetricsStore()
    }
}
```

## Atomic

**Module:** `Synchronization` · **Availability:** iOS 18.0+

`Atomic<Value>` provides lock-free atomic operations on values conforming to
`AtomicRepresentable`. Use atomics for simple counters, flags, and
compare-and-swap patterns where a full lock would be overkill. `Atomic`
conforms to `Sendable`, so it can be stored in `Sendable` holder types.

**Documentation:**
[sosumi.ai/documentation/synchronization/atomic](https://sosumi.ai/documentation/synchronization/atomic)

### Counter Example

```swift
import Synchronization

final class RequestTracker: Sendable {
    let activeRequests = Atomic<Int>(0)

    func beginRequest() {
        activeRequests.wrappingAdd(1, ordering: .relaxed)
    }

    func endRequest() {
        activeRequests.wrappingSubtract(1, ordering: .relaxed)
    }

    var count: Int {
        activeRequests.load(ordering: .relaxed)
    }
}
```

For an independent scalar counter called from C callbacks, `Atomic<Int>` is the
best iOS 18+ standard-library fit because the callback remains synchronous and
does not need an actor hop:

```swift
import Synchronization

@available(iOS 18.0, *)
final class CallbackCounter: Sendable {
    private let value = Atomic<Int>(0)

    func incrementFromCallback() {
        value.wrappingAdd(1, ordering: .relaxed)
    }

    var snapshot: Int {
        value.load(ordering: .relaxed)
    }
}
```

Use `.relaxed` only when the counter is independent and does not publish or
order access to other state. If a flag or counter coordinates access to other
data, use acquire/release ordering or a lock that protects the compound state.

### Boolean Flag

```swift
let isShutdown = Atomic<Bool>(false)

func shutdown() {
    let (exchanged, _) = isShutdown.compareExchange(
        expected: false,
        desired: true,
        ordering: .acquiringAndReleasing
    )
    guard exchanged else { return } // Already shut down
    performCleanup()
}
```

### Memory Ordering

Atomic operations require an explicit memory ordering:

| Ordering | Use case |
|---|---|
| `.relaxed` | Counters, statistics — no ordering guarantees needed |
| `.acquiring` | Read that must see all writes before a corresponding release |
| `.releasing` | Write that must be visible to a corresponding acquire |
| `.acquiringAndReleasing` | Compare-and-swap, read-modify-write |
| `.sequentiallyConsistent` | Strongest guarantee — rarely needed |

**Guideline:** Use `.relaxed` for simple counters. Use
`.acquiringAndReleasing` for compare-and-swap patterns. Avoid
`.sequentiallyConsistent` unless you have a proven need — it is the most
expensive ordering.

### When to Use Atomics vs Mutex

- **Atomics:** Simple independent scalar values (Int, Bool, UInt64), single-field
  counters, flags. Lock-free and very fast. For C callback counters, prefer
  `Atomic` when the app can use iOS 18+ APIs or an accepted package dependency;
  otherwise use `OSAllocatedUnfairLock`.
- **Mutex:** Compound state (dictionaries, structs with multiple fields),
  multi-step operations that must be atomic as a group.

## Locks vs Actors: When to Use Each

### Use Actors When:

- **Async isolation is natural.** The protected state is accessed from async
  contexts and you can afford the hop.
- **Callers can suspend.** Actor-isolated APIs are `async` from outside the
  actor, so they fit task-based code but not synchronous C callbacks, real-time
  hooks, or other no-suspension call sites.
- **Structured concurrency.** You want the compiler to enforce isolation
  boundaries and prevent data races statically. Calls from outside the actor are
  async actor hops, so actor APIs are inappropriate for synchronous callbacks.
- **Global actor isolation fits.** Use `@MainActor` or another global actor for
  shared state bound to that executor; do not use `nonisolated(unsafe)` as a
  synchronization substitute.
- **Reentrancy can be handled.** Actor state may change across `await`, so
  restore invariants before suspension and re-check assumptions after it.
- **Most Swift code.** Actors are the default recommendation for shared mutable
  state in Swift concurrency.
- **Complex state with multiple methods.** Actor isolation protects all
  properties and methods automatically.

```swift
// GOOD: Actor for a cache accessed from async contexts
actor ImageDownloader {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] { return cached }
        let (data, _) = try await URLSession.shared.data(from: url)
        let image = UIImage(data: data)!
        cache[url] = image
        return image
    }
}
```

### Use Mutex / Locks When:

- **Synchronous access is required.** Callers cannot (or should not) be async.
  Accessing an actor from synchronous code requires `Task` and introduces
  unwanted asynchrony.
- **Performance-critical paths.** Lock acquisition is nanoseconds; actor hops
  involve task scheduling. For tight loops or high-frequency access, a lock
  may be significantly faster.
- **Bridging with C/ObjC.** C callbacks, delegate methods, or ObjC APIs that
  cannot be made async.
- **Simple counters or flags.** `Atomic<Int>` or `Atomic<Bool>` is cheaper and
  simpler than creating an actor for a single value.
- **Availability matters.** `Atomic` from `Synchronization` is iOS 18+; for
  iOS 16–17, use `OSAllocatedUnfairLock` for synchronous state or an existing
  package-backed atomic only when the dependency is already accepted.

```swift
// GOOD: Mutex for synchronous, high-frequency access
final class MetricsCollector: Sendable {
    let metrics = Mutex<[String: Int]>([:])

    // Called from tight loops, C callbacks, or synchronous code
    func increment(_ key: String) {
        metrics.withLock { $0[key, default: 0] += 1 }
    }

    func snapshot() -> [String: Int] {
        metrics.withLock { $0 }
    }
}
```

### Decision Guide

Apply these checks in order instead of treating them as mutually exclusive
branches:

1. **All access is async and callers can suspend:** use an actor.
2. **Single independent scalar counter or flag:** use `Atomic` when available;
   for iOS 16-17 support without an atomic package, use `OSAllocatedUnfairLock`.
3. **Synchronous C/ObjC callback or no-suspension caller:** use
   `OSAllocatedUnfairLock` for iOS 16+ or `Mutex` when the minimum target is
   iOS 18+.
4. **Compound invariants or dictionaries:** use `Mutex` / lock-backed state for
   synchronous access, or an actor for async access.
5. **Availability branch:** choose iOS 18+ APIs with runtime
   `if #available(iOS 18, *)`, not compile-time platform checks.

### Anti-Patterns

**Never put locks inside actors.** An actor already serializes access; adding
any lock (`NSLock`, `Mutex`, or `OSAllocatedUnfairLock`) creates double
synchronization and risks deadlocks. This is a lock-inside-actor problem, not an
`NSLock`-specific problem.

```swift
// WRONG: Lock inside an actor — double synchronization
actor BadCache {
    let lock = Mutex<[String: Data]>([:])  // Unnecessary!
    // The actor already protects its state
}

// CORRECT: Just use the actor's built-in isolation
actor GoodCache {
    var cache: [String: Data] = [:]

    func store(_ data: Data, key: String) {
        cache[key] = data
    }
}
```

**Avoid reaching first for `DispatchSemaphore` or `NSLock` in modern Swift.**
`NSLock` is `Sendable` on Apple platforms, but `Mutex` (iOS 18+) and
`OSAllocatedUnfairLock` (iOS 16+) make the protected state and lock ownership
clearer in Swift concurrency code. Use this exact correction when reviewing
stale guidance: the `NSLock` Sendable objection is wrong, but modern
state-protecting primitives are still preferred for new code. Avoid extra claims
about how `NSLock` gets Sendable conformance; do not mention retroactive or
unchecked conformance mechanics in normal review output.

**Never hold a lock across `await`.** Suspension while holding a blocking lock
keeps a thread unavailable for unrelated work, can starve the cooperative pool,
and can deadlock if resumed work needs the same lock or executor progress.
`Mutex.withLock` and `OSAllocatedUnfairLock.withLock` take synchronous closures;
that shape is intentional because `await` should not appear inside the critical
section.

```swift
// WRONG: Holding lock across suspension point
mutex.withLock { value in
    value = await fetchData()  // DEADLOCK RISK
}

// CORRECT: Fetch first, then lock to update
let data = await fetchData()
mutex.withLock { value in
    value = data
}
```
