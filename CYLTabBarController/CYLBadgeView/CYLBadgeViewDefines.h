//
//  CYLBadgeViewDefines.h
//  CYLBadgeView
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] Shared by the CYLBadgeView sources only; not part of the public API.
 *      Everything CYLBadgeView and Core both use (macros, `-cyl_setHidden:`, `-cyl_valueForKey:`, `-cyl_tabButton`,
 *      `CYLLocalizedString()`, `+[CYLUtils isLiquidGlassActive]`...) comes from CYLUtils, which both depend on.
 *      `CYL_BADGE_CORE_AVAILABLE` is only for what exists in Core alone, the tab bar: with Core, a tab button's badge
 *      goes on its icon or Lottie view and is mirrored to the Liquid Glass platter; on its own
 *      (`pod 'CYLTabBarController/CYLBadgeView'`) the badge goes on the control or the tab icon. Like the Lottie
 *      guards, it is set with `__has_include`.
 * [CN] 仅供 CYLBadgeView 源文件内部使用，不属于公开 API。
 *      CYLBadgeView 与 Core 共同使用的内容（宏、`-cyl_setHidden:`、`-cyl_valueForKey:`、`-cyl_tabButton`、`CYLLocalizedString()`、
 *      `+[CYLUtils isLiquidGlassActive]` 等）都来自二者共同依赖的 CYLUtils。
 *      `CYL_BADGE_CORE_AVAILABLE` 只用于 Core 独有的 TabBar 部分：有 Core 时，Tab 按钮的角标显示在图标或 Lottie 视图上，并同步到液态
 *      玻璃 platter；单独使用（`pod 'CYLTabBarController/CYLBadgeView'`）时，角标显示在控件或 Tab 图标上。与 Lottie 的隔离方式相同，
 *      通过 `__has_include` 判断。
 */

#ifndef CYLBadgeViewDefines_h
#define CYLBadgeViewDefines_h

#import <UIKit/UIKit.h>
#import "CYLUtils.h"

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#define CYL_BADGE_CORE_AVAILABLE 1
#import <CYLTabBarController/CYLTabBarController.h>
#elif __has_include("CYLTabBarController.h")
#define CYL_BADGE_CORE_AVAILABLE 1
#import "CYLTabBarController.h"
#else
#define CYL_BADGE_CORE_AVAILABLE 0
#endif

#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The animation a badge plays for `animationType`, sized for a badge of `badgeSize`; nil for
 *      `CYLBadgeAnimationTypeNone`. Add it with the key `CYLBadgeAnimationKeyForType(animationType)`. Shared by the
 *      library's badges (`-[UIView cyl_beginAnimation]`) and the system badge of a bar button item on iOS 26+; private to
 *      CYLBadgeView, not public API.
 * [CN] 角标在 `animationType` 下播放的动画，按 `badgeSize` 计算幅度；`CYLBadgeAnimationTypeNone` 时为 nil。使用
 *      `CYLBadgeAnimationKeyForType(animationType)` 作为 key 添加。由本库角标（`-[UIView cyl_beginAnimation]`）与 iOS 26+ 上
 *      bar button item 的系统角标共用；仅供 CYLBadgeView 内部使用，不是公开 API。
 */
FOUNDATION_EXTERN CAAnimation *_Nullable CYLBadgeAnimationForType(CYLBadgeAnimationType animationType, CGSize badgeSize);

/*!
 * [EN] A transparent view that holds a badge outside the view the badge belongs to, so nothing clips or covers it. It is
 *      either the top-most subview of a container, or sits right above a given sibling; constraints keep it on
 *      `alignView`'s frame, and it follows the `hidden` and `alpha` of the views it is told to follow (KVO on their
 *      layers). Used for hosts that clip (UIView+CYLBadgeExtention) and for the badges of controls (UIControl+CYLBadgeExtention).
 * [CN] 透明视图，在角标所属视图之外承载角标，使其不被裁剪或遮挡。它要么是容器最上层的子视图，要么紧贴某个兄弟视图之上；约束使其与
 *      `alignView` 的 frame 对齐，并跟随指定视图的 `hidden`、`alpha`（KVO 其 layer）。用于会裁剪的宿主（UIView+CYLBadgeExtention）
 *      以及控件的角标（UIControl+CYLBadgeExtention）。
 */
@interface CYLBadgeHostOverlayView : UIView
/// The view it is aligned to. 对齐的视图。
@property (nonatomic, weak, readonly, nullable) UIView *host;
- (void)cyl_attachToContainer:(UIView *)container
                 aboveSubview:(nullable UIView *)sibling
                alignedToView:(UIView *)alignView
    followingVisibilityOfViews:(NSArray<UIView *> *)views;
/// Right above `host` in its superview, aligned to it and following its visibility. 紧贴 `host` 之上，与其对齐并跟随其可见性。
- (void)cyl_attachToHost:(UIView *)host;
- (void)cyl_detach;
/// Removes this view from its superview when `owner` is deallocated. `owner` 销毁时将本视图移除。
- (void)cyl_removeWhenDeallocated:(id)owner;
@end

NS_ASSUME_NONNULL_END

#endif /* CYLBadgeViewDefines_h */
