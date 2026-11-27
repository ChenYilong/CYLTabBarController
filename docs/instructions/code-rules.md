# Code Rules [`code-rules`]

## General

- **No warnings**: fix every build and static-analyzer warning you encounter, including old ones in code you did not change.
- **Public API**: never remove or change an existing public API; add new API instead. Prefer implementing an existing protocol method over adding a new category method; file-private C functions and private headers are fine.

## Swift-friendly names for underscored protocol methods

Swift method names must not contain underscores, but a Swift class that implements an Objective-C protocol method must use its imported name (for example, `cyl_play…`); renaming it no longer satisfies the protocol. Adding `NS_SWIFT_NAME` to the existing method would change a Swift API already released on `master`, which the Public API rule forbids.

Instead, add a new method with the same name minus the underscore, keeping the `cyl` prefix (for example, `-cyl_playSelectAnimationWithTabButton:…` → `-cylPlaySelectAnimationWithTabButton:…`), and define its Swift name with `NS_SWIFT_NAME` on the new method only. Both spellings run the same logic: the library calls the underscore-free one when it is implemented, otherwise the underscored one. If the old method was `@required`, make it `@optional` so a class can implement only the new one.

## Plus button images

Read [../PlusButton.md](../PlusButton.md) before changing the plus button's images, its stand-in, or its theming. With a plus child view controller on Liquid Glass (not FlatDesign), the stand-in ignores selected images and shows only the real plus button's normal image. Selected images stay available to apps and themes for FlatDesign and the classic tab bar, so keep this in the plus button's internals, behind a Liquid Glass guard.

When the app asks for the title to be aligned (`+alignsTitleWithTabBarItemTitles`), the stand-in and the real plus button line up by icon only: take the icon's coordinates and ignore the other subviews.

## Optional components are isolated with guards

- **FlatDesign code in Core**: `#if CYL_FLATDESIGN_AVAILABLE` (defined once in `CYLUtils/CYLUtilsMacros.h`), and run only for `CYLTabBarStyleTypeFlatDesign`, so Liquid Glass and the classic style are never affected.
- **Lottie**: separate `__has_include` guards; check keys first; call through `respondsToSelector:` and `cyl_performSelector`.
- **An animation library's own keys exist only with that library**: its header defines `CYL_<LIBRARY>_AVAILABLE` (`__has_include` of the library), and the header's content and the `.m` definitions sit inside it (`CYL_PAG_AVAILABLE`, `CYL_RIVE_AVAILABLE`). Core and CYLUtils get no library switch. The released Lottie keys stay defined and are marked `CYL_LOTTIE_REQUIRED` (a compile warning without Lottie). See [../Tab-Bar-Item-Animation.md](../Tab-Bar-Item-Animation.md).

## Clean builds and simulator

- **Clean before every build and run**: build into an empty derived data folder (delete it first, or pass a new `-derivedDataPath`), for apps, tests, and scripts alike. The Objective-C demo does not relink after a change in the library only, so a reused build tests an old binary and its result means nothing (2026-11-09: two experiments ran stale code). Confirm a new symbol is in the app (`strings <app>/<binary> | grep <symbol>`) when in doubt.
- **Simulator**: run `scripts/free-ram.sh` before every simulator use. Details and common failures: the `cyl-verify` skill.

## Verify before pushing

Run `pod lib lint CYLTabBarController.podspec --quick`, plus a build or static check of the changed code. Say plainly what could not be verified.

## Xcode project file format

Xcode project files keep the Objective-C example's format (`objectVersion = 46`, `compatibilityVersion = "Xcode 3.2"`, no folder sync, deployment target below 27), or CI on Xcode 26 fails. Check before committing any `.xcodeproj` change. Full rules: the `cyl-xcode-compat` skill.
