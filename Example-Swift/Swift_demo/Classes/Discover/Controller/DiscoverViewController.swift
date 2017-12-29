//
//  DiscoverViewController.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/27.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

fileprivate let cellID = "DiscoverTableViewCell"

class DiscoverViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabUI()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - 设置UI界面
extension DiscoverViewController{
    fileprivate func setupTabUI(){
        tableView.register(UINib.init(nibName: "DiscoverTableViewCell", bundle: nil), forCellReuseIdentifier: cellID)
        
        self.navigationItem.title = "同城"

    }
}


// MARK: - dataSource
extension DiscoverViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! DiscoverTableViewCell
        
        cell.titleLabel.text =  "测试数据\(indexPath.row)"
        return cell
        
        
    }
}
// MARK: - delegate
extension DiscoverViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DiscoverDetailViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
        
    }
}

