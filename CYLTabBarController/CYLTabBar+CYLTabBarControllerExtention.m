/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>
#import "CYLTabBar.h"

/*!
 * [EN] The object at `index`, or nil when `array` is nil or `index` is out of range (negative, `NSNotFound` or too
 *      large). Used instead of `@try` / `@catch` around subscripts: under ARC an exception can leak, and a `@try` around
 *      several reads skips every read after the first that throws.
 * [CN] 返回 `index` 处的对象；`array` 为 nil 或 `index` 越界（负数、`NSNotFound` 或过大）时返回 nil。用来代替下标外的
 *      `@try` / `@catch`：ARC 下抛出异常可能泄漏内存，而包住多次读取的 `@try` 会在第一次抛出后跳过其余全部读取。
 */
static inline id _Nullable CYLObjectAtIndex(NSArray * _Nullable array, NSUInteger index) {
    return index < array.count ? array[index] : nil;
}

@implementation CYLTabBar (CYLTabBarControllerExtention)

/*!
 * [EN] The plus child view controller is bound to the CYLTabBarController (by its `context`), so it is asked of the
 *      controller that owns this tab bar (its `delegate`), and checked against THAT controller's `viewControllers`.
 *      `-cyl_tabBarController` would return the root controller for a view, the wrong one with several. The context
 *      comparison it used to make is implied: the child was registered for this controller's context.
 * [CN] PlusButton 子控制器绑定的是 CYLTabBarController（通过它的 `context`），因此向拥有本 TabBar 的控制器（它的 `delegate`）询问，
 *      并对 **该** 控制器的 `viewControllers` 做检查。`-cyl_tabBarController` 对 View 返回的是根控制器，有多个时会错。
 *      原来的 context 比较已经隐含：子控制器就是按本控制器的 context 注册的。
 */
- (BOOL)cyl_hasPlusChildViewController {
    CYLTabBarController *tabBarController = [self tabBarController];
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:tabBarController ?: self];
    if (!plusChildViewController) {
        return NO;
    }
    BOOL isAdded = [tabBarController.viewControllers containsObject:plusChildViewController];
    BOOL isEverAdded = plusChildViewController.cyl_plusViewControllerEverAdded;
    return isAdded && isEverAdded;
}

- (NSArray *)cyl_originalTabBarButtons {
    NSArray *tabBarButtons = [self cyl_tabBarButtonFromTabBarSubviews:[self cyl_sortedSubviews]];
    return tabBarButtons;
}

/*!
 * [EN] Sorts tab bar buttons in logical (view controller) order: left-to-right for LTR, right-to-left for RTL (e.g. Arabic).
 * [CN] 按逻辑顺序（与子控制器顺序一致）排序：LTR 下从左到右，RTL（如阿语）下从右到左。
 */
- (NSComparator)cyl_tabBarButtonComparator {
    BOOL isRightToLeft = [self cyl_isRightToLeftLayout];
    // FIX: issue #653 — in the iOS 27.1 vertical bar the tab buttons are no longer inside this tab bar and are
    // stacked top to bottom: order them by their vertical centre in window coordinates (the plus button stays
    // in this tab bar, so a shared coordinate space is needed).
    // 竖向栏中 Tab 按钮不在本 TabBar 内且从上到下排列：按窗口坐标系中的垂直中心排序（加号按钮仍在本 TabBar 上，需统一坐标系）。
    UIView *platterView = self.cyl_platterView;
    BOOL isVerticalBar = platterView.window && platterView.window == self.window && ![platterView isDescendantOfView:self]
                         && CGRectGetHeight(platterView.bounds) > CGRectGetWidth(platterView.bounds);
    if (isVerticalBar) {
        return ^NSComparisonResult(UIView * formerView, UIView * latterView) {
            CGFloat formerViewY = [formerView convertPoint:CGPointMake(CGRectGetMidX(formerView.bounds), CGRectGetMidY(formerView.bounds)) toView:nil].y;
            CGFloat latterViewY = [latterView convertPoint:CGPointMake(CGRectGetMidX(latterView.bounds), CGRectGetMidY(latterView.bounds)) toView:nil].y;
            if (fabs(formerViewY - latterViewY) < 0.5) { return NSOrderedSame; }
            return (formerViewY < latterViewY) ? NSOrderedAscending : NSOrderedDescending;
        };
    }
    return ^NSComparisonResult(UIView * formerView, UIView * latterView) {
        CGFloat formerViewX = formerView.frame.origin.x;
        CGFloat latterViewX = latterView.frame.origin.x;
        if (isRightToLeft) {
            return  (formerViewX < latterViewX) ? NSOrderedDescending : NSOrderedAscending;
        }
        return  (formerViewX > latterViewX) ? NSOrderedDescending : NSOrderedAscending;
    };
}

- (NSArray *)cyl_sortedSubviews {
    if (self.cyl_tabBarSubviews.count == 0) {
        return self.cyl_tabBarSubviews;
    }
    NSMutableArray *tabBarButtonArray = [NSMutableArray arrayWithCapacity:self.cyl_tabBarSubviews.count];
    [self.cyl_tabBarSubviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj cyl_isTabButton]) {
            [tabBarButtonArray addObject:obj];
        }
    }];
    //    return tabBarButtonArray;
    NSArray *sortedSubviews = [[tabBarButtonArray copy] sortedArrayUsingComparator:[self cyl_tabBarButtonComparator]];
    return sortedSubviews;
}

- (NSArray *)cyl_tabBarButtonFromTabBarSubviews:(NSArray *)tabBarSubviews {
    if (tabBarSubviews.count == 0) {
        return tabBarSubviews;
    }
    NSMutableArray *tabBarButtonMutableArray = [NSMutableArray arrayWithCapacity:tabBarSubviews.count];
    [tabBarSubviews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj cyl_isTabButton]) {
            [tabBarButtonMutableArray addObject:obj];
            [obj cyl_setTabBarChildViewControllerIndex:idx];
        }
    }];

    return [tabBarButtonMutableArray copy];
}

- (nullable NSArray *)cyl_visibleControls {
    NSMutableArray *originalTabBarButtons = [NSMutableArray arrayWithArray:[self.cyl_originalTabBarButtons copy]];
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    BOOL notAdded = (NSNotFound == [originalTabBarButtons indexOfObject:plusButton]);
    if (plusButton && notAdded && [self isKindOfClass:[CYLTabBar class]]) {
        [originalTabBarButtons addObject:plusButton];
    }
    if (originalTabBarButtons.count == 0) {
        return nil;
    }
    //FIXME:  originalTabBarButtons == 3 (tabButton + plus)
    NSMutableArray *tabBarButtonArray = [NSMutableArray arrayWithCapacity:originalTabBarButtons.count];
    [originalTabBarButtons enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (([obj cyl_isTabButton] || [obj cyl_isPlusControl] ) ) {
            [tabBarButtonArray addObject:obj];
        }
    }];
    
    NSArray *sortedSubviews = [[tabBarButtonArray copy] sortedArrayUsingComparator:[self cyl_tabBarButtonComparator]];
    return sortedSubviews;
}

/*!
 * [CN] cyl_subTabBarButtons也就是与 VC匹配的Control集合，
 * [EN] cyl_subTabBarButtons is the collection of controls that match the VCs,
 */
- (NSArray<UIControl *> *)cyl_subTabBarButtons {
    if ([CYLConstants isLiquidGlassActive]) {
        return self.cyl_tabBarSubviews;
    }
    // [CN] FIXME:  to delete 这个逻辑是不是和cyl_subTabBarButtonsWithoutPlusButton一样子？
    //不一样，仅限 cyl_isChildViewControllerPlusButton
    // [EN] FIXME:  to delete Is this logic the same as cyl_subTabBarButtonsWithoutPlusButton?
    //      No, it is limited to cyl_isChildViewControllerPlusButton
    NSMutableArray *subControls = [NSMutableArray arrayWithCapacity:self.cyl_visibleControls.count];
    [self.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([control cyl_isPlusButton] && ![CYLPlusButton plusChildViewControllerForOwner:self].cyl_plusViewControllerEverAdded) {
            return;
        }
        [subControls addObject:control];
    }];
    return subControls;
}

/*!
 * [CN] cyl_subTabBarButtonsWithoutPlusButton也就是与 系统风格tabbbaritem样式匹配的Control集合，
 * [EN] cyl_subTabBarButtonsWithoutPlusButton is the collection of controls that match the system-style tab bar items,
 */
- (NSArray<UIControl *> *)cyl_subTabBarButtonsWithoutPlusButton {
    NSMutableArray *subControls = [NSMutableArray arrayWithCapacity:self.cyl_visibleControls.count];
    [self.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([control cyl_isPlusControl]) {
            return;
        }
        [subControls addObject:control];
    }];
    return subControls;
}

- (UIControl *)cyl_tabBarButtonWithTabIndex:(NSUInteger)tabIndex {
    UIControl *selectedControl = [self cyl_visibleControlWithIndex:tabIndex];
    
    NSInteger plusViewControllerIndex = [self.tabBarController.viewControllers indexOfObject:[CYLPlusButton plusChildViewControllerForOwner:self]];
    BOOL isPlusViewControllerAdded = [CYLPlusButton plusChildViewControllerForOwner:self].cyl_plusViewControllerEverAdded && (plusViewControllerIndex != NSNotFound);
    
    if (isPlusViewControllerAdded) {
        return selectedControl;
    }
    
    selectedControl = CYLObjectAtIndex([self cyl_subTabBarButtonsWithoutPlusButton], tabIndex);
    return selectedControl;
}

- (UIControl *)cyl_visibleControlWithIndex:(NSUInteger)index {
    UIControl *selectedControl;
    selectedControl = CYLObjectAtIndex(self.cyl_visibleControls, index);
    return selectedControl;
}

- (void)cyl_animationLottieImageWithSelectedControl:(nullable UIControl *)selectedControl
                                          lottieURL:(nullable NSURL *)lottieURL
                                               size:(CGSize)size
                                    defaultSelected:(BOOL)defaultSelected
                                        contentMode:(UIViewContentMode)contentMode {
    // FIX: issue #604 — any animation library, through the `CYLTabBarItemAnimation` subspec when it is in the build.
    // 任意动画库：构建中包含 `CYLTabBarItemAnimation` 子库时由它处理。
    if (CYLTabBarItemAnimationIsAvailable()) {
        [self cyl_playTabBarItemAnimationWithSelectedControl:selectedControl URL:lottieURL size:size defaultSelected:defaultSelected contentMode:contentMode];
    }
}

- (void)cyl_stopAnimationOfAllLottieView {
    // FIX: issue #604 — any animation library, through the `CYLTabBarItemAnimation` subspec when it is in the build.
    // 任意动画库：构建中包含 `CYLTabBarItemAnimation` 子库时由它处理。
    if (CYLTabBarItemAnimationIsAvailable()) {
        [self cyl_stopAllTabBarItemAnimations];
    }
}

/*!
 * [CN] 思路为： 从当前图层的control，获得index， 再从另外的图层中的index位置， 获取control。以此来避免直接使用 index 来获取不同图层的。因为有可能存在plusButton， 导致，index的数值变动， 降级复杂度。以control为锚点， index仅辅助。
 * [EN] Approach: get the index from the control in the current layer, then get the control at that index in the other
 *      layer. This avoids using the index directly to look up controls across layers, because a plusButton may shift
 *      the index values; it reduces complexity. The control is the anchor; the index only assists.
 */
- (nullable UIControl *)cyl_selectedContentControlFromContentControl:(nullable UIControl *)contentControl {
//    if ([contentControl cyl_isPlusControl]) {
//        return nil;
//    }
    UIControl *selectedContentControl = nil;
    // [CN] FIXME:  必须为 cyl_subTabBarButtonsWithoutPlusButton （不能 cyl_subTabBarButtons）否则Lottie选中动画不显示，因为Lottie文件数量与tabbaritems 的数量少一个。
    // [EN] FIXME:  Must be cyl_subTabBarButtonsWithoutPlusButton (not cyl_subTabBarButtons), otherwise the Lottie selected
    //      animation does not show, because there is one fewer Lottie file than tab bar items.
    NSUInteger index = [self.cyl_subTabBarButtons indexOfObject:contentControl];
    if (NSNotFound == index) {
        return nil;
    }
    // [CN] FIXME:  to delete  必须为 cyl_platterSelectedContentViewWithoutPlusButttonWithIndex （不能cyl_platterSelectedContentViewWithIndex）否则Lottie选中动画不显示，，因为Lottie文件数量与tabbaritems 的数量少一个。
    //TODO: selectedContentControl不对，plusButton 下一个会添加失败，添加的是 plusButton对应的lottie， 顺延了。
    // [EN] FIXME:  to delete  Must be cyl_platterSelectedContentViewWithoutPlusButttonWithIndex
    //      (not cyl_platterSelectedContentViewWithIndex), otherwise the Lottie selected animation does not show,
    //      because there is one fewer Lottie file than tab bar items.
    //      TODO: selectedContentControl is wrong; adding to the one after the plusButton fails: it adds the Lottie
    //      for the plusButton instead, shifted by one.
    selectedContentControl = [self cyl_platterSelectedContentViewWithIndex:index];
    if (!selectedContentControl) {
        return nil;
    }
    return selectedContentControl;
}

- (nullable UIControl *)cyl_normalContentControlFromSelectedContentControl:(UIControl *)selectedContentControl {
    //    if ([selectedContentControl cyl_isPlusControl]) {
    //        return nil;
    //    }
    UIControl *contentControl = nil;
    //FIXME:  to delete cyl_platterSelectedContentViewsWithoutPlusButton
    NSUInteger index = [self.cyl_platterSelectedContentViews indexOfObject:selectedContentControl];
    if (NSNotFound == index) {
        return nil;
    }
    //FIXME:  to delete cyl_subTabBarButtonsWithoutPlusButton
    contentControl = CYLObjectAtIndex(self.cyl_subTabBarButtons, index);
    if (!contentControl) {
        return nil;
    }
    return contentControl;
}

- (CGFloat)cyl_cachedXOffsetWithIndex:(CGFloat)index {
    if (![CYLConstants isLiquidGlassActive]) {
        return 0.0f;
    }
    CGFloat boundsWidthOffset = (self.cyl_boundsSize.width - CYLScreenWidth()) * 0.5;
    CGFloat plusButtonIndex = [self plusButtonIndex];
    if (index<plusButtonIndex) {
        return boundsWidthOffset;
    }
    return fabs(boundsWidthOffset);
}

- (CGFloat)cyl_cachedWidthOffsetWithIndex:(CGFloat)index {
    if (![CYLConstants isLiquidGlassActive]) {
        return 0.0f;
    }
    CGFloat originalTabBarItemWidth = self.cyl_boundsSize.width / self.cyl_tabbarItemsCount;
    CGFloat visiableTabBarItemWidth = self.cyl_tabBarItemWidth;
    CGFloat WidthOffsetWithIndex = originalTabBarItemWidth - visiableTabBarItemWidth;
    return fabs(WidthOffsetWithIndex);
}

- (UIControl * _Null_unspecified)cyl_selectedControl {
    UIControl *selectedControl = objc_getAssociatedObject(self, @selector(cyl_selectedControl));
    if (!selectedControl) {
        // [EN] Each candidate is read with a bounds check: the old `@try` around `[0]` jumped to `@catch` on the first empty
        //      array, so the fallbacks after it never ran and this returned nil. Only controls count: the first subview of a
        //      tab bar that is not Liquid Glass can be a background view.
        // [CN] 每个候选都先检查下标再读取：原来 `[0]` 外的 `@try` 在第一个空数组处就跳到 `@catch`，后面的备选从未执行，结果返回 nil。
        //      只接受控件：非液态玻璃 TabBar 的第一个子视图可能是背景视图。
        for (NSArray *candidates in @[ self.cyl_platterSelectedContentViews ?: @[], self.cyl_platterContentViews ?: @[], self.cyl_visibleControls ?: @[] ]) {
            id candidate = CYLObjectAtIndex(candidates, 0);
            if ([candidate isKindOfClass:[UIControl class]]) {
                selectedControl = candidate;
                break;
            }
        }
    }
    // [EN] Still nil when the tab bar has no control yet. The header declares a nonnull return, and that public API stays as
    //      released (making it nullable would change its Swift type), so the cast tells the static analyzer the nil is known.
    // [CN] TabBar 还没有任何控件时仍为 nil。头文件声明的返回值为非空，该公开 API 保持已发布的样子（改为 nullable 会改变其 Swift 类型），
    //      因此这里的转换告诉静态分析器：返回 nil 是已知的。
    return (UIControl * _Nonnull)selectedControl;
}

- (void)cyl_setSelectedControl:(UIControl *)selectedControl {
    UIControl *selectedControl_ = selectedControl;
    objc_setAssociatedObject(self, @selector(cyl_selectedControl), selectedControl_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_selectedIndex {
    NSInteger selectedIndex = self.cyl_selectedControl.cyl_tabBarItemVisibleIndex;
    return selectedIndex;
}

- (BOOL)cyl_shouldUpdateHiddenStatueForPlusButtonLabel {
    CYLTabBarController *tabBarController = [self tabBarController];
    return [self cyl_shouldUpdateHiddenStatueForPlusButtonLabelForTabBarController:tabBarController];
}

- (BOOL)cyl_shouldUpdateHiddenStatueForPlusButtonLabelForTabBarController:(CYLTabBarController *)theTabBarController {
    if (![CYLConstants isLiquidGlassActive] || ![self isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    
    CYLTabBarController *tabBarController = theTabBarController;
    
    if (!theTabBarController) {
        tabBarController = [self tabBarController];
    }
    
    CYLTabBar *tabBar = (CYLTabBar *)tabBarController.tabBar;
    if (!tabBar) {
        tabBar = self;
    }
    // The plus button and its child view controller are bound to the controller (by its `context`), so ask it.
    // PlusButton 和它的子控制器绑定的是控制器（通过它的 `context`），所以向它询问。
    id plusOwner = tabBarController ?: self;
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [CYLPlusButton plusButtonForOwner:plusOwner];
    if (![CYLPlusButton plusChildViewControllerForOwner:plusOwner]) {
        return NO;
    }
    if (!plusButton) {
        return NO;
    }
    // FIX: issue #636, #641 — the tab item shows the plus button's title (`-cyl_showsTitleInTabBarItem`), drawn by the
    // system in both Liquid Glass layers: there is no plus button label to hide or show, and no swipe to block.
    // TabBarItem 显示 PlusButton 的标题，由系统在液态玻璃两个图层中绘制：无需隐藏/显示 PlusButton 的 Label，也无需禁止滑动。
    if ([plusButton cyl_showsTitleInTabBarItem]) {
        return NO;
    }
    if (!plusButton.cyl_tabLabel) {
        return NO;
    }
    if (plusButton.cyl_tabLabel.text.length == 0) {
        return NO;
    }
    
    SEL actionshouldShowPlatterLiquidLensViewForControl = @selector(tabBarController:shouldShowPlatterLiquidLensViewForControl:);
    BOOL shouldShowPlatterLiquidLensViewForControl;
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(
                                            
                                            
                                            shouldShowPlatterLiquidLensViewForControl = [tabBarController performSelector:actionshouldShowPlatterLiquidLensViewForControl withObject:tabBarController withObject:plusButton];
                                            
                                            
                                            );
    
    // [CN] 如果在选中CYLPlusChildViewController的状态下，  重复点击，或者滑动手势，又选中CYLPlusChildViewController。 相当于重复点击CYLPlusChildViewController， 则不显示未选中状态的Label， 仅仅在切换到其他tab的情况下， 显示未选中状态的Label。 否则会出现Label重叠的情况。
    // [EN] If CYLPlusChildViewController is already selected and it is selected again by a repeated tap or a swipe gesture,
    //      this counts as tapping CYLPlusChildViewController again, so the unselected-state Label is not shown. The
    //      unselected-state Label is shown only when switching to another tab; otherwise the Labels would overlap.
    if (shouldShowPlatterLiquidLensViewForControl && ![tabBar isPlusButtonLayoutCentered]  ) {
        return YES;
    }
    return NO;
}

@end

@implementation UITabBar (CYLTabBarControllerExtention)



- (CGFloat)cyl_platterViewWidth {
    NSNumber *platterViewWidthObject = objc_getAssociatedObject(self, @selector(cyl_platterViewWidth));
    return [platterViewWidthObject doubleValue];
}

- (void)cyl_setPlatterViewWidth:(CGFloat)platterViewWidth {
    NSNumber *platterViewWidthObject = @(platterViewWidth);
    objc_setAssociatedObject(self, @selector(cyl_platterViewWidth), platterViewWidthObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)cyl_platterViewSize {
    NSValue *platterViewSize = objc_getAssociatedObject(self, @selector(cyl_platterViewSize));
    return platterViewSize;
}

- (void)cyl_setPlatterViewSize:(NSValue *)platterViewSize {
    NSValue *platterViewSize_ = platterViewSize;
    objc_setAssociatedObject(self, @selector(cyl_platterViewSize), platterViewSize_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)cyl_contentView {
    return self.cyl_platterView ?: self;
}

- (UIView *)cyl_platterView {
    UIView *platterView = objc_getAssociatedObject(self, @selector(cyl_platterView));
    return platterView;
}

- (void)cyl_setPlatterView:(UIView *)platterView {
    UIView *platterView_ = platterView;
    objc_setAssociatedObject(self, @selector(cyl_platterView), platterView_, OBJC_ASSOCIATION_ASSIGN);
}

- (NSObject *)cyl_platterContentView {
    UIView *platterContentView = objc_getAssociatedObject(self, @selector(cyl_platterContentView));
    return platterContentView;
}

- (void)cyl_setPlatterContentView:(UIView *)platterContentView {
    UIView *platterContentView_ = platterContentView;
    objc_setAssociatedObject(self, @selector(cyl_platterContentView), platterContentView_, OBJC_ASSOCIATION_ASSIGN);
}

- (CALayer *)cyl_portalLayer {
    CALayer *portalLayer = objc_getAssociatedObject(self, @selector(cyl_portalLayer));
    return portalLayer;
}

- (void)cyl_setPortalLayer:(CALayer *)portalLayer {
    CALayer *portalLayer_ = portalLayer;
    objc_setAssociatedObject(self, @selector(cyl_portalLayer), portalLayer_, OBJC_ASSOCIATION_ASSIGN);
}

- (UIView *)cyl_portalView {
    UIView *portalView = objc_getAssociatedObject(self, @selector(cyl_portalView));
    return portalView;
}

- (void)cyl_setPortalView:(UIView *)portalView {
    UIView *portalView_ = portalView;
    objc_setAssociatedObject(self, @selector(cyl_portalView), portalView_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 *
 *CYLTabBar
 └── UIFocusContainerGuide
 └── _UITabBarPlatterView
 [CN] ├── SelectedContentView        ❌ 状态壳
 ├── _UILiquidLensView          ❌ 视觉
 └── ContentView                ✅ 真正容器
 [EN] ├── SelectedContentView        ❌ state shell
      ├── _UILiquidLensView          ❌ visual
      └── ContentView                ✅ the real container
 ├── _UITabButton           ✅
 ├── _UITabButton           ✅
 [CN] ├── _UITabButton           ❌ hidden / disabled（中间占位）
 [EN] ├── _UITabButton           ❌ hidden / disabled (middle placeholder)
 ├── _UITabButton           ✅
 ├── _UITabButton           ✅
 └── DestOutView            ❌
 └── CYLPlusButtonSubclass              ⭐
 
 */
- (NSArray<UIControl *> *)cyl_tabBarSubviews {
    if (![CYLConstants isLiquidGlassActive]) {
        return self.subviews;
        
    }
    // [CN] iOS 26 以前，保持原逻辑
    // [EN] Before iOS 26, keep the original logic
    if (CYL_UIDesignOldVersionCYLTabBarWithoutiOS26) {
        return self.subviews;
    }
    
    
    UIView *platterView = self.cyl_platterView;
    if (![platterView cyl_isPlatterView]) {        
        return self.subviews;
    }
    
    // [CN] 记录 platter 尺寸
    // [EN] Record the platter size
    [self cyl_setPlatterViewWidth:platterView.bounds.size.width];
    [self cyl_setPlatterViewSize:[NSValue valueWithCGSize:platterView.bounds.size]];
    
    UIView * container = platterView;
    // [CN] 3️⃣ 从 PlatterView 中，找真正承载 UITabBarButton 的 ContentView
    // [EN] 3️⃣ In the PlatterView, find the ContentView that actually hosts the UITabBarButtons
    UIView *contentView = nil;
    for (UIView *sub in container.subviews) {
        if ([sub cyl_isPlatterContentView]) {
            contentView = sub;
            break;
        }
    }
    return (NSArray<UIControl *> *)([self cyl_allTabViewsFrom:contentView] ?: self.subviews);
}

- (NSArray<UIControl *> *)cyl_platterSelectedContentViewsWithoutPlusButton {
    NSMutableArray *subControls = [NSMutableArray arrayWithCapacity:self.cyl_platterSelectedContentViews
.count];
    [self.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([control cyl_isPlusControl]) {
            return;
        }
        [subControls addObject:control];
    }];
    return subControls;
}

- (NSArray *)cyl_allTabViewsFrom:(UIView *)contentView {
    if (!contentView) {
        return nil;
    }

    // [CN] 4️⃣ 收集所有 UITabBarItem 对应 view UITabButton 的 frame
    // [EN] 4️⃣ Collect the frames of the UITabButton views corresponding to all UITabBarItems
    NSMutableArray<UIView *> *itemViews = [NSMutableArray array];
    for (UIView *sub in contentView.subviews) {
        if ([sub isKindOfClass:UIControl.class]) {
            [itemViews addObject:sub];
         }
    }
    
    // 5️⃣ 按视觉顺序排序（横向栏按 x 轴；竖向栏按 y 轴）
    // FIX: issue #653 — in the iOS 27.1 vertical bar (folded iPhone Duo) the buttons are stacked top to bottom.
    // Sort them by their vertical centre: while the selection lens animates, the touched button widens
    // (e.g. x 396 → 386, width 44 → 64), so sorting by x would move it to the front and shift every index
    // (the selected copy of another tab then got the plus cover and lost its icon).
    // 竖向栏中按钮从上到下排列，按垂直中心排序：选中玻璃动画时被按下的按钮会变宽、x 变小，
    // 若按 x 排序会被排到最前，导致索引错位（其他 Tab 的选中副本被加上加号遮罩、图标消失）。
    BOOL isVerticalBar = CGRectGetHeight(contentView.bounds) > CGRectGetWidth(contentView.bounds);
    [itemViews sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        if (isVerticalBar) {
            CGFloat dy = CGRectGetMidY(a.frame) - CGRectGetMidY(b.frame);
            if (fabs(dy) < 0.5) { return NSOrderedSame; }
            return dy < 0 ? NSOrderedAscending : NSOrderedDescending;
        }
        if (CGRectGetMinX(a.frame) < CGRectGetMinX(b.frame)) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
#if defined(DEBUG) || defined(BETA)
    
    // [CN] 6️⃣ 转成 frame 数组
    // [EN] 6️⃣ Convert to an array of frames
//    NSMutableArray<NSValue *> *frames = [NSMutableArray array];
//    for (UIView *v in itemViews) {
//        [frames addObject:[NSValue valueWithCGRect:v.frame]];
//    }
//    static BOOL logged = NO;
//    if (!logged) {
//        logged = YES;
//    }
#endif

    return itemViews;
}

- (CGFloat)cyl_fullHeight {
    return CYLGetTabBarFullH(self.cyl_boundsSize.height);
}

- (CGSize)cyl_boundsSize {
    CGSize size = self.bounds.size;
    if (![CYLConstants isLiquidGlassActive]) {
        CGFloat contentHeight = CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom;
         CGSize sizeWithSafeAreaInsets = CGSizeMake(size.width, contentHeight);
        return sizeWithSafeAreaInsets;
    }
    if (CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26) {
        [self cyl_tabBarSubviews];
        CGSize _size = [self.cyl_platterViewSize CGSizeValue];
        if (_size.width > 0) {
            return _size ;
        }
    }
    return size;
}

- (CGFloat)cyl_boundsWidthOffset {
    if (![CYLConstants isLiquidGlassActive]) {
        return 0.0f;
    }
    CGFloat boundsWidthOffset = (CYLScreenWidth() - self.cyl_boundsSize.width) * 0.5;
    return boundsWidthOffset;
}

- (NSArray *)cyl_platterViews {
    //    - (BOOL)cyl_isPlatterView; {
    return  [NSArray new];
}

- (UIView *)cyl_platterViewWithIndex:(NSInteger)index {
    //    - (BOOL)cyl_isPlatterView; {
    UIView *view = nil;
    view = CYLObjectAtIndex(self.cyl_platterViews, index);
    return view;
}
- (NSArray *)cyl_platterContentViews {
    return  self.cyl_tabBarSubviews;
}

- (UIView *)cyl_platterContentViewWithIndex:(NSInteger)index {
    UIView *view = nil;
    view = CYLObjectAtIndex(self.cyl_platterContentViews, index);
    return  view;
}

- (nullable UIView *)cyl_platterSelectedContentView {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {
        
        // [CN] TODO:  找到罩子的真正view， 修改frame
        // [EN] TODO:  Find the actual view of the overlay and modify its frame
        if ([sub cyl_isPlatterSelectedContentView]) {
            contentView = sub;
            break;
        }
    }
    
    if (!contentView) {
        return nil;
    }
    return contentView;
    
}

- (nullable NSArray<UIControl *> *)cyl_platterSelectedContentViews {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {

        if ([sub cyl_isPlatterSelectedContentView]) {
            contentView = sub;
            break;
        }
    }
    
    if (!contentView) {
        return nil;
    }
    
    
    return (NSArray<UIControl *> *)([self cyl_allTabViewsFrom:contentView] ?: self.subviews);
}

- (nullable UIView *)cyl_platterLiquidLensView {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {
        if ([sub cyl_isPlatterLiquidLensView]) {
            contentView = sub;
            break;
        }
    }
    
    if (!contentView) {
        return nil;
    }
    return contentView;
}

- (nullable UIView *)cyl_platterVisualProviderFloatingSelectedContentView {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {
        if ([sub cyl_isPlatterVisualProviderFloatingSelectedContentView]) {
            contentView = sub;
            break;
        }
    }
    
    if (!contentView) {
        return nil;
    }
    
    return contentView;
}

- (nullable UIView *)cyl_platterLiquidLensViewContentView {
    UIView *contentView = [self.cyl_portalView cyl_valueForKey:@"sourceView"];
    if (contentView) {
        return contentView;
    }
    for (UIView *sub in self.cyl_platterView.subviews) {
        if ([sub cyl_isPlatterLiquidLensView]) {
            for (UIView *subsubview in sub.subviews) {
                contentView = subsubview;
                break;
            }
        }
    }
    
    if (!contentView) {
        return nil;
    }
    
    return contentView;
}

- (nullable UIView *)cyl_platterLiquidLensClearGlassView {
    UIView *contentView;

    for (UIView *sub in self.cyl_platterLiquidLensViewSubViews) {
        if ([sub cyl_isPlatterLiquidLensClearGlassView]) {
            contentView = sub;
            break;
            
            
        }
    }
    
    if (!contentView) {
        return nil;
    }
    
    return contentView;
}


- (nullable NSArray<UIView *> *)cyl_platterLiquidLensViewSubViews {
    UIView *contentView = self.cyl_platterLiquidLensViewContentView;
    
    if (!contentView) {
        return nil;
    }
    
    
    return contentView.subviews;
    
}



- (nullable UIView *)cyl_platterDestOutView {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {
        // [CN] TODO:  找到罩子的真正view， 修改frame
        // [EN] TODO:  Find the actual view of the overlay and modify its frame
        if ([sub cyl_isPlatterDestOutView]) {
            contentView = sub;
            break;
        }
    }
    
    if (!contentView) {
        return nil;
    }
    
    
    return contentView;
    
}

- (UIControl *)cyl_platterSelectedContentViewWithoutPlusButttonWithIndex:(NSInteger)index {
    //    - (BOOL)cyl_isPlatterView; {
    UIControl *view = nil;
    view = CYLObjectAtIndex(self.cyl_platterSelectedContentViewsWithoutPlusButton, index);
    return view;
}

- (UIControl *)cyl_platterSelectedContentViewWithIndex:(NSInteger)index {
    //    - (BOOL)cyl_isPlatterView; {
    UIControl *view = nil;
    view = CYLObjectAtIndex(self.cyl_platterSelectedContentViews, index);
    return view;
}

- (NSArray *)cyl_platterPortalViews {
    return  [NSArray new];
}

- (UIView *)cyl_platterPortalViewWithIndex:(NSInteger)index {
    //    - (BOOL)cyl_isPlatterView; {
    UIView *view = nil;
    view = CYLObjectAtIndex(self.cyl_platterPortalViews, index);
    return view;
}



@end
