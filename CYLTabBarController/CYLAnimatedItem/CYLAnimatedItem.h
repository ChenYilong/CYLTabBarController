//
//  CYLAnimatedItem.h
//  CYLAnimatedItem
//
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

#import <CYLAnimatedItem/CYLAnimatedItemMacros.h>
#import <CYLAnimatedItem/CYLAnimationKeys.h>
#import <CYLAnimatedItem/CYLTabBarItemAnimator.h>
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>
#import <CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>
#import <CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>
#import <CYLAnimatedItem/CYLTabBarItemViewAnimator.h>
#import <CYLAnimatedItem/CYLGIFTabBarItemAnimator.h>
#import <CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>
#import <CYLAnimatedItem/CYLRiveTabBarItemAnimator.h>
#import <CYLAnimatedItem/CYLAnimatedItemView.h>
