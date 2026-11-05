//
//  CYLTabBarController+CYLTheme.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #216 — the tab bar's side of theme switching (`CYLTabBarTheme`), split out of CYLTabBarController.m:
//      applying a theme in place, restoring the app's own look, the launch theme, the injectable manager, and the
//      animation colors that follow the theme (#216 + #604).
// [CN] FIX: issue #216 — 换肤在 TabBar 这一侧的实现（`CYLTabBarTheme`），从 CYLTabBarController.m 拆出：原地应用主题、恢复 App 自己的外观、
//      启动时的主题、可注入的管理器，以及跟随主题的动画颜色（#216 + #604）。

#import "CYLTabBarController.h"
#import "CYLTabBarController+CYLPrivate.h"
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#import <objc/runtime.h>

#pragma mark - Theme switching (issue #216)

/// [EN] What the app had set before the first theme changed it. [CN] 第一次被主题修改前 App 自己的设置。
static char CYLThemeOriginalTabBarItemsAttributesKey;
static char CYLThemeOriginalStandardAppearanceKey;
static char CYLThemeOriginalScrollEdgeAppearanceKey;
/// [EN] The launch theme was applied (or a theme change came first). [CN] 已应用启动时的主题（或已先收到主题切换）。
static char CYLThemeLaunchThemeAppliedKey;
/// [EN] The manager set with `cyl_themeManager`, nil for the default one. [CN] 通过 `cyl_themeManager` 设置的管理器，nil 表示默认管理器。
static char CYLThemeManagerKey;

@implementation CYLTabBarController (CYLTheme)

- (void)cyl_themeDidChangeByManager:(CYLThemeManager *)manager identifier:(nullable __kindof NSObject<NSCopying> *)identifier theme:(nullable __kindof NSObject *)theme {
    [super cyl_themeDidChangeByManager:manager identifier:identifier theme:theme];
    // [EN] The tab bar's manager (`cyl_themeManager`) drives the tab bar; another manager (e.g. the themes of one page)
    //      only with a tab bar theme. The animation colors (`CYLTabBarAnimationColors`) may hold theme colors of any
    //      manager: resolved again every time.
    // [CN] TabBar 的管理器（`cyl_themeManager`）决定 TabBar 外观；其他管理器（例如某个页面自己的主题）仅在其主题为 TabBar 主题时生效。
    //      动画颜色（`CYLTabBarAnimationColors`）可能是任意管理器的主题颜色：每次都重新解析。
    BOOL isTabBarManager = (manager == self.cyl_themeManager);
    if (isTabBarManager || [theme conformsToProtocol:@protocol(CYLTabBarTheme)]) {
        [self cyl_applyTabBarTheme:theme];
    }
    [self cyl_refreshTabBarItemAnimationColors];
}

- (CYLThemeManager *)cyl_themeManager {
    return objc_getAssociatedObject(self, &CYLThemeManagerKey) ?: CYLThemeManagerCenter.defaultThemeManager;
}

- (void)setCyl_themeManager:(CYLThemeManager *)themeManager {
    objc_setAssociatedObject(self, &CYLThemeManagerKey, themeManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 * FIX: issue #216
 * [EN] Every tab button applies the colors of its animation again (`CYLTabBarAnimationColors` resolved for the new theme).
 *      Only with an animation library; a tab without registered colors does nothing.
 * [CN] 每个 Tab 按钮重新应用其动画的颜色（按新主题解析的 `CYLTabBarAnimationColors`）。仅在有动画库时；没有注册颜色的 Tab 不做处理。
 */
- (void)cyl_refreshTabBarItemAnimationColors {
    if (!CYLTabBarItemAnimationIsAvailable() || !self.isViewLoaded) {
        return;
    }
    for (UIViewController *viewController in self.viewControllers) {
        for (UIControl *tabButton in [self cyl_tabButtonsOfViewController:viewController]) {
            [tabButton cyl_refreshTabBarItemAnimationColors];
        }
    }
}

- (void)cyl_applyLaunchTabBarThemeIfNeeded {
    if (objc_getAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey)) {
        return;
    }
    objc_setAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id theme = self.cyl_themeManager.currentTheme;
    // [EN] Nothing to restore yet: only a tab bar theme changes anything here.
    // [CN] 此时尚无需恢复：只有 TabBar 主题才需要处理。
    if ([theme conformsToProtocol:@protocol(CYLTabBarTheme)]) {
        [self cyl_applyTabBarTheme:theme];
    }
}

- (void)cyl_applyTabBarTheme:(id)theme {
    objc_setAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id<CYLTabBarTheme> tabBarTheme = [theme conformsToProtocol:@protocol(CYLTabBarTheme)] ? theme : nil;

    // [EN] Titles and icons, in place (issue #601). [CN] 原地更新标题与图标（issue #601）。
    NSArray<NSDictionary<NSString *, id> *> *itemsAttributes = nil;
    if ([tabBarTheme respondsToSelector:@selector(cyl_tabBarItemsAttributesForTabBarController:)]) {
        itemsAttributes = [tabBarTheme cyl_tabBarItemsAttributesForTabBarController:self];
    }
    NSArray *originalItemsAttributes = objc_getAssociatedObject(self, &CYLThemeOriginalTabBarItemsAttributesKey);
    if (itemsAttributes.count > 0) {
        if (!originalItemsAttributes) {
            objc_setAssociatedObject(self, &CYLThemeOriginalTabBarItemsAttributesKey, [self.tabBarItemsAttributes copy] ?: @[], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [self updateTabBarItemsWithAttributes:itemsAttributes];
    } else if (originalItemsAttributes) {
        [self updateTabBarItemsWithAttributes:originalItemsAttributes];
        objc_setAssociatedObject(self, &CYLThemeOriginalTabBarItemsAttributesKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // [EN] The appearance: a new object for every theme, so every style (FlatDesign included) applies it.
    // [CN] 外观：每个主题都是新对象，因此所有样式（包括扁平样式）都会应用。
    if (@available(iOS 13.0, *)) {
        UITabBar *tabBar = self.tabBar;
        UITabBarAppearance *appearance = nil;
        if ([tabBarTheme respondsToSelector:@selector(cyl_tabBarAppearanceForTabBarController:)]) {
            appearance = [tabBarTheme cyl_tabBarAppearanceForTabBarController:self];
        }
        id originalStandardAppearance = objc_getAssociatedObject(self, &CYLThemeOriginalStandardAppearanceKey);
        if (appearance) {
            if (!originalStandardAppearance) {
                objc_setAssociatedObject(self, &CYLThemeOriginalStandardAppearanceKey, tabBar.standardAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                if (@available(iOS 15.0, *)) {
                    objc_setAssociatedObject(self, &CYLThemeOriginalScrollEdgeAppearanceKey, tabBar.scrollEdgeAppearance ?: [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }
            tabBar.standardAppearance = appearance;
            if (@available(iOS 15.0, *)) {
                tabBar.scrollEdgeAppearance = [appearance copy];
            }
        } else if ([originalStandardAppearance isKindOfClass:[UITabBarAppearance class]]) {
            tabBar.standardAppearance = originalStandardAppearance;
            if (@available(iOS 15.0, *)) {
                id originalScrollEdgeAppearance = objc_getAssociatedObject(self, &CYLThemeOriginalScrollEdgeAppearanceKey);
                tabBar.scrollEdgeAppearance = [originalScrollEdgeAppearance isKindOfClass:[UITabBarAppearance class]] ? originalScrollEdgeAppearance : nil;
            }
            objc_setAssociatedObject(self, &CYLThemeOriginalStandardAppearanceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &CYLThemeOriginalScrollEdgeAppearanceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        // [EN] Bring the title offset copies (issue #475) and the flat design tab bar up to date now.
        // [CN] 立即更新标题偏移副本（issue #475）与扁平样式 TabBar。
        [self cyl_syncTabBarAppearances];
    }

    if ([tabBarTheme respondsToSelector:@selector(cyl_customizeTabBarController:)]) {
        [tabBarTheme cyl_customizeTabBarController:self];
    }
}

@end
