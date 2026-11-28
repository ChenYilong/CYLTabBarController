//
//  ChilderVC.swift
//  HealthyHome
//
//  Created by apple on 2020/2/15.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

class ChilderVC: ViewController {

    /// The background image, from `CYLDemoBackgroundImageURL` in Info.plist; set it before the view loads to show
    /// another one. 背景图地址，取自 Info.plist 的 `CYLDemoBackgroundImageURL`，可在视图加载前修改。
    var backgroundImageURL = Bundle.main.object(forInfoDictionaryKey: "CYLDemoBackgroundImageURL") as? String ?? ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addRightBarButtonItemTitle("next", "", self, action: #selector(nextAction))
        
        let backImageView = UIImageView(frame: self.view.bounds)
        backImageView.imageFromURL(backgroundImageURL, placeholder: UIImage.imageWithColor(.lightGray))
        self.view.addSubview(backImageView)
    }
    
    @objc func nextAction() {
        let next = NextVC()
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    override func touchesBegan(_ _: Set<UITouch>, with _: UIEvent?) {
        
        TabBarCommon.enterApp()
    }
    

}
