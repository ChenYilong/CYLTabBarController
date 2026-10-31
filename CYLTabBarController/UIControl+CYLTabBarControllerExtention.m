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

- (UIView *)cyl_lottieAnimationView {
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
        //如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
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
    //        //TODO: 区分cover 与 replace 两个场景， 获取到真实的view，可能是lottie，决定是否限制新视图的尺寸， 目前暂不限制尺寸。 因为主要场景为 cover 场景。cover =( adjustTabBarItemImageViewSizeDependOnSuperView == yes), replace =( adjustTabBarItemImageViewSizeDependOnSuperView == NO)
    if (newView.frame.size.width == 0 || newView.frame.size.height == 0) {
        //        不再限制newView 是否能超过父视图，因为你可以通过设置size来控制newView的展示大小。
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

- (void)cyl_addLottieImageWithLottieURL:(NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode {
    NSString *lottieFilePath = [lottieURL path];
    [self cyl_addLottieImageWithLottieFilePath:lottieFilePath size:size contentMode:contentMode];
}

- (void)cyl_addLottieImageWithLottieFilePath:(NSString *)lottieFilePath
                                        size:(CGSize)size
                                 contentMode:(UIViewContentMode)contentMode {
    NSURL *lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
    if (!lottieURL) {
        return;
    }
    if (CGSizeEqualToSize(CGSizeZero, size)) {
        size = CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
    }
    if ([self cyl_isPlusControl]) {
        return;
    }
#if __has_include(<Lottie/Lottie.h>)
    
    if (self.cyl_lottieAnimationView) {
        return;
    }
    UIControl *tabButton = self;
    LOTAnimationView *lottieView = [[LOTAnimationView alloc] initWithContentsOfURL:lottieURL];
    lottieView.frame = CGRectMake(0, 0, size.width, size.height);
    lottieView.userInteractionEnabled = NO;
    lottieView.contentMode = contentMode;
    lottieView.translatesAutoresizingMaskIntoConstraints = YES;// FIX: issue #653, see `_CYLTabButtonLayoutTracker`
    [lottieView setClipsToBounds:NO];
    [tabButton cyl_replaceTabImageViewWithNewView:lottieView show:YES];
#endif
    
#if __has_include(<Lottie/Lottie-Swift.h>)
    if (self.cyl_lottieAnimationView) {
        return;
    }
    UIControl *tabButton = self;
    NSString *filePath = lottieFilePath;
    CYLCompatibleLOTAnimation *composition = [[CYLCompatibleLOTAnimation alloc] initWithFilepath:filePath];
    CYLCompatibleLOTAnimationView *lottieView = [[CYLCompatibleLOTAnimationView alloc] initWithCompatibleAnimation:composition];
    lottieView.frame = CGRectMake(0, 0, size.width, size.height);
    lottieView.userInteractionEnabled = NO;
    lottieView.contentMode = contentMode;
    
    lottieView.translatesAutoresizingMaskIntoConstraints = YES;// FIX: issue #653, see `_CYLTabButtonLayoutTracker`
    [lottieView setClipsToBounds:NO];
    [tabButton cyl_replaceTabImageViewWithNewView:lottieView show:YES];
#endif
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
            //Avoid triggering Lottie animation when index == 0 on app startup. 希望Lottie icon 启动后 index== 0 不执行动画 #389
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

//    dispatch_async(dispatch_get_main_queue(),^{  不能增加dispatch_get_main_queue判断，否则暂停与播放，可能错乱。

        if (defaultSelected) {
            //Avoid triggering Lottie animation when index == 0 on app startup. 希望Lottie icon 启动后 index== 0 不执行动画 #389
            lottieView.animationProgress = 1;
            [lottieView forceDrawingUpdate];
        } else {
            lottieView.animationProgress = 0;
            ///播放到指定进度（0-1）
            [lottieView play];
        }
//    });
#endif
}

/*!
  通过(lottieView.animationProgress > 0) 判断，以及放置在 dispatch_get_main_queue， 尝试 修复扁平风格 CYLFlatDesignTabBar 第一次初始化时，可能展示失败的问题。
 其中 通过(lottieView.animationProgress > 0) 判断 ， 可以降低80%的发生几率， 但并不保证100%完全避免，
 不能增加dispatch_get_main_queue判断，否则暂停与播放，可能错乱。
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

- (UIControl *)cyl_platterSelectedControl {
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

//offset如果都是正数，则往右下偏移
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

