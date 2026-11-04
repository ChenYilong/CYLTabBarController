//
//  UIViewController+CYLTabBarItemUpdate.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLTabBarItemUpdate.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

static NSString *const CYLTabBarItemUpdateCellIdentifier = @"CYLTabBarItemUpdateCell";

/// Rows, each one switching one thing on the tab, or back. 每行切换 Tab 的一项，或恢复。
typedef NS_ENUM(NSInteger, CYLTabBarItemUpdateRow) {
    CYLTabBarItemUpdateRowTitle,        // `-updateTabBarItemForViewController:attributes:`
    CYLTabBarItemUpdateRowIconView,     // `-setTabBarItemIconViewProvider:atIndex:`
    CYLTabBarItemUpdateRowNetworkIcon,  // `-setTabBarItemIconWithURL:selectedURL:size:atIndex:`
    CYLTabBarItemUpdateRowAllNetworkIcons, // the same, for every tab
    CYLTabBarItemUpdateRowAllLocalIcons,   // `-setTabBarItemIcon:selectedIcon:size:atIndex:`, local images, for every tab
    CYLTabBarItemUpdateRowGIFIcon,      // the same, with a GIF
    CYLTabBarItemUpdateRowAllTitles,    // `-updateTabBarItemsWithAttributes:`
    CYLTabBarItemUpdateRowCount,
};

static char CYLTabBarItemInitialAttributesKey;
static char CYLTabBarItemTitleUpdatedKey;
static char CYLTabBarItemActiveIconRowKey;
static char CYLTabBarItemAllTitlesUpdatedKey;
static char CYLTabBarItemAllNetworkIconsKey;
static char CYLTabBarItemAllLocalIconsKey;
static char CYLPlusButtonInitialAttributesKey;

@implementation UIViewController (CYLTabBarItemUpdate)

- (NSInteger)cyl_tabBarItemUpdateRowCount {
    return CYLTabBarItemUpdateRowCount;
}

#pragma mark - Cells

- (UITableViewCell *)cyl_tabBarItemUpdateCellForTableView:(UITableView *)tableView row:(NSInteger)row {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLTabBarItemUpdateCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLTabBarItemUpdateCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    NSString *title = nil;
    NSString *subtitle = nil;
    NSString *symbolName = nil;
    switch (row) {
        case CYLTabBarItemUpdateRowTitle:
            title = CYLLocalizedString(@"更换 Tab 标题");
            subtitle = CYLLocalizedString(@"原地更换当前页 Tab 的标题，再点恢复");
            symbolName = @"textformat";
            break;
        case CYLTabBarItemUpdateRowIconView:
            title = CYLLocalizedString(@"切换 Tab 图标");
            subtitle = CYLLocalizedString(@"用自定义视图替换当前页 Tab 的图标，再点恢复");
            symbolName = @"star";
            break;
        case CYLTabBarItemUpdateRowNetworkIcon:
            title = CYLLocalizedString(@"下载网络图标");
            subtitle = CYLLocalizedString(@"从网络下载当前页 Tab 的图标（带缓存），再点恢复");
            symbolName = @"icloud.and.arrow.down";
            break;
        case CYLTabBarItemUpdateRowAllNetworkIcons:
            title = CYLLocalizedString(@"批量下载网络图标");
            subtitle = CYLLocalizedString(@"下载并更新所有 Tab 的图标，再点恢复");
            symbolName = @"square.and.arrow.down.on.square";
            break;
        case CYLTabBarItemUpdateRowAllLocalIcons:
            title = CYLLocalizedString(@"批量使用本地图标");
            subtitle = CYLLocalizedString(@"用本地图片（图片名、文件路径、UIImage、文件 URL）更新所有 Tab 的图标，再点恢复");
            symbolName = @"photo.on.rectangle";
            break;
        case CYLTabBarItemUpdateRowGIFIcon:
            title = CYLLocalizedString(@"GIF 动图图标");
            subtitle = CYLLocalizedString(@"当前页 Tab 显示 GIF 动图，再点恢复");
            symbolName = @"sparkles";
            break;
        default:
            title = CYLLocalizedString(@"批量更换标题");
            subtitle = CYLLocalizedString(@"一次更新所有 Tab 的标题，再点恢复");
            symbolName = @"list.bullet";
            break;
    }
    cell.textLabel.text = title;
    cell.detailTextLabel.text = subtitle;
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:symbolName];
    }
    cell.accessoryType = [self cyl_isTabBarItemUpdateRowActive:row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - Actions

- (void)cyl_didSelectTabBarItemUpdateRow:(NSInteger)row {
    CYLTabBarController *tabBarController = [self cyl_tabBarItemUpdateTabBarController];
    UIViewController *tabViewController = [self cyl_tabBarItemUpdateTabViewController];
    NSUInteger index = [tabBarController.viewControllers indexOfObject:tabViewController];
    if (!tabBarController || index == NSNotFound) {
        return;
    }
    [self cyl_initialTabBarItemsAttributesOfTabBarController:tabBarController];
    [self cyl_initialPlusButtonAttributesOfTabBarController:tabBarController];
    switch (row) {
        case CYLTabBarItemUpdateRowTitle:
            [self cyl_toggleTitleOfTabViewController:tabViewController inTabBarController:tabBarController];
            break;
        case CYLTabBarItemUpdateRowIconView:
        case CYLTabBarItemUpdateRowNetworkIcon:
        case CYLTabBarItemUpdateRowGIFIcon:
            [self cyl_toggleIconRow:row ofTabViewController:tabViewController atIndex:index inTabBarController:tabBarController];
            break;
        case CYLTabBarItemUpdateRowAllNetworkIcons:
        case CYLTabBarItemUpdateRowAllLocalIcons:
            [self cyl_toggleAllIconsRow:row inTabBarController:tabBarController];
            break;
        default:
            [self cyl_toggleAllTitlesInTabBarController:tabBarController];
            break;
    }
}

/// The title: "Purchased courses"; tapped again, the title of the `tabBarItemsAttributes` given at initialization.
/// 标题：“已购课程”；再次点击，恢复为初始化时传入的 `tabBarItemsAttributes` 中的标题。
- (void)cyl_toggleTitleOfTabViewController:(UIViewController *)tabViewController
                        inTabBarController:(CYLTabBarController *)tabBarController {
    BOOL isUpdated = [objc_getAssociatedObject(tabViewController, &CYLTabBarItemTitleUpdatedKey) boolValue];
    NSString *title = isUpdated ? [self cyl_initialTitleOfTabViewController:tabViewController inTabBarController:tabBarController]
                                : CYLLocalizedString(@"已购课程");
    if ([tabBarController updateTabBarItemForViewController:tabViewController attributes:@{CYLTabBarItemTitle : title ?: @""}]) {
        objc_setAssociatedObject(tabViewController, &CYLTabBarItemTitleUpdatedKey, (isUpdated ? nil : @YES),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

/// The icon: the one of this row; the same row again, the icon of the `tabBarItemsAttributes` given at initialization
/// (`nil` restores the tab's own icon). 图标：该行的图标；再次点击同一行，恢复为初始化时传入的 `tabBarItemsAttributes` 中的图标
/// （传 `nil` 即恢复 Tab 自身的图标）。
- (void)cyl_toggleIconRow:(NSInteger)row
      ofTabViewController:(UIViewController *)tabViewController
                  atIndex:(NSUInteger)index
       inTabBarController:(CYLTabBarController *)tabBarController {
    NSNumber *activeRow = objc_getAssociatedObject(tabViewController, &CYLTabBarItemActiveIconRowKey);
    if (activeRow && activeRow.integerValue == row) {
        [self cyl_restoreInitialIconOfTabViewController:tabViewController atIndex:index inTabBarController:tabBarController];
        objc_setAssociatedObject(tabViewController, &CYLTabBarItemActiveIconRowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    BOOL isSet = NO;
    if (row == CYLTabBarItemUpdateRowIconView) {
        if (@available(iOS 13.0, *)) {
            // Any view works here, e.g. a `UIImageView` loaded by SDWebImage or Kingfisher. 这里可以是任意视图。
            isSet = [tabBarController setTabBarItemIconViewProvider:^UIView *(BOOL selected) {
                UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:(selected ? @"star.fill" : @"star")]];
                iconView.tintColor = selected ? [UIColor systemOrangeColor] : [UIColor systemGrayColor];
                iconView.contentMode = UIViewContentModeScaleAspectFit;
                iconView.frame = CGRectMake(0, 0, 25, 25);
                return iconView;
            } atIndex:index];
        }
    } else if (row == CYLTabBarItemUpdateRowNetworkIcon) {
        // Downloaded once, then from the cache; the tab keeps its icon until the images are ready.
        // 只下载一次，之后读取缓存；图片就绪前 Tab 保持自身图标。
        isSet = [tabBarController setTabBarItemIconWithURL:[NSURL URLWithString:@"https://cdn-icons-png.flaticon.com/512/3132/3132732.png"]
                                               selectedURL:[NSURL URLWithString:@"https://cdn-icons-png.flaticon.com/512/3132/3132779.png"]
                                                      size:CGSizeMake(24, 24)
                                                   atIndex:index];
    } else {
        // Any URL, a file one here. 任何 URL 都可以，这里使用本地文件 URL。
        NSURL *GIFURL = [CYLResourceBundle() URLForResource:@"cyl_tab_sample_animated" withExtension:@"gif"];
        isSet = GIFURL && [tabBarController setTabBarItemIconWithURL:GIFURL selectedURL:nil size:CGSizeMake(24, 24) atIndex:index];
    }
    if (isSet) {
        objc_setAssociatedObject(tabViewController, &CYLTabBarItemActiveIconRowKey, @(row), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

/// Every tab's title with a star; tapped again, the titles of the `tabBarItemsAttributes` given at initialization.
/// 所有 Tab 的标题加上星号；再次点击，恢复为初始化时传入的 `tabBarItemsAttributes` 中的标题。
- (void)cyl_toggleAllTitlesInTabBarController:(CYLTabBarController *)tabBarController {
    BOOL isUpdated = [objc_getAssociatedObject(tabBarController, &CYLTabBarItemAllTitlesUpdatedKey) boolValue];
    // One entry per tab, in order, none for the plus button: the shape `-updateTabBarItemsWithAttributes:` takes.
    // 每个 Tab 一项、按顺序、PlusButton 不占项：即 `-updateTabBarItemsWithAttributes:` 接受的结构。
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:tabBarController];
    NSMutableArray<NSDictionary *> *attributes = [NSMutableArray array];
    for (UIViewController *viewController in tabBarController.viewControllers) {
        if (viewController.cyl_isPlaceholder || viewController == plusChildViewController) {
            continue;
        }
        NSString *title = nil;
        if (isUpdated) {
            title = [self cyl_initialTitleOfTabViewController:viewController inTabBarController:tabBarController];
            // Every title is the initial one again, also the one of "Change tab title". 所有标题都已恢复，包括“更换 Tab 标题”的。
            objc_setAssociatedObject(viewController, &CYLTabBarItemTitleUpdatedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
            title = [NSString stringWithFormat:@"★ %@", [self cyl_titleOfTabViewController:viewController inTabBarController:tabBarController] ?: @""];
        }
        [attributes addObject:@{CYLTabBarItemTitle : title ?: @""}];
    }
    [tabBarController updateTabBarItemsWithAttributes:attributes];
    // [EN] The plus button's title too. [CN] PlusButton 的标题也一并修改。
    NSString *plusTitle = [CYLPlusButton plusButtonForOwner:tabBarController].cyl_title;
    NSString *initialPlusTitle = [self cyl_initialPlusButtonAttributesOfTabBarController:tabBarController][CYLTabBarItemTitle];
    if (isUpdated && initialPlusTitle) {
        [tabBarController updatePlusButtonWithAttributes:@{ CYLTabBarItemTitle : initialPlusTitle }];
    } else if (!isUpdated && plusTitle) {
        [tabBarController updatePlusButtonWithAttributes:@{ CYLTabBarItemTitle : [NSString stringWithFormat:@"★ %@", plusTitle] }];
    }
    objc_setAssociatedObject(tabBarController, &CYLTabBarItemAllTitlesUpdatedKey, (isUpdated ? nil : @YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 * [EN] The icons of every tab, in order (repeated past the fourth tab), unselected then selected. From the network
 *      (`CYLTabBarItemUpdateRowAllNetworkIcons`), or local (`CYLTabBarItemUpdateRowAllLocalIcons`), one kind of source
 *      per tab: an image name, the absolute path of a file, a `UIImage`, a file `NSURL` (a GIF). A local image the app
 *      does not have falls back to a symbol.
 * [CN] 每个 Tab 的图标，按顺序（超过 4 个 Tab 时循环使用），先未选中后选中。来自网络（`CYLTabBarItemUpdateRowAllNetworkIcons`），或来自本地
 *      （`CYLTabBarItemUpdateRowAllLocalIcons`），每个 Tab 一种来源：图片名、文件绝对路径、`UIImage`、文件 `NSURL`（GIF）。App 中没有的本地
 *      图片改用系统符号。
 */
- (NSArray<NSArray *> *)cyl_iconsOfAllIconsRow:(NSInteger)row {
    if (row == CYLTabBarItemUpdateRowAllNetworkIcons) {
        return @[
            @[ @"https://cdn-icons-png.flaticon.com/512/1946/1946488.png", @"https://cdn-icons-png.flaticon.com/512/1946/1946436.png" ],
            @[ @"https://cdn-icons-png.flaticon.com/512/2099/2099085.png", @"https://cdn-icons-png.flaticon.com/512/2099/2099085.png" ],
            @[ @"https://cdn-icons-png.flaticon.com/512/2099/2099100.png", @"https://cdn-icons-png.flaticon.com/512/2099/2099100.png" ],
            @[ @"https://cdn-icons-png.flaticon.com/512/1077/1077063.png", @"https://cdn-icons-png.flaticon.com/512/1077/1077114.png" ],
        ];
    }
    id (^symbol)(NSString *, UIColor *) = ^id(NSString *name, UIColor *color) {
        if (@available(iOS 13.0, *)) {
            return [[UIImage systemImageNamed:name] imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        return name;
    };
    // [EN] An image name, as `CYLTabBarItemImage`. [CN] 图片名，与 `CYLTabBarItemImage` 相同。
    id named = [UIImage imageNamed:@"img_tab_home_0"] ? @"img_tab_home_0" : symbol(@"house", UIColor.systemGrayColor);
    id namedSelected = [UIImage imageNamed:@"img_tab_home_1"] ? @"img_tab_home_1" : symbol(@"house.fill", UIColor.systemOrangeColor);
    // [EN] The absolute path of a file (#535). [CN] 文件的绝对路径（#535）。
    id path = [[NSBundle mainBundle] pathForResource:@"img_tab_message_0" ofType:@"png"] ?: symbol(@"envelope", UIColor.systemGrayColor);
    id pathSelected = [[NSBundle mainBundle] pathForResource:@"img_tab_message_1" ofType:@"png"] ?: symbol(@"envelope.fill", UIColor.systemOrangeColor);
    // [EN] A file URL of a GIF, in the library's resource bundle. [CN] 本库资源包中 GIF 的文件 URL。
    id fileURL = [CYLResourceBundle() URLForResource:@"cyl_tab_sample_animated" withExtension:@"gif"] ?: symbol(@"sparkles", UIColor.systemPurpleColor);
    return @[
        @[ named, namedSelected ],
        @[ path, pathSelected ],
        @[ symbol(@"heart", UIColor.systemGrayColor), symbol(@"heart.fill", UIColor.systemRedColor) ], // [EN] A UIImage. [CN] UIImage。
        @[ fileURL, fileURL ],
    ];
}

/// [EN] The plus button's normal and selected images of `row`: from the network, or a `UIImage`.
/// [CN] `row` 中 PlusButton 的普通与选中图片：来自网络，或 `UIImage`。
- (NSArray *)cyl_plusButtonIconsOfAllIconsRow:(NSInteger)row {
    if (row == CYLTabBarItemUpdateRowAllNetworkIcons) {
        return @[ @"https://cdn-icons-png.flaticon.com/512/992/992651.png", @"https://cdn-icons-png.flaticon.com/512/1828/1828817.png" ];
    }
    if (@available(iOS 13.0, *)) {
        return @[ [[UIImage systemImageNamed:@"plus.circle"] imageWithTintColor:UIColor.systemOrangeColor renderingMode:UIImageRenderingModeAlwaysOriginal],
                  [[UIImage systemImageNamed:@"plus.circle.fill"] imageWithTintColor:UIColor.systemOrangeColor renderingMode:UIImageRenderingModeAlwaysOriginal] ];
    }
    return @[ @"img_tab_home_0", @"img_tab_home_1" ];
}

/*!
 * [EN] Updates the icon of every tab with the icons of `row`, network or local (`-setTabBarItemIcon:selectedIcon:size:atIndex:`);
 *      tapped again, the icons of the `tabBarItemsAttributes` given at initialization.
 * [CN] 用 `row` 的图标（网络或本地，`-setTabBarItemIcon:selectedIcon:size:atIndex:`）更新所有 Tab 的图标；再次点击，恢复为初始化时传入的
 *      `tabBarItemsAttributes` 中的图标。
 */
- (void)cyl_toggleAllIconsRow:(NSInteger)row inTabBarController:(CYLTabBarController *)tabBarController {
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:tabBarController];
    const void *key = (row == CYLTabBarItemUpdateRowAllNetworkIcons) ? &CYLTabBarItemAllNetworkIconsKey : &CYLTabBarItemAllLocalIconsKey;
    const void *otherKey = (key == &CYLTabBarItemAllNetworkIconsKey) ? &CYLTabBarItemAllLocalIconsKey : &CYLTabBarItemAllNetworkIconsKey;
    BOOL isActive = [objc_getAssociatedObject(tabBarController, key) boolValue];
    NSArray<NSArray *> *icons = [self cyl_iconsOfAllIconsRow:row];
    NSUInteger tabIndex = 0;
    NSArray<UIViewController *> *viewControllers = tabBarController.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        UIViewController *viewController = viewControllers[index];
        if (viewController.cyl_isPlaceholder || viewController == plusChildViewController) {
            continue;
        }
        // [EN] Replaces this tab's own icon row as well. [CN] 同时取代该 Tab 单独设置的图标行。
        objc_setAssociatedObject(viewController, &CYLTabBarItemActiveIconRowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (isActive) {
            [self cyl_restoreInitialIconOfTabViewController:viewController atIndex:index inTabBarController:tabBarController];
        } else {
            NSArray *tabIcons = icons[tabIndex % icons.count];
            [tabBarController setTabBarItemIcon:tabIcons[0] selectedIcon:tabIcons[1] size:CGSizeMake(24, 24) atIndex:index];
        }
        tabIndex++;
    }
    // [EN] The plus button's images too: the row's, or the initial ones. [CN] PlusButton 的图片也一并修改：该行的，或初始的。
    NSDictionary *initialPlusAttributes = [self cyl_initialPlusButtonAttributesOfTabBarController:tabBarController];
    if (isActive) {
        NSMutableDictionary *imageAttributes = [initialPlusAttributes mutableCopy];
        [imageAttributes removeObjectForKey:CYLTabBarItemTitle];
        if (imageAttributes.count > 0) {
            [tabBarController updatePlusButtonWithAttributes:imageAttributes];
        }
    } else {
        NSArray *plusIcons = [self cyl_plusButtonIconsOfAllIconsRow:row];
        [tabBarController updatePlusButtonWithAttributes:@{ CYLTabBarItemImageURL : plusIcons[0], CYLTabBarItemSelectedImageURL : plusIcons[1] }];
    }
    // [EN] One of the two rows at a time. [CN] 两行同一时间只有一行生效。
    objc_setAssociatedObject(tabBarController, key, (isActive ? nil : @YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(tabBarController, otherKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Helpers

/// The `tabBarItemsAttributes` given at initialization, one entry per tab (its view controller), copied before the
/// first change of these rows: the tab bar controller merges each update into its `tabBarItemsAttributes`.
/// 初始化时传入的 `tabBarItemsAttributes`，每个 Tab（其视图控制器）一项，在这些行第一次修改前复制：TabBarController 会把每次更新合并进
/// `tabBarItemsAttributes`。
- (NSMapTable<UIViewController *, NSDictionary *> *)cyl_initialTabBarItemsAttributesOfTabBarController:(CYLTabBarController *)tabBarController {
    NSMapTable *attributes = objc_getAssociatedObject(tabBarController, &CYLTabBarItemInitialAttributesKey);
    if (!attributes) {
        attributes = [NSMapTable weakToStrongObjectsMapTable];
        [tabBarController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger index, BOOL *stop) {
            NSDictionary *tabAttributes = [tabBarController tabBarItemAttributesAtIndex:index];
            if (tabAttributes) {
                [attributes setObject:[tabAttributes copy] forKey:viewController];
            }
        }];
        objc_setAssociatedObject(tabBarController, &CYLTabBarItemInitialAttributesKey, attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return attributes;
}

/// [EN] The plus button's title and images before the first change of these rows (`-updatePlusButtonWithAttributes:` keys).
/// [CN] 这些行第一次修改前 PlusButton 的标题与图片（`-updatePlusButtonWithAttributes:` 的 key）。
- (NSDictionary *)cyl_initialPlusButtonAttributesOfTabBarController:(CYLTabBarController *)tabBarController {
    NSDictionary *attributes = objc_getAssociatedObject(tabBarController, &CYLPlusButtonInitialAttributesKey);
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:tabBarController];
    if (!attributes && plusButton) {
        NSMutableDictionary *initialAttributes = [NSMutableDictionary dictionary];
        initialAttributes[CYLTabBarItemTitle] = plusButton.cyl_title;
        initialAttributes[CYLTabBarItemImage] = [plusButton imageForState:UIControlStateNormal];
        initialAttributes[CYLTabBarItemSelectedImage] = [plusButton imageForState:UIControlStateSelected];
        attributes = [initialAttributes copy];
        objc_setAssociatedObject(tabBarController, &CYLPlusButtonInitialAttributesKey, attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return attributes ?: @{};
}

/// The title of the `tabBarItemsAttributes` given at initialization. 初始化时传入的 `tabBarItemsAttributes` 中的标题。
- (NSString *)cyl_initialTitleOfTabViewController:(UIViewController *)tabViewController
                               inTabBarController:(CYLTabBarController *)tabBarController {
    NSDictionary *attributes = [[self cyl_initialTabBarItemsAttributesOfTabBarController:tabBarController] objectForKey:tabViewController];
    return attributes[CYLTabBarItemTitle] ?: [self cyl_titleOfTabViewController:tabViewController inTabBarController:tabBarController];
}

/// The icon of the `tabBarItemsAttributes` given at initialization, back on the tab at `index`: its icons from the
/// network when it has `CYLTabBarItemImageURL`, else its own icon (`nil` provider).
/// 将 Tab 恢复为初始化时传入的 `tabBarItemsAttributes` 中的图标：有 `CYLTabBarItemImageURL` 时为网络图标，否则为 Tab 自身的图标（provider 传 nil）。
- (void)cyl_restoreInitialIconOfTabViewController:(UIViewController *)tabViewController
                                          atIndex:(NSUInteger)index
                               inTabBarController:(CYLTabBarController *)tabBarController {
    NSDictionary *attributes = [[self cyl_initialTabBarItemsAttributesOfTabBarController:tabBarController] objectForKey:tabViewController];
    NSMutableDictionary *URLAttributes = [NSMutableDictionary dictionary];
    for (NSString *key in @[ CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize ]) {
        URLAttributes[key] = attributes[key];
    }
    if (URLAttributes[CYLTabBarItemImageURL]) {
        [tabBarController updateTabBarItemAtIndex:index attributes:URLAttributes];
    } else {
        [tabBarController setTabBarItemIconViewProvider:nil atIndex:index];
    }
}

- (CYLTabBarController *)cyl_tabBarItemUpdateTabBarController {
    return [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
}

/// The tab of this page: its navigation controller, or itself. 当前页面所在的 Tab：其导航控制器或自身。
- (UIViewController *)cyl_tabBarItemUpdateTabViewController {
    return self.navigationController ?: self;
}

/// The title a tab shows: FlatDesign shows `cyl_tabBarItem`, the other styles `tabBarItem`.
/// Tab 显示的标题：扁平样式显示 `cyl_tabBarItem`，其他样式显示 `tabBarItem`。
- (NSString *)cyl_titleOfTabViewController:(UIViewController *)tabViewController
                        inTabBarController:(CYLTabBarController *)tabBarController {
#if CYL_FLATDESIGN_AVAILABLE
    if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
        return tabViewController.cyl_tabBarItem.title;
    }
#endif
    return tabViewController.tabBarItem.title;
}

- (BOOL)cyl_isTabBarItemUpdateRowActive:(NSInteger)row {
    UIViewController *tabViewController = [self cyl_tabBarItemUpdateTabViewController];
    switch (row) {
        case CYLTabBarItemUpdateRowTitle:
            return [objc_getAssociatedObject(tabViewController, &CYLTabBarItemTitleUpdatedKey) boolValue];
        case CYLTabBarItemUpdateRowIconView:
        case CYLTabBarItemUpdateRowNetworkIcon:
        case CYLTabBarItemUpdateRowGIFIcon: {
            NSNumber *activeRow = objc_getAssociatedObject(tabViewController, &CYLTabBarItemActiveIconRowKey);
            return activeRow != nil && activeRow.integerValue == row;
        }
        case CYLTabBarItemUpdateRowAllNetworkIcons:
            return [objc_getAssociatedObject([self cyl_tabBarItemUpdateTabBarController], &CYLTabBarItemAllNetworkIconsKey) boolValue];
        case CYLTabBarItemUpdateRowAllLocalIcons:
            return [objc_getAssociatedObject([self cyl_tabBarItemUpdateTabBarController], &CYLTabBarItemAllLocalIconsKey) boolValue];
        default:
            return [objc_getAssociatedObject([self cyl_tabBarItemUpdateTabBarController], &CYLTabBarItemAllTitlesUpdatedKey) boolValue];
    }
}

@end
