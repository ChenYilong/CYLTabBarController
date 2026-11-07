# ObservableObject to @Observable Migration

The `@Observable` macro (iOS 17 / macOS 14) replaces the `ObservableObject` protocol with a simpler, more performant observation system. Views only re-render when properties they actually read change, rather than when any `@Published` property changes.

## Concept Mapping

| ObservableObject (Old) | @Observable (New) | Notes |
|----------------------|-------------------|-------|
| `class MyModel: ObservableObject` | `@Observable class MyModel` | Macro replaces protocol conformance |
| `@Published var name: String` | `var name: String` | Plain stored properties, no wrapper |
| `@StateObject private var model` | `@State private var model` | For owned instances |
| `@ObservedObject var model` | `var model: MyModel` (direct reference) | No property wrapper needed |
| `@EnvironmentObject var model` | `@Environment(MyModel.self) var model` | Or `@Environment(\.myModel)` with custom key |
| `objectWillChange.send()` | Automatic | No manual notification |
| `model.$name` (publisher) | `AsyncSequence` / `withObservationTracking` | No Combine dependency |
| `.environmentObject(model)` | `.environment(model)` | Direct injection |

## Basic Migration

### Before (ObservableObject)

```swift
class UserSettings: ObservableObject {
    @Published var username: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var theme: Theme = .system

    // Computed properties do not trigger updates
    var displayName: String {
        username.isEmpty ? "Anonymous" : username
    }

    func logOut() {
        isLoggedIn = false
        username = ""
    }
}
```

### After (@Observable)

```swift
@Observable
class UserSettings {
    var username: String = ""
    var isLoggedIn: Bool = false
    var theme: Theme = .system

    // Computed properties based on observed properties DO trigger updates
    var displayName: String {
        username.isEmpty ? "Anonymous" : username
    }

    func logOut() {
        isLoggedIn = false
        username = ""
    }
}
```

Key differences:
- Remove `ObservableObject` conformance. Add `@Observable` macro.
- Remove all `@Published` wrappers. Properties are plain stored properties.
- Computed properties that read observed properties now automatically trigger view updates. With `ObservableObject`, they did not.
- No manual `objectWillChange.send()` needed anywhere.

## View Property Wrapper Migration

### @StateObject to @State

`@StateObject` was needed to own an `ObservableObject` instance and keep it alive across view re-renders. With `@Observable`, use `@State`.

```swift
// Before
struct ContentView: View {
    @StateObject private var settings = UserSettings()

    var body: some View {
        SettingsView(settings: settings)
    }
}

// After
struct ContentView: View {
    @State private var settings = UserSettings()

    var body: some View {
        SettingsView(settings: settings)
    }
}
```

### @ObservedObject to Direct Reference

`@ObservedObject` subscribed a view to all `@Published` changes. With `@Observable`, a plain property reference is sufficient -- SwiftUI tracks which properties the view's `body` actually reads.

```swift
// Before
struct SettingsView: View {
    @ObservedObject var settings: UserSettings

    var body: some View {
        Text(settings.username)
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}

// After
struct SettingsView: View {
    var settings: UserSettings

    var body: some View {
        Text(settings.username)
        Toggle("Dark Mode", isOn: $settings.isDarkMode)  // Compiler error: need @Bindable
    }
}
```

### @Bindable for Bindings

When a view needs to create bindings (`$` syntax) to an `@Observable` object it does not own, use `@Bindable`:

```swift
// ✅ Correct: use @Bindable for bindings to non-owned @Observable
struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        TextField("Username", text: $settings.username)
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}
```

Decision guide for which wrapper to use:
- View **creates and owns** the object: `@State`
- View **receives** the object and needs **bindings**: `@Bindable`
- View **receives** the object and only **reads**: plain `var` (no wrapper)

### @EnvironmentObject to @Environment

```swift
// Before
// Injection:
ContentView()
    .environmentObject(settings)

// Usage:
struct ProfileView: View {
    @EnvironmentObject var settings: UserSettings

    var body: some View {
        Text(settings.username)
    }
}

// After
// Injection:
ContentView()
    .environment(settings)

// Usage:
struct ProfileView: View {
    @Environment(UserSettings.self) var settings

    var body: some View {
        Text(settings.username)
    }
}
```

If you need bindings to an environment-injected `@Observable` object, create a local `@Bindable`:

```swift
struct ProfileView: View {
    @Environment(UserSettings.self) var settings

    var body: some View {
        @Bindable var settings = settings
        TextField("Username", text: $settings.username)
    }
}
```

## Performance Benefits

With `ObservableObject`, any `@Published` property change re-renders every view observing that object, even if the view does not use the changed property.

With `@Observable`, SwiftUI tracks exactly which properties each view's `body` reads and only re-renders when those specific properties change.

```swift
@Observable
class AppState {
    var username: String = ""
    var itemCount: Int = 0
    var lastSyncDate: Date = .now
}

// This view only re-renders when `username` changes.
// Changes to `itemCount` or `lastSyncDate` do NOT cause re-render.
struct UsernameView: View {
    var state: AppState

    var body: some View {
        Text(state.username)
    }
}
```

With the old `ObservableObject`, this view would re-render on every `@Published` change.

## Combine Publishers to AsyncSequence

### Before (Combine)

```swift
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Item] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.search(query)
            }
            .store(in: &cancellables)
    }

    private func search(_ query: String) {
        // perform search
    }
}
```

### After (AsyncSequence)

```swift
@Observable
class SearchViewModel {
    var query: String = ""
    var results: [Item] = []

    // No Combine, no cancellables
}

// Debounce in the view using task
struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        List(viewModel.results) { item in
            Text(item.title)
        }
        .searchable(text: $viewModel.query)
        .task(id: viewModel.query) {
            // task(id:) restarts when query changes
            // Add a delay for debounce effect
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            viewModel.results = await performSearch(viewModel.query)
        }
    }
}
```

### Manual Observation (Outside SwiftUI)

For observing changes outside of SwiftUI views, use `withObservationTracking`:

```swift
func observeChanges(to settings: UserSettings) {
    withObservationTracking {
        // Access properties you want to track
        _ = settings.username
        _ = settings.theme
    } onChange: {
        // Called once when any tracked property changes
        // Must re-register to observe again
        print("Settings changed")
        observeChanges(to: settings)  // Re-register
    }
}
```

Note: `withObservationTracking` fires only once per registration. You must re-register in the `onChange` closure to continue observing. For continuous observation, consider `AsyncStream`:

```swift
extension UserSettings {
    var usernameChanges: AsyncStream<String> {
        AsyncStream { continuation in
            @Sendable func observe() {
                withObservationTracking {
                    continuation.yield(self.username)
                } onChange: {
                    observe()
                }
            }
            observe()
        }
    }
}
```

## Excluding Properties from Observation

If you have properties that should not trigger view updates:

```swift
@Observable
class ViewModel {
    var visibleProperty: String = ""  // Changes trigger updates

    @ObservationIgnored
    var internalCache: [String: Data] = [:]  // Changes do NOT trigger updates
}
```

## Coexistence Strategy

During migration, you may have both `ObservableObject` and `@Observable` classes. They can coexist:

```swift
// Old class, not yet migrated
class LegacySettings: ObservableObject {
    @Published var fontSize: Int = 14
}

// New class, already migrated
@Observable
class ModernSettings {
    var theme: Theme = .system
}

struct ContentView: View {
    @StateObject private var legacy = LegacySettings()
    @State private var modern = ModernSettings()

    var body: some View {
        ChildView(legacy: legacy, modern: modern)
    }
}

struct ChildView: View {
    @ObservedObject var legacy: LegacySettings
    var modern: ModernSettings

    var body: some View {
        Text("Font: \(legacy.fontSize)")
        Text("Theme: \(modern.theme.rawValue)")
    }
}
```

### Migration Order

1. Migrate models that are used by few views first.
2. Update each view that uses the migrated model (change `@StateObject` to `@State`, `@ObservedObject` to plain `var` or `@Bindable`, `@EnvironmentObject` to `@Environment`).
3. Remove Combine imports if no longer needed.
4. Repeat for the next model.

## When NOT to Migrate

Stay on `ObservableObject` if:

- Your minimum deployment target is below iOS 17 / macOS 14.
- You heavily use Combine pipelines (`$property.debounce.map.sink`) and prefer Combine's operator model. Note: you can still use Combine with `@Observable`, but `@Published` projections are not available.
- The class is stable, well-tested, and not causing performance issues. Migration is optional -- `ObservableObject` is not deprecated.
- You need to support watchOS 9 or tvOS 16 (these do not have `@Observable`).

## Common Mistakes

```swift
// ❌ Using @Published with @Observable (redundant, causes issues)
@Observable
class Settings {
    @Published var name: String = ""  // Wrong: @Published is for ObservableObject
}

// ✅ Plain stored properties with @Observable
@Observable
class Settings {
    var name: String = ""
}
```

```swift
// ❌ Using @ObservedObject with @Observable class
struct MyView: View {
    @ObservedObject var settings: Settings  // Wrong: @ObservedObject is for ObservableObject

    var body: some View {
        Text(settings.name)
    }
}

// ✅ Plain var or @Bindable with @Observable class
struct MyView: View {
    @Bindable var settings: Settings  // Use @Bindable if you need $ bindings

    var body: some View {
        TextField("Name", text: $settings.name)
    }
}
```

```swift
// ❌ Using @StateObject with @Observable class
struct ParentView: View {
    @StateObject private var settings = Settings()  // Wrong

    var body: some View { ChildView(settings: settings) }
}

// ✅ Use @State with @Observable class
struct ParentView: View {
    @State private var settings = Settings()

    var body: some View { ChildView(settings: settings) }
}
```

```swift
// ❌ Using .environmentObject with @Observable class
ContentView()
    .environmentObject(settings)  // Wrong: .environmentObject is for ObservableObject

// ✅ Use .environment with @Observable class
ContentView()
    .environment(settings)
```

```swift
// ❌ Forgetting @Bindable when creating bindings to @Environment observable
struct ProfileView: View {
    @Environment(Settings.self) var settings

    var body: some View {
        TextField("Name", text: $settings.name)  // Compiler error
    }
}

// ✅ Create local @Bindable
struct ProfileView: View {
    @Environment(Settings.self) var settings

    var body: some View {
        @Bindable var settings = settings
        TextField("Name", text: $settings.name)
    }
}
```

## Checklist

- [ ] Minimum deployment target is iOS 17 / macOS 14
- [ ] `ObservableObject` protocol replaced with `@Observable` macro
- [ ] All `@Published` property wrappers removed
- [ ] `@StateObject` replaced with `@State`
- [ ] `@ObservedObject` replaced with plain `var` or `@Bindable`
- [ ] `@EnvironmentObject` replaced with `@Environment(Type.self)`
- [ ] `.environmentObject()` replaced with `.environment()`
- [ ] `@Bindable` used where `$` bindings are needed
- [ ] Manual `objectWillChange.send()` calls removed
- [ ] Combine `$property` publishers replaced with `task(id:)` or `AsyncStream`
- [ ] `AnyCancellable` sets removed if Combine is no longer used
- [ ] `@ObservationIgnored` added to properties that should not trigger updates
