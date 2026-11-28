//
//  CYLLottieTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The composition root of the Lottie subspecs: its `+load` registers the animator before any tab is built, and Swift has no `+load`. The lottie-ios 4.x player is Swift (LottieSwift/CYLLottieSwiftTabBarItemAnimationPlayer.swift); the lottie-ios 2.x player stays here because a Swift import of lottie-ios 2.x leaks a `Lottie` module dependency to every client (see below). [CN] Lottie 子库的组合根：其 `+load` 在创建任何 Tab 之前注册 animator，而 Swift 没有 `+load`。lottie-ios 4.x 播放器为 Swift；lottie-ios 2.x 播放器保留在这里，因为 Swift 导入 lottie-ios 2.x 会把 `Lottie` 模块依赖泄露给所有使用方（见下文）。

#import "CYLLottieTabBarItemAnimator.h"
// The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
// [EN] The keys (`CYLTabBarLottie…`, `CYLTabBarAnimation…`), from CYLUtils: no Core. [CN] key（`CYLTabBarLottie…`、`CYLTabBarAnimation…`），来自 CYLUtils：不依赖 Core。
#if __has_include("../../CYLUtils/CYLAnimationKeys.h")
#import "../../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif
// Shared through CYLUtils (the source tree, or flattened by CocoaPods). 通过 CYLUtils 共用（源码目录，或 CocoaPods 展平后）。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemMacros.h>)
#import <CYLAnimatedItem/CYLAnimatedItemMacros.h>
#elif __has_include("../../CYLAnimatedItem/CYLAnimatedItemMacros.h")
#import "../../CYLAnimatedItem/CYLAnimatedItemMacros.h"
#else
#import "CYLAnimatedItemMacros.h"
#endif

// FIX: issue #604 — only with a Lottie library; without one this file is empty and the class is never used.
// 仅在引入 Lottie 库时编译；未引入时本文件为空，也不会使用该类。
#if CYL_LOTTIE_AVAILABLE

// [EN] FIX: issue #605 — first: the generated header below also declares the Swift views of the Rive subspec when both are in the
//      build (e.g. Rive with FlatDesign, which brings Lottie), and those views adopt this header's protocols.
// [CN] FIX: issue #605 — 需先引入：两者同时在构建中时（例如 Rive 与会引入 Lottie 的扁平样式），下面生成的头文件也声明了 Rive 子库的 Swift 视图，这些视图遵守本头文件的协议。
#if __has_include("../CYLTabBarItemAnimationPlayableView.h")
#import "../CYLTabBarItemAnimationPlayableView.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimationPlayableView.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#elif __has_include("CYLAnimatedItem-Swift.h")
#import "CYLAnimatedItem-Swift.h"
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#endif

#if defined(SWIFT_PACKAGE)
// [EN] Swift Package Manager: the Swift modules this file uses through their Objective-C interface. [CN] Swift Package Manager：本文件通过其 Objective-C 接口使用的 Swift 模块。
#pragma clang module import CYLAnimatedItemSwift
#pragma clang module import CYLTabBarControllerLottieSwift
#endif

#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
#endif

#pragma mark - Lottie 2.x (Objective-C)

// [EN] The lottie-ios 2.x player stays Objective-C: a Swift file that imports lottie-ios 2.x makes the CYLAnimatedItem Swift
//      module depend on the `Lottie` module (`internal import` does not drop it without library evolution, and
//      `@_implementationOnly` warns there), so a client without lottie-ios on its search paths fails with "unable to resolve
//      module dependency: 'Lottie'" (the `pod lib lint` app of the root spec, CI run 45008954758). Swift tried and reverted
//      2026-11-22 (docs/Swift-Migration.md, engine step 5 fix).
// [CN] lottie-ios 2.x 播放器保留为 Objective-C：导入 lottie-ios 2.x 的 Swift 文件会让 CYLAnimatedItem 的 Swift 模块依赖 `Lottie` 模块（未开启
//      library evolution 时 `internal import` 无法去掉该依赖，`@_implementationOnly` 会产生警告），搜索路径中没有 lottie-ios 的使用方会报错
//      "unable to resolve module dependency: 'Lottie'"（根 spec 的 `pod lib lint` App，CI run 45008954758）。2026-11-22 尝试 Swift 后回退
//      （docs/Swift-Migration.md 引擎第 5 步修复）。


#if __has_include(<Lottie/Lottie.h>)
/**
 * [EN] Whether `URL` is a remote file (http, https...), which this animator downloads itself.
 * [CN] `URL` 是否为远程文件（http、https 等），由本 animator 自行下载。
 */
static BOOL CYLLottieURLIsRemote(NSURL *URL) {
    return !URL.isFileURL && URL.scheme.length > 0;
}

/**
 * [EN] A remote Lottie file, as the GIF and PAG animators do: `view` is marked as loading, so the item keeps its static
 *      image (or the placeholder); the file is downloaded through the shared URL session (its HTTP cache applies) and
 *      handed to `load` on the main queue; then `CYLTabBarItemAnimationReportLoaded` or, when the download fails, the
 *      status is 400 or above, or `load` returns NO, `CYLTabBarItemAnimationReportFailure`.
 * [CN] 远程 Lottie 文件，与 GIF、PAG animator 相同：`view` 标记为加载中，item 保留静态图片（或占位图）；通过共享 URL session 下载
 *      （遵循其 HTTP 缓存），在主队列交给 `load`；随后调用 `CYLTabBarItemAnimationReportLoaded`，下载失败、状态码不小于 400 或 `load`
 *      返回 NO 时调用 `CYLTabBarItemAnimationReportFailure`。
 */
static void CYLLottieDownload(NSURL *URL, UIView *view, BOOL (^load)(UIView *view, NSData *data)) {
    CYLTabBarItemAnimationMarkLoading(view);
    __weak UIView *weakView = view;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 200;
        NSData *usable = (data.length > 0 && status < 400) ? data : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *strongView = weakView;
            if (!strongView) {
                return;
            }
            if (usable && load(strongView, usable)) {
                CYLTabBarItemAnimationReportLoaded(strongView);
            } else {
                CYLTabBarItemAnimationReportFailure(strongView, error);
            }
        });
    }];
    [task resume];
}
#endif

#if __has_include(<Lottie/Lottie.h>)
/// [EN] Plays a `LOTAnimationView` (lottie-ios 2.x). [CN] 播放 `LOTAnimationView`（lottie-ios 2.x）。
@interface CYLLottieObjectiveCTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLLottieObjectiveCTabBarItemAnimationPlayer

+ (BOOL)isLottieView:(UIView *)view {
    // [EN] Inside the `__has_include` guard Lottie is linked (this file already uses the class), so no string lookup.
    // [CN] 在 `__has_include` 守卫内 Lottie 已链接（本文件已直接使用该类），因此无需按字符串查找。
    return [view isKindOfClass:[LOTAnimationView class]];
}

+ (UIView *)viewWithURL:(NSURL *)URL {
    if (CYLLottieURLIsRemote(URL)) {
        // [EN] Downloaded here, not by lottie-ios 2.x's -initWithContentsOfURL:, which reports neither success nor failure.
        // [CN] 在这里下载，而不是使用 lottie-ios 2.x 的 -initWithContentsOfURL:，后者既不报告成功也不报告失败。
        LOTAnimationView *view = [[LOTAnimationView alloc] initWithFrame:CGRectZero];
        CYLLottieDownload(URL, view, ^BOOL(UIView *target, NSData *data) {
            id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            LOTComposition *composition = [JSON isKindOfClass:[NSDictionary class]]
                ? [LOTComposition animationFromJSON:JSON inBundle:nil] : nil;
            if (!composition) {
                return NO;
            }
            ((LOTAnimationView *)target).sceneModel = composition;
            return YES;
        });
        return view;
    }
    if (![LOTAnimationView instancesRespondToSelector:@selector(initWithContentsOfURL:)]) {
        return nil;
    }
    return [[LOTAnimationView alloc] initWithContentsOfURL:URL];
}

- (LOTAnimationView *)lottieView {
    return (LOTAnimationView *)self.animationView;
}

- (void)play {
    LOTAnimationView *lottieView = self.lottieView;
    dispatch_async(dispatch_get_main_queue(), ^{
        lottieView.animationProgress = 0;
        [self playWithEndNotification];
    });
}

/// [EN] Plays and tells `onEnded` when the pass runs to its end (`animationFinished` is NO after a stop or a restart). [CN] 播放，一遍播放到结尾时通知 `onEnded`（停止或重新播放后 `animationFinished` 为 NO）。
- (void)playWithEndNotification {
    __weak typeof(self) weakSelf = self;
    [self.lottieView playWithCompletion:^(BOOL animationFinished) {
        if (animationFinished) {
            [weakSelf notifyPlaybackEnded];
        }
    }];
}

- (BOOL)isPlaying {
    return self.lottieView.isAnimationPlaying;
}

- (void)showLastFrame {
    LOTAnimationView *lottieView = self.lottieView;
    dispatch_async(dispatch_get_main_queue(), ^{
        // [CN] 希望Lottie icon 启动后 index== 0 不执行动画 #389
        // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
        lottieView.animationProgress = 1;
        [lottieView forceDrawingUpdate];
    });
}

- (void)stop {
    // [CN] 通过 (animationProgress > 0) 判断，降低扁平风格 CYLFlatDesignTabBar 第一次初始化时展示失败的几率。
    // [EN] The (animationProgress > 0) check lowers the chance that the flat design CYLFlatDesignTabBar fails to show on its
    //      first initialization.
    LOTAnimationView *lottieView = self.lottieView;
    if (lottieView.animationProgress > 0) {
        [lottieView stop];
    }
}

- (CGFloat)progress {
    return self.lottieView.animationProgress;
}

- (void)setProgress:(CGFloat)progress {
    LOTAnimationView *lottieView = self.lottieView;
    lottieView.animationProgress = progress;
    [lottieView forceDrawingUpdate];
}

- (CGFloat)animationSpeed {
    return self.lottieView.animationSpeed;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
    self.lottieView.animationSpeed = animationSpeed;
}

- (BOOL)loops {
    return self.lottieView.loopAnimation;
}

- (void)setLoops:(BOOL)loops {
    LOTAnimationView *lottieView = self.lottieView;
    if (lottieView.loopAnimation == loops) {
        return;
    }
    lottieView.loopAnimation = loops;
    // [EN] Lottie 2.x reads it when a play starts: a playing view continues from where it is under the new mode.
    // [CN] Lottie 2.x 在开始播放时读取该值：正在播放的视图从当前位置按新模式继续播放。
    if (lottieView.isAnimationPlaying) {
        [self playWithEndNotification];
    }
}

@end
#endif

// [EN] The lottie-ios 4.x player is Swift (docs/Swift-Migration.md, engine step 5): CYLLottieSwiftTabBarItemAnimationPlayer
//      (LottieSwift/), compiled with lottie-ios 4.x and exported by the generated header imported above. This class stays
//      Objective-C as the composition root: its +load registers the animator, which Swift cannot do.
// [CN] lottie-ios 4.x 播放器为 Swift（docs/Swift-Migration.md 引擎第 5 步）：CYLLottieSwiftTabBarItemAnimationPlayer（LottieSwift/），随 lottie-ios 4.x
//      编译，由上面引入的生成头文件导出。本类作为组合根保留为 Objective-C：其 +load 注册 animator，这是 Swift 做不到的。

#pragma mark - The animator (the factory of the Swift players)

@implementation CYLLottieTabBarItemAnimator

/// [EN] Registers itself when it is linked (only with Lottie). [CN] 被链接时自行注册（仅在引入 Lottie 时）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[self alloc] init]];
}

- (NSString *)identifier {
    return @"Lottie";
}

/// [EN] Looked up last: Lottie takes every file no other animator takes, as before. [CN] 最后查找：其他 animator 都不处理的文件交给 Lottie，与原来一致。
- (CYLTabBarItemAnimatorPriority)priority {
    return CYLTabBarItemAnimatorPriorityFallback;
}

- (NSArray<NSString *> *)fileExtensions {
    return @[ @"json", @"lottie" ];
}

/// [EN] The Lottie keys, which stand for the generic `CYLTabBarAnimation…` keys. [CN] Lottie 的 key，对应通用的 `CYLTabBarAnimation…` key。
- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{
        CYLTabBarAnimationURL : CYLTabBarLottieURL,
        CYLTabBarAnimationFilePath : CYLTabBarLottieFilePath,
        CYLTabBarAnimationSize : CYLTabBarLottieSize,
        CYLTabBarAnimationDarkURL : CYLTabBarLottieDarkURL,
        CYLTabBarAnimationDarkFilePath : CYLTabBarLottieDarkFilePath,
        CYLTabBarAnimationDarkColors : CYLTabBarLottieDarkColors,
    };
}

/// [EN] Lottie 4 (LottieSwift) also plays `.lottie` archives; Lottie 2 does not. [CN] Lottie 4（LottieSwift）也能播放 `.lottie` 压缩包；Lottie 2 不能。
static BOOL CYLLottieAnimatorAcceptsDotLottie(void) {
#if __has_include(<Lottie/Lottie-Swift.h>)
    return YES;
#else
    return NO;
#endif
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    // [EN] Every file another animator does not take (they are looked up first), but only a Lottie animation: a picture or
    //      a broken file is left to the static image (CYLTabBarItemAnimationURLMayBeLottie).
    // [CN] 其他 animator 不处理的文件（它们先被查找），但只接收 Lottie 动画：图片或损坏的文件交给静态图片（CYLTabBarItemAnimationURLMayBeLottie）。
    return CYLTabBarItemAnimationURLMayBeLottie(URL, CYLLottieAnimatorAcceptsDotLottie());
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    // [EN] Also checked here: a tab's Lottie keys bind a URL to this animator without asking -canAnimateFileAtURL:. A file
    //      that does not load makes no view, so the caller keeps the static image instead of an empty Lottie view over it.
    // [CN] 这里也要检查：Tab 的 Lottie key 会把 URL 绑定到本 animator，而不调用 -canAnimateFileAtURL:。无法加载的文件不创建视图，调用方因此保留静态
    //      图片，而不是在其上方放一个空的 Lottie 视图。
    if (!CYLTabBarItemAnimationURLMayBeLottie(URL, CYLLottieAnimatorAcceptsDotLottie())) {
        return nil;
    }
    // The first Lottie library linked makes the view (each behind its own guard). 由先引入的 Lottie 库创建视图（各自使用独立的 guard）。
    UIView *lottieView = nil;
#if __has_include(<Lottie/Lottie.h>)
    lottieView = [CYLLottieObjectiveCTabBarItemAnimationPlayer viewWithURL:URL];
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    lottieView = lottieView ?: [CYLLottieSwiftTabBarItemAnimationPlayer viewWithURL:URL];
#endif
    return lottieView;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
#if __has_include(<Lottie/Lottie.h>)
    if ([CYLLottieObjectiveCTabBarItemAnimationPlayer isLottieView:view]) {
        return [[CYLLottieObjectiveCTabBarItemAnimationPlayer alloc] initWithAnimationView:view];
    }
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    if ([CYLLottieSwiftTabBarItemAnimationPlayer isLottieView:view]) {
        return [[CYLLottieSwiftTabBarItemAnimationPlayer alloc] initWithAnimationView:view];
    }
#endif
    return nil;
}

@end

#endif
