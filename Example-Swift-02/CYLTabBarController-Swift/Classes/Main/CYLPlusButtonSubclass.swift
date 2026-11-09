//
//  CYLPlusButtonSubclass.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

class CYLPlusButtonSubclass: CYLPlusButton,CYLPlusButtonSubclassing {

    
    static func plusButton() -> Any {
        return CYLPlusButtonSubclass.cyl_plusButton(with: UIImage(named: "post_normal")!, title: CYLLocalizedString("发布"),
                                                    selectedTitle: CYLLocalizedString("选中"), selectedTitleColor: UIColor(red: 1, green: 102.0 / 255.0, blue: 0, alpha: 1))
    }

    // [EN] The other methods: Example-Shared/CYLPlusButtonSubclass+Layout.swift. [CN] 其他方法见 Example-Shared/CYLPlusButtonSubclass+Layout.swift。
}
