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
    @IBAction func firstBtnClick(_ _: UIButton) {
        
        self.cyl_popSelectTabBarChildViewController(at: 1)

    }
    @IBAction func secondBtnClick(_ _: UIButton) {
        
        self.cyl_popSelectTabBarChildViewController(at: 2)

        // [CN] 重要：改变选中字体的颜色
        // [EN] Important: change the color of the selected title text.
        CYLExternPlusButton.isSelected = true

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // #408: the same pop / push demos by tab identifier ("home", "city", "message", "mine"; see
        // MainRootNavigationViewController), which stay right when tabs come and go, unlike an index.
        // #408：按 Tab 标识（"home"、"city"、"message"、"mine"，见 MainRootNavigationViewController）的 Pop / Push 演示，
        // 增减 Tab 后依然准确，不像下标。
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "tag"), style: .plain,
                                                            target: self, action: #selector(showTabBarItemIdentifierDemos))
    }

    @objc private func showTabBarItemIdentifierDemos() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        // Pops to the stack's root and selects the "message" tab, with pop animation. Pop 到栈底并选中「消息」，带 pop 动画。
        sheet.addAction(UIAlertAction(title: "forTabBarItemIdentifier: \"message\", animated: true", style: .default) { [weak self] _ in
            self?.cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier: "message", animated: true)
        })
        // Selects the "mine" tab, then pushes a page onto it in the completion. 选中「我的」，并在 completion 中向该 Tab push 一个页面。
        sheet.addAction(UIAlertAction(title: "forTabBarItemIdentifier: \"mine\", completion:", style: .default) { [weak self] _ in
            self?.cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier: "mine") { selected in
                let next = NextHomeViewController()
                next.hidesBottomBarWhenPushed = true
                selected.navigationController?.pushViewController(next, animated: true)
            }
        })
        // Pops the current stack, selects the "city" tab, then pushes a page onto it. Pop 当前导航栈、选中「同城」，再向该 Tab push 一个页面。
        sheet.addAction(UIAlertAction(title: "cyl_pushOrPop(to:animated:tabBarItemIdentifier: \"city\")", style: .default) { [weak self] _ in
            let next = NextHomeViewController()
            next.hidesBottomBarWhenPushed = true
            self?.cyl_pushOrPop(to: next, animated: true, tabBarItemIdentifier: "city") { _, completionHandler in
                // The index is ignored: the tab is selected by its identifier. index 被忽略：按标识选中 Tab。
                completionHandler(false, nil, true, 0)
            }
        })
        // An unknown identifier returns nil: nothing is popped or selected. 未知标识返回 nil：不 pop、不切换 Tab。
        sheet.addAction(UIAlertAction(title: "forTabBarItemIdentifier: \"unknown\"", style: .default) { [weak self] _ in
            let selected = self?.cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier: "unknown")
            let alert = UIAlertController(title: nil, message: String(format: CYLDemoLocalizedString("返回值：%@"), selected.map { "\($0)" } ?? "nil"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: CYLDemoLocalizedString("OK"), style: .default))
            self?.present(alert, animated: true)
        })
        sheet.addAction(UIAlertAction(title: CYLDemoLocalizedString("取消"), style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
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
