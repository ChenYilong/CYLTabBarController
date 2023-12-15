//
//  CYLPlusButtonSubclass.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {
    static func plusButton() -> Any! {
        let button = CYLPlusButtonSubclass()
        button.setImage(UIImage(named: "post_normal"), for: .normal)
        button.titleLabel?.textAlignment = .center

        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)

        button.setTitle("发布", for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)

        button.setTitle("选中", for: .selected)
        button.setTitleColor(UIColor.blue, for: .selected)

        button.adjustsImageWhenHighlighted = false
        button.sizeToFit()
//        button.addTarget(self, action: #selector(testClick(sender:)), for: .touchUpInside)
        return button
    }

//    @objc static func testClick(sender: UIButton){
//        print("testClick")
//    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        return 2
    }

    static func multiplier(ofTabBarHeight _: CGFloat) -> CGFloat {
        return 0.3
    }

    static func constantOfPlusButtonCenterYOffset(forTabBarHeight _: CGFloat) -> CGFloat {
        return -10
    }

    static func plusChildViewController() -> UIViewController! {
        let vc = PublishViewController()
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    static func shouldSelectPlusChildViewController() -> Bool {
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // tabbar UI layout setup
        let imageViewEdgeWidth: CGFloat = bounds.size.width * 0.7
        let imageViewEdgeHeight: CGFloat = imageViewEdgeWidth * 0.9

        let centerOfView = bounds.size.width * 0.5
        let labelLineHeight = titleLabel!.font.lineHeight
        let verticalMargin = (bounds.size.height - labelLineHeight - imageViewEdgeHeight) * 0.5

        let centerOfImageView = verticalMargin + imageViewEdgeHeight * 0.5
        let centerOfTitleLabel = imageViewEdgeHeight + verticalMargin * 2 + labelLineHeight * 0.5 + 10

        // imageView position layout
        imageView!.bounds = CGRect(x: 0, y: 0, width: imageViewEdgeWidth, height: imageViewEdgeHeight)
        imageView!.center = CGPoint(x: centerOfView, y: centerOfImageView)

        // title position layout
        titleLabel!.bounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: labelLineHeight)
        titleLabel!.center = CGPoint(x: centerOfView, y: centerOfTitleLabel)
    }
}
