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
    static BOOL result = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 27.0, *)) {
            result = YES;
        } else if (@available(iOS 26.0, *)) {
            result = ![[NSBundle.mainBundle objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"] boolValue];
        } else {
            result = NO;
        }
    });
    return result;
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
+ (NSURL *)cyl_getURLFromString:(NSString *)string {
    if (!string) {
        return nil;
    }
    NSURL *URL;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:string]){
        // URL = [NSURL URLWithString:string]; 会无法识别中文， 故改用 fileURLWithPath
        URL = [NSURL fileURLWithPath:string];
    }
    
    if (!URL) {
        return nil;
    }
    return URL;
}

+ (BOOL)isLottieEnabledFromlottieURLs:(NSMutableArray *)lottieURLs tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
#if __has_include(<Lottie/Lottie.h>)
    NSInteger lottieURLCount = lottieURLs.count;
    BOOL isLottieEnabled = lottieURLCount > 0 ;
    BOOL isLottieEnabledFromAttributes = NO;
    if (tabBarItemsAttributes && tabBarItemsAttributes.count > 0) {
        @try {
            isLottieEnabledFromAttributes = tabBarItemsAttributes[0][CYLTabBarLottieURL] || tabBarItemsAttributes[0][CYLTabBarLottieFilePath];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    }
    return isLottieEnabled || isLottieEnabledFromAttributes;
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)

    NSInteger lottieURLCount = lottieURLs.count;
    BOOL isLottieEnabled = lottieURLCount > 0 ;
    BOOL isLottieEnabledFromAttributes = NO;
    if (tabBarItemsAttributes && tabBarItemsAttributes.count > 0) {
        @try {
            isLottieEnabledFromAttributes = tabBarItemsAttributes[0][CYLTabBarLottieURL] || tabBarItemsAttributes[0][CYLTabBarLottieFilePath];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    }
    return isLottieEnabled || isLottieEnabledFromAttributes;
#endif
    return NO;
}

@end
