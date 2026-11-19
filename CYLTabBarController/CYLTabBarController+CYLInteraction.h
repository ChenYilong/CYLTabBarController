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

#import "CYLTabBarControllerTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #535
 * [EN] Called on a long press on a tab button or the plus button.
 * [CN] 长按 Tab 按钮或 PlusButton 时回调。
 */
#ifndef __swift__
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
