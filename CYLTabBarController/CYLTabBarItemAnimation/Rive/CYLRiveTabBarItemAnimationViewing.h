//
//  CYLRiveTabBarItemAnimationViewing.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLRiveTabBarItemAnimationConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

/// [EN] Main actor in Swift: views are used on the main thread. The methods keep the `cyl_` prefix in Objective-C (no
///      clash with UIKit) and get camelCase names in Swift (`NS_SWIFT_NAME`).
/// [CN] 在 Swift 中属于主 actor：视图只在主线程使用。方法在 Objective-C 中保留 `cyl_` 前缀（避免与 UIKit 冲突），在 Swift 中使用驼峰命名
///      （`NS_SWIFT_NAME`）。
#ifndef NS_SWIFT_UI_ACTOR
#define NS_SWIFT_UI_ACTOR
#endif

/*!
 * [EN] The interface between the Rive animator (Objective-C) and a view that renders Rive: what the player calls. The
 *      animator and its player depend only on this protocol, never on a concrete view class; the Swift bridge
 *      `CYLRiveTabBarItemAnimationView` (RiveSwift/) adopts it, and so can any other view (a test double, another
 *      renderer).
 * [CN] Rive animator（Objective-C）与渲染 Rive 的视图之间的接口：播放器调用的方法。animator 及其播放器只依赖本协议，从不依赖具体的视图类；
 *      Swift 桥接 `CYLRiveTabBarItemAnimationView`（RiveSwift/）遵守它，其他视图（测试替身、其他渲染方式）也可以遵守。
 */
NS_SWIFT_UI_ACTOR
@protocol CYLRiveTabBarItemAnimationViewing <NSObject>

/// [EN] Plays once (sets the active boolean, or fires the trigger). [CN] 播放一次（设置 active 布尔属性，或触发 trigger）。
- (void)cyl_play NS_SWIFT_NAME(playAnimation());

/// [EN] The resting state, without playing (the tab selected at launch, #389). [CN] 静止状态，不播放（启动时选中的 Tab，#389）。
- (void)cyl_showLastFrame NS_SWIFT_NAME(showAnimationRestingState());

/// [EN] Stops: the active boolean goes back to NO. [CN] 停止：active 布尔属性恢复为 NO。
- (void)cyl_stop NS_SWIFT_NAME(stopAnimation());

/// [EN] View model color property path -> color; nil restores the light colors. [CN] view model 颜色属性路径 -> 颜色；nil 恢复浅色颜色。
- (void)cyl_applyColors:(nullable NSDictionary<NSString *, UIColor *> *)colors NS_SWIFT_NAME(applyAnimationColors(_:));

@end

/*!
 * [EN] The abstract factory of Rive views: the animator asks its provider (`+[CYLRiveTabBarItemAnimator viewProvider]`)
 *      for a view, so which class renders Rive is decided where the pieces are wired, not inside the animator.
 * [CN] Rive 视图的抽象工厂：animator 向其 provider（`+[CYLRiveTabBarItemAnimator viewProvider]`）请求视图，因此由哪个类渲染 Rive 在装配处决定，
 *      而不是在 animator 内部。
 */
NS_SWIFT_UI_ACTOR
@protocol CYLRiveTabBarItemAnimationViewProviding <NSObject>

/// [EN] A view for `configuration`, or nil. [CN] 根据 `configuration` 创建的视图，或 nil。
+ (nullable UIView<CYLRiveTabBarItemAnimationViewing> *)cyl_animationViewWithConfiguration:(CYLRiveTabBarItemAnimationConfiguration *)configuration
    NS_SWIFT_NAME(makeAnimationView(configuration:));

@end

NS_ASSUME_NONNULL_END
