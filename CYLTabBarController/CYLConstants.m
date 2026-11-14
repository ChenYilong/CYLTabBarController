//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLConstants.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

/*
 * FIX: issue #442
 * [EN] The style registry (dark URLs and colors of tab icon animations) is Swift
 *      (`Swift/CYLTabBarItemAnimationStyleRegistry.swift`, docs/Swift-Migration.md, step 45); the deprecated Lottie class
 *      methods below forward to it through these private C functions.
 * [CN] 风格注册表（Tab 图标动画的深色 URL 与颜色）已迁移到 Swift（`Swift/CYLTabBarItemAnimationStyleRegistry.swift`，
 *      docs/Swift-Migration.md，第 45 步）；下面已弃用的 Lottie 类方法通过这些私有 C 函数转发给它。
 */
FOUNDATION_EXTERN void CYLTabBarItemAnimationRegisterDarkURL(NSURL *_Nullable URL, NSURL *_Nullable darkURL);
FOUNDATION_EXTERN void CYLTabBarItemAnimationRegisterDarkColors(NSURL *_Nullable URL, NSDictionary *_Nullable darkColors);

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

// [EN] Deprecated Lottie names kept for compatibility: implemented here, forwarding to the neutral API.
// [CN] 为兼容保留的已废弃 Lottie 名称：在此实现，并转发给通用 API。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (NSValue *)cyl_getTureLottieSizeValue:(NSValue *)lottieSizeValue fromNormalImage:(UIImage *)normalImage {
    return [self cyl_tabBarItemAnimationSizeValue:lottieSizeValue fromNormalImage:normalImage];
}

#pragma clang diagnostic pop

+ (NSValue *)cyl_tabBarItemAnimationSizeValue:(NSValue *)lottieSizeValue fromNormalImage:(UIImage *)normalImage {
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

// [EN] Deprecated Lottie names kept for compatibility: implemented here, forwarding to the neutral API.
// [CN] 为兼容保留的已废弃 Lottie 名称：在此实现，并转发给通用 API。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (void)cyl_registerDarkLottieURL:(NSURL *)darkLottieURL forLottieURL:(NSURL *)lottieURL {
    CYLTabBarItemAnimationRegisterDarkURL(lottieURL, darkLottieURL);
}

+ (NSURL *)cyl_lottieURL:(NSURL *)lottieURL forTraitCollection:(UITraitCollection *)traitCollection {
    return [CYLTabBarItemAnimationDefaultStyleSource() URL:lottieURL forTraitCollection:traitCollection];
}

+ (void)cyl_registerLottieDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forLottieURL:(NSURL *)lottieURL {
    CYLTabBarItemAnimationRegisterDarkColors(lottieURL, darkColors);
}

+ (BOOL)cyl_hasDarkLottieForLottieURL:(NSURL *)lottieURL {
    return [CYLTabBarItemAnimationDefaultStyleSource() hasStyleVariantForURL:lottieURL];
}

+ (NSDictionary<NSString *, UIColor *> *)cyl_lottieDarkColorsForLottieURL:(NSURL *)lottieURL {
    return [CYLTabBarItemAnimationDefaultStyleSource() darkColorsForURL:lottieURL];
}

+ (BOOL)cyl_hasDarkLottieURLs {
    return [CYLTabBarItemAnimationDefaultStyleSource() hasStyleVariants];
}

#pragma clang diagnostic pop

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

/// FIX: issue #604 — YES when `attributes` give an animation file of any library in the build (generic keys, or each
/// library's own keys). `attributes` 中设置了构建中任意动画库的文件时返回 YES（通用 key，或各动画库自己的 key）。
static BOOL CYLTabBarItemAttributesHaveAnimationFile(NSDictionary *attributes) {
    return CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationURL) != nil ||
           CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationFilePath) != nil;
}

// [EN] Deprecated Lottie names kept for compatibility: implemented here, forwarding to the neutral API.
// [CN] 为兼容保留的已废弃 Lottie 名称：在此实现，并转发给通用 API。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (BOOL)isLottieEnabledFromlottieURLs:(NSMutableArray *)lottieURLs tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    return [self isTabBarItemAnimationEnabledWithURLs:lottieURLs tabBarItemsAttributes:tabBarItemsAttributes];
}

#pragma clang diagnostic pop

+ (BOOL)isTabBarItemAnimationEnabledWithURLs:(NSArray<NSURL *> *)URLs tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    // FIX: issue #604 — only with an animation library, i.e. the `CYLTabBarItemAnimation` service, checked at runtime
    // so that any library works (Lottie, PAG or one added later); without one, never enabled.
    // 仅在引入动画库（即 `CYLTabBarItemAnimation` 服务）时启用，在运行时判断，以支持任意动画库（Lottie、PAG 或以后新增的库）；没有时恒为 NO。
    if (!CYLTabBarItemAnimationIsAvailable()) {
        return NO;
    }
    NSInteger URLCount = URLs.count;
    BOOL isLottieEnabled = URLCount > 0 ;
    BOOL isLottieEnabledFromAttributes = NO;
    if (tabBarItemsAttributes && tabBarItemsAttributes.count > 0) {
        // [EN] Checked instead of `@try`: only dictionaries are read. FIX: issue #477 — any tab, not only the first: only
        //      some tabs may have an animation, of any library (Lottie, PAG, Rive).
        // [CN] 用检查代替 `@try`：只读取字典。任意一个 Tab，而不只是第一个：可能只有部分 Tab 有动画，且可以是任一动画库（Lottie、PAG、Rive）。
        for (NSDictionary *item in tabBarItemsAttributes) {
            if ([item isKindOfClass:[NSDictionary class]] && CYLTabBarItemAttributesHaveAnimationFile(item)) {
                isLottieEnabledFromAttributes = YES;
                break;
            }
        }
    }
    return isLottieEnabled || isLottieEnabledFromAttributes;
}

@end
