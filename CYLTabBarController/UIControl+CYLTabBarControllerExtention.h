//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN
/*!
 * [EN] `UIControl (CYLTabBarControllerExtention)` and `UIControl (CYLTabBarControllerExtentionDeprecated)` are implemented in
 *      Swift (`Swift/UIControl+CYLTabBarControllerExtention.swift`, every selector kept) and declared by the generated Swift
 *      interface (`CYLSwiftInterface.h`), imported at the end of this header (docs/Swift-Migration.md, step 26).
 * [CN] `UIControl (CYLTabBarControllerExtention)` 与 `UIControl (CYLTabBarControllerExtentionDeprecated)` 在 Swift 中实现
 *      （`Swift/UIControl+CYLTabBarControllerExtention.swift`，所有 selector 不变），由 Swift 生成接口（`CYLSwiftInterface.h`）声明，
 *      该接口在本头文件末尾导入（docs/Swift-Migration.md，第 26 步）。
 */

/*!
 * FIX: issue #604
 * [EN] Library-neutral tab icon animation (Lottie, PAG, Rive…). Every call goes to the animation service of the
 *      `CYLTabBarItemAnimation` subspec; without an animation subspec they do nothing. They replace the deprecated
 *      Lottie-named methods above (`-cyl_lottieAnimationView`, `-cyl_addLottieImageWithLottieURL:…`…).
 * [CN] 与动画库无关的 Tab 图标动画方法（Lottie、PAG、Rive…）。每个调用都交给 `CYLTabBarItemAnimation` 子库的动画服务；没有引入
 *      动画子库时不做处理。它们取代上面已废弃的 Lottie 命名方法（`-cyl_lottieAnimationView`、`-cyl_addLottieImageWithLottieURL:…`…）。
 */
/*!
 * [EN] `UIControl (CYLTabBarItemAnimation)` is public Swift (every selector kept); Objective-C reads it from the generated Swift
 *      interface since docs/Swift-Migration.md step 119. [CN] `UIControl (CYLTabBarItemAnimation)` 为公开的 Swift（selector 不变）；
 *      自第 119 步起 Objective-C 通过生成的 Swift 接口读取。
 */

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
