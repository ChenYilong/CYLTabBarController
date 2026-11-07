---
name: debugging-instruments
description: "Debug iOS apps and profile performance using LLDB, the interactive Memory Graph Debugger, and Instruments. Use for crashes, retain-cycle inspection, hangs, build failures, and generic CPU, memory, energy, or network profiling. Use ios-memgraph-analysis for .memgraph capture, leaks CLI ownership paths, or persistent heap growth; use ios-ettrace-performance for ETTrace capture and JSON."
---

# Debugging and Instruments

Keep interactive graph and Instruments triage here. Route detailed `.memgraph`
command-line ownership/growth analysis and ETTrace work to their focused skills.

## Contents

- [LLDB Debugging](#lldb-debugging)
- [Memory Debugging](#memory-debugging)
- [Hang Diagnostics](#hang-diagnostics)
- [Build Failure Triage](#build-failure-triage)
- [Instruments Overview](#instruments-overview)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## LLDB Debugging

Start with a small, repeatable workflow:

1. Reproduce in a Debug build and stop at the narrowest useful breakpoint.
2. Inspect locals without executing code, then capture the current stack.
3. Move to the relevant frame or thread and verify the failing state.
4. Add a condition or watchpoint only when the bad transition is still unclear.

```text
(lldb) br set -f ViewModel.swift -l 42     # Stop at file and line
(lldb) v myLocal                           # Inspect without executing code
(lldb) po myObject                         # Use debugDescription when needed
(lldb) bt all                              # Capture every thread's backtrace
(lldb) frame select 3                      # Inspect a relevant frame
(lldb) br modify 1 -c "count > 10"         # Narrow a noisy breakpoint
(lldb) w set v self.score                  # Stop on an unexpected write
```

Use `v` over `po` when you only need a local variable value — it does not
execute code and cannot trigger side effects. Expression evaluation can execute
or mutate program state, and hardware watchpoints are scarce, so use both
deliberately.

Load [references/lldb-patterns.md](references/lldb-patterns.md) for the complete
inspection, breakpoint/logpoint, expression, watchpoint, thread navigation, and
symbolic-breakpoint command tables.

## Memory Debugging

### Memory Graph Debugger Workflow

1. Run the app in Debug configuration.
2. Reproduce the suspected leak (navigate to a screen, then back).
3. Tap the **Memory Graph** button in Xcode's debug bar.
4. Look for purple warning icons — these indicate leaked objects.
5. Select a leaked object to see its reference graph and backtrace.

Enable **Malloc Stack Logging** (Scheme > Diagnostics) before running so
the Memory Graph shows allocation backtraces.

### Common Retain Cycle Patterns

**Closure capturing self strongly:**

```swift
// LEAK — closure holds strong reference to self
class ProfileViewModel {
    var onUpdate: (() -> Void)?

    func startObserving() {
        onUpdate = {
            self.refresh()  // strong capture of self
        }
    }
}

// FIXED — use [weak self]
func startObserving() {
    onUpdate = { [weak self] in
        self?.refresh()
    }
}
```

**Strong delegate reference:**

```swift
// LEAK — strong delegate creates a cycle
protocol DataDelegate: AnyObject {
    func didUpdate()
}

class DataManager {
    var delegate: DataDelegate?  // should be weak
}

// FIXED — weak delegate
class DataManager {
    weak var delegate: DataDelegate?
}
```

**Timer retaining target:**

```swift
// LEAK — Timer.scheduledTimer retains its target
timer = Timer.scheduledTimer(
    timeInterval: 1.0, target: self,
    selector: #selector(tick), userInfo: nil, repeats: true
)

// FIXED — use closure-based API with [weak self]
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.tick()
}
```

### Instruments: Allocations and Leaks

- **Allocations template**: Track memory growth over time. Use the
  "Mark Generation" feature to isolate allocations created between
  user actions (e.g., open/close a screen).
- **Leaks template**: Detects leaked allocations, including isolated retain
  cycles the process can no longer reach. Run alongside Allocations for a
  complete picture.
- Filter by your app's module name to exclude system allocations.

For leak or memory-growth triage, pair the tools: use Allocations **Mark
Generation** before and after the reproduction step to prove retained growth,
then use Memory Graph Debugger to inspect object ownership and Malloc Stack
Logging to recover allocation call stacks.

### Malloc Stack Logging

Enable in Scheme > Run > Diagnostics > Malloc Stack Logging. This records
allocation backtraces so the Memory Graph Debugger, Allocations instrument,
and exported `.memgraph` files can show where objects were created.

```bash
# Inspect an exported memory graph from Xcode or Instruments
leaks MyApp.memgraph
```

## Hang Diagnostics

### Identifying Main Thread Hangs

For discrete interactions, delays under 100 ms are rarely noticeable. Apple
developer tools commonly report main-run-loop busy periods over 250 ms, but
that reporting threshold is not a product target: a few hundred milliseconds
can still feel unresponsive. Common detection tools:

- **Thread Checker** (Xcode Diagnostics): warns about non-main-thread UI calls
- **Thread Performance Checker**: reports priority inversions while debugging
- **On-device Hang Detection**: Developer Settings reports hangs from device use
- **Time Profiler / CPU Profiler / Hitches**: profile reproducible hangs
- **os_signpost** and `OSSignposter`: mark intervals for Instruments
- **MetricKit** hang diagnostics: production hang detection (see
  `metrickit` skill for `HangDiagnostic` and iOS 26 compatibility)

```swift
import os

let signposter = OSSignposter(subsystem: "com.example.app", category: "DataLoad")

func loadData() async {
    let state = signposter.beginInterval("loadData")
    let result = await fetchFromNetwork()
    signposter.endInterval("loadData", state)
    process(result)
}
```

### Using the Time Profiler

1. Product > Profile (Cmd+I) to launch Instruments.
2. Select the **Time Profiler** template.
3. Record while reproducing the slow interaction.
4. Focus on the main thread — sort by "Weight" to find hot paths.
5. Check "Hide System Libraries" to see only your code.
6. Double-click a heavy frame to jump to source.

### Common Hang Causes

| Cause | Symptom | Fix |
|-------|---------|-----|
| Synchronous I/O on main thread | Network/file reads block UI | Move to `Task { }` or background actor |
| Lock contention | Main thread waiting on a lock held by background work | Use actors or reduce lock scope |
| Layout thrashing | Repeated `layoutSubviews` calls | Batch layout changes, avoid forced layout |
| JSON parsing large payloads | UI freezes during data load | Parse on a background thread |
| Synchronous image decoding | Scroll jank on image-heavy lists | Use `AsyncImage` or decode off main thread |

## Build Failure Triage

### Reading Compiler Diagnostics

- Start from the **first** error — subsequent errors are often cascading.
- Search for the error code (e.g., `error: cannot convert`) in the build log.
- Use Report Navigator (Cmd+9) for the full build log with timestamps.

### SPM Dependency Resolution

```text
# Common: version conflict
error: Dependencies could not be resolved because root depends on 'Package' 1.0.0..<2.0.0

# Fix: check Package.resolved and update version ranges
# Reset package caches if needed:
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
swift package resolve
```

### Module Not Found / Linker Errors

| Error | Check |
|-------|-------|
| `No such module 'Foo'` | Target membership, import paths, framework search paths |
| `Undefined symbol` | Linking phase missing framework, wrong architecture |
| `duplicate symbol` | Two targets define same symbol; check for ObjC naming collisions |

Build settings to inspect first:
- `FRAMEWORK_SEARCH_PATHS`
- `OTHER_LDFLAGS`
- `SWIFT_INCLUDE_PATHS`
- `BUILD_LIBRARY_FOR_DISTRIBUTION` (for XCFrameworks)

## Instruments Overview

### Template Selection Guide

| Template | Use When |
|----------|----------|
| **Time Profiler** | CPU is high, UI feels slow, need to find hot code paths |
| **Allocations** | Memory grows over time, need to track object lifetimes |
| **Leaks** | Suspect retain cycles or abandoned objects |
| **Network** | Inspecting HTTP request/response timing and payloads |
| **SwiftUI** | Profiling view body evaluations and update frequency |
| **Animation Hitches / Core Animation instruments** | Frame drops, hitches, blending, and commit/render work |
| **Power Profiler** | Battery drain, thermal pressure, background energy impact |
| **File Activity** | Excessive disk I/O, slow file operations |
| **System Trace** | Thread scheduling, syscalls, virtual memory faults |

### xctrace CLI for CI Profiling

```bash
# Record a trace from the command line
xcrun xctrace record --device "My iPhone" \
    --template "Time Profiler" \
    --instrument "Allocations" \
    --output profile.trace \
    --launch -- /path/to/MyApp.app

# Export trace data as XML for automated analysis
xcrun xctrace export --input profile.trace --xpath '/trace-toc/run/data/table'

# List available templates
xcrun xctrace list templates

# List connected devices
xcrun xctrace list devices
```

Use one `--template` per recording; add extra instruments with
`--instrument`. Use `xctrace` in CI pipelines to catch performance regressions
automatically. Compare exported metrics between builds.

## Common Mistakes

### DON'T: Use print() for debugging instead of os.Logger

Use `Logger` for levels, privacy metadata, and subsystem/category filtering;
`.debug` remains in memory and is not persisted in release builds.

```swift
// WRONG — unstructured and not filterable by subsystem/category
print("user tapped button, state: \(viewModel.state)")
print("network response: \(data)")

// CORRECT — structured logging with Logger
import os

let logger = Logger(subsystem: "com.example.app", category: "UI")

logger.debug("Button tapped, state: \(viewModel.state, privacy: .public)")
logger.info("Network response received, bytes: \(data.count)")
```

### DON'T: Forget to enable Malloc Stack Logging before memory debugging

```swift
// WRONG — open Memory Graph without enabling Malloc Stack Logging
// Result: leaked objects visible but no allocation backtrace

// CORRECT — enable BEFORE running:
// Scheme > Run > Diagnostics > check "Malloc Stack Logging: All Allocations"
// Then run, reproduce the leak, and open Memory Graph
```

### DON'T: Debug optimized code expecting full variable visibility

```swift
// WRONG — profiling with Debug build, debugging with Release build
// Debug builds: extra runtime checks distort perf measurements
// Release builds: variables show as "<optimized out>" in debugger

// CORRECT approach:
// Debugging: use Debug configuration (full symbols, no optimization)
// Profiling: use Release configuration (realistic performance)
```

### DON'T: Stop on every loop iteration without conditional breakpoints

```swift
// WRONG — breakpoint on line inside loop, stops 10,000 times
for item in items {
    process(item)  // breakpoint here stops on EVERY item
}

// CORRECT — use a conditional breakpoint:
// (lldb) br set -f MyFile.swift -l 42 -c "item.id == targetID"
// Or in Xcode: right-click breakpoint > Edit > add Condition
```

### DON'T: Ignore Thread Sanitizer warnings

Thread Sanitizer (TSan) warnings indicate data races that may only crash
intermittently. Treat them as real bugs unless you have isolated a tool issue.

```swift
// WRONG — ignoring TSan warning about concurrent access
var cache: [String: Data] = [:]  // accessed from multiple threads

// CORRECT — protect shared mutable state
actor CacheActor {
    var cache: [String: Data] = [:]

    func get(_ key: String) -> Data? { cache[key] }
    func set(_ key: String, _ value: Data) { cache[key] = value }
}
```

Enable TSan: Scheme > Run > Diagnostics > Thread Sanitizer. For iOS, iPadOS,
tvOS, visionOS, and watchOS apps, run TSan in Simulator; Apple documents device
support only for 64-bit macOS apps.

## Review Checklist

- [ ] Using `os.Logger` instead of `print()` for diagnostic output
- [ ] Malloc Stack Logging enabled before memory debugging sessions
- [ ] Memory Graph Debugger checked after dismiss/dealloc flows
- [ ] Delegates declared as `weak var` to prevent retain cycles
- [ ] Closures stored as properties use `[weak self]` capture lists
- [ ] Timers use closure-based API with `[weak self]`
- [ ] Thread Sanitizer enabled in Simulator test schemes for race triage
- [ ] No synchronous I/O or heavy computation on the main thread
- [ ] Time Profiler run on Release build for performance baselines
- [ ] Build failures triaged from the first error in the build log
- [ ] `OSSignposter` used for custom performance intervals
- [ ] Conditional breakpoints used for loop/collection debugging

## References

- [Logging (unified logging system)](https://sosumi.ai/documentation/os/logging)
- [Logger](https://sosumi.ai/documentation/os/logger)
- [OSSignposter](https://sosumi.ai/documentation/os/ossignposter)
- [Generating log messages from your code](https://sosumi.ai/documentation/os/generating-log-messages-from-your-code)
- [Recording performance data (signposts)](https://sosumi.ai/documentation/os/recording-performance-data)
- [Diagnosing memory, thread, and crash issues early](https://sosumi.ai/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [Data races](https://sosumi.ai/documentation/xcode/data-races)
- [Reducing your app's memory use](https://sosumi.ai/documentation/xcode/reducing-your-app-s-memory-use)
- [Profiling apps using Instruments](https://developer.apple.com/tutorials/instruments)
- [Improving app responsiveness](https://sosumi.ai/documentation/xcode/improving-app-responsiveness)
- [Analyzing your app's battery use](https://sosumi.ai/documentation/xcode/analyzing-your-app-s-battery-use)
- [Analyzing the performance of your shipping app](https://sosumi.ai/documentation/xcode/analyzing-the-performance-of-your-shipping-app)
- LLDB command reference: [references/lldb-patterns.md](references/lldb-patterns.md)
- Instruments template guide: [references/instruments-guide.md](references/instruments-guide.md)
