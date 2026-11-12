/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

// CYL-SWIFT-MIGRATION: objc-shell — [EN] `CYLBaseViewController` stays an Objective-C class because Objective-C code subclasses it
//      (the demo's view controllers, apps); it holds no logic: each lifecycle method only calls the
//      `-cyl_…NavigationSetting` methods of `UIViewController (CYLTabBarControllerExtention)`, which move to Swift
//      with that category (docs/Swift-Migration.md).
//      [CN] `CYLBaseViewController` 保留为 Objective-C 类，因为 Objective-C 代码会继承它（示例中的控制器、App）；它不含逻辑：每个生命周期
//      方法只调用 `UIViewController (CYLTabBarControllerExtention)` 的 `-cyl_…NavigationSetting` 方法，这些方法随该类别迁移到
//      Swift（docs/Swift-Migration.md）。
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CYLBaseViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
