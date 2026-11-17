//
//  CYLGIFTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLGIFTabBarItemAnimator.h"
// [EN] The registry and the view protocols of the `CYLTabBarItemAnimation` subspec. [CN] `CYLTabBarItemAnimation` 子库的注册表与视图协议。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationPlayableView.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationPlayableView.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif
// [EN] `CYLTabBarAnimationURL` and the other generic keys, from CYLUtils: no Core, so the subspec works without the tab bar.
// [CN] `CYLTabBarAnimationURL` 等通用 key，来自 CYLUtils：不依赖 Core，因此本子库无需 TabBar 也能使用。
#if __has_include("../../CYLUtils/CYLAnimationKeys.h")
#import "../../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif

#if CYL_GIF_AVAILABLE
#import <ImageIO/ImageIO.h>

/*
 * [EN] The delay of one GIF frame (0.1 s for a delay under 11 ms, as browsers do): the same rule as Core's
 *      `+[UIImage cyl_GIFFrameDelayWithProperties:]`, here so that this subspec does not need Core.
 * [CN] 一帧 GIF 的延迟（小于 11 毫秒时为 0.1 秒，与浏览器一致）：与 Core 的 `+[UIImage cyl_GIFFrameDelayWithProperties:]` 规则相同，放在这里
 *      使本子库不依赖 Core。
 */
static NSTimeInterval CYLGIFFrameDelay(NSDictionary *properties) {
    NSDictionary *gif = properties[(__bridge NSString *)kCGImagePropertyGIFDictionary];
    NSTimeInterval delay = [gif[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime] doubleValue];
    if (delay <= 0) {
        delay = [gif[(__bridge NSString *)kCGImagePropertyGIFDelayTime] doubleValue];
    }
    return delay < 0.011 ? 0.1 : delay;
}


static NSString *const CYLGIFPlayAnimationKey = @"CYLGIFTabBarItemPlayAnimation";

/*!
 * [EN] A GIF that plays by itself. The frames play through a keyframe animation of the layer's contents, so each keeps its own
 *      delay; `UIImageView.animationImages` gives every frame the same one. The image view already holds the end state while
 *      the animation runs, so nothing changes when the animation ends or the system removes it (e.g. in the background).
 * [CN] 自己会播放的 GIF。各帧通过 layer contents 的关键帧动画播放，因此保留各自的时长；`UIImageView.animationImages` 会让每一帧时长相同。动画运行期间
 *      图片视图已经持有结束状态，因此动画结束或被系统移除时（例如进入后台）画面不会变化。
 */
@interface CYLGIFTabBarItemAnimationView : UIImageView <CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding>
@property (nonatomic, copy) NSArray<UIImage *> *frames;
@property (nonatomic, copy) NSArray<NSNumber *> *frameDelays;
@end

@implementation CYLGIFTabBarItemAnimationView

/*!
 * [EN] Decodes every frame of `source` into the view. NO when it has no frame (not a GIF, or a broken one).
 * [CN] 把 `source` 的每一帧解码到视图中。没有任何帧时（不是 GIF 或已损坏）返回 NO。
 */
- (BOOL)cyl_loadFramesFromSource:(CGImageSourceRef)source {
    size_t count = source ? CGImageSourceGetCount(source) : 0;
    NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray<NSNumber *> *frameDelays = [NSMutableArray arrayWithCapacity:count];
    for (size_t index = 0; index < count; index++) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, index, NULL);
        if (!imageRef) {
            continue;
        }
        [frames addObject:[UIImage imageWithCGImage:imageRef]];
        CGImageRelease(imageRef);
        NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
        [frameDelays addObject:@(CYLGIFFrameDelay(properties))];
    }
    if (frames.count == 0) {
        return NO;
    }
    self.frames = frames;
    self.frameDelays = frameDelays;
    self.image = frames.firstObject;
    return YES;
}

+ (nullable UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                             options:(NSDictionary<NSString *, NSString *> *)options
                                                                         contentMode:(UIViewContentMode)contentMode {
    if (!fileURL.isFileURL && fileURL.scheme.length > 0) {
        return [self cyl_animationViewDownloadingURL:fileURL contentMode:contentMode];
    }
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
    if (!source) {
        return nil;
    }
    CYLGIFTabBarItemAnimationView *view = [[self alloc] initWithImage:nil];
    BOOL loaded = [view cyl_loadFramesFromSource:source];
    CFRelease(source);
    if (!loaded) {
        return nil;
    }
    view.contentMode = contentMode;
    return view;
}

/*!
 * [EN] A remote GIF (http, https): an empty view, marked as loading so that the item keeps its static image (or the
 *      placeholder), filled once the file is downloaded (`CYLTabBarItemAnimationReportLoaded`), or reported as failed
 *      when the download or the decoding fails (`CYLTabBarItemAnimationReportFailure`), which shows the static image again.
 *      The download goes through the shared URL session, so its HTTP cache applies.
 * [CN] 远程 GIF（http、https）：先返回空视图并标记为加载中，使条目继续显示静态图片（或占位图）；下载完成后填充帧
 *      （`CYLTabBarItemAnimationReportLoaded`）；下载或解码失败时报告失败（`CYLTabBarItemAnimationReportFailure`），重新显示静态图片。
 *      下载使用共享的 URL session，因此遵循其 HTTP 缓存。
 */
+ (UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewDownloadingURL:(NSURL *)URL contentMode:(UIViewContentMode)contentMode {
    CYLGIFTabBarItemAnimationView *view = [[self alloc] initWithImage:nil];
    view.contentMode = contentMode;
    CYLTabBarItemAnimationMarkLoading(view);
    __weak CYLGIFTabBarItemAnimationView *weakView = view;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 200;
        CGImageSourceRef source = (data.length > 0 && status < 400) ? CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL) : NULL;
        dispatch_async(dispatch_get_main_queue(), ^{
            CYLGIFTabBarItemAnimationView *strongView = weakView;
            BOOL loaded = strongView && source && [strongView cyl_loadFramesFromSource:source];
            if (source) {
                CFRelease(source);
            }
            if (!strongView) {
                return;
            }
            if (loaded) {
                CYLTabBarItemAnimationReportLoaded(strongView);
            } else {
                CYLTabBarItemAnimationReportFailure(strongView, error);
            }
        });
    }];
    [task resume];
    return view;
}

- (void)cyl_playAnimationView {
    [self.layer removeAnimationForKey:CYLGIFPlayAnimationKey];
    self.image = self.frames.lastObject;
    if (self.frames.count < 2) {
        return;
    }
    double duration = [[self.frameDelays valueForKeyPath:@"@sum.self"] doubleValue];
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:self.frames.count];
    NSMutableArray<NSNumber *> *keyTimes = [NSMutableArray arrayWithCapacity:self.frames.count + 1];
    double elapsed = 0;
    for (NSUInteger index = 0; index < self.frames.count; index++) {
        [contents addObject:(__bridge id)self.frames[index].CGImage];
        [keyTimes addObject:@(elapsed / duration)];
        elapsed += self.frameDelays[index].doubleValue;
    }
    // [EN] Discrete: one key time more than values, the last one 1. [CN] 离散模式：key time 比 values 多一个，最后一个为 1。
    [keyTimes addObject:@1];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animation.calculationMode = kCAAnimationDiscrete;
    animation.values = contents;
    animation.keyTimes = keyTimes;
    animation.duration = duration;
    [self.layer addAnimation:animation forKey:CYLGIFPlayAnimationKey];
}

- (void)cyl_showAnimationViewLastFrame {
    [self.layer removeAnimationForKey:CYLGIFPlayAnimationKey];
    self.image = self.frames.lastObject;
}

- (void)cyl_stopAnimationView {
    [self.layer removeAnimationForKey:CYLGIFPlayAnimationKey];
    self.image = self.frames.firstObject;
}

@end

@implementation CYLGIFTabBarItemAnimator

+ (CYLTabBarItemViewAnimator *)animator {
    static CYLTabBarItemViewAnimator *animator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animator = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"GIF"
                                                          fileExtensions:@[ @"gif" ]
                                                           attributeKeys:@{
            CYLTabBarAnimationURL : CYLTabBarGIFURL,
            CYLTabBarAnimationFilePath : CYLTabBarGIFFilePath,
            CYLTabBarAnimationSize : CYLTabBarGIFSize,
            CYLTabBarAnimationDarkURL : CYLTabBarGIFDarkURL,
            CYLTabBarAnimationDarkFilePath : CYLTabBarGIFDarkFilePath,
        }
                                                            viewProvider:[CYLGIFTabBarItemAnimationView class]];
    });
    return animator;
}

/// [EN] Registers the GIF animator, the composition root of this subspec. [CN] 注册 GIF 的 animator，这是本子库的组合根。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:self.animator];
}

@end

#endif
