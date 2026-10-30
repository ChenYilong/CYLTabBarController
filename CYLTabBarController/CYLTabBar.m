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
static void *const CYLTabBarAlpha = (void*)&CYLTabBarAlpha;


// Implemented in CYLTabBarController.m, issue #610.
@interface CYLTabBarController (CYLTabControlActions)
- (void)cyl_bindTabControlActions;
@end

@interface CYLTabBar () <UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSMutableSet<UIView *> *observedViews;

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

- (NSString *)context {
    return self.cyl_context;
}

- (void)setContext:(NSString *)context {
    self.cyl_context = context;
    [self setPlusButton:CYLExternPlusButton];
}

- (instancetype)sharedInit {
    // KVO注册监听
    _tabBarItemWidth = CYLTabBarItemWidth;
    [self addObserver:self forKeyPath:@"tabBarItemWidth" options:NSKeyValueObservingOptionNew context:CYLTabBarContext];
    __weak __typeof(self) weakSelf = self;
    void (^CYLTabBarItemLottieAnimationPlayingNotificationBlock)(NSNotification *) = ^(NSNotification *notification) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
             return;
        }
        [self cyl_stopAnimationOfAllLottieView];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemLottieAnimationPlayingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:CYLTabBarItemLottieAnimationPlayingNotificationBlock];
    [self cyl_keepStackedItemLayoutOnHingedDevice];
    return self;
}

#pragma mark - Stacked item layout on hinged devices (iOS 27.1+, iPhone Duo)
// MARK: Stacked item layout

/*!
 * FIX: issue #680
 * [EN] Liquid Glass only. When the iPhone Duo is in landscape with a compact height (e.g. folded), UIKit switches the
 *      tab items to the compact inline layout: icon on the left, title on the right, 36 pt high. CYLTabBarController
 *      lays out Lottie icons, badges and the plus button for the stacked layout, so their centres no longer match.
 *      On a device with a hinge, this keeps the tab bar's vertical size class regular, so the items stay stacked
 *      (icon above title) as in portrait. The hinge is found with `UIHingeInteraction`, which only reports a hinge on
 *      foldable devices; every other device and the FlatDesign style are unchanged.
 * [CN] 仅液态玻璃样式。iPhone Duo 横屏且高度为 compact（如折叠时）时，UIKit 把 Tab 按钮切换为紧凑横排布局：
 *      图标在左、标题在右，高 36pt。CYLTabBarController 的 Lottie 图标、角标、加号按钮都按上下布局计算，中心点因此错位。
 *      在有铰链的设备上，把 TabBar 的垂直 size class 固定为 regular，按钮保持与竖屏一致的上下结构（图标在上、标题在下）。
 *      通过 `UIHingeInteraction` 判断是否有铰链（只有可折叠设备才会返回铰链），其他设备和扁平样式不受影响。
 */
- (void)cyl_keepStackedItemLayoutOnHingedDevice {
#if defined(__IPHONE_27_1) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_27_1
    if (@available(iOS 27.1, *)) {
        if (![CYLConstants isLiquidGlassActive]) { return; }
        __weak __typeof(self) weakSelf = self;
        UIHingeInteraction *hingeInteraction = [[UIHingeInteraction alloc] initWithUpdateHandler:^(UIHingeInteraction *interaction, UIHingeInteractionUpdate *update) {
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self || !update.hinge) { return; }
            // Reading an unset override throws, so check `containsTrait:` first. Hinge angle updates can be frequent.
            if (![self.traitOverrides containsTrait:UITraitVerticalSizeClass.class]) {
                self.traitOverrides.verticalSizeClass = UIUserInterfaceSizeClassRegular;
            }
        }];
        [self addInteraction:hingeInteraction];
    }
#endif
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    if ([CYLConstants isLiquidGlassActive]) {
        //如果不是扁平设计风格，也就是液态玻璃不支持自定义高度， 液态玻璃系统样式是固定高度的。// Unless it's a flat design style—in which case Liquid Glass does not support custom heights—the Liquid Glass system style has a fixed height.
        return sizeThatFits;
    }

    CGFloat height = [self cyl_tabBarController].tabBarHeight + [self cyl_tabBarController].view.safeAreaInsets.bottom;
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

- (NSString *)matchedTabBarContext {
    NSString *matchedTabBarContext = [[CYLExternPlusButton class] matchedTabBarContext];
    return matchedTabBarContext;
}

- (BOOL)hasPlusButton {
    BOOL isSameContext = [[CYLExternPlusButton class] hasPlusButtonForTabBarContext:self.context];//|| (!tabBarContext  && !self.context);
    return isSameContext;
}

- (BOOL)hasPlusChildViewController {
    BOOL hasPlusChildViewController = [[CYLExternPlusButton class] hasPlusChildViewControllerForTabBarContext:self.context];//|| (!tabBarContext  && !self.context);;//&& !isAdded;
    return hasPlusChildViewController;
}

- (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton {
    if (!CYLExternPlusButton || !_plusButton) {
        return nil;
    }

    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    BOOL isSameContext = [self hasPlusButton];

    if (_plusButton  && addedToTabBar && isSameContext) {
        return _plusButton;
    }
    return nil;
}

- (void)setPlusButton:(CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton {
    if (!plusButton) {
        return;
    }
    if (![self hasPlusButton]) {
        return;
    }
    _plusButton = plusButton;
    if (!self.isPlusButtonActive) {
        BOOL isFirstAdded = (_plusButton.superview == nil);
        BOOL isSameContext = [self hasPlusButton];
        if (_plusButton && isSameContext && isFirstAdded) {
            //TODO:  iOS26 考虑应该放进选中图层，而非粗暴放进最底层，这样未来可以 PlusButton 支持自定义index
            [self cyl_addPlatterViewThenBringSubviewToFront:(UIButton *)_plusButton];
            self.plusButtonActive = YES;
            [_plusButton cyl_setTabBarController:[self cyl_tabBarController]];
        }
    }
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
#if defined(DEBUG) || defined(BETA)
                            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
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
    [self cyl_layoutTabBarSubviews];
    // FIX: issue #610 — UIKit replaces the tab buttons when an item's image changes and lays out only the tab bar,
    // so bind the tap action here as well, not only in the controller's -viewDidLayoutSubviews. Done after the layout
    // above, which sets each new button's visible index (used to recognise the plus child view controller's button).
    // 修改 item 图片后 UIKit 会重建 Tab 按钮且只重新布局 TabBar，所以这里也要为新按钮添加点击事件。放在上面的布局之后，
    // 因为布局时才会设置新按钮的 visible index（用于识别加号子控制器对应的按钮）。
    [self.tabBarController cyl_bindTabControlActions];
}

- (void)cyl_layoutTabBarSubviews {
    self.tabBarButtonArray = [self cyl_originalTabBarButtons];
    
    [self presetUnselectedItemTintColor];
    if (self.tabBarButtonArray && self.tabBarButtonArray.count > 0) {
        [self setupTabImageViewDefaultOffset:self.tabBarButtonArray[0]];
    }
    
    // FIX: iOS15有时候会导致TaBar透明的问题 但是这样会导致无法主动让TabBar透明 考虑以后添加属性 // 现在通过判断isHidden来处理，如果隐藏了就不再修改alpha
    if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.0") && ![CYLConstants isLiquidGlassActive]) {
        [self removeAlphaObserver];
        UIView *backgroundView = self.cyl_tabBackgroundView;
        UIView *shadowView = self.cyl_tabShadowImageView.subviews.firstObject;
        
        if (shadowView && ![self.observedViews containsObject:shadowView]) {
            [self.observedViews addObject:shadowView];
            [shadowView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:CYLTabBarAlpha];
        }
        if ([UITabBar appearance].backgroundImage) {
            UIView *imageView = backgroundView.cyl_imageView;
            if (imageView && ![self.observedViews containsObject:imageView]) {
                [self.observedViews addObject:imageView];
                [imageView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:CYLTabBarAlpha];
            }
        } else {
            UIView *effectView = backgroundView.cyl_tabEffectView;
            if (effectView && ![self.observedViews containsObject:effectView]) {
                [self.observedViews addObject:effectView];
                [effectView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:CYLTabBarAlpha];
            }
        }
    }
    CGFloat tabBarWidth = self.cyl_boundsSize.width;
    
    if (!self.plusButtonActive) {
        if (self.didLayoutSubViewsBlock) {
            self.didLayoutSubViewsBlock(self);
        }
        return;
    }
    
    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    if (!addedToTabBar && self.hasPlusButton) {
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
        if (self.didLayoutSubViewsBlock) {
            self.didLayoutSubViewsBlock(self);
        }
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
    if (self.didLayoutSubViewsBlock) {
        self.didLayoutSubViewsBlock(self);
    }
}

/*!
 * iOS26+ 玻璃效果不能使用 frame 进行修改， 否则 会引发 手势的 lifted 状态变更后，点击后左右闪动bug。
 */
- (void)changeXForChildView:(UIControl *)childView
                 childViewX:(CGFloat)childViewX
            tabBarItemWidth:(CGFloat)tabBarItemWidth
                      index:(NSUInteger)index {
    if (![CYLConstants isLiquidGlassActive]) {
        //RTL（如阿语）下镜像 x 坐标，使第 0 个 Tab 位于最右侧
        if ([self cyl_isRightToLeftLayout]) {
            childViewX = self.cyl_boundsSize.width - childViewX - tabBarItemWidth;
        }
        //仅修改childView的x和宽度,yh值不变
        childView.frame = CGRectMake(childViewX,
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

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return NO;
}

// KVO监听执行
/*!
 //TODO:   iOS26 适配以下接口， 思路是监听， 特定窗口的缩小尺寸变动。执行隐藏和现实PlusButton操作。
 * 增加了类型为UITabBarController.MinimizeBehavior的tabBarMinimizeBehavior属性，用于设置 Tabbar 最小化时的行为。
增加了类型为UITabAccessory的bottomAccessory属性，用于在 Tabbar 的上方再添加一个 UITabAccessory（辅助内容）。
UISearchTab 会从 TabBar 分离出来单独显示。
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == CYLTabBarAlpha) {
        UIView *view = object;
        if (!view.isHidden) {
            if ([change[NSKeyValueChangeNewKey] floatValue] == 0) {
                view.alpha = 1;
            }
        }
        return;
    }
    if(context != CYLTabBarContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == CYLTabBarContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemWidthDidChangeNotification object:self];
        if (@available(iOS 11.0, *)) {
            if (CYL_IS_IPHONE_X) {
                [self layoutIfNeeded];
            }
        }
        return;
    }
}

- (void)dealloc {
    // KVO反注册
    [self cyl_removeObserver:self forKeyPath:@"tabBarItemWidth"];
    [self removeAlphaObserver];
}

- (void)removeAlphaObserver {
    if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.0") && ![CYLConstants isLiquidGlassActive]) {
        [_observedViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj cyl_removeObserver:self forKeyPath:@"alpha"];
        }];
        [_observedViews removeAllObjects];
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

- (BOOL)isPlusButtonLayoutCentered {
    return [self.plusButton isLayoutCentered];
}

- (CGFloat)multiplierOfTabBarHeight {
    
    return [CYLExternPlusButton multiplierOfTabBarHeight:self.cyl_boundsSize.height];
}

//- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
//    CGFloat multiplierOfTabBarHeight;
//    if ([[self.plusButton class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
//        multiplierOfTabBarHeight = [[self.plusButton class] multiplierOfTabBarHeight:tabBarHeight];
//    }
//    
//    CYL_DEPRECATED_DECLARATIONS_PUSH
//    else if ([[self.plusButton class] respondsToSelector:@selector(multiplerInCenterY)]) {
//        multiplierOfTabBarHeight = [[self.plusButton class] multiplerInCenterY];
//    }
//    CYL_DEPRECATED_DECLARATIONS_POP
//    
//    else {
//        CGSize sizeOfPlusButton = self.plusButton.frame.size;
//        CGFloat heightDifference = sizeOfPlusButton.height - self.cyl_boundsSize.height;
//        if (heightDifference < 0) {
//            multiplierOfTabBarHeight = 0.5;
//        } else {
//            CGPoint center = CGPointMake(self.cyl_boundsSize.height * 0.5, self.cyl_boundsSize.height * 0.5);
//            center.y = center.y - heightDifference * 0.5;
//            multiplierOfTabBarHeight = center.y / self.cyl_boundsSize.height;
//        }
//    }
//    return multiplierOfTabBarHeight;
//}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight {
    return [self constantOfPlusButtonCenterYOffsetForTabBarHeight:self.cyl_boundsSize.height];
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    CGFloat constantOfPlusButtonCenterYOffset = 0.f;
    if ([[self.plusButton class] respondsToSelector:@selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:)]) {
        constantOfPlusButtonCenterYOffset = [[self.plusButton class] constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    }
    return constantOfPlusButtonCenterYOffset;
}

- (NSUInteger)plusButtonIndex {
    NSUInteger plusButtonIndex = NSNotFound;
//
//    if ([[self.plusButton class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
//        plusButtonIndex = [[self.plusButton class] indexOfPlusButtonInTabBar];
//    } else {
//        if (CYLTabbarItemsCount % 2 != 0) {
//#if defined(DEBUG) || defined(BETA)
//            NSAssert(NO, @"[DEBUG INFO]If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO] 如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置");
//#endif
//        } else {
//            plusButtonIndex = CYLTabbarItemsCount * 0.5;
//        }
//    }
    plusButtonIndex = [[self.plusButton class] indexForTabbarItemsCount:CYLTabbarItemsCount];
    CGFloat tabBarWidth = self.cyl_boundsSize.width;
    CGFloat tabBarHeight = self.cyl_boundsSize.height;
    
    if (![CYLConstants isLiquidGlassActive]) {
        CGFloat multiplierOfTabBarHeight = [self multiplierOfTabBarHeight];
        CGFloat constantOfPlusButtonCenterYOffset = [self constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
        _plusButton.center = CGPointMake(tabBarWidth * 0.5, tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset);
        
        CGFloat childViewX = plusButtonIndex * CYLTabBarItemWidth;
        CGFloat tabBarItemWidth = CGRectGetWidth(self.plusButton.frame);
        [self changeXForChildView:self.plusButton
                       childViewX:childViewX
                  tabBarItemWidth:tabBarItemWidth
                            index:plusButtonIndex
        ];
        CYLPlusButtonIndex = plusButtonIndex;
    } else {
        CYLPlusButtonIndex = plusButtonIndex;
        //FIXME:  to delete 液态玻璃暂时不支持自定义PlusButton位置。
//        [self.plusButton cyl_setTabBarItemVisibleIndex:CYLPlusButtonIndex];
        
        // FIX: issue #653 — iOS 27.1 vertical bar (folded iPhone Duo, `allowsVerticalBar = YES`).
        // [EN] The system moves the tab buttons out of this bar into a vertical bar on the trailing edge, while the
        //      plus button stays here. Centre it on its placeholder tab button instead of the horizontal position.
        // [CN] 系统把 Tab 按钮移出本 TabBar，放进右侧竖向栏，而加号按钮仍在本 TabBar 上，需对齐到它的占位 Tab 按钮中心。
        UIView *verticalBarSlot = [self cyl_verticalBarTabButtonAtIndex:plusButtonIndex];
        if (verticalBarSlot) {
            CGPoint slotCenter = [verticalBarSlot.superview convertPoint:verticalBarSlot.center toView:self];
            if (!CGPointEqualToPoint(self.plusButton.center, slotCenter)) {
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                self.plusButton.center = slotCenter;
                [CATransaction commit];
                // The vertical bar may lay out its buttons after this pass; check again on the next run loop.
                // 竖向栏可能在本次布局之后才排好按钮，下一个 run loop 再校正一次（位置不变时不会再次触发）。
                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf setNeedsLayout];
                });
            }
            [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:plusButtonIndex];
            return plusButtonIndex;
        }
        
        UIView *platterView = self.cyl_contentView;
        
        // 系统默认参数
        CGFloat multiplierOfTabBarHeight =
        [self multiplierOfTabBarHeight];
        
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
    }
    [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:plusButtonIndex];

    return plusButtonIndex;
}

/*!
 * FIX: issue #653
 * [EN] The tab button at `index` when the system shows the tab buttons in the iOS 27.1 vertical bar, i.e. when the
 *      platter is no longer inside this tab bar; nil otherwise.
 * [CN] iOS 27.1 竖向栏中（platter 已不在本 TabBar 内）第 `index` 个 Tab 按钮；其他情况返回 nil。
 */
- (UIView *)cyl_verticalBarTabButtonAtIndex:(NSUInteger)index {
    UIView *platterView = self.cyl_platterView;
    if (!platterView || !platterView.window || platterView.window != self.window || [platterView isDescendantOfView:self]) {
        return nil;
    }
    NSArray<UIControl *> *tabButtons = [self cyl_tabBarSubviews];
    if (index == NSNotFound || index >= tabButtons.count) {
        return nil;
    }
    UIView *tabButton = tabButtons[index];
    return [tabButton isDescendantOfView:platterView] ? tabButton : nil;
}

/*!
 * FIX: issue #653
 * [EN] The tab button (normal layer) under `windowPoint` while the tab buttons are shown in the iOS 27.1 vertical bar; nil otherwise.
 * [CN] iOS 27.1 竖向栏中，位于 `windowPoint`（窗口坐标）下的 Tab 按钮（常态图层）；其他情况返回 nil。
 */
- (UIControl *)cyl_verticalBarTabButtonAtWindowPoint:(CGPoint)windowPoint {
    if (![self cyl_verticalBarTabButtonAtIndex:0]) {
        return nil;
    }
    for (UIControl *tabButton in [self cyl_tabBarSubviews]) {
        CGPoint point = [tabButton convertPoint:windowPoint fromView:nil];
        if ([tabButton pointInside:point withEvent:nil]) {
            return tabButton;
        }
    }
    return nil;
}

/*!
 * FIX: issue #598
 * [EN] Vertical center of the part of `tabBarButton` that holds its content, in this tab bar's coordinates (the same
 *      value as `tabBarButton.center.y` while the button stays above the bottom safe area).
 *      On iOS 16, during a push (iPhone 12), the tab button was laid out stretched over the bottom safe area: its frame
 *      height went from 49 to 83, so `center.y` moved from 24.5 to 41.5. `tabImageViewDefaultOffset` came out ~8.5 pt too
 *      large, the image was moved down onto the title, and since the value is computed only once it stayed wrong.
 *      Leave out the part of the button inside the bottom safe area. Classic style only (no Liquid Glass, no FlatDesign).
 * [CN] `tabBarButton` 中承载内容那部分的垂直中心，使用本 TabBar 的坐标系（按钮位于底部安全区之上时，与
 *      `tabBarButton.center.y` 相同）。
 *      iOS 16（iPhone 12）push 过程中，Tab 按钮会被拉伸到底部安全区内：frame 高度由 49 变为 83，`center.y` 由 24.5 变为 41.5，
 *      计算出的 `tabImageViewDefaultOffset` 偏大约 8.5pt，图片被下移与文字重叠；该值只计算一次，因此会一直错误。
 *      这里排除按钮位于底部安全区内的部分。仅适用于经典样式（非液态玻璃、非扁平样式）。
 */
- (CGFloat)cyl_tabButtonContentCenterY:(UIView *)tabBarButton {
    // Classic style only. Liquid Glass (iOS 26+) lays the buttons out in its own platter, and FlatDesign does not use
    // `tabImageViewDefaultOffset` at all (it is applied only by the classic `-offsetTabBarTabImageViewToFit:`): keep the
    // previous value there. The superview check is a last line of defence for any other button layout.
    // 仅限经典样式：液态玻璃（iOS 26+）的按钮布局在 platter 中，扁平样式完全不使用 `tabImageViewDefaultOffset`
    // （仅由经典样式的 `-offsetTabBarTabImageViewToFit:` 使用），这两种情况保持原值。
    if ([CYLConstants isLiquidGlassActive] ||
        CYLTabBarStyleTypeFlatDesign == self.tabBarController.tabBarStyleType ||
        tabBarButton.superview != self) {
        return tabBarButton.center.y;
    }
    CGRect frame = tabBarButton.frame;
    CGFloat contentMaxY = CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom;
    if (CGRectGetMaxY(frame) <= contentMaxY || contentMaxY <= CGRectGetMinY(frame)) {
        return tabBarButton.center.y;
    }
    return (CGRectGetMinY(frame) + contentMaxY) * 0.5;
}

- (void)setupTabImageViewDefaultOffset:(UIView *)tabBarButton {
    if (self.tabImageViewDefaultOffset > 0) {
        return;
    }
    __block BOOL shouldCustomizeImageView = YES;
    __block CGFloat tabImageViewDefaultOffset = 0.f;
    CGFloat tabButtonCenterY = [self cyl_tabButtonContentCenterY:tabBarButton];
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
 * FIX: issue #653
 * [EN] `view.frame` converted from its superview's coordinate space to this tab bar's; `CGRectNull` if `view` is nil.
 * [CN] 将 `view.frame` 从其父视图坐标系转换到本 TabBar 坐标系；`view` 为 nil 时返回 `CGRectNull`。
 */
- (CGRect)cyl_convertFrameOfView:(UIView *)view {
    if (!view) {
        return CGRectNull;
    }
    UIView *superview = view.superview;
    if (!superview || superview == self) {
        return view.frame;
    }
    return [superview convertRect:view.frame toView:self];
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
        CGRect plusButtonFrame = [self.plusButton touchableRect];
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
        UIControl *selectedTabBarButton = tabBarButtons[index];
        UIView *imageView;
        if (selectedTabBarButton && [selectedTabBarButton isKindOfClass:[UIControl class]] && [selectedTabBarButton respondsToSelector:@selector(cyl_getActualBadgeSuperView)]) {
            imageView = selectedTabBarButton.cyl_getActualBadgeSuperView;
        }
        
        // FIX: issue #653 — in Liquid Glass the tab buttons live in the platter, not in this tab bar, so their `frame`
        // is in the platter's coordinate space while `point` is in this tab bar's. On the unfolded iPhone Duo the platter
        // is centered with a large horizontal offset, so a tap on the 2nd tab hit-tested as another tab and a repeat tap on
        // the selected tab never called `tabBarController:didSelectControl:`. Convert both frames to this tab bar first.
        // 液态玻璃下 Tab 按钮在 platter 内，frame 是 platter 坐标，point 是本 TabBar 坐标；iPhone Duo 展开时 platter 居中、偏移较大，
        // 点击第 2 个 Tab 被识别为其他 Tab，导致选中状态下再次点击不回调 didSelectControl。这里先把 frame 转换到本 TabBar 坐标系。
        CGRect selectedTabBarButtonFrame = [self cyl_convertFrameOfView:selectedTabBarButton];
        CGRect imageViewFrame = [self cyl_convertFrameOfView:imageView];

        BOOL isTabBarButtonFrame = CGRectContainsPoint(selectedTabBarButtonFrame, point) || CGRectContainsPoint(imageViewFrame, point);
        if (isTabBarButtonFrame && !selectedTabBarButton.cyl_canNotResponseEvent) {
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

// 识别ContinuousSelection手势，需要代理长按等其他，处理PlusButton事件响应优先级为最优。
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (![CYLConstants isLiquidGlassActive] || ![self isKindOfClass:[CYLTabBar class]]) {
        [super addGestureRecognizer:gestureRecognizer];
        return;
    }
    if ([gestureRecognizer cyl_isContinuousGestureRecognizer]) {
        self.liquidGlassContinuousGestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [gestureRecognizer addTarget:self action:@selector(cyl_liquidGlassGestureRecognizerDidUpdate:)];
    }
    if ([gestureRecognizer cyl_isLongGestureRecognizer]) {
        self.liquidGlassLongGestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [gestureRecognizer addTarget:self action:@selector(cyl_liquidGlassGestureRecognizerDidUpdate:)];
    }
    [super addGestureRecognizer:gestureRecognizer];
}

/*!
 * FIX: issue #653 — plus button hidden while pressing or dragging in the iOS 27.1 vertical bar.
 * [EN] While a tab is pressed or dragged, UIKit shows a lifted copy of the tab platter in a portal view. With a
 *      horizontal tab bar that portal is added to this tab bar, below the plus button. In the vertical bar it is added
 *      to the tab bar controller's container view, above the branch that holds this tab bar, so it covered the plus
 *      button (only the plus cover in the selected layer stayed visible). Keep such portal views just below that branch.
 * [CN] 按住或拖拽 Tab 时，系统用 portal 视图显示抬起的 platter 副本。横向时该 portal 加在本 TabBar 上、位于加号按钮之下；
 *      竖向栏中它被加到 TabBarController 的容器视图上，位于本 TabBar 所在分支之上，遮住了加号按钮（只剩选中图层里的加号遮罩）。
 *      这里把这类 portal 视图移到该分支下方。
 */
- (void)cyl_liquidGlassGestureRecognizerDidUpdate:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan && gestureRecognizer.state != UIGestureRecognizerStateChanged) {
        return;
    }
    if (![self cyl_keepPlusButtonAbovePortalViewsInVerticalBar] || gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    // The portal is added by the lift animation, slightly after the gesture begins, and a finger held still sends no
    // further updates: keep checking while the gesture is active. 抬起动画稍后才添加 portal，手指不动时没有后续回调，因此手势进行中持续检查。
    [self cyl_keepPlusButtonAbovePortalViewsWhileGestureIsActive:gestureRecognizer];
}

- (void)cyl_keepPlusButtonAbovePortalViewsWhileGestureIsActive:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(self) weakSelf = self;
    __weak UIGestureRecognizer *weakGestureRecognizer = gestureRecognizer;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        UIGestureRecognizer *strongGestureRecognizer = weakGestureRecognizer;
        if (!strongSelf || !strongGestureRecognizer) {
            return;
        }
        [strongSelf cyl_keepPlusButtonAbovePortalViewsInVerticalBar];
        UIGestureRecognizerState state = strongGestureRecognizer.state;
        if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
            [strongSelf cyl_keepPlusButtonAbovePortalViewsWhileGestureIsActive:strongGestureRecognizer];
        }
    });
}

/// Returns NO when there is nothing to do (no plus button, or the tab buttons are not in the vertical bar).
- (BOOL)cyl_keepPlusButtonAbovePortalViewsInVerticalBar {
    if (!self.plusButton.superview || ![self cyl_verticalBarTabButtonAtIndex:0]) {
        return NO;
    }
    UIView *rootView = self.tabBarController.viewIfLoaded;
    for (UIView *child = self, *parent = self.superview; parent; child = parent, parent = parent.superview) {
        for (UIView *sibling in [parent.subviews copy]) {
            NSUInteger childIndex = [parent.subviews indexOfObject:child];
            NSUInteger siblingIndex = [parent.subviews indexOfObject:sibling];
            if (siblingIndex != NSNotFound && childIndex != NSNotFound && siblingIndex > childIndex && [sibling cyl_isPlatterPortalView]) {
                [parent insertSubview:sibling belowSubview:child];
            }
        }
        if (parent == rootView || parent == self.window) {
            break;
        }
    }
    return YES;
}

/*!
 * FIX: issue #653 — plus button does not respond in the iOS 27.1 vertical bar.
 * [EN] With a horizontal tab bar, UIKit's hit test reaches the plus button (via `-hitTest:withEvent:` above), so the
 *      touch goes to it and its `UIControlEventTouchUpInside` actions run. In the vertical bar this tab bar's container
 *      (`_UIBottomTabBarGroupView`) is 0 pt tall, so UIKit's hit test never reaches the plus button: the touch goes to
 *      the placeholder tab in the vertical bar and the plus button's actions (e.g. the demo's `-clickPublish`) never run.
 *      When that happens, send them here. Several gesture recognizers can ask during the same touch; the calls are
 *      coalesced to one per run loop turn.
 * [CN] 横向时系统 hitTest 能命中加号按钮（见上方 `-hitTest:withEvent:`），触摸交给加号按钮，触发其 TouchUpInside 事件。
 *      竖向栏中本 TabBar 所在容器 `_UIBottomTabBarGroupView` 高度为 0，系统 hitTest 命中不了加号按钮，触摸落到竖向栏的占位 Tab 上，
 *      加号按钮的点击事件（如 Demo 中的 `-clickPublish`）不会执行，这里补发。同一次触摸可能有多个手势询问，同一 run loop 内只发送一次。
 */
- (void)cyl_sendPlusButtonActionsIfUnreachableForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    CYLPlusButton *plusButton = CYLExternPlusButton;
    UIWindow *window = self.window;
    if (!plusButton || !window || !plusButton.enabled || !plusButton.userInteractionEnabled || plusButton.hidden) {
        return;
    }
    UIView *systemHitView = [window hitTest:[gestureRecognizer locationInView:window] withEvent:nil];
    if ([systemHitView isDescendantOfView:plusButton]) {
        return; // UIKit delivers the touch to the plus button itself. 系统会把触摸交给加号按钮，无需补发。
    }
    static BOOL isSendPending = NO;
    if (isSendPending) {
        return;
    }
    isSendPending = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        isSendPending = NO;
        [plusButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
}

- (CYLTabBarController *)tabBarController {
    CYLTabBarController *tabBarController = self.cyl_tabBarController;
    if (self.delegate && [self.delegate isKindOfClass:[CYLTabBarController class]]) {
        tabBarController = (CYLTabBarController *)self.delegate;
    }
    return tabBarController;
}

//处理PlusButton事件响应优先级为最优。

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (![CYLConstants isLiquidGlassActive] || ![self isKindOfClass:[CYLTabBar class]]) {
        return YES;
    }
    CGPoint location = [gestureRecognizer locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:nil];
    if (!hitView) {
        // FIX: issue #653 — in the iOS 27.1 vertical bar the tab buttons are outside this tab bar, so the hit test
        // above finds nothing and a tap on the already selected tab never reached `-tabChangedToControl:`
        // (no `tabBarController:didSelectControl:` callback). Look the tab button up under the touch instead.
        // 竖向栏中 Tab 按钮不在本 TabBar 内，上面的 hitTest 为 nil，导致选中状态下再次点击不回调 didSelectControl，这里按触摸点查找 Tab 按钮。
        hitView = [self cyl_verticalBarTabButtonAtWindowPoint:[gestureRecognizer locationInView:nil]];
    }
    SEL actin = @selector(tabChangedToControl:);
    CYLTabBarController *tabBarController = [self tabBarController];
    if ([self cyl_shouldUpdateHiddenStatueForPlusButtonLabel] && [hitView isKindOfClass:[CYLPlusButton class]] && [tabBarController.selectedViewController isEqual:CYLPlusChildViewController]) {
        //如果在选中CYLPlusChildViewController的状态下，  重复点击，或者滑动手势，又选中CYLPlusChildViewController。 相当于重复点击CYLPlusChildViewController， 则不显示未选中状态的Label， 仅仅在切换到其他tab的情况下， 显示未选中状态的Label。 否则会出现Label重叠的情况。
        //TODO:   选中center按钮 长按玻璃遮罩 向左或者向右 稍微移动一点距离 回到原位center 按钮标题 会变模糊. 由于无法解决， 故暂时禁止在选中PlusVC时的 用户滑动手势。等未来找到合适方案再处理.
//        [CYLExternPlusButton setTabLabelHidden:NO];
        if (!CYLExternPlusButton.cyl_keepShowingPlusButtonLabel) {
            return NO;
        }
    }
    if (([hitView cyl_isTabButton] || [hitView isKindOfClass:[CYLPlusButton class]] ) && [tabBarController respondsToSelector:actin]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         UIControl *control = (UIControl *)hitView;
         if (control.selected) {
             //FIX: iOS26 无法追加点击事件， 导致无法在选中状态下， 二次点击回调, 被系统手势拦截需要禁用特定手势，因为手势优先级高于 ControlEvents;
             [tabBarController performSelector:actin withObject:control];
         }
         )
    }
    
    if ([hitView isKindOfClass:[CYLPlusButton class]] && !CYLPlusChildViewController) {
        // 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
        // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
        if (!CYLExternPlusButton.cyl_userInteractionDisabled) {
            if ([tabBarController respondsToSelector:actin]) {
                CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
                (
                 [tabBarController performSelector:actin withObject:CYLExternPlusButton];
                 
                 )
            }
        }
        [self cyl_sendPlusButtonActionsIfUnreachableForGestureRecognizer:gestureRecognizer];
        return NO;
    }
    
    return YES;
}

@end

