# XCTest to Swift Testing Migration

Swift Testing is a modern testing framework (Xcode 16 / Swift 6.0) that replaces XCTest with a more expressive, macro-based API. Both frameworks can coexist in the same test target.

## Concept Mapping

| XCTest | Swift Testing | Notes |
|--------|--------------|-------|
| `import XCTest` | `import Testing` | New module |
| `class MyTests: XCTestCase` | `struct MyTests` or `@Suite struct MyTests` | Structs preferred, no inheritance |
| `func testSomething()` | `@Test func something()` | No `test` prefix required |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` | Single macro for all comparisons |
| `XCTAssertTrue(x)` | `#expect(x)` | Same macro |
| `XCTAssertFalse(x)` | `#expect(!x)` | Same macro |
| `XCTAssertNil(x)` | `#expect(x == nil)` | Same macro |
| `XCTAssertNotNil(x)` | `#expect(x != nil)` | Same macro |
| `XCTAssertGreaterThan(a, b)` | `#expect(a > b)` | Same macro |
| `XCTAssertThrowsError(expr)` | `#expect(throws: MyError.self) { expr }` | Type-safe |
| `XCTAssertNoThrow(expr)` | `#expect(throws: Never.self) { expr }` | Explicit "no throw" |
| `XCTUnwrap(optional)` | `try #require(optional)` | Throws on nil, stops test |
| `XCTFail("message")` | `Issue.record("message")` | Records a test failure |
| `setUp()` / `setUpWithError()` | `init()` / `init() throws` | Struct initializer |
| `tearDown()` | `deinit` (class) or not needed (struct) | Structs clean up automatically |
| `setUpWithError() throws` | `init() async throws` | Async init supported |
| `addTeardownBlock { }` | `defer { }` or test cleanup in deinit | Standard Swift patterns |
| `func testPerformance()` with `measure { }` | Not available | Use XCTest for performance tests |
| `XCTestExpectation` + `wait(for:)` | Built-in async/await | `@Test func x() async { }` |
| `continueAfterFailure = false` | `try #require()` | Stops test on failure |
| Test class inheritance | `@Suite` with shared init | No inheritance, use composition |

## Basic Migration

### Before (XCTest)

```swift
import XCTest

class CalculatorTests: XCTestCase {
    var calculator: Calculator!

    override func setUp() {
        calculator = Calculator()
    }

    override func tearDown() {
        calculator = nil
    }

    func testAddition() {
        let result = calculator.add(2, 3)
        XCTAssertEqual(result, 5)
    }

    func testDivisionByZero() {
        XCTAssertThrowsError(try calculator.divide(10, by: 0)) { error in
            XCTAssertEqual(error as? CalculatorError, .divisionByZero)
        }
    }

    func testOptionalResult() throws {
        let result = try XCTUnwrap(calculator.lastResult)
        XCTAssertGreaterThan(result, 0)
    }
}
```

### After (Swift Testing)

```swift
import Testing

@Suite
struct CalculatorTests {
    let calculator: Calculator

    init() {
        calculator = Calculator()
    }
    // No tearDown needed -- struct deallocates automatically

    @Test
    func addition() {
        let result = calculator.add(2, 3)
        #expect(result == 5)
    }

    @Test
    func divisionByZero() {
        #expect(throws: CalculatorError.divisionByZero) {
            try calculator.divide(10, by: 0)
        }
    }

    @Test
    func optionalResult() throws {
        let result = try #require(calculator.lastResult)
        #expect(result > 0)
    }
}
```

Key differences:
- Struct instead of class. No inheritance from `XCTestCase`.
- `init()` replaces `setUp()`. No `tearDown()` needed for structs.
- `@Test` attribute replaces `test` prefix naming convention.
- `#expect` replaces all `XCTAssert*` variants with natural Swift expressions.
- `#require` replaces `XCTUnwrap` and also stops the test on failure (like `continueAfterFailure = false`).

## #expect: The Universal Assertion

`#expect` accepts any boolean expression. When it fails, Swift Testing shows the actual values in the failure message.

```swift
// All of these work with #expect
#expect(result == 42)
#expect(result != 0)
#expect(array.count > 5)
#expect(string.contains("hello"))
#expect(array.isEmpty)
#expect(!flag)
#expect(value >= minimum && value <= maximum)
```

Failure messages show values automatically:

```
Expectation failed: (result == 42)
  result: 37
```

No need for custom messages in most cases. If you want one:

```swift
#expect(result == 42, "Expected 42 but got \(result) for input \(input)")
```

## #require: Stop Test on Failure

`#require` works like `#expect` but throws on failure, stopping the test. Use it when subsequent assertions depend on this one passing.

```swift
@Test
func userProfile() throws {
    let user = try #require(fetchUser(id: 123))  // Stops test if nil
    #expect(user.name == "Alice")                 // Only runs if user was found
    #expect(user.email.contains("@"))
}
```

This replaces two XCTest patterns:
- `XCTUnwrap` for unwrapping optionals
- `continueAfterFailure = false` for stopping on first failure

## Async Tests

### Before (XCTest)

```swift
class NetworkTests: XCTestCase {
    func testFetchUser() {
        let expectation = expectation(description: "Fetch user")
        var fetchedUser: User?

        networkService.fetchUser(id: 123) { result in
            if case .success(let user) = result {
                fetchedUser = user
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.name, "Alice")
    }
}
```

### After (Swift Testing)

```swift
@Suite
struct NetworkTests {
    @Test
    func fetchUser() async throws {
        let user = try await networkService.fetchUser(id: 123)
        #expect(user.name == "Alice")
    }
}
```

No expectations, no callbacks, no timeouts. Just `async`/`await`.

## Parameterized Tests

Swift Testing supports parameterized tests natively. This replaces the XCTest pattern of writing multiple near-identical test methods.

### Before (XCTest)

```swift
class ParserTests: XCTestCase {
    func testParseInteger() {
        XCTAssertEqual(parse("42"), .integer(42))
    }

    func testParseNegativeInteger() {
        XCTAssertEqual(parse("-7"), .integer(-7))
    }

    func testParseZero() {
        XCTAssertEqual(parse("0"), .integer(0))
    }

    func testParseFloat() {
        XCTAssertEqual(parse("3.14"), .float(3.14))
    }
}
```

### After (Swift Testing)

```swift
@Suite
struct ParserTests {
    @Test(arguments: [
        ("42", Token.integer(42)),
        ("-7", Token.integer(-7)),
        ("0", Token.integer(0)),
        ("3.14", Token.float(3.14)),
    ])
    func parseToken(input: String, expected: Token) {
        #expect(parse(input) == expected)
    }
}
```

Each argument combination runs as a separate test case in the test navigator.

### Multiple Argument Collections

```swift
@Test(arguments: ["GET", "POST", "PUT"], [200, 404, 500])
func httpResponse(method: String, statusCode: Int) async throws {
    let response = try await makeRequest(method: method, expectedStatus: statusCode)
    #expect(response.statusCode == statusCode)
}
// Runs 9 test cases (3 methods x 3 status codes)
```

### Zip Instead of Cartesian Product

```swift
@Test(arguments: zip(["GET", "POST"], [200, 201]))
func httpResponse(method: String, statusCode: Int) async throws {
    // Runs 2 test cases: (GET, 200) and (POST, 201)
}
```

## Tags for Organization

Tags replace XCTest's informal naming conventions for organizing tests.

```swift
extension Tag {
    @Tag static var networking: Self
    @Tag static var database: Self
    @Tag static var ui: Self
    @Tag static var slow: Self
}

@Suite
struct APITests {
    @Test(.tags(.networking))
    func fetchUsers() async throws {
        // ...
    }

    @Test(.tags(.networking, .slow))
    func uploadLargeFile() async throws {
        // ...
    }
}

@Suite(.tags(.database))  // All tests in suite get this tag
struct DatabaseTests {
    @Test
    func insertRecord() throws {
        // Inherits .database tag
    }
}
```

You can filter by tag in Xcode's test navigator or via command line:

```bash
swift test --filter .tags:networking
```

## Display Names

```swift
@Test("Addition of two positive integers")
func addition() {
    #expect(Calculator.add(2, 3) == 5)
}

@Suite("Calculator Edge Cases")
struct EdgeCases {
    @Test("Division by zero throws an error")
    func divisionByZero() {
        #expect(throws: CalculatorError.divisionByZero) {
            try Calculator.divide(10, by: 0)
        }
    }
}
```

## Test Conditions

Run tests conditionally based on runtime conditions:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["CI"] != nil))
func integrationTest() async throws {
    // Only runs on CI
}

@Test(.disabled("Server is down for maintenance"))
func serverTest() async throws {
    // Skipped with a reason
}

@Test(.bug("https://github.com/org/repo/issues/123", "Crashes on empty input"))
func knownBugTest() {
    // Marked as related to a known bug
}
```

## Suites

`@Suite` groups related tests. Suites can be nested:

```swift
@Suite
struct MathTests {
    @Suite
    struct AdditionTests {
        @Test func positiveNumbers() { #expect(add(2, 3) == 5) }
        @Test func negativeNumbers() { #expect(add(-2, -3) == -5) }
    }

    @Suite
    struct MultiplicationTests {
        @Test func positiveNumbers() { #expect(multiply(2, 3) == 6) }
        @Test func byZero() { #expect(multiply(5, 0) == 0) }
    }
}
```

### Shared Setup via Init

```swift
@Suite
struct DatabaseTests {
    let database: Database

    init() async throws {
        database = try await Database.createTestDatabase()
        try await database.migrate()
    }

    @Test
    func insertUser() async throws {
        try await database.insert(User(name: "Alice"))
        let count = try await database.count(User.self)
        #expect(count == 1)
    }

    @Test
    func deleteUser() async throws {
        let user = User(name: "Bob")
        try await database.insert(user)
        try await database.delete(user)
        let count = try await database.count(User.self)
        #expect(count == 0)
    }
}
```

Each `@Test` function gets its own instance of the `@Suite` struct, so each test gets a fresh `database`.

## Coexistence

XCTest and Swift Testing can coexist in the same test target. This is the recommended approach for incremental migration.

```swift
// Same test target can have both:

// XCTest (keep existing tests)
import XCTest

class LegacyTests: XCTestCase {
    func testOldFeature() {
        XCTAssertEqual(1 + 1, 2)
    }
}

// Swift Testing (new tests and migrated tests)
import Testing

@Suite
struct NewTests {
    @Test
    func newFeature() {
        #expect(1 + 1 == 2)
    }
}
```

Rules for coexistence:
- Both `import XCTest` and `import Testing` can appear in different files in the same target.
- Do NOT mix them in the same file. Each file should use one framework.
- Do NOT subclass `XCTestCase` and use `@Test` in the same type.
- XCTest performance tests (`measure { }`) must stay in XCTest. Swift Testing does not have a performance measurement API.

### Migration Order

1. Start with simple assertion-only tests (no `setUp`/`tearDown`, no expectations).
2. Then migrate tests with `setUp`/`tearDown` (convert to struct `init`).
3. Then migrate async tests with `XCTestExpectation` (convert to `async`/`await`).
4. Leave performance tests in XCTest.
5. Delete XCTest imports only when all tests in a file are migrated.

## When NOT to Migrate

Stay on XCTest if:

- You need performance testing (`measure { }`) -- Swift Testing does not support this.
- You need UI testing (`XCUIApplication`, `XCUIElement`) -- these are XCTest-only.
- Your CI system does not yet support Xcode 16 / Swift 6.0.
- You rely on `XCTestCase` subclassing for shared test infrastructure across many test classes.
- Your test target uses Objective-C test helpers that rely on `XCTestCase`.

## Common Mistakes

```swift
// ❌ Using XCTest assertions in Swift Testing
import Testing

@Test
func myTest() {
    XCTAssertEqual(1, 1)  // Wrong framework's assertion
}

// ✅ Use #expect
import Testing

@Test
func myTest() {
    #expect(1 == 1)
}
```

```swift
// ❌ Prefixing test functions with "test" (unnecessary but harmless)
@Test
func testAddition() { }  // Works but the "test" prefix is redundant

// ✅ Clean function name
@Test
func addition() { }

// ✅ Or use a display name
@Test("Addition of positive integers")
func addition() { }
```

```swift
// ❌ Using XCTestExpectation for async tests
@Test
func fetchData() {
    // Cannot use XCTestExpectation in Swift Testing
}

// ✅ Use async/await
@Test
func fetchData() async throws {
    let data = try await service.fetch()
    #expect(!data.isEmpty)
}
```

```swift
// ❌ Using class with var properties for test state
@Suite
class MyTests {
    var counter = 0

    @Test
    func incrementOnce() {
        counter += 1
        #expect(counter == 1)  // May fail if tests share state
    }
}

// ✅ Use struct -- each test gets its own instance
@Suite
struct MyTests {
    var counter = 0

    @Test
    mutating func incrementOnce() {
        counter += 1
        #expect(counter == 1)  // Always passes, fresh instance per test
    }
}
```

```swift
// ❌ Mixing XCTest and Swift Testing in the same type
class MyTests: XCTestCase {
    @Test  // Cannot use @Test on XCTestCase methods
    func something() { }
}

// ✅ Keep them in separate types (can be in the same file or different files)
class LegacyTests: XCTestCase {
    func testSomething() { XCTAssertTrue(true) }
}

@Suite
struct ModernTests {
    @Test func something() { #expect(true) }
}
```

## Checklist

- [ ] Xcode 16+ / Swift 6.0+ available
- [ ] `import Testing` added (not replacing `import XCTest` in existing files -- use new files)
- [ ] Test classes converted to structs with `@Suite`
- [ ] `setUp()` converted to `init()` (or `init() async throws`)
- [ ] `tearDown()` removed (structs clean up automatically)
- [ ] `XCTAssert*` replaced with `#expect`
- [ ] `XCTUnwrap` replaced with `try #require`
- [ ] `XCTestExpectation` + `wait(for:)` replaced with `async`/`await`
- [ ] Duplicate test methods replaced with `@Test(arguments:)` parameterized tests
- [ ] Tags added for test organization
- [ ] Performance tests left in XCTest (no Swift Testing equivalent)
- [ ] UI tests left in XCTest (no Swift Testing equivalent)
- [ ] No mixing of `XCTestCase` and `@Test` in the same type
