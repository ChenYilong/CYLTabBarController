//
//  AppDelegate.swift
//  WYWTabBar
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // [EN] FIX: issue #601 — how long and how much the icons from the network stay cached (memory and sandbox), as
        //      SDWebImage's SDImageCacheConfig.
        // [CN] 网络图标在内存与沙盒中的缓存时长与大小，参考 SDWebImage 的 SDImageCacheConfig。
        let imageCache = CYLImageCache.shared()
        imageCache.maxDiskAge = 30 * 24 * 60 * 60                  // 30 days
        imageCache.maxDiskSize = 20 * 1024 * 1024                  // 20 MB
        imageCache.diskCacheExpireType = .accessDate
        return true
    }
}
