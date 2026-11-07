# Assertions

## Basic Assertions
```swift
XCTAssertTrue(element.exists)
XCTAssertFalse(element.exists)
XCTAssertEqual(element.label, "Expected")
XCTAssertNotEqual(element.value as? String, "Wrong")
XCTAssertNil(element.value)
XCTAssertNotNil(element.value)
```

## With Custom Messages
```swift
XCTAssertTrue(element.exists, "Submit button should be visible")
XCTAssertEqual(element.label, "Done", "Button label should be 'Done' after completion")
```

## Existence Patterns
```swift
// Element must exist (fails test if not)
XCTAssertTrue(element.waitForExistence(timeout: 5), "Element not found")

// Element should not exist
XCTAssertFalse(app.alerts["Error"].exists, "Unexpected error alert")

// Element state
XCTAssertTrue(button.isEnabled, "Button should be enabled")
XCTAssertTrue(button.isHittable, "Button should be tappable")
```
