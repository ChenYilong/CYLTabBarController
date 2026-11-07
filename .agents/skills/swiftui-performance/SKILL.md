---
name: swiftui-performance
description: "Profile, diagnose, and remediate SwiftUI runtime performance using code review, Instruments, and repeatable measurements. Use when a SwiftUI screen renders slowly, scrolling or animations hitch, view bodies update excessively, list identity churns, layout work spikes, or broad Observation dependencies raise CPU cost. Covers evidence-based triage, SwiftUI Instruments lanes, lazy-container guardrails, state lifetime, and before/after verification."
---

# SwiftUI Performance

Audit SwiftUI view performance from a reproducible symptom to measured
remediation. Route animation design to `swiftui-animation`, production telemetry
to `metrickit`, ownership/leak analysis to `ios-memgraph-analysis`, navigation
behavior to `swiftui-navigation`, state architecture to `swiftui-patterns`, and
layout construction to `swiftui-layout-components`.

## Contents

- [Workflow Decision Tree](#workflow-decision-tree)
- [1. Code-First Review](#1-code-first-review)
- [2. Guide the User to Profile](#2-guide-the-user-to-profile)
- [3. Analyze and Diagnose](#3-analyze-and-diagnose)
- [4. Remediate](#4-remediate)
- [Common Code Smells (and Fixes)](#common-code-smells-and-fixes)
- [5. Verify](#5-verify)
- [Outputs](#outputs)
- [Instruments Profiling](#instruments-profiling)
- [Identity and Lifetime](#identity-and-lifetime)
- [Lazy Loading Patterns](#lazy-loading-patterns)
- [State and Observation Optimization](#state-and-observation-optimization)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Workflow Decision Tree

- Code supplied: review it first and label findings as hypotheses.
- Symptoms only: collect the smallest relevant view, data flow, reproduction,
  device, OS, and build configuration.
- Inconclusive review: collect a trace or lane screenshots before prescribing a
  broad refactor.

Use this triage list for both code and trace analysis:

- Broad state dependencies or invalidation storms
- Unstable list identity or root conditional swapping
- Formatting, sorting, decoding, or synchronous I/O in `body`
- Layout/geometry feedback loops and oversized images
- Implicit animation applied to a large hierarchy

## 1. Code-First Review

Map each suspect from the triage list to exact code. Report likely causes with
code references, but label them code-backed hypotheses until a trace confirms
cost. Propose a minimal repro or measurement when evidence is missing.

## 2. Guide the User to Profile

Use the SwiftUI Instruments template on a **Release build** and real device when
possible. Reproduce the exact interaction, capturing SwiftUI lanes, Time
Profiler, and Hangs/Hitches as relevant. Ask for the trace or screenshots of the
lanes and call tree.

## 3. Analyze and Diagnose

Apply the same triage list to trace evidence. Correlate long or frequent SwiftUI
updates with the Time Profiler call tree and the reproduced interaction. Separate
trace-backed findings from code-backed hypotheses and name the next measurement
that would resolve remaining uncertainty.

## 4. Remediate

Apply targeted fixes:
- Narrow state scope (`@State`/`@Observable` closer to leaf views).
- Stabilize identities for `ForEach` and lists.
- Move heavy work out of `body` into model-layer precomputation, an explicit derived
  value updated when its inputs change, a memoized helper, or background processing.
  Use `@State` only when the view owns both the value and its update lifecycle; it is
  not a generic cache for arbitrary computation.
- Use `equatable()` only when equality is cheaper than recomputing the subtree and
  the compared inputs have stable value semantics.
- Downsample images before rendering.
- Reduce layout complexity or use fixed sizing where possible.

## Common Code Smells (and Fixes)

| Smell | Evidence to seek | Targeted fix |
|---|---|---|
| Formatter, sort, filter, or decode in `body` | Long/frequent body updates with matching call-tree cost | Recompute when inputs change; downsample/decode off the main actor |
| `UUID()` or unstable `id: \.self` | Recreated rows, lost state, excess updates | Use stable model identity |
| Root `if`/`else` swaps | State reset or update spikes when toggled | Localize conditional content/modifiers when semantics allow |
| Broad model reads | Many unrelated views update together | Pass narrow values or move reads into focused child views |
| Geometry writes during layout | Repeating layout/update cycle | Threshold changes or replace the feedback path with stable layout |

## 5. Verify

Ask the user to re-run the same capture and compare with baseline metrics.
Summarize the delta (CPU, frame drops, memory peak) if provided.

## Outputs

Provide:
- A short metrics table (before/after if available).
- Top issues (ordered by impact).
- Proposed fixes with estimated effort.

## Instruments Profiling

Use the **SwiftUI template** in Instruments (Cmd+I to profile). Current SwiftUI lanes include Update Groups, Long View Body Updates, Long Representable Updates / Representable Updates, Other Long Updates / Other Updates, and the Cause & Effect Graph. Correlate those with Time Profiler and Hangs/Hitches.

Add `Self._printChanges()` in debug builds to log which property triggered a view update:

```swift
var body: some View {
    #if DEBUG
    let _ = Self._printChanges()  // "MyView: @self, _count changed."
    #endif
    Text("Count: \(count)")
}
```

See [references/optimizing-swiftui-performance-instruments.md](references/optimizing-swiftui-performance-instruments.md) for the full profiling workflow.

## Identity and Lifetime

Identity controls view lifetime and state. Use stable model IDs in repeated
content and reserve `.id(_:)` changes for intentional resets. Prefer
`@ViewBuilder` or generic composition over `AnyView` in profiled hot rows. Treat
root conditional branches as suspects—not automatic defects—when evidence shows
state churn or expensive recreation.

```swift
Text(title)
    .foregroundStyle(isHighlighted ? .yellow : .primary)

ForEach(items) { item in
    Row(item: item).id(item.stableID)
}
```

## Lazy Loading Patterns

Use lazy containers when profiling shows eager construction, layout, or update
work is material; there is no universal item-count threshold. Route grid/list
construction choices to `swiftui-layout-components`.

Guardrails:

- Off-screen views are removed from the lazy stack. SwiftUI may keep them briefly, then delete the views and their view-local state.
- Persist important row state outside the row view if it must survive scrolling away.
- Body and layout work can happen before `onAppear` because of prefetching. Do not make `onAppear` the only setup point for data a row needs to render.
- Treat `onAppear` and `onDisappear` as visibility signals, not lifetime guarantees.
- Filter data before `ForEach`; avoid `if` branches that make each element produce zero or one row.
- Keep each `ForEach` element to a constant number of top-level subviews. Wrap row contents in a stable container if needed. Use `-LogForEachSlowPath YES` while debugging list/table slow paths.
- Avoid absolute content-size or content-offset assumptions; lazy stacks estimate off-screen sizes.
- Avoid geometry feedback loops in lazy rows. Prefer stable sizing, layout primitives, or a custom `Layout` before feeding geometry changes back into row state.

## State and Observation Optimization

Observation tracks properties read during view evaluation. Reduce fan-out by
passing narrow derived values or moving reads into focused child views.

```swift
// Split reads into child views so each tracks only what it renders.
struct ProfileView: View {
    let model: ProfileModel
    var body: some View {
        VStack {
            NameRow(model: model)      // only tracks name
            EmailRow(model: model)     // only tracks email
            AvatarView(model: model)   // only tracks avatar
            SettingsForm(model: model) // only tracks settings
        }
    }
}
```

Cheap computed values can remain derived; expensive transformations need an
explicit owner, input set, and refresh trigger. Do not add view models as a
performance ritual—measure first and route general state design to
`swiftui-patterns`.

## Common Mistakes

1. **Profiling Debug builds.** Debug builds include extra runtime checks and disable optimizations, producing misleading perf data. Profile Release builds on a real device.
2. **Observing an entire model when only one property is needed.** Break large `@Observable` models into focused ones, or use computed properties/closures to narrow observation scope.
3. **Using geometry feedback inside ScrollView items.** GeometryReader or noisy geometry state can force repeated layout. Prefer stable sizing, custom layout, or narrowly scoped `.onGeometryChange` (iOS 16+) with thresholds.
4. **Calling `DateFormatter()` or `NumberFormatter()` inside `body`.** These are expensive to create. Make them static or move them outside the view.
5. **Animating non-equatable state.** If SwiftUI cannot determine equality, it redraws every frame. Conform state to `Equatable`, then use `.animation(_:value:)` for simple value-bound changes or `.animation(_:body:)` for narrower modifier-scoped implicit animation.
6. **Large flat `List` without identifiers.** Use `id:` or make items `Identifiable` so SwiftUI can diff efficiently instead of rebuilding the entire list.
7. **Unnecessary `@State` wrapper objects.** Wrapping a simple value type in a class for `@State` defeats value semantics. Use plain `@State` with structs.
8. **Blocking `MainActor` with synchronous I/O.** File reads, JSON parsing of large payloads, and image decoding should happen off the main actor. Prefer nonisolated async helpers or dedicated actors; reserve `Task.detached` for cases where you intentionally break actor inheritance and handle cancellation yourself.

## Review Checklist

- [ ] No `DateFormatter`/`NumberFormatter` allocations inside `body`
- [ ] Large lists use `Identifiable` items or explicit `id:`
- [ ] `@Observable` models expose only the properties views actually read
- [ ] Heavy computation is off `MainActor` (image processing, parsing)
- [ ] Lazy rows have stable identity, constant top-level row shape, and prefiltered data
- [ ] Geometry changes in scroll rows are thresholded and do not feed broad state
- [ ] Row rendering does not depend on `onAppear` as the only setup point
- [ ] Implicit animations use `.animation(_:value:)` for value-bound changes or `.animation(_:body:)` for narrower modifier scope
- [ ] No synchronous network/file I/O on the main thread
- [ ] Profiling done on Release build, real device
- [ ] `@State` is not used as an unspecified cache; every derived value has an explicit owner and refresh trigger
- [ ] `equatable()` is used only when comparison is cheaper than recomputation and inputs have stable value semantics
- [ ] Findings distinguish code-backed hypotheses from trace-backed evidence
- [ ] `@Observable` view models are `@MainActor`-isolated; types crossing concurrency boundaries are `Sendable`

## References

- Demystify SwiftUI performance (WWDC23): [references/demystify-swiftui-performance-wwdc23.md](references/demystify-swiftui-performance-wwdc23.md)
- Optimizing SwiftUI performance with Instruments: [references/optimizing-swiftui-performance-instruments.md](references/optimizing-swiftui-performance-instruments.md)
- Understanding hangs in your app: [references/understanding-hangs-in-your-app.md](references/understanding-hangs-in-your-app.md)
- Understanding and improving SwiftUI performance: [references/understanding-improving-swiftui-performance.md](references/understanding-improving-swiftui-performance.md)
- WWDC transcript sources: [references/wwdc-session-sources.md](references/wwdc-session-sources.md)
