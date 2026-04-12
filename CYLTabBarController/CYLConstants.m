//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLConstants.h"

@implementation CYLConstants

static CGFloat _basisWidthScale = 1.0;
static CGFloat _basisHeightScale = 1.0;

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

+ (BOOL)isUsedLiquidGlass {
    static BOOL result = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 26.0, *)) {
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
        CGSize placeholderSize = CGSizeMake(22, 22);
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
@end
