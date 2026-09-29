//
//  ChilderVC.swift
//  HealthyHome
//
//  Created by apple on 2020/2/15.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class ChilderVC: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addRightBarButtonItemTitle("next", "", self, action: #selector(nextAction))
        
        let backImageView = UIImageView(frame: self.view.bounds)
        backImageView.imageFromURL("https://fc3tn.baidu.com/it/u=3025909226,1763324618&fm=202&src=bqdata", placeholder: UIImage.imageWithColor(.lightGray))
        self.view.addSubview(backImageView)
    }
    
    @objc func nextAction() {
        let next = NextVC()
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        TabBarCommon.enterApp {
            
        }
    }
    

}
