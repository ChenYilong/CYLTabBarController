//
//  CYLTabBarController+CYLCompatibility.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The deprecated Lottie names kept for compatibility (they forward to the neutral animation API) and `-rootWindow`,
 *      declared in `CYLTabBarController (CYLTabBarControllerDeprecated)` and `CYLTabBarController (CYLRootWindow)`. Internal
 *      Swift members with the Objective-C selectors: the generated header must not declare a category of the class (it
 *      is read before it). Translated from Objective-C (docs/Swift-Migration.md, step 104).
 * [CN] 为兼容保留的已废弃 Lottie 名称（转发给通用动画 API）与 `-rootWindow`，声明于 `CYLTabBarController (CYLTabBarControllerDeprecated)` 与
 *      `CYLTabBarController (CYLRootWindow)`。以 Objective-C selector 实现的内部 Swift 成员：生成的头文件不能声明该类的类别（它在类之前被读取）。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 104 步）。
 */
extension CYLTabBarController {

    @objc(lottieURLs)
    func cylLottieURLs() -> NSMutableArray {
        tabBarItemAnimationURLs
    }

    @objc(lottieSizes)
    func cylLottieSizes() -> NSMutableArray {
        tabBarItemAnimationSizes
    }

    @objc(isLottieViewAdded)
    func cylIsLottieViewAdded() -> Bool {
        isTabBarItemAnimationViewAdded
    }

    @objc(rootWindow)
    func cylRootWindow() -> UIWindow {
        CYLGetRootWindow()
    }
}
