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

## Title alignment: decide this first

| The app wants | Do | Avoid |
|:---|:---|:---|
| The title on the tab titles' line, with their font and colors | `+alignsTitleWithTabBarItemTitles` returns YES, **and give the button a title** | YES with no title: the method then does nothing, and on Liquid Glass the button covers the whole tab item instead of replacing its icon. Not recommended |
| A title drawn on the picture (background image only) | Do not implement it. Place the button with `+multiplierOfTabBarHeight:` and `+constantOfPlusButtonCenterYOffsetForTabBarHeight:` | YES: the title leaves the picture for the tab titles' line |
| No title at all | Do not implement it | |

With YES on Liquid Glass the title moves into the tab item under the button (#636), so the system draws it in both layers, and `currentTitle` is nil on the button. Read `tabBarItem.title` of the child view controller instead.

## Liquid Glass (iOS 26+, not FlatDesign), with a plus child view controller

- The real button sits in `CYLTabBar`; its stand-in (`-selectedContentView`) sits in the selected layer. For a subclass the stand-in is another `+plusButton` instance, so anything `+plusButton` schedules also runs on the stand-in.
- Both draw **only the normal image**, selected or not. A selected image set by the app or a theme stays readable through `-imageForState:` and is used by FlatDesign and the classic tab bar.
- With title alignment the two line up **by icon only**: take the icon's coordinates and ignore other subviews. With no drawn icon (background image, removed image) they line up by button center.
- Keep this inside the plus button, behind a Liquid Glass guard. The guard is Liquid Glass active **and** not FlatDesign: `+isLiquidGlassActive` is also YES with FlatDesign on iOS 26.
- A badge exists only on the real button, so where the glass covers it, it looks blurred. An icon with transparent parts can show a blurred halo in the glass: the mask that hid it was removed.

## Images that change later

- A late image, a replacement, a removal (`setImage:nil`) or a late background image must end like the same picture set at launch. The ObjC demo's row "PlusButton 图片之后才加载" compares each case with a control.
- A plus button whose picture is its background image takes no image from a theme or the demo's "change all icons" rows: an icon would sit over the picture, beside the title. Only an app calling `-updatePlusButtonWithAttributes:` itself can add one.
- A theme gives way to a background image; see `cyl-theme`. A badge asked for before the picture arrives is shown when it arrives.
- All plus button images are drawn as original, never tinted and not darkened on touch.

## Other limits

- iOS 27.1 vertical bar (`allowsVerticalBar`, unfolded iPhone Duo): the Y offset methods are ignored, because the button is centered in the bar.
- Height and touches: [PlusButton-Touchable-Area](../../../docs/PlusButton-Touchable-Area.md), [PlusButton-Subview-Touches](../../../docs/PlusButton-Subview-Touches.md).
- `selectedIndex` and the slot: [SelectedIndex-PlusButton](../../../docs/SelectedIndex-PlusButton.md), [PlusButton-Slot](../../../docs/PlusButton-Slot.md).
- Badge: [PlusButton-Badge](../../../docs/PlusButton-Badge.md). Background image: [PlusButton-Background-Image-Liquid-Glass](../../../docs/PlusButton-Background-Image-Liquid-Glass.md).
