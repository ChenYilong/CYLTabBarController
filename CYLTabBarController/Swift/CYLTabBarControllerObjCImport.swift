//
//  CYLTabBarControllerObjCImport.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Swift Package Manager only (docs/Swift-Migration.md, phase 3): the Objective-C declarations of this library (typedefs, option sets,
//      constants, C globals) live in the C target `CYLTabBarControllerObjC`, below this module. CocoaPods, Carthage and the Xcode
//      framework see them through the framework module, so they do not need (or have) this import.
// [CN] 仅 Swift Package Manager（docs/Swift-Migration.md，第 3 阶段）：本库的 Objective-C 声明（typedef、选项集、常量、C 全局变量）位于本模块之下的
//      C 目标 `CYLTabBarControllerObjC` 中。CocoaPods、Carthage 与 Xcode framework 通过 framework 模块看到它们，因此不需要（也没有）这个导入。
#if SWIFT_PACKAGE
@_exported import CYLTabBarControllerObjC
@_exported import CYLAnimatedItemViews
@_exported import CYLAnimatedItemSwift
#endif
