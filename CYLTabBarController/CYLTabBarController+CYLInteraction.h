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

// [EN] `UIViewController (CYLTabButtonAnimation)` (`cyl_tabButtonAnimation`) is public Swift since the class switch
//      (Swift/CYLTabBarController+CYLInteraction.swift). [CN] `UIViewController (CYLTabButtonAnimation)`（`cyl_tabButtonAnimation`）自类切换起为
//      公开的 Swift（Swift/CYLTabBarController+CYLInteraction.swift）。

NS_ASSUME_NONNULL_END
