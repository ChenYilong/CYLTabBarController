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

@end

NS_ASSUME_NONNULL_END
