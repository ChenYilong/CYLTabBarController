# Understanding Hangs in Your App (Summary)

Context: Apple guidance on identifying hangs caused by long-running main-thread
work and understanding the main run loop.

## Contents
- What a hang is
- Main-thread work stages
- Triage workflow
- Common root causes
- Fix patterns
- Verification checklist
- Related SwiftUI implications

## What a hang is

A hang is a noticeable delay in a discrete interaction. Apple commonly frames
this as main-thread busy time long enough for the user to feel the UI stop
responding.

Practical thresholds:

- Under ~100 ms usually feels immediate.
- Around 100–250 ms starts to feel sticky.
- Above ~250 ms is a likely hang candidate.
- Multi-second stalls are usually obvious product bugs, not subtle perf issues.

The important point is not the exact number. A hang is user-perceived blocked
interaction, and the main thread is usually where the problem lives.

## Main-thread work stages

A typical interaction flows through three stages on the main thread:

1. Event delivery to the target view or responder
2. Your code mutating state, computing values, and scheduling UI changes
3. Core Animation committing the frame tree to the render server

If any one of those stages runs too long, the main run loop cannot get back to
sleep and cannot service the next event in time.

## Main run loop model

The main run loop is a good mental model for hangs:

- Healthy apps spend most of their time idle, waiting for work.
- A busy run loop means new taps, gestures, timers, and redraw work queue up.
- Main-actor tasks still execute on the main thread. Moving code to `@MainActor`
  is a correctness tool, not a performance optimization.

If the UI is stalled, assume the main thread is overloaded until profiling
proves otherwise.

## Triage workflow

### 1. Reproduce a single concrete interaction

Start with one specific symptom:

- tapping a button does nothing for half a second
- pushing a detail screen pauses before animating
- dismissing a sheet freezes scrolling underneath

Avoid broad goals like "the app feels slow" until you isolate a single path.

### 2. Record with Instruments

Use the Hangs instrument, and pair it with Time Profiler when needed.

Good capture setup:

- Release build
- real device
- repeatable interaction path
- enough repetitions to confirm the same stall pattern

### 3. Inspect busy windows on the main thread

Look for long busy periods instead of staring at total CPU first.

Questions to answer:

- Is the main thread blocked in app code?
- Is it blocked in synchronous I/O?
- Is it repeatedly recalculating layout or view state?
- Is there a lock or actor hop forcing serialization?

### 4. Reduce the work, not just the symptom

A useful fix removes or re-locates expensive work. A weak fix only hides the
stall behind a spinner while the main thread still does too much.

## Common root causes

### Synchronous I/O on the main thread

Typical offenders:

- file reads
- JSON decoding for large payloads
- image decoding
- database fetches
- Keychain work done inline with UI gestures

```swift
// DON'T
Button("Open") {
    let data = try? Data(contentsOf: fileURL)
    model = parse(data)
}

// DO
Button("Open") {
    Task {
        let data = try await loadFileData()
        let parsed = try await parseModel(from: data)
        await MainActor.run { model = parsed }
    }
}
```

### Heavy work in event handlers

A tap handler should kick off work, not do all the work inline.

```swift
// DON'T
func didTapRefresh() {
    items = expensiveRebuildOfEntireList()
}

// DO
func didTapRefresh() {
    Task {
        let rebuilt = await rebuildList()
        await MainActor.run { items = rebuilt }
    }
}
```

### Main-thread contention from layout or rendering

SwiftUI and UIKit/AppKit can both stall if the view tree triggers too much work
per interaction.

Watch for:

- repeated formatter creation
- image resizing in `body`
- expensive attributed string generation during scroll
- layout invalidations triggered by frequent geometry changes

### Locking and serialization

A hang may show up as main-thread waiting, not main-thread computing.

Examples:

- a lock held by background work
- synchronous dispatch back to main
- a main-actor method waiting on another main-actor path

### Priority inversion

If high-priority UI work is waiting on lower-priority work that holds a needed
resource, the UI still feels hung even if the main thread stack looks shallow.

## Fix patterns

### Keep main-thread work small and deterministic

Prefer this split:

- main thread: input, state wiring, view invalidation
- background work: parsing, formatting batches, image prep, persistence
- main thread again: commit the final result

### Precompute instead of recompute

```swift
// DON'T
Text(distanceFormatter.string(from: trip.distance))

// DO
Text(trip.formattedDistance)
```

If the value changes rarely, compute it at the model boundary.

### Stream results instead of blocking for all results

When practical, render partial state first and append or replace as work
finishes.

### Cancel stale work aggressively

A common hang pattern is doing unnecessary work for content the user already
navigated away from.

```swift
.task(id: searchQuery) {
    results = []
    results = await search(query: searchQuery)
}
```

Pair this with cancellation inside the async work.

Remember that a `.task` closure declared from a SwiftUI `body` inherits the view's main-actor context. Move heavy work into nonisolated async functions or dedicated actors; use `Task.detached` only when you intentionally break actor inheritance and can handle cancellation yourself.

## Verification checklist

After a fix, confirm all of the following:

- the same interaction no longer triggers a Hangs event
- main-thread busy windows are shorter
- the fix works in Release on device
- repeated interaction does not regress frame pacing
- cancellation works when navigating away mid-task

If the hang disappears but scrolling or animation gets worse elsewhere, the
work likely just moved rather than improved.

## Related SwiftUI implications

SwiftUI-specific hangs often come from:

- long view body updates
- broad observable dependencies
- list identity churn
- hidden work in formatting or filtering

Use the SwiftUI Instrument when the symptom is tied to view updates or layout.
Use the Hangs instrument when the symptom is broad UI unresponsiveness and you
first need to confirm the main thread is blocked.
