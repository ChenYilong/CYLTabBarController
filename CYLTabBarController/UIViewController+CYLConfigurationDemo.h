//
//  UIViewController+CYLConfigurationDemo.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>


/*!
 * [EN] The string constants of this header are macros for Objective-C and Swift constants for Swift
 *      (`Swift/CYLConstants+Keys.swift`); each `#ifndef __swift__` hides a macro from Swift (docs/Swift-Migration.md).
 * [CN] 本头文件中的字符串常量对 Objective-C 是宏，对 Swift 是常量（`Swift/CYLConstants+Keys.swift`）；每个 `#ifndef __swift__`
 *      对 Swift 隐藏一个宏（docs/Swift-Migration.md）。
 */


/*!
 * [EN] The URL of a sample configuration on GitHub, used by the demo's "load from a URL" action.
 * [CN] GitHub 上示例配置文件的 URL，用于演示中的“从网络 URL 加载”。
 */
#ifndef __swift__
#define CYLSampleConfigurationURLString @"https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/Example-Shared/Configurations/cyl_tabbar_configuration.yaml"
#endif

/*!
 * [EN] A demo row of the settings section (see `UIViewController+CYLSettingsSection.h`): one configuration file creates a
 *      whole `CYLTabBarController` (`+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]`). The row offers
 *      the sample files, one per format (JSON, JSON5, JSONC, plist in XML, binary and OpenStep form, .strings, YAML, TOML,
 *      INI, .cfg, .properties, .env, XML, Protobuf text and binary), and a download from a URL
 *      (`+[CYLTabBarController loadTabBarControllerWithConfigurationURL:completion:]`). The tab bar controller it creates is
 *      presented full screen; every page shows the file it came from, and a Close button.
 * [CN] 设置分组中的一个演示行（见 `UIViewController+CYLSettingsSection.h`）：一个配置文件生成整个 `CYLTabBarController`
 *      （`+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]`）。该行提供各格式的示例文件（JSON、JSON5、JSONC、XML / 二进制 /
 *      OpenStep 格式的 plist、.strings、YAML、TOML、INI、.cfg、.properties、.env、XML、Protobuf 文本与二进制），以及从 URL 下载
 *      （`+[CYLTabBarController loadTabBarControllerWithConfigurationURL:completion:]`）。生成的 TabBarController 全屏展示，每个页面显示其来源文件，
 *      并带有关闭按钮。
 */

/*!
 * [EN] `UIViewController (CYLConfigurationDemo)` and `UIViewController (CYLConfigurationEdgeCases)` are implemented in Swift
 *      (`Swift/UIViewController+CYLConfigurationDemo.swift`, every selector kept) and declared by the generated Swift interface
 *      (`CYLSwiftInterface.h`), imported below (docs/Swift-Migration.md, step 31).
 * [CN] `UIViewController (CYLConfigurationDemo)` 与 `UIViewController (CYLConfigurationEdgeCases)` 在 Swift 中实现
 *      （`Swift/UIViewController+CYLConfigurationDemo.swift`，所有 selector 不变），由下面导入的 Swift 生成接口（`CYLSwiftInterface.h`）声明
 *      （docs/Swift-Migration.md，第 31 步）。
 */
#import "CYLSwiftInterface.h"
