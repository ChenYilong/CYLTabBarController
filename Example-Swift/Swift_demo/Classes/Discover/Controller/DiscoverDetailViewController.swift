//
//  DiscoverDetailViewController.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/27.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

class DiscoverDetailViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DiscoverDetailViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.cyl_popSelectTabBarChildViewController(at: 3)

    }
}
