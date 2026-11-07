# Font Usage Guidelines

Comprehensive guide for font usage, Dynamic Type, and typography best practices.

## System Text Styles

### iOS Text Style Hierarchy

Use the named system text styles (`.largeTitle` down through `.caption2`) rather than fixed point sizes — they carry the right weight/size for their role and scale automatically with Dynamic Type.

### Usage Examples

```swift
// ✅ Page title
Text("Expenses")
    .font(.largeTitle)

// ✅ Section header
Text("Recent")
    .font(.headline)

// ✅ Body content
Text("This is the main content of the expense description...")
    .font(.body)

// ✅ Metadata
Text("Updated 2 hours ago")
    .font(.caption)
    .foregroundColor(.secondary)
```

## Dynamic Type Support

### Why Dynamic Type Matters

- **Accessibility**: Users with vision impairments need larger text
- **User Preference**: Some prefer smaller/larger text
- **App Store Requirement**: Required for accessibility compliance
- **Better UX**: Respects user system settings

### Automatic Dynamic Type

```swift
// ✅ Automatically scales with Dynamic Type
Text("Title")
    .font(.headline)

Text("Body text here")
    .font(.body)

// All system text styles scale automatically
```

### Custom Fonts with Dynamic Type

```swift
// ❌ Bad - Fixed size
Text("Custom Title")
    .font(.custom("SF Pro Display", size: 20))

// ✅ Good - Scales with Dynamic Type
Text("Custom Title")
    .font(.custom("SF Pro Display", size: 20, relativeTo: .headline))

// ✅ Alternative approach
Text("Custom Title")
    .font(.custom("SF Pro Display", fixedSize: 20))
    .dynamicTypeSize(.large...(.xxxLarge)) // Limit scaling range if needed
```

### Testing Dynamic Type

```swift
// Test different sizes in preview
struct ExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExpenseView()
                .previewDisplayName("Default")

            ExpenseView()
                .environment(\.sizeCategory, .extraSmall)
                .previewDisplayName("Extra Small")

            ExpenseView()
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("XXXL")
        }
    }
}
```

### Responsive Layouts for Large Text

```swift
// ❌ Bad - Layout breaks with large text
HStack {
    Text("Very long expense name here")
    Spacer()
    Text("$150.00")
}

// ✅ Good - Adaptive layout
ViewThatFits {
    HStack {
        Text(expense.name)
        Spacer()
        Text(expense.formattedAmount)
    }

    VStack(alignment: .leading) {
        Text(expense.name)
        Text(expense.formattedAmount)
    }
}

// ✅ Alternative - Manual check
@Environment(\.sizeCategory) var sizeCategory

var body: some View {
    if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: 4) {
            Text(expense.name)
            Text(expense.formattedAmount)
        }
    } else {
        HStack {
            Text(expense.name)
            Spacer()
            Text(expense.formattedAmount)
        }
    }
}
```

### Dynamic Type Size Categories

```swift
extension DynamicTypeSize {
    var isAccessibilitySize: Bool {
        self >= .accessibility1
    }
}

// Size categories:
// .xSmall
// .small
// .medium (default)
// .large
// .xLarge
// .xxLarge
// .xxxLarge
// .accessibility1
// .accessibility2
// .accessibility3
// .accessibility4
// .accessibility5
```

### Limiting Dynamic Type Range

```swift
// ✅ Limit scaling range when necessary
Text("Icon Label")
    .font(.caption)
    .dynamicTypeSize(.small ... .large)

// ✅ Good for fixed-size UI elements
Button {
    // action
} label: {
    Image(systemName: "plus")
    Text("Add")
        .dynamicTypeSize(.small ... .large) // Keep button compact
}
```

## Font Weights & Styles

### Font Weights

```swift
// Available weights
.font(.body.weight(.ultraLight))
.font(.body.weight(.thin))
.font(.body.weight(.light))
.font(.body.weight(.regular))
.font(.body.weight(.medium))
.font(.body.weight(.semibold))
.font(.body.weight(.bold))
.font(.body.weight(.heavy))
.font(.body.weight(.black))

// Shorthand
.font(.headline.bold())
```

### Font Styles

```swift
// Italic
.font(.body.italic())

// Monospaced
.font(.body.monospaced())

// Monospaced digit (for aligned numbers)
.font(.body.monospacedDigit())

// Small caps
.font(.body.smallCaps())

// Leading (line spacing)
.font(.body.leading(.tight))
.font(.body.leading(.standard))
.font(.body.leading(.loose))
```

### When to Use Font Weights

```swift
// ✅ Use semibold for emphasis
Text("Important Message")
    .font(.body.weight(.semibold))

// ✅ Use bold for strong emphasis
Text("Warning")
    .font(.body.bold())

// ❌ Avoid overuse of heavy weights
Text("Regular text")
    .font(.body.weight(.black)) // Too heavy for body text
```

## Text Formatting

### Line Limit

```swift
// ✅ Limit lines for truncation
Text("Long text here...")
    .lineLimit(2)

// ✅ Single line
Text("Title")
    .lineLimit(1)

// ✅ Unlimited lines (default)
Text("Description")
    .lineLimit(nil)
```

### Truncation Mode

```swift
// Truncate at tail (default)
Text("Very long text...")
    .truncationMode(.tail)

// Truncate at head
Text("...end of text")
    .truncationMode(.head)

// Truncate in middle
Text("Beginning...end")
    .truncationMode(.middle)
```

### Text Alignment

```swift
// Left aligned (default)
Text("Left")
    .multilineTextAlignment(.leading)

// Center aligned
Text("Center")
    .multilineTextAlignment(.center)

// Right aligned
Text("Right")
    .multilineTextAlignment(.trailing)
```

### Text Case

```swift
// Uppercase
Text("title")
    .textCase(.uppercase) // "TITLE"

// Lowercase
Text("TITLE")
    .textCase(.lowercase) // "title"

// None (preserve original)
Text("Title")
    .textCase(nil)
```

## Common Patterns

### Expense Row Typography

```swift
struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(expense.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.formattedAmount)
                    .font(.body.monospacedDigit())
                    .fontWeight(.semibold)

                Text(expense.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

### Section Header

```swift
struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
```

### Empty State Typography

```swift
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Expenses")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first expense to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### Form Label

```swift
struct FormRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
```

## Anti-Patterns

### Fixed Font Sizes

```swift
// ❌ Bad - Doesn't scale
Text("Title")
    .font(.system(size: 18))

// ✅ Good - Scales with Dynamic Type
Text("Title")
    .font(.headline)
```

### Mixing Styles Inconsistently

```swift
// ❌ Bad - Inconsistent hierarchy
VStack {
    Text("Header 1").font(.title)
    Text("Header 2").font(.headline)
    Text("Header 3").font(.title2) // Wrong order
}

// ✅ Good - Consistent hierarchy
VStack {
    Text("Header 1").font(.title)
    Text("Header 2").font(.title2)
    Text("Header 3").font(.headline)
}
```

### Too Many Font Weights

```swift
// ❌ Bad - Visual noise
VStack {
    Text("Title").bold()
    Text("Subtitle").fontWeight(.semibold)
    Text("Description").fontWeight(.medium)
    Text("Footer").bold()
}

// ✅ Good - Clear hierarchy
VStack {
    Text("Title").bold()
    Text("Subtitle").font(.subheadline)
    Text("Description").font(.body)
    Text("Footer").font(.caption).foregroundColor(.secondary)
}
```

### Ignoring Line Limits

```swift
// ❌ Bad - Can overflow
HStack {
    Text("Very long expense name that might wrap")
    Text("$150")
}

// ✅ Good - Controlled truncation
HStack {
    Text("Very long expense name that might wrap")
        .lineLimit(1)
    Spacer()
    Text("$150")
}
```

## Accessibility Considerations

### Text Scaling Checklist

- [ ] All text uses system text styles or custom fonts with `relativeTo:`
- [ ] Layouts adapt to larger text sizes
- [ ] No clipped text at XXXL sizes
- [ ] Critical information visible at all sizes
- [ ] Buttons remain tappable at all sizes

### Color & Contrast

- [ ] Text has sufficient contrast with background
- [ ] Secondary text still readable
- [ ] Don't rely on color alone for meaning

### Testing Tools

**Settings → Accessibility → Display & Text Size:**
- Larger Text
- Bold Text
- Increase Contrast

**Xcode Accessibility Inspector:**
- Text size preview
- Contrast analyzer
- Layout viewer

## Font Naming Conventions

### Variable Names

```swift
// ✅ Clear naming
let titleFont: Font = .headline
let bodyFont: Font = .body
let captionFont: Font = .caption

// ❌ Unclear naming
let font1: Font = .headline
let bigFont: Font = .title
```

### Custom Text Styles

```swift
// ✅ Reusable text styles
struct TextStyles {
    static let pageTitle: Font = .largeTitle.bold()
    static let sectionHeader: Font = .headline
    static let emphasized: Font = .body.weight(.semibold)
    static let metadata: Font = .caption
}

// Usage
Text("Page Title")
    .font(TextStyles.pageTitle)
```

## References

- [Typography - HIG](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Supporting Dynamic Type](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)
- [Text (SwiftUI)](https://developer.apple.com/documentation/swiftui/text)
- [Font (SwiftUI)](https://developer.apple.com/documentation/swiftui/font)
