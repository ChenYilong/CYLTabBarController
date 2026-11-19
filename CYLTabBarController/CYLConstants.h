//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#ifndef CYLConstants_h
#define CYLConstants_h

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
// FIX: issue #535 — the feature checks and generic macros (CYL_FLATDESIGN_AVAILABLE, CYL_LOTTIE_AVAILABLE,
// CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS, CYL_IS_IOS_27...) live in CYLUtils, shared by Core and CYLBadgeView.
// 功能检测与通用宏位于 CYLUtils，由 Core 与 CYLBadgeView 共用。
#if __has_include("CYLUtils/CYLUtilsMacros.h")
#import "CYLUtils/CYLUtilsMacros.h"
#else
#import "CYLUtilsMacros.h"
#endif


// [CN] 必须在 flat design guard 之外，否则未引入 CYLFlatDesignTabBar 子库的
// subspec（如 LottieSwift）看不到该前向声明，会报 "expected a type"。
// [EN] Must be outside the flat design guard; otherwise subspecs that do not import the CYLFlatDesignTabBar subspec
//      (e.g. LottieSwift) cannot see this forward declaration and report "expected a type".
@class CYLTabBarController;

#if CYL_FLATDESIGN_AVAILABLE

@class CYLFlatDesignTabBar;

@protocol CYLFlatDesignUITabBarControllerDelegate <UITabBarControllerDelegate>

@optional

// tabBar show/hide only for CYLTabBarController

/*!
 * [EN] Flat design only. Called before the flat-design tab bar is shown.
 * [CN] 仅扁平化模式。扁平化 TabBar 即将显示时回调。
 */
- (void)tabBarController:(CYLTabBarController *)tabBarController willShowTabBar:(CYLFlatDesignTabBar *)tabBar;

/*!
 * [EN] Flat design only. Called after the flat-design tab bar is shown.
 * [CN] 仅扁平化模式。扁平化 TabBar 显示完成后回调。
 */
- (void)tabBarController:(CYLTabBarController *)tabBarController didShowTabBar:(CYLFlatDesignTabBar *)tabBar;

/*!
 * [EN] Flat design only. Called before the flat-design tab bar is hidden.
 * [CN] 仅扁平化模式。扁平化 TabBar 即将隐藏时回调。
 */
- (void)tabBarController:(CYLTabBarController *)tabBarController willHideTabBar:(CYLFlatDesignTabBar *)tabBar;

/*!
 * [EN] Flat design only. Called after the flat-design tab bar is hidden.
 * [CN] 仅扁平化模式。扁平化 TabBar 隐藏完成后回调。
 */
- (void)tabBarController:(CYLTabBarController *)tabBarController didHideTabBar:(CYLFlatDesignTabBar *)tabBar;

@end
#endif


/*!
 * [EN] The placeholder size of a tab image: read-only Swift variables since step 114, read by Objective-C through these macros;
 *      set it with `CYLConstants.tabBarItemImagePlaceholderSize`.
 * [CN] Tab 图片的占位尺寸：自第 114 步起为只读的 Swift 变量，Objective-C 通过这些宏读取；用 `CYLConstants.tabBarItemImagePlaceholderSize` 设置。
 */
#ifndef __swift__
#define CYLTabBarItemImagePlaceholderWidth (CYLTabBarItemImagePlaceholderCurrentWidth())
#define CYLTabBarItemImagePlaceholderHeight (CYLTabBarItemImagePlaceholderCurrentHeight())
#endif

typedef NS_ENUM(NSInteger, CYLTabBarStyleType) {
    CYLTabBarStyleTypeDefault = 0,
    CYLTabBarStyleTypeSystem,
    CYLTabBarStyleTypeFlatDesign,
    CYLTabBarStyleTypeLiquidGlass
};

/*!
 * [EN] How the tab bar reacts to scrolling (issue #13). One value for every style, set with
 *      `-[CYLTabBarController cyl_tabBarMinimizeBehavior]`:
 *      - Liquid Glass (iOS 26+): passed to the native `UITabBarController.tabBarMinimizeBehavior`; the system minimizes
 *        (shrinks) the tab bar, and the plus button is centered on its tab meanwhile.
 *      - FlatDesign: the tab bar is hidden and shown with `-setTabBarHidden:animated:` while the current page scrolls.
 *      - Classic tab bar (iOS 25 and earlier, and iOS 26 in UI compatibility mode): the system tab bar, with its plus
 *        button, is hidden and shown with `-setTabBarHidden:animated:` while the current page scrolls.
 *      The values match `UITabBarMinimizeBehavior` one to one.
 * [CN] TabBar 随滚动的变化方式（issue #13）。所有样式共用一个值，通过 `-[CYLTabBarController cyl_tabBarMinimizeBehavior]` 设置：
 *      - 液态玻璃（iOS 26+）：传给系统原生的 `UITabBarController.tabBarMinimizeBehavior`，由系统缩小 TabBar，期间 PlusButton 居中于它的 Tab。
 *      - 扁平样式：当前页面滚动时，通过 `-setTabBarHidden:animated:` 隐藏、显示 TabBar。
 *      - 经典 TabBar（iOS 25 及以前，以及 iOS 26 的 UI 兼容模式）：当前页面滚动时，用 `-setTabBarHidden:animated:` 隐藏、显示系统 TabBar（连同 PlusButton）。
 *      各个取值与 `UITabBarMinimizeBehavior` 一一对应。
 */
typedef NS_ENUM(NSInteger, CYLTabBarMinimizeBehavior) {
    /*!
     * [EN] Liquid Glass: the system default. FlatDesign and classic: same as Never.
     * [CN] 液态玻璃：系统默认行为。扁平样式与经典样式：等同于 Never。
     */
    CYLTabBarMinimizeBehaviorAutomatic = 0,
    /*!
     * [EN] The tab bar never minimizes or hides on scroll. [CN] 滚动时 TabBar 不缩小、不隐藏。
     */
    CYLTabBarMinimizeBehaviorNever,
    /*!
     * [EN] Minimizes (FlatDesign and classic: hides) when scrolling down, expands when scrolling back up.
     * [CN] 向下滚动时缩小（扁平样式与经典样式：隐藏），向上滚动时恢复。
     */
    CYLTabBarMinimizeBehaviorOnScrollDown,
    /*!
     * [EN] Minimizes (FlatDesign and classic: hides) when scrolling up, expands when scrolling back down; for content
     *      aligned to the bottom, such as a chat.
     * [CN] 向上滚动时缩小（扁平样式与经典样式：隐藏），向下滚动时恢复；适合底部对齐的内容，如聊天页面。
     */
    CYLTabBarMinimizeBehaviorOnScrollUp,
};


#define CYLRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define CYLRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

/*!
 * [EN] `+[CYLConstants UIBasisWidthScale]` / `UIBasisHeightScale` as C functions (Swift, step 114), so the inline functions
 *      below compile before the generated Swift interface is imported.
 * [CN] 以 C 函数形式提供的 `+[CYLConstants UIBasisWidthScale]` / `UIBasisHeightScale`（Swift，第 114 步），使下方的内联函数在导入生成的
 *      Swift 接口之前即可编译。
 */
#define CYLScale (CYLConstantsUIBasisWidthScale())
#define CYLHScale (CYLConstantsUIBasisHeightScale())

#define CYL_PERFORM_SELECTOR_BOOL(Target, SelectorName, Result) do { SEL action = @selector(SelectorName); if ([Target respondsToSelector:action]) { CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS( Result = ((BOOL (*)(id, SEL))[Target methodForSelector:action])(Target, action); ); } } while (0)

#define CYL_PERFORM_SELECTOR(Target, SelectorName) do { SEL action = @selector(SelectorName); if ([Target respondsToSelector:action]) { CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS( (( (*)(id, SEL))[Target methodForSelector:action])(Target, action); ); } } while (0)

#define CYL_PERFORM_SELECTOR_2OBJECT(Target, SelectorName, Obj1, Obj2) do { SEL action = @selector(SelectorName); if ([Target respondsToSelector:action]) { CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS( [Target performSelector:action withObject:Obj1 withObject:Obj2] ); } } while (0)


#define CYL_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define CYL_IF_NOT_FLATDESIGN_BEGIN if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType) {     //Not CYLTabBarStyleTypeFlatDesign
#define CYL_IF_NOT_FLATDESIGN_END } else { }

#define CYL_IF_FLATDESIGN_BEGIN if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#define CYL_IF_FLATDESIGN_END } else { }

#define CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26 CYL_IS_IOS_26 && (self.cyl_tabBarController.noNeedUIDesignCompatibility)


#define CYL_UIDesignOldVersionCYLTabBar ((!CYL_IS_IOS_26) || (![CYLConstants isUsedLiquidGlass]))
#define CYL_UIDesignOldVersionCYLTabBarOniOS26 ((CYL_IS_IOS_26) && (![CYLConstants isUsedLiquidGlass]))

#define CYL_UIDesignOldVersionCYLTabBarWithoutiOS26 ((!CYL_IS_IOS_26) && (![CYLConstants isUsedLiquidGlass]))
#define CYL_UIDesignClassicCYLTabBar CYL_UIDesignOldVersionCYLTabBar

/*!
 * [CN] TODO: 下个版本完善， 这个版本不推荐使用
 * [EN] TODO: To be improved in the next version; not recommended in this version
 */
#define CYL_UIDesignNewCYLTabBar (CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26)

/*!
 * [CN] TODO: 临时版本， 使用UITabBar重写
 * [EN] TODO: Temporary version, to be rewritten with UITabBar
 */
#define CYL_UIDesignNewPureCustomTabBar (CYL_IS_IOS_26) && (![[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"] boolValue]))

#define CYL_NoNeed_UIDesignRequiresCompatibility (self.cyl_tabBarController.noNeedUIDesignCompatibility)

#define CYL_requires_UIDesignRequiresCompatibility  CYL_UIDesignNewPureCustomTabBar

#define CYL_IS_IPHONE_X ((MIN(self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height) >= 375 && MAX(self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height) >= 812))


#pragma mark - Inline helpers

/*!
 * [EN] The helper functions (`CYLGetRootWindow()`, `CYLGetRootViewController()`, `CYLScreenWidth()`, `CYLScaleValue()`…, and the
 *      `cyl_is<Type>TypeEncoding()` / `cyl_is<Type>Ivar()` pairs) are Swift since step 133 (`Swift/CYLConstantsFunctions.swift`), with
 *      the same C names: they are declared by the generated Swift interface imported below.
 * [CN] 辅助函数（`CYLGetRootWindow()`、`CYLGetRootViewController()`、`CYLScreenWidth()`、`CYLScaleValue()`…，以及 `cyl_is<Type>TypeEncoding()` /
 *      `cyl_is<Type>Ivar()` 函数对）自第 133 步起为 Swift，C 名称不变：由下方导入的生成 Swift 接口声明。
 */


#import "CYLSwiftInterface.h"

#endif /* CYLConstants_h */


