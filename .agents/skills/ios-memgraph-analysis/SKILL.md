---
name: ios-memgraph-analysis
description: "Use when capturing or analyzing an iOS .memgraph, especially when the task mentions a memory leak, heap growth, persistent memory increase, ownership path, or matched-capture comparison with Apple CLI tools. Covers unambiguous Simulator capture, leaks/heap/vmmap/malloc_history evidence, raw artifact preservation, and same-flow verification. Use debugging-instruments for interactive Xcode Memory Graph, Instruments, generic retain-cycle inspection, or LLDB work."
---

# iOS Memgraph Analysis

Use memory graphs to prove why memory survives a defined lifetime boundary.
Separate unreachable leaks from reachable growth, preserve raw tool output, and
verify the same app-owned type and ownership path after a fix.

## Contents

- [Boundary](#boundary)
- [Evidence Model](#evidence-model)
- [Workflow](#workflow)
- [Ownership Decisions](#ownership-decisions)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Boundary

This skill owns `.memgraph` capture and command-line ownership/growth analysis.
Use the Memory Graph Debugger or Instruments when their interactive graph and
allocation timeline are the primary task. Use source review for a suspected
closure capture only after runtime evidence identifies the lifetime or path.

## Evidence Model

Do not collapse these conditions:

- **Unreachable leak:** allocated memory no longer has a path from a live root.
  An isolated strong cycle can be unreachable and still consume memory.
- **Reachable but abandoned state:** a live root still retains objects the user
  flow no longer needs. `leaks` may correctly report zero.
- **Expected cache or pool:** memory survives intentionally and must be judged by
  its bound, eviction behavior, and pressure response.
- **Heap regression or fragmentation:** footprint grows because more/larger
  allocations persist or dirty pages are poorly utilized, without a leak.

Apple's leak scanner uses conservative pointer discovery and incomplete type
metadata. Counts can fluctuate, and a zero result does not prove the absence of
an ownership bug. Strong evidence identifies the expected lifetime, an
app-owned type or allocation, and a credible path or isolated reproduction.

## Workflow

### 1. Define the lifetime before capturing

Name the object that should disappear and the event that ends its useful life.
For example: `EditorViewModel` should deinitialize after dismissing the editor
and completing pending save work.

Record one deterministic sequence:

1. launch or restore a known state;
2. take an optional baseline graph;
3. perform the feature flow;
4. cross the expected release boundary;
5. wait for legitimate asynchronous cleanup;
6. take the post-flow graph.

Keep build, simulator/device, data, Malloc Stack Logging setting, and repetition
count stable. Malloc Stack Logging adds valuable allocation backtraces but also
overhead; compare only runs with the same setting.

### 2. Capture a graph without guessing the process

Xcode can export a graph from the Memory Graph Debugger. For a running Simulator
app, use the helper from this skill:

```bash
mkdir -p /tmp/myapp-memory
mkdir /tmp/myapp-memory/run-01
python3 scripts/capture_sim_memgraph.py \
  --bundle-id com.example.MyApp \
  --output-dir /tmp/myapp-memory/run-01 \
  --pretty > /tmp/myapp-memory/run-01/capture.json
```

The per-run `mkdir` must fail if the capture directory already exists. Use a
new run name rather than mixing stale evidence with a retry.

Pass `--udid` when more than one Simulator is booted. The helper accepts only
one exact launchd label and PID; zero or multiple matches are errors. It runs the
host `leaks --outputGraph` command, retains stdout/stderr, and writes a manifest.
Do not replace this with `pgrep | head -1` or a substring match.

Capturing suspends the process. Do not use capture latency as performance data.

### 3. Preserve raw output and build a bounded summary

```bash
MEMGRAPH=$(jq -er \
  'select(.status == "captured") | .memgraph | select(type == "string" and length > 0)' \
  /tmp/myapp-memory/run-01/capture.json)
test -s "$MEMGRAPH"
python3 scripts/summarize_memgraph.py \
  "$MEMGRAPH" \
  --artifact-dir /tmp/myapp-memory/run-01/analysis-raw \
  --app-image 'MyApp|MyFeatureKit' \
  --trace-limit 3 --group-by-type --pretty \
  > /tmp/myapp-memory/run-01/analysis.json
```

Read the exact graph path from the preserved capture report; do not guess a
timestamped filename. The helper creates a dedicated raw-artifact directory,
refuses to reuse it, runs `leaks --list`, and parses only a conservative subset
of its text. `--app-image` marks candidate rows; it does not prove ownership.
`--trace-limit` runs bounded
`leaks --traceTree=<address>` queries. Add `--reference-tree` when aggregate
root paths are more useful than individual leaked addresses. With
`--group-by-type`, that reference-tree query is grouped in the same invocation.
Exit statuses 0 and 1 from `leaks` remain analyzable; a primary status above 1
fails the summary, while optional-query failures are preserved and warned as
unusable without discarding a valid primary summary.

Apple does not publish these text formats as stable machine schemas. Treat
parse warnings as a reason to inspect the raw artifacts, not to loosen the
parser until it emits a desired answer.

### 4. Find the first actionable app-owned edge

Start with an app-owned leaked type or allocation stack. Inspect:

- the leak's object graph and Malloc Stack Logging backtrace, when present;
- a bounded `--traceTree=<address>` for objects that reference one address;
- `--groupByType` to compress repeated types and reveal a retained payload;
- `--referenceTree` for a top-down view when the responsible address is unclear;
- source code for the first strong edge controlled by the app.

An unreachable self-cycle may have no live root in `traceTree`. Use the grouped
leak graph plus source verification or reduce the behavior to an isolated
reproduction. Never invent a root path that the graph does not contain.

### 5. Investigate growth when `leaks` is empty

Use matching baseline and post-flow graphs, locate the growing region, compare
object types, then trace a suspicious address back to an app-owned edge. The
evidence goal is persistent reachable growth across the same lifetime—not a
lower RSS value or a single large snapshot. Load
[reachable-growth.md](references/reachable-growth.md) only for this empty-leak
branch; it contains the ordered `vmmap`, `heap`, `leaks`, and `malloc_history`
queries and their logging-dependent alternatives.

### 6. Fix and verify the same lifetime

Prefer the narrowest ownership correction: break the unintended strong edge,
cancel work that owns the object, remove an observer, bound/evict a cache, or
release a large buffer after its last use. Use `weak` when the reference may
legitimately become `nil`; use `unowned` only with a proven lifetime guarantee.

Repeat the identical flow. A fix is supported when the same app-owned type/path
disappears or the pre/post growth attributable to it is removed across repeated
runs. Lower RSS, a smaller graph file, or a lower aggregate leak count alone is
not proof.

## Ownership Decisions

| Evidence | Next action |
|---|---|
| App type in a root cycle | Inspect both strong edges and allocation stack. |
| No root for a leaked address | Inspect grouped cycle evidence and isolate the flow. |
| Live root retains dismissed feature state | Follow the path to the first app-owned edge. |
| Zero leaks but repeated malloc growth | Diff baseline/post heap objects. |
| Framework object dominates | Find the app-created owner, input, or call frequency. |
| Growth stabilizes at a documented bound | Test eviction/pressure behavior before changing it. |

## Common Mistakes

- Declaring the app leak-free because `leaks` returned zero once.
- Selecting the first PID or Simulator from an ambiguous list.
- Enabling Malloc Stack Logging in only one side of a comparison.
- Treating a parser's best-effort type column as an API guarantee.
- Pasting enormous reference trees into a report without finding an app edge.
- Fixing every closure with `[weak self]` without reasoning about lifetime.
- Claiming success from graph size, RSS, or total-count changes without proving the target lifetime and ownership path.

## Review Checklist

- [ ] The object and expected release boundary are explicit.
- [ ] Baseline and post-flow graphs use the same build, runtime target, data
      state, deterministic flow, cleanup wait, repetitions, and Malloc Stack
      Logging setting.
- [ ] Simulator, bundle identifier, process label, and PID are unambiguous.
- [ ] Original graph and raw command outputs are preserved.
- [ ] Current installed-tool help confirms version-sensitive command shapes.
- [ ] Leak, reachable growth, expected cache, and fragmentation are separated.
- [ ] The finding names an app-owned type/allocation and credible path.
- [ ] Missing type metadata or conservative-scanner limits are disclosed.
- [ ] The fix changes one ownership/lifetime cause.
- [ ] Verification repeats the same flow and evidence query.

## References

- [Reachable growth when `leaks` is empty](references/reachable-growth.md) —
  matched-graph comparison and address-to-owner workflow
- [Gathering information about memory use](https://sosumi.ai/documentation/xcode/gathering-information-about-memory-use)
- [Detect and diagnose memory issues — WWDC21](https://sosumi.ai/videos/play/wwdc2021/10180)
- [Analyze heap memory — WWDC24](https://sosumi.ai/videos/play/wwdc2024/10173)
