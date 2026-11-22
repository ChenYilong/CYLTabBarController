---
name: cyl-naming
description: "How to name new code in CYLTabBarController after the SonarCloud re-evaluation (2026-11-22): CYL on types, no prefix on members of our own types, cylCamelCase (+ @objc(cyl_foo)) on members added to system types, cylFoo constants, Objective-C selectors unchanged, deprecated shims for released Swift names; per-language notes for Kotlin, Dart, ArkTS and TypeScript. Use before adding or renaming a public name."
---

# Naming after the static analysis (added 2026-11-22)

The same rule is in `AGENTS.md` ("Naming: keep the project's prefixes", sub-item "the prefix after the static analysis"). When they disagree, `AGENTS.md` wins; fix this file.

## Checklist

1. Type (class, struct, enum, protocol, typealias): `CYLFoo`.
2. Member of one of our types: no prefix.
3. Member added to a type we do not own (`UIViewController`, `UIView`, `UITabBarItem`, `NSObject`…): `cylFoo`; add `@objc(cyl_foo)` when Objective-C calls it, so the selector does not change.
4. Global constant or function: `cylFoo`, or a static member of a `CYL` type.
5. Renaming a released Swift name: keep the old one as `@available(*, deprecated, renamed: "cylFoo")`. Unreleased names need no shim.
6. Objective-C selectors, headers and Objective-C class names keep `cyl_` / `CYL`.
7. Kotlin, Dart, ArkTS, TypeScript: packages / libraries / modules namespace classes and extensions; keep the prefix only where the name is global (Android resources with `resourcePrefix`, platform channel and native module names, custom component tags, CSS classes, event names, storage keys).

## Evidence

SonarCloud, PR #788 (2026-11-22): 956 open issues: `swift:S100` 743, `swift:S115` 146, `S1075` 18, `S116` 16, `S117` 11, `S101` 3. Rule formats: S100 and S115 `^[a-z][a-zA-Z0-9]*$`, S101 `^[A-Z][a-zA-Z0-9]*$`.
