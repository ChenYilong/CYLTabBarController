# Launch Arguments and Environment

## Setting Values
```swift
let app = XCUIApplication()

// Launch arguments (appear in ProcessInfo.processInfo.arguments)
app.launchArguments = ["-UITest", "-DisableAnimations"]
app.launchArguments.append("-SkipOnboarding")

// Launch environment (appear in ProcessInfo.processInfo.environment)
app.launchEnvironment["API_URL"] = "https://test.example.com"
app.launchEnvironment["TEST_USER_ID"] = "test-user-123"

app.launch()  // Must be set before launch!
```

## Reading in App Code
```swift
// Check for launch argument
if ProcessInfo.processInfo.arguments.contains("-UITest") {
    UIView.setAnimationsEnabled(false)
}

// Read environment variable
if let testUserID = ProcessInfo.processInfo.environment["TEST_USER_ID"] {
    UserDefaults.standard.set(testUserID, forKey: "testUserID")
}
```

## UserDefaults Override Trick
Arguments with `-` prefix set UserDefaults:
```swift
// In test
app.launchArguments = ["-myKey", "myValue"]

// In app - reads from UserDefaults
UserDefaults.standard.string(forKey: "myKey") // "myValue"
```

## Localization Testing
```swift
app.launchArguments = [
    "-AppleLanguages", "(es)",
    "-AppleLocale", "es_ES"
]
```

## Accessibility Testing
```swift
app.launchArguments = [
    "-UIPreferredContentSizeCategoryName",
    UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
]
```
