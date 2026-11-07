# Troubleshooting

## Element Not Found
1. Check accessibility identifier is set in code
2. Use Accessibility Inspector (Xcode > Open Developer Tool)
3. Print element hierarchy: `print(app.debugDescription)`
4. Check element is in view (may need scrolling)
5. Ensure element is enabled for accessibility

## Flaky Tests
1. Use `waitForExistence` instead of `sleep`
2. Add `continueAfterFailure = false`
3. Disable animations in test setup
4. Reset simulator state between tests
5. Use unique test data

## Swift 6 Concurrency Errors
1. Mark test class with `@MainActor`
2. Use `nonisolated` for properties that don't need main actor
3. Use async setUp/tearDown if needed
4. Check for Sendable conformance issues

## Screenshots Not Saved
1. Set `attachment.lifetime = .keepAlways`
2. Check DerivedData location for `.xcresult`
3. Use `xcparse` to extract from result bundle

## Permission Dialog Issues
1. Use `resetAuthorizationStatus(for:)` before `app.launch()`
2. HealthKit uses a scrollable sheet on iOS 26 - must scroll to reveal buttons
3. `addUIInterruptionMonitor` requires an app interaction to trigger
4. For system-level alerts, use springboard bundle identifier approach

# What's New in Xcode 26 / iOS 26

## New APIs
- **`wait(for:toEqual:timeout:)`** - KeyPath-based waiting for any property value
- **`waitForNonExistence(withTimeout:)`** - Native API to wait for element removal (Xcode 16+)
- **XCTHitchMetric** - Measure UI responsiveness and frame drops

## Enhanced Recording
- Cleaner, more maintainable generated test code
- Multiple identifier options for element selection
- Integration with Test Report's Automation Explorer

## Cross-Platform Testing
- Run automation tests across iPhone, iPad, Mac, Apple TV, Apple Watch
- Test plan configurations for multiple locales, device types, system conditions
- Video recordings and screenshots of test runs in results

## Swift Concurrency Debugging
- Seamless stepping across threads in async tests
- Task ID visibility in debugger
- Thread Performance Checker integration
