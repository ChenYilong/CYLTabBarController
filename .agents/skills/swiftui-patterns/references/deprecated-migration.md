# Deprecated API Migration Guide

A comprehensive mapping of deprecated, legacy, or fragile SwiftUI and iOS patterns to modern defaults from iOS 15 through iOS 26. Each section shows the old pattern, the modern replacement, and migration notes. Target iOS 26 with Swift 6.3; backward-compatible to iOS 16 unless noted.

## Contents
- NavigationView to NavigationStack
- NavigationView Sidebar to NavigationSplitView
- ObservableObject / `@Published` / `@StateObject` to `@Observable` / `@State`
- `@ObservedObject` to let / `@Bindable`
- `@EnvironmentObject` to `@Environment`
- foregroundColor to foregroundStyle
- .onChange single-value to two-value
- ActionSheet to confirmationDialog
- Alert (Legacy) to modern .alert
- AnyView to `@ViewBuilder`
- .onAppear + Task to .task
- presentationMode to dismiss
- GeometryReader to Layout / containerRelativeFrame
- PreviewProvider to #Preview
- XCTest to Swift Testing
- List row actions: EditButton/.onDelete/.swipeActions
- UIApplication.shared.open to openURL
- `@FetchRequest` to `@Query` (SwiftData)
- some vs any return types
- .sheet(item:) for sheet presentation
- Color.resolve(in:) usage
- ForEach with Identifiable
- Toolbar placement updates

## NavigationView to NavigationStack

NavigationView was deprecated in iOS 16. Use NavigationStack for push-based navigation with a single column, or NavigationSplitView for multi-column layouts.

### Before (Deprecated)

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            List(items) { item in
                NavigationLink(destination: DetailView(item: item)) {
                    Text(item.title)
                }
            }
            .navigationTitle("Items")
        }
        .navigationViewStyle(.stack)
    }
}
```

### After (Modern)

```swift
struct ContentView: View {
    @State private var path: [Item] = []

    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: item) {
                    Text(item.title)
                }
            }
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                DetailView(item: item)
            }
        }
    }
}
```

### Migration Notes

NavigationStack gives you programmatic control over the navigation path via a binding. Value-based NavigationLink separates the trigger from the destination, keeping list rows lightweight. The `.navigationViewStyle(.stack)` modifier is no longer needed.

---

## NavigationView Sidebar to NavigationSplitView

### Before (Deprecated)

```swift
struct SidebarApp: View {
    var body: some View {
        NavigationView {
            SidebarList()
            DetailPlaceholder()
        }
        .navigationViewStyle(.columns)
    }
}
```

### After (Modern)

```swift
struct SidebarApp: View {
    @State private var selectedCategory: Category?
    @State private var selectedItem: Item?

    var body: some View {
        NavigationSplitView {
            List(categories, selection: $selectedCategory) { category in
                Label(category.name, systemImage: category.icon)
            }
            .navigationTitle("Categories")
        } content: {
            if let category = selectedCategory {
                List(category.items, selection: $selectedItem) { item in
                    Text(item.title)
                }
            } else {
                ContentUnavailableView("Select a Category",
                                       systemImage: "sidebar.left")
            }
        } detail: {
            if let item = selectedItem {
                DetailView(item: item)
            } else {
                ContentUnavailableView("Select an Item",
                                       systemImage: "doc.text")
            }
        }
    }
}
```

### Migration Notes

NavigationSplitView explicitly models two-column and three-column layouts. Column visibility is controlled via `NavigationSplitViewVisibility` and `columnVisibility` bindings. On compact size classes the split view collapses into a NavigationStack automatically.

---

## ObservableObject / `@Published` / `@StateObject` to `@Observable` / `@State`

The Observation framework (iOS 17+) replaces Combine-based observation. Classes annotated with `@Observable` track property access automatically -- no `@Published` wrappers needed.

### Before (Superseded)

```swift
class UserSettings: ObservableObject {
    @Published var username: String = ""
    @Published var notificationsEnabled: Bool = true
    @Published var theme: Theme = .system

    func resetToDefaults() {
        username = ""
        notificationsEnabled = true
        theme = .system
    }
}

struct SettingsView: View {
    @StateObject private var settings = UserSettings()

    var body: some View {
        Form {
            TextField("Username", text: $settings.username)
            Toggle("Notifications", isOn: $settings.notificationsEnabled)
            Picker("Theme", selection: $settings.theme) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
        }
    }
}
```

### After (Modern)

```swift
@Observable
class UserSettings {
    var username: String = ""
    var notificationsEnabled: Bool = true
    var theme: Theme = .system

    func resetToDefaults() {
        username = ""
        notificationsEnabled = true
        theme = .system
    }
}

struct SettingsView: View {
    @State private var settings = UserSettings()

    var body: some View {
        Form {
            TextField("Username", text: $settings.username)
            Toggle("Notifications", isOn: $settings.notificationsEnabled)
            Picker("Theme", selection: $settings.theme) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
        }
    }
}
```

### Migration Notes

- Replace `ObservableObject` conformance with the `@Observable` macro.
- Remove all `@Published` property wrappers -- observation is automatic.
- Replace `@StateObject` with `@State` for owned instances.
- Computed properties that depend on stored properties are tracked automatically.
- The view only re-evaluates when properties it actually reads change, so fine-grained observation is free.
- **Requires iOS 17+ minimum deployment target.** `ObservableObject` is not formally deprecated (no compiler warning) -- it is superseded. Do not rewrite working `ObservableObject` code if the project targets iOS 16 or earlier.

---

## `@ObservedObject` to let / `@Bindable`

### Before (Superseded)

```swift
struct ProfileEditor: View {
    @ObservedObject var profile: ProfileModel

    var body: some View {
        TextField("Name", text: $profile.name)
        Toggle("Public", isOn: $profile.isPublic)
    }
}
```

### After (Modern)

When you only need to read properties, use a plain `let`:

```swift
struct ProfileDisplay: View {
    let profile: ProfileModel  // @Observable class

    var body: some View {
        Text(profile.name)
        Text(profile.isPublic ? "Public" : "Private")
    }
}
```

When you need to create bindings, use `@Bindable`:

```swift
struct ProfileEditor: View {
    @Bindable var profile: ProfileModel

    var body: some View {
        TextField("Name", text: $profile.name)
        Toggle("Public", isOn: $profile.isPublic)
    }
}
```

### Migration Notes

With `@Observable`, you no longer need `@ObservedObject` to subscribe to changes. A plain `let` constant already triggers view updates when read properties change. Use `@Bindable` only when you need two-way bindings via `$` syntax.

---

## `@EnvironmentObject` to `@Environment`

### Before (Superseded)

```swift
// Injection
ContentView()
    .environmentObject(authManager)

// Usage
struct ContentView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        if auth.isLoggedIn {
            HomeView()
        } else {
            LoginView()
        }
    }
}
```

### After (Modern)

```swift
// Injection
ContentView()
    .environment(authManager)

// Usage
struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        if auth.isLoggedIn {
            HomeView()
        } else {
            LoginView()
        }
    }
}
```

### Migration Notes

With `@Observable`, use `.environment(_:)` (the type-keyed overload) instead of `.environmentObject(_:)`. Read with `@Environment(Type.self)`. If you need bindings from an environment-injected object, pull it into a local `@Bindable`:

```swift
struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        @Bindable var auth = auth
        Toggle("Remember Me", isOn: $auth.rememberMe)
    }
}
```

---

## foregroundColor(_:) to foregroundStyle(_:)

`foregroundColor(_:)` was deprecated in iOS 17. Its replacement, `foregroundStyle(_:)`, accepts any `ShapeStyle` -- not just `Color` -- enabling gradients, hierarchical styles, and materials directly.

### Before (Deprecated)

```swift
Text("Hello")
    .foregroundColor(.red)

Text("Secondary")
    .foregroundColor(.secondary)
```

### After (Modern)

```swift
Text("Hello")
    .foregroundStyle(.red)

Text("Secondary")
    .foregroundStyle(.secondary)

// Gradient -- not possible with foregroundColor
Text("Gradient")
    .foregroundStyle(
        .linearGradient(colors: [.blue, .purple],
                        startPoint: .leading, endPoint: .trailing)
    )
```

### Migration Notes

`foregroundStyle(_:)` is a drop-in replacement when passing a `Color`. The broader `ShapeStyle` conformance also accepts gradients, `.tint`, `.selection`, and hierarchical styles (`.primary`, `.secondary`, `.tertiary`, `.quaternary`). Multi-level variants `foregroundStyle(_:_:)` and `foregroundStyle(_:_:_:)` set hierarchical styles for child content in one call.

**Not to be confused with** `NSAttributedString.Key.foregroundColor` -- that is a UIKit/Foundation attributed-string key used for Core Text, `NSAttributedString`, and PDF rendering. It is not deprecated and has no SwiftUI equivalent.

---

## .onChange(of:perform:) to Modern onChange

The single-value `onChange` closure was deprecated in iOS 17. Modern overloads can run a zero-argument closure or provide both old and new values.

### Before (Deprecated)

```swift
.onChange(of: searchText) { newValue in
    performSearch(newValue)
}
```

### After (Modern: new value only)

```swift
.onChange(of: searchText) {
    performSearch(searchText)
}
```

### After (Modern: compare old and new)

```swift
.onChange(of: searchText) { oldValue, newValue in
    performSearch(newValue)
}
```

If you only need the new value, use `_` for the old value:

```swift
.onChange(of: searchText) { _, newValue in
    performSearch(newValue)
}
```

### Migration Notes

The two-value variant lets you compare old and new values inline without maintaining extra state. The `initial` parameter is also available if you need the callback to fire on first appearance:

```swift
.onChange(of: searchText, initial: true) { _, newValue in
    performSearch(newValue)
}
```

---

## ActionSheet to confirmationDialog

### Before (Deprecated)

```swift
.actionSheet(isPresented: $showingOptions) {
    ActionSheet(
        title: Text("Choose an action"),
        message: Text("Select one of the options below"),
        buttons: [
            .default(Text("Share")) { shareItem() },
            .destructive(Text("Delete")) { deleteItem() },
            .cancel()
        ]
    )
}
```

### After (Modern)

```swift
.confirmationDialog("Choose an action",
                     isPresented: $showingOptions,
                     titleVisibility: .visible) {
    Button("Share") { shareItem() }
    Button("Delete", role: .destructive) { deleteItem() }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("Select one of the options below")
}
```

### Migration Notes

`.confirmationDialog` uses standard SwiftUI `Button` views with roles instead of an array of `ActionSheet.Button`. The `titleVisibility` parameter controls whether the title appears (it is hidden by default on iOS). A cancel-role button is added automatically if you omit one.

---

## Alert (Legacy) to Modern .alert with Actions

### Before (Deprecated)

```swift
.alert(isPresented: $showingAlert) {
    Alert(
        title: Text("Delete Item?"),
        message: Text("This action cannot be undone."),
        primaryButton: .destructive(Text("Delete")) { deleteItem() },
        secondaryButton: .cancel()
    )
}
```

### After (Modern)

```swift
.alert("Delete Item?", isPresented: $showingAlert) {
    Button("Delete", role: .destructive) { deleteItem() }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This action cannot be undone.")
}
```

With a data item:

```swift
.alert("Delete Item?", isPresented: $showingAlert, presenting: itemToDelete) { item in
    Button("Delete", role: .destructive) { delete(item) }
} message: { item in
    Text("Delete \"\(item.title)\"? This cannot be undone.")
}
```

### Migration Notes

The modern alert API accepts a `presenting` parameter to pass data directly into the alert closures, eliminating the need for separate optional state tracking.

---

## AnyView to `@ViewBuilder` and Concrete Types

### Before (Type-Erased Pattern)

```swift
func destination(for route: Route) -> AnyView {
    switch route {
    case .home: return AnyView(HomeView())
    case .profile: return AnyView(ProfileView())
    case .settings: return AnyView(SettingsView())
    }
}
```

### After (Modern)

```swift
@ViewBuilder
func destination(for route: Route) -> some View {
    switch route {
    case .home: HomeView()
    case .profile: ProfileView()
    case .settings: SettingsView()
    }
}
```

### Migration Notes

`AnyView` erases type information and hides useful view structure from SwiftUI. `@ViewBuilder` preserves concrete types, helping the framework reason about identity, updates, and transitions. Avoid `AnyView` unless interfacing with APIs that genuinely require heterogeneous view storage.

---

## .onAppear + Manual Task to .task

### Before (Manual Lifecycle Pattern)

```swift
struct FeedView: View {
    @State private var posts: [Post] = []

    var body: some View {
        List(posts) { post in
            PostRow(post: post)
        }
        .onAppear {
            Task {
                posts = try await fetchPosts()
            }
        }
    }
}
```

### After (Modern)

```swift
struct FeedView: View {
    @State private var posts: [Post] = []

    var body: some View {
        List(posts) { post in
            PostRow(post: post)
        }
        .task {
            do {
                posts = try await fetchPosts()
            } catch {
                // handle error
            }
        }
    }
}
```

### Migration Notes

`.task` automatically cancels the async work when the view disappears, preventing retain cycles and stale updates. Use `.task(id:)` to re-run the task when a dependency changes:

```swift
.task(id: selectedCategory) {
    posts = try? await fetchPosts(for: selectedCategory)
}
```

---

## `@Environment(\.presentationMode)` to `@Environment(\.dismiss)`

### Before (Deprecated)

```swift
struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
```

### After (Modern)

```swift
struct DetailView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("Done") {
            dismiss()
        }
    }
}
```

### Migration Notes

`dismiss` is a callable `DismissAction`. Call it directly -- no `.wrappedValue` needed. Works for sheets, full-screen covers, and navigation push destinations.

---

## GeometryReader Overuse to Layout Protocol and containerRelativeFrame

GeometryReader has performance costs and complicates layout. iOS 16 introduced the Layout protocol, and iOS 17 added `containerRelativeFrame` for proportional sizing.

### Before (Fragile Layout Pattern)

```swift
GeometryReader { proxy in
    HStack(spacing: 0) {
        SidePanel()
            .frame(width: proxy.size.width * 0.3)
        MainContent()
            .frame(width: proxy.size.width * 0.7)
    }
}
```

### After (Modern) -- containerRelativeFrame (iOS 17+)

```swift
HStack(spacing: 0) {
    SidePanel()
        .containerRelativeFrame(.horizontal) { length, _ in
            length * 0.3
        }
    MainContent()
        .containerRelativeFrame(.horizontal) { length, _ in
            length * 0.7
        }
}
```

### After (Modern) -- Custom Layout (iOS 16+)

```swift
struct ProportionalHStack: Layout {
    var ratios: [CGFloat]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == ratios.count else { return }
        var x = bounds.minX
        for (index, subview) in subviews.enumerated() {
            let width = bounds.width * ratios[index]
            subview.place(at: CGPoint(x: x, y: bounds.minY),
                          proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width
        }
    }
}

// Usage
ProportionalHStack(ratios: [0.3, 0.7]) {
    SidePanel()
    MainContent()
}
```

### Migration Notes

GeometryReader is still appropriate when you genuinely need to read the proposed size and cannot express the layout declaratively. For proportional sizing, prefer `containerRelativeFrame`. For custom arrangements, prefer the Layout protocol. Both avoid the bottom-up sizing behavior that makes GeometryReader tricky to compose.

---

## PreviewProvider to #Preview Macro

### Before (Legacy)

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")

        ContentView()
            .preferredColorScheme(.dark)
    }
}
```

### After (Modern)

```swift
#Preview("Light Mode") {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
```

Widget and UIKit previews:

```swift
#Preview("Timeline Entry", as: .systemSmall) {
    MyWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview("UIKit Controller") {
    let vc = MyViewController()
    vc.title = "Preview"
    return vc
}
```

### Migration Notes

The `#Preview` macro (iOS 17+) is less boilerplate and supports naming each preview directly. It works with SwiftUI views, UIKit view controllers, and WidgetKit timelines. For modern targets, replace `PreviewProvider` structs with `#Preview` blocks.

---

## XCTest to Swift Testing

Swift Testing (Xcode 16+) provides a modern, expressive test framework that coexists with XCTest.

### Before (XCTest)

```swift
import XCTest
@testable import MyApp

final class CartTests: XCTestCase {
    var cart: Cart!

    override func setUp() {
        cart = Cart()
    }

    override func tearDown() {
        cart = nil
    }

    func testAddItem() throws {
        cart.add(Item(name: "Widget", price: 9.99))
        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.total, 9.99, accuracy: 0.01)
    }

    func testEmptyCartTotal() {
        XCTAssertEqual(cart.total, 0)
    }

    func testDiscountCodes() throws {
        let codes = ["SAVE10", "SAVE20", "SAVE50"]
        for code in codes {
            cart.applyDiscount(code: code)
            XCTAssertTrue(cart.hasDiscount)
        }
    }
}
```

### After (Swift Testing)

```swift
import Testing
@testable import MyApp

@Suite("Cart Tests")
struct CartTests {
    let cart = Cart()

    @Test("Adding an item updates count and total")
    func addItem() {
        cart.add(Item(name: "Widget", price: 9.99))
        #expect(cart.items.count == 1)
        #expect(cart.total.isApproximatelyEqual(to: 9.99))
    }

    @Test("Empty cart has zero total")
    func emptyCartTotal() {
        #expect(cart.total == 0)
    }

    @Test("Discount codes", arguments: ["SAVE10", "SAVE20", "SAVE50"])
    func discountCodes(code: String) {
        cart.applyDiscount(code: code)
        #expect(cart.hasDiscount)
    }
}
```

### Migration Notes

- Replace `XCTestCase` subclass with a plain struct annotated with `@Suite`.
- Replace `setUp` / `tearDown` with an initializer and deinit (or just inline setup).
- Replace `XCTAssert*` macros with `#expect(...)` and `#require(...)`.
- Use `@Test("description", arguments:)` for parameterized tests instead of manual loops.
- Swift Testing and XCTest targets can coexist in the same project during migration.
- Use `@Test(.disabled("reason"))` instead of `XCTSkip`.

---

## List Row Actions with EditButton, .onDelete, .onMove, and .swipeActions

### Basic Edit Mode Pattern

```swift
struct ItemList: View {
    @State private var items = ["A", "B", "C"]

    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
                .onDelete { items.remove(atOffsets: $0) }
                .onMove { items.move(fromOffsets: $0, toOffset: $1) }
            }
            .navigationTitle("Items")
            .toolbar { EditButton() }
        }
    }
}
```

### Contextual Swipe Actions

```swift
struct ItemList: View {
    @State private var items = ["A", "B", "C"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                if let index = items.firstIndex(of: item) {
                                    items.remove(at: index)
                                }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Pin", systemImage: "pin") {
                                pinItem(item)
                            }
                            .tint(.orange)
                        }
                }
                .onMove { items.move(fromOffsets: $0, toOffset: $1) }
            }
            .navigationTitle("Items")
            .toolbar { EditButton() }
        }
    }
}
```

### Migration Notes

`.swipeActions` (iOS 15+) gives you per-row, multi-action swipe menus with custom tints and roles. `EditButton`, `.onDelete`, and `.onMove` remain valid for edit mode and reordering. Prefer `.swipeActions` when the desired interaction is a contextual row action, and keep edit mode when users need batch delete or reorder workflows.

---

## UIApplication.shared.open to `@Environment(\.openURL)`

### Before (App-Coupled Pattern)

```swift
Button("Open Website") {
    if let url = URL(string: "https://example.com") {
        UIApplication.shared.open(url)
    }
}
```

### After (Modern)

```swift
struct LinkButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button("Open Website") {
            openURL(URL(string: "https://example.com")!)
        }
    }
}
```

With a completion handler:

```swift
openURL(url) { accepted in
    if !accepted {
        // handle failure to open URL
    }
}
```

### Migration Notes

`@Environment(\.openURL)` works on all Apple platforms, not just iOS. It can be overridden in the environment for testing or to intercept URL opens. Avoid reaching for `UIApplication.shared` in SwiftUI views.

---

## `@FetchRequest` to `@Query` (SwiftData)

Core Data's `@FetchRequest` is superseded by SwiftData's `@Query` macro when you migrate to SwiftData models.

### Before (Core Data)

```swift
struct ItemListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDItem.timestamp, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == NO")
    ) private var items: FetchedResults<CDItem>

    var body: some View {
        List(items) { item in
            Text(item.title ?? "")
        }
    }
}
```

### After (SwiftData)

```swift
struct ItemListView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isCompleted },
        sort: \.timestamp,
        order: .reverse
    ) private var items: [Item]

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }
}
```

### Migration Notes

`@Query` uses type-safe `#Predicate` instead of string-based `NSPredicate`. Sort descriptors use key paths directly. The model container is injected via `.modelContainer(for:)` on an ancestor view. SwiftData models are plain Swift classes with the `@Model` macro rather than NSManagedObject subclasses.

---

## Opaque return types to some/any clarifications (Swift 5.7+)

### Before

```swift
func makeView() -> AnyView {
    AnyView(Text("Hello"))
}

protocol DataSource {
    func fetch() -> AnyPublisher<[Item], Error>
}
```

### After (Modern)

```swift
func makeView() -> some View {
    Text("Hello")
}

protocol DataSource {
    func fetch() async throws -> [Item]
}

// When you need a protocol-typed variable:
let source: any DataSource = RemoteDataSource()
```

### Migration Notes

Use `some` for opaque return types when the concrete type is fixed. Use `any` for existentials when you need to store heterogeneous conformances. Prefer `async throws` over Combine publishers for new code. Swift 5.7+ allows `some` in parameter position too:

```swift
func display(_ view: some View) { ... }
```

---

## .sheet(item:) with Optional Identifiable to Modern Pattern

### Before (Fragile Pattern)

```swift
@State private var selectedItem: Item?
@State private var showingSheet = false

Button {
    selectedItem = item
    showingSheet = true
} label: {
    ItemRow(item: item)
}
.buttonStyle(.plain)
.sheet(isPresented: $showingSheet) {
    if let item = selectedItem {
        DetailView(item: item)
    }
}
```

### After (Modern)

```swift
@State private var selectedItem: Item?

Button {
    selectedItem = item
} label: {
    ItemRow(item: item)
}
.buttonStyle(.plain)
.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}
```

### Migration Notes

Using `.sheet(item:)` eliminates the dual-state problem where `showingSheet` and `selectedItem` can become out of sync. The sheet presents when the binding becomes non-nil and dismisses when it becomes nil. The unwrapped value is passed directly into the closure.

---

## Resolving SwiftUI Color for Interop (iOS 17+)

### Before

```swift
let color = UIColor.link
let swiftUIColor = Color(uiColor: color)
```

### After (Modern)

`Color(uiColor:)` is still valid when bridging an existing UIKit color. For concrete RGBA values from SwiftUI colors, resolve the color in the current environment:

```swift
// Custom colors via asset catalogs (always preferred)
let brand = Color("BrandBlue")

// Resolved colors for interop (iOS 17+)
@Environment(\.self) var environment

let resolved = Color.blue.resolve(in: environment)
// resolved.red, resolved.green, resolved.blue, resolved.opacity
```

### Migration Notes

`Color.resolve(in:)` (iOS 17+) gives you concrete RGBA values in the current environment. Use it for custom runtime color manipulations or lower-level interop. For static brand colors, use asset catalogs; for UIKit colors you already have, keep `Color(uiColor:)`.

---

## ForEach with Range to ForEach with Identifiable / indices

### Before (Fragile Pattern)

```swift
ForEach(0..<items.count) { index in
    Text(items[index].name)
}
```

### After (Modern)

```swift
// Identifiable models
ForEach(items) { item in
    Text(item.name)
}

// When you need the index
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    Text("\(index + 1). \(item.name)")
}

// Subranges with bindable access
ForEach($items) { $item in
    TextField("Name", text: $item.name)
}
```

### Migration Notes

Constant-range `ForEach(0..<n)` is only safe when the range never changes. For dynamic data, always use identifiable collections. `ForEach($items)` provides direct bindings to each element without index arithmetic.

---

## Toolbar Placement Names (iOS 16+)

### Before

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") { dismiss() }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Edit") { isEditing.toggle() }
    }
    ToolbarItem(placement: .bottomBar) {
        Button("Add") { addItem() }
    }
}
```

### After (Modern)

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button("Back") { dismiss() }
    }
    ToolbarItem(placement: .topBarTrailing) {
        Button("Edit") { isEditing.toggle() }
    }
    ToolbarItem(placement: .bottomBar) {
        Button("Add") { addItem() }
    }
}
```

### Migration Notes

Prefer `.topBarLeading` and `.topBarTrailing` (iOS 16+) in modern `NavigationStack` and `NavigationSplitView` contexts. The names describe placement without tying the item to a specific navigation-bar implementation.

---

## cornerRadius to clipShape(.rect(cornerRadius:))

`.cornerRadius(_:)` was deprecated in iOS 17.

### Before (Deprecated)

```swift
RoundedRectangle(cornerRadius: 12)
    .cornerRadius(12)

Image("photo")
    .cornerRadius(8)
```

### After (Modern)

```swift
RoundedRectangle(cornerRadius: 12)
    .clipShape(.rect(cornerRadius: 12))

Image("photo")
    .clipShape(.rect(cornerRadius: 8))
```

### Migration Notes

`clipShape(.rect(cornerRadius:))` uses `RoundedRectangle` under the hood and also supports `cornerRadii` for per-corner control (iOS 16+):

```swift
.clipShape(.rect(cornerRadii: .init(topLeading: 12, bottomTrailing: 12)))
```

---

## tabItem to Tab (iOS 18+)

The `tabItem` modifier approach was superseded by the `Tab` type inside `TabView` (iOS 18+).

### Before (Legacy)

```swift
TabView {
    HomeView()
        .tabItem {
            Label("Home", systemImage: "house")
        }
    SettingsView()
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
}
```

### After (Modern — iOS 18+)

```swift
TabView {
    Tab("Home", systemImage: "house") {
        HomeView()
    }
    Tab("Settings", systemImage: "gear") {
        SettingsView()
    }
}
```

### Migration Notes

`Tab` provides a cleaner API and is required for the new tab sidebar on iPadOS 18+. The `tabItem` modifier still works but does not support the sidebar presentation. Use `Tab` with a `value` parameter and `@State` selection for programmatic tab switching. `TabSection` groups tabs in the sidebar.

---

## scrollIndicators(.hidden) Replaces showsIndicators Parameter

The `showsIndicators` parameter on `ScrollView` is available but the `scrollIndicators` modifier (iOS 16+) is preferred for consistency.

### Before

```swift
ScrollView(.vertical, showsIndicators: false) {
    content
}
```

### After (Modern)

```swift
ScrollView {
    content
}
.scrollIndicators(.hidden)
```

### Migration Notes

`.scrollIndicators(_:axes:)` accepts `.automatic`, `.visible`, `.hidden`, and `.never`. It also works on `List` and `TextEditor`. The `axes` parameter lets you control horizontal and vertical indicators independently.
