# Accessibility and Internationalization [`accessibility-i18n`]

## Accessibility is required everywhere

The library code shipped to CocoaPods / SPM and to Gradle / Maven, the React Native and Flutter components, and every example fully support accessibility (VoiceOver, TalkBack, Voice Control, Switch Control, Dynamic Type where the platform supports it). This applies to new code, to code you change, and to existing code you review: fix what is missing when you encounter it.

- **Every control and every piece of text is an accessibility element** with a meaningful label (and value, trait/role, state such as selected or on/off, and hint when useful): tabs, the plus button, badges (read as part of their host, for example "Messages, 99+ new"), covers and decorations (hidden from accessibility; the tab reads instead), list rows (title and subtitle in one element), switches, sliders, and buttons inside rows, menus, and their items.
- **Hide purely decorative views** from accessibility; never leave an interactive view without a label.
- **Platform guidance**:
  - React Native: `accessible`, `accessibilityRole`, `accessibilityLabel`, `accessibilityState` / `accessibilityValue`.
  - Flutter: `Semantics` (or the widget's `semanticLabel`), `ExcludeSemantics` for decorations.
  - Android: `contentDescription`, `importantForAccessibility`, `stateDescription`.
  - iOS: `accessibilityLabel`, `accessibilityTraits`, `accessibilityValue`, `accessibilityElementsHidden`.
  - HarmonyOS (ArkUI, API 12): `accessibilityGroup(true)` + `accessibilityText` + `accessibilityDescription` on each control, `accessibilityLevel('no')` for decorations; the selected state and role go into the description text (`accessibilitySelected` is API 13 and `accessibilityRole` is API 18, above the port's `compatibleSdkVersion`).
- **Automated tests and simulator/emulator checks drive the UI through accessibility first**: find elements by their accessibility label or identifier (XCUITest queries, `axe describe-ui`, `uiautomator`, Flutter `find.bySemanticsLabel`, React Native `getByLabelText`), and fall back to coordinates only when no element can be found, then file the missing label as a bug and fix it.
- **Convention**: every component and every text in this project supports accessibility. A change that adds a control or text without accessibility support is not done.

## Accessibility and localization in all code, including HarmonyOS (added 2026-11-16)

All code in this project supports accessibility (screen readers such as VoiceOver, TalkBack, and the HarmonyOS screen reader; visual aids such as large text, bold text, high contrast, and color inversion) and internationalization/localization through localization files, including the HarmonyOS NEXT (ArkTS / ArkUI) code. Where support is missing, add it first, then continue.

- **HarmonyOS**: every control has `accessibilityText` (localized), `accessibilityDescription` when a hint helps, `accessibilityGroup(true)` for a control made of several views, `accessibilityLevel('no')` for decorations, a stable `id` (`key`) for tests, and the selected state in its text; all texts come from string resources (`$r('app.string.…')`, `resources/<locale>/element/string.json`) copied from CYLTabBarController's localization files (`CYLTabBarController/Resources/CYLTabBarController.bundle/*.lproj`), keeping only the strings the HarmonyOS code uses. Code: `CrossPlatform/harmonyos-cyltabbar`. Skill: `cyl-harmonyos-a11y-l10n`.
- **Automated UI tests use these features first to locate controls**: accessibility identifiers (`id` / `key`, `accessibilityIdentifier`, `testID`), accessibility labels/texts, and localized strings (HarmonyOS UiTest `ON.id()` / `ON.text()`, XCUITest queries, `axe describe-ui`, `uiautomator`, Flutter `find.bySemanticsLabel`, React Native `getByLabelText`), to tap, drive complex flows, and consecutive steps. Coordinates are the last resort; a control that cannot be found that way is a bug to fix.
