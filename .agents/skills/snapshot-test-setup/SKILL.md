---
name: snapshot-test-setup
description: Set up SwiftUI visual regression testing with swift-snapshot-testing. Generates snapshot test boilerplate and CI configuration. Use for UI regression prevention.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-24
review_by: 2027-06-22
---

# Snapshot Test Setup

Generate SwiftUI snapshot/visual regression tests using Point-Free's swift-snapshot-testing library. Catches unintended UI changes by comparing rendered views against reference images.

## When This Skill Activates

Use this skill when the user:
- Wants "snapshot tests" or "visual regression tests"
- Says "I want to catch UI regressions"
- Asks about "screenshot testing" or "preview testing"
- Wants to verify SwiftUI views don't change unexpectedly
- Mentions "swift-snapshot-testing" or "Point-Free"

## Why Snapshot Tests

```
Without snapshots:        With snapshots:
Change a modifier         Change a modifier
  → Looks fine locally      → Snapshot test fails
  → Push to main            → Shows exact visual diff
  → User reports UI bug     → Fix before merging
  → Embarrassing             → Confidence in UI changes
```

## Pre-Setup Checks

### 1. Project Context

```
Glob: **/Package.swift or **/*.xcodeproj
Grep: "swift-snapshot-testing" (already added?)
Grep: "SnapshotTesting" in test files
```

### 2. Configuration Questions

Ask via AskUserQuestion:

1. **Package manager?**
   - Swift Package Manager
   - CocoaPods
   - Tuist

2. **Platform?**
   - iOS
   - macOS
   - Both

3. **What to test?**
   - Specific views (user provides names)
   - All screens
   - Component library

## Setup Process

### Step 1: Add Dependency

#### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        from: "1.17.0"
    )
]

// Test target
.testTarget(
    name: "YourAppTests",
    dependencies: [
        "YourApp",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
    ]
)
```

#### Xcode Project

1. File → Add Package Dependencies
2. URL: `https://github.com/pointfreeco/swift-snapshot-testing`
3. Add `SnapshotTesting` to your test target

### Step 2: Create Snapshot Test Base

```swift
import Testing
import SnapshotTesting
import SwiftUI
@testable import YourApp

// MARK: - Snapshot Configuration

enum SnapshotConfig {
    // iOS devices to test
    static let iPhoneConfigs: [String: ViewImageConfig] = [
        "iPhone_SE": .iPhoneSe,
        "iPhone_16": .iPhone13,       // Similar dimensions
        "iPhone_16_Pro_Max": .iPhone13ProMax
    ]

    // macOS window sizes
    static let macOSConfigs: [String: CGSize] = [
        "compact": CGSize(width: 400, height: 600),
        "regular": CGSize(width: 800, height: 600),
        "wide": CGSize(width: 1200, height: 800)
    ]

    // Color schemes to test
    static let colorSchemes: [ColorScheme] = [.light, .dark]
}
```

### Step 3: Generate Snapshot Tests

#### iOS View Snapshot

```swift
@Suite("Snapshots: HomeView")
struct HomeViewSnapshotTests {

    // perceptualPrecision < 1.0 absorbs GPU/anti-aliasing noise across runs
    // on the same pinned simulator — 0.98 catches real layout/color changes
    // while ignoring sub-perceptual rendering jitter.
    @Test("matches reference - light mode")
    func lightMode() {
        let view = HomeView(items: Item.sampleList)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13, perceptualPrecision: 0.98)
        )
    }

    @Test("matches reference - dark mode")
    func darkMode() {
        let view = HomeView(items: Item.sampleList)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13, perceptualPrecision: 0.98)
        )
    }

    @Test("matches reference - empty state")
    func emptyState() {
        let view = HomeView(items: [])

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13, perceptualPrecision: 0.98)
        )
    }

    @Test("matches reference - accessibility Dynamic Type")
    func dynamicTypeAccessibility() {
        let view = HomeView(items: Item.sampleList)
            .environment(\.dynamicTypeSize, .accessibility3)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13, perceptualPrecision: 0.98)
        )
    }
}
```

#### macOS View Snapshot

```swift
@Suite("Snapshots: SettingsView")
struct SettingsViewSnapshotTests {

    @Test("matches reference - standard size")
    func standardSize() {
        let view = SettingsView()
            .frame(width: 500, height: 400)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: CGSize(width: 500, height: 400))
        )
    }

    @Test("matches reference - dark mode")
    func darkMode() {
        let view = SettingsView()
            .frame(width: 500, height: 400)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: CGSize(width: 500, height: 400))
        )
    }
}
```

#### Component Snapshot (Reusable)

```swift
@Suite("Snapshots: ItemCard")
struct ItemCardSnapshotTests {

    @Test("default state")
    func defaultState() {
        let view = ItemCard(item: .sample)
            .frame(width: 300)

        assertSnapshot(of: view, as: .image)
    }

    @Test("selected state")
    func selectedState() {
        let view = ItemCard(item: .sample, isSelected: true)
            .frame(width: 300)

        assertSnapshot(of: view, as: .image)
    }

    @Test("long title wraps")
    func longTitle() {
        let item = Item(title: "This is a very long title that should wrap to multiple lines")
        let view = ItemCard(item: item)
            .frame(width: 300)

        assertSnapshot(of: view, as: .image)
    }
}
```

### Step 4: Recording Reference Images

First run records reference images (golden masters):

```bash
# Record all snapshots (first run)
xcodebuild test -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Reference images land in `__Snapshots__/` directories next to test files:

```
Tests/SnapshotTests/
├── __Snapshots__/
│   └── HomeViewSnapshotTests/
│       ├── lightMode.1.png
│       ├── darkMode.1.png
│       ├── emptyState.1.png
│       └── dynamicTypeXXL.1.png
├── HomeViewSnapshotTests.swift
└── ItemCardSnapshotTests.swift
```

### Step 5: Re-record When Intentional Changes

When you intentionally change a view:

```swift
// Temporarily set record mode
@Test("matches reference - light mode")
func lightMode() {
    withSnapshotTesting(record: .all) {
        let view = HomeView(items: Item.sampleList)
        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13)
        )
    }
}
```

## Gate Wiring (the deterministic UI gate)

Snapshot suites are the UI half of the deterministic gauntlet (code half:
`testing/fitness-functions`, `swift/code-size`, `testing/coverage-ratchet`).
They use the same install trick as fitness functions: **they are ordinary
tests in the existing unit-test target**, so they ride every `test` gate that
already exists — no new CI plumbing to *run* them. What makes them a *gate*
rather than a capability:

- **A pixel diff is a FAIL, not a discussion.** SwiftShip's `<check
  type="snapshot">` runs the suite scoped to a task's touched screens
  (`-only-testing`); the phase does not close on a red diff.
- **The re-record ratchet.** `__Snapshots__/` baselines are committed;
  re-recording is a *stated decision* — the commit message says which screens
  changed and why. Record mode (`withSnapshotTesting(record: .all)`) is never
  committed enabled; a committed record-mode test asserts nothing.
- **Determinism guards.** Pin one simulator model/OS as the snapshot
  destination and document it in the suite header (baselines from other
  devices/OS versions will diff). Use `perceptualPrecision: 0.98`. Require a
  **double-run green** before committing new baselines — a suite that flakes
  between two identical runs is not a gate. OS/simulator bumps legitimately
  require re-records: that's a stated-intent event like any other.
- **New or changed screen ⇒ snapshot in the same task.** A view task without
  a snapshot for its touched screens leaves the gate blind exactly where the
  change happened.
- **Environment assembly:** reuse the project's preview harness (the struct
  its `#Preview`s already use to inject state/environment) rather than
  building a parallel one — the DEBUG-only harness is visible to test builds,
  and reuse keeps snapshots rendering exactly what previews render.

## What to Snapshot

### High Value (Always Snapshot)
- Screens with multiple states (empty, loaded, error), reusable components across configurations, light/dark mode, Dynamic Type at accessibility sizes

### Medium Value (Selectively Snapshot)
- Navigation flows (each step)
- Onboarding screens
- Paywall/subscription views
- Settings screens

### Low Value (Skip)
- Views that are 100% system components (plain List, NavigationStack)
- Views that change frequently during active development
- Views dependent on live data

## CI Integration

### GitHub Actions

```yaml
- name: Run Snapshot Tests
  run: |
    xcodebuild test \
      -scheme YourApp \
      -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
      -only-testing "YourAppTests/Snapshots" \
      -resultBundlePath TestResults.xcresult

- name: Upload Failed Snapshots
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: failed-snapshots
    path: "**/Failures/**"
```

### Xcode Cloud

```bash
# ci_scripts/ci_post_xcodebuild.sh
if [ "$CI_XCODEBUILD_ACTION" = "test" ]; then
    # Upload snapshot failures as artifacts
    if [ -d "$CI_DERIVED_DATA_PATH" ]; then
        find "$CI_DERIVED_DATA_PATH" -name "Failures" -type d \
            -exec cp -r {} "$CI_RESULT_BUNDLE_PATH/" \;
    fi
fi
```

## Output Format

```markdown
## Snapshot Tests Setup

### Dependency Added
swift-snapshot-testing 1.17.0 via SPM

### Tests Generated
| View | Configurations | Tests |
|------|---------------|-------|
| HomeView | light, dark, empty, XXL type | 4 |
| SettingsView | light, dark | 2 |
| ItemCard | default, selected, long title | 3 |
| **Total** | | **9** |

### Files Created
- `Tests/SnapshotTests/HomeViewSnapshotTests.swift`
- `Tests/SnapshotTests/SettingsViewSnapshotTests.swift`
- `Tests/SnapshotTests/ItemCardSnapshotTests.swift`

### Next Steps
1. Run tests once to record reference images
2. Commit `__Snapshots__/` directories to git
3. Add snapshot test step to CI pipeline
```

## References

- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
- `generators/test-generator/` — for unit/integration test generation
- `testing/tdd-feature/` — for TDD workflow with UI features
- `testing/fitness-functions/` — the code half of the deterministic gauntlet (same ride-the-test-gate trick)
