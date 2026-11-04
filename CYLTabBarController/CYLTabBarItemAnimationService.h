//
//  CYLTabBarItemAnimationService.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #442
 * [EN] Where the animation for the current style comes from: the dark version and dark colors registered for a light
 *      animation URL. Core owns the registrations and provides the default (`CYLTabBarItemAnimationDefaultStyleSource()`);
 *      the engine only depends on this protocol.
 * [CN] 当前风格下的动画从哪里来：为浅色动画 URL 注册的深色版本与深色颜色。注册信息由 Core 持有并提供默认实现
 *      （`CYLTabBarItemAnimationDefaultStyleSource()`）；引擎只依赖本协议。
 */
@protocol CYLTabBarItemAnimationStyleSource <NSObject>
/// [EN] YES when any animation has a dark version or dark colors. [CN] 任意动画有深色版本或深色颜色时返回 YES。
- (BOOL)hasStyleVariants;
/// [EN] YES when `URL` has a dark version or dark colors. [CN] `URL` 有深色版本或深色颜色时返回 YES。
- (BOOL)hasStyleVariantForURL:(nullable NSURL *)URL;
/// [EN] The version of `URL` for `traitCollection`. [CN] `URL` 在 `traitCollection` 下的版本。
- (nullable NSURL *)URL:(nullable NSURL *)URL forTraitCollection:(nullable UITraitCollection *)traitCollection;
/// [EN] Keypath -> dark color for `URL`. [CN] `URL` 的「keypath -> 深色颜色」。
- (nullable NSDictionary<NSString *, UIColor *> *)darkColorsForURL:(nullable NSURL *)URL;
@end

/*!
 * FIX: issue #604 — private header of Core, not part of the public API.
 * [EN] The tab icon animation Core needs, as an abstraction Core owns (dependency inversion): Core calls only this
 *      protocol and knows no animation library. The `CYLTabBarItemAnimation` subspec, which comes only with an animation
 *      library's subspec (Lottie, PAG…), implements it (`CYLTabBarItemAnimationEngine`) and hands it to Core with
 *      `CYLTabBarItemAnimationSetService()` when it loads. Without it `CYLTabBarItemAnimationGetService()` is nil, every
 *      call is a no-op and the tabs show their images.
 * [CN] Core 需要的 Tab 图标动画能力，以 Core 自己定义的抽象表示（依赖反转）：Core 只调用本协议，不认识任何动画库。
 *      `CYLTabBarItemAnimation` 子库（只随某个动画库的子库引入：Lottie、PAG…）实现它（`CYLTabBarItemAnimationEngine`），并在加载时通过
 *      `CYLTabBarItemAnimationSetService()` 交给 Core。没有该子库时 `CYLTabBarItemAnimationGetService()` 为 nil，所有调用都不起作用，
 *      Tab 显示图片。
 */
@protocol CYLTabBarItemAnimationService <NSObject>

/// [EN] The animation view in `control` (two levels deep); nil for the plus button. [CN] `control` 中的动画视图（向下查找两层）；PlusButton 返回 nil。
- (nullable UIView *)animationViewInControl:(UIControl *)control;

/// [EN] YES for an animation view of any library. [CN] 任意动画库的动画视图返回 YES。
- (BOOL)isAnimationView:(UIView *)view;

/// [EN] YES once `control`'s animation view has been added and laid out. [CN] `control` 的动画视图已添加并完成布局时返回 YES。
- (BOOL)isAnimationReadyInControl:(UIControl *)control;

/*!
 * [EN] Adds the animation at `URL` (a local file) in place of `control`'s icon, once; a zero `size` uses the placeholder
 *      size. When this call adds the view and `animationSpeed` is above 0, sets that speed (#428).
 * [CN] 用 `URL`（本地文件）的动画替换 `control` 的图标显示（只添加一次）；size 为 0 时使用占位尺寸。本次调用新添加视图且
 *      `animationSpeed` 大于 0 时设置该速度（#428）。
 */
- (void)addAnimationWithURL:(nullable NSURL *)URL
                       size:(CGSize)size
                contentMode:(UIViewContentMode)contentMode
             animationSpeed:(CGFloat)animationSpeed
                  toControl:(UIControl *)control;

/// [EN] Sets the playback speed of `control`'s animation. [CN] 设置 `control` 动画的播放速度。
- (void)setAnimationSpeed:(CGFloat)animationSpeed inControl:(UIControl *)control;

/// [EN] Swaps `control`'s animation for the version matching the current style (#442). [CN] 将 `control` 的动画替换为与当前风格相符的版本（#442）。
- (void)reloadAnimationForCurrentStyleInControl:(UIControl *)control;

/// [EN] Adds the animation if needed and plays it (`defaultSelected`: its last frame). [CN] 必要时添加动画并播放（`defaultSelected`：显示最后一帧）。
- (void)playAnimationWithURL:(NSURL *)URL
                        size:(CGSize)size
             defaultSelected:(BOOL)defaultSelected
                 contentMode:(UIViewContentMode)contentMode
                   inControl:(UIControl *)control;

/// [EN] Stops `control`'s animation if it has started. [CN] 若 `control` 的动画已开始播放，则停止。
- (void)stopAnimationInControl:(UIControl *)control;

/*!
 * [EN] The key that stands for `genericKey` (`CYLTabBarAnimationURL`…) in the library `attributes` choose by their keys
 *      (e.g. `CYLTabBarRiveURL` when the tab uses Rive's keys); nil when it uses only generic keys.
 * [CN] `attributes` 通过 key 选择的动画库中与 `genericKey`（`CYLTabBarAnimationURL`…）对应的 key（例如 Tab 使用 Rive 的 key 时为
 *      `CYLTabBarRiveURL`）；只使用通用 key 时为 nil。
 */
- (nullable NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes;

/*!
 * [EN] Remembers that `URL` (a tab's file, or its dark version) is played by the library `attributes` choose by their
 *      keys, whatever its extension; with generic keys only, the file decides.
 * [CN] 记录 `URL`（Tab 的文件或其深色版本）由 `attributes` 通过 key 选择的动画库播放，与扩展名无关；只使用通用 key 时由文件决定。
 */
- (void)bindAnimationURL:(NSURL *)URL toAttributes:(NSDictionary *)attributes;

/// [EN] The file extensions the libraries in the build play, in lookup order. [CN] 构建中各动画库能播放的文件扩展名，按查找顺序排列。
- (NSArray<NSString *> *)animationFileExtensions;

@end

/// [EN] Called by the `CYLTabBarItemAnimation` subspec when it loads. [CN] 由 `CYLTabBarItemAnimation` 子库在加载时调用。
/// [EN] Core's style source, over the registrations of the `…DarkURL` / `…DarkFilePath` / `…DarkColors` keys.
/// [CN] Core 的风格来源，基于 `…DarkURL` / `…DarkFilePath` / `…DarkColors` 等 key 的注册信息。
FOUNDATION_EXTERN id<CYLTabBarItemAnimationStyleSource> CYLTabBarItemAnimationDefaultStyleSource(void);

FOUNDATION_EXTERN void CYLTabBarItemAnimationSetService(id<CYLTabBarItemAnimationService> _Nullable service);

/// [EN] The service, or nil without an animation library. [CN] 动画服务；没有动画库时为 nil。
FOUNDATION_EXTERN id<CYLTabBarItemAnimationService> _Nullable CYLTabBarItemAnimationGetService(void);

/// [EN] YES when an animation library is in the build. [CN] 构建中包含动画库时返回 YES。
static inline BOOL CYLTabBarItemAnimationIsAvailable(void) {
    return CYLTabBarItemAnimationGetService() != nil;
}

/*!
 * [EN] The value of a generic animation key (`CYLTabBarAnimationURL`…) in a tab's attributes: the generic key first, then
 *      the key of the one library the tab's keys choose (e.g. `CYLTabBarRiveURL`), never another library's. Core reads tab
 *      attributes only through this, so a new library needs no change in Core.
 * [CN] Tab 属性中某个通用动画 key（`CYLTabBarAnimationURL`…）的值：先取通用 key，再取 Tab 的 key 所选择的那一个动画库的 key（例如
 *      `CYLTabBarRiveURL`），不会取其他动画库的 key。Core 只通过它读取 Tab 属性，因此新增动画库时无需修改 Core。
 */
FOUNDATION_EXTERN id _Nullable CYLTabBarItemAttributesAnimationValue(NSDictionary * _Nullable attributes, NSString *genericKey);

NS_ASSUME_NONNULL_END
