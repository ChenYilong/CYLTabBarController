//
//  CYLBadgeObjCImport.swift
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Swift Package Manager only: this layer's Objective-C declarations live in the C target `CYLBadgeObjC`. CocoaPods and the Xcode
//      framework see them through the framework module.
// [CN] 仅 Swift Package Manager：本层的 Objective-C 声明位于 C 目标 `CYLBadgeObjC` 中。CocoaPods 与 Xcode framework 通过 framework 模块看到它们。
#if SWIFT_PACKAGE
@_exported import CYLBadgeObjC
#endif
