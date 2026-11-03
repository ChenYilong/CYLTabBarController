/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/01/26.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #425
 * [EN] App-wide default badge style. Most apps use the same badge everywhere (a red background, white text, one font,
 *      the same corner offset), but each badge property belongs to one object, so it had to be set on every tab,
 *      bar button and view again. Set the defaults here once, typically in
 *      `-application:didFinishLaunchingWithOptions:`, before showing badges:
 *
 *          CYLBadgeAppearance *appearance = [CYLBadgeAppearance globalAppearance];
 *          appearance.backgroundColor = [UIColor systemPinkColor];
 *          appearance.font = [UIFont boldSystemFontOfSize:10];
 *          appearance.centerOffset = CGPointMake(-2, 2);
 *
 *      Precedence: a value set on an object (e.g. `viewController.cyl_badgeBackgroundColor`) wins over the global one;
 *      the global one wins over the built-in default. This covers every badge host: UIViewController, UITabBarItem,
 *      UIBarButtonItem, UIControl and UIView.
 *
 *      Badges created later use the new defaults. A badge already on screen picks up new colors, font and border the
 *      next time it is shown (`-cyl_showBadgeValue:animationType:`); a red dot keeps its size and position until its
 *      style changes. So set the appearance before showing badges. Use it on the main thread, like the rest of UIKit.
 * [CN] App 全局的默认角标样式。大多数 App 的角标处处相同（红色背景、白色文字、同一种字体、同样的位置偏移），但角标属性都设置在
 *      单个对象上，每个 Tab、BarButton、视图都要重复设置一次。现在可以在这里统一设置一次，通常放在
 *      `-application:didFinishLaunchingWithOptions:` 中、显示角标之前（示例见上方英文部分）。
 *
 *      优先级：对象上单独设置的值（如 `viewController.cyl_badgeBackgroundColor`）优先于全局值；全局值优先于内置默认值。
 *      适用于所有角标宿主：UIViewController、UITabBarItem、UIBarButtonItem、UIControl 和 UIView。
 *
 *      之后创建的角标使用新的默认值。已经显示的角标在下次显示时（`-cyl_showBadgeValue:animationType:`）使用新的颜色、字体和边框；
 *      红点在样式改变前保持原有尺寸和位置。因此请在显示角标之前设置。请在主线程使用，与 UIKit 其他 API 一致。
 */
@interface CYLBadgeAppearance : NSObject

/*!
 * [EN] The shared global appearance. In Swift: `CYLBadgeAppearance.global`.
 * [CN] 全局共享的角标样式。Swift 中为 `CYLBadgeAppearance.global`。
 */
@property (class, nonatomic, readonly) CYLBadgeAppearance *globalAppearance NS_SWIFT_NAME(global);

/*!
 * [EN] Background color. Red by default; set nil to restore it. Dynamic colors follow Dark Mode.
 * [CN] 背景色，默认红色；设为 nil 恢复默认。动态颜色会跟随深色模式。
 */
@property (null_resettable, nonatomic, strong) UIColor *backgroundColor;

/*!
 * [EN] Text color. White by default; set nil to restore it.
 * [CN] 文字颜色，默认白色；设为 nil 恢复默认。
 */
@property (null_resettable, nonatomic, strong) UIColor *textColor;

/*!
 * [EN] Text font. `[UIFont boldSystemFontOfSize:9]` by default; set nil to restore it.
 * [CN] 文字字体，默认 `[UIFont boldSystemFontOfSize:9]`；设为 nil 恢复默认。
 */
@property (null_resettable, nonatomic, strong) UIFont *font;

/*!
 * [EN] Offset of the badge center from the host's top-right corner, {0, 0} by default. Positive x moves it right,
 *      positive y moves it down. Non-finite values are treated as 0.
 * [CN] 角标中心相对宿主右上角的偏移，默认 {0, 0}。x 为正向右，y 为正向下。非有限值按 0 处理。
 */
@property (nonatomic, assign) CGPoint centerOffset;

/*!
 * [EN] Radius of the red dot (`cyl_showBadge`, or a value of @""), 4 by default. 0, negative or non-finite values
 *      restore the default.
 * [CN] 红点（`cyl_showBadge` 或值为 @""）的半径，默认 4。0、负数或非有限值恢复默认。
 */
@property (nonatomic, assign) CGFloat radius;

/*!
 * [EN] Space added around the text of number and text badges, 8 by default. Negative or non-finite values are
 *      treated as 0.
 * [CN] 数字和文本角标在文字四周增加的空间，默认 8。负数或非有限值按 0 处理。
 */
@property (nonatomic, assign) CGFloat margin;

/*!
 * [EN] Numbers above it are shown as "<maximum>+", 99 by default. Values below 1 are treated as 1.
 * [CN] 超过该值的数字显示为 "<最大值>+"，默认 99。小于 1 的值按 1 处理。
 */
@property (nonatomic, assign) NSInteger maximumBadgeNumber;

/*!
 * [EN] Corner radius of number and text badges. 0 by default, which means automatic: half the badge height (a capsule).
 *      Negative or non-finite values are treated as 0.
 * [CN] 数字和文本角标的圆角半径。默认 0，表示自动：角标高度的一半（胶囊形）。负数或非有限值按 0 处理。
 */
@property (nonatomic, assign) CGFloat cornerRadius;

/*!
 * [EN] Border color, nil (no border) by default. Drawn only when `borderWidth` > 0.
 * [CN] 边框颜色，默认 nil（无边框）。仅当 `borderWidth` > 0 时绘制。
 */
@property (nullable, nonatomic, strong) UIColor *borderColor;

/*!
 * [EN] Border width, 0 by default. Negative or non-finite values are treated as 0.
 * [CN] 边框宽度，默认 0。负数或非有限值按 0 处理。
 */
@property (nonatomic, assign) CGFloat borderWidth;

/*!
 * [EN] Restores every property to its built-in default.
 * [CN] 将所有属性恢复为内置默认值。
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
