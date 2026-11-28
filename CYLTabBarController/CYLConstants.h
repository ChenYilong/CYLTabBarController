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


// [EN] `CYLFlatDesignUITabBarControllerDelegate` is Swift since the class switch (FlatDesign subspec). [CN] 自类切换起为 Swift（扁平样式子库）。


/*!
 * [EN] `CYLTabBarStyleType` and `CYLTabBarMinimizeBehavior` are Swift since the class switch (`Swift/CYLTabBarControllerTypes.swift`).
 * [CN] `CYLTabBarStyleType` 与 `CYLTabBarMinimizeBehavior` 自类切换起为 Swift。
 */


#define CYLRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define CYLRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

/*!
 * [EN] `+[CYLConstants UIBasisWidthScale]` / `UIBasisHeightScale` as C functions (Swift, step 114), declared by the generated Swift
 *      interface imported at the end of this file (the header declarations went with the inline functions, phase 3).
 * [CN] 以 C 函数形式提供的 `+[CYLConstants UIBasisWidthScale]` / `UIBasisHeightScale`（Swift，第 114 步），由本文件末尾导入的生成 Swift 接口
 *      声明（头文件中的声明随内联函数一起删除，第 3 阶段）。
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


#import "CYLTabBarControllerSwiftInterface.h"

#endif /* CYLConstants_h */


