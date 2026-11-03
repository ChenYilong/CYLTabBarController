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


// 必须在 flat design guard 之外，否则未引入 CYLFlatDesignTabBar 子库的
// subspec（如 LottieSwift）看不到该前向声明，会报 "expected a type"。
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


FOUNDATION_EXTERN CGFloat CYLTabBarItemImagePlaceholderWidth;
FOUNDATION_EXTERN CGFloat CYLTabBarItemImagePlaceholderHeight;

typedef NS_ENUM(NSInteger, CYLTabBarStyleType) {
    CYLTabBarStyleTypeDefault = 0,
    CYLTabBarStyleTypeSystem,
    CYLTabBarStyleTypeFlatDesign,
    CYLTabBarStyleTypeLiquidGlass
};

@interface CYLConstants : NSObject

/*!
 * [EN] Returns the screen width divided by 375 (the iPhone 8 design width), for scaling layouts.
 * [CN] 返回屏幕宽度与 375（iPhone 8 设计稿宽度）的比例，用于等比适配布局。
 */
+ (CGFloat)UIBasisWidthScale;

/*!
 * [EN] Returns the screen height divided by 667 (the iPhone 8 design height), for scaling layouts.
 * [CN] 返回屏幕高度与 667（iPhone 8 设计稿高度）的比例，用于等比适配布局。
 */
+ (CGFloat)UIBasisHeightScale;

/*!
 * Liquid Glass, same as `+isUsedLiquidGlass`.
 * @return YES  if iOS Version > iOS 27.0
 * [EN] Returns YES if Liquid Glass is in use: always on iOS 27+, on iOS 26 unless `UIDesignRequiresCompatibility` is YES in Info.plist, never below iOS 26.
 * [CN] 判断是否启用了液态玻璃：iOS 27+ 始终为 YES；iOS 26 下除非 Info.plist 中 UIDesignRequiresCompatibility 为 YES；iOS 26 以下始终为 NO。
 */
+ (BOOL)isLiquidGlassActive;

/*!
 * Liquid Glass, same as `+isLiquidGlassActive`
 * @return YES  if iOS Version > iOS 27.0
 * [EN] Same as `+isLiquidGlassActive`; the result is computed once and cached.
 * [CN] 同 +isLiquidGlassActive，结果只计算一次并缓存。
 */
+ (BOOL)isUsedLiquidGlass;

/*!
 * [EN] Returns the Lottie size to use: `lottieSizeValue` if non-zero, else the normal image size, else the default placeholder size.
 * [CN] 返回实际使用的 Lottie 尺寸：优先 lottieSizeValue（非零），其次普通图片尺寸，最后使用默认占位尺寸。
 */
+ (NSValue *)cyl_getTureLottieSizeValue:(NSValue *)lottieSizeValue fromNormalImage:(UIImage *)normalImage;

/*!
 * [EN] Returns a file URL for a local file path, or nil if the file does not exist.
 * [CN] 将本地文件路径转换为文件 URL，文件不存在时返回 nil。
 */
+ (NSURL *)cyl_getURLFromString:(NSString *)string;

/*!
 * FIX: issue #442
 * [EN] Registers `darkLottieURL` as the Dark Mode version of the Lottie animation at `lottieURL` (nil removes it).
 *      `CYLTabBarLottieDarkURL` / `CYLTabBarLottieDarkFilePath` in `tabBarItemsAttributes` call it for you.
 * [CN] 将 `darkLottieURL` 注册为 `lottieURL` 处 Lottie 动画的深色模式版本（传 nil 移除）。`tabBarItemsAttributes` 中的
 *      `CYLTabBarLottieDarkURL` / `CYLTabBarLottieDarkFilePath` 会自动调用。
 */
+ (void)cyl_registerDarkLottieURL:(NSURL *)darkLottieURL forLottieURL:(NSURL *)lottieURL;

/*!
 * [EN] The Lottie animation to show for `traitCollection`: the registered dark version where the style is dark,
 *      `lottieURL` otherwise (and always before iOS 13). nil `lottieURL` returns nil; nil `traitCollection` means light.
 * [CN] 在 `traitCollection` 下应显示的 Lottie 动画：风格为深色时返回已注册的深色版本，否则（以及 iOS 13 以下）返回 `lottieURL`。
 *      `lottieURL` 为 nil 时返回 nil；`traitCollection` 为 nil 时按浅色处理。
 */
+ (NSURL *)cyl_lottieURL:(NSURL *)lottieURL forTraitCollection:(UITraitCollection *)traitCollection;

/*!
 * FIX: issue #442 (Lottie 4.x)
 * [EN] Registers `darkColors` (keypath -> UIColor) for the Lottie animation at `lottieURL`: one animation file that
 *      follows Dark Mode (nil removes them). `CYLTabBarLottieDarkColors` in `tabBarItemsAttributes` calls it for you.
 * [CN] 为 `lottieURL` 处的 Lottie 动画注册 `darkColors`（keypath -> UIColor）：一份动画文件即可适配深色模式（传 nil 移除）。
 *      `tabBarItemsAttributes` 中的 `CYLTabBarLottieDarkColors` 会自动调用。
 */
+ (void)cyl_registerLottieDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forLottieURL:(NSURL *)lottieURL;

/*!
 * [EN] The dark colors registered for `lottieURL`, nil when there are none.
 * [CN] 为 `lottieURL` 注册的深色颜色，没有时为 nil。
 */
+ (NSDictionary<NSString *, UIColor *> *)cyl_lottieDarkColorsForLottieURL:(NSURL *)lottieURL;

/*!
 * [EN] YES once a dark Lottie animation or dark Lottie colors have been registered: only then does a change of style
 *      reload Lottie icons.
 * [CN] 注册过深色 Lottie 动画或深色 Lottie 颜色后为 YES：只有这时切换深浅色才会重新加载 Lottie 图标。
 */
+ (BOOL)cyl_hasDarkLottieURLs;

/*!
 * [EN] YES when a dark animation or dark colors are registered for `lottieURL`. Lottie icons without them never run
 *      any of the #442 code.
 * [CN] 为 `lottieURL` 注册了深色动画或深色颜色时为 YES。没有注册的 Lottie 图标不会执行任何 #442 相关代码。
 */
+ (BOOL)cyl_hasDarkLottieForLottieURL:(NSURL *)lottieURL;

/*!
 * [EN] Returns YES if Lottie is linked and either `lottieURLs` is non-empty or the first item attributes specify a Lottie URL or file path.
 * [CN] 判断是否启用 Lottie：需集成 Lottie，且 lottieURLs 非空或第一个 TabBarItem 属性中指定了 Lottie URL / 文件路径。
 */
+ (BOOL)isLottieEnabledFromlottieURLs:(NSMutableArray *)lottieURLs tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

@end

CG_INLINE UIWindowScene *CYLGetWindowScene(void) {
    UIWindowScene *windowScene = nil;
    
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* wScene in [UIApplication sharedApplication].connectedScenes) {
            if (wScene.activationState == UISceneActivationStateForegroundActive) {
                windowScene = wScene;
                break;
            }
        }
    }
    return windowScene;
}

CG_INLINE UIWindow *CYLGetRootWindow(void) {
    UIWindow *window = nil;
    if ([UIApplication.sharedApplication.delegate respondsToSelector:@selector(window)]) {
        //兼容新版项目结构，也就是AppDelegate没有window的情况
        window = UIApplication.sharedApplication.delegate.window;
    }
    if (window) {
        return window;
    }
    if (@available(iOS 13.0, *)) {
        UIWindowScene* wScene = CYLGetWindowScene();
        if (wScene) {
            window = wScene.windows.firstObject;
        }
    }
    return window;
}

CG_INLINE UIViewController *CYLGetRootViewController(void) {
    UIViewController *rootViewController ;
    UIWindow *window = CYLGetRootWindow();
    if (window) {
        rootViewController = window.rootViewController;
        UIViewController *topVC = rootViewController;
        while (topVC.presentedViewController) {
            topVC = topVC.presentedViewController;
        }
        
        if (!topVC) { return nil; }
        rootViewController = topVC;
    }
    
    return rootViewController;
}

CG_INLINE CGFloat CYLGetTabBarFullH(CGFloat baseTabBarHeight) {
    CGFloat bottom = CYLGetRootWindow().safeAreaInsets.bottom;
    if (bottom > 0) {
        return  baseTabBarHeight + CYLGetRootWindow().safeAreaInsets.bottom;
    } else {
        return baseTabBarHeight;
    }
}

#define CYLRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define CYLRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

#define CYLScale [CYLConstants UIBasisWidthScale]
#define CYLHScale [CYLConstants UIBasisHeightScale]

#define CYL_PERFORM_SELECTOR_BOOL(Target, SelectorName, Result) \
do { \
    SEL action = @selector(SelectorName); \
    if ([Target respondsToSelector:action]) { \
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS( \
            Result = ((BOOL (*)(id, SEL))[Target methodForSelector:action])(Target, action); \
        ); \
    } \
} while (0)

#define CYL_PERFORM_SELECTOR(Target, SelectorName) \
do { \
    SEL action = @selector(SelectorName); \
    if ([Target respondsToSelector:action]) { \
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS( \
            (( (*)(id, SEL))[Target methodForSelector:action])(Target, action); \
        ); \
    } \
} while (0)

#define CYL_PERFORM_SELECTOR_2OBJECT(Target, SelectorName, Obj1, Obj2) \
do { \
    SEL action = @selector(SelectorName); \
    if ([Target respondsToSelector:action]) { \
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS( \
            [Target performSelector:action withObject:Obj1 withObject:Obj2]\
        ); \
    } \
} while (0)


#define CYL_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define CYL_IF_NOT_FLATDESIGN_BEGIN if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType) {     //Not CYLTabBarStyleTypeFlatDesign
#define CYL_IF_NOT_FLATDESIGN_END } else { \
}

#define CYL_IF_FLATDESIGN_BEGIN if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) { \

#define CYL_IF_FLATDESIGN_END } else { \
    }

#define CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26 CYL_IS_IOS_26 && (self.cyl_tabBarController.noNeedUIDesignCompatibility)


#define CYL_UIDesignOldVersionCYLTabBar ((!CYL_IS_IOS_26) || (![CYLConstants isUsedLiquidGlass]))
#define CYL_UIDesignOldVersionCYLTabBarOniOS26 ((CYL_IS_IOS_26) && (![CYLConstants isUsedLiquidGlass]))

#define CYL_UIDesignOldVersionCYLTabBarWithoutiOS26 ((!CYL_IS_IOS_26) && (![CYLConstants isUsedLiquidGlass]))
#define CYL_UIDesignClassicCYLTabBar CYL_UIDesignOldVersionCYLTabBar

//TODO: 下个版本完善， 这个版本不推荐使用
#define CYL_UIDesignNewCYLTabBar (CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26)

//TODO: 临时版本， 使用UITabBar重写
#define CYL_UIDesignNewPureCustomTabBar (CYL_IS_IOS_26) && (![[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"] boolValue]))

#define CYL_NoNeed_UIDesignRequiresCompatibility (self.cyl_tabBarController.noNeedUIDesignCompatibility)

#define CYL_requires_UIDesignRequiresCompatibility  CYL_UIDesignNewPureCustomTabBar

#define CYL_IS_IPHONE_X ((MIN(self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height) >= 375 && MAX(self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height) >= 812))

/*!
 *  屏幕尺寸  不是tabbar尺寸
 */
CG_INLINE CGSize CYLScreenSize(void) {
    CGSize size = CYLGetWindowScene().screen.bounds.size;
    if (size.width == 0 || size.height == 0) {
        CYL_DEPRECATED_DECLARATIONS_PUSH
        size = [[UIScreen mainScreen] bounds].size;
        CYL_DEPRECATED_DECLARATIONS_POP
    }
    return size;
}

CG_INLINE CGFloat CYLScreenWidth(void) {
    return CYLScreenSize().width;
}

CG_INLINE CGFloat CYLScreenHeight(void) {
    return CYLScreenSize().height;
}

CG_INLINE CGFloat CYLScaleValue(CGFloat value) {
    return value * CYLScale;
}

CG_INLINE CGFloat CYLHScaleValue(CGFloat value) {
    return value * CYLHScale;
}

CG_INLINE UIFont * CYLScaleFont(CGFloat fontSize)  {
    return [UIFont systemFontOfSize:CYLScaleValue(fontSize)];
}

CG_INLINE UIFont * CYLScaleBoldFont(CGFloat fontSize) {
    return [UIFont boldSystemFontOfSize:CYLScaleValue(fontSize)];
}

/**
 * 判断两个字符串是否相等（两个都为 nil 也算相等）
 */
CG_INLINE BOOL CYLStringEqual(NSString *a, NSString *b) {
    return (a == b) || [a isEqualToString:b];
}

CG_INLINE CGFloat CYLHalfOfDiff(CGFloat value1, CGFloat value2) {
    return (value1 - value2) * 0.5;
}
#pragma mark - Ivar

/**
 用于判断一个给定的 type encoding（const char *）或者 Ivar 是哪种类型的系列函数。
 
 为了节省代码量，函数由宏展开生成，一个宏会展开为两个函数定义：
 
 1. isXxxTypeEncoding(const char *)，例如判断是否为 BOOL 类型的函数名为：isBOOLTypeEncoding()
 2. isXxxIvar(Ivar)，例如判断是否为 BOOL 的 Ivar 的函数名为：isBOOLIvar()
 
 @see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
 */
#define _CYLTypeEncodingDetectorGenerator(_TypeInFunctionName, _typeForEncode) \
    CG_INLINE BOOL cyl_is##_TypeInFunctionName##TypeEncoding(const char *typeEncoding) {\
        return strncmp(@encode(_typeForEncode), typeEncoding, strlen(@encode(_typeForEncode))) == 0;\
    }\
    CG_INLINE BOOL cyl_is##_TypeInFunctionName##Ivar(Ivar ivar) {\
        return cyl_is##_TypeInFunctionName##TypeEncoding(ivar_getTypeEncoding(ivar));\
    }

_CYLTypeEncodingDetectorGenerator(Char, char)
_CYLTypeEncodingDetectorGenerator(Int, int)
_CYLTypeEncodingDetectorGenerator(Short, short)
_CYLTypeEncodingDetectorGenerator(Long, long)
_CYLTypeEncodingDetectorGenerator(LongLong, long long)
_CYLTypeEncodingDetectorGenerator(NSInteger, NSInteger)
_CYLTypeEncodingDetectorGenerator(UnsignedChar, unsigned char)
_CYLTypeEncodingDetectorGenerator(UnsignedInt, unsigned int)
_CYLTypeEncodingDetectorGenerator(UnsignedShort, unsigned short)
_CYLTypeEncodingDetectorGenerator(UnsignedLong, unsigned long)
_CYLTypeEncodingDetectorGenerator(UnsignedLongLong, unsigned long long)
_CYLTypeEncodingDetectorGenerator(NSUInteger, NSUInteger)
_CYLTypeEncodingDetectorGenerator(Float, float)
_CYLTypeEncodingDetectorGenerator(Double, double)
_CYLTypeEncodingDetectorGenerator(CGFloat, CGFloat)
_CYLTypeEncodingDetectorGenerator(BOOL, BOOL)
_CYLTypeEncodingDetectorGenerator(Void, void)
_CYLTypeEncodingDetectorGenerator(Character, char *)
_CYLTypeEncodingDetectorGenerator(Object, id)
_CYLTypeEncodingDetectorGenerator(Class, Class)
_CYLTypeEncodingDetectorGenerator(Selector, SEL)

#endif /* CYLConstants_h */


