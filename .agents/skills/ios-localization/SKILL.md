---
name: ios-localization
description: "Implement, review, or improve localization and internationalization in iOS/macOS apps — String Catalogs (.xcstrings), generated localizable symbols, stable key naming, LocalizedStringKey, LocalizedStringResource, pluralization, FormatStyle for numbers/dates/measurements, right-to-left layout, Dynamic Type, and locale-aware formatting. Use when adding multi-language support, setting up String Catalogs, enabling generated symbols for compile-time-safe localization keys, handling plural forms, formatting dates/numbers/currencies for different locales, testing localizations, or making UI work correctly in RTL languages like Arabic and Hebrew."
---

# iOS Localization & Internationalization

Localize Apple-platform apps with String Catalogs, modern string types,
locale-aware formatting, and right-to-left layout.

## Contents

- [String Catalogs and Generated Symbols](#string-catalogs-and-generated-symbols)
- [String Types -- Decision Guide](#string-types-decision-guide)
- [String Interpolation in Localized Strings](#string-interpolation-in-localized-strings)
- [Pluralization](#pluralization)
- [FormatStyle -- Locale-Aware Formatting](#formatstyle-locale-aware-formatting)
- [Right-to-Left (RTL) Layout](#right-to-left-rtl-layout)
- [Common Mistakes](#common-mistakes)
- [Localization Review Checklist](#review-checklist)
- [References](#references)

## String Catalogs and Generated Symbols

String Catalogs are the recommended Xcode 15+ workflow for new localization work. They keep localizable strings, pluralization rules, and device variations together in an Xcode-managed JSON file with a visual editor. Legacy `.strings` and `.stringsdict` files can coexist during migration, but new Swift and SwiftUI code should default to String Catalogs.

**How automatic extraction works:**

Xcode scans for these patterns on each build:

```swift
// SwiftUI -- automatically extracted (LocalizedStringKey)
Text("Welcome back")              // key: "Welcome back"
Label("Settings", systemImage: "gear")
Button("Save") { }
Toggle("Dark Mode", isOn: $dark)

// Programmatic -- automatically extracted
String(localized: "No items found")
LocalizedStringResource("Order placed")

// Plain String: not extracted or localized
let msg = "Hello"
```

Xcode adds discovered keys to the String Catalog automatically. Mark translations as Needs Review, Translated, or Stale in the editor.

For detailed String Catalog workflows, migration, and testing strategies, see [references/string-catalogs.md](references/string-catalogs.md).

Generated symbols are an Xcode 26 typed-access layer on top of String Catalogs;
they do not change the catalog's Xcode 15 availability.

**Enable:** Build Settings > Localization > Generate String Catalog Symbols → `Yes` (on by default in new Xcode 26 projects). Requires catalog format version `1.1`.

**Workflow:** Add a key manually via the (+) button in the String Catalog editor — manual keys have the **Generate Swift Symbol** checkbox enabled by default. Auto-extracted keys can also opt in via Refactor > Convert Strings to Symbols. Use stable manual keys for generated-symbol strings. Avoid source-copy-derived keys for API-facing strings because wording edits can rename generated identifiers and churn call sites.

```swift
// Generated from key "room_available" in Localizable.xcstrings
Text(.roomAvailable)

// Parameterized key "landmarks_count" with %1$(count)lld
Text(.landmarksCount(count: 42))

// Non-default table "Booking.xcstrings"
Text(.Booking.confirmBookingCta)
```

Xcode derives symbol names by camelCasing the key: `settings.notifications.toggle` → `.settingsNotificationsToggle`. You can convert existing extracted strings to symbols via Refactor > Convert Strings to Symbols (reversible).

Generated symbols are `internal`. For cross-module access, create a public wrapper extension. For heavier multi-module setups, use [xcstrings-tool](https://github.com/liamnichols/xcstrings-tool) instead.

For the full generated symbols reference — extraction states, symbol derivation rules, and cross-module patterns — see [references/string-catalogs.md](references/string-catalogs.md).

## String Types -- Decision Guide

| Context | Type | Why |
|---|---|---|
| SwiftUI view text | `LocalizedStringKey` (implicit) | SwiftUI performs lookup |
| View models, services, and errors | `String(localized:)` | Resolves to `String` now |
| App Intents, widgets, deferred system UI | `LocalizedStringResource` | Carries localization until display |
| Non-user-facing logs and analytics | Plain `String` | No localization needed |

### LocalizedStringKey (SwiftUI default)

SwiftUI views accept `LocalizedStringKey` for their text parameters. String literals are implicitly converted -- no extra work needed.

```swift
Text("Welcome back")
Button("Delete") { deleteItem() }
```

Use `LocalizedStringKey` when passing strings directly to SwiftUI view initializers. Do not construct `LocalizedStringKey` manually in most cases.

### String(localized:) -- Modern NSLocalizedString replacement

Use for any localized string outside a SwiftUI view initializer. Returns a plain `String`. The literal/interpolated initializer is available iOS 15+; resolving a `LocalizedStringResource` is iOS 16+.

```swift
let title = String(localized: "Welcome back")
let msg = String(localized: "error.network",
                 defaultValue: "Check your internet connection")
```

For Swift package localization failures, answer with this explicit resource checklist before bundle debugging:
1. `Package.swift` declares `defaultLocalization`.
2. The target `resources` list processes the catalog location, such as `.process("Resources")`.
3. `Localizable.xcstrings` is actually inside that processed target-resource path.
Only after those pass, debug lookup with `bundle: .module` or `Text(..., bundle: .module)`.

Existing `NSLocalizedString` literal keys can still be exported or migrated by Xcode tooling, but new Swift code should prefer `String(localized:)`, SwiftUI literals, `LocalizedStringResource`, or generated symbols.

### LocalizedStringResource -- Pass localization info without resolving

Use when a string must be carried as a localizable value for later resolution, especially for App Intents, widgets, notifications, generated localizable symbols, and system APIs that accept `LocalizedStringResource` directly. Use `String(localized:)` when code needs the resolved string immediately. Available iOS 16+.

```swift
struct OrderCoffeeIntent: AppIntent {
    static var title: LocalizedStringResource = "Order Coffee"
}

func showAlert(title: LocalizedStringResource, message: LocalizedStringResource) {
    let resolved = String(localized: title)
}
```

## String Interpolation in Localized Strings

Interpolated values in localized strings become positional arguments that translators can reorder.

```swift
// English: "Welcome, Alice! You have 3 new messages."
// German:  "Willkommen, Alice! Sie haben 3 neue Nachrichten."
// Japanese: "Alice さん、新しいメッセージが 3 件あります。"
let text = String(localized: "Welcome, \(name)! You have \(count) new messages.")
```

In the String Catalog, this appears with `%@` and `%lld` placeholders that translators can reorder:
- English: `"Welcome, %@! You have %lld new messages."`
- Japanese: `"%@さん、新しいメッセージが%lld件あります。"`

**Type-safe interpolation** (preferred over format specifiers):
```swift
// Interpolation provides type safety
String(localized: "Score: \(score, format: .number)")
String(localized: "Due: \(date, format: .dateTime.month().day())")
```

## Pluralization

String Catalogs handle pluralization natively -- no `.stringsdict` XML required.

### Setup in String Catalog

When a localized string contains an integer interpolation, Xcode detects it and offers plural variants in the String Catalog editor. Supply translations for each CLDR plural category:

| Category | English example | Arabic example |
|----------|----------------|----------------|
| zero | (not used) | 0 items |
| one | 1 item | 1 item |
| two | (not used) | 2 items (dual) |
| few | (not used) | 3-10 items |
| many | (not used) | 11-99 items |
| other | 2+ items | 100+ items |

English uses only `one` and `other`. Arabic uses all six. Always supply `other` as the fallback.

```swift
// Code -- single interpolation triggers plural support
Text("\(unreadCount) unread messages")

// String Catalog entries (English):
//   one:   "%lld unread message"
//   other: "%lld unread messages"
```

### Device Variations

String Catalogs support device-specific text (iPhone vs iPad vs Mac):

```swift
// In String Catalog editor, enable "Vary by Device" for a key
// iPhone: "Tap to continue"
// iPad:   "Tap or click to continue"
// Mac:    "Click to continue"
```

Use Foundation's automatic grammar agreement markup when nearby words must
inflect for a value's number or gender. Preserve the complete inflecting phrase
for translators; see [Automatic Grammar Agreement](https://sosumi.ai/documentation/foundation/automatic-grammar-agreement).

## FormatStyle -- Locale-Aware Formatting

Never hard-code user-facing formats. Use `FormatStyle` and test output under
contrasting locales such as `en_US`, `de_DE`, `ar_SA`, and `ja_JP`.

`ios-localization` owns `FormatStyle` guidance when the issue is locale-aware user-facing display, including numbers, dates, currency, units, names, lists, calendars, separators, and locale preview/testing. For custom `FormatStyle`, `ParseableFormatStyle`, parsing, `Date.IntervalFormatStyle`, `URL.FormatStyle`, or reusable formatter API design, route to `swift-formatstyle`; keep `ios-localization` advice to locale risks and testing unless implementation is explicitly requested.

### Dates

```swift
let now = Date.now

// Preset styles
now.formatted(date: .long, time: .shortened)
// US: "January 15, 2026 at 3:30 PM"
// DE: "15. Januar 2026 um 15:30"
// JP: "2026年1月15日 15:30"

// Component-based
now.formatted(.dateTime.month(.wide).day().year())
// US: "January 15, 2026"

// In SwiftUI
Text(now, format: .dateTime.month().day().year())
```

### Numbers

```swift
let count = 1234567
count.formatted()                     // "1,234,567" (US) / "1.234.567" (DE)
count.formatted(.number.precision(.fractionLength(2)))
count.formatted(.percent)             // For 0.85 -> "85%" (US) / "85 %" (FR)

// Currency
let price = Decimal(29.99)
price.formatted(.currency(code: "USD"))  // "$29.99" (US) / "29,99 $US" (FR)
price.formatted(.currency(code: "EUR"))  // "29,99 EUR" (DE)
```

### Measurements

```swift
let distance = Measurement(value: 5, unit: UnitLength.kilometers)
distance.formatted(.measurement(width: .wide))
// US: "3.1 miles" (auto-converts!) / DE: "5 Kilometer"

let temp = Measurement(value: 22, unit: UnitTemperature.celsius)
temp.formatted(.measurement(width: .abbreviated))
// US: "72 F" (auto-converts!) / FR: "22 C"
```

Load [references/formatstyle-locale.md](references/formatstyle-locale.md) for
duration, names, lists, custom styles, variant matrices, and deeper RTL testing.

## Right-to-Left (RTL) Layout

SwiftUI automatically mirrors layouts for RTL languages (Arabic, Hebrew, Urdu, Persian). Most views require zero changes.

### What SwiftUI auto-mirrors

- `HStack` children reverse order
- `.leading` / `.trailing` alignment and padding swap sides
- `NavigationStack` back button moves to trailing edge
- `List` disclosure indicators flip
- Text alignment follows reading direction

### What needs manual attention

```swift
// Testing RTL in previews
MyView()
    .environment(\.layoutDirection, .rightToLeft)
    .environment(\.locale, Locale(identifier: "ar"))

// Images that should mirror (directional arrows, progress indicators)
Image(systemName: "chevron.right")
    .flipsForRightToLeftLayoutDirection(true)

// Images that should NOT mirror: logos, photos, clocks, music notes

// Forced LTR for specific content (phone numbers, code)
Text("+1 (555) 123-4567")
    .environment(\.layoutDirection, .leftToRight)
```

### Layout rules

- **DO** use `.leading` / `.trailing` -- they auto-flip for RTL
- **DON'T** use `.left` / `.right` -- they are fixed and break RTL
- **DO** use `HStack` / `VStack` -- they respect layout direction
- **DON'T** use absolute `offset(x:)` for directional positioning

## Common Mistakes

### DON'T: Use fixed-width layouts
```swift
// WRONG -- German text is ~30% longer than English
Text(title).frame(width: 120)
```

### DO: Use flexible layouts
```swift
// CORRECT
Text(title).fixedSize(horizontal: false, vertical: true)
// Or use VStack/wrapping that accommodates expansion
```

### DON'T: Skip pseudolocalization testing
Testing only in English hides truncation, layout, and RTL bugs.

### DO: Test with German (long) and Arabic (RTL) at minimum
Use Xcode scheme settings to override the app language without changing device locale.

## Review Checklist

- [ ] All user-facing strings use localization (`LocalizedStringKey` in SwiftUI or `String(localized:)`)
- [ ] No string concatenation for user-visible text
- [ ] Dates and numbers use `FormatStyle`, not hardcoded formats
- [ ] Pluralization handled via String Catalog plural variants (not manual if/else)
- [ ] Layout uses `.leading` / `.trailing`, not `.left` / `.right`
- [ ] UI tested with long text (German) and RTL (Arabic)
- [ ] String Catalog includes all target languages
- [ ] Images needing RTL mirroring use `.flipsForRightToLeftLayoutDirection(true)`
- [ ] App Intents and widgets use `LocalizedStringResource`
- [ ] No `NSLocalizedString` usage in new code
- [ ] Comments provided for ambiguous keys (context for translators)
- [ ] `@ScaledMetric` used for spacing that must scale with Dynamic Type
- [ ] Currency formatting uses explicit currency code, not locale default
- [ ] Pseudolocalization tested (accented, right-to-left, double-length)
- [ ] Manually-managed keys use stable symbol-style names, not English text as the key
- [ ] Generate String Catalog Symbols enabled for targets with manually-managed keys
- [ ] Ensure localized string types are Sendable; use @MainActor for locale-change UI updates

## References

- FormatStyle patterns: [references/formatstyle-locale.md](references/formatstyle-locale.md)
- String Catalogs guide: [references/string-catalogs.md](references/string-catalogs.md)
