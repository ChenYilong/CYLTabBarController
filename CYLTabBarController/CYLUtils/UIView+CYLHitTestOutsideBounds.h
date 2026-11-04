//
//  UIView+CYLHitTestOutsideBounds.h
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #535
 * [EN] A subview that sticks out of its superview does not get touches outside the superview: UIKit stops at the
 *      superview's bounds. Set `cyl_respondsOutsideSuperviewBounds = YES` on such a subview (e.g. a raised button on a
 *      custom bar, or a badge you can tap) and it gets them again. Ported from the issue's `UIView (Chain)`
 *      (`ableRespose`): instead of a swizzle installed for every app at launch, it is installed the first time the
 *      property is set to YES, it hit-tests the subview's own subviews too, and it skips hidden, transparent and
 *      non-interactive superviews. The tab bars of this library already handle the plus button and its subviews
 *      (`touchableAreaOutsets`, `-hitTestInteractiveSubview:withEvent:`); this is for your own views.
 * [CN] 超出父视图的子视图在父视图范围之外收不到点击：UIKit 在父视图边界处就停止查找。对这样的子视图（例如自定义栏上凸起的按钮，或可点击的角标）
 *      设置 `cyl_respondsOutsideSuperviewBounds = YES` 即可重新接收点击。移植自 issue 中的 `UIView (Chain)`（`ableRespose`）：
 *      不在 App 启动时为所有 App 交换方法，而是在第一次设为 YES 时才安装；会继续对该子视图的子视图做 hitTest；并跳过隐藏、透明、
 *      不可交互的父视图。本库的 TabBar 已经处理 PlusButton 及其子视图（`touchableAreaOutsets`、`-hitTestInteractiveSubview:withEvent:`），
 *      本属性用于你自己的视图。
 */
@interface UIView (CYLHitTestOutsideBounds)

/// [EN] Default NO. [CN] 默认 NO。
@property (nonatomic, assign, getter=cyl_respondsOutsideSuperviewBounds, setter=cyl_setRespondsOutsideSuperviewBounds:) BOOL cyl_respondsOutsideSuperviewBounds;

@end

NS_ASSUME_NONNULL_END
