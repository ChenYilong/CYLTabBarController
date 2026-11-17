//
//  CYLTabBarItemAnimationPlayableView.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #415
 * [EN] `CYLTabBarItemAnimationPlayableView` (a view that plays itself: `-cyl_playAnimationView`, `-cyl_showAnimationViewLastFrame`,
 *      `-cyl_stopAnimationView`, optional `-cyl_applyAnimationViewColors:`) and `CYLTabBarItemAnimationViewProviding` (its factory,
 *      `+cyl_animationViewWithFileURL:options:contentMode:`) are declared in Swift (`Swift/CYLTabBarItemAnimationPlayableView.swift`),
 *      with the same selectors and Swift names; Objective-C gets them from the generated Swift interface imported below. In
 *      Swift, the Rive views adopting Objective-C protocols made the generated header import the umbrella header, which broke a
 *      CocoaPods build with the Rive subspec.
 * [CN] `CYLTabBarItemAnimationPlayableView`（自己会播放的视图）与 `CYLTabBarItemAnimationViewProviding`（其工厂）在 Swift 中声明
 *      （`Swift/CYLTabBarItemAnimationPlayableView.swift`），selector 与 Swift 名称不变；Objective-C 通过下方导入的 Swift 生成接口获得声明。
 *      此前 Swift 中的 Rive 视图遵守 Objective-C 协议，使生成的头文件导入总头文件，导致引入 Rive 子库的 CocoaPods 构建失败。
 */
@protocol CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding;

NS_ASSUME_NONNULL_END

// [EN] The Swift protocols, from the module that compiles them: the CYLAnimatedItem pod, Swift Package Manager's Swift target,
//      or the framework target of CYLTabBarController.xcodeproj. Never CYLTabBarController's CocoaPods module.
// [CN] Swift 协议，来自编译它们的模块：CYLAnimatedItem pod、Swift Package Manager 的 Swift target，或 CYLTabBarController.xcodeproj
//      的 framework target。不来自 CYLTabBarController 的 CocoaPods 模块。
#ifndef __swift__
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#elif __has_include("CYLAnimatedItem-Swift.h")
#import "CYLAnimatedItem-Swift.h"
#elif defined(SWIFT_PACKAGE)
@import CYLTabBarControllerSwift;
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>) || __has_include("CYLTabBarController-Swift.h")
// [EN] A framework with the component and the tab bar in one module: the Swift header declares a subclass of
//      CYLAnimatedItemView (CYLFlatDesignTabBarButton), so the component's interface comes first.
// [CN] 组件与 TabBar 在同一模块的 framework：Swift 头文件声明了 CYLAnimatedItemView 的子类（CYLFlatDesignTabBarButton），因此先导入组件的接口。
#if __has_include(<CYLTabBarController/CYLAnimatedItemView.h>)
#import <CYLTabBarController/CYLAnimatedItemView.h>
#elif __has_include("CYLAnimatedItemView.h")
#import "CYLAnimatedItemView.h"
#endif
#if __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#else
#import "CYLTabBarController-Swift.h"
#endif
#endif
#endif
