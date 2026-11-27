# Animated items and optional components (tag: `animation`)

Full text of the `animation` rules. [AGENTS.md](../../AGENTS.md#animated-items-and-optional-components-tag-animation) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

- **`CYLAnimatedItemView` does not depend on CYLTabBarController (added 2026-11-17)**: the animated item component
  (iOS: the `CYLAnimatedItem` pod, `CYLAnimatedItem.podspec`; Android: `:cylanimateditem`, package
  `com.cyl.animateditem`) never imports, calls or depends on CYLTabBarController's code, subspecs, module or resources
  (no `CYLTabBarController-Swift.h`, no `:cyltabbar`; CYLUtils only as the independent `CYLUtils` pod, see the 2026-11-27 note below); CYLTabBarController depends on it, never the other
  way round. Code that is only for tests may depend on CYLTabBarController. Details:
  [docs/Animated-Item.md](docs/Animated-Item.md#enstructure).
- **Optional components are isolated with guards**:
  - FlatDesign code in Core: `#if CYL_FLATDESIGN_AVAILABLE` (defined once in `CYLUtils/CYLUtilsMacros.h`), and run only
    for `CYLTabBarStyleTypeFlatDesign`, so Liquid Glass and the classic style are never affected.
  - Lottie: separate `__has_include` guards; check keys first; call through `respondsToSelector:` and
    `cyl_performSelector`.
  - Every type's keys always exist (2026-11-17, in the component's core `CYLAnimationKeys.h`): without that type's engine a
    key still compiles, gets a compile warning (`CYL_PAG_REQUIRED`, `CYL_RIVE_REQUIRED`, `CYL_SVGA_REQUIRED`,
    `CYL_GIF_REQUIRED`, `CYL_LOTTIE_REQUIRED`) and a debug log at run time (`CYLAnimationWarnMissingEngine()`; Android
    `CYLAnimationEngines.warnMissingEngine`), and the item shows its static image, or the placeholder. The switches are all defined in the component's core,
    `CYLAnimatedItem/CYLAnimatedItemMacros.h` (2026-11-17): `CYL_ANIMATION_ENGINE_AVAILABLE` (any engine),
    `CYL_LOTTIE_AVAILABLE` (the Lottie library), and `CYL_GIF_AVAILABLE`, `CYL_PAG_AVAILABLE`, `CYL_RIVE_AVAILABLE`,
    `CYL_SVGA_AVAILABLE` (that type's engine subspec, found by its animator header through the header search paths,
    plus its library). Each animator header imports that file, and the animator itself sits inside its switch. CYLTabBarController's Core and CYLUtils define no library switch. The released Lottie keys stay defined and are marked
    `CYL_LOTTIE_REQUIRED` (a compile warning without Lottie). See docs/Tab-Bar-Item-Animation.md.
- **Amended 2026-11-27 (owner decision D7, [docs/Animated-Item-Badge.md](../Animated-Item-Badge.md#enowner-decisions))**: CYLUtils
  and CYLBadge become independent pods below the component: CYLUtils ← CYLBadge ← CYLAnimatedItem ← CYLTabBarController.
  The component may depend on those two pods (until they are extracted, the no-CYLUtils rule above still holds), and
  still never on CYLTabBarController itself, its Core or its other subspecs. CYLUtils and CYLBadge never depend on the
  component or on the tab bar.
