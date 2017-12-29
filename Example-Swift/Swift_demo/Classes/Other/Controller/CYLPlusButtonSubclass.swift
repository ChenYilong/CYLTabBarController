//
//  CYLPlusButtonSubclass.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/27.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.titleLabel?.textAlignment = NSTextAlignment.center
        self.adjustsImageWhenHighlighted = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 控件大小,间距大小
        // 注意：一定要根据项目中的图片去调整下面的0.7和0.9，Demo之所以这么设置，因为demo中的 plusButton 的 icon 不是正方形。
        let imageViewEdgeWidth = CGFloat(self.bounds.size.width) * 0.7
        let imageViewEdgeHeight = imageViewEdgeWidth * 0.9
        
        let centerOfView = self.bounds.size.width * 0.5
        let labelLineHeight = self.titleLabel?.font.lineHeight
        let verticalMargin = (self.bounds.size.height - labelLineHeight! - imageViewEdgeHeight) * 0.5
        
        // imageView 和 titleLabel 中心的 Y 值
        let centerOfImageView = verticalMargin + imageViewEdgeHeight * 0.5
        let centerOfTitleLabel = imageViewEdgeHeight  + verticalMargin * 2 + labelLineHeight! * 0.5 + 5
        
        //imageView position 位置
        self.imageView?.bounds = CGRect.init(x: 0, y: 0, width: imageViewEdgeWidth, height: imageViewEdgeHeight)
        self.imageView?.center = CGPoint.init(x: centerOfView, y: centerOfImageView)
        
        //title position 位置
        self.titleLabel?.bounds = CGRect.init(x: 0, y: 0, width: self.bounds.size.width, height: labelLineHeight!)
        self.titleLabel?.center = CGPoint.init(x: centerOfView, y: centerOfTitleLabel)
    }
    
    
    static func plusButton() -> Any! {
        let button:CYLPlusButtonSubclass = CYLPlusButtonSubclass()
        let buttonImage = UIImage.init(named: "post_normal")
        button.setImage(buttonImage, for: .normal)
        button.setTitle("发布", for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)
        
        button.setTitle("发布", for: .selected)
        button.setTitleColor(UIColor.blue, for: .selected)

        button.titleLabel?.font = UIFont.systemFont(ofSize: 9.5)
        button.sizeToFit()  // or set frame in this way `button.frame = CGRectMake(0.0, 0.0, 250, 100);`
        //    button.frame = CGRectMake(0.0, 0.0, 250, 100);
        //    button.backgroundColor = [UIColor redColor];
        
        // if you use `+plusChildViewController` , do not addTarget to plusButton.
        button .addTarget(button, action: #selector(clickPublish), for: .touchUpInside)
        return button;
    }
    
    static func multiplier(ofTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        return  0.4
    }
    
    static func constantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        return  -10
    }
    
    
   
}

extension CYLPlusButtonSubclass:UIAlertViewDelegate {
    @objc func clickPublish() {
  
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "拍照", style: .default) { (action:UIAlertAction) in
            
        }
        
        let action2 = UIAlertAction(title: "从相册选取", style: .default) { (action:UIAlertAction) in

        }
        
        let action3 = UIAlertAction(title: "淘宝一键转卖", style: .default) { (action:UIAlertAction) in
        }
        
        let action4 = UIAlertAction(title: "取消", style: .cancel) { (action:UIAlertAction) in
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        alertController.addAction(action4)

        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        rootViewController?.present(alertController, animated: true, completion: nil)
    
    }
    
    
}

