//
//  UIColor+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
// [CN] Copyright © 2026年 https://github.com/ChenYilong .All rights reserved.
// [EN] Copyright © 2026 https://github.com/ChenYilong .All rights reserved.
//

#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (CYLTabBarControllerExtention)

@property (class, nonatomic, readonly) UIColor *cyl_systemRedColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemGreenColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemBlueColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemOrangeColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemYellowColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemPinkColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemPurpleColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemTealColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemIndigoColor;


/* Shades of gray. systemGray is the base gray color.
 */
@property (class, nonatomic, readonly) UIColor *cyl_systemGrayColor;
@property (class, nonatomic, readonly) UIColor *cyl_systemGray2Color;
@property (class, nonatomic, readonly) UIColor *cyl_systemGray3Color;
@property (class, nonatomic, readonly) UIColor *cyl_systemGray4Color;
@property (class, nonatomic, readonly) UIColor *cyl_systemGray5Color;
@property (class, nonatomic, readonly) UIColor *cyl_systemGray6Color;

#pragma mark Foreground colors

/* Foreground colors for static text and related elements.
 */
@property (class, nonatomic, readonly) UIColor *cyl_labelColor;
@property (class, nonatomic, readonly) UIColor *cyl_secondaryLabelColor;
@property (class, nonatomic, readonly) UIColor *cyl_tertiaryLabelColor ;
@property (class, nonatomic, readonly) UIColor *cyl_quaternaryLabelColor;

/* Foreground color for standard system links.
 */
@property (class, nonatomic, readonly) UIColor *cyl_linkColor;

/* Foreground color for placeholder text in controls or text fields or text views.
 */
@property (class, nonatomic, readonly) UIColor *cyl_placeholderTextColor;

/* Foreground colors for separators (thin border or divider lines).
 * `separatorColor` may be partially transparent, so it can go on top of any content.
 * `opaqueSeparatorColor` is intended to look similar, but is guaranteed to be opaque, so it will
 * completely cover anything behind it. Depending on the situation, you may need one or the other.
 */
@property (class, nonatomic, readonly) UIColor *cyl_separatorColor;
@property (class, nonatomic, readonly) UIColor *cyl_opaqueSeparatorColor;

#pragma mark Background colors

/* We provide two design systems (also known as "stacks") for structuring an iOS app's backgrounds.
 *
 * Each stack has three "levels" of background colors. The first color is intended to be the
 * main background, farthest back. Secondary and tertiary colors are layered on top
 * of the main background, when appropriate.
 *
 * Inside of a discrete piece of UI, choose a stack, then use colors from that stack.
 * We do not recommend mixing and matching background colors between stacks.
 * The foreground colors above are designed to work in both stacks.
 *
 * 1. systemBackground
 *    Use this stack for views with standard table views, and designs which have a white
 *    primary background in light mode.
 */
@property (class, nonatomic, readonly) UIColor *cyl_systemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *cyl_secondarySystemBackgroundColor;
@property (class, nonatomic, readonly) UIColor *cyl_tertiarySystemBackgroundColor;

/* 2. systemGroupedBackground
 *    Use this stack for views with grouped content, such as grouped tables and
 *    platter-based designs. These are like grouped table views, but you may use these
 *    colors in places where a table view wouldn't make sense.
 */
@property (class, nonatomic, readonly) UIColor *cyl_systemGroupedBackgroundColor;
@property (class, nonatomic, readonly) UIColor *cyl_secondarySystemGroupedBackgroundColor;
@property (class, nonatomic, readonly) UIColor *cyl_tertiarySystemGroupedBackgroundColor;

#pragma mark Fill colors

/* Fill colors for UI elements.
 * These are meant to be used over the background colors, since their alpha component is less than 1.
 *
 * systemFillColor is appropriate for filling thin and small shapes.
 * Example: The track of a slider.
 */
@property (class, nonatomic, readonly) UIColor *cyl_systemFillColor;

/* secondarySystemFillColor is appropriate for filling medium-size shapes.
 * Example: The background of a switch.
 */
@property (class, nonatomic, readonly) UIColor *cyl_secondarySystemFillColor;

/* tertiarySystemFillColor is appropriate for filling large shapes.
 * Examples: Input fields, search bars, buttons.
 */
@property (class, nonatomic, readonly) UIColor *cyl_tertiarySystemFillColor;

/* quaternarySystemFillColor is appropriate for filling large areas containing complex content.
 * Example: Expanded table cells.
 */
@property (class, nonatomic, readonly) UIColor *cyl_quaternarySystemFillColor;

#pragma mark Other colors

/* lightTextColor is always light, and darkTextColor is always dark, regardless of the current UIUserInterfaceStyle.
 * When possible, we recommend using `labelColor` and its variants, instead.
 * for a dark background
 */
@property(class, nonatomic, readonly) UIColor *cyl_lightTextColor;

/*!
 * for a light background
 */
@property(class, nonatomic, readonly) UIColor *cyl_darkTextColor;

#pragma mark Dark Mode

/*!
 * FIX: issue #552
 * [EN] A color that follows Dark Mode: `darkColor` where the view's interface style is dark, `lightColor` otherwise
 *      (including iOS 12 and an unspecified style). It is resolved each time it is drawn, so it switches with the system
 *      setting and with any `overrideUserInterfaceStyle` on a window, view controller or view. Returns `lightColor` when
 *      `darkColor` is nil.
 *
 *          tabBar.backgroundColor = [UIColor cyl_colorWithLightColor:UIColor.whiteColor darkColor:UIColor.blackColor];
 *
 *      Don't pick one of the two yourself by checking `UITraitCollection.currentTraitCollection` (or the screen's or
 *      window scene's traits) when you set the color: outside of drawing that style is often unspecified, the scene
 *      ignores overrides, and the color would not change when the style does.
 * [CN] 跟随深色模式的颜色：视图为深色界面风格时为 `darkColor`，否则为 `lightColor`（包括 iOS 12 和未指定风格）。
 *      每次绘制时解析，因此会随系统设置以及 window、视图控制器、视图上的 `overrideUserInterfaceStyle` 切换。
 *      `darkColor` 为 nil 时返回 `lightColor`。
 *
 *      不要在设置颜色时通过 `UITraitCollection.currentTraitCollection`（或屏幕、window scene 的 trait）自行判断并二选一：
 *      在绘制之外，此时的风格往往是 unspecified，scene 也不认 override，而且风格切换后颜色不会跟着变。
 */
+ (UIColor *)cyl_colorWithLightColor:(UIColor *)lightColor darkColor:(nullable UIColor *)darkColor NS_SWIFT_NAME(cyl_color(withLight:dark:));

/*!
 * [EN] A new random color each time it is read: any hue, with saturation and brightness kept between 0.5 and 1, so
 *      white badge text stays readable on it. Used by the demos for badges, e.g.
 *
 *          self.navigationItem.rightBarButtonItem.cyl_badgeBackgroundColor = UIColor.cyl_randomColor;
 *
 * [CN] 每次读取都返回一个新的随机颜色：色相任意，饱和度和亮度保持在 0.5～1 之间，白色角标文字在其上依然清晰。Demo 用它给角标
 *      设置随机颜色（示例见上）。
 * Swift would drop "Color"
 */
@property (class, nonatomic, readonly) UIColor *cyl_randomColor NS_SWIFT_NAME(cyl_randomColor);

@end

#pragma mark - Deprecated API

@interface UIColor (CYLTabBarControllerDeprecated)

@property (class, nonatomic, readonly, nullable) UIColor *cyl_systemBrownColor CYL_DEPRECATED("Deprecated in 1.27.5.");

@end
NS_ASSUME_NONNULL_END
