# Bridging and Interop

Patterns for bridging callback-based, delegate-based, and GCD code into Swift Concurrency.

## Contents

- [Checked Continuations](#checked-continuations)
- [AsyncStream from Callbacks](#asyncstream-from-callbacks)
- [GCD Migration](#gcd-migration)
- [Synchronous parallel-for](#synchronous-parallel-for-concurrentperform-versus-task-groups)

## Checked Continuations

Use `withCheckedContinuation` (non-throwing) or `withCheckedThrowingContinuation` (throwing) to bridge completion-handler APIs into async/await. Available iOS 13+.

Docs: [withCheckedContinuation](https://sosumi.ai/documentation/swift/withcheckedcontinuation(isolation:function:_:)) · [withCheckedThrowingContinuation](https://sosumi.ai/documentation/swift/withcheckedthrowingcontinuation(isolation:function:_:))

### Basic Pattern

```swift
func fetchData() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        legacyFetch { result in
            switch result {
            case .success(let data):
                continuation.resume(returning: data)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

### Rules

- **Resume exactly once.** Missing resume suspends the task forever (leak). Double resume crashes at runtime.
- **Prefer checked over unsafe.** `withCheckedContinuation` detects misuse at runtime with diagnostics. Use `withUnsafeContinuation` only in performance-critical paths after correctness is proven.
- **Capture continuation carefully.** The continuation escapes the closure — ensure all code paths resume it, including error and cancellation paths.

### Delegate Bridging

```swift
class LocationBridge: NSObject, CLLocationManagerDelegate {
    private var continuation: CheckedContinuation<CLLocation, any Error>?
    private let manager = CLLocationManager()

    func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations[0])
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
```

### Cancellation Support

```swift
func fetchWithCancellation() async throws -> Data {
    try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            let task = legacyFetch { result in
                switch result {
                case .success(let data): continuation.resume(returning: data)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
            // Store task for cancellation
        }
    } onCancel: {
        // Cancel the underlying work
    }
}
```

## AsyncStream from Callbacks

For APIs that deliver multiple values over time (delegates, NotificationCenter), use `AsyncStream`:

```swift
func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let delegate = StreamingLocationDelegate(continuation: continuation)
        continuation.onTermination = { _ in
            delegate.stop()
        }
        delegate.start()
    }
}
```

## GCD Migration

| GCD Pattern | Migration direction |
| --- | --- |
| `DispatchQueue.main.async { }` | `@MainActor` isolation or `MainActor.run { }` |
| `DispatchQueue.global().async { }` | `Task { }` or `Task.detached { }` (Swift 6.2: `@concurrent`) |
| `DispatchGroup` | `async let` or `TaskGroup` |
| `DispatchSemaphore` | Actor isolation or `AsyncStream` |
| `DispatchWorkItem` with cancel | `Task` with `task.cancel()` |
| `DispatchQueue` serial queue | `actor` |
| `DispatchQueue.concurrentPerform` when the surrounding API can become async | `withTaskGroup`, usually with bounded/chunked child work |
| `DispatchQueue.concurrentPerform` for a measured synchronous CPU-bound parallel-for | Keep `concurrentPerform`; follow the audit below |
| `DispatchSource.makeTimerSource` | `Task.sleep(for:)` in a loop, or `Clock` |

### Synchronous parallel-for: `concurrentPerform` versus task groups

Apple documents `DispatchQueue.concurrentPerform` as an efficient synchronous
parallel-for: it executes every iteration and waits for them all to finish before
returning. A [task group](https://sosumi.ai/documentation/swift/withtaskgroup(of:returning:isolation:body:))
also waits for its child tasks, but its API is `async`. Use a task group when the
surrounding operation can be asynchronous. Keep
[`concurrentPerform`](https://sosumi.ai/documentation/dispatch/dispatchqueue/concurrentperform(iterations:execute:))
when a caller must remain synchronous and measurement shows that independent,
finite CPU work benefits from a parallel-for. Finite CPU computation does not by
itself violate the cooperative executor's
[forward-progress requirement](https://sosumi.ai/documentation/swift/globalconcurrentexecutor).

The API is declared `@preconcurrency`, but its closure parameter is `@Sendable`.
Under Swift 6 complete checking, direct captures of both
[`UnsafeBufferPointer`](https://sosumi.ai/documentation/swift/unsafebufferpointer)
and [`UnsafeMutableBufferPointer`](https://sosumi.ai/documentation/swift/unsafemutablebufferpointer)
are rejected because neither buffer view is `Sendable`. When the compiler cannot
express a manually proven pointer invariant, confine `nonisolated(unsafe)` to the
local base-pointer bindings captured by the closure:

```swift
func doubled(_ input: UnsafeBufferPointer<Int>) -> [Int] {
    guard !input.isEmpty else { return [] }

    return Array(unsafeUninitializedCapacity: input.count) { output, initializedCount in

        nonisolated(unsafe) let inputBase = input.baseAddress!
        nonisolated(unsafe) let outputBase = output.baseAddress!

        // SAFETY: concurrentPerform joins before return. Iteration i reads only
        // inputBase[i] and initializes only outputBase[i]; the ranges do not
        // alias, both contain input.count elements, and both remain valid for
        // the entire loop.
        DispatchQueue.concurrentPerform(iterations: input.count) { index in
            outputBase.advanced(by: index).initialize(
                to: inputBase[index] * 2
            )
        }

        initializedCount = input.count
    }
}
```

Before accepting this opt-out, require one adjacent `// SAFETY:` proof that
covers:

- the actual index, stride, range, and bounds arithmetic;
- every alias between captured pointers and why concurrent reads and writes do
  not conflict;
- initialization versus mutation of each destination element;
- pointer validity until the synchronous loop has joined.

Disjoint ranges are a nonconflicting-access invariant, not synchronization.
Input/output aliasing is allowed only when the access proof remains
nonconflicting. For a same-base in-place transform, prove that iteration `i`
reads element `i` before writing element `i`, touches no other element, and that
the read/write sets for iterations `i` and `j` do not overlap when `i != j`.
Same pointer identity alone proves neither safety nor unsafety; shifted,
neighboring, strided, or tiled access requires a fresh alias and range proof.
Never widen the opt-out to a buffer view, enclosing type, or unrelated shared
state.

`concurrentPerform` does not automatically participate in Swift task
cancellation. If cancellation is required, design an explicit thread-safe
signal and define partial-output semantics, or move the operation behind an
async API.

#### Acceptance checks

Before retaining this carve-out:

- benchmark the complete operation against the serial implementation on
  representative supported devices and workloads;
- compare parallel output with the serial result, byte-for-byte when the
  operation permits;
- avoid nested parallel loops unless separate measurement shows that the
  resulting oversubscription is beneficial.

These are engineering checks, not Apple API guarantees. See the supplemental
[Swift Forums discussion](https://forums.swift.org/t/dispatchqueue-concurrentperform-unsaferawpointer-in-swift-6/74125)
for the original strict-concurrency use case.

### DispatchGroup → TaskGroup

```swift
// Before (GCD)
let group = DispatchGroup()
for url in urls {
    group.enter()
    fetch(url) { _ in group.leave() }
}
group.notify(queue: .main) { updateUI() }

// After (Swift Concurrency)
let results = await withTaskGroup(of: Data?.self) { group in
    for url in urls {
        group.addTask { try? await fetch(url) }
    }
    return await group.reduce(into: [Data]()) { if let d = $1 { $0.append(d) } }
}
updateUI(results)
```

### Serial Queue → Actor

```swift
// Before
let serialQueue = DispatchQueue(label: "com.app.cache")
serialQueue.async { self.cache[key] = value }

// After
actor Cache {
    private var storage: [String: Data] = [:]
    func set(_ key: String, _ value: Data) { storage[key] = value }
    func get(_ key: String) -> Data? { storage[key] }
}
```
