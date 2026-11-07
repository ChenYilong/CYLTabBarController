---
name: tdd-bug-fix
description: Fix bugs using red-green-refactor — reproduce the bug as a failing test first, then fix it. Use when fixing bugs to ensure they never regress.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# TDD Bug Fix

Fix bugs the right way: reproduce first, fix second, verify always. Especially critical when using AI to generate fixes — the test ensures the AI actually solved the problem.

## When This Skill Activates

Use this skill when the user:
- Reports a bug and wants it fixed
- Says "this is broken" or "this doesn't work"
- Asks to "fix and add a test" or "fix with TDD"
- Wants to ensure a bug doesn't come back
- Is skeptical of AI-generated fixes ("how do I know it's actually fixed?")

## Why TDD for Bug Fixes

```
Without TDD:           With TDD:
Bug reported           Bug reported
  → AI generates fix     → Write failing test (RED)
  → Deploy               → AI generates fix (GREEN)
  → Hope it works        → Test passes — confirmed fixed
  → Bug returns later    → Test prevents regression forever
```

## Process

### Phase 1: Understand the Bug

Gather information:

1. **What's the expected behavior?**
2. **What's the actual behavior?**
3. **Steps to reproduce?**
4. **Which code is involved?**

```
Grep: "[relevant keyword]" to find the source
Read: the suspected file(s)
```

Identify:
- [ ] The function/method where the bug lives
- [ ] The input that triggers the bug
- [ ] The incorrect output/behavior
- [ ] The correct expected output/behavior

### Phase 2: RED — Write the Failing Test

Write a test that **fails because of the bug**. This proves the bug exists.

#### Template: Logic Bug

```swift
import Testing
@testable import YourApp

@Suite("Bug Fix: [Brief description]")
struct BugFix_DescriptionTests {

    @Test("should [expected behavior] — was [actual behavior]")
    func reproduceBug() {
        // Arrange — set up the conditions that trigger the bug
        let calculator = PriceCalculator()

        // Act — perform the operation that's broken
        let result = calculator.applyDiscount(price: 100, percent: 50)

        // Assert — what it SHOULD return (this will FAIL now)
        #expect(result == 50.0)  // Currently returns 0.5 (bug: divides by 100 twice)
    }
}
```

#### Template: Async Bug

```swift
@Test("should return cached items when network fails — was crashing")
func reproduceBug() async throws {
    let mockNetwork = MockNetworkClient(shouldFail: true)
    let mockCache = MockCache(items: [.sample])
    let service = DataService(network: mockNetwork, cache: mockCache)

    // This should return cached data, but currently crashes
    let items = try await service.fetchItems()

    #expect(items.count == 1)
}
```

#### Template: State Bug

```swift
@Test("should update count after deletion — was showing stale count")
func reproduceBug() {
    let manager = ItemManager()
    manager.addItem(Item(title: "Test"))

    manager.deleteItem(at: 0)

    #expect(manager.count == 0)     // Currently still returns 1
    #expect(manager.items.isEmpty)  // Currently still contains item
}
```

#### Template: Edge Case Bug

```swift
@Test("should handle empty input — was crashing with index out of range")
func reproduceBug() {
    let parser = CSVParser()

    // This crashes with empty string
    let result = parser.parse("")

    #expect(result.rows.isEmpty)
    #expect(result.columns.isEmpty)
}
```

#### Template: UI State Bug

```swift
@Test("should show error state when API fails — was showing infinite spinner")
func reproduceBug() async {
    let failingAPI = MockAPI(shouldFail: true)
    let viewModel = ListViewModel(api: failingAPI)

    await viewModel.loadData()

    #expect(viewModel.state == .error)  // Currently stuck on .loading
    #expect(viewModel.isLoading == false)
}
```

**Run the test — it MUST fail.** If it passes, you haven't reproduced the bug.

```bash
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/BugFix_DescriptionTests"
```

### Phase 3: GREEN — Fix the Bug

Now fix the code to make the test pass. The fix should be **minimal** — only change what's needed.

#### Fix Guidelines

- **Minimal, targeted fix** — change only what's needed; don't refactor or fix unrelated issues (file those separately)
- **AI should target the specific test** — give Claude the failing test as context

```
Prompt to Claude: "Here's a failing test that reproduces a bug.
Fix the source code to make this test pass without breaking
any existing tests."
```

**Run the test — it MUST pass now.**

```bash
# Run the bug fix test
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/BugFix_DescriptionTests"

# Run ALL tests to check for regressions
xcodebuild test -scheme YourApp
```

### Phase 4: REFACTOR (Optional)

If the fix introduced duplication or the code could be cleaner:

1. **Refactor only with all tests passing**
2. **Run tests after each change**
3. **Keep the bug fix test** — it's now a permanent regression test

### Phase 5: Verify Completeness

Checklist before marking the bug as fixed:

- [ ] Failing test written that reproduces the bug
- [ ] Fix implemented — test now passes
- [ ] All existing tests still pass (no regressions)
- [ ] Edge cases covered (empty, nil, boundary values)
- [ ] Test is clearly named and documents the bug
- [ ] Fix is minimal — no unrelated changes

## Multiple Related Bugs

If a bug has multiple symptoms, write multiple tests:

```swift
@Suite("Bug Fix: Discount calculation errors")
struct BugFix_DiscountCalculationTests {

    @Test("50% discount on $100 should be $50")
    func fiftyPercentDiscount() {
        let calc = PriceCalculator()
        #expect(calc.applyDiscount(price: 100, percent: 50) == 50.0)
    }

    @Test("discount on $0 should return $0")
    func zeroPrice() {
        let calc = PriceCalculator()
        #expect(calc.applyDiscount(price: 0, percent: 50) == 0.0)
    }
}
```

## Output Format

```markdown
## Bug Fix: [Description]

### Bug Summary
- **Expected**: [What should happen]
- **Actual**: [What was happening]
- **Root cause**: [Why it was broken]

### Test (RED)
```swift
// Failing test that reproduces the bug
```

### Fix (GREEN)
**File**: `path/to/file.swift:XX`
```swift
// Before (buggy)
// After (fixed)
```

### Verification
- [x] Bug test fails before fix
- [x] Bug test passes after fix
- [x] All existing tests still pass
- [x] Edge cases covered: [list]

### Regression Prevention
Test added: `Tests/BugFixes/BugFix_DescriptionTests.swift`
This test will catch any future regression of this bug.
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Test passes before fix | You didn't reproduce the bug | Make assertions more specific |
| Fix breaks other tests | Fix was too broad | Revert and use smaller, targeted change |
| Test is too specific | Brittle, breaks on unrelated changes | Test behavior, not implementation details |
| Skipping the red step | No proof the test catches the bug | Always verify test fails first |

## References

- `testing/tdd-feature/` — for new features (not bug fixes)
- `testing/characterization-test-generator/` — for capturing existing behavior first
- `generators/test-generator/` — for general test generation
