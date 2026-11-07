# Common Patterns

## Page Object Model
```swift
protocol Screen {
    var app: XCUIApplication { get }
    func waitForScreen(timeout: TimeInterval) -> Bool
}

struct LoginScreen: Screen {
    let app: XCUIApplication

    var usernameField: XCUIElement { app.textFields["username"] }
    var passwordField: XCUIElement { app.secureTextFields["password"] }
    var loginButton: XCUIElement { app.buttons["Login"] }
    var errorLabel: XCUIElement { app.staticTexts["error-message"] }

    func waitForScreen(timeout: TimeInterval = 5) -> Bool {
        usernameField.waitForExistence(timeout: timeout)
    }

    func login(username: String, password: String) -> HomeScreen {
        usernameField.tap()
        usernameField.typeText(username)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
        return HomeScreen(app: app)
    }
}
```

## Reusable Helpers
```swift
extension XCUIApplication {
    func waitForElement(_ identifier: String, timeout: TimeInterval = 5) -> XCUIElement {
        let element = descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      "Element '\(identifier)' not found within \(timeout)s")
        return element
    }

    func tapTab(_ identifier: String) {
        let tab = buttons[identifier]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(identifier)' not found")
        tab.tap()
    }
}

extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let currentValue = value as? String, !currentValue.isEmpty else {
            tap()
            typeText(text)
            return
        }
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
```

## Timeout Constants
```swift
enum TestTimeout: TimeInterval {
    case short = 2
    case medium = 5
    case long = 10
    case networkLoad = 30
}

// Usage
button.waitForExistence(timeout: TestTimeout.medium.rawValue)
```

## Advanced Patterns

For more detailed patterns including:
- Base test class implementation
- iOS system dialog handling (HealthKit, Location, Notifications)
- Scroll and wait patterns
- Text field helpers
- Debugging techniques
- Test organization

See [patterns.md](patterns.md).
