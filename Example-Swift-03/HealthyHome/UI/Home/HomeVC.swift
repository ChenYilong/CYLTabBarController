//
//  HomeVC.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import CYLTabBarController
import UIKit

private let cellIdentifier = "cell"

/// The app icon drawn at 40 x 40 pt with rounded corners. At full size it fills the row, and the badge, which sits on
/// the icon's top-right corner, ends up under the row above.
private let demoIcon: UIImage? = {
    guard let image = UIImage(named: "DemoIcon") else { return nil }
    let rect = CGRect(x: 0, y: 0, width: 40, height: 40)
    return UIGraphicsImageRenderer(size: rect.size).image { _ in
        UIBezierPath(roundedRect: rect, cornerRadius: 8).addClip()
        image.draw(in: rect)
    }
}()

/// Row height that leaves room above the icon for its badge.
private let demoRowHeight: CGFloat = 60

private struct BadgeDemoItem {
    var title: String
    var value: String
    var animation: CYLBadgeAnimationType = .none
    var maximum = 99
    var colored = false
    var bordered = false
    var offset = false
    var radius: CGFloat = 0
    var cornerRadius: CGFloat = 0
}

/// How to use the badge, on any UIView (here the cell's image view), UIBarButtonItem or UIViewController:
///   view.cyl_showBadgeValue("", animationType: .none)   // red dot
///   view.cyl_showBadgeValue("8", animationType: .shake) // number / text, with an animation
///   view.cyl_clearBadge()                               // hide it
/// Set colors, border, offset and radius BEFORE calling cyl_showBadgeValue.
/// Every badge style and animation, one per row.
private let badgeDemoItems: [BadgeDemoItem] = [
    // Styles
    BadgeDemoItem(title: "Red dot", value: ""),
    BadgeDemoItem(title: "Number", value: "8"),
    BadgeDemoItem(title: "Number above maximum", value: "100", maximum: 99),
    BadgeDemoItem(title: "New", value: "new"),
    BadgeDemoItem(title: "Other text", value: "hot"),
    // Appearance
    BadgeDemoItem(title: "Custom colors", value: "5", colored: true),
    BadgeDemoItem(title: "Border", value: "5", bordered: true),
    BadgeDemoItem(title: "Center offset", value: "", offset: true),
    BadgeDemoItem(title: "Red dot radius", value: "", radius: 6),
    BadgeDemoItem(title: "Corner radius", value: "new", cornerRadius: 3),
    // Repeating animations
    BadgeDemoItem(title: "Scale", value: "3", animation: .scale),
    BadgeDemoItem(title: "Shake", value: "3", animation: .shake),
    BadgeDemoItem(title: "Bounce", value: "3", animation: .bounce),
    BadgeDemoItem(title: "Breathe", value: "", animation: .breathe),
    // Once animations
    BadgeDemoItem(title: "Left to right once", value: "3", animation: .leftRightOnce),
    BadgeDemoItem(title: "Right to left once", value: "3", animation: .rightLeftOnce),
    BadgeDemoItem(title: "Fade in once", value: "3", animation: .fadeInOnce),
    BadgeDemoItem(title: "Rolling once", value: "3", animation: .rollingOnce),
    BadgeDemoItem(title: "Scale once", value: "3", animation: .scaleOnce),
]

class HomeVC: ViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "首页"
        self.view.backgroundColor = .white

        addRightBarButtonItemImage("屏幕全屏", self, action: #selector(tapAction))

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = demoRowHeight
        view.addSubview(tableView)
    }

    @objc func tapAction() {
        let child = ChilderVC()
        self.navigationController?.pushViewController(child, animated: true)
    }
}

extension HomeVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return badgeDemoItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = badgeDemoItems[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1). \(item.title)"
        cell.showBadgeDemo(item)
        return cell
    }

    /// Tap a row to clear its badge.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.cellForRow(at: indexPath)?.imageView?.cyl_clearBadge()
    }
}

private extension UITableViewCell {

    /// Shows the demo icon in the cell and a badge on it.
    func showBadgeDemo(_ item: BadgeDemoItem) {
        guard let iconView = imageView else { return }
        iconView.image = demoIcon
        iconView.clipsToBounds = false

        // Cells are reused: clear the badge and reset every option before the next one.
        iconView.cyl_clearBadge()
        iconView.cyl_badgeBackgroundColor = item.colored ? .purple : .red
        iconView.cyl_badgeTextColor = item.colored ? .yellow : .white
        iconView.cyl_badgeBorderColor = item.bordered ? .white : nil
        iconView.cyl_badgeBorderWidth = item.bordered ? 2 : 0
        iconView.cyl_badgeCenterOffset = item.offset ? CGPoint(x: -8, y: 8) : .zero
        iconView.cyl_badgeMaximumBadgeNumber = item.maximum
        iconView.cyl_badgeRadius = item.radius
        iconView.cyl_badgeCornerRadius = item.cornerRadius
        // Options must be set before showing the badge.
        iconView.cyl_showBadgeValue(item.value, animationType: item.animation)
    }
}
