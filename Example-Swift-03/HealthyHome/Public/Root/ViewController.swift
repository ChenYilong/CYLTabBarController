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
        willSet {// [CN] 变化前默认false
        // [EN] Defaults to false before the change
            addleftBarButtonItem()
        }
        didSet {// [CN] isShowBackBtn属性改变后，更新方法
        // [EN] Update method called after the isShowBackBtn property changes
            addleftBarButtonItem()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        isShowBackBtn = true

    }

    /// [CN] MARK: 导航栏左侧返回按钮
    /// [EN] MARK: Back button on the left side of the navigation bar
    func addleftBarButtonItem() {
        let vces: Int = (self.navigationController?.viewControllers.count)!
        if vces > 1 && isShowBackBtn == true {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), style: .prominent, target: self, action: #selector(backClicked))
        }else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIView())
        }
    }

    /// [CN] MARK: 导航栏右侧添加按钮（文字）
    /// [EN] MARK: Add button on the right side of the navigation bar (text)
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
    
    /// [CN] MARK: 导航栏右侧添加按钮（图片）
    /// [EN] MARK: Add button on the right side of the navigation bar (image)
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

