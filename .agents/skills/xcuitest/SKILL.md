---
name: xcuitest
user-invocable: true
description: "API reference: XCUITest. Query for element queries, waiting patterns, Swift 6 @MainActor, assertions, screenshots, launch arguments."
context: fork
agent: Explore
---

# XCUITest Reference

Comprehensive reference for writing reliable XCUITest UI tests in Swift 6.

## Quick Reference

```swift
// Basic test structure
@MainActor
final class MyUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testExample() {
        let button = app.buttons["Submit"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }
}
```

## Topic Guides

Curated guidance with code examples (grep-friendly):

| File | Content |
|------|---------|
| [element-queries.md](element-queries.md) | Core API classes: XCUIApplication, XCUIElement, XCUIElementQuery, XCUICoordinate |
| [interactions.md](interactions.md) | Taps, presses, text input, swipes, coordinate-based and other gestures |
| [waiting.md](waiting.md) | waitForExistence, XCTWaiter, non-existence, property waits, Xcode 26 KeyPath waits |
| [swift6-concurrency.md](swift6-concurrency.md) | Swift 6 strict concurrency: @MainActor test classes, async setUp/tearDown, nonisolated |
| [assertions.md](assertions.md) | XCTAssert patterns, custom messages, existence checks |
| [screenshots.md](screenshots.md) | Screenshots, XCTAttachment, screenshot-on-failure, extracting from .xcresult |
| [launch-arguments.md](launch-arguments.md) | Launch arguments/environment, UserDefaults override, localization and accessibility testing |
| [permissions.md](permissions.md) | resetAuthorizationStatus, XCUIProtectedResource, interruption monitors, springboard/system alerts |
| [test-helpers.md](test-helpers.md) | Page Object Model, reusable helpers, timeout constants |
| [troubleshooting.md](troubleshooting.md) | Common failures (element not found, flaky tests) and what's new in Xcode 26 / iOS 26 |
| [patterns.md](patterns.md) | Advanced patterns: base test class, system dialogs, scroll/wait, debugging, test organization |

## Downloaded Reference Files

Apple documentation pages available locally:

| File | Content |
|------|---------|
| [xctest-index.md](xctest-index.md) | Full XCTest framework index |
| [xcuiautomation-index.md](xcuiautomation-index.md) | Full XCUIAutomation framework index |
| [xcuiapplication.md](xcuiapplication.md) | XCUIApplication class |
| [xcuielement.md](xcuielement.md) | XCUIElement class |
| [xcuielementquery.md](xcuielementquery.md) | XCUIElementQuery class |
| [xcuicoordinate.md](xcuicoordinate.md) | XCUICoordinate class |
| [xcuiprotectedresource.md](xcuiprotectedresource.md) | XCUIProtectedResource enum |
| [xcuiscreenshot.md](xcuiscreenshot.md) | XCUIScreenshot class |

## Sources

### Apple Documentation
- [XCTest | Apple Developer Documentation](https://developer.apple.com/documentation/xctest)
- [XCUIAutomation | Apple Developer Documentation](https://developer.apple.com/documentation/xcuiautomation)
- [XCUIElementQuery | Apple Developer Documentation](https://developer.apple.com/documentation/xctest/xcuielementquery)
- [waitForExistence | Apple Developer Documentation](https://developer.apple.com/documentation/xctest/xcuielement/2879412-waitforexistence)
- [wait(for:toEqual:timeout:) | Apple Developer Documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielement/wait(for:toequal:timeout:))
- [resetAuthorizationStatus(for:) | Apple Developer Documentation](https://developer.apple.com/documentation/xctest/xcuiapplication/3526066-resetauthorizationstatus)
- [XCUIProtectedResource | Apple Developer Documentation](https://developer.apple.com/documentation/xctest/xcuiprotectedresource)
- [XCUIScreenshot | Apple Developer Documentation](https://developer.apple.com/documentation/xctest/xcuiscreenshot)

### WWDC Sessions
- [Record, replay, and review: UI automation with Xcode - WWDC25](https://developer.apple.com/videos/play/wwdc2025/344/)
- [What's new in Xcode 26 - WWDC25](https://developer.apple.com/videos/play/wwdc2025/247/)

### Community Resources
- [XCTest Meets @MainActor | Quality Coding](https://qualitycoding.org/xctest-mainactor/)
- [Issues with setUp() and tearDown() in XCTest for Swift 6 | Swift Forums](https://forums.swift.org/t/issues-with-setup-and-teardown-in-xctest-for-swift-6/75990)
- [Waiting in XCTest | Masilotti.com](https://masilotti.com/xctest-waiting/)
- [UI Testing Cheat Sheet | Masilotti.com](https://masilotti.com/ui-testing-cheat-sheet/)
- [XCUIElement Actions and Gestures | Apps Developer Blog](https://www.appsdeveloperblog.com/xcuielement-actions-and-gestures/)
- [Configuring UI tests with launch arguments | polpiella.dev](https://www.polpiella.dev/configuring-ui-tests-with-launch-arguments)
- [UI Testing improvements in Xcode 16 | Jesse Squires](https://www.jessesquires.com/blog/2024/07/09/uitest-improvements-in-xcode-16/)

### Fetching More Apple Docs

1. Search this skill's local `.md` files first.
2. If the topic is not here, check the other installed Apple skills you have available by their names, descriptions, or `SKILL.md` frontmatter, then grep their local files. This is faster and uses less context than fetching new docs from the internet.
3. If no installed skill has the page, use the relevant documentation path from the local XCTest or XCUIAutomation indexes with the `sosumi.ai` Markdown mirror. For example, `/documentation/xcuiautomation/xcuielement` maps to `https://sosumi.ai/documentation/xcuiautomation/xcuielement`.
