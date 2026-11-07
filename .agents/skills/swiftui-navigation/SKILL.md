---
name: swiftui-navigation
description: "Implement SwiftUI navigation patterns including NavigationStack, NavigationSplitView, sheet presentation, tab-based navigation, and deep linking. Use when building push navigation, programmatic routing, multi-column layouts, modal sheets, tab bars, universal links, or custom URL scheme handling."
---

# SwiftUI Navigation

Navigation patterns for SwiftUI apps targeting iOS 26+ with Swift 6.3. Covers push navigation, multi-column layouts, sheet presentation, tab architecture, and deep linking. Patterns are backward-compatible to iOS 17 unless noted.

## Contents

- [NavigationStack (Push Navigation)](#navigationstack-push-navigation)
- [NavigationSplitView (Multi-Column)](#navigationsplitview-multi-column)
- [Sheet Presentation](#sheet-presentation)
- [Tab-Based Navigation](#tab-based-navigation)
- [Deep Links](#deep-links)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## NavigationStack (Push Navigation)

Use `NavigationStack` with a typed `[Route]` binding for programmatic push navigation. Define routes as a `Hashable` enum and map them with `.navigationDestination(for:)`; this keeps the path compile-time checked. Use `NavigationPath` only when one stack must hold heterogeneous route value types.

```swift
enum Route: Hashable {
    case item(id: Item.ID)
}

struct ContentView: View {
    @State private var path: [Route] = []
    let items: [Item]

    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: Route.item(id: item.id)) {
                    ItemRow(item: item)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .item(let id):
                    DetailView(itemID: id)
                }
            }
            .navigationTitle("Items")
        }
    }
}
```

**Programmatic navigation:**

```swift
path.append(.item(id: item.id))  // Push
path.removeLast()                // Pop one
path = []                        // Pop to root
```

**Router pattern:** For apps with complex navigation, use a router object that owns the path and sheet state. Each tab gets its own router instance injected via `.environment()`. Centralize destination mapping with a single `.navigationDestination(for:)` block or a shared `withAppRouter()` modifier.

See [references/navigationstack.md](references/navigationstack.md) for full router examples including per-tab stacks, centralized destination mapping, and generic tab routing.

## NavigationSplitView (Multi-Column)

Use `NavigationSplitView` for sidebar-detail layouts on iPad and Mac. Falls back to stack navigation on iPhone.

```swift
struct MasterDetailView: View {
    @State private var selectedItem: Item?

    var body: some View {
        NavigationSplitView {
            List(items, selection: $selectedItem) { item in
                NavigationLink(value: item) { ItemRow(item: item) }
            }
            .navigationTitle("Items")
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                ContentUnavailableView("Select an Item", systemImage: "sidebar.leading")
            }
        }
    }
}
```

### Custom Split Column (Manual HStack)

For custom multi-column layouts (e.g., a dedicated notification column independent of selection), use a manual `HStack` split with `horizontalSizeClass` checks:

```swift
@MainActor
struct AppView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @AppStorage("showSecondaryColumn") private var showSecondaryColumn = true

  var body: some View {
    HStack(spacing: 0) {
      primaryColumn
      if shouldShowSecondaryColumn {
        Divider().edgesIgnoringSafeArea(.all)
        secondaryColumn
      }
    }
  }

  private var shouldShowSecondaryColumn: Bool {
    horizontalSizeClass == .regular
      && showSecondaryColumn
  }

  private var primaryColumn: some View {
    TabView { /* tabs */ }
  }

  private var secondaryColumn: some View {
    NotificationsTab()
      .environment(\.isSecondaryColumn, true)
      .frame(maxWidth: .secondaryColumnWidth)
  }
}
```

Use the manual HStack split when you need full control or a non-standard secondary column. Use `NavigationSplitView` when you want a standard system layout with minimal customization.

## Sheet Presentation

Prefer `.sheet(item:)` over `.sheet(isPresented:)` when state represents a selected model. Sheets should own their actions and call `dismiss()` internally.

```swift
@State private var selectedItem: Item?

.sheet(item: $selectedItem) { item in
    EditItemSheet(item: item)
}
```

**Presentation sizing (iOS 18+):** Control sheet dimensions with `.presentationSizing`:

```swift
.sheet(item: $selectedItem) { item in
    EditItemSheet(item: item)
        .presentationSizing(.form)  // .form, .page, .fitted, .automatic
}
```

`PresentationSizing` values:
- `.automatic` -- platform default
- `.page` -- roughly paper size, for informational content
- `.form` -- slightly narrower than page, for form-style UI
- `.fitted` -- sized by the content's ideal size

Fine-tuning: `.fitted(horizontal:vertical:)` constrains fitting axes; `.sticky(horizontal:vertical:)` grows but does not shrink in specified dimensions.

**Dismissal protection:** On iOS/iPadOS, use `.interactiveDismissDisabled(hasUnsavedChanges)` and provide explicit Save/Discard actions inside the sheet. On macOS 15+, use `.dismissalConfirmationDialog("Discard?", shouldPresent: hasUnsavedChanges)` for window dismissal confirmation.
Route every programmatic close through the same save/validate/discard gate;
`interactiveDismissDisabled` guards interactive dismissal only.

**Enum-driven sheet routing:** Define a `SheetDestination` enum that is `Identifiable`, store it on the router, and map it with a shared view modifier. This lets any child view present sheets without prop-drilling. See [references/sheets.md](references/sheets.md) for the full centralized sheet routing pattern.

## Tab-Based Navigation

Use the `Tab` API with a selection binding for scalable tab architecture. Each tab should wrap its content in an independent `NavigationStack`.

```swift
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack { HomeView() }
            }
            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                NavigationStack { SearchView() }
            }
            Tab("Profile", systemImage: "person", value: .profile) {
                NavigationStack { ProfileView() }
            }
        }
    }
}
```

**Custom binding with side effects:** Route selection changes through a function to intercept special tabs (e.g., compose) that should trigger an action instead of changing selection.

### iOS 26 Tab Additions

- **`Tab(value:role:)` with `.search`** -- marks a dedicated search tab with system default search title, icon, and pinning behavior
- **`.tabViewSearchActivation(_:)`** -- controls search tab activation and deactivation behavior
- **`.tabBarMinimizeBehavior(_:)`** -- `.onScrollDown`, `.onScrollUp`, `.never` (iPhone only)
- **`.tabViewSidebarHeader/Footer`** -- customize sidebar sections on iPadOS/macOS
- **`.tabViewBottomAccessory { }`** -- attach content below the tab bar (e.g., Now Playing bar)
- **`TabSection`** -- group tabs into sidebar sections with `.tabPlacement(.sidebarOnly)`

See [references/tabview.md](references/tabview.md) for full TabView patterns including custom bindings, dynamic tabs, and sidebar customization.

## Deep Links

Use parse → validate → commit. Parse into a typed route without mutating
navigation; validate scheme/host/path, identifier shape, authorization, and
destination existence; then update tab/path atomically. Invalid links must leave
the current navigation unchanged.

### Universal Links

Universal links let iOS open your app for standard HTTPS URLs. They require:
1. An Apple App Site Association (AASA) file at `/.well-known/apple-app-site-association`
2. An Associated Domains entitlement (`applinks:example.com`)

Handle Universal Links and custom URL schemes in SwiftUI with `.onOpenURL`:

```swift
@main
struct MyApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in router.handle(url: url) }
        }
    }
}
```

### Custom URL Schemes

Register schemes in `Info.plist` under `CFBundleURLTypes`. Handle with `.onOpenURL`. Prefer universal links over custom schemes for publicly shared links -- they provide web fallback and domain verification.

### Handoff (NSUserActivity)

Advertise activities with `.userActivity()` and receive Handoff or other user activities with `.onContinueUserActivity()`. Declare activity types in `Info.plist` under `NSUserActivityTypes`. Set `isEligibleForHandoff = true` and provide a `webpageURL` as fallback.

See [references/deeplinks.md](references/deeplinks.md) for full examples of AASA configuration, router URL handling, custom URL schemes, and NSUserActivity continuation.

## Common Mistakes

1. Using deprecated `NavigationView` -- use `NavigationStack` or `NavigationSplitView`
2. Sharing one navigation path or router across all tabs -- each tab needs its own path
3. Using `.sheet(isPresented:)` when state represents a model -- use `.sheet(item:)` instead
4. Storing view instances in navigation paths -- store lightweight `Hashable` route data
5. Nesting `@Observable` router objects inside other `@Observable` objects
6. Prefer `Tab(value:)` with `TabView(selection:)` over the older `.tabItem { }` API
7. Assuming `tabBarMinimizeBehavior` works on iPad -- it is iPhone only
8. Handling deep links in multiple places -- centralize URL parsing in the router
9. Hard-coding sheet frame dimensions -- use `.presentationSizing(.form)` instead
10. Missing `@MainActor` on router classes -- required for Swift 6 concurrency safety

## Review Checklist

- [ ] `NavigationStack` used (not `NavigationView`)
- [ ] Each tab has its own `NavigationStack` with independent path
- [ ] Route enum is `Hashable` with stable identifiers
- [ ] `.navigationDestination(for:)` maps all route types
- [ ] `.sheet(item:)` preferred over `.sheet(isPresented:)`
- [ ] Sheets own their dismiss logic internally
- [ ] Router object is `@MainActor` and `@Observable`
- [ ] Deep link URLs parsed and validated before navigation
- [ ] Universal links have AASA and Associated Domains configured
- [ ] Tab selection uses `Tab(value:)` with binding

## References

- NavigationStack and router patterns: [references/navigationstack.md](references/navigationstack.md)
- Sheet presentation and routing: [references/sheets.md](references/sheets.md)
- TabView patterns and iOS 26 API: [references/tabview.md](references/tabview.md)
- Deep links, universal links, and Handoff: [references/deeplinks.md](references/deeplinks.md)
- Architecture and state management: see `swiftui-patterns` skill
- Layout and components: see `swiftui-layout-components` skill
