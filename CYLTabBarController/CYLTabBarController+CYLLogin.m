//
//  CYLTabBarController+CYLLogin.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Tabs that require login (issue #19).
//      Split out of CYLTabBarController.m without changes.
// [CN] 需要登录的 Tab（issue #19）。
//      从 CYLTabBarController.m 中拆分出来，内容未改动。

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"



#if CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#import "CYLFlatDesignTabBar.h"

#else
#endif


//#import "CYLFlatDesignTabBarItem.h"
//#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
//#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
//#import "CYLFlatDesignTabBarHideTabBar.h"


#if CYL_FLATDESIGN_AVAILABLE
//#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLFlatDesignTabBarItem.h>
#import <CYLTabBarController/UINavigationController+CYLFlatDesignTabBarPrivate.h>
#import <CYLTabBarController/_CYLFlatDesignTabBarParallaxOverlayView.h>
#import <CYLTabBarController/CYLFlatDesignTabBarHideTabBar.h>
#endif


#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
//#import <CYLTabBarController/UIImage+CYLTabBarControllerExtention.h>
//#import <CYLTabBarController/NSObject+CYLTabBarControllerExtention.h>
#else
//#import "CYLTabBarController.h"
//#import "UIImage+CYLTabBarControllerExtention.h"
//#import "NSObject+CYLTabBarControllerExtention.h"
#endif
#import "CYLTabBarController+CYLPrivate.h"

#pragma mark - CYLLogin (issue #19)

static NSString *const CYLTabBarLoggedInUserDefaultsKey = @"CYLTabBarControllerLoggedIn";
static char CYLLoginStateProviderKey;
static char CYLLoginRequiredTabBarItemIdentifiersKey;
static char CYLLoginRequiredBlockKey;
static char CYLLoginHandlerKey;
static char CYLLoginInterceptedViewControllerKey;

@implementation CYLTabBarController (CYLLogin)

- (BOOL)cyl_loggedIn {
    BOOL (^loginStateProvider)(void) = self.cyl_loginStateProvider;
    if (loginStateProvider) {
        return loginStateProvider();
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:CYLTabBarLoggedInUserDefaultsKey];
}

- (void)cyl_setLoggedIn:(BOOL)loggedIn {
    [[NSUserDefaults standardUserDefaults] setBool:loggedIn forKey:CYLTabBarLoggedInUserDefaultsKey];
    if (!loggedIn) {
        [self cyl_leaveTabRequiringLoginIfNeeded];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarLoginStateDidChangeNotification object:self];
}

- (BOOL (^)(void))cyl_loginStateProvider {
    return objc_getAssociatedObject(self, &CYLLoginStateProviderKey);
}

- (void)cyl_setLoginStateProvider:(BOOL (^)(void))loginStateProvider {
    objc_setAssociatedObject(self, &CYLLoginStateProviderKey, loginStateProvider, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray<NSString *> *)cyl_loginRequiredTabBarItemIdentifiers {
    return objc_getAssociatedObject(self, &CYLLoginRequiredTabBarItemIdentifiersKey);
}

- (void)cyl_setLoginRequiredTabBarItemIdentifiers:(NSArray<NSString *> *)loginRequiredTabBarItemIdentifiers {
    objc_setAssociatedObject(self, &CYLLoginRequiredTabBarItemIdentifiersKey, loginRequiredTabBarItemIdentifiers, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(CYLTabBarController *, UIViewController *))cyl_loginRequiredBlock {
    return objc_getAssociatedObject(self, &CYLLoginRequiredBlockKey);
}

- (void)cyl_setLoginRequiredBlock:(BOOL (^)(CYLTabBarController *, UIViewController *))loginRequiredBlock {
    objc_setAssociatedObject(self, &CYLLoginRequiredBlockKey, loginRequiredBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CYLTabBarController *, UIViewController *, CYLTabBarLoginCompletion))cyl_loginHandler {
    return objc_getAssociatedObject(self, &CYLLoginHandlerKey);
}

- (void)cyl_setLoginHandler:(void (^)(CYLTabBarController *, UIViewController *, CYLTabBarLoginCompletion))loginHandler {
    objc_setAssociatedObject(self, &CYLLoginHandlerKey, loginHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)cyl_isLoginRequiredForViewController:(UIViewController *)viewController {
    if (!viewController || viewController.cyl_isPlaceholder) {
        return NO;
    }
    BOOL (^loginRequiredBlock)(CYLTabBarController *, UIViewController *) = self.cyl_loginRequiredBlock;
    if (loginRequiredBlock) {
        return loginRequiredBlock(self, viewController);
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:requiresLoginToSelectViewController:)]) {
        return [delegate tabBarController:self requiresLoginToSelectViewController:viewController];
    }
    NSArray<NSString *> *identifiers = self.cyl_loginRequiredTabBarItemIdentifiers;
    NSString *identifier = viewController.cyl_tabBarItemIdentifier;
    return identifier.length > 0 && [identifiers containsObject:identifier];
}

- (BOOL)cyl_interceptLoginIfNeededForViewController:(UIViewController *)viewController {
    if (![self cyl_isLoginRequiredForViewController:viewController] || self.cyl_loggedIn) {
        return NO;
    }
    // One tap reaches here up to twice (`-tabBarController:shouldSelectViewController:`, then the tab button's action):
    // start the login only once per run loop turn. 一次点击最多到达这里两次：每个 runloop 只发起一次登录。
    if (objc_getAssociatedObject(self, &CYLLoginInterceptedViewControllerKey) == viewController) {
        return YES;
    }
    objc_setAssociatedObject(self, &CYLLoginInterceptedViewControllerKey, viewController, OBJC_ASSOCIATION_ASSIGN);
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            objc_setAssociatedObject(strongSelf, &CYLLoginInterceptedViewControllerKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
    });
    [self cyl_startLoginForViewController:viewController];
    return YES;
}

- (void)cyl_startLoginForViewController:(UIViewController *)viewController {
    __weak __typeof(self) weakSelf = self;
    __weak UIViewController *weakViewController = viewController;
    __block BOOL completed = NO;
    CYLTabBarLoginCompletion completion = ^(BOOL loggedIn) {
        void (^finish)(void) = ^{
            // Only the first call counts. 只有第一次调用有效。
            if (completed) {
                return;
            }
            completed = YES;
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            UIViewController *strongViewController = weakViewController;
            if (!strongSelf || !loggedIn) {
                return;
            }
            strongSelf.cyl_loggedIn = YES;
            NSUInteger index = strongViewController ? [strongSelf.viewControllers indexOfObject:strongViewController] : NSNotFound;
            if (index != NSNotFound) {
                strongSelf.selectedIndex = index;
            }
        };
        if ([NSThread isMainThread]) {
            finish();
        } else {
            dispatch_async(dispatch_get_main_queue(), finish);
        }
    };
    void (^loginHandler)(CYLTabBarController *, UIViewController *, CYLTabBarLoginCompletion) = self.cyl_loginHandler;
    if (loginHandler) {
        loginHandler(self, viewController, completion);
        return;
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:presentLoginForViewController:completion:)]) {
        [delegate tabBarController:self presentLoginForViewController:viewController completion:completion];
        return;
    }
#if defined(DEBUG) || defined(BETA)
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), CYLLocalizedString(@"需要登录的 Tab 被点击，但没有设置 cyl_loginHandler 或代理方法 -tabBarController:presentLoginForViewController:completion:。"));
#endif
}

/// Logged out on a tab that needs login: select the first tab that does not. 在需要登录的 Tab 上退出登录：切换到第一个不需要登录的 Tab。
- (void)cyl_leaveTabRequiringLoginIfNeeded {
    UIViewController *selectedViewController = self.selectedViewController;
    if (!selectedViewController || ![self cyl_isLoginRequiredForViewController:selectedViewController]) {
        return;
    }
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        UIViewController *viewController = viewControllers[index];
        if (!viewController.cyl_isPlaceholder && ![self cyl_isLoginRequiredForViewController:viewController]) {
            self.selectedIndex = index;
            return;
        }
    }
}

@end
