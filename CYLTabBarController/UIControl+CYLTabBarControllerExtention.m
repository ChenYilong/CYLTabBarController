//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIControl+CYLTabBarControllerExtention.h"
#import <objc/runtime.h>
#import "UIView+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import "CYLTabBarController.h"

#if __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#else
#endif

#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
#else
#endif

#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "CYLPlusButton.h"

/*!
 * FIX: issue #653 (iPhone Duo, vertical bar)
 * [EN] Keeps views that CYL adds to a tab button (Lottie icon, selected cover, badge point) at a point
 *      derived from the button's own subviews, using frames instead of Auto Layout.
 *      Any constraint inside a tab button pulls the whole tab bar platter into Auto Layout. On iOS 27.1,
 *      when the system moves the tab bar to the vertical bar (folded iPhone Duo with `allowsVerticalBar = YES`),
 *      the platter is hosted by a SwiftUI toolbar that then sizes it to the whole free area (a tall panel
 *      over the content) instead of its natural size.
 *      The tracker fills the tab button (flexible width and height), so its `-layoutSubviews` runs whenever the
 *      button is resized, e.g. when it moves between the horizontal and the vertical bar, and re-centres the views.
 * [CN] 让 CYL 添加到 Tab 按钮上的视图（Lottie 图标、选中遮罩、红点）用 frame 跟随按钮内的参照视图，不再使用 Auto Layout。
 *      Tab 按钮内只要有约束，整个 TabBar 的 platter 都会进入 Auto Layout。iOS 27.1 系统把 TabBar 放到竖向栏时
 *      （iPhone Duo 折叠且 `allowsVerticalBar = YES`），platter 由 SwiftUI 工具栏承载，会被撑满整个可用区域，
 *      变成盖住内容的竖长面板，而不是按内容大小显示。
 *      tracker 铺满 Tab 按钮（宽高自适应），按钮尺寸变化（如横向栏与竖向栏之间切换）时触发 `-layoutSubviews`，重新定位这些视图。
 */
typedef CGPoint (^_CYLTabButtonCenterProvider)(UIControl *tabButton);

@interface _CYLTabButtonLayoutTracker : UIView
+ (instancetype)cyl_trackerForTabButton:(UIControl *)tabButton;
- (void)cyl_trackView:(UIView *)view centerProvider:(_CYLTabButtonCenterProvider)centerProvider;
/// Moves `view`'s placement to `newView` (e.g. a Lottie view swapped for its Dark Mode version, #442).
- (void)cyl_replaceTrackedView:(UIView *)view withView:(UIView *)newView;
@end

@implementation _CYLTabButtonLayoutTracker {
    NSMapTable<UIView *, _CYLTabButtonCenterProvider> *_centerProviders;
}

+ (instancetype)cyl_trackerForTabButton:(UIControl *)tabButton {
    for (UIView *subview in tabButton.subviews) {
        if ([subview isKindOfClass:self]) {
            return (_CYLTabButtonLayoutTracker *)subview;
        }
    }
    _CYLTabButtonLayoutTracker *tracker = [[self alloc] initWithFrame:tabButton.bounds];
    tracker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tracker.userInteractionEnabled = NO;
    tracker.backgroundColor = UIColor.clearColor;
    [tabButton insertSubview:tracker atIndex:0];
    return tracker;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _centerProviders = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)cyl_replaceTrackedView:(UIView *)view withView:(UIView *)newView {
    _CYLTabButtonCenterProvider centerProvider = view ? [_centerProviders objectForKey:view] : nil;
    if (!centerProvider || !newView) { return; }
    [_centerProviders removeObjectForKey:view];
    [self cyl_trackView:newView centerProvider:centerProvider];
}

- (void)cyl_trackView:(UIView *)view centerProvider:(_CYLTabButtonCenterProvider)centerProvider {
    if (!view || !centerProvider) { return; }
    [_centerProviders setObject:[centerProvider copy] forKey:view];
    [self cyl_updateTrackedView:view];
}

- (void)cyl_updateTrackedView:(UIView *)view {
    UIControl *tabButton = (UIControl *)self.superview;
    _CYLTabButtonCenterProvider centerProvider = [_centerProviders objectForKey:view];
    if (!centerProvider || ![tabButton isKindOfClass:UIControl.class] || view.superview != tabButton) { return; }
    CGPoint center = centerProvider(tabButton);
    if (isnan(center.x) || isnan(center.y) || CGPointEqualToPoint(view.center, center)) { return; }
    view.center = center;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIView *view in _centerProviders.keyEnumerator.allObjects) {
        [self cyl_updateTrackedView:view];
    }
}

@end

/// [EN] Converts `view`'s centre (plus `offset`) to `tabButton`'s coordinates; falls back to the button's centre.
/// [CN] 把 `view` 的中心点（加 `offset`）转换到 `tabButton` 坐标系；取不到时用按钮中心。
static CGPoint CYLTabButtonPointInView(UIControl *tabButton, UIView *view, CGPoint pointInView) {
    if (!view || !view.superview) {
        return CGPointMake(CGRectGetMidX(tabButton.bounds), CGRectGetMidY(tabButton.bounds));
    }
    return [view convertPoint:pointInView toView:tabButton];
}

/*!
 * FIX: issue #653 / #662
 * [EN] Places `newView` (fixed size) by frame: centre X on `imageView`, centre Y on `replacedView`, plus `offset` —
 *      the same placement as the former Auto Layout constraints. Calling it again for a view that is already tracked
 *      replaces its offset (e.g. the FlatDesign plus button's vertical offset depends on the tab bar height, which
 *      changes when the iPhone Duo folds or unfolds) and re-centres it at once.
 * [CN] 用 frame 定位 `newView`（固定尺寸）：X 中心对齐 `imageView`，Y 中心对齐 `replacedView`，再加 `offset`，与原约束一致。
 *      对已跟踪的视图再次调用会替换其偏移量（如扁平样式加号按钮的纵向偏移依赖 TabBar 高度，iPhone Duo 折叠/展开时会变化）并立即重新定位。
 */
static void CYLTrackViewInTabButton(UIControl *tabBarButton, UIView *newView, CGSize newViewSize, UIView *imageView, UIView *replacedView, UIOffset offset) {
    newView.translatesAutoresizingMaskIntoConstraints = YES;
    if (newViewSize.width > 0 && newViewSize.height > 0) {
        newView.bounds = (CGRect){CGPointZero, newViewSize};
    }
    __weak UIView *weakImageView = imageView;
    __weak UIView *weakReplacedView = replacedView;
    [[_CYLTabButtonLayoutTracker cyl_trackerForTabButton:tabBarButton] cyl_trackView:newView centerProvider:^CGPoint(UIControl *tabButton) {
        UIView *imageView = weakImageView;
        UIView *replaced = weakReplacedView ?: imageView;
        CGPoint centerX = CYLTabButtonPointInView(tabButton, imageView, CGPointMake(CGRectGetMidX(imageView.bounds), CGRectGetMidY(imageView.bounds)));
        CGPoint centerY = CYLTabButtonPointInView(tabButton, replaced, CGPointMake(CGRectGetMidX(replaced.bounds), CGRectGetMidY(replaced.bounds)));
        return CGPointMake(centerX.x + offset.horizontal, centerY.y + offset.vertical);
    }];
}

@implementation UIControl (CYLTabBarControllerExtention)

- (BOOL)cyl_isChildViewControllerPlusButton {
    if (![CYLPlusButton plusChildViewControllerForOwner:self].cyl_plusViewControllerEverAdded) {
        return NO;
    }
    BOOL isChildViewControllerPlusButton = ([self cyl_isPlusButton] && [CYLPlusButton plusChildViewControllerForOwner:self].cyl_plusViewControllerEverAdded);
    if (isChildViewControllerPlusButton) {
        return YES;
    }
    
    if ([CYLPlusButton plusButtonForOwner:self].cyl_tabBarItemVisibleIndex == self.cyl_tabBarItemVisibleIndex) {
        return YES;
    }
    return isChildViewControllerPlusButton;
}

- (void)cyl_setUserInteractionDisabled:(BOOL)cyl_userInteractionDisabled {
    [self cyl_setShouldNotSelect:cyl_userInteractionDisabled];
}

- (BOOL)cyl_userInteractionDisabled {
    return self.cyl_shouldNotSelect;
}

- (BOOL)cyl_shouldNotSelect {
    NSNumber *shouldNotSelectObject = objc_getAssociatedObject(self, @selector(cyl_shouldNotSelect));
    return [shouldNotSelectObject boolValue];
}

- (void)cyl_setShouldNotSelect:(BOOL)shouldNotSelect {
    NSNumber *shouldNotSelectObject = @(shouldNotSelect);
    objc_setAssociatedObject(self, @selector(cyl_shouldNotSelect), shouldNotSelectObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_tabBarItemVisibleIndex {
    if (!self.cyl_isTabButton && !self.cyl_isPlusButton) {
        return NSNotFound;
    }
    NSNumber *tabBarItemVisibleIndexObject = objc_getAssociatedObject(self, @selector(cyl_tabBarItemVisibleIndex));
    return [tabBarItemVisibleIndexObject integerValue];
}

- (void)cyl_setTabBarItemVisibleIndex:(NSInteger)tabBarItemVisibleIndex {
    NSNumber *tabBarItemVisibleIndexObject = [NSNumber numberWithInteger:tabBarItemVisibleIndex];
    objc_setAssociatedObject(self, @selector(cyl_tabBarItemVisibleIndex), tabBarItemVisibleIndexObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_tabBarChildViewControllerIndex {
    if (!self.cyl_isTabButton && !self.cyl_isPlusButton ) {
        return NSNotFound;
    }
    NSNumber *tabBarChildViewControllerIndexObject = objc_getAssociatedObject(self, @selector(cyl_tabBarChildViewControllerIndex));
    return [tabBarChildViewControllerIndexObject integerValue];
}

- (void)cyl_setTabBarChildViewControllerIndex:(NSInteger)tabBarChildViewControllerIndex {
    NSNumber *tabBarChildViewControllerIndexObject = [NSNumber numberWithInteger:tabBarChildViewControllerIndex];
    objc_setAssociatedObject(self, @selector(cyl_tabBarChildViewControllerIndex), tabBarChildViewControllerIndexObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_setTabBarItemIdentifier:(NSString *)tabBarItemIdentifier {
    objc_setAssociatedObject(self, @selector(cyl_tabBarItemIdentifier), [tabBarItemIdentifier copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)cyl_tabBarItemIdentifier {
    NSString *identifier = objc_getAssociatedObject(self, @selector(cyl_tabBarItemIdentifier));
    if (identifier) {
        return identifier;
    }
    // A plus button: its class's identifier, the same for every tab bar controller's copy. 多 TabBar 的副本共用。
    if ([self cyl_isPlusButton]) {
        if ([self.class respondsToSelector:@selector(tabBarItemIdentifier)]) {
            identifier = [(Class<CYLPlusButtonSubclassing>)self.class tabBarItemIdentifier];
        }
        // Not implemented: the class name, e.g. "CYLPlusButtonSubclass". 未实现时为类名。
        return identifier.length > 0 ? identifier : [CYLTabBarController cyl_defaultTabBarItemIdentifierForClass:self.class];
    }
#if CYL_FLATDESIGN_AVAILABLE
    // A flat design tab button knows its tab through its item: it has no `cyl_tabBarChildViewControllerIndex`, and is not a
    // `cyl_isTabButton` under Liquid Glass. The one under the plus button is the plus child view controller's tab, whose
    // identifier is the plus button's. 扁平样式的 Tab 按钮通过其 item 找到 Tab：它没有 `cyl_tabBarChildViewControllerIndex`，
    // 液态玻璃下也不算 `cyl_isTabButton`。PlusButton 下方的按钮对应 PlusButton 子控制器，其标识即 PlusButton 的标识。
    if ([self isKindOfClass:[CYLFlatDesignTabBarButton class]]) {
        return ((CYLFlatDesignTabBarButton *)self).tabBarItem.childViewController.cyl_tabBarItemIdentifier;
    }
#endif
    NSInteger index = self.cyl_tabBarChildViewControllerIndex;
    NSArray<UIViewController *> *viewControllers = self.cyl_tabBarController.viewControllers;
    if (index < 0 || index == NSNotFound || index >= (NSInteger)viewControllers.count) {
        return nil;
    }
    return viewControllers[index].cyl_tabBarItemIdentifier;
}

- (BOOL)cyl_isLottieReady {
    if (self.cyl_tabBarController.lottieURLs.count > 0) {
        return self.cyl_tabBarController.lottieViewAdded;
    }
    if (self.cyl_lottieAnimationView) {
        UIView *view = (UIView *)self.cyl_lottieAnimationView;
        if (view && [view respondsToSelector:@selector(frame)]) {
            return view.frame.size.width > 10;
        }
    }
    return NO;
}

- (BOOL)cyl_isSelected {
    NSUInteger tabBarSelectedIndex = self.cyl_tabBarController.selectedIndex;
    NSUInteger tabBarChildViewControllerIndex = self.cyl_tabBarChildViewControllerIndex;
    BOOL isSelected = (tabBarSelectedIndex == tabBarChildViewControllerIndex) && self.selected;
    
    if (self.cyl_tabBarController.tabBar.cyl_hasPlusChildViewController) {
        isSelected = isSelected && [CYLPlusButton plusChildViewControllerForOwner:self].cyl_plusViewControllerEverAdded;
    }
    return isSelected;
}

- (BOOL)cyl_isPlusControl {
    return [CYLPlusButton isPlusButtonView:self] || [self cyl_isChildViewControllerPlusButton];
}

- (nullable UIView *)cyl_lottieAnimationView {
    if ([self cyl_isPlusControl]) {
        return nil;
    }
    UIView *animationView = nil;
    for (UIView *subview in self.subviews) {
        if ([subview cyl_isLottieAnimationView]) {
            animationView = subview;
            return animationView;
        }
        for (UIView *subsubview in subview.subviews) {
            if ([subsubview cyl_isLottieAnimationView]) {
                animationView = subsubview;
                return animationView;
            }
        }
    }
    return nil;
}

#define cyl_replaceTabImageViewWithNewViewcyl_isReadydelaySeconds 0
- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                      show:(BOOL)show {
    [self cyl_replaceTabImageViewWithNewView:newView offset:UIOffsetZero show:show completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
    }];
}

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:NO newView:newView offset:offset show:theShow shouldAutoHideNewView:YES completion:completion];
}

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                 offset:(UIOffset)offset
                                   show:(BOOL)theShow
                             completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:YES newView:newView offset:offset show:theShow shouldAutoHideNewView:YES completion:completion];
}

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                   show:(BOOL)show {
    [self cyl_replaceTabButtonWithNewView:newView offset:UIOffsetZero show:show completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
        if (isReplaced) {
            tabBarButton.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
        }
    }];
}

- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                  contentNewView:(UIView *)contentNewView
                           seclectContentNewView:(UIView *)seclectContentNewView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_coverTabImageViewOrTabButton:isTabButton newView:contentNewView offset:offset show:theShow delayIfNeededForSeconds:delay completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull theNewView) {
        if (isReplaced && tabBarButton.cyl_platterSelectedControl)  {
            [tabBarButton cyl_coverSeclectContentTabImageViewOrTabButton:isTabButton newView:seclectContentNewView offset:offset show:theShow delayIfNeededForSeconds:delay completion:^(BOOL theTheIsReplaced, UIControl *theTheTabBarButton, UIView *theTheNewView) {
                !completion?:completion(theTheIsReplaced, theTheTabBarButton, theTheNewView);
            }];
        } else
            !completion?:completion(isReplaced, tabBarButton, theNewView);
    }];
}

- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                         newView:(UIView *)newView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_coverSeclectContentTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow delayIfNeededForSeconds:delay completion:completion];
}

- (void)cyl_coverSeclectContentTabImageViewOrTabButton:(BOOL)isTabButton
                                               newView:(UIView *)newView
                                                offset:(UIOffset)offset
                                                  show:(BOOL)theShow
                               delayIfNeededForSeconds:(CGFloat)delay
                                            completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [(self.cyl_platterSelectedControl ?: self) cyl_coverTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow delayIfNeededForSeconds:delay completion:completion];
}

- (void)cyl_coverTabImageViewOrTabButton:(BOOL)isTabButton
                                 newView:(UIView *)newView
                                  offset:(UIOffset)offset
                                    show:(BOOL)theShow
                 delayIfNeededForSeconds:(CGFloat)delay
                              completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    UIControl *selectedTabButton = self;
    // NSTimeInterval, not NSUInteger: callers pass fractions (0.1, 0.5), which an integer type truncated to 0,
    // so a Lottie tab that was not ready yet was never waited for.
    // 必须是 NSTimeInterval：调用方传入的是小数（0.1、0.5），用整型会截断为 0，导致 Lottie 未就绪时从不等待。
    NSTimeInterval delaySeconds = selectedTabButton.cyl_isReady ? 0 : MAX(delay, 0);
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        // [CN] 如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
        // [EN] Lottie animation icons need a delay; otherwise the replacement happens before the lottie animation has
        //      finished initializing, and the position is wrong.
        [self cyl_replaceTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow shouldAutoHideNewView:NO shouldHideOriginalView:NO completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
            //FIXME:  #480
            if (isReplaced) {
                tabBarButton.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
                // tabBarButton.cyl_platterNormalControl.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
                [tabBarButton.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

                    if (![obj isEqual:newView] && ![obj isKindOfClass:[_CYLTabButtonLayoutTracker class]]) {
                        [obj cyl_setHidden:theShow];
                    }
                }];
            }
            if (theShow) {
                //                [tabBarButton cyl_clearBadge];
                [tabBarButton cyl_performSelector:@selector(cyl_clearBadge)];
            } else {
                [tabBarButton cyl_performSelector:@selector(cyl_resumeBadge)];
                
            }
            !completion?:completion(isReplaced, tabBarButton, newView);
            
        }];
    });
}

- (void)cyl_replaceTabImageViewOrTabButton:(BOOL)isTabButton
                                   newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                     shouldAutoHideNewView:(BOOL)shouldAutoHideNewView
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow shouldAutoHideNewView:shouldAutoHideNewView shouldHideOriginalView:YES completion:completion];
}

- (void)cyl_replaceTabImageViewOrTabButton:(BOOL)isTabButton
                                   newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                     shouldAutoHideNewView:(BOOL)shouldAutoHideNewView
                    shouldHideOriginalView:(BOOL)shouldHideOriginalView
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
//    newView.translatesAutoresizingMaskIntoConstraints = NO;
//    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIControl *tabBarButton = self;//_UI+TabButton
    UIImageView *swappableImageView = tabBarButton.cyl_tabImageView;
    UIView *replacedView = swappableImageView;
    if (isTabButton) {
        replacedView = tabBarButton;
    }
    if (!replacedView) {
        !completion?:completion(NO, self, nil);
        return;
    }
    // [CN] //TODO: 区分cover 与 replace 两个场景， 获取到真实的view，可能是lottie，决定是否限制新视图的尺寸， 目前暂不限制尺寸。 因为主要场景为 cover 场景。cover =( adjustTabBarItemImageViewSizeDependOnSuperView == yes), replace =( adjustTabBarItemImageViewSizeDependOnSuperView == NO)
    // [EN] TODO: Distinguish the cover and replace cases, get the real view (it may be lottie), and decide whether to limit
    //      the new view's size. For now the size is not limited, because cover is the main case.
    //      cover =( adjustTabBarItemImageViewSizeDependOnSuperView == yes), replace =(
    //      adjustTabBarItemImageViewSizeDependOnSuperView == NO)
    if (newView.frame.size.width == 0 || newView.frame.size.height == 0) {
        // [CN] 不再限制newView 是否能超过父视图，因为你可以通过设置size来控制newView的展示大小。
        // [EN] No longer restricts whether newView may exceed its superview, because you can control newView's displayed size
        //      by setting size.
        //        if (newView.frame.size.width > tabBarButton.frame.size.width || newView.frame.size.height > tabBarButton.frame.size.height) {
        newView.frame = ({
            CGRect frame = newView.frame;
            if (self.cyl_tabBarController.adjustTabBarItemImageViewSizeDependOnSuperView) {
                frame.size = tabBarButton.frame.size;
            } else {
                UIImage *image = swappableImageView.image;
                frame.size = CGSizeMake(image.size.width, image.size.height);
            }
            frame;
        });
    }
    BOOL newViewCreated = (newView.superview);
    BOOL newViewAddedToTabButton = [self.subviews containsObject:newView];
    BOOL isNewViewAddedToTabButton = newViewCreated && newViewAddedToTabButton;
    if (newView.superview && !newViewAddedToTabButton) {
        [newView removeFromSuperview];
    }
    if (isNewViewAddedToTabButton && theShow) {
        // FIX: issue #662 — already shown: refresh its placement with the current offset instead of keeping the first one.
        // 已显示：用当前的 offset 刷新定位，而不是一直沿用第一次的值。
        CYLTrackViewInTabButton(tabBarButton, newView, newView.bounds.size, swappableImageView, replacedView, offset);
        !completion?:completion(YES, self, newView);
        return;
    }
    BOOL show = (newView && theShow);
    if (shouldHideOriginalView) {
        swappableImageView.hidden = (show);
    }
    if (isTabButton && shouldHideOriginalView) {
        tabBarButton.cyl_tabLabel.hidden = (show);
    }
    BOOL shouldShowNewView = show && !newView.superview;
    BOOL shouldRemoveNewView = newView.superview;
    if (shouldShowNewView) {
        [tabBarButton addSubview:newView];
        CGSize newViewSize = newView.frame.size;
        CYLTrackViewInTabButton(tabBarButton, newView, newViewSize, swappableImageView, replacedView, offset);
        !completion?:completion(YES, self, newView);
        return;
    }
    if (shouldRemoveNewView && shouldAutoHideNewView) {
        [newView removeFromSuperview];
        newView = nil;
        !completion?:completion(NO, self, nil);
        return;
    }
    //    });
    !completion?:completion(NO, self, nil);
}

- (void)cyl_addLottieImageWithLottieURL:(nullable NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode {
    NSString *lottieFilePath = [lottieURL path];
    [self cyl_addLottieImageWithLottieFilePath:lottieFilePath size:size contentMode:contentMode];
}

#if CYL_LOTTIE_AVAILABLE
static UIView *CYLMakeLottieAnimationView(NSURL *sourceURL, NSURL *shownURL, CGSize size, UIViewContentMode contentMode);
static void CYLApplyLottieDarkColors(UIView *lottieView, UITraitCollection *traitCollection);
#endif

- (void)cyl_addLottieImageWithLottieFilePath:(NSString *)lottieFilePath
                                        size:(CGSize)size
                                 contentMode:(UIViewContentMode)contentMode {
    NSURL *lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
    if (!lottieURL) {
        return;
    }
    if ([self cyl_isPlusControl]) {
        return;
    }
#if CYL_LOTTIE_AVAILABLE
    // FIX: Lottie icons invisible in FlatDesign. No `CYLTabBarLottieSize` means a zero size; both Lottie flavors need
    // the placeholder size, otherwise the animation view is 0 x 0. Only compiled with Lottie, so that the analyzer
    // does not report a dead store without it.
    // 未设置 `CYLTabBarLottieSize` 时 size 为 0，两种 Lottie 都需要使用占位尺寸，否则动画视图为 0 x 0（扁平样式下图标不显示）。
    if (CGSizeEqualToSize(CGSizeZero, size)) {
        size = CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
    }
    // FIX: issue #442 — first: does this animation use a #442 key (`CYLTabBarLottieDarkURL` / `…DarkFilePath` /
    // `…DarkColors`)? Without one, everything below is the original path. 首先判断该动画是否使用了 #442 新增的 key；
    // 没有时，下面的逻辑与原来完全相同。
    BOOL followsDarkMode = [CYLConstants cyl_hasDarkLottieForLottieURL:lottieURL];
    UIView *shownLottieView = self.cyl_lottieAnimationView;
    if (shownLottieView) {
        if (followsDarkMode) {
            [self cyl_replaceLottieAnimationView:shownLottieView
                                   withLottieURL:[CYLConstants cyl_lottieURL:lottieURL forTraitCollection:self.traitCollection]
                                       sourceURL:lottieURL];
            CYLApplyLottieDarkColors(self.cyl_lottieAnimationView, self.traitCollection);
        }
        return;
    }
    // The dark animation where the style is dark. 深色风格下使用深色动画。
    NSURL *styleLottieURL = followsDarkMode ? [CYLConstants cyl_lottieURL:lottieURL forTraitCollection:self.traitCollection] : lottieURL;
    UIView *lottieView = CYLMakeLottieAnimationView(lottieURL, styleLottieURL, size, contentMode);
    if (!lottieView) {
        return;
    }
    if (followsDarkMode) {
        CYLApplyLottieDarkColors(lottieView, self.traitCollection);
    }
    [self cyl_replaceTabImageViewWithNewView:lottieView show:YES];
    [self cyl_postLottieAnimationViewDidAddNotification];
#else
    (void)size;
    (void)contentMode;
#endif
}

#pragma mark - Dark Mode Lottie (#442)

#if CYL_LOTTIE_AVAILABLE

static const void *CYLLottieSourceURLKey = &CYLLottieSourceURLKey;
static const void *CYLLottieShownURLKey = &CYLLottieShownURLKey;

/*!
 * [EN] A Lottie view playing `shownURL`, the version of `sourceURL` (the light animation the tab was given) for the
 *      current style. Both are kept on the view, so it can be swapped when the style changes.
 * [CN] 播放 `shownURL` 的 Lottie 视图；`shownURL` 是 `sourceURL`（Tab 设置的浅色动画）在当前风格下的版本。两者都保存在视图上，
 *      以便风格变化时替换。
 */
static UIView *CYLMakeLottieAnimationView(NSURL *sourceURL, NSURL *shownURL, CGSize size, UIViewContentMode contentMode) {
    UIView *lottieView = nil;
    // Each Lottie library behind its own guard, as elsewhere; the first one linked makes the view.
    // 与其他代码一致，每个 Lottie 库各用一个 guard；由先引入的库创建视图。
#if __has_include(<Lottie/Lottie.h>)
    if (!lottieView && [LOTAnimationView instancesRespondToSelector:@selector(initWithContentsOfURL:)]) {
        lottieView = [[LOTAnimationView alloc] initWithContentsOfURL:shownURL];
    }
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    if (!lottieView && [CYLCompatibleLOTAnimationView instancesRespondToSelector:@selector(initWithCompatibleAnimation:)]) {
        CYLCompatibleLOTAnimation *composition = [[CYLCompatibleLOTAnimation alloc] initWithFilepath:shownURL.path];
        lottieView = [[CYLCompatibleLOTAnimationView alloc] initWithCompatibleAnimation:composition];
    }
#endif
    if (!lottieView) {
        return nil;
    }
    lottieView.frame = CGRectMake(0, 0, size.width, size.height);
    lottieView.userInteractionEnabled = NO;
    lottieView.contentMode = contentMode;
    lottieView.translatesAutoresizingMaskIntoConstraints = YES;// FIX: issue #653, see `_CYLTabButtonLayoutTracker`
    [lottieView setClipsToBounds:NO];
    // Remembered only for animations that use a #442 key, to swap them when the style changes.
    // 仅为使用了 #442 新增 key 的动画记录，以便风格变化时替换。
    if ([CYLConstants cyl_hasDarkLottieForLottieURL:sourceURL]) {
        objc_setAssociatedObject(lottieView, CYLLottieSourceURLKey, sourceURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(lottieView, CYLLottieShownURLKey, shownURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return lottieView;
}

/// Copies the playback state (progress, speed) of one Lottie view to another and draws it. Lottie ObjC: by class;
/// Lottie Swift: only what the views respond to. 复制播放状态：Lottie ObjC 按类型判断；Lottie Swift 只调用能响应的方法。
static void CYLCopyLottieAnimationState(UIView *fromView, UIView *toView) {
#if __has_include(<Lottie/Lottie.h>)
    if ([fromView isKindOfClass:[LOTAnimationView class]] && [toView isKindOfClass:[LOTAnimationView class]]) {
        LOTAnimationView *from = (LOTAnimationView *)fromView;
        LOTAnimationView *to = (LOTAnimationView *)toView;
        to.animationSpeed = from.animationSpeed;
        to.animationProgress = from.animationProgress;
        [to forceDrawingUpdate];
        return;
    }
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    CYLCompatibleLOTAnimationView *from = (CYLCompatibleLOTAnimationView *)fromView;
    CYLCompatibleLOTAnimationView *to = (CYLCompatibleLOTAnimationView *)toView;
    if ([from respondsToSelector:@selector(animationSpeed)] && [to respondsToSelector:@selector(setAnimationSpeed:)]) {
        to.animationSpeed = from.animationSpeed;
    }
    if ([from respondsToSelector:@selector(animationProgress)] && [to respondsToSelector:@selector(setAnimationProgress:)]) {
        to.animationProgress = from.animationProgress;
    }
    if ([toView respondsToSelector:@selector(forceDrawingUpdate)]) {
        [toView cyl_performSelector:@selector(forceDrawingUpdate)];
    }
#endif
}

static const void *CYLLottieDarkColorsAppliedKey = &CYLLottieDarkColorsAppliedKey;

/*!
 * FIX: issue #442 — Lottie 4.x only.
 * [EN] Sets the dark colors registered for the view's animation (`CYLTabBarLottieDarkColors`) with Lottie's value
 *      providers where `traitCollection` is dark, and removes them otherwise, so one file follows Dark Mode. Does nothing
 *      when they are already in that state, or without dark colors.
 * [CN] `traitCollection` 为深色时，用 Lottie 的 value provider 设置为该动画注册的深色颜色（`CYLTabBarLottieDarkColors`），否则移除，
 *      使一份文件即可适配深色模式。状态未变化或没有深色颜色时不做处理。
 */
static void CYLApplyLottieDarkColors(UIView *lottieView, UITraitCollection *traitCollection) {
    // First: `CYLTabBarLottieDarkColors` registered with usable values for this animation. 首先：该动画注册了有效的深色颜色。
    NSURL *sourceURL = lottieView ? objc_getAssociatedObject(lottieView, CYLLottieSourceURLKey) : nil;
    NSDictionary<NSString *, UIColor *> *darkColors = sourceURL ? [CYLConstants cyl_lottieDarkColorsForLottieURL:sourceURL] : nil;
    if (darkColors.count == 0) {
        return;
    }
    // Then: Lottie 4.x (Lottie Swift) only. 其次：仅 Lottie 4.x（Lottie Swift）。
#if __has_include(<Lottie/Lottie-Swift.h>)
    // Methods added to `CYLCompatibleLOTAnimationView` for #442: call them only when the view responds to them.
    // #442 为 `CYLCompatibleLOTAnimationView` 新增的方法：仅在视图能响应时调用。
    SEL setColorSelector = @selector(setColorValue:forKeypathString:);
    SEL removeColorSelector = @selector(removeValueProviderForKeypathString:);
    if (![lottieView respondsToSelector:setColorSelector] || ![lottieView respondsToSelector:removeColorSelector]) {
        return;
    }
    BOOL dark = NO;
    if (@available(iOS 13.0, *)) {
        dark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    if ([objc_getAssociatedObject(lottieView, CYLLottieDarkColorsAppliedKey) boolValue] == dark) {
        return;
    }
    [darkColors enumerateKeysAndObjectsUsingBlock:^(NSString *keypath, UIColor *color, BOOL *stop) {
        (void)stop;
        if (![keypath isKindOfClass:[NSString class]] || ![color isKindOfClass:[UIColor class]]) {
            return;
        }
        if (dark) {
            UIColor *resolvedColor = color;
            if (@available(iOS 13.0, *)) {
                resolvedColor = [color resolvedColorWithTraitCollection:traitCollection];
            }
            [lottieView cyl_performSelector:setColorSelector withObject:resolvedColor withObject:keypath];
        } else {
            [lottieView cyl_performSelector:removeColorSelector withObject:keypath];
        }
    }];
    objc_setAssociatedObject(lottieView, CYLLottieDarkColorsAppliedKey, @(dark), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([lottieView respondsToSelector:@selector(forceDrawingUpdate)]) {
        [lottieView cyl_performSelector:@selector(forceDrawingUpdate)];
    }
#else
    (void)traitCollection;
#endif
}

#endif

/*!
 * [EN] Swaps `lottieView` for one playing `lottieURL` in place (frame, layout tracking, visibility, playback state),
 *      unless it already plays it. Only for animations that use a #442 key: `sourceURL` is the light animation the tab
 *      was given (nil: the one recorded on the view).
 * [CN] 若 `lottieView` 播放的不是 `lottieURL`，原地替换为播放 `lottieURL` 的视图（保持位置、布局跟踪、可见性和播放状态）。仅用于
 *      使用了 #442 新增 key 的动画：`sourceURL` 为 Tab 设置的浅色动画（nil 表示视图上记录的那个）。
 */
- (void)cyl_replaceLottieAnimationView:(UIView *)lottieView withLottieURL:(NSURL *)lottieURL sourceURL:(NSURL *)sourceURL {
    // First: an animation that uses a #442 key. 首先：使用了 #442 新增 key 的动画。
    if (![CYLConstants cyl_hasDarkLottieURLs] || !lottieView || !lottieURL) {
        return;
    }
#if CYL_LOTTIE_AVAILABLE
    sourceURL = sourceURL ?: objc_getAssociatedObject(lottieView, CYLLottieSourceURLKey);
    if (![CYLConstants cyl_hasDarkLottieForLottieURL:sourceURL]) {
        return;
    }
    // A view made before the key was set plays the light animation. 设置 key 之前创建的视图播放的是浅色动画。
    NSURL *shownURL = objc_getAssociatedObject(lottieView, CYLLottieShownURLKey) ?: sourceURL;
    UIView *superview = lottieView.superview;
    if (!superview || [shownURL isEqual:lottieURL]) {
        if (!objc_getAssociatedObject(lottieView, CYLLottieSourceURLKey)) {
            objc_setAssociatedObject(lottieView, CYLLottieSourceURLKey, sourceURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(lottieView, CYLLottieShownURLKey, shownURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }
    UIView *newLottieView = CYLMakeLottieAnimationView(sourceURL, lottieURL, lottieView.bounds.size, lottieView.contentMode);
    if (!newLottieView) {
        return;
    }
    newLottieView.center = lottieView.center;
    newLottieView.transform = lottieView.transform;
    newLottieView.autoresizingMask = lottieView.autoresizingMask;
    newLottieView.hidden = lottieView.hidden;
    newLottieView.alpha = lottieView.alpha;
    CYLCopyLottieAnimationState(lottieView, newLottieView);
    [superview insertSubview:newLottieView aboveSubview:lottieView];
    for (UIView *subview in superview.subviews) {
        if ([subview isKindOfClass:[_CYLTabButtonLayoutTracker class]]) {
            [(_CYLTabButtonLayoutTracker *)subview cyl_replaceTrackedView:lottieView withView:newLottieView];
        }
    }
    [lottieView removeFromSuperview];
#else
    (void)sourceURL;
#endif
}

- (void)cyl_reloadLottieAnimationViewForCurrentStyle {
    // First: only when a #442 key is in use. 首先：仅在使用了 #442 新增的 key 时处理。
    if (![CYLConstants cyl_hasDarkLottieURLs]) {
        return;
    }
#if CYL_LOTTIE_AVAILABLE
    UIView *lottieView = self.cyl_lottieAnimationView;
    NSURL *sourceURL = lottieView ? objc_getAssociatedObject(lottieView, CYLLottieSourceURLKey) : nil;
    if (![CYLConstants cyl_hasDarkLottieForLottieURL:sourceURL]) {
        return;
    }
    [self cyl_replaceLottieAnimationView:lottieView
                           withLottieURL:[CYLConstants cyl_lottieURL:sourceURL forTraitCollection:self.traitCollection]
                               sourceURL:sourceURL];
    CYLApplyLottieDarkColors(self.cyl_lottieAnimationView, self.traitCollection);
#endif
}

- (void)cyl_addLottieImageWithLottieURL:(nullable NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode
                         animationSpeed:(CGFloat)animationSpeed {
    BOOL hadLottieAnimationView = (self.cyl_lottieAnimationView != nil);
    [self cyl_addLottieImageWithLottieURL:lottieURL size:size contentMode:contentMode];
    if (!hadLottieAnimationView) {
        [self cyl_setLottieAnimationSpeed:animationSpeed];
    }
}

- (void)cyl_setLottieAnimationSpeed:(CGFloat)animationSpeed {
    if (animationSpeed <= 0) {
        return;
    }
#if __has_include(<Lottie/Lottie.h>)
    LOTAnimationView *lottieView = (LOTAnimationView *)self.cyl_lottieAnimationView;
    if ([lottieView isKindOfClass:[LOTAnimationView class]]) {
        lottieView.animationSpeed = animationSpeed;
    }
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    CYLCompatibleLOTAnimationView *lottieView = (CYLCompatibleLOTAnimationView *)self.cyl_lottieAnimationView;
    if ([lottieView respondsToSelector:@selector(setAnimationSpeed:)]) {
        lottieView.animationSpeed = animationSpeed;
    }
#endif
}

/// FIX: issue #428 — posted asynchronously, so that `-cyl_addLottieImageWithLottieURL:size:contentMode:animationSpeed:`
/// has set the default speed before observers run, and a speed set by an observer is kept.
- (void)cyl_postLottieAnimationViewDidAddNotification {
    __weak UIControl *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIControl *tabButton = weakSelf;
        if (!tabButton.cyl_lottieAnimationView) {
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationViewDidAddNotification object:tabButton];
    });
}

- (void)cyl_animationLottieImageWithLottieURL:(NSURL *)lottieURL
                                         size:(CGSize)size
                              defaultSelected:(BOOL)defaultSelected
                                  contentMode:(UIViewContentMode)contentMode {
    if ([self cyl_isPlusControl]) {
        return;
    }
    if (!lottieURL) {
        return;
    }
    
#if __has_include(<Lottie/Lottie.h>)
    
    //_UITabButton
    [self cyl_addLottieImageWithLottieURL:lottieURL size:size contentMode:contentMode];
    LOTAnimationView *lottieView = (LOTAnimationView *)self.cyl_lottieAnimationView;
    if (!lottieView) {
        [self cyl_addLottieImageWithLottieURL:lottieURL size:size contentMode:contentMode];
    }
    lottieView = (LOTAnimationView *)self.cyl_lottieAnimationView;
    if (!lottieView || ![lottieView isKindOfClass:[LOTAnimationView class]]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];

    dispatch_async(dispatch_get_main_queue(),^{
        
        if (defaultSelected) {
            // [CN] Avoid triggering Lottie animation when index == 0 on app startup. 希望Lottie icon 启动后 index== 0 不执行动画 #389
            // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
            lottieView.animationProgress = 1;
            [lottieView forceDrawingUpdate];
        } else {
            lottieView.animationProgress = 0;
            [lottieView play];
        }
    });
#endif
    
    
#if __has_include(<Lottie/Lottie-Swift.h>)
    
    //_UITabButton
    [self cyl_addLottieImageWithLottieURL:lottieURL size:size contentMode:contentMode];
    CYLCompatibleLOTAnimationView *lottieView = (CYLCompatibleLOTAnimationView *)self.cyl_lottieAnimationView;
    if (!lottieView) {
        [self cyl_addLottieImageWithLottieURL:lottieURL size:size contentMode:contentMode];
    }
    lottieView = (CYLCompatibleLOTAnimationView *)self.cyl_lottieAnimationView;
    if (!lottieView || ![NSStringFromClass([lottieView class]) containsString:NSStringFromClass([CYLCompatibleLOTAnimationView class])]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];

// [CN] dispatch_async(dispatch_get_main_queue(),^{  不能增加dispatch_get_main_queue判断，否则暂停与播放，可能错乱。
// [EN] dispatch_async(dispatch_get_main_queue(),^{  The dispatch_get_main_queue check must not be added; otherwise pause
//      and play may get out of order.

        if (defaultSelected) {
            // [CN] Avoid triggering Lottie animation when index == 0 on app startup. 希望Lottie icon 启动后 index== 0 不执行动画 #389
            // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
            lottieView.animationProgress = 1;
            [lottieView forceDrawingUpdate];
        } else {
            lottieView.animationProgress = 0;
            /// [CN] 播放到指定进度（0-1）
            /// [EN] Play to the given progress (0-1)
            [lottieView play];
        }
//    });
#endif
}

/*!
  [CN] 通过(lottieView.animationProgress > 0) 判断，以及放置在 dispatch_get_main_queue， 尝试 修复扁平风格 CYLFlatDesignTabBar 第一次初始化时，可能展示失败的问题。
 其中 通过(lottieView.animationProgress > 0) 判断 ， 可以降低80%的发生几率， 但并不保证100%完全避免，
 不能增加dispatch_get_main_queue判断，否则暂停与播放，可能错乱。
  [EN] The (lottieView.animationProgress > 0) check, plus running on dispatch_get_main_queue, try to fix an issue where
       the flat design style CYLFlatDesignTabBar may fail to display on its first initialization.
       The (lottieView.animationProgress > 0) check lowers the chance of it happening by 80%, but does not guarantee
       avoiding it 100%.
       The dispatch_get_main_queue check must not be added; otherwise pause and play may get out of order.
 */
- (void)cyl_stopAnimationOfLottieView {
    //    dispatch_async(dispatch_get_main_queue(),^{
#if __has_include(<Lottie/Lottie.h>)
    if ([self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        LOTAnimationView *lottieView = (LOTAnimationView *)self.cyl_lottieAnimationView;
            
        if (lottieView && [lottieView isKindOfClass:[LOTAnimationView class]] && (lottieView.animationProgress > 0)) {
            [lottieView stop];
        }
    }
#if CYL_FLATDESIGN_AVAILABLE
        
    else if ([self.cyl_tabBarController.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        LOTAnimationView *lottieView = (LOTAnimationView *)self.cyl_lottieAnimationView;
            
        if (lottieView && [lottieView isKindOfClass:[LOTAnimationView class]] && (lottieView.animationProgress > 0)) {
            [lottieView stop];
        }
    }
#endif
        
        
#endif
        
        
#if __has_include(<Lottie/Lottie-Swift.h>)
        
    if ([self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
            
        CYLCompatibleLOTAnimationView *lottieView = (CYLCompatibleLOTAnimationView *)self.cyl_lottieAnimationView;
            
        if (lottieView && [lottieView isKindOfClass:[CYLCompatibleLOTAnimationView class]] && (lottieView.animationProgress > 0)) {
            [lottieView stop];
        }
    }
        
#if CYL_FLATDESIGN_AVAILABLE
    //TODO:   仅仅保留一个 else if or else 即可
    else if ([self.cyl_tabBarController.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLCompatibleLOTAnimationView *lottieView = (CYLCompatibleLOTAnimationView *)self.cyl_lottieAnimationView;
        if (lottieView && [lottieView isKindOfClass:[CYLCompatibleLOTAnimationView class]] && (lottieView.animationProgress > 0)) {
            [lottieView stop];
        }
    }  else {
        CYLCompatibleLOTAnimationView *lottieView = (CYLCompatibleLOTAnimationView *)self.cyl_lottieAnimationView;
        if (lottieView && [lottieView isKindOfClass:[CYLCompatibleLOTAnimationView class]] && (lottieView.animationProgress > 0)) {
            [lottieView stop];
        }
    }
#endif
        
#endif
    //    });
}

#pragma mark - private method

//- (CGFloat)cyl_xOffset {
//    if (![CYLConstants isLiquidGlassActive]) {
//        return 0.0f;
//    }
//    CGFloat boundsWidthOffset;// = (CYLScreenWidth() - self.cyl_boundsSize.width) * 0.5;
//
//    return boundsWidthOffset;
//}

- (nullable UIControl *)cyl_platterSelectedControl {
    if (![self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return nil;
    }
    UIControl *selectedContentControl = [self.cyl_tabBarController.tabBar cyl_selectedContentControlFromContentControl:self];
    if (!selectedContentControl) {
        selectedContentControl = self;
    }
    return selectedContentControl;
}

- (BOOL)cyl_isPlatterSelectedControl {
    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    if (!self.superview) {
        return NO;
    }
    if (!self.cyl_tabBarController) {
        return NO;
    }
    if (![self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    
    return [self.superview cyl_isPlatterSelectedContentView];
}

- (BOOL)cyl_isPlatterNormalControl {
    if (self.cyl_tabBarController.tabBar && [self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return [self.superview cyl_isPlatterContentView];
    }
    return NO;
}

- (UIControl *)cyl_platterNormalControl {
    UIControl *platterNormalControl = [self.cyl_tabBarController.tabBar cyl_normalContentControlFromSelectedContentControl:self];
    if (!platterNormalControl) {
        platterNormalControl = self;
    }
    return platterNormalControl;
}

- (void)cyl_hideControl {
    UIControl *control = self;
    UIControl *selectedControl = self.cyl_platterSelectedControl;
    control.hidden = YES;
    control.cyl_tabLabel.hidden = YES;
    control.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
    control.userInteractionEnabled = NO;
    selectedControl.hidden = YES;
    selectedControl.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
    selectedControl.cyl_tabLabel.hidden = YES;
    selectedControl.userInteractionEnabled = NO;
    
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
CYL_DEPRECATED_DECLARATIONS_PUSH
- (void)cyl_setShowTabBadgePointIfNeeded:(BOOL)showTabBadgePoint {
    @try {
        [self cyl_setShowTabBadgePoint:showTabBadgePoint];
    } @catch (NSException *exception) {
        NSLog(@"CYLPlusChildViewController do not support set TabBarItem red point");
    }
}

- (void)cyl_setShowTabBadgePoint:(BOOL)showTabBadgePoint {
    if (showTabBadgePoint && self.cyl_tabBadgePointView.superview == nil) {
        UIView *tabBadgePointView = self.cyl_tabBadgePointView;
        [self cyl_bringSubviewToFront:tabBadgePointView];
        // FIX: issue #653 — frames, not constraints: see `_CYLTabButtonLayoutTracker`.
        // Same placement as the former constraints: centre at the image view's top-right corner plus the offset.
        tabBadgePointView.translatesAutoresizingMaskIntoConstraints = YES;
        __weak UIView *weakImageView = self.cyl_tabImageView;
        [[_CYLTabButtonLayoutTracker cyl_trackerForTabButton:self] cyl_trackView:tabBadgePointView centerProvider:^CGPoint(UIControl *tabButton) {
            UIView *imageView = weakImageView;
            CGPoint topRight = CYLTabButtonPointInView(tabButton, imageView, CGPointMake(CGRectGetMaxX(imageView.bounds), CGRectGetMinY(imageView.bounds)));
            UIOffset offset = tabButton.cyl_tabBadgePointViewOffset;
            return CGPointMake(topRight.x + offset.horizontal, topRight.y + offset.vertical);
        }];
    }
    self.cyl_tabBadgePointView.hidden = showTabBadgePoint == NO;
    self.cyl_tabBadgeView.hidden = showTabBadgePoint == YES;
}

- (void)cyl_setTabBadgePointView:(UIView *)tabBadgePointView {
    UIView *tempView = objc_getAssociatedObject(self, @selector(cyl_tabBadgePointView));
    if (tempView) {
        [tempView removeFromSuperview];
    }
    if (tabBadgePointView.superview) {
        [tabBadgePointView removeFromSuperview];
    }
    
    tabBadgePointView.hidden = YES;
    objc_setAssociatedObject(self, @selector(cyl_tabBadgePointView), tabBadgePointView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)cyl_tabBadgePointView {
    UIView *tabBadgePointView = objc_getAssociatedObject(self, @selector(cyl_tabBadgePointView));
    
    if (tabBadgePointView == nil) {
        tabBadgePointView = self.cyl_defaultTabBadgePointView;
        objc_setAssociatedObject(self, @selector(cyl_tabBadgePointView), tabBadgePointView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tabBadgePointView;
}

- (void)cyl_setTabBadgePointViewOffset:(UIOffset)tabBadgePointViewOffset {
    objc_setAssociatedObject(self, @selector(cyl_tabBadgePointViewOffset), [NSValue valueWithUIOffset:tabBadgePointViewOffset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// [CN] offset如果都是正数，则往右下偏移
// [EN] If both offsets are positive, it shifts toward the bottom right.
- (UIOffset)cyl_tabBadgePointViewOffset {
    id tabBadgePointViewOffsetObject = objc_getAssociatedObject(self, @selector(cyl_tabBadgePointViewOffset));
    UIOffset tabBadgePointViewOffset = [tabBadgePointViewOffsetObject UIOffsetValue];
    return tabBadgePointViewOffset;
}

- (void)cyl_showTabBadgePoint {
    [self cyl_setShowTabBadgePointIfNeeded:YES];
}

- (void)cyl_removeTabBadgePoint {
    [self cyl_setShowTabBadgePointIfNeeded:NO];
}

- (BOOL)cyl_isShowTabBadgePoint {
    return !self.cyl_tabBadgePointView.hidden;
}

- (UIView *)cyl_defaultTabBadgePointView {
    
    UIView *defaultRedTabBadgePointView;
    CYL_DEPRECATED_DECLARATIONS_PUSH
    defaultRedTabBadgePointView = [UIView cyl_tabBadgePointViewWithClolor:[UIColor redColor] radius:4.5];
    CYL_DEPRECATED_DECLARATIONS_POP
    return defaultRedTabBadgePointView;
}
CYL_DEPRECATED_DECLARATIONS_POP
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP

@end

