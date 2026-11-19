//
//  CYLTabBarController+CYLInteraction.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
// [EN] The category needs the class; CYLTabBarController.h imports this header at its end, after the class.
// [CN] 分类需要类的声明；CYLTabBarController.h 在文件末尾（类声明之后）导入本头文件。
#import "CYLTabBarController.h"
#import "CYLTabButtonAnimation.h"
#import "CYLTabBarTransition.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #535
 * [EN] Built-in tap animations, see `cyl_tabButtonTapAnimationType`.
 * [CN] 内置的点击动画，见 `cyl_tabButtonTapAnimationType`。
 */
typedef NS_ENUM(NSInteger, CYLTabButtonTapAnimationType) {
    /*!
     * [EN] No animation (default). [CN] 无动画（默认）。
     */
    CYLTabButtonTapAnimationTypeNone = 0,
    /*!
     * [EN] 1.0 → 1.5 → 0.8 → 1.0, `CYLTabButtonScaleAnimation`. [CN] 放大再缩小。
     */
    CYLTabButtonTapAnimationTypeScale,
    /*!
     * [EN] Grows from small, `CYLTabButtonZoomInAnimation`. [CN] 从小放大。
     */
    CYLTabButtonTapAnimationTypeZoomIn,
    /*!
     * [EN] Elastic bounce, `CYLTabButtonBounceAnimation`. [CN] 弹性动画。
     */
    CYLTabButtonTapAnimationTypeBounce,
    /*!
     * [EN] Bounce with fireworks. [CN] 弹性动画加烟花。
     */
    CYLTabButtonTapAnimationTypeBounceWithFireworks,
    /*!
     * [EN] One full turn, `CYLTabButtonRotationAnimation`. [CN] 旋转一圈。
     */
    CYLTabButtonTapAnimationTypeRotation,
    /*!
     * [EN] Flip from left, `CYLTabButtonFlipAnimation`. [CN] 从左翻转。
     */
    CYLTabButtonTapAnimationTypeFlip,
    /*!
     * [EN] Icon down, title floats away, `CYLTabButtonFumeAnimation`. [CN] 图标下移、标题飘散。
     */
    CYLTabButtonTapAnimationTypeFume,
};

/*!
 * FIX: issue #535
 * [EN] Called on a long press on a tab button or the plus button.
 * [CN] 长按 Tab 按钮或 PlusButton 时回调。
 */
#ifndef __swift__
typedef void (^CYLTabBarControllerDidLongPressControlBlock)(CYLTabBarController *tabBarController, UIControl *control);
#endif

/*!
 * FIX: issue #535
 * [EN] A tap animation for this view controller's tab only; takes precedence over the tab bar controller's.
 * [CN] 仅用于该控制器所在 Tab 的点击动画，优先于 TabBarController 的设置。
 */
@interface UIViewController (CYLTabButtonAnimation)

@property (nonatomic, strong, nullable, setter=cyl_setTabButtonAnimation:) id<CYLTabButtonAnimation> cyl_tabButtonAnimation;

@end

NS_ASSUME_NONNULL_END
