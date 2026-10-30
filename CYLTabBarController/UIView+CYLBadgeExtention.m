/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIView+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CAAnimation+CYLBadgeExtention.h"
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "CYLBadge/CYLTabBarBadgeView.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#endif


#define kCYLBadgeDefaultMaximumBadgeNumber 99
#define kCYLBadgeDefaultMargin (8.0)
#define kCYLBadgeDefaultDelayIfNeededForSeconds (0.5)

static const CGFloat kCYLBadgeDefaultRedDotRadius = 4.f;
static const NSUInteger kCYLBadgeMaximumLayoutRetryCount = 3;

@implementation UIView (CYLBadgeExtention)

#pragma mark -- public methods

- (BOOL)cyl_isReady {

    if (![self cyl_badgeClass]) {
        return NO;
    }
//    if (!CYLGetRootViewController()) {
    //UIBarButton not ready, so if you use for BarButton, we cannot add redpoint. so i delete this judge.
//        return NO;
//    }
    UIView *view = [self cyl_getActualBadgeSuperView];

    if (view && [view isKindOfClass:[UIView class]]) {
        return view.frame.size.width > 10;
    }
    return [view cyl_findBarButtonContentView].frame.size.width > 10;
}
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [self cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value
        animationTypeValue:(NSNumber *)animationTypeValue {
    NSUInteger generation = [self cyl_invalidatePendingBadgeValue];
    if ([self cyl_shouldWaitForLayoutBeforeShowingBadgeValue:value]) {
        [self cyl_showBadgeValue:value animationTypeValue:animationTypeValue afterLayoutWithGeneration:generation attempt:0];
        return;
    }
    [self cyl_showBadgeValueNow:value animationTypeValue:animationTypeValue];
}

/*!
 * FIX: badge position with Auto Layout (xib / storyboard / constraints, e.g. a label with a relative width in a cell)
 * [EN] The badge was placed once, from the host view's frame at the moment it was shown. With Auto Layout that frame
 *      is often still zero (the badge was then dropped, so apps waited with `dispatch_after`) or changes later (the
 *      badge stayed where the old right edge was). Now:
 *      1. A host that is not laid out yet (`-cyl_isReady` is NO even after `-layoutIfNeeded`) shows the badge on the
 *         next run loop, then after `cyl_delayIfNeededForSeconds`, at most `kCYLBadgeMaximumLayoutRetryCount` times.
 *         Only the latest value is shown: a newer show or a clear cancels a pending one.
 *      2. The badge is anchored to the host's top-right corner (`-cyl_layoutBadgeAtTopRightCorner`), so it follows
 *         later size changes.
 *      Scope: every badge, whatever the tab bar style (classic, iOS 26 UI compatibility mode, Liquid Glass on iOS 26+
 *      and the iPhone Duo, FlatDesign) and any other view: they all share this code. On the Duo, folding changes the
 *      tab button widths, and Liquid Glass relays out its buttons; the anchored badge follows both.
 * [CN] 角标只在显示时按宿主视图当时的 frame 定位一次。使用自动布局时，这个 frame 往往还是 0（角标因此不显示，App 只能用
 *      `dispatch_after` 延迟），或者之后才改变（角标停留在原来的右边缘）。现在：
 *      1. 宿主尚未完成布局时（调用 `-layoutIfNeeded` 后 `-cyl_isReady` 仍为 NO），先在下一个 run loop、再按
 *         `cyl_delayIfNeededForSeconds` 延迟重试，最多 `kCYLBadgeMaximumLayoutRetryCount` 次。只显示最新的值：
 *         新的显示或清除会取消等待中的显示。
 *      2. 角标固定在宿主的右上角（`-cyl_layoutBadgeAtTopRightCorner`），宿主尺寸之后改变时角标跟随移动。
 *      范围：所有角标，与 TabBar 样式无关（经典、iOS 26 UI 兼容模式、iOS 26+ 液态玻璃与 iPhone Duo、扁平样式），
 *      以及其他任意视图：它们共用这段代码。iPhone Duo 折叠时 Tab 按钮宽度会变，液态玻璃也会重新布局按钮，角标都会跟随。
 */
- (BOOL)cyl_shouldWaitForLayoutBeforeShowingBadgeValue:(NSString *)value {
    if (!value || ![self cyl_badgeClass]) {
        return NO;
    }
    // A number <= 0 hides the badge, which needs no layout.
    NSString *nonDigits = [value stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if (value.length > 0 && nonDigits.length == 0 && [value integerValue] <= 0) {
        return NO;
    }
    return ![self cyl_isReady];
}

- (void)cyl_showBadgeValue:(NSString *)value
        animationTypeValue:(NSNumber *)animationTypeValue
 afterLayoutWithGeneration:(NSUInteger)generation
                   attempt:(NSUInteger)attempt {
    NSTimeInterval delay = (attempt == 0) ? 0 : MAX(self.cyl_delayIfNeededForSeconds, 0.1);
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self || [self cyl_pendingBadgeGeneration] != generation) {
            return;
        }
        if ((attempt + 1 < kCYLBadgeMaximumLayoutRetryCount) && [self cyl_shouldWaitForLayoutBeforeShowingBadgeValue:value]) {
            [self cyl_showBadgeValue:value animationTypeValue:animationTypeValue afterLayoutWithGeneration:generation attempt:attempt + 1];
            return;
        }
        [self cyl_showBadgeValueNow:value animationTypeValue:animationTypeValue];
    });
}

- (NSUInteger)cyl_pendingBadgeGeneration {
    return [objc_getAssociatedObject(self, @selector(cyl_pendingBadgeGeneration)) unsignedIntegerValue];
}

/// Cancels a badge value waiting for layout; returns the new generation.
- (NSUInteger)cyl_invalidatePendingBadgeValue {
    NSUInteger generation = [self cyl_pendingBadgeGeneration] + 1;
    objc_setAssociatedObject(self, @selector(cyl_pendingBadgeGeneration), @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return generation;
}

- (void)cyl_showBadgeValueNow:(NSString *)value
           animationTypeValue:(NSNumber *)animationTypeValue {
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [[[self cyl_badge] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
     if ([self cyl_shouldUpdateBadgeSubviews]) {
         [[self cyl_badge] removeFromSuperview];
         id view = nil;
         [self cyl_setBadge:view];
     }
     );
    CYLBadgeAnimationType animationType = [animationTypeValue intValue];
    [self  cyl_setBadgeAnimationTypeValue:@(animationType)];
    [self cyl_showBadgeWithValue:value];
    
    if (animationType != CYLBadgeAnimationTypeNone) {
        [self cyl_beginAnimation];
    }
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [self cyl_showBadgeValue:value animationTypeValue:@(animationType)];
}

- (void)cyl_showBadgeValue:(NSString *)value {
    [self cyl_showBadgeValue:value animationType:CYLBadgeAnimationTypeNone];
}

- (BOOL)cyl_keepShowingPlusButtonLabel {
    NSNumber *keepShowingPlusButtonLabelObject = objc_getAssociatedObject(self, @selector(cyl_keepShowingPlusButtonLabel));
    return [keepShowingPlusButtonLabelObject boolValue];
}

- (void)cyl_setKeepShowingPlusButtonLabel:(BOOL)keepShowingPlusButtonLabel {
    NSNumber *keepShowingPlusButtonLabelObject = @(keepShowingPlusButtonLabel);
    objc_setAssociatedObject(self, @selector(cyl_keepShowingPlusButtonLabel), keepShowingPlusButtonLabelObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -- private methods
/**
 By swizzling the original method - (void)willMoveToSuperview:(UIView *)newSuperview;
 Move the badge view on top of its siblings when its super view appears every time for adjustment on iOS 11.
 */
- (void)cyl_willMoveToSuperview:(UIView *)newSuperview __IOS_AVAILABLE(11.0) {
    [self cyl_willMoveToSuperview:newSuperview];
    
    if (newSuperview && self.cyl_badge) {
        [self cyl_bringBadgeToFront:self.cyl_badge];
    }
}

- (void)cyl_showBadgeWithValue:(NSString *)value {
    if (!value) {
        return;
    }
    NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *trimmedString = [value stringByTrimmingCharactersInSet:numberSet];
    BOOL isNumber = NO;
    if ((trimmedString.length == 0) && (value.length > 0)) {
        isNumber = YES;
    }
    if (isNumber) {
        [self cyl_showNumberBadgeWithValue:[value integerValue]];
        return;
    }
    
    if ([value isEqualToString:@""]) {
        [self cyl_showRedDotBadge];
        return;
    }
    if ([value isEqualToString:@"new"] || [value isEqualToString:@"NEW"] ) {
        [self cyl_showNewBadge:value];
        return;
    }
    [self cyl_showTextBadge:value];
}

/**
 *  clear badge
 */
- (void)cyl_clearBadge {
    [self cyl_invalidatePendingBadgeValue];
    [self.cyl_badge cyl_setHidden:YES];
}

- (BOOL)cyl_isShowBadge {
    return (self.cyl_badge && !self.cyl_badge.cyl_isHidden);
}

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge {
    if (self.cyl_isPauseBadge) {
        [self.cyl_badge cyl_setHidden:NO];
    }
}

- (BOOL)cyl_isPauseBadge {
    return (self.cyl_badge && self.cyl_badge.cyl_isHidden);
}

- (id)cyl_getActualBadgeSuperView {
    //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
    [self layoutIfNeeded];
    return self;
}


- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
    if (aSelector == NULL) { return; }
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [self performSelector:aSelector withObject:object1 withObject:object2];
     )
}

#pragma mark -- private methods

- (void)cyl_addMargin {
    CGRect frame = self.cyl_badge.frame;
    frame.size.width += self.cyl_badgeMargin;
    frame.size.height += self.cyl_badgeMargin;
    if(CGRectGetWidth(frame) < CGRectGetHeight(frame)) {
        frame.size.width = CGRectGetHeight(frame);
    }
    self.cyl_badge.frame = frame;
}

- (void)cyl_showRedDotBadge {
    if (![self cyl_isReady]) {
        return;
    }
    [self cyl_badgeInit];
    //if badge has been displayed and, in addition, is was not red dot style, we must update UI.
    if (self.cyl_badge.tag != CYLBadgeStyleRedDot) {
        self.cyl_badge.text = @"";
        self.cyl_badge.tag = CYLBadgeStyleRedDot;
        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
    }
    [self.cyl_badge cyl_setHidden:NO];
}

- (void)cyl_showNewBadge:(NSString *)value {
    if (![self cyl_badgeClass]) {
        return;
    }
    CGSize size = [value sizeWithAttributes:
                   @{NSFontAttributeName:
                         self.cyl_badgeFont}];
    float labelHeight = ceilf(size.height)+ self.cyl_badgeMargin;
    [self cyl_setBadgeCornerRadius:labelHeight/3];
    [self cyl_showTextBadge:value];
}

- (void)cyl_showTextBadge:(NSString *)value {
    if (![self cyl_isReady]) {
        return;
    }
    if (value == 0 || !value ||value.length == 0) {
        [self.cyl_badge cyl_setHidden:YES];

        return;
    }
    [self cyl_badgeInit];
    self.cyl_badge.tag = CYLBadgeStyleOther;
    self.cyl_badge.text = value;
    self.cyl_badge.font = self.cyl_badgeFont;
    [self cyl_adjustLabelWidth:self.cyl_badge];
    [self cyl_addMargin];
    [self cyl_layoutBadgeAtTopRightCorner];
    //FIXME:  to delete
    self.cyl_badge.layer.cornerRadius = (self.cyl_badgeCornerRadius !=0 ) ? self.cyl_badgeCornerRadius : CGRectGetHeight(self.cyl_badge.frame) / 2;
    [self.cyl_badge cyl_setHidden:NO];
}

- (void)cyl_showNumberBadgeWithValue:(NSInteger)value {
    if (![self cyl_badgeClass]) {
        return;
    }
    if (value <= 0) {
        [self.cyl_badge cyl_setHidden:YES];
        return;
    }
    [self cyl_badgeInit];
    [self.cyl_badge cyl_setHidden:(value == 0)];
    self.cyl_badge.tag = CYLBadgeStyleNumber;
    NSString *text = (value > self.cyl_badgeMaximumBadgeNumber ?
                      [NSString stringWithFormat:@"%@+", @(self.cyl_badgeMaximumBadgeNumber)] :
                      [NSString stringWithFormat:@"%@", @(value)]);
    [self cyl_showTextBadge:text];
}

//lazy loading
- (void)cyl_badgeInit {
    if (![self cyl_isReady]) {
        return;
    }
    if (self.cyl_badgeBackgroundColor == nil) {
        self.cyl_badgeBackgroundColor = [UIColor redColor];
    }
    if (self.cyl_badgeTextColor == nil) {
        self.cyl_badgeTextColor = [UIColor whiteColor];
    }
    
    if (!self.cyl_badge) {
        if (![self cyl_isReady]) {
            return;
        }
        Class class = [self cyl_badgeClass];
        self.cyl_badge = [[class alloc] initWithFrame:(self.frame)];
//        self.cyl_badge = [[class alloc] init];

        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.textAlignment = NSTextAlignmentCenter;
        self.cyl_badge.textColor = self.cyl_badgeTextColor;
        self.cyl_badge.text = @"";
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
        self.cyl_badge.layer.masksToBounds = YES;//very important
        [self.cyl_badge cyl_setHidden:YES];
        
        self.cyl_badge.backgroundColor = self.cyl_badgeBackgroundColor;
        
        [self cyl_bringBadgeToFront:self.cyl_badge];
    }
}

- (void)cyl_bringBadgeToFront:(UIView *)view {
    if (![self cyl_isReady]) {
        return;
    }
    [self addSubview:view];
    [self bringSubviewToFront:view];
    view.layer.zPosition = MAXFLOAT;
    __weak __typeof(self) weakSelf = self;
    void (^CYLTabBarItemLottieAnimationPlayingNotificationBlock)(NSNotification *) = ^(NSNotification *notification) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
             return;
        }
//        [self cyl_setBadge:nil];
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
//             [[[self cyl_badge] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
//             if ([self cyl_shouldUpdateBadgeSubviews]) {
//                 [[self cyl_badge] removeFromSuperview];
//                 id view = nil;
//                 [self cyl_setBadge:view];
//             }
             );
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarStyleTypeDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:CYLTabBarItemLottieAnimationPlayingNotificationBlock];
//    [self cyl_setBadge:view];

}

- (void)cyl_resetRedDotBadgeFrame {
    CGFloat redotWidth = kCYLBadgeDefaultRedDotRadius *2;
    if (self.cyl_badgeRadius) {
        redotWidth = self.cyl_badgeRadius * 2;
    }
    if (!self.cyl_badge) {
        return;
    }
    CGRect frame = CGRectMake(CGRectGetWidth(self.bounds), -redotWidth, redotWidth, redotWidth);
    self.cyl_badge.frame = frame;
    //更新frame
    [self.cyl_badge layoutIfNeeded];
    [self cyl_layoutBadgeAtTopRightCorner];
    self.cyl_badge.layer.masksToBounds = YES;//very important
    
}

/*!
 * [EN] Centers the badge on the host's top-right corner (plus `cyl_badgeCenterOffset`) and keeps it there: the flexible
 *      left and bottom margins move it with the right edge when the host is resized later, by Auto Layout too (the
 *      mask is turned into constraints). `bounds`, not `frame`: a transform on the host (e.g. a tab image animation)
 *      must not move the badge.
 * [CN] 将角标中心放在宿主右上角（加上 `cyl_badgeCenterOffset`），并保持在那里：左边距和下边距可变，宿主之后尺寸改变时
 *      （包括自动布局，mask 会转换为约束）角标随右边缘移动。使用 `bounds` 而不是 `frame`：宿主上的 transform
 *      （如 Tab 图片动画）不应移动角标。
 */
- (void)cyl_layoutBadgeAtTopRightCorner {
    UIView *badge = self.cyl_badge;
    if (!badge) {
        return;
    }
    badge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGPoint badgeCenterOffset = self.cyl_badgeCenterOffset;
    badge.center = CGPointMake(CGRectGetWidth(self.bounds) + 2 + badgeCenterOffset.x, badgeCenterOffset.y);
}

#pragma mark --  other private methods
- (void)cyl_adjustLabelWidth:(UIView<CYLBadgeTextDisplaying> *)badgeSuperView {
    if (!badgeSuperView) {
        return;
    }
    //获得子视图的Label以获得字符长度。用以拉伸父视图
    //UILabel 与 CYLTabBarBadgeView 没有继承关系，各自检查类型后再向下转换（两者都是 UIView 的子类）。
    UILabel *label = nil;
    if ([badgeSuperView isKindOfClass:[UILabel class]]) {
        label = (UILabel *)badgeSuperView;
    } else if ([badgeSuperView isKindOfClass:[CYLTabBarBadgeView class]]) {
        label = ((CYLTabBarBadgeView *)badgeSuperView).badgeLabel;
    }
    if (!label.text || 0 == label.text.length) {
        return;
    }
    CGSize labelsize = [self cyl_getLabelSize:label];
    if (CGSizeEqualToSize(CGSizeZero, labelsize)) {
        return;
    }
//    CGSize labelsize = [self sizeThatFits:CGSizeMake(CYLScreenWidth() ,CYLScreenHeight())];
    CGRect frame = label.frame;
    frame.size = CGSizeMake(ceilf(labelsize.width), ceilf(labelsize.height));
//    获得字符长度后， 需要修改父视图的宽度， 仅仅修改Label无法达到真正的拉伸效果
        [label setFrame:frame];

    [badgeSuperView setFrame:frame];

}

- (CGSize)cyl_getLabelSize:(UILabel *)label {
    [label setNumberOfLines:0];
    NSString *s = label.text;
    UIFont *font = label.font;
    CGSize size = CGSizeMake(CYLScreenWidth() ,CYLScreenHeight());
    CGSize labelsize;
    
    if (![s respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        
        CYL_DEPRECATED_DECLARATIONS_PUSH
        labelsize = [s sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
        CYL_DEPRECATED_DECLARATIONS_POP
    } else {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByWordWrapping];
        
        labelsize = [s boundingRectWithSize:size
                                    options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                 attributes:@{ NSFontAttributeName:font, NSParagraphStyleAttributeName : style}
                                    context:nil].size;
    }
    return labelsize;
}

#pragma mark -- animation

/*!
 * FIX: issue #583, #271
 * [EN] The badge's Shake and Bounce animations (`+cyl_shake_AnimationRepeatTimes:…`, `+cyl_bounce_AnimationRepeatTimes:…`)
 *      kept the default `removedOnCompletion = YES`, unlike Breathe and Scale. Core Animation removes such animations when
 *      the app goes to the background, so after returning a badge with text stopped shaking/bouncing. Keep them. Set here,
 *      not in those public factories, so apps that use the factories themselves see no change.
 *      Scope: every badge, whatever the tab bar style (classic, iOS 26 UI compatibility mode, Liquid Glass on iOS 26+ and
 *      the iPhone Duo, FlatDesign): they all share this code, and the problem does not depend on the style. No style check
 *      on purpose: looking up the tab bar controller from a badge finds the root one, which can be the wrong one with
 *      nested tab bar controllers.
 * [CN] 角标的 Shake、Bounce 动画（`+cyl_shake_AnimationRepeatTimes:…`、`+cyl_bounce_AnimationRepeatTimes:…`）与 Breathe、Scale 不同，
 *      保留了默认的 `removedOnCompletion = YES`。App 进入后台时 Core Animation 会移除这类动画，回到前台后带文字的角标不再抖动/弹跳。
 *      这里将其保留。在此处设置而不修改这两个公开的工厂方法，App 自行使用这些方法时行为不变。
 *      范围：所有角标，与 TabBar 样式无关（经典、iOS 26 UI 兼容模式、iOS 26+ 液态玻璃与 iPhone Duo、扁平样式）：它们共用这段代码，
 *      且该问题与样式无关。有意不判断样式：从角标查找 TabBarController 会找到根控制器，嵌套 TabBarController 时可能找错。
 */
- (void)cyl_keepBadgeAnimationAfterBackground:(CAAnimation *)animation {
    animation.removedOnCompletion = NO;
}

//if u want to add badge animation type, follow steps bellow:
//1. go to definition of CYLBadgeAnimationType and add new type
//2. go to category of CAAnimation+CYLBadgeExtention to add new animation interface
//3. call that new interface here
- (void)cyl_beginAnimation {
    CGFloat moveDistance = self.cyl_badge.frame.size.width * 1.5;
    if (!self.cyl_badge) {
        return;
    }
    switch(self.cyl_badgeAnimationType) {
        case CYLBadgeAnimationTypeBreathe:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_opacityForever_Animation:1.4]
                                        forKey:CYLBadgeBreatheAnimationKey];
            break;
        case CYLBadgeAnimationTypeShake: {
            CAAnimation *animation = [CAAnimation cyl_shake_AnimationRepeatTimes:CGFLOAT_MAX
                                                                        durTimes:1
                                                                          forObj:self.cyl_badge.layer];
            [self cyl_keepBadgeAnimationAfterBackground:animation];
            [self.cyl_badge.layer addAnimation:animation forKey:CYLBadgeShakeAnimationKey];
            break;
        }
        case CYLBadgeAnimationTypeScale:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_scaleFrom:1.4
                                                                  toScale:0.6
                                                                 durTimes:1
                                                                      rep:MAXFLOAT]
                                        forKey:CYLBadgeScaleAnimationKey];
            break;
        case CYLBadgeAnimationTypeBounce: {
            CAAnimation *animation = [CAAnimation cyl_bounce_AnimationRepeatTimes:CGFLOAT_MAX
                                                                         durTimes:1
                                                                           forObj:self.cyl_badge.layer];
            [self cyl_keepBadgeAnimationAfterBackground:animation];
            [self.cyl_badge.layer addAnimation:animation forKey:CYLBadgeBounceAnimationKey];
            break;
        }
            
            
            /*!
             *
             
             
             
             
             
             
             
             
             */
        case CYLBadgeAnimationTypeLeftRightOnce:        /* left to right animation*/
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_leftRight_AnimationMoveDistance:moveDistance
                                                             repeatTimes:1
                                                                durTimes:0.5]
                                        forKey:CYLBadgeLeftRightOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeRightLeftOnce:        /* right to left animation*/
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_rightLeft_AnimationMoveDistance:moveDistance
                                                             repeatTimes:1
                                                                durTimes:0.5]
                                        forKey:CYLBadgeRightLeftOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeFadeInOnce:           /* fade in animation */
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_fadeIn_AnimationRepeatTimes:1
                                                            durTimes:1.5]
                                        forKey:CYLBadgeFadeInOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeRollingOnce:           /*rolling animation*/
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_rolling_AnimationRepeatTimes:1
                                                             durTimes:0.5]
                                        forKey:CYLBadgeRollingOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeScaleOnce:           /*ScaleOnce animation*/
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_scale_AnimationRepeatTimes:1
                                                           durTimes:0.5]
                                        forKey:CYLBadgeScaleOnceAnimationKey];
            
            
            break;
            
            
            
        case CYLBadgeAnimationTypeNone:
        default:
            
            break;
    }
}


- (void)cyl_removeAnimation {
    if (self.cyl_badge) {
        [self.cyl_badge.layer removeAllAnimations];
    }
}

#pragma mark -- setter/getter

- (UIView<CYLBadgeTextDisplaying> *)cyl_badge {
    return objc_getAssociatedObject(self, @selector(cyl_badge));
}

- (void)cyl_setBadge:(UIView<CYLBadgeTextDisplaying> *)label {
    objc_setAssociatedObject(self, @selector(cyl_badge), label, OBJC_ASSOCIATION_RETAIN);
}

- (UIFont *)cyl_badgeFont {
    id font = objc_getAssociatedObject(self, @selector(cyl_badgeFont));
    return font ?: kCYLBadgeDefaultFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    objc_setAssociatedObject(self, @selector(cyl_badgeFont), badgeFont, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.font = badgeFont;
}

- (UIColor *)cyl_badgeBackgroundColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeBackgroundColor));
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBackgroundColor), badgeBackgroundColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.backgroundColor = badgeBackgroundColor;
}

- (UIColor *)cyl_badgeTextColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeTextColor));
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeTextColor), badgeTextColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.textColor = badgeTextColor;
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeAnimationType));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return CYLBadgeAnimationTypeNone;
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    NSNumber *numObj = @(animationType);
    objc_setAssociatedObject(self, @selector(cyl_badgeAnimationType), numObj, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    [self cyl_removeAnimation];
    [self cyl_beginAnimation];
}

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
}
- (NSNumber *)cyl_badgeAnimationTypeValue {
    return @([self cyl_badgeAnimationType]);
}

- (CGRect)cyl_badgeFrame {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeFrame));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 4) {
        CGFloat x = [obj[@"x"] floatValue];
        CGFloat y = [obj[@"y"] floatValue];
        CGFloat width = [obj[@"width"] floatValue];
        CGFloat height = [obj[@"height"] floatValue];
        return  CGRectMake(x, y, width, height);
    }
    return CGRectZero;
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (NSValue *)cyl_badgeFrameValue {
    return [NSValue valueWithCGRect:[self cyl_badgeFrame]];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    NSDictionary *frameInfo = @{@"x" : @(badgeFrame.origin.x), @"y" : @(badgeFrame.origin.y),
                                @"width" : @(badgeFrame.size.width), @"height" : @(badgeFrame.size.height)};
    objc_setAssociatedObject(self, @selector(cyl_badgeFrame), frameInfo, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.frame = badgeFrame;
}

- (CGFloat)cyl_badgeCornerRadius {
    NSNumber *badgeCornerRadiusObject = objc_getAssociatedObject(self, @selector(cyl_badgeCornerRadius));
    return [badgeCornerRadiusObject floatValue];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)badgeCornerRadius {
    NSNumber *badgeCornerRadiusObject = @(badgeCornerRadius);
    objc_setAssociatedObject(self, @selector(cyl_badgeCornerRadius), badgeCornerRadiusObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue floatValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}
- (NSNumber *)cyl_badgeCornerRadiusValue {
    return @([self cyl_badgeCornerRadius]);
}

- (CGPoint)cyl_badgeCenterOffset {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeCenterOffset));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 2) {
        CGFloat x = [obj[@"x"] floatValue];
        CGFloat y = [obj[@"y"] floatValue];
        return CGPointMake(x, y);
    }
    return CGPointZero;
}

- (void)cyl_setBadgeCenterOffsetValue:(NSValue *)badgeCenterOffsetValue {
    //    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
    CGPoint badgeCenterOffset = badgeCenterOffsetValue.CGPointValue;
    [self cyl_setBadgeCenterOffset:badgeCenterOffset];
}

- (NSValue *)cyl_badgeCenterOffsetValue {
    return [NSValue valueWithCGPoint:[self cyl_badgeCenterOffset]];
}

//FIXME:  to delete ios27_ bug
- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOff {
    NSDictionary *cenerInfo = @{@"x" : @(badgeCenterOff.x), @"y" : @(badgeCenterOff.y)};
    objc_setAssociatedObject(self, @selector(cyl_badgeCenterOffset), cenerInfo, OBJC_ASSOCIATION_RETAIN);
    if ([self cyl_shouldUpdateBadgeSubviews]) {
        return;
    }
    //FIXME:  to delete 如果在这里提前初始化， 那么就会导致
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    [self cyl_layoutBadgeAtTopRightCorner];
 }

//badgeRadiusKey

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    objc_setAssociatedObject(self, @selector(cyl_badgeRadius), [NSNumber numberWithFloat:badgeRadius], OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue floatValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (NSNumber *)cyl_badgeRadiusValue {
    return @([self cyl_badgeRadius]);
}

- (CGFloat)cyl_badgeRadius {
    return [objc_getAssociatedObject(self, @selector(cyl_badgeRadius)) floatValue];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    objc_setAssociatedObject(self, @selector(cyl_badgeMargin), [NSNumber numberWithFloat:badgeMargin], OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue floatValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (NSNumber *)cyl_badgeMarginValue {
    return @([self cyl_badgeMargin]);
}

- (CGFloat)cyl_badgeMargin {
    id margin = objc_getAssociatedObject(self, @selector(cyl_badgeMargin));
    return margin == nil ? kCYLBadgeDefaultMargin : [margin floatValue];
}

- (NSInteger)cyl_badgeMaximumBadgeNumber {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return kCYLBadgeDefaultMaximumBadgeNumber;
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    NSNumber *numObj = @(badgeMaximumBadgeNumber);
    objc_setAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber), numObj, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    return @([self cyl_badgeMaximumBadgeNumber]);
}

- (CGFloat)cyl_delayIfNeededForSeconds {
    NSNumber *delayIfNeededForSecondsObject = objc_getAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds));
    if (!delayIfNeededForSecondsObject) {
        return kCYLBadgeDefaultDelayIfNeededForSeconds;
    }
    return [delayIfNeededForSecondsObject floatValue];
}

- (void)cyl_setDelayIfNeededForSeconds:(CGFloat)delayIfNeededForSeconds {
    NSNumber *delayIfNeededForSecondsObject = @(delayIfNeededForSeconds);
    objc_setAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds), delayIfNeededForSecondsObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_isHidden {
    return self.cyl_isInvisiable;
}

- (BOOL)cyl_isInvisiable {
    BOOL isSizeZero = CGSizeEqualToSize(CGSizeZero, self.frame.size);
    //这里删除(NO == obj.opaque) ，因为iOS27以上的视图，渲染会通过通过 opaque 设置为 NO 进行，所以这里删除涉及关于 opaque 的判断。
    BOOL isInvisible = (YES == self.hidden ) || (self.alpha <= 0.01f)  || (!self.superview) || isSizeZero;
    return isInvisible;
}

- (BOOL)cyl_canNotResponseEvent {
    return self.cyl_isInvisiable || (NO == self.userInteractionEnabled ) || self.cyl_isPlaceholder;
}

// 不管 image 还是 text 的 UIBarButtonItem 都获取内部的 _UIModernBarButton 即可
- (UIView *)cyl_findBarButtonContentView {
    NSString *classString = NSStringFromClass(self.class);
    if ([classString isEqualToString:@"UITabBarButton"] || [classString isEqualToString:@"_UITabButton"]) {
        // 特别的，对于 UITabBarItem，将 imageView 作为参考 view
        UIView *imageView = [self cyl_tabImageView];
        return imageView;
    }
    
    if ([classString isEqualToString:@"_UIButtonBarButton"]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:UIButton.class]) {
                return subview;
            }
        }
    }
    
    return self;
}

- (Class)cyl_badgeClass {
    //    return [UILabel class];

    //    return [CYLTabBarBadgeView class];
    Class badgeClass = nil;
    if (!CYL_IS_IOS_27) {
        return [UILabel class];
    }
    BOOL isCYLTabBarStyleTypeLiquidGlass = [self cyl_isCYLTabBarStyleTypeLiquidGlass];
    
    
     
    if (isCYLTabBarStyleTypeLiquidGlass) {
        badgeClass = [CYLTabBarBadgeView class];
    } else {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        badgeClass = [UILabel class];
#endif
    }
    return badgeClass;
}

- (BOOL)cyl_isCYLTabBarStyleTypeLiquidGlass {
    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    return YES;
}

- (BOOL)cyl_shouldUpdateBadgeSubviews {
    
//    return YES;

    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    if (CYL_IS_IOS_27 && ![self.cyl_badge isKindOfClass:[UILabel class]]) {
        return YES;
    }
    return YES;
}

@end

