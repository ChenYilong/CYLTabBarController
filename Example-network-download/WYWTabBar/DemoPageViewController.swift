//
//  DemoPageViewController.swift
//  WYWTabBar
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit

/// [EN] The page of a tab: its title in the middle. One class for every tab (the Objective-C example had four empty ones).
/// [CN] 一个 Tab 的页面：标题显示在中间。所有 Tab 共用一个类（Objective-C 示例有四个空类）。
final class DemoPageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
