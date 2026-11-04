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
 * [EN] The skin (theme) demo of the examples: six tab bar themes registered with
 *      `CYLThemeManagerCenter.defaultThemeManager` (Default, Grapefruit, Grass, Pink Rose, Dark and a Spring Festival skin
 *      with holiday icons), each adopting `CYLTabBarTheme`, a theme picker, and the choice saved across launches. Part of
 *      the settings section (`UIViewController+CYLSettingsSection.h`); the ObjC example also has a "Skin" button in the
 *      navigation bar of its home page.
 * [CN] 示例中的换肤（主题）演示：向 `CYLThemeManagerCenter.defaultThemeManager` 注册六套 TabBar 主题（默认、西柚、青草、玫瑰粉、深色，
 *      以及带节日图标的春节皮肤），每套都遵守 `CYLTabBarTheme`；提供主题选择器，所选主题在下次启动时保留。属于设置分组
 *      （`UIViewController+CYLSettingsSection.h`）；ObjC 示例首页的导航栏还有一个“换肤”按钮。
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

@end

NS_ASSUME_NONNULL_END
