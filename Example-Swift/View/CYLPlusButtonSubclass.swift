//
//  CYLPlusButtonSubclass.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {
    static func plusButton() -> Any {
        let button = CYLPlusButtonSubclass.cyl_plusButton(with: UIImage(named: "post_normal")!, title: CYLLocalizedString("发布"),
                                                          selectedTitle: CYLLocalizedString("选中"), selectedTitleColor: .blue)
        // Issue #91: a larger touchable area without changing the frame (positive values grow it outward), e.g. the gap
        // below the raised button. The settings row "PlusButton touchable area" shows and scales it at runtime.
        // Issue #91：不改变 frame 即可扩大点击范围（正值向外扩展），例如凸起按钮下方的间隙。设置分组中的「PlusButton 点击范围」行可在运行时显示并按倍数调整。
        button.touchableAreaOutsets = UIEdgeInsets(top: 0, left: 8, bottom: 12, right: 8)
        // button.touchableAreaScale = 1.5   // or scale the area around the center 或以中心按倍数放大
        // button.showsTouchableArea = true  // debugging: show the area 调试：显示可点击区域
        return button
    }

    // [EN] The other methods: Example-Shared/CYLPlusButtonSubclass+Layout.swift. [CN] 其他方法见 Example-Shared/CYLPlusButtonSubclass+Layout.swift。
}
