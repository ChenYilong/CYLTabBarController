# FormatStyle & Locale-Aware Formatting

Comprehensive reference for locale-aware formatting in iOS 15+ using `FormatStyle`. Never hard-code date, number, or measurement formats -- these break in every locale except the one you tested. `ios-localization` owns `FormatStyle` guidance when the issue is locale-aware user-facing display: numbers, dates, currency, units, names, lists, calendars, separators, and locale preview/testing. Locale-aware formatting matters even in single-language apps; explicitly recommend testing or previewing user-facing output under multiple locales. Use the `swift-formatstyle` skill for broader standalone FormatStyle API design.

## Contents

- [Date Formatting](#date-formatting)
- [Number Formatting](#number-formatting)
- [Measurement Formatting](#measurement-formatting)
- [Duration Formatting](#duration-formatting)
- [PersonNameComponents Formatting](#personnamecomponents-formatting)
- [ByteCountFormatStyle](#bytecountformatstyle)
- [ListFormatStyle](#listformatstyle)
- [Custom FormatStyle Implementation](#custom-formatstyle-implementation)
- [Forcing a Specific Locale](#forcing-a-specific-locale)
- [RTL Layout Deep Dive](#rtl-layout-deep-dive)
- [`@ScaledMetric for Dynamic Type`](#scaledmetric-for-dynamic-type)
- [Layout Testing with Accessibility Inspector](#layout-testing-with-accessibility-inspector)
- [Quick Reference Table](#quick-reference-table)

## Migration from Legacy Formatters

`FormatStyle` (iOS 15+) replaces the older `Formatter` subclasses. If you encounter legacy code, migrate to `FormatStyle`:

| Legacy | Modern replacement |
|--------|-------------------|
| `DateFormatter` | `.formatted(.dateTime...)` or `Date.FormatStyle` |
| `NumberFormatter` | `.formatted(.number...)` or `IntegerFormatStyle` / `FloatingPointFormatStyle` |
| `DateComponentsFormatter` | `Duration.formatted(.units(...))` or `.time(pattern:)` |
| `MeasurementFormatter` | `Measurement.formatted(.measurement(...))` |
| `DateIntervalFormatter` | `(start..<end).formatted(date:time:)` |
| `PersonNameComponentsFormatter` | `.formatted(.name(style:))` |
| `ByteCountFormatter` | `.formatted(.byteCount(style:))` |
| `ListFormatter` | `.formatted(.list(type:))` |

`FormatStyle` is value-type, `Sendable`, composable, and works directly in SwiftUI `Text` views. The legacy formatters are reference types that require manual locale and calendar configuration.

## Date Formatting

### Preset date and time styles

```swift
let date = Date.now

// Date only
date.formatted(date: .numeric, time: .omitted)      // "1/15/2026" (US) / "15.01.2026" (DE)
date.formatted(date: .abbreviated, time: .omitted)   // "Jan 15, 2026" (US) / "15. Jan. 2026" (DE)
date.formatted(date: .long, time: .omitted)          // "January 15, 2026" (US) / "15. Januar 2026" (DE)
date.formatted(date: .complete, time: .omitted)      // "Thursday, January 15, 2026" (US)

// Time only
date.formatted(date: .omitted, time: .shortened)     // "3:30 PM" (US) / "15:30" (DE)
date.formatted(date: .omitted, time: .standard)      // "3:30:45 PM" (US) / "15:30:45" (DE)
date.formatted(date: .omitted, time: .complete)       // includes time zone

// Combined
date.formatted(date: .long, time: .shortened)         // "January 15, 2026 at 3:30 PM"
date.formatted()                                       // platform default
```

### Component-based date formatting

Build custom date formats by composing components. The system reorders components for each locale.

```swift
// Month and day
date.formatted(.dateTime.month().day())               // "Jan 15" (US) / "15 Jan" (UK)

// Full date with weekday
date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
// "Thursday, January 15, 2026" (US) / "Donnerstag, 15. Januar 2026" (DE)

// Month name styles
date.formatted(.dateTime.month(.wide))                // "January"
date.formatted(.dateTime.month(.abbreviated))         // "Jan"
date.formatted(.dateTime.month(.narrow))              // "J"
date.formatted(.dateTime.month(.twoDigits))           // "01"

// Day styles
date.formatted(.dateTime.day(.twoDigits))             // "15"
date.formatted(.dateTime.day(.ordinalOfDayInMonth))   // "3" (third Thursday)

// Year
date.formatted(.dateTime.year(.defaultDigits))        // "2026"
date.formatted(.dateTime.year(.twoDigits))            // "26"

// Hour/minute
date.formatted(.dateTime.hour().minute())             // "3:30 PM" (US, 12h) / "15:30" (DE, 24h)
date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute())  // "3:30"
```

### SwiftUI date display

```swift
// Automatic format
Text(event.date, format: .dateTime.month().day().year())

// Date range
Text(event.start...event.end)   // "Jan 15 - Jan 20, 2026"

// Relative (auto-updates)
Text(event.date, style: .relative)   // "2 hours ago", "in 3 days"
Text(event.date, style: .timer)      // counts up/down live
Text(event.date, style: .offset)     // "+2 hours" / "-3 days"
```

### Relative date formatting

```swift
// Relative (named style)
let relative = date.formatted(.relative(presentation: .named))
// "yesterday", "today", "tomorrow", "last Friday", "in 2 weeks"

// Relative (numeric style)
let relativeNum = date.formatted(.relative(presentation: .numeric))
// "1 day ago", "in 2 days", "3 weeks ago"

// Relative with specific units
let relativeCustom = date.formatted(.relative(presentation: .named, unitsStyle: .wide))
```

### Date ranges and intervals

```swift
let start = Date.now
let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!

// Range formatting
(start..<end).formatted(date: .abbreviated, time: .omitted)
// "Jan 15 - 20, 2026" (smart about shared month/year)

// Duration of interval
(start..<end).formatted(.components(style: .wide))
// "5 days"
```

### ISO 8601 (for APIs, not for display)

```swift
// For serialization to APIs -- NOT for user-facing display
date.formatted(.iso8601)                              // "2026-01-15T15:30:45Z"
date.formatted(.iso8601.dateSeparator(.dash).timeSeparator(.colon))
```

## Number Formatting

### Integer and decimal

```swift
let value = 1234567

value.formatted()                                      // "1,234,567" (US) / "1.234.567" (DE) / "1 234 567" (FR)
value.formatted(.number.grouping(.never))              // "1234567"
value.formatted(.number.precision(.significantDigits(3))) // "1,230,000"

let decimal = 3.14159
decimal.formatted(.number.precision(.fractionLength(2)))  // "3.14"
decimal.formatted(.number.precision(.fractionLength(0...3))) // "3.142"

// Notation
value.formatted(.number.notation(.compactName))        // "1.2M" (US) / "1,2 Mio." (DE)
value.formatted(.number.notation(.scientific))         // "1.234567E6"
```

### Rounding

```swift
let num = 3.456

// Round to 2 fraction digits
num.formatted(.number.precision(.fractionLength(2)).rounded(rule: .up))     // "3.46"
num.formatted(.number.precision(.fractionLength(2)).rounded(rule: .down))   // "3.45"
num.formatted(.number.precision(.fractionLength(2)).rounded(rule: .toNearestOrEven)) // "3.46"
```

### Percent

```swift
let ratio = 0.856

ratio.formatted(.percent)                              // "86%" (US) / "86 %" (FR)
ratio.formatted(.percent.precision(.fractionLength(1))) // "85.6%"

// Integer percentage
let score = 92
score.formatted(.percent)                              // "9,200%" -- probably not what you want!
// For integer percentages, divide first:
(Double(score) / 100).formatted(.percent)              // "92%"
```

### Currency

Always specify the currency code explicitly. The locale controls formatting (symbol position, decimal separator), but the currency code determines the currency.

```swift
let price = Decimal(29.99)

// Explicit currency code (recommended)
price.formatted(.currency(code: "USD"))                // "$29.99" (US) / "29,99 $US" (FR) / "US$29.99" (AU)
price.formatted(.currency(code: "EUR"))                // "EUR29.99" (US) / "29,99 EUR" (DE) / "29,99 EUR" (FR)
price.formatted(.currency(code: "JPY"))                // "JPY30" (no decimals for yen)

// Narrow symbol (when space is limited)
price.formatted(.currency(code: "USD").presentation(.narrow))  // "$29.99" even in non-US locales

// In SwiftUI
Text(price, format: .currency(code: order.currencyCode))
```

**Important:** Use `Decimal` (not `Double`) for monetary values to avoid floating-point precision errors.

### Ordinal numbers

```swift
let position = 3
position.formatted(.number.notation(.ordinal))         // "3rd" (EN) / "3." (DE) / "3e" (FR)
```

## Measurement Formatting

The system auto-converts units based on locale (metric vs imperial) unless you opt out.

### Length / distance

```swift
let distance = Measurement(value: 5, unit: UnitLength.kilometers)

distance.formatted(.measurement(width: .wide))
// US: "3.1 miles"  (auto-converts to imperial!)
// DE: "5 Kilometer"
// JP: "5 km" (with .abbreviated)

distance.formatted(.measurement(width: .abbreviated))  // "3.1 mi" (US) / "5 km" (DE)
distance.formatted(.measurement(width: .narrow))       // "3.1mi" (US) / "5km" (DE)

// Prevent auto-conversion (keep original unit)
distance.formatted(.measurement(width: .wide, usage: .asProvided))
// US: "5 kilometers" (keeps km even in US locale)
```

### Weight / mass

```swift
let weight = Measurement(value: 75, unit: UnitMass.kilograms)

weight.formatted(.measurement(width: .wide))
// US: "165.3 pounds" / DE: "75 Kilogramm"

weight.formatted(.measurement(width: .abbreviated, usage: .personWeight))
// Uses locale-appropriate unit for body weight
```

### Temperature

```swift
let temp = Measurement(value: 22, unit: UnitTemperature.celsius)

temp.formatted(.measurement(width: .abbreviated))
// US: "72 F" (auto-converts!) / FR: "22 C" / DE: "22 C"

// Weather-specific (ensures locale-correct unit)
temp.formatted(.measurement(width: .abbreviated, usage: .weather))
```

### Speed

```swift
let speed = Measurement(value: 100, unit: UnitSpeed.kilometersPerHour)
speed.formatted(.measurement(width: .abbreviated))
// US: "62.1 mph" / DE: "100 km/h"
```

### Volume

```swift
let volume = Measurement(value: 500, unit: UnitVolume.milliliters)
volume.formatted(.measurement(width: .abbreviated, usage: .drink))
// US: "16.9 fl oz" / DE: "500 ml"
```

## Duration Formatting

### Time pattern

```swift
let dur = Duration.seconds(3661) // 1 hour, 1 minute, 1 second

dur.formatted(.time(pattern: .hourMinuteSecond))       // "1:01:01"
dur.formatted(.time(pattern: .hourMinute))             // "1:01"
dur.formatted(.time(pattern: .minuteSecond))           // "61:01"
```

### Units style (iOS 16+)

```swift
dur.formatted(.units(allowed: [.hours, .minutes], width: .wide))
// "1 hour, 1 minute" (EN) / "1 Stunde, 1 Minute" (DE)

dur.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
// "1 hr, 1 min" (EN) / "1 Std., 1 Min." (DE)

dur.formatted(.units(allowed: [.hours, .minutes], width: .narrow))
// "1h 1m"

// Maximum unit count
dur.formatted(.units(allowed: [.hours, .minutes, .seconds],
                     width: .abbreviated,
                     maximumUnitCount: 2))
// "1 hr, 1 min" (drops seconds)
```

## PersonNameComponents Formatting

Respects locale conventions for name ordering (given-family vs family-given).

```swift
var name = PersonNameComponents()
name.givenName = "John"
name.familyName = "Appleseed"
name.namePrefix = "Dr."
name.nickname = "Johnny"

name.formatted(.name(style: .long))        // "Dr. John Appleseed" (US) / "Appleseed John" (JP)
name.formatted(.name(style: .medium))      // "John Appleseed" (US) / "Appleseed John" (JP)
name.formatted(.name(style: .short))       // "John" (US) / "Appleseed" (JP)
name.formatted(.name(style: .abbreviated)) // "JA" (initials)

// In SwiftUI
Text(name, format: .name(style: .medium))
```

## ByteCountFormatStyle

Format file sizes with locale-appropriate units.

```swift
let bytes: Int64 = 1_536_000

bytes.formatted(.byteCount(style: .file))      // "1.5 MB"
bytes.formatted(.byteCount(style: .memory))    // "1.46 MB" (uses 1024-based)
bytes.formatted(.byteCount(style: .binary))    // "1.46 MB"

// Specific allowed units
bytes.formatted(.byteCount(style: .file, allowedUnits: [.kb]))  // "1,536 kB"
```

## ListFormatStyle

Join arrays into grammatically correct lists.

```swift
let fruits = ["Apples", "Oranges", "Bananas"]

fruits.formatted(.list(type: .and))
// EN: "Apples, Oranges, and Bananas"
// FR: "Apples, Oranges et Bananas"
// AR: "Apples وOranges وBananas"

fruits.formatted(.list(type: .or))
// EN: "Apples, Oranges, or Bananas"

// With member formatting
let prices = [Decimal(1.99), Decimal(2.49), Decimal(3.99)]
prices.formatted(.list(memberStyle: .currency(code: "USD"), type: .and))
// "$1.99, $2.49, and $3.99"

// Two items
["Red", "Blue"].formatted(.list(type: .and))
// "Red and Blue" (no Oxford comma for two items)
```

## Custom FormatStyle Implementation

Create a reusable `FormatStyle` for domain-specific formatting.

```swift
struct AbbreviatedCountStyle: FormatStyle {
    func format(_ value: Int) -> String {
        switch value {
        case ..<1_000:
            return "\(value)"
        case 1_000..<1_000_000:
            let k = Double(value) / 1_000.0
            return k.formatted(.number.precision(.fractionLength(0...1))) + "K"
        case 1_000_000..<1_000_000_000:
            let m = Double(value) / 1_000_000.0
            return m.formatted(.number.precision(.fractionLength(0...1))) + "M"
        default:
            let b = Double(value) / 1_000_000_000.0
            return b.formatted(.number.precision(.fractionLength(0...1))) + "B"
        }
    }
}

extension FormatStyle where Self == AbbreviatedCountStyle {
    static var abbreviatedCount: AbbreviatedCountStyle { .init() }
}

// Usage
let followers = 12_500
followers.formatted(.abbreviatedCount)  // "12.5K"

// In SwiftUI
Text(followers, format: .abbreviatedCount)
```

### Custom ParseableFormatStyle (for input parsing)

```swift
struct AbbreviatedCountStyle: ParseableFormatStyle {
    var parseStrategy: AbbreviatedCountParseStrategy { .init() }

    func format(_ value: Int) -> String { /* same as above */ }
}

struct AbbreviatedCountParseStrategy: ParseStrategy {
    func parse(_ value: String) throws -> Int {
        let cleaned = value.uppercased().trimmingCharacters(in: .whitespaces)
        if cleaned.hasSuffix("K") {
            guard let num = Double(cleaned.dropLast()) else { throw parseError }
            return Int(num * 1_000)
        }
        // ... handle M, B, plain numbers
        guard let num = Int(cleaned) else { throw parseError }
        return num
    }

    private var parseError: some Error {
        DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid count"))
    }
}
```

## Forcing a Specific Locale

Occasionally you need a specific locale (server APIs, fixed-format exports). Use `.locale()` modifier:

```swift
// Force US format for API serialization (not user display)
let usPrice = price.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))

// Force a date format for an API
let apiDate = date.formatted(.iso8601)  // Prefer ISO 8601 for APIs

// Force German format for a German-language PDF export
let deDate = date.formatted(.dateTime.month(.wide).day().year().locale(Locale(identifier: "de_DE")))
```

**Warning:** Never force a locale for user-facing UI. Always let the system locale drive user-visible formatting.

## RTL Layout Deep Dive

### How SwiftUI auto-mirrors

SwiftUI respects `layoutDirection` from the environment. When the user's language is RTL:

1. **HStack**: Children render right-to-left
2. **Leading/Trailing**: `.leading` = right side, `.trailing` = left side
3. **Padding**: `.padding(.leading, 16)` applies to right side
4. **NavigationStack**: Back button appears on trailing (left) side
5. **Lists**: Disclosure chevrons point left
6. **ScrollView**: Horizontal scrolling starts from the right
7. **Text alignment**: Default alignment follows reading direction

### Image flipping

```swift
// Directional images SHOULD flip
Image(systemName: "chevron.forward")
    .flipsForRightToLeftLayoutDirection(true)

Image(systemName: "arrow.right")
    .flipsForRightToLeftLayoutDirection(true)

Image("progress-arrow")
    .flipsForRightToLeftLayoutDirection(true)

// These should NOT flip:
// - Logos and brand marks
// - Photos and illustrations
// - Clock faces (clockwise is universal)
// - Music notation
// - Checkmarks
// - Mathematical symbols (+, -, =)
// - Media playback controls (play triangle always points right)

// SF Symbols with .rtl variant auto-flip (e.g., text.alignleft has text.alignright)
// Check SF Symbols app for RTL variants
```

### Environment-based testing

```swift
// Preview with RTL
#Preview("Arabic RTL") {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
}

// Preview with both directions side by side
#Preview("LTR vs RTL") {
    HStack(spacing: 0) {
        ContentView()
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity)
        Divider()
        ContentView()
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "ar"))
            .frame(maxWidth: .infinity)
    }
}
```

### Semantic content attributes (UIKit interop)

When mixing UIKit views via `UIViewRepresentable`, set semantic content attribute:

```swift
class MyUIView: UIView {
    override var semanticContentAttribute: UISemanticContentAttribute {
        // .forceLeftToRight for phone numbers, code
        // .forceRightToLeft to force RTL
        // .unspecified to follow system (default)
        .unspecified
    }
}
```

### Bidirectional text

When mixing LTR and RTL text (e.g., English brand names in Arabic text), Unicode bidirectional algorithm handles it automatically. For edge cases:

```swift
// Force LTR for specific content within RTL context
Text("\u{200E}+1 (555) 123-4567")  // LTR mark before phone number

// Or use environment override on a specific view
Text(phoneNumber)
    .environment(\.layoutDirection, .leftToRight)
```

### Common RTL pitfalls

| Issue | Wrong | Correct |
|-------|-------|---------|
| Fixed position | `.padding(.left, 16)` | `.padding(.leading, 16)` |
| Absolute offset | `.offset(x: -20)` for "move left" | Use alignment or `.padding(.trailing)` |
| Text alignment | `.multilineTextAlignment(.left)` | `.multilineTextAlignment(.leading)` |
| Corner radius | Only rounding top-left/top-right | Round leading/trailing corners |
| Swipe gestures | "Swipe right to delete" | "Swipe to leading edge" -- or use system gestures |

## `@ScaledMetric` for Dynamic Type

Use `@ScaledMetric` to make custom spacing, icon sizes, and padding scale with the user's Dynamic Type setting.

```swift
struct ProfileRow: View {
    @ScaledMetric(relativeTo: .body) private var avatarSize = 44.0
    @ScaledMetric(relativeTo: .body) private var spacing = 12.0

    var body: some View {
        HStack(spacing: spacing) {
            AvatarView()
                .frame(width: avatarSize, height: avatarSize)
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(subtitle).font(.subheadline)
            }
        }
    }
}
```

### relativeTo parameter

`@ScaledMetric` scales proportionally to a text style. Choose the text style that the metric logically accompanies:

| Text style | Base size | Use for |
|------------|-----------|---------|
| `.body` | 17pt | General spacing, icons next to body text |
| `.caption` | 12pt | Small icons, fine spacing |
| `.title` | 28pt | Large icons, hero spacing |
| `.largeTitle` | 34pt | Hero images, splash elements |

### Testing Dynamic Type

```swift
// Preview with large text
#Preview("Accessibility XXL") {
    ContentView()
        .dynamicTypeSize(.accessibility3)
}

// Preview matrix
#Preview("Dynamic Type Sizes") {
    ScrollView {
        ForEach(DynamicTypeSize.allCases, id: \.self) { size in
            ContentView()
                .dynamicTypeSize(size)
                .padding()
                .border(Color.gray)
        }
    }
}
```

## Layout Testing with Accessibility Inspector

Accessibility Inspector (Xcode > Open Developer Tool > Accessibility Inspector) provides:

1. **Audit**: Scans running app for accessibility issues including truncated text
2. **Inspection**: Shows exact font sizes and Dynamic Type response
3. **Settings**: Override Dynamic Type size, Bold Text, Reduce Motion on device without changing system settings

### Quick test workflow

1. Launch app in Simulator
2. Open Accessibility Inspector, target the Simulator
3. Use the Settings panel to set Dynamic Type to "Accessibility XXL"
4. Navigate through every screen -- look for truncated text, overlapping elements, broken layouts
5. Switch to RTL (set language to Arabic in scheme options)
6. Repeat navigation -- check all alignment and reading order

## Quick Reference Table

| Data type | FormatStyle | Example output (US) |
|-----------|-------------|---------------------|
| `Date` | `.dateTime.month().day().year()` | "Jan 15, 2026" |
| `Date` range | `(start..<end).formatted(date:time:)` | "Jan 15 - 20, 2026" |
| `Date` relative | `.relative(presentation: .named)` | "yesterday" |
| `Int` | `.number` | "1,234,567" |
| `Int` ordinal | `.number.notation(.ordinal)` | "3rd" |
| `Int` compact | `.number.notation(.compactName)` | "1.2M" |
| `Double` | `.number.precision(.fractionLength(2))` | "3.14" |
| `Double` | `.percent` | "85.6%" |
| `Decimal` | `.currency(code: "USD")` | "$29.99" |
| `Measurement` | `.measurement(width: .abbreviated)` | "5 km" / "3.1 mi" |
| `Duration` | `.time(pattern: .hourMinuteSecond)` | "1:01:01" |
| `Duration` | `.units(width: .abbreviated)` | "1 hr, 1 min" |
| `PersonNameComponents` | `.name(style: .medium)` | "John Doe" |
| `Int64` (bytes) | `.byteCount(style: .file)` | "1.5 MB" |
| `[String]` | `.list(type: .and)` | "A, B, and C" |
