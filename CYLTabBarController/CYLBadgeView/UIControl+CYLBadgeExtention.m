/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIControl+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CYLBadgeProtocol.h"
#import "CYLBadgeViewDefines.h"

/*!
 * FIX: issue #535
 * [EN] This category puts a tab button's badge on its icon (image or Lottie view) and mirrors it to the Liquid Glass
 *      platter, which needs Core. Without Core (`pod 'CYLTabBarController/CYLBadgeView'`) it is left out, and every
 *      `UIControl`, e.g. a `UIButton`, uses the `UIView (CYLBadgeExtention)` implementation: the badge goes on the
 *      control itself.
 * [CN] 该分类把 Tab 按钮的角标放在图标（图片或 Lottie 视图）上，并同步到液态玻璃 platter，这些都依赖 Core。没有 Core 时
 *      （`pod 'CYLTabBarController/CYLBadgeView'`）不编译该分类，所有 `UIControl`（例如 `UIButton`）使用
 *      `UIView (CYLBadgeExtention)` 的实现，角标显示在控件本身上。
 */
#if CYL_BADGE_CORE_AVAILABLE

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView

/// [EN] Above 0 while `-cyl_performOnBadgeLayers:` runs (UIKit, so the main thread only).
/// [CN] `-cyl_performOnBadgeLayers:` 执行期间大于 0（UIKit，只在主线程）。
static NSInteger CYLBadgeLayerPerformDepth = 0;

@interface UIView (CYLBadgeAnchorLayout)
- (void)cyl_layoutBadgeAtTopRightCorner;
@end

/*!
 * [EN] The transparent view that holds a control's badge (`-cyl_badgeAnchorViewAlignedToView:`). It places its badge again
 *      on every layout pass, from its final bounds: placed once, the badge kept the fraction of a point it got from the
 *      bounds at that moment (a plus button's badge shown before its image loaded sat 0.17–0.33 pt off the same badge shown
 *      with the image ready).
 * [CN] 承载控件角标的透明视图（`-cyl_badgeAnchorViewAlignedToView:`）。每次布局都按最终的 bounds 重新放置角标：只放置一次时，角标会保留当时
 *      bounds 带来的不到一个点的偏差（图片加载前就显示的 PlusButton 角标，与图片已就绪时显示的同一角标相差 0.17–0.33 pt）。
 */
@interface CYLBadgeAnchorView : UIView
/// [EN] The view it follows, the visible part of its picture (fractions) and the two constraints set from them.
/// [CN] 跟随的视图、其图片可见部分（比例）以及据此设置的两个约束。
@property (nonatomic, weak) UIView *cyl_target;
@property (nonatomic, assign) CGRect cyl_unitRect;
@property (nonatomic, weak) NSLayoutConstraint *cyl_leadingConstraint;
@property (nonatomic, weak) NSLayoutConstraint *cyl_topConstraint;
@end

@implementation CYLBadgeAnchorView

- (void)layoutSubviews {
    [super layoutSubviews];
    // [EN] The padding before the visible part follows the target's current size: computed only when the badge was pinned,
    //      it kept the size the target had then (a badge pinned before its image loaded sat 0.17 pt off).
    // [CN] 可见部分之前的边距随目标当前尺寸变化：只在固定角标时计算的话，会保留目标当时的尺寸（图片加载前固定的角标偏移 0.17 pt）。
    CGSize targetSize = self.cyl_target.bounds.size;
    CGFloat leading = CGRectGetMinX(self.cyl_unitRect) * targetSize.width;
    CGFloat top = CGRectGetMinY(self.cyl_unitRect) * targetSize.height;
    if (self.cyl_leadingConstraint && fabs(self.cyl_leadingConstraint.constant - leading) > 0.01) {
        self.cyl_leadingConstraint.constant = leading;
    }
    if (self.cyl_topConstraint && fabs(self.cyl_topConstraint.constant - top) > 0.01) {
        self.cyl_topConstraint.constant = top;
    }
    [self cyl_layoutBadgeAtTopRightCorner];
}

@end

@implementation UIControl (CYLBadgeExtention) 

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    CYL_DEPRECATED_DECLARATIONS_PUSH
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     // [CN] 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
     // [EN] No longer required, so this is not core logic; may be removed in the future.
     if (self && [self respondsToSelector:@selector(cyl_removeTabBadgePoint)]) {
         [self cyl_removeTabBadgePoint];
     }
     );
    
    
    CYL_DEPRECATED_DECLARATIONS_POP
    
    [self cyl_clearBadge];
    // FIX: this used to call itself and never return. 之前这里调用自身，导致无限递归。
    [self cyl_showBadgeValue:badgeValue animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
}

// Bridge getters for KVC/KVO compliance if accessed as properties
- (NSNumber *)cyl_badgeAnimationTypeValue {
    return @(self.cyl_badgeAnimationType);
}

- (NSValue *)cyl_badgeCenterOffsetValue {
    return [NSValue valueWithCGPoint:self.cyl_badgeCenterOffset];
}

- (NSNumber *)cyl_badgeCornerRadiusValue {
    return @(self.cyl_badgeCornerRadius);
}

- (NSValue *)cyl_badgeFrameValue {
    return [NSValue valueWithCGRect:self.cyl_badgeFrame];
}

- (NSNumber *)cyl_badgeMarginValue {
    return @(self.cyl_badgeMargin);
}

- (NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    return @(self.cyl_badgeMaximumBadgeNumber);
}

- (NSNumber *)cyl_badgeRadiusValue {
    return @(self.cyl_badgeRadius);
}

// delayIfNeededForSeconds getter/setter to satisfy warnings
- (NSTimeInterval)cyl_delayIfNeededForSeconds {
    // Default to 0 if not managed elsewhere; adjust if there is a backing store
    NSNumber *value = objc_getAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds));
    return value != nil ? value.doubleValue : 0;
}

- (void)cyl_setDelayIfNeededForSeconds:(NSTimeInterval)seconds {
    objc_setAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds), @(seconds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)cyl_delayIfNeededForSecondsValue {
    return @(self.cyl_delayIfNeededForSeconds);
}

- (void)cyl_setDelayIfNeededForSecondsValue:(NSNumber *)delayIfNeededForSecondsValue {
    [self cyl_setDelayIfNeededForSeconds:[delayIfNeededForSecondsValue doubleValue]];
}

#pragma mark -- public methods

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [self cyl_showBadgeValue:@"" animationTypeValue:@(CYLBadgeAnimationTypeNone)];
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [self cyl_showBadgeValue:value animationTypeValue:@(animationType)];
}

- (void)cyl_showBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue {
    if (CYLBadgeLayerPerformDepth == 0) {
        [self cyl_performSelector:_cmd withObject:value withObject:animationTypeValue];
        return;
    }
    [self cyl_showBadgeValueInThisLayer:value animationTypeValue:animationTypeValue];
}

- (void)cyl_showBadgeValueInThisLayer:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue {
    [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:value animationType:(CYLBadgeAnimationType)animationTypeValue.integerValue];
}

- (BOOL)cyl_isShowBadge {
    return [CYL_ACTUAL_BARBUTTON cyl_isShowBadge];
}

- (BOOL)cyl_isPauseBadge {
    return [CYL_ACTUAL_BARBUTTON cyl_isPauseBadge];
}

/**
 *  clear badge
 */
- (void)cyl_clearBadge {
    if (CYLBadgeLayerPerformDepth == 0) {
        [self cyl_performSelector:_cmd];
        return;
    }
    [CYL_ACTUAL_BARBUTTON cyl_clearBadge];
}

- (void)cyl_resumeBadge {
    if (CYLBadgeLayerPerformDepth == 0) {
        [self cyl_performSelector:_cmd];
        return;
    }
    [CYL_ACTUAL_BARBUTTON cyl_resumeBadge];
}

- (void)cyl_refreshBadge {
    if (CYLBadgeLayerPerformDepth == 0) {
        [self cyl_performSelector:_cmd];
        return;
    }
    [CYL_ACTUAL_BARBUTTON cyl_refreshBadge];
}

#pragma mark -- private method

- (UIView *)cyl_getActualBadgeSuperViewFromControl:(UIControl *)tabButton {
    return [tabButton cyl_getActualBadgeSuperView];
}
/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
 This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *
 *  @return view
 */
- (UIView *)cyl_getActualBadgeSuperView {
    // badge label will be added onto imageView
    //只有在TabBar选中状态下才能取到SwappableImageView
    UIControl *tabButton = self;
    UIImageView *tabImageView = [tabButton cyl_tabImageView];
    UIView *lottieAnimationView = tabButton.cyl_tabBarItemAnimationView;
    
    UIView *actualBadgeSuperView = nil;
    
    do {
        // [EN] Issue #601: an icon hidden for the view shown in its place still takes the badge.
        // [CN] 被替换显示而隐藏的图标仍承载角标。
        if (lottieAnimationView && (!lottieAnimationView.cyl_isInvisiable || lottieAnimationView.cyl_isBadgeHostReplacedByIconView)) {
            actualBadgeSuperView = lottieAnimationView;

            break;
        }
        if (tabImageView && (!tabImageView.cyl_isInvisiable || tabImageView.cyl_isBadgeHostReplacedByIconView)) {
            actualBadgeSuperView = tabImageView;

            break;
        }
    } while (NO);
    // By class name: `-cyl_isTabButton` is YES for every UIControl before iOS 26. UITabBarButton, _UITabButton and
    // CYLFlatDesignTabBarButton are tab buttons. 按类名判断：iOS 26 以前 `-cyl_isTabButton` 对所有 UIControl 都返回 YES。
    NSString *controlClassName = NSStringFromClass(tabButton.class);
    BOOL isTabBarButton = [controlClassName containsString:@"TabButton"] || [controlClassName containsString:@"TabBarButton"];
    if (!isTabBarButton) {
        /*!
         * FIX: badges of plus buttons and other controls were covered or clipped
         * [EN] The badge of a control that is not a tab button (a plus button, any UIButton) went inside its icon. That
         *      view can lie under the control's other content: a UIButton with a configuration draws its image above
         *      the first image view found, so the plus button's "+" covered most of its badge. It also changed the
         *      icon's `clipsToBounds`. The badge now goes on a transparent anchor that is the control's top-most
         *      subview (zPosition MAXFLOAT, so content the control adds later stays below it), aligned to the icon or,
         *      without one, to the whole control: it is always drawn above everything in the control, at the icon's
         *      top-right corner as before. When the control clips (clipsToBounds, masksToBounds or a mask), the anchor
         *      goes right above the control in its superview instead, so the clipping does not cut the badge. Tab
         *      buttons are unchanged.
         * [CN] 非 Tab 按钮的控件（PlusButton、任意 UIButton）的角标原先放在其图标视图中。该视图可能位于控件其他内容之下：使用
         *      configuration 的 UIButton 会在找到的第一个图片视图之上绘制图片，因此 PlusButton 的「+」遮住了大部分角标；原逻辑还会
         *      修改图标的 `clipsToBounds`。现在角标放在一个透明的锚点视图上，它是控件最上层的子视图（zPosition 为 MAXFLOAT，控件之后
         *      添加的内容也位于其下），与图标对齐，没有图标时与整个控件对齐：角标总是绘制在控件所有内容之上，位置仍在图标右上角。
         *      控件本身会裁剪（clipsToBounds、masksToBounds 或 mask）时，锚点改为放在父视图中、紧贴控件之上，角标不再被裁剪。
         *      Tab 按钮不变。
         */
        return [tabButton cyl_badgeAnchorViewAlignedToView:actualBadgeSuperView];
    }
    if (actualBadgeSuperView) {
        [actualBadgeSuperView setClipsToBounds:NO];
        // [CN] 建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
        // [EN] It is recommended to call layoutIfNeeded after the autolayout code before trying to read the frame.
        //      Auto layout cells
        //      need [self layoutIfNeeded] for the frame to have a value, so the badge can find its position.
        //      Make sure the view's showBadge method is called after layoutIfNeeded
        [actualBadgeSuperView layoutIfNeeded];// [CN] 建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame
        // [EN] It is recommended to call layoutIfNeeded after the autolayout code before trying to read the frame
    }

    return actualBadgeSuperView;
}

/*!
 * [EN] The part of `image` that is not transparent, as fractions of its size (the whole image without alpha, or when it
 *      cannot be read). Measured once per image, on a copy of at most 64×64 pixels.
 * [CN] `image` 中不透明的部分，以占其尺寸的比例表示（没有 alpha 或无法读取时为整张图片）。每张图片只测量一次，使用最大 64×64 像素的副本。
 */
static CGRect CYLBadgeOpaqueUnitRectOfImage(UIImage *image) {
    static const char CYLBadgeOpaqueUnitRectKey = 0;
    CGRect unitRect = CGRectMake(0, 0, 1, 1);
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        return unitRect;
    }
    NSValue *cached = objc_getAssociatedObject(image, &CYLBadgeOpaqueUnitRectKey);
    if (cached) {
        return cached.CGRectValue;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = alphaInfo != kCGImageAlphaNone && alphaInfo != kCGImageAlphaNoneSkipFirst && alphaInfo != kCGImageAlphaNoneSkipLast;
    size_t width = MIN(CGImageGetWidth(cgImage), (size_t)64);
    size_t height = MIN(CGImageGetHeight(cgImage), (size_t)64);
    if (hasAlpha && width > 0 && height > 0) {
        NSMutableData *alphaData = [NSMutableData dataWithLength:width * height];
        CGContextRef context = CGBitmapContextCreate(alphaData.mutableBytes, width, height, 8, width, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
            CGContextRelease(context);
            // [EN] Row 0 of the buffer is the top of the image. [CN] 缓冲区第 0 行是图片顶部。
            const uint8_t *alpha = alphaData.bytes;
            size_t minX = width, minY = height, maxX = 0, maxY = 0;
            for (size_t y = 0; y < height; y++) {
                for (size_t x = 0; x < width; x++) {
                    if (alpha[y * width + x] > 25) {
                        minX = MIN(minX, x);
                        maxX = MAX(maxX, x);
                        minY = MIN(minY, y);
                        maxY = MAX(maxY, y);
                    }
                }
            }
            if (minX <= maxX && minY <= maxY) {
                unitRect = CGRectMake((CGFloat)minX / width, (CGFloat)minY / height,
                                      (CGFloat)(maxX - minX + 1) / width, (CGFloat)(maxY - minY + 1) / height);
            }
        }
    }
    objc_setAssociatedObject(image, &CYLBadgeOpaqueUnitRectKey, [NSValue valueWithCGRect:unitRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return unitRect;
}

/// [EN] The picture that fills `view`: an image view's image, or the background image of a button without an image.
/// [CN] 填满 `view` 的图片：图片视图的图片，或没有图片的按钮的背景图片。
static UIImage *CYLBadgeImageFillingView(UIView *view) {
    if ([view isKindOfClass:[UIImageView class]]) {
        return ((UIImageView *)view).image;
    }
    if ([view isKindOfClass:[UIButton class]] && !((UIButton *)view).currentImage) {
        return ((UIButton *)view).currentBackgroundImage;
    }
    return nil;
}

/*!
 * [EN] The transparent view that holds the badge of a control that is not a tab button, aligned to `referenceView` (the
 *      icon) or to the whole control, and within it to the visible part of its picture: a picture with transparent
 *      padding (e.g. Example-PAG's plus button, a 66 pt circle in a 90 pt image) put the badge at the padding's corner,
 *      away from what is seen.
 * [CN] 承载非 Tab 按钮控件角标的透明视图，与 `referenceView`（图标）或整个控件对齐，并进一步对齐到其图片的可见部分：图片带透明边距时
 *      （例如 Example-PAG 的 PlusButton，90 pt 图片中是 66 pt 的圆形），角标原先位于边距的角上，离可见内容较远。
 */
- (UIView *)cyl_badgeAnchorViewAlignedToView:(UIView *)referenceView {
    UIView *anchorView = objc_getAssociatedObject(self, @selector(cyl_badgeAnchorViewAlignedToView:));
    if (!anchorView) {
        anchorView = [[CYLBadgeAnchorView alloc] initWithFrame:self.bounds];
        anchorView.backgroundColor = UIColor.clearColor;
        anchorView.userInteractionEnabled = NO;
        anchorView.clipsToBounds = NO;
        anchorView.isAccessibilityElement = NO;
        anchorView.translatesAutoresizingMaskIntoConstraints = NO;
        objc_setAssociatedObject(self, @selector(cyl_badgeAnchorViewAlignedToView:), anchorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    BOOL controlClips = self.clipsToBounds || self.layer.masksToBounds || self.layer.mask;
    UIView *container = (controlClips && self.superview) ? self.superview : self;
    if (container == self) {
        if (anchorView.superview != self) {
            [anchorView removeFromSuperview];
            [self addSubview:anchorView];
        }
        [self bringSubviewToFront:anchorView];
        anchorView.layer.zPosition = MAXFLOAT;
    } else {
        if (anchorView.superview != container) {
            [anchorView removeFromSuperview];
        }
        [container insertSubview:anchorView aboveSubview:self];
        anchorView.layer.zPosition = self.layer.zPosition;
        anchorView.hidden = self.hidden;
        anchorView.alpha = self.alpha;
    }
    UIView *target = (referenceView && referenceView != anchorView) ? referenceView : self;
    // [EN] An image view without an image shows nothing (e.g. a plus button drawn by its background image, or whose image
    //      is not loaded yet): the badge goes on the whole control, whose background is what is seen.
    // [CN] 没有图片的图片视图不显示任何内容（例如由背景图绘制的 PlusButton，或图片尚未加载）：角标对齐整个控件，其背景才是可见内容。
    if ([target isKindOfClass:[UIImageView class]]) {
        CGSize imageSize = ((UIImageView *)target).image.size;
        if (imageSize.width <= 0 || imageSize.height <= 0) {
            target = self;
        }
    }
    CGRect unitRect = CYLBadgeOpaqueUnitRectOfImage(CYLBadgeImageFillingView(target));
    CGSize targetSize = target.bounds.size;
    NSArray<NSLayoutConstraint *> *constraints = objc_getAssociatedObject(anchorView, @selector(cyl_badgeAnchorViewAlignedToView:));
    BOOL isPinnedToTarget = constraints.count == 4 && constraints.firstObject.active && constraints.firstObject.secondItem == target &&
                            constraints[2].multiplier == CGRectGetWidth(unitRect) && constraints[3].multiplier == CGRectGetHeight(unitRect);
    if (!isPinnedToTarget) {
        [NSLayoutConstraint deactivateConstraints:constraints ?: @[]];
        // Constraints keep the anchor on the icon as the control lays out again. 约束让锚点在控件重新布局后仍与图标对齐。
        constraints = @[
            [anchorView.leadingAnchor constraintEqualToAnchor:target.leadingAnchor],
            [anchorView.topAnchor constraintEqualToAnchor:target.topAnchor],
            [anchorView.widthAnchor constraintEqualToAnchor:target.widthAnchor multiplier:CGRectGetWidth(unitRect)],
            [anchorView.heightAnchor constraintEqualToAnchor:target.heightAnchor multiplier:CGRectGetHeight(unitRect)],
        ];
        [NSLayoutConstraint activateConstraints:constraints];
        objc_setAssociatedObject(anchorView, @selector(cyl_badgeAnchorViewAlignedToView:), constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        isPinnedToTarget = NO;
    }
    // [EN] The padding before the visible part, for the target's current size. Only real changes: this runs during the
    //      plus button's layout, and any change lays it out again.
    // [CN] 可见部分之前的边距，按目标当前尺寸计算。只在确有变化时修改：本方法在 PlusButton 布局期间执行，任何修改都会让它再次布局。
    CGFloat leading = CGRectGetMinX(unitRect) * targetSize.width;
    CGFloat top = CGRectGetMinY(unitRect) * targetSize.height;
    if ([anchorView isKindOfClass:[CYLBadgeAnchorView class]]) {
        CYLBadgeAnchorView *badgeAnchorView = (CYLBadgeAnchorView *)anchorView;
        badgeAnchorView.cyl_target = target;
        badgeAnchorView.cyl_unitRect = unitRect;
        badgeAnchorView.cyl_leadingConstraint = constraints[0];
        badgeAnchorView.cyl_topConstraint = constraints[1];
    }
    if (fabs(constraints[0].constant - leading) >= 0.5) {
        constraints[0].constant = leading;
    }
    if (fabs(constraints[1].constant - top) >= 0.5) {
        constraints[1].constant = top;
    }
    if (!isPinnedToTarget) {
        // [EN] Once, right after pinning, so the badge can be laid out before the next layout pass; setting it on every
        //      call fought Auto Layout's pixel rounding and laid the plus button out forever.
        // [CN] 只在刚建立约束时设置一次 frame，角标无需等到下一次布局；每次调用都设置会与 Auto Layout 的像素取整冲突，导致 PlusButton 无限布局。
        CGRect visibleRect = CGRectMake(leading, top, CGRectGetWidth(unitRect) * targetSize.width,
                                        CGRectGetHeight(unitRect) * targetSize.height);
        anchorView.frame = [target convertRect:visibleRect toView:container];
    }
    return anchorView;
}

- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *obj = nil;
    [self cyl_performSelector:aSelector withObject:obj];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object1 withObject:(nullable id)object2 {
    if (aSelector == NULL) { return; }
    [self cyl_performOnBadgeLayers:^(UIControl *control) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [control performSelector:aSelector withObject:object1 withObject:object2];
         )
    }];
}

/*!
 * FIX: issue #779
 * [EN] The controls that draw this tab, one per layer: on Liquid Glass, the control in the normal layer and the one in the
 *      selected layer, which is seen through the glass. A badge in only one of them was covered by the glass.
 * [CN] 绘制该 Tab 的控件，每个图层一个：液态玻璃下是普通图层与选中图层（透过玻璃看到）中的控件。只在其中一个上显示角标时，角标会被玻璃遮挡。
 */
- (NSArray<UIControl *> *)cyl_badgeLayerControls {
    if (![CYLUtils isLiquidGlassActive]) {
        return @[ self ];
    }
    UIControl *counterpart = [self cyl_isPlatterSelectedControl] ? self.cyl_platterNormalControl : self.cyl_platterSelectedControl;
    return (counterpart && counterpart != self) ? @[ self, counterpart ] : @[ self ];
}

/*!
 * FIX: issue #779
 * [EN] Runs `block` once per layer. Inside it, a badge method called on a control acts on that control only, so
 *      `-[UIViewController cyl_showBadgeValue:animationType:]`, `-[UITabBarItem ...]` and a direct call on a tab button or a
 *      plus button all reach both layers exactly once.
 * [CN] 每个图层执行一次 `block`。在其中对控件调用角标方法时只作用于该控件，因此通过 UIViewController、UITabBarItem，或直接对 Tab 按钮、
 *      PlusButton 调用，都恰好作用于两个图层各一次。
 */
- (void)cyl_performOnBadgeLayers:(void (NS_NOESCAPE ^)(UIControl *control))block {
    if (CYLBadgeLayerPerformDepth > 0) {
        block(self);
        return;
    }
    CYLBadgeLayerPerformDepth++;
    for (UIControl *control in [self cyl_badgeLayerControls]) {
        block(control);
    }
    CYLBadgeLayerPerformDepth--;
}

- (BOOL)cyl_isReady {
    if (![CYLUtils isLiquidGlassActive]) {
        return YES;
    }
    // [CN] 由于 SelectedControl 所在图层的渲染比未选中图层有延迟， 所以必须加延迟，如果不加延迟，可能无法获取到正确的子视图， 有概率获取的子视图为nil
    //由于有几率无法获取到cyl_tabImageView， 只有延迟获取，才能避免获取为空nil。
    // [EN] Because the layer of the SelectedControl renders later than the unselected layer, a delay is
    //      required. Without it
    //      the correct subview may not be obtained, and the subview may sometimes be nil
    //      cyl_tabImageView sometimes cannot be obtained; only fetching it after a delay avoids getting nil.
    
    UIView *view = self.cyl_platterSelectedControl.cyl_tabImageView;
    if (!view) {
        return NO;
    }
    BOOL isTabImageViewReady = self.cyl_tabImageView.frame.size.width > 10 || self.cyl_tabLabel.frame.size.width > 10;
    BOOL isLottieReady = YES;
    if (self.cyl_tabBarController.tabBarItemAnimationURLs.count > 0) {
        isLottieReady = self.cyl_isTabBarItemAnimationReady;
    }
    return isTabImageViewReady && isLottieReady;
}

#pragma mark -- setter/getter
- (UIView<CYLBadgeTextDisplaying> *)cyl_badge {
    return CYL_ACTUAL_BARBUTTON.cyl_badge;
}

- (void)cyl_setBadge:(UIView<CYLBadgeTextDisplaying> *)label {
    // [EN] One view cannot be in two layers. [CN] 一个视图不能同时位于两个图层。
    [CYL_ACTUAL_BARBUTTON cyl_setBadge:label];
}

- (UIFont *)cyl_badgeFont {
    return CYL_ACTUAL_BARBUTTON.cyl_badgeFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeFont:badgeFont]; }];
}

- (UIColor *)cyl_badgeBackgroundColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBackgroundColor];
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeBackgroundColor:badgeBackgroundColor]; }];
}

- (UIColor *)cyl_badgeTextColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeTextColor];
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeTextColor:badgeTextColor]; }];
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeAnimationType];
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeAnimationType:animationType]; }];
}

// The badge lives on the actual badge super view (tab image / Lottie view), like the properties above.
- (UIColor *)cyl_badgeBorderColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBorderColor];
}

- (void)cyl_setBadgeBorderColor:(UIColor *)badgeBorderColor {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeBorderColor:badgeBorderColor]; }];
}

- (CGFloat)cyl_badgeBorderWidth {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBorderWidth];
}

- (void)cyl_setBadgeBorderWidth:(CGFloat)badgeBorderWidth {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeBorderWidth:badgeBorderWidth]; }];
}

- (BOOL)cyl_badgeRespectsReduceMotion {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRespectsReduceMotion];
}

- (void)cyl_setBadgeRespectsReduceMotion:(BOOL)badgeRespectsReduceMotion {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeRespectsReduceMotion:badgeRespectsReduceMotion]; }];
}

- (CGRect)cyl_badgeFrame {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeFrame:badgeFrame]; }];
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeCenterOffset:badgeCenterOffset]; }];
}

- (void)cyl_setBadgeCenterOffsetValue:(NSValue *)badgeCenterOffsetValue {
//    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
    CGPoint badgeCenterOffset = badgeCenterOffsetValue.CGPointValue;
    [self cyl_setBadgeCenterOffset:badgeCenterOffset];
}
- (NSInteger)cyl_badgeMaximumBadgeNumber {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber]; }];
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeMargin:badgeMargin]; }];
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue doubleValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeRadius:badgeRadius]; }];
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue doubleValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (CGFloat)cyl_badgeCornerRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)cyl_badgeCornerRadius {
    [self cyl_performOnBadgeLayers:^(UIControl *control) { [(UIView *)[control cyl_getActualBadgeSuperView] cyl_setBadgeCornerRadius:cyl_badgeCornerRadius]; }];
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue doubleValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

@end

#endif /* CYL_BADGE_CORE_AVAILABLE */
