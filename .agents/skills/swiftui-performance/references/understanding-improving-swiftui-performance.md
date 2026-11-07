# Understanding and Improving SwiftUI Performance (Summary)

Context: Apple guidance on diagnosing SwiftUI performance with Instruments and
applying design patterns to reduce long or frequent updates.

## Contents
- Core concepts
- Instruments workflow
- Reading SwiftUI timeline lanes
- Diagnosing long updates
- Diagnosing frequent updates
- Common remediation patterns
- Verification loop
- Practical guardrails

## Core concepts

SwiftUI is declarative. Performance problems are usually one of two categories:

- **Long updates**: one update takes too much time
- **Frequent updates**: many small updates happen too often

Both feel bad to users, but they require different fixes.

### Long updates

These usually come from expensive body evaluation, expensive layout, or hosted
platform-view work.

### Frequent updates

These usually come from dependency fan-out, noisy observable state, or geometry
and timer signals invalidating more of the tree than intended.

## Instruments workflow

A practical workflow:

1. Profile in Release on a real device.
2. Choose the SwiftUI template.
3. Reproduce one interaction repeatedly.
4. Inspect the SwiftUI track first, then correlate with Time Profiler.
5. Change one thing at a time and re-record.

If you cannot reproduce the exact interaction on demand, your trace will be much
harder to interpret.

## Reading SwiftUI timeline lanes

### Update Groups

Shows clusters of update activity over time. Good for spotting periods where the
screen keeps re-evaluating even when no single event stands out.

### Long View Body Updates

Highlights expensive `body` work. These often point straight to code you can
simplify or move out of render paths.

### Long Representable Updates

Useful when SwiftUI hosts UIKit/AppKit content. Instruments 26 surfaces this as representable work; some documentation and expanded views refer to Platform View Updates. If this lane is hot, inspect:

- `UIViewRepresentable` / `UIViewControllerRepresentable`
- `List` row content with embedded platform views
- media, map, or web components

### Other Long Updates

Captures non-body SwiftUI work like layout, geometry, and update coordination.

### Hitches

Frame misses. These are the symptom users feel, not always the root cause.

## Diagnosing long updates

### Start with the red/orange update window

Do not begin from total runtime. Begin from the expensive update itself.

### Correlate with Time Profiler

Set inspection range on the slow update and inspect hot frames.

Common findings:

- formatting in `body`
- array transformations in `body`
- image decoding during scroll
- representable updates doing too much work every pass

### Typical fix shape

```swift
// DON'T
Text(Self.formatter.string(from: total as NSNumber) ?? "")

// DO
Text(viewModel.formattedTotal)
```

The right fix is usually architectural, not micro-optimizing the same body code.

## Diagnosing frequent updates

### Watch Update Groups and Cause Graph together

Frequent updates often look like "the screen keeps waking up" rather than "one
frame is red."

### Look for noisy dependencies

Typical offenders:

- a timer injected high in the tree
- geometry state stored in a shared model
- a broad `@Observable` root model
- environment values changing more often than needed

### Reduce fan-out

Good strategies:

- split shared models by domain
- move fast-changing state lower in the tree
- derive narrow child state instead of passing whole parents
- gate updates by thresholds when continuous values are noisy

## Common remediation patterns

### Precompute presentation values

Cache strings, sorted arrays, and other display-ready values before render.

### Make dependencies narrower

A row should depend on row state, not screen state.

### Keep representables idempotent

Only touch hosted UIKit/AppKit views when actual inputs changed.

### Avoid layout feedback loops

Be careful when geometry changes trigger state changes that trigger layout again.

### Make lists identity-friendly

Use stable IDs, pre-filtered data, and consistent row counts.

## Verification loop

After every performance change:

- record the same trace again
- compare update counts
- compare hitch frequency
- compare the target lane you were trying to cool down
- verify behavior still matches product requirements

Performance fixes can accidentally change animation timing, placeholder states,
or navigation behavior. Verify the UX, not just the graph.

## Practical guardrails

Use these as default heuristics:

- keep work out of `body`
- prefer smaller dependency surfaces
- cache display data near the model layer
- avoid hidden per-row allocations in lists
- profile Release builds, not just debug builds
- treat frequent updates and long updates as different bugs

When a screen still feels slow after obvious body cleanups, the next place to
look is usually dependency fan-out, not isolated hot code.
