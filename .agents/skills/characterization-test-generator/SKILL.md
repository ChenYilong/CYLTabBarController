---
name: characterization-test-generator
description: Generates tests that capture current behavior of existing code before refactoring. Use when you need a safety net before AI-assisted refactoring or modifying legacy code.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Characterization Test Generator

Generate tests that document what existing code **actually does** — not what it should do. These tests capture current behavior so you can refactor with confidence, especially when using AI to modify code.

## When This Skill Activates

Use this skill when the user:
- Says "I need to refactor this" or "help me refactor"
- Wants to "add tests before changing code"
- Asks for "characterization tests" or "golden master tests"
- Says "I want to safely modify this class/module"
- Mentions "legacy code" or "untested code"
- Wants AI to refactor but is worried about breaking things

## Why This Matters for AI-Generated Code

AI refactoring is powerful but risky:
- AI doesn't remember **why** code works a certain way
- AI may "improve" code and break subtle behavior
- Characterization tests freeze current behavior as a regression suite
- If any test fails after refactoring, you know something changed

## Process

### Phase 1: Discover Code Under Test

```
Glob: **/*.swift (in the target module)
Grep: "class |struct |enum |protocol |func " (public API surface)
```

Identify:
- [ ] Public types and their public methods
- [ ] Input types and return types
- [ ] Side effects (network, disk, UserDefaults, notifications)
- [ ] Dependencies (injected or created internally)
- [ ] State mutations (properties that change)

### Phase 2: Classify Behavior

For each public method, classify:

| Category | Example | Test Strategy |
|----------|---------|---------------|
| Pure computation | `calculate(a, b) -> c` | Input/output pairs |
| State mutation | `addItem(_:)` modifies array | Before/after state checks |
| Async operation | `fetchData() async -> [Item]` | Mock dependencies, verify results |
| Side effect | `save()` writes to disk | Verify mock was called |
| Event emission | `delegate?.didUpdate()` | Capture delegate calls |
| Error path | Throws on invalid input | Verify correct error type |

### Phase 3: Generate Tests

#### Test Naming Convention

Characterization tests should be clearly labeled:

```swift
import Testing
@testable import YourApp

@Suite("Characterization: ItemManager")
struct ItemManagerCharacterizationTests {
    // Tests document CURRENT behavior, not ideal behavior
}
```

#### Template: Pure Computation

```swift
@Test("current behavior: calculates total with tax")
func calculatesTotal() {
    let calculator = PriceCalculator()

    let result = calculator.total(subtotal: 100.0, taxRate: 0.08)

    // Document actual behavior — even if the rounding seems wrong
    #expect(result == 108.0)
}
```

#### Template: State Mutation

```swift
@Test("current behavior: addItem appends and sorts by date")
func addItemSortsbyDate() {
    let manager = ItemManager()
    let older = Item(title: "A", date: .distantPast)
    let newer = Item(title: "B", date: .now)

    manager.addItem(older)
    manager.addItem(newer)

    // Document actual ordering behavior
    #expect(manager.items.first?.title == "A")
    #expect(manager.items.last?.title == "B")
    #expect(manager.items.count == 2)
}
```

#### Template: Async with Dependencies

```swift
@Test("current behavior: loadItems returns cached data when offline")
func loadItemsOffline() async throws {
    let mockNetwork = MockNetworkClient(shouldFail: true)
    let mockCache = MockCache(items: [Item.sample])
    let service = ItemService(network: mockNetwork, cache: mockCache)

    let items = try await service.loadItems()

    // Document: falls back to cache when network fails
    #expect(items.count == 1)
    #expect(items.first?.title == Item.sample.title)
}
```

#### Template: Side Effects

```swift
@Test("current behavior: save writes to UserDefaults")
func saveWritesToDefaults() {
    let defaults = MockUserDefaults()
    let settings = SettingsManager(defaults: defaults)

    settings.setTheme(.dark)
    settings.save()

    // Document: saves as string, not as enum raw value
    #expect(defaults.lastSetValue as? String == "dark")
    #expect(defaults.lastSetKey == "app_theme")
}
```

#### Template: Error Paths

```swift
@Test("current behavior: throws on empty title")
func throwsOnEmptyTitle() {
    let validator = ItemValidator()

    #expect(throws: ValidationError.emptyField("title")) {
        try validator.validate(Item(title: "", date: .now))
    }
}
```

#### Template: Edge Cases

```swift
@Test("current behavior: handles nil optional gracefully")
func handlesNilOptional() {
    let parser = DataParser()

    let result = parser.parse(data: nil)

    // Document: returns empty array on nil, doesn't crash
    #expect(result.isEmpty)
}

@Test("current behavior: handles empty collection")
func handlesEmptyCollection() {
    let aggregator = StatsAggregator()

    let stats = aggregator.compute(values: [])

    // Document: returns zeroes, not NaN or crash
    #expect(stats.average == 0.0)
    #expect(stats.count == 0)
}
```

### Phase 4: Fill in Actual Values

This is the key step. For each test:

1. **Read the source code** to understand what the method actually returns
2. **Trace the logic** for the given inputs
3. **Write the assertion with the actual value**

```swift
// ❌ Wrong — this is what you WANT it to do
#expect(result == expectedCorrectValue)

// ✅ Right — this is what it ACTUALLY does
#expect(result == actualCurrentValue)  // Note: off-by-one, but current behavior
```

**Add comments for surprising behavior:**
```swift
// CHARACTERIZATION: This returns 11 not 10 due to inclusive range.
// Don't "fix" this until intentionally changing behavior.
#expect(range.count == 11)
```

### Phase 5: Verify and Lock

1. **Run all characterization tests** — they must ALL pass
2. **If any fail**, adjust assertions to match actual behavior
3. **Tag them:**

```swift
@Suite("Characterization: ItemManager")
@Tag(.characterization)
struct ItemManagerCharacterizationTests { ... }

// Define the tag
extension Tag {
    @Tag static var characterization: Self
}
```

4. **Run selectively:**
```bash
# Run only characterization tests
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/ItemManagerCharacterizationTests"
```

## Output Format

```markdown
## Characterization Tests Generated

**Module**: [Module name]
**Classes tested**: [List]
**Tests generated**: [Count]

### Coverage Summary

| Class | Methods Covered | Edge Cases | Notes |
|-------|----------------|------------|-------|
| ItemManager | 5/7 | 3 | 2 private methods skipped |
| PriceCalculator | 3/3 | 2 | All public API covered |

### Files Created
- `Tests/CharacterizationTests/ItemManagerCharacterizationTests.swift`
- `Tests/CharacterizationTests/PriceCalculatorCharacterizationTests.swift`

### Surprising Behaviors Found
- `PriceCalculator.total()` rounds DOWN, not to nearest cent
- `ItemManager.sort()` is unstable — equal dates may reorder

### Ready to Refactor
All [X] characterization tests passing. Safe to refactor with AI.
Run `xcodebuild test` after each change to verify no behavior changed.
```

## When NOT to Use This

- Code is already well-tested (check coverage first)
- You're deleting the code entirely (no need to characterize)
- The code is trivially simple (single-line computed properties)
- You **want** to change the behavior (use `tdd-bug-fix` instead)

## References

- Michael Feathers, *Working Effectively with Legacy Code* — coined "characterization test"
- `generators/test-generator/` — for standard test generation (not characterization)
- `testing/tdd-refactor-guard/` — pre-refactor checklist that uses these tests
