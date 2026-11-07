# Swift 6 Concurrency

## The Problem
Swift 6 strict concurrency requires proper actor isolation. `XCTestCase` methods are not main-actor-isolated by default, causing errors when accessing `@MainActor` objects.

**Error you'll see:**
```
Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
```

## Solution 1: Mark Test Class with @MainActor (Recommended)
```swift
@MainActor
final class MyUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testSomething() {
        // All code runs on main actor
    }
}
```

## Solution 2: Async setUp/tearDown with MainActor.run
```swift
final class MyUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            app = XCUIApplication()
            app.launch()
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            app = nil
        }
        try await super.tearDown()
    }
}
```

## Solution 3: Mark Properties as nonisolated
For properties that don't need main actor:
```swift
@MainActor
final class MyUITests: XCTestCase {
    nonisolated var testUserID: String {
        ProcessInfo.processInfo.environment["TEST_USER_ID"] ?? "default"
    }
}
```

## Async Test Methods
```swift
@MainActor
func testAsyncOperation() async throws {
    app.buttons["Start"].tap()

    // Await async operation
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertTrue(app.staticTexts["Complete"].exists)
}
```
