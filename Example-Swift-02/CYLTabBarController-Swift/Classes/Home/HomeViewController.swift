//
//  HomeViewController.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

private let cellIdentifier = "cell"

final class HomeViewController: UITableViewController {

    /// [EN] Inset grouped, like the other demo lists: each section has its own rounded background.
    /// [CN] 与其他示例列表一样使用 inset grouped：每个分组都有自己的圆角背景。
    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = cylDemoLocalizedString("首页")
        self.navigationController?.tabBarItem.badgeValue = "3"
        // No navigation bar button here: a bell button is added, with an animated badge in a random color.
        // 没有导航栏按钮：先添加铃铛按钮，再显示随机颜色的动画角标。
        cyl_showNavigationBadge(value: "8", animationType: .bounce, backgroundColor: UIColor.cyl_randomColor)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
}


extension HomeViewController{
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = String(format: cylDemoLocalizedString("我是第%@行"), "\(indexPath.row)")
        return cell
    }
    
    
    override func tableView(_ _: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 50
    }
    
    override func tableView(_ _: UITableView, didSelectRowAt _: IndexPath) {
        
        let vc = NextHomeViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
