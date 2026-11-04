//
//  UIViewController+CYLThemeSettings.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #216
 * [EN] The skin (theme) demo of the examples: sixteen tab bar themes registered with
 *      `CYLThemeManagerCenter.defaultThemeManager`, each adopting `CYLTabBarTheme`: five color themes (Default,
 *      Grapefruit, Grass, Pink Rose, Dark) and eleven holiday skins with their own icons (Spring Festival, Christmas,
 *      Halloween, Valentine's Day, Mid-Autumn, Easter, New Year, Summer, Birthday, Space, Ocean). The icons are Fluent
 *      Emoji (MIT License, Microsoft), in the library's resource bundle. A theme picker, a theme list section, and the
 *      choice saved across launches. Part of the settings section (`UIViewController+CYLSettingsSection.h`); the ObjC
 *      example also has a "Skin" button in the navigation bar of its home page.
 * [CN] 示例中的换肤（主题）演示：向 `CYLThemeManagerCenter.defaultThemeManager` 注册十六套 TabBar 主题，每套都遵守 `CYLTabBarTheme`：
 *      五个配色主题（默认、西柚、青草、玫瑰粉、深色）与十一个带自己图标的节日皮肤（春节、圣诞节、万圣节、情人节、中秋节、复活节、新年、
 *      夏日、生日、太空、海洋）。图标为 Fluent Emoji（MIT 许可证，Microsoft），位于本库资源包中。提供主题选择器、主题列表 section，
 *      所选主题在下次启动时保留。属于设置分组（`UIViewController+CYLSettingsSection.h`）；ObjC 示例首页的导航栏还有一个“换肤”按钮。
 */
@interface UIViewController (CYLThemeSettings)

/*!
 * [EN] Registers the demo themes once and makes the saved one current (Default the first time). Call it at launch,
 *      before the tab bar controller appears, so the saved skin shows from the start; the theme row also calls it.
 * [CN] 注册演示主题（只执行一次），并将保存的主题设为当前主题（首次为默认主题）。请在启动时、TabBarController 显示之前调用，
 *      使保存的皮肤从一开始就生效；主题行也会调用它。
 */
+ (void)cyl_setUpThemeSettings;

/*!
 * [EN] The theme row of the settings section: the current theme, a tap opens the picker.
 * [CN] 设置分组中的主题行：显示当前主题，点击打开主题选择器。
 */
- (UITableViewCell *)cyl_themeSettingsCellForTableView:(UITableView *)tableView;

/*!
 * [EN] Shows the theme picker (an action sheet): one action per theme, and "Follow the system Dark Mode" on iOS 13+.
 *      Picking a theme switches it at once in every tab bar style.
 * [CN] 显示主题选择器（action sheet）：每个主题一项，iOS 13+ 还有“跟随系统深色模式”。选择后立即切换，适用于所有 TabBar 样式。
 * @param sourceView [EN] Where the popover points on iPad, e.g. the tapped cell; nil for the view controller's view.
 *                   [CN] iPad 上弹出框指向的视图，例如被点击的 cell；传 nil 时为当前控制器的 view。
 * @param completion [EN] Runs after a theme was picked, e.g. to reload the row. [CN] 选择主题后执行，例如刷新该行。
 */
- (void)cyl_presentThemePickerFromView:(nullable UIView *)sourceView completion:(nullable void (^)(void))completion;

/*!
 * [EN] A section of its own that lists every demo theme, one row each: five color themes and eleven holiday skins
 *      (Spring Festival, Christmas, Halloween, Valentine's Day, Mid-Autumn, Easter, New Year, Summer, Birthday, Space,
 *      Ocean) with Fluent Emoji icons. A tap applies the theme; the current one has a checkmark. Use the four methods
 *      below in a table view's data source and delegate.
 * [CN] 单独的一个 section，每行一个演示主题：五个配色主题与十一个使用 Fluent Emoji 图标的节日皮肤（春节、圣诞节、万圣节、情人节、
 *      中秋节、复活节、新年、夏日、生日、太空、海洋）。点击应用该主题，当前主题显示勾号。在列表的数据源与代理中使用下面四个方法。
 */
- (NSString *)cyl_themeListSectionTitle;

/// [EN] Number of rows of the theme list section. [CN] 主题列表 section 的行数。
- (NSInteger)cyl_themeListRowCount;

/// [EN] The cell of a theme: its name, its first icon (or color), a checkmark when current. [CN] 主题的 cell：名字、第一个图标（或颜色）、当前主题显示勾号。
- (UITableViewCell *)cyl_themeListCellForTableView:(UITableView *)tableView row:(NSInteger)row;

/// [EN] Applies the theme of `row`; reload the section afterwards for the checkmark. [CN] 应用第 `row` 行的主题；之后请刷新该 section 以更新勾号。
- (void)cyl_didSelectThemeListRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
