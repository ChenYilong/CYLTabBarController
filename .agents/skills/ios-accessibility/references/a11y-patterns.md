# Accessibility Patterns Reference

## Contents
- Labels, Values, and Hints
- Traits and Element Grouping
- Custom Controls and Adjustable Actions
- Focus Management Patterns
- Dynamic Type and Layout
- Custom Rotors
- System Accessibility Preferences
- UIKit Accessibility Patterns
- AppKit Accessibility Patterns
- Voice Control Patterns
- Switch Control Patterns
- Full Keyboard Access Patterns
- Automated Accessibility Testing

## Labels, Values, and Hints

```swift
Button(action: { }) {
    Image(systemName: "heart.fill")
}
.accessibilityLabel("Favorite")

Slider(value: $volume, in: 0...100)
    .accessibilityValue("\(Int(volume)) percent")

Button("Submit")
    .accessibilityHint("Submits the form and sends your feedback")
```

## Traits and Element Grouping

```swift
// Add traits without overwriting defaults
Button("Go") { }
    .accessibilityAddTraits(.updatesFrequently)

// Group children into a single accessibility element
HStack {
    Image(systemName: "person.circle")
    VStack {
        Text("John Doe")
        Text("Engineer")
    }
}
.accessibilityElement(children: .combine)

// Binary custom control: prefer Toggle when possible; otherwise expose toggle state
HStack {
    Image(systemName: isFavorite ? "heart.fill" : "heart")
    Text(product.name)
}
.onTapGesture { isFavorite.toggle() }
.accessibilityElement()
.accessibilityLabel("Favorite \(product.name)")
.accessibilityValue(isFavorite ? "On" : "Off")
.accessibilityAddTraits(.isToggle)
.accessibilityAction { isFavorite.toggle() }
```

## Custom Controls and Adjustable Actions

```swift
HStack { /* custom star rating UI */ }
    .accessibilityElement()
    .accessibilityLabel("Rating")
    .accessibilityValue("\(rating) out of 5 stars")
    .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: if rating < 5 { rating += 1 }
        case .decrement: if rating > 1 { rating -= 1 }
        @unknown default: break
        }
    }
```

For custom quantity controls, steppers, ratings, sliders, or other adjustable values, prefer the native control first. If the control is custom, SwiftUI needs `.accessibilityAdjustableAction`; UIKit custom controls also need `accessibilityTraits.insert(.adjustable)`.

## Focus Management Patterns

```swift
@AccessibilityFocusState private var focusOnTrigger: Bool

Button("Open Settings") { showSheet = true }
    .accessibilityFocused($focusOnTrigger)
    .sheet(isPresented: $showSheet) {
        SettingsSheet()
            .onDisappear {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    focusOnTrigger = true
                }
            }
    }
```

```swift
enum A11yFocus: Hashable { case nameField, emailField, submitButton }
@AccessibilityFocusState private var focus: A11yFocus?
```

## Dynamic Type and Layout

```swift
@ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 24
@ScaledMetric(relativeTo: .body) private var rowSpacing: CGFloat = 12
@ScaledMetric(relativeTo: .body) private var controlHeight: CGFloat = 44
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var body: some View {
    Group {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading) { icon; textContent }
        } else {
            HStack { icon; textContent }
        }
    }
    .frame(minHeight: controlHeight)
}
```

Use `@ScaledMetric(relativeTo:)` for non-text dimensions that need to track text size, including icon sizes, spacing, control heights, and custom hit-region dimensions.

## Custom Rotors

```swift
List(items) { item in ItemRow(item: item) }
    .accessibilityRotor("Unread") {
        ForEach(items.filter { !$0.isRead }) { item in
            AccessibilityRotorEntry(item.title, id: item.id)
        }
    }
```

## System Accessibility Preferences

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.colorSchemeContrast) var contrast
@Environment(\.legibilityWeight) var legibilityWeight
```

## UIKit Accessibility Patterns

```swift
customButton.accessibilityTraits.insert(.button)
customButton.accessibilityTraits.remove(.staticText)

UIAccessibility.post(notification: .announcement, argument: "Upload complete")
UIAccessibility.post(notification: .layoutChanged, argument: targetView)
UIAccessibility.post(notification: .screenChanged, argument: newScreenView)
```

## AppKit Accessibility Patterns

AppKit accessibility centers on `NSAccessibilityProtocol`. Use standard AppKit controls when possible, then override or add accessibility behavior only where the default metadata is wrong or incomplete.

### Custom NSView with role, label, value, and action

```swift
final class FavoriteToggleView: NSView {
    var isFavorite = false {
        didSet {
            NSAccessibility.post(element: self, notification: .valueChanged)
        }
    }

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .button }
    override func accessibilityLabel() -> String? { "Favorite" }
    override func accessibilityValue() -> Any? { isFavorite ? "On" : "Off" }

    override func accessibilityPerformPress() -> Bool {
        isFavorite.toggle()
        return true
    }
}
```

### NSAccessibilityElement for non-view items

Use `NSAccessibilityElement` when an accessible item has no backing `NSView`, such as a virtual data point in a chart or a drawn annotation.

```swift
let pointElement = NSAccessibilityElement.element(
    withRole: .button,
    frame: pointFrame,
    label: "March revenue",
    parent: chartView
)
```

### AppKit announcements and notifications

```swift
NSAccessibility.post(element: saveStatusLabel, notification: .valueChanged)

NSAccessibility.post(
    element: self,
    notification: .announcementRequested,
    userInfo: [
        .announcement: "Export complete"
    ]
)
```

Use `.announcementRequested` when assistive apps need to announce transient status. Use state-specific notifications such as `.valueChanged` when the accessible value changed.

## Voice Control Patterns

Voice Control generates tap targets from accessibility labels. Labels must be speakable and unique within the visible screen.

### accessibilityInputLabels (iOS 14+)

Provide shorter spoken alternatives when the primary label is long, awkward, repeated, localized, acronym-heavy, or commonly shortened in speech:

```swift
// Primary label is descriptive but long to speak
Button(action: { startWorkout() }) {
    VStack {
        Image(systemName: "figure.run")
        Text("Start Outdoor Running Workout")
    }
}
.accessibilityLabel("Start Outdoor Running Workout")
.accessibilityInputLabels(["Start Run", "Run", "Start Workout"])
```

```swift
// Navigation link with verbose label
NavigationLink {
    AccountSettingsView()
} label: {
    Label("Account and Privacy Settings", systemImage: "person.circle")
}
.accessibilityInputLabels(["Account", "Settings", "Privacy"])
```

Also consider input labels for repeated row actions, quantity controls, media controls, and product-name labels where Voice Control users are likely to speak a shorter command than the visible text.

### Speakable Label Guidelines

```swift
// Bad: emoji-only, unspeakable
Button("❤️") { toggleFavorite() }

// Good: speakable label
Button(action: { toggleFavorite() }) {
    Image(systemName: "heart.fill")
}
.accessibilityLabel("Favorite")

// Bad: duplicate labels on same screen
ForEach(items) { item in
    Button("Edit") { edit(item) }  // Voice Control can't distinguish
}

// Good: unique labels
ForEach(items) { item in
    Button("Edit") { edit(item) }
        .accessibilityLabel("Edit \(item.name)")
}
```

## Switch Control Patterns

Switch Control scans elements sequentially. Reduce scan stops with grouping and provide custom actions for gesture-based interactions.

### Custom Actions for Gesture Alternatives

```swift
// Swipe-to-delete row: Switch Control can't swipe
TaskRow(task: task)
    .accessibilityAction(named: "Complete") { completeTask(task) }
    .accessibilityAction(named: "Delete") { deleteTask(task) }
    .accessibilityAction(named: "Reschedule") { rescheduleTask(task) }
```

```swift
// Long-press context menu: expose actions directly
PhotoThumbnail(photo: photo)
    .contextMenu { /* ... */ }
    .accessibilityAction(named: "Share") { sharePhoto(photo) }
    .accessibilityAction(named: "Add to Album") { addToAlbum(photo) }
    .accessibilityAction(named: "Delete") { deletePhoto(photo) }
```

### Grouping for Scan Efficiency

```swift
// Bad: 5 scan stops per row
HStack {
    Image(systemName: "doc")
    VStack {
        Text(document.title)
        Text(document.date.formatted())
    }
    Spacer()
    Text(document.size)
    Image(systemName: "chevron.right")
}

// Good: 1 scan stop per row
HStack {
    Image(systemName: "doc")
    VStack {
        Text(document.title)
        Text(document.date.formatted())
    }
    Spacer()
    Text(document.size)
    Image(systemName: "chevron.right")
}
.accessibilityElement(children: .combine)
```

## Full Keyboard Access Patterns

Full Keyboard Access review checks whether keyboard users can complete the same common tasks without touch. Keep the implementation mechanics in the `focus-engine` skill when the fix requires Tab-order wiring, skipped custom cards, `.focusable()`, SwiftUI keyboard focus state, focus sections, directional movement, tvOS focus, or `UIFocusGuide`.

- Every interactive control is reachable by keyboard.
- Activation works with expected keyboard input.
- Focus indicators are visible and not hidden by custom styling.
- Focus traversal is logical and does not trap users in a region.
- Gesture-only interactions have keyboard-operable alternatives.
- App shortcuts do not override system shortcuts.
- Custom controls skipped by Tab should be filed as keyboard focus implementation issues and routed to `focus-engine`; keep the accessibility finding here.
- Explicitly assess traversal impact: accessibility element order and grouping affect VoiceOver swipe order, Switch Control scan order, Voice Control overlay targeting, and Full Keyboard Access reachability review.

## Automated Accessibility Testing

Use `XCUIElement` attributes to verify accessibility properties in UI tests.

### Verifying Labels and Identifiers

```swift
func testAccessibilityLabels() throws {
    let app = XCUIApplication()
    app.launch()

    // Verify buttons have meaningful labels
    let settingsButton = app.buttons["Settings"]
    XCTAssertTrue(settingsButton.exists, "Settings button must exist")
    XCTAssertTrue(settingsButton.isEnabled, "Settings button must be enabled")

    // Verify a cell groups content correctly
    let productCell = app.cells.element(boundBy: 0)
    XCTAssertFalse(productCell.label.isEmpty, "Product cell must have a combined label")
}
```

### Testing Focus and Selection State

```swift
func testTabNavigationOrder() throws {
    let app = XCUIApplication()
    app.launch()

    let usernameField = app.textFields["Username"]
    let passwordField = app.secureTextFields["Password"]

    usernameField.tap()
    XCTAssertTrue(usernameField.hasFocus)

    // Tab to next field
    usernameField.typeText("\t")
    XCTAssertTrue(passwordField.hasFocus)
}
```

### Testing Custom Actions

```swift
func testSwipeToDeleteAlternative() throws {
    let app = XCUIApplication()
    app.launch()

    let cell = app.cells["task-buy-groceries"]
    XCTAssertTrue(cell.exists)
    try app.performAccessibilityAudit(for: [.action])

    // Verify the custom gesture has a discoverable, operable alternative.
    let deleteButton = app.buttons["Delete Buy groceries"]
    XCTAssertTrue(deleteButton.exists)
    deleteButton.tap()
    XCTAssertFalse(cell.exists)
}
```

The audit and behavioral assertion complement, but do not replace, manual
VoiceOver and Switch Control testing of the custom action.
