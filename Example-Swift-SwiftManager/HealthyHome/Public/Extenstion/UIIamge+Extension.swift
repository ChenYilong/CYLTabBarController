//
//  UIIamge+Extension.swift
//  HealthyHome
//
//  Created by apple on 2020/2/11.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

extension UIImage {
    
    ///MARK:图片颜色
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    
}
