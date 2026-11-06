//
//  CYLThemeManager.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLThemeManager.h"
#import "CYLThemePrivate.h"
#import "UIView+CYLTheme.h"
#import "UIViewController+CYLTheme.h"
#import "CALayer+CYLTheme.h"

NSNotificationName const CYLThemeDidChangeNotification = @"CYLThemeDidChangeNotification";

/*!
 * [EN] The windows of the app: those of every connected window scene (iOS 13+), else `UIApplication.windows`.
 * [CN] App 的所有 window：iOS 13+ 为所有已连接 window scene 的 window，否则为 `UIApplication.windows`。
 */
static NSArray<UIWindow *> *CYLThemeApplicationWindows(void) {
    UIApplication *application = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
        for (UIScene *scene in application.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
            }
        }
        if (windows.count > 0) {
            return windows;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // [EN] Before iOS 13, or an app without scenes. [CN] iOS 13 以前，或未使用 scene 的 App。
    return application.windows;
#pragma clang diagnostic pop
}

/// [EN] The layer colors of `view` and its subviews. [CN] `view` 及其子视图的 layer 颜色。
static void CYLThemeRefreshLayerColorsOfViewTree(UIView *view) {
    [view.layer cyl_refreshThemeColors];
    for (UIView *subview in [view.subviews copy]) {
        CYLThemeRefreshLayerColorsOfViewTree(subview);
    }
}

/// [EN] The loaded views of `viewController` and its children / presented ones that are not in a window.
/// [CN] `viewController` 及其子控制器、present 出的控制器中已加载但不在 window 上的 view。
static void CYLThemeRefreshLayerColorsOfDetachedViews(UIViewController *viewController) {
    if (viewController.isViewLoaded && !viewController.view.window && !viewController.view.superview) {
        CYLThemeRefreshLayerColorsOfViewTree(viewController.view);
    }
    for (UIViewController *childViewController in [viewController.childViewControllers copy]) {
        CYLThemeRefreshLayerColorsOfDetachedViews(childViewController);
    }
    UIViewController *presentedViewController = viewController.presentedViewController;
    if (presentedViewController && presentedViewController.presentingViewController == viewController) {
        CYLThemeRefreshLayerColorsOfDetachedViews(presentedViewController);
    }
}

void CYLThemeRefreshTraitDependentValues(void) {
    for (UIWindow *window in CYLThemeApplicationWindows()) {
        if (window.hidden) {
            continue;
        }
        CYLThemeRefreshLayerColorsOfViewTree(window);
        if (window.rootViewController) {
            CYLThemeRefreshLayerColorsOfDetachedViews(window.rootViewController);
        }
    }
}

@interface CYLThemeManager ()

@property (nonatomic, strong) NSMutableArray<NSObject<NSCopying> *> *cyl_themeIdentifiers;
@property (nonatomic, strong) NSMutableArray<NSObject *> *cyl_themes;

@end

@implementation CYLThemeManager

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, name = %@, currentThemeIdentifier = %@, themeIdentifiers = %@", [super description], self.name, self.currentThemeIdentifier, self.themeIdentifiers];
}

- (instancetype)initWithName:(__kindof NSObject<NSCopying> *)name {
    if (self = [super init]) {
        _name = [name copy];
        _cyl_themeIdentifiers = [NSMutableArray array];
        _cyl_themes = [NSMutableArray array];
        // [EN] A system appearance change made in the background was ignored: check it again once active.
        // [CN] 在后台发生的系统外观变化已被忽略：回到前台时重新检查。
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cyl_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

#pragma mark - System appearance

- (void)cyl_applicationDidBecomeActive:(NSNotification *)notification {
    if (@available(iOS 13.0, *)) {
        if (!_respondsSystemStyleAutomatically) {
            return;
        }
        [self updateThemeForTraitCollection:[self cyl_currentTraitCollection]];
    }
}

/// [EN] The traits of the first visible window, else the current ones. [CN] 第一个可见 window 的 trait，否则为当前 trait。
- (UITraitCollection *)cyl_currentTraitCollection API_AVAILABLE(ios(13.0)) {
    for (UIWindow *window in CYLThemeApplicationWindows()) {
        if (!window.hidden && window.rootViewController) {
            return window.traitCollection;
        }
    }
    return UITraitCollection.currentTraitCollection;
}

- (void)setRespondsSystemStyleAutomatically:(BOOL)respondsSystemStyleAutomatically {
    _respondsSystemStyleAutomatically = respondsSystemStyleAutomatically;
    if (respondsSystemStyleAutomatically) {
        [self updateThemeForTraitCollection:[self cyl_currentTraitCollection]];
    }
}

- (void)updateThemeForTraitCollection:(UITraitCollection *)traitCollection {
    if (!_respondsSystemStyleAutomatically || !self.identifierForTrait || !traitCollection) {
        return;
    }
    // [EN] iOS draws the app in the other appearance in the background to snapshot it for the app switcher: ignore it,
    //      `UIApplicationDidBecomeActiveNotification` checks again.
    // [CN] iOS 会在后台以另一种外观绘制 App，为多任务界面截图：忽略这种变化，回到前台时（`UIApplicationDidBecomeActiveNotification`）再检查。
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        return;
    }
    if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleUnspecified) {
        return;
    }
    NSObject<NSCopying> *identifier = self.identifierForTrait(traitCollection);
    if (identifier && ![identifier isEqual:_currentThemeIdentifier]) {
        self.currentThemeIdentifier = identifier;
    }
}

#pragma mark - Persistence

- (NSString *)cyl_persistenceKey {
    return [NSString stringWithFormat:@"CYLThemeManager.%@.currentThemeIdentifier", self.name];
}

- (nullable NSObject<NSCopying> *)cyl_savedThemeIdentifier {
    id identifier = [[NSUserDefaults standardUserDefaults] objectForKey:[self cyl_persistenceKey]];
    return ([identifier isKindOfClass:[NSString class]] || [identifier isKindOfClass:[NSNumber class]]) ? identifier : nil;
}

- (void)setPersistsCurrentThemeIdentifier:(BOOL)persistsCurrentThemeIdentifier {
    _persistsCurrentThemeIdentifier = persistsCurrentThemeIdentifier;
    if (!persistsCurrentThemeIdentifier) {
        return;
    }
    NSObject<NSCopying> *savedIdentifier = [self cyl_savedThemeIdentifier];
    if (!_currentThemeIdentifier && savedIdentifier && ([self themeForIdentifier:savedIdentifier] || self.themeGenerator)) {
        self.currentThemeIdentifier = savedIdentifier;
    }
}

- (void)cyl_saveCurrentThemeIdentifierIfNeeded {
    NSObject<NSCopying> *identifier = _currentThemeIdentifier;
    if (_persistsCurrentThemeIdentifier && ([identifier isKindOfClass:[NSString class]] || [identifier isKindOfClass:[NSNumber class]])) {
        [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:[self cyl_persistenceKey]];
    }
}

#pragma mark - Current theme

- (void)setCurrentThemeIdentifier:(NSObject<NSCopying> *)currentThemeIdentifier {
    NSAssert(NSThread.isMainThread, @"CYLThemeManager: change the theme on the main thread.");
    if (!currentThemeIdentifier) {
        return;
    }
    if (![self.cyl_themeIdentifiers containsObject:currentThemeIdentifier] && self.themeGenerator) {
        NSObject *theme = self.themeGenerator(currentThemeIdentifier);
        if (theme) {
            [self addThemeIdentifier:currentThemeIdentifier theme:theme];
        }
    }
    NSObject *theme = [self themeForIdentifier:currentThemeIdentifier];
    if (!theme) {
        NSLog(@"🔴 CYLThemeManager: register the theme of identifier %@ before making it current.", currentThemeIdentifier);
        return;
    }
    BOOL themeChanged = _currentThemeIdentifier && ![_currentThemeIdentifier isEqual:currentThemeIdentifier];
    _currentThemeIdentifier = [currentThemeIdentifier copy];
    _currentTheme = theme;
    [self cyl_saveCurrentThemeIdentifierIfNeeded];
    if (themeChanged) {
        [self cyl_notifyThemeChanged];
    }
}

- (void)setCurrentTheme:(NSObject *)currentTheme {
    NSAssert(NSThread.isMainThread, @"CYLThemeManager: change the theme on the main thread.");
    if (!currentTheme) {
        return;
    }
    if (![self.cyl_themes containsObject:currentTheme] && self.themeIdentifierGenerator) {
        NSObject<NSCopying> *identifier = self.themeIdentifierGenerator(currentTheme);
        if (identifier) {
            [self addThemeIdentifier:identifier theme:currentTheme];
        }
    }
    NSObject<NSCopying> *identifier = [self identifierForTheme:currentTheme];
    if (!identifier) {
        NSLog(@"🔴 CYLThemeManager: register the theme %@ before making it current.", currentTheme);
        return;
    }
    BOOL themeChanged = _currentTheme && ![_currentTheme isEqual:currentTheme];
    _currentTheme = currentTheme;
    _currentThemeIdentifier = identifier;
    [self cyl_saveCurrentThemeIdentifierIfNeeded];
    if (themeChanged) {
        [self cyl_notifyThemeChanged];
    }
}

#pragma mark - Themes

- (NSArray<NSObject<NSCopying> *> *)themeIdentifiers {
    return self.cyl_themeIdentifiers.count > 0 ? [self.cyl_themeIdentifiers copy] : nil;
}

- (NSArray<NSObject *> *)themes {
    return self.cyl_themes.count > 0 ? [self.cyl_themes copy] : nil;
}

- (NSObject *)themeForIdentifier:(NSObject<NSCopying> *)identifier {
    NSUInteger index = identifier ? [self.cyl_themeIdentifiers indexOfObject:identifier] : NSNotFound;
    return index != NSNotFound ? self.cyl_themes[index] : nil;
}

- (NSObject<NSCopying> *)identifierForTheme:(NSObject *)theme {
    NSUInteger index = theme ? [self.cyl_themes indexOfObject:theme] : NSNotFound;
    return index != NSNotFound ? self.cyl_themeIdentifiers[index] : nil;
}

- (void)addThemeIdentifier:(NSObject<NSCopying> *)identifier theme:(NSObject *)theme {
    if (!identifier || !theme) {
        return;
    }
    if ([self.cyl_themeIdentifiers containsObject:identifier] || [self.cyl_themes containsObject:theme]) {
        NSLog(@"🔴 CYLThemeManager: the theme identifier %@ or its theme is already registered.", identifier);
        return;
    }
    [self.cyl_themeIdentifiers addObject:[identifier copy]];
    [self.cyl_themes addObject:theme];
    // [EN] The saved theme, registered now. [CN] 保存的主题，此时才注册。
    if (_persistsCurrentThemeIdentifier && !_currentThemeIdentifier && [identifier isEqual:[self cyl_savedThemeIdentifier]]) {
        self.currentThemeIdentifier = identifier;
    }
}

// [EN] Identifiers and themes are kept as pairs at the same index: removing one removes the pair.
// [CN] identifier 与主题按相同下标成对保存：移除其一时成对移除。
- (void)removeThemeIdentifier:(NSObject<NSCopying> *)identifier {
    NSUInteger index = identifier ? [self.cyl_themeIdentifiers indexOfObject:identifier] : NSNotFound;
    if (index != NSNotFound) {
        [self.cyl_themeIdentifiers removeObjectAtIndex:index];
        [self.cyl_themes removeObjectAtIndex:index];
    }
}

- (void)removeTheme:(NSObject *)theme {
    NSUInteger index = theme ? [self.cyl_themes indexOfObject:theme] : NSNotFound;
    if (index != NSNotFound) {
        [self.cyl_themeIdentifiers removeObjectAtIndex:index];
        [self.cyl_themes removeObjectAtIndex:index];
    }
}

#pragma mark - Notify

- (void)cyl_notifyThemeChanged {
    // [EN] A cross-fade: a snapshot over each visible window, restyled underneath, then faded out.
    // [CN] 交叉淡入淡出：每个可见 window 上覆盖其截图，在其下更新样式，然后淡出截图。
    NSMutableArray<UIView *> *snapshots = [NSMutableArray array];
    if (self.themeChangeAnimationDuration > 0) {
        for (UIWindow *window in CYLThemeApplicationWindows()) {
            if (window.hidden || window.alpha <= 0.01) {
                continue;
            }
            UIView *snapshot = [window snapshotViewAfterScreenUpdates:NO];
            if (!snapshot) {
                continue;
            }
            snapshot.frame = window.bounds;
            snapshot.userInteractionEnabled = NO;
            [window addSubview:snapshot];
            [snapshots addObject:snapshot];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLThemeDidChangeNotification object:self];
    NSObject<NSCopying> *identifier = self.currentThemeIdentifier;
    NSObject *theme = self.currentTheme;
    for (UIWindow *window in CYLThemeApplicationWindows()) {
        if (window.hidden || window.alpha <= 0.01 || !window.rootViewController) {
            continue;
        }
        [window.rootViewController cyl_themeDidChangeByManager:self identifier:identifier theme:theme];
        // [EN] With some presentation styles a window holds the views of several view controllers: walk the whole window.
        // [CN] 某些 present 方式下一个 window 上有多个控制器的视图：遍历整个 window。
        [window cyl_themeDidChangeByManager:self identifier:identifier theme:theme enumeratesSubviews:YES];
    }
    if (snapshots.count > 0) {
        [UIView animateWithDuration:self.themeChangeAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            for (UIView *snapshot in snapshots) {
                snapshot.alpha = 0;
            }
        } completion:^(BOOL finished) {
            for (UIView *snapshot in snapshots) {
                [snapshot removeFromSuperview];
            }
        }];
    }
}

@end
