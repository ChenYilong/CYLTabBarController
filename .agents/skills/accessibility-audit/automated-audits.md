# Automated Accessibility Audits

The XCUITest `performAccessibilityAudit` API and the Accessibility Inspector workflow it automates. Sourced from Apple's WWDC23 "Perform accessibility audits for your app" (10035) and WWDC19 "Accessibility Inspector" (257).

## performAccessibilityAudit (Xcode 15+)

"Calling performAccessibilityAudit on your XCUIApplication will audit the current view for accessibility issues just as the Inspector does" (WWDC23 10035). No assertions needed — the test fails automatically on findings:

```swift
func testAccessibility() throws {
    let app = XCUIApplication()
    app.launch()
    try app.performAccessibilityAudit()   // defaults to all audit types
}
```

Full signature:

```swift
func performAccessibilityAudit(
    for auditTypes: XCUIAccessibilityAuditType = .all,
    _ issueHandler: ((XCUIAccessibilityAuditIssue) throws -> Bool)? = nil
) throws
```

`XCUIAccessibilityAuditIssue` carries `element`, `auditType`, `compactDescription`, `detailedDescription`.

### Audit types

| Type | Checks for | Platform |
|---|---|---|
| `.contrast` | Insufficient text/background contrast | iOS + macOS |
| `.elementDetection` | Elements assistive technologies can't detect | iOS + macOS |
| `.hitRegion` | Missing/too-small hit targets | iOS + macOS |
| `.sufficientElementDescription` | Missing or meaningless labels | iOS + macOS |
| `.dynamicType` | Text that doesn't scale at larger sizes | iOS + macOS |
| `.textClipped` | Text clipped/truncated at larger sizes | iOS + macOS |
| `.trait` | Trait problems (conflicting/missing) | iOS only |
| `.action` | Action-related issues | macOS only |
| `.parentChild` | Hierarchy issues | macOS only |
| `.all` | Everything supported on the platform (default) | both |

(The session demonstrates `.dynamicType` and `.contrast`; the full set is in the XCUIAccessibilityAuditType documentation.)

### Filtering accepted issues

The issue handler returns **`true` to ignore** an issue, `false` to report it (WWDC23 10035). Filter specific accepted findings — never disable whole audit types to get to green:

```swift
try app.performAccessibilityAudit(for: [.dynamicType, .contrast]) { issue in
    var shouldIgnore = false
    if let element = issue.element,
       element.label == "My Label",
       issue.auditType == .contrast {
        shouldIgnore = true                 // known, accepted contrast issue
    }
    return shouldIgnore
}
```

### The findings you'll hit first (with fixes)

1. **"Label is not human-readable"** — a technical ID used as the spoken label:

```swift
// ❌ VoiceOver speaks "QUOTE underscore TEXTVIEW"
quoteTextView.accessibilityLabel = "QUOTE_TEXTVIEW"

// ✅ identifier for tests (never spoken), human label for people
quoteTextView.accessibilityIdentifier = "QUOTE_TEXTVIEW"
```

2. **Decorative image exposed as an element** — curate the container:

```swift
view.accessibilityElements = [quoteTextView, newQuoteButton]  // decoration excluded
```

3. **Curation broke the UI tests** — excluding an element from accessibility also removes it from XCUITest. `automationElements` exposes elements to automation independently — and **overriding it replaces the whole set; list every element automation needs**:

```swift
view.automationElements = [imageView, quoteTextView, newQuoteButton]
```

## CI Integration Patterns (WWDC23 10035)

- **Audits only see the current screen.** One audit test per distinct screen/state; navigate first, then audit.
- **`continueAfterFailure = true`** before the audit call — surface all issues in one run.
- **`tearDown()` audit** — apply an audit across every test in a class for free:

```swift
override func tearDown() {
    super.tearDown()
    try? app.performAccessibilityAudit()
}
```

- **Dedicated test plan** for audit-enabled tests (e.g. a nightly accessibility plan) so they're selectively runnable.
- **Debugging failures**: issues appear inline in the source editor; Report Navigator → per-issue breakdown; **double-click the attached element screenshot** to identify the view.
- Audits complement, never replace, manual passes: "turning on VoiceOver or Dynamic Type remains the best validation method."

```swift
// ❌ One audit on the home screen, first failure hides the rest
func testA11y() throws {
    app.launch()
    try app.performAccessibilityAudit()
}

// ✅ Audit each screen state, see all issues, filter accepted ones explicitly
func testDetailScreenA11y() throws {
    app.launch()
    app.buttons["Show Detail"].tap()
    continueAfterFailure = true
    try app.performAccessibilityAudit(for: .all) { issue in
        issue.auditType == .contrast && issue.element?.label == "Watermark"
    }
}
```

## Accessibility Inspector Workflow (WWDC19 257)

Xcode → Open Developer Tool → Accessibility Inspector → target device/simulator + app.

1. **Run Audit**: findings appear in a table; selecting one highlights the offending view (screenshot + border) and offers a Help suggestion.
2. Fix and **re-run until zero findings**.
3. **Auto Navigate** (speaker button): the Inspector walks the whole screen speaking each element as VoiceOver would — this is where wrong reading order, redundant announcements, and unlabeled elements become audible without enabling VoiceOver.
4. **Point Inspection**: click any element to see its label/traits/value/hint.
5. **Color Contrast Calculator** (Window → Show Color Contrast Calculator): check failing pairs; nudge sliders until the ratio passes — **4.5:1 minimum** for body text (larger text can pass at 3:1; the WWDC19 demo flagged 2.3 and fixed toward the passing threshold).

Findings the WWDC19 demo walks through: an image whose label was its **filename**; text drawn in a `CATextLayer` (invisible to VoiceOver until `isAccessibilityElement = true` + a label); insufficient contrast on secondary text.

## Checklist

- [ ] One `performAccessibilityAudit` test per distinct screen/state, in a dedicated test plan
- [ ] `continueAfterFailure = true` before every audit call
- [ ] Accepted issues filtered individually in the issue handler (with a comment saying why), not by disabling audit types
- [ ] `accessibilityIdentifier` used for test IDs — never `accessibilityLabel`
- [ ] `automationElements` lists the full set wherever accessibility curation hides elements from tests
- [ ] Inspector audit at zero findings; Auto Navigate reading order verified per screen
- [ ] Contrast pairs pass 4.5:1 (3:1 for large text) in the Color Contrast Calculator
- [ ] Manual VoiceOver/Dynamic Type passes still scheduled — automation is the floor, not the ceiling

## References

- [WWDC23 — Perform accessibility audits for your app](https://developer.apple.com/videos/play/wwdc2023/10035/)
- [WWDC19 — Accessibility Inspector](https://developer.apple.com/videos/play/wwdc2019/257/)
- [XCUIAccessibilityAuditType documentation](https://developer.apple.com/documentation/xctest/xcuiaccessibilityaudittype)
