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

/*!
 * FIX: issue #442
 * [EN] The dark versions and dark colors registered for light animation URLs (`absoluteString`), kept in one instance
 *      instead of global dictionaries. It is Core's `CYLTabBarItemAnimationStyleSource`; the `CYLConstants` class methods
 *      below forward to it. Main thread only, like the tab bar that uses it.
 * [CN] 为浅色动画 URL（`absoluteString`）注册的深色版本与深色颜色，保存在一个实例中，而不是全局字典。它就是 Core 的
 *      `CYLTabBarItemAnimationStyleSource`；下面 `CYLConstants` 的类方法都转发给它。与使用它的 Tab 栏一样只在主线程使用。
 */
@interface CYLTabBarItemAnimationStyleRegistry : NSObject <CYLTabBarItemAnimationStyleSource>
- (void)registerDarkURL:(NSURL *)darkURL forURL:(NSURL *)URL;
- (void)registerDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forURL:(NSURL *)URL;
@end

@implementation CYLTabBarItemAnimationStyleRegistry {
    NSMutableDictionary<NSString *, NSURL *> *_darkURLs;
    NSMutableDictionary<NSString *, NSDictionary<NSString *, UIColor *> *> *_darkColors;
}

- (instancetype)init {
    if (self = [super init]) {
        _darkURLs = [NSMutableDictionary dictionary];
        _darkColors = [NSMutableDictionary dictionary];
    }
    return self;
}

static NSString *CYLTabBarItemAnimationStyleKey(NSURL *URL) {
    return [URL isKindOfClass:[NSURL class]] ? URL.absoluteString : nil;
}

- (void)registerDarkURL:(NSURL *)darkURL forURL:(NSURL *)URL {
    NSString *key = CYLTabBarItemAnimationStyleKey(URL);
    if (key.length == 0) {
        return;
    }
    // Only a real URL counts; anything else clears it. 只接受 NSURL，其他值视为清除。
    _darkURLs[key] = [darkURL isKindOfClass:[NSURL class]] ? darkURL : nil;
}

- (void)registerDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forURL:(NSURL *)URL {
    NSString *key = CYLTabBarItemAnimationStyleKey(URL);
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
    _darkColors[key] = validColors.count > 0 ? [validColors copy] : nil;
}

#pragma mark - CYLTabBarItemAnimationStyleSource

- (BOOL)hasStyleVariants {
    return _darkURLs.count > 0 || _darkColors.count > 0;
}

- (BOOL)hasStyleVariantForURL:(NSURL *)URL {
    NSString *key = CYLTabBarItemAnimationStyleKey(URL);
    return key.length > 0 && (_darkURLs[key] != nil || _darkColors[key].count > 0);
}

- (NSURL *)URL:(NSURL *)URL forTraitCollection:(UITraitCollection *)traitCollection {
    if (!URL) {
        return nil;
    }
    if (@available(iOS 13.0, *)) {
        NSString *key = CYLTabBarItemAnimationStyleKey(URL);
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark && key.length > 0) {
            return _darkURLs[key] ?: URL;
        }
    }
    return URL;
}

- (NSDictionary<NSString *, UIColor *> *)darkColorsForURL:(NSURL *)URL {
    NSString *key = CYLTabBarItemAnimationStyleKey(URL);
    return key.length > 0 ? _darkColors[key] : nil;
}

@end

/// [EN] Core's style source: the one style registry. [CN] Core 的风格来源：唯一的风格注册表。
static CYLTabBarItemAnimationStyleRegistry *CYLTabBarItemAnimationSharedStyleRegistry(void) {
    static CYLTabBarItemAnimationStyleRegistry *registry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registry = [[CYLTabBarItemAnimationStyleRegistry alloc] init];
    });
    return registry;
}

id<CYLTabBarItemAnimationStyleSource> CYLTabBarItemAnimationDefaultStyleSource(void) {
    return CYLTabBarItemAnimationSharedStyleRegistry();
}

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

+ (void)cyl_registerDarkLottieURL:(NSURL *)darkLottieURL forLottieURL:(NSURL *)lottieURL {
    [CYLTabBarItemAnimationSharedStyleRegistry() registerDarkURL:darkLottieURL forURL:lottieURL];
}

+ (NSURL *)cyl_lottieURL:(NSURL *)lottieURL forTraitCollection:(UITraitCollection *)traitCollection {
    return [CYLTabBarItemAnimationSharedStyleRegistry() URL:lottieURL forTraitCollection:traitCollection];
}

+ (void)cyl_registerLottieDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forLottieURL:(NSURL *)lottieURL {
    [CYLTabBarItemAnimationSharedStyleRegistry() registerDarkColors:darkColors forURL:lottieURL];
}

+ (BOOL)cyl_hasDarkLottieForLottieURL:(NSURL *)lottieURL {
    return [CYLTabBarItemAnimationSharedStyleRegistry() hasStyleVariantForURL:lottieURL];
}

+ (NSDictionary<NSString *, UIColor *> *)cyl_lottieDarkColorsForLottieURL:(NSURL *)lottieURL {
    return [CYLTabBarItemAnimationSharedStyleRegistry() darkColorsForURL:lottieURL];
}

+ (BOOL)cyl_hasDarkLottieURLs {
    return [CYLTabBarItemAnimationSharedStyleRegistry() hasStyleVariants];
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

/// FIX: issue #604 — YES when `attributes` give an animation file of any library in the build (generic keys, or each
/// library's own keys). `attributes` 中设置了构建中任意动画库的文件时返回 YES（通用 key，或各动画库自己的 key）。
static BOOL CYLTabBarItemAttributesHaveAnimationFile(NSDictionary *attributes) {
    return CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationURL) != nil ||
           CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationFilePath) != nil;
}

+ (BOOL)isLottieEnabledFromlottieURLs:(NSMutableArray *)lottieURLs tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    // FIX: issue #604 — only with an animation library, i.e. the `CYLTabBarItemAnimation` service, checked at runtime
    // so that any library works (Lottie, PAG or one added later); without one, never enabled.
    // 仅在引入动画库（即 `CYLTabBarItemAnimation` 服务）时启用，在运行时判断，以支持任意动画库（Lottie、PAG 或以后新增的库）；没有时恒为 NO。
    if (!CYLTabBarItemAnimationIsAvailable()) {
        return NO;
    }
    NSInteger lottieURLCount = lottieURLs.count;
    BOOL isLottieEnabled = lottieURLCount > 0 ;
    BOOL isLottieEnabledFromAttributes = NO;
    if (tabBarItemsAttributes && tabBarItemsAttributes.count > 0) {
        @try {
            // FIX: issue #477 — any tab, not only the first: only some tabs may have an animation.
            // 任意一个 Tab，而不只是第一个：可能只有部分 Tab 有动画。
            for (NSDictionary *item in tabBarItemsAttributes) {
                if ([item isKindOfClass:[NSDictionary class]] && CYLTabBarItemAttributesHaveAnimationFile(item)) {
                    isLottieEnabledFromAttributes = YES;
                    break;
                }
            }
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    }
    return isLottieEnabled || isLottieEnabledFromAttributes;
}

@end
