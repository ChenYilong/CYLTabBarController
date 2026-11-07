# Waiting Mechanisms

## waitForExistence (Simplest)
```swift
// Returns Bool - does not fail test automatically
let exists = element.waitForExistence(timeout: 5)
XCTAssertTrue(exists, "Element did not appear")

// Common pattern
if button.waitForExistence(timeout: 3) {
    button.tap()
}
```

## XCTWaiter (More Control)
```swift
// Wait with result handling
let predicate = NSPredicate(format: "exists == true")
let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
let result = XCTWaiter().wait(for: [expectation], timeout: 5)

switch result {
case .completed:
    // Element found
case .timedOut:
    XCTFail("Element did not appear within timeout")
case .incorrectOrder:
    // Multiple expectations fulfilled out of order
case .invertedFulfillment:
    // Inverted expectation was fulfilled (unexpected)
case .interrupted:
    // Wait was interrupted
@unknown default:
    break
}
```

## Wait for Non-Existence (Xcode 16+)
```swift
// Native API (Xcode 16+) - preferred
let loadingIndicator = app.activityIndicators["loading"]
XCTAssertTrue(loadingIndicator.waitForNonExistence(withTimeout: 10), "Loading should complete")

// Legacy approach (pre-Xcode 16)
func waitForNonExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    return result == .completed
}
```

## Wait for Property Change
```swift
// Wait for element to become enabled
let predicate = NSPredicate(format: "isEnabled == true")
let expectation = XCTNSPredicateExpectation(predicate: predicate, object: button)
XCTWaiter().wait(for: [expectation], timeout: 5)

// Wait for label to change
let predicate = NSPredicate(format: "label == 'Done'")
let expectation = XCTNSPredicateExpectation(predicate: predicate, object: statusLabel)
XCTWaiter().wait(for: [expectation], timeout: 10)
```

## Multiple Expectations
```swift
let exp1 = XCTNSPredicateExpectation(predicate: pred1, object: element1)
let exp2 = XCTNSPredicateExpectation(predicate: pred2, object: element2)
XCTWaiter().wait(for: [exp1, exp2], timeout: 10, enforceOrder: false)
```

## Wait for Property Value (Xcode 26+ / iOS 26+)
```swift
// New KeyPath-based waiting - wait for any property to equal a value
let favoriteButton = app.buttons["Favorite"]
favoriteButton.tap()

// Wait for value property to become true
XCTAssertTrue(
    favoriteButton.wait(for: \.value, toEqual: true, timeout: 10),
    "Button should show favorited state"
)

// Wait for label to change
XCTAssertTrue(
    statusLabel.wait(for: \.label, toEqual: "Complete", timeout: 5),
    "Status should update to Complete"
)

// Wait for element to become enabled
XCTAssertTrue(
    submitButton.wait(for: \.isEnabled, toEqual: true, timeout: 3),
    "Submit button should become enabled"
)
```

**Note:** The `wait(for:toEqual:timeout:)` method uses Swift KeyPaths for type-safe property access. It returns `true` if the property matches the expected value within the timeout, `false` otherwise.
