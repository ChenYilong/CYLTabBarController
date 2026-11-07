---
name: uikit-legacy
description: Pure UIKit patterns for state management, data binding, and component design without SwiftUI bridging
version: 2.0.0
---

# UIKit Patterns (Pure UIKit)

This skill covers pure UIKit patterns for building iOS applications. **No SwiftUI bridging** - all patterns use native UIKit approaches.

## State Management (Without SwiftUI)

### Delegate Pattern

The classic UIKit approach for communication between components.

```swift
// MARK: - Protocol Definition

protocol UserProfileDelegate: AnyObject {
    func userProfileDidUpdate(_ profile: UserProfile)
    func userProfileDidRequestLogout()
    func userProfileDidFail(with error: Error)
}

// MARK: - Delegate Implementation

final class UserProfileViewController: UIViewController {

    weak var delegate: UserProfileDelegate?

    private func handleProfileUpdate() {
        delegate?.userProfileDidUpdate(currentProfile)
    }

    @objc private func logoutTapped() {
        delegate?.userProfileDidRequestLogout()
    }
}

// MARK: - Parent ViewController

final class SettingsViewController: UIViewController, UserProfileDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let profileVC = UserProfileViewController()
        profileVC.delegate = self
    }

    func userProfileDidUpdate(_ profile: UserProfile) {
        // Handle profile update
    }

    func userProfileDidRequestLogout() {
        // Handle logout
    }

    func userProfileDidFail(with error: Error) {
        showAlert(for: error)
    }
}
```

### Closure-Based Binding

Modern UIKit approach using closures for reactive-style updates.

```swift
// MARK: - ViewModel with Closure Bindings

final class UserListViewModel {

    // MARK: - State

    private(set) var users: [User] = [] {
        didSet { onUsersChanged?(users) }
    }

    private(set) var isLoading: Bool = false {
        didSet { onLoadingChanged?(isLoading) }
    }

    private(set) var error: Error? {
        didSet {
            if let error = error {
                onError?(error)
            }
        }
    }

    // MARK: - Bindings

    var onUsersChanged: (([User]) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Actions

    func loadUsers() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                users = try await userService.fetchAll()
            } catch {
                self.error = error
            }
        }
    }
}

// MARK: - ViewController Binding

final class UserListViewController: UIViewController {

    private var viewModel = UserListViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.loadUsers()
    }

    private func bindViewModel() {
        viewModel.onUsersChanged = { [weak self] users in
            self?.tableView.reloadData()
        }

        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.loadingIndicator.isHidden = !isLoading
            if isLoading {
                self?.loadingIndicator.startAnimating()
            } else {
                self?.loadingIndicator.stopAnimating()
            }
        }

        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
    }
}
```

### Property Observers (didSet)

Use `didSet` for simple property-driven updates.

```swift
final class ProfileHeaderView: UIView {

    var user: User? {
        didSet {
            updateUI()
        }
    }

    var isEditing: Bool = false {
        didSet {
            editButton.isHidden = isEditing
            saveButton.isHidden = !isEditing
            nameTextField.isEnabled = isEditing
        }
    }

    private func updateUI() {
        guard let user = user else { return }
        nameLabel.text = user.name
        emailLabel.text = user.email
        avatarImageView.load(from: user.avatarURL)
    }
}
```

### NotificationCenter for Broadcasts

Use for app-wide events that multiple components need to observe.

```swift
// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let cartDidUpdate = Notification.Name("cartDidUpdate")
}

// MARK: - Posting Notifications

final class AuthService {

    func login(user: User) {
        // ... login logic
        NotificationCenter.default.post(
            name: .userDidLogin,
            object: nil,
            userInfo: ["user": user]
        )
    }

    func logout() {
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
}

// MARK: - Observing Notifications

final class DashboardViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLogin),
            name: .userDidLogin,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLogout),
            name: .userDidLogout,
            object: nil
        )
    }

    @objc private func handleUserLogin(_ notification: Notification) {
        guard let user = notification.userInfo?["user"] as? User else { return }
        updateUIForUser(user)
    }

    @objc private func handleUserLogout(_ notification: Notification) {
        resetUI()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

### KVO (Key-Value Observing)

For observing properties on NSObject subclasses.

```swift
final class DownloadManager: NSObject {

    @objc dynamic var progress: Double = 0.0
    @objc dynamic var isDownloading: Bool = false
}

final class DownloadViewController: UIViewController {

    private let downloadManager = DownloadManager()
    private var progressObservation: NSKeyValueObservation?
    private var downloadingObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservations()
    }

    private func setupObservations() {
        progressObservation = downloadManager.observe(\.progress, options: [.new]) { [weak self] _, change in
            guard let progress = change.newValue else { return }
            DispatchQueue.main.async {
                self?.progressView.progress = Float(progress)
            }
        }

        downloadingObservation = downloadManager.observe(\.isDownloading, options: [.new]) { [weak self] _, change in
            guard let isDownloading = change.newValue else { return }
            DispatchQueue.main.async {
                self?.downloadButton.isEnabled = !isDownloading
            }
        }
    }
}
```

## SwiftUI → UIKit Mappings

When converting SwiftUI code to UIKit, use these mappings:

### State Management

| SwiftUI | UIKit Equivalent |
|---------|------------------|
| `@State` | Instance property + `didSet` |
| `@Binding` | Delegate or closure callback |
| `@ObservedObject` | Protocol delegate + closure bindings |
| `@Observable` | Class with closure bindings |
| `@Environment` | Dependency injection via init |
| `@EnvironmentObject` | Shared singleton or passed reference |

### View Components

| SwiftUI | UIKit |
|---------|-------|
| `NavigationStack` | `UINavigationController` |
| `NavigationLink` | `pushViewController(_:animated:)` |
| `List` | `UITableView` |
| `LazyVGrid` | `UICollectionView` with compositional layout |
| `ScrollView` | `UIScrollView` |
| `VStack` | `UIStackView(axis: .vertical)` |
| `HStack` | `UIStackView(axis: .horizontal)` |
| `ZStack` | Multiple subviews with constraints |
| `Button` | `UIButton` |
| `Text` | `UILabel` |
| `TextField` | `UITextField` |
| `TextEditor` | `UITextView` |
| `Image` | `UIImageView` |
| `Toggle` | `UISwitch` |
| `Slider` | `UISlider` |
| `Picker` | `UIPickerView` or `UISegmentedControl` |
| `DatePicker` | `UIDatePicker` |
| `ProgressView` | `UIProgressView` or `UIActivityIndicatorView` |

### Modifiers → Methods/Properties

| SwiftUI Modifier | UIKit |
|------------------|-------|
| `.font()` | `label.font = ` |
| `.foregroundStyle()` | `label.textColor = ` |
| `.background()` | `view.backgroundColor = ` |
| `.frame()` | `NSLayoutConstraint` |
| `.padding()` | `layoutMargins` or constraint constants |
| `.cornerRadius()` | `layer.cornerRadius` |
| `.shadow()` | `layer.shadow*` properties |
| `.opacity()` | `view.alpha = ` |
| `.hidden()` | `view.isHidden = ` |
| `.disabled()` | `control.isEnabled = ` |
| `.onTapGesture()` | `UITapGestureRecognizer` |
| `.onAppear()` | `viewWillAppear(_:)` |
| `.onDisappear()` | `viewWillDisappear(_:)` |
| `.sheet()` | `present(_:animated:)` |
| `.alert()` | `UIAlertController` |

## UIKit View Lifecycle

```
init(coder:) / init(nibName:bundle:)
    ↓
loadView()
    ↓
viewDidLoad()                  ← Setup UI, bind ViewModel
    ↓
viewWillAppear(_:)             ← Refresh data, start animations
    ↓
viewWillLayoutSubviews()
    ↓
viewDidLayoutSubviews()        ← Adjust for final frame sizes
    ↓
viewDidAppear(_:)              ← Analytics, start tracking
    ↓
[User interaction]
    ↓
viewWillDisappear(_:)          ← Pause tasks
    ↓
viewDidDisappear(_:)           ← Stop expensive operations
    ↓
deinit                         ← Clean up observers
```

## Data Binding Without SwiftUI

### Protocol-Based ViewModel

```swift
// MARK: - ViewModel Protocol

protocol ProductDetailViewModelProtocol {
    var product: Product { get }
    var isInCart: Bool { get }
    var formattedPrice: String { get }

    var onProductUpdated: (() -> Void)? { get set }
    var onCartStatusChanged: ((Bool) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func addToCart()
    func removeFromCart()
    func refresh()
}

// MARK: - Implementation

final class ProductDetailViewModel: ProductDetailViewModelProtocol {

    private(set) var product: Product {
        didSet { onProductUpdated?() }
    }

    private(set) var isInCart: Bool = false {
        didSet { onCartStatusChanged?(isInCart) }
    }

    var formattedPrice: String {
        currencyFormatter.string(from: NSNumber(value: product.price)) ?? ""
    }

    var onProductUpdated: (() -> Void)?
    var onCartStatusChanged: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?

    private let cartService: CartServiceProtocol
    private let currencyFormatter: NumberFormatter

    init(product: Product, cartService: CartServiceProtocol) {
        self.product = product
        self.cartService = cartService
        self.currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency

        checkCartStatus()
    }

    func addToCart() {
        Task { @MainActor in
            do {
                try await cartService.add(product)
                isInCart = true
            } catch {
                onError?(error)
            }
        }
    }

    func removeFromCart() {
        Task { @MainActor in
            do {
                try await cartService.remove(product)
                isInCart = false
            } catch {
                onError?(error)
            }
        }
    }

    func refresh() {
        checkCartStatus()
    }

    private func checkCartStatus() {
        Task { @MainActor in
            isInCart = await cartService.contains(product)
        }
    }
}
```

### Combine with UIKit (Optional)

If using Combine without SwiftUI:

```swift
import Combine

final class SearchViewModel {

    @Published private(set) var results: [SearchResult] = []
    @Published private(set) var isSearching = false

    private var cancellables = Set<AnyCancellable>()

    func search(query: String) {
        isSearching = true

        searchService.search(query: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    if case .failure(let error) = completion {
                        // Handle error
                    }
                },
                receiveValue: { [weak self] results in
                    self?.results = results
                }
            )
            .store(in: &cancellables)
    }
}

final class SearchViewController: UIViewController {

    private var viewModel = SearchViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearching in
                self?.activityIndicator.isHidden = !isSearching
            }
            .store(in: &cancellables)
    }
}
```

## NO SwiftUI Bridging

**IMPORTANT**: Do NOT use these patterns in pure UIKit projects:

```swift
// ❌ DO NOT USE - UIHostingController
let hostingController = UIHostingController(rootView: SomeSwiftUIView())

// ❌ DO NOT USE - UIViewRepresentable
struct MyUIKitView: UIViewRepresentable { ... }

// ❌ DO NOT USE - UIViewControllerRepresentable
struct MyUIKitViewController: UIViewControllerRepresentable { ... }
```

**Instead**, use pure UIKit alternatives:

```swift
// ✅ USE - Direct UIKit
let viewController = MyUIKitViewController()
navigationController?.pushViewController(viewController, animated: true)

// ✅ USE - Container view controller
addChild(childVC)
view.addSubview(childVC.view)
childVC.view.frame = containerView.bounds
childVC.didMove(toParent: self)
```

## Memory Management

### Weak References in Closures

```swift
// ❌ WRONG - Strong reference cycle
button.addAction(UIAction { _ in
    self.handleTap()  // Strong capture
}, for: .touchUpInside)

// ✅ CORRECT - Weak capture
button.addAction(UIAction { [weak self] _ in
    self?.handleTap()
}, for: .touchUpInside)
```

### Weak Delegates

```swift
// Always use weak for delegate references
weak var delegate: SomeDelegate?
```

### Observation Cleanup

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
    // NSKeyValueObservation automatically invalidates in deinit
}
```

## Navigation Patterns

### Coordinator Pattern

```swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        loginCoordinator.delegate = self
        childCoordinators.append(loginCoordinator)
        loginCoordinator.start()
    }
}

extension AppCoordinator: LoginCoordinatorDelegate {
    func loginCoordinatorDidFinish(_ coordinator: LoginCoordinator) {
        childCoordinators.removeAll { $0 === coordinator }
        showMainFlow()
    }
}
```

### Router Pattern (VIP)

See the VIP+W Architecture skill for Router implementation.
