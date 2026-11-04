//
//  UIView+CYLTheme.h
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
 * [EN] How a view follows the theme. When the theme of a `CYLThemeManager` changes, every view of the visible windows
 *      (hidden ones included, so they are right when shown) gets `-cyl_themeDidChangeByManager:identifier:theme:`. No
 *      UIKit method is swizzled: a view added to a window later reads its theme colors when it is drawn, as any
 *      dynamic color. Also done for every view, without registering anything:
 *      - labels and text views redraw (their text colors follow);
 *      - `UITabBar`, `UINavigationBar` and `UIToolbar` assign their appearances again, so the theme colors in them
 *        follow (for a tab bar of `CYLTabBarController`, prefer the `CYLTabBarTheme` protocol, see
 *        `CYLTabBarController.h`).
 * [CN] 视图如何跟随主题。`CYLThemeManager` 的主题切换时，可见 window 上的所有视图（包括隐藏的视图，显示时即为正确样式）都会收到
 *      `-cyl_themeDidChangeByManager:identifier:theme:`。不会 hook 任何 UIKit 方法：之后才加入 window 的视图在绘制时读取主题颜色，
 *      与其他动态颜色相同。无需注册，所有视图都会：
 *      - UILabel 与 UITextView 重新绘制（文字颜色随之更新）；
 *      - `UITabBar`、`UINavigationBar`、`UIToolbar` 重新设置各自的 appearance，使其中的主题颜色随之更新（`CYLTabBarController`
 *        的 TabBar 推荐使用 `CYLTabBarTheme` 协议，见 `CYLTabBarController.h`）。
 */
@interface UIView (CYLTheme)

/*!
 * [EN] Registers properties of the receiver to set again when the theme changes, by their getter names, e.g.
 *      `@[ @"backgroundColor", @"tintColor" ]`; the setter follows the usual naming (`setBackgroundColor:`). A property
 *      that holds a theme color (`+[UIColor cyl_colorWithThemeProvider:]`) gets a fresh copy of it, any other object
 *      that is not a color or an image (e.g. an `NSAttributedString`) is set again as is; plain colors and images are
 *      left alone, so a style set later in code is kept.
 * [CN] 按 getter 名注册主题切换时需要重新设置的属性，例如 `@[ @"backgroundColor", @"tintColor" ]`；setter 按常规命名
 *      （`setBackgroundColor:`）。持有主题颜色（`+[UIColor cyl_colorWithThemeProvider:]`）的属性会得到该颜色的新副本；
 *      非颜色、非图片的其他对象（例如 `NSAttributedString`）原样重新设置；普通颜色与图片保持不变，后来在代码中设置的样式不会被覆盖。
 */
- (void)cyl_registerThemeColorProperties:(NSArray<NSString *> *)getters;

/*!
 * [EN] Removes properties registered with `-cyl_registerThemeColorProperties:`.
 * [CN] 移除通过 `-cyl_registerThemeColorProperties:` 注册的属性。
 */
- (void)cyl_unregisterThemeColorProperties:(NSArray<NSString *> *)getters;

/*!
 * [EN] Called when the theme changes: sets the registered properties again, redraws labels and text views, applies the
 *      bar appearances again, then runs `cyl_themeDidChangeBlock`. Override it for anything else (an enum, a layer's
 *      `CGColor`...) and call super.
 * [CN] 主题切换时调用：重新设置已注册的属性，重绘 UILabel 与 UITextView，重新应用 Bar 的 appearance，然后执行
 *      `cyl_themeDidChangeBlock`。其他内容（枚举值、layer 的 `CGColor` 等）可重写本方法处理，并调用 super。
 * @param manager [EN] The manager whose theme changed. [CN] 主题发生变化的管理器。
 * @param identifier [EN] The identifier of the new theme. [CN] 新主题的 identifier。
 * @param theme [EN] The new theme object. [CN] 新的主题对象。
 */
- (void)cyl_themeDidChangeByManager:(nullable CYLThemeManager *)manager
                         identifier:(nullable __kindof NSObject<NSCopying> *)identifier
                              theme:(nullable __kindof NSObject *)theme NS_REQUIRES_SUPER;

/*!
 * [EN] Runs at the end of `-cyl_themeDidChangeByManager:identifier:theme:`, a block instead of a subclass.
 * [CN] 在 `-cyl_themeDidChangeByManager:identifier:theme:` 末尾执行，无需子类化即可响应主题切换。
 */
@property (nonatomic, copy, nullable) void (^cyl_themeDidChangeBlock)(void);

@end

NS_ASSUME_NONNULL_END
