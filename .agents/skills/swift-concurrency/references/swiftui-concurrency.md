# SwiftUI Concurrency Guide

Concurrency patterns and best practices specific to SwiftUI applications.

## Contents

- [MainActor Default in SwiftUI](#mainactor-default-in-swiftui)
- [Where SwiftUI Runs Code Off the Main Thread](#where-swiftui-runs-code-off-the-main-thread)
- [Sendable Closures and Data-Race Safety](#sendable-closures-and-data-race-safety)
- [Structuring Async Work](#structuring-async-work)
- [The .task Modifier](#the-task-modifier)
- [`@Observable View Models`](#observable-view-models)
- [Async Observation with Observations (SE-0475)](#async-observation-with-observations-se-0475)
- [Performance-Driven Concurrency](#performance-driven-concurrency)
- [Common SwiftUI Concurrency Mistakes](#common-swiftui-concurrency-mistakes)

## MainActor Default in SwiftUI

- `View` is `@MainActor` isolated by default; `body` and all members inherit
  this isolation.
- Swift 6.2 can infer `@MainActor` for all types in a module via default actor
  isolation (SE-0466).
- This default aligns with UIKit/AppKit `@MainActor` APIs and simplifies UI
  code.

## Where SwiftUI Runs Code Off the Main Thread

SwiftUI may evaluate some view logic on background threads for performance:

- `Shape` path generation
- `Layout` methods (`sizeThatFits`, `placeSubviews`)
- `visualEffect` closures
- `onGeometryChange` closures

These APIs often require `Sendable` closures to reflect their off-main-thread
runtime semantics.

## Sendable Closures and Data-Race Safety

Accessing `@MainActor` state from a `Sendable` closure is unsafe and flagged by
the compiler.

**Fix:** Capture value copies in the closure capture list.

```swift
// WRONG: Captures @MainActor state directly
.visualEffect { content, proxy in
    content.offset(y: self.offset)  // Error: @MainActor state in Sendable closure
}

// CORRECT: Capture a copy
let currentOffset = offset
// ... use in closure:
.visualEffect { [currentOffset] content, proxy in
    content.offset(y: currentOffset)
}
```

Avoid sending `self` into a `Sendable` closure just to read a single property.

## Structuring Async Work

SwiftUI action callbacks are synchronous so UI updates (like loading states) can
be immediate.

```swift
struct ContentView: View {
    @State private var isLoading = false
    @State private var result: String?

    var body: some View {
        Button("Load") {
            isLoading = true           // Immediate UI update
            Task {
                result = await fetchData()
                isLoading = false
            }
        }
    }
}
```

**Pattern:** Use state as the boundary. Async work updates model/state; UI
reacts synchronously.

## The .task Modifier

Prefer `.task` over manual `Task` creation in views:

```swift
.task {
    await loadInitialData()
}
```

**Advantages:**
- Automatically cancels on view disappear.
- Inherits the view's actor isolation (`@MainActor`).
- No need to store `Task` references for cancellation.

Use `.task(id:)` to restart work when a value changes:

```swift
.task(id: selectedItem) {
    details = await fetchDetails(for: selectedItem)
}
```

## `@Observable` View Models

- Annotate view models with both `@Observable` and `@MainActor`.
- Use `@State` to own an `@Observable` instance (replaces `@StateObject`).
- Avoid `@ObservedObject` / `@StateObject` / `ObservableObject` in new code.

```swift
@Observable @MainActor
final class ViewModel {
    var items: [Item] = []
    var isLoading = false

    func load() async {
        isLoading = true
        items = await fetchItems()
        isLoading = false
    }
}

struct ItemListView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.load() }
    }
}
```

## Async Observation with Observations (SE-0475)

Use `Observations { }` for transactional async observation:

```swift
.task {
    for await _ in Observations { viewModel.searchText } {
        await viewModel.performSearch()
    }
}
```

## Performance-Driven Concurrency

- Offload expensive work from the main actor to avoid hitches.
- Keep time-sensitive UI logic (animations, gesture responses) synchronous.
- Separate UI code from long-running async work.

```swift
@Observable @MainActor
final class ImageProcessor {
    var processedImage: UIImage?

    func process(data: Data) async {
        // Offload heavy work
        let result = await Self.runProcessing(data: data)
        processedImage = result
    }

    @concurrent
    nonisolated static func runProcessing(data: Data) async -> UIImage {
        // Runs on background thread pool
        // ...
    }
}
```

## Common SwiftUI Concurrency Mistakes

1. **Creating `Task` in `body`.** Use `.task` modifier instead.
2. **Not cancelling tasks.** `.task` does this automatically; manual `Task`
   references must be cancelled in `onDisappear`.
3. **Blocking MainActor in view updates.** Move heavy computation to
   `@concurrent` functions.
4. **Using `Task.detached` in views.** Loses actor context. Use `Task { }` or
   `.task` modifier.
5. **Updating state from background.** Always update `@State` / `@Observable`
   properties on `@MainActor`.
