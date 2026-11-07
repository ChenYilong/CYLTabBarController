# Advanced Testing Patterns

Warning-severity issues, programmatic test cancellation, and image attachments for Swift Testing.

## Contents

- [Warning-Severity Issues](#warning-severity-issues)
- [Programmatic Test Cancellation](#programmatic-test-cancellation)
- [Exit Test Value Capturing](#exit-test-value-capturing)
- [Image Attachments](#image-attachments)
- [Version Gates](#version-gates)
- [Proposal Reference](#proposal-reference)

## Warning-Severity Issues

ST-0013 adds a `severity` parameter to `Issue.record()` in Swift 6.3 / Xcode 26.4 and newer. Warnings are surfaced in test output but do not cause the test to fail.

```swift
@Test func dataIntegrity() {
    let result = loadData()

    // Hard failure — test fails
    #expect(result.isValid)

    // Warning — logged but test still passes
    if result.processingTime > 2.0 {
        Issue.record(
            "Processing took \(result.processingTime)s — exceeds 2s target",
            severity: .warning
        )
    }
}
```

Use warnings for:
- Performance regressions that aren't blocking
- Deprecated code paths that still work
- Non-critical data quality checks
- Flaky conditions you want to track without failing CI

## Programmatic Test Cancellation

ST-0016 adds `try Test.cancel()` in Swift 6.3 / Xcode 26.4 and newer to stop a test from within without marking it as passed or failed. The test is recorded as "cancelled."

```swift
@Test func requiresNetwork() async throws {
    guard NetworkMonitor.shared.isConnected else {
        try Test.cancel("No network — skipping integration test")
    }

    let response = try await APIClient.shared.healthCheck()
    #expect(response.status == .ok)
}
```

Key differences from other mechanisms:
- Throwing an error — marks the test as failed
- `withKnownIssue` — marks a failure as expected (test still runs)
- `try Test.cancel()` — marks the test as cancelled (neutral outcome, test stops)

## Exit Test Value Capturing

ST-0012 allows exit tests to capture values from the enclosing scope when using the Swift 6.3 compiler. Exit testing itself requires Swift 6.2 / Xcode 26.0 or newer and uses the `processExitsWith:` macros.

When an exit-test body reads values from the parent process, correct the sample to use an explicit capture list and mention the Swift 6.3 compiler requirement. Captured values must conform to `Sendable` and `Codable`.

```swift
@Test func exitCodeValidation() async {
    let expectedCode: Int32 = 42
    await #expect(processExitsWith: .failure) { [expectedCode] in
        exit(expectedCode)  // Can now capture `expectedCode`
    }
}
```

## Image Attachments

ST-0014 adds image attachments in Swift 6.3 / Xcode 26.4 and newer. Import both `Testing` and the relevant UI framework, then record platform image values directly and specify `as:` when you need an explicit format.

```swift
import Testing
import UIKit

@Test func renderedOutput() async throws {
    let view = ChartView(data: sampleData)
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
    let image = renderer.image { ctx in
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }

    // Attach UIImage directly
    Attachment.record(image, named: "chart-output", as: .png)
}
```

Supported Apple-platform image types include:
- `UIImage` on iOS, tvOS, visionOS, and watchOS when importing UIKit
- `CGImage` when importing CoreGraphics
- `CIImage` when importing CoreImage
- `NSImage` on macOS when importing AppKit

## Version Gates

| Feature | Minimum toolchain / platform |
|---|---|
| Attachments API for standard attachable values | Swift 6.2 / Xcode 26.0 |
| Exit testing with `processExitsWith:` | Swift 6.2 / Xcode 26.0; supported on macOS, Linux, FreeBSD, OpenBSD, and Windows runtime targets |
| Exit-test capture lists | Swift 6.3 compiler |
| `Issue.record(_:severity:)` warnings | Swift 6.3 / Xcode 26.4 |
| `Test.cancel(_:)` | Swift 6.3 / Xcode 26.4 |
| Image attachment recording | Swift 6.3 / Xcode 26.4 |

Do not use exit tests for iOS, tvOS, or watchOS runtime targets. For iOS app code that needs fatal-path coverage, move the exit behavior behind a smaller pure Swift API, test the non-exiting branches directly, and reserve exit tests for a supported host/tool target.

## Proposal Reference

| Proposal | Feature |
|---|---|
| ST-0009 | Attachments API (`Attachment` type, `.record()`) |
| ST-0012 | Exit test value capturing |
| ST-0013 | Warning-severity issues (`Issue.record` with `severity:`) |
| ST-0014 | Image attachments on Apple platforms (cross-import overlays) |
| ST-0016 | Programmatic test cancellation (`try Test.cancel()`) |
