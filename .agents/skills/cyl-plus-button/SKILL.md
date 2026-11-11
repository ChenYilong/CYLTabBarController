---
name: cyl-plus-button
description: "Rules and limits of CYLPlusButton: registering, position, title alignment, the Liquid Glass stand-in, selected images, background images, late images, badges and touches. Use before writing or changing a plus button, in the library or in an app."
---

# CYLPlusButton

Read [PlusButton](../../../docs/PlusButton.md) before changing its images, its stand-in or its theming. Source of truth: code, then `docs/`, then `README.md`. If they disagree, fix the wrong one first (usually `README.md`), then this skill.

## Create it

- A `CYLPlusButton` subclass conforming to `CYLPlusButtonSubclassing`. Prefer `+cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:` in `+plusButton`.
- Call `[YourClass registerPlusButton]` before any `CYLTabBarController` is created, in `-application:didFinishLaunchingWithOptions:` or a SwiftUI `App`'s `init`. Never in `+load`.
- The plus button is not counted in `viewControllers` or `tabBarItemsAttributes`.
- `+indexOfPlusButtonInTabBar` must be implemented when the number of tab items is odd.
- Several tab bar controllers: `+tabBarContext` must match the controller's `context`.
- Without a subclass (a configuration file, React Native, Flutter): `CYLTabBarControllerPlusButton` = `{CYLTabBarItemTitle, CYLTabBarItemImage, CYLTabBarItemSelectedTitle?, CYLTabBarItemSelectedTitleColor?}` in the configuration, `CYLTabBarControllerPlusButtonAction` (code only) for taps; in code, `+[CYLPlusButton cyl_registerPlusButtonWithAttributes:action:context:]` (Android: `CYLPlusButton.cyl_registerPlusButtonWithAttributes`). One per context (each keeps its attributes and action); it aligns its title when it has one. More keys in the same dictionary: `CYLPlusButtonBackgroundImage` (title drawn on it, button takes its size; titles not aligned by default), `CYLPlusButtonIndexInTabBar`, `CYLPlusButtonCenterYMultiplier` / `CYLPlusButtonCenterYOffset`, `CYLPlusButtonAlignsTitle`, `CYLPlusButtonKeepsTitleVisible`, `CYLTabBarItemTitleColor` / `CYLTabBarItemTitleFont`, `CYLTabBarItemSelectedImage`, `CYLPlusButtonSize` (the button's size, as a subclass's frame), `CYLPlusButtonImageSize` (its images drawn aspect fit in that size, e.g. a 512 px network image), and `CYLTabBarItemPageIdentifier` for its own page (the action still runs: it fires from `cyl_sendDidSelectControl:`). iOS makes a subclass per registration (`objc_allocateClassPair`), adding only the class methods for keys that are present. On Android the configured title color is a `ForegroundColorSpan` on the title text (a `Spannable.Factory`), drawn over the tab bar's tint; with a background image the badge offset (`cyl_badgeCenterOffset`) puts the badge on the image's visible top-right corner (`opaqueBounds`). On iOS 15+ the configured button lays out with a `UIButtonConfiguration` (image on top, `imagePadding` 0, no leading / trailing insets), like `CYLPlusButtonSubclass`, so an aligned title lands where the Objective-C example puts it. Android's aligned rule is the same: button height = image + title, title on the tab titles' line, image right above it. Badges on both platforms anchor at the image's top-right corner: center = (image right + 2 + offset.x, image top + offset.y) (`cyl_badgeOrigin` on Android). See [Configuration-File](../../../docs/Configuration-File.md).

## Title alignment: decide this first

| The app wants | Do | Avoid |
|:---|:---|:---|
| The title on the tab titles' line, with their font and colors | `+alignsTitleWithTabBarItemTitles` returns YES, **and give the button a title** | YES with no title: the method then does nothing, and on Liquid Glass the button covers the whole tab item instead of replacing its icon. Not recommended |
| A title drawn on the picture (background image only) | Do not implement it. Place the button with `+multiplierOfTabBarHeight:` and `+constantOfPlusButtonCenterYOffsetForTabBarHeight:` | YES: the title leaves the picture for the tab titles' line |
| No title at all | Do not implement it | |

With YES on Liquid Glass the title moves into the tab item under the button (#636), so the system draws it in both layers, and `currentTitle` is nil on the button. Read `tabBarItem.title` of the child view controller instead.

## Liquid Glass (iOS 26+, not FlatDesign), with a plus child view controller

- The real button sits in `CYLTabBar`; its stand-in (`-selectedContentView`) sits in the selected layer. For a subclass the stand-in is another `+plusButton` instance, so anything `+plusButton` schedules also runs on the stand-in.
- The real button lies under the platter, and the lens blurs what is under it: while the plus page is selected, `-cyl_updateLiquidGlassMask` masks the real button under the lens (the whole lens area when all its content is inside, else the title's strip only, so an icon reaching above the platter shows no gap). It runs last in `-layoutSubviews` and on every tab bar layout pass; an app's own `layer.mask` is left alone.
- Both draw **only the normal image**, selected or not. A selected image set by the app or a theme stays readable through `-imageForState:` and is used by FlatDesign and the classic tab bar.
- With title alignment the two line up **by icon only**: take the icon's coordinates and ignore other subviews. With no drawn icon (background image, removed image) they line up by button center.
- Keep this inside the plus button, behind a Liquid Glass guard. The guard is Liquid Glass active **and** not FlatDesign: `+isLiquidGlassActive` is also YES with FlatDesign on iOS 26.
- A badge goes through `-cyl_performSelector:` to both layers (#779): the real button and the stand-in, so it stays sharp in the glass. An icon with transparent parts can show a blurred halo in the glass: the mask that hid it was removed.

## Images that change later

- A late image, a replacement, a removal (`setImage:nil`) or a late background image must end like the same picture set at launch. The ObjC demo's row "PlusButton 图片之后才加载" compares each case with a control.
- A plus button whose picture is its background image takes no image from a theme or the demo's "change all icons" rows: an icon would sit over the picture, beside the title. Only an app calling `-updatePlusButtonWithAttributes:` itself can add one.
- A theme gives way to a background image; see `cyl-theme`. A badge asked for before the picture arrives is shown when it arrives.
- All plus button images are drawn as original, never tinted and not darkened on touch.

## Other limits

- iOS 27.1 vertical bar (`allowsVerticalBar`, unfolded iPhone Duo): the Y offset methods are ignored, because the button is centered in the bar.
- Taps and `tabBarController:didSelectControl:`: use `plusButton.reportsTapsToDelegate` (default YES; NO keeps the plus button's taps out). ⚠️ `cyl_userInteractionDisabled` / `cyl_shouldNotSelect` are deprecated: they were also the library's selection lock, so the plus button stopped reporting once its page was selected. Do not decide reporting from the layout at creation. See [PlusButton-Badge](../../../docs/PlusButton-Badge.md).
- Touchable area on Liquid Glass: points above the bar reach the plus button through `CYLTabBarOverflowTouchView` (iOS 26+), but a point in a neighboring tab's column goes to the system tab bar's gesture, not the plus button. Do not override `-touchableRect` to return `frame`: it disables `touchableAreaOutsets` and `touchableAreaScale`.
- Subviews that take touches (an X button, a view with a gesture) get them first (#202). On Liquid Glass `-[CYLTabBar gestureRecognizerShouldBegin:]` refuses UIKit's selection gesture for such a subview; without that the gesture selected the stand-in tab under the plus button and cancelled the subview's touch.
- Height and touches: [PlusButton-Touchable-Area](../../../docs/PlusButton-Touchable-Area.md), [PlusButton-Subview-Touches](../../../docs/PlusButton-Subview-Touches.md).
- `selectedIndex` and the slot: [SelectedIndex-PlusButton](../../../docs/SelectedIndex-PlusButton.md), [PlusButton-Slot](../../../docs/PlusButton-Slot.md).
- Its page's navigation title: `CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM(plusChildViewController)` makes it follow the plus button's title (`cyl_title`), at setup and after `-updatePlusButtonWithAttributes:` / skins; the tab notifications then carry `CYLPlusButtonKey`. Android: `plusChildViewController().cyl_navigationTitleFollowsTabBarItemTitle = true` (the activity title while the plus page is selected). See [Update-Tab-Bar-Items-In-Place](../../../docs/Update-Tab-Bar-Items-In-Place.md).
- Badge: [PlusButton-Badge](../../../docs/PlusButton-Badge.md). Background image: [PlusButton-Background-Image-Liquid-Glass](../../../docs/PlusButton-Background-Image-Liquid-Glass.md).

### Default setup in the examples

Unless the task says otherwise, an example's CYLTabBarController has a plus button **with its own page**
(`plusChildViewController`) and is created **from a local configuration file** with
`+tabBarControllerWithConfigurationFile:error:` (tabs in `CYLTabBarControllerTabBarItemsAttributes`, the plus button in
`CYLTabBarControllerPlusButton`, its page by `CYLTabBarItemPageIdentifier`). Another setup is used only on purpose and named
in the demo. AGENTS.md, "How the examples set CYLTabBarController up".
