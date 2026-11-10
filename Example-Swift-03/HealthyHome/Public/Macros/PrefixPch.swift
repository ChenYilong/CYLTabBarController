//
//  PrefixPch.swift
//  HealthyHome
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController


// [CN] MARK: - 时间格式
// [EN] MARK: - Time format
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




/// [CN] MARK:判空
/// [EN] MARK: Empty check
func isEmptyStr(str:String) -> Bool {
    if (str == ""||str.isEmpty || str.count == 0) {
        return false;
    }else{
        return true;
    }
}

// [CN] MARK:设置随机颜色
// [EN] MARK: Set a random color
let randomColor = UIColor(red: CGFloat(arc4random_uniform(256)) / 255, green: CGFloat(arc4random_uniform(256)) / 255, blue: CGFloat(arc4random_uniform(256)) / 255, alpha: 1)

// [CN] MARK: iPhone设备
// [EN] MARK: iPhone device
let isIPhone = (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone ? true : false)
// [CN] MARK: iPad设备
// [EN] MARK: iPad device
let isIPad = (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? true : false)
// [CN] MARK:当前的APP信息
// [EN] MARK: Current app info
let appInfo = Bundle.main.infoDictionary
// [CN] MARK:当前app版本号
// [EN] MARK: Current app version
let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
// [CN] MARK:  获取设备系统号
// [EN] MARK:  Get the device system version
let systemVersion = UIDevice.current.systemVersion
// [CN] MARK:系统版本：用 `if #available(iOS xx, *)` 判断（最低支持 iOS 15，原来的 IOS8~11_OR_LATER 常量恒为 true，已删除）
// [EN] MARK: System version: check with `if #available(iOS xx, *)` (minimum supported is iOS 15;
//      the old IOS8~11_OR_LATER constants were always true and have been removed)

// [CN] MARK: 当前窗口场景（`UIScreen.main`、`UIApplication.windows` 已弃用，改用 UIWindowScene）
// [EN] MARK: Current window scene (`UIScreen.main` and `UIApplication.windows` are deprecated; use
//      UIWindowScene instead)
func currentWindowScene() -> UIWindowScene? {
    return UIApplication.shared.connectedScenes.first { $0 is UIWindowScene } as? UIWindowScene
}

// [CN] MARK: 视图宽高
// [EN] MARK: View width and height
let screenWidth = currentWindowScene()?.screen.bounds.width ?? 0
let screenHeight = currentWindowScene()?.screen.bounds.height ?? 0

// [CN] MARK: 当前状态栏高度（`UIApplication.statusBarFrame` 在 iOS 27 起已失效，改用 UIWindowScene.statusBarManager）
// [EN] MARK: Current status bar height (`UIApplication.statusBarFrame` no longer works as of iOS 27;
//      use UIWindowScene.statusBarManager instead)
private func currentStatusBarHeight() -> CGFloat {
    return currentWindowScene()?.statusBarManager?.statusBarFrame.height ?? 0
}

// [CN] MARK:导航栏含标签栏高度
// [EN] MARK: Navigation bar height including tab bar
let barHeight = currentStatusBarHeight() == 44 ? 88 : 64
// [CN] MARK:Tab高度
// [EN] MARK: Tab height
let tabHeight = currentStatusBarHeight() == 44 ? 83 : 49


// [CN] MARK: 底部安全距离，全屏手机为34pt,非全屏手机为0pt
// [EN] MARK: Bottom safe area: 34pt on full-screen phones, 0pt on non-full-screen phones
@available(iOS 11.0, *)
let bottomSafeAreaHeight = currentWindowScene()?.windows.first?.safeAreaInsets.bottom ?? 0.0

// [CN] MARK: (1)先获取状态栏的高度，根据状态栏的高度定义 导航栏高度、tabbar高度、顶部的安全距离、底部的安全距离
//MARK: 状态栏高度
// [EN] MARK: (1) First get the status bar height, then derive the navigation bar height, tabbar height,
//      top safe area and bottom safe area from it
//      MARK: Status bar height
let statusBarHeight = currentStatusBarHeight()
// [CN] MARK: 导航栏高度
// [EN] MARK: Navigation bar height
let navigationHeight = statusBarHeight + 44
// [CN] MARK: tabbar高度
// [EN] MARK: tabbar height
let tabBarHeight = (statusBarHeight == 44 ? 83 : 49)
// [CN] MARK: 顶部安全距离
// [EN] MARK: Top safe area
let topSafeAreaHeight = statusBarHeight - 20
// [CN] MARK: 底部安全距离
// [EN] MARK: Bottom safe area
let btmSafeAreaHeight = tabBarHeight - 49


// [CN] MARK:（2）先获取底部的安全距离，根据底部的安全距离定义导航栏高度、tabbar高度、顶部的安全距离、状态栏高度
//MARK: 顶部的安全距离
// [EN] MARK: (2) First get the bottom safe area, then derive the navigation bar height, tabbar height,
//      top safe area and status bar height from it
//      MARK: Top safe area
@available(iOS 11.0, *)
let tpSafeAreaHeight = (bottomSafeAreaHeight == 0 ? 0 : 24)
// [CN] MARK: 导航栏高度
// [EN] MARK: Navigation bar height
@available(iOS 11.0, *)
let navigationBarHeight = (bottomSafeAreaHeight == 0 ? 64 : 88)
// [CN] MARK: tabbar 高度
// [EN] MARK: tabbar height
@available(iOS 11.0, *)
let tabbarHeight = bottomSafeAreaHeight + 49


/// [CN] MARK:打印日志 NSLog
/// [EN] MARK: Print log NSLog
func debugLog<T>(message: T,
              file: String = #file,
              method: String = #function,
              line: Int = #line)
{
    #if DEBUG
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}

/// [CN] 打印日志
/// [EN] Print log
func debugLog<T>(_ msg:T,fileName:String = #file,methodName:String = #function,lineNum:Int = #line){
    #if DEBUG
        let logStr = fileName.components(separatedBy: "/").last!.replacingOccurrences(of: "swift", with: "");
        print(String(format: CYLDemoLocalizedString("类：%@ 行：[%@] 方法：%@ 数据：%@"), logStr, "\(lineNum)", methodName, "\(msg)"))
    #endif
}
