//
//  PrefixPch.swift
//  HealthyHome
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit


// MARK: - 时间格式
enum TimeFormat:String {
    case format_default                = "yyyy-MM-dd HH:mm:ss"
    case format_yyyy_M_d_H_m           = "yyyy-MM-dd HH:mm"
    case format_yyyy_M_d               = "yyyy-MM-dd"
    case format_yyyy_M                 = "yyyy-MM"
    case format_yy_M_d_H_m             = "yy-MM-dd HH:mm"
    case format_yy_M_d                 = "yy-MM-dd"
    case format_M_d_H_m_s              = "MM-dd HH:mm:ss"
    case format_M_d_H_m                = "MM-dd HH:mm"
    case format_M_d                    = "MM-dd"
    case format_yyyy_M_d_HmsS          = "yyyy-MM-dd HH:mm:ss.SSS"
    case format_Hms                    = "HH:mm:ss"
    case format_Hm                     = "HH:mm"
    case format_yyyyMMddHHmmssSSS      = "yyyyMMddHHmmssSSS"
    case format_yyyyMdHms              = "yyyyMMddHHmmss"
    case format_YYMMdd                 = "yyyyMMdd"
    case format_yyyyMdWithSlash        = "yyyy/MM/dd"
    case format_yyyyMd                 = "yyyy.MM.dd"
}




///MARK:判空
func isEmptyStr(str:String) -> Bool {
    if (str == ""||str.isEmpty || str.count == 0) {
        return false;
    }else{
        return true;
    }
}

//MARK:设置随机颜色
let RandomColor = UIColor(red: CGFloat(arc4random_uniform(256)/255), green: CGFloat(arc4random_uniform(256)/255), blue: CGFloat(arc4random_uniform(256)/255), alpha: 1)

//MARK: iPhone设备
let isIPhone = (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone ? true : false)
//MARK: iPad设备
let isIPad = (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? true : false)
//MARK:当前的APP信息
let appInfo = Bundle.main.infoDictionary
//MARK:当前app版本号
let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
//MARK:  获取设备系统号
let systemVersion = UIDevice.current.systemVersion
//MARK:系统版本
let IOS8_OR_LATER = (Float(systemVersion)! >= 8.0 ? true : false)
let IOS9_OR_LATER = (Float(systemVersion)! >= 9.0 ? true : false)
let IOS10_OR_LATER = (Float(systemVersion)! >= 10.0 ? true : false)
let IOS11_OR_LATER = (Float(systemVersion)! >= 11.0 ? true : false)

//MARK: 视图宽高
let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

//MARK:导航栏含标签栏高度
let barHeight = UIApplication.shared.statusBarFrame.height == 44 ? 88 : 64
//MARK:Tab高度
let tabHeight = UIApplication.shared.statusBarFrame.height == 44 ? 83 : 49


//MARK: 底部安全距离，全屏手机为34pt,非全屏手机为0pt
@available(iOS 11.0, *)
let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0

//MARK: (1)先获取状态栏的高度，根据状态栏的高度定义 导航栏高度、tabbar高度、顶部的安全距离、底部的安全距离
//MARK: 状态栏高度
let statusBarHeight = UIApplication.shared.statusBarFrame.height
//MARK: 导航栏高度
let navigationHeight = statusBarHeight + 44
//MARK: tabbar高度
let tabBarHeight = (statusBarHeight == 44 ? 83 : 49)
//MARK: 顶部安全距离
let topSafeAreaHeight = statusBarHeight - 20
//MARK: 底部安全距离
let btmSafeAreaHeight = tabBarHeight - 49


//MARK:（2）先获取底部的安全距离，根据底部的安全距离定义导航栏高度、tabbar高度、顶部的安全距离、状态栏高度
//MARK: 顶部的安全距离
@available(iOS 11.0, *)
let tpSafeAreaHeight = (bottomSafeAreaHeight == 0 ? 0 : 24)
//MARK: 导航栏高度
@available(iOS 11.0, *)
let navigationBarHeight = (bottomSafeAreaHeight == 0 ? 64 : 88)
//MARK: tabbar 高度
@available(iOS 11.0, *)
let tabbarHeight = bottomSafeAreaHeight + 49


///MARK:打印日志 NSLog
func debugLog<T>(message: T,
              file: String = #file,
              method: String = #function,
              line: Int = #line)
{
    #if DEBUG
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}

///打印日志
func DeLog<T>(_ msg:T,fileName:String = #file,methodName:String = #function,lineNum:Int = #line){
    #if DEBUG
        let logStr = fileName.components(separatedBy: "/").last!.replacingOccurrences(of: "swift", with: "");
        print("类：\(logStr) 行：[\(lineNum)] 方法：\(methodName) 数据：\(msg)")
    #endif
}
