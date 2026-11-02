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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = CYLLocalizedString("首页")
        self.navigationController?.tabBarItem.badgeValue = "3"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
}


extension HomeViewController{
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = String(format: CYLLocalizedString("我是第%ld行"), indexPath.row)
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = NextHomeViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
