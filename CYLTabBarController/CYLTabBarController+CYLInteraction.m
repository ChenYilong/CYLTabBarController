//
//  CYLTabBarController+CYLInteraction.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController+CYLInteraction.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h>

/// [EN] Implemented in CYLTabBarController.m. [CN] 实现位于 CYLTabBarController.m。
@interface CYLTabBarController (CYLInteractionPrivate)
- (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)cyl_contextPlusButton;
- (nullable UIViewController *)cyl_contextPlusChildViewController;
- (nullable UIControl *)cyl_reportedControlForControl:(nullable UIControl *)control;
@end

/// [EN] FIX: issue #152 — implemented in CYLTabBarController.m (`CYLTabBarController (CYLTabBarItemGesture)`).
/// [CN] FIX: issue #152 — 实现位于 CYLTabBarController.m（`CYLTabBarController (CYLTabBarItemGesture)`）。
@interface CYLTabBarController (CYLInteractionTabBarItemGesture)
- (BOOL)cyl_hasTabBarItemGestureReceiver;
- (BOOL)cyl_isTabBarItemGestureControl:(UIControl *)control viewController:(UIViewController *__autoreleasing _Nullable *_Nullable)viewController;
- (void)cyl_reportTabBarItemGesture:(CYLTabBarItemGesture)gesture control:(UIControl *)control viewController:(nullable UIViewController *)viewController;
- (void)cyl_recognizeLiquidGlassTapOnControl:(UIControl *)control selectedViewControllerAtTouchDown:(nullable UIViewController *)selectedViewController;
@end

/// [EN] Implemented in CYLTabBar.m (iOS 27.1 vertical bar, #653). [CN] 实现位于 CYLTabBar.m（iOS 27.1 竖向栏，#653）。
@interface CYLTabBar (CYLInteractionVerticalBar)
- (nullable UIControl *)cyl_verticalBarTabButtonAtWindowPoint:(CGPoint)windowPoint;
@end

/// [EN] Used by the gesture handler below. [CN] 供下方的手势处理对象使用。
@interface CYLTabBarController (CYLInteractionInternal)
- (BOOL)cyl_handlesDidLongPressControl;
- (BOOL)cyl_handlesTabButtonLongPress;
- (nullable UIControl *)cyl_tabControlAtPoint:(CGPoint)touchPoint;
- (void)cyl_reportLongPressOnControl:(UIControl *)control;
- (void)cyl_installInteractionGestureRecognizersIfNeeded;
- (BOOL)cyl_liquidGlassReceivesTabTouches;
- (BOOL)cyl_liquidGlassTakesTabTaps;
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
 * FIX: issue #152 / #535 — long press, Reselect and DoubleTap in Liquid Glass.
 * [EN] One press on a tab button, followed through UIKit's own Liquid Glass gestures (the continuous selection and the
 *      long press that lifts the lens), which `CYLTabBar` forwards: in Liquid Glass they receive every touch on the tab
 *      buttons, and a gesture added by the library does not. The press is one tap when it ends where it began, a long
 *      press when it is held for `cyl_tabButtonLongPressMinimumDuration`, and neither when the finger moves to switch tabs.
 *      The idea of one tracker for tap, long tap and double tap, with the item found by its position rather than by
 *      `hitTest`, follows Telegram-iOS's tab bar (`TapLongTapOrDoubleTapGestureRecognizer`); no code is taken from it.
 * [CN] 一次按在 Tab 按钮上的触摸，通过 `CYLTabBar` 转发的系统液态玻璃手势（连续选择手势与抬起 lens 的长按手势）跟踪：液态玻璃下
 *      Tab 按钮上的每次触摸都由它们接收，库自己添加的手势收不到。在按下的位置结束算一次点击，按住
 *      `cyl_tabButtonLongPressMinimumDuration` 算长按，手指移动去切换 Tab 时两者都不算。用一个跟踪器同时处理点击、长按与双击、
 *      按位置而不是 `hitTest` 找到 Tab，这一思路参考 Telegram-iOS 的 TabBar（`TapLongTapOrDoubleTapGestureRecognizer`），未使用其代码。
 */
@interface CYLTabBarLiquidGlassPress : NSObject
/// [EN] The UIKit gesture this press is followed through. [CN] 跟踪这次触摸所用的系统手势。
@property (nonatomic, weak, nullable) UIGestureRecognizer *gestureRecognizer;
@property (nonatomic, weak, nullable) UIControl *control;
@property (nonatomic, weak, nullable) UIViewController *selectedViewControllerAtTouchDown;
@property (nonatomic, assign) CGPoint windowStartPoint;
@property (nonatomic, assign) BOOL moved;
@property (nonatomic, assign) BOOL longPressReported;
/// [EN] Tells a pending long press timer whether it still belongs to this press. [CN] 用于判断尚未触发的长按计时是否仍属于本次触摸。
@property (nonatomic, assign) NSUInteger generation;
@end

@implementation CYLTabBarLiquidGlassPress
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
static const void *CYLLiquidGlassPressKey = &CYLLiquidGlassPressKey;
static const void *CYLLiquidGlassSeenKey = &CYLLiquidGlassSeenKey;
/// [EN] How far the finger may move and still be a tap or a long press, in points. [CN] 仍算点击或长按时手指可移动的距离（pt）。
static const CGFloat CYLLiquidGlassPressAllowableMovement = 10.0;

#pragma mark - CYLTabBarTapSound

/// [EN] The system keyboard click. [CN] 系统键盘点击声。
static const SystemSoundID CYLTabBarDefaultTapSoundID = 1104;

/*!
 * [EN] One system sound for `cyl_tabButtonTapSoundURL`, created once and disposed of with this object. The code in the
 *      issue created a new sound on every tap and never disposed of it.
 * [CN] `cyl_tabButtonTapSoundURL` 对应的系统音效，只创建一次，随本对象释放。issue 中的代码每次点击都新建音效且从不释放。
 */
@interface CYLTabBarTapSound : NSObject
@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, assign, readonly) SystemSoundID soundID;
@end

@implementation CYLTabBarTapSound

- (nullable instancetype)initWithURL:(NSURL *)URL {
    SystemSoundID soundID = 0;
    if (!URL.isFileURL || AudioServicesCreateSystemSoundID((__bridge CFURLRef)URL, &soundID) != kAudioServicesNoError) {
        return nil;
    }
    if (self = [super init]) {
        _URL = [URL copy];
        _soundID = soundID;
    }
    return self;
}

- (void)dealloc {
    AudioServicesDisposeSystemSoundID(_soundID);
}

@end

#pragma mark - Views of a tab button

/// [EN] The view to animate as the icon: the Lottie view, else the image view. [CN] 作为图标播放动画的视图：Lottie 视图，否则为图片视图。
static UIView *CYLTabButtonIconView(UIControl *control) {
    // [EN] FIX: issue #601 — a view shown in place of the icon (`-setTabBarItemIconViewProvider:atIndex:`): the icon, or the
    //      Lottie view, is hidden then, so the tap animation plays on that view.
    // [CN] FIX: issue #601 — 替换图标显示的视图（`-setTabBarItemIconViewProvider:atIndex:`）：此时图标或 Lottie 视图已隐藏，
    //      点击动画在该视图上播放。
    for (UIView *subview in control.subviews) {
        if (subview.cyl_isTabBarItemIconView && !subview.hidden) {
            return subview;
        }
    }
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

#pragma mark - Tap sound and haptic feedback

- (BOOL)cyl_tabButtonTapSoundEnabled {
    return [objc_getAssociatedObject(self, @selector(cyl_tabButtonTapSoundEnabled)) boolValue];
}

- (void)cyl_setTabButtonTapSoundEnabled:(BOOL)tabButtonTapSoundEnabled {
    objc_setAssociatedObject(self, @selector(cyl_tabButtonTapSoundEnabled), @(tabButtonTapSoundEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSURL *)cyl_tabButtonTapSoundURL {
    return [(CYLTabBarTapSound *)objc_getAssociatedObject(self, @selector(cyl_tabButtonTapSoundURL)) URL];
}

- (void)cyl_setTabButtonTapSoundURL:(NSURL *)tabButtonTapSoundURL {
    // [EN] The old sound is disposed of when its object is released. nil, or a file that cannot be played: the click.
    // [CN] 旧音效随其对象释放。nil 或无法播放的文件：使用点击声。
    CYLTabBarTapSound *sound = tabButtonTapSoundURL ? [[CYLTabBarTapSound alloc] initWithURL:tabButtonTapSoundURL] : nil;
#if defined(DEBUG) || defined(BETA)
    if (tabButtonTapSoundURL && !sound) {
        NSLog(@"🔴 %@ %@", @(__PRETTY_FUNCTION__), tabButtonTapSoundURL);
    }
#endif
    objc_setAssociatedObject(self, @selector(cyl_tabButtonTapSoundURL), sound, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_tabButtonHapticFeedbackEnabled {
    return [objc_getAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackEnabled)) boolValue];
}

- (void)cyl_setTabButtonHapticFeedbackEnabled:(BOOL)tabButtonHapticFeedbackEnabled {
    objc_setAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackEnabled), @(tabButtonHapticFeedbackEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // [EN] A new generator for the current style, prepared so the first tap has no delay.
    // [CN] 为当前强度新建反馈器并预先准备，第一次点击没有延迟。
    objc_setAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackGenerator), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (tabButtonHapticFeedbackEnabled) {
        [[self cyl_tabButtonHapticFeedbackGenerator] prepare];
    }
}

- (UIImpactFeedbackStyle)cyl_tabButtonHapticFeedbackStyle {
    NSNumber *style = objc_getAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackStyle));
    return style ? (UIImpactFeedbackStyle)style.integerValue : UIImpactFeedbackStyleMedium;
}

- (void)cyl_setTabButtonHapticFeedbackStyle:(UIImpactFeedbackStyle)tabButtonHapticFeedbackStyle {
    objc_setAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackStyle), @(tabButtonHapticFeedbackStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackGenerator), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImpactFeedbackGenerator *)cyl_tabButtonHapticFeedbackGenerator {
    UIImpactFeedbackGenerator *generator = objc_getAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackGenerator));
    if (!generator) {
        generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:self.cyl_tabButtonHapticFeedbackStyle];
        objc_setAssociatedObject(self, @selector(cyl_tabButtonHapticFeedbackGenerator), generator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return generator;
}

- (void)cyl_playTabButtonTapFeedback {
    if (self.cyl_tabButtonTapSoundEnabled) {
        CYLTabBarTapSound *sound = objc_getAssociatedObject(self, @selector(cyl_tabButtonTapSoundURL));
        AudioServicesPlaySystemSound(sound ? sound.soundID : CYLTabBarDefaultTapSoundID);
    }
    if (self.cyl_tabButtonHapticFeedbackEnabled) {
        UIImpactFeedbackGenerator *generator = [self cyl_tabButtonHapticFeedbackGenerator];
        [generator impactOccurred];
        // [EN] Ready for the next tap. [CN] 为下一次点击做准备。
        [generator prepare];
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

#pragma mark - Liquid Glass (issue #152 / #535)

/*!
 * [EN] YES in Liquid Glass with a `CYLTabBar` whose UIKit gestures were captured: tab button touches then come through
 *      `-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`, not through the library's own long press recognizer.
 * [CN] 液态玻璃下、且 `CYLTabBar` 已拿到系统手势时为 YES：此时 Tab 按钮的触摸经由 `-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`，
 *      而不是库自己的长按手势。
 */
- (BOOL)cyl_liquidGlassReceivesTabTouches {
    if (![CYLConstants isLiquidGlassActive] || ![self.tabBar isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    CYLTabBar *tabBar = (CYLTabBar *)self.tabBar;
    return tabBar.liquidGlassContinuousGestureRecognizer != nil || tabBar.liquidGlassLongGestureRecognizer != nil;
}

/*!
 * [EN] YES once a Liquid Glass press was followed: tab taps are then counted when the press ends
 *      (`-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`), which knows whether it was a tap, a long press or a drag;
 *      `-tabBarController:shouldSelectViewController:` no longer counts them.
 * [CN] 一旦跟踪过液态玻璃的触摸即为 YES：此后 Tab 的点击在触摸结束时计数（`-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`），
 *      那里知道这次是点击、长按还是拖动；`-tabBarController:shouldSelectViewController:` 不再计数。
 */
- (BOOL)cyl_liquidGlassTakesTabTaps {
    return [self cyl_liquidGlassReceivesTabTouches] && [objc_getAssociatedObject(self, CYLLiquidGlassSeenKey) boolValue];
}

/*!
 * [EN] The tab button under `windowPoint` in Liquid Glass, found by position (Liquid Glass layers can answer
 *      `hitTest` instead of the buttons): the vertical bar's buttons (iOS 27.1), else a visible button whose frame holds
 *      the point, else, inside the tab bar, the one whose center is closest horizontally. Placeholders are skipped; the
 *      selected layer's copy and the tab under the plus button are reported as `-tabBarController:didSelectControl:` does.
 * [CN] 液态玻璃下 `windowPoint` 处的 Tab 按钮，按位置查找（液态玻璃的图层可能代替按钮响应 `hitTest`）：先查竖向栏的按钮（iOS 27.1），
 *      再查 frame 包含该点的可见按钮，最后在 TabBar 范围内取水平方向中心最近的按钮。跳过占位按钮；选中图层中的副本与 PlusButton 下方的
 *      Tab 按 `-tabBarController:didSelectControl:` 的方式上报。
 */
- (nullable UIControl *)cyl_liquidGlassTabControlAtWindowPoint:(CGPoint)windowPoint {
    CYLTabBar *tabBar = (CYLTabBar *)self.tabBar;
    if (![tabBar isKindOfClass:[CYLTabBar class]] || !tabBar.window || tabBar.hidden) {
        return nil;
    }
    UIControl *control = [tabBar cyl_verticalBarTabButtonAtWindowPoint:windowPoint];
    if (!control) {
        UIControl *closestControl = nil;
        CGFloat closestDistance = CGFLOAT_MAX;
        for (UIControl *candidate in [tabBar cyl_visibleControls]) {
            if (candidate.hidden || candidate.alpha < 0.01 || !candidate.window || candidate.cyl_isPlaceholder) {
                continue;
            }
            CGRect frame = [candidate convertRect:candidate.bounds toView:nil];
            if (CGRectContainsPoint(frame, windowPoint)) {
                control = candidate;
                break;
            }
            CGFloat distance = fabs(CGRectGetMidX(frame) - windowPoint.x);
            if (distance < closestDistance) {
                closestDistance = distance;
                closestControl = candidate;
            }
        }
        if (!control && CGRectContainsPoint([tabBar convertRect:tabBar.bounds toView:nil], windowPoint)) {
            control = closestControl;
        }
    }
    if (!control) {
        return nil;
    }
    if ([control cyl_isPlatterSelectedControl]) {
        control = [control cyl_platterNormalControl];
    }
    return [self cyl_reportedControlForControl:control] ?: control;
}

- (nullable CYLTabBarLiquidGlassPress *)cyl_liquidGlassPress {
    return objc_getAssociatedObject(self, CYLLiquidGlassPressKey);
}

/*!
 * [EN] Called by `CYLTabBar` for every update of UIKit's Liquid Glass gestures. See `CYLTabBarLiquidGlassPress`.
 *      A plus button keeps its own paths (its touch-up and the library's long press recognizer).
 * [CN] `CYLTabBar` 对系统液态玻璃手势的每次更新调用。见 `CYLTabBarLiquidGlassPress`。PlusButton 仍走自己的路径（抬起事件与库的长按手势）。
 */
- (void)cyl_liquidGlassTabBarGestureRecognizerDidUpdate:(UIGestureRecognizer *)gestureRecognizer {
    BOOL handlesLongPress = [self cyl_handlesTabButtonLongPress];
    BOOL handlesTaps = [self cyl_hasTabBarItemGestureReceiver];
    if ((!handlesLongPress && !handlesTaps) || ![self cyl_liquidGlassReceivesTabTouches]) {
        return;
    }
    CYLTabBarLiquidGlassPress *press = [self cyl_liquidGlassPress];
    UIWindow *window = self.view.window;
    CGPoint windowPoint = [gestureRecognizer locationInView:window];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // [EN] Both UIKit gestures can begin for the same touch: follow the first one.
            // [CN] 同一次触摸中两个系统手势都可能开始：只跟踪先开始的那个。
            UIGestureRecognizerState followedState = press.gestureRecognizer.state;
            if (press.gestureRecognizer && press.gestureRecognizer != gestureRecognizer &&
                (followedState == UIGestureRecognizerStateBegan || followedState == UIGestureRecognizerStateChanged)) {
                return;
            }
            UIControl *control = [self cyl_liquidGlassTabControlAtWindowPoint:windowPoint];
            if (!control || [control cyl_isPlusButton]) {
                objc_setAssociatedObject(self, CYLLiquidGlassPressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                return;
            }
            objc_setAssociatedObject(self, CYLLiquidGlassSeenKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CYLTabBarLiquidGlassPress *newPress = [[CYLTabBarLiquidGlassPress alloc] init];
            newPress.gestureRecognizer = gestureRecognizer;
            newPress.control = control;
            newPress.selectedViewControllerAtTouchDown = self.selectedViewController;
            newPress.windowStartPoint = windowPoint;
            newPress.generation = press.generation + 1;
            objc_setAssociatedObject(self, CYLLiquidGlassPressKey, newPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (handlesLongPress) {
                [self cyl_scheduleLiquidGlassLongPressForPress:newPress];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (press.gestureRecognizer != gestureRecognizer) {
                return;
            }
            CGFloat dx = windowPoint.x - press.windowStartPoint.x;
            CGFloat dy = windowPoint.y - press.windowStartPoint.y;
            if (sqrt(dx * dx + dy * dy) > CYLLiquidGlassPressAllowableMovement) {
                // [EN] A drag across the tabs (UIKit switches the tab on lift): neither a tap nor a long press.
                // [CN] 在 Tab 间拖动（系统在抬起时切换）：既不算点击也不算长按。
                press.moved = YES;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            if (press.gestureRecognizer != gestureRecognizer) {
                return;
            }
            objc_setAssociatedObject(self, CYLLiquidGlassPressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIControl *control = press.control;
            if (handlesTaps && control && !press.moved && !press.longPressReported) {
                [self cyl_recognizeLiquidGlassTapOnControl:control selectedViewControllerAtTouchDown:press.selectedViewControllerAtTouchDown];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            if (press.gestureRecognizer == gestureRecognizer) {
                objc_setAssociatedObject(self, CYLLiquidGlassPressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            break;
        }
        default:
            break;
    }
}

/*!
 * [EN] Reports the long press when the press is still held, and has not moved, after the long press duration.
 *      While a `didLongPressControl` listener is set, UIKit's gesture is then cancelled, so lifting the finger does not
 *      select the tab, as that API documents (#535); with only `CYLTabBarItemGestureLongPress` it still does (#152).
 * [CN] 经过长按时长后，触摸仍在按住且未移动时上报长按。设置了 `didLongPressControl` 监听时，随后取消系统手势，
 *      抬起手指时不会选中该 Tab（与该 API 的文档一致，#535）；只使用 `CYLTabBarItemGestureLongPress` 时仍会选中（#152）。
 */
- (void)cyl_scheduleLiquidGlassLongPressForPress:(CYLTabBarLiquidGlassPress *)press {
    NSUInteger generation = press.generation;
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.cyl_tabButtonLongPressMinimumDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        CYLTabBarLiquidGlassPress *currentPress = [strongSelf cyl_liquidGlassPress];
        UIGestureRecognizer *gestureRecognizer = currentPress.gestureRecognizer;
        UIControl *control = currentPress.control;
        if (!strongSelf || currentPress.generation != generation || currentPress.moved || !control || !gestureRecognizer) {
            return;
        }
        UIGestureRecognizerState state = gestureRecognizer.state;
        if (state != UIGestureRecognizerStateBegan && state != UIGestureRecognizerStateChanged) {
            return;
        }
        currentPress.longPressReported = YES;
        [strongSelf cyl_reportLongPressOnControl:control];
        if ([strongSelf cyl_handlesDidLongPressControl] && gestureRecognizer.enabled) {
            gestureRecognizer.enabled = NO;
            gestureRecognizer.enabled = YES;
        }
    });
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
 * FIX: issue #19 / #118
 * [EN] YES when `viewController` needs login while logged out; the login is started (as a tap does).
 * [CN] `viewController` 需要登录且当前未登录时为 YES，并发起登录（与点击相同）。
 */
- (BOOL)cyl_swipeNeedsLoginForViewController:(UIViewController *)viewController {
    return [self cyl_interceptLoginIfNeededForViewController:viewController];
}

/*!
 * [EN] Asks the delegate, as a tap does (the login check is `-cyl_swipeNeedsLoginForViewController:`). The tab bar controller's own
 *      `-tabBarController:shouldSelectViewController:` runs the login check itself.
 * [CN] 与点击一样询问代理（登录检查见 `-cyl_swipeNeedsLoginForViewController:`）。TabBarController 自身的
 *      `-tabBarController:shouldSelectViewController:` 会自己做登录检查。
 */
- (BOOL)cyl_shouldSwipeSelectViewController:(UIViewController *)viewController {
    id<UITabBarControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        // [EN] A swipe is a tap on the tab it selects: the delegate, `-tabBarController:didSelectControl:`, the tap
        //      animation, sound and haptic, and Reselect / DoubleTap (issue #152) all see it as one.
        // [CN] 滑动等同于点击它所选中的 Tab：代理、`-tabBarController:didSelectControl:`、点击动画、声音与触感反馈，
        //      以及 Reselect / DoubleTap（issue #152）都把它当作一次点击。
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
    // FIX: issue #118
    // [EN] One switch at a time: a swipe during the slide (or during a UIKit transition) is ignored, as
    //      LxTabBarController learned (its issue #2: a tap during the transition crashed).
    // [CN] 同一时间只切换一次：滑动动画（或系统转场）进行中的滑动会被忽略，借鉴 LxTabBarController（其 issue #2：转场中点击导致崩溃）。
    if ([objc_getAssociatedObject(self, @selector(cyl_switchToAdjacentTabWithStep:animated:)) boolValue] || self.transitionCoordinator) {
        return NO;
    }
    NSInteger direction = step > 0 ? 1 : -1;
    NSInteger index = (NSInteger)selectedIndex + direction;
    UIViewController *toViewController = nil;
    // [EN] The next tab that can be selected. A tab the delegate refuses (e.g. a plus button's tab that only the plus
    //      button opens) is skipped; a tab that needs login stops the swipe there and starts the login, as a tap does.
    // [CN] 下一个可以选中的 Tab。代理拒绝的 Tab（例如只能由 PlusButton 打开的 Tab）会被跳过；需要登录的 Tab 与点击一样，
    //      停在该处并发起登录。
    for (; index >= 0 && index < (NSInteger)viewControllers.count; index += direction) {
        UIViewController *candidate = viewControllers[index];
        if (![self cyl_canSwipeToViewController:candidate]) {
            continue;
        }
        if ([self cyl_swipeNeedsLoginForViewController:candidate]) {
            return NO;
        }
        // [EN] A plus button with a child view controller is a tab too: a swipe selects its page, as a tap on the plus
        //      button does (that tap does not ask the delegate either). Without a child view controller the plus button
        //      has no page, and its placeholder tab was skipped above.
        // [CN] 带子控制器的 PlusButton 也是一个 Tab：滑动选中其页面，与点击 PlusButton 相同（点击 PlusButton 同样不询问代理）。
        //      没有子控制器时 PlusButton 没有页面，其占位 Tab 已在上面跳过。
        BOOL isPlusChildViewController = [self hasPlusChildViewController] &&
            [candidate cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]];
        if (isPlusChildViewController || [self cyl_shouldSwipeSelectViewController:candidate]) {
            toViewController = candidate;
            break;
        }
    }
    if (!toViewController) {
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
    objc_setAssociatedObject(self, @selector(cyl_switchToAdjacentTabWithStep:animated:), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toView.transform = CGAffineTransformIdentity;
        snapshotView.transform = CGAffineTransformMakeTranslation(-width * direction, 0);
    } completion:^(BOOL finished) {
        toView.transform = CGAffineTransformIdentity;
        [snapshotView removeFromSuperview];
        if (weakSelf) {
            objc_setAssociatedObject(weakSelf, @selector(cyl_switchToAdjacentTabWithStep:animated:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
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

/// [EN] YES when the table view of `cell` offers swipe actions on its rows. [CN] `cell` 所在 tableView 的行支持侧滑操作时为 YES。
static BOOL CYLTableViewCellHasSwipeActions(UITableViewCell *cell) {
    UIView *superview = cell.superview;
    while (superview && ![superview isKindOfClass:[UITableView class]]) {
        superview = superview.superview;
    }
    UITableView *tableView = (UITableView *)superview;
    if (!tableView) {
        return NO;
    }
    id<UITableViewDelegate> delegate = tableView.delegate;
    id<UITableViewDataSource> dataSource = tableView.dataSource;
    return [delegate respondsToSelector:@selector(tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:)] ||
           [delegate respondsToSelector:@selector(tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:)] ||
           [dataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)];
}

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
        // FIX: issue #118
        // [EN] A table view cell that can be swiped to show actions (e.g. Delete) keeps the horizontal swipe: this was
        //      a known conflict of the scroll-view based WXTabBarController (its issues #5 and #15).
        // [CN] 可以侧滑显示操作（例如删除）的 tableView cell 保留水平滑动：这是基于 scrollView 的 WXTabBarController 的已知冲突
        //      （其 issue #5 与 #15）。
        if ([current isKindOfClass:[UITableViewCell class]] && CYLTableViewCellHasSwipeActions((UITableViewCell *)current)) {
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
        // [EN] In Liquid Glass the tab buttons' long press comes from UIKit's own gestures
        //      (`-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`); this recognizer keeps only the plus button there.
        // [CN] 液态玻璃下 Tab 按钮的长按来自系统手势（`-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`）；此时本手势只处理 PlusButton。
        if (control && ![control cyl_isPlusButton] && [tabBarController cyl_liquidGlassReceivesTabTouches]) {
            return NO;
        }
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
