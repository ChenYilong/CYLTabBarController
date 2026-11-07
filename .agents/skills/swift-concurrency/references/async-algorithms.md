# Swift Async Algorithms

[swift-async-algorithms](https://github.com/apple/swift-async-algorithms) is an Apple open-source package providing `AsyncSequence` algorithms modeled after the standard library's `Sequence` algorithms.

## Contents

- [Key Algorithms](#key-algorithms)
- [Common Patterns](#common-patterns)

Add to Package.swift:

```swift
.package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
```

## Key Algorithms

### Combining

```swift
import AsyncAlgorithms

// Merge multiple sequences into one (interleaved by arrival time)
for await value in merge(streamA, streamB) {
    handle(value)
}

// Combine latest values from two sequences (emits when either updates)
for await (a, b) in combineLatest(streamA, streamB) {
    handle(a, b)
}

// Zip — pairs elements 1:1 (waits for both)
for await (a, b) in zip(streamA, streamB) {
    handle(a, b)
}

// Chain — concatenate sequences end-to-end
for await value in chain(streamA, streamB) {
    handle(value)
}
```

### Temporal

```swift
// Debounce — emit after a quiet period (e.g., search-as-you-type)
let searchResults = searchTerms
    .debounce(for: .milliseconds(300))

for await term in searchResults {
    await performSearch(term)
}

// Throttle — emit at most once per interval
let throttled = sensorReadings
    .throttle(for: .seconds(1))

for await reading in throttled {
    updateDisplay(reading)
}

// Chunks — collect elements into arrays by count or time
for await batch in events.chunks(ofCount: 10) {
    await processBatch(batch) // [Event] with up to 10 elements
}

for await batch in events.chunked(by: .repeating(every: .seconds(1))) {
    await processBatch(batch)
}
```

### Filtering and Transformation

```swift
// Remove consecutive duplicates
for await value in stream.removeDuplicates() {
    handle(value)
}

// Compacted — remove nils (like compactMap without transform)
let values: AsyncStream<Int?> = ...
for await value in values.compacted() {
    // value is non-optional Int
}
```

## Common Patterns

### Search-as-you-type

```swift
func searchResults(for terms: AsyncStream<String>) -> AsyncStream<[Result]> {
    AsyncStream { continuation in
        Task {
            for await term in terms.debounce(for: .milliseconds(300)) {
                guard !Task.isCancelled else { break }
                let results = try? await searchService.search(term)
                continuation.yield(results ?? [])
            }
            continuation.finish()
        }
    }
}
```

### Rate-limited API calls

```swift
for await batch in requestStream.chunks(ofCount: 50).throttle(for: .seconds(1)) {
    await api.sendBatch(batch)
}
```
