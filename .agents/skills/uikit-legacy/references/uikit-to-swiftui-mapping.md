# SwiftUI to UIKit Component Mapping

Use this reference when converting SwiftUI code to pure UIKit implementations.

## Views

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `Text` | `UILabel` |
| `Image` | `UIImageView` |
| `Button` | `UIButton` |
| `TextField` | `UITextField` |
| `TextEditor` | `UITextView` |
| `SecureField` | `UITextField` with `isSecureTextEntry = true` |
| `Toggle` | `UISwitch` |
| `Slider` | `UISlider` |
| `Stepper` | `UIStepper` |
| `ProgressView` (determinate) | `UIProgressView` |
| `ProgressView` (indeterminate) | `UIActivityIndicatorView` |
| `Picker` | `UIPickerView` |
| `Picker` (segmented) | `UISegmentedControl` |
| `DatePicker` | `UIDatePicker` |
| `ColorPicker` | `UIColorPickerViewController` |

## Containers

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `VStack` | `UIStackView(axis: .vertical)` |
| `HStack` | `UIStackView(axis: .horizontal)` |
| `ZStack` | Multiple subviews with constraints |
| `ScrollView` | `UIScrollView` |
| `List` | `UITableView` |
| `LazyVGrid` | `UICollectionView` with compositional layout |
| `LazyHGrid` | `UICollectionView` with compositional layout |
| `TabView` (pages) | `UIPageViewController` |
| `TabView` (tabs) | `UITabBarController` |
| `Form` | `UITableView` (grouped style) |
| `Section` | `UITableView` section |
| `Group` | No direct equivalent (grouping only) |
| `GeometryReader` | Manual frame calculations |

## Navigation

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `NavigationStack` | `UINavigationController` |
| `NavigationLink` | `pushViewController(_:animated:)` |
| `.navigationTitle()` | `navigationItem.title = ` |
| `.navigationBarTitleDisplayMode()` | `navigationItem.largeTitleDisplayMode = ` |
| `.toolbar()` | `navigationItem.rightBarButtonItems = ` |
| `ToolbarItem` | `UIBarButtonItem` |
| `.sheet()` | `present(_:animated:)` |
| `.fullScreenCover()` | `present(_:animated:)` with `.fullScreen` |
| `.popover()` | `UIPopoverPresentationController` |
| `.alert()` | `UIAlertController(preferredStyle: .alert)` |
| `.confirmationDialog()` | `UIAlertController(preferredStyle: .actionSheet)` |

## Layout Modifiers

| SwiftUI Modifier | UIKit Equivalent |
|------------------|------------------|
| `.frame(width:height:)` | `NSLayoutConstraint` for width/height |
| `.frame(maxWidth: .infinity)` | Leading + trailing constraints |
| `.padding()` | `layoutMargins` or constraint constants |
| `.padding(.horizontal)` | Leading/trailing constraint constants |
| `.background()` | `view.backgroundColor = ` or background subview |
| `.overlay()` | Subview positioned on top |
| `.cornerRadius()` | `layer.cornerRadius = ` with `clipsToBounds = true` |
| `.clipShape()` | `layer.mask` or custom `CAShapeLayer` |
| `.shadow()` | `layer.shadow*` properties |
| `.border()` | `layer.borderWidth` + `layer.borderColor` |
| `.opacity()` | `view.alpha = ` |

## Appearance Modifiers

| SwiftUI Modifier | UIKit Equivalent |
|------------------|------------------|
| `.font()` | `label.font = ` / `textField.font = ` |
| `.fontWeight()` | `UIFont.systemFont(ofSize:weight:)` |
| `.foregroundStyle()` | `label.textColor = ` |
| `.tint()` | `view.tintColor = ` |
| `.accentColor()` | `view.tintColor = ` |
| `.multilineTextAlignment()` | `label.textAlignment = ` |
| `.lineLimit()` | `label.numberOfLines = ` |
| `.truncationMode()` | `label.lineBreakMode = ` |
| `.hidden()` | `view.isHidden = true` |
| `.disabled()` | `control.isEnabled = false` |

## Gestures

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `.onTapGesture()` | `UITapGestureRecognizer` |
| `.onLongPressGesture()` | `UILongPressGestureRecognizer` |
| `DragGesture` | `UIPanGestureRecognizer` |
| `MagnificationGesture` | `UIPinchGestureRecognizer` |
| `RotationGesture` | `UIRotationGestureRecognizer` |
| `.simultaneousGesture()` | `gestureRecognizer.delegate` methods |

## State Management

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `@State` | Instance property + `didSet` for UI updates |
| `@Binding` | Delegate pattern or closure callback |
| `@ObservedObject` | Protocol-based ViewModel with closures |
| `@Observable` | Class with closure bindings |
| `@Environment` | Dependency injection via initializer |
| `@EnvironmentObject` | Shared singleton or passed reference |
| `@StateObject` | Property initialized once + closure bindings |

## Lifecycle

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `.onAppear()` | `viewWillAppear(_:)` |
| `.onDisappear()` | `viewWillDisappear(_:)` |
| `.task()` | `Task { }` in `viewDidLoad()` |
| `init()` | `init(nibName:bundle:)` or `init(coder:)` |

## Common Conversions

### Text → UILabel
```swift
// SwiftUI
Text("Hello")
    .font(.headline)
    .foregroundStyle(.blue)
    .multilineTextAlignment(.center)

// UIKit
let label = UILabel()
label.text = "Hello"
label.font = .preferredFont(forTextStyle: .headline)
label.textColor = .systemBlue
label.textAlignment = .center
```

### Button → UIButton
```swift
// SwiftUI
Button("Tap Me") {
    handleTap()
}
.buttonStyle(.borderedProminent)

// UIKit
let button = UIButton(configuration: .borderedProminent())
button.setTitle("Tap Me", for: .normal)
button.addAction(UIAction { [weak self] _ in
    self?.handleTap()
}, for: .touchUpInside)
```

### VStack → UIStackView
```swift
// SwiftUI
VStack(spacing: 16) {
    Text("Title")
    Text("Subtitle")
    Spacer()
    Button("Action") { }
}

// UIKit
let stackView = UIStackView()
stackView.axis = .vertical
stackView.spacing = 16
stackView.addArrangedSubview(titleLabel)
stackView.addArrangedSubview(subtitleLabel)
let spacer = UIView()
spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
stackView.addArrangedSubview(spacer)
stackView.addArrangedSubview(actionButton)
```

### List → UITableView
```swift
// SwiftUI
List(items) { item in
    Text(item.name)
}

// UIKit
class ItemsViewController: UIViewController, UITableViewDataSource {
    private let tableView = UITableView()
    private var items: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = items[indexPath.row].name
        cell.contentConfiguration = config
        return cell
    }
}
```

### NavigationStack → UINavigationController
```swift
// SwiftUI
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}

// UIKit
class ItemsViewController: UIViewController, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        let detailVC = ItemDetailViewController(item: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
```

### Sheet → Present Modally
```swift
// SwiftUI
.sheet(isPresented: $showSettings) {
    SettingsView()
}

// UIKit
@objc private func showSettings() {
    let settingsVC = SettingsViewController()
    settingsVC.modalPresentationStyle = .pageSheet
    present(settingsVC, animated: true)
}
```

### Alert → UIAlertController
```swift
// SwiftUI
.alert("Error", isPresented: $showError) {
    Button("OK") { }
    Button("Retry") { retry() }
} message: {
    Text(errorMessage)
}

// UIKit
private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
        self?.retry()
    })
    present(alert, animated: true)
}
```
