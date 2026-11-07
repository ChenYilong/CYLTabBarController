# Swift Patterns Extended Reference

Additional patterns and examples that extend the core SKILL.md. Refer to this file for deeper Codable patterns, advanced result builder techniques, and supplementary collection/formatting recipes.

## Contents

- [Codable: Enums with Associated Values](#codable-enums-with-associated-values)
- [Codable: Date Decoding Strategies](#codable-date-decoding-strategies)
- [Codable: Unkeyed Containers (Arrays)](#codable-unkeyed-containers-arrays)
- [Codable: Wrapper for Lossy Array Decoding](#codable-wrapper-for-lossy-array-decoding)
- [Codable Boundary Routing](#codable-boundary-routing)
- [Result Builder: HTML Builder](#result-builder-html-builder)
- [Result Builder: buildFinalResult](#result-builder-buildfinalresult)
- [Property Wrapper: UserDefaults-Backed](#property-wrapper-userdefaults-backed)
- [Property Wrapper: Validated](#property-wrapper-validated)
- [Advanced Regex Builder Patterns](#advanced-regex-builder-patterns)
- [FormatStyle: Custom FormatStyle](#formatstyle-custom-formatstyle)
- [Collection Patterns: Chunking and Windows](#collection-patterns-chunking-and-windows)
- [Guard: Complex Pattern Matching](#guard-complex-pattern-matching)
- [Typed Throws: Protocol with Typed Errors](#typed-throws-protocol-with-typed-errors)
- [String Interpolation: Custom appendInterpolation](#string-interpolation-custom-appendinterpolation)
- [Never: Advanced Usage](#never-advanced-usage)

## Codable: Enums with Associated Values

```swift
enum Shape: Codable {
    case circle(radius: Double)
    case rectangle(width: Double, height: Double)

    enum CodingKeys: String, CodingKey {
        case type, radius, width, height
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .circle(let radius):
            try container.encode("circle", forKey: .type)
            try container.encode(radius, forKey: .radius)
        case .rectangle(let width, let height):
            try container.encode("rectangle", forKey: .type)
            try container.encode(width, forKey: .width)
            try container.encode(height, forKey: .height)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "circle":
            let radius = try container.decode(Double.self, forKey: .radius)
            self = .circle(radius: radius)
        case "rectangle":
            let width = try container.decode(Double.self, forKey: .width)
            let height = try container.decode(Double.self, forKey: .height)
            self = .rectangle(width: width, height: height)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container,
                debugDescription: "Unknown shape type: \(type)")
        }
    }
}
```

## Codable: Date Decoding Strategies

```swift
// Configure decoder for specific date formats
let decoder = JSONDecoder()

// ISO 8601 (most common for APIs)
decoder.dateDecodingStrategy = .iso8601

// Unix timestamp (seconds since epoch)
decoder.dateDecodingStrategy = .secondsSince1970

// Custom format
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd"
formatter.locale = Locale(identifier: "en_US_POSIX")
decoder.dateDecodingStrategy = .formatted(formatter)

// Multiple formats in one payload
decoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)

    let iso = ISO8601DateFormatter()
    if let date = iso.date(from: string) { return date }

    let fallback = DateFormatter()
    fallback.dateFormat = "yyyy-MM-dd"
    fallback.locale = Locale(identifier: "en_US_POSIX")
    if let date = fallback.date(from: string) { return date }

    throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Cannot decode date: \(string)")
}
```

## Codable: Unkeyed Containers (Arrays)

```swift
// JSON: { "coordinates": [37.7749, -122.4194] }
struct Location: Decodable {
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var coords = try container.nestedUnkeyedContainer(forKey: .coordinates)
        latitude = try coords.decode(Double.self)
        longitude = try coords.decode(Double.self)
    }
}
```

## Codable: Wrapper for Lossy Array Decoding

Skip invalid elements instead of failing the entire array:

```swift
struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                result.append(element)
            } else {
                _ = try? container.decode(AnyCodable.self) // skip invalid
            }
        }
        elements = result
    }
}

private struct AnyCodable: Decodable {}
```

## Codable Boundary Routing

Keep this skill to small, typed Codable shaping examples. Route type-erased JSON
values, lossy dynamic payload wrappers, `@dynamicMemberLookup` JSON access, and
production decoding architecture to `swift-codable`.

## Result Builder: HTML Builder

A practical example of a custom result builder:

```swift
@resultBuilder
struct HTMLBuilder {
    static func buildBlock(_ components: String...) -> String {
        components.joined(separator: "\n")
    }

    static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }

    static func buildEither(first component: String) -> String {
        component
    }

    static func buildEither(second component: String) -> String {
        component
    }

    static func buildArray(_ components: [String]) -> String {
        components.joined(separator: "\n")
    }
}

func div(@HTMLBuilder content: () -> String) -> String {
    "<div>\n\(content())\n</div>"
}

func p(_ text: String) -> String { "<p>\(text)</p>" }
func h1(_ text: String) -> String { "<h1>\(text)</h1>" }

let html = div {
    h1("Welcome")
    p("Hello, world!")
    if showDetails {
        p("Details here")
    }
}
```

## Result Builder: buildFinalResult

Transform the accumulated result at the end:

```swift
@resultBuilder
struct AttributedStringBuilder {
    static func buildBlock(_ components: AttributedString...) -> AttributedString {
        components.reduce(into: AttributedString()) { $0.append($1) }
    }

    static func buildFinalResult(_ component: AttributedString) -> Text {
        Text(component)
    }
}
```

## Property Wrapper: UserDefaults-Backed

```swift
@propertyWrapper
struct AppStorage<Value> {
    let key: String
    let defaultValue: Value
    let store: UserDefaults

    var wrappedValue: Value {
        get { store.object(forKey: key) as? Value ?? defaultValue }
        set { store.set(newValue, forKey: key) }
    }

    init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = wrappedValue
        self.store = store
    }
}

// Usage
struct Settings {
    @AppStorage("onboarding_complete") var onboardingComplete = false
    @AppStorage("preferred_theme") var theme = "system"
}
```

## Property Wrapper: Validated

```swift
@propertyWrapper
struct Validated<Value> {
    private var value: Value
    private let validator: (Value) -> Bool
    private(set) var isValid: Bool

    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            isValid = validator(newValue)
        }
    }

    var projectedValue: Bool { isValid }

    init(wrappedValue: Value, _ validator: @escaping (Value) -> Bool) {
        self.value = wrappedValue
        self.validator = validator
        self.isValid = validator(wrappedValue)
    }
}

// Usage
struct SignUpForm {
    @Validated({ $0.count >= 3 }) var username = ""
    @Validated({ $0.contains("@") && $0.contains(".") }) var email = ""

    var canSubmit: Bool { $username && $email }
}
```

## Advanced Regex Builder Patterns

### Reference captures with strong typing

```swift
import RegexBuilder

struct LogEntry {
    let timestamp: String
    let level: String
    let message: String
}

let timestampRef = Reference(Substring.self)
let levelRef = Reference(Substring.self)
let messageRef = Reference(Substring.self)

let logRegex = Regex {
    Capture(as: timestampRef) { /\[.+?\]/ }
    " "
    Capture(as: levelRef) {
        ChoiceOf { "INFO"; "WARN"; "ERROR"; "DEBUG" }
    }
    ": "
    Capture(as: messageRef) { OneOrMore(.any) }
}

if let match = "[2026-05-28] INFO: Started".firstMatch(of: logRegex) {
    let entry = LogEntry(
        timestamp: String(match[timestampRef]),
        level: String(match[levelRef]),
        message: String(match[messageRef])
    )
    _ = entry
}
```

### Reusing regex components

```swift
let ipOctet = Regex {
    ChoiceOf {
        Regex { "25"; ("0"..."5") }
        Regex { "2"; ("0"..."4"); .digit }
        Regex { Optionally { ("0"..."1") }; .digit; Optionally { .digit } }
    }
}

let ipAddress = Regex {
    ipOctet; "."; ipOctet; "."; ipOctet; "."; ipOctet
}
```

## FormatStyle: Custom FormatStyle

Create reusable format styles for domain types:

```swift
struct FileSize {
    let bytes: Int64
}

struct FileSizeFormatStyle: FormatStyle {
    typealias FormatInput = FileSize
    typealias FormatOutput = String

    func format(_ value: FileSize) -> String {
        ByteCountFormatter.string(fromByteCount: value.bytes, countStyle: .file)
    }
}

extension FormatStyle where Self == FileSizeFormatStyle {
    static var fileSize: FileSizeFormatStyle { .init() }
}

// Usage
let size = FileSize(bytes: 1_500_000)
FileSizeFormatStyle().format(size) // "1.5 MB"
```

Use `swift-formatstyle` for richer reusable style design, parsing, and
locale-sensitive formatting review.

## Collection Patterns: Chunking and Windows

```swift
// chunks(ofCount:) -- Swift Algorithms package
import Algorithms

let batches = items.chunks(ofCount: 10)
for batch in batches {
    try await upload(batch)
}

// windows(ofCount:) -- sliding window
let movingAverages = values.windows(ofCount: 3).map { window in
    window.reduce(0, +) / Double(window.count)
}

// adjacentPairs() -- process consecutive elements
for (previous, current) in values.adjacentPairs() {
    if current > previous * 2 {
        print("Spike detected")
    }
}
```

## Guard: Complex Pattern Matching

```swift
func processResponse(_ data: Data) throws -> User {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let userData = json["user"] as? [String: Any],
          let name = userData["name"] as? String,
          let id = userData["id"] as? Int
    else {
        throw ParseError.invalidFormat
    }

    // Use Codable instead when practical -- this is for mixed/dynamic JSON
    return User(id: id, name: name)
}

// Guard with where clause
func processItems(_ items: [Item]) {
    for item in items {
        guard case .active(let config) = item.status,
              config.isEnabled,
              !config.isExpired
        else { continue }

        activate(item, with: config)
    }
}
```

## Typed Throws: Protocol with Typed Errors

```swift
protocol DataStore {
    associatedtype StoreError: Error
    func save(_ data: Data) throws(StoreError)
    func load(id: String) throws(StoreError) -> Data
}

struct FileStore: DataStore {
    enum StoreError: Error {
        case notFound, permissionDenied, diskFull
    }

    func save(_ data: Data) throws(StoreError) {
        // ...
    }

    func load(id: String) throws(StoreError) -> Data {
        guard fileExists(id) else { throw .notFound }
        // ...
    }
}
```

## String Interpolation: Custom appendInterpolation

Apple documents `DefaultStringInterpolation` as the type used while building interpolated strings, and supports extending it with custom `appendInterpolation(...)` overloads.

```swift
extension DefaultStringInterpolation {
    mutating func appendInterpolation(json value: some Encodable) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(value),
           let string = String(data: data, encoding: .utf8) {
            appendLiteral(string)
        }
    }

    mutating func appendInterpolation(ordinal value: Int) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        if let result = formatter.string(from: value as NSNumber) {
            appendLiteral(result)
        }
    }
}

print("Config: \(json: settings)")
print("You placed \(ordinal: 3)")
```

## Never: Advanced Usage

```swift
// Publisher that never fails
let publisher: AnyPublisher<String, Never> = Just("hello").eraseToAnyPublisher()

// Phantom type preventing construction
enum Locked {}
enum Unlocked {}

struct Door<State> {
    private init() {}
}

extension Door where State == Unlocked {
    func open() { /* ... */ }
}

// Generic constraint meaning "this case cannot happen"
func absurd<T>(_ never: Never) -> T {
    // No body needed -- Never has no values, so this is never called
}
```
