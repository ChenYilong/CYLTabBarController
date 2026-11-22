# Accessibility and localization (tag: `accessibility-localization`)

Full text of the `accessibility-localization` rules. [AGENTS.md](../../AGENTS.md#accessibility-and-localization-tag-accessibility-localization) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

- **Accessibility is required everywhere.** The library code shipped to CocoaPods / SPM and to Gradle / Maven, the
  React Native and Flutter components, and every example fully support accessibility (VoiceOver, TalkBack, Voice
  Control, Switch Control, Dynamic Type where the platform has it). This applies to new code, to code you change, and to
  existing code you review: fix what is missing when you meet it.
  - Every control and every piece of text is an accessibility element with a meaningful label (and value, trait / role,
    state such as selected or on/off, and hint when useful): tabs, the plus button, badges (read as part of their host,
    e.g. "Messages, 99+ new"), covers and decorations (hidden from accessibility, the tab reads instead), list rows
    (title and subtitle in one element), switches, sliders and buttons inside rows, menus and their items.
  - Hide purely decorative views from accessibility; never leave an interactive view without a label.
  - React Native: `accessible`, `accessibilityRole`, `accessibilityLabel`, `accessibilityState` /
    `accessibilityValue`. Flutter: `Semantics` (or the widgets' `semanticLabel`), `ExcludeSemantics` for decorations.
    Android: `contentDescription`, `importantForAccessibility`, `stateDescription`. iOS: `accessibilityLabel`,
    `accessibilityTraits`, `accessibilityValue`, `accessibilityElementsHidden`.
    HarmonyOS (ArkUI, API 12): `accessibilityGroup(true)` + `accessibilityText` + `accessibilityDescription` on each
    control, `accessibilityLevel('no')` for decorations; the selected state and role go into the description text
    (`accessibilitySelected` is API 13 and `accessibilityRole` API 18, above the port's compatibleSdkVersion).
  - Automated tests and simulator / emulator checks drive the UI through accessibility first: find elements by their
    accessibility label or identifier (XCUITest queries, `axe describe-ui`, `uiautomator`, Flutter `find.bySemanticsLabel`,
    React Native `getByLabelText`), and fall back to coordinates only when no element can be found, then file the
    missing label as a bug and fix it.
  - The convention: every component and every text of this project supports accessibility. A change that adds a control
    or a text without it is not done.
- **Accessibility and localization in all code, HarmonyOS included (2026-11-16).** All code of this project supports
  accessibility (screen readers such as VoiceOver, TalkBack and the HarmonyOS screen reader; visual aids such as large
  text, bold text, high contrast and color inversion) and internationalization / localization through localization
  files, including the HarmonyOS NEXT (ArkTS / ArkUI) code. Where support is missing, add it first, then continue.
  - HarmonyOS: every control has `accessibilityText` (localized), `accessibilityDescription` when a hint helps,
    `accessibilityGroup(true)` for a control made of several views, `accessibilityLevel('no')` for decorations, a
    stable `id` (`key`) for tests and the selected state in its text; all texts come from string resources
    (`$r('app.string.…')`, `resources/<locale>/element/string.json`) copied from CYLTabBarController's localization
    files (`CYLTabBarController/Resources/CYLTabBarController.bundle/*.lproj`), keeping only the strings the HarmonyOS
    code uses. Code: `CrossPlatform/harmonyos-cyltabbar`. Skill: `cyl-harmonyos-a11y-l10n`.
  - Automated UI tests use these features first to locate controls: accessibility identifiers (`id` / `key`,
    `accessibilityIdentifier`, `testID`), accessibility labels / texts and localized strings (HarmonyOS UiTest `ON.id()` /
    `ON.text()`, XCUITest queries, `axe describe-ui`, `uiautomator`, Flutter `find.bySemanticsLabel`, React Native
    `getByLabelText`), to tap, to drive complex flows and consecutive steps. Coordinates are the last resort; a control
    that cannot be found that way is a bug to fix.
- **No Chinese text in code**: every string literal that contains Chinese, including log, assert and debug messages,
  goes through `CYLLocalizedString(@"<original Chinese text>")` (Swift: `CYLLocalizedString("...")`), with
  `[NSString stringWithFormat:]` / `String(format:)` for values. `CYLLocalizedString()` is declared with
  `NS_FORMAT_ARGUMENT(1)`, so keep placeholders and arguments in step. The only exceptions are resource identifiers
  (e.g. an image asset name) and constants that are documented as localization keys; never touch Xcode project
  files, plists or storyboards for this.
- **Localization (i18n / l10n) file structure.** Localized texts are always many files, one per language: they are
  never left as loose `.lproj` folders in a target or folder, but grouped and reached through one entry point.
  - **iOS: one `.bundle` per owner.** Put all the `.lproj` folders of a set of tables into one `.bundle`
    (`<Name>.bundle/<language>.lproj/<Table>.strings`). Several bundles are fine, one per owner or purpose.
  - **The core bundle is permanent.** `CYLTabBarController/Resources/CYLTabBarController.bundle` (table
    `CYLTabBarController`) ships with the library: always keep it, with its name, path and table name, and update it
    carefully. It holds the library's own texts only. Every key goes into **all** its `.lproj` folders with the same
    `%@` / `%1$@` specifiers, so every table has the same keys; never rename or remove a key that released code reads;
    check for duplicate keys with `LC_ALL=C sort`.
  - **Examples have their own bundle, at the example level.** Texts that only an example shows go into a bundle that
    belongs to the example (in its own folder, or in `Example-Shared/` when several examples share it), not into the
    core bundle. Xcode's `Base.lproj` for storyboards and launch screens stays where Xcode puts it.
  - **Always a macro per bundle.** Each bundle gets one macro (and a Swift function named in Swift style, lowerCamelCase: `cylDemoLocalizedString` for
    `CYLDemoLocalizedString`, as SonarCloud rule swift:S100 requires) that maps a key to
    its bundle and table, so callers never spell the bundle out: the core one is `CYLLocalizedString(@"…")`; an
    example's is, for instance, `CYLDemoLocalizedString(@"…")` over `NSLocalizedStringFromTableInBundle`. Declare it
    with `NS_FORMAT_ARGUMENT(1)` and `CYL_RETURNS_LOCALIZED_STRING`, like the core one.
  - **Acceptance criterion: at least two different macros, one per layer.** A project passes only when it has at least
    two different macros (and their Swift-style Swift functions) that read the localized files of two different
    layers: (1) a **core** macro that reads the localized files inside the library's own bundle; (2) an **example**
    macro that reads the localized files at the example level. On iOS these are `CYLLocalizedString` →
    `CYLTabBarController.bundle` and `CYLDemoLocalizedString` → `Example-Shared/CYLDemo.bundle`. Other platforms use a
    different package form, name and folder name (Android `res/values*/` per module, a table file per example for React
    Native and Flutter), but each layer is still a folder or package of per-language files reached through its own
    macro or helper. It fails when one macro reads both layers, when an example reads the core bundle through
    `NSLocalizedString` or `NSBundle` calls of its own, when an example's texts sit in the core bundle, or when
    loose `.lproj` folders are left in a target. An example project that compiles a file calling the example macro
    must also compile the macro's source (`CYLDemoLocalization.m` / `.swift`) and ship `CYLDemo.bundle`. Run
    `python3 scripts/check-localization-macros.py` for the iOS side; it exits 1 and names each failure.
  - **Other platforms, the same way.** Android: the library's strings in the library module's `res/values*/` (the core
    tables: kept, updated carefully, generated from the iOS tables by `scripts/android-library-strings.py`), an
    example's strings in its own module's `res/values*/`, each reached through one helper (`CYLLocalization.string` for
    the library, an example helper for an example). React Native and Flutter: one table file per example
    (`strings.json`, generated by `scripts/sync-example-shared.py`) behind one function (`t()`).
  - Gaps against this rule are listed under TODO in [docs/Configuration-Localization.md](docs/Configuration-Localization.md).
