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
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationPlayableView.h"
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

+ (nullable UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                             options:(NSDictionary<NSString *, NSString *> *)options
                                                                         contentMode:(UIViewContentMode)contentMode {
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
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
    CFRelease(source);
    if (frames.count == 0) {
        return nil;
    }
    CYLGIFTabBarItemAnimationView *view = [[self alloc] initWithImage:frames.firstObject];
    view.frames = frames;
    view.frameDelays = frameDelays;
    view.contentMode = contentMode;
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
