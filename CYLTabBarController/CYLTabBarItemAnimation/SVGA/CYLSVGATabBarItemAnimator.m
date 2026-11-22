//
//  CYLSVGATabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// TODO (Swift migration, still counted by scripts/swift-migration-score.py): [EN] The SVGA view subclasses `SVGAPlayer`, which has a `-stopAnimation` method; the playable view protocol's Swift name for `-cyl_stopAnimationView` is also `stopAnimation()`, and a Swift class cannot have both (tried 2026-11-22: "Objective-C method 'stopAnimation' ... does not match the requirement's selector"). Renaming the protocol's Swift name would change a public API; a Swift view that holds an `SVGAPlayer` instead of being one is the way out (docs/Swift-Migration.md, engine steps 4–5). The `+load` registration is required Objective-C anyway. [CN] SVGA 视图继承 `SVGAPlayer`，后者有 `-stopAnimation` 方法；可播放视图协议中 `-cyl_stopAnimationView` 的 Swift 名称也是 `stopAnimation()`，Swift 类无法同时拥有二者。修改协议的 Swift 名称会改变公开 API；改为持有 `SVGAPlayer` 的 Swift 视图才是出路。`+load` 注册本身也必须是 Objective-C。

#import "CYLSVGATabBarItemAnimator.h"
// [EN] The registry and the playable view protocol of the `CYLTabBarItemAnimation` subspec.
// [CN] `CYLTabBarItemAnimation` 子库的注册表与可播放视图协议。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationPlayableView.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationPlayableView.h"
#import "CYLTabBarItemAnimationFactory.h"
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
@interface CYLSVGATabBarItemAnimationView : SVGAPlayer <CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding, SVGAPlayerDelegate>
@property (nonatomic, assign) CYLSVGATabBarItemAnimationState cyl_requestedState;
/// [EN] The frame shown now (SVGAPlayer keeps its own private). [CN] 当前显示的帧（SVGAPlayer 自己的是私有的）。
@property (nonatomic, assign) NSInteger cyl_frame;
/// [EN] Plays again after each pass (`loops = 0`). [CN] 每遍播放后再次播放（`loops = 0`）。
@property (nonatomic, assign) BOOL cyl_loops;
/// [EN] The playback rate; 1 plays with SVGAPlayer's own timer. [CN] 播放速率；为 1 时用 SVGAPlayer 自己的计时器。
@property (nonatomic, assign) CGFloat cyl_speed;
/// [EN] Steps the frames itself when the rate is not 1: SVGAPlayer's display link has a fixed, private frame interval.
/// [CN] 速率不为 1 时自己逐帧推进：SVGAPlayer 的 display link 帧间隔固定且为私有。
@property (nonatomic, strong, nullable) CADisplayLink *cyl_speedLink;
@property (nonatomic, assign) CFTimeInterval cyl_speedStartTime;
@property (nonatomic, assign) NSInteger cyl_speedStartFrame;
@end

@implementation CYLSVGATabBarItemAnimationView

+ (nullable UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                             options:(NSDictionary<NSString *, NSString *> *)options
                                                                         contentMode:(UIViewContentMode)contentMode {
    CYLSVGATabBarItemAnimationView *view = [[self alloc] initWithFrame:CGRectZero];
    view.loops = 1;
    view.cyl_speed = 1;
    view.delegate = view;
    view.clearsAfterStop = NO;
    view.fillMode = @"Forward";
    view.contentMode = contentMode;
    view.userInteractionEnabled = NO;
    view.isAccessibilityElement = NO;
    __weak CYLSVGATabBarItemAnimationView *weakView = view;
    void (^completion)(SVGAVideoEntity *) = ^(SVGAVideoEntity *videoItem) {
        [weakView cyl_showVideoItem:videoItem];
        CYLTabBarItemAnimationReportLoaded(weakView);
    };
    void (^failure)(NSError *) = ^(NSError *error) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴 CYLTabBarController SVGA: %@ could not be parsed: %@", fileURL, error.localizedDescription);
#endif
        // [EN] A corrupted file or a failed download: the host shows its image or placeholder. [CN] 文件损坏或下载失败：宿主显示其图片或占位图。
        CYLTabBarItemAnimationReportFailure(weakView, error);
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
        // [EN] A download: the host shows its static image, or its placeholder, until the file is parsed.
        // [CN] 下载中：在文件解析完成之前，宿主显示其静态图片或占位图。
        CYLTabBarItemAnimationMarkLoading(view);
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
    [self cyl_stopSpeedLink];
    self.cyl_frame = 0;
    if (self.cyl_speed != 1 && self.videoItem.FPS > 0) {
        [self stepToFrame:0 andPlay:NO];
        [self cyl_startSpeedLink];
    } else {
        [self stepToFrame:0 andPlay:YES];
    }
    [self cyl_keepTintOverlayAboveDrawing];
}

- (void)cyl_showAnimationViewLastFrame {
    self.cyl_requestedState = CYLSVGATabBarItemAnimationStateLastFrame;
    [self cyl_stopSpeedLink];
    if (self.videoItem.frames <= 0) {
        return;
    }
    self.cyl_frame = self.videoItem.frames - 1;
    [self stepToFrame:self.videoItem.frames - 1 andPlay:NO];
    [self cyl_keepTintOverlayAboveDrawing];
}

- (void)cyl_stopAnimationView {
    self.cyl_requestedState = CYLSVGATabBarItemAnimationStateFirstFrame;
    [self cyl_stopSpeedLink];
    if (!self.videoItem) {
        return;
    }
    self.cyl_frame = 0;
    [self stepToFrame:0 andPlay:NO];
    [self cyl_keepTintOverlayAboveDrawing];
}

#pragma mark - Loop, seek and speed

- (void)cyl_setAnimationViewLoops:(BOOL)loops {
    self.cyl_loops = loops;
    // [EN] SVGAPlayer: 0 repeats until stopped. [CN] SVGAPlayer：0 表示一直重复直到停止。
    self.loops = loops ? 0 : 1;
}

- (CGFloat)cyl_animationViewProgress {
    NSInteger frames = self.videoItem.frames;
    return frames > 1 ? (CGFloat)self.cyl_frame / (CGFloat)(frames - 1) : 0;
}

- (void)cyl_setAnimationViewProgress:(CGFloat)progress {
    NSInteger frames = self.videoItem.frames;
    if (frames <= 0) {
        return;
    }
    [self cyl_stopSpeedLink];
    NSInteger frame = (NSInteger)lround(MIN(MAX(progress, 0), 1) * (frames - 1));
    self.cyl_frame = frame;
    [self stepToFrame:frame andPlay:NO];
    [self cyl_keepTintOverlayAboveDrawing];
}

- (void)cyl_setAnimationViewSpeed:(CGFloat)speed {
    if (!(speed > 0) || !isfinite(speed) || speed == self.cyl_speed) {
        return;
    }
    self.cyl_speed = speed;
    BOOL playing = self.cyl_speedLink != nil || self.cyl_requestedState == CYLSVGATabBarItemAnimationStatePlaying;
    if (!playing || !self.videoItem || self.videoItem.FPS <= 0) {
        return;
    }
    // [EN] Live: continue from the frame shown now at the new rate. [CN] 实时生效：从当前帧以新速率继续。
    NSInteger frame = self.cyl_frame;
    [self cyl_stopSpeedLink];
    if (speed == 1) {
        [self stepToFrame:frame andPlay:YES];
    } else {
        [self pauseAnimation];
        self.cyl_speedStartFrame = frame;
        [self cyl_startSpeedLinkFromFrame:frame];
    }
}

- (void)cyl_startSpeedLink {
    [self cyl_startSpeedLinkFromFrame:0];
}

- (void)cyl_startSpeedLinkFromFrame:(NSInteger)frame {
    self.cyl_speedStartFrame = frame;
    self.cyl_speedStartTime = CACurrentMediaTime();
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(cyl_speedTick:)];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.cyl_speedLink = link;
}

- (void)cyl_stopSpeedLink {
    [self.cyl_speedLink invalidate];
    self.cyl_speedLink = nil;
}

- (void)cyl_speedTick:(CADisplayLink *)link {
    NSInteger frames = self.videoItem.frames;
    if (frames <= 0 || self.videoItem.FPS <= 0) {
        [self cyl_stopSpeedLink];
        return;
    }
    CFTimeInterval elapsed = CACurrentMediaTime() - self.cyl_speedStartTime;
    NSInteger frame = self.cyl_speedStartFrame + (NSInteger)floor(elapsed * self.videoItem.FPS * self.cyl_speed);
    if (frame >= frames) {
        if (!self.cyl_loops) {
            // [EN] One pass: rest on the last frame, as fillMode "Forward". [CN] 播放一遍：停在最后一帧，与 fillMode "Forward" 相同。
            [self cyl_stopSpeedLink];
            self.cyl_frame = frames - 1;
            [self stepToFrame:frames - 1 andPlay:NO];
            [self cyl_keepTintOverlayAboveDrawing];
            return;
        }
        frame %= frames;
    }
    if (frame != self.cyl_frame) {
        self.cyl_frame = frame;
        [self stepToFrame:frame andPlay:NO];
        [self cyl_keepTintOverlayAboveDrawing];
    }
}

- (void)removeFromSuperview {
    [self cyl_stopSpeedLink];
    [super removeFromSuperview];
}

#pragma mark - SVGAPlayerDelegate

- (void)svgaPlayer:(SVGAPlayer *)player didAnimatedToFrame:(NSInteger)frame {
    self.cyl_frame = frame;
}

/*!
 * [EN] SVGAPlayer adds its drawing layer on top of its own layer each time it draws, which hid the `tint` overlay the engine
 *      puts over the view (a layer composited "sourceAtop"): it goes back right above the drawing layer, sized to the view,
 *      and nothing else moves (a badge keeps its place).
 * [CN] SVGAPlayer 每次绘制都会把其绘制图层加到自身图层的最上方，遮住引擎放在视图上的 `tint` 叠加视图（以 "sourceAtop" 合成的图层）：把它放回绘制图层的正上方并与视图同尺寸，
 *      其他内容位置不变（角标保持原位）。
 */
- (void)cyl_keepTintOverlayAboveDrawing {
    CALayer *drawLayer = [self respondsToSelector:NSSelectorFromString(@"drawLayer")] ? [self valueForKey:@"drawLayer"] : nil;
    if (!drawLayer || drawLayer.superlayer != self.layer) {
        return;
    }
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer.name isEqualToString:@"CYLTabBarItemAnimationTintOverlay"]) {
            layer.frame = self.bounds;
            [self.layer insertSublayer:layer above:drawLayer];
            return;
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self cyl_keepTintOverlayAboveDrawing];
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
