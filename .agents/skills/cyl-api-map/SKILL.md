---
name: cyl-api-map
description: "Map of CYLTabBarController features to the document that holds their API, limits and demo. Use to find the right API before writing tab bar code, instead of guessing or adding a new one."
---

# Feature to document

Read the document for the feature before using its API. The public API is in the headers under `CYLTabBarController/`; the entry header is `CYLTabBarController.h`. Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

| Feature | Document |
|:---|:---|
| Installing, Swift, `import` failures | [Swift-Guide](../../../docs/Swift-Guide.md) |
| SwiftUI | [SwiftUI-Integration](../../../docs/SwiftUI-Integration.md) |
| Carthage | [Carthage](../../../docs/Carthage.md) |
| Carthage demo | [Carthage-Example](../../../docs/Carthage-Example.md) |
| Every customization and its API | [Custom-Tab-Bar-Features](../../../docs/Custom-Tab-Bar-Features.md) |
| Small customizations (double tap, item styles) | [TabBar-Customization-Toolkit](../../../docs/TabBar-Customization-Toolkit.md) |
| Gallery of scenes, one per API | [Tab-Bar-Gallery](../../../docs/Tab-Bar-Gallery.md) |
| The demo settings list | [Demo-Test-List](../../../docs/Demo-Test-List.md) |
| FAQ | [FAQ](../../../docs/FAQ.md) |
| Usage guide (installation details, Objective-C setup, plus button protocol, appearance, badges, Dark Mode, localization, orientation, nested tab bars, Storyboard; moved from the README) | [Usage guide](../../../docs/Usage-Guide.md) |
| Highlights of earlier versions (1.99.x: iOS 27, iPhone Duo, runtime plus button) | [Version highlights](../../../docs/Version-Highlights.md) |
| Plus button rules | [PlusButton](../../../docs/PlusButton.md) |
| Plus button: slot, counts; on Liquid Glass it follows its slot's center; titles are cut (longest first) only when they overflow the platter | [PlusButton-Slot](../../../docs/PlusButton-Slot.md) |
| Swift migration of the iOS core layer: plan, order, score (`scripts/swift-migration-score.py`), progress | [Swift-Migration](../../../docs/Swift-Migration.md) |
| Every open TODO of `docs/`, grouped by what it needs (code, simulator, device, maintainer), and the sweep's progress | [TODO-Sweep](../../../docs/TODO-Sweep.md) |
| Swift coding style: names, `@objc` compatibility, comments, formatting | [Swift-Coding-Style](../../../docs/Swift-Coding-Style.md) |
| WeChat Mini Program: package `cyl-tabbar-miniprogram` (`CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-tab-bar`, pure mini program code, not a `CYLTabBarHostView` wrapper) reading the configuration keys, Lottie icons through its sub-dependency `cyl-lottie-miniprogram` (`CrossPlatform/lottie-miniprogram`: the `cyl-lottie` component and our fork of lottie-miniprogram with its 55 upstream issues), PAG icons through `cyl-pag-miniprogram` (libpag-lite, one-BMP-sequence PAG files only) and Rive icons through `cyl-rive-miniprogram` (`@rive-app/canvas-advanced` + WXWebAssembly; `.riv` copies named `*.riv.bin`, WASM copied out of `miniprogram_npm`), the `cyl-tab-bar-item` component (CYLFlatDesignTabBarItem API), events, methods, `cyl_swipe_behavior.js`, the example in `example/` with `npm run setup` (relative-path dependencies into `miniprogram_npm`), DevTools testing, scores (keys, API, issues) and TODO | [WeChat-Mini-Program](../../../docs/WeChat-Mini-Program.md) |
| Examples' pull to refresh and placeholders (CYLTableViewPlaceHolder: `CYLRefreshAnimationHeader`, empty / no-network placeholders), problems that library causes | [CYLTableViewPlaceHolder-Integration-Issues](../../../docs/CYLTableViewPlaceHolder-Integration-Issues.md) |
| Plus button: badge | [PlusButton-Badge](../../../docs/PlusButton-Badge.md) |
| Plus button: background image | [PlusButton-Background-Image-Liquid-Glass](../../../docs/PlusButton-Background-Image-Liquid-Glass.md) |
| Plus button: touchable area | [PlusButton-Touchable-Area](../../../docs/PlusButton-Touchable-Area.md) |
| Plus button: subview touches | [PlusButton-Subview-Touches](../../../docs/PlusButton-Subview-Touches.md) |
| Plus button with Lottie tab icons | [PlusButton-Lottie-TabIcon](../../../docs/PlusButton-Lottie-TabIcon.md) |
| `setSelectedIndex:` with a plus button | [SelectedIndex-PlusButton](../../../docs/SelectedIndex-PlusButton.md) |
| Update tabs without a rebuild ; navigation bar title that follows the tab title (`CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM`, `CYL_TAB_BAR_ITEM_TITLE`); tab change notifications with exact objects and identifier (`CYLTabBarItemTitleDidChangeNotification`, `CYLTabBarItemIconDidChangeNotification`, `CYLTabBarItemDidChangeNotification`, `CYLTabBarControllerThemeDidApplyNotification`); Android: `Fragment.cyl_navigationTitleFollowsTabBarItemTitle` (the activity title), `Fragment.cyl_tabBarItemTitle`, `CYLNotificationCenter` | [Update-Tab-Bar-Items-In-Place](../../../docs/Update-Tab-Bar-Items-In-Place.md) |
| One configuration file (JSON, YAML, plist, …, a URL) creates the tab bar; every key, file values, the error codes, the edge cases | [Configuration-File](../../../docs/Configuration-File.md) |
| React Native and Flutter components (`CrossPlatform/react-native-cyltabbar`, `CrossPlatform/flutter_cyltabbar`): how they work, `CYLTabBarHostView` (iOS and Android: only the bar of a configured controller, for any host or a native app drawing its own pages), `CYLTabBarControllerPlusButton` / `…PlusButtonAction`, host badges / long press / plus page / `touchableRects` (the transparent strip passes touches), `badgeAttributes` / `plusButtonBadgeAttributes` (value, color, animation, radius, center offset per badge), `tabCoverImages` (a cover over a selected tab, as `-setSelectedCoverShow:`), the iOS host forwarding the delegate methods it does not handle to the controller's own delegate, `CYLAnimationView` (PAG / Rive / Lottie in a page), the 4 animated-icon demos (`example-pag`, `example-rive`, `example_pag`, `example_rive`), limits | [Cross-Platform-Components](../../../docs/Cross-Platform-Components.md) |
| Plus button keys without a subclass (`CYLPlusButtonBackgroundImage`, `…IndexInTabBar`, `…CenterYMultiplier` / `…CenterYOffset`, `…AlignsTitle`, `…KeepsTitleVisible`, `…ShowsSelection`) and the top-level `CYLTabBarControllerUserInterfaceStyle` (iOS only), `…TabButtonTapAnimation`, `…SwipeToSwitchTab` | [Configuration-File](../../../docs/Configuration-File.md) |
| React Native: run the example, add `react-native-cyltabbar`, pod install, `<CYLTabBar>` props and events, image values, troubleshooting | [React-Native-Component](../../../docs/React-Native-Component.md) |
| Flutter: run the example, add `flutter_cyltabbar`, `FlutterFragmentActivity` on Android, Swift Package Manager (`path:` to this repository) or CocoaPods on iOS, `CYLTabBar` fields, troubleshooting | [Flutter-Component](../../../docs/Flutter-Component.md) |
| Localized texts of a configuration file: `CYLTabBarControllerLocalization` (`…TableName`, `…Path`, `…BundleName`), `.strings` tables in the app (never in the library), location routes `bundle:` / `sandbox:Documents|Caches|tmp/…` / `file:` / absolute / `~/` / relative, downloaded tables, React Native / Flutter | [Configuration-Localization](../../../docs/Configuration-Localization.md) |
| Configuration manifest (iOS + Android, RN / Flutter `manifestRoute`): `CYLTabBarManifest` / `CYLTabBarManifestLoader` after uni-app `tabBar` / `midButton` / `theme.json`, Expo Updates (`id`, `version`, `assets[]` with SHA-256, embedded fallback) and Firebase Remote Config (`conditions`, platform / app version / time); asset references `asset:<key>?state=&theme=` (version + theme + tab + state); fallback `previous` / `embedded` / `none` and delegate callbacks; key `CYLTabBarControllerManifestRoute`; sample in `Example-Shared/Configurations/Manifests` | [Configuration-Manifest](../../../docs/Configuration-Manifest.md) |
| Resource routes: one string for a built-in or sandbox resource (`CYLResourceRoute` in CYLUtils, Android `CYLResourceRoute.kt`), prefixes `bundle:` / `sandbox:` / `file:` / `/` / `~/` / relative, query `?name=&theme=&version=&format=` picking `{name}[-{theme}][@{version}].{format}`, `+configurationWithRoute:error:`, `+tabBarControllerWithConfigurationRoute:error:`, downloaded configurations; sample files live in `Example-Shared/Configurations/`, never in the library | [Resource-Routes](../../../docs/Resource-Routes.md) |
| Skins in a configuration file: `CYLTabBarControllerThemes` / `ThemeIdentifier` / `DarkThemeIdentifier` / `ThemeManagerName`, `"@name"` tab values, reserved bar names (`CYLTabBarBackgroundImage`, `CYLTabBarShadowImage`, `CYLTabBarStackedItemPositioning` / `Width` / `Spacing`, `CYLTabBarBackgroundColor`...), `CYLTabBarConfigurationTheme` (`colorNamed:`), iOS and Android | [Configuration-File](../../../docs/Configuration-File.md) |
| Scripts: export the tabs written in code to configuration files, the edge-case checklist, the parser tests | [Configuration-Scripts](../../../docs/Configuration-Scripts.md) |
| Tab pages from cross-platform page IDs: `CYLTabBarPageRegistry`, `CYLTabBarPage`, lookup order, reload, skipped tabs, asynchronous pages, Android | [Tab-Page-Registry](../../../docs/Tab-Page-Registry.md) |
| Review of the page registry against its design, scores and the refactoring done | [Tab-Page-Registry-Review](../../../docs/Tab-Page-Registry-Review.md) |
| Research: how a tab in a configuration finds its page object | [Tab-View-Controller-Resolution-Research](../../../docs/Tab-View-Controller-Resolution-Research.md) |
| Research: registering the plus button through configurations (proposal, not implemented) | [PlusButton-Registration-Research](../../../docs/PlusButton-Registration-Research.md) |
| CYLTabBarController for Android (`Example-Android/cyltabbar`, Kotlin and Java): usage, tap animations and transitions, Lottie / PAG / Rive by reflection, themes, badges, memory warnings, every configuration format, tests, limits | [Android-Library](../../../docs/Android-Library.md) |
| Android tab bar styles: classic, FlatDesign (translated from iOS `CYLFlatDesignTabBar`; `CYLFlatDesignTabBar` / `Button` / `Item` are aliases of `CYLTabBar` / `CYLTabBarItemButton` / `CYLTabBarItem`) and Liquid Glass (after Kyant's AndroidLiquidGlass `LiquidBottomTabs`: the floating dock and its selection bubble, Android 13+ / 12 / older), pages under a floating bar, the plus button on top in every style | [Android-Library](../../../docs/Android-Library.md) |
| Android Liquid Glass: how the dock is built (shadow, glass, surface tint, bubble, highlight), its values, and the Android-only surface tint `CYLTabBar.cyl_liquidGlassSurfaceOpacity` (0–1, default 0.4) / `cyl_liquidGlassSurfaceColor`, with the demo's live slider | [Android-Liquid-Glass](../../../docs/Android-Liquid-Glass.md) |
| Every iOS public symbol with its Android twin, status and the migration score (generated by `scripts/android-api-map.py`) | [Android-API-Map](../../../docs/Android-API-Map.md) |
| Every iOS public symbol with its comment and its HarmonyOS NEXT counterpart (TODO until implemented; Liquid Glass included), and the score (generated by `scripts/harmonyos-api-map.py`) | [HarmonyOS-API-Map](../../../docs/HarmonyOS-API-Map.md) |
| HarmonyOS port progress against iOS / Android, one TODO per missing feature, and the score (generated by `scripts/harmonyos-parity.py`) | [HarmonyOS-Parity](../../../docs/HarmonyOS-Parity.md) |
| Problems seen in HarmonyOS emulator screenshots, one row each with status and score, other repositories included (generated by `scripts/harmonyos-issues.py` from `scripts/harmonyos-issues.json`) | [HarmonyOS-Issues](../../../docs/HarmonyOS-Issues.md) |
| HarmonyOS Liquid Glass of the reference harmonyos-liquid-glass-tabbar, reproduced in the example only (entry demo/CYLGlassDock.ets, page pages/LiquidGlassDock; the library keeps the iOS style), scored; TODO: SDK 6.1.1 / API 24+ for the system material | [HarmonyOS-Liquid-Glass-Parity](../../../docs/HarmonyOS-Liquid-Glass-Parity.md) |
| Bugs fixed only in an example (allowed only with the owner's agreement): why the core could not fix each one | [Example-Layer-Fixes](../../../docs/Example-Layer-Fixes.md) |
| Badge debugging: the build option `CYL_BADGE_ANIMATION_DISABLED` (iOS Swift condition, Android `-PcylBadgeAnimationDisabled=true`, HarmonyOS `buildProfileFields`, Mini Program `cyl_debug.js`) turns badge animations off while checking badge positions | [Badge-Debugging](../../../docs/Badge-Debugging.md) |
| Screenshot rules: stitched images in one column, two columns when taller than one phone screen, header / caption / footer bands with platform, simulator, host OS, IDE version, commit, purpose and result, never over the screenshots; `scripts/stitch-screenshots.py` | [Screenshot-Guidelines](../../../docs/Screenshot-Guidelines.md) |
| Rive tab icon tinted like a template image: `CYLTabBarAnimationOptionTint` (`"tint"`: `"title"` follows the tab bar's selected / unselected tint, or `"#RRGGBB"`), iOS and Android; WeChat Mini Program: `tint` / `darkTint` in the route fragment or `CYLTabBarAnimationOptions`, item `animationTint`, cyl-rive `tint` | [Rive-Animation](../../../docs/Rive-Animation.md) |
| License notices in every published package (CocoaPods, SwiftPM, Carthage, Maven, npm, pub.dev, ohpm, mini program): where each package keeps the `LICENSE`, `scripts/check-license-notices.py` | [License-Notices](../../../docs/License-Notices.md) |
| The iOS Example's demo rows ported to the Android demo (`Example-Android/app`): what iOS shows, the Android implementation, status, score; scroll hiding restore on Android | [Android-Demo-Migration](../../../docs/Android-Demo-Migration.md) |
| The Android versions of Example-PAG, Example-GIF and Example-Rive (`Example-Android/example-*`), the shared `demokit` module (`DemoAssets` reads the iOS examples' asset catalogs, fonts and bundle: no copied resources), `CYLGIFDrawable` (a GIF image loops) | [Android-Examples](../../../docs/Android-Examples.md) |
| How the Android library compares with QMUI_Android's `QMUITabSegment` and `QMUISkinManager` (scores per dimension, gaps to close) | [Android-QMUI-Comparison](../../../docs/Android-QMUI-Comparison.md) |
| Android "More" past five view controllers (as UIKit; the plus page counts), and the Android-only `CYLTabBarController.cyl_showsAllTabs` / key `CYLTabBarControllerShowsAllTabs` to show every tab; `cyl_moreViewController`, `cyl_isMoreSelected`, `CYLTabBar.cyl_moreButton`, `cyl_visibleTabCount` | [Android-Library](../../../docs/Android-Library.md) |
| Android-only extensions adapted from QMUI_Android (off by default, no iOS twin): `CYLTabBar.cyl_indicator` (`CYLTabBarIndicator`), `cyl_scrollMode` (`CYLTabBarScrollMode`), `cyl_updateIndicatorPosition`, `cyl_itemWidthWeights`, `CYLTabBarController.cyl_swipesBetweenPages`, `cyl_setupWithViewPager2`; theme values `View.cyl_themeValue`, `CYLThemeValueBuilder`, `CYLThemeStyle`, `CYLThemeValues` (`installLayoutInflaterFactory`, `register`, `setRuleHandler`), `CYLThemeSpan`, `CYLThemeItemDecoration` | [Android-Library](../../../docs/Android-Library.md) |
| Publishing the Android library to Maven (Maven Local, Maven Central, GitHub Packages): `scripts/publish-android.sh`, coordinates `io.github.chenyilong:cyltabbarcontroller` / `cyltabbarcontroller-pages`, credentials, signing | [Android-Library](../../../docs/Android-Library.md) |
| Image-only tabs | [Image-Only-Tabs](../../../docs/Image-Only-Tabs.md) |
| Per-tab colors | [Tab-Item-Colors](../../../docs/Tab-Item-Colors.md) |
| Icon rendering mode: one image tinted per state, or original colors (`CYLTabBarItemIconRenderingMode`, `CYLTabBarControllerIconRenderingMode`, #787) | [Tab-Item-Colors](../../../docs/Tab-Item-Colors.md) |
| Tab positioning, width, spacing | [Tab-Item-Positioning](../../../docs/Tab-Item-Positioning.md) |
| A different title when selected | [TabBarItem-Selected-Title](../../../docs/TabBarItem-Selected-Title.md) |
| FlatDesign appearance | [FlatDesign-StandardAppearance](../../../docs/FlatDesign-StandardAppearance.md) |
| Tab gestures, double tap | [TabBarItem-Gestures](../../../docs/TabBarItem-Gestures.md) |
| Tap animations, haptics, interactions | [Tab-Interactions](../../../docs/Tab-Interactions.md) |
| Reselect: pop or scroll to top | [Tab-Reselect](../../../docs/Tab-Reselect.md) |
| A tab runs an action | [Tab-Custom-Action](../../../docs/Tab-Custom-Action.md) |
| Login-required tabs (also the config key, Android persistence, `CYLTabBarHostView` / React Native / Flutter `loggedIn`, `onLoginRequest`, `onLoginStateChange`) | [Login-Required-Tabs](../../../docs/Login-Required-Tabs.md) |
| Localization and language switch (`CYLLocalizedString`, `CYLSetLocalizationLanguage`, `-cyl_presentLanguagePicker`, right to left; Android `CYLLocalization.language`; `CYLTabBarHostView` / React Native / Flutter `language`) | [README, Localization](../../../docs/Usage-Guide.md#cn多语言本地化) |
| Example-level texts (not library API): `CYLDemoLocalizedString` (Objective-C macro; the Swift function is `cylDemoLocalizedString`) reading `Example-Shared/CYLDemo.bundle`; the library's own texts use `CYLLocalizedString`; a project needs both layers, checked by `scripts/check-localization-macros.py` | [AGENTS.md, Localization file structure](../../../AGENTS.md) |
| Hide or minimize on scroll | [TabBar-Minimize-On-Scroll](../../../docs/TabBar-Minimize-On-Scroll.md) |
| Push from anywhere | [Push-From-Anywhere](../../../docs/Push-From-Anywhere.md) |
| Accessibility identifiers, XCUITest | [Tab-Accessibility](../../../docs/Tab-Accessibility.md) |
| Hit testing | [TabBar-HitTest-Super-Fallback](../../../docs/TabBar-HitTest-Super-Fallback.md) |
| Adding animated tab icons: steps, notes, demos | [Tab-Icon-Animation-Quick-Start](../../../docs/Tab-Icon-Animation-Quick-Start.md) |
| Animation subspec, adding a library | [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md) |
| Several animation engines in one app: which are in, which are missing, conflicts (`+[CYLTabBarItemAnimatorRegistry registrationReport]`, `+registeredIdentifiers`, `+missingKnownIdentifiers`, DEBUG launch log, `CYLTabBarItemAnimatorRegistryDidChangeNotification`; Android `registrationReport()`) | [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md#enregistering-and-choosing-a-library) |
| An animated icon + title view to subclass, without the tab bar (tags, placeholders, chips): `CYLAnimatedItemView` (iOS: its own pod and module `CYLAnimatedItem`, `CYLAnimatedItem.podspec`, `import CYLAnimatedItem`, SwiftPM product `CYLAnimatedItem`, the FlatDesign tab button is a subclass, engines `CYLAnimatedItem/LottieSwift`…, no dependency on CYLTabBarController, a rule; only test code may depend on it; Android module `:cylanimateditem`, package `com.cyl.animateditem`; HarmonyOS module `cylanimateditem`; mini program component `cyl-animated-item`), protocols `CYLAnimatedItemContent`, `CYLAnimatedItemAnimating`, `CYLAnimatedItemViewDelegate` / `CYLAnimatedItemGestureListener`; static images by default; one Core-free engine subspec per type (`CYLAnimatedItemLottieSwift`, `…PAG`, `…Rive`, `…SVGA`, `…GIF`), so `CYLAnimatedItem` plus `CYLAnimatedItemLottieSwift` brings no tab bar; Core depends on `CYLAnimatedItem` (no engine), and the tab bar's `LottieSwift`/`PAG`… are Core plus the matching engine; the engine (subspec `CYLAnimationEngine`, Core-free) comes with any of them and is detected by `CYL_ANIMATION_ENGINE_AVAILABLE`, like `CYL_FLATDESIGN_AVAILABLE`; integration guide for other repositories | [Animated-Item](../../../docs/Animated-Item.md) |
| A centered vertical stack whose every element is an animated item (empty states, placeholders, onboarding cards): `CYLAnimatedItemStackView` (iOS: Swift with an Objective-C API, in `CYLAnimatedItem`, SwiftPM `import CYLAnimatedItemViews`; Android `com.cyl.animateditem.CYLAnimatedItemStackView`; HarmonyOS in `cylanimateditem` (the Win HarmonyOS session); mini program component `cyl-animated-item-stack` with an `items` array and an `action` event); reserved first item, an action name per item, `backgroundAction`, lookup by action, titles wrapped to the width; the generic form of CYLTableViewPlaceHolder's `CYLPlaceholderStackView`. `CYLAnimatedItemView` is Swift on iOS since 2026-11-19 (Objective-C cannot subclass it) | [Animated-Item](../../../docs/Animated-Item.md) |
| PAG | [PAG-Animation](../../../docs/PAG-Animation.md) |
| Rive | [Rive-Animation](../../../docs/Rive-Animation.md) |
| SVGA (issue #415): `pod 'CYLTabBarController/SVGA'`, `CYLTabBarSVGAURL` keys, player SVGAPlayerLite (maintained SVGAPlayer fork, Protobuf 3.27), demo in Example-Rive after the Rive demo | [SVGA-Animation](../../../docs/SVGA-Animation.md) |
| GIF: looping image or play once | [GIF-Animation](../../../docs/GIF-Animation.md) |
| Mixing animated and static tabs | [Per-Tab-Animation](../../../docs/Per-Tab-Animation.md) |
| Themes | [Theme-Switching](../../../docs/Theme-Switching.md) |
| Theme evaluation | [Theme-Switching-Evaluation](../../../docs/Theme-Switching-Evaluation.md) |
| Theme evaluation against QMUI | [Theme-Switching-QMUI-Evaluation](../../../docs/Theme-Switching-QMUI-Evaluation.md) |
| Plus child theme test | [Plus-Child-Theme-Switching-Test](../../../docs/Plus-Child-Theme-Switching-Test.md) |
| Helpers in CYLUtils | [CYLUtils-Helpers](../../../docs/CYLUtils-Helpers.md) |
| Liquid Glass robustness | [Liquid-Glass-Robustness](../../../docs/Liquid-Glass-Robustness.md) |
| CI and releases | [Mac-CI-CD](../../../docs/Mac-CI-CD.md) |
| Bilingual documents | [Bilingual-Documentation](../../../docs/Bilingual-Documentation.md) |
| Agent skills in this repository | [Agent-Skills](../../../docs/Agent-Skills.md) |
| Documentation folder rules | [instructions](../../../docs/instructions.md) |
| Commit readiness and pre-commit TODO tracking | [Commit-Readiness-2026-11-09](../../../docs/commit-readiness-2026-11-09.md) |

`python3 scripts/sync-agent-skills.py --check` fails when a document in `docs/` is missing here. A new document gets a row in the same change.

## Styles

`tabBarStyleType`: `CYLTabBarStyleTypeDefault`, `CYLTabBarStyleTypeSystem`, `CYLTabBarStyleTypeFlatDesign`, `CYLTabBarStyleTypeLiquidGlass`. See `cyl-xcode-compat` for which system shows what.

## Swift first on iOS (added 2026-11-19)

- **The iOS core is Swift; every new piece of code is Swift first (added 2026-11-19, owner)**: the core code of this project on iOS (the CocoaPods / Swift Package Manager / Carthage sources under `CYLTabBarController/`, including the `CYLAnimatedItem` module) is Swift. Write every new class, extension, test and example in Swift. Use Objective-C only where Swift cannot do the job (a header that must stay importable from Objective-C without modules, a `+load`-time hook, a C macro), and give the reason in a comment and in the task's document in `docs/`. Keep the public API usable from Objective-C (`@objc`, `@objcMembers`, `NS_SWIFT_NAME` counterparts) so existing Objective-C callers keep working. When you touch Objective-C code for a new feature, prefer adding the feature in a Swift file over growing the Objective-C file. Migration log: `docs/Swift-Migration.md`. Details: `AGENTS.md`, "Code rules".
