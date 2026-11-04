//
//  TabBarAnimationDemo.swift
//  HealthyHome
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// [EN] The PAG part of the animation demo: Example-Rive reuses every other source of this app and has its own copy of
///      only this file.
/// [CN] 动画 Demo 中与 PAG 相关的部分：Example-Rive 复用本 App 的其他所有源文件，只有这个文件是它自己的版本。
enum TabBarAnimationDemo {

    static func addingAnimations(to tabBarItemsAttributes: [[AnyHashable: Any]]) -> [[AnyHashable: Any]] {
        // [EN] #604: PAG animations (Tencent libpag) instead of Lottie, with the `CYLTabBarController/PAG` subspec. Each name is
        //      "<name>.pag" in the main bundle (Example-Shared/PAGResources/pag-ios, fetched by `pod install`); "<name>_dark.pag" would be its Dark Mode version.
        //      Without the subspec no library plays ".pag" files, so the images show.
        // [CN] #604：使用 PAG 动画（腾讯 libpag）代替 Lottie，需引入 `CYLTabBarController/PAG` 子库。每个名称对应 main bundle 中的
        //      「<名称>.pag」（Example-Shared/PAGResources/pag-ios，由 `pod install` 下载）；「<名称>_dark.pag」为其深色模式版本。未引入子库时没有动画库播放 ".pag" 文件，显示图片。
        // [EN] #477: only some tabs are animated. Each tab takes its own file through
        //      `CYLTabBarItemAttributesAddingAnimationFile()` ("<name>.pag": PAG, "<name>.json": Lottie, or the file type of
        //      any library added later); "" leaves the second tab ("健康") with its images. Selecting it stops the animated tabs.
        // [CN] #477：只有部分 Tab 有动画。每个 Tab 通过 `CYLTabBarItemAttributesAddingAnimationFile()` 使用自己的文件（「名称.pag」为 PAG，
        //      「名称.json」为 Lottie，或以后新增动画库的文件类型）；"" 表示第二个 Tab（「健康」）保持图片。选中它时，有动画的 Tab 会停止。
        let animationFiles = ["1.pag", "", "22.pag", "test2.pag"]
        return zip(tabBarItemsAttributes, animationFiles).map { attributes, fileName in
            var item = CYLTabBarItemAttributesAddingAnimationFile(attributes, fileName, nil)
            // [EN] The generic size key, for any animation library: `CYLTabBarAnimationSize` (only for the animated tabs).
            // [CN] 通用的尺寸 key，适用于任意动画库：`CYLTabBarAnimationSize`（仅用于有动画的 Tab）。
            if item[CYLTabBarAnimationFilePath] != nil {
                item[CYLTabBarAnimationSize] = NSValue(cgSize: CGSize(width: 33, height: 33))
            }
            return item
        }
    }
}
