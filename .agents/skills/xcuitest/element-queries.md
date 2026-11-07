# Core API Classes

## XCUIApplication
Proxy for launching, monitoring, and terminating the app under test.

```swift
let app = XCUIApplication()

// Launch configuration
app.launchArguments = ["-UITest", "-DisableAnimations"]
app.launchEnvironment["API_URL"] = "https://test.example.com"

// Lifecycle
app.launch()      // Start the app
app.terminate()   // Stop the app
app.activate()    // Bring to foreground

// State checking
app.state == .runningForeground
app.state == .runningBackground
app.state == .notRunning
```

## XCUIElement
Represents a single UI element. Supports interactions and property queries.

```swift
let element = app.buttons["Submit"]

// Properties
element.exists           // Bool - element is in hierarchy
element.isHittable       // Bool - element can receive taps
element.isEnabled        // Bool - element is enabled
element.isSelected       // Bool - element is selected
element.label            // String - accessibility label
element.value            // Any? - current value
element.identifier       // String - accessibility identifier
element.frame            // CGRect - frame in screen coordinates
element.elementType      // XCUIElement.ElementType
```

## XCUIElementQuery
Defines search criteria for finding UI elements.

```swift
// Type-based queries (convenience)
app.buttons              // All buttons
app.staticTexts          // All text labels
app.textFields           // All text inputs
app.secureTextFields     // Password fields
app.switches             // Toggle switches
app.sliders              // Slider controls
app.tables               // Table views
app.cells                // Table/collection cells
app.scrollViews          // Scroll views
app.images               // Image views
app.alerts               // Alert dialogs
app.sheets               // Action sheets
app.navigationBars       // Navigation bars
app.tabBars              // Tab bars
app.toolbars             // Toolbars

// Querying by identifier (subscript)
app.buttons["Submit"]
app.staticTexts["Welcome"]

// Descendants query (any element type)
app.descendants(matching: .any)
app.descendants(matching: .button)
app.descendants(matching: .staticText)

// Chained queries
app.descendants(matching: .any).matching(identifier: "my-id").firstMatch

// Predicate queries
app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Save'"))
app.buttons.matching(NSPredicate(format: "identifier == 'submit-btn'"))
app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Error'"))

// Query results
query.count              // Number of matches
query.element            // Single element (fails if not exactly 1)
query.firstMatch         // First matching element
query.element(boundBy: 0) // Element at index
query.allElementsBoundByIndex  // Array of all elements
```

## XCUICoordinate
Represents a screen location for coordinate-based interactions.

```swift
// Normalized offset (0,0 = top-left, 1,1 = bottom-right)
let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
let topLeft = element.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

// Absolute offset from normalized point
let point = app.coordinate(withNormalizedOffset: .zero)
    .withOffset(CGVector(dx: 100, dy: 200))

// Screen coordinates
let screenCenter = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
```
