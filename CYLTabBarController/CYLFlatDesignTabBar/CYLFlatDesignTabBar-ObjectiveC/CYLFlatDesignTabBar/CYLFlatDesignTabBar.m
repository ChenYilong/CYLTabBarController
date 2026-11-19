//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The Objective-C shell of `CYLFlatDesignTabBar` (docs/Swift-Migration.md, step 50): the implementation is Swift
//      (`Swift/CYLFlatDesignTabBar+CYLImplementation.swift`). The class stays declared in Objective-C because
//      `CYLTabBarController.h` adopts `CYLFlatDesignTabBarDelegate`, which its interface names; this file keeps the
//      overrides and the public accessors, each a one-line forward to a `cyl_flatDesign…` method of the Swift extension.
// [CN] `CYLFlatDesignTabBar` 的 Objective-C 外壳（docs/Swift-Migration.md，第 50 步）：实现位于 Swift
//      （`Swift/CYLFlatDesignTabBar+CYLImplementation.swift`）。类仍在 Objective-C 中声明，因为 `CYLTabBarController.h` 遵守其接口引用的
//      `CYLFlatDesignTabBarDelegate`；本文件保留重写方法与公开存取方法，每个都是一行转发到 Swift 扩展的 `cyl_flatDesign…` 方法。

// [EN] Only the C constant is left here: `CYLFlatDesignTabBar` is Swift (`Swift/CYLFlatDesignTabBar.swift`, step 101), and Swift
//      cannot define a C symbol that Objective-C callers link against (`extern NSString *const` in CYLFlatDesignTabBarItem.h).
// [CN] 这里只剩 C 常量：`CYLFlatDesignTabBar` 已改为 Swift（`Swift/CYLFlatDesignTabBar.swift`，第 101 步），而 Swift 无法定义供 Objective-C
//      调用方链接的 C 符号（CYLFlatDesignTabBarItem.h 中的 `extern NSString *const`）。
#import <Foundation/Foundation.h>

NSString *const CYLFlatDesignTabBarItemDidChange = @"CYLFlatDesignTabBarItemDidChange";
