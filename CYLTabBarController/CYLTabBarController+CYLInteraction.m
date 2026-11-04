//
//  CYLTabBarController+CYLInteraction.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController+CYLInteraction.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

/// [EN] Implemented in CYLTabBarController.m. [CN] 实现位于 CYLTabBarController.m。
@interface CYLTabBarController (CYLInteractionPrivate)
- (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)cyl_contextPlusButton;
- (nullable UIControl *)cyl_reportedControlForControl:(nullable UIControl *)control;
@end

/// [EN] FIX: issue #152 — implemented in CYLTabBarController.m (`CYLTabBarController (CYLTabBarItemGesture)`).
/// [CN] FIX: issue #152 — 实现位于 CYLTabBarController.m（`CYLTabBarController (CYLTabBarItemGesture)`）。
@interface CYLTabBarController (CYLInteractionTabBarItemGesture)
- (BOOL)cyl_hasTabBarItemGestureReceiver;
- (BOOL)cyl_isTabBarItemGestureControl:(UIControl *)control viewController:(UIViewController *__autoreleasing _Nullable *_Nullable)viewController;
- (void)cyl_reportTabBarItemGesture:(CYLTabBarItemGesture)gesture control:(UIControl *)control viewController:(nullable UIViewController *)viewController;
@end

/// [EN] Used by the gesture handler below. [CN] 供下方的手势处理对象使用。
@interface CYLTabBarController (CYLInteractionInternal)
- (BOOL)cyl_handlesDidLongPressControl;
- (BOOL)cyl_handlesTabButtonLongPress;
- (nullable UIControl *)cyl_tabControlAtPoint:(CGPoint)touchPoint;
- (void)cyl_reportLongPressOnControl:(UIControl *)control;
- (void)cyl_installInteractionGestureRecognizersIfNeeded;
@end

/*!
 * [EN] The long press of the tab buttons. Its own class: CYLTabBar treats every `UILongPressGestureRecognizer` added to
 *      it as the Liquid Glass one, and this one is added to the tab bar controller's view anyway.
 * [CN] Tab 按钮的长按手势，使用单独的类：CYLTabBar 会把添加给它的 `UILongPressGestureRecognizer` 当作液态玻璃的手势；
 *      而且本手势添加在 TabBarController 的 view 上。
 */
@interface CYLTabButtonLongPressGestureRecognizer : UILongPressGestureRecognizer
@property (nonatomic, weak, nullable) UIControl *cyl_pressedControl;
@end

@implementation CYLTabButtonLongPressGestureRecognizer
@end

/// [EN] The pan of `cyl_swipeToSwitchTabEnabled`. [CN] `cyl_swipeToSwitchTabEnabled` 的拖动手势。
@interface CYLTabBarSwipeGestureRecognizer : UIPanGestureRecognizer
@end

@implementation CYLTabBarSwipeGestureRecognizer
@end

/*!
 * [EN] The delegate and target of both gestures; it holds the tab bar controller weakly.
 * [CN] 两个手势的代理与响应者，弱引用 TabBarController。
 */
@interface CYLTabBarInteractionHandler : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak, nullable) CYLTabBarController *tabBarController;
@property (nonatomic, strong, nullable) CYLTabButtonLongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong, nullable) CYLTabBarSwipeGestureRecognizer *swipeGestureRecognizer;
- (void)cyl_longPressDidUpdate:(CYLTabButtonLongPressGestureRecognizer *)gestureRecognizer;
- (void)cyl_swipeDidUpdate:(CYLTabBarSwipeGestureRecognizer *)gestureRecognizer;
@end

static const void *CYLTabBarInteractionHandlerKey = &CYLTabBarInteractionHandlerKey;
static const void *CYLPreviousAnimatedControlKey = &CYLPreviousAnimatedControlKey;

#pragma mark - Views of a tab button

/// [EN] The view to animate as the icon: the Lottie view, else the image view. [CN] 作为图标播放动画的视图：Lottie 视图，否则为图片视图。
static UIView *CYLTabButtonIconView(UIControl *control) {
#if CYL_LOTTIE_AVAILABLE
    // [EN] Only when the Lottie library is integrated: a tab with a Lottie icon animates the Lottie view.
    // [CN] 仅在引入 Lottie 库时：有 Lottie 图标的 Tab 对 Lottie 视图播放动画。
    if ([control respondsToSelector:@selector(cyl_lottieAnimationView)]) {
        UIView *lottieView = [control cyl_lottieAnimationView];
        if (lottieView) {
            return lottieView;
        }
    }
#endif
    if ([control isKindOfClass:[UIButton class]]) {
        return ((UIButton *)control).imageView ?: control;
    }
#if CYL_FLATDESIGN_AVAILABLE
    // [EN] FlatDesign tab buttons have their own `imageView`. [CN] 扁平样式的 Tab 按钮有自己的 `imageView`。
    if ([control isKindOfClass:[CYLFlatDesignTabBarButton class]]) {
        return ((CYLFlatDesignTabBarButton *)control).imageView ?: control;
    }
#endif
    return [control cyl_tabImageView] ?: control;
}

static UILabel *_Nullable CYLTabButtonTitleLabel(UIControl *control) {
    if ([control isKindOfClass:[UIButton class]]) {
        return ((UIButton *)control).titleLabel;
    }
#if CYL_FLATDESIGN_AVAILABLE
    // [EN] FlatDesign tab buttons have their own `titleLabel`. [CN] 扁平样式的 Tab 按钮有自己的 `titleLabel`。
    if ([control isKindOfClass:[CYLFlatDesignTabBarButton class]]) {
        return ((CYLFlatDesignTabBarButton *)control).titleLabel;
    }
#endif
    return [control cyl_tabLabel];
}

/*!
 * [EN] The buttons that show `control`: itself, plus its copy in the Liquid Glass selected layer (a tab's selected
 *      button, or the plus button's `selectedContentView`).
 * [CN] 显示 `control` 的按钮：它自己，以及液态玻璃选中图层中的副本（Tab 的选中按钮，或 PlusButton 的 `selectedContentView`）。
 */
static NSArray<UIControl *> *CYLTabButtonLayers(UIControl *control) {
    NSMutableArray<UIControl *> *controls = [NSMutableArray arrayWithObject:control];
    UIControl *selectedLayerControl = nil;
    if ([control isKindOfClass:[CYLPlusButton class]]) {
        // [EN] `selectedContentView` is declared by the CYLPlusButtonSubclassing protocol; CYLPlusButton implements it.
        // [CN] `selectedContentView` 由 CYLPlusButtonSubclassing 协议声明，CYLPlusButton 实现了它。
        selectedLayerControl = ((CYLPlusButton<CYLPlusButtonSubclassing> *)control).selectedContentView;
    } else if ([CYLConstants isLiquidGlassActive]) {
        selectedLayerControl = [control cyl_platterSelectedControl];
    }
    if (selectedLayerControl && selectedLayerControl != control && selectedLayerControl.window) {
        [controls addObject:selectedLayerControl];
    }
    return controls;
}

#pragma mark - Animations

static id<CYLTabButtonAnimation> _Nullable CYLTabButtonAnimationForType(CYLTabButtonTapAnimationType type) {
    switch (type) {
        case CYLTabButtonTapAnimationTypeScale:
            return [[CYLTabButtonScaleAnimation alloc] init];
        case CYLTabButtonTapAnimationTypeZoomIn:
            return [[CYLTabButtonZoomInAnimation alloc] init];
        case CYLTabButtonTapAnimationTypeBounce:
            return [[CYLTabButtonBounceAnimation alloc] init];
        case CYLTabButtonTapAnimationTypeBounceWithFireworks: {
            CYLTabButtonBounceAnimation *animation = [[CYLTabButtonBounceAnimation alloc] init];
            animation.playsFireworks = YES;
            return animation;
        }
        case CYLTabButtonTapAnimationTypeRotation:
            return [[CYLTabButtonRotationAnimation alloc] init];
        case CYLTabButtonTapAnimationTypeFlip:
            return [[CYLTabButtonFlipAnimation alloc] init];
        case CYLTabButtonTapAnimationTypeFume:
            return [[CYLTabButtonFumeAnimation alloc] init];
        case CYLTabButtonTapAnimationTypeNone:
        default:
            return nil;
    }
}

@implementation CYLTabBarController (CYLInteraction)

#pragma mark - Tap animation

- (CYLTabButtonTapAnimationType)cyl_tabButtonTapAnimationType {
    return [objc_getAssociatedObject(self, @selector(cyl_tabButtonTapAnimationType)) integerValue];
}

- (void)cyl_setTabButtonTapAnimationType:(CYLTabButtonTapAnimationType)tabButtonTapAnimationType {
    objc_setAssociatedObject(self, @selector(cyl_tabButtonTapAnimationType), @(tabButtonTapAnimationType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // [EN] One object per type, kept until the type changes. [CN] 每种类型一个对象，类型改变前一直复用。
    objc_setAssociatedObject(self, @selector(cyl_animationForTapAnimationType), CYLTabButtonAnimationForType(tabButtonTapAnimationType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable id<CYLTabButtonAnimation>)cyl_animationForTapAnimationType {
    return objc_getAssociatedObject(self, @selector(cyl_animationForTapAnimationType));
}

- (nullable id<CYLTabButtonAnimation>)cyl_defaultTabButtonAnimation {
    return objc_getAssociatedObject(self, @selector(cyl_defaultTabButtonAnimation));
}

- (void)cyl_setDefaultTabButtonAnimation:(id<CYLTabButtonAnimation>)defaultTabButtonAnimation {
    objc_setAssociatedObject(self, @selector(cyl_defaultTabButtonAnimation), defaultTabButtonAnimation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 * [EN] The index of `control`'s view controller in `viewControllers`, or NSNotFound (e.g. a plus button without a child
 *      view controller).
 * [CN] `control` 对应的控制器在 `viewControllers` 中的位置，没有时为 NSNotFound（例如没有子控制器的 PlusButton）。
 */
- (NSUInteger)cyl_viewControllerIndexForTabControl:(UIControl *)control {
    if (!control) {
        return NSNotFound;
    }
    if ([control isKindOfClass:[CYLPlusButton class]]) {
        if (![self hasPlusChildViewController]) {
            return NSNotFound;
        }
        NSInteger index = control.cyl_tabBarChildViewControllerIndex;
        return (index >= 0 && index < (NSInteger)self.viewControllers.count) ? (NSUInteger)index : NSNotFound;
    }
    NSUInteger index = [self.viewControllers indexOfObjectPassingTest:^BOOL(__kindof UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        UIControl *tabButton = viewController.cyl_tabButton;
        return tabButton && (tabButton == control || [tabButton cyl_platterSelectedControl] == control);
    }];
    if (index != NSNotFound) {
        return index;
    }
#if CYL_FLATDESIGN_AVAILABLE
    // [EN] FlatDesign only: the position among the bar's buttons. [CN] 仅扁平样式：在栏中按钮里的位置。
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType && [self.cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        NSUInteger buttonIndex = [((CYLFlatDesignTabBar *)self.cyl_tabBar).tabBarButtons indexOfObject:(CYLFlatDesignTabBarButton *)control];
        if (buttonIndex < self.viewControllers.count) {
            return buttonIndex;
        }
    }
#endif
    return NSNotFound;
}

- (nullable id<CYLTabButtonAnimation>)cyl_animationForTabControl:(UIControl *)control {
    NSUInteger index = [self cyl_viewControllerIndexForTabControl:control];
    if (index != NSNotFound) {
        UIViewController *viewController = self.viewControllers[index];
        id<CYLTabButtonAnimation> animation = viewController.cyl_tabButtonAnimation ?: viewController.cyl_getViewControllerInsteadOfNavigationController.cyl_tabButtonAnimation;
        if (animation) {
            return animation;
        }
    }
    return self.cyl_defaultTabButtonAnimation ?: [self cyl_animationForTapAnimationType];
}

- (void)cyl_playTabButtonAnimationForControl:(UIControl *)control {
    if (!control) {
        return;
    }
    // [EN] Held weakly (CYLUtils): a tab button can be replaced by UIKit. [CN] 弱引用（CYLUtils）：Tab 按钮可能被 UIKit 替换。
    UIControl *previousControl = [self cyl_weakAssociatedObjectForKey:CYLPreviousAnimatedControlKey];
    NSUInteger index = [self cyl_viewControllerIndexForTabControl:control];
    NSUInteger previousIndex = [self cyl_viewControllerIndexForTabControl:previousControl];
    BOOL hasIndexes = (index != NSNotFound && previousIndex != NSNotFound);

    // [EN] The button selected before plays its deselect animation, when its animation has one.
    // [CN] 之前选中的按钮播放取消选中动画（其动画实现了该方法时）。
    if (previousControl && previousControl != control) {
        id<CYLTabButtonAnimation> previousAnimation = [self cyl_animationForTabControl:previousControl];
        if ([previousAnimation respondsToSelector:@selector(cyl_playDeselectAnimationWithTabButton:iconView:titleLabel:)]) {
            if (hasIndexes && [previousAnimation respondsToSelector:@selector(cyl_setToRight:)]) {
                previousAnimation.cyl_toRight = previousIndex < index;
            }
            for (UIControl *layer in CYLTabButtonLayers(previousControl)) {
                [previousAnimation cyl_playDeselectAnimationWithTabButton:layer
                                                                 iconView:CYLTabButtonIconView(layer)
                                                               titleLabel:CYLTabButtonTitleLabel(layer)];
            }
        }
    }
    [self cyl_setWeakAssociatedObject:control forKey:CYLPreviousAnimatedControlKey];

    id<CYLTabButtonAnimation> animation = [self cyl_animationForTabControl:control];
    if (!animation) {
        return;
    }
    if (hasIndexes && [animation respondsToSelector:@selector(cyl_setFromLeft:)]) {
        animation.cyl_fromLeft = previousIndex < index;
    }
    for (UIControl *layer in CYLTabButtonLayers(control)) {
        [animation cyl_playSelectAnimationWithTabButton:layer
                                               iconView:CYLTabButtonIconView(layer)
                                             titleLabel:CYLTabButtonTitleLabel(layer)];
    }
}

#pragma mark - Long press

- (nullable CYLTabBarControllerDidLongPressControlBlock)cyl_didLongPressControlBlock {
    return objc_getAssociatedObject(self, @selector(cyl_didLongPressControlBlock));
}

- (void)cyl_setDidLongPressControlBlock:(CYLTabBarControllerDidLongPressControlBlock)didLongPressControlBlock {
    objc_setAssociatedObject(self, @selector(cyl_didLongPressControlBlock), didLongPressControlBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self cyl_installInteractionGestureRecognizersIfNeeded];
}

- (NSTimeInterval)cyl_tabButtonLongPressMinimumDuration {
    NSNumber *duration = objc_getAssociatedObject(self, @selector(cyl_tabButtonLongPressMinimumDuration));
    return duration ? duration.doubleValue : 0.5;
}

/*!
 * [EN] The one long press duration, also behind `cyl_tabBarItemLongPressDuration` (issue #152): both features share one
 *      recognizer. At least 0.1 s.
 * [CN] 唯一的长按时长，`cyl_tabBarItemLongPressDuration`（issue #152）也使用它：两个功能共用同一个手势。最短 0.1 秒。
 */
- (void)cyl_setTabButtonLongPressMinimumDuration:(NSTimeInterval)tabButtonLongPressMinimumDuration {
    NSTimeInterval duration = MAX(tabButtonLongPressMinimumDuration, 0.1);
    objc_setAssociatedObject(self, @selector(cyl_tabButtonLongPressMinimumDuration), @(duration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_interactionHandler].longPressGestureRecognizer.minimumPressDuration = duration;
}

/// [EN] YES when `cyl_didLongPressControlBlock` or `-tabBarController:didLongPressControl:` listens.
/// [CN] 设置了 `cyl_didLongPressControlBlock` 或实现了 `-tabBarController:didLongPressControl:` 时为 YES。
- (BOOL)cyl_handlesDidLongPressControl {
    return self.cyl_didLongPressControlBlock != nil ||
        [self.delegate respondsToSelector:@selector(tabBarController:didLongPressControl:)];
}

/*!
 * [EN] YES when someone listens to long presses: the callbacks above, or the `CYLTabBarItemGestureLongPress` of issue #152
 *      (`cyl_tabBarItemGestureHandler`, `-tabBarController:didRecognizeTabBarItemGesture:control:viewController:`).
 * [CN] 有人监听长按时为 YES：上面的回调，或 issue #152 的 `CYLTabBarItemGestureLongPress`
 *      （`cyl_tabBarItemGestureHandler`、`-tabBarController:didRecognizeTabBarItemGesture:control:viewController:`）。
 */
- (BOOL)cyl_handlesTabButtonLongPress {
    return [self cyl_handlesDidLongPressControl] || [self cyl_hasTabBarItemGestureReceiver];
}

/*!
 * [EN] The tab button or plus button under `touchPoint` (in this controller's view), as `-tabBarController:didSelectControl:`
 *      reports it, or nil. The tab bars' own hit tests already resolve the plus button (also its raised part and its
 *      touchable area) and the Liquid Glass platter.
 * [CN] `touchPoint`（本控制器 view 坐标）下的 Tab 按钮或 PlusButton（与 `-tabBarController:didSelectControl:` 上报的一致），没有时为 nil。
 *      TabBar 自己的 hitTest 已经处理了 PlusButton（包括凸起部分与可点击区域）和液态玻璃的 platter。
 */
- (nullable UIControl *)cyl_tabControlAtPoint:(CGPoint)touchPoint {
    UIView *tabBar = self.cyl_tabBar ?: self.tabBar;
    if (!tabBar || tabBar.hidden || !tabBar.window) {
        return nil;
    }
    UIView *hitView = [tabBar hitTest:[tabBar convertPoint:touchPoint fromView:self.view] withEvent:nil];
    // [EN] The button the hit view belongs to, inside the tab bar (CYLUtils). [CN] 被命中视图所属的按钮，限于 TabBar 内（CYLUtils）。
    UIControl *control = [hitView cyl_nearestControlBelowView:tabBar];
    if (!control) {
        return nil;
    }
#if CYL_FLATDESIGN_AVAILABLE
    // [EN] FlatDesign only: its buttons are reported as they are. [CN] 仅扁平样式：其按钮按原样上报。
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        return control;
    }
#endif
    if ([control cyl_isPlatterSelectedControl]) {
        control = [control cyl_platterNormalControl];
    }
    return [self cyl_reportedControlForControl:control] ?: control;
}

/*!
 * [EN] One long press, reported to both APIs: `cyl_didLongPressControlBlock` then `-tabBarController:didLongPressControl:`
 *      (issue #535), then `CYLTabBarItemGestureLongPress` (issue #152) for a tab button or the plus button.
 * [CN] 一次长按，向两套 API 上报：先 `cyl_didLongPressControlBlock`、再 `-tabBarController:didLongPressControl:`（issue #535），
 *      然后对 Tab 按钮或 PlusButton 上报 `CYLTabBarItemGestureLongPress`（issue #152）。
 */
- (void)cyl_reportLongPressOnControl:(UIControl *)control {
    CYLTabBarControllerDidLongPressControlBlock block = self.cyl_didLongPressControlBlock;
    if (block) {
        block(self, control);
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:didLongPressControl:)]) {
        [delegate tabBarController:self didLongPressControl:control];
    }
    if (![self cyl_hasTabBarItemGestureReceiver]) {
        return;
    }
    // [EN] The pressed control may be an interactive subview of the plus button (#202): the LongPress belongs to the tab
    //      button or plus button it is in.
    // [CN] 被按住的控件可能是 PlusButton 上可交互的子控件（#202）：LongPress 属于它所在的 Tab 按钮或 PlusButton。
    UIView *tabBar = self.cyl_tabBar ?: self.tabBar;
    for (UIControl *candidate = control; candidate; candidate = [candidate.superview cyl_nearestControlBelowView:tabBar]) {
        UIViewController *viewController = nil;
        if ([self cyl_isTabBarItemGestureControl:candidate viewController:&viewController]) {
            [self cyl_reportTabBarItemGesture:CYLTabBarItemGestureLongPress control:candidate viewController:viewController];
            return;
        }
    }
}

#pragma mark - Swipe

- (BOOL)cyl_swipeToSwitchTabEnabled {
    return [objc_getAssociatedObject(self, @selector(cyl_swipeToSwitchTabEnabled)) boolValue];
}

- (void)cyl_setSwipeToSwitchTabEnabled:(BOOL)swipeToSwitchTabEnabled {
    objc_setAssociatedObject(self, @selector(cyl_swipeToSwitchTabEnabled), @(swipeToSwitchTabEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_installInteractionGestureRecognizersIfNeeded];
}

/// [EN] YES when `viewController` can be selected by a swipe. [CN] `viewController` 可以通过滑动选中时为 YES。
- (BOOL)cyl_canSwipeToViewController:(UIViewController *)viewController {
    if (viewController.cyl_isPlaceholder) {
        return NO;
    }
    UIControl *tabButton = viewController.cyl_tabButton;
    return !(tabButton && tabButton.hidden && tabButton.window);
}

/*!
 * [EN] Asks the delegate and the login check (issue #19), as a tap does. The tab bar controller's own
 *      `-tabBarController:shouldSelectViewController:` runs the login check itself.
 * [CN] 与点击一样询问代理与登录检查（issue #19）。TabBarController 自身的 `-tabBarController:shouldSelectViewController:` 会自己做登录检查。
 */
- (BOOL)cyl_shouldSwipeSelectViewController:(UIViewController *)viewController {
    id<UITabBarControllerDelegate> delegate = self.delegate;
    if (delegate != (id<UITabBarControllerDelegate>)self && [self cyl_interceptLoginIfNeededForViewController:viewController]) {
        return NO;
    }
    if ([delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        return [delegate tabBarController:self shouldSelectViewController:viewController];
    }
    return YES;
}

- (BOOL)cyl_switchToAdjacentTabWithStep:(NSInteger)step animated:(BOOL)animated {
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    NSUInteger selectedIndex = self.selectedIndex;
    if (step == 0 || selectedIndex == NSNotFound || selectedIndex >= viewControllers.count) {
        return NO;
    }
    NSInteger direction = step > 0 ? 1 : -1;
    NSInteger index = (NSInteger)selectedIndex + direction;
    while (index >= 0 && index < (NSInteger)viewControllers.count && ![self cyl_canSwipeToViewController:viewControllers[index]]) {
        index += direction;
    }
    if (index < 0 || index >= (NSInteger)viewControllers.count) {
        return NO;
    }
    UIViewController *toViewController = viewControllers[index];
    if (![self cyl_shouldSwipeSelectViewController:toViewController]) {
        return NO;
    }
    UIView *fromView = self.selectedViewController.view;
    UIView *containerView = fromView.superview;
    UIView *snapshotView = (animated && containerView) ? [fromView snapshotViewAfterScreenUpdates:NO] : nil;
    self.selectedIndex = (NSUInteger)index;
    UIView *toView = self.selectedViewController.view;
    if (!snapshotView || toView.superview != containerView) {
        return YES;
    }
    // [EN] Slide like `CYLTabBarSlideTransitionAnimator`: the old page (a snapshot) leaves, the new one comes in.
    // [CN] 与 `CYLTabBarSlideTransitionAnimator` 相同的滑动：旧页面（快照）滑出，新页面滑入。
    CGFloat width = CGRectGetWidth(containerView.bounds);
    snapshotView.frame = fromView.frame;
    [containerView addSubview:snapshotView];
    toView.transform = CGAffineTransformMakeTranslation(width * direction, 0);
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toView.transform = CGAffineTransformIdentity;
        snapshotView.transform = CGAffineTransformMakeTranslation(-width * direction, 0);
    } completion:^(BOOL finished) {
        toView.transform = CGAffineTransformIdentity;
        [snapshotView removeFromSuperview];
    }];
    return YES;
}

#pragma mark - Gestures

- (CYLTabBarInteractionHandler *)cyl_interactionHandler {
    return objc_getAssociatedObject(self, CYLTabBarInteractionHandlerKey);
}

/*!
 * [EN] Adds the long press and the swipe to this controller's view once, when one of them is used. Called from the
 *      setters and from `-viewDidLayoutSubviews`, never before the view is loaded (`tabBarStyleType` must be set
 *      before `-viewDidLoad`). Each gesture asks first whether its feature is on, so unused ones never take a touch.
 * [CN] 使用其中一个功能时，把长按与滑动手势添加到本控制器的 view 上（只添加一次）。由 setter 与 `-viewDidLayoutSubviews` 调用，
 *      不会在 view 加载前调用（`tabBarStyleType` 需在 `-viewDidLoad` 前设置）。每个手势先判断对应功能是否开启，未使用的手势不会接收触摸。
 */
- (void)cyl_installInteractionGestureRecognizersIfNeeded {
    if (![self isViewLoaded] || [self cyl_interactionHandler]) {
        return;
    }
    if (!self.cyl_swipeToSwitchTabEnabled && ![self cyl_handlesTabButtonLongPress]) {
        return;
    }
    CYLTabBarInteractionHandler *handler = [[CYLTabBarInteractionHandler alloc] init];
    handler.tabBarController = self;

    CYLTabButtonLongPressGestureRecognizer *longPress = [[CYLTabButtonLongPressGestureRecognizer alloc] initWithTarget:handler action:@selector(cyl_longPressDidUpdate:)];
    longPress.minimumPressDuration = self.cyl_tabButtonLongPressMinimumDuration;
    // [EN] Lifting the finger is not delayed; `cancelsTouchesInView` is decided per touch (`-gestureRecognizer:shouldReceiveTouch:`).
    // [CN] 抬起手指不延迟；`cancelsTouchesInView` 在每次触摸时决定（`-gestureRecognizer:shouldReceiveTouch:`）。
    longPress.delaysTouchesEnded = NO;
    longPress.delegate = handler;
    [self.view addGestureRecognizer:longPress];
    handler.longPressGestureRecognizer = longPress;

    CYLTabBarSwipeGestureRecognizer *swipe = [[CYLTabBarSwipeGestureRecognizer alloc] initWithTarget:handler action:@selector(cyl_swipeDidUpdate:)];
    swipe.delegate = handler;
    swipe.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:swipe];
    handler.swipeGestureRecognizer = swipe;

    objc_setAssociatedObject(self, CYLTabBarInteractionHandlerKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - CYLTabBarInteractionHandler

/// [EN] YES when `view` or one of its superviews scrolls horizontally. [CN] `view` 或其父视图可以横向滚动时为 YES。
static BOOL CYLViewIsInHorizontalScrollView(UIView *view, UIView *stopView) {
    for (UIView *current = view; current && current != stopView; current = current.superview) {
        if ([current isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)current;
            UIEdgeInsets insets = scrollView.adjustedContentInset;
            if (scrollView.scrollEnabled && scrollView.contentSize.width + insets.left + insets.right > CGRectGetWidth(scrollView.bounds) + 1) {
                return YES;
            }
        }
        if ([current isKindOfClass:[UISlider class]] || [current isKindOfClass:[UISwitch class]]) {
            return YES;
        }
    }
    return NO;
}

@implementation CYLTabBarInteractionHandler

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CYLTabBarController *tabBarController = self.tabBarController;
    if (!tabBarController) {
        return NO;
    }
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        if (![tabBarController cyl_handlesTabButtonLongPress]) {
            return NO;
        }
        UIControl *control = [tabBarController cyl_tabControlAtPoint:[touch locationInView:tabBarController.view]];
        self.longPressGestureRecognizer.cyl_pressedControl = control;
        // [EN] Lifting the finger after a long press selects the tab only without `didLongPressControl` listeners: those
        //      documented that it does not (issue #535); `CYLTabBarItemGestureLongPress` keeps the selection (issue #152).
        // [CN] 仅在没有 `didLongPressControl` 监听时，长按后抬起手指才会选中该 Tab：该回调的文档说明不会选中（issue #535）；
        //      `CYLTabBarItemGestureLongPress` 保留选中（issue #152）。
        self.longPressGestureRecognizer.cancelsTouchesInView = [tabBarController cyl_handlesDidLongPressControl];
        return control != nil;
    }
    if (gestureRecognizer == self.swipeGestureRecognizer) {
        if (!tabBarController.cyl_swipeToSwitchTabEnabled || tabBarController.presentedViewController) {
            return NO;
        }
        // [EN] Not on the tab bar, and not where a horizontal scroll (or a slider) needs the touch.
        // [CN] 不在 TabBar 上，也不在需要横向滚动（或滑块）的位置。
        CGPoint point = [touch locationInView:tabBarController.view];
        if ([tabBarController cyl_tabControlAtPoint:point]) {
            return NO;
        }
        UIView *tabBar = tabBarController.cyl_tabBar ?: tabBarController.tabBar;
        if (tabBar && [touch.view isDescendantOfView:tabBar]) {
            return NO;
        }
        return !CYLViewIsInHorizontalScrollView(touch.view, tabBarController.view);
    }
    return YES;
}

/*!
 * [EN] Both gestures work alongside the others: Liquid Glass has its own long press on the tab bar, and a vertical table
 *      view's pan also begins on a horizontal swipe. Horizontal scroll views are already excluded in `-shouldReceiveTouch:`.
 * [CN] 两个手势与其他手势同时识别：液态玻璃在 TabBar 上有自己的长按手势，竖向 tableView 的拖动手势在水平滑动时也会开始。
 *      可横向滚动的 scrollView 已在 `-shouldReceiveTouch:` 中排除。
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return gestureRecognizer == self.longPressGestureRecognizer || gestureRecognizer == self.swipeGestureRecognizer;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CYLTabBarController *tabBarController = self.tabBarController;
    if (gestureRecognizer != self.swipeGestureRecognizer) {
        return YES;
    }
    // [EN] Only at the root of a navigation stack (the back gesture belongs to the pushed pages), and only horizontally.
    // [CN] 仅在导航栈的根控制器上（被 push 的页面使用返回手势），且仅水平方向。
    UIViewController *selectedViewController = tabBarController.selectedViewController;
    if ([selectedViewController isKindOfClass:[UINavigationController class]] &&
        ((UINavigationController *)selectedViewController).viewControllers.count > 1) {
        return NO;
    }
    CGPoint velocity = [self.swipeGestureRecognizer velocityInView:tabBarController.view];
    return fabs(velocity.x) > fabs(velocity.y) * 1.5;
}

- (void)cyl_longPressDidUpdate:(CYLTabButtonLongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CYLTabBarController *tabBarController = self.tabBarController;
    UIControl *control = gestureRecognizer.cyl_pressedControl ?: [tabBarController cyl_tabControlAtPoint:[gestureRecognizer locationInView:tabBarController.view]];
    if (tabBarController && control) {
        [tabBarController cyl_reportLongPressOnControl:control];
    }
}

- (void)cyl_swipeDidUpdate:(CYLTabBarSwipeGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    CYLTabBarController *tabBarController = self.tabBarController;
    CGPoint translation = [gestureRecognizer translationInView:tabBarController.view];
    CGPoint velocity = [gestureRecognizer velocityInView:tabBarController.view];
    // [EN] A short fast flick counts too. [CN] 快速的短距离轻扫同样有效。
    BOOL isSwipe = fabs(translation.x) > 60.0 || fabs(velocity.x) > 500.0;
    if (!isSwipe || fabs(translation.x) < fabs(translation.y)) {
        return;
    }
    // [EN] Finger to the left: the next tab. [CN] 手指向左：下一个 Tab。
    [tabBarController cyl_switchToAdjacentTabWithStep:(translation.x < 0 ? 1 : -1) animated:YES];
}

@end

#pragma mark - UIViewController (CYLTabButtonAnimation)

@implementation UIViewController (CYLTabButtonAnimation)

- (nullable id<CYLTabButtonAnimation>)cyl_tabButtonAnimation {
    return objc_getAssociatedObject(self, @selector(cyl_tabButtonAnimation));
}

- (void)cyl_setTabButtonAnimation:(id<CYLTabButtonAnimation>)tabButtonAnimation {
    objc_setAssociatedObject(self, @selector(cyl_tabButtonAnimation), tabButtonAnimation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
