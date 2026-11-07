//
//  CYLGIFTabBarItemAnimator.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include("../CYLTabBarItemViewAnimator.h")
#import "../CYLTabBarItemViewAnimator.h"
#else
#import "CYLTabBarItemViewAnimator.h"
#endif

/*!
 * [EN] 1 when ImageIO, which decodes GIF files, is part of the build; 0 otherwise. Everything below, the GIF keys included,
 *      exists only then. Use `#if CYL_GIF_AVAILABLE` for GIF-only code of your own. CocoaPods: `pod 'CYLTabBarController/GIF'`.
 * [CN] 工程中有解码 GIF 的 ImageIO 时为 1，否则为 0。以下所有内容（包括 GIF 的 key）只在此时存在。App 自己只用于 GIF 的代码可用
 *      `#if CYL_GIF_AVAILABLE` 包住。CocoaPods：`pod 'CYLTabBarController/GIF'`。
 */
#if __has_include(<ImageIO/ImageIO.h>)
#define CYL_GIF_AVAILABLE 1
#else
#define CYL_GIF_AVAILABLE 0
#endif

#if CYL_GIF_AVAILABLE
NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #605
 * [EN] GIF tab icons that play once when the tab is selected, the same way as Lottie, PAG and Rive, through the short path
 *      of the `CYLTabBarItemAnimation` subspec: a `CYLTabBarItemViewAnimator` for ".gif" files, whose view plays itself.
 *      This class only registers it and declares the GIF keys. How a GIF plays depends on the key that gives it:
 *      - `CYLTabBarGIFURL` / `CYLTabBarGIFFilePath` (or the generic `CYLTabBarAnimationURL` / `…FilePath`): an animation.
 *        It shows its first frame, plays once when the tab is selected and stays on its last frame.
 *      - `CYLTabBarItemImage` with an animated image, or `CYLTabBarItemImageURL`: an image. It loops, and needs no subspec.
 * [CN] 选中 Tab 时播放一次的 GIF Tab 图标，用法与 Lottie、PAG、Rive 相同，通过 `CYLTabBarItemAnimation` 子库的简便方式接入：为 ".gif" 文件注册
 *      一个 `CYLTabBarItemViewAnimator`，其视图自己播放。本类只负责注册它并声明 GIF 的 key。GIF 如何播放取决于传入它的 key：
 *      - `CYLTabBarGIFURL` / `CYLTabBarGIFFilePath`（或通用的 `CYLTabBarAnimationURL` / `…FilePath`）：动画。显示第一帧，选中 Tab 时播放一次，
 *        然后停在最后一帧。
 *      - `CYLTabBarItemImage` 传动图，或 `CYLTabBarItemImageURL`：图片。循环播放，不需要子库。
 */
@interface CYLGIFTabBarItemAnimator : NSObject

/// [EN] The registered animator, e.g. to inject another view provider. [CN] 已注册的 animator，例如用于注入其他视图 provider。
@property (class, nonatomic, readonly) CYLTabBarItemViewAnimator *animator;

@end

/*!
 * [EN] Keys for a tab's GIF animation, aliases of the generic `CYLTabBarAnimation…` keys (either works), like the Lottie, PAG
 *      and Rive keys. A GIF has no color layers, so there is no dark colors key: give a Dark Mode file instead.
 *      - `CYLTabBarGIFURL`: an NSURL of a local .gif file; `CYLTabBarGIFFilePath`: its full path (NSString). The URL wins.
 *      - `CYLTabBarGIFSize`: the view size, an NSValue of CGSize.
 *      - `CYLTabBarGIFDarkURL` / `CYLTabBarGIFDarkFilePath`: the Dark Mode version.
 * [CN] Tab 的 GIF 动画 key，是通用 key `CYLTabBarAnimation…` 的别名（两者都可以用），与 Lottie、PAG、Rive 的 key 相同。GIF 没有颜色图层，因此没有深色颜色
 *      key：请提供深色模式的文件。
 *      - `CYLTabBarGIFURL`：本地 .gif 文件的 NSURL；`CYLTabBarGIFFilePath`：其完整路径（NSString）。URL 优先。
 *      - `CYLTabBarGIFSize`：视图尺寸，CGSize 的 NSValue。
 *      - `CYLTabBarGIFDarkURL` / `CYLTabBarGIFDarkFilePath`：深色模式版本。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarGIFURL;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFFilePath;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFSize;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFDarkURL;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFDarkFilePath;

NS_ASSUME_NONNULL_END
#endif
