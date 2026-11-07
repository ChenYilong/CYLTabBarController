# Reachable Growth When `leaks` Is Empty

Load this workflow only after a matched lifetime produces no unreachable leak
but baseline and post-flow graphs show persistent growth.

## Contents

- [Match the Captures](#match-the-captures)
- [Locate the Growing Region](#locate-the-growing-region)
- [Find a Suspicious Address](#find-a-suspicious-address)
- [Trace Ownership](#trace-ownership)
- [Preserve Evidence](#preserve-evidence)

## Match the Captures

Capture baseline and post-flow graphs from the same app build, process, device
or Simulator, launch state, and user flow. Repeated post-flow growth is stronger
evidence than a single large snapshot.

## Locate the Growing Region

Run `vmmap -summary` on both graphs. If growth is in malloc regions, compare the
graphs with the installed `heap` tool's current syntax:

```bash
heap --diffFrom=baseline.memgraph post.memgraph
```

Treat the result as a type/size lead, not as proof of ownership.

## Find a Suspicious Address

Obtain an address for a growing app-owned type or size:

```bash
heap --addresses='<class-or-size-pattern>' post.memgraph
```

Record the query and selected address so the next step is reproducible.

## Trace Ownership

- Without Malloc Stack Logging, use `leaks --traceTree=<address>` to find the
  live ownership path.
- With Malloc Stack Logging, use
  `malloc_history post.memgraph -fullStacks <address>` for allocation evidence.
- Use `leaks --referenceTree --groupByType` when aggregate ownership clues are
  more useful than a single path.

Stop at the first strong app-owned edge. A framework node, allocation stack, or
type-count delta alone does not identify the lifetime bug.

## Preserve Evidence

Check each installed tool's `--help` because Xcode/macOS output and flags can
evolve. Preserve raw command output beside both graphs, then repeat the same
queries after the ownership fix.
