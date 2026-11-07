---
name: swift-testing
description: "Writes and migrates Swift Testing framework tests with @Test, @Suite, #expect, #require, confirmation, traits, withKnownIssue, Attachment.record, processExitsWith exit tests and capture lists, Test.cancel, Issue.record warnings/manual failures, XCTest-to-Swift Testing migration, Xcode 27 interoperability modes, XCUITest UI-test boundaries, performance/snapshot boundaries, mocking, async patterns, and test organization. Use when writing tests, converting XCTest assertions such as XCTUnwrap or XCTFail, reviewing advanced Swift Testing API availability, or deciding when to keep XCTest/XCUITest."
---

# Swift Testing

Swift Testing is the modern testing framework for Swift (Xcode 16+, Swift 6+). Prefer it for new unit tests. Keep XCTest where migration is still in progress, and use XCTest for UI automation, performance APIs, Objective-C exception tests, and common snapshot-test tooling.

## Contents

- [Basic Tests](#basic-tests)
- [`@Test Traits`](#test-traits)
- [#expect and #require](#expect-and-require)
- [`@Suite and Test Organization`](#suite-and-test-organization)
- [Execution Model](#execution-model)
- [XCTest Migration Boundaries](#xctest-migration-boundaries)
- [Known Issues](#known-issues)
- [Additional Patterns](#additional-patterns)
- [Common Mistakes](#common-mistakes)
- [Test Attachments](#test-attachments)
- [Exit Testing](#exit-testing)
- [Version-Gated APIs](#version-gated-apis)
- [Review Checklist](#review-checklist)
- [References](#references)

---

## Basic Tests

```swift
import Testing

@Test("User can update their display name")
func updateDisplayName() {
    var user = User(name: "Alice")
    user.name = "Bob"
    #expect(user.name == "Bob")
}
```

## `@Test` Traits

```swift
@Test("Validates email format")                                    // display name
@Test(.tags(.validation, .email))                                  // tags
@Test(.disabled("Server migration in progress"))                   // disabled
@Test(.enabled(if: ProcessInfo.processInfo.environment["CI"] != nil)) // conditional
@Test(.bug("https://github.com/org/repo/issues/42"))               // bug reference
@Test(.timeLimit(.minutes(1)))                                     // time limit
@Test("Timeout handling", .tags(.networking), .timeLimit(.seconds(30))) // combined
```

## #expect and #require

```swift
// #expect records failure but continues execution
#expect(result == 42)
#expect(name.isEmpty == false)
#expect(items.count > 0, "Items should not be empty")

// #expect with error type checking
#expect(throws: ValidationError.self) {
    try validate(email: "not-an-email")
}

// #expect with specific error value
#expect {
    try validate(email: "")
} throws: { error in
    guard let err = error as? ValidationError else { return false }
    return err == .empty
}

// #require records failure AND stops test (like XCTUnwrap)
let user = try #require(await fetchUser(id: 1))
#expect(user.name == "Alice")

// #require for optionals -- unwraps or fails
let first = try #require(items.first)
#expect(first.isValid)
```

**Rule: Use `#require` when subsequent assertions depend on the value. Use `#expect` for independent checks.**

## `@Suite` and Test Organization

See [references/testing-patterns.md](references/testing-patterns.md) for suite organization, confirmation patterns, known-issue handling, and execution-model details.

## Execution Model

Swift Testing runs tests in parallel by default. Do not assume test order, shared suite instances, or exclusive access to mutable state unless you explicitly design for it.

```swift
@Suite(.serialized)
struct KeychainTests {
    @Test func storesToken() throws { /* ... */ }
    @Test func deletesToken() throws { /* ... */ }
}
```

Use `.serialized` when a test or suite must run one-at-a-time because it touches shared external state. It does not make unrelated tests outside that scope run serially.

**Rules:**
- Each test must set up its own state.
- Shared mutable globals are a bug unless protected or intentionally serialized.
- `@Suite(.serialized)` is for exclusive execution, not for expressing logical ordering between tests.
- If tests depend on sequence, combine them into one test or move the sequence into shared helper code.

## XCTest Migration Boundaries

Swift Testing unit tests do not inherit from `XCTestCase`. Declare `@Test` on
free functions or methods on suite types such as `struct`, `class`, or `actor`;
use `static` or `class` methods when instance fixtures are unnecessary.

XCTest and Swift Testing can coexist during migration. Migrate one file or
suite at a time, compare discovery/pass/fail/skip counts, and keep UI automation,
performance benchmarks, and common snapshot flows on XCTest/XCUITest or snapshot
tooling. Separate files or targets when that makes runner expectations clearer.

For Xcode 27-era mixed helpers, check the configured interoperability mode rather than claiming cross-framework APIs are forbidden. Older test plans inherit `limited`; new projects use `complete`; `strict` and `none` are also available. Prefer `complete` or `strict` during migration and use `SWIFT_TESTING_XCTEST_INTEROP_MODE` for SwiftPM when needed. See [references/testing-advanced.md](references/testing-advanced.md) for the mode matrix and toolchain gates.

Do not mechanically replace every XCTest assertion with `#expect`; preserve
required unwraps and unconditional failures with these migration defaults:
- `XCTAssert*` -> `#expect(...)`
- `XCTUnwrap` or any value required by later checks -> `try #require(...)`
- `XCTFail("...")` or manual unconditional issues -> `Issue.record("...")`
- UI tests, performance benchmarks, and common snapshot-test flows stay on XCTest/XCUITest or snapshot tooling.
- Put `@available` on individual `@Test` functions, not on suite types or their containing types.

See [references/testing-patterns.md](references/testing-patterns.md) for migration examples and [references/testing-advanced.md](references/testing-advanced.md) for Swift/Xcode version gates.

## Known Issues

Mark expected failures so they do not cause test failure:

```swift
withKnownIssue("Propane tank is empty") {
    #expect(truck.grill.isHeating)
}

// Intermittent / flaky failures
withKnownIssue(isIntermittent: true) {
    #expect(service.isReachable)
}

// Conditional known issue
withKnownIssue {
    #expect(foodTruck.grill.isHeating)
} when: {
    !hasPropane
}
```

If no known issues are recorded, Swift Testing records a distinct issue notifying you the problem may be resolved.

## Additional Patterns

See [references/testing-patterns.md](references/testing-patterns.md) for parameterized tests, tags and suites, async testing, traits, and execution-model details.

## Test Attachments

Attach diagnostic data to test results for debugging failures. See [references/testing-patterns.md](references/testing-patterns.md) for full examples.

```swift
@Test func generateReport() async throws {
    let report = try generateReport()
    Attachment.record(report.data, named: "report.json")
    #expect(report.isValid)
}
```

For image attachments and their toolchain gate, use the canonical table in
[Version-Gated APIs](#version-gated-apis).

## Exit Testing

Test code that calls `exit()`, `fatalError()`, or `preconditionFailure()` on a
supported runtime. State the exact gate from [Version-Gated APIs](#version-gated-apis)
when correcting exit-test code.

```swift
@Test func invalidInputCausesExit() async {
    await #expect(processExitsWith: .failure) {
        processInvalidInput()  // calls fatalError()
    }
}
```

## Version-Gated APIs

For advanced APIs, state the exact toolchain and runtime gate beside the
correction. This is the canonical summary; [references/testing-advanced.md](references/testing-advanced.md)
contains the detailed matrix and examples.

```swift
@Test func exitsWithCapturedCode() async {
    let expectedCode: Int32 = 42
    await #expect(processExitsWith: .failure) { [expectedCode] in
        exit(expectedCode)
    }
}
```

| User code to correct | Current guidance |
|---|---|
| `#expect(exitsWith:)` | Use `await #expect(processExitsWith: .failure) { ... }`. Exit testing requires Swift 6.2 / Xcode 26.0 or newer and is supported on macOS, Linux, FreeBSD, OpenBSD, and Windows runtime targets, not iOS, tvOS, or watchOS. For an iOS app target, test fatal-path logic through a smaller non-exiting API or a supported host/tool target. |
| Exit-test closure reads outer values | Add an explicit capture list, for example `{ [expectedCode] in ... }`. Exit-test capture lists require the Swift 6.3 compiler; captured values must be `Sendable` and `Codable`. |
| `Test.cancel()` in a test that awaits work | Make the test `async throws` and call `try Test.cancel("reason")`. `Test.cancel(_:)` requires Swift 6.3 / Xcode 26.4-era support. |
| `Issue.record(..., severity: .warning)` | Use `Issue.record("message", severity: .warning)`. Warning severity is reported but does not fail the test, and requires Swift 6.3 / Xcode 26.4-era support. |
| `Attachment(image, named:).record()` | Use `Attachment.record(image, named: "name", as: .png)`. Import `Testing` plus the relevant image framework; Apple-platform image values include `UIImage`, `CGImage`, `CIImage`, and `NSImage`. Image attachment recording requires Swift 6.3 / Xcode 26.4-era support. |

## Common Mistakes

1. **Testing implementation, not behavior.** Test what the code does, not how.
2. **No error path tests.** If a function can throw, test the throw path.
3. **Flaky async tests or sleeps.** Use `confirmation`, clock injection, or concurrency primitives instead of sleeping.
4. **Shared mutable state between tests.** Each test sets up its own state via `init()` in `@Suite`.
5. **Missing accessibility identifiers in UI tests.** XCUITest queries rely on them.
6. **Not testing cancellation.** If code supports `Task` cancellation, verify it cancels cleanly.
7. **Unclear migration boundaries.** Follow XCTest Migration Boundaries instead of treating either framework as an all-or-nothing choice.
8. **Non-Sendable helpers shared across tests.** Make shared helpers `Sendable`; annotate MainActor-dependent test code with `@MainActor`.
9. **Treating serialization as ordering.** Tests run in parallel by default; `.serialized` protects exclusive state but does not make one test feed another.

## Review Checklist

- [ ] All new tests use Swift Testing (`@Test`, `#expect`), not XCTest assertions
- [ ] Test names describe behavior (`fetchUserReturnsNilOnNetworkError` not `testFetchUser`)
- [ ] Error paths have dedicated tests
- [ ] Async tests use `confirmation()`, not `Task.sleep`
- [ ] Parameterized tests used for repetitive variations
- [ ] Tags applied for filtering (`.critical`, `.slow`)
- [ ] Mocks conform to protocols, not subclass concrete types
- [ ] No shared mutable state between tests
- [ ] Tests do not rely on declaration order or shared suite instances
- [ ] `.serialized` used only for truly exclusive state, not to model workflow sequencing
- [ ] Cancellation tested for cancellable async operations

## References

- Testing patterns: [references/testing-patterns.md](references/testing-patterns.md)
- Advanced testing (warnings, cancellation, image attachments): [references/testing-advanced.md](references/testing-advanced.md)
