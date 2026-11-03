/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIBarButtonItem+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "UIControl+CYLBadgeExtention.h"
#import "CYLBadgeAppearance.h"
// FIX: issue #535 — no Core header needed; see CYLBadgeViewDefines.h. 不再依赖 Core 头文件，见 CYLBadgeViewDefines.h。
#import "CYLBadgeViewDefines.h"

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView

/*!
 * FIX: badge colors of bar button items on iOS 26+ (Liquid Glass)
 * [EN] On iOS 26+ the content of a bar button item (`_UIModernBarButton`, with
 *      `_enableMonochromaticTreatmentOnImageAndTitle`) is drawn monochrome in the bar's tint, and colors drawn by layers
 *      inside it are lost (Apple Developer Forums 794886, 795908; "Liquid Glass – A Field Guide to UIKit Compatibility
 *      Pitfalls"). The library's badge sits inside that content, so `cyl_badgeBackgroundColor` (e.g. a random color)
 *      was replaced by the tint: a black dot on a light bar.
 *      With Liquid Glass active, the badge of a `UIBarButtonItem` is now the system badge (`UIBarButtonItemBadge`,
 *      iOS 26), whose colors UIKit keeps: background `cyl_badgeBackgroundColor`, text `cyl_badgeTextColor`, font
 *      `cyl_badgeFont` (default: `CYLBadgeAppearance`). The value works as before: "" a dot, a number (capped at
 *      `cyl_badgeMaximumBadgeNumber`, e.g. "99+"), "new"/"NEW" localized, any other text. The animation type is applied
 *      to the system badge view when it can be found in the bar. `item.badge` is a copy, so the badge is configured
 *      first and then assigned. Before iOS 26, and with `UIDesignRequiresCompatibility`, nothing changes.
 * [CN] iOS 26+ 上 bar button item 的内容（`_UIModernBarButton`，`_enableMonochromaticTreatmentOnImageAndTitle`）会按导航栏的
 *      tint 以单色绘制，其中由 layer 绘制的颜色会丢失（Apple 开发者论坛 794886、795908；《Liquid Glass – A Field Guide to UIKit
 *      Compatibility Pitfalls》）。本库的角标位于该内容中，因此 `cyl_badgeBackgroundColor`（例如随机色）被 tint 替换：浅色导航栏上
 *      显示为黑点。
 *      现在液态玻璃生效时，`UIBarButtonItem` 的角标改用系统角标（iOS 26 的 `UIBarButtonItemBadge`），UIKit 会保留其颜色：背景色
 *      `cyl_badgeBackgroundColor`、文字颜色 `cyl_badgeTextColor`、字体 `cyl_badgeFont`（默认取 `CYLBadgeAppearance`）。取值规则不变：
 *      "" 为红点，数字（超过 `cyl_badgeMaximumBadgeNumber` 显示如 "99+"），"new"/"NEW" 按语言本地化，其他文字原样显示。能在导航栏中
 *      找到系统角标视图时，会为其添加动画。`item.badge` 返回的是副本，因此先设置好角标再赋值。iOS 26 以前以及设置了
 *      `UIDesignRequiresCompatibility` 时行为不变。
 */
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
#define CYL_SYSTEM_BAR_BUTTON_BADGE_SDK 1
#else
#define CYL_SYSTEM_BAR_BUTTON_BADGE_SDK 0
#endif

/*!
 * [EN] YES when bar button item badges are the system ones: iOS 26+ with Liquid Glass active. A plain function, not a
 *      method: it does not depend on the item, and it adds nothing to UIBarButtonItem besides `CYLBadgeProtocol`.
 * [CN] bar button item 的角标使用系统角标：iOS 26+ 且液态玻璃生效。使用函数而不是方法：与具体 item 无关，且除 `CYLBadgeProtocol`
 *      外不给 UIBarButtonItem 增加任何方法。
 */
static BOOL CYLBarButtonItemUsesSystemBadge(void) {
#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
    if (@available(iOS 26.0, *)) {
        return [CYLUtils isLiquidGlassActive];
    }
#endif
    return NO;
}

#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
/// The system badge for `value`, with the library's rules; nil hides it. 按本库规则生成的系统角标；nil 表示隐藏。
static UIBarButtonItemBadge *CYLSystemBarButtonBadge(NSString *value, NSInteger maximumBadgeNumber) API_AVAILABLE(ios(26.0)) {
    if (value.length == 0) {
        return [UIBarButtonItemBadge indicatorBadge];
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([value rangeOfCharacterFromSet:nonDigits].location == NSNotFound) {
        NSInteger number = value.integerValue;
        if (number <= 0) {
            return nil;
        }
        NSInteger maximum = MAX(1, maximumBadgeNumber);
        NSString *text = number > maximum ? [NSString stringWithFormat:@"%@+", @(maximum)] : [NSString stringWithFormat:@"%@", @(number)];
        return [UIBarButtonItemBadge badgeWithString:text];
    }
    if ([value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        return nil;
    }
    if ([value isEqualToString:@"new"] || [value isEqualToString:@"NEW"]) {
        value = CYLLocalizedString(value);
    }
    return [UIBarButtonItemBadge badgeWithString:value];
}

/// The system badge view inside `view` (a view whose class name has "Badge", not one of the library's). 系统角标视图。
static UIView *CYLSystemBadgeViewInView(UIView *view, CGRect itemFrameInWindow) {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass(subview.class);
        if ([className containsString:@"Badge"] && ![className hasPrefix:@"CYL"] && !subview.hidden) {
            CGRect frameInWindow = [subview convertRect:subview.bounds toView:nil];
            if (CGRectIsEmpty(itemFrameInWindow) || CGRectIntersectsRect(CGRectInset(frameInWindow, -8, -8), itemFrameInWindow)) {
                return subview;
            }
        }
        UIView *badgeView = CYLSystemBadgeViewInView(subview, itemFrameInWindow);
        if (badgeView) {
            return badgeView;
        }
    }
    return nil;
}

/// Applies `animationType` to the system badge view once the bar has laid it out. 导航栏布局出系统角标视图后为其添加动画。
static void CYLAnimateSystemBarButtonBadge(UIBarButtonItem *item, UIView *host, CYLBadgeAnimationType animationType) {
    if (animationType == CYLBadgeAnimationTypeNone) {
        return;
    }
    if (host.cyl_badgeRespectsReduceMotion && UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }
    __weak UIBarButtonItem *weakItem = item;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *itemView = weakItem.cyl_view;
        // The bar that holds the item; its badge may be outside the item's own view. item 所在的 bar；系统角标可能不在 item 自身的视图中。
        UIView *barView = itemView;
        while (barView.superview && ![barView isKindOfClass:[UINavigationBar class]] && ![barView isKindOfClass:[UIToolbar class]]) {
            barView = barView.superview;
        }
        [barView layoutIfNeeded];
        CGRect itemFrameInWindow = itemView ? [itemView convertRect:itemView.bounds toView:nil] : CGRectZero;
        UIView *badgeView = itemView ? CYLSystemBadgeViewInView(itemView, itemFrameInWindow) : nil;
        badgeView = badgeView ?: (barView ? CYLSystemBadgeViewInView(barView, itemFrameInWindow) : nil);
        if (!badgeView) {
            return;
        }
        for (NSString *key in CYLBadgeAllAnimationKeys()) {
            [badgeView.layer removeAnimationForKey:key];
        }
        CAAnimation *animation = CYLBadgeAnimationForType(animationType, badgeView.bounds.size);
        NSString *animationKey = CYLBadgeAnimationKeyForType(animationType);
        if (animation && animationKey) {
            [badgeView.layer addAnimation:animation forKey:animationKey];
        }
    });
}
#endif

@implementation UIBarButtonItem (CYLBadgeExtention)

#pragma mark -- public methods
- (BOOL)cyl_isReady {
    // The system badge (iOS 26+) needs no laid-out view, so nothing waits for it. 系统角标（iOS 26+）不依赖已布局的视图，无需等待。
    if (CYLBarButtonItemUsesSystemBadge()) {
        return YES;
    }
    UIView *view = [self cyl_getActualBadgeSuperView];
    if (view && [view isKindOfClass:[UIView class]]) {
        return view.frame.size.width > 10;
    }
    return [view cyl_findBarButtonContentView].frame.size.width > 10;
}
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
/*!
 * FIX: badge position with Auto Layout
 * [EN] `delaySeconds` was an `NSUInteger`, so the 0.5 s wait for a bar button that is not laid out yet became 0.
 * [CN] `delaySeconds` 原为 `NSUInteger`，尚未完成布局的 bar button 本应等待 0.5 秒，实际变成了 0 秒。
 */
- (void)cyl_showBadge {
    if (CYLBarButtonItemUsesSystemBadge()) {
        [self cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
        return;
    }
    if (@available(iOS 11.0, *)) {
        [self swizzling_willMoveToSuperview];
    }
    NSTimeInterval delaySeconds = self.cyl_isReady ? 0 : 0.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [CYL_ACTUAL_BARBUTTON cyl_showBadge];

    });
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType {
#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
    if (@available(iOS 26.0, *)) {
        if (CYLBarButtonItemUsesSystemBadge()) {
            UIView *host = CYL_ACTUAL_BARBUTTON;
            // The library's own badge would be drawn monochrome here, so it is not shown. 本库自己的角标在这里会被单色绘制，因此不显示。
            [host cyl_clearBadge];
            objc_setAssociatedObject(self, @selector(cyl_resumeBadge), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(self, @selector(cyl_badgeAnimationType), @(animationType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NSInteger maximumBadgeNumber = host ? host.cyl_badgeMaximumBadgeNumber : [CYLBadgeAppearance globalAppearance].maximumBadgeNumber;
            UIBarButtonItemBadge *badge = CYLSystemBarButtonBadge(value, maximumBadgeNumber);
            badge.backgroundColor = self.cyl_badgeBackgroundColor;
            badge.foregroundColor = self.cyl_badgeTextColor;
            badge.font = self.cyl_badgeFont;
            // `badge` is a copy: configure it first, then assign it. `badge` 为副本：先设置好再赋值。
            self.badge = badge;
            if (badge) {
                CYLAnimateSystemBarButtonBadge(self, host, animationType);
            }
            return;
        }
    }
#endif
    if (@available(iOS 11.0, *)) {
        [self swizzling_willMoveToSuperview];
    }
    NSTimeInterval delaySeconds = self.cyl_isReady ? 0 : 0.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:value animationType:animationType];
    });
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType
           backgroundColor:(UIColor *)backgroundColor {
    if (backgroundColor) {
        self.cyl_badgeBackgroundColor = backgroundColor;
    }
    [self cyl_showBadgeValue:value animationType:animationType];
}

- (void)cyl_clearBadge {
#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
    if (@available(iOS 26.0, *)) {
        if (self.badge) {
            // Kept for -cyl_resumeBadge. 保留，供 -cyl_resumeBadge 恢复。
            objc_setAssociatedObject(self, @selector(cyl_resumeBadge), self.badge, OBJC_ASSOCIATION_COPY_NONATOMIC);
            self.badge = nil;
        }
    }
#endif
    [CYL_ACTUAL_BARBUTTON cyl_clearBadge];
}

- (void)cyl_resumeBadge {
#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
    if (@available(iOS 26.0, *)) {
        UIBarButtonItemBadge *pausedBadge = objc_getAssociatedObject(self, @selector(cyl_resumeBadge));
        if (pausedBadge && !self.badge) {
            self.badge = pausedBadge;
            objc_setAssociatedObject(self, @selector(cyl_resumeBadge), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
            CYLAnimateSystemBarButtonBadge(self, CYL_ACTUAL_BARBUTTON, self.cyl_badgeAnimationType);
            return;
        }
    }
#endif
    [CYL_ACTUAL_BARBUTTON cyl_resumeBadge];
}

- (BOOL)cyl_isPauseBadge {
#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
    if (@available(iOS 26.0, *)) {
        if (!self.badge && objc_getAssociatedObject(self, @selector(cyl_resumeBadge))) {
            return YES;
        }
    }
#endif
    return [CYL_ACTUAL_BARBUTTON cyl_isPauseBadge];
}

- (BOOL)cyl_isShowBadge {
#if CYL_SYSTEM_BAR_BUTTON_BADGE_SDK
    if (@available(iOS 26.0, *)) {
        if (self.badge) {
            return YES;
        }
    }
#endif
    return [CYL_ACTUAL_BARBUTTON cyl_isShowBadge];
}

#pragma mark -- private method
/*!
 * [EN] Runs `block` with the view that shows the badge: now when the bar button is laid out, else after the same 0.5 s
 *      that `-cyl_showBadgeValue:animationType:` waits. A style set in `-viewDidLoad` (e.g. `cyl_badgeBackgroundColor`)
 *      was sent to a view that did not exist yet and was lost, while the badge itself still appeared later. Blocks
 *      queued with the same delay run in order, so a style set before showing the badge is applied before it shows.
 * [CN] 用显示角标的视图执行 `block`：bar button 已完成布局时立即执行，否则与 `-cyl_showBadgeValue:animationType:` 一样延迟 0.5 秒。
 *      以前在 `-viewDidLoad` 中设置的样式（如 `cyl_badgeBackgroundColor`）发给了尚不存在的视图而丢失，角标本身却会稍后显示。
 *      相同延迟的任务按顺序执行，因此在显示角标之前设置的样式会先生效。
 */
- (void)cyl_performWithBadgeSuperView:(void (^)(UIView *view))block {
    if (self.cyl_isReady) {
        block(CYL_ACTUAL_BARBUTTON);
        return;
    }
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) self = weakSelf;
        UIView *view = self ? (UIView *)[self cyl_getActualBadgeSuperView] : nil;
        if (view) {
            block(view);
        }
    });
}

/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
    This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *<_UIModernBarButton: 0x107721500>:
 in _UIModernBarButton:
     _guardAgainstDegenerateBaselineCalculation (BOOL): NO
     _shouldUseButtonPlatters (BOOL): NO
     _enableMonochromaticTreatmentOnImageAndTitle (BOOL): YES
     _usesTintColorCapsuleForSelection (BOOL): YES
     __additionalSelectionInsets (struct UIEdgeInsets): {0, 0, 0, 0}
     _selectionIndicatorViewFrame (struct CGRect): {{-12, -2}, {139, 36}}
 in UIButton:
     _externalFlatEdge (unsigned long): 0
     _but
 *  @return view
 */
- (UIView *)cyl_getActualBadgeSuperView {
    UIButton *barButtonContentView = (UIButton *)self.cyl_view.cyl_findBarButtonContentView;
    UIView *actualBadgeSuperView = barButtonContentView;

    // 不管 image 还是 text 的 UIBarButtonItem 都获取内部的 _UI+ModernBarButton 即可
    do {
        if (barButtonContentView.imageView && (barButtonContentView.imageView.frame.size.width > 10)) {
            actualBadgeSuperView = barButtonContentView.imageView;
            break;
        }
        if (barButtonContentView.titleLabel && (barButtonContentView.titleLabel.frame.size.width > 10)) {
            //cyl_isButtonLabel
            actualBadgeSuperView = barButtonContentView.titleLabel;
            break;
        }
        
    } while (false); // same as : 0, NO
    //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用 
    [actualBadgeSuperView layoutIfNeeded];//建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame
    return actualBadgeSuperView;//use KVC to hack actual view
}

- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object1 withObject:(nullable id)object2 {
    if (aSelector == NULL) { return; }
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [self performSelector:aSelector withObject:object1 withObject:object2];
     )
}

#pragma mark -- KVC bridge accessors required by CYLBadgeProtocol

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

/*!
 * [EN] `CYLBadgeProtocol` declares `cyl_delayIfNeededForSeconds` as a `CGFloat`. This returned an `NSNumber *`, so a
 *      caller going through the protocol read an object pointer as a floating-point number. Return the number itself.
 * [CN] `CYLBadgeProtocol` 将 `cyl_delayIfNeededForSeconds` 声明为 `CGFloat`，这里却返回 `NSNumber *`，
 *      通过协议调用时会把对象指针当作浮点数读取。现在直接返回数值。
 */
- (CGFloat)cyl_delayIfNeededForSeconds {
    // Mirror the logic used when delaying badge operations.
    // 0 if ready immediately, otherwise default to 0.5s.
    NSTimeInterval delaySeconds = self.cyl_isReady ? 0 : 0.5;
    return delaySeconds;
}

- (void)cyl_setDelayIfNeededForSeconds:(CGFloat)seconds {
    // Accept and ignore; delay is computed dynamically by cyl_isReady.
    // Provided to satisfy protocol/KVC expectations.
    (void)seconds;
}

/*!
 * [EN] Before, `cyl_delayIfNeededForSeconds` returned an `NSNumber *` from this class although the protocol declares a
 *      `CGFloat`. A caller that used the declared type read a pointer as a number; one that used `performSelector:` /
 *      KVC got the object. The declared type is the contract, so it returns the `CGFloat`. For an object, use this
 *      NSNumber accessor, which also works through `performSelector:` and KVC.
 * [CN] 原先这个类的 `cyl_delayIfNeededForSeconds` 返回 `NSNumber *`，而协议声明的是 `CGFloat`。按声明类型调用的代码会把指针当数字读取；
 *      用 `performSelector:` / KVC 的代码拿到的是对象。声明的类型才是约定，所以现在返回 `CGFloat`。需要对象时请用这个 NSNumber 访问器，
 *      它同样可用于 `performSelector:` 和 KVC。
 */
- (NSNumber *)cyl_delayIfNeededForSecondsValue {
    return @(self.cyl_delayIfNeededForSeconds);
}

- (void)cyl_setDelayIfNeededForSecondsValue:(NSNumber *)delayIfNeededForSecondsValue {
    [self cyl_setDelayIfNeededForSeconds:[delayIfNeededForSecondsValue doubleValue]];
}

#pragma mark -- setter/getter
- (UIView<CYLBadgeTextDisplaying> *)cyl_badge {
    return CYL_ACTUAL_BARBUTTON.cyl_badge;
}

- (void)cyl_setBadge:(UIView<CYLBadgeTextDisplaying> *)label {
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadge:label]; }];
}

- (UIFont *)cyl_badgeFont {
    // Remembered on the item too, for the system badge (iOS 26+) and before the bar button is laid out.
    // 同时保存在 item 上，供系统角标（iOS 26+）以及 bar button 尚未布局时使用。
    return objc_getAssociatedObject(self, @selector(cyl_badgeFont)) ?: (CYL_ACTUAL_BARBUTTON.cyl_badgeFont ?: [CYLBadgeAppearance globalAppearance].font);
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    objc_setAssociatedObject(self, @selector(cyl_badgeFont), badgeFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeFont:badgeFont]; }];
}

- (UIColor *)cyl_badgeBackgroundColor {
    // Remembered on the item too, for the system badge (iOS 26+) and before the bar button is laid out.
    // 同时保存在 item 上，供系统角标（iOS 26+）以及 bar button 尚未布局时使用。
    return objc_getAssociatedObject(self, @selector(cyl_badgeBackgroundColor)) ?: (CYL_ACTUAL_BARBUTTON.cyl_badgeBackgroundColor ?: [CYLBadgeAppearance globalAppearance].backgroundColor);
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBackgroundColor), badgeBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeBackgroundColor:badgeBackgroundColor]; }];
}

- (UIColor *)cyl_badgeTextColor {
    // Remembered on the item too, for the system badge (iOS 26+) and before the bar button is laid out.
    // 同时保存在 item 上，供系统角标（iOS 26+）以及 bar button 尚未布局时使用。
    return objc_getAssociatedObject(self, @selector(cyl_badgeTextColor)) ?: (CYL_ACTUAL_BARBUTTON.cyl_badgeTextColor ?: [CYLBadgeAppearance globalAppearance].textColor);
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeTextColor), badgeTextColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeTextColor:badgeTextColor]; }];
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    // The system badge (iOS 26+) has no view of the library to keep it in. 系统角标（iOS 26+）没有本库的视图来保存它。
    NSNumber *animationType = CYLBarButtonItemUsesSystemBadge() ? objc_getAssociatedObject(self, @selector(cyl_badgeAnimationType)) : nil;
    return animationType ? (CYLBadgeAnimationType)animationType.unsignedIntegerValue : [CYL_ACTUAL_BARBUTTON cyl_badgeAnimationType];
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    objc_setAssociatedObject(self, @selector(cyl_badgeAnimationType), @(animationType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeAnimationType:animationType]; }];
}

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
}

- (CGRect)cyl_badgeFrame {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeFrame:badgeFrame]; }];
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeCenterOffset:badgeCenterOffset]; }];
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
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber]; }];
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeMargin:badgeMargin]; }];
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue doubleValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeRadius:badgeRadius]; }];
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue doubleValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (CGFloat)cyl_badgeCornerRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)cyl_badgeCornerRadius {
    [self cyl_performWithBadgeSuperView:^(UIView *view) { [view cyl_setBadgeCornerRadius:cyl_badgeCornerRadius]; }];
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue doubleValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

/**
 Swizzling -[_UIButtonBarButton willMoveToSuperview:]
 */
- (void)swizzling_willMoveToSuperview __IOS_AVAILABLE(11.0) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(willMoveToSuperview:);
        SEL swizzledSelector = NSSelectorFromString(@"cyl_willMoveToSuperview:");
        Method originalMethod = class_getInstanceMethod(NSClassFromString(@"_UIButtonBarButton"), originalSelector);
        Method swizzledMethod = class_getInstanceMethod(super.class, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

@end
