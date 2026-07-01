//
//  HomeVC.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class HomeVC: ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "首页"
        self.view.backgroundColor = .red

        addRightBarButtonItemImage("屏幕全屏", self, action: #selector(tapAction))
    }
    
    @objc func tapAction() {
        let child = ChilderVC()
        self.navigationController?.pushViewController(child, animated: true)
    }
    
    
    
}
