//
//  CYLFlatDesignTabBarController.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "CYLFlatDesignTabBarController.h"
#import <objc/runtime.h>
#import "CYLFlatDesignTabBarItem.h"
#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
#import "_CYLFlatDesignTabBarParallaxOverlayView.h"

CGFloat const CYLFlatDesignTabBarControllerHideShowBarDuration = 0.2;

@interface CYLFlatDesignTabBarHideTabBar : UITabBar
@end

@implementation CYLFlatDesignTabBarHideTabBar
- (void)setHidden:(BOOL)hidden {
    hidden = YES;
    [super setHidden:hidden];
}
@end

@interface CYLFlatDesignTabBarController ()<UINavigationControllerExtensionDelegate>

@property (nonatomic, assign, readonly) CGRect tabBarFrame;
@property (nonatomic, strong, readonly) NSMutableArray<CYLFlatDesignTabBarItem *> *items;

@property (nonatomic, assign) BOOL cyl_tabBarHidden;

@end

@implementation CYLFlatDesignTabBarController {
    struct {
        unsigned willShowTabBar : 1;
        unsigned didShowTabBar : 1;
        unsigned willHideTabBar : 1;
        unsigned didHideTabBar : 1;
    } _delegateHas;
    
    BOOL _tabBarIsAnimating;
    // 用于记录快速设置tabBar显示和隐藏最后一次的状态
    BOOL _lastShowHideTabBar;
    BOOL _needsReloadItems;
    
    _CYLFlatDesignTabBarParallaxOverlayView *_parallaxOverlayView;
}

@dynamic delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 通过KVC 换成 CYLFlatDesignTabBarHideTabBar，控制其永久隐藏
    CYLFlatDesignTabBarHideTabBar *tabBar = [[CYLFlatDesignTabBarHideTabBar alloc] init];
    @try {
        [self setValue:tabBar forKey:@"tabBar"];
    } @catch (NSException *exception) {
        NSLog(@"%@ KVC异常：%@", NSStringFromClass(self.class), exception.reason);
    }
    
    // 添加自定义的 CYLFlatDesignTabBar
    _cyl_tabBarHidden = NO;
    _tabBarHeight = 49.0;
    _cyl_tabBar = [[CYLFlatDesignTabBar alloc] initWithFrame:self.tabBarFrame];
    _cyl_tabBar.delegate = self;
    [self.view addSubview:self.cyl_tabBar];
    
    [self addObserver:self forKeyPath:@"cyl_tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];

    [self setTabBarHidden:NO];
    [self _updateAdditionalSafeAreaInsets:NO animated:NO];
}

#pragma mark - Observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"cyl_tabBar"]) {
        CYLFlatDesignTabBar *oldTabBar = change[NSKeyValueChangeOldKey];
        [oldTabBar removeFromSuperview];
        
        CYLFlatDesignTabBar *newTabBar = change[NSKeyValueChangeNewKey];
        newTabBar.delegate = self;
        newTabBar.items = oldTabBar.items;
        newTabBar.selectedItem = oldTabBar.selectedItem;
        _cyl_tabBar = newTabBar;
        if (newTabBar) {
            [self.view addSubview:newTabBar];
            [self.view setNeedsLayout];
        }
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cyl_tabBar"];
}

#pragma mark - Overrides
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_tabBarIsAnimating && !CGRectEqualToRect(self.cyl_tabBar.frame, self.tabBarFrame) && self.cyl_tabBar.superview == self.view) {
        self.cyl_tabBar.frame = self.tabBarFrame;
    }
}

- (BOOL)isTabBarHidden {
    return _cyl_tabBarHidden;
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    // 隐藏系统 tabBar
    if (@available(iOS 18.0, *)) {
        [super setTabBarHidden:YES animated:animated];
    } else {
        self.tabBar.hidden = YES;
    }
    
    if (_tabBarIsAnimating) {
        _lastShowHideTabBar = hidden;
        return;
    }
    if (self.cyl_tabBar.superview != self.view) { return; }
    if (_cyl_tabBarHidden != hidden) {
        
        _cyl_tabBarHidden = hidden;
        _lastShowHideTabBar = hidden;
        
        if (self.cyl_tabBar.hidden == hidden) {
            return;
        }
        BOOL canShowsBottomBar = [self _checkHidesBottomBarWhenPushed];
        if (!canShowsBottomBar) {
            // 让 hidesBottomBarWhenPushed 优先级更高
            return;
        }
        
        if (animated) {
            _tabBarIsAnimating = YES;

            if (hidden) {
                if (_delegateHas.willHideTabBar) {
                    [self.delegate tabBarController:self willHideTabBar:self.cyl_tabBar];
                }
            } else {
                if (_delegateHas.willShowTabBar) {
                    [self.delegate tabBarController:self willShowTabBar:self.cyl_tabBar];
                }
            }
            
            CGAffineTransform startTransform = hidden? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, _cyl_tabBar.frame.size.height);
            CGAffineTransform endTransform = hidden? CGAffineTransformMakeTranslation(0, _cyl_tabBar.frame.size.height) : CGAffineTransformIdentity;
            _cyl_tabBar.transform = startTransform;
            _cyl_tabBar.hidden = NO;
            
            [UIView animateWithDuration:CYLFlatDesignTabBarControllerHideShowBarDuration animations:^{
                self.cyl_tabBar.transform = endTransform;
            } completion:^(BOOL finished) {
                self.cyl_tabBar.transform = CGAffineTransformIdentity;
                self.cyl_tabBar.hidden = hidden;
                [self _updateAdditionalSafeAreaInsets:NO animated:animated];
                self->_tabBarIsAnimating = NO;
                
                if (hidden) {
                    if (self->_delegateHas.didHideTabBar) {
                        [self.delegate tabBarController:self didHideTabBar:self.cyl_tabBar];
                    }
                } else {
                    if (self->_delegateHas.didShowTabBar) {
                        [self.delegate tabBarController:self didShowTabBar:self.cyl_tabBar];
                    }
                }
                
                if (self->_lastShowHideTabBar != hidden) {
                    // 动画结束，如果和最后一次设置显隐状态不一致，使其显示正确的状态，主要解决快速设置bug（两次设置时间间隔<0.2s）
                    [self setTabBarHidden:self->_lastShowHideTabBar animated:animated];
                }
            }];
        } else {
            if (hidden) {
                if (_delegateHas.willHideTabBar) {
                    [self.delegate tabBarController:self willHideTabBar:self.cyl_tabBar];
                }
            } else {
                if (_delegateHas.willShowTabBar) {
                    [self.delegate tabBarController:self willShowTabBar:self.cyl_tabBar];
                }
            }
            
            _cyl_tabBar.hidden = hidden;
            [self _updateAdditionalSafeAreaInsets:NO animated:animated];
            
            if (hidden) {
                if (_delegateHas.didHideTabBar) {
                    [self.delegate tabBarController:self didHideTabBar:self.cyl_tabBar];
                }
            } else {
                if (_delegateHas.didShowTabBar) {
                    [self.delegate tabBarController:self didShowTabBar:self.cyl_tabBar];
                }
            }
        }
    }
}

- (BOOL)_checkHidesBottomBarWhenPushed {
    BOOL showsTabBar = YES;
    UIViewController *selectedViewController = self.selectedViewController;
    if ([selectedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)selectedViewController;
        NSInteger currentIndex = [navigationController.viewControllers indexOfObject:navigationController.topViewController];
        NSInteger showsBottomBarIndex = -1;
        for (NSInteger index = 0; index < navigationController.viewControllers.count; index++) {
            UIViewController *viewController = navigationController.viewControllers[index];
            if (viewController.hidesBottomBarWhenPushed) {
                showsBottomBarIndex = index - 1;
                break;
            } else {
                showsBottomBarIndex = index;
            }
        }
        if (currentIndex <= showsBottomBarIndex) {
            showsTabBar = YES;
        } else {
            showsTabBar = NO;
        }
    } else if ([selectedViewController isKindOfClass:[UIViewController class]]) {
        showsTabBar = !selectedViewController.hidesBottomBarWhenPushed;
    }    return showsTabBar;
}

- (void)setDelegate:(id<CYLFlatDesignTabBarControllerDelegate>)delegate {
    [super setDelegate:delegate];
    _delegateHas.willShowTabBar = [delegate respondsToSelector:@selector(tabBarController:willShowTabBar:)];
    _delegateHas.didShowTabBar = [delegate respondsToSelector:@selector(tabBarController:didShowTabBar:)];
    _delegateHas.willHideTabBar = [delegate respondsToSelector:@selector(tabBarController:willHideTabBar:)];
    _delegateHas.didHideTabBar = [delegate respondsToSelector:@selector(tabBarController:didHideTabBar:)];
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    _needsReloadItems = YES;
    [super setViewControllers:viewControllers];
    if (_needsReloadItems) {
        [self _captureItems];
        [self.cyl_tabBar setItems:_items];
        _needsReloadItems = NO;
    }
    self.cyl_tabBar.selectedItem = self.selectedViewController.cyl_tabBarItem;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (self.selectedIndex != selectedIndex) {
        [super setSelectedIndex:selectedIndex];
        if (_needsReloadItems) {
            [self _captureItems];
            [self.cyl_tabBar setItems:_items];
            _needsReloadItems = NO;
        }
        self.cyl_tabBar.selectedItem = self.selectedViewController.cyl_tabBarItem;
        [self _updateBottomBarShowHideIfNeeded];
    }
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    if (self.selectedViewController != selectedViewController) {
        [super setSelectedViewController:selectedViewController];
        self.cyl_tabBar.selectedItem = selectedViewController.cyl_tabBarItem;
        [self _updateBottomBarShowHideIfNeeded];
    }
}

/// 状态栏
- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.selectedViewController.preferredStatusBarUpdateAnimation;
}

/// HomeIndicator
- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    return self.selectedViewController;
}

/// 控制器支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.selectedViewController.supportedInterfaceOrientations;
}

#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (!CGSizeEqualToSize(self.view.bounds.size, size)) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self _updateAdditionalSafeAreaInsets:NO animated:NO];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
        }];
    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Setter
- (void)setTabBarHeight:(CGFloat)tabBarHeight {
    if (_tabBarHeight != tabBarHeight) {
        _tabBarHeight = tabBarHeight;
        [self _updateAdditionalSafeAreaInsets:NO animated:NO];
        [self.view setNeedsLayout];
    }
}

#pragma mark - TabBarItem Action

- (void)_qqtabBarItemClicked:(CYLFlatDesignTabBarItem *)tabBarItem {
    NSInteger index = [self.cyl_tabBar.items indexOfObject:tabBarItem];
    if ([self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        BOOL sholudSelect = [self.delegate tabBarController:self shouldSelectViewController:self.viewControllers[index]];
        if (!sholudSelect) {
            return;
        }
    }
    
    self.selectedIndex = index;
    
    if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [self.delegate tabBarController:self didSelectViewController:self.viewControllers[index]];
    }
}

#pragma mark - UINavigationControllerExtensionDelegate
- (void)cyl_navigationController:(UINavigationController *)navigationController
   navigationBarDidChangeHeight:(CGFloat)height {
    
}

- (void)cyl_navigationController:(UINavigationController *)navigationController
         didBeginTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation {
    // 转场或pop手势返回时禁止用户交互
    self.view.userInteractionEnabled = NO;
    UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = self.tabBarHeight;
    [UIView performWithoutAnimation:^{
        self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        if (self.moreNavigationController && self.moreNavigationController != self.selectedViewController) {
            self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }
    }];
}

- (void)cyl_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                percentComplete:(CGFloat)percentComplete {
//     NSLog(@"pop手势返回：%.2f", percentComplete);
}


- (void)cyl_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
           popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer {
    
}

- (void)cyl_navigationController:(UINavigationController *)navigationController
          willEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled {
    BOOL showsTabBar = [self _shouldShowsBottomBar];
    if (operation == UINavigationControllerOperationPush) {
        if (!showsTabBar && !self.cyl_tabBar.hidden) {
            [self _addParallaxOverlayViewToViewController:fromVC];
        }
    } else {
        if (showsTabBar && self.cyl_tabBar.hidden) {
            [self _addParallaxOverlayViewToViewController:toVC];
        }
    }
    
    UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = showsTabBar ? self.tabBarHeight : 0;
    [UIView performWithoutAnimation:^{
        self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        if (self.moreNavigationController && self.moreNavigationController != self.selectedViewController) {
            self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }
    }];
}

- (void)cyl_navigationController:(UINavigationController *)navigationController
           didEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled {
    self.view.userInteractionEnabled = YES;
    if (_parallaxOverlayView) {
        [_parallaxOverlayView removeFromSuperview];
        _parallaxOverlayView = nil;
    }
    
    if (self.cyl_tabBar.superview != self.view) {
        self.cyl_tabBar.frame = self.tabBarFrame;
        [self.view addSubview:self.cyl_tabBar];
    }
    
    [self _updateBottomBarShowHideIfNeeded];
}

#pragma mark - Private
- (CGRect)tabBarFrame {
    CGFloat tabBarHeight = _tabBarHeight + self.view.safeAreaInsets.bottom;
    return CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
}

- (void)_captureItems {
    BOOL hasMoreItem = NO;
    if (self.moreNavigationController) {
        hasMoreItem = [self.tabBar.items containsObject:self.moreNavigationController.tabBarItem];
    }
    NSMutableArray *items = [NSMutableArray array];
    if (hasMoreItem) {
        for (NSInteger i = 0; i < self.tabBar.items.count - 1; i++) {
            UIViewController *viewController = self.viewControllers[i];
            [items addObject:viewController.cyl_tabBarItem];
        }
        CYLFlatDesignTabBarItem *moreItem = self.moreNavigationController.cyl_tabBarItem;
        UITabBarItem *systemMoreItem = self.moreNavigationController.tabBarItem;
        if (moreItem.title.length == 0 && systemMoreItem.title.length < 0) {
            moreItem.title = systemMoreItem.title;
        }
        if (!moreItem.image && systemMoreItem.image) {
            moreItem.image = systemMoreItem.image;
        }
        if (!moreItem.selectedImage && systemMoreItem.selectedImage) {
            moreItem.selectedImage = systemMoreItem.selectedImage;
        }
        [items addObject:moreItem];
    } else {
        for (UIViewController *viewController in self.viewControllers) {
            [items addObject:viewController.cyl_tabBarItem];
        }
    }
    [self _syncSystemItems];
    _items = items;
}

- (void)_syncSystemItems {
    for (UIViewController *viewController in self.viewControllers) {
        viewController.tabBarItem.title = viewController.cyl_tabBarItem.title;
        viewController.tabBarItem.image = viewController.cyl_tabBarItem.image;
        viewController.tabBarItem.badgeValue = viewController.cyl_tabBarItem.badgeValue;
        viewController.tabBarItem.badgeColor = viewController.cyl_tabBarItem.badgeColor;
        viewController.tabBarItem.titlePositionAdjustment = viewController.cyl_tabBarItem.titlePositionAdjustment;
        [viewController.tabBarItem setTitleTextAttributes:[viewController.cyl_tabBarItem titleTextAttributesForState:UIControlStateNormal] forState:UIControlStateNormal];
        [viewController.tabBarItem setTitleTextAttributes:[viewController.cyl_tabBarItem titleTextAttributesForState:UIControlStateSelected] forState:UIControlStateSelected];
    }
}

- (BOOL)_shouldShowsBottomBar {
    BOOL showsTabBar = YES;
    if (self.isTabBarHidden) {
        showsTabBar = NO;
    } else {
        showsTabBar = [self _checkHidesBottomBarWhenPushed];
    }
    return showsTabBar;
}

- (void)_updateBottomBarShowHideIfNeeded {
    BOOL showsTabBar = [self _shouldShowsBottomBar];
    if (!_tabBarIsAnimating) {
        self.cyl_tabBar.hidden = !showsTabBar;
    }
    [self _updateAdditionalSafeAreaInsets:NO animated:NO];
}

- (void)_addParallaxOverlayViewToViewController:(UIViewController *)viewController {
    // create overlayView
    UIView *superview = viewController.view;
    if (!_parallaxOverlayView) {
        _parallaxOverlayView = [[_CYLFlatDesignTabBarParallaxOverlayView alloc] initWithFrame:superview.bounds];
    }
    [superview addSubview:_parallaxOverlayView];
    [superview bringSubviewToFront:_parallaxOverlayView];
    
    if (self.cyl_tabBar.superview != _parallaxOverlayView) {
        if (!_tabBarIsAnimating) {
            self.cyl_tabBar.frame = self.tabBarFrame;
        }
        self.cyl_tabBar.hidden = NO;
        [_parallaxOverlayView addSubview:self.cyl_tabBar];
    }
}

- (void)_updateAdditionalSafeAreaInsets:(BOOL)shouldLayoutManually animated:(BOOL)animated {
    UIViewController *selectedViewController = self.selectedViewController;
    UIEdgeInsets additionalSafeAreaInsets = selectedViewController.additionalSafeAreaInsets;
    additionalSafeAreaInsets.bottom = self.cyl_tabBar.hidden ? 0 : self.tabBarHeight;
    NSTimeInterval duration = animated ? 0.2 : 0;
    [UIView animateWithDuration:duration animations:^{
        selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        if (self.moreNavigationController && self.moreNavigationController != selectedViewController) {
            self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
        }
    }];
    if (shouldLayoutManually) {
        [selectedViewController.view setNeedsLayout];
        [selectedViewController.view layoutIfNeeded];
    }
}

- (void)_changeItem:(CYLFlatDesignTabBarItem *)item toItem:(CYLFlatDesignTabBarItem *)toItem {
    NSInteger index = [_items indexOfObject:item];
    if (index == NSNotFound) {
        return;
    }
    [_items replaceObjectAtIndex:index withObject:toItem];
    [self.cyl_tabBar setItems:_items];
}

@end

@implementation UIViewController (CYLFlatDesignTabBarControllerItem)

static char *_qqtabBarItemPropertyKey;

- (CYLFlatDesignTabBarItem *)cyl_tabBarItem {
    CYLFlatDesignTabBarItem *item = objc_getAssociatedObject(self, &_qqtabBarItemPropertyKey);
    if (!item) {
        NSString *title = item.title ?: self.title;
        item = [[CYLFlatDesignTabBarItem alloc] initWithTitle:title image:item.image selectedImage:item.selectedImage];
        objc_setAssociatedObject(self, &_qqtabBarItemPropertyKey, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)cyl_setTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (tabBarItem == nil) {
        tabBarItem = [[CYLFlatDesignTabBarItem alloc] initWithTitle:self.title image:nil];
    }
    
    CYLFlatDesignTabBarItem *oldItem = self.cyl_tabBarItem;
    
    if ([self.tabBarController isKindOfClass:[CYLFlatDesignTabBarController class]]) {
        CYLFlatDesignTabBarController *tabBarController = (CYLFlatDesignTabBarController *)self.tabBarController;
        [tabBarController _changeItem:oldItem toItem:tabBarItem];
    }
    
    objc_setAssociatedObject(self, &_qqtabBarItemPropertyKey, tabBarItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


