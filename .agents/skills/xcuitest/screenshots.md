# Screenshots and Attachments

## Take Screenshot
```swift
// Screenshot of entire screen
let screenshot = XCUIScreen.main.screenshot()

// Screenshot of specific element
let elementShot = element.screenshot()

// Create attachment
let attachment = XCTAttachment(screenshot: screenshot)
attachment.name = "Login Screen"
attachment.lifetime = .keepAlways  // Don't delete after test
add(attachment)
```

## Automatic Screenshot on Failure
```swift
override func tearDown() {
    if let failureCount = testRun?.failureCount, failureCount > 0 {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Failure-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    super.tearDown()
}
```

## Access Screenshots After Test
Screenshots are stored in the `.xcresult` bundle in DerivedData.
Use `xcparse` to extract:
```bash
brew install xcparse
xcparse screenshots /path/to/Test.xcresult /output/directory
```
