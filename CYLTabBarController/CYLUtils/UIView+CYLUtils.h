//
//  UIView+CYLUtils.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] View helpers used by both Core and CYLBadgeView. `-cyl_setHidden:` comes from `UIView+CYLTabBarControllerExtention.h`, `-cyl_isInvisiable` and `-cyl_canNotResponseEvent` from `UIView+CYLBadgeExtention.h`; both import this header.
 * [CN] Core 与 CYLBadgeView 共用的视图方法。`-cyl_setHidden:` 来自 `UIView+CYLTabBarControllerExtention.h`，`-cyl_isInvisiable`、`-cyl_canNotResponseEvent` 来自 `UIView+CYLBadgeExtention.h`，二者都会导入本头文件。
 */

#import <UIKit/UIKit.h>
#import "NSObject+CYLUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CYLUtils)

/*!
 * [EN] Hides or shows the receiver, also updating alpha, opaque and userInteractionEnabled together.
 * [CN] 隐藏或显示当前视图，同时联动修改 alpha、opaque 与 userInteractionEnabled。
 */
- (void)cyl_setHidden:(BOOL)hidden;

/*!
 * [EN] Returns YES if the view is effectively invisible: hidden, alpha ≈ 0, zero size, or not in a superview.
 * [CN] 判断视图是否实际不可见：hidden、alpha 接近 0、尺寸为零或没有父视图。
 */
- (BOOL)cyl_isInvisiable;

/*!
 * [EN] Returns YES if the view cannot receive touches: invisible, interaction disabled, or a placeholder.
 * [CN] 判断视图是否无法响应事件：不可见、禁用交互或为占位视图。
 */
- (BOOL)cyl_canNotResponseEvent;

/*!
 * FIX: issue #535
 * [EN] The keyframe animation suggested in the issue, for any view: scale 1.5, then 0.8, then back to 1.0 in 0.5 s,
 *      with UIView keyframes (it sets `transform`, so use it on views whose transform you do not set yourself).
 * [CN] issue 中建议的关键帧动画，可用于任意视图：0.5 秒内放大到 1.5 倍，缩小到 0.8 倍，再恢复到 1.0（使用 UIView 关键帧，会设置
 *      `transform`，请勿用于自己设置了 transform 的视图）。
 */
- (void)cyl_addScaleBounceAnimationWithCompletion:(nullable void (^)(BOOL finished))completion;

/*!
 * [EN] The receiver or its nearest superview that is a `UIControl`, looking up to `stopView` but not at it (nil: up to the
 *      window). For a hit-tested subview (an image view or a label inside a button), this is the button it belongs to.
 * [CN] 接收者本身或最近的 `UIControl` 父视图，向上查找到 `stopView` 为止且不包括它（nil：一直查找到 window）。对 hitTest 得到的
 *      子视图（按钮内的 imageView 或 label）而言，就是它所属的按钮。
 */
- (nullable UIControl *)cyl_nearestControlBelowView:(nullable UIView *)stopView;

@end

NS_ASSUME_NONNULL_END
