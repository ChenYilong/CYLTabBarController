//
//  CYLTabButtonAnimation.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #535
 * [EN] Tap animations of tab buttons and the plus button. The protocol `CYLTabButtonAnimation` and the classes
 *      `CYLTabButtonScaleAnimation`, `CYLTabButtonZoomInAnimation`, `CYLTabButtonBounceAnimation`,
 *      `CYLTabButtonRotationAnimation`, `CYLTabButtonFumeAnimation`, `CYLTabButtonPressAnimation`,
 *      `CYLTabButtonBlockAnimation`, `CYLTabButtonFlipAnimation` and `CYLTabButtonFrameAnimation` are implemented in Swift
 *      (`Swift/CYLTabButtonAnimation.swift`, docs/Swift-Migration.md, step 46), with their Objective-C names, selectors and
 *      documentation; Objective-C callers get their declarations from the generated Swift interface imported at the end.
 *      Only the block types stay here, for Objective-C.
 *
 *          CYLTabButtonBlockAnimation *animation = [CYLTabButtonBlockAnimation new];
 *          animation.selectAnimation = ^(UIControl *button, UIView *iconView, UILabel *titleLabel) {
 *              [[CYLTabButtonBounceAnimation new] cyl_playSelectAnimationWithTabButton:button iconView:iconView titleLabel:titleLabel];
 *          };
 *          tabBarController.cyl_defaultTabButtonAnimation = animation;
 *
 * [CN] Tab 按钮与 PlusButton 的点击动画。协议 `CYLTabButtonAnimation` 及上述各类在 Swift 中实现（`Swift/CYLTabButtonAnimation.swift`，
 *      docs/Swift-Migration.md，第 46 步），保留 Objective-C 名称、selector 与文档；Objective-C 调用方从末尾导入的 Swift 生成接口获得声明。
 *      这里只为 Objective-C 保留 block 类型。
 */
@protocol CYLTabButtonAnimation;

#ifndef __swift__
/*!
 * [EN] The signature of the animation blocks of `CYLTabButtonBlockAnimation`: the same arguments as the protocol methods.
 * [CN] `CYLTabButtonBlockAnimation` 中动画 block 的签名：参数与协议方法相同。
 */
typedef void (^CYLTabButtonAnimationBlock)(UIControl *button, UIView *iconView, UILabel *_Nullable titleLabel);

/*!
 * [EN] The signature of `CYLTabButtonBlockAnimation.badgeChangedAnimation`.
 * [CN] `CYLTabButtonBlockAnimation.badgeChangedAnimation` 的签名。
 */
typedef void (^CYLTabButtonBadgeAnimationBlock)(UIControl *button, UIView *iconView, UIView *_Nullable badgeView);
#endif

// [EN] `-[UIView cyl_addScaleBounceAnimationWithCompletion:]` (the issue's keyframe animation for any view) is in CYLUtils.
// [CN] `-[UIView cyl_addScaleBounceAnimationWithCompletion:]`（issue 中可用于任意视图的关键帧动画）位于 CYLUtils。

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
