//
//  CYLTabBarController+CYLConfiguration.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBarController+CYLPrivate.h"

/*
 * [EN] What stays in Objective-C of `CYLTabBarController (CYLConfiguration)` (docs/Swift-Migration.md, step 44): the
 *      initializers (a Swift initializer cannot build the subclass a class method is called on) and
 *      `CYLTabBarConfigurationTheme` (its protocol names this class). The value conversion, skins, localization, routes and
 *      loaders are in Swift/CYLTabBarController+CYLConfiguration.swift.
 * [CN] `CYLTabBarController (CYLConfiguration)` 中留在 Objective-C 的部分（docs/Swift-Migration.md，第 44 步）：初始化方法（Swift 初始化方法
 *      无法创建类方法所在的子类）与 `CYLTabBarConfigurationTheme`（其协议引用了本类）。值转换、皮肤、本地化、路由与加载方法在
 *      Swift/CYLTabBarController+CYLConfiguration.swift 中。
 */

/// [EN] Private: the PlusButton slot's entry; the same key as in CYLTabBarController.m (#774). [CN] 私有：PlusButton slot 的一项；与 CYLTabBarController.m 中的键相同（#774）。
static NSString *const CYLTabBarItemPlusSlotPlaceholderKey = @"CYLTabBarItemPlusSlotPlaceholder";

#define CYLColorValue(value) [CYLTabBarController cyl_configurationColorValue:(value)]
#define CYLFontValue(value) [CYLTabBarController cyl_configurationFontValue:(value)]
#define CYLImageValue(value) [CYLTabBarController cyl_configurationImageValue:(value)]
#define CYLStringValue(value) [CYLTabBarController cyl_configurationStringValue:(value)]
#define CYLNormalizedItemAttributes(value) [CYLTabBarController cyl_normalizedItemAttributes:(value)]
#define CYLLogInvalidConfigurationValue(key, value) [CYLTabBarController cyl_logInvalidConfigurationValue:(value) forKey:(key)]

@interface CYLTabBarConfigurationTheme ()
- (instancetype)initWithIdentifier:(NSString *)identifier values:(NSDictionary<NSString *, id> *)values
                        references:(NSDictionary<id, NSDictionary<NSString *, NSString *> *> *)references NS_DESIGNATED_INITIALIZER;
@end

@implementation CYLTabBarConfigurationTheme {
    /// [EN] Per tab (its identifier, or its position without one): item key -> value name. [CN] 每个 Tab（其标识，没有时为位置）：item 键 -> 值名称。
    NSDictionary<id, NSDictionary<NSString *, NSString *> *> *_references;
}

- (instancetype)initWithIdentifier:(NSString *)identifier values:(NSDictionary<NSString *, id> *)values
                        references:(NSDictionary<id, NSDictionary<NSString *, NSString *> *> *)references {
    if (self = [super init]) {
        _identifier = [identifier copy];
        _values = [values copy];
        _references = [references copy];
    }
    return self;
}

+ (instancetype)cyl_themeWithIdentifier:(NSString *)identifier values:(NSDictionary<NSString *, id> *)values
                             references:(NSDictionary<id, NSDictionary<NSString *, NSString *> *> *)references {
    return [[self alloc] initWithIdentifier:identifier values:values references:references];
}

- (nullable id)valueForName:(NSString *)name {
    return [name isKindOfClass:[NSString class]] ? self.values[name] : nil;
}

- (nullable UIColor *)colorForName:(NSString *)name {
    return CYLColorValue([self valueForName:name]);
}

- (nullable UIFont *)fontForName:(NSString *)name {
    id value = [self valueForName:name];
    return value ? CYLFontValue(value) : nil;
}

- (nullable UIImage *)imageForName:(NSString *)name {
    id value = [self valueForName:name];
    if ([value isKindOfClass:[UIImage class]]) {
        return value;
    }
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    id image = CYLImageValue(value);
    return [image isKindOfClass:[UIImage class]] ? image : [UIImage imageNamed:value];
}

+ (UIColor *)cyl_colorNamed:(NSString *)name inManager:(CYLThemeManager *)manager theme:(id)theme {
    UIColor *color = [theme isKindOfClass:[CYLTabBarConfigurationTheme class]] ? [(CYLTabBarConfigurationTheme *)theme colorForName:name] : nil;
    if (color) {
        return color;
    }
    // [EN] Another kind of theme is current: the first skin of the file that has the color. [CN] 当前是其他类型的主题：使用文件中第一个提供该颜色的皮肤。
    for (id candidate in manager.themes) {
        color = [candidate isKindOfClass:[CYLTabBarConfigurationTheme class]] ? [(CYLTabBarConfigurationTheme *)candidate colorForName:name] : nil;
        if (color) {
            return color;
        }
    }
    return UIColor.clearColor;
}

+ (UIColor *)colorNamed:(NSString *)name {
    NSString *colorName = [name copy];
    return [UIColor cyl_colorWithName:colorName themeProvider:^UIColor *(CYLThemeManager *manager, id identifier, id theme) {
        return [CYLTabBarConfigurationTheme cyl_colorNamed:colorName inManager:manager theme:theme];
    }];
}

+ (UIColor *)colorNamed:(NSString *)name themeManagerName:(__kindof NSObject<NSCopying> *)managerName {
    NSString *colorName = [name copy];
    return [UIColor cyl_colorWithName:colorName themeManagerName:managerName provider:^UIColor *(CYLThemeManager *manager, id identifier, id theme) {
        return [CYLTabBarConfigurationTheme cyl_colorNamed:colorName inManager:manager theme:theme];
    }];
}

#pragma mark CYLTabBarTheme

- (nullable NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray array];
    BOOL themed = NO;
    NSUInteger position = 0;
    for (NSDictionary *item in tabBarController.tabBarItemsAttributes) {
        if (![item isKindOfClass:[NSDictionary class]] || [item[CYLTabBarItemPlusSlotPlaceholderKey] boolValue]) {
            continue;
        }
        NSString *identifier = CYLStringValue(item[CYLTabBarItemIdentifier]);
        NSDictionary<NSString *, NSString *> *references = identifier.length > 0 ? _references[identifier] : _references[@(position)];
        position++;
        NSMutableDictionary *raw = [NSMutableDictionary dictionary];
        for (NSString *key in references) {
            id value = self.values[references[key]];
            if (value) {
                raw[key] = value;
            }
        }
        themed = themed || raw.count > 0;
        // [EN] An empty entry keeps that tab as it is. [CN] 空条目让该 Tab 保持不变。
        [items addObject:raw.count > 0 ? CYLNormalizedItemAttributes(raw) : @{}];
    }
    return themed ? items : nil;
}

- (nullable UITabBarAppearance *)cyl_tabBarAppearanceForTabBarController:(CYLTabBarController *)tabBarController API_AVAILABLE(ios(13.0)) {
    UIColor *background = [self colorForName:CYLTabBarBackgroundColor];
    UIColor *shadow = [self colorForName:CYLTabBarShadowColor];
    UIColor *titleColor = [self colorForName:CYLTabBarItemTitleColor];
    UIColor *selectedTitleColor = [self colorForName:CYLTabBarItemSelectedTitleColor];
    UIColor *iconColor = [self colorForName:CYLTabBarItemIconColor];
    UIColor *selectedIconColor = [self colorForName:CYLTabBarItemSelectedIconColor];
    UIFont *titleFont = [self fontForName:CYLTabBarItemTitleFont];
    UIFont *selectedTitleFont = [self fontForName:CYLTabBarItemSelectedTitleFont] ?: titleFont;
    UIImage *backgroundImage = [self imageForName:CYLTabBarBackgroundImage];
    UIImage *shadowImage = [self imageForName:CYLTabBarShadowImage];
    NSString *positioning = [CYLStringValue([self valueForName:CYLTabBarStackedItemPositioning]) lowercaseString];
    id itemWidth = [self valueForName:CYLTabBarStackedItemWidth];
    id itemSpacing = [self valueForName:CYLTabBarStackedItemSpacing];
    BOOL layout = positioning.length > 0 || [itemWidth respondsToSelector:@selector(doubleValue)] || [itemSpacing respondsToSelector:@selector(doubleValue)];
    if (!background && !shadow && !titleColor && !selectedTitleColor && !iconColor && !selectedIconColor && !titleFont && !selectedTitleFont &&
        !backgroundImage && !shadowImage && !layout) {
        // [EN] No bar-wide values: the app's own appearance stays. [CN] 没有整个 TabBar 的值：保留 App 自己的外观。
        return nil;
    }
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    // [EN] A background color asks for an opaque bar, as the example's skins (`CYLDemoTheme`): over the default (blurred)
    //      background, Liquid Glass did not show it. [CN] 背景色需要不透明的 TabBar，与示例的皮肤（`CYLDemoTheme`）相同：
    //      在默认（模糊）背景上，液态玻璃不显示该颜色。
    if (background) {
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = background;
    } else {
        [appearance configureWithDefaultBackground];
    }
    if (shadow) {
        appearance.shadowColor = shadow;
    }
    if (backgroundImage) {
        appearance.backgroundImage = backgroundImage;
    }
    if (shadowImage) {
        appearance.shadowImage = shadowImage;
    }
    // [EN] How the items share the width: the system tab bar and the FlatDesign tab bar both read these. [CN] 各 Item 如何分配宽度：系统 TabBar 与扁平样式 TabBar 都会读取。
    if ([positioning isEqualToString:@"centered"]) {
        appearance.stackedItemPositioning = UITabBarItemPositioningCentered;
    } else if ([positioning isEqualToString:@"fill"]) {
        appearance.stackedItemPositioning = UITabBarItemPositioningFill;
    } else if ([positioning isEqualToString:@"automatic"]) {
        appearance.stackedItemPositioning = UITabBarItemPositioningAutomatic;
    } else if (positioning.length > 0) {
        CYLLogInvalidConfigurationValue(CYLTabBarStackedItemPositioning, positioning);
    }
    if ([itemWidth respondsToSelector:@selector(doubleValue)]) {
        appearance.stackedItemWidth = MAX([itemWidth doubleValue], 0);
    }
    if ([itemSpacing respondsToSelector:@selector(doubleValue)]) {
        appearance.stackedItemSpacing = MAX([itemSpacing doubleValue], 0);
    }
    [appearance cyl_applyItemAppearanceWithBlock:^(UITabBarItemAppearance *itemAppearance) {
        NSMutableDictionary *normal = [itemAppearance.normal.titleTextAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
        if (titleColor) {
            normal[NSForegroundColorAttributeName] = titleColor;
        }
        if (titleFont) {
            normal[NSFontAttributeName] = titleFont;
        }
        itemAppearance.normal.titleTextAttributes = normal;
        NSMutableDictionary *selected = [itemAppearance.selected.titleTextAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
        if (selectedTitleColor) {
            selected[NSForegroundColorAttributeName] = selectedTitleColor;
        }
        if (selectedTitleFont) {
            selected[NSFontAttributeName] = selectedTitleFont;
        }
        itemAppearance.selected.titleTextAttributes = selected;
        if (iconColor) {
            itemAppearance.normal.iconColor = iconColor;
        }
        if (selectedIconColor) {
            itemAppearance.selected.iconColor = selectedIconColor;
        }
    }];
    return appearance;
}

- (void)cyl_customizeTabBarController:(CYLTabBarController *)tabBarController {
    if (@available(iOS 13.0, *)) {
        return;
    }
    // [EN] Before iOS 13, the classic tab bar colors. [CN] iOS 13 以前使用经典的 TabBar 颜色。
    UITabBar *tabBar = tabBarController.tabBar;
    UIColor *background = [self colorForName:CYLTabBarBackgroundColor];
    if (background) {
        tabBar.barTintColor = background;
    }
    UIColor *selectedIconColor = [self colorForName:CYLTabBarItemSelectedIconColor];
    if (selectedIconColor) {
        tabBar.tintColor = selectedIconColor;
    }
    UIColor *iconColor = [self colorForName:CYLTabBarItemIconColor];
    if (iconColor) {
        tabBar.unselectedItemTintColor = iconColor;
    }
}

@end

@implementation CYLTabBarController (CYLConfigurationInitializers)

- (instancetype)initWithConfigurationFile:(NSString *)filePath error:(NSError **)error {
    if (![NSThread isMainThread]) {
        // [EN] UIKit objects only on the main thread (E1). [CN] UIKit 对象只能在主线程创建（E1）。
        if (error) {
            *error = [CYLTabBarController cyl_configurationMainThreadError];
        }
        return nil;
    }
    NSDictionary<NSString *, id> *configuration = [[self class] configurationWithContentsOfFile:filePath error:error];
    if (!configuration) {
        return nil;
    }
    self = [self initWithConfiguration:configuration];
    NSError *pagesError = [CYLTabBarController cyl_configurationPagesErrorForTabBarController:self];
    if (pagesError) {
        if (error) {
            *error = pagesError;
        }
        return nil;
    }
    return self;
}

+ (instancetype)tabBarControllerWithConfigurationFile:(NSString *)filePath error:(NSError **)error {
    return [[self alloc] initWithConfigurationFile:filePath error:error];
}

- (instancetype)initWithConfigurationRoute:(NSString *)route error:(NSError **)error {
    NSString *path = [CYLTabBarController cyl_pathOfConfigurationRoute:route error:error];
    return path ? [self initWithConfigurationFile:path error:error] : nil;
}

+ (instancetype)tabBarControllerWithConfigurationRoute:(NSString *)route error:(NSError **)error {
    return [[self alloc] initWithConfigurationRoute:route error:error];
}

/// [EN] A tab bar controller of `tabBarControllerClass` from a loaded configuration, or the error. [CN] 由加载的配置创建 `tabBarControllerClass` 的 TabBarController，或返回错误。
static void CYLFinishLoadedTabBarController(Class tabBarControllerClass, NSDictionary<NSString *, id> *configuration, NSError *error,
                                            CYLTabBarControllerConfigurationCompletion completion) {
    CYLTabBarController *tabBarController = configuration ? [[tabBarControllerClass alloc] initWithConfiguration:configuration] : nil;
    NSError *pagesError = configuration ? [CYLTabBarController cyl_configurationPagesErrorForTabBarController:tabBarController] : nil;
    completion(pagesError ? nil : tabBarController, pagesError ?: error);
}

+ (NSURLSessionDataTask *)loadTabBarControllerWithConfigurationURLRequest:(NSURLRequest *)request
                                                               completion:(CYLTabBarControllerConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    Class tabBarControllerClass = self;
    return [self loadConfigurationWithURLRequest:request completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
        CYLFinishLoadedTabBarController(tabBarControllerClass, configuration, error, completion);
    }];
}

+ (NSURLSessionDataTask *)loadTabBarControllerWithConfigurationURL:(NSURL *)URL
                                                        completion:(CYLTabBarControllerConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    Class tabBarControllerClass = self;
    return [self loadConfigurationWithURL:URL completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
        CYLFinishLoadedTabBarController(tabBarControllerClass, configuration, error, completion);
    }];
}

@end
