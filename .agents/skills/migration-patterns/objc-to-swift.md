# Objective-C to Swift Migration

Incrementally migrating an Objective-C codebase to Swift while keeping the app functional throughout. Swift and Objective-C coexist in the same project using bridging headers, so you can migrate one file at a time without a big-bang rewrite.

## When to Migrate

- New features should be written in Swift -- there is no reason to start new files in ObjC.
- Fixing bugs in an ObjC file is a good opportunity to migrate that file to Swift.
- ObjC code is hard to maintain (manual retain/release patterns, stringly-typed APIs, verbose syntax).
- You want Swift-only APIs: SwiftUI, async/await, actors, `@Observable`, Swift Testing.
- You want stronger type safety and fewer runtime crashes (optionals, enums, value types).

## When NOT to Migrate

- ObjC code is stable, well-tested, and rarely touched. If it works and nobody needs to change it, leave it.
- Performance-critical C/C++ interop code. ObjC has zero-cost C interop; Swift requires bridging.
- Team is not yet comfortable with Swift. Training should come before migration.
- Massive codebase with a tight deadline. Migration takes time and introduces risk.
- Third-party ObjC libraries you do not control. Wrap them rather than rewrite them.

## Concept Mapping

| Objective-C | Swift | Notes |
|-------------|-------|-------|
| `@interface` / `@implementation` | `class` / `struct` / `enum` | Choose value types where possible |
| `@property (nonatomic, strong)` | `var` | `let` for readonly equivalents |
| `@property (nonatomic, copy)` | `var` (value types are copied) | Strings, arrays are value types in Swift |
| `@property (nonatomic, readonly)` | `let` or `private(set) var` | Depends on mutability needs |
| `NSString` | `String` | Bridged automatically |
| `NSArray` / `NSDictionary` | `[Element]` / `[Key: Value]` | Typed collections |
| `NSNumber` | `Int`, `Double`, `Bool` | Use native types |
| `NSError **` | `throws` | Error handling via try/catch |
| `Block` (`^`) | Closure (`{ }`) | Syntax difference, same concept |
| `id` | `Any` | Prefer specific types |
| `NS_ENUM` | `enum: Int` (or `CaseIterable`) | Natively typed |
| `NS_OPTIONS` | `OptionSet` | Struct-based |
| `dispatch_queue_t` + GCD | `async`/`await` + actors | Modern concurrency |
| Category | Extension | Same concept, different syntax |
| Protocol (`@protocol`) | Protocol | Swift protocols are more powerful |
| `#pragma mark -` | `// MARK: -` | Section separators |
| `@selector` | `#selector` | Compile-time checked |
| `@try/@catch` | `do/try/catch` | Swift does not catch ObjC exceptions |
| `instancetype` | `Self` | Return type inference |
| `nullable` / `nonnull` | `Optional` / non-optional | Direct mapping |

## Bridging Header Setup

### ObjC to Swift (Bridging Header)

The bridging header lets Swift code import ObjC classes. Xcode creates it automatically when you first add a Swift file to an ObjC project.

```
// ProjectName-Bridging-Header.h
// Import ObjC headers you want visible to Swift

#import "NetworkManager.h"
#import "UserModel.h"
#import "DatabaseHelper.h"
```

Build setting: `SWIFT_OBJC_BRIDGING_HEADER = ProjectName/ProjectName-Bridging-Header.h`

Rules:
- Keep the bridging header minimal. Only import headers that Swift code actually needs.
- Do not import every header -- it slows down compilation and creates unnecessary coupling.
- Remove headers from the bridging header as you migrate those classes to Swift.

### Swift to ObjC (Generated Header)

Xcode auto-generates a `ProjectName-Swift.h` header that exposes Swift classes to ObjC. Import it in ObjC files:

```objc
// In any .m file that needs Swift classes
#import "ProjectName-Swift.h"

// Never import this in .h files (causes circular imports)
```

Build setting: `DEFINES_MODULE = YES`

### @objc Attribute

Swift classes and members are not visible to ObjC by default. Mark them explicitly:

```swift
// Single class with specific members visible to ObjC
@objc class UserManager: NSObject {
    @objc var currentUser: User?

    @objc func logOut() {
        currentUser = nil
    }

    // Not visible to ObjC (no @objc)
    func swiftOnlyMethod() { }
}
```

### @objcMembers

When most members need ObjC visibility, use `@objcMembers` on the class instead of marking each member:

```swift
@objcMembers
class LegacyService: NSObject {
    var isReady: Bool = false      // Visible to ObjC
    func start() { }              // Visible to ObjC
    func stop() { }               // Visible to ObjC

    // Opt out specific members
    @nonobjc func swiftOnlyHelper() { }
}
```

## Incremental Migration Strategy

Migrate leaves first, trunks last. Start with classes that have the fewest dependencies on other ObjC classes.

### Recommended Order

1. **Model classes** -- Fewest dependencies, easiest to test. Convert `NSObject` subclasses to Swift structs or classes.
2. **Utility / helper classes** -- String formatters, date helpers, validators. Usually standalone.
3. **Network layer** -- API clients, request builders. Good candidate for async/await modernization.
4. **ViewModels / Presenters** -- Business logic layer. May have more dependencies on models and services.
5. **View controllers** -- Most complex, most dependencies. Migrate last.

For each file, the process is:
1. Create the new `.swift` file
2. Translate the ObjC code to Swift
3. Update the bridging header (remove the migrated header, add any new Swift `@objc` visibility)
4. Update all ObjC callers to use the Swift version (via `ProjectName-Swift.h`)
5. Delete the old `.h` and `.m` files
6. Run all tests

## Common Translation Patterns

### Blocks to Closures

```objc
// Objective-C
typedef void (^CompletionHandler)(NSData * _Nullable data, NSError * _Nullable error);

- (void)fetchDataWithCompletion:(CompletionHandler)completion {
    [self.session dataTaskWithURL:self.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completion(data, error);
    }];
}
```

```swift
// Swift (direct translation)
func fetchData(completion: @escaping (Data?, Error?) -> Void) {
    session.dataTask(with: url) { data, response, error in
        completion(data, error)
    }.resume()
}

// Swift (modern -- use async/await)
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

### NSError** to throws

```objc
// Objective-C
- (BOOL)saveToFile:(NSString *)path error:(NSError **)error {
    NSData *data = [self serializedData];
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyApp" code:100 userInfo:@{
                NSLocalizedDescriptionKey: @"Serialization failed"
            }];
        }
        return NO;
    }
    return [data writeToFile:path options:NSDataWritingAtomic error:error];
}
```

```swift
// Swift
enum FileError: LocalizedError {
    case serializationFailed

    var errorDescription: String? {
        switch self {
        case .serializationFailed: return "Serialization failed"
        }
    }
}

func save(to path: String) throws {
    guard let data = serializedData() else {
        throw FileError.serializationFailed
    }
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}
```

### Delegates to Protocols

```objc
// Objective-C
@protocol DownloadDelegate <NSObject>
@required
- (void)downloadDidFinish:(Download *)download;
- (void)download:(Download *)download didFailWithError:(NSError *)error;
@optional
- (void)download:(Download *)download didUpdateProgress:(float)progress;
@end

@interface Download : NSObject
@property (nonatomic, weak) id<DownloadDelegate> delegate;
@end
```

```swift
// Swift
protocol DownloadDelegate: AnyObject {
    func downloadDidFinish(_ download: Download)
    func download(_ download: Download, didFailWith error: Error)
    func download(_ download: Download, didUpdateProgress progress: Float)  // Optional via default impl
}

extension DownloadDelegate {
    // Default implementation makes it optional
    func download(_ download: Download, didUpdateProgress progress: Float) { }
}

class Download {
    weak var delegate: DownloadDelegate?
}
```

### Enums (NS_ENUM and NS_OPTIONS)

```objc
// Objective-C
typedef NS_ENUM(NSInteger, Priority) {
    PriorityLow,
    PriorityMedium,
    PriorityHigh
};

typedef NS_OPTIONS(NSUInteger, Permissions) {
    PermissionsRead   = 1 << 0,
    PermissionsWrite  = 1 << 1,
    PermissionsDelete = 1 << 2
};
```

```swift
// Swift
enum Priority: Int, CaseIterable {
    case low
    case medium
    case high
}

struct Permissions: OptionSet {
    let rawValue: UInt

    static let read   = Permissions(rawValue: 1 << 0)
    static let write  = Permissions(rawValue: 1 << 1)
    static let delete = Permissions(rawValue: 1 << 2)

    static let readWrite: Permissions = [.read, .write]
    static let all: Permissions = [.read, .write, .delete]
}
```

### Singletons

```objc
// Objective-C
@implementation MyManager

+ (instancetype)sharedManager {
    static MyManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MyManager alloc] init];
    });
    return instance;
}

@end
```

```swift
// Swift
class MyManager {
    static let shared = MyManager()
    private init() { }
}
```

### Categories to Extensions

```objc
// Objective-C -- UIColor+Hex.h / UIColor+Hex.m
@interface UIColor (Hex)
+ (UIColor *)colorWithHex:(NSUInteger)hex;
@end

@implementation UIColor (Hex)
+ (UIColor *)colorWithHex:(NSUInteger)hex {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1.0];
}
@end
```

```swift
// Swift
extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
```

### KVO to Combine or @Observable

```objc
// Objective-C (KVO)
[self.user addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"name"]) {
        [self updateNameLabel];
    }
}
```

```swift
// Swift (iOS 17+ -- @Observable)
@Observable
class User {
    var name: String = ""
}

// SwiftUI view automatically observes changes
struct UserView: View {
    var user: User

    var body: some View {
        Text(user.name)  // Re-renders when name changes
    }
}
```

### Nullability Annotations to Optionals

```objc
// Objective-C
@interface UserService : NSObject
- (nullable User *)findUserWithID:(nonnull NSString *)userID;
- (nonnull NSArray<User *> *)allUsers;
- (void)saveUser:(nonnull User *)user completion:(nullable void (^)(NSError * _Nullable))completion;
@end
```

```swift
// Swift
class UserService {
    func findUser(withID userID: String) -> User? {
        // nullable return -> Optional
    }

    func allUsers() -> [User] {
        // nonnull return -> non-optional
    }

    func saveUser(_ user: User, completion: ((Error?) -> Void)? = nil) {
        // nullable block -> optional closure
    }
}
```

## Mixed-Language Project Management

### NS_SWIFT_NAME for Better Swift APIs

Improve how ObjC APIs appear in Swift without changing the ObjC interface:

```objc
// Objective-C
typedef NS_ENUM(NSInteger, ABCRecordType) {
    ABCRecordTypePerson,
    ABCRecordTypeOrganization
} NS_SWIFT_NAME(Record.RecordType);

@interface ABCManager : NSObject
+ (instancetype)managerWithConfiguration:(ABCConfiguration *)config
    NS_SWIFT_NAME(init(configuration:));
- (void)fetchRecordsOfType:(ABCRecordType)type
    NS_SWIFT_NAME(fetchRecords(ofType:));
@end
```

### NS_REFINED_FOR_SWIFT

Hide the ObjC version and provide a better Swift wrapper:

```objc
// Objective-C
@interface DataStore : NSObject
- (NSInteger)countForType:(NSString *)type NS_REFINED_FOR_SWIFT;
@end
```

```swift
// Swift extension provides the refined API
extension DataStore {
    // The ObjC method is available as __countForType(_:)
    func count(for type: RecordType) -> Int {
        return __count(forType: type.rawValue)
    }
}
```

### Module Map Considerations

For framework targets or when using `@import`:

```
// module.modulemap
framework module MyFramework {
    umbrella header "MyFramework.h"
    export *
    module * { export * }
}
```

Build setting: `DEFINES_MODULE = YES` must be enabled for the `-Swift.h` header to be generated.

## Testing During Migration

- **Keep existing ObjC tests running.** Do not delete ObjC tests until the Swift replacement is verified.
- **Write new tests in Swift Testing or XCTest.** All new test files should be Swift.
- **Test the bridging layer.** Write tests that exercise ObjC code calling Swift and Swift code calling ObjC to catch bridging issues.
- **Verify no behavior changes.** After migrating each file, run the full test suite. The migrated Swift code should produce identical results.
- **Test nullability boundaries.** ObjC and Swift handle `nil` differently. Verify that `nil` values pass correctly across the bridge.

```swift
// Test that Swift class works when called from ObjC patterns
import XCTest

class BridgingTests: XCTestCase {
    func testSwiftClassAccessibleFromObjC() {
        // Verify @objc class can be instantiated and used
        let manager = UserManager()
        manager.logOut()
        XCTAssertNil(manager.currentUser)
    }

    func testNullabilityBridging() {
        // Verify nil handling across the bridge
        let service = UserService()
        let user = service.findUser(withID: "nonexistent")
        XCTAssertNil(user)  // Should be nil, not crash
    }
}
```

## Common Mistakes

```swift
// ❌ Swift class not inheriting from NSObject (invisible to ObjC)
@objc class MyHelper {
    @objc func doWork() { }
}
// Error: only classes that inherit from NSObject can be @objc

// ✅ Inherit from NSObject for ObjC visibility
@objc class MyHelper: NSObject {
    @objc func doWork() { }
}
```

```swift
// ❌ Importing -Swift.h in a .h file (circular import)
// MyClass.h
#import "ProjectName-Swift.h"  // Causes circular dependency

// ✅ Use forward declaration in .h, import in .m
// MyClass.h
@class MySwiftClass;  // Forward declaration

// MyClass.m
#import "ProjectName-Swift.h"  // Import here
```

```swift
// ❌ Assuming Swift structs/enums are visible to ObjC
@objc struct Point {  // Error: structs cannot be @objc
    var x: Double
    var y: Double
}

// ✅ Use class inheriting from NSObject, or keep as Swift-only type
@objc class Point: NSObject {
    @objc var x: Double
    @objc var y: Double

    @objc init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
```

```swift
// ❌ Using Swift-only types in @objc methods
@objc class DataService: NSObject {
    @objc func process(items: [String: Any]) -> Result<Data, Error> {
        // Error: Result is not representable in Objective-C
    }
}

// ✅ Use ObjC-compatible types at the boundary
@objc class DataService: NSObject {
    @objc func process(items: [String: Any]) throws -> Data {
        // throws bridges to NSError** in ObjC
    }
}
```

```swift
// ❌ Not handling nil vs NSNull from ObjC collections
// ObjC NSDictionary can contain NSNull, which bridges to NSNull in Swift, not nil
let value = dict["key"]  // Could be NSNull, not nil

// ✅ Check for NSNull explicitly
if let value = dict["key"], !(value is NSNull) {
    // Safe to use value
}
```

```swift
// ❌ Migrating everything at once (big-bang rewrite)
// This almost always fails for non-trivial apps

// ✅ Migrate one file at a time, test after each migration
// Keep both languages compiling and running throughout
```

## Checklist

- [ ] Bridging header (`ProjectName-Bridging-Header.h`) set up and minimal
- [ ] `DEFINES_MODULE = YES` in build settings
- [ ] Migration order planned: models -> utilities -> network -> viewmodels -> view controllers
- [ ] `@objc` / `@objcMembers` applied where Swift classes need ObjC visibility
- [ ] Swift classes that need ObjC visibility inherit from `NSObject`
- [ ] `-Swift.h` only imported in `.m` files, never `.h` files (use forward declarations)
- [ ] `NS_SWIFT_NAME` / `NS_REFINED_FOR_SWIFT` used for ObjC APIs consumed from Swift
- [ ] NSError** patterns replaced with `throws`
- [ ] Blocks replaced with closures (or async/await for modern code)
- [ ] NS_ENUM / NS_OPTIONS replaced with `enum` / `OptionSet`
- [ ] Nullability annotations mapped to Swift optionals
- [ ] Existing ObjC tests still pass after each file migration
- [ ] Bridging layer tested (ObjC calling Swift and Swift calling ObjC)
- [ ] Old `.h` and `.m` files deleted after successful migration and testing
- [ ] Bridging header updated (migrated headers removed)
