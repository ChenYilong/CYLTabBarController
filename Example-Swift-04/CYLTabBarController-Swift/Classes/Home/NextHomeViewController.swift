//
//  NextHomeViewController.swift
//  CYLTabBarController-Swift
//
//  Created by Anthony on 2018/5/11.
//  Copyright © 2018年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

class NextHomeViewController: UIViewController {
    @IBAction func firstBtnClick(_ sender: UIButton) {
        
        self.cyl_popSelectTabBarChildViewController(at: 1)

    }
    @IBAction func secondBtnClick(_ sender: UIButton) {
        
        self.cyl_popSelectTabBarChildViewController(at: 2)

        //重要：改变选中字体的颜色
        CYLExternPlusButton.isSelected = true

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
