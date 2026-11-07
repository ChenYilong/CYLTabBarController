---
name: migration-patterns
description: Migration guides for CoreData to SwiftData, UIKit to SwiftUI, ObservableObject to @Observable, XCTest to Swift Testing, Objective-C to Swift, and StoreKit 1 to StoreKit 2. Use when migrating between Apple framework generations.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Migration Patterns

Comprehensive guides for migrating between Apple framework generations. Each guide covers the full before/after mapping, coexistence strategies, and common pitfalls.

## When This Skill Activates

- User asks how to migrate from CoreData to SwiftData
- User is moving UIKit code to SwiftUI (or embedding one in the other)
- User needs to update from ObservableObject/Combine to @Observable/AsyncSequence
- User is converting XCTest tests to Swift Testing
- User asks about coexistence strategies (running old and new frameworks side by side)
- User wants to know whether a migration is worth doing for their situation
- User is migrating Objective-C code to Swift (bridging headers, incremental migration)
- User is migrating from StoreKit 1 to StoreKit 2 (in-app purchases, subscriptions)
- User encounters errors during a framework migration

## Decision Tree

```
What are you migrating?
|
+-- Data persistence layer
|   +-- CoreData --> SwiftData
|   |   See coredata-to-swiftdata.md
|   |   Min: iOS 17 / macOS 14
|   |
|   +-- Still need CoreData features SwiftData lacks?
|       Stay on CoreData or use coexistence mode
|
+-- UI framework
|   +-- UIKit --> SwiftUI
|   |   See uikit-to-swiftui.md
|   |   Min: iOS 13 (basic), iOS 16+ (modern navigation)
|   |
|   +-- Full rewrite or incremental?
|       Incremental is almost always better -- adopt screen by screen
|
+-- State management / observation
|   +-- ObservableObject --> @Observable
|   |   See observable-migration.md
|   |   Min: iOS 17 / macOS 14
|   |
|   +-- Combine publishers --> AsyncSequence
|       Also covered in observable-migration.md
|
+-- Programming language
|   +-- Objective-C --> Swift
|   |   See objc-to-swift.md
|   |   Incremental: migrate leaves first, trunks last
|   |
|   +-- Mixed-language project?
|       Both languages coexist via bridging headers
|
+-- In-app purchases
|   +-- StoreKit 1 --> StoreKit 2
|   |   See storekit-migration.md
|   |   Min: iOS 15
|   |
|   +-- Using a third-party SDK (RevenueCat, etc.)?
|       Check if SDK already supports StoreKit 2 internally
|
+-- Testing framework
    +-- XCTest --> Swift Testing
        See xctest-to-swift-testing.md
        Min: Xcode 16 / Swift 6.0
```

## Quick Reference

| Migration | Reference File | Minimum OS | Risk Level |
|-----------|---------------|------------|------------|
| CoreData to SwiftData | `coredata-to-swiftdata.md` | iOS 17 / macOS 14 | High (data layer) |
| UIKit to SwiftUI | `uikit-to-swiftui.md` | iOS 13+ | Medium (incremental) |
| ObservableObject to @Observable | `observable-migration.md` | iOS 17 / macOS 14 | Low-Medium |
| Objective-C to Swift | `objc-to-swift.md` | Any | Medium (incremental) |
| StoreKit 1 to StoreKit 2 | `storekit-migration.md` | iOS 15 | Medium-High (payments) |
| XCTest to Swift Testing | `xctest-to-swift-testing.md` | Xcode 16 | Low |

## Process

### 1. Assess the Migration

Before starting, determine:
- What is the minimum deployment target? Many migrations require iOS 17+.
- How large is the surface area? (number of models, screens, test files)
- Can you adopt incrementally or is it all-or-nothing?
- Are there third-party dependencies that assume the old framework?

### 2. Load Relevant Reference File

Based on the migration type, read from this directory:
- `coredata-to-swiftdata.md` -- NSManagedObject to @Model, migration stages, coexistence
- `uikit-to-swiftui.md` -- UIHostingController, Representable, incremental adoption
- `observable-migration.md` -- @Observable macro, @Environment injection, AsyncSequence
- `objc-to-swift.md` -- Bridging headers, @objc, incremental file-by-file migration
- `storekit-migration.md` -- StoreKit 2 async/await purchases, Transaction.currentEntitlements, JWS
- `xctest-to-swift-testing.md` -- @Test, #expect, #require, parameterized tests

### 3. Review the User's Code

Scan for old-framework patterns and map each to its modern equivalent using the reference file. Check for:

- [ ] Deprecated API usage that has a direct modern replacement
- [ ] Custom workarounds that are no longer needed with the new framework
- [ ] Third-party dependencies that may conflict with the migration
- [ ] Coexistence requirements (both frameworks running simultaneously)

### 4. Recommend a Migration Strategy

For each migration, decide between:

- **Full migration**: Replace all old-framework code at once. Best for small codebases or when old framework is causing problems.
- **Incremental migration**: Migrate piece by piece while both frameworks coexist. Best for large codebases, production apps, or when timeline is flexible.
- **No migration**: The old framework is still appropriate. See "When NOT to Migrate" in each reference file.

## General Migration Principles

1. **Migrate tests first.** If you are migrating both app code and tests, migrate tests to Swift Testing first. This gives you a safety net for the app-code migration.

2. **One migration at a time.** Do not migrate CoreData to SwiftData and ObservableObject to @Observable in the same PR. Each migration should be independently reviewable and revertible.

3. **Keep the old code compiling.** During incremental migration, both old and new code must compile and run. Use coexistence patterns from each reference file.

4. **Feature-flag large migrations.** For production apps, consider gating new-framework code behind a feature flag so you can roll back without a code revert.

5. **Write migration tests.** For data-layer migrations (CoreData to SwiftData), write tests that verify data roundtrips correctly through both stacks.

## References

- [Migrating from CoreData to SwiftData](https://developer.apple.com/documentation/coredata/migrating-from-core-data-to-swiftdata)
- [Migrating to new navigation types](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types)
- [Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [Migrating a test from XCTest](https://developer.apple.com/documentation/testing/migratingfromxctest)
- [Migrating an app from StoreKit 1](https://developer.apple.com/documentation/storekit/in-app_purchase/implementing_a_store_in_your_app_using_the_storekit_api)
