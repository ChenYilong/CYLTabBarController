//
//  CYLTabButtonAnimation.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabButtonAnimation.h"

/// [EN] Duration of the TLAnimationTabBar animations. [CN] TLAnimationTabBar 动画的时长。
static const NSTimeInterval CYLTabButtonAnimationDuration = 0.5;

static NSString *const CYLTabButtonAnimationKeyPathScale = @"transform.scale";
static NSString *const CYLTabButtonAnimationKeyPathRotation = @"transform.rotation";
static NSString *const CYLTabButtonAnimationKeyPathContents = @"contents";
static NSString *const CYLTabButtonAnimationKeyPathPositionY = @"position.y";
static NSString *const CYLTabButtonAnimationKeyPathOpacity = @"opacity";

#pragma mark - Helpers

/// [EN] A cubic keyframe animation. [CN] 三次曲线插值的关键帧动画。
static CAKeyframeAnimation *CYLTabButtonKeyframeAnimation(NSString *keyPath, NSArray *values, NSTimeInterval duration) {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    animation.values = values;
    animation.duration = duration;
    animation.calculationMode = kCAAnimationCubic;
    return animation;
}

/// [EN] The CGImages of `images`, for a `contents` animation. [CN] `images` 对应的 CGImage，用于 `contents` 动画。
static NSArray *CYLTabButtonCGImages(NSArray<UIImage *> *images, BOOL reversed) {
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:images.count];
    NSEnumerator *enumerator = reversed ? images.reverseObjectEnumerator : images.objectEnumerator;
    for (UIImage *image in enumerator) {
        if (image.CGImage) {
            [frames addObject:(__bridge id)image.CGImage];
        }
    }
    return frames;
}

/// [EN] The held frames of `CYLTabButtonFrameAnimation`. [CN] `CYLTabButtonFrameAnimation` 保持的帧。
static NSString *const CYLTabButtonFrameAnimationKey = @"cyl.tabButton.frames";

static void CYLTabButtonPlayFrameAnimation(UIView *iconView, NSArray<UIImage *> *images, BOOL reversed) {
    NSArray *frames = CYLTabButtonCGImages(images, reversed);
    if (frames.count == 0) {
        return;
    }
    CAKeyframeAnimation *animation = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathContents, frames, CYLTabButtonAnimationDuration);
    animation.calculationMode = kCAAnimationDiscrete;
    animation.repeatCount = 1;
    // [EN] Selected: the last frame stays. Deselected (reversed): back to the icon itself at the end, not to the first frame.
    // [CN] 选中：保持最后一帧。取消选中（倒序）：结束后恢复为图标本身，而不是停在第一帧。
    animation.removedOnCompletion = reversed;
    animation.fillMode = reversed ? kCAFillModeRemoved : kCAFillModeForwards;
    [iconView.layer addAnimation:animation forKey:CYLTabButtonFrameAnimationKey];
}

/// [EN] A small dot drawn in `color`, the default firework particle. [CN] 用 `color` 绘制的小圆点，默认的烟花粒子。
static UIImage *CYLTabButtonDotImage(UIColor *color) {
    CGSize size = CGSizeMake(8, 8);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [color setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, size.width, size.height)] fill];
    }];
}

/*!
 * [EN] `image` drawn into a bitmap, for an emitter cell. The cell takes the CGImage, which has no tint: an SF Symbol or a
 *      template image would show black. A template image is drawn in `tintColor`, any other image as it looks.
 * [CN] 将 `image` 绘制为位图，供粒子使用。粒子使用 CGImage，其中不包含着色：SF Symbol 或模板图片会显示为黑色。
 *      模板图片按 `tintColor` 绘制，其他图片按原样绘制。
 */
static UIImage *CYLTabButtonParticleImage(UIImage *image, UIColor *tintColor) {
    if (image.size.width <= 0 || image.size.height <= 0) {
        return image;
    }
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        if (image.renderingMode == UIImageRenderingModeAlwaysTemplate) {
            [tintColor setFill];
            [image drawInRect:rect];
            CGContextSetBlendMode(context.CGContext, kCGBlendModeSourceIn);
            CGContextFillRect(context.CGContext, rect);
        } else {
            [image drawInRect:rect];
        }
    }];
}

static CAEmitterLayer *CYLTabButtonEmitterLayer(NSString *cellName, CGFloat lifetime, CGFloat lifetimeRange, CGFloat velocity,
                                                CGFloat velocityRange, UIImage *image, CGPoint center) {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.name = cellName;
    cell.alphaRange = 0.20;
    cell.alphaSpeed = -1.0;
    cell.lifetime = lifetime;
    cell.lifetimeRange = lifetimeRange;
    cell.birthRate = 0;
    cell.velocity = velocity;
    cell.velocityRange = velocityRange;
    cell.contents = (__bridge id)image.CGImage;
    cell.scale = 0.5;
    cell.scaleRange = 0.2;

    CAEmitterLayer *layer = [CAEmitterLayer layer];
    layer.name = @"cyl_emitterLayer";
    layer.emitterShape = kCAEmitterLayerCircle;
    layer.emitterMode = kCAEmitterLayerOutline;
    layer.emitterSize = CGSizeMake(25, 0);
    layer.emitterCells = @[ cell ];
    layer.renderMode = kCAEmitterLayerOldestFirst;
    layer.masksToBounds = NO;
    layer.emitterPosition = center;
    return layer;
}

/*!
 * [EN] Fireworks around `view`: particles gather, then burst (TLAnimationTabBar). The emitter layers are removed after.
 * [CN] `view` 周围的烟花：粒子先聚拢再炸开（TLAnimationTabBar），结束后移除粒子图层。
 */
static void CYLTabButtonPlayFireworks(UIView *view, UIImage *_Nullable image) {
    UIColor *tintColor = view.tintColor ?: [UIColor systemBlueColor];
    UIImage *particle = image ? CYLTabButtonParticleImage(image, tintColor) : CYLTabButtonDotImage(tintColor);
    if (!particle.CGImage) {
        return;
    }
    BOOL clipsToBounds = view.clipsToBounds;
    view.clipsToBounds = NO;
    CGPoint center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    CAEmitterLayer *explosionLayer = CYLTabButtonEmitterLayer(@"explosion", 0.7, 0.3, 40.0, 10.0, particle, center);
    CAEmitterLayer *chargeLayer = CYLTabButtonEmitterLayer(@"charge", 0.3, 0.1, -40.0, 0.0, particle, center);
    [view.layer addSublayer:explosionLayer];
    [view.layer addSublayer:chargeLayer];

    chargeLayer.beginTime = CACurrentMediaTime();
    [chargeLayer setValue:@100 forKeyPath:@"emitterCells.charge.birthRate"];
    __weak UIView *weakView = view;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CYLTabButtonAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [chargeLayer setValue:@0 forKeyPath:@"emitterCells.charge.birthRate"];
        [chargeLayer removeFromSuperlayer];
        explosionLayer.beginTime = CACurrentMediaTime();
        [explosionLayer setValue:@300 forKeyPath:@"emitterCells.explosion.birthRate"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [explosionLayer setValue:@0 forKeyPath:@"emitterCells.explosion.birthRate"];
            [explosionLayer removeFromSuperlayer];
            weakView.clipsToBounds = clipsToBounds;
        });
    });
}

#pragma mark - CYLTabButtonScaleAnimation

@implementation CYLTabButtonScaleAnimation

- (instancetype)init {
    if (self = [super init]) {
        _duration = CYLTabButtonAnimationDuration;
    }
    return self;
}

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    // [EN] Layer keyframes, so a transform the tab bar set on the icon is left alone.
    // [CN] 使用图层关键帧动画，不会覆盖 TabBar 设置在图标上的 transform。
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:CYLTabButtonAnimationKeyPathScale];
    animation.values = @[ @1.0, @1.5, @0.8, @1.0 ];
    animation.keyTimes = @[ @0.0, @(1.0 / 3.0), @(2.0 / 3.0), @1.0 ];
    animation.duration = self.duration;
    [iconView.layer addAnimation:animation forKey:@"cyl.tabButton.scale"];
}

@end

#pragma mark - CYLTabButtonZoomInAnimation

@implementation CYLTabButtonZoomInAnimation

- (instancetype)init {
    if (self = [super init]) {
        _duration = CYLTabButtonAnimationDuration;
    }
    return self;
}

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:CYLTabButtonAnimationKeyPathScale];
    animation.values = @[ @0.1, @1.2, @0.9, @1.0 ];
    animation.keyTimes = @[ @0.0, @0.5, @0.75, @1.0 ];
    animation.duration = self.duration;
    [iconView.layer addAnimation:animation forKey:@"cyl.tabButton.zoomIn"];
}

@end

#pragma mark - CYLTabButtonBounceAnimation

@implementation CYLTabButtonBounceAnimation

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CAKeyframeAnimation *animation = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathScale,
                                                                   @[ @1.0, @0.85, @1.15, @0.95, @1.02, @1.0 ],
                                                                   CYLTabButtonAnimationDuration);
    [iconView.layer addAnimation:animation forKey:@"cyl.tabButton.bounce"];
    if (self.playsFireworks) {
        CYLTabButtonPlayFireworks(iconView, self.fireworksImage);
    }
}

@end

#pragma mark - CYLTabButtonRotationAnimation

@implementation CYLTabButtonRotationAnimation

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:CYLTabButtonAnimationKeyPathRotation];
    animation.fromValue = @0.0;
    animation.toValue = @(-M_PI * 2);
    animation.duration = CYLTabButtonAnimationDuration;
    [iconView.layer addAnimation:animation forKey:@"cyl.tabButton.rotation"];
}

@end

#pragma mark - CYLTabButtonFumeAnimation

/// [EN] The animations Fume leaves on the button while it is selected. [CN] Tab 选中期间 Fume 留在按钮上的动画。
static NSString *const CYLTabButtonFumeIconKey = @"cyl.tabButton.fume.icon";
static NSString *const CYLTabButtonFumeMoveKey = @"cyl.tabButton.fume.move";
static NSString *const CYLTabButtonFumeScaleKey = @"cyl.tabButton.fume.scale";
static NSString *const CYLTabButtonFumeOpacityKey = @"cyl.tabButton.fume.opacity";

static void CYLTabButtonFumeMoveIcon(UIView *iconView, NSArray *values) {
    CAKeyframeAnimation *animation = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathPositionY, values, CYLTabButtonAnimationDuration / 2.0);
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [iconView.layer addAnimation:animation forKey:CYLTabButtonFumeIconKey];
}

@implementation CYLTabButtonFumeAnimation

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLTabButtonFumeMoveIcon(iconView, @[ @(iconView.layer.position.y), @(iconView.layer.position.y + 4.0) ]);
    if (!titleLabel) {
        return;
    }
    CGFloat y = titleLabel.layer.position.y;
    CAKeyframeAnimation *move = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathPositionY, @[ @(y), @(y - 60.0) ], CYLTabButtonAnimationDuration);
    [titleLabel.layer addAnimation:move forKey:CYLTabButtonFumeMoveKey];
    CAKeyframeAnimation *scale = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathScale, @[ @1.0, @2.0 ], CYLTabButtonAnimationDuration);
    [titleLabel.layer addAnimation:scale forKey:CYLTabButtonFumeScaleKey];
    CAKeyframeAnimation *opacity = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathOpacity, @[ @1.0, @0.0 ], CYLTabButtonAnimationDuration);
    [titleLabel.layer addAnimation:opacity forKey:CYLTabButtonFumeOpacityKey];
    titleLabel.alpha = 0;
}

- (void)cyl_playDeselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    // [EN] Removing the forward-filled move puts the icon back where the layout placed it.
    // [CN] 移除保持在终点的位移动画，图标回到布局给出的位置。
    [iconView.layer removeAnimationForKey:CYLTabButtonFumeIconKey];
    if (!titleLabel) {
        return;
    }
    CGFloat y = titleLabel.layer.position.y;
    CAKeyframeAnimation *move = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathPositionY, @[ @(y + 15.0), @(y) ], CYLTabButtonAnimationDuration);
    [titleLabel.layer addAnimation:move forKey:CYLTabButtonFumeMoveKey];
    CAKeyframeAnimation *opacity = CYLTabButtonKeyframeAnimation(CYLTabButtonAnimationKeyPathOpacity, @[ @0.0, @1.0 ], CYLTabButtonAnimationDuration);
    [titleLabel.layer addAnimation:opacity forKey:CYLTabButtonFumeOpacityKey];
    titleLabel.alpha = 1;
}

- (void)cyl_resetTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [iconView.layer removeAnimationForKey:CYLTabButtonFumeIconKey];
    for (NSString *key in @[ CYLTabButtonFumeMoveKey, CYLTabButtonFumeScaleKey, CYLTabButtonFumeOpacityKey ]) {
        [titleLabel.layer removeAnimationForKey:key];
    }
    titleLabel.alpha = 1;
}

@end

#pragma mark - CYLTabButtonFlipAnimation

/// [EN] The transition option for `direction` 1–6. [CN] `direction`（1–6）对应的转场选项。
static UIViewAnimationOptions CYLTabButtonFlipOption(NSUInteger direction) {
    switch (direction) {
        case 2: return UIViewAnimationOptionTransitionFlipFromRight;
        case 3: return UIViewAnimationOptionTransitionFlipFromTop;
        case 4: return UIViewAnimationOptionTransitionFlipFromBottom;
        case 5: return UIViewAnimationOptionTransitionCurlUp;
        case 6: return UIViewAnimationOptionTransitionCurlDown;
        default: return UIViewAnimationOptionTransitionFlipFromLeft;
    }
}

@implementation CYLTabButtonFlipAnimation

- (instancetype)init {
    if (self = [super init]) {
        _direction = 1;
    }
    return self;
}

- (NSUInteger)cyl_clampedDirection {
    return MIN(MAX(self.direction, (NSUInteger)1), (NSUInteger)6);
}

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [UIView transitionWithView:iconView
                      duration:CYLTabButtonAnimationDuration
                       options:CYLTabButtonFlipOption([self cyl_clampedDirection])
                    animations:nil
                    completion:nil];
}

- (void)cyl_playDeselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    if (self.disablesDeselectAnimation) {
        return;
    }
    // [EN] The opposite direction: 1 ↔ 2, 3 ↔ 4, 5 ↔ 6. [CN] 反方向：1 ↔ 2、3 ↔ 4、5 ↔ 6。
    NSUInteger direction = [self cyl_clampedDirection];
    NSUInteger opposite = (direction % 2 == 0) ? direction - 1 : direction + 1;
    [UIView transitionWithView:iconView
                      duration:CYLTabButtonAnimationDuration
                       options:CYLTabButtonFlipOption(opposite)
                    animations:nil
                    completion:nil];
}

@end

#pragma mark - CYLTabButtonFrameAnimation

@implementation CYLTabButtonFrameAnimation

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    if (self.images.count == 0) {
        return;
    }
    CYLTabButtonPlayFrameAnimation(iconView, self.images, NO);
    if (self.playsFireworks) {
        CYLTabButtonPlayFireworks(iconView, self.fireworksImage);
    }
}

- (void)cyl_playDeselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    if (self.images.count == 0) {
        return;
    }
    CYLTabButtonPlayFrameAnimation(iconView, self.images, YES);
}

- (void)cyl_resetTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [iconView.layer removeAnimationForKey:CYLTabButtonFrameAnimationKey];
}

@end

#pragma mark - CYLTabButtonPressAnimation

@implementation CYLTabButtonPressAnimation

- (instancetype)init {
    if (self = [super init]) {
        _pressedScale = 0.85;
    }
    return self;
}

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    // [EN] Pressing is the whole animation; nothing more on selection. [CN] 按压即是全部动画，选中时不再播放。
}

- (void)cyl_playHighlightAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CGFloat scale = self.pressedScale;
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        iconView.transform = CGAffineTransformMakeScale(scale, scale);
    } completion:nil];
}

- (void)cyl_playDehighlightAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        iconView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end

@implementation CYLTabButtonBlockAnimation

/*!
 * [EN] An optional method counts as implemented only while its block is set, so the library's default applies otherwise.
 * [CN] 只有设置了对应 block 时，可选方法才算已实现；否则库的默认行为生效。
 */
- (BOOL)respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(cyl_playDeselectAnimationWithTabButton:iconView:titleLabel:)) {
        return self.deselectAnimation != nil;
    }
    if (aSelector == @selector(cyl_playReselectAnimationWithTabButton:iconView:titleLabel:)) {
        return self.reselectAnimation != nil;
    }
    if (aSelector == @selector(cyl_playHighlightAnimationWithTabButton:iconView:titleLabel:)) {
        return self.highlightAnimation != nil;
    }
    if (aSelector == @selector(cyl_playDehighlightAnimationWithTabButton:iconView:titleLabel:)) {
        return self.dehighlightAnimation != nil;
    }
    if (aSelector == @selector(cyl_playBadgeChangedAnimationWithTabButton:iconView:badgeView:)) {
        return self.badgeChangedAnimation != nil;
    }
    return [super respondsToSelector:aSelector];
}

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLTabButtonAnimationBlock block = self.selectAnimation;
    if (block) {
        block(button, iconView, titleLabel);
    }
}

- (void)cyl_playDeselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLTabButtonAnimationBlock block = self.deselectAnimation;
    if (block) {
        block(button, iconView, titleLabel);
    }
}

- (void)cyl_playReselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLTabButtonAnimationBlock block = self.reselectAnimation;
    if (block) {
        block(button, iconView, titleLabel);
    }
}

- (void)cyl_playHighlightAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLTabButtonAnimationBlock block = self.highlightAnimation;
    if (block) {
        block(button, iconView, titleLabel);
    }
}

- (void)cyl_playDehighlightAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLTabButtonAnimationBlock block = self.dehighlightAnimation;
    if (block) {
        block(button, iconView, titleLabel);
    }
}

- (void)cyl_playBadgeChangedAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView badgeView:(UIView *)badgeView {
    CYLTabButtonBadgeAnimationBlock block = self.badgeChangedAnimation;
    if (block) {
        block(button, iconView, badgeView);
    }
}

@end
