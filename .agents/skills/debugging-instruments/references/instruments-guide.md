# Instruments Guide Reference

Detailed template-by-template guide for profiling iOS apps with Instruments. Companion to the main `debugging-instruments` skill.

## Contents

- [General Workflow](#general-workflow)
- [Time Profiler](#time-profiler)
- [Allocations](#allocations)
- [Leaks](#leaks)
- [Network](#network)
- [SwiftUI Instruments](#swiftui-instruments)
- [Animation Hitches and Core Animation](#animation-hitches-and-core-animation)
- [Power Profiler](#power-profiler)
- [File Activity](#file-activity)
- [System Trace](#system-trace)
- [xctrace CLI](#xctrace-cli)
- [Custom Instruments with os_signpost](#custom-instruments-with-os_signpost)
- [Automation and CI Integration](#automation-and-ci-integration)

## General Workflow

1. **Build for profiling**: Product > Profile (Cmd+I). This builds with Release optimization by default.
2. **Select a template** from the Instruments chooser.
3. **Configure recording**: Set the target device and process.
4. **Record**: Press the red record button and reproduce the scenario.
5. **Analyze**: Use the timeline, detail views, and call tree to find issues.
6. **Filter**: Check "Hide System Libraries" and use the search bar to focus on your code.

Always profile on a **physical device** for accurate measurements. Simulator
performance does not reflect real-world behavior.

## Time Profiler

**When to use**: CPU is high, UI is slow, animations stutter, or you need to
find which functions consume the most time.

### Key Workflow

1. Record while reproducing the slow interaction.
2. Select the time range of interest in the timeline.
3. Switch to the **Call Tree** view in the detail pane.
4. Enable these checkboxes:
   - **Separate by Thread** — isolate main thread vs background
   - **Invert Call Tree** — show leaf functions (actual work) first
   - **Hide System Libraries** — focus on your code
5. Sort by **Weight** (self time) to find the hottest functions.
6. Double-click a function to view source with per-line timing.

### Reading the Call Tree

- **Weight**: total time in this function and all its callees
- **Self Weight**: time spent in this function alone (not callees)
- **Symbol Name**: the function — look for your module prefix

Focus on functions with high **Self Weight** — these are doing the actual work.

### Tips

- Profile the same user interaction 3 times to get stable measurements.
- Use the **Comparison** view to diff traces before/after a fix.
- Check "Flatten Recursion" if recursive calls make the tree hard to read.

## Allocations

**When to use**: Memory grows over time, you suspect objects are not being
freed, or you need to track object lifetimes.

### Key Workflow

1. Record while reproducing the scenario.
2. Use **Mark Generation** (button in the detail pane) to snapshot allocations
   at specific points. For example:
   - Mark before navigating to a screen
   - Navigate to the screen
   - Navigate back
   - Mark again
   - The difference shows objects that were not freed
3. Expand a generation to see allocations grouped by category.
4. Filter by your module name to exclude system allocations.

### Allocation Lifespan

- **Created & Still Living**: objects allocated and not yet freed
- **Created & Destroyed**: objects with normal lifetimes
- **Persistent**: long-lived allocations (singletons, caches)
- **Transient**: short-lived allocations (autoreleased, temporary)

Focus on "Created & Still Living" objects in the generation diff — these
are your potential leaks.

### Heap Growth Analysis

Enable the **Allocations List** and sort by **Persistent Bytes**. Look for:
- Classes with unexpectedly high instance counts
- Image data or NSData objects that should have been released
- View controllers that persist after dismissal

## Leaks

**When to use**: Suspected retain cycles or abandoned memory.

### Key Workflow

1. Run with the Leaks template.
2. The tool automatically checks for leaks every 10 seconds.
3. Red "Leak" markers appear in the timeline when leaks are detected.
4. Click a leak marker to see the leaked object and its retain/release history.
5. The **Cycles & Roots** view shows the reference graph — follow the arrows
   to find the cycle.

### Interpreting Results

- **Leak**: an object with no references pointing to it (true orphan)
- **Root Leak**: the object at the head of a leaked object graph
- **Cycles & Roots graph**: arrows show retain relationships — look for
  bidirectional arrows indicating a cycle

### Common Cycle Patterns

Leaks instrument commonly catches:
- Closure -> self -> closure cycles
- Delegate strong reference cycles
- NotificationCenter observer blocks retaining self
- CADisplayLink/Timer retaining target

## Network

**When to use**: Inspecting HTTP request/response timing, payload sizes,
or connection reuse.

### Key Workflow

1. Record with the Network template.
2. Each HTTP request appears as a bar in the timeline.
3. Select a request to see:
   - URL, method, status code
   - Request/response headers
   - Timing breakdown (DNS, connect, TLS, request, response)
   - Payload size

### What to Look For

- **Waterfall gaps**: sequential requests that could be parallelized
- **Large payloads**: responses that could use pagination or compression
- **Redundant requests**: duplicate calls to the same endpoint
- **DNS/TLS latency**: consider connection prewarming

## SwiftUI Instruments

**When to use**: SwiftUI view body is evaluated too frequently, unnecessary
redraws, or identity churn in lists.

### Key Workflow

1. Select the **SwiftUI** template in Instruments.
2. Record while interacting with the UI.
3. Check these lanes:
   - **Update Groups**: shows batches of view updates triggered together
   - **Long View Body Updates**: highlights body evaluations exceeding a time threshold
   - **Cause and Effect Graph**: traces why a view was re-evaluated
4. Look for views with excessive body evaluations during a single interaction.

### Tips

- Filter by view name to focus on a specific component.
- Cross-reference with Time Profiler to see if body evaluations are expensive.
- See the `swiftui-performance` skill for remediation patterns.

## Animation Hitches and Core Animation

**When to use**: Frame drops, off-screen rendering, excessive blending.

### Key Workflow

1. Record with the **Animation Hitches** template on a real device when the
   symptom is stutter or missed frames.
2. Add Core Animation instruments such as **Core Animation FPS**,
   **Core Animation Commits**, or **Core Animation Activity** when you need
   lower-level render pipeline detail.
3. Check FPS, hitches, commits, and frame lifetime lanes for drops or long
   commit/render work.
4. Enable these debug options in Recording Options or Xcode view debugging:
   - **Color Blended Layers** — red areas have multiple overlapping layers
   - **Color Off-screen Rendered** — yellow areas use off-screen passes
   - **Color Hits Green and Misses Red** — rasterization cache hits/misses

### Common Issues

| Issue | Indicator | Fix |
|-------|-----------|-----|
| Transparent overlapping views | Red blended layers | Use opaque backgrounds |
| Corner radius + clip | Off-screen rendering | Use `cornerCurve` with pre-masked images |
| Shadow without path | Off-screen rendering | Set `shadowPath` explicitly |
| Large images not downsampled | High memory + slow rendering | Downsample before display |

## Power Profiler

**When to use**: Battery drain complaints, background energy impact, or
App Store rejection for excessive energy use.

### Key Workflow

1. Record with the **Power Profiler** template on a physical device.
2. Check power, thermal, and energy-impact lanes for high readings.
3. Examine component breakdown:
   - CPU
   - Network
   - Location
   - GPU
   - Background tasks

### Tips

- Profile typical user sessions (5-10 minutes of real usage).
- Compare foreground vs background energy impact.
- Check that background tasks complete and do not run indefinitely.
- Cross-reference with MetricKit energy metrics from production.

## File Activity

**When to use**: Slow file operations, excessive disk I/O, or disk write
exceptions from MetricKit.

### Key Workflow

1. Record with the File Activity template.
2. Look for:
   - Frequent writes to the same file (journaling, logging)
   - Large reads on the main thread
   - Unintended file access patterns

## System Trace

**When to use**: Deep investigation of thread scheduling, virtual memory
faults, system calls, and inter-process communication.

### Key Workflow

1. Record with the System Trace template.
2. Focus on the main thread lane.
3. Look for:
   - **Thread blocks**: main thread waiting on locks, semaphores, or dispatch queues
   - **VM faults**: page faults from memory-mapped files or large allocations
   - **Context switches**: excessive switching between threads

This is the most advanced template — use it after Time Profiler when you
need OS-level detail.

## xctrace CLI

### Recording

```bash
# Record Time Profiler trace
xcrun xctrace record \
    --template "Time Profiler" \
    --device "iPhone" \
    --output ~/traces/profile.trace \
    --time-limit 30s \
    --launch -- /path/to/MyApp.app

# Record Allocations trace for a running app
xcrun xctrace record \
    --template "Allocations" \
    --device "iPhone" \
    --output ~/traces/alloc.trace \
    --attach MyApp

# Record with multiple instruments
xcrun xctrace record \
    --template "Time Profiler" \
    --instrument "Allocations" \
    --output ~/traces/combined.trace \
    --launch -- /path/to/MyApp.app
```

### Exporting Data

```bash
# List available tables in a trace
xcrun xctrace export --input profile.trace --toc

# Export specific table as XML
xcrun xctrace export --input profile.trace \
    --xpath '/trace-toc/run/data/table[@schema="time-profile"]'

# Export to a file
xcrun xctrace export --input profile.trace \
    --xpath '/trace-toc/run/data/table[@schema="time-profile"]' \
    --output profile_data.xml
```

### Listing Resources

```bash
# Available templates
xcrun xctrace list templates

# Connected devices
xcrun xctrace list devices

# Available instruments
xcrun xctrace list instruments
```

## Custom Instruments with os_signpost

### Emitting Signposts for Instruments

```swift
import os

let signposter = OSSignposter(subsystem: "com.example.app", category: "Networking")

func fetchUser(id: String) async throws -> User {
    let signpostID = signposter.makeSignpostID()
    let state = signposter.beginInterval("fetchUser", id: signpostID)
    defer { signposter.endInterval("fetchUser", state) }

    let (data, _) = try await URLSession.shared.data(from: userURL(id))
    signposter.emitEvent("dataReceived", id: signpostID, "\(data.count) bytes")

    return try JSONDecoder().decode(User.self, from: data)
}
```

### Viewing in Instruments

1. Open Instruments with a Blank document, then add the **os_signpost**
   instrument, or start from a template that includes **Points of Interest**.
2. Your custom intervals appear as labeled bars in the timeline.
3. Events appear as point markers.
4. Filter by subsystem or category to isolate your signposts.

### Integration with MetricKit

On iOS 27, signposts emitted through a retained
`MetricManager.logHandle(category:)` are reported in the daily
`MetricReport` as `MetricResult.signpostInterval`. See the `metrickit` skill
for the current custom-signpost pattern and the isolated iOS 26 compatibility
path.

## Automation and CI Integration

### Performance Baselines with xctrace

Create a shell script for CI:

```bash
#!/bin/bash
set -euo pipefail

APP_BUNDLE="build/MyApp.app"
TRACE_OUTPUT="traces/ci_profile_$(date +%s).trace"
TEMPLATE="Time Profiler"

# Record trace
xcrun xctrace record \
    --template "$TEMPLATE" \
    --output "$TRACE_OUTPUT" \
    --time-limit 60s \
    --launch -- "$APP_BUNDLE"

# Export data for analysis
xcrun xctrace export \
    --input "$TRACE_OUTPUT" \
    --toc > "traces/toc.xml"

echo "Trace saved to $TRACE_OUTPUT"
```

### XCTest Performance Metrics

Complement Instruments with in-test measurements:

```swift
func testScrollPerformance() {
    let app = XCUIApplication()
    app.launch()

    let measureOptions = XCTMeasureOptions()
    measureOptions.iterationCount = 5

    measure(metrics: [
        XCTClockMetric(),
        XCTCPUMetric(),
        XCTMemoryMetric(),
        XCTStorageMetric()
    ], options: measureOptions) {
        app.swipeUp()
        app.swipeDown()
    }
}
```

Set performance baselines in Xcode to automatically flag regressions in CI.
