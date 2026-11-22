//
//  CYLPAGTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The composition root of the PAG subspecs: its `+load` registers the animator before any tab is built, and Swift has no `+load`. The player and the view loading are Swift (CYLPAGTabBarItemAnimation.swift). [CN] PAG 子库的组合根：其 `+load` 在创建任何 Tab 之前注册 animator，而 Swift 没有 `+load`。播放器与视图加载为 Swift（CYLPAGTabBarItemAnimation.swift）。

#import "CYLPAGTabBarItemAnimator.h"
// [EN] The generic keys, from CYLUtils: no Core. [CN] 通用 key，来自 CYLUtils：不依赖 Core。
#if __has_include("../../CYLUtils/CYLAnimationKeys.h")
#import "../../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif

// FIX: issue #604 — only with libpag (`CYL_PAG_AVAILABLE`, the PAG subspec); without it this file is empty: no keys,
// no class.
// [CN] 仅在引入 libpag 时编译（`CYL_PAG_AVAILABLE`，PAG 子库）；未引入时本文件为空：没有 key，也没有类。
#if CYL_PAG_AVAILABLE
#import <libpag/PAGView.h>

// [EN] The PAG keys are declared and defined in the component's core (CYLAnimationKeys), so they exist without libpag.
// [CN] PAG 的 key 在组件核心（CYLAnimationKeys）中声明与定义，没有 libpag 时也存在。

// The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif

#if CYL_PAG_OBJC_PLAYER
// CYL-SWIFT-MIGRATION: objc-required — [EN] The `CYLAnimatedItem/PAGEnterprise` subspec only: Swift cannot `import libpag` from
//      libpag-enterprise, whose umbrella header includes the missing `libpag/PAGView+Audio.h` (the reason that subspec also
//      builds with `-fno-modules`; pod lib lint failed on it in run 44975115535). So there the player and the view loading stay
//      Objective-C, with the same class names and methods as CYLPAGTabBarItemAnimation.swift, which the `PAG` subspec uses.
// [CN] 仅用于 `CYLAnimatedItem/PAGEnterprise` 子库：Swift 无法从 libpag-enterprise `import libpag`，其 umbrella 头文件引用了不存在的
//      `libpag/PAGView+Audio.h`（该子库同样因此使用 `-fno-modules`；pod lib lint 在运行 44975115535 中因此失败）。因此该子库的播放器与视图
//      加载保留 Objective-C，类名与方法与 `PAG` 子库使用的 CYLPAGTabBarItemAnimation.swift 相同。
/// [EN] Plays a `PAGView`. [CN] 播放 `PAGView`。
@interface CYLPAGTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer, PAGViewListener>
@end

@implementation CYLPAGTabBarItemAnimationPlayer {
    /// [EN] Added to the view on the first `-play`, the only moment an end can follow. [CN] 在第一次 `-play` 时加到视图上，结束只可能出现在此之后。
    BOOL _listening;
}

- (PAGView *)pagView {
    return (PAGView *)self.animationView;
}

- (BOOL)isPlaying {
    return [self.pagView isPlaying];
}

/// [EN] PAG reports the end of the animation after its repeat count (never with `loops` on). [CN] PAG 在重复次数用完后报告动画结束（`loops` 开启时从不）。
- (void)onAnimationEnd:(PAGView *)pagView {
    [self notifyPlaybackEnded];
}

- (void)play {
    PAGView *pagView = self.pagView;
    if (!_listening && pagView) {
        _listening = YES;
        [pagView addListener:self];
    }
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

- (BOOL)loops {
    return [self.pagView repeatCount] == 0;
}

/// [EN] PAG repeats forever with a repeat count of 0; 1 plays once. [CN] PAG 的重复次数为 0 时无限循环；1 表示播放一次。
- (void)setLoops:(BOOL)loops {
    [self.pagView setRepeatCount:loops ? 0 : 1];
}

@end

/// [EN] Makes the `PAGView` of a tab and its player (PAGEnterprise). [CN] 创建 Tab 的 `PAGView` 及其播放器（PAGEnterprise）。
@interface CYLPAGTabBarItemAnimationViews : NSObject
+ (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode;
+ (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view;
@end

@implementation CYLPAGTabBarItemAnimationViews

+ (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    // Loaded as the official samples (libpag/pag-ios) do: `-setComposition:` with `+[PAGFile Load:]`, which every
    // libpag version has (3.x and later).
    // 与官方示例（libpag/pag-ios）一致：用 `+[PAGFile Load:]` 加 `-setComposition:` 加载，各版本均支持。
    BOOL remote = !URL.isFileURL && URL.scheme.length > 0;
    PAGFile *pagFile = (!remote && URL.path.length > 0) ? [PAGFile Load:URL.path] : nil;
    if (!pagFile && !remote) {
        return nil;
    }
    PAGView *pagView = [[PAGView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    // [EN] Rendered on the main thread, everywhere: a tab bar has several small PAGViews. With one render thread each, those
    //      threads stalled inside the simulator's software OpenGL while holding their player's lock, and the first call that
    //      needed it (`-stop`, `-setHidden:`) blocked the main thread: blank icons, no playback. One path on every target also
    //      means that what the simulator shows is what a device runs.
    // [CN] 所有环境都在主线程绘制：TabBar 中有多个很小的 PAGView。每个一个绘制线程时，这些线程会在模拟器的软件 OpenGL 内部卡住并持有播放器的锁，
    //      之后第一个需要该锁的调用（`-stop`、`-setHidden:`）会阻塞主线程：图标空白，不播放。所有环境走同一条路径，模拟器上看到的就是真机运行的。
    [pagView setSync:YES];
    if (pagFile) {
        [pagView setComposition:pagFile];
    } else {
        // [EN] A remote file (http, https): downloaded first, then loaded; meanwhile the item keeps its static image (or the
        //      placeholder), and a failed download or file goes back to it (`CYLTabBarItemAnimationReportFailure`).
        // [CN] 远程文件（http、https）：先下载再加载；期间条目保留静态图片（或占位图），下载或文件失败时回到静态图片
        //      （`CYLTabBarItemAnimationReportFailure`）。
        [self cyl_loadRemoteURL:URL intoView:pagView];
    }
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

/*!
 * [EN] Downloads `URL` through the shared URL session into the caches folder, then gives it to `pagView` on the main
 *      thread. The view is marked loading until then.
 * [CN] 通过共享的 URL session 把 `URL` 下载到缓存目录，然后在主线程交给 `pagView`。在此之前视图被标记为加载中。
 */
+ (void)cyl_loadRemoteURL:(NSURL *)URL intoView:(PAGView *)pagView {
    CYLTabBarItemAnimationMarkLoading(pagView);
    __weak PAGView *weakView = pagView;
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:URL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 200;
        NSString *path = nil;
        if (location && status < 400) {
            NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
            NSString *name = [NSString stringWithFormat:@"cyl-pag-%lu.pag", (unsigned long)URL.absoluteString.hash];
            path = [caches stringByAppendingPathComponent:name];
            [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
            if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:NULL]) {
                path = nil;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            PAGView *view = weakView;
            if (!view) {
                return;
            }
            PAGFile *file = path ? [PAGFile Load:path] : nil;
            if (!file) {
                CYLTabBarItemAnimationReportFailure(view, error);
                return;
            }
            [view setComposition:file];
            [view setProgress:0];
            [view flush];
            CYLTabBarItemAnimationReportLoaded(view);
        });
    }];
    [task resume];
}

+ (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return [view isKindOfClass:[PAGView class]] ? [[CYLPAGTabBarItemAnimationPlayer alloc] initWithAnimationView:view] : nil;
}

@end
#else
// [EN] The Swift player and view loading of this subspec, through the module's generated header (framework or static library).
// [CN] 本子库的 Swift 播放器与视图加载，通过模块生成的头文件引入（framework 或静态库）。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#else
#import "CYLAnimatedItem-Swift.h"
#endif
#endif

@implementation CYLPAGTabBarItemAnimator

+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[self alloc] init]];
}

- (NSString *)identifier {
    return @"PAG";
}

- (NSArray<NSString *> *)fileExtensions {
    return @[ @"pag" ];
}

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
    return [CYLPAGTabBarItemAnimationViews animationViewWithURL:URL size:size contentMode:contentMode];
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return [CYLPAGTabBarItemAnimationViews playerForAnimationView:view];
}

@end

#endif
