# String Catalogs (.xcstrings) -- Detailed Reference

## Contents

- [What is a String Catalog?](#what-is-a-string-catalog)
- [Creating a String Catalog](#creating-a-string-catalog)
- [Automatic String Extraction](#automatic-string-extraction)
- [Manual Key Management](#manual-key-management)
- [Handling Strings in Non-SwiftUI Code](#handling-strings-in-non-swiftui-code)
- [Bundle Access Patterns](#bundle-access-patterns)
- [Multi-Module / SPM Localization](#multi-module-spm-localization)
- [Pluralization in String Catalogs](#pluralization-in-string-catalogs)
- [Device Variations](#device-variations)
- [Exporting for Translators (XLIFF / xcloc)](#exporting-for-translators-xliff-xcloc)
- [String Catalog JSON Structure](#string-catalog-json-structure)
- [Generated Localizable Symbols (Xcode 26+)](#generated-localizable-symbols-xcode-26)
- [Testing Strategies](#testing-strategies)
- [Migration from .strings / .stringsdict](#migration-from-strings-stringsdict)
- [Best Practices](#best-practices)

## What is a String Catalog?

A String Catalog is a single Xcode-managed `.xcstrings` file (JSON-based) that holds localizable strings in a target, along with translations, plural forms, and device variations. In Xcode 15 and later, String Catalogs are the recommended workflow for new localization work because they replace much of the manual synchronization previously required across `.strings` and `.stringsdict` files.

**Availability:** Xcode 15+, all Apple platforms. String Catalogs are the recommended Xcode 15+ workflow for app localization. Xcode 26 adds generated localizable symbols on top of String Catalogs; do not describe catalogs themselves as requiring Xcode 26 or iOS 17.

## Creating a String Catalog

1. File > New > File > String Catalog
2. Name it `Localizable.xcstrings` (the default table name, matching the legacy `Localizable.strings`)
3. Place it in the target's source directory
4. Add target languages in Project > Info > Localizations

For a non-default table name (e.g., `Onboarding.xcstrings`), reference it explicitly:

```swift
String(localized: "welcome.title", table: "Onboarding")
```

## Automatic String Extraction

On every build, Xcode scans source files and extracts strings from known localizable initializers. Extraction is compiler-driven -- it recognizes these patterns:

### SwiftUI (LocalizedStringKey)
```swift
Text("Hello, world")                        // extracted
Label("Settings", systemImage: "gear")      // extracted
Button("Save") { }                          // extracted
Toggle("Enable notifications", isOn: $on)   // extracted
.navigationTitle("Home")                     // extracted
Section("Account") { }                      // extracted

// NOT extracted -- computed or variable strings
Text(viewModel.title)                       // not extracted (runtime value)
Text(verbatim: "v1.2.3")                    // not extracted (verbatim skips localization)
```

### Foundation (String(localized:))
```swift
String(localized: "No results found")               // extracted
String(localized: "error.title",
       defaultValue: "Something went wrong",
       comment: "Generic error alert title")         // extracted with default + comment
```

### LocalizedStringResource
```swift
LocalizedStringResource("Order placed")              // extracted
static var title: LocalizedStringResource = "Title"  // extracted
```

### What is NOT extracted
```swift
let x: String = "Not localized"          // plain String assignment
print("debug info")                      // not user-facing
NSLocalizedString("legacy", comment: "") // legacy API; Xcode can export literal keys
```

Prefer `String(localized:)`, SwiftUI localizable literals, or `LocalizedStringResource` in new Swift code so String Catalog syncing and generated-symbol workflows stay straightforward. If automatic extraction misses a string, add it manually in the String Catalog editor.

## Manual Key Management

Open the `.xcstrings` file in Xcode to use the visual editor:

- **Add key**: Click + at the bottom of the key list
- **Remove key**: Select key, press Delete (marks as Stale, removed on next build if no code reference)
- **Edit comment**: Select key, edit the Comment field (provides translator context)
- **Mark state**: Right-click a translation to set Needs Review / Reviewed
- **Vary by plural**: Select a key, click Vary > Plural to add plural categories
- **Vary by device**: Select a key, click Vary > Device to add iPhone/iPad/Mac variants

### Key naming conventions

For manually-managed strings, use stable symbol-style keys rather than English text as the key. This prevents silent localization breaks when UI copy changes (a typo or rewording just creates a new key and stales the old one — no compiler error). With Xcode 26's generated symbols, stable keys also produce readable, predictable Swift accessors.

```text
onboarding.welcome.title        -> "Welcome"
onboarding.welcome.subtitle     -> "Get started in minutes"
settings.notifications.toggle   -> "Enable Notifications"
error.network.title             -> "Connection Error"
error.network.message           -> "Check your internet and try again"
```

Use `String(localized:defaultValue:)` when you want a structured key that differs from the English text:

```swift
let title = String(localized: "error.network.title",
                   defaultValue: "Connection Error",
                   comment: "Title for network error alert")
```

For SwiftUI auto-extracted strings, the literal text IS the key by default. This is fine for simple views. For any string you manage manually — shared keys, keys referenced across modules, or keys where copy changes frequently — use a stable key instead.

## Handling Strings in Non-SwiftUI Code

### View models, services, and utilities

```swift
class OrderService {
    func statusMessage(for order: Order) -> String {
        switch order.status {
        case .shipped:
            return String(localized: "order.status.shipped",
                          defaultValue: "Your order has shipped!",
                          comment: "Order status when item is in transit")
        case .delivered:
            return String(localized: "order.status.delivered",
                          defaultValue: "Delivered on \(order.deliveryDate!, format: .dateTime.month().day())",
                          comment: "Order status with delivery date")
        case .processing:
            return String(localized: "order.status.processing",
                          defaultValue: "Processing your order...",
                          comment: "Order status while being prepared")
        }
    }
}
```

### Specifying table and bundle

```swift
// From a specific table
String(localized: "greeting",
       table: "Onboarding",
       comment: "First-launch greeting")

// From a specific bundle (framework or Swift package)
String(localized: "button.save",
       table: "SharedUI",
       bundle: .module,
       comment: "Save button in shared component")
```

## Bundle Access Patterns

### Main app
```swift
// Uses Bundle.main by default -- no bundle argument needed
String(localized: "Hello")
```

### Swift Package (SPM)
```swift
// .module refers to the package's resource bundle
String(localized: "Hello", bundle: .module)

// In SwiftUI, pass the package bundle explicitly for package resources
Text("Hello", bundle: .module)
```

### Framework
```swift
// Reference the framework's bundle
let frameworkBundle = Bundle(for: MyFrameworkClass.self)
String(localized: "Hello",
       bundle: .init(frameworkBundle.bundleURL))
```

## Multi-Module / SPM Localization

Each Swift package target that contains user-facing strings needs its own String Catalog.

### Package.swift setup
```swift
let package = Package(
    name: "SharedUI",
    defaultLocalization: "en",
    targets: [
        .target(
            name: "SharedUI",
            dependencies: [],
            resources: [
                .process("Resources")  // Localizable.xcstrings goes here
            ]
        )
    ]
)
```

### Directory structure
```text
Sources/
  SharedUI/
    Resources/
      Localizable.xcstrings    <- String Catalog for this module
    Views/
      ButtonStyles.swift
```

### Accessing strings from the package
```swift
// Inside the package -- bundle: .module resolves package-owned resources
public struct SaveButton: View {
    public var body: some View {
        Button(String(localized: "Save", bundle: .module)) { }
    }
}
```

**Important:** Code outside the main app bundle needs an explicit bundle. Use `bundle: .module` in Swift packages, `Bundle(for:)` in frameworks, or the current-target bundle macro when available.

For Swift package localization failures, answer with this explicit resource checklist before bundle debugging:
1. `Package.swift` declares `defaultLocalization`.
2. The target `resources` list processes the catalog location, such as `.process("Resources")`.
3. `Localizable.xcstrings` is actually inside that processed target-resource path.
Only after those pass, debug lookup with `bundle: .module` or `Text(..., bundle: .module)`.

## Pluralization in String Catalogs

### Setup

1. Write code with integer interpolation:
   ```swift
   Text("\(itemCount) items in your cart")
   ```
2. Build the project -- Xcode adds the key to the String Catalog
3. Open the String Catalog, select the key
4. Click "Vary by Plural" in the inspector
5. Fill in plural forms for each language

### English plural forms
```text
one:   "%1$(itemCount)lld item in your cart"
other: "%1$(itemCount)lld items in your cart"
```

### Arabic plural forms (all six categories)
```text
zero:  "لا توجد عناصر في سلتك"
one:   "عنصر واحد في سلتك"
two:   "عنصران في سلتك"
few:   "%lld عناصر في سلتك"        (3-10)
many:  "%lld عنصرًا في سلتك"       (11-99)
other: "%lld عنصر في سلتك"         (100+)
```

### Multiple plural variables

When a string has two integer interpolations, the String Catalog shows a matrix of plural combinations:

```swift
Text("\(photoCount) photos in \(albumCount) albums")
// English needs: one/one, one/other, other/one, other/other
```

## Device Variations

Enable "Vary by Device" for a key to provide different text on iPhone, iPad, Apple Watch, Mac, Apple TV, and Apple Vision Pro.

```swift
// Code is the same everywhere:
Text("Tap to continue")

// String Catalog provides:
// iPhone: "Tap to continue"
// iPad:   "Tap or click to continue"
// Mac:    "Click to continue"
// Vision: "Look and tap to continue"
```

## Exporting for Translators (XLIFF / xcloc)

### Export

1. Product > Export Localizations... (or `xcodebuild -exportLocalizations`)
2. Select target languages
3. Xcode creates `.xcloc` bundles (one per language)
4. Send `.xcloc` files to translators (they contain XLIFF 1.2 inside)

### Command-line export
```bash
xcodebuild -exportLocalizations \
    -project MyApp.xcodeproj \
    -localizationPath ./Localizations \
    -exportLanguage de -exportLanguage ja -exportLanguage ar
```

### Import

1. Product > Import Localizations...
2. Select the completed `.xcloc` file
3. Xcode merges translations into the String Catalog
4. Review changes in the diff viewer

### Command-line import
```bash
xcodebuild -importLocalizations \
    -project MyApp.xcodeproj \
    -localizationPath ./Localizations/de.xcloc
```

## String Catalog JSON Structure

The `.xcstrings` file is Xcode-managed JSON. Understanding the observed structure can help with parser-backed validation or careful batch updates, but prefer Xcode's editor/export/import workflows for normal localization changes and validate any automated edit before committing.

```json
{
  "sourceLanguage": "en",
  "version": "1.0",
  "strings": {
    "Welcome, %@!": {
      "comment": "Greeting shown on home screen with user name",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Welcome, %@!"
          }
        },
        "de": {
          "stringUnit": {
            "state": "translated",
            "value": "Willkommen, %@!"
          }
        }
      }
    },
    "room_available": {
      "comment": "Button label on room search results",
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Book this room"
          }
        }
      }
    },
    "%1$(count)lld items": {
      "localizations": {
        "en": {
          "variations": {
            "plural": {
              "one": {
                "stringUnit": {
                  "state": "translated",
                  "value": "%1$(count)lld item"
                }
              },
              "other": {
                "stringUnit": {
                  "state": "translated",
                  "value": "%1$(count)lld items"
                }
              }
            }
          }
        }
      }
    }
  }
}
```

Note the `"room_available"` key above: it uses `"extractionState": "manual"` and a stable symbol-style key with the English text in `"value"`, not in the key itself. Use stable manual keys for generated-symbol strings. Avoid source-copy-derived keys for API-facing strings because wording edits can rename generated identifiers and churn call sites.

### Translation states
- `"new"` -- Xcode extracted the key but no translation exists
- `"translated"` -- Translation provided
- `"needs_review"` -- Marked for review (source string changed or manual flag)
- `"stale"` -- Key no longer found in code (removed on next clean build)

### Extraction states

The `extractionState` field (separate from translation `state`) tracks how a key entered the catalog:

| Value | Meaning |
|-------|---------|
| `extracted_with_value` | Xcode found the string in source code and extracted it automatically |
| `manual` | Added by hand via the (+) button — not discovered from code. Xcode will never update or remove manual keys during build sync |
| `stale` | Previously extracted from code, but Xcode can no longer find it. Orphaned translations still exist |
| `migrated` | Converted from a legacy `.strings` or `.stringsdict` file |

The `manual` state is significant: manual keys have the **Generate Swift Symbol** checkbox enabled by default, so they automatically produce compiler-checked `LocalizedStringResource` accessors when the build setting is on. Auto-extracted keys can also generate symbols — enable the checkbox per-key or use Refactor > Convert Strings to Symbols.

## Generated Localizable Symbols (Xcode 26+)

Generated symbols are an Xcode 26 typed-access layer on top of String Catalogs;
do not describe catalogs themselves as requiring Xcode 26 or iOS 17.

### Enabling symbol generation

1. Build Settings > Localization > **Generate String Catalog Symbols** → `Yes` (on by default in new Xcode 26 projects)
2. The catalog must use format version `"1.1"` — Xcode 26 writes this automatically when symbol generation metadata is present
3. Each key has a **Generate Swift Symbol** checkbox in the String Catalog editor. Manual keys (added via the (+) button) have this enabled by default. Auto-extracted keys can opt in via Refactor > Convert Strings to Symbols, which enables the checkbox

### How Xcode derives symbol names

Xcode camelCases the key name, lowercasing the first segment:

| Catalog key | Generated symbol |
|-------------|-----------------|
| `room_available` | `.roomAvailable` |
| `settings.notifications.toggle` | `.settingsNotificationsToggle` |
| `TITLE` | `.title` |

Keys with format specifiers become functions. Use positional named placeholders such as `%1$(name)lld` for descriptive argument labels; bare `%lld` produces generic labels:

| Catalog key | Format | Generated symbol |
|-------------|--------|-----------------|
| `landmarks_count` | `%1$(count)lld` | `.landmarksCount(count: Int)` |
| `greeting` | `%@` | `.greeting(_ param1: String)` |

You can rename parameters during refactoring for more descriptive signatures.

### Using generated symbols

```swift
// Simple key — static property
Text(.roomAvailable)

// Parameterized key — function
Text(.landmarksCount(count: 42))

// Non-default table (Booking.xcstrings)
Text(.Booking.confirmBookingCta)

// In non-SwiftUI code
let title = String(localized: .roomAvailable)
let attributed = AttributedString(localized: .greeting(userName))
```

Code completion supports generated symbols — type `.` and choose from the menu.

### Refactoring existing strings to symbols

Select one or more keys in the String Catalog editor, Control-click, and choose **Refactor > Convert Strings to Symbols**. Xcode replaces string literal usage in code with the generated symbol. This is reversible via **Convert Symbols to Strings**.

### Cross-module limitations

Generated symbols are declared `internal`. Code in other modules cannot access them directly. Default to a public wrapper; reach for `xcstrings-tool` if the wrapper becomes unwieldy across many modules:

- **Public wrapper** (default): Create a public extension on `LocalizedStringResource` that delegates to the internal symbols
- **[xcstrings-tool](https://github.com/liamnichols/xcstrings-tool)**: A Swift Package Plugin that generates public constants from `.xcstrings` files — use this for heavier multi-module setups where maintaining manual wrappers becomes tedious

For Swift Packages, the generated symbols use the `.module` bundle automatically. The `internal` visibility means only code within the same package target can reference them.

## Testing Strategies

### Scheme language override

Edit Scheme > Run > Options > App Language. Choose any added language to launch the app in that locale without changing the device/simulator system language.

### Pseudolocalization options

Xcode provides built-in pseudolocalization modes (Edit Scheme > Run > Options > App Language):

| Option | Effect | Catches |
|--------|--------|---------|
| Accented Pseudolanguage | Adds accents: "Hello" -> "[Hellо]" | Hardcoded strings (unlocalized text is obvious) |
| Right-to-Left Pseudolanguage | Forces RTL layout | Layout mirroring bugs |
| Double-Length Pseudolanguage | Doubles all strings | Truncation and overflow |
| Bounded String Pseudolanguage | Wraps strings in brackets | Missing localizations |

### UI tests with locale override

```swift
func testGermanLayout() {
    let app = XCUIApplication()
    app.launchArguments += ["-AppleLanguages", "(de)"]
    app.launchArguments += ["-AppleLocale", "de_DE"]
    app.launch()

    // Verify no truncation on key screens
    let saveButton = app.buttons["Speichern"]
    XCTAssertTrue(saveButton.exists)
    XCTAssertTrue(saveButton.isHittable)
}
```

### Snapshot testing per locale

Use a snapshot testing library to capture screenshots in multiple locales and compare them for layout regressions:

```swift
let locales = ["en_US", "de_DE", "ar_SA", "ja_JP"]
for locale in locales {
    app.launchArguments = ["-AppleLanguages", "(\(locale.prefix(2)))"]
    app.launch()
    // Capture and compare snapshot
}
```

### Translation coverage validation

Check that all keys are translated before release:

```bash
# Parse the .xcstrings JSON and check for "new" or empty states
python3 -c "
import json, sys
with open('Localizable.xcstrings') as f:
    data = json.load(f)
missing = []
for key, info in data['strings'].items():
    for lang, loc in info.get('localizations', {}).items():
        unit = loc.get('stringUnit', {})
        if unit.get('state') in ('new', None) or not unit.get('value'):
            missing.append(f'{lang}: {key}')
if missing:
    print('Missing translations:')
    for m in missing: print(f'  {m}')
    sys.exit(1)
print('All translations complete.')
"
```

## Migration from .strings / .stringsdict

### Automatic migration

1. Select the `.strings` file in the project navigator
2. Right-click > Migrate to String Catalog...
3. Xcode creates a `.xcstrings` file with all existing keys and translations
4. Verify in the String Catalog editor
5. Remove the old `.strings` / `.stringsdict` files from the target

### Manual migration

If automatic migration fails (complex bundle setups, CocoaPods):

1. Create a new `Localizable.xcstrings`
2. Build to extract keys from code
3. Copy translations from old `.strings` files into the String Catalog editor
4. Copy plural rules from `.stringsdict` into plural variants
5. Remove old files

### Migration checklist

- [ ] All `.strings` keys present in the new String Catalog
- [ ] All `.stringsdict` plural rules converted to String Catalog plural variants
- [ ] Bundle references updated (if custom bundle was used)
- [ ] Build succeeds with no missing-localization warnings
- [ ] Test every language the app supports
- [ ] Remove old `.strings` and `.stringsdict` files from the target
- [ ] Commit the `.xcstrings` file (it is JSON, diffs well in version control)

### Coexistence

String Catalogs and `.strings` files can coexist in the same target during migration. Xcode resolves keys from the String Catalog first, then falls back to `.strings`. Remove legacy files after verifying the migration.

## Best Practices

1. **One String Catalog per target** -- keep `Localizable.xcstrings` as the single source of truth for each target.
2. **Use comments** -- provide context for every ambiguous key. Translators cannot see your UI.
3. **Review extraction on every build** -- new keys appear with state "new". Translate them promptly.
4. **Version control the .xcstrings file** -- it is JSON and diffs clearly. Review translation changes in PRs.
5. **Automate coverage checks** -- integrate translation-coverage validation in CI to catch missing translations before release.
6. **Export regularly** -- send updated `.xcloc` bundles to translators after each sprint or feature merge.
7. **Test with pseudolocalizations in CI** -- run UI tests with double-length and RTL pseudo-languages to catch layout issues early.
8. **Prefer stable keys with generated symbols** -- for manually-managed strings, use symbol-style keys and enable Generate String Catalog Symbols to get compile-time safety and autocompletion.
