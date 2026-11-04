//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLConstants.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@implementation CYLConstants

static CGFloat _basisWidthScale = 1.0;
static CGFloat _basisHeightScale = 1.0;

CGFloat CYLTabBarItemImagePlaceholderWidth = 22.0f;
CGFloat CYLTabBarItemImagePlaceholderHeight = 22.0f;

+ (void)initialize {
    _basisWidthScale = CYLGetRootWindow().windowScene.screen.bounds.size.width / 375.0;
    _basisHeightScale = CYLGetRootWindow().windowScene.screen.bounds.size.height / 667.0;
}

+ (CGFloat)UIBasisWidthScale {
    return _basisWidthScale;
}

+ (CGFloat)UIBasisHeightScale {
    return _basisHeightScale;
}

+ (BOOL)isLiquidGlassActive {
    return [self isUsedLiquidGlass];
}

+ (BOOL)isUsedLiquidGlass {
    // FIX: issue #535 — one implementation, in CYLUtils, shared with CYLBadgeView. 唯一实现位于 CYLUtils，与 CYLBadgeView 共用。
    return [CYLUtils isLiquidGlassActive];
}

+ (NSValue *)cyl_getTureLottieSizeValue:(NSValue *)lottieSizeValue fromNormalImage:(UIImage *)normalImage {
    NSValue *tureLottieSizeValue = nil;
    do {
        if (!CGSizeEqualToSize(CGSizeZero, [lottieSizeValue CGSizeValue])) {
            tureLottieSizeValue = lottieSizeValue;
            break;
        }
        if (normalImage && !CGSizeEqualToSize(CGSizeZero, normalImage.size)) {
            tureLottieSizeValue = [NSValue valueWithCGSize:normalImage.size];
            break;
        }
        
        CGSize placeholderSize = CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
        tureLottieSizeValue = [NSValue valueWithCGSize:placeholderSize];
        break;
    } while (NO);
    return tureLottieSizeValue;
}


/*
- (NSArray<__kindof UIWindow *> *)cyl_windows {
    __block NSArray *windows = nil;
    [self.connectedScenes enumerateObjectsUsingBlock:^(UIScene *scene, BOOL *stop) {
        if ([scene isKindOfClass:UIWindowScene.class] && [scene.session.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
            windows = [(UIWindowScene *)scene windows];
            *stop = YES;
        }
    }];
    if (!windows || windows.count == 0) {
        windows = self.windows;
    }
    return windows ? : @[];
}
- (nullable __kindof UIWindow *)cyl_keyWindow {
    __block UIWindow *keyWindow = nil;
    [self.connectedScenes enumerateObjectsUsingBlock:^(UIScene *scene, BOOL *stop) {
        if ([scene isKindOfClass:UIWindowScene.class] && [scene.session.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
            [[(UIWindowScene *)scene windows] enumerateObjectsUsingBlock:^(UIWindow *window, NSUInteger idx, BOOL *substop) {
                if (window.isKeyWindow && !window.isHidden) {
                    keyWindow = window;
                    *substop = YES;
                }
            }];
            *stop = YES;
        }
    }];
    if (!keyWindow) {
        BeginIgnoreDeprecatedWarning
        keyWindow = self.keyWindow;
        EndIgnoreDeprecatedWarning
    }
    if (!keyWindow) {
        keyWindow = self.cyl_delegateWindow;
    }
    return keyWindow;
}
- (nullable __kindof UIWindow *)cyl_delegateWindow {
    __block UIWindow *delegateWindow = nil;
    [self.connectedScenes enumerateObjectsUsingBlock:^(UIScene *scene, BOOL *stop) {
        if ([scene isKindOfClass:UIWindowScene.class] && [scene.session.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
            if ([scene.delegate respondsToSelector:@selector(window)]) {
                delegateWindow = [scene.delegate performSelector:@selector(window)];
                *stop = YES;
            }
        }
    }];
    if (!delegateWindow && [self.delegate respondsToSelector:@selector(window)]) {
        delegateWindow = [self.delegate performSelector:@selector(window)];
    }
    return delegateWindow;
}

*/
#pragma mark - Dark Mode Lottie (#442)

/// Light Lottie URL (`absoluteString`) -> its dark version. Main thread only, like the tab bar that uses it.
static NSMutableDictionary<NSString *, NSURL *> *CYLDarkLottieURLs(void) {
    static NSMutableDictionary<NSString *, NSURL *> *darkLottieURLs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        darkLottieURLs = [NSMutableDictionary dictionary];
    });
    return darkLottieURLs;
}

+ (void)cyl_registerDarkLottieURL:(NSURL *)darkLottieURL forLottieURL:(NSURL *)lottieURL {
    NSString *key = [lottieURL isKindOfClass:[NSURL class]] ? lottieURL.absoluteString : nil;
    if (key.length == 0) {
        return;
    }
    // Only a real URL counts; anything else clears it. 只接受 NSURL，其他值视为清除。
    CYLDarkLottieURLs()[key] = [darkLottieURL isKindOfClass:[NSURL class]] ? darkLottieURL : nil;
}

+ (NSURL *)cyl_lottieURL:(NSURL *)lottieURL forTraitCollection:(UITraitCollection *)traitCollection {
    if (!lottieURL) {
        return nil;
    }
    if (@available(iOS 13.0, *)) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return CYLDarkLottieURLs()[lottieURL.absoluteString] ?: lottieURL;
        }
    }
    return lottieURL;
}

/// Light Lottie URL (`absoluteString`) -> keypath -> dark color (Lottie 4.x). Main thread only.
static NSMutableDictionary<NSString *, NSDictionary<NSString *, UIColor *> *> *CYLLottieDarkColors(void) {
    static NSMutableDictionary<NSString *, NSDictionary<NSString *, UIColor *> *> *lottieDarkColors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lottieDarkColors = [NSMutableDictionary dictionary];
    });
    return lottieDarkColors;
}

+ (void)cyl_registerLottieDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forLottieURL:(NSURL *)lottieURL {
    NSString *key = [lottieURL isKindOfClass:[NSURL class]] ? lottieURL.absoluteString : nil;
    if (key.length == 0) {
        return;
    }
    // Only keypath (non-empty NSString) -> UIColor pairs count. 只保留「非空 NSString keypath -> UIColor」。
    NSMutableDictionary<NSString *, UIColor *> *validColors = [NSMutableDictionary dictionary];
    if ([darkColors isKindOfClass:[NSDictionary class]]) {
        [darkColors enumerateKeysAndObjectsUsingBlock:^(id keypath, id color, BOOL *stop) {
            (void)stop;
            if ([keypath isKindOfClass:[NSString class]] && [(NSString *)keypath length] > 0 && [color isKindOfClass:[UIColor class]]) {
                validColors[keypath] = color;
            }
        }];
    }
    CYLLottieDarkColors()[key] = validColors.count > 0 ? [validColors copy] : nil;
}

+ (BOOL)cyl_hasDarkLottieForLottieURL:(NSURL *)lottieURL {
    NSString *key = [lottieURL isKindOfClass:[NSURL class]] ? lottieURL.absoluteString : nil;
    if (key.length == 0) {
        return NO;
    }
    return CYLDarkLottieURLs()[key] != nil || CYLLottieDarkColors()[key].count > 0;
}

+ (NSDictionary<NSString *, UIColor *> *)cyl_lottieDarkColorsForLottieURL:(NSURL *)lottieURL {
    NSString *key = lottieURL.absoluteString;
    return key.length > 0 ? CYLLottieDarkColors()[key] : nil;
}

+ (BOOL)cyl_hasDarkLottieURLs {
    return CYLDarkLottieURLs().count > 0 || CYLLottieDarkColors().count > 0;
}

+ (NSURL *)cyl_getURLFromString:(NSString *)string {
    if (!string) {
        return nil;
    }
    NSURL *URL;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:string]){
        // [CN] URL = [NSURL URLWithString:string]; 会无法识别中文， 故改用 fileURLWithPath
        // [EN] URL = [NSURL URLWithString:string]; cannot handle Chinese characters, so use fileURLWithPath instead
        URL = [NSURL fileURLWithPath:string];
    }
    
    if (!URL) {
        return nil;
    }
    return URL;
}

+ (BOOL)isLottieEnabledFromlottieURLs:(NSMutableArray *)lottieURLs tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    // Lottie ObjC (`<Lottie/Lottie.h>`) or Lottie Swift (`<Lottie/Lottie-Swift.h>`); without either, never enabled.
    // 引入 Lottie ObjC 或 Lottie Swift 之一时才可能启用；两者都没有时恒为 NO。
#if CYL_LOTTIE_AVAILABLE
    NSInteger lottieURLCount = lottieURLs.count;
    BOOL isLottieEnabled = lottieURLCount > 0 ;
    BOOL isLottieEnabledFromAttributes = NO;
    if (tabBarItemsAttributes && tabBarItemsAttributes.count > 0) {
        // [EN] Checked instead of `@try`: the first attributes entry must be a dictionary to be read.
        // [CN] 用检查代替 `@try`：第一个属性项必须是字典才读取。
        NSDictionary *firstAttributes = tabBarItemsAttributes.firstObject;
        if ([firstAttributes isKindOfClass:[NSDictionary class]]) {
            isLottieEnabledFromAttributes = firstAttributes[CYLTabBarLottieURL] || firstAttributes[CYLTabBarLottieFilePath];
        }
    }
    return isLottieEnabled || isLottieEnabledFromAttributes;
#else
    (void)lottieURLs;
    (void)tabBarItemsAttributes;
    return NO;
#endif
}

@end
