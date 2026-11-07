# Approachable Concurrency Quick Reference

Use this reference when the project has opted into the Swift 6.2 approachable
concurrency settings and, when appropriate, default MainActor isolation.

## Detecting the Mode

**Xcode 26:** Check build settings under Swift Compiler > Concurrency:
- Swift language version: 6.2+
- Approachable Concurrency: enabled when using the bundled upcoming-feature flags
  (`NonisolatedNonsendingByDefault`, isolated-conformance inference, inferred
  Sendable captures, and related usability flags).
- Default Actor Isolation: `MainActor` when unannotated code should infer
  `@MainActor` isolation.
- Strict Concurrency Checking: Swift 6 language mode is complete and emits
  errors; Complete / Targeted / Minimal are migration settings for earlier
  language modes.

**SwiftPM:** Inspect `Package.swift` `swiftSettings` for the corresponding flags.

## Behavior Changes

### Async functions stay on the caller's actor

In Swift 6.2, nonisolated async functions no longer hop to the global
concurrent executor. They stay on whichever actor called them. This eliminates
many "sending X risks causing data races" errors.

### Default MainActor isolation

With Default Actor Isolation set to `MainActor`, unannotated declarations in the
module are inferred as `@MainActor`.
This means:
- Global and static variables are protected by default.
- Protocol conformances are implicitly isolated.
- Mutable state is safe without explicit annotation.

### Isolated conformances

Protocol conformances can be explicitly isolated:
`extension Foo: @MainActor SomeProtocol`. The compiler prevents using the
conformance outside the matching isolation context.

## Applying Fixes in This Mode

- **Prefer minimal annotations.** Let default MainActor isolation do the work
  for UI-bound code.
- **Use isolated conformances** instead of `nonisolated` workarounds for
  protocol conformances.
- **Keep global/shared mutable state on MainActor** unless there is a clear
  performance need to offload.
- **Remove redundant `@MainActor` annotations** that are now implied by the
  default isolation mode.

## Offloading Work

- Use `@concurrent` on async functions that must run on the concurrent pool.
- Do not present `nonisolated` alone as a CPU-offloading mechanism; it opts out
  of actor isolation, while `@concurrent` requests the concurrent pool.
- Make types or members `nonisolated` only when they are truly thread-safe and
  used off the main actor.
- Continue to respect `Sendable` boundaries when values cross actors or tasks.

## Common Pitfalls

| Pitfall | Why it happens | Fix |
|---|---|---|
| CPU-heavy work on MainActor | Default isolation hides the problem | Move to `@concurrent` async function |
| `Task.detached` breaking isolation | Ignores inherited actor context | Use `Task { }` unless you truly need detachment |
| Redundant `@MainActor` everywhere | Default isolation already provides it | Remove explicit annotations |
| `nonisolated` on mutable state | Breaks the safety guarantee | Keep mutable state isolated |
| Explicit-capture closure issue in Xcode 26.5 | Swift 6.3.2 release-note bug with `nonisolated(nonsending)` closure parameters | See [diagnostics.md](diagnostics.md) for the documented workarounds |

## Concurrency Keywords

| Keyword | What it does |
|---|---|
| `async` | Function can suspend |
| `await` | Suspend here until done |
| `Task { }` | Start async work, inherits context |
| `Task.detached { }` | Start async work, no inherited context |
| `Task.immediate { }` | Start immediately on current actor |
| `@MainActor` | Runs on main thread |
| `actor` | Type with isolated mutable state |
| `nonisolated` | Opts out of actor isolation |
| `Sendable` | Safe to pass between isolation domains |
| `@concurrent` | Always run on background thread pool (Swift 6.2+) |
| `async let` | Start parallel work (fixed count) |
| `TaskGroup` | Dynamic parallel work |
| `sending` | Parameter-level isolation transfer (SE-0430) |
