# Accessibility Quick Reference

Quick reference for SwiftUI accessibility implementation.

## Essential Modifiers

### Labels & Descriptions
```swift
// Label: What the element is
.accessibilityLabel("Add new expense")

// Value: Current state/value
.accessibilityValue("$150.00")

// Hint: What happens when activated
.accessibilityHint("Creates a new expense in this group")
```

### Traits
```swift
// Add traits
.accessibilityAddTraits(.isButton)
.accessibilityAddTraits(.isHeader)
.accessibilityAddTraits(.isSelected)
.accessibilityAddTraits(.updatesFrequently)

// Remove traits
.accessibilityRemoveTraits(.isImage)
```

### Grouping & Hiding
```swift
// Combine multiple elements into one
VStack {
    Text("Total")
    Text("$150")
}
.accessibilityElement(children: .combine)

// Hide decorative elements
Image("background-pattern")
    .accessibilityHidden(true)
```

### Custom Actions
```swift
.accessibilityAction(named: "Delete") {
    deleteExpense()
}

.accessibilityAction(named: "Edit") {
    showEditSheet()
}
```

## Common Patterns

### Icon-Only Buttons
```swift
// ❌ Bad
Button {
    addExpense()
} label: {
    Image(systemName: "plus")
}

// ✅ Good
Button {
    addExpense()
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel("Add expense")
```

### Custom Controls
```swift
// ❌ Bad - VoiceOver doesn't know it's tappable
Image(systemName: "star")
    .onTapGesture { toggleFavorite() }

// ✅ Good
Image(systemName: "star")
    .onTapGesture { toggleFavorite() }
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("Favorite")
    .accessibilityValue(isFavorite ? "On" : "Off")
```

### Lists with Actions
```swift
List {
    ForEach(expenses) { expense in
        ExpenseRow(expense: expense)
            .accessibilityAction(named: "Delete") {
                delete(expense)
            }
            .accessibilityAction(named: "Edit") {
                edit(expense)
            }
    }
}
```

### Toggle States
```swift
Toggle("Enable notifications", isOn: $notificationsEnabled)
    .accessibilityValue(notificationsEnabled ? "Enabled" : "Disabled")
```

### Progress & Status
```swift
ProgressView("Loading expenses", value: progress, total: 1.0)
    .accessibilityLabel("Loading")
    .accessibilityValue("\(Int(progress * 100)) percent complete")
```

## Dynamic Type Support

### Use Semantic Text Styles
```swift
// ✅ Good - Scales automatically
Text("Expense Title")
    .font(.headline)

Text("Description")
    .font(.body)

Text("Date")
    .font(.caption)

// ❌ Bad - Fixed size
Text("Expense Title")
    .font(.system(size: 18))
```

### Custom Fonts with Scaling
```swift
// ✅ Good - Custom font that scales
Text("Title")
    .font(.custom("SF Pro Display", size: 17, relativeTo: .body))

// ❌ Bad - Fixed custom font
Text("Title")
    .font(.custom("SF Pro Display", fixedSize: 17))
```

### Handle Large Text
```swift
// Use ViewThatFits for flexibility
ViewThatFits {
    HStack {
        Text("Long text here")
        Spacer()
        Text("$150")
    }

    VStack(alignment: .leading) {
        Text("Long text here")
        Text("$150")
    }
}

// Or use dynamic layout
@Environment(\.sizeCategory) var sizeCategory

var body: some View {
    if sizeCategory.isAccessibilityCategory {
        VStack { /* Vertical layout */ }
    } else {
        HStack { /* Horizontal layout */ }
    }
}
```

### Size Model
- 12 sizes total: 7 default + 5 accessibility sizes. `.body` runs 17pt at the default size, 28pt at the first accessibility size, 53pt at the largest — roughly 3× (WWDC24 10074).
- The App Store Accessibility Nutrition Label claim bar is **200%** text scaling; the maximum accessibility size is ~**310%** — see `ios/accessibility-audit` for the label evaluation workflow.

### Large Content Viewer
**Scaling is always preferred** — use the viewer only for bars that legitimately can't grow: tab bars, nav bars, toolbars, custom fixed-height bars (WWDC19 261). Rationale: a tab bar takes under 10% of screen height; scaled to accessibility sizes it would eat almost a quarter (WWDC24 10074). At accessibility text sizes, long-pressing a bar item shows a large HUD of its glyph + title; lifting the finger activates it. System bars are automatic; custom bars adopt it:

```swift
// SwiftUI
FigureButton(figure: figure)
    .accessibilityShowsLargeContentViewer {
        Label(figure.title, systemImage: figure.systemImage)
    }

// UIKit — UILargeContentViewerItem properties + the interaction (WWDC19 261)
button.showsLargeContentViewer = true
button.largeContentTitle = "Favorites"
button.largeContentImage = UIImage(systemName: "star.fill")
button.scalesLargeContentImage = true      // needs Preserve Vector Data on the asset
customBar.addInteraction(UILargeContentViewerInteraction())
```

```swift
// ❌ Body content that could scale, "fixed" with the viewer instead
label.font = UIFont.systemFont(ofSize: 13)

// ✅ Scale what can scale; the viewer is only for bars that can't
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true
```

## Color & Contrast

### Semantic Colors
```swift
// ✅ Good - Adapts to light/dark mode
Text("Title")
    .foregroundColor(.primary)

Background()
    .fill(Color(.systemBackground))

// ❌ Bad - Fixed colors
Text("Title")
    .foregroundColor(.black)

Background()
    .fill(Color.white)
```

### Contrast Requirements
Use Xcode's Accessibility Inspector to verify contrast ratios for text and UI components.

## Testing Checklist

### VoiceOver Testing
- [ ] All interactive elements have labels
- [ ] Navigation order is logical
- [ ] Custom actions work correctly
- [ ] Dynamic content is announced

### Dynamic Type Testing
- [ ] Test at largest size (Accessibility XXXL)
- [ ] No clipped text
- [ ] Layouts adapt appropriately
- [ ] Buttons remain tappable

### Visual Testing
- [ ] Test in Dark Mode
- [ ] Test with Increased Contrast
- [ ] Test with Reduce Transparency
- [ ] Test with Reduce Motion

### Keyboard Testing (iPad/Mac)
- [ ] All actions have keyboard shortcuts
- [ ] Focus indicator is visible
- [ ] Tab order is logical

## Testing in Simulator

### Enable Accessibility Features
```
Settings → Accessibility → VoiceOver → On
Settings → Accessibility → Display & Text Size → Larger Text
Settings → Accessibility → Display & Text Size → Increase Contrast
Settings → Accessibility → Motion → Reduce Motion
```

### Xcode Accessibility Inspector
```
Xcode → Open Developer Tool → Accessibility Inspector
```

Features:
- Inspect element accessibility properties
- Audit for common issues
- Check color contrast
- Test with different settings

Full audit workflow — automated `performAccessibilityAudit` XCUITests, Inspector triage, and Accessibility Nutrition Label evaluation — lives in `ios/accessibility-audit`.

## Resources

- [Apple Accessibility Documentation](https://developer.apple.com/documentation/accessibility)
- [SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
