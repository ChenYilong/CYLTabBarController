---
name: swiftui-patterns
description: "Builds and reviews SwiftUI views with modern MV architecture, state, composition, isolated previews, and migration guidance. Covers @Observable ownership, @State/@Bindable/@Environment wiring, view decomposition, ViewModifiers, environment values, .task loading, iOS 26+ handoffs, Writing Tools, clipboard availability, and performance. Use when structuring SwiftUI state, managing @Observable, composing views, previewing meaningful UI states, or correcting SwiftUI patterns."
---

# SwiftUI Patterns

Modern SwiftUI patterns targeting iOS 26+ with Swift 6.3. Covers architecture, state management, view composition, environment wiring, async loading, design polish, and platform/share integration. Navigation, layout, animation, and Liquid Glass patterns live in dedicated sibling skills. Patterns are backward-compatible to iOS 17 unless noted.

## Contents

- [Architecture: Model-View (MV) Pattern](#architecture-model-view-mv-pattern)
- [Workflow](#workflow)
- [State Management](#state-management)
- [View Ordering Convention](#view-ordering-convention)
- [View Composition](#view-composition)
- [Environment](#environment)
- [Async Data Loading](#async-data-loading)
- [iOS 26+ New APIs](#ios-26-new-apis)
- [Performance Guidelines](#performance-guidelines)
- [HIG Alignment](#hig-alignment)
- [Writing Tools (iOS 18+)](#writing-tools-ios-18)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

**Scope boundary:** This skill covers architecture, state ownership, composition, environment wiring, async loading, and related SwiftUI app structure patterns. Detailed navigation patterns are covered in the `swiftui-navigation` skill, including `NavigationStack`, `NavigationSplitView`, sheets, tabs, and deep-linking patterns. Detailed layout, container, and component patterns are covered in the `swiftui-layout-components` skill, including stacks, grids, lists, scroll view patterns, forms, controls, search UI with `.searchable`, overlays, and related layout components. Detailed animation choreography is covered in `swiftui-animation`. Liquid Glass adoption, custom glass controls, scroll edge effects, `.scrollEdgeEffectStyle`, and `.backgroundExtensionEffect` are covered in `swiftui-liquid-glass`.

## Workflow

1. Record the current state ownership, actions, side effects, navigation, and lifecycle behavior.
2. Choose the smallest MV/state/composition change that preserves that contract.
3. Build after each structural step; fix compiler and isolation errors before continuing.
4. Render deterministic previews for loaded, loading, empty, and error states as applicable, including required environment dependencies.
5. Exercise important interactions and side effects. If behavior changes, restore the fixture, fix the smallest boundary, and rerun the same build, preview, and interaction checks.

Load [Behavior-Preserving View Refactoring](references/view-refactoring.md) for restructuring existing views and [Isolated Preview Construction](references/preview-isolation.md) for fixture and dependency patterns.

## Architecture: Model-View (MV) Pattern

Default to MV -- views are lightweight state expressions; models and services own business logic. Do not introduce view models unless the existing code already uses them.

**Core principles:**
- Favor `@State`, `@Environment`, `@Query`, `.task`, and `.onChange` for orchestration
- Inject services and shared models via `@Environment`; keep views small and composable
- Split large views into smaller subviews rather than introducing a view model
- Test models, services, and business logic; keep views simple and declarative

```swift
struct FeedView: View {
    @Environment(FeedClient.self) private var client

    enum ViewState {
        case loading, error(String), loaded([Post])
    }

    @State private var viewState: ViewState = .loading

    var body: some View {
        List {
            switch viewState {
            case .loading:
                ProgressView()
            case .error(let message):
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle",
                                       description: Text(message))
            case .loaded(let posts):
                ForEach(posts) { post in
                    PostRow(post: post)
                }
            }
        }
        .task { await loadFeed() }
        .refreshable { await loadFeed() }
    }

    private func loadFeed() async {
        do {
            let posts = try await client.getFeed()
            viewState = .loaded(posts)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
}
```

For MV pattern rationale, app wiring, and lightweight client examples, see [references/architecture-patterns.md](references/architecture-patterns.md).

## State Management

### `@Observable` Ownership Rules

**Important:** Isolate UI-bound `@Observable` stores and view models on `@MainActor` when SwiftUI views own them, mutate them, or bind to their properties. Observation tracks changes; it does not make shared mutable state thread-safe. Domain models that do not touch UI state can use their own isolation strategy.

| Wrapper | When to Use |
|---------|-------------|
| `@State` | View owns the object or value. Creates and manages lifecycle. |
| `let` | View receives an `@Observable` object. Read-only observation -- no wrapper needed. |
| `@Bindable` | View receives an `@Observable` object and needs two-way bindings (`$property`). |
| `@Environment(Type.self)` | Access shared `@Observable` object from environment. |
| `@State` (value types) | View-local simple state: toggles, counters, text field values. Always `private`. |
| `@Binding` | Two-way connection to parent's `@State` or `@Bindable` property. |

### Ownership Pattern

```swift
// UI-bound @Observable store -- main-actor isolated
@MainActor
@Observable final class ItemStore {
    var title = ""
    var items: [Item] = []
}

// View that OWNS the model
struct ParentView: View {
    @State private var viewModel = ItemStore()

    var body: some View {
        ChildView(store: viewModel)
            .environment(viewModel)
    }
}

// View that READS (no wrapper needed for @Observable)
struct ChildView: View {
    let store: ItemStore

    var body: some View { Text(store.title) }
}

// View that BINDS (needs two-way access)
struct EditView: View {
    @Bindable var store: ItemStore

    var body: some View {
        TextField("Title", text: $store.title)
    }
}

// View that reads from ENVIRONMENT
struct DeepView: View {
    @Environment(ItemStore.self) private var store

    var body: some View {
        @Bindable var s = store
        TextField("Title", text: $s.title)
    }
}
```

**Granular tracking:** SwiftUI only re-renders views that read properties that changed. If a view reads `items` but not `isLoading`, changing `isLoading` does not trigger a re-render. This is a major performance advantage over `ObservableObject`.

### Legacy ObservableObject

Only use if supporting iOS 16 or earlier. `@StateObject` → `@State`, `@ObservedObject` → `let`, `@EnvironmentObject` → `@Environment(Type.self)`.

## View Ordering Convention

Order members top to bottom: 1) `@Environment` 2) `let` properties 3) `@State` / stored properties 4) computed `var` 5) `init` 6) `body` 7) view builders / helpers 8) async functions

## View Composition

### Extract Subviews

Break views into focused subviews. Each should have a single responsibility.
When restructuring an existing view, load [Behavior-Preserving View Refactoring](references/view-refactoring.md)
for action/side-effect boundaries and build/preview proof.

```swift
var body: some View {
    VStack {
        HeaderSection(title: title, isPinned: isPinned)
        DetailsSection(details: details)
        ActionsSection(onSave: onSave, onCancel: onCancel)
    }
}
```

### Computed View Properties

Keep computed `some View` properties for small, stateless fragments. Extract a section into a dedicated `View` type when it has any of these signals:

- meaningful branching or substantial layout
- its own state or async lifecycle
- narrower Observation dependencies than the parent
- a useful independent preview
- enough complexity to obscure the parent's data flow

When narrowing dependencies, pass only the values, bindings, and actions the child needs. If they form a large but cohesive interface, pass a feature-scoped `@Observable` model. Observation limits invalidation to properties the child reads, but an app-wide store still creates a broad interface; reserve it for children that genuinely need that cohesive state.

Reuse is a useful outcome, not a prerequisite for decomposition.

Extensions and `// MARK: -` organize a large file; they do not create view boundaries or replace extraction.

### ViewBuilder Functions

For conditional logic that does not warrant a separate struct:

```swift
@ViewBuilder
private func statusBadge(for status: Status) -> some View {
    switch status {
    case .active: Text("Active").foregroundStyle(.green)
    case .inactive: Text("Inactive").foregroundStyle(.secondary)
    }
}
```

### Custom View Modifiers

Extract repeated styling into `ViewModifier`:

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.background)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(radius: 2)
    }
}
extension View { func cardStyle() -> some View { modifier(CardStyle()) } }
```

### Stable View Tree

Avoid top-level conditional view swapping. Prefer a single stable base view with conditions inside sections or modifiers.

When extracted views need independent state coverage, deterministic fixtures, or environment setup, load [Isolated Preview Construction](references/preview-isolation.md).

## Environment

### Custom Environment Values

Use `@Entry` for custom environment values and actions. It generates the entry boilerplate for `EnvironmentValues`.

```swift
extension EnvironmentValues {
    @Entry var theme: Theme = .default
    @Entry var refreshFeed: @Sendable () async -> Void = {}
}

// Usage
.environment(\.theme, customTheme)
.environment(\.refreshFeed) { await feedStore.refresh() }

@Environment(\.theme) private var theme
@Environment(\.refreshFeed) private var refreshFeed
```

For iOS 17-compatible code or older compatibility shims, use manual `EnvironmentKey` types instead.

### Common Built-in Environment Values

```swift
@Environment(\.dismiss) var dismiss
@Environment(\.colorScheme) var colorScheme
@Environment(\.dynamicTypeSize) var dynamicTypeSize
@Environment(\.horizontalSizeClass) var sizeClass
@Environment(\.isSearching) var isSearching
@Environment(\.openURL) var openURL
@Environment(\.modelContext) var modelContext
```

## Async Data Loading

Always use `.task` -- it cancels automatically on view disappear:

```swift
struct ItemListView: View {
    @State var store = ItemStore()

    var body: some View {
        List(store.items) { item in
            ItemRow(item: item)
        }
        .task { await store.load() }
        .refreshable { await store.refresh() }
    }
}
```

Use `.task(id:)` to re-run when a dependency changes:

```swift
.task(id: searchText) {
    guard !searchText.isEmpty else { return }
    await search(query: searchText)
}
```

Never create manual `Task` in `onAppear` unless you need to store a reference for cancellation. Exception: `Task {}` is acceptable in synchronous action closures (e.g., Button actions) for immediate state updates before async work.

Use `swift-concurrency` for cancellation handlers, debounce and clocks, `AsyncSequence`, or actor isolation.

## iOS 26+ New APIs

Route `.scrollEdgeEffectStyle`, `.backgroundExtensionEffect`, and glass controls to `swiftui-liquid-glass`; route `@Animatable` to `swiftui-animation`. `TextEditor(text: Binding<AttributedString>)` is the iOS 26 rich-text editing path. Keep availability checks beside code that adopts these APIs.

Clipboard command modifiers are not iOS 26 defaults: `.copyable`, `.cuttable`, and command-based `.pasteDestination(for:action:validator:)` are macOS 13+ and iOS/iPadOS/Mac Catalyst 27 beta in current Apple docs. For iOS 26 targets, use `UIPasteboard` for custom clipboard commands, or use drag/drop and `ShareLink` for `Transferable` flows. See [references/platform-and-sharing.md](references/platform-and-sharing.md).

## Performance Guidelines

- **Lazy stacks/grids:** Use `LazyVStack`, `LazyHStack`, `LazyVGrid`, `LazyHGrid` for large collections. Regular stacks render all children immediately.
- **Stable IDs:** All items in `List`/`ForEach` must conform to `Identifiable` with stable IDs. Never use array indices.
- **Avoid body recomputation:** Move filtering and sorting to computed properties or the model, not inline in `body`.
- **Equatable views:** For complex views that re-render unnecessarily, conform to `Equatable`.

## HIG Alignment

Follow Apple Human Interface Guidelines for layout, typography, color, and accessibility. Key rules:

- Use semantic colors (`Color.primary`, `.secondary`, `Color(uiColor: .systemBackground)`) for automatic light/dark mode
- Use system font styles (`.title`, `.headline`, `.body`, `.caption`) for Dynamic Type support
- Use `ContentUnavailableView` for empty and error states
- Omit `spacing:` on stacks unless a specific value is required — `nil` (the default) uses platform-appropriate adaptive spacing
- Support adaptive layouts via `horizontalSizeClass`
- Provide VoiceOver labels (`.accessibilityLabel`) and support Dynamic Type accessibility sizes by switching layout orientation

See [references/design-polish.md](references/design-polish.md) for HIG, theming, haptics, focus, transitions, and loading patterns.

## Writing Tools (iOS 18+)

Control the Apple Intelligence Writing Tools experience on text views with `.writingToolsBehavior(_:)`.

| Level | Effect | When to use |
|-------|--------|-------------|
| `.complete` | Full inline rewriting (proofread, rewrite, transform) | Notes, email, documents |
| `.limited` | Reduced overlay-panel experience | Code editors, validated forms |
| `.disabled` | Writing Tools hidden entirely | Passwords, search bars |
| `.automatic` | System chooses based on context (default) | Most views |

```swift
TextEditor(text: $body)
    .writingToolsBehavior(.complete)
TextField("Search…", text: $query)
    .writingToolsBehavior(.disabled)
```

**Detecting active sessions:** Read `isWritingToolsActive` on `UITextView` (UIKit) to defer validation or suspend undo grouping until a rewrite finishes.

> **Docs:** [WritingToolsBehavior](https://sosumi.ai/documentation/swiftui/writingtoolsbehavior) · [writingToolsBehavior(_:)](https://sosumi.ai/documentation/swiftui/view/writingtoolsbehavior(_:))

## Common Mistakes

1. Using `@ObservedObject` to create objects -- use `@StateObject` (legacy) or `@State` (modern)
2. Heavy computation in view `body` -- move to model or computed property
3. Not using `.task` for async work -- manual `Task` in `onAppear` leaks if not cancelled
4. Array indices as `ForEach` IDs -- causes incorrect diffing and UI bugs
5. Forgetting `@Bindable` -- `$property` syntax on `@Observable` requires `@Bindable`
6. Over-using `@State` -- only for view-local state; shared state belongs in `@Observable`
7. Keeping complex or independently previewable sections computed -- extract `View` types; extensions and `// MARK:` only organize
8. Using `NavigationView` -- deprecated; use `NavigationStack`
9. Reaching for `foregroundColor(_:)` when `foregroundStyle(_:)` better matches semantic styling
10. Inline closures in body -- extract complex closures to methods
11. `.sheet(isPresented:)` when state represents a model -- use `.sheet(item:)` instead
12. **Using `AnyView` for routine branching** -- type erasure hides structure and can hurt performance or identity-sensitive transitions. Use `@ViewBuilder`, `Group`, or generics unless an API genuinely needs heterogeneous view storage. See [references/deprecated-migration.md](references/deprecated-migration.md)
13. **Putting `@AppStorage` inside an `@Observable` class.** `@AppStorage` is a view `DynamicProperty`; keep it in a `View`, or expose a normal observed property backed by `UserDefaults` in the model.

14. Hard-coding `spacing:` on every stack -- omit it to get adaptive platform spacing; only specify when the value is intentional
15. Treating `.copyable`, `.cuttable`, or command-based `.pasteDestination(for:action:validator:)` as iOS 16/iOS 26 APIs -- they are macOS 13+ and iOS/iPadOS/Mac Catalyst 27 beta in current Apple docs. Use `UIPasteboard`, drag/drop, or `ShareLink` for iOS 26 targets.
16. Treating modern defaults as formal deprecations -- `#Preview` is the modern preview default, but `PreviewProvider` is legacy rather than compiler-deprecated. `EditButton`, `.onDelete`, and `.onMove` remain valid for edit-mode list workflows; use `.swipeActions` for contextual row actions.
17. Making a required dependency optional to stop a preview crash -- install deterministic preview dependencies instead, without live networking, authentication, production databases, or global singletons

## Review Checklist

- [ ] `@Observable` used for shared state models (not `ObservableObject` on iOS 17+)
- [ ] `@State` owns objects; `let`/`@Bindable` receives them
- [ ] Migration and availability claims checked for current platform support, especially clipboard and sharing APIs
- [ ] `NavigationStack` used (not `NavigationView`)
- [ ] `.task` modifier for async data loading
- [ ] `LazyVStack`/`LazyHStack` for large collections
- [ ] Stable `Identifiable` IDs (not array indices)
- [ ] Extraction uses branching/layout, lifecycle, dependency, preview, or parent-flow signals; small stateless fragments stay computed
- [ ] Extensions and `// MARK:` only organize files
- [ ] Structure-only refactors preserve behavior; use thin action/lifecycle methods, keep reusable logic in services/models, then build and render useful previews
- [ ] Previews cover meaningful loaded/loading/empty/error states with deterministic fixtures and every required environment dependency
- [ ] No heavy computation in view `body`
- [ ] Environment used for deeply shared state
- [ ] `foregroundStyle(_:)` used when semantic styling is preferable to a fixed color
- [ ] Custom `ViewModifier` for repeated styling
- [ ] `.sheet(item:)` preferred over `.sheet(isPresented:)`
- [ ] Sheets own their actions and call `dismiss()` internally
- [ ] MV pattern followed -- no unnecessary view models
- [ ] UI-bound `@Observable` stores and view models are `@MainActor`-isolated
- [ ] Model types passed across concurrency boundaries are `Sendable`
- [ ] Stack `spacing:` omitted unless a specific value is required (prefer adaptive default)

## References

- Architecture, app wiring, and lightweight clients: [references/architecture-patterns.md](references/architecture-patterns.md)
- Design polish (HIG, theming, haptics, transitions, loading, focus): [references/design-polish.md](references/design-polish.md)
- Deprecated API migration: [references/deprecated-migration.md](references/deprecated-migration.md)
- Platform and sharing patterns (Transferable, clipboard availability, media, menus, macOS settings): [references/platform-and-sharing.md](references/platform-and-sharing.md)
- Isolated preview construction (state coverage, fixtures, and environment dependencies): [references/preview-isolation.md](references/preview-isolation.md)
- Existing-view restructuring (behavior contract, action/side-effect boundaries, and verification): [references/view-refactoring.md](references/view-refactoring.md)
