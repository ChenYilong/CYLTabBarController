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

@interface CYLConstants : NSObject

+ (CGFloat)UIBasisWidthScale;
+ (CGFloat)UIBasisHeightScale;
+ (BOOL)isUsedLiquidGlass;
+ (NSValue *)cyl_getTureLottieSizeValue:(NSValue *)lottieSizeValue fromNormalImage:(UIImage *)normalImage;

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

/*!
 *  屏幕尺寸  不是tabbar尺寸
 */
CG_INLINE CGSize CYLScreenSize(void) {
    CGSize size = CYLGetWindowScene().screen.bounds.size;
    if (size.width == 0 || size.height == 0) {
        size = [[UIScreen mainScreen] bounds].size;
    }
    return size;
}

CG_INLINE CGFloat CYLScreenWidth(void) {
    return CYLScreenSize().width;
}

CG_INLINE CGFloat CYLScreenHeight(void) {
    return CYLScreenSize().height;
}

#define CYLRGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define CYLRGBAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

#define CYLScale [CYLConstants UIBasisWidthScale]
#define CYLHScale [CYLConstants UIBasisHeightScale]

#define CYL_DEPRECATED(explain) __attribute__((deprecated(explain)))


#define CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wdeprecated-implementations\"")

#define CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP \
_Pragma("clang diagnostic pop")

#define CYL_DEPRECATED_DECLARATIONS_PUSH \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")

#define CYL_DEPRECATED_DECLARATIONS_POP \
_Pragma("clang diagnostic pop")


#define CYL_METHOD_SIGNATURES_PUSH \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wmethod-signatures\"")

#define CYL_METHOD_SIGNATURES_POP \
_Pragma("clang diagnostic pop")


#define CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
@try { \
Stuff; \
} @catch (NSException *exception) { \
NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", \
@(__PRETTY_FUNCTION__), @(__LINE__), exception.reason); \
} \
_Pragma("clang diagnostic pop") \
} while (0);


#define CYL_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

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

#define CYL_IS_IOS_11  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.f) && (@available(iOS 11.0, *))
#define CYL_IS_IOS_13  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13.f) && (@available(iOS 13.0, *))
#define CYL_IS_IOS_16  if (@available(iOS 16.0, *))

#define CYL_IS_IOS_26 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 26.f)

#define CYL_IS_IPHONE_X ((MIN(self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height) >= 375 && MAX(self.cyl_tabBarController.visiableTabBarSize.width, self.cyl_tabBarController.visiableTabBarSize.height) >= 812))

#define CYL_SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define CYL_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define CYL_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define CYL_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

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


