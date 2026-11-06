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
#import "CYLPlusButton.h"
#import <objc/runtime.h>

#pragma mark - Theme switching (issue #216)

/// [EN] What the app had set before the first theme changed it. [CN] 第一次被主题修改前 App 自己的设置。
static char CYLThemeOriginalStandardAppearanceKey;
static char CYLThemeOriginalScrollEdgeAppearanceKey;
/// [EN] The launch theme was applied (or a theme change came first). [CN] 已应用启动时的主题（或已先收到主题切换）。
static char CYLThemeLaunchThemeAppliedKey;
/// [EN] The manager set with `cyl_themeManager`, nil for the default one. [CN] 通过 `cyl_themeManager` 设置的管理器，nil 表示默认管理器。
static char CYLThemeManagerKey;
/// [EN] What a theme changed, to give back (`CYLThemeRestorableValue`): the tab attributes by tab and key, the icon view
///      provider by tab, the plus button by part. [CN] 主题修改过、需要恢复的内容（`CYLThemeRestorableValue`）：按 Tab 与 key 保存的
///      Tab attributes、按 Tab 保存的图标视图 provider、按部分保存的 PlusButton。
static char CYLThemeAttributeRestorablesKey;
static char CYLThemeIconRestorablesKey;
static char CYLThemePlusButtonRestorablesKey;
/// [EN] Counts the themes applied; a value still loading for an older theme is dropped. [CN] 已应用主题的计数；为旧主题加载的值会被丢弃。
static char CYLThemeGenerationKey;
/// [EN] The three parts of the plus button a theme can change. [CN] 主题可以修改的 PlusButton 三个部分。
static NSString *const CYLThemePlusButtonPartTitle = @"title";
static NSString *const CYLThemePlusButtonPartImage = @"image";
static NSString *const CYLThemePlusButtonPartSelectedImage = @"selectedImage";

/// [EN] What the plus button shows now for `part`. [CN] PlusButton 当前显示的 `part`。
static id _Nullable CYLThemePlusButtonCurrentPart(CYLPlusButton *plusButton, NSString *part) {
    if ([part isEqualToString:CYLThemePlusButtonPartTitle]) {
        return plusButton.cyl_title;
    }
    return [plusButton imageForState:([part isEqualToString:CYLThemePlusButtonPartImage] ? UIControlStateNormal : UIControlStateSelected)];
}

/// [EN] The icon keys of `tabBarItemsAttributes`. [CN] `tabBarItemsAttributes` 中与图标有关的 key。
static NSArray<NSString *> *CYLThemeIconAttributeKeys(void) {
    return @[ CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage,
              CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize ];
}

/// [EN] `attributes` without its icon keys. [CN] 去掉图标 key 的 `attributes`。
static NSDictionary<NSString *, id> *CYLThemeAttributesWithoutIcons(NSDictionary<NSString *, id> *_Nullable attributes) {
    NSMutableDictionary *withoutIcons = [attributes mutableCopy] ?: [NSMutableDictionary dictionary];
    [withoutIcons removeObjectsForKeys:CYLThemeIconAttributeKeys()];
    return [withoutIcons copy];
}

/// [EN] The same object, or equal ones (nil only matches nil). [CN] 同一对象或相等的对象（nil 只与 nil 匹配）。
static BOOL CYLThemeSameValue(id _Nullable value, id _Nullable otherValue) {
    return value == otherValue || [value isEqual:otherValue];
}

/*!
 * [EN] One value a theme changes, and what to give back: the single restore model of the tab attributes, the icon views
 *      and the plus button. It only decides; each caller reads and writes its own kind of value.
 *      1. Before a theme writes, `-prepareWithCurrentValue:`: if the value is no longer what the last theme wrote, the
 *         app changed it, and that becomes the value to give back; otherwise the first value seen is kept.
 *      2. After the write (also asynchronous), `-didInstallValue:` with the value read back.
 *      3. When no theme sets it any more, `-shouldRestoreWithCurrentValue:originalValue:`: YES with the value to write
 *         (nil when there was none) unless the app changed it meanwhile.
 * [CN] 主题修改的一个值，以及需要恢复的内容：Tab attributes、图标视图与 PlusButton 共用的唯一恢复模型。它只做判断；读写由调用方各自完成。
 *      1. 主题写入前调用 `-prepareWithCurrentValue:`：如果当前值已不是上一个主题写入的值，说明 App 修改过，它成为要恢复的值；否则保留
 *         第一次看到的值。
 *      2. 写入后（包括异步写入）调用 `-didInstallValue:`，传入读回的值。
 *      3. 没有主题再设置它时调用 `-shouldRestoreWithCurrentValue:originalValue:`：返回 YES 及要写回的值（原本没有时为 nil），除非 App
 *         期间修改过。
 */
@interface CYLThemeRestorableValue : NSObject
/// [EN] The value to give back; `NSNull` for none; nil before the first theme. [CN] 要恢复的值；没有时为 `NSNull`；第一个主题之前为 nil。
@property (nonatomic, strong, nullable) id original;
/// [EN] What the last theme wrote, as read back; nil while it is still loading. [CN] 上一个主题写入的值（读回的值）；仍在加载时为 nil。
@property (nonatomic, strong, nullable) id installed;
- (void)prepareWithCurrentValue:(nullable id)current;
- (void)didInstallValue:(nullable id)value;
- (BOOL)shouldRestoreWithCurrentValue:(nullable id)current originalValue:(id _Nullable __autoreleasing *_Nonnull)originalValue;
@end

@implementation CYLThemeRestorableValue

- (void)prepareWithCurrentValue:(id)current {
    if (self.installed && !CYLThemeSameValue(current, self.installed)) {
        self.original = current ?: [NSNull null];
        self.installed = nil;
    }
    if (!self.original) {
        self.original = current ?: [NSNull null];
    }
}

- (void)didInstallValue:(id)value {
    self.installed = value;
}

- (BOOL)shouldRestoreWithCurrentValue:(id)current originalValue:(id _Nullable __autoreleasing *)originalValue {
    *originalValue = [self.original isKindOfClass:[NSNull class]] ? nil : self.original;
    return self.installed != nil && CYLThemeSameValue(current, self.installed);
}

@end

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
    // [EN] Styles set before the tab bar was replaced by the library's own (CYLTabBar) are written into the bar shown now.
    // [CN] 在 TabBar 被替换为本库的 CYLTabBar 之前设置的样式，写入当前显示的 TabBar。
    [self cyl_applyTabBarItemStyles];
    id theme = self.cyl_themeManager.currentTheme;
    // [EN] Nothing to restore yet: only a tab bar theme changes anything here.
    // [CN] 此时尚无需恢复：只有 TabBar 主题才需要处理。
    if ([theme conformsToProtocol:@protocol(CYLTabBarTheme)]) {
        [self cyl_applyTabBarTheme:theme];
    }
}

- (void)cyl_applyTabBarTheme:(id)theme {
    objc_setAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSUInteger generation = [objc_getAssociatedObject(self, &CYLThemeGenerationKey) unsignedIntegerValue] + 1;
    objc_setAssociatedObject(self, &CYLThemeGenerationKey, @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id<CYLTabBarTheme> tabBarTheme = [theme conformsToProtocol:@protocol(CYLTabBarTheme)] ? theme : nil;

    NSArray<NSDictionary<NSString *, id> *> *itemsAttributes = nil;
    if ([tabBarTheme respondsToSelector:@selector(cyl_tabBarItemsAttributesForTabBarController:)]) {
        itemsAttributes = [tabBarTheme cyl_tabBarItemsAttributesForTabBarController:self];
    }
    NSMapTable<UIViewController *, NSDictionary *> *tabAttributes = [self cyl_themeAttributesByTabOfItemsAttributes:itemsAttributes];
    // [EN] Titles and the other keys, in place (`-updateTabBarItemAtIndex:attributes:`, issue #601).
    // [CN] 原地更新标题与其他 key（`-updateTabBarItemAtIndex:attributes:`，issue #601）。
    [self cyl_applyThemeTabAttributes:tabAttributes];
    // [EN] The icons, as views in place of each tab's icon (`-setTabBarItemIcon:selectedIcon:size:atIndex:`).
    // [CN] 图标：以视图替换每个 Tab 的图标（`-setTabBarItemIcon:selectedIcon:size:atIndex:`）。
    [self cyl_applyThemeIconsOfTabAttributes:tabAttributes generation:generation];
    // [EN] The plus button's title and images (`-updatePlusButtonWithAttributes:`).
    // [CN] PlusButton 的标题与图片（`-updatePlusButtonWithAttributes:`）。
    NSDictionary<NSString *, id> *plusButtonAttributes = nil;
    if ([tabBarTheme respondsToSelector:@selector(cyl_plusButtonAttributesForTabBarController:)]) {
        plusButtonAttributes = [tabBarTheme cyl_plusButtonAttributesForTabBarController:self];
    }
    [self cyl_applyThemePlusButtonAttributes:plusButtonAttributes generation:generation];

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
    // [EN] Styles set in one place win over the theme's appearance. [CN] 在一处设置的样式优先于主题的外观。
    [self cyl_applyTabBarItemStyles];
    // [EN] What the app adds to the tab buttons in its one-time layout block (`-setViewDidLayoutSubViewsBlockInvokeOnce:block:`,
    //      e.g. a cover over a tab, badges) is added again after the next layout: before, a theme switch left that block
    //      marked as run, and what UIKit dropped from the tab buttons never came back.
    //      Scope: every style. The block itself decides what to add; the theme's own icons do not depend on it: they are
    //      views in place of each icon (`-[UIControl cyl_replaceTabImageViewWithNewView:show:]`), in both layers on Liquid
    //      Glass, and are installed again after every layout (#601).
    // [CN] App 在只执行一次的布局 block（`-setViewDidLayoutSubViewsBlockInvokeOnce:block:`，如 Tab 上的封面、角标）中添加到 Tab 按钮的内容，
    //      在下一次布局后重新添加：之前换肤后该 block 仍被标记为已执行，UIKit 从 Tab 按钮中丢弃的内容不会再出现。
    //      范围：所有样式。添加什么由 block 自己决定；主题自身的图标不依赖它：它们是替换每个图标的视图
    //      （`-[UIControl cyl_replaceTabImageViewWithNewView:show:]`，液态玻璃下两个图层都有），每次布局后都会重新安装（#601）。
    [self cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce];
    // [EN] Liquid Glass only: the stand-in follows the plus button's new image and position after every theme change.
    // [CN] 仅液态玻璃：每次换肤后，替身跟随 PlusButton 的新图片与新位置。
    if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && [CYLConstants isLiquidGlassActive]) {
        [self cyl_layOutPlusButtonInLiquidGlassLayers];
    }
}

/// [EN] YES while no other theme was applied after the one counted `generation`. [CN] 计数为 `generation` 的主题之后没有应用其他主题时为 YES。
- (BOOL)cyl_isCurrentThemeGeneration:(NSUInteger)generation {
    return [objc_getAssociatedObject(self, &CYLThemeGenerationKey) unsignedIntegerValue] == generation;
}

/// [EN] The restore records stored under `key`, created the first time. [CN] 保存在 `key` 下的恢复记录，第一次使用时创建。
- (id)cyl_themeRestorablesForKey:(const void *)key create:(id (^)(void))create {
    id restorables = objc_getAssociatedObject(self, key);
    if (!restorables) {
        restorables = create();
        objc_setAssociatedObject(self, key, restorables, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return restorables;
}

/*!
 * [EN] The theme's attributes by tab: one entry per tab, none for the plus button's tab or a placeholder (as
 *      `-updateTabBarItemsWithAttributes:`).
 * [CN] 按 Tab 保存的主题 attributes：每个 Tab 一项，PlusButton 的 Tab 与占位控制器不占项（与 `-updateTabBarItemsWithAttributes:` 相同）。
 */
- (NSMapTable<UIViewController *, NSDictionary *> *)cyl_themeAttributesByTabOfItemsAttributes:(nullable NSArray<NSDictionary<NSString *, id> *> *)itemsAttributes {
    NSMapTable<UIViewController *, NSDictionary *> *tabAttributes = [NSMapTable weakToStrongObjectsMapTable];
    NSUInteger attributesIndex = 0;
    for (NSUInteger index = 0; index < self.viewControllers.count && attributesIndex < itemsAttributes.count; index++) {
        UIViewController *viewController = self.viewControllers[index];
        // [EN] The same slot test as `-updateTabBarItemsWithAttributes:` (a plus child inside a navigation controller too).
        // [CN] 与 `-updateTabBarItemsWithAttributes:` 相同的 slot 判断（也包括被导航控制器包裹的 PlusButton 子控制器）。
        if ([self cyl_isPlusSlotViewController:viewController]) {
            continue;
        }
        [tabAttributes setObject:itemsAttributes[attributesIndex++] forKey:viewController];
    }
    return tabAttributes;
}

/*!
 * [EN] Titles and every other key except the icons, one restore record per tab and key: a key the new theme does not
 *      give gets its value back (removed when the app had none), unless the app changed it meanwhile. One update per tab.
 * [CN] 标题与图标以外的其他 key，每个 Tab 的每个 key 一条恢复记录：新主题未提供的 key 恢复原值（App 原本没有时移除），除非 App 期间修改过。
 *      每个 Tab 只更新一次。
 */
- (void)cyl_applyThemeTabAttributes:(NSMapTable<UIViewController *, NSDictionary *> *)tabAttributes {
    NSMapTable<UIViewController *, NSMutableDictionary<NSString *, CYLThemeRestorableValue *> *> *restorables =
        [self cyl_themeRestorablesForKey:&CYLThemeAttributeRestorablesKey create:^id { return [NSMapTable weakToStrongObjectsMapTable]; }];
    NSMutableSet<UIViewController *> *viewControllers = [NSMutableSet setWithArray:restorables.keyEnumerator.allObjects];
    [viewControllers addObjectsFromArray:tabAttributes.keyEnumerator.allObjects];
    for (UIViewController *viewController in viewControllers) {
        NSUInteger index = [self.viewControllers indexOfObject:viewController];
        if (index == NSNotFound) {
            [restorables removeObjectForKey:viewController];
            continue;
        }
        NSDictionary<NSString *, id> *current = [self tabBarItemAttributesAtIndex:index] ?: @{};
        NSDictionary<NSString *, id> *themeValues = CYLThemeAttributesWithoutIcons([tabAttributes objectForKey:viewController]);
        NSMutableDictionary<NSString *, CYLThemeRestorableValue *> *values = [restorables objectForKey:viewController] ?: [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, id> *toWrite = [NSMutableDictionary dictionary];
        NSMutableArray<NSString *> *toRemove = [NSMutableArray array];
        for (NSString *key in values.allKeys) {
            if (themeValues[key]) {
                continue;
            }
            id original = nil;
            if ([values[key] shouldRestoreWithCurrentValue:current[key] originalValue:&original]) {
                if (original) {
                    toWrite[key] = original;
                } else {
                    [toRemove addObject:key];
                }
            }
            [values removeObjectForKey:key];
        }
        for (NSString *key in themeValues) {
            CYLThemeRestorableValue *value = values[key] ?: [CYLThemeRestorableValue new];
            values[key] = value;
            [value prepareWithCurrentValue:current[key]];
            toWrite[key] = themeValues[key];
        }
        if (toWrite.count > 0) {
            [self updateTabBarItemAtIndex:index attributes:toWrite];
        }
        if (toRemove.count > 0) {
            [self cyl_themeRemoveTabBarItemAttributeKeys:toRemove atIndex:index];
        }
        NSDictionary<NSString *, id> *written = [self tabBarItemAttributesAtIndex:index] ?: @{};
        for (NSString *key in themeValues) {
            [values[key] didInstallValue:written[key] ?: themeValues[key]];
        }
        if (values.count > 0) {
            [restorables setObject:values forKey:viewController];
        } else {
            [restorables removeObjectForKey:viewController];
        }
    }
}

/*!
 * [EN] The theme's icons, with the mechanism of `-setTabBarItemIcon:selectedIcon:size:atIndex:` (the "change all local
 *      icons" and "change all network icons" demo rows): a view in place of each tab's icon, in every style (Liquid
 *      Glass, its selected layer included, the system tab bar, FlatDesign), also over a Lottie icon, drawn with its own
 *      colors. Setting `tabBarItem.image` did not show on Liquid Glass with Lottie icons, and made UIKit rebuild the
 *      tab buttons.
 *      - The icon of an entry: `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` (with `CYLTabBarItemImageURLSize`)
 *        win; else `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`, combined with their dark images.
 *      - One restore record per tab (the icon view provider): a tab the new theme gives no icon gets its own back, as
 *        does a tab whose icon could not be loaded, unless the app replaced the theme's icon meanwhile.
 *      - Icons are loaded first (network ones asynchronously) and shown only if no other theme came in between.
 * [CN] 主题图标，使用 `-setTabBarItemIcon:selectedIcon:size:atIndex:` 的机制（演示中的“批量使用本地图标”“批量下载网络图标”行）：
 *      以视图替换每个 Tab 的图标，适用于所有样式（液态玻璃，包括其选中图层；系统 TabBar；扁平样式），也能覆盖 Lottie 图标，按原图颜色绘制。
 *      原来设置 `tabBarItem.image` 的方式在使用 Lottie 图标的液态玻璃上不显示，并会让 UIKit 重建 Tab 按钮。
 *      - 每项的图标：`CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL`（及 `CYLTabBarItemImageURLSize`）优先；否则为
 *        `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`，并与其深色图片合成。
 *      - 每个 Tab 一条恢复记录（图标视图 provider）：新主题未提供图标的 Tab、图标加载失败的 Tab 恢复自己的图标，除非 App 期间替换了主题图标。
 *      - 先加载图标（网络图标为异步），只有期间没有切换到其他主题时才显示。
 */
- (void)cyl_applyThemeIconsOfTabAttributes:(NSMapTable<UIViewController *, NSDictionary *> *)tabAttributes generation:(NSUInteger)generation {
    NSMapTable<UIViewController *, CYLThemeRestorableValue *> *restorables =
        [self cyl_themeRestorablesForKey:&CYLThemeIconRestorablesKey create:^id { return [NSMapTable weakToStrongObjectsMapTable]; }];
    NSMapTable<UIViewController *, CYLTabBarItemIconViewProvider> *providers = [self cyl_tabBarItemIconViewProviders];

    NSMapTable<UIViewController *, NSDictionary *> *themeIcons = [NSMapTable weakToStrongObjectsMapTable];
    for (UIViewController *viewController in tabAttributes.keyEnumerator.allObjects) {
        NSDictionary<NSString *, id> *attributes = [tabAttributes objectForKey:viewController];
        id icon = attributes[CYLTabBarItemImageURL];
        id selectedIcon = attributes[CYLTabBarItemSelectedImageURL];
        NSValue *sizeValue = attributes[CYLTabBarItemImageURLSize];
        if (!icon) {
            id image = attributes[CYLTabBarItemImage];
            id selectedImage = attributes[CYLTabBarItemSelectedImage];
            // [EN] With a dark image, the combined image (names and UIImages); else the source as it is.
            // [CN] 有深色图片时为合成后的图片（图片名与 UIImage）；否则原样使用该来源。
            icon = attributes[CYLTabBarItemDarkImage] ? [UIImage cyl_imageWithImageInfo:image darkImageInfo:attributes[CYLTabBarItemDarkImage]] : image;
            selectedIcon = attributes[CYLTabBarItemSelectedDarkImage] ?
                [UIImage cyl_imageWithImageInfo:selectedImage darkImageInfo:attributes[CYLTabBarItemSelectedDarkImage]] : selectedImage;
            if (!icon) {
                icon = selectedIcon;
            }
        }
        if (!icon) {
            continue;
        }
        NSMutableDictionary *tabIcon = [NSMutableDictionary dictionaryWithObject:icon forKey:@"icon"];
        tabIcon[@"selectedIcon"] = selectedIcon;
        tabIcon[@"size"] = [sizeValue isKindOfClass:[NSValue class]] ? sizeValue : nil;
        [themeIcons setObject:[tabIcon copy] forKey:viewController];
    }

    // [EN] Tabs without an icon in this theme. [CN] 本主题中没有图标的 Tab。
    for (UIViewController *viewController in restorables.keyEnumerator.allObjects) {
        if (![themeIcons objectForKey:viewController]) {
            [self cyl_restoreThemeIconOfViewController:viewController];
        }
    }

    __weak __typeof(self) weakSelf = self;
    for (UIViewController *viewController in themeIcons.keyEnumerator.allObjects) {
        CYLThemeRestorableValue *value = [restorables objectForKey:viewController] ?: [CYLThemeRestorableValue new];
        [restorables setObject:value forKey:viewController];
        [value prepareWithCurrentValue:[providers objectForKey:viewController]];
        NSDictionary *tabIcon = [themeIcons objectForKey:viewController];
        __weak UIViewController *weakViewController = viewController;
        CYLLoadTabBarItemIcon(tabIcon[@"icon"], ^(UIImage *image) {
            void (^show)(UIImage *) = ^(UIImage *selectedImage) {
                __strong __typeof(weakSelf) self = weakSelf;
                UIViewController *strongViewController = weakViewController;
                // [EN] Dropped when another theme came in between, or the tab is gone. [CN] 期间切换了其他主题或 Tab 已不存在时丢弃。
                if (!self || !strongViewController || ![self cyl_isCurrentThemeGeneration:generation]) {
                    return;
                }
                NSUInteger index = [self.viewControllers indexOfObject:strongViewController];
                NSValue *sizeValue = tabIcon[@"size"];
                CGSize size = sizeValue ? sizeValue.CGSizeValue : CGSizeZero;
                // [EN] Not loaded (e.g. a failed download): the tab's own icon again. [CN] 未能加载（例如下载失败）：恢复 Tab 自己的图标。
                if (!image || index == NSNotFound || ![self setTabBarItemIcon:image selectedIcon:selectedImage size:size atIndex:index]) {
                    [self cyl_restoreThemeIconOfViewController:strongViewController];
                    return;
                }
                [value didInstallValue:[[self cyl_tabBarItemIconViewProviders] objectForKey:strongViewController]];
            };
            id selectedIcon = tabIcon[@"selectedIcon"];
            if (!image || !selectedIcon || [selectedIcon isEqual:tabIcon[@"icon"]]) {
                show(nil);
            } else {
                CYLLoadTabBarItemIcon(selectedIcon, show);
            }
        });
    }
}

/// [EN] Gives `viewController` its own icon back, unless the app replaced the theme's icon. [CN] 恢复 `viewController` 自己的图标，除非 App 替换了主题图标。
- (void)cyl_restoreThemeIconOfViewController:(UIViewController *)viewController {
    NSMapTable<UIViewController *, CYLThemeRestorableValue *> *restorables = objc_getAssociatedObject(self, &CYLThemeIconRestorablesKey);
    CYLThemeRestorableValue *value = [restorables objectForKey:viewController];
    if (!value) {
        return;
    }
    [restorables removeObjectForKey:viewController];
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    id original = nil;
    if (index != NSNotFound &&
        [value shouldRestoreWithCurrentValue:[[self cyl_tabBarItemIconViewProviders] objectForKey:viewController] originalValue:&original]) {
        [self setTabBarItemIconViewProvider:original atIndex:index];
    }
}

/*!
 * [EN] The theme's plus button, through `-updatePlusButtonWithAttributes:` (as the "change all titles" and "change all
 *      network icons" demo rows), one restore record per part: the title, the image, the selected image. A part the new
 *      theme does not give, or an image that could not be loaded, gets its own value back, unless the app changed it.
 *      An image the plus button never had is restored as the normal image (a button without a selected image shows its
 *      normal one); a title it never had as "".
 * [CN] 主题中的 PlusButton，通过 `-updatePlusButtonWithAttributes:`（与演示中“批量更换标题”“批量下载网络图标”行相同），每个部分一条恢复
 *      记录：标题、图片、选中图片。新主题未提供的部分、未能加载的图片恢复为它自己的内容，除非 App 修改过。PlusButton 原本没有的图片恢复为
 *      普通图片（按钮没有选中图片时显示普通图片）；原本没有的标题恢复为 ""。
 */
- (void)cyl_applyThemePlusButtonAttributes:(nullable NSDictionary<NSString *, id> *)attributes generation:(NSUInteger)generation {
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton) {
        return;
    }
    NSMutableDictionary<NSString *, CYLThemeRestorableValue *> *restorables =
        [self cyl_themeRestorablesForKey:&CYLThemePlusButtonRestorablesKey create:^id { return [NSMutableDictionary dictionary]; }];
    NSMutableDictionary<NSString *, id> *themeParts = [NSMutableDictionary dictionary];
    themeParts[CYLThemePlusButtonPartTitle] = attributes[CYLTabBarItemTitle];
    themeParts[CYLThemePlusButtonPartImage] = attributes[CYLTabBarItemImageURL] ?: attributes[CYLTabBarItemImage];
    themeParts[CYLThemePlusButtonPartSelectedImage] = attributes[CYLTabBarItemSelectedImageURL] ?: attributes[CYLTabBarItemSelectedImage];
    NSValue *sizeValue = attributes[CYLTabBarItemImageURLSize];

    for (NSString *part in @[ CYLThemePlusButtonPartTitle, CYLThemePlusButtonPartImage, CYLThemePlusButtonPartSelectedImage ]) {
        id themeValue = themeParts[part];
        if (!themeValue) {
            [self cyl_restoreThemePlusButtonPart:part];
            continue;
        }
        CYLThemeRestorableValue *value = restorables[part] ?: [CYLThemeRestorableValue new];
        restorables[part] = value;
        [value prepareWithCurrentValue:CYLThemePlusButtonCurrentPart(plusButton, part)];
        if ([part isEqualToString:CYLThemePlusButtonPartTitle]) {
            if ([self updatePlusButtonWithAttributes:@{ CYLTabBarItemTitle : themeValue }]) {
                [value didInstallValue:CYLThemePlusButtonCurrentPart(plusButton, part) ?: themeValue];
            }
            continue;
        }
        __weak __typeof(self) weakSelf = self;
        __weak CYLPlusButton *weakPlusButton = plusButton;
        CYLLoadTabBarItemIcon(themeValue, ^(UIImage *image) {
            __strong __typeof(weakSelf) self = weakSelf;
            CYLPlusButton *strongPlusButton = weakPlusButton;
            // [EN] Dropped when another theme came in between. [CN] 期间切换了其他主题时丢弃。
            if (!self || !strongPlusButton || ![self cyl_isCurrentThemeGeneration:generation]) {
                return;
            }
            if (!image) {
                [self cyl_restoreThemePlusButtonPart:part];
                return;
            }
            NSString *imageKey = [part isEqualToString:CYLThemePlusButtonPartImage] ? CYLTabBarItemImage : CYLTabBarItemSelectedImage;
            NSMutableDictionary *imageAttributes = [NSMutableDictionary dictionaryWithObject:image forKey:imageKey];
            imageAttributes[CYLTabBarItemImageURLSize] = [sizeValue isKindOfClass:[NSValue class]] ? sizeValue : nil;
            if ([self updatePlusButtonWithAttributes:imageAttributes]) {
                [value didInstallValue:CYLThemePlusButtonCurrentPart(strongPlusButton, part)];
            }
        });
    }
}

/// [EN] Puts the plus button's own `part` back, unless the app changed it. [CN] 恢复 PlusButton 自己的 `part`，除非 App 修改过。
- (void)cyl_restoreThemePlusButtonPart:(NSString *)part {
    NSMutableDictionary<NSString *, CYLThemeRestorableValue *> *restorables = objc_getAssociatedObject(self, &CYLThemePlusButtonRestorablesKey);
    CYLThemeRestorableValue *value = restorables[part];
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!value || !plusButton) {
        return;
    }
    [restorables removeObjectForKey:part];
    id original = nil;
    if (![value shouldRestoreWithCurrentValue:CYLThemePlusButtonCurrentPart(plusButton, part) originalValue:&original]) {
        return;
    }
    if ([part isEqualToString:CYLThemePlusButtonPartTitle]) {
        [plusButton cyl_updateTitle:(original ?: @"") image:nil selectedImage:nil];
    } else if ([part isEqualToString:CYLThemePlusButtonPartImage]) {
        if (original) {
            [plusButton cyl_updateTitle:nil image:original selectedImage:nil];
        }
    } else {
        // [EN] No selected image of its own: the normal one, as a button without a selected image shows.
        // [CN] 原本没有选中图片：使用普通图片，与没有选中图片的按钮显示一致。
        UIImage *selectedImage = original ?: [plusButton imageForState:UIControlStateNormal];
        if (selectedImage) {
            [plusButton cyl_updateTitle:nil image:nil selectedImage:selectedImage];
        }
    }
}

@end

