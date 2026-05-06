/*
 //  CYLFlatDesignTabBarController
 //  CYLFlatDesignTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

import UIKit

open class CYLFlatDesignTabBarItemMoreContentView: CYLFlatDesignTabBarItemContentView {
    
    private let cylBundle: Bundle = {
        let bundle = Bundle(for: CYLFlatDesignTabBarController.self)
        if let url = bundle.url(forResource: "CYLFlatDesignTabBarController", withExtension: "bundle"),
           let resourceBundle = Bundle(url: url) {
            return resourceBundle
        }
        return bundle
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.title = NSLocalizedString("More_TabBarItem", bundle: cylBundle, comment: "")
        self.image = systemMore(highlighted: false)
        self.selectedImage = systemMore(highlighted: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func systemMore(highlighted isHighlighted: Bool) -> UIImage? {
        let image = UIImage.init()
        let circleDiameter = isHighlighted ? 5.0 : 4.0
        let scale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize.init(width: 32, height: 32), false, scale)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1.0)
            for index in 0...2 {
                let tmpRect = CGRect.init(x: 5.0 + 9.0 * Double(index), y: 14.0, width: circleDiameter, height: circleDiameter)
                context.addEllipse(in: tmpRect)
                image.draw(in: tmpRect)
            }

            if isHighlighted {
                context.setFillColor(UIColor.blue.cgColor)
                context.fillPath()
            } else {
                context.strokePath()
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
        
        return nil
    }
    
}
