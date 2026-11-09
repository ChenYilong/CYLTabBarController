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
| Plus button rules | [PlusButton](../../../docs/PlusButton.md) |
| Plus button: slot, counts | [PlusButton-Slot](../../../docs/PlusButton-Slot.md) |
| Plus button: badge | [PlusButton-Badge](../../../docs/PlusButton-Badge.md) |
| Plus button: background image | [PlusButton-Background-Image-Liquid-Glass](../../../docs/PlusButton-Background-Image-Liquid-Glass.md) |
| Plus button: touchable area | [PlusButton-Touchable-Area](../../../docs/PlusButton-Touchable-Area.md) |
| Plus button: subview touches | [PlusButton-Subview-Touches](../../../docs/PlusButton-Subview-Touches.md) |
| Plus button with Lottie tab icons | [PlusButton-Lottie-TabIcon](../../../docs/PlusButton-Lottie-TabIcon.md) |
| `setSelectedIndex:` with a plus button | [SelectedIndex-PlusButton](../../../docs/SelectedIndex-PlusButton.md) |
| Update tabs without a rebuild ; navigation bar title that follows the tab title (`CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM`, `CYL_TAB_BAR_ITEM_TITLE`); tab change notifications with exact objects and identifier (`CYLTabBarItemTitleDidChangeNotification`, `CYLTabBarItemIconDidChangeNotification`, `CYLTabBarItemDidChangeNotification`, `CYLTabBarControllerThemeDidApplyNotification`) | [Update-Tab-Bar-Items-In-Place](../../../docs/Update-Tab-Bar-Items-In-Place.md) |
| One configuration file (JSON, YAML, plist, …, a URL) creates the tab bar; every key, file values, the error codes, the edge cases | [Configuration-File](../../../docs/Configuration-File.md) |
| React Native and Flutter components (`CrossPlatform/react-native-cyltabbar`, `CrossPlatform/flutter_cyltabbar`): how they work, `CYLTabBarHostView` (iOS and Android: only the bar of a configured controller, for any host or a native app drawing its own pages), `CYLTabBarControllerPlusButton` / `…PlusButtonAction`, host badges / long press / plus page / `touchableRects` (the transparent strip passes touches), `badgeAttributes` / `plusButtonBadgeAttributes` (value, color, animation, radius, center offset per badge), `tabCoverImages` (a cover over a selected tab, as `-setSelectedCoverShow:`), the iOS host forwarding the delegate methods it does not handle to the controller's own delegate, `CYLAnimationView` (PAG / Rive / Lottie in a page), the 4 animated-icon demos (`example-pag`, `example-rive`, `example_pag`, `example_rive`), limits | [Cross-Platform-Components](../../../docs/Cross-Platform-Components.md) |
| Plus button keys without a subclass (`CYLPlusButtonBackgroundImage`, `…IndexInTabBar`, `…CenterYMultiplier` / `…CenterYOffset`, `…AlignsTitle`, `…KeepsTitleVisible`, `…ShowsSelection`) and the top-level `CYLTabBarControllerUserInterfaceStyle` (iOS only), `…TabButtonTapAnimation`, `…SwipeToSwitchTab` | [Configuration-File](../../../docs/Configuration-File.md) |
| React Native: run the example, add `react-native-cyltabbar`, pod install, `<CYLTabBar>` props and events, image values, troubleshooting | [React-Native-Component](../../../docs/React-Native-Component.md) |
| Flutter: run the example, add `flutter_cyltabbar`, `FlutterFragmentActivity` on Android, Swift Package Manager (`path:` to this repository) or CocoaPods on iOS, `CYLTabBar` fields, troubleshooting | [Flutter-Component](../../../docs/Flutter-Component.md) |
| Localized texts of a configuration file: `CYLTabBarControllerLocalization` (`…TableName`, `…Path`, `…BundleName`), `.strings` tables in the app (never in the library), location routes `bundle:` / `sandbox:Documents|Caches|tmp/…` / `file:` / absolute / `~/` / relative, downloaded tables, React Native / Flutter | [Configuration-Localization](../../../docs/Configuration-Localization.md) |
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
| The iOS Example's demo rows ported to the Android demo (`Example-Android/app`): what iOS shows, the Android implementation, status, score; scroll hiding restore on Android | [Android-Demo-Migration](../../../docs/Android-Demo-Migration.md) |
| The Android versions of Example-PAG, Example-GIF and Example-Rive (`Example-Android/example-*`), the shared `demokit` module (`DemoAssets` reads the iOS examples' asset catalogs, fonts and bundle: no copied resources), `CYLGIFDrawable` (a GIF image loops) | [Android-Examples](../../../docs/Android-Examples.md) |
| How the Android library compares with QMUI_Android's `QMUITabSegment` and `QMUISkinManager` (scores per dimension, gaps to close) | [Android-QMUI-Comparison](../../../docs/Android-QMUI-Comparison.md) |
| Android-only extensions adapted from QMUI_Android (off by default, no iOS twin): `CYLTabBar.cyl_indicator` (`CYLTabBarIndicator`), `cyl_scrollMode` (`CYLTabBarScrollMode`), `cyl_updateIndicatorPosition`, `CYLTabBarController.cyl_swipesBetweenPages`; theme values `View.cyl_themeValue`, `CYLThemeValueBuilder`, `CYLThemeStyle`, `CYLThemeValues` (`installLayoutInflaterFactory`, `register`, `setRuleHandler`), `CYLThemeSpan`, `CYLThemeItemDecoration` | [Android-Library](../../../docs/Android-Library.md) |
| Publishing the Android library to Maven (Maven Local, Maven Central, GitHub Packages): `scripts/publish-android.sh`, coordinates `io.github.chenyilong:cyltabbarcontroller` / `cyltabbarcontroller-pages`, credentials, signing | [Android-Library](../../../docs/Android-Library.md) |
| Image-only tabs | [Image-Only-Tabs](../../../docs/Image-Only-Tabs.md) |
| Per-tab colors | [Tab-Item-Colors](../../../docs/Tab-Item-Colors.md) |
| Tab positioning, width, spacing | [Tab-Item-Positioning](../../../docs/Tab-Item-Positioning.md) |
| A different title when selected | [TabBarItem-Selected-Title](../../../docs/TabBarItem-Selected-Title.md) |
| FlatDesign appearance | [FlatDesign-StandardAppearance](../../../docs/FlatDesign-StandardAppearance.md) |
| Tab gestures, double tap | [TabBarItem-Gestures](../../../docs/TabBarItem-Gestures.md) |
| Tap animations, haptics, interactions | [Tab-Interactions](../../../docs/Tab-Interactions.md) |
| Reselect: pop or scroll to top | [Tab-Reselect](../../../docs/Tab-Reselect.md) |
| A tab runs an action | [Tab-Custom-Action](../../../docs/Tab-Custom-Action.md) |
| Login-required tabs (also the config key, Android persistence, `CYLTabBarHostView` / React Native / Flutter `loggedIn`, `onLoginRequest`, `onLoginStateChange`) | [Login-Required-Tabs](../../../docs/Login-Required-Tabs.md) |
| Hide or minimize on scroll | [TabBar-Minimize-On-Scroll](../../../docs/TabBar-Minimize-On-Scroll.md) |
| Push from anywhere | [Push-From-Anywhere](../../../docs/Push-From-Anywhere.md) |
| Accessibility identifiers, XCUITest | [Tab-Accessibility](../../../docs/Tab-Accessibility.md) |
| Hit testing | [TabBar-HitTest-Super-Fallback](../../../docs/TabBar-HitTest-Super-Fallback.md) |
| Adding animated tab icons: steps, notes, demos | [Tab-Icon-Animation-Quick-Start](../../../docs/Tab-Icon-Animation-Quick-Start.md) |
| Animation subspec, adding a library | [Tab-Bar-Item-Animation](../../../docs/Tab-Bar-Item-Animation.md) |
| PAG | [PAG-Animation](../../../docs/PAG-Animation.md) |
| Rive | [Rive-Animation](../../../docs/Rive-Animation.md) |
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
