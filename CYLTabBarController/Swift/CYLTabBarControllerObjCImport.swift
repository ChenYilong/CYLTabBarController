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

// [EN] D7 (docs/Animated-Item-Badge.md): Core sits on top of CYLUtils, CYLBadge and CYLAnimatedItem, each a module of its own, and
//      re-exports them so `import CYLTabBarController` keeps giving their keys and classes to callers (CocoaPods and the Xcode framework
//      compile some of them into this module, hence `canImport`). Built on macOS, 2026-11-29.
// [CN] D7（docs/Animated-Item-Badge.md）：Core 位于 CYLUtils、CYLBadge 与 CYLAnimatedItem 之上，它们各自是独立的模块；在此重新导出，使
//      `import CYLTabBarController` 仍向调用方提供它们的 key 与类（CocoaPods 与 Xcode framework 会把其中一部分编进本模块，因此用 `canImport`）。
//      已于 2026-11-29 在 macOS 上构建。
#if canImport(CYLAnimatedItem)
@_exported import CYLAnimatedItem
#endif
#if canImport(CYLBadge)
@_exported import CYLBadge
#endif
#if canImport(CYLUtilsKit)
@_exported import CYLUtilsKit
#endif
