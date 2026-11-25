//
//  CYLAnimatedItem.h
//  CYLAnimatedItem
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The framework umbrella header: Xcode requires it, with the version symbols it exports; Swift cannot write a header. [CN] framework 伞头文件：Xcode 要求提供它及其导出的版本符号；Swift 不能编写头文件。
/*!
 * [EN] Umbrella header of the CYLAnimatedItem framework (the Carthage / Xcode framework target of CYLTabBarController.xcodeproj,
 *      docs/Animated-Item.md): the animated icon + title component, its animation keys and its engine. It never imports
 *      CYLTabBarController. CocoaPods generates its own umbrella header for the pod, and Swift Package Manager uses the module
 *      map in `include/`.
 * [CN] CYLAnimatedItem framework 的伞头文件（CYLTabBarController.xcodeproj 中供 Carthage / Xcode 使用的 framework target，
 *      docs/Animated-Item.md）：动效图标 + 标题组件、动画 key 与动画引擎。从不导入 CYLTabBarController。CocoaPods 会为该 pod
 *      生成自己的伞头文件，Swift Package Manager 使用 `include/` 中的 module map。
 */

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double CYLAnimatedItemVersionNumber;
FOUNDATION_EXPORT const unsigned char CYLAnimatedItemVersionString[];

// [EN] Each header only when it is part of the build: with CocoaPods this file is a public header of `CYLAnimatedItem/Core`,
//      which the pod's generated umbrella imports, and the engine and animator headers come only with their subspecs.
// [CN] 每个头文件只在参与构建时导入：使用 CocoaPods 时本文件是 `CYLAnimatedItem/Core` 的公开头文件，会被 pod 生成的伞头文件导入，
//      而引擎与 animator 的头文件只随各自的子库提供。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemMacros.h>)
#import <CYLAnimatedItem/CYLAnimatedItemMacros.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLAnimationKeys.h>)
#import <CYLAnimatedItem/CYLAnimationKeys.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimator.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimator.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationTint.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationTint.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemViewAnimator.h>)
#import <CYLAnimatedItem/CYLTabBarItemViewAnimator.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLGIFTabBarItemAnimator.h>)
#import <CYLAnimatedItem/CYLGIFTabBarItemAnimator.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>)
#import <CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLRiveTabBarItemAnimator.h>)
#import <CYLAnimatedItem/CYLRiveTabBarItemAnimator.h>
#endif
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemView.h>)
#import <CYLAnimatedItem/CYLAnimatedItemView.h>
#endif
