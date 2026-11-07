//
//  MeVC.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class MeVC: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = CYLLocalizedString("我的")
        self.view.backgroundColor = .systemBackground
        // [EN] The test list shared by every Swift demo (every settings row of the library, grouped), as a child.
        // [CN] 所有 Swift Demo 共用的测试列表（库中所有设置行，分组显示），作为子控制器。
        let settingsViewController = CYLSettingsDemoTableViewController()
        addChild(settingsViewController)
        settingsViewController.view.frame = view.bounds
        settingsViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(settingsViewController.view)
        settingsViewController.didMove(toParent: self)
    }
}
