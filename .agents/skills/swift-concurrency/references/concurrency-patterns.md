# Concurrency Patterns

Approachable concurrency patterns introduced in Swift 6.2+ — a philosophy shift where
code stays single-threaded by default until you choose to introduce concurrency.

## Contents

- [Core Problem Solved](#core-problem-solved)
- [SE-0466: Default MainActor Isolation](#se-0466-default-mainactor-isolation)
- [SE-0461: nonisolated(nonsending)](#se-0461-nonisolatednonsending)
- [`@concurrent Attribute`](#concurrent-attribute)
- [SE-0472: Task.immediate](#se-0472-taskimmediate)
- [Swift 6.4 Cleanup APIs](#swift-64-cleanup-apis)
- [Isolated Conformances](#isolated-conformances)
- [SE-0481: weak let](#se-0481-weak-let)
- [SE-0475: Transactional Observation (Observations)](#se-0475-transactional-observation-observations)
- [Global and Static State](#global-and-static-state)
- [Migration and Build Settings](#migration-and-build-settings)
- [Summary](#summary)

## Core Problem Solved

In Swift 6.0/6.1, data-race safety was enforced at compile time, but the most
natural code to write often produced data-race errors. Async functions on types
with mutable state would implicitly hop to the global concurrent executor,
causing send-safety violations even when no actual parallelism was intended.

```swift
// Swift 6.0/6.1: This produces a data-race error
class PhotoProcessor {
    func extractSticker(data: Data, with id: String?) async -> Sticker? { /* ... */ }
}

@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
        // Error: Sending 'self.photoProcessor' risks causing data races
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

```swift
// Swift 6.2: The same code compiles without error
// because extractSticker stays on the caller's actor
class PhotoProcessor {
    func extractSticker(data: Data, with id: String?) async -> Sticker? { /* ... */ }
}

@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

## SE-0466: Default MainActor Isolation

Enable with the `-default-isolation MainActor` compiler flag, SwiftPM
`.defaultIsolation(MainActor.self)`, or Xcode's separate `Default Actor
Isolation` build setting set to `MainActor`.

Do not confuse this with Xcode's `Approachable Concurrency` build setting, which
enables a bundle of upcoming-feature flags such as nonisolated-nonsending by
default, isolated-conformance inference, inferred Sendable captures, and related
global-actor usability changes.

**What it does:**
- Unannotated declarations in the module are inferred as `@MainActor` unless
  opted out.
- Global and static variables are protected by the main actor by default.
- Protocol conformances are implicitly isolated to `@MainActor`.
- Eliminates most annotation burden for single-threaded UI code.

**Recommended for:** Apps, scripts, and executable targets. Not recommended for
library targets that should remain actor-agnostic.

```swift
// With default MainActor isolation -- no @MainActor annotations needed:
final class StickerLibrary {
    static let shared = StickerLibrary()
}

final class StickerModel {
    let photoProcessor = PhotoProcessor()
    var selection: [PhotosPickerItem] = []
}

extension StickerModel: Exportable {
    func export() { photoProcessor.exportAsPNG() }
}
```

## SE-0461: nonisolated(nonsending)

Nonisolated async functions stay on the caller's actor by default instead of
hopping to the global concurrent executor. This is the `nonisolated(nonsending)`
default behavior.

**Key implication:** Values passed into an async function are never sent outside
the actor, eliminating data races without annotation.

To explicitly opt into background execution, use `@concurrent`.

## `@concurrent` Attribute

Ensures a function always runs on the concurrent thread pool, freeing the
calling actor for other work.

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
    static func extractSubject(from data: Data) async -> Sticker { /* ... */ }
}
```

**Steps to offload a function to background:**
1. Ensure the containing type is `nonisolated` or the function can be called
   from a nonisolated context.
2. Add `@concurrent` to the function. `nonisolated` alone does not move
   CPU-heavy work off the caller's actor.
3. Add `async` if not already asynchronous.
4. Add `await` at call sites.

```swift
nonisolated struct PhotoProcessor {
    @concurrent
    func process(data: Data) async -> ProcessedPhoto? { /* ... */ }
}

processedPhotos[item.id] = await PhotoProcessor().process(data: data)
```

## SE-0472: Task.immediate

`Task.immediate` starts executing synchronously on the current actor before any
suspension point, rather than being enqueued. There is also
`Task.immediateDetached` which combines immediate start with detached semantics.

```swift
Task.immediate { await handleUserInput() }
```

Use for latency-sensitive work where enqueue delay is unacceptable.

## Swift 6.4 Cleanup APIs

Swift 6.4 adds async `defer` (SE-0493) and cancellation shields (SE-0504).
Gate both behind Swift 6.4 / Xcode 27 beta and the platform availability of
`withTaskCancellationShield` (iOS 27+ beta).

Use async `defer` when cleanup itself must call async APIs. The defer body
inherits surrounding isolation and is implicitly awaited at scope exit, but it
does not hide cancellation from cleanup code.

Use `withTaskCancellationShield` only for short cleanup or rollback that must
finish after cancellation. Do not wrap normal user-cancelable work in a shield.

## Isolated Conformances

A conformance that needs MainActor state is called an *isolated conformance*.
The compiler ensures the conformance is only used in a matching isolation
context.

```swift
protocol Exportable {
    func export()
}

extension StickerModel: @MainActor Exportable {
    func export() { photoProcessor.exportAsPNG() }
}

@MainActor
struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // OK -- on MainActor
    }
}

// But in a nonisolated context:
nonisolated struct GenericExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        // Error: Main actor-isolated conformance of 'StickerModel' to
        // 'Exportable' cannot be used in nonisolated context
        items.append(item)
    }
}
```

## SE-0481: weak let

Immutable weak references (`weak let`) enable `Sendable` conformance for types
that hold weak references, since immutability guarantees thread safety.
SE-0481 is implemented in Swift 6.3.

## SE-0475: Transactional Observation (Observations)

`Observations { }` provides transactional observation of `@Observable` types
via `AsyncSequence`.

```swift
for await _ in Observations { model.count } {
    print("Count changed to \(model.count)")
}
```

## Global and Static State

Global and static variables are prone to data races. The most common protection
is `@MainActor`:

```swift
@MainActor
final class StickerLibrary {
    static let shared = StickerLibrary()  // protected by MainActor
}
```

With default MainActor isolation (SE-0466), this annotation is implicit.

## Migration and Build Settings

All approachable concurrency features are opt-in via:
- **Xcode 26:** Swift Compiler > Concurrency section in build settings.
- **SwiftPM:** `swiftSettings` in Package.swift using the `SwiftSetting` API.

For Swift 6 language mode, strict concurrency checking is complete and
data-race diagnostics are errors. Use Targeted or Minimal only as Swift 5
migration settings while preparing code for Swift 6.

Swift 6.2 includes migration tooling to help make necessary code changes
automatically. See swift.org/migration for details.

## Summary

The Swift 6.2 concurrency progression:
1. Start with code that runs on the main actor by default (no data race risk).
2. Async functions run wherever they are called from (still no data race risk).
3. When you need performance, offload specific code with `@concurrent`.
