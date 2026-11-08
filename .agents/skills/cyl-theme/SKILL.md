---
name: cyl-theme
description: "Theme switching (skins) in CYLTabBarController: CYLThemeManager, CYLTabBarTheme, how themes restore tabs and the plus button. Use when adding a skin, or changing theme or in-place tab update code."
---

# Themes

Main document: [Theme-Switching](../../../docs/Theme-Switching.md). In-place updates: [Update-Tab-Bar-Items-In-Place](../../../docs/Update-Tab-Bar-Items-In-Place.md). Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

## Use

- Register themes with `CYLThemeManagerCenter.defaultThemeManager` (`-addThemeIdentifier:theme:`), and set `currentThemeIdentifier`. Views and view controllers are told through `CYLThemeDidChangeNotification`.
- A theme object conforms to `CYLTabBarTheme` (in `CYLTabBarController.h`) to restyle the tab bar in place: no new tab bar and no new pages, in Liquid Glass, the system tab bar and FlatDesign.
- Register themes before the tab bar appears: `Example/SceneDelegate.m` calls `+cyl_setUpThemeSettings` first.

## Limits

- Themes go through the same code as the app's own updates: `-updateTabBarItemsWithAttributes:` for the tabs, `-updatePlusButtonWithAttributes:` for the plus button.
- What a theme changed is recorded and given back when a theme no longer provides it, unless the app changed it meanwhile (`CYLThemeRestorableValue`). A new attribute needs the same treatment.
- A plus button whose picture is its background image takes no theme image, including one that arrives after the theme.
- Liquid Glass has two layers, so theme icons use `-setTabBarItemIcon:selectedIcon:size:atIndex:`. Never change `tabBarItem.image` there: UIKit rebuilds the tab button.
- Liquid Glass and other styles differ here: isolate the code with the guard in `cyl-xcode-compat`.

## Check

`scripts/plus-child-theme-test.sh` and `STYLE=FlatDesign scripts/theme-screenshots.sh`; see [Plus-Child-Theme-Switching-Test](../../../docs/Plus-Child-Theme-Switching-Test.md).

## Android: theme values (Android only)

The Android library follows the same `CYLThemeManager` model. On top of it, theme values (adapted from QMUI_Android) let any view follow a theme by name: `View.cyl_themeValue = "textColor:title|background:surface"` (or `CYLThemeValueBuilder`, or `app:cyl_themeTextColor="title"` with `CYLThemeValues.installLayoutInflaterFactory` before `super.onCreate`). Names resolve in the current theme: a `CYLThemeStyle(R.style.X)` (theme attributes), a `Map`, or a `CYLThemeValueProviding`. Views outside a tab bar controller's activity need `CYLThemeValues.register(target)`. Never add these to the iOS API; they have no iOS twin. Details: docs/Android-Library.md, "Android-only extensions".

## Skins in a configuration file (iOS and Android)

A configuration file can carry skins: `CYLTabBarControllerThemes` (identifier -> named values), `CYLTabBarControllerThemeIdentifier` (base and first skin), `CYLTabBarControllerDarkThemeIdentifier` (Dark Mode) and `CYLTabBarControllerThemeManagerName`. Tab values written `"@name"` take the current skin's value; reserved names (`CYLTabBarBackgroundColor`, `CYLTabBarShadowColor`, the bar-wide title / icon colors and fonts) style the whole bar. Each skin is a `CYLTabBarConfigurationTheme` registered with the manager, so switching is `manager.currentThemeIdentifier = "dark"` and goes through the usual `CYLTabBarTheme` path. Use this instead of writing a `CYLTabBarTheme` class when the skins are data. A skin's `CYLTabBarBackgroundColor` gives an opaque bar (classic and FlatDesign; the Liquid Glass glass ignores it, iOS 26 and Android alike). A skin of an earlier configuration that a new configuration does not list is replaced by the new one's first skin (a skin the app registered itself stays): this is how a React Native / Flutter app switches skins, by passing a configuration with the chosen skin (see the examples' skin menus). Details: docs/Configuration-File.md, "Skins".
