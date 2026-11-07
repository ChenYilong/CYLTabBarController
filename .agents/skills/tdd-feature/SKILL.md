---
name: tdd-feature
description: Red-green-refactor scaffold for building new features with TDD. Write failing tests first, then implement to pass. Use when building new features test-first.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# TDD Feature

Build new features using the red-green-refactor cycle. Tests define the spec, AI generates the implementation, tests verify correctness.

## When This Skill Activates

Use this skill when the user:
- Wants to "TDD a new feature" or "build test-first"
- Says "I want tests before code"
- Asks for "red-green-refactor" workflow
- Wants AI to generate code that's provably correct
- Is building a new module, service, or feature from scratch

## Why TDD for New Features with AI

```
Traditional:     AI generates code → You hope it's correct → Ship → Find bugs
TDD with AI:     You write tests (spec) → AI generates code to pass → Proven correct
```

The test is your **acceptance criteria in code form**. AI excels at going from failing test to passing implementation — it's a concrete, unambiguous target.

## Process

### Phase 1: Define the Feature

Before writing any code or tests, understand:

1. **What does this feature do?** (user story or requirement)
2. **What are the inputs?** (parameters, user actions, data)
3. **What are the outputs?** (return values, state changes, UI updates)
4. **What are the edge cases?** (empty, nil, error, boundary)
5. **What dependencies does it need?** (network, storage, other services)

### Phase 2: Design the API Surface

Sketch the public interface before writing tests:

```swift
// Example: Designing a FavoriteManager
protocol FavoriteManaging {
    func add(_ item: Item) async throws
    func remove(_ item: Item) async throws
    func isFavorite(_ item: Item) -> Bool
    var favorites: [Item] { get }
    var count: Int { get }
}
```

This doesn't need to compile yet — it's the contract you'll test against.

### Phase 3: RED — Write Failing Tests

Write tests for each behavior. Start with the simplest case and build up.

#### Order of Tests (Simple → Complex)

1. **Construction** — can you create the object?
2. **Happy path** — does the basic operation work?
3. **State verification** — does state update correctly?
4. **Edge cases** — empty, nil, boundaries
5. **Error handling** — what fails and how?
6. **Integration** — does it work with dependencies?

#### Template: Feature Test Suite

```swift
import Testing
@testable import YourApp

@Suite("FavoriteManager")
struct FavoriteManagerTests {

    // 1. Construction
    @Test("starts with empty favorites")
    func startsEmpty() {
        let manager = FavoriteManager()
        #expect(manager.favorites.isEmpty)
        #expect(manager.count == 0)
    }

    // 2. Happy path
    @Test("can add a favorite")
    func addFavorite() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")

        try await manager.add(item)

        #expect(manager.count == 1)
        #expect(manager.isFavorite(item))
    }

    // 3. State verification
    @Test("can remove a favorite")
    func removeFavorite() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")
        try await manager.add(item)

        try await manager.remove(item)

        #expect(manager.count == 0)
        #expect(!manager.isFavorite(item))
    }

    // 4. Edge cases
    @Test("adding duplicate does not increase count")
    func addDuplicate() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")

        try await manager.add(item)
        try await manager.add(item)

        #expect(manager.count == 1)
    }

    @Test("removing non-existent item does nothing")
    func removeNonExistent() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")

        try await manager.remove(item)

        #expect(manager.count == 0)
    }

    // 5. Error handling
    @Test("throws when storage is full")
    func storageFullError() async {
        let manager = FavoriteManager(maxCapacity: 2)
        let items = (1...3).map { Item(id: "\($0)", title: "Item \($0)") }

        await #expect(throws: FavoriteError.capacityExceeded) {
            for item in items {
                try await manager.add(item)
            }
        }
    }

    // 6. Ordering
    @Test("favorites are in insertion order")
    func insertionOrder() async throws {
        let manager = FavoriteManager()
        let items = ["C", "A", "B"].map { Item(id: $0, title: $0) }

        for item in items {
            try await manager.add(item)
        }

        #expect(manager.favorites.map(\.title) == ["C", "A", "B"])
    }
}
```

**Run tests — they should ALL fail** (the type doesn't even exist yet).

### Phase 4: GREEN — Implement to Pass

Now implement the feature. Pass the **tests as context to AI**:

```
Prompt to Claude: "Here are my failing tests for FavoriteManager.
Implement the FavoriteManager class to make all tests pass.
Follow the protocol FavoriteManaging."
```

#### Implementation Rules

- **One test at a time** — make the first test pass, then the second, etc.
- **Write the simplest code** that passes each test
- **Don't anticipate future tests** — only satisfy current failing tests
- **Run tests after each change**

```bash
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/FavoriteManagerTests"
```

### Phase 5: REFACTOR

With all tests green, clean up the implementation:

- Extract helper methods
- Improve naming
- Remove duplication
- Optimize performance (if tests cover perf requirements)

**Run tests after every refactor step.** If any test fails, you've changed behavior — revert.

### Phase 6: Integration

Once the unit is solid, write integration tests:

```swift
@Suite("FavoriteManager Integration")
struct FavoriteManagerIntegrationTests {

    @Test("persists favorites across sessions")
    func persistence() async throws {
        let store = InMemoryStore()

        // Session 1: Add favorite
        let manager1 = FavoriteManager(store: store)
        try await manager1.add(Item(id: "1", title: "Test"))

        // Session 2: Verify it persists
        let manager2 = FavoriteManager(store: store)
        await manager2.loadFavorites()

        #expect(manager2.count == 1)
    }
}
```

## TDD Rhythm

```
RED    → Write one failing test (30 seconds - 2 minutes)
GREEN  → Make it pass with simplest code (1 - 5 minutes)
REFACTOR → Clean up while tests stay green (1 - 3 minutes)
REPEAT → Next test
```

**Cadence matters.** If you're spending more than 5 minutes on GREEN, the test might be too big. Break it into smaller tests.

## Test Categories by Feature Type

### ViewModel Feature

```swift
@Suite("SearchViewModel")
struct SearchViewModelTests {
    @Test("starts in idle state")
    @Test("searching updates state to loading")
    @Test("successful search shows results")
    @Test("empty search shows empty state")
    @Test("failed search shows error")
    @Test("debounces rapid input")
    @Test("cancels previous search on new input")
}
```

### Data Layer Feature

```swift
@Suite("ItemRepository")
struct ItemRepositoryTests {
    @Test("fetches items from remote")
    @Test("caches fetched items locally")
    @Test("returns cached items when offline")
    @Test("syncs local changes to remote")
    @Test("handles conflict resolution")
    @Test("deletes expire cached items")
}
```

### Business Logic Feature

```swift
@Suite("SubscriptionManager")
struct SubscriptionManagerTests {
    @Test("free user has basic access")
    @Test("pro user has full access")
    @Test("expired subscription reverts to free")
    @Test("family member inherits subscription")
    @Test("trial period grants pro access")
    @Test("grace period maintains access after lapse")
}
```

## Output Format

```markdown
## TDD Feature: [Feature Name]

### API Design
```swift
// Protocol / public interface
```

### Tests Written (RED)
1. `startsEmpty` — Initial state
2. `addFavorite` — Happy path
3. `removeFavorite` — State change
4. `addDuplicate` — Edge case
5. `removeNonExistent` — Edge case
6. `storageFullError` — Error handling

### Implementation (GREEN)
**File**: `Sources/Features/FavoriteManager.swift`
All [X] tests passing.

### Refactoring Done
- Extracted storage logic to private method
- Renamed internal property for clarity

### Next Steps
- [ ] Add integration tests with persistence
- [ ] Wire up to ViewModel
- [ ] Add UI for favorite toggle
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Writing too many tests before implementing | Overwhelming; can't see progress | Write 2-3 tests, implement, repeat |
| Tests that test implementation | Brittle; break on refactor | Test behavior and outcomes only |
| Skipping the refactor step | Accumulating technical debt | Refactor every 3-5 green cycles |
| AI implementing beyond the tests | Untested code in production | Only implement what tests require |
| Not running tests after each change | Silent regressions | `xcodebuild test` after every edit |

## References

- Kent Beck, *Test-Driven Development: By Example*
- `testing/test-contract/` — for protocol-level test suites
- `testing/test-data-factory/` — for reducing test setup boilerplate
- `generators/test-generator/` — for standalone test generation
