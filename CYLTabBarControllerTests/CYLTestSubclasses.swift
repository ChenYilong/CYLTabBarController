//
//  CYLTestSubclasses.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] A plus button as an app makes it: its stand-in comes from `+plusButton`. Swift, because `CYLPlusButton` becomes an
      `open` Swift class in phase ② of the migration (docs/Swift-Migration.md, step 108; docs/Subclassing-In-Swift.md);
      the tests in CYLThemeTests.m use it through `CYLTabBarControllerTests-Swift.h`.
 [CN] App 的 PlusButton：其替身来自 `+plusButton`。用 Swift 编写：迁移第 ② 阶段 `CYLPlusButton` 将成为 `open` 的 Swift 类（第 108 步）；
      CYLThemeTests.m 通过 `CYLTabBarControllerTests-Swift.h` 使用它。
 */
@objc(CYLTestPlusButton)
public final class CYLTestPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {
    public static func plusButton() -> Any {
        CYLTestPlusButton()
    }
}

/**
 [EN] A subclass that overrides the delegate method and calls super, as the examples do (CYLTabBarToolkitTests.m).
 [CN] 与示例一样重写代理方法并调用 super 的子类（CYLTabBarToolkitTests.m）。
 */
@objc(CYLSuperCallingTabBarController)
public final class CYLSuperCallingTabBarController: CYLTabBarController {
    @objc public var shouldSelectCalls = 0

    public override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        shouldSelectCalls += 1
        return super.tabBarController(tabBarController, shouldSelect: viewController)
    }
}
