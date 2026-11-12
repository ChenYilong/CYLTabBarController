//
//  CYLSwiftInterface.h
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * [EN] The Objective-C interface of the library's Swift code (docs/Swift-Migration.md): the header Swift generates
 *      (CocoaPods, Carthage, the Xcode framework) or the Swift module (SwiftPM). Classes translated to Swift are
 *      declared only there, as a class cannot be declared twice. Never imported while Swift itself compiles
 *      (`__swift__`), which would import Swift's own declarations back into it.
 * [CN] 本库 Swift 代码的 Objective-C 接口（docs/Swift-Migration.md）：Swift 生成的头文件（CocoaPods、Carthage、Xcode framework）或
 *      Swift 模块（SwiftPM）。已翻译为 Swift 的类只在这里声明，因为一个类不能声明两次。Swift 自身编译时不导入（`__swift__`），
 *      否则会把 Swift 自己的声明再导入回去。
 */
#ifndef __swift__
#if defined(SWIFT_PACKAGE)
@import CYLTabBarControllerSwift;
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#elif __has_include("CYLTabBarController-Swift.h")
#import "CYLTabBarController-Swift.h"
#endif
#endif
