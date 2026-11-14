//
//  CYLTabBarItemAnimator.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLTabBarItemAnimationPlayer.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Lookup order of animators: higher first; equal priorities keep their registration order.
 * [CN] animator 的查找顺序：数值大的优先；相同优先级按注册顺序。
 */
typedef NSInteger CYLTabBarItemAnimatorPriority NS_TYPED_EXTENSIBLE_ENUM;
/*!
 * [EN] An animator that recognizes its own files (the default). [CN] 只识别自己文件类型的 animator（默认）。
 */
static const CYLTabBarItemAnimatorPriority CYLTabBarItemAnimatorPriorityDefault = 0;
/*!
 * [EN] An animator that takes any file no other animator takes (Lottie). [CN] 接收其他 animator 都不处理的文件的 animator（Lottie）。
 */
static const CYLTabBarItemAnimatorPriority CYLTabBarItemAnimatorPriorityFallback = -1000;

/*!
 * FIX: issue #604 — public protocols of the `CYLTabBarItemAnimation` subspec, split by role (interface segregation).
 * [EN] An animation library is described by two small protocols, combined in `CYLTabBarItemAnimator`:
 *      - `CYLTabBarItemAnimationFileMatching`: which files it plays, and how it is looked up;
 *      - `CYLTabBarItemAnimationViewFactory`: the views it makes, and a `CYLTabBarItemAnimationPlayer` for each.
 *      The tab bar only talks to these protocols (dependency inversion), through `CYLTabBarItemAnimatorRegistry` and
 *      `CYLTabBarItemAnimationFactory`. To add a library, write a class adopting `CYLTabBarItemAnimator` and a player
 *      class, and register the animator in its `+load`, compiled only when the library is linked; nothing else changes
 *      (see docs/Tab-Bar-Item-Animation.md).
 * [CN] 一个动画库由两个小协议描述，并组合为 `CYLTabBarItemAnimator`：
 *      - `CYLTabBarItemAnimationFileMatching`：能播放哪些文件，以及如何被查找；
 *      - `CYLTabBarItemAnimationViewFactory`：创建视图，并为每个视图提供一个 `CYLTabBarItemAnimationPlayer`。
 *      TabBar 只通过 `CYLTabBarItemAnimatorRegistry` 与 `CYLTabBarItemAnimationFactory` 与这些协议交互（依赖反转）。新增动画库时，编写一个遵守
 *      `CYLTabBarItemAnimator` 的类和一个播放器类，并在 `+load` 中注册 animator（仅在链接了该动画库时编译）；其他代码都无需修改
 *      （见 docs/Tab-Bar-Item-Animation.md）。
 */
@protocol CYLTabBarItemAnimationFileMatching <NSObject>

/*!
 * [EN] A unique name, e.g. @"Lottie", @"PAG"; registering the same name again replaces the animator.
 * [CN] 唯一名称，例如 @"Lottie"、@"PAG"；再次注册同名 animator 会替换原来的。
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/*!
 * [EN] YES for an animation file this library plays. [CN] 本动画库能播放的动画文件返回 YES。
 */
- (BOOL)canAnimateFileAtURL:(NSURL *)URL;

@optional

/*!
 * [EN] The lookup order (default `CYLTabBarItemAnimatorPriorityDefault`). [CN] 查找顺序（默认 `CYLTabBarItemAnimatorPriorityDefault`）。
 */
@property (nonatomic, readonly) CYLTabBarItemAnimatorPriority priority;

/*!
 * [EN] The file extensions it plays, e.g. @[@"pag"], used to find "<name>.<ext>" for a bare file name
 *      (`CYLTabBarItemAttributesAddingAnimationFile`).
 * [CN] 能播放的文件扩展名，例如 @[@"pag"]；用于为不带扩展名的文件名查找「名称.扩展名」（`CYLTabBarItemAttributesAddingAnimationFile`）。
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *fileExtensions;

/*!
 * [EN] This library's own attribute keys, by the generic key they stand for, e.g.
 *      @{ CYLTabBarAnimationURL : CYLTabBarPAGURL }. The generic keys (`CYLTabBarAnimation…`) always work.
 * [CN] 本动画库自己的属性 key，按其对应的通用 key 列出，例如 @{ CYLTabBarAnimationURL : CYLTabBarPAGURL }。通用 key（`CYLTabBarAnimation…`）始终有效。
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *attributeKeys;

@end

/*!
 * [EN] The factory side of a library: it makes the views, and a player for each (Abstract Factory). The engine never
 *      creates or inspects a library's view itself.
 * [CN] 动画库的工厂部分：创建视图，并为每个视图创建播放器（抽象工厂）。引擎从不自行创建或检查某个动画库的视图。
 */
@protocol CYLTabBarItemAnimationViewFactory <NSObject>

/*!
 * [EN] A view showing the first frame of the animation at `URL`, scaled like `contentMode`; nil when the file cannot be
 *      loaded. `CYLTabBarItemAnimationFactory` sets its frame and layout.
 * [CN] 显示 `URL` 动画第一帧的视图，按 `contentMode` 缩放；文件无法加载时返回 nil。由 `CYLTabBarItemAnimationFactory` 设置 frame 与布局。
 */
- (nullable UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] A player for `view` when it is one of this library's views, else nil (also used to recognize a view).
 * [CN] `view` 是本动画库的视图时返回其播放器，否则返回 nil（也用于识别视图）。
 */
- (nullable id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view;

@end

/*!
 * [EN] An animation library for tab icons: Lottie, PAG, or any library added later. [CN] Tab 图标动画库：Lottie、PAG 或以后新增的任意动画库。
 */
@protocol CYLTabBarItemAnimator <CYLTabBarItemAnimationFileMatching, CYLTabBarItemAnimationViewFactory>
@end

NS_ASSUME_NONNULL_END
