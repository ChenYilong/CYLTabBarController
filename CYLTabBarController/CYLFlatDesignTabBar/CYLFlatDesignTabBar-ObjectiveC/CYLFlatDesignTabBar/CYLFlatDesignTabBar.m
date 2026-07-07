//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBar.h"
#import "CYLFlatDesignTabBarItem.h"
#import "CYLTabBarController.h"
//#import "CYLFlatDesignUIViewController.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/UIControl+CYLTabBarControllerExtention.h>
#else
#import "CYLTabBarController.h"
#import "UIControl+CYLTabBarControllerExtention.h"

#endif
#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"

@interface CYLFlatDesignTabBar ()

// _UIBackground
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIVisualEffectView *backgroundEffectView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *shadowImageView;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, weak, readonly, nullable) UITabBarController *tabBarController;
/*!
 * @property (nonatomic, weak, readonly, nullable) CYLFlatDesignUIViewController *customTabBarController;

 */
@property (nonatomic, weak) UIButton<CYLPlusButtonSubclassing> *plusButton;

@end

@implementation CYLFlatDesignTabBar {
    NSInteger _selectedItemIndex;
    NSMutableArray *_buttons;
}
//@synthesize context = _context;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 引入CYLFlatDesignTabBar，即表示同意 hook push行为
        [UINavigationController cyl_navigationBarActionHook];
        [self commonInit];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabBarItemDidChange:) name:CYLFlatDesignTabBarItemDidChange object:nil];
        __weak __typeof(self) weakSelf = self;
        void (^CYLTabBarItemLottieAnimationPlayingNotificationBlock)(NSNotification *) = ^(NSNotification *notification) {
            __strong typeof(self) self = weakSelf;
            if (!self) {
                 return;
            }
            [self stopAnimationOfAllLottieView];
        };
        [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemLottieAnimationPlayingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:CYLTabBarItemLottieAnimationPlayingNotificationBlock];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    
    CGFloat height = self.contentView.frame.size.height;
    if (height > 0) {
        sizeThatFits.height = height;
    }
    return sizeThatFits;
}

- (void)dealloc {
    @try {
        //iOS9之后， 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
}

- (void)_tabBarItemDidChange:(NSNotification *)note {
    if (_items == nil || _items.count == 0) { return; }
    CYLFlatDesignTabBarItem *changedItem = [note object];
    NSInteger itemIndex = [_items indexOfObject:changedItem];
    if (itemIndex != NSNotFound) {
        CYLFlatDesignTabBarButton *tabBarButton = _buttons[itemIndex];
        tabBarButton.tabBarItem = changedItem;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateLayout];
}

- (void)commonInit {
    _selectedItemIndex = -1;
    _buttons = [NSMutableArray array];
    
    _backgroundView = [[UIView alloc] init];
    _backgroundView.clipsToBounds = NO;

    [self addSubview:_backgroundView];
    
    _backgroundImageView = [[UIImageView alloc] init];
    _backgroundView.clipsToBounds = NO;

    [_backgroundView addSubview:_backgroundImageView];
    
    _contentView = [[UIView alloc] init];
    _contentView.clipsToBounds = NO;
    [self addSubview:_contentView];
    
    self.barTintColor = [UIColor clearColor];
    self.tintColor = [UIColor systemBlueColor];
    _useLayoutSafeAreaInsets = NO;
}

#pragma mark - Setter & Getter

- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue {
    return [[CYLFlatDesignTabBarItem alloc] initWithTitle:title
                                                    image:tabBarItemImage
                                            selectedImage:tabBarItemSelectedImage
                                                    index:index
                                  titlePositionAdjustment:titlePositionAdjustment
                                  imagePositionAdjustment:UIOffsetZero
                                              imageInsets:imageInsets
                                           lottieFilePath:lottieFilePath
                                          lottieSizeValue:lottieSizeValue];
    
     
}

- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarButtons {
    return [_buttons copy];
}

- (void)setDelegate:(id<CYLFlatDesignTabBarDelegate>)delegate {
    if (_delegate != delegate) {
        if (_delegate) {
            // 系统 UITabBarController 也是不允许修改的
            //FIXME:  to delete cylflatdesign_tabBarController
            /*!
             *             if (self.tabBarController || self.customTabBarController) {
            #if defined(DEBUG) || defined(BETA)
                            NSAssert(NO, @"不允许更改由 tabBarController 管理的 tabBar 的代理");
            #endif
                            return;
                        }

             */
            if (self.tabBarController) {
#if defined(DEBUG) || defined(BETA)
                NSAssert(NO, @"不允许更改由 tabBarController 管理的 tabBar 的代理");
#endif
                return;
            }

        }
        _delegate = delegate;
    }
}

- (void)setItems:(NSArray<CYLFlatDesignTabBarItem *> *)items {
    if (![_items isEqualToArray:items]) {
        if (self.selectedItem && ![items containsObject:self.selectedItem]) {
            _selectedItemIndex = -1;
        }
        _items = [items copy];
        [self _reloadItems];
    }
}

- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarItems {
    return self.tabBarButtons;
}

- (void)setTabBarItems:(NSArray<CYLFlatDesignTabBarItem *> *)tabBarItems {
    [self setItems:tabBarItems];
}

- (void)setSelectedItem:(CYLFlatDesignTabBarItem *)selectedItem {
    if (selectedItem) {
        NSInteger index = [self.items indexOfObject:selectedItem];
        if (index != NSNotFound && _selectedItemIndex != index) {
            [self _setSelectedIndex:index];
        }
    } else {
        if (self.selectedItem) {
            CYLFlatDesignTabBarButton *selectedButton = _buttons[_selectedItemIndex];
//            selectedButton.tabBarItem = selectedItem;
            selectedButton.selected = NO;
            _selectedItemIndex = -1;
        }
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [self _setSelectedIndex:selectedIndex];
}

- (CYLFlatDesignTabBarItem *)selectedItem {
    if (_selectedItemIndex >= 0 && _selectedItemIndex < _items.count) {
        return [_items objectAtIndex:_selectedItemIndex];
    }
    return nil;
}

- (void)setTintColor:(UIColor *)tintColor {
    if (_tintColor != tintColor) {
        _tintColor = tintColor;
        for (CYLFlatDesignTabBarButton *button in _buttons) {
            button.tintColor = tintColor;
        }
    }
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (_barTintColor != barTintColor) {
        _barTintColor = barTintColor;
        _backgroundImageView.image = _backgroundImage;
        if (_backgroundImage) {
            if (_backgroundEffectView) {
                [_backgroundEffectView removeFromSuperview];
                _backgroundEffectView = nil;
            }
            _backgroundImageView.backgroundColor = [UIColor clearColor];
        } else {
            _backgroundImageView.backgroundColor = self.barTintColor;
            if (!_backgroundEffectView) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
                _backgroundEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            }
            [_backgroundView insertSubview:_backgroundEffectView atIndex:0];
        }
        [self setNeedsLayout];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {

    if (_backgroundImage != backgroundImage) {
        _backgroundImage = backgroundImage;
        _backgroundImageView.image = backgroundImage;
        if (backgroundImage) {
            if (_backgroundEffectView) {
                [_backgroundEffectView removeFromSuperview];
                _backgroundEffectView = nil;
            }
            _backgroundImageView.backgroundColor = [UIColor clearColor];
        } else {
            _backgroundImageView.backgroundColor = self.barTintColor;
            if (!_backgroundEffectView) {
                UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
                _backgroundEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            }
            [_backgroundView insertSubview:_backgroundEffectView atIndex:0];
        }
        [self setNeedsLayout];
    }
}

- (void)setShadowImage:(UIImage *)shadowImage {
    if (_shadowImage != shadowImage) {
        _shadowImage = shadowImage;
        if (shadowImage) {
            if (!_shadowImageView) {
                _shadowImageView = [[UIImageView alloc] init];
            }
            _shadowImageView.image = shadowImage;
            [_backgroundView addSubview:_shadowImageView];
        } else {
            if (_shadowImageView) {
                [_shadowImageView removeFromSuperview];
                _shadowImageView = nil;
            }
        }
        [self setNeedsLayout];
    }
}

- (void)setUseLayoutSafeAreaInsets:(BOOL)useLayoutSafeAreaInsets {
    if (_useLayoutSafeAreaInsets != useLayoutSafeAreaInsets) {
        _useLayoutSafeAreaInsets = useLayoutSafeAreaInsets;
        [self setNeedsLayout];
    }
}

- (void)setContext:(NSString *)context {
    _context = context;
    self.cyl_context = context;
}

#pragma mark - Private

- (void)_tabBarDidSelectButton:(CYLFlatDesignTabBarButton *)tabBarButton {
    NSInteger selectedIndex = [_buttons indexOfObject:tabBarButton];
    CYLFlatDesignTabBarItem *item = self.items[selectedIndex];
    //    tabBarButton.tabBarItem = item;
    
    if (!item.isEnabled) { return; }
    
    if ([self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
        [self.delegate tabBar:self didSelectItem:item];
    }
    
    //FIXME:  to delete cylflatdesign_tabBarController
    NSString *clickSelectorFromString = [NSString stringWithFormat:@"%@BarItem%@", @"_tab", @"Clicked"];
    
    if (self.tabBarController) {
        // 系统方法
        SEL sel = NSSelectorFromString(clickSelectorFromString);
        if ([self.tabBarController respondsToSelector:sel]) {
            //FIXME:  to delete cylflatdesign_tabBarController
            UITabBarItem *systemItem = self.tabBarController.tabBar.items[selectedIndex];
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             [self.tabBarController performSelector:sel withObject:systemItem];
             );
        } else {
            // 容错处理, 防止版本系统修改方法名称
            SEL customSEL = NSSelectorFromString(@"_cyltabBarItemClicked:");
            if ([self.tabBarController respondsToSelector:customSEL]) {
                CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
                (
                 [self.tabBarController performSelector:customSEL withObject:item];
                 );
            } else {
                [self _setSelectedIndex:selectedIndex];
            }
        }
    } else {
        [self _setSelectedIndex:selectedIndex];
    }
}

- (UITabBarController *)tabBarController {
    if ([self.delegate isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)self.delegate;
        return tabBarController;
    }
    return nil;
}

/*!
 * - (CYLFlatDesignUIViewController *)customTabBarController {
    if ([self.delegate isKindOfClass:[CYLFlatDesignUIViewController class]]) {
       return (CYLFlatDesignUIViewController *)self.delegate;
   }
   return nil;
}
 */

- (void)_reloadItems {
    // remove old
    for (CYLFlatDesignTabBarButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    // add tabBarButton
    for (NSInteger index = 0; index < self.items.count; index++) {
        CYLFlatDesignTabBarItem *item = self.items[index];
        CYLFlatDesignTabBarButton *button = [[CYLFlatDesignTabBarButton alloc] initWithTabBarItem:item];
        //FIXME:  to delete ， 二选一， weak。
//        item.tabBarButton = button;
//        [button setTabBarItem:item];
        button.tintColor = self.tintColor;
        button.selected = (item == self.selectedItem);
        [button addTarget:self action:@selector(_tabBarDidSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        //TODO:  对齐方案， 最简单。 移除PlusButton对应的item， 重新从 self.contentView 插入对齐。
        button.clipsToBounds = NO;
        [self.contentView insertSubview:button atIndex:0];
        [_buttons addObject:button];
    }
    [self setNeedsLayout];
}

- (void)_setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedItemIndex != selectedIndex) {
        //统一使用CYLTabBarItemLottieAnimationPlayingNotification进行动画重置， 故删除手动重置。
//         [self stopAnimationOfAllLottieView];
//        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
        _selectedItemIndex = selectedIndex;
        for (NSInteger i = 0; i < _buttons.count; i++) {
            CYLFlatDesignTabBarButton *tabBarButton = _buttons[i];
            tabBarButton.selected = (i == selectedIndex);
        }
    }
}

- (void)_updateLayout {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    // background
    _backgroundView.frame = self.bounds;
    
    _backgroundImageView.frame = _backgroundView.bounds;
    if (_backgroundEffectView) {
        _backgroundEffectView.frame = _backgroundView.bounds;
    }
    
    if (_shadowImageView) {
        CGFloat shadowImageHeight = 1.0 / UIScreen.mainScreen.scale;
        _shadowImageView.frame = CGRectMake(0, -shadowImageHeight, CGRectGetWidth(_backgroundView.frame), shadowImageHeight);
    }
    
    // 放在UITabBarController里
    CGFloat contentHeight = CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom;
//    if (self.useLayoutSafeAreaInsets) {
//        contentHeight = CGRectGetHeight(self.bounds);
//    }
    self.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), contentHeight);
    
    NSInteger itemCount = self.items.count;
    if (itemCount == 0) { return; }
    if (_buttons.count != itemCount) { return; }

    CGFloat contentWidth = CGRectGetWidth(self.contentView.frame);
    if (self.useLayoutSafeAreaInsets) {
        contentWidth -= (self.safeAreaInsets.left + self.safeAreaInsets.right);
    }
    
//    系统间距
//    CGFloat margin = 2.0;
//    CGFloat buttonSpace = 4.0;
//    CGFloat buttonY = 1.0;
    
    CGFloat margin = 0.0;
    CGFloat buttonSpace = 0.0;
    CGFloat buttonY = 0.0;
    CGFloat buttonWidth = 0;
    if (itemCount == 1) {
        buttonWidth = contentWidth - margin * 2;
    } else {
        buttonWidth = (contentWidth - margin * 2 - (itemCount - 1) * buttonSpace) / itemCount;
    }
    CGFloat buttonHeight = CGRectGetHeight(self.contentView.frame) - buttonY;

    for (NSInteger i = 0; i < self.items.count; i++) {
        CYLFlatDesignTabBarButton *button = _buttons[i];
        //        button.tabBarItem = self.items[i];
        [button setTabBarItem:self.items[i]];
        
        CGFloat buttonX = margin + i * (buttonWidth + buttonSpace);
        if (self.useLayoutSafeAreaInsets) {
            buttonX += self.safeAreaInsets.left;
        }
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
    }
    if ([self hasPlusButton]) {
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = (CYLPlusButton<CYLPlusButtonSubclassing> *)CYLExternPlusButton;
        CGFloat tabBarHeight = self.contentView.frame.size.height;
        CGFloat tabBarWidth = self.contentView.frame.size.width;
        CGFloat multiplierOfTabBarHeight = [plusButton multiplierOfTabBarHeight:tabBarHeight];
        CGFloat constantOfPlusButtonCenterYOffset = [plusButton constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
        plusButton.layer.contentsGravity = kCAGravityCenter;

        if (@available(iOS 13.0, *)) {
            plusButton.layer.contentsScale = CYLGetRootWindow().windowScene.screen.scale;
        }
        
//        plusButton.clipsToBounds = NO;
//        [self.contentView cyl_bringSubviewToTop:plusButton];
        self.plusButton = plusButton;
        //FIXME:  to delete 自定义的index。
//        [self cyl_replace];(
        CYLFlatDesignTabBarButton *plusButtonIndexPlaceholder = _buttons[CYLPlusButtonIndex];
        if (![plusButtonIndexPlaceholder.tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
            return;
        }
        __weak __typeof(self) weakSelf = self;
        /*!
                                               *
                                                      if multiplierOfTabBarHeight * TabBarHeight + constantOfPlusButtonCenterYOffset == 0.5 * TabBarHeight + plusButtonoffsetY;
                                                      plusButtonoffsetY = fabsf(multiplierOfTabBarHeight -0.5) * tabBarHeight + constantOfPlusButtonCenterYOffset
                                                      CGFloat plusButtonoffsetY = multiplierOfTabBarHeight * TabBarHeight
                                               */
        UIOffset plusButtonoffset =  UIOffsetMake(0, constantOfPlusButtonCenterYOffset);
        self.plusButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [plusButtonIndexPlaceholder cyl_coverVisiableTabImageViewOrTabButton:YES
                                                        contentNewView:self.plusButton
                                                 seclectContentNewView:self.plusButton
                                                                offset:plusButtonoffset
                                                                  show:YES
                                               delayIfNeededForSeconds:0.1
                                                            completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull newView) {
               __strong typeof(self) self = weakSelf;
               if (!self) {
                   return;
               }
            [newView layoutIfNeeded];
            [tabBarButton cyl_setIsPlaceholder:YES];

//            [tabBarButton cyl_bringSubviewToTop:newView];
//            tabBarButton.userInteractionEnabled = NO;
//               if (isReplaced && show && newView) {
//                   [self.viewControllers[0] cyl_clearBadge];
//       //            [tabBarButton.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//       //                if (![obj isKindOfClass:[newView class]]) {
//       //                    [obj cyl_setHidden:show];
//       //                }
//       //            }];
//       //            [tabBarButton insertSubview:tabBarButton.cyl_lottieAnimationView belowSubview:selectedTabButton];
//       //            [tabBarButton bringSubviewToFront:newView];
//                   [tabBarButton cyl_bringSubviewToTop:newView];
//                   if (![CYLConstants isLiquidGlassActive]) {
//                       // LiquidGlass 已经自带缩放动画， 无需缩放
//                       [self addOnceScaleAnimationOnView:newView];
//                   }
//               }
        }];
        
//        self.plusButton.center = CGPointMake(tabBarWidth * 0.5, tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset);
    }
}

//- (UIButton *)selectedCover {
////    if (_selectedCover) {
////        return _selectedCover;
////    }
//    UIButton *selectedCover = [UIButton buttonWithType:UIButtonTypeCustom];
//    
//    UIImage *image = [UIImage imageNamed:@"home_select_cover"];
//    [selectedCover setImage:image forState:UIControlStateNormal];
//    selectedCover.frame = ({
//        CGRect frame = selectedCover.frame;
//        frame.size = CGSizeMake(image.size.width, image.size.height);
//        frame;
//    });
//    selectedCover.contentMode = UIViewContentModeCenter;
//    selectedCover.imageView.contentMode = UIViewContentModeScaleAspectFit;
//
//    selectedCover.translatesAutoresizingMaskIntoConstraints = NO;
//    // selectedCover.userInteractionEnabled = false;
////    _selectedCover = selectedCover;
//    return selectedCover;
//}

- (void)stopAnimationOfAllLottieView {
#if __has_include(<Lottie/Lottie.h>)
    if ([self isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLFlatDesignTabBar *flatDesignTabBar = (CYLFlatDesignTabBar *)self;
        [flatDesignTabBar.tabBarItems enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cyl_stopAnimationOfLottieView];
        }];
        
    }
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
    if ([self isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLFlatDesignTabBar *flatDesignTabBar = (CYLFlatDesignTabBar *)self;
        [flatDesignTabBar.tabBarItems enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
            [obj cyl_stopAnimationOfLottieView];
#else
            [obj cyl_stopAnimationOfLottieView];
#endif
        }];
        
    }
#endif

}

#pragma mark - plusFrame and tabBarItemFrameWithIndex
/*!
 *

 *  Capturing touches on a subview outside the frame of its superview.
 
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
 */
// 如果imageView超出TabBar范围，增加imageView响应区域
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
        //与CYLTabBar实现有区别，plusButton在 CYLTabBar是直接加在根视图， 而扁平风格，则是在子视图里， 所以需要坐标系转换到根视图。
        CGRect plusButtonFrameToSuperview = [self.plusButton convertRect:plusButtonFrame toView:self];

        BOOL isInPlusButtonFrame = CGRectContainsPoint(plusButtonFrameToSuperview, point);
        if (isInPlusButtonFrame && ![self hasPlusChildViewController] ) {
            return self.plusButton;
        }
        BOOL isInPlusButtonSuperFrame = CGRectContainsPoint(self.plusButton.superview.frame, point);
        if (isInPlusButtonSuperFrame && self.plusButton.superview.cyl_isPlaceholder && self.plusButton.superview.cyl_canNotResponseEvent && !self.plusButton.cyl_canNotResponseEvent) {
            //防止误触PlusButton轮廓外， 且在tabBarButton范围内。否则， 会切换到PlusButton 对应的空白placeholder vc上。
            return self.plusButton;
        }
    }
    for (CYLFlatDesignTabBarButton *selectedTabBarButton in self.tabBarButtons) {
        CGRect imageRect = [selectedTabBarButton.actualBadgeSuperView convertRect:selectedTabBarButton.imageView.bounds toView:self];
        BOOL isTabBarButtonFrame = (CGRectContainsPoint(selectedTabBarButton.frame, point) || CGRectContainsPoint(imageRect, point));
        if (isTabBarButtonFrame && !selectedTabBarButton.cyl_canNotResponseEvent) {
            return selectedTabBarButton;
        }
        // 防止误触PlusButton轮廓外， 且在tabBarButton范围内。否则， 会切换到PlusButton 对应的空白placeholder vc上。已经在(self.plusButton)判断逻辑内处理， 这里无需重复处理。
        //        else if (selectedTabBarButton.cyl_isPlaceholder && (self.plusButton)) {
        //            return self.plusButton;
        //        }
    }
    
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

- (CGFloat)tabItemWidth {
    CYLTabBarItemWidth = (CYLScreenWidth() - CYLPlusButtonWidth) / CYLTabbarItemsCount;
    //        CYLTabBarItemWidth = (tabBarWidth) / CYLTabbarItemsCount;
    return CYLTabBarItemWidth;
}

- (CGFloat)plusWidth {
    return CYLPlusButtonWidth;
}

//- (CGRect)plusFrame {
//    return CGRectMake(CYLHalfOfDiff(CYLScreenWidth(), [self plusWidth]), 0, [self plusWidth], CYLTabBarHeight);
//}

- (CGRect)tabBarItemFrameWithIndex:(NSInteger)index {
    CGFloat w = [self tabItemWidth];
    CGFloat h = CYLTabBarHeight;
    CGFloat x = 0;
    if (index > 1) {
        x = CYLScreenWidth() - w - (3 - index) * (w + CYLScaleValue(2));
    } else {
        x = index * (w + CYLScaleValue(2));
    }
    CGFloat y = 0;
    
    return CGRectMake(x, y, w, h);
}

- (BOOL)hasPlusButton {
    BOOL isSameContext = [[CYLExternPlusButton class] hasPlusButtonForTabBarContext:self.cyl_context];//|| (!tabBarContext  && !self.context);
    return isSameContext;
}

- (BOOL)hasPlusChildViewController {
    BOOL hasPlusChildViewController = [[CYLExternPlusButton class] hasPlusChildViewControllerForTabBarContext:self.cyl_context];//|| (!tabBarContext  && !self.context);;//&& !isAdded;
    return hasPlusChildViewController;
}

@end
