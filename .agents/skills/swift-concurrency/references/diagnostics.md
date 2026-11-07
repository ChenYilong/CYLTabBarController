# Concurrency Diagnostics

Common Swift concurrency compiler warnings and errors with their fixes.

## Diagnostic → Fix Reference

| Diagnostic | Cause | Fix |
| --- | --- | --- |
| `Sending 'x' risks causing data races` | Passing a non-Sendable value across isolation boundaries | Make the type `Sendable`, use `sending` parameter, or restructure to avoid the crossing |
| `Capture of 'x' with non-sendable type in a @Sendable closure` | Closure captures non-Sendable value | Make type Sendable, copy the value, or use an actor |
| `Non-sendable type 'X' returned by implicitly asynchronous call` | Returning non-Sendable from cross-isolation call | Make return type Sendable or keep work on same isolation |
| `Main actor-isolated property 'x' can not be mutated from a nonisolated context` | Accessing @MainActor state from non-main context | Add `@MainActor` to caller, use `await MainActor.run { }`, or restructure |
| `Call to main actor-isolated function in a synchronous nonisolated context` | Calling @MainActor function without await | Add `await`, annotate caller `@MainActor`, or use `.task { }` in SwiftUI |
| `Actor-isolated property 'x' can not be referenced from a nonisolated context` | Accessing actor state without await | Add `await` or move code into the actor |
| `Type 'X' does not conform to protocol 'Sendable'` | Stored properties aren't all Sendable | Prefer an immutable value type or immutable snapshot; otherwise use actor isolation or synchronization. Use `@unchecked Sendable` only with documented internal locking |
| `Passing closure as a 'sending' parameter risks causing data races` | Closure captures values that could race | Ensure captures are Sendable or don't escape the isolation domain |
| `Task-isolated value of type 'X' passed as a strongly transferred parameter` | Moving a value out of a task unsafely | Copy the value or use `sending` return |
| `Global variable 'x' is not concurrency-safe` | Mutable global without isolation | Add `@MainActor`, make it `nonisolated(unsafe)` (with justification), or use actor |

## Swift 6.2 Approachable Concurrency Changes

With `UpcomingFeature.InferSendableFromCaptures` (Swift 6.2):
- Closures infer Sendable from their captures (fewer explicit annotations needed)
- `nonisolated(nonsending)` is the new default for async functions (SE-0461)
- `@concurrent` marks functions that intentionally run off-actor

### Xcode 26.5 Explicit-Capture Closure Issue

Xcode 26.5 release notes document a Swift 6.3.2 issue under
`NonisolatedNonsendingByDefault` / Approachable Concurrency: a closure with an
explicit capture list passed to a `nonisolated(nonsending)` parameter, or
converted to that function type, can infer isolation from the parent context
instead of the closure type.

Use only the documented workarounds:
- Remove explicit captures when implicit capture is safe and equivalent.
- Convert the closure into a local `@Sendable nonisolated(nonsending)` async
  function.

## Strict Concurrency Adoption Strategy

1. **Know the language mode.** In Swift 6 / 6.3 language mode, strict
   concurrency checking is complete and data-race diagnostics are errors.
2. **Use migration levels only before Swift 6.** In Swift 5 language mode,
   `Targeted` or `Minimal` can stage adoption before moving to `Complete`.
3. **Fix diagnostics bottom-up.** Start with leaf types (models, DTOs), then
   services, then UI.
4. **Use `@preconcurrency import`** temporarily for third-party modules that
   haven't adopted Sendable — document removal plan.

For Sendable diagnostics, check this order before adding annotations:
immutable `struct` / `enum`, immutable `let` properties on a `final` class,
actor or global-actor isolation, a small synchronized wrapper, then
`@unchecked Sendable` only when the compiler cannot see a proven lock invariant.

## Runtime Diagnostics

Enable the Thread Sanitizer (`-sanitize=thread`) to catch data races at runtime that the compiler can't statically prove.

Xcode: Edit Scheme → Run → Diagnostics → Thread Sanitizer.

Common TSan findings in concurrent code:
- Simultaneous reads and writes to `Dictionary` or `Array` without actor protection
- Delegate callbacks arriving on unexpected queues
- Completion handlers racing with synchronous property access
