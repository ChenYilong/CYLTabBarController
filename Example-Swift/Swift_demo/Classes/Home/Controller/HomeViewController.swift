//
//  HomeViewController.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/21.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

fileprivate let cellID = "cell"


class HomeViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight - kTabBarHeight))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HomeViewCell.self, forCellReuseIdentifier: cellID)

        return tableView
    }()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "首页"
        self.navigationController?.navigationBar.isTranslucent = false
        // Do any additional setup after loading the view.
        setupTabUI()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTabUI() {
        view.addSubview(tableView)
        
    }

}

// MARK: - 设置UITableViewDelegate协议
extension HomeViewController: UITableViewDelegate, UITabBarControllerDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let badgeNumber = indexPath.row
        self.navigationItem.title = "首页\(badgeNumber)"
        self.navigationController?.tabBarItem.badgeValue = "\(badgeNumber)"

        let tabBarControllerConfig = CYLTabBarControllerConfig()
        let tabBarController = tabBarControllerConfig.tabBarController
        tabBarController.delegate = self
        self.navigationController?.pushViewController(tabBarController, animated: true)
        
    
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
        
    }
}

// MARK: - 设置UITableViewDataSource数据源
extension HomeViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        
        cell?.textLabel?.text = "测试数据\(indexPath.row)"
        
        return cell!
        
        
    }
}

