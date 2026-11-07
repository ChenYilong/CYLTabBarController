# UIKit to SwiftUI Migration

SwiftUI is Apple's declarative UI framework. Migration from UIKit is best done incrementally -- screen by screen -- using bridging APIs that let both frameworks coexist.

## Concept Mapping

| UIKit | SwiftUI | Notes |
|-------|---------|-------|
| `UIViewController` | `View` struct | No lifecycle methods, use `onAppear`/`task` |
| `UINavigationController` | `NavigationStack` | iOS 16+ for modern API |
| `UITabBarController` | `TabView` | iOS 18+ for customizable tabs |
| `UITableView` | `List` | Automatic diffing, no data source protocol |
| `UICollectionView` | `LazyVGrid` / `LazyHGrid` | Or `List` for simple layouts |
| `UIStackView` | `VStack` / `HStack` / `ZStack` | Declarative, no constraints |
| `UILabel` | `Text` | Supports Markdown, attributed strings |
| `UIButton` | `Button` | Action closure, not target-action |
| `UITextField` | `TextField` | Two-way binding with `$` |
| `UITextView` | `TextEditor` | iOS 16+ for styled editing |
| `UIImageView` | `Image` / `AsyncImage` | `AsyncImage` for remote URLs |
| `UIAlertController` | `.alert()` / `.confirmationDialog()` | View modifier, not presented |
| `UIActivityIndicatorView` | `ProgressView` | Determinate and indeterminate |
| Auto Layout constraints | Stack-based layout | No explicit constraints |
| Storyboards / XIBs | Swift code (declarative) | No Interface Builder |
| Delegate pattern | Closures, bindings, `@Environment` | No protocol conformance needed |
| `viewDidLoad` | `onAppear` / `task` | `task` for async work |
| `viewWillAppear` | `onAppear` | Called on every appearance |
| `viewDidDisappear` | `onDisappear` | Called on every disappearance |
| `prepare(for segue:)` | `NavigationLink(value:)` | Type-safe navigation |

## UIHostingController: Embedding SwiftUI in UIKit

This is the primary tool for incremental migration. Wrap any SwiftUI view in a `UIHostingController` to use it inside a UIKit app.

### Basic Usage

```swift
import SwiftUI

class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let swiftUIView = ItemListView()
        let hostingController = UIHostingController(rootView: swiftUIView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
}
```

### Passing Data Back to UIKit

Use closures or a shared `@Observable` model:

```swift
// Closure approach
struct ItemListView: View {
    var onItemSelected: (Item) -> Void

    var body: some View {
        List(items) { item in
            Button(item.title) {
                onItemSelected(item)
            }
        }
    }
}

// In UIKit
let view = ItemListView { [weak self] item in
    self?.navigateToDetail(item)
}
let hostingController = UIHostingController(rootView: view)
```

```swift
// @Observable approach (iOS 17+)
@Observable
class AppState {
    var selectedItem: Item?
}

// Shared between UIKit and SwiftUI
let state = AppState()

// SwiftUI reads/writes state
struct ItemListView: View {
    @Bindable var state: AppState

    var body: some View {
        List(items) { item in
            Button(item.title) { state.selectedItem = item }
        }
    }
}

// UIKit observes changes via withObservationTracking or KVO
```

### Sizing

By default, `UIHostingController` sizes to fit its content. To control sizing:

```swift
hostingController.sizingOptions = .preferredContentSize  // Uses preferredContentSize
hostingController.view.invalidateIntrinsicContentSize()
```

## UIViewRepresentable: Wrapping UIKit Views in SwiftUI

Use this when UIKit has a component SwiftUI does not (e.g., `MKMapView`, `WKWebView`, custom UIKit views).

### Basic Pattern

```swift
struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
            // Handle selection
        }
    }
}
```

Key points:
- `makeUIView` creates the UIKit view once.
- `updateUIView` is called when SwiftUI state changes -- update the UIKit view here.
- `Coordinator` bridges UIKit delegate callbacks to SwiftUI.
- Never store SwiftUI state in the coordinator; pass it through the representable.

### Common Mistake: Not Using Coordinator for Delegates

```swift
// ❌ Setting delegate to self (View is a struct, can't be a delegate)
struct MapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = self  // Compiler error: struct cannot conform to NSObjectProtocol
        return mapView
    }
}

// ✅ Use Coordinator
struct MapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate { }
}
```

## UIViewControllerRepresentable: Wrapping UIKit View Controllers in SwiftUI

For embedding entire UIKit view controllers (e.g., `UIImagePickerController`, `PHPickerViewController`):

```swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let provider = results.first?.itemProvider,
               provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
            parent.dismiss()
        }
    }
}
```

## Navigation Migration

### Before (UIKit)

```swift
class ItemListViewController: UITableViewController {
    var items: [Item] = []

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        let detailVC = ItemDetailViewController(item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
```

### After (SwiftUI)

```swift
struct ItemListView: View {
    let items: [Item]

    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}
```

### Tab Bar Migration

```swift
// Before (UIKit)
let tabBarController = UITabBarController()
tabBarController.viewControllers = [
    UINavigationController(rootViewController: HomeViewController()),
    UINavigationController(rootViewController: SearchViewController()),
    UINavigationController(rootViewController: ProfileViewController()),
]

// After (SwiftUI, iOS 18+)
TabView {
    Tab("Home", systemImage: "house") {
        NavigationStack { HomeView() }
    }
    Tab("Search", systemImage: "magnifyingglass") {
        NavigationStack { SearchView() }
    }
    Tab("Profile", systemImage: "person") {
        NavigationStack { ProfileView() }
    }
}
```

## Table View / Collection View Migration

### UITableView to List

```swift
// Before (UIKit) -- requires UITableViewDataSource, UITableViewDelegate
class ItemListViewController: UITableViewController {
    var items: [Item] = []

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].title
        return cell
    }
}

// After (SwiftUI) -- no data source, no cell reuse, no index paths
struct ItemListView: View {
    let items: [Item]

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }
}
```

### UICollectionView to LazyVGrid

```swift
// Before (UIKit) -- UICollectionViewDataSource, UICollectionViewFlowLayout, etc.
// (50+ lines of boilerplate)

// After (SwiftUI)
struct PhotoGrid: View {
    let photos: [Photo]
    let columns = [GridItem(.adaptive(minimum: 100))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    AsyncImage(url: photo.url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }
}
```

## Delegate Pattern Migration

### Before (UIKit Delegate)

```swift
protocol ItemSelectionDelegate: AnyObject {
    func didSelectItem(_ item: Item)
    func didDeselectItem(_ item: Item)
}

class ItemPickerViewController: UIViewController {
    weak var delegate: ItemSelectionDelegate?

    func selectItem(_ item: Item) {
        delegate?.didSelectItem(item)
    }
}
```

### After (SwiftUI Closure / Binding)

```swift
// Option 1: Closure
struct ItemPicker: View {
    let items: [Item]
    var onSelect: (Item) -> Void

    var body: some View {
        List(items) { item in
            Button(item.title) { onSelect(item) }
        }
    }
}

// Usage
ItemPicker(items: items) { item in
    selectedItem = item
}
```

```swift
// Option 2: Binding (two-way)
struct ItemPicker: View {
    let items: [Item]
    @Binding var selection: Item?

    var body: some View {
        List(items, selection: $selection) { item in
            Text(item.title)
        }
    }
}

// Usage
@State private var selection: Item?
ItemPicker(items: items, selection: $selection)
```

## Lifecycle Migration

```swift
// UIKit lifecycle
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelTasks()
    }
}

// SwiftUI equivalent
struct MyView: View {
    @State private var data: [Item] = []

    var body: some View {
        List(data) { item in
            ItemRow(item: item)
        }
        .task {
            // Replaces viewDidLoad for async work
            // Automatically cancelled when view disappears
            data = await loadInitialData()
        }
        .onAppear {
            // Replaces viewWillAppear for sync work
            refreshData()
        }
        .onDisappear {
            // Replaces viewDidDisappear
            cancelTasks()
        }
    }
}
```

Key differences:
- `task` is preferred over `onAppear` for async work. It is automatically cancelled when the view is removed.
- SwiftUI views are structs, not classes. No inheritance, no `super` calls.
- There is no `viewDidLoad` equivalent because SwiftUI views are recreated frequently. Use `task` or `onAppear`.

## Incremental Adoption Strategy

### Recommended Order

1. **Start with leaf screens.** Migrate simple detail views first (settings, about, profile). These have few dependencies.

2. **Move to list screens.** Replace `UITableViewController` / `UICollectionViewController` with SwiftUI `List` or `LazyVGrid` views wrapped in `UIHostingController`.

3. **Migrate navigation last.** Keep UIKit navigation (`UINavigationController`, `UITabBarController`) as the container while migrating individual screens to SwiftUI. Only replace the navigation layer when most screens are SwiftUI.

4. **Replace the App/Scene delegate last.** Move to `@main` struct with SwiftUI `App` and `Scene` once the entire UI is SwiftUI.

### Screen-by-Screen Pattern

```swift
// Step 1: Replace a UIKit view controller with a SwiftUI screen
// in the UIKit navigation flow

class SettingsViewController: UIViewController {
    // OLD: 200 lines of UIKit code

    // NEW: Replace entire body with UIHostingController
    override func viewDidLoad() {
        super.viewDidLoad()

        let settingsView = SettingsView()
        let hosting = UIHostingController(rootView: settingsView)
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.didMove(toParent: self)
    }
}
```

This lets you migrate one screen at a time while the rest of the app stays UIKit.

## When NOT to Migrate

Stay on UIKit (or keep a hybrid) if:

- Your minimum deployment target is below iOS 15 (SwiftUI is usable but limited before iOS 15).
- You rely on advanced UIKit features without SwiftUI equivalents (e.g., complex `UICollectionViewCompositionalLayout`, custom `UIViewController` transitions with interactive gestures).
- Your team is deeply experienced in UIKit and the app is stable. Migration is not free.
- You have a large codebase with many custom UIKit subclasses. Incremental migration will take months/years.
- Performance-critical views (e.g., custom OpenGL/Metal rendering) are better managed directly in UIKit.

It is perfectly fine to have a hybrid app indefinitely. Apple supports both frameworks and they interoperate well.

## Common Mistakes

```swift
// ❌ Putting NavigationStack inside UINavigationController (double navigation bar)
// UIKit side:
let swiftUIView = NavigationStack { ContentView() }  // Has its own nav bar
let hosting = UIHostingController(rootView: swiftUIView)
navigationController?.pushViewController(hosting, animated: true)  // UIKit nav bar too

// ✅ If UIKit provides navigation, don't add NavigationStack
let swiftUIView = ContentView()  // No NavigationStack
let hosting = UIHostingController(rootView: swiftUIView)
navigationController?.pushViewController(hosting, animated: true)
```

```swift
// ❌ Trying to access UIKit view hierarchy from SwiftUI
struct MyView: View {
    var body: some View {
        Text("Hello")
            .onAppear {
                // Cannot access self.view, superview, etc.
            }
    }
}

// ✅ Use UIViewRepresentable if you need UIKit access
```

```swift
// ❌ Migrating everything at once in a big-bang rewrite
// This almost always fails for non-trivial apps

// ✅ Migrate incrementally, one screen at a time
```

## Checklist

- [ ] Identified leaf screens to migrate first
- [ ] UIHostingController used to embed SwiftUI in UIKit navigation
- [ ] UIViewRepresentable / UIViewControllerRepresentable for UIKit components needed in SwiftUI
- [ ] Delegates replaced with closures or bindings
- [ ] No double navigation bars (NavigationStack inside UINavigationController)
- [ ] Lifecycle methods mapped to onAppear / task / onDisappear
- [ ] Shared state uses @Observable (iOS 17+) or ObservableObject for both frameworks
- [ ] Each migrated screen tested independently before moving to next
- [ ] UIKit navigation container kept until majority of screens are SwiftUI
