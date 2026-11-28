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
- **Protocols hold requirements only; edits are anchored uniquely (added 2026-11-23, the `CYLAnimatedItemAnimating` break)**:
  a Swift protocol lists requirements and nothing else: no function body, no stored property. Implementations go in the
  class (or, for a Swift-only protocol, in a protocol extension; an `@objc` protocol cannot get Objective-C-visible
  defaults from an extension). What happened: `pauseAnimation()` / `resumeAnimation()` were pasted with their bodies inside
  `@objc public protocol CYLAnimatedItemAnimating` (commit `cc74a545`, still in `e0d5e960`), because the anchor text
  `func playAnimation()` occurs in the protocol *and* in the class and the paste landed at the first match. Swift rejects
  that, and every integrator that pinned the branch (CYLTableViewPlaceHolder) failed to compile before any CI had run on
  the commit. Rules:
  (1) **Released protocols**: `CYLAnimatedItemAnimating` and every other public protocol is released API; a new *required*
  member breaks external conformers, so a new member of an `@objc` protocol is `@objc optional` (called as `x.method?()`),
  or the method lives only on the class when every caller holds the class.
  (2) **Anchors**: when a script or an edit inserts code, the anchor text includes the declaration keyword and the opening
  brace (`open func playAnimation() {`, not `func playAnimation()`), is asserted to occur exactly once, and the insertion
  point is the *end* of a declaration (never right after an opening brace). A search must also be scoped: the end marker of
  a block is searched from the start marker, not from the top of the file.
  (3) **Afterwards, check the enclosing declaration** of what was inserted (`sed -n '/protocol Name/,/^}/p'`), and compare
  the protocol's member list with its version before the change.
  (4) **Run `python3 scripts/check-swift-protocol-bodies.py CYLTabBarController`** before pushing Swift written without a
  compiler: it fails on a protocol that contains a function body or a stored property (it found the two bodies above and
  reports 0 after the fix). It is a heuristic, not a compile: say in the commit that the code was not compiled.
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
  - **The prefix exists to stop silent overriding (amended 2026-11-27, owner decisions N0-N3,
    [docs/Animated-Item-Badge-CrossPlatform.md](../Animated-Item-Badge-CrossPlatform.md#ennaming-where-a-cyl-prefix-is-needed-reassessed-per-platform)).**
    Why iOS uses `cyl_`: Objective-C categories have no namespace. A category method silently overrides, or is
    overridden by, a method with the same name that the integrating app, the system or another library has on that
    class, so someone else's implementation is replaced. The `cyl_` prefix makes such a clash impossible. On every other
    platform, reassess whether the language already prevents this, and keep a prefix only where it does not. The
    spelling always follows the language:
    - Objective-C selectors of category methods and properties (also `@objc` members added in Swift extensions):
      `cyl_` is required (`-cyl_showBadgeValue:`); the Swift name is `cylFoo` (see the SonarCloud bullet below).
    - Kotlin, Dart and TypeScript extensions: **`cyl_` is not required.** Extensions are resolved at compile time and
      never override a member. On a platform type (`View`, `TextView`, `MenuItem`, Flutter classes) use `cylFoo`, with
      no underscore, because a member the platform adds later silently wins over the extension; on our own types, no
      prefix.
    - Public methods of a WeChat Mini Program component instance: keep a prefix, spelled `cylFoo` (they share the
      instance namespace with the framework's own methods and behaviours, so a same-named method silently shadows
      them). **When `cylFoo` is already taken (owner, 2026-11-28, N4): `cyl` + module name + the original method name**,
      so the module name is inserted and the clash goes away: `cylBadgeFoo`, `cylAnimatedItemPlayer`,
      `cylTabBarPlayAll`. The module is the component or library that owns the method (`Badge`, `AnimatedItem`,
      `TabBar`, `Lottie`). Apply the same style on any platform where a prefixed name clashes, and never add a suffix
      or a digit to dodge a clash.
    - No prefix: members of our own types on every platform, ArkTS APIs (ArkTS cannot extend system components or
      prototypes), TypeScript / React Native props and ES module members, Dart library members. Global names keep a
      prefix (Android resources, channel and native module names, component tags, CSS classes, event names, storage
      keys).
    - **Release status (owner, 2026-11-27): only iOS is released; Android, HarmonyOS, the WeChat Mini Program, React
      Native and Flutter are not released yet.** iOS names keep their spelling (public API rule). On the other
      platforms, existing names that break this rule (for example Android `View.cyl_*`, HarmonyOS `CYLBadge.cyl_*`,
      mini program `cyl_*` component methods) are renamed directly, with no aliases and no deprecated forwards. Once a
      platform is released, the public API rule applies to it too.
  - Remove any other prefix the copied code carries (another project's or author's prefix, `XX`, `My`, `QMUI`, `JX`…)
    and rename its symbols, files and references accordingly; keep a credit to the source in a comment instead.
  - Keep the names of public APIs that already shipped, as the Public API rule requires; this rule is for new code.
  - **Swift names follow SonarCloud (added 2026-11-23, owner; swift:S100 / S101 / S115 / S116 / S117 and the Swift
    API Design Guidelines).** The `cyl_` rule above is for Objective-C selectors (and the reasons above for other languages). In Swift:
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
