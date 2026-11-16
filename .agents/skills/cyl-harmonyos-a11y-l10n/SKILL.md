---
name: cyl-harmonyos-a11y-l10n
description: "Accessibility (screen readers, visual and blind assistance), internationalization / localization, and accessibility-first UI automation for the HarmonyOS port (CrossPlatform/harmonyos-cyltabbar). Use when adding or changing any HarmonyOS control or text, when copying translations from the iOS bundle, and when writing or running HarmonyOS UI tests."
---

# HarmonyOS accessibility, localization and UI tests

**Rule: all code of this project supports accessibility (screen readers and other visual / blind assistance) and
internationalization / localization, and the HarmonyOS code does too. If you find a control, a text or a page that
does not, add the support first. In automated UI tests, locate controls through these features first (accessibility
text / description and ids) to tap them, long press them, swipe, or run complex multi-step flows.**

## 1. Accessibility (ArkUI, API 12)

The port's compatibleSdkVersion is 5.0.0(12), so use only API 12 attributes:

| Need | ArkUI |
|---|---|
| One element for a control and its children | `.accessibilityGroup(true)` |
| What the screen reader says | `.accessibilityText(label)` |
| Role, position, state, subtitle | `.accessibilityDescription(text)` |
| Hide decorations | `.accessibilityLevel('no')` |

`accessibilitySelected` (API 13) and `accessibilityRole` (API 18) are above the minimum: put the selected state and the
role into the description text instead.

What the library already does (`cyltabbar`):
- Each tab: group + label "<title>, <badge>" (`cylAccessibilityLabel`) + description "Tab, n of m, Selected"
  (`cylAccessibilityDescription`). The cover image, Lottie canvas and badge are read through the tab.
- The plus button: group + label "<title or Plus button>, <badge>" + description "Selected" / "Double tap to open".
- Badges: `CYLBadgeView` has `accessibilityLevel('no')`; `cyl_badgeAccessibilityText(badge)` gives the text the host
  reads ("New content", "99+ new messages", "Badge: NEW").
- `CYLLottieIcon`, the touchable-area overlay: `accessibilityLevel('no')`, `hitTestBehavior(HitTestMode.Transparent)`
  (they never take the tab's taps).

The example (`entry`): each demo row is one group, label = title, description = subtitle and badge.

Checklist for new code: every interactive view has a label; no label repeats an icon file name; decorations are hidden;
state changes (selected, on / off) are in the description; texts are localized (section 2).

## 2. Localization

- Every user-visible text: `CYLLocalizedString('<key>', ...args)` (`%@`, `%1$@`, `%ld` placeholders), or
  `cyl_localizationKey('<key>')` for keys stored in data and looked up later.
- The key is the original text, the same key as iOS (`CYLLocalizedString(@"<original Chinese text>")`). Search the iOS
  table first and reuse its key:
  `CYLTabBarController/Resources/CYLTabBarController.bundle/en.lproj/CYLTabBarController.strings`.
- Texts only the HarmonyOS port has: add the key to `scripts/harmonyos-l10n.json` with at least `en` (and `zh-Hans`).
- Generate: `python3 scripts/harmonyos-l10n.py`. It copies **only the keys the HarmonyOS sources use** from every iOS
  `.lproj` (33 languages) into `cyltabbar/src/main/resources/<qualifier>/element/string.json`, writes
  `CYLLocalizationTable.ets` (key -> resource name) and the entry tab titles. `--check` fails when they are stale or a
  key has no English text. Never edit generated files by hand.
- Qualifiers: `en` -> `base`, `zh-Hans` -> `zh_CN`, `zh-Hant` -> `zh_TW`, `pt-BR` -> `pt_BR`, others as is.
- `EntryAbility.onCreate` calls `cyl_setLocalizationContext(this.context)`. The Language row switches with
  `i18n.System.setAppPreferredLanguage`.
- For accessibility labels of `$r(...)` titles use `cyl_textOf(resource)`.

## 3. UI automation, accessibility first

1. Locate by accessibility text / description or by id. Every control has an id:
   `cyl-tab-<identifier>`, `cyl-plus-button`, `cyl-tab-bar`, `cyl-badge`, `cyl-row-<page>-<rowId>`, `cyl-nav-skin-<page>`,
   `cyl-back`, `cyl-page-<identifier>`.
2. Act on the element: tap, long press (`longPressDuration`, 500 ms by default), double tap, swipe the page
   (`swipeToSwitchTabEnabled`), and chain steps for complex flows (open a row, act in the pushed page, go back, check
   the tab bar).
3. Assert through the same features (the label now says "Selected", the badge text changed, the row's description).
4. Use coordinates only when no element can be found, and file the missing label as a bug and fix it.

Tools: `hdc shell uitest` / `@ohos.UiTest` (`ON.text()`, `ON.id()`, `ON.description()`), DevEco Studio's UI
inspector; on Windows build with `scripts/harmonyos-build.sh`.

## Choosing the language in UI tests (added 2026-11-16)

The example accepts the launch parameter `CYLDemoLanguage` (a language tag such as `zh-Hant`, `de`, `ar`; empty follows the system), like the iOS demos' launch arguments. It calls `CYLSetLocalizationLanguage` before the page loads, so a test can check any of the 33 languages without changing the shared emulator's system language: `hdc shell aa start -b com.cyl.tabbar.harmony -a EntryAbility --ps CYLDemoLanguage zh-Hant`. The in-app language picker mirrors iOS (English, 简体中文, हिन्दी, Español, العربية, 跟随系统).

## Fix in the core first (added 2026-11-17)

Change the core code (the code published to CocoaPods, Swift Package Manager, Maven / Gradle, npm, pub.dev, ohpm or
the WeChat Mini Program component) so that the whole class of bug is avoided; a fix only in the example layer is the
worst option. If the core cannot fix it, ask the owner first and explain why; after the owner agrees, fix it in the
example and record the reason in `docs/Example-Layer-Fixes.md` (see AGENTS.md, "Code rules").

## Badge debugging on HarmonyOS (added 2026-11-17)

While checking badge positions on the emulator, set `CYL_BADGE_ANIMATION_DISABLED` to `true` in `buildProfileFields` of `cyltabbar/build-profile.json5`, rebuild, and take the screenshots and `uitest dumpLayout` dumps; set it back to `false` before committing. `CYLBadge.ets` reads it from the module's generated `BuildProfile.ets` (`import BuildProfile from '../../../BuildProfile'`; a HAR must import its own file by that relative path, the bare `'BuildProfile'` resolves to the app's). Full rule: AGENTS.md, "Code rules"; docs/Badge-Debugging.md.

Default: `CYL_BADGE_ANIMATION_DISABLED` is `false` (NO) in `cyltabbar/build-profile.json5`; set it to `true` (YES) only while debugging badge coordinates and alignment, never commit it as `true`. **Badge animation build controls default to NO (added 2026-11-17)**: every build control that turns badge animations off, including but not limited to the iOS Swift compilation condition `CYL_BADGE_ANIMATION_DISABLED`, the Android Gradle property `-PcylBadgeAnimationDisabled` (`BuildConfig.CYL_BADGE_ANIMATION_DISABLED`, also in the React Native and Flutter Android builds), the HarmonyOS `buildProfileFields` entry `CYL_BADGE_ANIMATION_DISABLED` in `cyltabbar/build-profile.json5`, the WeChat Mini Program constant `CYL_BADGE_ANIMATION_DISABLED` in `src/cyl-tab-bar/cyl_debug.js`, and any badge animation switch added later, defaults to NO (not set, `false`): badges animate as the app asks. Set one to YES (`true`) only while debugging badges: badge coordinates, offsets and alignment with the icon or other views. Set it on locally only; never commit, merge, release or publish it as YES (no Podfile, Xcode project, `gradle.properties`, CI setting or package with it on), and set it back to NO when the debugging is done, then check once more with animations on. Details: `docs/Badge-Debugging.md`.
