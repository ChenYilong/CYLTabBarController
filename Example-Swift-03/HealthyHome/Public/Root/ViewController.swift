//
//  ViewController.swift
//  HealthyHome
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var isShowBackBtn: Bool? {
        willSet {//变化前默认false
            addleftBarButtonItem()
        }
        didSet {//isShowBackBtn属性改变后，更新方法
            addleftBarButtonItem()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        isShowBackBtn = true

    }

    ///MARK: 导航栏左侧返回按钮
    func addleftBarButtonItem() {
        let vces: Int = (self.navigationController?.viewControllers.count)!
        if vces > 1 && isShowBackBtn == true {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), style: .done, target: self, action: #selector(backClicked))
        }else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIView())
        }
    }

    ///MARK: 导航栏右侧添加按钮（文字）
    func addRightBarButtonItemTitle(_ title: String, _ color: String, _ target: Any, action: Selector) {
    
        if isEmptyStr(str: title) {
            let button = UIButton()
            button.setTitle(title, for: .normal)
            if isEmptyStr(str: color) {
                button.setTitleColor(.hexColor(color), for: .normal)
            }else {
                button.setTitleColor(.white, for: .normal)
            }
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.addTarget(target, action: action, for: .touchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
        
    }
    
    ///MARK: 导航栏右侧添加按钮（图片）
    func addRightBarButtonItemImage(_ imageName: String, _ target: Any, action: Selector) {
        
        let button = UIButton()
        if isEmptyStr(str: imageName) {
            button.setImage(UIImage(named: imageName), for: .normal)
        }else {
            button.backgroundColor = .white
            button.width = 45
            button.height = 30
            button.layer.masksToBounds = true
            button.layer.cornerRadius = 5
        }
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(target, action: action, for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    
    @objc func backClicked() {
        let vces: Int = (self.navigationController?.viewControllers.count)!
        if vces > 1 {
            if (self.presentedViewController != nil) {
                self.dismiss(animated: true, completion: nil)
            }else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

