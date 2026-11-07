# Element Interactions

## Tap Actions
```swift
element.tap()                    // Single tap
element.doubleTap()              // Double tap
element.twoFingerTap()           // Two finger tap (iOS only)
element.tap(withNumberOfTaps: 3, numberOfTouches: 1) // Triple tap
```

## Press Actions
```swift
element.press(forDuration: 1.0)  // Long press
element.press(forDuration: 0.5, thenDragTo: otherElement) // Press and drag
```

## Text Input
```swift
textField.tap()                  // Focus first
textField.typeText("Hello")      // Type text
textField.clearAndEnterText("New text") // Custom helper needed

// Clear text field
textField.tap()
textField.press(forDuration: 1.0)
app.menuItems["Select All"].tap()
textField.typeText("")           // Or use delete key
```

## Swipe Gestures
```swift
element.swipeUp()
element.swipeDown()
element.swipeLeft()
element.swipeRight()

// With velocity (iOS 16+)
element.swipeUp(velocity: .fast)
element.swipeUp(velocity: .slow)
```

## Coordinate-Based Gestures
```swift
// Pull to refresh
let start = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
let end = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 6))
start.press(forDuration: 0, thenDragTo: end)

// Custom swipe
let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
from.press(forDuration: 0.1, thenDragTo: to)

// Tap at specific point
let point = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
point.tap()
```

## Other Gestures
```swift
element.pinch(withScale: 0.5, velocity: -1)  // Pinch in
element.pinch(withScale: 2.0, velocity: 1)   // Pinch out
element.rotate(0.5, withVelocity: 1)         // Rotate

// Sliders
slider.adjust(toNormalizedSliderPosition: 0.7)

// Pickers
picker.adjust(toPickerWheelValue: "Option 3")
```
