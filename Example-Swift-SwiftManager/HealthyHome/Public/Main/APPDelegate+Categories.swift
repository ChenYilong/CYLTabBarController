//
//  APPDelegate+Categories.swift
//  HealthyHome
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 apple. All rights reserved.
//

import Foundation

extension AppDelegate {
    
}

func isFirst() -> Bool {
    if UserDefaults.isFirstLaunch() || UserDefaults.isFirstLaunchOfNewVersion() {
        return true
    }
    return false
}



//应用启动第一次 当前版本第一次重新启动
extension UserDefaults {
    //应用启动第一次
    static func isFirstLaunch() -> Bool {
        let hasBeenLaunch = "hasBeenLaunch"
        let isFirestLaunch = UserDefaults.standard.bool(forKey: hasBeenLaunch)
        if isFirestLaunch {
            UserDefaults.standard.set(true, forKey: hasBeenLaunch)
            UserDefaults.standard.synchronize()
        }
        return isFirestLaunch
    }
    
    //当前版本第一次重新启动
    static func isFirstLaunchOfNewVersion() -> Bool {
        //主程序此版本好
        let majorVersion = appVersion as! String
        //上次启动的版本号
        let hasBeenLaunchOfNewVersion = "hasBeenLaunchOfNewVersion"
        let lastVersion = UserDefaults.standard.string(forKey: hasBeenLaunchOfNewVersion)
        //版本号比较
        let isFirstLaunchOfNewVersion = majorVersion != lastVersion
        if isFirstLaunchOfNewVersion {
            UserDefaults.standard.set(majorVersion, forKey: hasBeenLaunchOfNewVersion)
            UserDefaults.standard.synchronize()
        }
        return isFirstLaunchOfNewVersion;
    }
}
