---
source: project
description: Project-specific XCUITest patterns and helpers
---

# XCUITest Advanced Patterns

## Base Test Class Pattern

A reusable base class that handles common setup, teardown, and helpers:

```swift
import XCTest

@MainActor
class BaseUITest: XCTestCase {
    var app: XCUIApplication!

    // Configuration from environment
    nonisolated var apiURL: String {
        ProcessInfo.processInfo.environment["API_URL"] ?? "https://api.example.com"
    }

    nonisolated var testUserID: String {
        ProcessInfo.processInfo.environment["TEST_USER_ID"] ?? "default-user"
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.terminate() // Ensure fresh state

        // Pass configuration
        app.launchArguments += ["-UITest"]
        app.launchArguments += ["-API_URL", apiURL]
        app.launchArguments += ["-TEST_USER_ID", testUserID]

        app.launch()
    }

    override func tearDown() {
        captureScreenshotOnFailure()
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func captureScreenshotOnFailure() {
        guard let failureCount = testRun?.failureCount, failureCount > 0 else { return }
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Failure-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func waitForElement(_ identifier: String, timeout: TimeInterval = 10) -> XCUIElement {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      "Element '\(identifier)' did not appear within \(timeout)s")
        return element
    }

    func takeScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func tapTab(_ identifier: String) {
        let tab = app.buttons[identifier]
        if tab.waitForExistence(timeout: 2) {
            tab.tap()
            Thread.sleep(forTimeInterval: 0.3) // Animation
            return
        }
        // Fallback to any element type
        let anyTab = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(anyTab.waitForExistence(timeout: 5), "Tab '\(identifier)' not found")
        anyTab.tap()
        Thread.sleep(forTimeInterval: 0.3)
    }

    func swipeDown() {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        from.press(forDuration: 0.1, thenDragTo: to)
    }

    func swipeUp() {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        from.press(forDuration: 0.1, thenDragTo: to)
    }
}
```

## Handling iOS System Dialogs

### HealthKit Authorization (iOS 26+)
HealthKit dialog is a scrollable sheet with buttons below the fold:

```swift
func handleHealthKitDialog() {
    let healthAccessText = app.staticTexts["Health Access"]

    if healthAccessText.waitForExistence(timeout: 5) {
        // Scroll down to reveal buttons
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        from.press(forDuration: 0.1, thenDragTo: to)

        // Tap "Don't Allow"
        let dontAllowButton = app.buttons["Don't Allow"]
        if dontAllowButton.waitForExistence(timeout: 5) {
            dontAllowButton.tap()
        } else {
            // Fallback with predicate
            let button = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Don\\'t Allow'")
            ).firstMatch
            if button.exists { button.tap() }
        }
    }
}
```

### Location Permission
```swift
func handleLocationPermission(allow: Bool) {
    addUIInterruptionMonitor(withDescription: "Location") { alert -> Bool in
        if allow {
            if alert.buttons["Allow While Using App"].exists {
                alert.buttons["Allow While Using App"].tap()
                return true
            }
        } else {
            if alert.buttons["Don't Allow"].exists {
                alert.buttons["Don't Allow"].tap()
                return true
            }
        }
        return false
    }
}
```

### Notification Permission
```swift
func handleNotificationPermission(allow: Bool) {
    addUIInterruptionMonitor(withDescription: "Notification") { alert -> Bool in
        let button = allow ? "Allow" : "Don't Allow"
        if alert.buttons[button].exists {
            alert.buttons[button].tap()
            return true
        }
        return false
    }
}
```

## Waiting Patterns

### Wait for Network Data to Load
```swift
func waitForDataToLoad(timeout: TimeInterval = 30) {
    // Wait for loading indicator to disappear
    let loadingIndicator = app.activityIndicators.firstMatch
    if loadingIndicator.exists {
        let gone = waitForNonExistence(loadingIndicator, timeout: timeout)
        XCTAssertTrue(gone, "Loading indicator did not disappear")
    }

    // Wait for content to appear
    let content = app.scrollViews["main-content"].firstMatch
    XCTAssertTrue(content.waitForExistence(timeout: timeout), "Content did not load")
}

func waitForNonExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    return result == .completed
}
```

### Wait for Animation to Complete
```swift
func waitForAnimation() {
    // Simple delay (last resort)
    Thread.sleep(forTimeInterval: 0.5)
}

func waitForElementToSettle(_ element: XCUIElement, timeout: TimeInterval = 3) {
    var previousFrame = CGRect.zero
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        guard element.exists else {
            Thread.sleep(forTimeInterval: 0.1)
            continue
        }
        let currentFrame = element.frame
        if currentFrame == previousFrame && !currentFrame.isEmpty {
            return // Frame stable
        }
        previousFrame = currentFrame
        Thread.sleep(forTimeInterval: 0.1)
    }
}
```

### Wait with Retry
```swift
func waitAndRetry<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 1,
    action: () throws -> T
) rethrows -> T {
    var lastError: Error?
    for attempt in 1...maxAttempts {
        do {
            return try action()
        } catch {
            lastError = error
            if attempt < maxAttempts {
                Thread.sleep(forTimeInterval: delay)
            }
        }
    }
    throw lastError!
}
```

## Element Query Patterns

### Find by Partial Text
```swift
// Contains text (case insensitive)
let errorText = app.staticTexts.matching(
    NSPredicate(format: "label CONTAINS[c] 'error'")
).firstMatch

// Starts with
let titleText = app.staticTexts.matching(
    NSPredicate(format: "label BEGINSWITH 'Welcome'")
).firstMatch

// Ends with
let buttonText = app.buttons.matching(
    NSPredicate(format: "label ENDSWITH 'More'")
).firstMatch

// Regex (use MATCHES)
let versionText = app.staticTexts.matching(
    NSPredicate(format: "label MATCHES 'v[0-9]+\\.[0-9]+'")
).firstMatch
```

### Find Element in Hierarchy
```swift
// Element inside a specific cell
let cell = app.cells["user-cell-0"]
let deleteButton = cell.buttons["Delete"]

// Element inside scroll view
let scrollView = app.scrollViews["main-scroll"]
let card = scrollView.descendants(matching: .any).matching(identifier: "card-1").firstMatch

// Element with parent matching criteria
let submitButton = app.descendants(matching: .button)
    .containing(NSPredicate(format: "identifier == 'submit'"))
    .firstMatch
```

### Check if Table/List is Empty
```swift
func isTableEmpty(_ tableIdentifier: String) -> Bool {
    let table = app.tables[tableIdentifier]
    return table.cells.count == 0
}

func waitForTableToPopulate(_ tableIdentifier: String, timeout: TimeInterval = 10) {
    let predicate = NSPredicate(format: "count > 0")
    let cells = app.tables[tableIdentifier].cells
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: cells)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    XCTAssertEqual(result, .completed, "Table did not populate")
}
```

## Scroll Patterns

### Scroll Until Element Visible
```swift
func scrollUntilVisible(_ element: XCUIElement, in scrollView: XCUIElement, maxScrolls: Int = 10) {
    var scrollCount = 0
    while !element.isHittable && scrollCount < maxScrolls {
        scrollView.swipeUp()
        scrollCount += 1
        Thread.sleep(forTimeInterval: 0.3)
    }
    XCTAssertTrue(element.isHittable, "Element not visible after \(maxScrolls) scrolls")
}
```

### Scroll to Top
```swift
func scrollToTop(_ scrollView: XCUIElement) {
    let statusBar = app.statusBars.firstMatch
    if statusBar.exists {
        statusBar.tap() // iOS convention: tap status bar scrolls to top
    } else {
        // Manual scroll
        for _ in 0..<10 {
            scrollView.swipeDown()
        }
    }
}
```

## Text Field Patterns

### Clear and Type
```swift
extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let currentValue = value as? String else {
            tap()
            typeText(text)
            return
        }

        if currentValue.isEmpty {
            tap()
            typeText(text)
            return
        }

        // Select all and delete
        tap()
        press(forDuration: 1.0)

        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
            typeText(text) // Replaces selection
        } else {
            // Fallback: delete character by character
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue,
                                       count: currentValue.count)
            typeText(deleteString + text)
        }
    }
}
```

### Dismiss Keyboard
```swift
func dismissKeyboard() {
    // Tap outside text field
    app.tap()

    // Or use keyboard button if available
    if app.buttons["Done"].exists {
        app.buttons["Done"].tap()
    } else if app.buttons["Return"].exists {
        app.buttons["Return"].tap()
    }
}
```

## Debugging

### Print Element Hierarchy
```swift
func printHierarchy() {
    print("=== APP HIERARCHY ===")
    print(app.debugDescription)
    print("=====================")
}
```

### Log Element State
```swift
func logElementState(_ element: XCUIElement, name: String) {
    print("=== \(name) ===")
    print("exists: \(element.exists)")
    print("isHittable: \(element.isHittable)")
    print("isEnabled: \(element.isEnabled)")
    print("label: \(element.label)")
    print("value: \(String(describing: element.value))")
    print("frame: \(element.frame)")
    print("================")
}
```

### Diagnostic Test
```swift
func testDiagnostic() {
    takeScreenshot("00-launch")

    print("=== DIAGNOSTIC ===")
    print("Buttons: \(app.buttons.count)")
    print("StaticTexts: \(app.staticTexts.count)")
    print("TextFields: \(app.textFields.count)")

    // Check specific elements
    let elements = ["tab-home", "submit-button", "main-scroll"]
    for id in elements {
        let el = app.descendants(matching: .any).matching(identifier: id).firstMatch
        print("\(id): \(el.exists ? "FOUND" : "NOT FOUND")")
    }
    print("==================")

    printHierarchy()
    takeScreenshot("01-after-diagnostic")
}
```

## Test Organization

### Test Naming Convention
```swift
// Format: test_<feature>_<scenario>_<expectedResult>
func test_login_validCredentials_navigatesToHome() { }
func test_login_invalidPassword_showsError() { }
func test_profile_editName_savesSuccessfully() { }
```

### Test with Multiple Assertions
```swift
func test_userProfile_displaysAllFields() {
    navigateToProfile()

    // Soft assertions (continue after failure)
    let originalContinueAfterFailure = continueAfterFailure
    continueAfterFailure = true

    XCTAssertTrue(app.staticTexts["name"].exists, "Name should be visible")
    XCTAssertTrue(app.staticTexts["email"].exists, "Email should be visible")
    XCTAssertTrue(app.staticTexts["phone"].exists, "Phone should be visible")
    XCTAssertTrue(app.images["avatar"].exists, "Avatar should be visible")

    continueAfterFailure = originalContinueAfterFailure
}
```

### Skip Test Conditionally
```swift
func test_featureOnlyOnIPad() throws {
    try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad,
                  "This test only runs on iPad")
    // iPad-specific test
}

func test_requiresNetwork() throws {
    try XCTSkipUnless(isNetworkAvailable(),
                      "Network required for this test")
    // Network-dependent test
}
```
