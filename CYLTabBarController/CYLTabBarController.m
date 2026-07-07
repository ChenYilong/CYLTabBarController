//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
#import <objc/runtime.h>
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"

#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
#else

#endif


#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#import "CYLFlatDesignTabBar.h"

#else
#endif


//#import "CYLFlatDesignTabBarItem.h"
//#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
//#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
//#import "CYLFlatDesignTabBarHideTabBar.h"


#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLFlatDesignTabBarItem.h>
#import <CYLTabBarController/UINavigationController+CYLFlatDesignTabBarPrivate.h>
#import <CYLTabBarController/_CYLFlatDesignTabBarParallaxOverlayView.h>
#import <CYLTabBarController/CYLFlatDesignTabBarHideTabBar.h>
#endif


#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
//#import <CYLTabBarController/UIImage+CYLTabBarControllerExtention.h>
//#import <CYLTabBarController/NSObject+CYLTabBarControllerExtention.h>
#else
//#import "CYLTabBarController.h"
//#import "UIImage+CYLTabBarControllerExtention.h"
//#import "NSObject+CYLTabBarControllerExtention.h"
#endif

NSString *const CYLTabBarItemTitle = @"CYLTabBarItemTitle";
NSString *const CYLTabBarItemImage = @"CYLTabBarItemImage";
NSString *const CYLTabBarItemSelectedImage = @"CYLTabBarItemSelectedImage";
NSString *const CYLTabBarItemImageInsets = @"CYLTabBarItemImageInsets";
NSString *const CYLTabBarItemTitlePositionAdjustment = @"CYLTabBarItemTitlePositionAdjustment";
NSString *const CYLTabBarItemImagePositionAdjustment = @"CYLTabBarItemImagePositionAdjustment";
NSString *const CYLTabBarLottieFilePath = @"CYLTabBarLottieFilePath";
NSString *const CYLTabBarLottieURL = @"CYLTabBarLottieURL";
NSString *const CYLTabBarLottieSize = @"CYLTabBarLottieSize";

NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
CGFloat CYLTabBarHeight = 49.0f;

NSString *const CYLTabBarItemWidthDidChangeNotification = @"CYLTabBarItemWidthDidChangeNotification";
NSString *const CYLTabBarItemLottieAnimationPlayingNotification = @"CYLTabBarItemLottieAnimationPlayingNotification";

NSString *const CYLTabBarStyleTypeDidChangeNotification = @"CYLTabBarStyleTypeDidChangeNotification";
static void * const CYLTabImageViewDefaultOffsetContext = (void*)&CYLTabImageViewDefaultOffsetContext;
//static void * const CYLTabBarControllerVisiableItemsCountContext = (void*)&CYLTabBarControllerVisiableItemsCountContext;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
CGFloat const CYLFlatDesignUITabBarControllerHideShowBarDuration = 0.2;
#else
#endif

@interface CYLTabBarController () <UITabBarControllerDelegate>

@property (nonatomic, assign, getter=isObservingTabImageViewDefaultOffset) BOOL observingTabImageViewDefaultOffset;
@property (nonatomic, assign, getter=shouldInvokeOnceViewDidLayoutSubViewsBlock) BOOL invokeOnceViewDidLayoutSubViewsBlock;
@property (nonatomic, strong) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong) NSMutableArray *lottieSizes;
@property (nonatomic, assign, getter=isLottieViewAdded) BOOL lottieViewAdded;
@property (nonatomic, strong) UIImage *tabItemPlaceholderImage;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, strong) CYLTabBar *tabBar;
@property (nonatomic, assign, readonly) CGRect tabBarFrame;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
@property (nonatomic, strong) NSMutableArray<CYLFlatDesignTabBarItem *> *items;
@property (nonatomic, assign) BOOL cyl_tabBarHidden;
//@property (nonatomic, assign) CYLTabBarStyleType tabBarStyleType;
//@property (nonatomic, readwrite) CYLFlatDesignTabBar *cyl_tabBar;
#else
#endif
@end

@implementation CYLTabBarController {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#else
#endif
}

@synthesize viewControllers = _viewControllers;
@synthesize tabBarHeight = _tabBarHeight;
@synthesize cyl_tabBar = _cyl_tabBar;
@synthesize selectedViewController = _selectedViewController;
@dynamic tabBar;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
//@synthesize viewControllers = _viewControllers;
@synthesize selectedIndex = _selectedIndex;
@dynamic delegate;

//@synthesize tabBarHeight = _tabBarHeight;
#else
#endif

#pragma mark -
#pragma mark - Life Cycle


- (void)tabChangedToControl:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    UIViewController *vc = nil;
    [self tabChangedToSelectedViewController:vc control:control];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)tabChangedToSelectedViewController:(UIViewController *)viewController
                                   control:(UIControl *)control {
    
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self tabChangedToSelectedIndex:self.selectedIndex viewController:viewController control:control];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * 三个地方 ， 都要调用：
 *  选中状态下的重新点击，（iOS26 需要在手势代理方法中进行hook追加该方法）
 *  用户切换index时
 *  代码切换index 时。
 */
- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                          control:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    //扁平样式，与玻璃样式均可使用
    if (![self.cyl_tabBar isKindOfClass:[UITabBar class]] && ![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (!control) {
        control = [viewController cyl_getViewControllerInsteadOfNavigationController].cyl_tabButton;
    }
    if (!control) {
        control = viewController.cyl_tabButton;
    }
    // Ensure we do not pass nil to a nonnull parameter
    UIViewController *targetVC = viewController ?: self.selectedViewController;
    if (targetVC) {
        UITabBarController *tabBarController = nil;
        [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:targetVC];
    }
    if (control) {
        [self didSelectControl:control];
    }
    
    UITabBarItem *item = viewController.tabBarItem;
    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    BOOL isLottieEnabled = [self isLottieEnabled];
    
    if (isLottieEnabled && !isChildViewControllerPlusButton) {
        //非液态玻璃 与 液态玻璃逻辑共用，Lottie 播放逻辑都在 tabChangedToSelectedIndex 中。
        if (NO == self.selectedViewController.cyl_isPlaceholder) {
            [self addLottieImageWithControl:control lottieURL:item.cyl_lottieURL lottieSizeValue:item.cyl_lottieSizeValue animation:YES];
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)initLottieTabBar:(CYLTabBar *)tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    //CYL_UIDesignClassicCYLTabBar
    dispatch_async(dispatch_get_main_queue(),^{
        if ([CYLConstants isLiquidGlassActive]) {
            [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
                UIControl *control = viewController.cyl_tabButton;
                NSURL *url = viewController.tabBarItem.cyl_lottieURL;
                NSValue *lottieSizeValue = viewController.tabBarItem.cyl_lottieSizeValue;
                if (!control) {
                    return;
                }
                if (!url) {
                    return;
                }
                if (!viewController.cyl_isEmbedInTabBarController) {
                    return;
                }
                if ([control cyl_isPlusControl]) {
                    return;
                }
                UIControl *tabButton = control;
                BOOL defaultSelected = NO;
                if (idx == self.selectedIndex) {
                    defaultSelected = YES;
                }
                //TODO:  selected content, double add
                [self addLottieImageWithControl:tabButton
                                      lottieURL:url
                                lottieSizeValue:lottieSizeValue
                                      animation:defaultSelected
                                defaultSelected:defaultSelected];
                self.lottieViewAdded = YES;
            }];
        } else {
            NSArray *subTabBarButtonsWithoutPlusButton = tabBar.cyl_subTabBarButtonsWithoutPlusButton;
            [subTabBarButtonsWithoutPlusButton enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
                UIControl *tabButton = control;
                BOOL defaultSelected = NO;
                if (idx == self.selectedIndex) {
                    defaultSelected = YES;
                }
                //TODO:  selected content, double add
                [self addLottieImageWithControl:tabButton animation:defaultSelected defaultSelected:defaultSelected];
                self.lottieViewAdded = YES;
            }];
        }
    });
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)setViewDidLayoutSubViewsBlockInvokeOnce:(BOOL)invokeOnce block:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock  {
    self.invokeOnceViewDidLayoutSubViewsBlock = YES;
    self.viewDidLayoutSubviewsBlock = [viewDidLayoutSubviewsBlock copy];
}

- (void)setViewDidLayoutSubViewsBlock:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock {
    _viewDidLayoutSubviewsBlock = [viewDidLayoutSubviewsBlock copy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self.cyl_tabBar layoutSubviews];//Fix issue #93 #392
    if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]] ) {
        // add callback for visiable control, included all plusButton.
        CYLTabBar *tabBar = (CYLTabBar *)self.cyl_tabBar;
        [tabBar.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([CYLConstants isLiquidGlassActive]) {
                //液态玻璃无法添加事件 放进手势响代理里处理。
                return;
            }
            //to avoid invoking didSelectControl twice, because plusChildViewControllerButtonClicked will invoke setSelectedIndex
            if ([control cyl_isChildViewControllerPlusButton]) {
                return;
            }
            UILabel *tabLabel = control.cyl_tabLabel;
            tabLabel.textAlignment = NSTextAlignmentCenter;
            
            //FIX: iOS26 之前也不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
            SEL action = @selector(tabChangedToControl:);
            //fix#610 removeTarget 以避免 `-setNeedsLayout` 导致的重复调用 viewDidLayoutSubviews， 可能导致的action追加失败的bug
            [control removeTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
            [control addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
            
            if (idx == self.selectedIndex && ![control isKindOfClass:[CYLPlusButton class]]) {
                control.selected = YES;
            }
        }];
        
        do {
            if (self.isLottieViewAdded) {
                break;
            }
            //FIXME: ??
            NSArray *subTabBarButtonsWithoutPlusButton = tabBar.cyl_subTabBarButtonsWithoutPlusButton;
            BOOL isLottieEnabled = [self isLottieEnabled];
            
            if (![CYLConstants isLiquidGlassActive]) {
                // 因为液态玻璃， 补全了所有的缺失的lottieURLs，所以一定保持一致， 无需要处理。
                if(!isLottieEnabled || (subTabBarButtonsWithoutPlusButton.count != self.lottieURLs.count)) {
                    self.lottieViewAdded = YES;
                    break;
                }
            } else {
                if(!isLottieEnabled) {
                    self.lottieViewAdded = YES;
                    break;
                }
            }
            [self initLottieTabBar:tabBar];
            break;
        } while (NO);
    }
    
    
    if ([CYLConstants isLiquidGlassActive] && ([self hasPlusButton]) && [self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        UIControl *plusControlOrigin = [self.cyl_tabBar cyl_platterContentViewWithIndex:CYLExternPlusButton.cyl_tabBarItemVisibleIndex];
        UIButton *selectedCover = CYLExternPlusButton.selectedContentView;
        UIControl *plusSelectedControl = plusControlOrigin.cyl_platterSelectedControl;
        [plusControlOrigin.cyl_tabImageView cyl_setHidden:YES];
        [plusControlOrigin.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];
        
        //由于 SelectedControl 所在图层的渲染比未选中图层有延迟， 所以必须加延迟，如果不加延迟，可能无法获取到正确的子视图， 有概率获取的子视图为nil
        NSUInteger delaySecondsForSelectedContentView = 0.5;
        if ([self hasPlusChildViewController]) {
            [plusSelectedControl cyl_coverTabImageViewOrTabButton:YES
                                                          newView:selectedCover
                                                           offset:UIOffsetZero
                                                             show:YES
                                          delayIfNeededForSeconds:delaySecondsForSelectedContentView
                                                       completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull selectedCover) {
                
                /*!
                 *
                 *我要求 selectedCover 的中心坐标 强制与 CYLExternPlusButton坐标一致。 坐标系转换
                 * _UITabBarPlatterView
                 ├── SelectedContentView
                 │    └── selectedCover
                 │
                 └── CYLPlusButtonSubclass
                 */
                UIView *platterView = CYLExternPlusButton.superview;
                UIView *selectedContainerView = selectedCover.superview;
                
                if (platterView && selectedContainerView) {
                    
                    CGPoint convertedCenter =
                    [selectedContainerView convertPoint:CYLExternPlusButton.center
                                               fromView:platterView];
                    
                    selectedCover.center = convertedCenter;
                }
            }];
        } else {
            //由于有几率无法获取到cyl_tabImageView， 只有延迟获取，才能避免获取为空nil。
            dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySecondsForSelectedContentView * NSEC_PER_SEC));
            dispatch_after(when, dispatch_get_main_queue(), ^{
                //imageView 是主要的
                [plusSelectedControl.cyl_tabImageView cyl_setHidden:YES];
                //cyl_swappableImageViewViewInTabBarButton这个是防御性的， 理论上可以不隐藏。
                [plusSelectedControl.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];
            });
        }
    }
    

} else {/**  CYLTabBarStyleTypeFlatDesign*/}

if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
    if (!_tabBarIsAnimating && !CGRectEqualToRect(self.cyl_tabBar.frame, self.tabBarFrame) && self.cyl_tabBar.superview == self.view) {
        //目的是动态更新tabbar高度 ， 测试方法为 修改 tabBarController.tabBarHeight ， 预期为实时跟新UI中的tabbar高度。// The goal is to dynamically update the tab bar height. The test method involves modifying `tabBarController.tabBarHeight`; the expected result is that the tab bar height in the UI updates in real time.
        self.cyl_tabBar.frame = self.tabBarFrame;
    }

#else
#endif
    } else {}


    if (self.shouldInvokeOnceViewDidLayoutSubViewsBlock) {
        //在对象生命周期内，不添加 flag 属性的情况下，防止多次调进这个方法
        if (objc_getAssociatedObject(self, _cmd)) {
            return;
        } else {
            !self.viewDidLayoutSubviewsBlock ?: self.viewDidLayoutSubviewsBlock(self);
            objc_setAssociatedObject(self, _cmd, @"shouldInvokeOnceViewDidLayoutSubViewsBlock", OBJC_ASSOCIATION_RETAIN);
        }
    } else {
        !self.viewDidLayoutSubviewsBlock ?: self.viewDidLayoutSubviewsBlock(self);
    }

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if ([CYLConstants isLiquidGlassActive]) {
        //如果不是扁平设计风格，也就是液态玻璃不支持自定义高度， 液态玻璃系统样式是固定高度的。// Unless it's a flat design style—in which case Liquid Glass does not support custom heights—the Liquid Glass system style has a fixed height.
        return;
    }
    if (0 == self.tabBarHeight) {
        return;
    }
    self.cyl_tabBar.frame = ({
        CGRect frame = self.cyl_tabBar.frame;
        CGFloat tabBarHeight = self.tabBarFrame.size.height;
        frame.size.height = tabBarHeight;
        frame.origin.y = self.view.frame.size.height - tabBarHeight;
        frame;
    });
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/// 控制器支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    UIViewController *controller = self.selectedViewController;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)controller;
        return navigationController.topViewController.supportedInterfaceOrientations;
    } else {
        return controller.supportedInterfaceOrientations;
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if ([_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {     return self.selectedViewController.supportedInterfaceOrientations; }
                return self.selectedViewController.supportedInterfaceOrientations;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/ }
    return self.selectedViewController.supportedInterfaceOrientations;
}

- (void)dealloc {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    [self removePlusButtonIfNeeded];
    /// MARK: 这里是全局处理，如果生成新的，这里操作时会破坏新的视图展示
    //    BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
    //    BOOL hasPlusChildViewController = [self hasPlusChildViewController] && isAdded;
    //    if (isAdded && hasPlusChildViewController && CYLPlusChildViewController.cyl_plusViewControllerEverAdded == YES) {
    //        [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:NO];
    //    }
    // KVO反注册
    if (self.cyl_tabBar && self.isObservingTabImageViewDefaultOffset) {
        [self.cyl_tabBar cyl_removeObserver:self forKeyPath:@"tabImageViewDefaultOffset"];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                [self cyl_removeObserver:self forKeyPath:@"cyl_tabBar"];
#else
#endif
    } else { }
}

#pragma mark - Overrides

- (BOOL)isTabBarHidden {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    return self.cyl_tabBarHidden;
#else
    return NO;
#endif
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    //CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                
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
      
            
                if (self.cyl_tabBarHidden != hidden) {
                    
                    self.cyl_tabBarHidden = hidden;
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
                                
                            CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willHideTabBar:, self, self.cyl_tabBar);
//                                [self.delegate tabBarController:self willHideTabBar:self.cyl_tabBar];
                            }
                        } else {
                            if (_delegateHas.willShowTabBar) {
//                                [self.delegate tabBarController:self willShowTabBar:self.cyl_tabBar];
                            CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willShowTabBar:, self, self.cyl_tabBar);
                                                            }

                        }
                        
                        CGAffineTransform startTransform = hidden? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, self.cyl_tabBar.frame.size.height);
                        CGAffineTransform endTransform = hidden? CGAffineTransformMakeTranslation(0, self.cyl_tabBar.frame.size.height) : CGAffineTransformIdentity;
                        self.cyl_tabBar.transform = startTransform;
                        self.cyl_tabBar.hidden = NO;
                        
                        [UIView animateWithDuration:CYLFlatDesignUITabBarControllerHideShowBarDuration animations:^{
                            self.cyl_tabBar.transform = endTransform;
                        } completion:^(BOOL finished) {
                            self.cyl_tabBar.transform = CGAffineTransformIdentity;
                            self.cyl_tabBar.hidden = hidden;
                            [self _updateAdditionalSafeAreaInsetsWithAnimated:animated];
                            self->_tabBarIsAnimating = NO;
                            
                            if (hidden) {
                                
                                if (self->_delegateHas.didHideTabBar) {
//                                    [self.delegate tabBarController:self didHideTabBar:self.cyl_tabBar];
                                CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didHideTabBar:, self, self.cyl_tabBar);
                                                                }

                            } else {
                                if (self->_delegateHas.didShowTabBar) {
//                                    [self.delegate tabBarController:self didShowTabBar:self.cyl_tabBar];
                                CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didShowTabBar:, self, self.cyl_tabBar);
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
//                                [self.delegate tabBarController:self willHideTabBar:self.cyl_tabBar];
                                CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willHideTabBar:, self, self.cyl_tabBar);

                            }

                        } else {
                            if (_delegateHas.willShowTabBar) {
//                                [self.delegate tabBarController:self willShowTabBar:self.cyl_tabBar];
                            CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willShowTabBar:, self, self.cyl_tabBar);

                            }

                        }
                        
                        self.cyl_tabBar.hidden = hidden;
                        [self _updateAdditionalSafeAreaInsetsWithAnimated:animated];
                        
                        if (hidden) {
                            if (_delegateHas.didHideTabBar) {
//                                [self.delegate tabBarController:self didHideTabBar:self.cyl_tabBar];
                            CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didHideTabBar:, self, self.cyl_tabBar);

                            }

                        } else {
                            if (_delegateHas.didShowTabBar) {
//                                [self.delegate tabBarController:self didShowTabBar:self.cyl_tabBar];
                                CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didShowTabBar:, self, self.cyl_tabBar);
                            }

                        }
                    }
                }
            
#else
#endif
    } else { }
}

- (BOOL)_checkHidesBottomBarWhenPushed {
    BOOL showsTabBar = YES;
    //CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return showsTabBar; }
                UIViewController *selectedViewController = self.selectedViewController;
                if ([self _showsMoreNavigationController]) {
                    NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
                    if (self.selectedIndex >= moreIndex || self.selectedIndex == NSNotFound) {
                        selectedViewController = self.moreNavigationController;
                    }
                }
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
                }
                return showsTabBar;
            
#else
#endif
    } else {/*Not CYLTabBarStyleTypeFlatDesign*/}
    return showsTabBar;
}

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)setDelegate:(id<CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate>)delegate {

#else
    - (void)setDelegate:(id<CYLTabBarControllerDelegate>)delegate {
#endif

    [super setDelegate:delegate];
    
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        _delegateHas.willShowTabBar = [delegate respondsToSelector:@selector(tabBarController:willShowTabBar:)];
        _delegateHas.didShowTabBar = [delegate respondsToSelector:@selector(tabBarController:didShowTabBar:)];
        _delegateHas.willHideTabBar = [delegate respondsToSelector:@selector(tabBarController:willHideTabBar:)];
        _delegateHas.didHideTabBar = [delegate respondsToSelector:@selector(tabBarController:didHideTabBar:)];
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)setupChildViewController:(UIViewController *)viewController
                             idx:(NSUInteger)idx {
    
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                NSString *title = nil;
                id normalImageInfo = nil;
                id selectedImageInfo = nil;
                UIOffset titlePositionAdjustment = UIOffsetZero;
                UIOffset imagePositionAdjustment = UIOffsetZero;
                
                UIEdgeInsets imageInsets = UIEdgeInsetsZero;
                NSURL *lottieURL = nil;
                NSString *lottieFilePath = nil;
                
                NSValue *lottieSizeValue = nil;
                if (viewController != CYLPlusChildViewController) {
                    
                    if (_tabBarItemsAttributes.count > idx) {
                        if (@available(iOS 13.0, *)) {
                            //fix https://github.com/ChenYilong/CYLTabBarController/issues/437
                            title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle] ?: @"";
                        } else {
                            title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                        }
                        
                        normalImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemImage];
                        selectedImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage];
                        lottieURL = _tabBarItemsAttributes[idx][CYLTabBarLottieURL];
                        lottieFilePath = _tabBarItemsAttributes[idx][CYLTabBarLottieFilePath];
                        
                        if (!lottieURL) {
                            lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                        }
                        lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
                        
                        NSValue *offsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemTitlePositionAdjustment];
                        UIOffset offset = [offsetValue UIOffsetValue];
                        titlePositionAdjustment = offset;
                        
                        NSValue *imagePositionAdjustmentoffsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemImagePositionAdjustment];
                        UIOffset imagePositionAdjustmentoffset = [imagePositionAdjustmentoffsetValue UIOffsetValue];
                        imagePositionAdjustment = imagePositionAdjustmentoffset;
                        
                        NSValue *insetsValue = _tabBarItemsAttributes[idx][CYLTabBarItemImageInsets];
                        UIEdgeInsets insets = [insetsValue UIEdgeInsetsValue];
                        imageInsets = insets;
                    }
                    
                } else {
                    /**如果是CYLPlusChildViewController ，title设置为空字符串，解决把第一个tabbarItem设置成plusButton后，其他的
                     tabbarItem会不显示title问题
                      见： https://github.com/ChenYilong/CYLTabBarController/issues/563
                     **/
                    title = @"";
                    if ([CYLConstants isLiquidGlassActive] && ([self hasPlusButton])) {
                    } else {
                        idx--;
                    }
                }
                [self addOneChildViewController:viewController
                                            idx:idx
                                      WithTitle:title
                                normalImageInfo:normalImageInfo
                              selectedImageInfo:selectedImageInfo
                        titlePositionAdjustment:titlePositionAdjustment
                        imagePositionAdjustment:imagePositionAdjustment
                                    imageInsets:imageInsets
                                      lottieURL:lottieURL
                                 lottieFilePath:lottieFilePath
                                lottieSizeValue:lottieSizeValue];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
}


/**
 *  添加一个子控制器
 *
 *  @param viewController    控制器
 *  @param title             标题
 *  @param normalImageInfo   图片
 *  @param selectedImageInfo 选中图片
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                              idx:(NSUInteger)idx
                        WithTitle:(NSString *)title
                  normalImageInfo:(id)normalImageInfo
                selectedImageInfo:(id)selectedImageInfo
          titlePositionAdjustment:(UIOffset)titlePositionAdjustment
          imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(NSURL *)lottieURL
                   lottieFilePath:(NSString *)lottieFilePath
                  lottieSizeValue:(NSValue *)lottieSizeValue {
    
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                
                UIImage *normalImage = [UIImage cyl_imageNamed:normalImageInfo];
                
                UIImage *selectedImage = [UIImage cyl_imageNamed:selectedImageInfo];;
                
                UIEdgeInsets insets = self.imageInsets;
                BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets));
                if (shouldCustomizeImageInsets) {
                    insets = imageInsets;
                }
                
                UIOffset titleoffset = self.titlePositionAdjustment;
                BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, titlePositionAdjustment));
                if (shouldCustomizeTitlePositionAdjustment) {
                    titleoffset = titlePositionAdjustment;
                }
                
                UIOffset imageoffset = self.imagePositionAdjustment;
                BOOL shouldCustomizeImagePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, imagePositionAdjustment));
                if (shouldCustomizeImagePositionAdjustment) {
                    imageoffset = imagePositionAdjustment;
                }
                
                lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                if (lottieURL) {
                    [self.lottieURLs addObject:lottieURL];
                    NSValue *tureLottieSizeValue = [CYLConstants cyl_getTureLottieSizeValue:lottieSizeValue fromNormalImage:normalImage];
                    [self.lottieSizes addObject:tureLottieSizeValue];
                }        //cyl_setTabBarItem 方法内部需要获取到tabbarvc但是， cyl_setTabBarItem是在初始化完成前的配置， 所以需要手动指定tabbarvc，否则cyl_setTabBarItem会初始化失败。
                CYLFlatDesignTabBarItem *cyl_tabBarItem = [[CYLFlatDesignTabBarItem alloc] initWithTitle:title
                                                                                                   image:normalImage
                                                                                           selectedImage:selectedImage
                                                                                                   index:idx
                                                                                 titlePositionAdjustment:titleoffset
                                                                                 imagePositionAdjustment:imageoffset
                                                                                             imageInsets:insets
                                                                                          lottieFilePath:lottieFilePath
                                                                                         lottieSizeValue:lottieSizeValue];
                
                
                [cyl_tabBarItem cylflatdesign_setTabBarController:self];
                cyl_tabBarItem.childViewController = viewController;
                [cyl_tabBarItem setTitleTextAttributes:
                 @{
                    NSForegroundColorAttributeName : UIColor.systemYellowColor
                }
                                              forState:UIControlStateSelected];
                
                [viewController cyl_setTabBarItem:cyl_tabBarItem];
                //    [self.items addObject:cyl_tabBarItem];
                //    [self addChildViewController:viewController];
            
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    
}



#pragma mark -
#pragma mark - public Methods
- (nonnull instancetype)initWithViewControllers:(nonnull NSArray<__kindof UIViewController *> *)viewControllers
                          tabBaritemsAttributes:(nonnull NSArray<NSDictionary *> *)tabBarItemsAttributes {
    NSString *context = nil;
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:UIEdgeInsetsZero
                 titlePositionAdjustment:UIOffsetZero
                               styleType:type
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    NSString *context = nil;
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:imageInsets
                 titlePositionAdjustment:titlePositionAdjustment
                               styleType:type
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                context:(NSString *)context {
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:imageInsets
                 titlePositionAdjustment:titlePositionAdjustment
                               styleType:type
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                              styleType:(CYLTabBarStyleType)styleType
                                context:(NSString *)context {
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:UIEdgeInsetsZero
                 titlePositionAdjustment:UIOffsetZero
                               styleType:styleType
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                              styleType:(CYLTabBarStyleType)styleType
                                context:(NSString *)context {
    if (self = [super init]) {
        _imageInsets = imageInsets;
        _titlePositionAdjustment = titlePositionAdjustment;
        _tabBarItemsAttributes = tabBarItemsAttributes;
        _adjustTabBarItemImageViewSizeDependOnSuperView = YES;
        //以下为重要步骤，谨慎修改顺序：
        self.tabBarStyleType = styleType;// 步骤1 must use setter 必须在 self.viewControllers之前设置， 因为 self.viewControllers直接涉及到样式判断逻辑。
        [self cyl_tabBar];
        self.context = context; // 步骤2 must use setter 必须在 self.viewControllers之前设置， 因为 self.viewControllers 直接涉及样式contxt 与 PlusButton的判断逻辑。否则 contxt 永远是默认值
        self.viewControllers = viewControllers;// 步骤3 must use setter,必须在 self.tabBarStyleType之后设置， 因为 self.viewControllers 直接涉及到扁平TabBar样式KVC逻辑。
        
    }
    return self;
}

- (UIViewContentMode)lottieAnimationViewContentMode {
    return UIViewContentModeScaleAspectFit;
}

- (void)removePlusButtonIfNeeded {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (!self.hasPlusButton) {
        return;
    }
    if ([[CYLExternPlusButton class] respondsToSelector:@selector(tabBarContext)]) {
        NSString *plusButtonContext = [[CYLExternPlusButton class] performSelector:@selector(tabBarContext)];
        if (plusButtonContext && ![self.cyl_context isEqualToString:plusButtonContext]) {
            // contexts differ; remove PlusButton
            if ([[CYLExternPlusButton class] respondsToSelector:@selector(removePlusButton)]) {
                [[CYLExternPlusButton class] performSelector:@selector(removePlusButton)];
            }
        }
    }
    
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(NSString *)context {
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:imageInsets
                         titlePositionAdjustment:titlePositionAdjustment
                                       styleType:styleType
                                         context:context];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                            context:(NSString *)context {
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:imageInsets
                         titlePositionAdjustment:titlePositionAdjustment
                                       styleType:CYLTabBarStyleTypeDefault
                                         context:context];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    NSString *context = nil;
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:imageInsets
                         titlePositionAdjustment:titlePositionAdjustment
                                         context:context];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(NSString *)context {
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:UIEdgeInsetsZero
                         titlePositionAdjustment:UIOffsetZero
                                       styleType:styleType
                                         context:context];
}
    
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    return [self tabBarControllerWithViewControllers:viewControllers
                               tabBarItemsAttributes:tabBarItemsAttributes
                                         imageInsets:UIEdgeInsetsZero
                             titlePositionAdjustment:UIOffsetZero];
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
- (void)hideTabBadgeBackgroundSeparator {
    [self hideTabBarShadowImageView];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP

#pragma mark -  *  iOS26+ , 有 plusButton

// MARK:  *  iOS26+ , 有 plusButton

/*!
 *  iOS26+ , 有 plusButton
 */
- (void)alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:(NSArray *)viewControllers {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (![self.cyl_tabBar hasPlusButton]) {
        _viewControllers = viewControllers;
        return;
    }
    UIViewController *viewController = nil;
    NSInteger index = NSNotFound;
    if ([self hasPlusChildViewController]) {
        viewController = CYLPlusChildViewController;
        //        index = CYLPlusButtonIndex;
    } else {
        UIViewController *placeholderViewController = [UIViewController new];
        [placeholderViewController cyl_setIsPlaceholder:YES];
        viewController = placeholderViewController;
    }
    _viewControllers = [[self alignViewControllers:viewControllers withPlusButtonViewControllerPlaceholder:viewController] copy];
    [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:index];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}

//CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                if (![self.cyl_tabBar hasPlusButton]) {
                    _viewControllers = viewControllers;
                    return;
                }
                UIViewController *viewController = nil;
                NSInteger index = NSNotFound;
                if ([self hasPlusChildViewController]) {
                    viewController = CYLPlusChildViewController;
                } else {
                    UIViewController *placeholderViewController = [UIViewController new];
                    [placeholderViewController cyl_setIsPlaceholder:YES];
                    viewController = placeholderViewController;
                }
           

                index = CYLPlusButtonIndex;
                _viewControllers = [[self alignViewControllers:viewControllers withPlusButtonViewControllerPlaceholder:viewController] copy];
                
                [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:index];
        
#else
#endif
    } else {}
}

/*!
 *  iOS26+ , 有 plusButton
 */
- (NSMutableArray *)alignViewControllers:(NSArray *)arrayWithoutPlusButton withPlusButtonViewControllerPlaceholder:(id)plusButtonViewControllerPlaceholder {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (!plusButtonViewControllerPlaceholder) {
        return [arrayWithoutPlusButton mutableCopy];
    }
    if (![self.cyl_tabBar hasPlusButton]) {
        return [arrayWithoutPlusButton mutableCopy];
    }
    NSMutableArray *arrayWithPlusButton = nil;
    if ([arrayWithoutPlusButton isKindOfClass:[NSArray class]]) {
        arrayWithPlusButton = [NSMutableArray arrayWithArray:arrayWithoutPlusButton];
    } else if ([arrayWithoutPlusButton isKindOfClass:[NSMutableArray class]]) {
        arrayWithPlusButton = (NSMutableArray *)arrayWithoutPlusButton;
    }
    NSInteger index = NSNotFound;
    if (plusButtonViewControllerPlaceholder && (plusButtonViewControllerPlaceholder == CYLPlusChildViewController)) {
        //        index = CYLPlusButtonIndex;
    }
    
    NSInteger plusButtonIndex = (index != NSNotFound) ? CYLPlusButtonIndex : arrayWithoutPlusButton.count / 2;
    
    if (arrayWithPlusButton.count > plusButtonIndex) {
        [arrayWithPlusButton insertObject:plusButtonViewControllerPlaceholder atIndex:plusButtonIndex];
        //FIXME:  to delete 液态玻璃暂时不支持自定义PlusButton位置。
        [CYLExternPlusButton cyl_setTabBarItemVisibleIndex:plusButtonIndex];
        [self cyl_addChildViewController:plusButtonViewControllerPlaceholder];
    }
    return arrayWithPlusButton;
} else {/**  CYLTabBarStyleTypeFlatDesign*/}

//CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return [arrayWithoutPlusButton mutableCopy]; }
                if (!plusButtonViewControllerPlaceholder) {
                    return [arrayWithoutPlusButton mutableCopy];
                }
                if (![self.cyl_tabBar hasPlusButton]) {
                    return [arrayWithoutPlusButton mutableCopy];
                }
                NSMutableArray *arrayWithPlusButton = nil;
                if ([arrayWithoutPlusButton isKindOfClass:[NSArray class]]) {
                    arrayWithPlusButton = [NSMutableArray arrayWithArray:arrayWithoutPlusButton];
                } else if ([arrayWithoutPlusButton isKindOfClass:[NSMutableArray class]]) {
                    arrayWithPlusButton = (NSMutableArray *)arrayWithoutPlusButton;
                }
                NSInteger index = NSNotFound;
                //    if (plusButtonViewControllerPlaceholder && (plusButtonViewControllerPlaceholder == CYLPlusChildViewController)) {
                index = CYLPlusButtonIndex;
                //    }
                NSInteger plusButtonIndex = (index != NSNotFound) ? CYLPlusButtonIndex : arrayWithoutPlusButton.count / 2;
                if (arrayWithPlusButton.count > plusButtonIndex) {
                    [arrayWithPlusButton insertObject:plusButtonViewControllerPlaceholder atIndex:plusButtonIndex];
                    [CYLExternPlusButton cyl_setTabBarItemVisibleIndex:plusButtonIndex];
                    [self cyl_addChildViewController:plusButtonViewControllerPlaceholder];
                }
                
                //TODO:  插入self.items
                //    if (self.items.count > plusButtonIndex) {
                //        [self.items insertObject:[CYLFlatDesignTabBarItem new] atIndex:plusButtonIndex];
                //    }
                return arrayWithPlusButton;
            
#else
#endif
        
    } else {    }
    return [arrayWithoutPlusButton mutableCopy];
}
/*!
 *  iOS26+ , 有 plusButton
 */
- (void)alignTabControlIfNeededWithViewControllers:(NSArray *)viewControllers {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    if (![self.cyl_tabBar hasPlusButton]) {
        _viewControllers = [viewControllers copy];
        return;
    }
    [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
    BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
    BOOL addedFlag = [CYLPlusChildViewController cyl_plusViewControllerEverAdded];
    BOOL hasPlusChildViewController = [self hasPlusChildViewController] && !isAdded && !addedFlag;
    if (hasPlusChildViewController) {
        [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
        [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:YES];
    } else {
        [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:NSNotFound];
    }
    
    if (![CYLConstants isLiquidGlassActive]) {
        if (!hasPlusChildViewController) {
            _viewControllers = [viewControllers copy];
        }
        return;
    }
    
    if (![self hasPlusButton]) {
        if (!hasPlusChildViewController) {
            _viewControllers = [viewControllers copy];
        }
        return;
    }
    
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        if (!hasPlusChildViewController) {
            _viewControllers = [viewControllers copy];
        }
        return;
    }
    
    // iOS26+ , 有 plusButton
    if ([self hasPlusButton] && [CYLConstants isLiquidGlassActive]) {
        [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
        NSDictionary *plusInfo =
        @{
            CYLTabBarItemTitle: @"",
            CYLTabBarItemImage :  [UIImage cyl_tabItemPlaceholderImage],
            CYLTabBarItemSelectedImage : [UIImage cyl_tabItemPlaceholderImage]
        };
        _tabBarItemsAttributes = [self alignViewControllers:_tabBarItemsAttributes withPlusButtonViewControllerPlaceholder:plusInfo];
    }
    [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (![self.cyl_tabBar hasPlusButton]) {
            _viewControllers = [viewControllers copy];
            return;
        }
        [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
        BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
        BOOL addedFlag = [CYLPlusChildViewController cyl_plusViewControllerEverAdded];
        BOOL hasPlusChildViewController = [self hasPlusChildViewController] && !isAdded && !addedFlag;
        if (hasPlusChildViewController) {
            [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
            [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:YES];
        } else {
            [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:NSNotFound];
        }
        
//        if (![CYLConstants isLiquidGlassActive]) {
//            if (!hasPlusChildViewController) {
//                _viewControllers = [viewControllers copy];
//            }
//            return;
//        }
        
        if (![self hasPlusButton]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
        
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
        
        // iOS26+ , 有 plusButton
//        if ([self hasPlusButton] && [CYLConstants isLiquidGlassActive]) {
                    if ([self hasPlusButton]) {

            [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
            NSDictionary *plusInfo =
            @{
                CYLTabBarItemTitle: @"",
                CYLTabBarItemImage :  [UIImage cyl_tabItemPlaceholderImage],
                CYLTabBarItemSelectedImage : [UIImage cyl_tabItemPlaceholderImage]
            };
            _tabBarItemsAttributes = [self alignViewControllers:_tabBarItemsAttributes withPlusButtonViewControllerPlaceholder:plusInfo];
        }
        [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
#else
#endif
    } else {}
}

- (void)doubleCheckTabControlAlignWithViewControllers:(NSArray *)viewControllers {
    //FIXME:  to delete
    if (!viewControllers) {
        viewControllers = _viewControllers;
    }
    if ((!_tabBarItemsAttributes) || (_tabBarItemsAttributes.count != viewControllers.count)) {
#if defined(DEBUG) || defined(BETA)
        NSAssert(NO, @" [DEBUG] The count of CYLTabBarControllers is not equal to the count of tabBarItemsAttributes.【Chinese】【仅为调试阶段的提示信息】设置_tabBarItemsAttributes属性时，请确保元素个数与控制器的个数相同，并在方法`-setViewControllers:`之前设置");
#endif
        return;
    }
}

/*!
 ** means ( CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26)
 * useCYL_UIDesignNewCYLTabBar if return YES
 * @return use  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, use  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention //better switch to property CYLTabBarStyleType
 *
 * double-check if to use CYLTabBarStyleTypeLiquidGlass or not:
 * UIDesignCompatibility == FlatDesign , noNeedUIDesignCompatibility == noNeed FlatDesign == LiquidGlass
 * 设置为 NO，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。
 * 由于 UI 兼容模式的命名晦涩， 更优雅直观的方式为 设置 CYLTabBarStyleType，其内部会设置该属性用于决定是否使用扁平设计。
 
 * @return means  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, means  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention better switch to property CYLTabBarStyleType
 */
- (BOOL)noNeedUIDesignCompatibility {
    if (!CYL_IS_IOS_26) {
        return YES;
    }
    BOOL isLiquidGlass = [CYLConstants isLiquidGlassActive];
    //， 这个表示requiresCompatibility，必须使用， 否则iOS26里的兼容模式会错乱。
    if (!isLiquidGlass) {
        return YES;
    }
    BOOL result = _noNeedUIDesignCompatibility && isLiquidGlass;
    return result;
}

- (void)setTabBarStyleType:(CYLTabBarStyleType)tabBarStyleType {
    if (CYL_IS_IOS_27 && CYLTabBarStyleTypeDefault == tabBarStyleType) {
        BOOL result = [[NSBundle.mainBundle objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"] boolValue];
        if (result) {
            tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
        }
    }
    switch (tabBarStyleType) {
        case CYLTabBarStyleTypeDefault:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
            
        case CYLTabBarStyleTypeSystem:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
            
        case CYLTabBarStyleTypeFlatDesign:
            [self setNoNeedUIDesignCompatibility:NO];
            break;
            
        case CYLTabBarStyleTypeLiquidGlass:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
            
        default:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
    }
    _tabBarStyleType = tabBarStyleType;
}


#pragma mark -
#pragma mark - Private Methods

- (void)hideTabBarShadowImageView {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    [self.cyl_tabBar layoutIfNeeded];
    UIImageView *imageView = self.cyl_tabBar.cyl_tabShadowImageView;
    [imageView cyl_setHidden:YES];//iOS13+
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)hasPlusButton {
    return [self.cyl_tabBar hasPlusButton];
}

- (NSUInteger)allItemsInTabBarCount {
    NSUInteger allItemsInTabBar = CYLTabbarItemsCount;
    if ([self hasPlusButton]) {
        allItemsInTabBar += 1;
    }
    return allItemsInTabBar;
}

- (id<UIApplicationDelegate>)appDelegate {
    return [UIApplication sharedApplication].delegate;
}

- (void)reloadTabBarItemsWithAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    _tabBarItemsAttributes = tabBarItemsAttributes;
    self.invokeOnceViewDidLayoutSubViewsBlock = YES;
    self.lottieViewAdded = NO;
    [_lottieURLs removeAllObjects];
    [_lottieSizes removeAllObjects];
    NSInteger index = [self selectedIndex];
    UIViewController *selected = _viewControllers[index];
    UIView *superView = selected.view.superview;
    NSMutableArray<UIViewController *> *viewControllers = [_viewControllers mutableCopy];
    if ([self hasPlusChildViewController]) {
        [viewControllers removeObjectAtIndex:CYLPlusButtonIndex];
    }
    [self setViewControllers:viewControllers];
    [self.view setNeedsLayout];
    self.selectedIndex = index;
    [superView addSubview:selected.view];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 *  仅限 CYLTabBar，在ViewDidLoad中调用
 *  不涉及 CYLTabBarStyleTypeFlatDesign样式（ 会在 setViewControllers 内部设置。）
 */
- (void)setUpDefaultStyleTabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self setUpTabBar:nil];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 *  包含所有样式类型：
 *   CYLTabBar，在ViewDidLoad中调用；因为考虑到PlusButton的逻辑， 涉及坐标计算，还有运行中增删 PlusButton的逻辑，需要涉及重新布局，需要layoutSubviews中进行。故延迟调用。
 *   CYLTabBarStyleTypeFlatDesign样式 会在 setViewControllers 内部调用，调用时机靠前。
 */
- (void)setUpTabBar:(UIView __kindof *)_tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN //Not CYLTabBarStyleTypeFlatDesign
    @try {
        CYLTabBar *tabBar = (CYLTabBar *)_tabBar;
        if (!tabBar) {
            tabBar = [[CYLTabBar alloc] init];
            [tabBar cyl_setTabBarController:self];
            _tabBar = tabBar;
            _cyl_tabBar = tabBar;
        }
        [self cyl_setValue:tabBar forKey:@"tabBar"];
        [self setUpIPADForTabBar:tabBar];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@: reason %@", @(__PRETTY_FUNCTION__), @(__LINE__), @"setUpTabBar failed", exception.reason);
#endif
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/** ipados 18 固定tabbar 在底部 */
- (void)setUpIPADForTabBar:(CYLTabBar *)tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (@available(iOS 18.0, *)) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            self.mode = UITabBarControllerModeTabBar;
            self.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassCompact;
            BOOL setupSuccess = NO;
            [self.view addSubview:tabBar];
            for (UIView *subview in self.view.subviews) {
                NSString *tabContainerClassName = [NSString stringWithFormat:@"%@%@%@", @"_UITab", @"Container", @"View"];
                if ([NSStringFromClass(subview.class) isEqualToString:tabContainerClassName]) {
                    [subview setHidden:YES];
                    setupSuccess = YES;
                }
            }
            if (!setupSuccess) {
                //防止未来类名变动， 暂时不会调用。
                [self.cyl_tabBar removeFromSuperview];
                [self.view addSubview:self.cyl_tabBar];
            }
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)hasPlusChildViewController {
    BOOL hasPlusChildViewControllerBool = NO;
    
    /*!
     *     SEL action = @selector(hasPlusChildViewController);
        if ([self.cyl_tabBar respondsToSelector:action]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             hasPlusChildViewControllerBool = [self.cyl_tabBar performSelector:action];
                                                    )
        }

     */
    CYL_PERFORM_SELECTOR_BOOL(self.cyl_tabBar, hasPlusChildViewController, hasPlusChildViewControllerBool);
    
    return hasPlusChildViewControllerBool;
}

- (BOOL)isPlusViewControllerAdded:(NSArray *)viewControllers {
    BOOL isAdded = [self cyl_isPlusViewControllerAdded:viewControllers];
    return isAdded;
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    //#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    //    CYLFlatDesignTabBar *pureCustomTabBar;
    //    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
    //        pureCustomTabBar = [CYLFlatDesignTabBar new];
    //        [self setUpTabBar:pureCustomTabBar];
    //    }
    //#endif
    
    if (_viewControllers && (_viewControllers.count > 0)) {
        for (UIViewController *viewController in _viewControllers) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
        }
        BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
        BOOL hasPlusChildViewController = [self hasPlusChildViewController] && !isAdded;
        if (hasPlusChildViewController) {
            [CYLPlusChildViewController willMoveToParentViewController:nil];
            [CYLPlusChildViewController.view removeFromSuperview];
            [CYLPlusChildViewController removeFromParentViewController];
        }
    }
    
    if (!viewControllers || viewControllers.count == 0 || ![viewControllers isKindOfClass:[NSArray class]]) {
        for (UIViewController *viewController in _viewControllers) {
            CYLTabBarController *tabBarController = nil;
            [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabBarController:tabBarController];
            [viewController cyl_setTabBarController:tabBarController];
        }
        _viewControllers = nil;
        return;
    }
    
    [self alignTabControlIfNeededWithViewControllers:viewControllers];
    
    CYLTabbarItemsCount = [viewControllers count];
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        _viewControllers = viewControllers;
        return;

    }
    CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

    CYLTabBarItemWidth = (cyl_tabBar.cyl_boundsSize.width - CYLPlusButtonWidth) / (CYLTabbarItemsCount);
    NSUInteger idx = 0;
    for (UIViewController *viewController in _viewControllers) {
        NSString *title = nil;
        id normalImageInfo = nil;
        id selectedImageInfo = nil;
        UIOffset titlePositionAdjustment = UIOffsetZero;
        UIOffset imagePositionAdjustment = UIOffsetZero;
        UIEdgeInsets imageInsets = UIEdgeInsetsZero;
        NSURL *lottieURL = nil;
        NSString *lottieFilePath = nil;
        
        NSValue *lottieSizeValue = nil;
        if (viewController != CYLPlusChildViewController) {
            if (_tabBarItemsAttributes.count > idx) {
                if (@available(iOS 13.0, *)) {
                    //fix https://github.com/ChenYilong/CYLTabBarController/issues/437
                    title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle] ?: @"";
                } else {
                    title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                }
                
                normalImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemImage];
                selectedImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage];
                lottieURL = _tabBarItemsAttributes[idx][CYLTabBarLottieURL];
                lottieFilePath = _tabBarItemsAttributes[idx][CYLTabBarLottieFilePath];
                
                if (!lottieURL) {
                    lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                }
                lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
                
                NSValue *offsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemTitlePositionAdjustment];
                UIOffset offset = [offsetValue UIOffsetValue];
                titlePositionAdjustment = offset;
                
                NSValue *imagePositionAdjustmentoffsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemImagePositionAdjustment];
                UIOffset imagePositionAdjustmentoffset = [imagePositionAdjustmentoffsetValue UIOffsetValue];
                imagePositionAdjustment = imagePositionAdjustmentoffset;
                
                NSValue *insetsValue = _tabBarItemsAttributes[idx][CYLTabBarItemImageInsets];
                UIEdgeInsets insets = [insetsValue UIEdgeInsetsValue];
                imageInsets = insets;
            }
        } else {
            /**如果是CYLPlusChildViewController ，title设置为空字符串，解决把第一个tabbarItem设置成plusButton后，其他的
             tabbarItem会不显示title问题
              见： https://github.com/ChenYilong/CYLTabBarController/issues/563
             **/
            title = @"";
            if ([CYLConstants isLiquidGlassActive] && ([self hasPlusButton])) {
            } else {
                idx--;
            }
        }
        
        [self addOneChildViewController:viewController
                              WithTitle:title
                        normalImageInfo:normalImageInfo
                      selectedImageInfo:selectedImageInfo
                titlePositionAdjustment:titlePositionAdjustment
                imagePositionAdjustment:imagePositionAdjustment
                            imageInsets:imageInsets
                              lottieURL:lottieURL
                        lottieSizeValue:lottieSizeValue
         
        ];
        
        
        //        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        //            //已经在addOneChildViewController 中操作， 这里无需重复处理
        //            // [self addChildViewController:viewController];
        //
        //            if (!viewController.cyl_isPlaceholder && ![viewController cyl_isEqualToViewController:CYLPlusChildViewController]) {
        //#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        //                pureCustomTabBar.delegate = self;
        //                CYLFlatDesignTabBarItem *tabItem = [pureCustomTabBar addItemWithTitle:title
        //                                                                      tabBarItemImage:normalImageInfo
        //                                                              tabBarItemSelectedImage:selectedImageInfo
        //                                                                                index:idx
        //                                                              titlePositionAdjustment:titlePositionAdjustment
        //                                                                          imageInsets:imageInsets
        //                                                                       lottieFilePath:lottieFilePath
        //                                                                      lottieSizeValue:lottieSizeValue];
        //                [viewController cyl_setTabButton:tabItem];
        //                [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabButton:tabItem];
        //#endif
        //
        //            }
        //        }
        [viewController cyl_setTabBarController:self];
        [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabBarController:self];
        [viewController.cyl_getActualBadgeSuperView cyl_setTabBarController:self];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].cyl_getActualBadgeSuperView cyl_setTabBarController:self];
        [viewController.tabBarItem.cyl_getActualBadgeSuperView cyl_setTabBarController:self];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem.cyl_getActualBadgeSuperView cyl_setTabBarController:self];
        
        idx++;
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}

        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        _needsReloadItems = YES;
        __weak __typeof(self) weakSelf = self;
        [viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull childVC, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(self) self = weakSelf;
            if (!self) {
                return;
            }
            [childVC cylflatdesign_setTabBarController:self];
            [self setupChildViewController:childVC idx:idx];;
            [childVC cyl_setTabButton:childVC.cyl_tabBarItem.tabBarButton];
            //TODO: if (_tabBarItemsAttributes.count > idx)
        }];
        CYLTabbarItemsCount = [viewControllers count];
        if (0 == CYLPlusButtonIndex) {
            CYLPlusButtonIndex = [[CYLExternPlusButton class] indexForTabbarItemsCount:CYLTabbarItemsCount];
        }
        [super setViewControllers:viewControllers];
        //    _viewControllers = viewControllers;
        [self alignTabControlIfNeededWithViewControllers:viewControllers];
        if (_needsReloadItems) {
            [self _captureItems];
            [self.cyl_tabBar setItems:self.items];
            _needsReloadItems = NO;
        }
        CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

        cyl_tabBar.selectedItem = self.selectedViewController.cyl_tabBarItem;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)setTintColor:(UIColor *)tintColor {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.f) {
        CYL_DEPRECATED_DECLARATIONS_PUSH
        [self.cyl_tabBar setSelectedImageTintColor:tintColor];
        CYL_DEPRECATED_DECLARATIONS_POP
    }
    self.cyl_tabBar.tintColor = tintColor;
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/**
 *  添加一个子控制器
 *
 *  @param viewController    控制器
 *  @param title             标题
 *  @param normalImageInfo   图片
 *  @param selectedImageInfo 选中图片
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                        WithTitle:(NSString *)title
                  normalImageInfo:(id)normalImageInfo
                selectedImageInfo:(id)selectedImageInfo
          titlePositionAdjustment:(UIOffset)titlePositionAdjustment
          imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(NSURL *)lottieURL
                  lottieSizeValue:(NSValue *)lottieSizeValue {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    viewController.tabBarItem.title = title;
    [viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem.title = title;
    UIImage *normalImage = [UIImage cyl_imageNamed:normalImageInfo];
    viewController.tabBarItem.image = normalImage;
    
    UIImage *selectedImage = [UIImage cyl_imageNamed:selectedImageInfo];;
    viewController.tabBarItem.selectedImage = selectedImage;
    
    UIEdgeInsets insets = self.imageInsets;
    BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets));
    if (shouldCustomizeImageInsets) {
        insets = imageInsets;
    }
    viewController.tabBarItem.imageInsets = insets;
    
    UIOffset offset = self.titlePositionAdjustment;
    BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, titlePositionAdjustment));
    if (shouldCustomizeTitlePositionAdjustment) {
        offset = titlePositionAdjustment;
    }
    viewController.tabBarItem.titlePositionAdjustment = offset;
    
    UIOffset imageoffset = self.imagePositionAdjustment;
    BOOL shouldCustomizeImagePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, imagePositionAdjustment));
    if (shouldCustomizeImagePositionAdjustment) {
        imageoffset = imagePositionAdjustment;
    }
    viewController.tabBarItem.cyl_imagePositionAdjustment = imageoffset;
    
    
    if (lottieURL) {
        [self.lottieURLs addObject:lottieURL];
        [viewController.tabBarItem cyl_setLottieURL:lottieURL];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem cyl_setLottieURL:lottieURL];
        
        NSValue *tureLottieSizeValue = [CYLConstants cyl_getTureLottieSizeValue:lottieSizeValue fromNormalImage:normalImage];
        [self.lottieSizes addObject:tureLottieSizeValue];
        [viewController.tabBarItem cyl_setLottieSizeValue:tureLottieSizeValue];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem cyl_setLottieSizeValue:tureLottieSizeValue];
    }
    [self addChildViewController:viewController];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (UIImage *)getImageFromImageInfo:(id)imageInfo {
    UIImage *image = [UIImage cyl_getImageFromImageInfo:imageInfo];
    return image;
}

#pragma mark -
#pragma mark - KVO Method

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if(context != CYLTabImageViewDefaultOffsetContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == CYLTabImageViewDefaultOffsetContext) {
        CGFloat tabImageViewDefaultOffset = [change[NSKeyValueChangeNewKey] floatValue];
        [self offsetTabBarTabImageViewToFit:tabImageViewDefaultOffset];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
#pragma mark - Observe
    //CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if ([keyPath isEqualToString:@"cyl_tabBar"]) {
            CYLFlatDesignTabBar *oldTabBar = change[NSKeyValueChangeOldKey];
            [oldTabBar removeFromSuperview];
            
            CYLFlatDesignTabBar *newTabBar = change[NSKeyValueChangeNewKey];
            newTabBar.delegate = self;
            newTabBar.items = oldTabBar.items;
            newTabBar.selectedItem = oldTabBar.selectedItem;
            self.cyl_tabBar = newTabBar;
            if (newTabBar) {
                [self.view addSubview:newTabBar];
                [self.view setNeedsLayout];
            }
        }
#else
#endif
    } else {}
}


- (void)offsetTabBarTabImageViewToFit:(CGFloat)tabImageViewDefaultOffset {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, _titlePositionAdjustment));
    BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, _imageInsets));
    if (shouldCustomizeImageInsets) {
        return;
    }
    CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

    NSArray<UITabBarItem *> *tabBarItems = cyl_tabBar.items;
    [tabBarItems enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIEdgeInsets imageInset = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);
        obj.imageInsets = imageInset;
        if (!shouldCustomizeTitlePositionAdjustment) {
            obj.titlePositionAdjustment = UIOffsetMake(0, MAXFLOAT);
        }
    }];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

#pragma mark - delegate
- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController shouldSelect:YES];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController
                                            shouldSelect:(BOOL)shouldSelect {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [[viewController.tabBarItem cyl_tabButton] cyl_setUserInteractionDisabled:!shouldSelect];
    if (!shouldSelect) {
        return;
    }
    UIButton *plusButton = CYLExternPlusButton;
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (![self hasPlusChildViewController]) {
        return;
    }
    BOOL isCurrentViewController = [viewController cyl_isEqualToViewController:CYLPlusChildViewController];
    BOOL shouldConfigureSelectionStatus = (!isCurrentViewController);
    
    if (plusButton.selected) {
        plusButton.selected = NO;
    }
    if (!shouldConfigureSelectionStatus) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (YES == viewController.cyl_isPlaceholder) {
        return NO;
    }
    if (@available(iOS 18.0, *)) {
        
        UIViewController *fromVC = self.selectedViewController;
        
        UIView *fromView = fromVC.view;
        UIView *toView = viewController.view;
        
        if (fromView && toView && fromView != toView) {
            // 自定义过渡效果，用于“隐藏” tabbar 切换时产生的 VC 闪烁
            [UIView transitionFromView:fromView
                                toView:toView
                              duration:0.01   // 几乎立即
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            completion:nil];
        }
    }
    
    [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    return viewController != self.selectedViewController;
}

- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldShowPlatterLiquidLensViewForControl:(UIControl *)control {
    if (![CYLConstants isLiquidGlassActive] || ![tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    if (![self hasPlusChildViewController]) {
        return YES;
    }
    if ([tabBarController.selectedViewController isEqual:CYLPlusChildViewController] && ![tabBarController.tabBar isPlusButtonLayoutCentered]) {
        return NO;
    }
    return YES;
}

- (void)tabBarController:(CYLTabBarController *)tabBarController beginShowPlatterLiquidLensViewForControl:(UIControl *)control {
    if (![CYLConstants isLiquidGlassActive] || ![tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    SEL action = @selector(tabBarController:shouldShowPlatterLiquidLensViewForControl:);
    BOOL shouldShowPlatterLiquidLensView = YES;
    if ([self.delegate respondsToSelector:action]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         shouldShowPlatterLiquidLensView = [self.delegate performSelector:action withObject:tabBarController withObject:control];
         )
    }
    if (shouldShowPlatterLiquidLensView) {
        [tabBarController.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:NO];
        tabBarController.tabBar.liquidGlassContinuousGestureRecognizer.enabled = YES;
        tabBarController.tabBar.liquidGlassLongGestureRecognizer.enabled = YES;
    } else {
        [tabBarController.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:YES];
        tabBarController.tabBar.liquidGlassContinuousGestureRecognizer.enabled = NO;
        tabBarController.tabBar.liquidGlassLongGestureRecognizer.enabled = NO;
    }
}

- (BOOL)isLottieEnabled {
    return [CYLConstants isLottieEnabledFromlottieURLs:self.lottieURLs tabBarItemsAttributes:self.tabBarItemsAttributes];
}

- (void)didSelectControl:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    SEL actin = @selector(tabBarController:didSelectControl:);
    
    BOOL shouldSelectViewController =  YES;
    @try {
        shouldSelectViewController = (!control.cyl_userInteractionDisabled) && (!control.hidden) ;
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    UIControl *contentControl = control;
    UIControl *selectedContentControl = nil;
    if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:control];
        if (![control cyl_isPlusControl]) {
            [self.cyl_tabBar cyl_setSelectedControl:selectedContentControl  ?: contentControl];
        } else {
            [self.cyl_tabBar cyl_setSelectedControl:CYLExternPlusButton];
        }
        
        if (shouldSelectViewController) {
            //TODO:  pure tabbar
            CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

            [cyl_tabBar.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.selected = NO;
            }];
            [cyl_tabBar.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.selected = NO;
            }];
            contentControl.selected = YES;
            selectedContentControl.selected = YES;
            //非液态玻璃 与 液态玻璃逻辑共用，Lottie播放逻辑都在 tabChangedToSelectedIndex 中。
        }
    }
    UIControl *control_ = control ?: self.selectedViewController.cyl_tabButton;
    [self tabBarController:self beginShowPlatterLiquidLensViewForControl:control_];
    
    if (shouldSelectViewController){
        if ([self.delegate respondsToSelector:actin]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             [self.delegate performSelector:actin withObject:self withObject:control_];
             );
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self addLottieImageWithControl:control lottieURL:nil lottieSizeValue:nil animation:animation];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)addLottieImageWithControl:(UIControl *)control
                        lottieURL:(NSURL *)lottieURL
                  lottieSizeValue:(NSValue *)theLottieSizeValue
                        animation:(BOOL)animation {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self addLottieImageWithControl:control
                          lottieURL:lottieURL
                    lottieSizeValue:theLottieSizeValue
                          animation:animation
                    defaultSelected:NO];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

//TODO:  selected content, double add
- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if ([CYLConstants isLiquidGlassActive]) {
        [self addLottieImageWithControl:control lottieURL:nil lottieSizeValue:nil animation:animation defaultSelected:defaultSelected];
    } else {
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

        NSUInteger index = [cyl_tabBar.cyl_subTabBarButtonsWithoutPlusButton indexOfObject:control];
        if (NSNotFound == index) {
            return;
        }
        if (control.cyl_isPlusButton) {
            return;
        }
        NSURL *lottieURL = self.lottieURLs[index];
        NSValue *lottieSizeValue = self.lottieSizes[index];
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode];
        if (animation) {
            [self.cyl_tabBar cyl_animationLottieImageWithSelectedControl:control lottieURL:lottieURL size:lottieSize defaultSelected:defaultSelected contentMode:self.lottieAnimationViewContentMode];
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

//TODO:  selected content, double add
- (void)addLottieImageWithControl:(UIControl *)control
                        lottieURL:(NSURL *)theLottieURL
                  lottieSizeValue:(NSValue *)theLottieSizeValue
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    UIControl *contentControl = control;
    UIControl *selectedContentControl;
    //FIXME:  必须为 cyl_subTabBarButtonsWithoutPlusButton （不能 cyl_subTabBarButtons）否则Lottie选中动画不显示，因为Lottie文件数量与tabbaritems 的数量少一个。
    //TODO: selectedContentControl不对，plusButton 下一个会添加失败，添加的是 plusButton对应的lottie， 顺延了。
    if (control.cyl_isPlusControl) {
        return;
    }
    
    NSURL *lottieURL = theLottieURL;
    NSValue *lottieSizeValue = theLottieSizeValue;
    if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        
        @try {
            CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
            NSUInteger index = [cyl_tabBar.cyl_subTabBarButtons indexOfObject:contentControl];
            if (NSNotFound != index) {
                if (!lottieURL) {
                    //TODO:lottieURLs 与 Control对应的index不一致， 因为 lottieURLs 可能会少一个 plusButton 对应的。如何能够不通过index就获取到 lottieURLs ?
                    lottieURL = self.lottieURLs[index];
                }
                
                if (!lottieSizeValue) {
                    lottieSizeValue = self.lottieSizes[index];
                }
            }
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    }
    
    CGSize lottieSize = [lottieSizeValue CGSizeValue];
    [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode];
    
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:contentControl];
    
    if (selectedContentControl) {
        [selectedContentControl cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode];
    }
    
    if (animation) {
        [self.cyl_tabBar cyl_animationLottieImageWithSelectedControl:contentControl
                                                           lottieURL:lottieURL
                                                                size:lottieSize
                                                     defaultSelected:defaultSelected
                                                         contentMode:self.lottieAnimationViewContentMode];
        if (selectedContentControl) {
            [self.cyl_tabBar cyl_animationLottieImageWithSelectedControl:selectedContentControl
                                                               lottieURL:lottieURL
                                                                    size:lottieSize
                                                         defaultSelected:defaultSelected
                                                             contentMode:self.lottieAnimationViewContentMode];
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

#pragma mark -
#pragma mark - getter & setter
// MARK: getter & setter

- (UIView __kindof *)cyl_tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
if (_cyl_tabBar && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            _cyl_tabBar = nil;
        }
#else
#endif
    
    if (!_cyl_tabBar) {
        // 处理tabBar，使用自定义 tabBar 并添加 发布按钮。仅限 CYLTabBar，CYLTabBarStyleTypeFlatDesign 会在 setViewControllers 内部设置。
        [self setUpDefaultStyleTabBar];
        // KVO注册监听
        if (!self.isObservingTabImageViewDefaultOffset) {
            @try {
                //CYLTabBarController may crash when deallocating
                [_cyl_tabBar addObserver:self forKeyPath:@"tabImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:CYLTabImageViewDefaultOffsetContext];
            } @catch(NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
            }
            self.observingTabImageViewDefaultOffset = YES;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarStyleTypeDidChangeNotification object:self];
        
    }
    return _cyl_tabBar;
    //    _cyl_tabBar = self.tabBar;
} else {/**  CYLTabBarStyleTypeFlatDesign*/

}
/*!
 *添加自定义的 CYLFlatDesignTabBar
 */


    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (_cyl_tabBar && [_cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            _cyl_tabBar = nil;
        }
        if (!_cyl_tabBar) {
            // 通过KVC 换成 CYLFlatDesignTabBarHideTabBar 控制系统 UITabBar 永久隐藏
            CYLFlatDesignTabBarHideTabBar *tabBar = [[CYLFlatDesignTabBarHideTabBar alloc] init];
            [self cyl_setValue:tabBar forKey:@"tabBar"];
            
            CYLFlatDesignTabBar *flatDesignTabBar = [[CYLFlatDesignTabBar alloc] initWithFrame:self.tabBarFrame];
            flatDesignTabBar.delegate = self;
            _cyl_tabBar = (UIView *)flatDesignTabBar;
            [self.view addSubview:_cyl_tabBar];
            [self addObserver:self forKeyPath:@"cyl_tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
            
            self.cyl_tabBarHidden = NO;
            [self setTabBarHidden:NO];
            [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarStyleTypeDidChangeNotification object:self];
        }

#else
#endif
    } else {}
    
    return _cyl_tabBar;
}


//- (void)cyl_setTabBar:(CYLTabBar *)cyl_tabBar {
//    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
//    self.tabBar = cyl_tabBar;
//} else {/**  CYLTabBarStyleTypeFlatDesign*/}
//}

- (NSString *)context {
    return self.cyl_context;
}

- (void)setContext:(NSString *)context {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    self.cyl_context = context;
    @try {
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
        cyl_tabBar.context = self.cyl_context;
        [cyl_tabBar setValue:self.cyl_context forKey:@"context"];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        //fix [bug]: #556
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@，[DEBUG] Please ensure that your custom CYLTabBarController subclass calls `super.viewDidLoad()` in the `viewDidLoad` method, and that this call is placed on the last line of the `viewDidLoad` method; otherwise, CYLTabBar KVC settings will fail.【DEBUG】请确保你的自定义 CYLTabBarController 的子类，在viewDidLoad中调用了 `super.viewDidLoad()`，且在viewDidLoad方法中最后一行调用，否则 CYLTabBar KVC 设置会失败。", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}


    //CYLTabBarStyleTypeFlatDesign
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        self.cyl_context = context;
        @try {
            CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

            cyl_tabBar.context = self.cyl_context;
            [cyl_tabBar setValue:self.cyl_context forKey:@"context"];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            //fix [bug]: #556
            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@，【DEBUG】请确保你的自定义 CYLTabBarController 的子类，在viewDidLoad中调用了 `super.viewDidLoad()`，且在viewDidLoad方法中最后一行调用，否则 CYLTabBar KVC 设置会失败。", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
        
        if ([[CYLExternPlusButton class] respondsToSelector:@selector(tabBarContext)]) {
            NSString *plusButtonContext = [[CYLExternPlusButton class] performSelector:@selector(tabBarContext)];
            if (plusButtonContext && ![self.cyl_context isEqualToString:plusButtonContext]) {
                // contexts differ; remove PlusButton
                if ([[CYLExternPlusButton class] respondsToSelector:@selector(removePlusButton)]) {
                    [[CYLExternPlusButton class] performSelector:@selector(removePlusButton)];
                }
            }
        }
#else
#endif
        
    } else {}
}

/**
 *  lazy load lottieURLs
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)lottieURLs {
    if (_lottieURLs == nil) {
        NSMutableArray *lottieURLs = [[NSMutableArray alloc] init];
        _lottieURLs = lottieURLs;
    }
    return _lottieURLs;
}

/**
 *  lazy load lottieSizes
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)lottieSizes {
    if (_lottieSizes == nil) {
        NSMutableArray *lottieSizes = [[NSMutableArray alloc] init];
        _lottieSizes = lottieSizes;
    }
    return _lottieSizes;
}

- (nonnull UIWindow *)rootWindow {
    return CYLGetRootWindow();
}
- (void)setTabBarHeight:(CGFloat)tabBarHeight {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    _tabBarHeight = tabBarHeight;
    CYLTabBarHeight = tabBarHeight;
} else {/**  CYLTabBarStyleTypeFlatDesign*/}

        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        if (_tabBarHeight != tabBarHeight) {
            _tabBarHeight = tabBarHeight;
            
            [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
            [self.view setNeedsLayout];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (CGFloat)tabBarHeight {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        if (0 == _tabBarHeight) {
            _tabBarHeight = CYLTabBarHeight;
        }
        return _tabBarHeight;
        
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return _tabBarHeight; }
    if (0 == _tabBarHeight) {
        _tabBarHeight = CYLTabBarHeight;
    }
    return _tabBarHeight;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return _tabBarHeight;
}

//#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
//- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItemAt:(NSInteger)index {
//    [self setSelectedIndex:index];
//    if (tabBar.tabBarItems && tabBar.tabBarItems.count > index) {
//        [self tabChangedToSelectedIndex:index
//                         viewController:self.selectedViewController
//                                       control:tabBar.tabBarItems[index]];
//    }
//}
//#endif


/**
 *  lazy load items
 *
 *  @return NSMutableArray<CYLFlatDesignTabBarItem *>
 */
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (NSMutableArray<CYLFlatDesignTabBarItem *> *)items {
    if (_items == nil) {
        NSMutableArray<CYLFlatDesignTabBarItem *> *items = [[NSMutableArray<CYLFlatDesignTabBarItem *> alloc] init];
        _items = items;
    }
    return _items;
}
#else
#endif

#pragma mark - Override selectedViewController (User initiated)

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    if (selectedViewController.cyl_isPlaceholder) { return; }

    if (self.selectedViewController == selectedViewController) { return; }

   NSUInteger indexOfSelectedViewController = [self.childViewControllers indexOfObject:selectedViewController];
    if (NSNotFound == indexOfSelectedViewController) { return; }
    [super setSelectedViewController:selectedViewController];

    _selectedViewController = selectedViewController;
//           NSUInteger indexOfSelectedViewController = [self.childViewControllers indexOfObject:selectedViewController];
//            if (NSNotFound == indexOfSelectedViewController) { return; }
    
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    //必须调用父类逻辑。
//    _selectedViewController = selectedViewController;
//
//    [super setSelectedViewController:selectedViewController];
    // Fix: #574 解决iOS15 扁平风格， 有时候TabBar会变透明的问题
    if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.0") && ![CYLConstants isLiquidGlassActive]) {
        if (nil == [UITabBar appearance].backgroundImage) {
            @try {
                //因为非核心功能， 仅为部分版本的细节修复， 所以用try catch 防止异常， 防止影响主要功能。
                if (self.cyl_tabBar.cyl_tabBackgroundView && self.cyl_tabBar.cyl_tabBackgroundView.cyl_tabEffectView) {
                    self.cyl_tabBar.cyl_tabBackgroundView.cyl_tabEffectView.alpha = 1;
                }
                if (self.cyl_tabBar.cyl_tabShadowImageView && (self.cyl_tabBar.cyl_tabShadowImageView.subviews.count > 0)) {
                    self.cyl_tabBar.cyl_tabShadowImageView.subviews.firstObject.alpha = 1;
                }
            } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
            }
        }
    }
    
    if (![CYLConstants isLiquidGlassActive]) {
        return;
    }
    //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
    
    // 用户点击 tab 时会触发 //showing initial vc for every tab :)
    UIControl *control = selectedViewController.cyl_tabButton;
    if ([selectedViewController isEqual:CYLPlusChildViewController]) {
        CYLExternPlusButton.selected = YES;
        [self tabChangedToSelectedIndex:CYLPlusButtonIndex
                         viewController:selectedViewController
                                control:CYLExternPlusButton];
    } else {
        [self tabChangedToSelectedIndex:self.selectedIndex
                         viewController:selectedViewController
                                control:control];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}


        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
            
            NSInteger selectedIndex = [self.viewControllers indexOfObject:selectedViewController];
            //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
            
            // 用户点击 tab 时会触发 //showing initial vc for every tab :)
            //        UIControl *control = selectedViewController.cyl_tabButton;
            if ([selectedViewController isEqual:CYLPlusChildViewController]) {
                CYLExternPlusButton.selected = YES;
            } else {
            }
            
            [self tabChangedToSelectedIndex:selectedIndex viewController:selectedViewController selectedItem:nil];
        
        [self _updateBottomBarShowHideIfNeeded];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
#pragma mark - Override selectedIndex (Programmatic changes)

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [super setSelectedIndex:selectedIndex];
    
    //#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    //
    //    if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
    //        CYLFlatDesignTabBar *tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
    //        [tabBar setSelectedIndex:selectedIndex];
    //    }
    //#endif
    
    if (![CYLConstants isLiquidGlassActive]) {
        return;
    }
    //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
    // 代码切换 tab 时会触发
    [self tabChangedToSelectedIndex:selectedIndex viewController:nil control:nil];
    
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (self.selectedIndex != selectedIndex) {
            _selectedIndex = selectedIndex;
            [super setSelectedIndex:selectedIndex];
            if (selectedIndex < 0 || selectedIndex >= self.viewControllers.count) { return; }
            if (_needsReloadItems) {
                [self _captureItems];
                [self.cyl_tabBar setItems:self.items];
                _needsReloadItems = NO;
            }
            //TODO:  这里避免使用selectedViewController，因为 self.viewControllers 被经过PlusButton补充，
            //        self.cyl_tabBar.selectedItem = selectedItem;
            [self tabChangedToSelectedIndex:selectedIndex viewController:nil selectedItem:nil];
            
        }
        [self _updateBottomBarShowHideIfNeeded];
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
}

- (CGSize)visiableTabBarSize {
    return self.cyl_tabBarController.tabBar.cyl_boundsSize;
}

/*!
 * 三个地方 ， 都要调用：
 *  选中状态下的重新点击，（iOS26 需要在手势代理方法中进行hook追加该方法）
 *  用户切换index时
 *  代码切换index 时。
 **/
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                     selectedItem:(CYLFlatDesignTabBarItem *)selectedItem {
    
    CYL_IF_FLATDESIGN_BEGIN
    
    //扁平样式可使用
    if (![self.tabBar isKindOfClass:[UITabBar class]] && ![self.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        return;
    }
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (!selectedItem) {
        selectedItem = viewController.cyl_tabBarItem;
    }
    UIControl *control = viewController.cyl_tabButton;
    //    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    //    BOOL isLottieEnabled = [self isLottieEnabled];
    
    //TODO:  setSelectedIndex 这里避免使用selectedViewController，因为 self.viewControllers 被经过PlusButton补充，
    
    if (!self.items || self.items.count == 0) {
        return;
    }
    if ([self _showsMoreNavigationController]) {
        NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
        if (selectedIndex >= moreIndex) {
            selectedItem = self.moreNavigationController.cyl_tabBarItem;
        } else {
            selectedItem = self.items[selectedIndex];
        }
    } else {
        selectedItem = self.items[selectedIndex];
    }
    
    CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

    cyl_tabBar.selectedItem = selectedItem;
    CYL_IF_FLATDESIGN_END
}
#else
#endif

#pragma mark -
#pragma mark - 状态栏
// MARK: 状态栏

- (UIViewController *)childViewControllerForStatusBarStyle {
    UIViewController *childViewController = self.selectedViewController;
    
    do {
        if (!childViewController) {
            childViewController = _viewControllers.lastObject;
            break;
        }
        if (!childViewController) {
            childViewController = CYLGetRootViewController();

            break;
        }
    } while (false); // same as : 0, NO
    if (CYLTabBarStyleTypeFlatDesign == _tabBarStyleType) {     //CYLTabBarStyleTypeFlatDesign
        
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        return childViewController;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
    return childViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;
    
   
//    self.topViewController;
//    self.scene;
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController; }
        return childViewController;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return childViewController;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;

        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController.preferredStatusBarUpdateAnimation; }
        return childViewController.preferredStatusBarUpdateAnimation;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    return childViewController.preferredStatusBarUpdateAnimation;
}

/// HomeIndicator
- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;

        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController; }
        return childViewController;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    return childViewController;
}


#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (!CGSizeEqualToSize(self.view.bounds.size, size)) {
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
                [self.selectedViewController.view setNeedsLayout];
                [self.selectedViewController.view layoutIfNeeded];
            } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


#pragma mark - TabBarItem Action
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

- (void)_cyltabBarItemClicked:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
        
        NSInteger index = [cyl_tabBar.items indexOfObject:tabBarItem];
        
        UIViewController *didSelectViewController = self.viewControllers[index];
        if (didSelectViewController.cyl_isPlaceholder) {
            return;
        }
        if (didSelectViewController.cyl_getViewControllerInsteadOfNavigationController.cyl_isPlaceholder) {
            return;
        }
        SEL actin = @selector(tabBarController:didSelectControl:);
        if ([self.delegate respondsToSelector:actin]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             [self.delegate performSelector:actin withObject:self withObject:tabBarItem.tabBarButton];
             )
            
        }
        if ([self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
            BOOL sholudSelect = [self.delegate tabBarController:self shouldSelectViewController:self.viewControllers[index]];
            if (!sholudSelect) {
                return;
            }
        }
        [self setSelectedViewController:didSelectViewController];
        //    [self setSelectedIndex:index];
        [self updateSelectionStatusIfNeededForShouldSelectViewController:didSelectViewController shouldSelect:YES];
        //    [self tabChangedToSelectedIndex:index viewController:self.viewControllers[index] selectedItem:tabBarItem];
        if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
            [self.delegate tabBarController:self didSelectViewController:didSelectViewController];
        }
        
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
#else
#endif
- (void)updateSelectionStatusIfNeededForShouldSelectViewController:(UIViewController *)viewController
                                                      shouldSelect:(BOOL)shouldSelect {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        //    [[viewController.tabBarItem cyl_tabButton] cyl_setUserInteractionDisabled:!shouldSelect];
        if (!shouldSelect) {
            return;
        }
        UIButton *plusButton = CYLExternPlusButton;
        if (!viewController) {
            viewController = self.selectedViewController;
        }
        if (![self hasPlusChildViewController]) {
            return;
        }
        
        BOOL isCurrentViewController = [viewController cyl_isEqualToViewController:CYLPlusChildViewController];
        
        if (isCurrentViewController) {
            [plusButton setSelected:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
        } else {
            [plusButton setSelected:NO];
        }
        
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

#pragma mark - UINavigationControllerExtensionDelegate
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
              navigationBarDidChangeHeight:(CGFloat)height {
    
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                    didBeginTransitionFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                                 operation:(UINavigationControllerOperation)operation {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        // 转场或pop手势返回时禁止用户交互
        self.view.userInteractionEnabled = NO;
        UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
        additionalSafeAreaInsets.bottom = self.tabBarHeight;
        [UIView performWithoutAnimation:^{
            self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            if ([self _showsMoreNavigationController] && self.moreNavigationController != self.selectedViewController) {
                self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            }
        }];
        
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                  didUpdateInteractiveFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                           percentComplete:(CGFloat)percentComplete {
    //     NSLog(@"pop手势返回：%.2f", percentComplete);
}


- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                  didUpdateInteractiveFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                      popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer {
    
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                     willEndTransitionFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                                 operation:(UINavigationControllerOperation)operation
                                 cancelled:(BOOL)cancelled {

        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
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
            if ([self _showsMoreNavigationController] && self.moreNavigationController != self.selectedViewController) {
                self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            }
        }];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                      didEndTransitionFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                                 operation:(UINavigationControllerOperation)operation
                                 cancelled:(BOOL)cancelled {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
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
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

#pragma mark - Private

- (CGRect)tabBarFrame {
    CGRect tabBarFrame = _cyl_tabBar.frame;
    CGFloat tabBarHeight = self.tabBarHeight + self.view.safeAreaInsets.bottom;
    tabBarFrame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
    return tabBarFrame;
}

- (BOOL)_showsMoreNavigationController {
    // 用 self.viewControllers.count > 5 判断行不行？
    BOOL _showsMoreNavigationController = NO;
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if ([_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {     return _showsMoreNavigationController; }
        
        _showsMoreNavigationController = (self.viewControllers.count > 5) || [self.tabBar.items containsObject:self.moreNavigationController.tabBarItem] ;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return _showsMoreNavigationController;
}

- (void)_captureItems {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        BOOL hasMoreItem = [self _showsMoreNavigationController];
        if (self.moreNavigationController) {
            hasMoreItem = [self.tabBar.items containsObject:self.moreNavigationController.tabBarItem];
        }
        NSMutableArray *items = [NSMutableArray array];
        if (hasMoreItem) {
            for (NSInteger i = 0; i < self.tabBar.items.count - 1; i++) {
                UIViewController *viewController = self.viewControllers[i];
                if (!viewController.cyl_tabBarItem) {
                    continue;
                }
                [viewController cylflatdesign_setTabBarController:self];
                [items addObject:viewController.cyl_tabBarItem];
                [viewController cyl_setTabButton:viewController.cyl_tabBarItem.tabBarButton];
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
            
            for (NSInteger i = 0; i < self.viewControllers.count; i++) {
                
                UIViewController *viewController = self.viewControllers[i];
                CYLFlatDesignTabBarItem *cyl_tabBarItem = viewController.cyl_tabBarItem;
                if (!cyl_tabBarItem) {
                    continue;
                }
                [viewController cylflatdesign_setTabBarController:self];
                cyl_tabBarItem.index = i;
                [items addObject:cyl_tabBarItem];
                [viewController cyl_setTabButton:cyl_tabBarItem.tabBarButton];
            }
            
            
        }
        if ((0 == self.viewControllers.count) || (0 == items.count)) {
            return;
        }
        [self _syncSystemItems];
        self.items = items;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)_syncSystemItems {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        for (UIViewController *viewController in self.viewControllers) {
            viewController.tabBarItem.title = viewController.cyl_tabBarItem.title;
            
            viewController.tabBarItem.image = viewController.cyl_tabBarItem.image;
            //        viewController.tabBarItem.badgeValue = viewController.cyl_badge.text;
            //        viewController.tabBarItem.badgeColor = viewController.cyl_tabBarItem.badgeColor;
            viewController.tabBarItem.titlePositionAdjustment = viewController.cyl_tabBarItem.titlePositionAdjustment;
            [viewController.tabBarItem setTitleTextAttributes:[viewController.cyl_tabBarItem titleTextAttributesForState:UIControlStateNormal] forState:UIControlStateNormal];
            [viewController.tabBarItem setTitleTextAttributes:[viewController.cyl_tabBarItem titleTextAttributesForState:UIControlStateSelected] forState:UIControlStateSelected];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)_shouldShowsBottomBar {
    BOOL showsTabBar = YES;
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return showsTabBar; }
        
        if (self.isTabBarHidden) {
            showsTabBar = NO;
        } else {
            showsTabBar = [self _checkHidesBottomBarWhenPushed];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
    return showsTabBar;
}

- (void)_updateBottomBarShowHideIfNeeded {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        BOOL showsTabBar = [self _shouldShowsBottomBar];
        if (!_tabBarIsAnimating) {
            self.cyl_tabBar.hidden = !showsTabBar;
        }
        [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)_addParallaxOverlayViewToViewController:(UIViewController *)viewController {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
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
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)_updateAdditionalSafeAreaInsetsWithAnimated:(BOOL)animated {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        UIViewController *selectedViewController = self.selectedViewController;
        UIEdgeInsets additionalSafeAreaInsets = selectedViewController.additionalSafeAreaInsets;
        additionalSafeAreaInsets.bottom = self.cyl_tabBar.hidden ? 0 : self.tabBarHeight;
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
                if ([self _showsMoreNavigationController] && self.moreNavigationController != selectedViewController) {
                    self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
                }
            }];
        } else {
            selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            if ([self _showsMoreNavigationController] && self.moreNavigationController != selectedViewController) {
                self.moreNavigationController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            }
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
    
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

- (void)changeItem:(CYLFlatDesignTabBarItem *)item toItem:(CYLFlatDesignTabBarItem *)toItem {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        NSInteger index = [self.items indexOfObject:item];
        if (index == NSNotFound) {
            return;
        }
        [self.items replaceObjectAtIndex:index withObject:toItem];
        [self.cyl_tabBar setItems:self.items];

    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
#else
#endif
    
@end

@implementation NSObject (CYLTabBarControllerReferenceExtension)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController {
    id __weak weakObject = tabBarController;
    id (^block)(void) = ^{ return weakObject; };
    objc_setAssociatedObject(self, @selector(cyl_tabBarController),
                             block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//TODO: 更新实现，多实例场景下进行栈操作，弹出最新一个。
- (CYLTabBarController *)cyl_tabBarController {
    CYLTabBarController *tabBarController;
    id (^block)(void) = objc_getAssociatedObject(self, @selector(cyl_tabBarController));
    tabBarController = (block ? block() : nil);
    if (tabBarController && [tabBarController cyl_isSystemStyleTabBar]) {
        return tabBarController;
    }
    if ([self isKindOfClass:[UIViewController class]] && [(UIViewController *)self parentViewController]) {
        tabBarController = [[(UIViewController *)self parentViewController] cyl_tabBarController];
        if ([tabBarController cyl_isSystemStyleTabBar]) {
            return tabBarController;
        }
    }
    
    UIViewController *rootViewController = [CYLGetRootViewController() cyl_getViewControllerInsteadOfNavigationController];;
    if ([rootViewController cyl_isSystemStyleTabBar]) {
        tabBarController = (CYLTabBarController *)rootViewController;
    }
    return tabBarController;
}
#pragma mark - @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)
// MARK: @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)


- (void)cylflatdesign_setTabBarController:(UIViewController *)tabBarController {
    UIViewController *tabBarController_ = tabBarController;
    objc_setAssociatedObject(self, @selector(cylflatdesign_tabBarController), tabBarController_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return;
    }
    if (referenceViewController.cyl_getViewControllerInsteadOfNavigationController) {
        objc_setAssociatedObject(referenceViewController.cyl_getViewControllerInsteadOfNavigationController, @selector(cylflatdesign_tabBarController), (tabBarController_), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    /*!
     *     if ((![tabBarController isKindOfClass:[CYLFlatDesignUIViewController class]]) && (![tabBarController.cyl_getViewControllerInsteadOfNavigationController isKindOfClass:[CYLFlatDesignUIViewController class]]))  {
     return;
     }
     CYLFlatDesignUIViewController *flatDesignTabViewController = nil;
     if ([tabBarController isKindOfClass:[CYLFlatDesignUIViewController class]]) {
     flatDesignTabViewController = (CYLFlatDesignUIViewController *)tabBarController;
     } else if ([tabBarController.cyl_getViewControllerInsteadOfNavigationController isKindOfClass:[CYLFlatDesignUIViewController class]]) {
     flatDesignTabViewController = (CYLFlatDesignUIViewController *)tabBarController.cyl_getViewControllerInsteadOfNavigationController;
     }
     [flatDesignTabViewController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull childViewController, NSUInteger idx, BOOL * _Nonnull stop) {
     objc_setAssociatedObject(childViewController, @selector(cylflatdesign_tabBarController), tabBarController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
     objc_setAssociatedObject(childViewController.cyl_getViewControllerInsteadOfNavigationController, @selector(cylflatdesign_tabBarController), tabBarController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
     }];
     *
     */
}

- (UIViewController __kindof *)cylflatdesign_tabBarController {
    UIViewController *viewController = objc_getAssociatedObject(self, @selector(cylflatdesign_tabBarController));
    if (viewController) {
        return viewController;
    }
    /*!
     *     viewController = [self cyl_nearestParentViewControllerThatIsKindOf:[CYLFlatDesignUIViewController class]];
     if (viewController) {
     return viewController;
     }
     */
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    
    UIViewController *flatDesignTabBarController = referenceViewController.tabBarController;
    
    if ([flatDesignTabBarController cyl_isFlatDesignStyleTabBar]) {
        viewController = flatDesignTabBarController;
    }
    flatDesignTabBarController = referenceViewController.cyl_getViewControllerInsteadOfNavigationController.tabBarController;
    
    if ([flatDesignTabBarController cyl_isFlatDesignStyleTabBar]) {
        viewController = flatDesignTabBarController;
    }
    flatDesignTabBarController = [self cyl_nearestParentViewControllerThatIsFlatDesignStyleTabBar];
    
    if ([flatDesignTabBarController cyl_isFlatDesignStyleTabBar]) {
        viewController = flatDesignTabBarController;
    }
    
    return viewController;
}


- (UIViewController __kindof *)cyl_nearestParentViewControllerThatIsFlatDesignStyleTabBar {
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    UIViewController *controller = referenceViewController.parentViewController;
    while (controller && ![controller cyl_isFlatDesignStyleTabBar]) {
        controller = controller.parentViewController;
    }
    
    if (controller && [controller cyl_isFlatDesignStyleTabBar]) {
        return (UIViewController *)controller;
    }
    return nil;
}

/*!
 * - (CYLFlatDesignUIViewController *)cyl_nearestParentViewControllerThatIsKindOf:(Class)c {
 UIViewController *controller = self.parentViewController;
 while (controller && ![controller isKindOfClass:c]) {
 controller = controller.parentViewController;
 }
 if (controller && [controller isKindOfClass:c]) {
 return (CYLFlatDesignUIViewController *)controller;
 }
 return nil;
 }
 */
- (UIViewController __kindof *)cyl_nearestParentViewControllerThatIsKindOf:(Class)c {
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    UIViewController *controller = referenceViewController.parentViewController;
    while (controller && ![controller isKindOfClass:c]) {
        controller = controller.parentViewController;
    }
    
    if (controller && [controller isKindOfClass:c]) {
        return (UIViewController *)controller;
    }
    return nil;
}
#endif

@end
