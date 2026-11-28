# iOS: public headers and core

> **UNVERIFIED.** Notes from a partial static reading on 2026-11-29; they were not re-checked against the code, and coverage is
> incomplete (see this folder's `README.md`). Later commits may have changed what is described, including the badge task's state.

Project: CYLTabBarController · exported 2026-11-29 for `claude-mem:learn-codebase`


**Coverage: all public headers read; the core was read only in part.**

## Public headers (complete)

All CYLTabBarController/**/*.h read (CN comments stripped). Public API is mostly shim headers over the Swift implementation (CYLSwiftInterface.h); ObjC kept for block typedefs, NS_OPTIONS, key macros, +load animator registration, @try. Config keys documented in CYLTabBarController.h. Animation: registry/factory/engine/player protocols; engines are optional subspecs behind CYL_*_AVAILABLE; CYLAnimatedItem never imports the tab bar.

## CYLPlusButton.swift

CYLPlusButton: open Swift class; setConfiguration:, cyl_clearBadge, +selectedContentView added via ObjC runtime; configuration plus button = runtime subclass (objc_allocateClassPair), so call class methods via runtime not type(of:). Per-context registry in +CYLImplementation. CYLCompatibleLottie.forceDrawingUpdate just calls forceDisplayUpdate (.swift)

## CYLPlusButton+CYLImplementation.swift (read in part)

CYLPlusButton+CYLImplementation.swift: per-context registry (NSRecursiveLock) + per-controller binding; legacy globals mirrored via ObjC class method. Images forced alwaysOriginal, unset derived states copy source state. Liquid Glass #636: title moves into tab item under plus button (cylShowsTitleInTabBarItem), stand-in in selected layer kept on plus button center. Lens mask compiled only with CYL_PLUS_BUTTON_LENS_MASK_ENABLED (off). Relies on private UIKit class name containing LiquidLens inside that flag.

## Plus button, explained

- **Runtime classes:** a plus button created from configuration is a subclass made while the app runs. For these, code has to call class methods through the Objective-C runtime; ordinary Swift calls would reach the parent class.
- **Separate registrations:** registrations are stored by tab bar context, and each tab bar controller has its own binding. The old global values are still updated for compatibility.
- **Images:** they're drawn in their original colors. Highlighted and disabled states you haven't set reuse another state's image, so iOS doesn't darken or fade the button.
- **Liquid Glass titles:** when title alignment and the other conditions are met, the title moves into the tab item below the plus button. A copy of the button in the selected layer is then kept lined up with it.
- **Lens mask:** it's compiled only when `CYL_PLUS_BUTTON_LENS_MASK_ENABLED` is set, and a code comment says it's off. If it's turned on, it finds the lens by looking for `LiquidLens` in a private UIKit class name, which an iOS update could change.

I didn't run any builds or tests, so these points come only from reading the code.

## Observations (20)

> The entries under "Observations" are copied verbatim from claude-mem. They are its automatic summaries of what was read; I have not re-checked each one against the source. No build or test was run during the learn-codebase read.

### #209 — Static-image tint rule was tied to animation colour path before commit 5958f8a3 (GitHub)
discovery · 2026-11-27 12:15 UTC
At d5f1b436, applyIconTintColor documented that it tinted animations only, not static images, under tint spec v2.

Before 5958f8a3, CYLAnimatedItemView excluded static images from built-in icon tinting by design. The new behaviour changes that rule, so the all-platform repin must use 5958f8a3 to pick up the static-image tint fix. The ClassifyMenu side also needs the line-444 filter removed, so the core rule is the single source of tint for these tags.

- At d5f1b436, the built-in icon colour documented in CYLAnimatedItemView applied to animations only, not to static images, per tint spec v2.
- At d5f1b436, applyIconColor cleared any colour filter on iconView when no effective icon colour was set, without checking whether the host had set it.
- At d5f1b436, the static image path had no call to re-apply the icon colour when the shown image changed.
- Commit 5958f8a3 is the pin the ClassifyMenu repin should use instead of d5f1b436, per the cross-session note from the winsCYLTabBarController session.

Files read: Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/CYLAnimatedItemView.kt

Concepts: problem-solution, gotcha

---

### #213 — Regression tests added for contrast lift after byte rounding (GitHub)
feature · 2026-11-27 12:16 UTC
New Android and HarmonyOS tests assert that lifted colours meet the contrast floor when judged on whole-byte values, with no slack.

Added regression coverage for the rounding bug in both the Android and HarmonyOS contrast lift. The Android test sweeps a range of hues at both the icon and title minimums and asserts the lifted colour passes on bytes, which replaces the previous 0.01 slack in the ClassifyMenu test. The HarmonyOS test checks specific dark teal and related colours through adaptedForContrastState for both icon and title kinds. Together these guard against reintroducing the gap where rounding drops a colour just under the floor.

- Android CYLAnimatedItemFlatContrastTest.kt gained aLiftedColourMeetsTheFloorAfterRoundingToBytes, which sweeps hues 0 to 359 in steps of 7 at minimums 3.0 and 4.5 over the darkFill reference.
- The Android test builds colours with Color.HSVToColor(hue, 1, 0.3) and asserts contrastOn(lifted, darkFill) >= minimum with no tolerance, reporting the lifted hex on failure.
- HarmonyOS CYLAnimatedItemFlatContrast.test.ets gained a test that lifts six dark teal and red-brown explicit colours for both icon and title kinds against DARK_FILL and asserts each meets its floor with no slack.
- The HarmonyOS test is inserted before the existing "glass keeps the glass reference" case.
- The Android test file already imports org.junit.Assert.assertTrue, so no new imports were added there.
- The Android edit appends the new test before the file's closing brace using a last-occurrence replacement, and the HarmonyOS edit uses a single-match assertion.
- The test comment cites the HarmonyOS failure of #007373 at 2.9977:1 found on 2026-11-28, which the earlier byte-rounding fix now prevents.

Files read: Example-Android/cylanimateditem/src/test/kotlin/com/cyl/animateditem/CYLAnimatedItemFlatContrastTest.kt, CrossPlatform/harmonyos-cyltabbar/entry/src/ohosTest/ets/test/CYLAnimatedItemFlatContrast.test.ets

Concepts: problem-solution, pattern

---

### #261 — Package header CYLPAGTabBarItemAnimator.h is a text placeholder, not the real header (GitHub)
discovery · 2026-11-28 11:45 UTC
On this Windows checkout, the ObjC include header holds only a relative path to the PAG animator source.

Reading the PAG animator header in the CYLTabBarController Package/ObjC/include directory returned only a relative path pointing to CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.h three directories up. The header is therefore a symlink-style redirect stored as a text file on this Windows cloud-synced checkout. Any build or include that resolves this header through the package include path will not find real declarations unless the link is materialized or the include points at the target. This matters for anyone building the PAG animation package from this checkout on Windows.

- Package/ObjC/include/CYLPAGTabBarItemAnimator.h in the CYLTabBarController checkout is one line long.
- The single line of CYLPAGTabBarItemAnimator.h is the relative path ../../../CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.h.
- The file is 1 line total, so it contains no Objective-C declarations of its own.
- The file's content is a relative path string, which matches the layout of a git symlink materialized as a plain text file.
- The working checkout sits under a cloud-synced folder on Windows, where symlinks are typically not created, so the link is stored as plain text.

Files read: CYLTabBarController\Package\ObjC\include\CYLPAGTabBarItemAnimator.h, CYLTabBarController/CYLTabBarController/Package/ObjC/include/CYLPAGTabBarItemAnimator.h

Concepts: gotcha, how-it-works

---

### #262 — Package header CYLPlusButton.h is also a text redirect to ../../../CYLPlusButton.h (GitHub)
discovery · 2026-11-28 11:45 UTC
The same symlink-as-text pattern seen in the PAG animator header appears in the CYLPlusButton header on this Windows checkout.

Reading Package/ObjC/include/CYLPlusButton.h returned only a relative path to ../../../CYLPlusButton.h. This is the same pattern recorded for CYLPAGTabBarItemAnimator.h: the include directory holds symlink-style redirects materialized as plain text on this Windows cloud-synced checkout. The redirect target is a sibling of the package root rather than the animation folder, so the include directory cannot resolve these headers directly without the links being materialized. This affects any Windows build that adds Package/ObjC/include to its header search path.

- Package/ObjC/include/CYLPlusButton.h in the CYLTabBarController checkout is one line long.
- The single line of CYLPlusButton.h is the relative path ../../../CYLPlusButton.h.
- The file contains no Objective-C declarations and redirects to a header three directories up.
- Package/ObjC/include contains at least two redirect-style headers, CYLPAGTabBarItemAnimator.h and CYLPlusButton.h, each stored as a relative path string.

Files read: CYLTabBarController\Package\ObjC\include\CYLPlusButton.h, CYLTabBarController/CYLTabBarController/Package/ObjC/include/CYLPlusButton.h

Concepts: gotcha, pattern

---

### #263 — Deprecated Swift name shim for UINavigationController in CYLFlatDesignTabBar forwards old names to new ones (GitHub)
discovery · 2026-11-28 11:46 UTC
A Deprecated folder keeps source-compatible Swift names for UINavigationController that forward to lowerCamelCase replacements.

Reading UINavigationController+CYLFlatDesignDeprecatedNames.swift showed a compatibility layer for the flat design tab bar. Swift callers using the old cyl_ prefixed name get a deprecation warning pointing at cylNavigationBarActionHook(), and the call forwards to the new name. The comments document that this layer is temporary, removed at the next major version, and excluded from SonarCloud analysis via .sonarcloud.properties. The Swift naming convention is recorded in docs/Swift-Coding-Style.md.

- UINavigationController+CYLFlatDesignDeprecatedNames.swift lives in CYLFlatDesignTabBar-ObjectiveC/Swift/Deprecated and is 25 lines long.
- The file defines cyl_navigationBarActionHook() as a deprecated class func on UINavigationController.
- The deprecated method is annotated @available(*, deprecated, renamed: "cylNavigationBarActionHook()") and @nonobjc.
- The deprecated method body forwards to Self.cylNavigationBarActionHook().
- The file header states the shims are removed at the next major version.
- The file header states SonarCloud skips this folder, configured in .sonarcloud.properties and documented in docs/Swift-Coding-Style.md.
- The Objective-C selectors were never renamed, so only the Swift-facing names changed.

Files read: CYLTabBarController\CYLFlatDesignTabBar\CYLFlatDesignTabBar-ObjectiveC\Swift\Deprecated\UINavigationController+CYLFlatDesignDeprecatedNames.swift, CYLTabBarController/CYLTabBarController/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/Swift/Deprecated/UINavigationController+CYLFlatDesignDeprecatedNames.swift

Concepts: pattern, why-it-exists

---

### #265 — Flat design page tab item moved into FlatDesign subspec with lazy creation and a More-tab icon fix (GitHub)
discovery · 2026-11-28 11:46 UTC
UIViewController+CYLFlatDesignTabBarItem.swift holds the cyl_tabBarItem accessor, which builds its item from UIKit's tabBarItem on demand.

Reading UIViewController+CYLFlatDesignTabBarItem.swift shows how a page's flat design tab item is resolved. The getter caches the item on the page and its navigation controller via associated objects, and creates it lazily from UIKit's tabBarItem, including animated images stored under selector keys by CYLTabBarController.m. The file records two fixes: the More tab used to show no icon and now falls back to the ellipsis symbol, and the setter keeps the item bound to the page even when the weak tab bar controller has been released. The subspec move lets Core compile without FlatDesign.

- UIViewController+CYLFlatDesignTabBarItem.swift is 92 lines and was moved from UIViewController (CYLTabBarControllerExtention) into the FlatDesign subspec so Core builds without FlatDesign.
- The move is documented as step 27 in docs/Swift-Migration.md, and the selector names cyl_tabBarItem and cyl_setTabBarItem: are unchanged.
- The cyl_tabBarItem getter returns a stored CYLFlatDesignTabBarItem from an associated object, or lazily creates one from UIKit tabBarItem, falling back to the page title.
- The cyl_setTabBarItem: setter with nil creates an empty CYLFlatDesignTabBarItem using the page title.
- The setter requires -[CYLFlatDesignTabBarButton setTabBarItem:] to run first, otherwise the item has no button yet.
- A PATCH(aifirx) change binds the item to the page even when the weak CYLTabBarController reference is gone, so the page keeps its icon and title.
- Animated tab images are read from associated objects keyed by the selectors cyl_tabBarItemAnimatedImage and cyl_tabBarItemAnimatedSelectedImage, which CYLTabBarController.m stores on the system item.
- A FIX removes the missing icon on the flat design More tab: the system UIMoreNavigationController item with no image now uses the SF Symbol "ellipsis".
- The More-tab detection matches by class name NSStringFromClass to avoid triggering the lazy moreNavigationController getter.
- Items without a title, such as the slot under the plus button, stay empty so VoiceOver reads nothing there.

Files read: CYLTabBarController\CYLFlatDesignTabBar\CYLFlatDesignTabBar-ObjectiveC\Swift\UIViewController+CYLFlatDesignTabBarItem.swift, CYLTabBarController/CYLTabBarController/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/Swift/UIViewController+CYLFlatDesignTabBarItem.swift

Concepts: how-it-works, problem-solution, gotcha

---

### #266 — Tab bar item animation factory binds players to views through associated objects and reports load or failure to the host tab button (GitHub)
discovery · 2026-11-28 11:46 UTC
CYLTabBarItemAnimationFactory.m creates animation views, attaches a weakly-referencing player, and routes load and failure callbacks up the view hierarchy.

Reading CYLTabBarItemAnimationFactory.m shows how animated tab icons are wired. The factory resolves an animator from a registry by URL, builds a view sized to the tab button, and attaches a player that the view retains and the player holds weakly. Load and failure reporting walks up the superview chain to the nearest host that implements the failure-handling protocol, falling back to a global notification when none exists. The layout fix for issue #653 is set here, at view creation time.

- CYLTabBarItemAnimationFactory.m is 151 lines and implements a shared factory with a dispatch_once singleton, plus an initializer that accepts an animator registry and falls back to CYLTabBarItemAnimatorRegistry sharedRegistry.
- The factory stores each animation view's player under the static key CYLTabBarItemAnimationPlayerKey using OBJC_ASSOCIATION_RETAIN_NONATOMIC.
- The player holds its view weakly, so the view-to-player association does not form a retain cycle.
- animationViewWithURL:size:contentMode: asks the registry for an animator by URL, builds the view, then asks the animator for a player; it returns nil if either step fails.
- Every animation view is sized to the given frame, has user interaction disabled, sets translatesAutoresizingMaskIntoConstraints to YES as a fix for issue #653 (see CYLTabButtonLayoutTracker), and has clipsToBounds set to NO.
- playerForView: returns nil for nil views and for plain UIView instances, returns any stored player, and otherwise asks each registered animator to claim a view made elsewhere in the app, then caches the claimed player.
- CYLTabBarItemAnimationMarkLoading, IsLoading and ReportLoaded track a loading flag on the view under CYLTabBarItemAnimationLoadingKey, and ReportLoaded clears it before notifying the host.
- ReportLoaded and ReportFailure dispatch to the main queue, walk up superviews to the first host conforming to CYLTabBarItemAnimationFailureHandling, and call cylAnimationViewDidLoad: or cylAnimationViewDidFail:error:.
- If no failure-handling host is found, ReportFailure posts CYLTabBarItemAnimationDidFailNotification with the error as NSUnderlyingErrorKey in userInfo.

Files read: CYLTabBarController\CYLTabBarItemAnimation\CYLTabBarItemAnimationFactory.m, CYLTabBarController/CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationFactory.m

Concepts: how-it-works, pattern, gotcha

---

### #404 — C global variables remain in Objective-C during Swift migration (GitHub)
decision · 2026-11-28 12:04 UTC
CYLTabBarControllerGlobals.m keeps the exported C data symbols in Objective-C because Swift cannot export them.

The Swift migration of CYLTabBarController keeps CYLTabBarControllerGlobals.m in Objective-C. The file exports the C data symbols and notification constants that CYLTabBarController.h declares with FOUNDATION_EXTERN, and apps and the library both read them. Swift cannot export data symbols, and @_cdecl only exports functions. Replacing the globals with accessor functions would change the public API, so the file stays as-is. The bilingual comment in the file points to docs/Swift-Migration.md for the reasoning.

- CYLTabBarControllerGlobals.m defines the C globals declared FOUNDATION_EXTERN in CYLTabBarController.h: CYLTabbarItemsCount, CYLPlusButtonIndex, CYLTabBarItemWidth, and CYLTabBarHeight (default 49.0f).
- The file also defines three NSString notification constants: CYLTabBarItemLottieAnimationPlayingNotification, CYLTabBarItemLottieAnimationViewDidAddNotification, and CYLTabBarStyleTypeDidChangeNotification.
- The file carries a CYL-SWIFT-MIGRATION marker of objc-required, meaning it is excluded from the Swift conversion.
- Swift cannot export a data symbol, and @_cdecl only covers functions.
- Converting these globals to functions would break the public API that apps and the library read.
- The rationale is documented in docs/Swift-Migration.md under the class switch section.

Files read: CYLTabBarController\CYLTabBarControllerGlobals.m, CYLTabBarController/CYLTabBarControllerGlobals.m

Concepts: trade-off, gotcha

---

### #405 — Lottie tab animation view uses autoresizing mask to avoid tab bar platter stretch on iOS 27.1 (GitHub)
bugfix · 2026-11-28 12:04 UTC
CYLCompatibleLOTAnimationView fills its bounds via autoresizing instead of Auto Layout constraints, to keep the platter out of constraint solving.

The Lottie wrapper view used by tab bar items previously filled its superview with Auto Layout edge constraints. On iOS 27.1 with a folded iPhone Duo, that constraint set caused the tab bar platter to stretch over the content. The view now uses frame and autoresizing masks, which keeps the tab bar platter outside Auto Layout.

- CYLCompatibleLOTAnimationView.setUpViews sets translatesAutoresizingMaskIntoConstraints to true and autoresizingMask to flexibleWidth and flexibleHeight.
- The code comment marks this as FIX for issue #653.
- The view sits inside a tab button, and any Auto Layout constraint there pulls the tab bar platter into constraint solving.
- On iOS 27.1 with a folded iPhone Duo, the vertical bar stretched the platter over the content when constraints were used.
- The fix lives in CYLTabBarController/LottieSwift/CYLCompatibleLottie.swift.

Files read: CYLTabBarController\LottieSwift\CYLCompatibleLottie.swift, CYLTabBarController/LottieSwift/CYLCompatibleLottie.swift

Concepts: problem-solution, gotcha

---

### #406 — Objective-C compatible Lottie wrapper gains keypath-string color override and provider removal (GitHub)
feature · 2026-11-28 12:04 UTC
CYLCompatibleLOTAnimationView adds keypath-string color setting, value-provider removal, and Data-based animation loading for Objective-C callers.

The Objective-C compatible Lottie wrapper now lets callers recolor layers by keypath string and remove those overrides, which addresses issue #442. A new cylLoadAnimationData method lets callers load remotely downloaded Lottie JSON into the view and reports whether the data parsed as a Lottie animation. All of these are exposed with @objc for Objective-C callers.

- setColorValue(_:forKeypathString:) accepts a keypath string such as "Icon_Home_Normal.**.Color" and forwards to the CompatibleAnimationKeypath overload.
- removeValueProvider(forKeypathString:) removes the value provider for a keypath, restoring the animation's own value.
- Both keypath-string methods are marked as FIX for issue #442.
- cylLoadAnimationData(_:) loads a downloaded Lottie JSON Data into the view and returns false when the data is not a valid Lottie animation.
- cylLoadAnimationData(_:) is exported to Objective-C with the selector cylLoadAnimationData:.

Files read: CYLTabBarController\LottieSwift\CYLCompatibleLottie.swift, CYLTabBarController/LottieSwift/CYLCompatibleLottie.swift

Concepts: what-changed, pattern

---

### #444 — KVO-safe removeObserver wrappers stay in Objective-C during the Swift migration (GitHub)
discovery · 2026-11-28 12:04 UTC
The NSObject category keeps two Objective-C methods and CYLCatchException because Swift cannot catch Objective-C exceptions.

The CYLTabBarController repository (Windows session, branch feat/cross-platform-components) migrates its NSObject extension to Swift. This Objective-C file is the one part that cannot move. It guards KVO observer removal against NSException, which occurs when code removes an observer that was never registered. Swift has no way to catch Objective-C exceptions, so the two wrapper methods and CYLCatchException remain in Objective-C. Everything else in the category lives in the Swift file, and docs/Swift-Migration.md records the migration plan. The file is 49 lines long and was read in full at this point.

- NSObject+CYLTabBarControllerExtention.m defines the category NSObject (CYLTabBarControllerExtentionKVOSafety) with cyl_removeObserver:forKeyPath: and cyl_removeObserver:forKeyPath:context:.
- Both cyl_removeObserver methods wrap the underlying removeObserver call in @try/@catch and swallow the NSException.
- The catch blocks log exception.reason through NSLog only under DEBUG or BETA builds.
- The file exports a C function, CYLCatchException(NS_NOESCAPE void (^block)(void)), that runs a block inside @try/@catch and returns the caught NSException or nil.
- The header comment tags this file CYL-SWIFT-MIGRATION: objc-required because Swift cannot catch the exception that -removeObserver:forKeyPath: raises for an unregistered observer.
- The rest of the NSObject extension is implemented in Swift at Swift/NSObject+CYLTabBarControllerExtention.swift, documented in docs/Swift-Migration.md.
- The file's header comments are bilingual, with English and Chinese (CN) explanations.

Files read: CYLTabBarController\NSObject+CYLTabBarControllerExtention.m, CYLTabBarController/NSObject+CYLTabBarControllerExtention.m

Concepts: why-it-exists, gotcha, trade-off

---

### #445 — CYLBaseNavigationController is now an open Swift class that toggles tab bar visibility on stack changes (GitHub)
discovery · 2026-11-28 12:04 UTC
The navigation controller hides the tab bar for pushed pages and restores it at the root, via overrides of push and pop methods.

In the CYLTabBarController repository, the Swift migration has moved CYLBaseNavigationController from an Objective-C shell into an open Swift class. The class subclasses UINavigationController and overrides every stack-changing method: push, setViewControllers, popToRoot, pop, and popTo. Push runs a pre-hook (cylBaseNavigationWillPush) before the super call. The other overrides run the super call first and then call cylBaseNavigationToggleTabBarHidden() so the tab bar state matches the new stack. The actual hide/show behavior is implemented in the UINavigationController+CYLBaseNavigation.swift extension, which this file calls into.

- Swift/CYLBaseNavigationController.swift declares open class CYLBaseNavigationController: UINavigationController with the @objc(CYLBaseNavigationController) name.
- The class was promoted to an open Swift class at docs/Swift-Migration.md step 113 (phase ②), and was an Objective-C shell from step 102 until then.
- pushViewController(_:animated:) calls cylBaseNavigationWillPush(_:) before calling super.
- setViewControllers(_:animated:), popToRootViewController(animated:), popViewController(animated:), and popToViewController(_:animated:) each call super first and then cylBaseNavigationToggleTabBarHidden().
- The tab bar visibility logic lives in the extension file UINavigationController+CYLBaseNavigation.swift, which this class delegates to through the helper methods.
- The file is 49 lines long and was read in full.

Files read: CYLTabBarController\Swift\CYLBaseNavigationController.swift, CYLTabBarController/Swift/CYLBaseNavigationController.swift

Concepts: how-it-works, what-changed, pattern

---

### #446 — CYLBaseTableViewController forwards view lifecycle events to navigation-setting hooks and cleans up in deinit (GitHub)
discovery · 2026-11-28 12:04 UTC
The Swift table view controller counterpart of CYLBaseViewController routes appear, disappear, and dealloc events to cyl*NavigationSetting helpers.

In the CYLTabBarController repository, the table view base class follows the same Swift migration pattern as CYLBaseNavigationController. Each lifecycle override calls super first and then delegates to a navigation-setting helper. The helpers are defined in an extension, not in this file. The deinit path calls cylDeallocNavigationSetting(), so navigation state gets cleaned up when the controller is released. The class mirrors CYLBaseViewController, so the two base classes should stay in sync.

- Swift/CYLBaseTableViewController.swift declares open class CYLBaseTableViewController: UITableViewController with the @objc(CYLBaseTableViewController) name.
- The class is the table view controller counterpart of CYLBaseViewController and became an open Swift class at docs/Swift-Migration.md step 113 (phase ②).
- viewWillAppear(_:) calls super and then cylViewWillAppearNavigationSetting(_:).
- viewDidAppear(_:) calls super and then cylViewDidAppearNavigationSetting(_:).
- viewWillDisappear(_:) calls super and then cylViewWillDisappearNavigationSetting(_:).
- viewDidDisappear(_:) calls super and then cylViewDidDisappearNavigationSetting(_:).
- deinit calls cylDeallocNavigationSetting().
- The file is 43 lines long and was read in full.

Files read: CYLTabBarController\Swift\CYLBaseTableViewController.swift, CYLTabBarController/Swift/CYLBaseTableViewController.swift

Concepts: how-it-works, pattern, what-changed

---

### #447 — CYLBaseViewController is the Swift base view controller that applies navigation settings on appear and disappear (GitHub)
discovery · 2026-11-28 12:04 UTC
It forwards lifecycle events to cyl*NavigationSetting helpers, forces layout in viewDidLoad, and cleans up in deinit.

In the CYLTabBarController repository, CYLBaseViewController is the UIViewController counterpart of CYLBaseTableViewController. Both base classes pass each appear and disappear event to the same navigation-setting helpers, and both clean up through cylDeallocNavigationSetting() in deinit. The UIViewController version adds a viewDidLoad override that calls view.layoutIfNeeded(). The table view version has no viewDidLoad override. Subclasses in the cross-platform examples use these bases to get navigation-bar and pop-gesture behavior without writing it themselves.

- Swift/CYLBaseViewController.swift declares open class CYLBaseViewController: UIViewController with the @objc(CYLBaseViewController) name.
- The class applies cyl_navigationBarHidden, cyl_disablePopGestureRecognizer, and related navigation settings as the view appears and disappears.
- The class became an open Swift class at docs/Swift-Migration.md step 113 (phase ②), and subclasses are written in Swift per docs/Subclassing-In-Swift.md.
- viewDidLoad calls super.viewDidLoad() and then view.layoutIfNeeded().
- viewWillAppear(_:), viewDidAppear(_:), viewWillDisappear(_:), and viewDidDisappear(_:) each call super and then the matching cyl*NavigationSetting(_:) helper.
- deinit calls cylDeallocNavigationSetting().
- The file is 50 lines long and was read in full.

Files read: CYLTabBarController\Swift\CYLBaseViewController.swift, CYLTabBarController/Swift/CYLBaseViewController.swift

Concepts: how-it-works, pattern, why-it-exists

---

### #448 — CYLConstants ported from Objective-C to Swift, keeping C-callable exports for the header macros (GitHub)
change · 2026-11-28 12:04 UTC
The layout-scale, Liquid Glass, and tab animation helpers moved to Swift at migration step 114, and the placeholder size setter is exposed to Objective-C.

In the CYLTabBarController repository, CYLConstants moved from Objective-C to Swift at migration step 114. The class keeps its selectors and Swift names, and the CYLConstants.h macros reach the Swift code through @_cdecl C exports. The screen-ratio helpers compute their values once from the root window scene, which replaces the old +initialize approach. Objective-C callers can set the tab image placeholder size, since the header macros are read-only. The deprecated dark-mode Lottie methods now forward to the shared CYLTabBarItemAnimationStyleRegistry, and tab animation is enabled only when an animation library is present and an animation source is configured.

- Swift/CYLConstants.swift declares open class CYLConstants: NSObject with the @objc(CYLConstants) name, replacing the former CYLConstants.m, since docs/Swift-Migration.md step 114.
- The file declares public globals cylTabBarItemImagePlaceholderWidth and cylTabBarItemImagePlaceholderHeight, both defaulting to 22 points.
- Four @_cdecl exports keep C symbols for CYLConstants.h macros: CYLTabBarItemImagePlaceholderCurrentWidth, CYLTabBarItemImagePlaceholderCurrentHeight, CYLConstantsUIBasisWidthScale, and CYLConstantsUIBasisHeightScale.
- The private static cylBasisScales tuple reads the root window scene's screen bounds once, dividing by the 375 x 667 design size.
- uiBasisWidthScale() and uiBasisHeightScale() return the screen width/375 and height/667 ratios.
- tabBarItemImagePlaceholderSize is a settable class var that writes through to the two placeholder globals, so Objective-C can set it even though the macros are read-only.
- cyl_tabBarItemAnimationSizeValue(_:fromNormalImage:) returns the given size if non-zero, else the normal image size if non-zero, else the placeholder size.
- Five legacy dark-mode Lottie methods are marked deprecated and forward to CYLTabBarItemAnimationStyleRegistry.shared: cyl_registerDarkLottieURL, cyl_lottieURL, cyl_registerLottieDarkColors, cyl_lottieDarkColorsForLottieURL, and cyl_hasDarkLottie.
- isTabBarItemAnimationEnabled(with:tabBarItemsAttributes:) returns false unless CYLTabBarItemAnimationCore.service exists, then returns true if URLs are given or any tab's attributes contain a URL or file path animation key.
- The file is 225 lines long and was read in full.

Files read: CYLTabBarController\Swift\CYLConstants.swift, CYLTabBarController/Swift/CYLConstants.swift

Concepts: what-changed, how-it-works, gotcha

---

### #455 — CYLConstants+Keys.swift is the Swift catalog of CYLTabBarController configuration, attribute, and notification keys (GitHub)
discovery · 2026-11-28 12:04 UTC
A 1094-line Swift file on branch swift-core holds the string keys for tab items, plus buttons, skins, localization, routes, accessibility, and notifications.

In the CYLTabBarController repository, the Swift port of the constants header is now a single catalog of string keys. Callers pass these keys in configuration dictionaries, tab item attribute dictionaries, and notification userInfo. Because the string values are unchanged from Objective-C, existing configuration files keep working after the migration. The file groups the keys by feature: tab item attributes, configuration keys, plus button keys, interaction and appearance, skins, localization, config routes, pages and remote config, colors and fonts, accessibility, and notifications. It also documents the precedence rules, such as animation URL over file path and config keys over file keys.

- Swift/CYLConstants+Keys.swift is 1094 lines, imports Foundation, and conditionally imports CYLAnimatedItem; it was translated from Objective-C per docs/Swift-Migration.md on branch swift-core.
- Most public let constants have a string value equal to their name, for example cylTabBarItemTitle equals "CYLTabBarItemTitle".
- Tab item attributes cover titles, images, URLs, Lottie and PAG animation keys, colors, fonts, insets, and identifiers, and some are tied to fixed issues such as #433 for selected titles and #604 for generic animation keys.
- cylTabBarAnimationURL takes precedence over cylTabBarAnimationFilePath, and the file extension picks the animation library: .json for Lottie and .pag for PAG.
- cylTabBarControllerPageLookupOrder defaults to instance, resolver, shared, automatic, and cylTabBarControllerAutomaticPageRegistration defaults to YES.
- cylTabBarControllerPlusButton is registered for the config's context before the bar is created, and a plus button with an even tab count is recommended.
- Plus button keys include cylPlusButtonIndexInTabBar, cylPlusButtonSize, cylPlusButtonShowsSelection (default NO, always shown on Android), and cylPlusButtonKeepsTitleVisible.
- Skins are configured through cylTabBarControllerThemes, and values can reference named colors with the "@name" syntax, where "@@" yields a literal "@".
- cylTabBarControllerLocalization looks up {language}.lproj/{table}.strings, with the table name defaulting to "Localizable", and untranslated keys fall back to the key text.
- cylTabBarControllerConfigurationRoute and cylTabBarControllerManifestRoute load configuration from routes, and config keys override file keys.
- cylTabBarHostBadge* keys let CYLTabBarHostView, used by the React Native and Flutter wrappers, show badges on a single tab bar.
- Notification names include cylTabBarItemDidChange, cylTabBarItemTitleDidChange, cylTabBarItemIconDidChange, and cylTabBarControllerThemeDidApply, with userInfo keys for index sets and identifiers.
- The tool output was condensed because the original file was 67589 characters, so details of the elided text are not available here.

Files read: CYLTabBarController\Swift\CYLConstants+Keys.swift, CYLTabBarController/Swift/CYLConstants+Keys.swift

Concepts: how-it-works, what-changed, gotcha

---

### #470 — PAG tab animator stays in Objective-C as the registration entry point (GitHub)
discovery · 2026-11-28 12:04 UTC
CYLPAGTabBarItemAnimator.m keeps its +load registration in Objective-C because Swift has no +load, while the player and view loading move to Swift.

The PAG animator is the Objective-C entry point of the PAG tab-animation subspec. Swift has no +load, so the file that registers the animator with CYLTabBarItemAnimatorRegistry must remain Objective-C. The file is gated on CYL_PAG_AVAILABLE so it only compiles when libpag is included (the PAG subspec), which resolves issue #604. The animator exposes the PAG identifier, the .pag file extension, and the attribute-key mapping for light and dark URLs and file paths. Its view and player factory methods delegate to the Swift implementation.

- CYLPAGTabBarItemAnimator.m is the composition root of the PAG subspecs and stays Objective-C because its +load registers the animator before any tab is built.
- The PAG player and view loading live in CYLPAGTabBarItemAnimation.swift for the PAG subspec.
- CYLPAGTabBarItemAnimator implements identifier "PAG", fileExtensions @[@"pag"], and canAnimateFileAtURL: by matching the lowercased pathExtension to "pag".
- attributeKeys maps CYLTabBarAnimationURL, FilePath, Size, DarkURL, and DarkFilePath to the CYLTabBarPAG* keys.
- The whole file compiles to nothing unless CYL_PAG_AVAILABLE is set, which is the fix for issue #604.

Files read: CYLTabBarController\CYLTabBarItemAnimation\PAG\CYLPAGTabBarItemAnimator.m, CYLTabBarController/CYLTabBarController/CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.m

Concepts: how-it-works, why-it-exists

---

### #471 — PAG views render on the main thread on every target (GitHub)
decision · 2026-11-28 12:04 UTC
PAG rendering is forced to the main thread because per-view render threads stalled inside the simulator's software OpenGL and blocked the main thread.

The PAG view factory always renders on the main thread. A tab bar holds several small PAGViews, and with one render thread per view those threads deadlocked against the player lock inside the simulator's software OpenGL. The first main-thread call that needed the lock then blocked the UI, so icons stayed blank and did not play. Forcing synchronous rendering everywhere removes the simulator-only path, so simulator output matches what devices run.

- CYLPAGTabBarItemAnimationViews sets [pagView setSync:YES] for every platform and simulator.
- Earlier per-view render threads stalled inside the simulator's software OpenGL while holding the player lock.
- The first call needing that lock (-stop or -setHidden:) blocked the main thread, leaving blank icons and no playback.
- One rendering path on all targets means the simulator matches device behavior.

Files read: CYLTabBarController\CYLTabBarItemAnimation\PAG\CYLPAGTabBarItemAnimator.m, CYLTabBarController/CYLTabBarController/CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.m

Concepts: problem-solution, gotcha, trade-off

---

### #472 — PAG remote animations download to caches and fall back to static images (GitHub)
discovery · 2026-11-28 12:04 UTC
Remote .pag files download through the shared URL session, load on the main thread, and report failure back to the static image or placeholder.

When the animation URL is remote (http or https), the PAG view shows its static image or placeholder while the file downloads into the caches directory. On success the file is loaded on the main thread and playback is reported loaded. On HTTP errors, a missing download, or a load failure, the view reports failure and keeps the static image. The weak view reference prevents the completion from touching a view that has been released.

- cyl_loadRemoteURL:intoView: marks the PAGView as loading through CYLTabBarItemAnimationMarkLoading before the download starts.
- Downloads use [NSURLSession sharedSession] downloadTaskWithURL and move the file into the caches directory as cyl-pag-<hash>.pag.
- Responses with HTTP status 400 or higher are treated as failures and do not produce a file.
- Completion dispatches to the main queue, loads PAGFile, and calls CYLTabBarItemAnimationReportLoaded on success or CYLTabBarItemAnimationReportFailure with the error on failure.
- The PAGView is held through a weak reference, so the callback does nothing if the view has been deallocated.
- Local files load synchronously with [PAGFile Load:path] and [pagView setComposition:pagFile].

Files read: CYLTabBarController\CYLTabBarItemAnimation\PAG\CYLPAGTabBarItemAnimator.m, CYLTabBarController/CYLTabBarController/CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.m

Concepts: how-it-works, pattern

---

### #473 — PAG player separates two libpag configurations for the PAGEnterprise subspec (GitHub)
discovery · 2026-11-28 12:04 UTC
The Objective-C player and view loader are used only by CYLAnimatedItem/PAGEnterprise because libpag-enterprise's umbrella header breaks Swift imports.

The PAG animator compiles in two modes. The PAG subspec uses Swift for the player and view loader. The PAGEnterprise subspec uses an Objective-C copy with the same class names and methods, because libpag-enterprise's umbrella header references a header that does not exist, which blocks Swift from importing libpag. The enterprise subspec therefore builds with -fno-modules, and pod lib lint failure in CI run 44975115535 motivated the split.

- The CYL_PAG_OBJC_PLAYER branch keeps CYLPAGTabBarItemAnimationPlayer and CYLPAGTabBarItemAnimationViews in Objective-C only for the CYLAnimatedItem/PAGEnterprise subspec.
- Swift cannot import libpag from libpag-enterprise because its umbrella header includes the missing libpag/PAGView+Audio.h.
- The PAGEnterprise subspec also builds with -fno-modules, because pod lib lint failed in run 44975115535.
- The PAG subspec uses CYLPAGTabBarItemAnimation.swift for the same player and view classes, with matching class names and methods.

Files read: CYLTabBarController\CYLTabBarItemAnimation\PAG\CYLPAGTabBarItemAnimator.m, CYLTabBarController/CYLTabBarController/CYLTabBarItemAnimation/PAG/CYLPAGTabBarItemAnimator.m

Concepts: problem-solution, gotcha, trade-off
