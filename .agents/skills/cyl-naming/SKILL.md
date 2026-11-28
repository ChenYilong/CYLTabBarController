---
name: cyl-naming
description: "How to name new code in CYLTabBarController after the SonarCloud re-evaluation (2026-11-22): CYL on types, no prefix on members of our own types, cylCamelCase (+ @objc(cyl_foo)) on members added to system types, cylFoo constants, Objective-C selectors unchanged, deprecated shims for released Swift names; per-language notes for Kotlin, Dart, ArkTS and TypeScript. Use before adding or renaming a public name."
---

# Naming after the static analysis (added 2026-11-22)

The same rule is in `docs/instructions/code.md` ("Naming: keep the project's prefixes", sub-item "Swift names follow SonarCloud"). When they disagree, the instruction file wins; fix this file.

## Checklist

1. Type (class, struct, enum, protocol, typealias): `CYLFoo`.
2. Member of one of our types: no prefix.
3. Member added to a type we do not own (`UIViewController`, `UIView`, `UITabBarItem`, `NSObject`…): `cylFoo`; add `@objc(cyl_foo)` when Objective-C calls it, so the selector does not change.
4. Global constant or function: `cylFoo`, or a static member of a `CYL` type.
5. Renaming a released Swift name: keep the old one as `@available(*, deprecated, renamed: "cylFoo")`. Unreleased names need no shim.
6. Objective-C selectors, headers and Objective-C class names keep `cyl_` / `CYL`.
7. Kotlin, Dart, ArkTS, TypeScript: packages / libraries / modules namespace classes and extensions; keep the prefix only where the name is global (Android resources with `resourcePrefix`, platform channel and native module names, custom component tags, CSS classes, event names, storage keys).
8. Why a prefix at all (2026-11-27, owner decisions N0-N3): Objective-C categories silently override same-named methods, so selectors keep `cyl_`. Elsewhere `cyl_` is not required: use a prefix only where a name can be silently overridden or shadowed, spelled `cylFoo`: Kotlin / Dart / TypeScript extensions on platform types (a later platform member wins over an extension), WeChat Mini Program component methods (shared instance namespace). Members of our own types, ArkTS APIs and React Native / Flutter props: no prefix. Only iOS is released: on the other platforms, rename rule-breaking names directly (no aliases). Table: docs/Animated-Item-Badge-CrossPlatform.md, "Naming". A clash on `cylFoo` is solved by inserting the module name, `cyl` + module + original name (`cylBadgeFoo`, `cylAnimatedItemPlayer`, `cylTabBarPlayAll`; owner, 2026-11-28, N4), never by a suffix or a digit.

## Evidence

SonarCloud, PR #788 (2026-11-22): 956 open issues: `swift:S100` 743, `swift:S115` 146, `S1075` 18, `S116` 16, `S117` 11, `S101` 3. Rule formats: S100 and S115 `^[a-z][a-zA-Z0-9]*$`, S101 `^[A-Z][a-zA-Z0-9]*$`.

## Table (Swift, 2026-11-23)

| Symbol | Swift name | Objective-C name |
|---|---|---|
| Type | `CYLFoo` (no leading `_`) | same (`@objc(CYLFoo)`) |
| Member of our own type | `foo` | `@objc(cyl_foo:)` = the exact old selector, when Objective-C calls it |
| Member added in an extension | `cylFoo` | `@objc(cyl_foo:)` |
| Global function / constant | `cylFoo` | unchanged C name through `@_cdecl("CYLFoo")` |
| `@_cdecl` function | `cylFooEntryPoint` | `CYLFoo` |
| Enum case | lowerCamelCase, no backticks (`.standard`, not `` .`default` ``) | `NS_SWIFT_NAME` if needed |
| Test helper | lowerCamelCase, never an XCTest name (`assertAccuratelyEqual`, not `XCTAssertEqual`) | n/a |
| Unused parameter | `_` or `label _` (S1172) | n/a |
| Function with more than 7 parameters | group into a struct or options object (S107) | n/a |

## Names that stay (bucket d of docs/Swift-Coding-Style.md)

- An `open` member: a client subclass overrides it by name, a deprecated forward cannot redirect an override.
- A requirement of a public protocol apps implement (`CYLBadgeProtocol`, `CYLTabBarTheme`, `CYLTabButtonAnimation`,
  `UINavigationControllerExtensionDelegate`), and our witnesses of it. To add a Swift-style name, add a second method
  without the underscore (see "Swift-friendly names for underscored protocol methods" in `docs/instructions/code.md`).
- A released enum case (`.default`).
- Each one is listed with its reason in bucket d and accepted in the SonarCloud UI by the owner. Do not add to the list
  for new code: a new member is `open` only when subclassing it is intended, and a new protocol requirement uses the
  Swift name.

## Check before committing Swift

`grep -rnE '\b(func|var|let) cyl_|func CYL[A-Za-z]*\(' CYLTabBarController --include='*.swift' | grep -v Deprecated/`
prints only names listed in bucket d. Then diff the generated `CYLTabBarController-Swift.h`: selectors stay identical.

