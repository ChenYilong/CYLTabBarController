# Optimizing SwiftUI Performance with Instruments (Summary)

Context: WWDC session introducing the SwiftUI Instrument in Instruments 26 and
how to diagnose SwiftUI-specific bottlenecks.

## Contents
- When to use the SwiftUI Instrument
- Recommended capture setup
- Reading the SwiftUI timeline
- Workflow for long view body updates
- Workflow for frequent updates
- Cause and Effect Graph usage
- Common hotspots
- Fix patterns
- Re-measure checklist

## When to use the SwiftUI Instrument

Use the SwiftUI Instrument when the symptom is clearly tied to view updates,
layout, rendering, or state fan-out.

Good fits:

- scrolling stutters in a SwiftUI-heavy screen
- pushing a destination causes a pause during view construction
- an animation feels inconsistent even without obvious main-thread blocking
- a timer or observable object causes too many updates

If the symptom is a broad app freeze with no clear UI source, start with Hangs
or Time Profiler first, then move to SwiftUI-specific tools.

## Recommended capture setup

Profile with the same assumptions you use for shipping code:

- Release build
- real device
- reproducible interaction sequence
- minimal debug logging
- enough repetitions to show a pattern, not a one-off spike

A good baseline template is:

- SwiftUI Instrument
- Time Profiler
- Hangs or Animation Hitches when relevant

## Reading the SwiftUI timeline

Key lanes to understand:

### Update Groups

High-level buckets of SwiftUI work over time. Useful for spotting bursts of
activity even when no single update is individually slow.

### Long View Body Updates

Use this lane when a view `body` itself is expensive.

Interpretation:

- orange indicates notable cost
- red indicates clearly too-slow view updates

### Long Representable Updates

This usually points to UIKit/AppKit work hosted inside SwiftUI. Instruments 26 labels this as representable work; related documentation may call the expanded lane Platform View Updates. Inspect:

- `UIViewRepresentable`
- `UIViewControllerRepresentable`
- heavy `List`/table bridging
- embedded media or web views

### Other Long Updates

Catches expensive work outside pure body computation, such as:

- text layout
- geometry
- list diffing
- update coordination

## Workflow for long view body updates

### 1. Find a red or orange update

Start with one obviously expensive update rather than a long trace window.

### 2. Set inspection range

Select the update window so Time Profiler aligns with the same time slice.

### 3. Inspect the call tree or flame graph

Look for work that should not be happening during body evaluation.

Common surprises:

- formatter allocation
- sorting or filtering collections
- image decoding
- string building
- model initialization
- synchronous persistence reads

### 4. Move heavy work out of `body`

```swift
// DON'T
var body: some View {
    Text(items.sorted(by: \.date).map(\.title).joined(separator: ", "))
}

// DO
var body: some View {
    Text(viewModel.joinedTitles)
}
```

### 5. Re-record the same flow

If the trace still shows long view body updates, the expensive work likely just
moved into a child view or another dependency path.

## Workflow for frequent updates

Some screens feel slow because updates happen too often, not because any one
update is catastrophic.

### 1. Use Update Groups first

Look for long active ranges with many updates but no large red spikes.

### 2. Inspect counts, not just duration

A screen doing cheap work 200 times can still feel worse than one doing one
moderately expensive update.

### 3. Open Cause and Effect Graph

This is often the fastest way to answer:

- what changed?
- which dependency triggered the update?
- why did that change fan out to unrelated views?

### 4. Narrow the dependency scope

Typical fixes:

- extract subviews so they only read the state they need
- replace broad shared models with narrower derived state
- avoid environment values for fast-changing data
- split large `@Observable` models if unrelated properties change together

## Cause and Effect Graph usage

Use it when backtraces are misleading.

SwiftUI is declarative, so the expensive work may not appear near the code that
caused the update chain.

Good uses:

- a selection change updates an unrelated sidebar
- a timer invalidates a full list
- geometry updates ripple through many subviews
- a global favorites model causes every row to re-evaluate

## Common hotspots

### Formatter allocation

Avoid constructing `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter`
in `body` or per-row views.

### Filtering or sorting in the view tree

Precompute filtered collections before render.

### Geometry-driven layout churn

Avoid feeding raw geometry values through broad observable state.

### Identity instability

Lists and tables get expensive when identity changes or row counts vary in ways
SwiftUI cannot efficiently diff.

### Platform view bridging

Audit representables for repeated configuration work in `updateUIView` or
`updateUIViewController`.

## Fix patterns

### Cache presentation data

```swift
@Observable
final class TripPresentationModel {
    var formattedDistance: String = ""

    func update(distance: Measurement<UnitLength>, formatter: MeasurementFormatter) {
        formattedDistance = formatter.string(from: distance)
    }
}
```

### Scope observable dependencies

Prefer models where a row reads only row-local state.

### Keep representable updates idempotent

Only mutate the hosted platform view when input values actually changed.

### Gate noisy signals

A geometry or timer signal may need thresholding, debouncing, or coalescing.

## Re-measure checklist

After every change:

- record the same flow again
- compare update count, not just total runtime
- verify hitch frequency went down
- verify no new Long Representable / Platform View Updates appeared
- verify behavior in Release on device

If a change makes one screen faster but causes more updates elsewhere, keep
following the dependency graph until the fan-out is truly reduced.
