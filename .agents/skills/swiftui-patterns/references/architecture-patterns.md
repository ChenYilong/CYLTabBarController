# Architecture Patterns

## Contents
- [MV Patterns](#mv-patterns)
- [App Wiring and Dependency Graph](#app-wiring-and-dependency-graph)
- [Lightweight Clients](#lightweight-clients)

## MV Patterns

Default to Model-View (MV) in SwiftUI. Views are lightweight state expressions; models and services own business logic. Do not introduce view models unless the existing code already requires them.

### Contents

- [Core Principles](#core-principles)
- [Why Not MVVM](#why-not-mvvm)
- [MV Pattern in Practice](#mv-pattern-in-practice)
- [When a ViewModel Already Exists](#when-a-viewmodel-already-exists)
- [When a New ViewModel Is Justified](#when-a-new-viewmodel-is-justified)
- [Environment vs. Initializer Injection](#environment-vs-initializer-injection)
- [Testing Strategy](#testing-strategy)
- [Source](#source)

### Core Principles

- Views orchestrate UI flow using `@State`, `@Environment`, `@Query`, `.task`, and `.onChange`
- Services and shared models live in the environment, are testable in isolation, and encapsulate complexity
- Split large views into smaller subviews rather than introducing a view model
- Test models, services, and business logic; views should stay simple and declarative

### Why Not MVVM

SwiftUI views are structs -- lightweight, disposable, and recreated frequently. Adding a ViewModel means fighting the framework's core design. Apple's own WWDC sessions (*Data Flow Through SwiftUI*, *Data Essentials in SwiftUI*, *Discover Observation in SwiftUI*) barely mention ViewModels.

Every ViewModel adds:
- More complexity and objects to synchronize
- More indirection and cognitive overhead
- Manual data fetching that duplicates SwiftUI/SwiftData mechanisms

### MV Pattern in Practice

#### View with Environment-Injected Service

```swift
struct FeedView: View {
    @Environment(FeedClient.self) private var client
    @Environment(AppTheme.self) private var theme

    enum ViewState {
        case loading, error(String), loaded([Post])
    }

    @State private var viewState: ViewState = .loading
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            List {
                switch viewState {
                case .loading:
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                case .error(let message):
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle",
                                           description: Text(message))
                    .listRowSeparator(.hidden)
                case .loaded(let posts):
                    ForEach(posts) { post in
                        PostRowView(post: post)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await loadFeed() }
            .task { await loadFeed() }
        }
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

#### Using .task(id:) and .onChange

SwiftUI modifiers act as small state reducers:

```swift
.task(id: searchText) {
    guard !searchText.isEmpty else { return }
    await searchFeed(query: searchText)
}
.onChange(of: isInSearch, initial: false) {
    guard !isInSearch else { return }
    Task { await fetchSuggestedFeed() }
}
```

#### App-Level Environment Setup

```swift
@main
struct MyApp: App {
    @State var client = APIClient()
    @State var auth = Auth()
    @State var router = AppRouter(initialTab: .feed)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(client)
                .environment(auth)
                .environment(router)
        }
    }
}
```

All dependencies are injected once and available everywhere.

#### SwiftData: The Perfect MV Example

SwiftData was built to work directly in views:

```swift
struct BookListView: View {
    @Query private var books: [Book]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(books) { book in
                BookRowView(book: book)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(book)
                        }
                    }
            }
        }
    }
}
```

Forcing a ViewModel here means manual fetching, manual refresh, and boilerplate everywhere.

### When a ViewModel Already Exists

If a ViewModel exists in the codebase:
- Make it non-optional when possible
- Pass dependencies via `init`, then forward them into the ViewModel in the view's `init`
- Store as `@State` in the root view that owns it
- Avoid `bootstrapIfNeeded` patterns

```swift
@State private var viewModel: SomeViewModel

init(dependency: Dependency) {
    _viewModel = State(initialValue: SomeViewModel(dependency: dependency))
}
```

Modern `@Observable` ViewModel with child-view binding:

```swift
@MainActor @Observable final class ProfileViewModel {
    var name: String = ""
    var isSaving: Bool = false

    private let client: ProfileClient

    init(client: ProfileClient) {
        self.client = client
    }

    func save() async throws {
        isSaving = true
        defer { isSaving = false }
        try await client.update(name: name)
    }
}

// Owner view creates via @State
struct ProfileScreen: View {
    @State private var viewModel: ProfileViewModel

    init(client: ProfileClient) {
        _viewModel = State(initialValue: ProfileViewModel(client: client))
    }

    var body: some View {
        ProfileForm(viewModel: viewModel)
    }
}

// Child view receives and binds
struct ProfileForm: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        TextField("Name", text: $viewModel.name)
        Button("Save") { Task { try? await viewModel.save() } }
            .disabled(viewModel.isSaving)
    }
}
```

Use `@MainActor` for observable types that are owned by SwiftUI views and mutate view-facing state. Keep non-UI domain models isolated according to their concurrency boundary instead of applying `@MainActor` by default.

### When a New ViewModel Is Justified

The MV pattern is the default. Introduce a ViewModel only when the view would be hard to read or test without one:

- **Multi-step workflows** — onboarding, checkout, or wizard flows where each step mutates shared draft state
- **Non-trivial business logic** — validation chains, derived state from multiple sources, or transformation pipelines that don't belong in a lightweight client
- **Coordinated async streams** — the view orchestrates multiple publishers or `AsyncSequence` values with interdependent state transitions
- **Existing test surface** — the codebase already tests against a ViewModel interface and rewriting to MV would be high cost, low reward

The bar is "this view would be hard to read and test without a ViewModel," not "I'm used to MVVM."

### Environment vs. Initializer Injection

**Use `@Environment` when** the dependency is shared across many views at different depths. Threading it through every intermediate initializer adds noise:
- App-wide services: auth, network client, theme, router
- SwiftData `ModelContext`
- Feature-scoped stores injected at a navigation root

**Use initializer parameters when** the data is specific to this view instance. Makes the view's requirements explicit and keeps previews simple:
- The selected item, filter mode, or configuration
- Parent-to-child data that only one view needs
- Values known at call site that don't change

Rule of thumb: if three or more intermediate views would need to accept and forward a parameter just to reach a deeply nested consumer, move it to the environment.

### Testing Strategy

- Unit test services and business logic
- Test models and transformations
- Use SwiftUI previews for visual regression
- Use UI automation for end-to-end tests
- Views should be simple enough that they do not need dedicated unit tests

### Source

Based on guidance from "SwiftUI in 2025: Forget MVVM" (Thomas Ricouard) and Apple WWDC sessions on SwiftUI data flow.

## App Wiring and Dependency Graph

### Contents

- [Intent](#intent)
- [Recommended Structure](#recommended-structure)
- [Root Shell Example](#root-shell-example)
- [Dependency Graph Modifier](#dependency-graph-modifier)
- [SwiftData / ModelContainer](#swiftdata-modelcontainer)
- [Sheet Routing (Enum-Driven)](#sheet-routing-enum-driven)
- [App Entry Point](#app-entry-point)
- [Deep Linking](#deep-linking)
- [When to Use](#when-to-use)
- [Caveats](#caveats)

### Intent

Wire the app shell (TabView + NavigationStack + sheets) and install a global dependency graph (environment objects, services, streaming clients, SwiftData ModelContainer) in one place.

### Recommended Structure

1. Root view sets up tabs, per-tab routers, and sheets.
2. A dedicated view modifier installs global dependencies and lifecycle tasks (auth state, streaming watchers, push tokens, data containers).
3. Feature views pull only what they need from the environment; feature-specific state stays local.

### Root Shell Example

```swift
@MainActor
struct AppView: View {
    @State private var selectedTab: AppTab = .home
    @State private var tabRouter = TabRouter()

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                let router = tabRouter.router(for: tab)
                Tab(value: tab) {
                    NavigationStack(path: tabRouter.binding(for: tab)) {
                        tab.makeContentView()
                    }
                    .withSheetDestinations(sheet: Binding(
                        get: { router.presentedSheet },
                        set: { router.presentedSheet = $0 }
                    ))
                    .environment(router)
                } label: {
                    tab.label
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .withAppDependencyGraph()
    }
}
```

#### AppTab Enum

```swift
@MainActor
enum AppTab: Identifiable, Hashable, CaseIterable {
    case home, notifications, settings
    var id: String { String(describing: self) }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .home: HomeView()
        case .notifications: NotificationsView()
        case .settings: SettingsView()
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .home: Label("Home", systemImage: "house")
        case .notifications: Label("Notifications", systemImage: "bell")
        case .settings: Label("Settings", systemImage: "gear")
        }
    }
}
```

#### Router Skeleton

```swift
@MainActor
@Observable
final class RouterPath {
    var path: [Route] = []
    var presentedSheet: SheetDestination?
}

enum Route: Hashable {
    case detail(id: String)
}
```

### Dependency Graph Modifier

Use a single modifier to install environment objects and handle lifecycle hooks. This keeps wiring consistent and avoids forgetting a dependency at call sites.

```swift
extension View {
    func withAppDependencyGraph(
        client: APIClient = .shared,
        auth: Auth = .shared,
        theme: Theme = .shared,
        toastCenter: ToastCenter = .shared
    ) -> some View {
        environment(client)
            .environment(auth)
            .environment(theme)
            .environment(toastCenter)
            .task(id: auth.currentAccount?.id) {
                // Re-seed services when account changes
                await client.configure(for: auth.currentAccount)
            }
    }
}
```

Notes:
- The `.task(id:)` hooks respond to account/client changes, re-seeding services and watcher state.
- Keep the modifier focused on global wiring; feature-specific state stays within features.
- Adjust types to match your project.

### SwiftData / ModelContainer

Install `ModelContainer` at the root so all feature views share the same store:

```swift
extension View {
    func withModelContainer() -> some View {
        modelContainer(for: [Draft.self, LocalTimeline.self, TagGroup.self])
    }
}
```

A single container avoids duplicated stores per sheet or tab and keeps data consistent.

### Sheet Routing (Enum-Driven)

Centralize sheets with a small enum and a helper modifier:

```swift
enum SheetDestination: Identifiable {
    case composer
    case settings
    var id: String { String(describing: self) }
}

extension View {
    func withSheetDestinations(sheet: Binding<SheetDestination?>) -> some View {
        sheet(item: sheet) { destination in
            switch destination {
            case .composer:
                ComposerView().withEnvironments()
            case .settings:
                SettingsView().withEnvironments()
            }
        }
    }
}
```

Enum-driven sheets keep presentation centralized and testable; adding a new sheet means one enum case and one switch branch.

### App Entry Point

```swift
@main
struct MyApp: App {
    @State var client = APIClient()
    @State var auth = Auth()
    @State var router = AppRouter(initialTab: .home)

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(client)
                .environment(auth)
                .environment(router)
        }
    }
}
```

### Deep Linking

Store `NavigationPath` as `Codable` for state restoration. Handle incoming URLs with `.onOpenURL`:

```swift
.onOpenURL { url in
    guard let route = Route(from: url) else { return }
    router.navigate(to: route)
}
```

See the `swiftui-navigation` skill for full URL routing patterns.

### When to Use

- Apps with multiple packages/modules that share environment objects and services
- Apps that need to react to account/client changes and rewire streaming/push safely
- Any app that wants consistent TabView + NavigationStack + sheet wiring without repeating environment setup

### Caveats

- Keep the dependency modifier slim; do not put feature state or heavy logic there
- Ensure `.task(id:)` work is lightweight or cancelled appropriately; long-running work belongs in services
- If unauthenticated clients exist, gate streaming/watch calls to avoid reconnect spam

## Lightweight Clients

Use this pattern to keep networking or service dependencies simple and testable without introducing a full view model or heavy DI framework. It works well for SwiftUI apps where you want a small, composable API surface that can be swapped in previews/tests.

### Intent
- Provide a tiny "client" type made of async closures.
- Keep business logic in a store or feature layer, not the view.
- Enable easy stubbing in previews/tests.

### Minimal shape
```swift
struct SomeClient {
    var fetchItems: (_ limit: Int) async throws -> [Item]
    var search: (_ query: String, _ limit: Int) async throws -> [Item]
}

extension SomeClient {
    static func live(baseURL: URL = URL(string: "https://example.com")!) -> SomeClient {
        let session = URLSession.shared  // Prototyping only. For production, create a URLSession with timeoutIntervalForRequest: 30, timeoutIntervalForResource: 300, waitsForConnectivity: true, and a URLCache.
        return SomeClient(
            fetchItems: { limit in
                // build URL, call session, decode
            },
            search: { query, limit in
                // build URL, call session, decode
            }
        )
    }
}
```

### Usage pattern
```swift
@MainActor
@Observable final class ItemsStore {
    enum LoadState { case idle, loading, loaded, failed(String) }

    var items: [Item] = []
    var state: LoadState = .idle
    private let client: SomeClient

    init(client: SomeClient) {
        self.client = client
    }

    func load(limit: Int = 20) async {
        state = .loading
        do {
            items = try await client.fetchItems(limit)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
```

```swift
struct ContentView: View {
    @Environment(ItemsStore.self) private var store

    var body: some View {
        List(store.items) { item in
            Text(item.title)
        }
        .task { await store.load() }
    }
}
```

```swift
@main
struct MyApp: App {
    @State private var store = ItemsStore(client: .live())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
```

### Guidance
- Keep decoding and URL-building in the client; keep state changes in the store.
- Make the store accept the client in `init` and keep it private.
- Avoid global singletons; use `.environment` for store injection.
- If you need multiple variants (mock/stub), add `static func mock(...)`.

### Pitfalls
- Don’t put UI state in the client; keep state in the store.
- Don’t capture `self` or view state in the client closures.
