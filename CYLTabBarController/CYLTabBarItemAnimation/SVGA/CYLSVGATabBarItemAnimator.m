//
//  CYLSVGATabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLSVGATabBarItemAnimator.h"
// [EN] The registry and the playable view protocol of the `CYLTabBarItemAnimation` subspec.
// [CN] `CYLTabBarItemAnimation` 子库的注册表与可播放视图协议。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationPlayableView.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationPlayableView.h"
#endif

// [EN] FIX: issue #415 — only with SVGAPlayer (`CYL_SVGA_AVAILABLE`, the SVGA subspec); without it this file is empty.
// [CN] 仅在引入 SVGAPlayer 时编译（`CYL_SVGA_AVAILABLE`，SVGA 子库）；未引入时本文件为空。
#if CYL_SVGA_AVAILABLE
// [EN] SVGAPlayerLite (the SVGA subspec's maintained fork) first; the original SVGAPlayer pod works too.
// [CN] 优先使用 SVGAPlayerLite（SVGA 子库依赖的维护分支）；原版 SVGAPlayer pod 同样可用。
#if __has_include(<SVGAPlayerLite/SVGA.h>)
#import <SVGAPlayerLite/SVGA.h>
#elif __has_include(<SVGAPlayer/SVGA.h>)
#import <SVGAPlayer/SVGA.h>
#else
#import "SVGA.h"
#endif

NSString *const CYLTabBarSVGAURL = @"CYLTabBarSVGAURL";
NSString *const CYLTabBarSVGAFilePath = @"CYLTabBarSVGAFilePath";
NSString *const CYLTabBarSVGASize = @"CYLTabBarSVGASize";
NSString *const CYLTabBarSVGADarkURL = @"CYLTabBarSVGADarkURL";
NSString *const CYLTabBarSVGADarkFilePath = @"CYLTabBarSVGADarkFilePath";

/*!
 * [EN] What the view shows once its file is parsed (parsing is asynchronous): a request made before is kept and applied then.
 * [CN] 文件解析完成后视图显示的状态（解析是异步的）：在此之前的请求会被保留，解析完成后再执行。
 */
typedef NS_ENUM(NSInteger, CYLSVGATabBarItemAnimationState) {
    CYLSVGATabBarItemAnimationStateFirstFrame = 0,
    CYLSVGATabBarItemAnimationStatePlaying,
    CYLSVGATabBarItemAnimationStateLastFrame,
};

/*!
 * [EN] An SVGA file in a tab: an `SVGAPlayer` that plays once and keeps its last frame (`fillMode` "Forward"), or shows its
 *      first frame. The parsed video is cached by the parser's memory cache, keyed by the file URL.
 * [CN] Tab 中的 SVGA 文件：一个 `SVGAPlayer`，播放一次并保持最后一帧（`fillMode` 为 "Forward"），或显示第一帧。解析后的视频由解析器的内存缓存
 *      按文件 URL 缓存。
 */
@interface CYLSVGATabBarItemAnimationView : SVGAPlayer <CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding>
@property (nonatomic, assign) CYLSVGATabBarItemAnimationState cyl_requestedState;
@end

@implementation CYLSVGATabBarItemAnimationView

+ (nullable UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                             options:(NSDictionary<NSString *, NSString *> *)options
                                                                         contentMode:(UIViewContentMode)contentMode {
    CYLSVGATabBarItemAnimationView *view = [[self alloc] initWithFrame:CGRectZero];
    view.loops = 1;
    view.clearsAfterStop = NO;
    view.fillMode = @"Forward";
    view.contentMode = contentMode;
    view.userInteractionEnabled = NO;
    view.isAccessibilityElement = NO;
    __weak CYLSVGATabBarItemAnimationView *weakView = view;
    void (^completion)(SVGAVideoEntity *) = ^(SVGAVideoEntity *videoItem) {
        [weakView cyl_showVideoItem:videoItem];
    };
    void (^failure)(NSError *) = ^(NSError *error) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴 CYLTabBarController SVGA: %@ could not be parsed: %@", fileURL, error.localizedDescription);
#endif
    };
    SVGAParser *parser = [[SVGAParser alloc] init];
    parser.enabledMemoryCache = YES;
    if (fileURL.isFileURL) {
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if (data.length == 0) {
            return nil;
        }
        [parser parseWithData:data cacheKey:fileURL.absoluteString completionBlock:completion failureBlock:failure];
    } else {
        [parser parseWithURL:fileURL completionBlock:completion failureBlock:failure];
    }
    return view;
}

/// [EN] Shows a parsed video in the state asked for so far. [CN] 以目前请求的状态显示解析完成的视频。
- (void)cyl_showVideoItem:(SVGAVideoEntity *)videoItem {
    self.videoItem = videoItem;
    switch (self.cyl_requestedState) {
        case CYLSVGATabBarItemAnimationStatePlaying:
            [self cyl_playAnimationView];
            break;
        case CYLSVGATabBarItemAnimationStateLastFrame:
            [self cyl_showAnimationViewLastFrame];
            break;
        case CYLSVGATabBarItemAnimationStateFirstFrame:
            [self cyl_stopAnimationView];
            break;
    }
}

- (void)cyl_playAnimationView {
    self.cyl_requestedState = CYLSVGATabBarItemAnimationStatePlaying;
    if (!self.videoItem) {
        return;
    }
    [self stepToFrame:0 andPlay:YES];
}

- (void)cyl_showAnimationViewLastFrame {
    self.cyl_requestedState = CYLSVGATabBarItemAnimationStateLastFrame;
    if (self.videoItem.frames <= 0) {
        return;
    }
    [self stepToFrame:self.videoItem.frames - 1 andPlay:NO];
}

- (void)cyl_stopAnimationView {
    self.cyl_requestedState = CYLSVGATabBarItemAnimationStateFirstFrame;
    if (!self.videoItem) {
        return;
    }
    [self stepToFrame:0 andPlay:NO];
}

@end

@implementation CYLSVGATabBarItemAnimator

+ (CYLTabBarItemViewAnimator *)animator {
    static CYLTabBarItemViewAnimator *animator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animator = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"SVGA"
                                                          fileExtensions:@[ @"svga" ]
                                                           attributeKeys:@{
            CYLTabBarAnimationURL : CYLTabBarSVGAURL,
            CYLTabBarAnimationFilePath : CYLTabBarSVGAFilePath,
            CYLTabBarAnimationSize : CYLTabBarSVGASize,
            CYLTabBarAnimationDarkURL : CYLTabBarSVGADarkURL,
            CYLTabBarAnimationDarkFilePath : CYLTabBarSVGADarkFilePath,
        }
                                                            viewProvider:[CYLSVGATabBarItemAnimationView class]];
    });
    return animator;
}

/// [EN] Registers SVGA's animator (this file only compiles with SVGAPlayer). [CN] 注册 SVGA 的 animator（本文件只在有 SVGAPlayer 时编译）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:self.animator];
}

@end

#endif
