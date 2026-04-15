//
//  UIColor+Extension.swift
//  SalesService
//
//  Created by 康洲 on 2019/8/27.
//  Copyright © 2019 康洲. All rights reserved.
//

import UIKit
extension UIColor {
    
    func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func rgbA(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    class func hexColor(_ hex: String) -> UIColor {
        
        return colorWithHexString(hex, alpha: 1)
    }
    
    //常用颜色
    class func color3() -> UIColor {
        return hexColor("#333333")
    }
    
    class func color6() -> UIColor {
        return hexColor("#666666")
    }
    
    class func color9() -> UIColor {
        return hexColor("#999999")
    }
    
    //分割线
    class func lineColor() -> UIColor {
        return hexColor("#eeeeee")
    }
    
    class func colorWithHexString(_ hex: String, alpha: CGFloat) -> UIColor {
        
        var cString:String = hex.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substring(from:1)
        }else if (cString.hasPrefix("0X") || cString.hasPrefix("0x")) {
            cString = (cString as NSString).substring(to: 2)
        }
        if ((cString as NSString).length != 6) {
            return .gray
        }
        let rString = (cString as NSString).substring(to:2)
        let gString = ((cString as NSString).substring(from:2) as NSString).substring(to: 2)
        let bString = ((cString as NSString).substring(from:4) as NSString).substring(to: 2)
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
    }
    
    //使用rgb方式生成自定义颜色
    convenience init(_ r: CGFloat, _ g : CGFloat, _ b : CGFloat) {
        let red = r / 255.0
        let green = g / 255.0
        let blue = b / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    //使用rgba方式生成自定义颜色
    convenience init(_ r: CGFloat, _ g : CGFloat, _ b : CGFloat, _ a: CGFloat) {
        let red = r / 255.0
        let green = g / 255.0
        let blue = b / 255.0
        self.init(red: red, green: green, blue: blue, alpha: a)
    }
}
