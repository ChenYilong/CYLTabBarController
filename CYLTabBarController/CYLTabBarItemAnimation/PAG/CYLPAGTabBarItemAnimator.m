//
//  CYLPAGTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPAGTabBarItemAnimator.h"
// [EN] Core's generic keys and helpers. [CN] Core 的通用 key 与工具函数。
#if __has_include("../../CYLTabBarController.h")
#import "../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif

// FIX: issue #604 — only with libpag (`CYL_PAG_AVAILABLE`, the PAG subspec); without it this file is empty: no keys,
// no class.
// [CN] 仅在引入 libpag 时编译（`CYL_PAG_AVAILABLE`，PAG 子库）；未引入时本文件为空：没有 key，也没有类。
#if CYL_PAG_AVAILABLE
#import <libpag/PAGView.h>

// [EN] The PAG keys, declared by the PAG subspec (aliases of the generic keys, see `attributeKeys`).
// [CN] PAG 的 key，由 PAG 子库声明（通用 key 的别名，见 `attributeKeys`）。
NSString *const CYLTabBarPAGURL = @"CYLTabBarPAGURL";
NSString *const CYLTabBarPAGFilePath = @"CYLTabBarPAGFilePath";
NSString *const CYLTabBarPAGSize = @"CYLTabBarPAGSize";
NSString *const CYLTabBarPAGDarkURL = @"CYLTabBarPAGDarkURL";
NSString *const CYLTabBarPAGDarkFilePath = @"CYLTabBarPAGDarkFilePath";

NSArray<NSDictionary *> *CYLTabBarItemsAttributesAddingPAGFiles(NSArray<NSDictionary *> *attributes,
                                                                 NSArray<NSString *> *pagFileNames,
                                                                 NSBundle *bundle) {
    // [EN] The generic helper with "<name>.pag": the same files, under the generic keys the PAG keys stand for.
    // [CN] 使用「名称.pag」调用通用工具函数：文件相同，使用 PAG key 所对应的通用 key。
    NSMutableArray *fileNames = [NSMutableArray arrayWithCapacity:pagFileNames.count];
    for (id name in pagFileNames) {
        BOOL hasName = [name isKindOfClass:[NSString class]] && [(NSString *)name length] > 0;
        [fileNames addObject:hasName ? [(NSString *)name stringByAppendingPathExtension:@"pag"] : @""];
    }
    return CYLTabBarItemsAttributesAddingAnimationFiles(attributes, fileNames, bundle);
}

// The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif

/// [EN] Plays a `PAGView`. [CN] 播放 `PAGView`。
@interface CYLPAGTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLPAGTabBarItemAnimationPlayer

- (PAGView *)pagView {
    return (PAGView *)self.animationView;
}

- (void)play {
    PAGView *pagView = self.pagView;
    [pagView stop];
    [pagView setProgress:0];
    [pagView play];
}

- (void)showLastFrame {
    PAGView *pagView = self.pagView;
    [pagView setProgress:1];
    [pagView flush];
}

- (void)stop {
    // As a stopped Lottie view: only when it has moved, back to the first frame. 与停止后的 Lottie 视图一致：仅在播放过时回到第一帧。
    PAGView *pagView = self.pagView;
    if ([pagView getProgress] <= 0) {
        return;
    }
    [pagView stop];
    [pagView setProgress:0];
    [pagView flush];
}

/// [EN] PAG has no playback speed, so only the progress is exposed. [CN] PAG 没有播放速度，因此只提供进度。
- (CGFloat)progress {
    return (CGFloat)[self.pagView getProgress];
}

- (void)setProgress:(CGFloat)progress {
    PAGView *pagView = self.pagView;
    [pagView setProgress:progress];
    [pagView flush];
}

@end

@implementation CYLPAGTabBarItemAnimator

/// [EN] Registers itself when it is linked (only with libpag). [CN] 被链接时自行注册（仅在引入 libpag 时）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[self alloc] init]];
}

- (NSString *)identifier {
    return @"PAG";
}

- (NSArray<NSString *> *)fileExtensions {
    return @[ @"pag" ];
}

/// [EN] The PAG keys, which stand for the generic `CYLTabBarAnimation…` keys. [CN] PAG 的 key，对应通用的 `CYLTabBarAnimation…` key。
- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{
        CYLTabBarAnimationURL : CYLTabBarPAGURL,
        CYLTabBarAnimationFilePath : CYLTabBarPAGFilePath,
        CYLTabBarAnimationSize : CYLTabBarPAGSize,
        CYLTabBarAnimationDarkURL : CYLTabBarPAGDarkURL,
        CYLTabBarAnimationDarkFilePath : CYLTabBarPAGDarkFilePath,
    };
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    return [URL.pathExtension.lowercaseString isEqualToString:@"pag"];
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    // Loaded as the official samples (libpag/pag-ios) do: `-setComposition:` with `+[PAGFile Load:]`, which every
    // libpag version has (3.x and later).
    // 与官方示例（libpag/pag-ios）一致：用 `+[PAGFile Load:]` 加 `-setComposition:` 加载，各版本均支持。
    PAGFile *pagFile = URL.path.length > 0 ? [PAGFile Load:URL.path] : nil;
    if (!pagFile) {
        return nil;
    }
    PAGView *pagView = [[PAGView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
#if TARGET_OS_SIMULATOR
    // [EN] The simulator draws PAG with software OpenGL. With one render thread per PAGView, as a tab bar has, those threads
    //      stall inside OpenGL while holding their player's lock: the first call that needs the lock (`-stop`, `-setHidden:`)
    //      then blocks the main thread, icons stay blank and tapping a tab plays nothing. Rendering on the main thread avoids it.
    // [CN] 模拟器用软件 OpenGL 绘制 PAG。每个 PAGView 一个绘制线程（TabBar 中有多个）时，这些线程会在 OpenGL 内部卡住并持有播放器的锁：
    //      之后第一个需要该锁的调用（`-stop`、`-setHidden:`）会阻塞主线程，图标空白，点击 Tab 不播放。改为在主线程绘制可以避免。
    [pagView setSync:YES];
#endif
    [pagView setComposition:pagFile];
    // Like a Lottie view: plays once, shows its first frame until then. 与 Lottie 视图一致：播放一次，播放前显示第一帧。
    [pagView setRepeatCount:1];
    switch (contentMode) {
        case UIViewContentModeScaleToFill: [pagView setScaleMode:PAGScaleModeStretch]; break;
        case UIViewContentModeScaleAspectFill: [pagView setScaleMode:PAGScaleModeZoom]; break;
        default: [pagView setScaleMode:PAGScaleModeLetterBox]; break;
    }
    [pagView setProgress:0];
    [pagView flush];
    return pagView;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return [view isKindOfClass:[PAGView class]] ? [[CYLPAGTabBarItemAnimationPlayer alloc] initWithAnimationView:view] : nil;
}

@end

#endif
