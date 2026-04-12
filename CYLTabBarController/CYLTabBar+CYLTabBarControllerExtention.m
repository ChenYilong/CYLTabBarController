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
#import "CYLTabBarController.h"
#import <objc/runtime.h>

#import "CYLTabBar.h"
#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif


@implementation CYLTabBar (CYLTabBarControllerExtention)

- (NSString *)cyl_context {
    NSString *context = objc_getAssociatedObject(self, @selector(cyl_context));
    return context;
}

- (void)cyl_setContext:(NSString *)context {
    NSString *context_ = context;
    objc_setAssociatedObject(self, @selector(cyl_context), context_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)cyl_hasPlusChildViewController {
    NSString *context = CYLPlusChildViewController.cyl_context;
    BOOL isSameContext = [context isEqualToString:self.cyl_context] && (context && (context.length > 0) && self.cyl_context && self.cyl_context.length > 0);
    BOOL isAdded = [[self cyl_tabBarController].viewControllers containsObject:CYLPlusChildViewController];
    BOOL isEverAdded = CYLPlusChildViewController.cyl_plusViewControllerEverAdded;
    if (CYLPlusChildViewController && isSameContext && isAdded && isEverAdded) {
        return YES;
    }
    return NO;
}

- (NSArray *)cyl_originalTabBarButtons {
    //FIXME:  _tabBarButtonArray == 4 but tabBarButtons == 2
    NSArray *tabBarButtons = [self cyl_tabBarButtonFromTabBarSubviews:[self cyl_sortedSubviews]];
    return tabBarButtons;
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
    NSArray *sortedSubviews = [[tabBarButtonArray copy] sortedArrayUsingComparator:^NSComparisonResult(UIView * formerView, UIView * latterView) {
        CGFloat formerViewX = formerView.frame.origin.x;
        CGFloat latterViewX = latterView.frame.origin.x;
        return  (formerViewX > latterViewX) ? NSOrderedDescending : NSOrderedAscending;
    }];
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

- (NSArray *)cyl_visibleControls {
    NSMutableArray *originalTabBarButtons = [NSMutableArray arrayWithArray:[self.cyl_originalTabBarButtons copy]];
    BOOL notAdded = (NSNotFound == [originalTabBarButtons indexOfObject:CYLExternPlusButton]);
    if (CYLExternPlusButton && notAdded && [self isKindOfClass:[CYLTabBar class]]) {
        [originalTabBarButtons addObject:CYLExternPlusButton];
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
    
    NSArray *sortedSubviews = [[tabBarButtonArray copy] sortedArrayUsingComparator:^NSComparisonResult(UIView * formerView, UIView * latterView) {
        CGFloat formerViewX = formerView.frame.origin.x;
        CGFloat latterViewX = latterView.frame.origin.x;
        return  (formerViewX > latterViewX) ? NSOrderedDescending : NSOrderedAscending;
    }];
    return sortedSubviews;
}

/*!
 * cyl_subTabBarButtons也就是与 VC匹配的Control集合，
 */
- (NSArray<UIControl *> *)cyl_subTabBarButtons {
    if ([CYLConstants isUsedLiquidGlass]) {
        return self.cyl_tabBarSubviews;
    }
    //FIXME:  to delete 这个逻辑是不是和cyl_subTabBarButtonsWithoutPlusButton一样子？
    //不一样，仅限 cyl_isChildViewControllerPlusButton
    NSMutableArray *subControls = [NSMutableArray arrayWithCapacity:self.cyl_visibleControls.count];
    [self.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([control cyl_isPlusButton] && !CYLPlusChildViewController.cyl_plusViewControllerEverAdded) {
            return;
        }
        [subControls addObject:control];
    }];
    return subControls;
}

/*!
 * cyl_subTabBarButtonsWithoutPlusButton也就是与 系统风格tabbbaritem样式匹配的Control集合，
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
    
    NSInteger plusViewControllerIndex = [self.cyl_tabBarController.viewControllers indexOfObject:CYLPlusChildViewController];
    BOOL isPlusViewControllerAdded = CYLPlusChildViewController.cyl_plusViewControllerEverAdded && (plusViewControllerIndex != NSNotFound);
    
    if (isPlusViewControllerAdded) {
        return selectedControl;
    }
    
    @try {
        selectedControl = [self cyl_subTabBarButtonsWithoutPlusButton][tabIndex];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    return selectedControl;
}

- (UIControl *)cyl_visibleControlWithIndex:(NSUInteger)index {
    UIControl *selectedControl;
    @try {
        NSArray *subControls = self.cyl_visibleControls;
        selectedControl = subControls[index];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    return selectedControl;
}

- (void)cyl_animationLottieImageWithSelectedControl:(UIControl *)selectedControl
                                          lottieURL:(NSURL *)lottieURL
                                               size:(CGSize)size
                                    defaultSelected:(BOOL)defaultSelected {
#if __has_include(<Lottie/Lottie.h>)
    //_UITabButton
    [self cyl_stopAnimationOfAllLottieView];
    [selectedControl cyl_animationLottieImageWithLottieURL:lottieURL size:size defaultSelected:defaultSelected];
#else
#endif
}

- (void)cyl_stopAnimationOfAllLottieView {
#if __has_include(<Lottie/Lottie.h>)
    if ([self isKindOfClass:[CYLTabBar class]]) {
        [self.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cyl_stopAnimationOfLottieView];
        }];
        [self.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cyl_stopAnimationOfLottieView];
        }];
    } else
    if ([self isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLFlatDesignTabBar *flatDesignTabBar = (CYLFlatDesignTabBar *)self;
        [flatDesignTabBar.tabBarItems enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cyl_stopAnimationOfLottieView];
        }];
    }
#else
#endif
}
/*!
 * 思路为： 从当前图层的control，获得index， 再从另外的图层中的index位置， 获取control。以此来避免直接使用 index 来获取不同图层的。因为有可能存在plusButton， 导致，index的数值变动， 降级复杂度。以control为锚点， index仅辅助。
 */
- (UIControl *)cyl_selectedContentControlFromContentControl:(UIControl *)contentControl {
//    if ([contentControl cyl_isPlusControl]) {
//        return nil;
//    }
    UIControl *selectedContentControl = nil;
    //FIXME:  必须为 cyl_subTabBarButtonsWithoutPlusButton （不能 cyl_subTabBarButtons）否则Lottie选中动画不显示，因为Lottie文件数量与tabbaritems 的数量少一个。
    NSUInteger index = [self.cyl_subTabBarButtons indexOfObject:contentControl];
    if (NSNotFound == index) {
        return nil;
    }
    //FIXME:  to delete  必须为 cyl_platterSelectedContentViewWithoutPlusButttonWithIndex （不能cyl_platterSelectedContentViewWithIndex）否则Lottie选中动画不显示，，因为Lottie文件数量与tabbaritems 的数量少一个。
    //TODO: selectedContentControl不对，plusButton 下一个会添加失败，添加的是 plusButton对应的lottie， 顺延了。
    selectedContentControl = [self cyl_platterSelectedContentViewWithIndex:index];
    if (!selectedContentControl) {
        return nil;
    }
    return selectedContentControl;
}

- (UIControl *)cyl_normalContentControlFromSelectedContentControl:(UIControl *)selectedContentControl {
//    if ([selectedContentControl cyl_isPlusControl]) {
//        return nil;
//    }
    UIControl *contentControl = nil;
    //FIXME:  to delete cyl_platterSelectedContentViewsWithoutPlusButton
    NSUInteger index = [self.cyl_platterSelectedContentViews indexOfObject:selectedContentControl];
    if (NSNotFound == index) {
        return nil;
    }
    @try {
        //FIXME:  to delete cyl_subTabBarButtonsWithoutPlusButton
        contentControl = [self.cyl_subTabBarButtons objectAtIndex:index];
    } @catch (NSException *exception) {
        }
    if (!contentControl) {
        return nil;
    }
    return contentControl;
}

- (CGFloat)cyl_cachedXOffsetWithIndex:(CGFloat)index {
    if (![CYLConstants isUsedLiquidGlass]) {
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
    if (![CYLConstants isUsedLiquidGlass]) {
        return 0.0f;
    }
    CGFloat originalTabBarItemWidth = self.cyl_boundsSize.width / CYLTabbarItemsCount;
    CGFloat visiableTabBarItemWidth = CYLTabBarItemWidth;
    CGFloat WidthOffsetWithIndex = originalTabBarItemWidth - visiableTabBarItemWidth;
    return fabs(WidthOffsetWithIndex);
}

- (UIControl *)cyl_selectedControl {
    UIControl *selectedControl = objc_getAssociatedObject(self, @selector(cyl_selectedControl));
    if (!selectedControl) {
        @try {
            do {
                selectedControl = self.cyl_platterSelectedContentViews[0];
                
                if (selectedControl) {
                    break;
                }
                selectedControl = self.cyl_platterContentViews[0];
                
                if (selectedControl) {
                    break;
                }
                selectedControl = self.cyl_visibleControls[0];
                
                if (selectedControl) {
                    break;
                }
            } while (false); // same as : 0, NO
        } @catch (NSException *exception) {}
    }
    return selectedControl;
}

- (void)cyl_setSelectedControl:(UIControl *)selectedControl {
    UIControl *selectedControl_ = selectedControl;
    objc_setAssociatedObject(self, @selector(cyl_selectedControl), selectedControl_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_selectedIndex {
    NSInteger selectedIndex = self.cyl_selectedControl.cyl_tabBarItemVisibleIndex;
    return selectedIndex;
}

@end

@implementation UITabBar (CYLTabBarControllerExtention)

- (CGFloat)cyl_platterViewWidth {
    NSNumber *platterViewWidthObject = objc_getAssociatedObject(self, @selector(cyl_platterViewWidth));
    return [platterViewWidthObject floatValue];
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
 ├── SelectedContentView        ❌ 状态壳
 ├── _UILiquidLensView          ❌ 视觉
 └── ContentView                ✅ 真正容器
 ├── _UITabButton           ✅
 ├── _UITabButton           ✅
 ├── _UITabButton           ❌ hidden / disabled（中间占位）
 ├── _UITabButton           ✅
 ├── _UITabButton           ✅
 └── DestOutView            ❌
 └── CYLPlusButtonSubclass              ⭐
 
 */
- (NSArray<UIControl *> *)cyl_tabBarSubviews {
    if (![CYLConstants isUsedLiquidGlass]) {
        return self.subviews;
        
    }
    // iOS 26 以前，保持原逻辑
    if (CYL_UIDesignOldVersionCYLTabBarWithoutiOS26) {
        return self.subviews;
    }
    
    
    UIView *platterView = self.cyl_platterView;
    if (![platterView cyl_isPlatterView]) {        
        return self.subviews;
    }
    
    // 记录 platter 尺寸
    [self cyl_setPlatterViewWidth:platterView.bounds.size.width];
    [self cyl_setPlatterViewSize:[NSValue valueWithCGSize:platterView.bounds.size]];
    
    UIView * container = platterView;
    // 3️⃣ 从 PlatterView 中，找真正承载 UITabBarButton 的 ContentView
    UIView *contentView = nil;
    for (UIView *sub in container.subviews) {
        if ([sub cyl_isPlatterContentView]) {
            contentView = sub;
            break;
        }
    }
    return [self cyl_allTabViewsFrom:contentView] ?: self.subviews;
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

    // 4️⃣ 收集所有 UITabBarItem 对应 view UITabButton 的 frame
    NSMutableArray<UIView *> *itemViews = [NSMutableArray array];
    for (UIView *sub in contentView.subviews) {
        if ([sub isKindOfClass:UIControl.class]) {
            [itemViews addObject:sub];
         }
    }
    
    // 5️⃣ 按视觉顺序排序（x 轴）
    [itemViews sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        if (CGRectGetMinX(a.frame) < CGRectGetMinX(b.frame)) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
#if defined(DEBUG) || defined(BETA)
    
    // 6️⃣ 转成 frame 数组
    NSMutableArray<NSValue *> *frames = [NSMutableArray array];
    for (UIView *v in itemViews) {
        [frames addObject:[NSValue valueWithCGRect:v.frame]];
    }
    static BOOL logged = NO;
    if (!logged) {
        logged = YES;
    }
#endif

    return itemViews;
}

- (CGFloat)cyl_fullHeight {
    return CYLGetTabBarFullH(self.cyl_boundsSize.height);
}

- (CGSize)cyl_boundsSize {
    CGSize size = self.bounds.size;
    if (![CYLConstants isUsedLiquidGlass]) {
        return size;
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
    if (![CYLConstants isUsedLiquidGlass]) {
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
    @try {
        view = self.cyl_platterViews[index];
    } @catch (NSException *exception) {
        
    }
    return view;
}
- (NSArray *)cyl_platterContentViews {
    return  self.cyl_tabBarSubviews;
}

- (UIView *)cyl_platterContentViewWithIndex:(NSInteger)index {
    UIView *view = nil;
    @try {
        view = self.cyl_platterContentViews[index];
    } @catch (NSException *exception) {
    }
    return  view;
}

- (UIView *)cyl_platterSelectedContentView {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {
        
        //TODO:  找到罩子的真正view， 修改frame
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

- (NSArray<UIControl *> *)cyl_platterSelectedContentViews {
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
    
    
    return [self cyl_allTabViewsFrom:contentView] ?: self.subviews;
    
}


- (UIView *)cyl_platterLiquidLensView {
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

- (UIView *)cyl_platterVisualProviderFloatingSelectedContentView {
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


/*!
 * [self.tabBar.cyl_portalView cyl_valueForKey:@"sourceView"]
 * ===
 self.tabBar.cyl_platterLiquidLensViewContentView
 */
- (UIView *)cyl_platterLiquidLensViewContentView {
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





- (UIView *)cyl_platterLiquidLensClearGlassView {
    UIView *contentView;// = [self.cyl_platterLiquidLensView cyl_valueForKey:@"belowGlassWarpBackdrop"];
    
    if (contentView) {
        return contentView;
    }
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


- (NSArray<UIView *> *)cyl_platterLiquidLensViewSubViews {
    UIView *contentView = self.cyl_platterLiquidLensViewContentView;
    
    if (!contentView) {
        return nil;
    }
    
    
    return contentView.subviews;
    
}



- (UIView *)cyl_platterDestOutView {
    UIView *contentView = nil;
    for (UIView *sub in self.cyl_platterView.subviews) {
        //TODO:  找到罩子的真正view， 修改frame
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
    @try {
        view = self.cyl_platterSelectedContentViewsWithoutPlusButton[index];
    } @catch (NSException *exception) {
        
    }
    return view;
}

- (UIControl *)cyl_platterSelectedContentViewWithIndex:(NSInteger)index {
    //    - (BOOL)cyl_isPlatterView; {
    UIControl *view = nil;
    @try {
        view = self.cyl_platterSelectedContentViews[index];
    } @catch (NSException *exception) {
        
    }
    return view;
}

- (NSArray *)cyl_platterPortalViews {
    return  [NSArray new];
}

- (UIView *)cyl_platterPortalViewWithIndex:(NSInteger)index {
    //    - (BOOL)cyl_isPlatterView; {
    UIView *view = nil;
    @try {
        view = self.cyl_platterPortalViews[index];
    } @catch (NSException *exception) {
        
    }
    return view;
}

@end

