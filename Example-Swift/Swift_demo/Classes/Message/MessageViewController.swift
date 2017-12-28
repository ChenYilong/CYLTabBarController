//
//  MessageViewController.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/28.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

fileprivate let cellID = "cell"

class MessageViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)

        self.navigationItem.title = "消息"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


// MARK: - dataSource
extension MessageViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UITableViewCell
        
        cell.textLabel?.text =  "测试数据\(indexPath.row)"
        return cell
        
        
    }
}
// MARK: - delegate
extension MessageViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
        
    }
}

