# Permission Handling and System Alerts

## Reset Authorization Status
Reset permissions before tests to ensure consistent state. Call before `app.launch()`.

```swift
override func setUp() {
    super.setUp()
    let app = XCUIApplication()

    // Reset permissions before launch
    app.resetAuthorizationStatus(for: .location)
    app.resetAuthorizationStatus(for: .camera)
    app.resetAuthorizationStatus(for: .photos)
    app.resetAuthorizationStatus(for: .health)

    app.launch()
}
```

## XCUIProtectedResource Types
```swift
// Available protected resources
.contacts          // Contacts access
.calendar          // Calendar access
.reminders         // Reminders access
.photos            // Photo library access
.microphone        // Microphone access
.camera            // Camera access
.mediaLibrary      // Media library access
.homeKit           // HomeKit access
.bluetooth         // Bluetooth access
.keyboardNetwork   // Network keyboard access
.location          // Location services
.health            // HealthKit access
```

## Handling HealthKit Permission Dialog (iOS 26)
HealthKit authorization on iOS 26 uses a scrollable sheet with buttons below the fold:

```swift
func handleHealthKitDialog(allow: Bool = false) {
    let healthAccessText = app.staticTexts["Health Access"]

    if healthAccessText.waitForExistence(timeout: 5) {
        // Scroll down to reveal buttons (iOS 26 sheet is scrollable)
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        from.press(forDuration: 0.1, thenDragTo: to)

        // Tap the appropriate button
        let buttonLabel = allow ? "Allow" : "Don't Allow"
        let button = app.buttons[buttonLabel]
        if button.waitForExistence(timeout: 5) {
            button.tap()
        } else {
            // Fallback: find by partial match
            let fallback = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] '\(buttonLabel)'")
            ).firstMatch
            if fallback.exists { fallback.tap() }
        }
    }
}
```

## Using UI Interruption Monitor
For handling unexpected permission dialogs during tests:

```swift
override func setUp() {
    super.setUp()

    // Handle location permission
    addUIInterruptionMonitor(withDescription: "Location Permission") { alert -> Bool in
        if alert.buttons["Allow While Using App"].exists {
            alert.buttons["Allow While Using App"].tap()
            return true
        }
        if alert.buttons["Don't Allow"].exists {
            alert.buttons["Don't Allow"].tap()
            return true
        }
        return false
    }

    // Handle HealthKit permission
    addUIInterruptionMonitor(withDescription: "Health Permission") { alert -> Bool in
        // Note: HealthKit uses a sheet, not a system alert
        // This may not trigger the interruption monitor
        return false
    }

    app.launch()
}

func testWithPermissions() {
    // Trigger action that shows permission dialog
    app.buttons["Enable Location"].tap()

    // IMPORTANT: Must interact with app to trigger the monitor
    app.tap()

    // Continue test...
}
```

## Springboard Alert Handling
For system-level alerts not caught by interruption monitor:

```swift
func handleSpringboardAlert(buttonLabel: String) {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alertButton = springboard.buttons[buttonLabel]

    if alertButton.waitForExistence(timeout: 3) {
        alertButton.tap()
    }
}

// Usage
handleSpringboardAlert(buttonLabel: "Allow")
handleSpringboardAlert(buttonLabel: "Don't Allow")
```

## System Alerts

### Interruption Monitor (for system dialogs)
```swift
override func setUp() {
    super.setUp()

    // Set up before launching app
    addUIInterruptionMonitor(withDescription: "System Alert") { alert -> Bool in
        // Handle location permission
        if alert.buttons["Allow While Using App"].exists {
            alert.buttons["Allow While Using App"].tap()
            return true
        }
        // Handle notification permission
        if alert.buttons["Allow"].exists {
            alert.buttons["Allow"].tap()
            return true
        }
        // Handle "Don't Allow"
        if alert.buttons["Don't Allow"].exists {
            alert.buttons["Don't Allow"].tap()
            return true
        }
        return false
    }

    app.launch()
}

func testWithSystemAlert() {
    // Trigger action that shows system alert
    app.buttons["Request Permission"].tap()

    // IMPORTANT: Must interact with app to trigger handler
    app.tap()

    // Continue test...
}
```

### Direct Alert Handling
```swift
// For app alerts (not system)
let alert = app.alerts["Confirm Delete"]
if alert.waitForExistence(timeout: 3) {
    alert.buttons["Delete"].tap()
}

// For springboard alerts (system)
let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
let systemAlert = springboard.alerts.firstMatch
if systemAlert.waitForExistence(timeout: 3) {
    systemAlert.buttons["Allow"].tap()
}
```
