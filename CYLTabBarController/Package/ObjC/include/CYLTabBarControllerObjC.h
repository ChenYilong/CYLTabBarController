//
//  CYLTabBarControllerObjC.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The umbrella header of the SwiftPM C target `CYLTabBarControllerObjC`: what the Swift module `CYLTabBarController` imports from
//      Objective-C (typedefs, option sets, constants, C globals, category headers). This folder links to the tab bar's own headers (those of
//      CYLUtils, CYLBadge and CYLAnimatedItem are in their C targets' folders), so the headers find each other by name, as they do in CocoaPods' flat Headers folder. The target is compiled with
//      `CYL_OBJC_BASE_TARGET`, so `CYLSwiftInterface.h` does not import the Swift module back (docs/Swift-Migration.md, phase 3).
// [CN] SwiftPM 的 C 目标 `CYLTabBarControllerObjC` 的伞头文件：Swift 模块 `CYLTabBarController` 从 Objective-C 导入的内容（typedef、选项集、
//      常量、C 全局变量、类别头文件）。本文件夹链接 TabBar 自己的头文件（CYLUtils、CYLBadge、CYLAnimatedItem 的头文件在各自 C target 的目录中），使头文件能按名称互相找到，与 CocoaPods 的扁平 Headers 目录一致。
//      该目标以 `CYL_OBJC_BASE_TARGET` 编译，因此 `CYLSwiftInterface.h` 不会把 Swift 模块再导入回来（docs/Swift-Migration.md，第 3 阶段）。

#import "CYLTabBarController.h"

// [EN] The headers that stay Objective-C on purpose (block typedefs, string enums, option sets, constants), which `CYLTabBarController.h`
//      does not import. [CN] 有意保留为 Objective-C 的头文件（block typedef、字符串枚举、选项集、常量），`CYLTabBarController.h` 不导入它们。
#import "CYLAnimationKeys.h"
#import "CYLTabBarPageRegistry.h"
#import "CYLTabButtonAnimation.h"
#import "UIColor+CYLTheme.h"
#import "UIImage+CYLTheme.h"
#import "UIVisualEffect+CYLTheme.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"
