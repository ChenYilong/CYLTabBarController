# Sheets

## Contents

- [Intent](#intent)
- [Core architecture](#core-architecture)
- [Example: SheetDestination enum](#example-sheetdestination-enum)
- [Example: withSheetDestinations modifier](#example-withsheetdestinations-modifier)
- [Example: presenting from a child view](#example-presenting-from-a-child-view)
- [Required wiring](#required-wiring)
- [Example: sheets that need their own navigation](#example-sheets-that-need-their-own-navigation)
- [Design choices to keep](#design-choices-to-keep)
- [iOS 26 Presentation Sizing](#ios-26-presentation-sizing)
- [Pitfalls](#pitfalls)

## Intent

Use a centralized sheet routing pattern so any view can present modals without prop-drilling. This keeps sheet state in one place and scales as the app grows.

## Core architecture

- Define a `SheetDestination` enum that describes every modal and is `Identifiable`.
- Store the current sheet in a router object (`presentedSheet: SheetDestination?`).
- Create a view modifier like `withSheetDestinations(...)` that maps the enum to concrete sheet views.
- Inject the router into the environment so child views can set `presentedSheet` directly.

## Example: SheetDestination enum

```swift
enum SheetDestination: Identifiable, Hashable {
  case composer
  case editProfile
  case settings
  case report(itemID: String)

  var id: String {
    switch self {
    case .composer, .editProfile:
      // Use the same id to ensure only one editor-like sheet is active at a time.
      return "editor"
    case .settings:
      return "settings"
    case .report:
      return "report"
    }
  }
}
```

## Example: withSheetDestinations modifier

```swift
extension View {
  func withSheetDestinations(
    sheet: Binding<SheetDestination?>
  ) -> some View {
    sheet(item: sheet) { destination in
      Group {
        switch destination {
        case .composer:
          ComposerView()
        case .editProfile:
          EditProfileView()
        case .settings:
          SettingsView()
        case .report(let itemID):
          ReportView(itemID: itemID)
        }
      }
    }
  }
}
```

## Example: presenting from a child view

```swift
struct StatusRow: View {
  @Environment(RouterPath.self) private var router

  var body: some View {
    Button("Report") {
      router.presentedSheet = .report(itemID: "123")
    }
  }
}
```

## Required wiring

For the child view to work, a parent view must:
- own the router instance,
- attach `withSheetDestinations(sheet: $router.presentedSheet)` (or an equivalent `sheet(item:)` handler), and
- inject it with `.environment(router)` after the sheet modifier so the modal content inherits it.

This makes the child assignment to `router.presentedSheet` drive presentation at the root.

## Example: sheets that need their own navigation

Wrap sheet content in a `NavigationStack` so it can push within the modal.

```swift
struct NavigationSheet<Content: View>: View {
  var content: () -> Content

  var body: some View {
    NavigationStack {
      content()
        .toolbar { CloseToolbarItem() }
    }
  }
}
```

## Design choices to keep

- Centralize sheet routing so features can present modals without wiring bindings through many layers.
- Use `sheet(item:)` to guarantee a single sheet is active and to drive presentation from the enum.
- Group related sheets under the same `id` when they are mutually exclusive (e.g., editor flows).
- Keep sheet views lightweight and composed from smaller views; avoid large monoliths.

## iOS 26 Presentation Sizing

Control sheet dimensions with `presentationSizing(_:)` (iOS 18+):

```swift
.sheet(item: $selectedItem) { item in
    EditItemSheet(item: item)
        .presentationSizing(.form)
}
```

`PresentationSizing` values:
- `.automatic` -- platform default
- `.page` -- roughly paper size, for informational content
- `.form` -- slightly narrower than page, for form-style UI
- `.fitted` -- sized by the content's ideal size

Modifier methods for fine-tuning:
- `.fitted(horizontal:vertical:)` -- constrain fitting to specific axes
- `.sticky(horizontal:vertical:)` -- grow but do not shrink in specified dimensions

### Dismissal Protection

On iOS/iPadOS, prevent gesture dismissal while unsaved changes exist and expose explicit Save/Discard actions inside the sheet:

```swift
.sheet(item: $selectedItem) { item in
    EditItemSheet(item: item)
        .interactiveDismissDisabled(hasUnsavedChanges)
}
```

`interactiveDismissDisabled` covers interactive dismissal. Route toolbar
buttons and other programmatic close paths through the same validation/save or
explicit-discard decision before calling `dismiss()`.

On macOS 15+, show a confirmation dialog when the user tries to dismiss a sheet with unsaved changes:

```swift
.sheet(item: $selectedItem) { item in
    EditItemSheet(item: item)
        .dismissalConfirmationDialog(
            "Discard changes?",
            shouldPresent: hasUnsavedChanges
        ) {
            Button("Discard", role: .destructive) { discardChanges() }
        }
}
```

- For `dismissalConfirmationDialog`, the Cancel action is included automatically and prevents dismissal.
- All other action buttons allow dismissal to proceed.
- Use `.keyboardShortcut(.defaultAction)` to set the default button

## Pitfalls

- Avoid mixing `sheet(isPresented:)` and `sheet(item:)` for the same concern; prefer a single enum.
- Do not store heavy state inside `SheetDestination`; pass lightweight identifiers or models.
- If multiple sheets can appear from the same screen, give them distinct `id` values.
- Use `presentationSizing(.form)` for form sheets instead of hard-coding frame dimensions.
- Use `interactiveDismissDisabled(_:)` for iOS/iPadOS dismissal prevention.
- Always pair `dismissalConfirmationDialog` with a `shouldPresent` condition on macOS; showing it when there are no changes is confusing.
