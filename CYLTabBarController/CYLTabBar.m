//
//  CYLTabBar.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBar.h"
#import "CYLTabBarController.h"
#import "CYLConstants.h"
#import <objc/runtime.h>
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"

static void *const CYLTabBarContext = (void*)&CYLTabBarContext;


@interface CYLTabBar () <UIGestureRecognizerDelegate>

@end

@implementation CYLTabBar
@synthesize plusButton = _plusButton;

#pragma mark -
#pragma mark - LifeCycle Method

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self = [self sharedInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self = [self sharedInit];
    }
    return self;
}

- (void)setPlusButton:(UIButton<CYLPlusButtonSubclassing> *)plusButton {
    if (!plusButton) {
        return;
    }
    _plusButton = plusButton;
    if (!self.hasAddPlusButton) {
        NSString *tabBarContext = self.plusButtonTabBarContext;
        BOOL isFirstAdded = (_plusButton.superview == nil);
        BOOL isSameContext = [tabBarContext isEqualToString:self.context] && (tabBarContext && self.context);
        if (_plusButton && isSameContext && isFirstAdded) {
            //TODO:  应该放进选中图层， 而非粗暴放进最底层，
            [self cyl_addPlatterViewThenBringSubviewToFront:(UIButton *)_plusButton];
            self.addPlusButton = YES;
            [_plusButton cyl_setTabBarController:[self cyl_tabBarController]];
        }
    }
}

- (void)setContext:(NSString *)context {
    _context = context;
    self.plusButton = CYLExternPlusButton;
    self.cyl_context = context;
}

- (instancetype)sharedInit {
    // KVO注册监听
    _tabBarItemWidth = CYLTabBarItemWidth;
    [self addObserver:self forKeyPath:@"tabBarItemWidth" options:NSKeyValueObservingOptionNew context:CYLTabBarContext];
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    CGFloat height = [self cyl_tabBarController].tabBarHeight;
    if (height > 0) {
        sizeThatFits.height = height;
    }
    return sizeThatFits;
}

/**
 *  lazy load tabBarButtonArray
 *
 *  @return NSArray
 */
- (NSArray<UIControl *> *)tabBarButtonArray {
    if (_tabBarButtonArray == nil) {
        _tabBarButtonArray = @[];
    }
    return _tabBarButtonArray;
}

- (NSString *)plusButtonTabBarContext {
    NSString *tabBarContext;
    if ([[_plusButton class] respondsToSelector:@selector(tabBarContext)]) {
        tabBarContext = [[_plusButton class] tabBarContext];
    }
    if (tabBarContext && tabBarContext.length > 0) {
        return tabBarContext;
    }
    tabBarContext = NSStringFromClass([CYLTabBarController class]);
    return tabBarContext;
}

- (UIButton<CYLPlusButtonSubclassing> *)plusButton {
    if (!CYLExternPlusButton || !_plusButton) {
        return nil;
    }
    NSString *plusButtonTabBarContext = self.plusButtonTabBarContext;
    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    BOOL isSameContext = [plusButtonTabBarContext isEqualToString:self.context] && (plusButtonTabBarContext && self.context);//|| (!tabBarContext  && !self.context);
    if (_plusButton  && addedToTabBar && isSameContext) {
//        _plusButton.hidden = YES;
        return _plusButton;
    }
    return nil;
}

- (void)presetUnselectedItemTintColor {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (self.unselectedItemTintColor) {
            return;
        }
        __block UIColor *tabLabelTextColor = nil;//for iOS13+
        tabLabelTextColor = [UIColor cyl_systemGrayColor];
        [self.tabBarButtonArray enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIControl *childView = obj;
            if (childView.selected) {
                return;
            }
            if (childView.cyl_tabEffectView && childView.cyl_tabLabel ) {
                tabLabelTextColor = childView.cyl_tabLabel.textColor;
            }
        }];
        
        if (@available(iOS 26.0, *)) {
            //fix #631
            [self.cyl_tabBarSubviews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj cyl_isTabLabel]) {
                        @try {
                            UILabel *label = (UILabel *)obj;
                            UIColor *color = label.textColor;
                            if (color && [color isKindOfClass:[UIColor class]]) {
                                tabLabelTextColor = label.textColor;
                                *stop = YES;
                                return;
                            }
                        } @catch (NSException *exception) {
                            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
                        }
                    }
                }];
            }];
        }
        self.unselectedItemTintColor = tabLabelTextColor;
    }
#endif
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tabBarButtonArray = [self cyl_originalTabBarButtons];
    
    [self presetUnselectedItemTintColor];
    if (self.tabBarButtonArray && self.tabBarButtonArray.count > 0) {
        [self setupTabImageViewDefaultOffset:self.tabBarButtonArray[0]];
    }
    
    CGFloat tabBarWidth = self.cyl_boundsSize.width;
    
    if (!self.addPlusButton) {
        return;
    }
    
    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    if (!addedToTabBar) {
        CYLTabBarItemWidth = (tabBarWidth) / CYLTabbarItemsCount;
        [self.tabBarButtonArray enumerateObjectsUsingBlock:^(UIControl * _Nonnull childView, NSUInteger buttonIndex, BOOL * _Nonnull stop) {
            //仅修改childView的x和宽度,yh值不变
            CGFloat childViewX = buttonIndex * CYLTabBarItemWidth;
            [self changeXForChildView:childView
                           childViewX:childViewX
                      tabBarItemWidth:CYLTabBarItemWidth
                                index:buttonIndex
            ];
        }];
        return;
    }
    CYLTabBarItemWidth = (tabBarWidth - CYLPlusButtonWidth) / CYLTabbarItemsCount;
   //plusButtonIndex内部调整 PlusButton 的中心坐标，不能直接修改 center，否则会造成点击动画时的闪动bug，需要借助坐标系转换。
    NSUInteger plusButtonIndex = [self plusButtonIndex];
    [self.tabBarButtonArray enumerateObjectsUsingBlock:^(UIControl * _Nonnull childView, NSUInteger buttonIndex, BOOL * _Nonnull stop) {
        //调整UITabBarItem的位置
        CGFloat childViewX;
        CGFloat visiableTabIndex = buttonIndex;
        CGFloat tabBarItemWidth = CYLTabBarItemWidth;
        
        if ([self cyl_hasPlusChildViewController]) {
            if (buttonIndex <= plusButtonIndex) {
                childViewX = buttonIndex * CYLTabBarItemWidth;
            } else {
                childViewX = (buttonIndex - 1) * CYLTabBarItemWidth + CYLPlusButtonWidth;
            }
            if (buttonIndex == plusButtonIndex) {
                tabBarItemWidth = CYLPlusButtonWidth;
            }
        } else {
            if (buttonIndex >= plusButtonIndex) {
                childViewX = buttonIndex * CYLTabBarItemWidth + CYLPlusButtonWidth;
                visiableTabIndex = buttonIndex  + 1;
            } else {
                childViewX = buttonIndex * CYLTabBarItemWidth;
            }
        }
        
        [childView cyl_setTabBarChildViewControllerIndex:buttonIndex];
        UIControl *selectedContentControl = [self cyl_selectedContentControlFromContentControl:childView];
        
        [selectedContentControl cyl_setTabBarChildViewControllerIndex:buttonIndex];
        //仅修改childView的x和宽度,yh值不变
        [self changeXForChildView:childView
                       childViewX:childViewX
                  tabBarItemWidth:tabBarItemWidth
                            index:visiableTabIndex
        ];
    }];
}

/*!
 * iOS26+ 玻璃效果不能使用 frame 进行修改， 否则 会引发 手势的 lifted 状态变更后，点击后左右闪动bug。
 */
- (void)changeXForChildView:(UIControl *)childView
                 childViewX:(CGFloat)childViewX
            tabBarItemWidth:(CGFloat)tabBarItemWidth
                      index:(NSUInteger)index {
    if (![CYLConstants isUsedLiquidGlass]) {
        //仅修改childView的x和宽度,yh值不变
        childView.frame = CGRectMake(childViewX,
                                     CGRectGetMinY(childView.frame),
                                     tabBarItemWidth,
                                     CGRectGetHeight(childView.frame)
                                     );
        childView.layer.frame = CGRectMake(childViewX,
                                           CGRectGetMinY(childView.frame),
                                           tabBarItemWidth,
                                           CGRectGetHeight(childView.frame)
                                           );
    }
    UIControl *selectedContentControl = [self cyl_selectedContentControlFromContentControl:childView];
    [childView cyl_setTabBarItemVisibleIndex:index];
    if (!selectedContentControl) { return; }
    //只有玻璃效果有 selectedContentControl，所以可以代替玻璃效果判断。
    //非常重要的 transform 设置， 请勿删除， iOS26+ 玻璃效果+Lottie动画需要禁用形变，否则会引发手势的 lifted 状态变更后的闪动bug。因静态图片场景下不会引起异常， 故未判断是否为Lottie场景
    selectedContentControl.transform = CGAffineTransformIdentity;//(1, 1);
}

#pragma mark - plusFrame and tabBarItemFrameWithIndex

- (CGFloat)tabItemWidth {
    return CYLTabBarItemWidth;
}

- (CGFloat)plusWidth {
    return CYLPlusButtonWidth;
}

- (CGRect)plusFrame {
    return CGRectMake(CYLHalfOfDiff(CYLScreenWidth(), [self plusWidth]), 0, [self plusWidth], CYLTabBarHeight);
}

//- (CGRect)tabBarItemFrameWithIndex:(NSInteger)index {
//    
//    NSInteger plusButtonIndex = 2;
////    CGFloat childViewX = plusButtonIndex * CYLTabBarItemWidth;
////    CGFloat tabBarItemWidth = CGRectGetWidth(self.plusButton.frame);
//    
//    CGFloat w = [self tabItemWidth];
//    CGFloat h = CYLTabBarHeight;
//    CGFloat x = 0;
//    if (index > 1) {
//        x = CYLScreenWidth() - w - (3 - index) * (w + CYLScaleValue(2));
//    } else {
//        x = index * (w + CYLScaleValue(2));
//    }
//    
//    CGFloat y = 0;
//    
//    return CGRectMake(x, y, w, h);
//}

#pragma mark -

#pragma mark -
#pragma mark - Private Methods

//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    return NO;
//}

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context == CYLTabBarContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemWidthDidChangeNotification object:self];
        if (@available(iOS 11.0, *)) {
            if (CYL_IS_IPHONE_X) {
                [self layoutIfNeeded];
            }
        }
    }
}

- (void)dealloc {
    // KVO反注册
    @try {
        [self removeObserver:self forKeyPath:@"tabBarItemWidth"];
    } @catch (NSException *exception) {
    }
}

- (void)setTabBarItemWidth:(CGFloat )tabBarItemWidth {
    if (_tabBarItemWidth != tabBarItemWidth) {
        [self willChangeValueForKey:@"tabBarItemWidth"];
        _tabBarItemWidth = tabBarItemWidth;
        [self didChangeValueForKey:@"tabBarItemWidth"];
    }
}

- (void)setTabImageViewDefaultOffset:(CGFloat)tabImageViewDefaultOffset {
    if (tabImageViewDefaultOffset != 0.f) {
        [self willChangeValueForKey:@"tabImageViewDefaultOffset"];
        _tabImageViewDefaultOffset = tabImageViewDefaultOffset;
        [self didChangeValueForKey:@"tabImageViewDefaultOffset"];
    }
}

- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
    if ([CYLConstants isUsedLiquidGlass] && self.cyl_hasPlusChildViewController) {
        return 0.5;
    }
    CGFloat multiplierOfTabBarHeight;
    if ([[self.plusButton class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
        multiplierOfTabBarHeight = [[self.plusButton class] multiplierOfTabBarHeight:tabBarHeight];
    }
    
    CYL_DEPRECATED_DECLARATIONS_PUSH
    else if ([[self.plusButton class] respondsToSelector:@selector(multiplerInCenterY)]) {
        multiplierOfTabBarHeight = [[self.plusButton class] multiplerInCenterY];
    }
    CYL_DEPRECATED_DECLARATIONS_POP
    
    else {
        CGSize sizeOfPlusButton = self.plusButton.frame.size;
        CGFloat heightDifference = sizeOfPlusButton.height - self.cyl_boundsSize.height;
        if (heightDifference < 0) {
            multiplierOfTabBarHeight = 0.5;
        } else {
            CGPoint center = CGPointMake(self.cyl_boundsSize.height * 0.5, self.cyl_boundsSize.height * 0.5);
            center.y = center.y - heightDifference * 0.5;
            multiplierOfTabBarHeight = center.y / self.cyl_boundsSize.height;
        }
    }
    return multiplierOfTabBarHeight;
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    if ([CYLConstants isUsedLiquidGlass] && self.cyl_hasPlusChildViewController) {
        return 0;
    }
    CGFloat constantOfPlusButtonCenterYOffset = 0.f;
    if ([[self.plusButton class] respondsToSelector:@selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:)]) {
        constantOfPlusButtonCenterYOffset = [[self.plusButton class] constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    }
    return constantOfPlusButtonCenterYOffset;
}

- (NSUInteger)plusButtonIndex {
    NSUInteger plusButtonIndex;
    if ([[self.plusButton class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
        plusButtonIndex = [[self.plusButton class] indexOfPlusButtonInTabBar];
    } else {
        if (CYLTabbarItemsCount % 2 != 0) {
#if defined(DEBUG) || defined(BETA)
            [NSException raise:NSStringFromClass([CYLTabBarController class]) format:@"[DEBUG INFO]If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO] 如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
#endif
        } else {
            plusButtonIndex = CYLTabbarItemsCount * 0.5;
        }
    }
    CYLPlusButtonIndex = plusButtonIndex;
    [self.plusButton cyl_setTabBarItemVisibleIndex:CYLPlusButtonIndex];
    
    UIView *platterView = self.cyl_contentView;
    CGFloat tabBarHeight = self.cyl_boundsSize.height;
    
    // 系统默认参数
    CGFloat multiplierOfTabBarHeight =
    [self multiplierOfTabBarHeight:tabBarHeight];
    
    CGFloat constantOfPlusButtonCenterYOffset =
    [self constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    
    // ===============================
    // 计算 platterView 中心
    // ===============================
    CGPoint platterCenter =
    [platterView.superview convertPoint:platterView.center
                                 toView:self];
    
    // ===============================
    // 叠加系统默认 Y 逻辑
    // ===============================
    CGFloat systemDefaultY =
    tabBarHeight * multiplierOfTabBarHeight
    + constantOfPlusButtonCenterYOffset;
    
    // 计算最终中心
    CGPoint finalCenter = CGPointMake(
                                      platterCenter.x ,
                                      systemDefaultY
                                      );
    
    // ===============================
    // 禁止隐式动画
    // ===============================
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    self.plusButton.center = finalCenter;
    
    [CATransaction commit];
    
    return plusButtonIndex;
}

- (void)setupTabImageViewDefaultOffset:(UIView *)tabBarButton {
    if (self.tabImageViewDefaultOffset > 0) {
        return;
    }
    __block BOOL shouldCustomizeImageView = YES;
    __block CGFloat tabImageViewDefaultOffset = 0.f;
    CGFloat tabButtonCenterY = tabBarButton.center.y;
    [tabBarButton.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj cyl_isTabLabel]) {
            shouldCustomizeImageView = NO;
        }
        CGFloat tabImageViewCenterY = obj.center.y;
        
        BOOL isTabImageView = [obj cyl_isTabImageView];
        if (isTabImageView) {
            tabImageViewDefaultOffset = (tabButtonCenterY - tabImageViewCenterY) * 0.5;
        }
        if (isTabImageView && tabImageViewDefaultOffset == 0.f) {
            shouldCustomizeImageView = NO;
        }
    }];
    if (shouldCustomizeImageView) {
        self.tabImageViewDefaultOffset = tabImageViewDefaultOffset;
    }
}

/*!
 *  Capturing touches on a subview outside the frame of its superview.
 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    //1. 边界情况：不能响应点击事件
    
    BOOL canNotResponseEvent = self.cyl_canNotResponseEvent;
    if (canNotResponseEvent) {
        return [super hitTest:point withEvent:event];
    }
    
    //2. 优先处理 PlusButton （包括其突出的部分）、TabBarItems 未凸出的部分
    //这一步主要是在处理只有两个 TabBarItems 的场景。
    // 2.1先考虑clipsToBounds情况：子view超出部分没有显示出来
    if (self.clipsToBounds && ![self pointInside:point withEvent:event]) {
        return [super hitTest:point withEvent:event];
    }
    
    if (self.plusButton) {
        CGRect plusButtonFrame = self.plusButton.frame;
        BOOL isInPlusButtonFrame = CGRectContainsPoint(plusButtonFrame, point);
        if (isInPlusButtonFrame) {
            return self.plusButton;
        }
    }
    NSArray *tabBarButtons = self.tabBarButtonArray;
    if (self.tabBarButtonArray.count == 0) {
        tabBarButtons = [self cyl_visibleControls];
    }
    for (NSUInteger index = 0; index < tabBarButtons.count; index++) {
        UIView *selectedTabBarButton = tabBarButtons[index];
        CGRect selectedTabBarButtonFrame = selectedTabBarButton.frame;
        BOOL isTabBarButtonFrame = CGRectContainsPoint(selectedTabBarButtonFrame, point);
        if (isTabBarButtonFrame && !selectedTabBarButton.hidden) {
            return selectedTabBarButton;
        }
    }
    //CYLFlatDesignTabBar 已经封装在该类内部，不需要在这里处理
    
    //3. 最后处理 TabBarItems 凸出的部分、添加到 TabBar 上的自定义视图、点击到 TabBar 上的空白区域
    UIView *result = [super hitTest:point withEvent:event];
    if (result) {
        return result;
    }
    
    for (UIView *subview in self.subviews.reverseObjectEnumerator) {
        CGPoint subPoint = [subview convertPoint:point fromView:self];
        result = [subview hitTest:subPoint withEvent:event];
        if (result) {
            return result;
        }
    }
    return [super hitTest:point withEvent:event];
}

- (void)addSubview:(UIView *)view {
    if ([view cyl_isPlatterView]) {
        [self cyl_setPlatterView:view];
        
        UIView * container = view;
        //  从 PlatterView 中，找真正承载 UITabBarButton 的 ContentView
        UIView *contentView = nil;
        for (UIView *sub in container.subviews) {
            if ([sub cyl_isPlatterContentView]) {
                contentView = sub;
                break;
            }
        }
        
        if (contentView) {
            [self cyl_setPlatterContentView:contentView];
        }
    }
    //点击后的聚焦瞬间遮罩
    if ([view cyl_isPlatterPortalView]) {
        
        if (!self.cyl_portalView) {
            [self cyl_setPortalView:view];
        }
    }
    
    [super addSubview:view];
}

// 识别ContinuousSelection手势，需要禁止长按等其他
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ([CYLConstants isUsedLiquidGlass] && [self isKindOfClass:[CYLTabBar class]] && !CYLPlusChildViewController) {
        if ([gestureRecognizer cyl_isContinuousGestureRecognizer]) {
            gestureRecognizer.delegate = self;
        }
        if ([gestureRecognizer cyl_isLongGestureRecognizer]) {
            gestureRecognizer.delegate = self;
        }
    }
    [super addGestureRecognizer:gestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:nil];
    if ([hitView isKindOfClass:[CYLPlusButton class]]) {
        return NO;
    }
    return YES;
}

@end

