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

/// The icon a control's badge sits on: its Lottie view, else its tab image view, when visible. 角标所在的图标：Lottie 视图或 Tab 图片视图。
static UIView *CYLBadgeIconViewOfControl(UIControl *control) {
    UIView *lottieAnimationView = (UIView *)control.cyl_lottieAnimationView;
    if (lottieAnimationView && !lottieAnimationView.cyl_isInvisiable) {
        return lottieAnimationView;
    }
    UIImageView *tabImageView = [control cyl_tabImageView];
    if (tabImageView && !tabImageView.cyl_isInvisiable) {
        return tabImageView;
    }
    return nil;
}

/*!
 * [EN] The outermost view from `view` up that clips (clipsToBounds, masksToBounds or a mask), inside the tab bar
 *      (UITabBar or CYLFlatDesignTabBar) that holds `view`: the badge may leave the views of its tab bar, never the tab bar
 *      itself, so it still moves and hides with it. With Liquid Glass this is the platter (`cyl_platterView`). Outside a
 *      tab bar only `view` itself counts, so a button elsewhere (e.g. in a sheet that animates) keeps its anchor close.
 * [CN] 从 `view` 向上、在包含它的 TabBar（UITabBar 或 CYLFlatDesignTabBar）之内最外层会裁剪（clipsToBounds、masksToBounds 或 mask）
 *      的视图：角标可以离开 TabBar 内部的视图，但不会离开 TabBar 本身，因此仍随 TabBar 移动、隐藏。液态玻璃下即 platter
 *      （`cyl_platterView`）。不在 TabBar 中时只考虑 `view` 本身，其他位置的按钮（例如位于带动画的 sheet 中）锚点不会离得太远。
 */
static UIView *CYLBadgeOutermostClippingView(UIView *view) {
    Class flatDesignTabBarClass = NSClassFromString(@"CYLFlatDesignTabBar");
    BOOL viewClips = view.clipsToBounds || view.layer.masksToBounds || view.layer.mask;
    UIView *clippingView = nil;
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if ([ancestor isKindOfClass:[UITabBar class]] || (flatDesignTabBarClass && [ancestor isKindOfClass:flatDesignTabBarClass])) {
            return clippingView;    // inside a tab bar 位于 TabBar 中
        }
        if ([ancestor isKindOfClass:[UIScrollView class]] || [ancestor isKindOfClass:[UIWindow class]]) {
            break;
        }
        if (ancestor.clipsToBounds || ancestor.layer.masksToBounds || ancestor.layer.mask) {
            clippingView = ancestor;
        }
    }
    return viewClips ? view : nil;
}

@implementation UIControl (CYLBadgeExtention) 

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    CYL_DEPRECATED_DECLARATIONS_PUSH
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     // 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
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
    [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:value animationType:animationType];
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
    [CYL_ACTUAL_BARBUTTON cyl_clearBadge];
}

- (void)cyl_resumeBadge {
    [CYL_ACTUAL_BARBUTTON cyl_resumeBadge];
}

- (void)cyl_refreshBadge {
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
    UIView *actualBadgeSuperView = CYLBadgeIconViewOfControl(tabButton);
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
         *      top-right corner as before. When the control or, inside a tab bar, a view above it clips (clipsToBounds,
         *      masksToBounds or a mask), the anchor goes right above the outermost such view instead, so the clipping
         *      does not cut the badge (see `-cyl_badgeAnchorViewAlignedToView:`).
         * [CN] 非 Tab 按钮的控件（PlusButton、任意 UIButton）的角标原先放在其图标视图中。该视图可能位于控件其他内容之下：使用
         *      configuration 的 UIButton 会在找到的第一个图片视图之上绘制图片，因此 PlusButton 的「+」遮住了大部分角标；原逻辑还会
         *      修改图标的 `clipsToBounds`。现在角标放在一个透明的锚点视图上，它是控件最上层的子视图（zPosition 为 MAXFLOAT，控件之后
         *      添加的内容也位于其下），与图标对齐，没有图标时与整个控件对齐：角标总是绘制在控件所有内容之上，位置仍在图标右上角。
         *      控件本身或（位于 TabBar 中时）其上层视图会裁剪（clipsToBounds、masksToBounds 或 mask）时，锚点改为紧贴最外层的
         *      这类视图之上，角标不再被裁剪（见 `-cyl_badgeAnchorViewAlignedToView:`）。
         */
        return [tabButton cyl_badgeAnchorViewAlignedToView:actualBadgeSuperView];
    }
    UIView *clippingView = actualBadgeSuperView ? CYLBadgeOutermostClippingView(tabButton) : nil;
    if (clippingView.superview) {
        /*!
         * FIX: tab badges cut by the Liquid Glass platter
         * [EN] With Liquid Glass the tab buttons are inside the platter (`cyl_platterView`), which clips them to its capsule,
         *      so a badge near its edge was cut, e.g. "NEW" on the last tab of the vertical bar on the iPhone Duo. The badge
         *      now goes on an anchor right above the platter in its superview, aligned to the icon; it follows the
         *      visibility of the tab button and of the views up to the platter. Both copies of a tab (the normal one and
         *      the platter's selected copy, which the badge methods are mirrored to) use the normal tab button's anchor,
         *      so the tab shows one badge. Tab bars without a clipping view keep the badge on the icon.
         * [CN] 液态玻璃下 Tab 按钮位于 platter（`cyl_platterView`）中，platter 会把内容裁剪为胶囊形，因此靠近边缘的角标会被裁掉，例如
         *      iPhone Duo 竖向栏最后一个 Tab 的 "NEW"。现在角标放在 platter 父视图中、紧贴 platter 之上的锚点视图上，与图标对齐，并跟随
         *      Tab 按钮及其到 platter 之间各视图的可见性。同一个 Tab 的两份副本（普通副本，以及角标方法同步到的 platter 选中副本）共用普通
         *      Tab 按钮的锚点视图，因此每个 Tab 只显示一个角标。没有裁剪视图的 TabBar 仍把角标放在图标上。
         */
        UIControl *owner = tabButton;
        if ([tabButton cyl_isPlatterSelectedControl] && tabButton.cyl_platterNormalControl) {
            owner = tabButton.cyl_platterNormalControl;
        }
        UIView *ownerIcon = owner == tabButton ? actualBadgeSuperView : (CYLBadgeIconViewOfControl(owner) ?: actualBadgeSuperView);
        return [owner cyl_badgeAnchorViewAlignedToView:ownerIcon];
    }
    if (actualBadgeSuperView) {
        [actualBadgeSuperView setClipsToBounds:NO];
        //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
        [actualBadgeSuperView layoutIfNeeded];//建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame
    }

    return actualBadgeSuperView;
}

/*!
 * [EN] The transparent view that holds a control's badge, aligned to `referenceView` (the icon) or to the whole control.
 *      It is the control's top-most subview; when the control or a view above it clips (up to the tab bar, see
 *      `CYLBadgeOutermostClippingView`), it sits right above the outermost such view instead and follows the visibility of
 *      the views from the control up to it.
 * [CN] 承载控件角标的透明视图，与 `referenceView`（图标）或整个控件对齐。它是控件最上层的子视图；控件或其上层视图会裁剪时（最多到
 *      TabBar，见 `CYLBadgeOutermostClippingView`），改为紧贴最外层的这类视图之上，并跟随从控件到该视图之间各视图的可见性。
 */
- (UIView *)cyl_badgeAnchorViewAlignedToView:(UIView *)referenceView {
    CYLBadgeHostOverlayView *anchorView = objc_getAssociatedObject(self, @selector(cyl_badgeAnchorViewAlignedToView:));
    if (!anchorView) {
        anchorView = [[CYLBadgeHostOverlayView alloc] initWithFrame:self.bounds];
        // It can live outside the control, so it goes away with the control. 它可能位于控件之外，因此随控件一起移除。
        [anchorView cyl_removeWhenDeallocated:self];
        objc_setAssociatedObject(self, @selector(cyl_badgeAnchorViewAlignedToView:), anchorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *alignView = (referenceView && referenceView != anchorView) ? referenceView : self;
    UIView *clippingView = CYLBadgeOutermostClippingView(self);
    UIView *clippingContainer = clippingView.superview;
    if (clippingContainer) {
        NSMutableArray<UIView *> *views = [NSMutableArray array];
        for (UIView *view = self; view; view = view.superview) {
            [views addObject:view];
            if (view == clippingView) {
                break;
            }
        }
        [anchorView cyl_attachToContainer:clippingContainer aboveSubview:clippingView alignedToView:alignView followingVisibilityOfViews:views];
    } else {
        [anchorView cyl_attachToContainer:self aboveSubview:nil alignedToView:alignView followingVisibilityOfViews:@[]];
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
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    if (![self isKindOfClass:[UIControl class]] || ![CYLUtils isLiquidGlassActive]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [self performSelector:aSelector withObject:object1 withObject:object2];
         )
        return;
    }
    if ([self cyl_isPlatterSelectedControl]) {
        selectedControl = self;
    } else {
        normalControl = self;
    }
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     if (normalControl) {
         [normalControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = normalControl.cyl_platterSelectedControl;
         if (counterpart) {
             [counterpart performSelector:aSelector withObject:object1 withObject:object2];
         }
     } else if (selectedControl) {
         [selectedControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = selectedControl.cyl_platterNormalControl;
         if (counterpart) {
             [counterpart performSelector:aSelector withObject:object1 withObject:object2];
         }
     }
     );
}
 
- (BOOL)cyl_isReady {
    if (![CYLUtils isLiquidGlassActive]) {
        return YES;
    }
    //由于 SelectedControl 所在图层的渲染比未选中图层有延迟， 所以必须加延迟，如果不加延迟，可能无法获取到正确的子视图， 有概率获取的子视图为nil
    //由于有几率无法获取到cyl_tabImageView， 只有延迟获取，才能避免获取为空nil。
    
    UIView *view = self.cyl_platterSelectedControl.cyl_tabImageView;
    if (!view) {
        return NO;
    }
    BOOL isTabImageViewReady = self.cyl_tabImageView.frame.size.width > 10 || self.cyl_tabLabel.frame.size.width > 10;
    BOOL isLottieReady = YES;
    if (self.cyl_tabBarController.lottieURLs.count > 0) {
        isLottieReady = self.cyl_isLottieReady;
    }
    return isTabImageViewReady && isLottieReady;
}

#pragma mark -- setter/getter
- (UIView<CYLBadgeTextDisplaying> *)cyl_badge {
    return CYL_ACTUAL_BARBUTTON.cyl_badge;
}

- (void)cyl_setBadge:(UIView<CYLBadgeTextDisplaying> *)label {
    [CYL_ACTUAL_BARBUTTON cyl_setBadge:label];
}

- (UIFont *)cyl_badgeFont {
    return CYL_ACTUAL_BARBUTTON.cyl_badgeFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeFont:badgeFont];
}

- (UIColor *)cyl_badgeBackgroundColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBackgroundColor];
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeBackgroundColor:badgeBackgroundColor];
}

- (UIColor *)cyl_badgeTextColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeTextColor];
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeTextColor:badgeTextColor];
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeAnimationType];
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeAnimationType:animationType];
}

// The badge lives on the actual badge super view (tab image / Lottie view), like the properties above.
- (UIColor *)cyl_badgeBorderColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBorderColor];
}

- (void)cyl_setBadgeBorderColor:(UIColor *)badgeBorderColor {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeBorderColor:badgeBorderColor];
}

- (CGFloat)cyl_badgeBorderWidth {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBorderWidth];
}

- (void)cyl_setBadgeBorderWidth:(CGFloat)badgeBorderWidth {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeBorderWidth:badgeBorderWidth];
}

- (BOOL)cyl_badgeRespectsReduceMotion {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRespectsReduceMotion];
}

- (void)cyl_setBadgeRespectsReduceMotion:(BOOL)badgeRespectsReduceMotion {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeRespectsReduceMotion:badgeRespectsReduceMotion];
}

- (CGRect)cyl_badgeFrame {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeFrame:badgeFrame];
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
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
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeMargin:badgeMargin];
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue doubleValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeRadius:badgeRadius];
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue doubleValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (CGFloat)cyl_badgeCornerRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)cyl_badgeCornerRadius {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue doubleValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

@end

#endif /* CYL_BADGE_CORE_AVAILABLE */
