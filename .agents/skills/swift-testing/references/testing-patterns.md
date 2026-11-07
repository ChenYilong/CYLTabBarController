# Swift Testing Patterns Reference

## Contents
- Basic Tests and Traits
- Expectations and Requirements
- Suite Organization
- Parameterized Tests
- Execution Model
- Confirmation and Known Issues
- Tags
- TestScoping and Test Organization
- XCTest Migration Patterns
- Mocking and Test Doubles
- Testable Architecture
- Async and Concurrent Tests
- XCTest UI Tests — Page Object Pattern
- Performance Testing
- Snapshot Testing
- Test Attachments
- Exit Testing
- Test File Organization
- What to Test
- Common Mistakes and Review Checklist

## Basic Tests and Traits

```swift
import Testing

@Test("User can update their display name")
func updateDisplayName() {
    var user = User(name: "Alice")
    user.name = "Bob"
    #expect(user.name == "Bob")
}

@Test(.tags(.validation, .email))
func validatesEmailFormat() { /* ... */ }
```

## Expectations and Requirements

```swift
#expect(result == 42)
#expect(name.isEmpty == false)
#expect(items.count > 0, "Items should not be empty")

// Error type checking
#expect(throws: ValidationError.self) {
    try validate(email: "not-an-email")
}

// Specific error matching
#expect {
    try validate(email: "")
} throws: { error in
    guard let err = error as? ValidationError else { return false }
    return err == .empty
}

// #require unwraps or fails the test
let user = try #require(await fetchUser(id: 1))
let first = try #require(items.first)
```

**Rule: Use `#require` when subsequent assertions depend on the value. Use `#expect` for independent checks.**

## Suite Organization

```swift
@Suite("User Authentication")
struct AuthTests {
    let service: AuthService
    let mockRepo: MockUserRepository

    // init() replaces setUp() -- runs before each test
    init() {
        mockRepo = MockUserRepository()
        service = AuthService(repository: mockRepo)
    }

    @Test func loginSucceeds() async throws {
        let user = try await service.login(email: "test@test.com", password: "pass")
        #expect(user.email == "test@test.com")
    }

    @Test func loginFailsWithBadPassword() async {
        #expect(throws: AuthError.invalidCredentials) {
            try await service.login(email: "test@test.com", password: "wrong")
        }
    }
}
```

Suites can nest for logical grouping:

```swift
@Suite("Payments")
struct PaymentTests {
    @Suite("Subscriptions")
    struct SubscriptionTests {
        @Test func renewsAutomatically() { /* ... */ }
    }
    @Suite("One-Time")
    struct OneTimeTests {
        @Test func chargesCorrectAmount() { /* ... */ }
    }
}
```

## Parameterized Tests

```swift
@Test("Email validation", arguments: [
    ("user@example.com", true),
    ("user@", false),
    ("@example.com", false),
    ("", false),
])
func validateEmail(email: String, isValid: Bool) {
    #expect(EmailValidator.isValid(email) == isValid)
}

// From CaseIterable
@Test(arguments: Currency.allCases)
func currencyHasSymbol(currency: Currency) {
    #expect(currency.symbol.isEmpty == false)
}

// Two collections: cartesian product
@Test(arguments: [1, 2, 3], ["a", "b"])
func combinations(number: Int, letter: String) {
    #expect(number > 0)
}

// Use zip for 1:1 pairing
@Test(arguments: zip(["USD", "EUR"], ["$", "€"]))
func currencySymbols(code: String, symbol: String) {
    #expect(Currency(code: code).symbol == symbol)
}
```

Each argument combination runs as an independent test case reported separately.

## Execution Model

Swift Testing uses Swift Concurrency and runs tests in parallel by default. Treat every test as isolated work unless you explicitly serialize a scope.

```swift
@Suite(.serialized, .tags(.database))
struct DatabaseTests {
    @Test func insertsRecord() async throws { /* ... */ }
    @Test func removesRecord() async throws { /* ... */ }
}
```

Use `.serialized` when tests must not overlap because they touch shared external state like a keychain, database, singleton service, or filesystem location. It does not make unrelated tests outside the serialized scope run one-at-a-time.

Important implications:
- Each test gets its own suite instance.
- Declaration order is not a contract.
- If one logical workflow depends on previous state, keep that workflow inside one test.
- Prefer isolated fixtures over shared mutable globals.

## Confirmation and Known Issues

### Confirmation (Async Event Testing)

```swift
// Basic confirmation -- event must fire exactly once
await confirmation("Received notification") { confirm in
    let observer = NotificationCenter.default.addObserver(
        forName: .userLoggedIn, object: nil, queue: .main
    ) { _ in confirm() }
    await authService.login()
    NotificationCenter.default.removeObserver(observer)
}

// Expected count -- event must fire exactly N times
await confirmation("Received 3 items", expectedCount: 3) { confirm in
    processor.onItem = { _ in confirm() }
    await processor.process(items)
}
```

### Known Issues

```swift
// Known failing test -- does not count as failure
withKnownIssue("Propane tank is empty") {
    #expect(truck.grill.isHeating)
}

// Intermittent / flaky
withKnownIssue(isIntermittent: true) {
    #expect(service.isReachable)
}

// Conditional
withKnownIssue {
    #expect(foodTruck.grill.isHeating)
} when: {
    !hasPropane
}

// Match specific issues only
try withKnownIssue {
    let level = try #require(foodTruck.batteryLevel)
    #expect(level >= 0.8)
} matching: { issue in
    guard case .expectationFailed(let expectation) = issue.kind else { return false }
    return expectation.isRequired
}
```

If no known issues are recorded, Swift Testing records a distinct issue notifying you the problem may be resolved.

## Tags

Tags must be declared as static members in an extension on `Tag`:

```swift
extension Tag {
    @Tag static var critical: Self
    @Tag static var slow: Self
    @Tag static var networking: Self
    @Tag static var validation: Self
}

@Test(.tags(.critical, .networking))
func apiCallReturnsData() async throws { /* ... */ }
```

Filter tests by tag in Xcode test plans or CLI (tag-based filtering syntax varies by toolchain — verify for your Swift version).

## TestScoping and Test Organization

`TestScoping` consolidates per-test setup/teardown into reusable fixtures when attached through a custom trait:

```swift
struct DatabaseScope: TestTrait, SuiteTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing body: @Sendable () async throws -> Void
    ) async throws {
        let db = try await TestDatabase.create()
        do {
            try await body()
            try await db.destroy()
        } catch {
            try? await db.destroy()
            throw error
        }
    }
}

extension Trait where Self == DatabaseScope {
    static var databaseScope: Self { .init() }
}

@Test(.databaseScope, .tags(.database))
func insertsRecord() async throws {
    // Test runs inside DatabaseScope.provideScope
}
```

## XCTest Migration Patterns

Swift Testing tests are functions annotated with `@Test`; they do not need `XCTestCase`. Use the smallest shape that needs the fixture:

```swift
@Test func validatesTotal() {
    #expect(Cart(items: [.sample]).total == 9.99)
}

@Suite("Checkout")
struct CheckoutTests {
    let calculator = PriceCalculator()

    @Test func appliesDiscount() {
        #expect(calculator.total(discount: .percent(10)) == 8.99)
    }
}

@Suite("Shared Cache")
actor CacheTests {
    var cache = TestCache()

    @Test func storesValue() async {
        await cache.store("value", forKey: "key")
        #expect(await cache.value(forKey: "key") == "value")
    }
}

struct PureHelperTests {
    @Test static func normalizesInput() {
        #expect(normalize("  email@example.com ") == "email@example.com")
    }
}
```

Common XCTest mappings:

| XCTest | Swift Testing |
|---|---|
| `XCTAssertTrue(x)` / `XCTAssert(x)` | `#expect(x)` |
| `XCTAssertFalse(x)` | `#expect(!x)` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertThrowsError(try f())` | `#expect(throws: (any Error).self) { try f() }` |
| `XCTAssertNoThrow(try f())` | `#expect(throws: Never.self) { try f() }` |
| `try XCTUnwrap(value)` | `try #require(value)` |
| `XCTFail("message")` | `Issue.record("message")` |

Convert `setUp` into isolated suite `init()` state. Avoid moving fixtures into singletons or shared globals; Swift Testing runs tests in parallel by default. Use actors or per-test fixtures for mutable test doubles, and use `.serialized` only when an external shared resource cannot be isolated.

### XCTest Interoperability During Migration

XCTest and Swift Testing can coexist in the same target, bundle, and even source file during migration. Xcode 27 is the important dividing line for migration reviews: test plans created before Xcode 27 inherit the older `limited` behavior, while new Xcode 27 projects use `complete` behavior by default. Test framework interoperability controls how issues cross that boundary:

- `limited`: preserves the older migration behavior. Cross-framework issues from XCTest are warnings, so a Swift Testing test that reuses a helper wrapping `XCTFail` may still pass while showing migration warnings. Test plans created before Xcode 27 inherit this mode.
- `complete`: treats XCTest assertions and Swift Testing issues as test issues across both frameworks. New Xcode 27 projects use this mode by default, and it is the preferred migration default when available.
- `strict`: like `complete`, but cross-framework issues from XCTest are fatal so teams catch stale helper usage quickly.
- `none`: disables interop and should be reserved for projects that intentionally forbid mixed helpers.

For SwiftPM, set `SWIFT_TESTING_XCTEST_INTEROP_MODE` when the package needs an explicit mode. A package still declaring `swift-tools-version: 6.3` can run under the Swift 6.4 toolchain with limited-mode behavior; updating the package to Swift tools version 6.4 or newer moves the default to complete-mode behavior.

Do not tell teams that all cross-framework APIs are categorically disallowed. Instead, keep existing helper code working under `complete` or `strict` while migrating toward native Swift Testing issue-reporting:

```swift
// Transitional helper body
func requireUser(_ user: User?) throws -> User {
    try #require(user, "Expected a user")
}

func recordMissingUser() {
    Issue.record("Expected a user")
}
```

Use native Swift Testing APIs for new Swift Testing tests. Keep UI automation, performance measurement, and Objective-C exception tests in XCTest.

## Mocking and Test Doubles

Define testable boundaries with protocols:

```swift
protocol UserRepository: Sendable {
    func fetch(id: String) async throws -> User
    func save(_ user: User) async throws
}

actor MockUserRepository: UserRepository {
    var users: [String: User] = [:]
    var fetchError: (any Error)?
    private(set) var savedUsers: [User] = []

    init(users: [String: User] = [:], fetchError: (any Error)? = nil) {
        self.users = users
        self.fetchError = fetchError
    }

    func fetch(id: String) async throws -> User {
        if let error = fetchError { throw error }
        guard let user = users[id] else { throw NotFoundError() }
        return user
    }

    func save(_ user: User) async throws {
        savedUsers.append(user)
        users[user.id] = user
    }
}
```

**Pattern:** Mocks conform to protocols, never subclass concrete types. For parallel Swift Testing runs, keep mutable mock state isolated in an actor or another Sendable-safe fixture. Store call counts and arguments for verification behind that isolation boundary.

## Testable Architecture

Inject dependencies through initializers for testability:

```swift
@Observable
class ProfileViewModel {
    var user: User?
    var error: Error?
    private let repository: any UserRepository

    init(repository: any UserRepository) {
        self.repository = repository
    }

    func load() async {
        do {
            user = try await repository.fetch(id: "current")
        } catch {
            self.error = error
        }
    }
}

// Test with mock
@Test @MainActor func viewModelLoadsUser() async {
    let mock = MockUserRepository(users: ["current": .preview])
    let vm = ProfileViewModel(repository: mock)
    await vm.load()
    #expect(vm.user?.name == "Alice")
}

@Test @MainActor func viewModelHandlesError() async {
    let mock = MockUserRepository(fetchError: URLError(.notConnectedToInternet))
    let vm = ProfileViewModel(repository: mock)
    await vm.load()
    #expect(vm.user == nil)
    #expect(vm.error != nil)
}
```

## Async and Concurrent Tests

```swift
@Test @MainActor func viewModelUpdatesOnMainActor() async {
    let vm = ProfileViewModel(repository: MockUserRepository())
    await vm.load()
    #expect(vm.user != nil)
}

// Clock injection for time-dependent logic
@Test func debounceUsesCorrectDelay() async throws {
    let clock = TestClock()
    let debouncer = Debouncer(delay: .seconds(1), clock: clock)
    debouncer.submit { /* action */ }
    await clock.advance(by: .milliseconds(500))
    #expect(!debouncer.hasExecuted)
    await clock.advance(by: .milliseconds(500))
    #expect(debouncer.hasExecuted)
}

// Error path testing
@Test func fetchThrowsOnNetworkError() async {
    let mock = MockUserRepository(fetchError: URLError(.notConnectedToInternet))
    #expect(throws: URLError.self) {
        try await mock.fetch(id: "1")
    }
}
```

## XCTest UI Tests — Page Object Pattern

Swift Testing does not support UI testing. Use XCTest with XCUITest for all UI tests.

```swift
class LoginUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testLoginFlow() throws {
        let loginPage = LoginPage(app: app)
        let homePage = loginPage.login(email: "test@test.com", password: "password")
        XCTAssertTrue(homePage.welcomeLabel.exists)
    }
}
```

### Page Object Pattern

Encapsulate UI element queries in page objects for reusable, readable UI tests:

```swift
struct LoginPage {
    let app: XCUIApplication
    var emailField: XCUIElement { app.textFields["Email"] }
    var passwordField: XCUIElement { app.secureTextFields["Password"] }
    var signInButton: XCUIElement { app.buttons["Sign In"] }

    @discardableResult
    func login(email: String, password: String) -> HomePage {
        emailField.tap(); emailField.typeText(email)
        passwordField.tap(); passwordField.typeText(password)
        signInButton.tap()
        return HomePage(app: app)
    }
}

struct HomePage {
    let app: XCUIApplication
    var welcomeLabel: XCUIElement { app.staticTexts["Welcome"] }
}
```

## Performance Testing

```swift
class FeedPerformanceTests: XCTestCase {
    func testFeedParsingPerformance() throws {
        let data = try loadFixture("large-feed.json")
        let metrics: [XCTMetric] = [XCTClockMetric(), XCTMemoryMetric()]
        measure(metrics: metrics) {
            _ = try? FeedParser.parse(data)
        }
    }
}
```

Performance tests require XCTest — not available in Swift Testing.

## Snapshot Testing

Add Point-Free's `SnapshotTesting` package to the test target via Swift Package Manager, then use it for visual regression. Requires XCTest:

```swift
import SnapshotTesting
import XCTest

class ProfileViewSnapshotTests: XCTestCase {
    func testProfileView() {
        let view = ProfileView(user: .preview)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))

        // Dark mode
        assertSnapshot(of: view.environment(\.colorScheme, .dark),
                       as: .image(layout: .device(config: .iPhone13)), named: "dark")

        // Large Dynamic Type
        assertSnapshot(of: view.environment(\.dynamicTypeSize, .accessibility3),
                       as: .image(layout: .device(config: .iPhone13)), named: "largeText")
    }
}
```

Always test Dark Mode and large Dynamic Type in snapshots.

## Test Attachments

Attach diagnostic data to test results for debugging failures:

```swift
@Test func generateReport() async throws {
    let report = try generateReport()
    // Attach the output for later inspection
    Attachment.record(report.data, named: "report.json")
    #expect(report.isValid)
}

// Attach from a file URL
@Test func processImage() async throws {
    let output = try processImage()
    let attachment = try await Attachment(contentsOf: output.url, named: "result.png")
    Attachment.record(attachment)
}
```

Attachments support standard `Attachable` values such as `Data`, `[UInt8]`, strings, and Encodable values when Foundation is imported. Image attachments require Swift 6.3 / Xcode 26.4 or newer and support platform image types such as `UIImage`, `CGImage`, `CIImage`, and `NSImage`; pass `as: .png` or another supported format when the filename should be explicit.

## Exit Testing

Test code that calls `exit()`, `fatalError()`, or `preconditionFailure()`. Exit testing requires Swift 6.2 / Xcode 26.0 or newer and is supported on macOS, Linux, FreeBSD, OpenBSD, and Windows runtime targets, not iOS, tvOS, or watchOS:

```swift
@Test func invalidInputCausesExit() async {
    await #expect(processExitsWith: .failure) {
        processInvalidInput()  // calls fatalError()
    }
}
```

Exit testing runs the closure in a subprocess. The test passes if the process exits with the expected status. Capturing values from the parent process in an exit-test capture list requires the Swift 6.3 compiler.

## Test File Organization

```text
Tests/AppTests/          # Swift Testing (Models/, ViewModels/, Services/)
Tests/AppUITests/        # XCTest UI tests (Pages/, Flows/)
Tests/Fixtures/          # Test data (JSON, images)
Tests/Mocks/             # Shared mock implementations
```

Name test files `<TypeUnderTest>Tests.swift`. Describe behavior in function names: `fetchUserReturnsNilOnNetworkError()` not `testFetchUser()`. Name mocks `Mock<ProtocolName>`.

### What to Test

**Always test:** business logic, validation rules, state transitions in view models, error handling paths, edge cases (empty collections, nil, boundaries), async success and failure, Task cancellation.

**Skip:** SwiftUI view body layout (use snapshots), simple property forwarding, Apple framework behavior, private methods (test through public API).

## CustomTestStringConvertible

When parameterized test arguments appear in test output, Swift Testing uses `String(describing:)` by default. Conform to `CustomTestStringConvertible` for better output:

```swift
enum Food: CaseIterable {
    case paella, oden, ragu
}

extension Food: CustomTestStringConvertible {
    var testDescription: String {
        switch self {
        case .paella: "paella valenciana"
        case .oden: "おでん"
        case .ragu: "ragù alla bolognese"
        }
    }
}

@Test(arguments: Food.allCases)
func isDelicious(_ food: Food) { /* output shows custom descriptions */ }
```

Use this for any type passed as a parameterized test argument where the default description is unclear — especially enums, IDs, or model types.

## Availability-Conditional Tests

Use `@available` on test functions to run tests only on specific OS versions:

```swift
@Test
@available(iOS 18, macOS 15, *)
func usesNewAPI() async throws {
    let result = try await NewFramework.process()
    #expect(result.isValid)
}
```

Swift Testing skips `@available`-gated tests when running on older OS versions. This replaces XCTest's `#available` guard + early return pattern.

Do not put `@available` on a suite type or a type that contains a suite; Swift Testing requires suite types to always be available. Put availability gates on individual `@Test` functions instead.

## Common Mistakes and Review Checklist

1. **Testing implementation, not behavior.** Test what the code does, not how.
2. **No error path tests.** If a function can throw, test the throw path.
3. **Flaky async tests.** Use `confirmation` with expected counts, not `sleep` calls.
4. **Shared mutable state between tests.** Each test sets up its own state via `init()` in `@Suite` or a fixture.
5. **Missing accessibility identifiers in UI tests.** XCUITest queries rely on them.
6. **Using `sleep` in tests.** Use `confirmation`, clock injection, or `withKnownIssue`.
7. **Not testing cancellation.** If code supports `Task` cancellation, verify it cancels cleanly.
8. **Unclear XCTest migration boundaries.** Apple allows XCTest and Swift Testing in one file during migration; prefer separate files when it keeps imports, ownership, and runner expectations clearer.
9. **Non-Sendable test helpers shared across tests.** Ensure test helper types are Sendable when shared across concurrent test cases.
10. **Assuming test order.** Parallel default execution means declaration order and suite nesting do not create a workflow.
11. **Using `.serialized` as a dependency chain.** Serialized scopes avoid overlap; they do not pass state from one test to the next.

### Review Checklist

- [ ] All new tests use Swift Testing (`@Test`, `#expect`), not XCTest assertions
- [ ] Test names describe behavior (`fetchUserReturnsNilOnNetworkError` not `testFetchUser`)
- [ ] Error paths have dedicated tests
- [ ] Async tests use `confirmation()`, not `Task.sleep`
- [ ] Parameterized tests used for repetitive variations
- [ ] Tags applied for filtering (`.critical`, `.slow`)
- [ ] Mocks conform to protocols, not subclass concrete types
- [ ] No shared mutable state between tests
- [ ] Tests do not rely on declaration order or shared suite instances
- [ ] `.serialized` is reserved for exclusive state, not workflow sequencing
- [ ] Cancellation tested for cancellable async operations
