//
//  CYLAnimationEngineSwiftTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLTabBarController
import CYLAnimatedItem

/**
 [EN] The animation engine's move to Swift (docs/Swift-Migration.md, 2026-11-21): every ported type keeps its Objective-C
      name, selectors and protocol list, so Objective-C callers and runtime lookups keep working.
 [CN] 动画引擎迁移到 Swift（docs/Swift-Migration.md，2026-11-21）：每个迁移的类型保留其 Objective-C 名称、选择器与协议列表，
      Objective-C 调用方与运行时查找继续可用。
 */
final class CYLAnimationEngineSwiftTests: XCTestCase {

    func testTabButtonPlayerKeepsItsObjectiveCSelector() {
        let control = UIControl()
        XCTAssertTrue(control.responds(to: NSSelectorFromString("cyl_tabBarItemAnimationPlayer")))
        XCTAssertNil(control.cyl_tabBarItemAnimationPlayer, "no animation view, no player")
    }
}
