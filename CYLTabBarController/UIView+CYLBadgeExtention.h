/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CYLBadgeProtocol.h"
@protocol CYLBadgeTextDisplaying;

NS_ASSUME_NONNULL_BEGIN

#pragma mark -- badge apis

@interface UIView (CYLBadgeExtention)<CYLBadgeProtocol>
/*!
 * [EN] The badge view: a `UILabel` by default, a `CYLTabBarBadgeView` for the Liquid Glass badge on iOS 27.
 *      The two are unrelated classes, so it is typed by what they share, `CYLBadgeTextDisplaying`.
 * [CN] 角标视图：默认是 `UILabel`，iOS 27 液态玻璃下是 `CYLTabBarBadgeView`。
 *      两者没有继承关系，因此按共有的 `CYLBadgeTextDisplaying` 协议声明类型。
 */
@property (nonatomic, strong, getter=cyl_badge, setter=cyl_setBadge:) UIView<CYLBadgeTextDisplaying> *cyl_badge;

/*!
 * [EN] Returns YES if a badge is currently shown on this view.
 * [CN] 判断当前视图上是否正在显示角标。
 */
- (BOOL)cyl_isShowBadge;

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 * [EN] Shows a red-dot badge on this view with no animation.
 * [CN] 在当前视图上显示红点角标，无动画。
 */
- (void)cyl_showBadge;

/**
 *  cyl_showBadge
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType animationType
 * [EN] Shows a badge with `value` (@"" for a red dot) and the given animation.
 *      Works with Auto Layout: if this view is not laid out yet, the badge is shown once it is (no `dispatch_after`
 *      needed), and it stays on the view's top-right corner when the view is resized.
 * [CN] 显示值为 value 的角标（传 @"" 为红点），并使用指定动画。
 *      支持自动布局：视图尚未完成布局时，会在布局完成后显示角标（无需 `dispatch_after`）；视图尺寸改变时角标保持在右上角。
 */
- (void)cyl_showBadgeValue:(NSString *)value
         animationType:(CYLBadgeAnimationType)animationType;
;

// wBadgeStyle default is CYLBadgeStyleNumber ;
// CYLBadgeAnimationType defualt is  CYLBadgeAnimationTypeNone

/*!
 * [EN] Shows a badge with `value` and no animation.
 * [CN] 显示值为 value 的角标，无动画。
 */
- (void)cyl_showBadgeValue:(NSString *)value;

/**
 *  clear badge(hide badge)
 * [EN] Hides the badge on this view.
 * [CN] 隐藏当前视图上的角标。
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 * [EN] Shows the badge again if one exists and was hidden.
 * [CN] 若角标存在且被隐藏，则重新显示。
 */
- (void)cyl_resumeBadge;

/*!
 * [EN] Returns YES if the badge is paused (hidden but kept).
 * [CN] 判断角标是否处于暂停（隐藏但保留）状态。
 */
- (BOOL)cyl_isPauseBadge;

/*!
 * [EN] Returns YES if the view is effectively invisible: hidden, alpha ≈ 0, zero size, or not in a superview.
 * [CN] 判断视图是否实际不可见：hidden、alpha 接近 0、尺寸为零或没有父视图。
 */
- (BOOL)cyl_isInvisiable;

/*!
 * [EN] Same as `-cyl_isInvisiable`.
 * [CN] 同 -cyl_isInvisiable。
 */
- (BOOL)cyl_isHidden;

/*!
 * [EN] Returns YES if the view cannot receive touches: invisible, interaction disabled, or a placeholder.
 * [CN] 判断视图是否无法响应事件：不可见、禁用交互或为占位视图。
 */
- (BOOL)cyl_canNotResponseEvent;

/*!
 * 在 cyl_getActualBadgeSuperView方法中使用
 * [EN] Returns the content view that a badge should be attached to (e.g. the image view of a tab button or bar button).
 * [CN] 返回角标应附着的内容视图（如 Tab 按钮或 BarButton 的图片视图）。
 */
- (UIView *)cyl_findBarButtonContentView;

@property (nonatomic, assign, getter=cyl_keepShowingPlusButtonLabel, setter=cyl_setKeepShowingPlusButtonLabel:) BOOL cyl_keepShowingPlusButtonLabel;

/*!
 * [EN] Border color of the badge, nil (no border) by default. Dynamic colors follow Dark Mode. Drawn only when
 *      `cyl_badgeBorderWidth` > 0.
 * [CN] 角标边框颜色，默认 nil（无边框）。动态颜色会跟随深色模式。仅当 `cyl_badgeBorderWidth` > 0 时绘制。
 */
@property (nonatomic, strong, nullable, getter=cyl_badgeBorderColor, setter=cyl_setBadgeBorderColor:) UIColor *cyl_badgeBorderColor;

/*!
 * [EN] Border width of the badge, 0 by default. Negative or non-finite values are treated as 0.
 * [CN] 角标边框宽度，默认 0。负数或非有限值按 0 处理。
 */
@property (nonatomic, assign, getter=cyl_badgeBorderWidth, setter=cyl_setBadgeBorderWidth:) CGFloat cyl_badgeBorderWidth;

/*!
 * [EN] YES by default: while the system's Reduce Motion setting is on, badges are shown without animation.
 *      Set NO to always animate.
 * [CN] 默认 YES：系统开启"减弱动态效果"时，角标不播放动画。设为 NO 则始终播放。
 */
@property (nonatomic, assign, getter=cyl_badgeRespectsReduceMotion, setter=cyl_setBadgeRespectsReduceMotion:) BOOL cyl_badgeRespectsReduceMotion;

/*!
 * [EN] Puts an existing badge back on top of this view's top-right corner, re-applies its border, and restores its
 *      repeating animation if UIKit removed it. Call it after rebuilding the view's content; it does nothing if no
 *      badge has been shown.
 * [CN] 将已有角标重新放到当前视图右上角的最上层，重新应用边框，并在循环动画被 UIKit 移除时恢复。
 *      在重建视图内容后调用；从未显示过角标时不做任何事。
 */
- (void)cyl_refreshBadge;

@end

NS_ASSUME_NONNULL_END

