# Demystify SwiftUI Performance (WWDC23) (Summary)

Context: WWDC23 session on building a mental model for SwiftUI performance and
triaging hangs, hitches, and excessive update work.

## Contents
- Core mental model
- Dependencies and invalidation
- Expensive body work
- Identity rules for lists and tables
- Initialization and lifecycle pitfalls
- Debugging tools
- Fix patterns
- What to verify after a change

## Core mental model

SwiftUI performance starts with one rule: only work that is required for the
current state should happen for the current frame.

A slow screen usually means one of these is false:

- too much work happens per update
- updates happen too often
- identity is unstable, so SwiftUI redoes work it could have reused

The session's practical loop is:

- Measure
- Identify
- Optimize
- Re-measure

Do not skip the last step. SwiftUI optimizations are easy to misjudge by eye.

## Dependencies and invalidation

A view updates when one of its dependencies changes.

Common dependency sources:

- `@State`
- `@Binding`
- `@Observable` / `@ObservedObject`
- `@Environment`
- container-derived identity (`ForEach`, `List`, `Table`)

The performance goal is not "fewer dependencies" in the abstract. The goal is
**precise dependencies** so only the view that needs to update actually updates.

### Practical implications

- Avoid a row depending on a whole collection if it only needs one element.
- Avoid broad environment-driven updates for fast-changing values.
- Extract subviews when a smaller view can read a smaller state surface.

### Debug-only dependency inspection

`Self._printChanges()` is useful in debug builds when you are not sure why a
view keeps updating.

Use it to answer:

- which property changed?
- which parent view re-rendered?
- is the view reacting to state it should not care about?

Do not treat `_printChanges()` output as a shipping-time profiling tool.

## Expensive body work

View bodies need to stay cheap.

Typical mistakes:

- string formatting in `body`
- array filtering and sorting in `body`
- expensive image work in `body`
- constructing large attributed strings during render
- initializing heavy models in-line with view creation

```swift
// DON'T
var body: some View {
    List(items.filter(shouldShow).sorted(by: sortRule)) { item in
        Text(numberFormatter.string(from: item.value as NSNumber) ?? "")
    }
}

// DO
var body: some View {
    List(viewModel.visibleItems) { item in
        Text(item.formattedValue)
    }
}
```

The winning pattern is precomputation at the model boundary, not clever work in
`body`.

## Identity rules for lists and tables

Identity is one of the biggest hidden performance levers in SwiftUI.

### Stable identity matters

Use stable IDs that survive refreshes and sorting. If identity churns, SwiftUI
cannot reuse rows, preserve animations, or diff efficiently.

### Constant row count matters

Inside `ForEach`, SwiftUI expects a predictable mapping between data elements and
rendered views.

Avoid patterns like:

```swift
ForEach(items) { item in
    if item.isVisible {
        Row(item: item)
    }
}
```

Prefer:

```swift
ForEach(visibleItems) { item in
    Row(item: item)
}
```

Use `-LogForEachSlowPath YES` while debugging when you suspect a list or table is taking the non-constant row-count path.

### Avoid `AnyView` in hot list rows

Type erasure can hide useful structural information and increase work in large
lists or tables.

### Table-specific note

`TableRow` resolves to a single row. Keep row structure predictable and use the
streamlined `Table` APIs when possible.

## Initialization and lifecycle pitfalls

### Heavy model creation in view init/body

Keep view initialization lightweight. Start async work with `.task` or from a
model object.

```swift
// DON'T
struct DetailView: View {
    let loader = BigLoader() // heavy construction
}

// DO
struct DetailView: View {
    @State private var model: DetailModel?

    var body: some View {
        content
            .task {
                model = await loadDetailModel()
            }
    }
}
```

### Hidden work from computed properties

A computed property can still be body work if it runs during render. If it is
expensive, treat it like body work and precompute it.

## Debugging tools

### Instruments

Use Instruments for hangs, hitches, update counts, and expensive frames.

### `_printChanges()`

Use it in debug to inspect dependency behavior.

### Release-build validation

A debug build can make SwiftUI performance look worse or different than a
shipping build. Validate important performance changes in Release on device.

## Fix patterns

### Split views by dependency boundary

If one small piece of state changes frequently, isolate the subview that reads
it.

### Pre-filter and cache collections

Do filtering, mapping, sorting, and grouping before rendering.

### Avoid broad environment reads in hot paths

Environment is convenient but not free. Keep fast-changing values local unless
multiple subtrees truly need them.

### Reduce hidden allocations

Move formatters, bundle lookups, and derived strings out of repeated body paths.

## What to verify after a change

After optimizing, check all of the following:

- the target interaction feels smoother
- update counts dropped in Instruments
- row identity stayed stable across reloads
- animation behavior still matches product intent
- no correctness bugs were introduced by caching or splitting views

A performance fix that breaks state ownership or animation correctness is not a
real fix.
