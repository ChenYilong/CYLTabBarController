# Code rules (tag: `code`)

Full text of the `code` rules. [AGENTS.md](../../AGENTS.md#code-rules-tag-code) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

## Code rules

- **The iOS core is Swift; every new piece of code is Swift first (added 2026-11-19, owner)**: the core code of this project on iOS (the CocoaPods / Swift Package Manager / Carthage sources under `CYLTabBarController/`, including the `CYLAnimatedItem` module) is Swift. Write every new class, extension, test and example in Swift. Use Objective-C only where Swift cannot do the job (a header that must stay importable from Objective-C without modules, a `+load`-time hook, a C macro), and give the reason in a comment and in the task's document in `docs/`. Keep the public API usable from Objective-C (`@objc`, `@objcMembers`, `NS_SWIFT_NAME` counterparts) so existing Objective-C callers keep working. When you touch Objective-C code for a new feature, prefer adding the feature in a Swift file over growing the Objective-C file. Migration log: `docs/Swift-Migration.md`.
- **Fix bugs in the core, not in the example (added 2026-11-17)**: when you fix an issue or a bug, change the core code
  first so that the whole class of problem is avoided for every app, not only the example. The core is the code
  published to a package manager: CocoaPods (the podspec's sources), Swift Package Manager, Maven / Gradle
  (`Example-Android/cyltabbar`), npm (`CrossPlatform/react-native-cyltabbar` outside `example*`), pub.dev
  (`CrossPlatform/flutter_cyltabbar` outside `example*`), ohpm (`CrossPlatform/harmonyos-cyltabbar/cyltabbar`) and the
  WeChat Mini Program component (outside `example`). Fixing only the example layer is the worst option. If the bug
  cannot be fixed in the core, stop and ask the owner first, giving the reason; only after the owner agrees, fix it in
  the example and record in `docs/Example-Layer-Fixes.md` why the core could not fix it (the issue, the reason, the
  example change, and what would let the core fix it later).
  **Order for every bug (added 2026-11-17)**: (1) record it first (the platform's issue list, e.g.
  `docs/HarmonyOS-Issues.md`, or the component's guide, e.g. the bug table in `docs/Animated-Item.md`) with what was
  seen and how to reproduce it; (2) capture a screenshot (simulator / emulator / DevTools) before fixing, or say why
  there is none (a unit-test-only failure: quote the test output instead); (3) fix it in this repository's components
  (for animation bugs, the CYLAnimatedItem component and its engines on each platform), not in an example. When an
  example has to change, add or change an API in the library first and make the example only call it.
- **No warnings**: fix every build and static-analyzer warning you meet, including old ones in code you did not change.
- **Public API**: never remove or change an existing public API; add new API instead. Prefer implementing an existing
  protocol method over adding a new category method; file-private C functions and private headers are fine.
- **Swift-friendly names for underscored protocol methods**: Swift method names must not contain underscores, but a
  Swift class that implements an Objective-C protocol method must use its imported name (e.g. `cyl_play…`); renaming it
  no longer satisfies the protocol. Adding `NS_SWIFT_NAME` to the existing method would change a Swift API already
  released on `master`, which the Public API rule forbids. Instead, add a new method with the same name minus the
  underscore, keeping the `cyl` prefix (e.g. `-cyl_playSelectAnimationWithTabButton:…` →
  `-cylPlaySelectAnimationWithTabButton:…`), and define its Swift name with `NS_SWIFT_NAME` on the new method only.
  Both spellings run the same logic: the library calls the underscore-free one when it is implemented, otherwise the
  underscored one. If the old method was `@required`, make it `@optional` so a class can implement only the new one.
- **Naming: keep the project's prefixes.** Every class, protocol, type and function of this project starts with `CYL`,
  and every category method and category property starts with `cyl_`. A file you create or bring in (copied from
  another project, a sample, a snippet) follows the same rules:
  - Name new classes, structs, enums, protocols, file-private C functions and constants with the `CYL` prefix
    (`CYLBadgeView`, `CYLDemoTheme`), and the file after its main type (`CYLBadgeView.m`, `UIView+CYLBadgeExtention.m`).
  - Name every method and property added in a category with the `cyl_` prefix (`-cyl_showBadgeValue:`), also in
    extensions of system types written in Swift, Kotlin, Dart or TypeScript in this repository.
  - Remove any other prefix the copied code carries (another project's or author's prefix, `XX`, `My`, `QMUI`, `JX`…)
    and rename its symbols, files and references accordingly; keep a credit to the source in a comment instead.
  - Keep the names of public APIs that already shipped, as the Public API rule requires; this rule is for new code.
  - **Swift names follow SonarCloud (added 2026-11-23, owner; swift:S100 / S101 / S115 / S116 / S117 and the Swift
    API Design Guidelines).** The `cyl_` rule above is for Objective-C selectors and for non-Swift languages. In Swift:
    types keep `CYL` (`CYLFoo`, no leading underscore); a member of our own type has no prefix (`reloadTabButtons`);
    a member added to a system type or to one of our types in an extension is `cylFoo` (add `@objc(cyl_foo)` when
    Objective-C calls it, so the selector stays); a global function or constant is `cylFoo`; a test helper is
    lowerCamelCase and never shares an XCTest name; the Swift name of an `@_cdecl("CYLFoo")` function is
    `cylFooEntryPoint`. Never write `func cyl_foo`, `var cyl_foo`, `let CYLFoo` or `func CYLFoo` in a new Swift file.
    A name that must stay (an `open` member a client may override, a requirement of a public protocol that apps
    implement, a released `.default`) is listed in docs/Swift-Coding-Style.md, bucket d, with its reason. Renaming a
    released Swift name needs a deprecated forward under a `Deprecated/` folder (excluded in `.sonarcloud.properties`).
    Details and the check: skill `cyl-naming`.
  - Sample apps follow it too: React Native and Flutter components, helpers and assets of the examples use `CYL`
    (`CYLBadgeView`, `cyl_badge_sample_icon`), unless the platform's own naming forbids it (e.g. Dart file names are
    snake_case: `cyl_badge_view.dart`).
- **Comments on public API: one documentation block format, for one line or many.** A caller reads a public API's
  comment through the IDE's documentation (Xcode Quick Help, the generated Swift interface, Android Studio, editor
  hovers), and only a documentation comment gets there whole. **The official documentation rules of each language are
  the reference**; within them:
  - **One-line comments use the block format too.** A one-line comment on public API is written like a multi-line one:
    three lines above the declaration (`/*!`, ` * text`, ` */` in Objective-C). Never `/*! text */` on one line, and
    never a trailing comment after a declaration or an enum case (`/**< */`, `/*!< */`, `///<`, `//`).
  - **One format per public file**, for short and long comments alike.
  - **Every platform and language**, each in its documentation tool's block form:
    - Objective-C public headers: `/*! … */` (HeaderDoc; Xcode shows it to Objective-C callers and in the Swift interface
      generated from the header).
    - Swift: `/** … */` (Swift Markup; Swift does not read `/*!` as documentation).
    - Kotlin, Java, TypeScript, JavaScript: `/** … */` (KDoc, Javadoc, TSDoc / JSDoc).
    - Python: a triple-quoted docstring on its own lines.
    - Go: `/* … */`; C#: `/** … */` with XML tags; Rust: `/** … */`.
    - A language without a block form uses its only documentation comment form in the whole file.
    - Where a language's official rule names one form, that rule wins: Dart keeps `///` (Effective Dart requires it for
      doc comments), and the official guides of Go (`//`), C# and Rust (`///`) prefer line comments; follow them in those
      languages.
  Check with `python3 scripts/check-public-api-comments.py` (iOS public headers, the Android library modules, the React
  Native sources, the Flutter sources); `--fix` rewrites one-line blocks into three lines, `//` / `///` comments in
  Objective-C headers into `/*! … */` blocks, and moves trailing comments above the declaration (merged into its existing
  block when it has one, since a second block would hide the first).
- **Comments are bilingual**: write `[EN]` / `[CN]` blocks; mark fixes with `FIX: issue #N`. A comment written in
  Chinese is tagged `[CN]` and is followed directly by its English translation tagged `[EN]`, in the same comment style
  (inside the same block comment on public API; `//` lines elsewhere). Comments that only
  contain a person's name, and commented-out code, need no translation.
- **License notice in every published package (added 2026-11-17)**: all code published to an outside registry
  (including but not limited to CocoaPods, Swift Package Manager, Carthage, Maven / Gradle, npm, pub.dev, ohpm and the
  WeChat Mini Program npm package) must ship the license notice (the root `LICENSE`) inside the package. When the
  package has a built-in resource folder, put the license there: on iOS the package's resource `.bundle` contains the
  license file (`CYLTabBarController.bundle/LICENSE`, `CYLAnimatedItem.bundle/LICENSE`); on Android the library's Java
  resources (`src/main/resources/META-INF/<module>/LICENSE`); for the mini program the component folder (`src/LICENSE`).
  When it has none, create one, or put the license at the package root where the registry publishes it (npm, pub.dev,
  ohpm). This applies to every platform. A new published package gets its license file, a row in
  [docs/License-Notices.md](docs/License-Notices.md) and an entry in `scripts/check-license-notices.py` in the same change;
  run `python3 scripts/check-license-notices.py` before pushing.
- **Swift for the iOS core layer (added 2026-11-12)**: the core layer (`Core`, `CYLUtils`, `CYLBadgeView` subspecs) is being translated from Objective-C to Swift, bottom-up, keeping every Objective-C name (`@objc(name)`); third-party adapters and the examples stay unless a change is needed. Follow [docs/Swift-Coding-Style.md](docs/Swift-Coding-Style.md); record each step and the score of `python3 scripts/swift-migration-score.py` in [docs/Swift-Migration.md](docs/Swift-Migration.md) and in the commit body; continue until the score is 100 (no Objective-C left; macro-only headers count as compatible). **Examples bend, the core does not (added 2026-11-13)**: when the migration breaks an example's build, fix the example first; examples have the lowest priority and their code may change freely. Never keep a workaround, overload, kept name or shim in the core only because an example uses it; the Swift coding style decides. The public API rule and kept Objective-C selectors still apply, for apps. Details: [docs/Swift-Coding-Style.md](docs/Swift-Coding-Style.md).
