//
//  FriendsVC.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

class FriendsVC: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] Only the navigation bar: `self.title` would also rename the tab, whose title is "Moments".
        // [CN] 只设置导航栏：`self.title` 还会修改 Tab 的标题，而 Tab 的标题是「朋友圈」。
        self.navigationItem.title = cylDemoLocalizedString("通讯录")
        self.view.backgroundColor = .purple

    }
}
