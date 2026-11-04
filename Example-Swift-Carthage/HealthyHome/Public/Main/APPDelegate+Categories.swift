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



// [CN] 应用启动第一次 当前版本第一次重新启动
// [EN] First app launch / first launch of the current version
extension UserDefaults {
    // [CN] 应用启动第一次
    // [EN] First app launch
    static func isFirstLaunch() -> Bool {
        let hasBeenLaunch = "hasBeenLaunch"
        let isFirestLaunch = UserDefaults.standard.bool(forKey: hasBeenLaunch)
        if isFirestLaunch {
            UserDefaults.standard.set(true, forKey: hasBeenLaunch)
            UserDefaults.standard.synchronize()
        }
        return isFirestLaunch
    }
    
    // [CN] 当前版本第一次重新启动
    // [EN] First launch of the current version
    static func isFirstLaunchOfNewVersion() -> Bool {
        // [CN] 主程序此版本好
        // [EN] Current version of the main app
        let majorVersion = appVersion as! String
        // [CN] 上次启动的版本号
        // [EN] Version from the last launch
        let hasBeenLaunchOfNewVersion = "hasBeenLaunchOfNewVersion"
        let lastVersion = UserDefaults.standard.string(forKey: hasBeenLaunchOfNewVersion)
        // [CN] 版本号比较
        // [EN] Version comparison
        let isFirstLaunchOfNewVersion = majorVersion != lastVersion
        if isFirstLaunchOfNewVersion {
            UserDefaults.standard.set(majorVersion, forKey: hasBeenLaunchOfNewVersion)
            UserDefaults.standard.synchronize()
        }
        return isFirstLaunchOfNewVersion;
    }
}
