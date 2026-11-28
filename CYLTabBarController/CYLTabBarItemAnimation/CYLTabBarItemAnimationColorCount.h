//
//  CYLTabBarItemAnimationColorCount.h
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] What the one-color detector says about an animation file (the same algorithm and fixtures on every platform).
 * [CN] 单色检测对动画文件的判断（各平台算法与测试夹具相同）。
 */
typedef NS_ENUM(NSInteger, CYLTabBarItemAnimationColorKind) {
    /// [EN] Cannot tell (PAG, SVGA, Rive, dotLottie, a parse failure, a missing or remote file): the file keeps its original colors. [CN] 无法判断（PAG、SVGA、Rive、dotLottie、解析失败、文件缺失或远程文件）：保持原色。
    CYLTabBarItemAnimationColorKindUndetectable = 0,
    /// [EN] Exactly one color. [CN] 恰好一种颜色。
    CYLTabBarItemAnimationColorKindOneColor = 1,
    /// [EN] More than one color, a gradient or an image. [CN] 多种颜色、渐变或图片。
    CYLTabBarItemAnimationColorKindMultiColor = 2,
};

/*!
 * [EN] THE one-color detector, a pure function over the file's bytes (the format is read from the content):
 *      Lottie JSON: the distinct RGB of every visible fill (`fl`) and stroke (`st`), static values and every keyframe value (`s` and `e`);
 *      alpha, a color whose alpha is 0 and a fill whose static opacity is 0 are ignored, `hd` shapes are skipped; a color of 0...255 values
 *      (any channel above 1) is scaled down; colors are sorted by (r, g, b) in 8 bits and merged greedily when every channel is within
 *      +-2/255 of a color already kept; a gradient (`gf` / `gs`), an image asset (`p` string with `u`, `e` or `w`) or an image layer (`ty` 2) is
 *      MultiColor. One kept color: OneColor; more: MultiColor; none, or not a JSON object: Undetectable.
 *      GIF: the first frame, un-premultiplied; pixels with alpha < 0.1 are ignored; 4 bits per channel; 98% or more of the rest in ONE
 *      bucket: OneColor, else MultiColor; an empty frame: Undetectable.
 *      Anything else (PAG, SVGA, Rive, dotLottie): Undetectable.
 * [CN] 单色检测，对文件字节的纯函数（格式从内容判断）：Lottie JSON 取所有可见填充（`fl`）与描边（`st`）的不同 RGB（静态值与每个关键帧的值，`s` 与 `e`）；
 *      忽略透明度、透明度为 0 的颜色与静态不透明度为 0 的填充，跳过 `hd` 形状；0...255 的取值（任一通道大于 1）先缩放；颜色按 8 位 (r, g, b) 排序，
 *      每个通道与已保留颜色相差不超过 2/255 时合并；渐变（`gf` / `gs`）、图片资源、图片图层（`ty` 为 2）为多色。保留一种为单色，多种为多色，
 *      没有或不是 JSON 对象为无法判断。GIF：第一帧，取消预乘；透明度低于 0.1 的像素忽略；每通道 4 位；其余像素有 98% 以上落在同一桶：单色，否则多色；
 *      空帧为无法判断。其他格式（PAG、SVGA、Rive、dotLottie）为无法判断。
 */
FOUNDATION_EXTERN CYLTabBarItemAnimationColorKind CYLTabBarItemAnimationColorKindOfData(NSData * _Nullable data);

/*!
 * [EN] `CYLTabBarItemAnimationColorKindOfData` for a local file, cached per file (path, size and modification date); a remote URL or a file
 *      over 8 MB is Undetectable (nothing is downloaded for it). The URL's fragment (options) is ignored.
 * [CN] 本地文件的 `CYLTabBarItemAnimationColorKindOfData`，按文件（路径、大小与修改时间）缓存；远程 URL 或超过 8 MB 的文件为无法判断（不为此下载）。
 *      忽略 URL 的 fragment（选项）。
 */
FOUNDATION_EXTERN CYLTabBarItemAnimationColorKind CYLTabBarItemAnimationColorKindOfURL(NSURL * _Nullable url);

NS_ASSUME_NONNULL_END
