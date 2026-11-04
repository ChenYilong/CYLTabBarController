//
//  TabBarAnimationDemo.swift
//  HealthyHome
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// [EN] The Rive part of the animation demo: Example-Rive reuses every other source of Example-PAG and has its own copy
///      of only this file.
/// [CN] 动画 Demo 中与 Rive 相关的部分：Example-Rive 复用 Example-PAG 的其他所有源文件，只有这个文件是它自己的版本。
enum TabBarAnimationDemo {

    static func addingAnimations(to tabBarItemsAttributes: [[AnyHashable: Any]]) -> [[AnyHashable: Any]] {
        // [EN] Rive animations, with the `CYLTabBarController/Rive` subspec. Every icon is an artboard of one file,
        //      "icon-set.riv" (rive_animated_icon, MIT; Example-Shared/RiveResources, fetched by `pod install`): the
        //      options of `CYLTabBarAnimationURLWithOptions()` name the artboard and its state machine. Selecting a tab sets
        //      the view model boolean "active" to true for a second, which plays the icon. nil leaves the second tab with
        //      its images (#477).
        // [CN] 使用 Rive 动画，需引入 `CYLTabBarController/Rive` 子库。所有图标都是同一个文件「icon-set.riv」中的画板（rive_animated_icon，MIT；
        //      Example-Shared/RiveResources，由 `pod install` 下载）：`CYLTabBarAnimationURLWithOptions()` 的选项指定画板及其状态机。选中 Tab 时，
        //      view model 布尔属性 "active" 设为 true 一秒，图标随之播放。nil 表示第二个 Tab 保持图片（#477）。
        let iconSet = Bundle.main.url(forResource: "icon-set", withExtension: "riv")
        let icons: [(artboard: String, stateMachine: String)?] = [
            ("HOME", "HOME_interactivity"),
            nil,
            ("BELL", "BELL_Interactivity"),
            ("USER", "USER_Interactivity"),
        ]
        return zip(tabBarItemsAttributes, icons).map { attributes, icon in
            var item = attributes
            guard let icon, let url = CYLTabBarAnimationURLWithOptions(iconSet, [
                .riveArtboard: icon.artboard,
                .riveStateMachine: icon.stateMachine,
                .riveColor: "#1F1F1F",
            ]) else {
                return item
            }
            item[CYLTabBarRiveURL] = url
            item[CYLTabBarRiveSize] = NSValue(cgSize: CGSize(width: 30, height: 30))
            // [EN] Dark Mode with the same file: the view model color "color" turns white. [CN] 同一份文件适配深色模式：view model 颜色 "color" 变为白色。
            item[CYLTabBarRiveDarkColors] = ["color": UIColor.white]
            return item
        }
    }
}
