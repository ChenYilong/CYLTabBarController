//
//  UIViewController+CYLTheme.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CYLThemeManager;

/*!
 * FIX: issue #216
 * [EN] How a view controller follows the theme, see `CYLThemeManager`.
 * [CN] 视图控制器如何跟随主题，见 `CYLThemeManager`。
 */
@interface UIViewController (CYLTheme)

/*!
 * [EN] Called when the theme changes, whether the view controller is visible or not; the default implementation passes
 *      it on to every child view controller and to the view controller this one presents, and updates the status bar.
 *      Every child gets it, also the tabs not shown yet: their view may not be loaded, so do not touch `self.view` here
 *      just to restyle it (check `isViewLoaded`), and do not count on it coming after `-viewDidLoad` or
 *      `-viewWillAppear:`. `CYLTabBarController` restyles its tab bar here. Call super when you override it.
 * [CN] 主题切换时调用，无论该控制器是否可见；默认实现会传递给所有子控制器以及由它 present 出的控制器，并刷新状态栏。
 *      所有子控制器都会收到，包括尚未显示的 Tab：其 view 可能尚未加载，不要仅为了更新样式而在这里访问 `self.view`（先判断
 *      `isViewLoaded`），也不要假定它一定晚于 `-viewDidLoad` 或 `-viewWillAppear:`。`CYLTabBarController` 在这里更新 TabBar 外观。
 *      重写时请调用 super。
 * @param manager [EN] The manager whose theme changed. [CN] 主题发生变化的管理器。
 * @param identifier [EN] The identifier of the new theme. [CN] 新主题的 identifier。
 * @param theme [EN] The new theme object. [CN] 新的主题对象。
 */
- (void)cyl_themeDidChangeByManager:(CYLThemeManager *)manager
                         identifier:(nullable __kindof NSObject<NSCopying> *)identifier
                              theme:(nullable __kindof NSObject *)theme NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
