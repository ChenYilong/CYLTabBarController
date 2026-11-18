//
//  CYLAnimatedItemTestTag.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLAnimatedItem

/**
 [EN] A tag as another repository would write it: a delete accessory, a badge read with the title, a state hook. Swift,
      because CYLAnimatedItemView is a Swift class since step 60 and Objective-C cannot subclass a Swift class; the tests
      in CYLAnimatedItemViewTests.m use it through `CYLTabBarControllerTests-Swift.h`.
 [CN] 其他仓库会这样写的标签：删除附加图标、随标题朗读的角标、状态钩子。用 Swift 编写：自第 60 步起 CYLAnimatedItemView 是 Swift 类，Objective-C
      不能继承 Swift 类；CYLAnimatedItemViewTests.m 通过 `CYLTabBarControllerTests-Swift.h` 使用它。
 */
@objc(CYLAnimatedItemTestTag)
@objcMembers
public final class CYLAnimatedItemTestTag: CYLAnimatedItemView {
    /** [EN] A badge read after the title. [CN] 在标题后朗读的角标。 */
    public var badge: String? {
        didSet { updateItemAccessibility() }
    }
    /** [EN] How many times the state hook ran. [CN] 状态钩子运行的次数。 */
    public var stateChanges = 0

    public override func itemAccessibilityLabel() -> String? {
        guard let badge = badge else { return title }
        return "\(title ?? ""), \(badge)"
    }

    public override func itemStateDidChange() {
        stateChanges += 1
    }
}
