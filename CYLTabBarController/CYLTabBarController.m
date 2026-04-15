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
#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif
#import "CYLFlatDesignTabBar.h"

NSString *const CYLTabBarItemTitle = @"CYLTabBarItemTitle";
NSString *const CYLTabBarItemImage = @"CYLTabBarItemImage";
NSString *const CYLTabBarItemSelectedImage = @"CYLTabBarItemSelectedImage";
NSString *const CYLTabBarItemImageInsets = @"CYLTabBarItemImageInsets";
NSString *const CYLTabBarItemTitlePositionAdjustment = @"CYLTabBarItemTitlePositionAdjustment";
NSString *const CYLTabBarLottieURL = @"CYLTabBarLottieURL";
NSString *const CYLTabBarLottieSize = @"CYLTabBarLottieSize";

NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
CGFloat CYLTabBarHeight = 49.0f;

NSString *const CYLTabBarItemWidthDidChangeNotification = @"CYLTabBarItemWidthDidChangeNotification";
static void * const CYLTabImageViewDefaultOffsetContext = (void*)&CYLTabImageViewDefaultOffsetContext;
//static void * const CYLTabBarControllerVisiableItemsCountContext = (void*)&CYLTabBarControllerVisiableItemsCountContext;

@interface CYLTabBarController () <UITabBarControllerDelegate>

@property (nonatomic, assign, getter=isObservingTabImageViewDefaultOffset) BOOL observingTabImageViewDefaultOffset;
@property (nonatomic, assign, getter=shouldInvokeOnceViewDidLayoutSubViewsBlock) BOOL invokeOnceViewDidLayoutSubViewsBlock;
@property (nonatomic, strong) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong) NSMutableArray *lottieSizes;
@property (nonatomic, assign, getter=isLottieViewAdded) BOOL lottieViewAdded;
@property (nonatomic, strong) UIImage *tabItemPlaceholderImage;

@end

@implementation CYLTabBarController

@synthesize viewControllers = _viewControllers;


#pragma mark -
#pragma mark - Life Cycle

- (void)viewDidLoad {
    if (@available(iOS 26.0, *)) {
        self.tabBarMinimizeBehavior = UITabBarMinimizeBehaviorOnScrollDown;
    } else {
        // Fallback on earlier versions
    }
    
    [super viewDidLoad];
    if (CYL_IS_IPHONE_X) {
        self.tabBarHeight = 83;
    }
    
    //    if (CYL_NoNeed_UIDesignRequiresCompatibility) {
    //        self.tabBar.translucent = NO;
    //    }
    // 处理tabBar，使用自定义 tabBar 添加 发布按钮
    [self setUpTabBar];
    // KVO注册监听
    if (!self.isObservingTabImageViewDefaultOffset) {
        @try {
            //CYLTabBarController may crash when deallocating
            [self.tabBar addObserver:self forKeyPath:@"tabImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:CYLTabImageViewDefaultOffsetContext];
        } @catch(NSException *e) { }
        self.observingTabImageViewDefaultOffset = YES;
    }
}

- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                          control:(UIControl *)control {
    //CYL_UIDesignClassicCYLTabBar
//    if (![self.tabBar isKindOfClass:[CYLTabBar class]]) {
//        return;
//    }
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (!control) {
        control = [viewController cyl_getViewControllerInsteadOfNavigationController].cyl_tabButton;
    }
    // Ensure we do not pass nil to a nonnull parameter
    UIViewController *targetVC = viewController ?: self.selectedViewController;
    if (targetVC) {
        UITabBarController *tabBarController = nil;
        [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:targetVC];
    }
    UIControl *selectedControl = control;

    if (!selectedControl) {
        //        selectedControl = [self.tabBar cyl_tabBarButtonWithTabIndex:selectedIndex];
    }
    
    if (selectedControl) {
        [self didSelectControl:selectedControl];
    }
    
    UITabBarItem *item = viewController.tabBarItem;//.cyl_tabButton;
    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    BOOL isLottieEnabled = [self isLottieEnabled];
    
    if (isLottieEnabled && !isChildViewControllerPlusButton && [CYLConstants isUsedLiquidGlass]) {
        if (self.selectedViewController.cyl_isPlaceholder == NO) {
            [self addLottieImageWithControl:control lottieURL:item.cyl_lottieURL lottieSizeValue:item.cyl_lottieSizeValue animation:YES];
        }
    }
}

- (void)setViewDidLayoutSubViewsBlockInvokeOnce:(BOOL)invokeOnce block:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock  {
    self.viewDidLayoutSubviewsBlock = viewDidLayoutSubviewsBlock;
    self.invokeOnceViewDidLayoutSubViewsBlock = YES;
}

- (void)setViewDidLayoutSubViewsBlock:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock {
    _viewDidLayoutSubviewsBlock = viewDidLayoutSubviewsBlock;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
//    [self.tabBar cyl_resetPlatterSelectedContentSourceViewNewBounds];

    [self.tabBar layoutSubviews];//Fix issue #93 #392
    CYLTabBar *tabBar =  (CYLTabBar *)self.tabBar;
    if ([self.tabBar isKindOfClass:[CYLTabBar class]] ) {
        // add callback for visiable control, included all plusButton.
        
        [tabBar.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
            //to avoid invoking didSelectControl twice, because plusChildViewControllerButtonClicked will invoke setSelectedIndex
            if ([control cyl_isChildViewControllerPlusButton]) {
                
                return;
            }
            UILabel *tabLabel = control.cyl_tabLabel;
            tabLabel.textAlignment = NSTextAlignmentCenter;
            SEL actin = @selector(didSelectControl:);
//            UIControl *selectedContentControl = [self.tabBar cyl_selectedContentControlFromContentControl:control];
            [control addTarget:self action:actin forControlEvents:UIControlEventTouchUpInside];
//            [selectedContentControl addTarget:self action:actin forControlEvents:UIControlEventTouchUpInside];

            if (idx == self.selectedIndex && ![control isKindOfClass:[CYLPlusButton class]]) {
                control.selected = YES;
            }
        }];
        
        do {
            if (self.isLottieViewAdded) {
                break;
            }
            //FIXME:
            NSArray *subTabBarButtonsWithoutPlusButton = tabBar.cyl_subTabBarButtonsWithoutPlusButton;
            BOOL isLottieEnabled = [self isLottieEnabled];

            if (![CYLConstants isUsedLiquidGlass]) {
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
            dispatch_async(dispatch_get_main_queue(),^{
                if ([CYLConstants isUsedLiquidGlass]) {
                    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
                        UIControl * control = viewController.cyl_tabButton;
                        NSURL *url = viewController.tabBarItem.cyl_lottieURL;
                        NSValue *lottieSizeValue = viewController.tabBarItem.cyl_lottieSizeValue;

                        if (!control) {
                            return;
                        }
                        
                        if (!url) {
                            return;
                        }
                        if (viewController.cyl_isPlaceholder) {
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
            
            break;
        } while (NO);
    }

    
    if ([CYLConstants isUsedLiquidGlass] && ([[self class] havePlusButton]) && [self.tabBar isKindOfClass:[CYLTabBar class]]) {
        
        dispatch_async(dispatch_get_main_queue(),^{
            
            UIControl *plusControlOrigin = [self.tabBar cyl_platterContentViewWithIndex:CYLExternPlusButton.cyl_tabBarItemVisibleIndex];
            UIButton *selectedCover = CYLExternPlusButton.selectedContentView;
            [plusControlOrigin.cyl_tabImageView cyl_setHidden:YES];
            
            if ([self hasPlusChildViewController]) {
                [plusControlOrigin cyl_coverVisiableTabImageViewOrTabButton:YES newView:selectedCover offset:UIOffsetZero show:YES delayIfNeededForSeconds:1 completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull newView) {
                    
                }];
            } else {
                UIControl *plusSelectedControl = plusControlOrigin.cyl_platterSelectedControl;
                [plusSelectedControl.cyl_tabImageView cyl_setHidden:YES];
            }
        });
        
    }
    
    if (self.shouldInvokeOnceViewDidLayoutSubViewsBlock) {
        //在对象生命周期内，不添加 flag 属性的情况下，防止多次调进这个方法
        if (objc_getAssociatedObject(self, _cmd)) {
            return;
        } else {
            !self.viewDidLayoutSubviewsBlock ?: self.viewDidLayoutSubviewsBlock(self);
            objc_setAssociatedObject(self, _cmd, @"shouldInvokeOnceViewDidLayoutSubViewsBlock", OBJC_ASSOCIATION_RETAIN);
        }
        return;
    }

    !self.viewDidLayoutSubviewsBlock ?: self.viewDidLayoutSubviewsBlock(self);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (!(self.tabBarHeight > 0)) {
        return;
    }
    self.tabBar.frame = ({
        CGRect frame = self.tabBar.frame;
        CGFloat tabBarHeight = self.tabBarHeight;
        frame.size.height = tabBarHeight;
        frame.origin.y = self.view.frame.size.height - tabBarHeight;
        frame;
    });

}

- (void)setTabBarHeight:(CGFloat)tabBarHeight {
    _tabBarHeight = tabBarHeight;
    CYLTabBarHeight = tabBarHeight;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *controller = self.selectedViewController;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)controller;
        return navigationController.topViewController.supportedInterfaceOrientations;
    } else {
        return controller.supportedInterfaceOrientations;
    }
}

- (void)dealloc {
    UIButton<CYLPlusButtonSubclassing> *plusButton = CYLExternPlusButton;
    if (plusButton.superview && (plusButton.superview == self.tabBar)) {
        plusButton.selected = NO;
        [plusButton removeFromSuperview];
    }
    BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
    BOOL hasPlusChildViewController = [self hasPlusChildViewController] && isAdded;
    if (isAdded && hasPlusChildViewController && CYLPlusChildViewController.cyl_plusViewControllerEverAdded == YES) {
        [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:NO];
    }
    // KVO反注册
    if (self.tabBar && self.isObservingTabImageViewDefaultOffset) {
        @try {
            [self.tabBar removeObserver:self forKeyPath:@"tabImageViewDefaultOffset"];
        } @catch(NSException *e) { }
    }
}

#pragma mark -
#pragma mark - public Methods

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    NSString *context = nil;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:UIEdgeInsetsZero
                 titlePositionAdjustment:UIOffsetZero
                               styleType:CYLTabBarStyleTypeDefault
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    NSString *context = nil;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:imageInsets
                 titlePositionAdjustment:titlePositionAdjustment
                               styleType:CYLTabBarStyleTypeDefault
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                context:(NSString *)context {
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:imageInsets
                 titlePositionAdjustment:titlePositionAdjustment
                               styleType:CYLTabBarStyleTypeDefault
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
        self.context = context; //must use setter
        self.viewControllers = viewControllers;//must use setter
        self.tabBarStyleType = styleType;//must use setter
    }
    return self;
}
 
- (void)setContext:(NSString *)context {
    if (context && context.length > 0) {
        _context = [context copy];
    } else {
        _context = NSStringFromClass([CYLTabBarController class]);
    }
    @try {
        [self.tabBar setValue:_context forKey:@"context"];
    } @catch (NSException *exception) {
    }
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

- (void)alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:(NSArray *)viewControllers {
    
    UIViewController *viewController = nil;
    NSInteger index = NSNotFound;
    if (CYLPlusChildViewController) {
        viewController = CYLPlusChildViewController;
        index = CYLPlusButtonIndex;
    } else {
        UIViewController *placeholderViewController = [UIViewController new];
        [placeholderViewController cyl_setIsPlaceholder:YES];
        viewController = placeholderViewController;
    }
//    if ([self.tabBar isKindOfClass:[CYLTabBar class]] && self.tabBarStyleType != CYLTabBarStyleTypeFlatDesign) {
        _viewControllers = [[self alignArray:viewControllers object:viewController] copy];
//    } else {
//        _viewControllers = viewControllers;
//    }
    [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:index];
}

- (NSMutableArray *)alignArray:(NSArray *)arrayWithoutPlusButton object:(id)object {
    if (!object) {
        return [arrayWithoutPlusButton mutableCopy];
    }
    NSMutableArray *arrayWithPlusButton = nil;
    if ([arrayWithoutPlusButton isKindOfClass:[NSArray class]]) {
        arrayWithPlusButton = [NSMutableArray arrayWithArray:arrayWithoutPlusButton];
    } else if ([arrayWithoutPlusButton isKindOfClass:[NSMutableArray class]]) {
        arrayWithPlusButton = (NSMutableArray *)arrayWithoutPlusButton;
    }
    NSInteger index = NSNotFound;
    if (object && object == CYLPlusChildViewController) {
        index = CYLPlusButtonIndex;
    }
    [arrayWithPlusButton insertObject:object atIndex:(index != NSNotFound) ? CYLPlusButtonIndex : arrayWithoutPlusButton.count / 2];
    return arrayWithPlusButton;
}

- (void)alignTabControlIfNeededWithViewControllers:(NSArray *)viewControllers {
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

    if (![CYLConstants isUsedLiquidGlass]) {
        if (!hasPlusChildViewController) {
            _viewControllers = [viewControllers copy];
        }
        return;
    }
    if (![[self class] havePlusButton]) {
        if (!hasPlusChildViewController) {
            _viewControllers = [viewControllers copy];
        }
        return;
    }
    if (![self.tabBar isKindOfClass:[CYLTabBar class]]) {
        if (!hasPlusChildViewController) {
            _viewControllers = [viewControllers copy];
        }
        return;
    }
    //TODO: iOS26+ , 有plusButton ， 但不是 hasPlusChildViewController。
 
    // plusButton and plusVC 全部使用 旧的 plusVC 逻辑， 摒弃 plusButton but no plusVC 逻辑。统一逻辑
    [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
    if ([self isLottieEnabled]) {
        
        NSDictionary *plusInfo =
        @{

            CYLTabBarItemTitle: @"",
            CYLTabBarItemImage :  [UIImage cyl_imageWithColor:[UIColor whiteColor] size:CGSizeMake(22, 22)],
            CYLTabBarItemSelectedImage : [UIImage cyl_imageWithColor:[UIColor whiteColor] size:CGSizeMake(22, 22)]
        };
        _tabBarItemsAttributes = [self alignArray:_tabBarItemsAttributes object:plusInfo];
    }
    else {
         //FIXME:  to delete 不能使用 imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal否则不显示
        //                    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        

        UIImage *normalImageInfo = _tabBarItemsAttributes[0][CYLTabBarItemImage];
        UIImage *selectedImageInfo = _tabBarItemsAttributes[0][CYLTabBarItemSelectedImage];
        normalImageInfo = [UIImage cyl_imageWithColor:[UIColor whiteColor] size:CGSizeMake(CYLTabBarHeight, CYLTabBarHeight)];
        selectedImageInfo = [UIImage cyl_imageWithColor:[UIColor whiteColor] size:CGSizeMake(CYLTabBarHeight, CYLTabBarHeight)];

        NSDictionary *plusInfo =
        @{
            CYLTabBarItemTitle: @"",
        CYLTabBarItemImage : normalImageInfo,
        CYLTabBarItemSelectedImage: selectedImageInfo
        };
        _tabBarItemsAttributes = [self alignArray:_tabBarItemsAttributes object:plusInfo];
    }
    [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
}

- (void)doubleCheckTabControlAlignWithViewControllers:(NSArray *)viewControllers {
    //FIXME:  to delete
    if (!viewControllers) {
        viewControllers = _viewControllers;
    }
    if ((!_tabBarItemsAttributes) || (_tabBarItemsAttributes.count != viewControllers.count)) {
#if defined(DEBUG) || defined(BETA)
        [NSException raise:NSStringFromClass([CYLTabBarController class]) format:@" [DEBUG] The count of CYLTabBarControllers is not equal to the count of tabBarItemsAttributes.【Chinese】【仅为调试阶段的提示信息】设置_tabBarItemsAttributes属性时，请确保元素个数与控制器的个数相同，并在方法`-setViewControllers:`之前设置"];
#endif
        return;
    }
}

- (void)hideTabBarShadowImageView {
    [self.tabBar layoutIfNeeded];
    UIImageView *imageView = self.tabBar.cyl_tabShadowImageView;
    [imageView cyl_setHidden:YES];//iOS13+    
}

+ (BOOL)havePlusButton {
    if (CYLExternPlusButton) {
        return YES;
    }
    return NO;
}

+ (NSUInteger)allItemsInTabBarCount {
    NSUInteger allItemsInTabBar = CYLTabbarItemsCount;
    if ([CYLTabBarController havePlusButton]) {
        allItemsInTabBar += 1;
    }
    return allItemsInTabBar;
}

- (id<UIApplicationDelegate>)appDelegate {
    return [UIApplication sharedApplication].delegate;
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
    BOOL isLiquidGlass = [CYLConstants isUsedLiquidGlass];
    //， 这个表示requiresCompatibility，必须使用， 否则iOS26里的兼容模式会错乱。
    if (!isLiquidGlass) {
        return YES;
    }

    
    BOOL result = _noNeedUIDesignCompatibility && isLiquidGlass;
    return result;
}

- (void)setTabBarStyleType:(CYLTabBarStyleType)tabBarStyleType {
    _tabBarStyleType = tabBarStyleType;
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
}

#pragma mark -
#pragma mark - Private Methods

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 */
- (void)setUpTabBar {
    [self setUpTabBar:nil];
}

- (void)setUpTabBar:(UITabBar *)_tabBar {
    @try {
        CYLTabBar *tabBar = (CYLTabBar *)_tabBar;
        if (!tabBar) {
            tabBar = [[CYLTabBar alloc] init];
        }
        //    CYL_UIDesignClassicCYLTabBar
        BOOL noNeedUIDesignCompatibility = [self noNeedUIDesignCompatibility];
        if (noNeedUIDesignCompatibility || !CYL_IS_IOS_26) {
            [self cyl_setValue:tabBar forKey:@"tabBar"];
            tabBar.delegate = self;

        } else if (CYL_IS_IOS_26 && !noNeedUIDesignCompatibility) {
            CYLFlatDesignTabBar *pureCustomTabBar = (CYLFlatDesignTabBar *)_tabBar;
            if (!pureCustomTabBar || ![pureCustomTabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
                pureCustomTabBar = [[CYLFlatDesignTabBar alloc] init];
            }
            pureCustomTabBar.delegate = self;
            
            [self cyl_setValue:pureCustomTabBar forKey:@"tabBar"];
            [self.tabBar addSubview:pureCustomTabBar];
        }
        [tabBar cyl_setTabBarController:self];
            
    } @catch (NSException *exception) {
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@: reason %@", @(__PRETTY_FUNCTION__), @(__LINE__), @"setUpTabBar failed", exception.reason);
    }
    
}
- (BOOL)hasPlusChildViewController {
    NSString *context = CYLPlusChildViewController.cyl_context;
    BOOL isSameContext = [context isEqualToString:self.context] && (context && self.context); // || (!context && !self.context);
    BOOL hasPlusChildViewController = CYLPlusChildViewController && isSameContext;//&& !isAdded;
    return hasPlusChildViewController;
}

- (BOOL)isPlusViewControllerAdded:(NSArray *)viewControllers {
    if ([viewControllers containsObject:CYLPlusChildViewController]) {
        return YES;
    }
    __block BOOL isAdded = NO;
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self isEqualViewController:obj compairedViewController:CYLPlusChildViewController]) {
            isAdded = YES;
            *stop = YES;
            return;
        }
    }];
    return isAdded;
}

- (void)setViewControllers:(NSArray *)viewControllers {
    BOOL noNeedUIDesignCompatibility = [self noNeedUIDesignCompatibility];
    CYLFlatDesignTabBar *pureCustomTabBar;
    if (!noNeedUIDesignCompatibility && CYL_IS_IOS_26) {
        pureCustomTabBar = [CYLFlatDesignTabBar new];
        pureCustomTabBar.delegate = self;
    }
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
        }
        _viewControllers = nil;
        return;
    }

    [self alignTabControlIfNeededWithViewControllers:viewControllers];

    CYLTabbarItemsCount = [viewControllers count];
    CYLTabBarItemWidth = (self.tabBar.cyl_boundsSize.width - CYLPlusButtonWidth) / (CYLTabbarItemsCount);
    NSUInteger idx = 0;
    for (UIViewController *viewController in _viewControllers) {
        NSString *title = nil;
        id normalImageInfo = nil;
        id selectedImageInfo = nil;
        UIOffset titlePositionAdjustment = UIOffsetZero;
        UIEdgeInsets imageInsets = UIEdgeInsetsZero;
        NSURL *lottieURL = nil;
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
            lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
            
            NSValue *offsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemTitlePositionAdjustment];
            UIOffset offset = [offsetValue UIOffsetValue];
            titlePositionAdjustment = offset;
            
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
            if ([CYLConstants isUsedLiquidGlass] && ([[self class] havePlusButton])) {
            } else {
                idx--;
            }
        }
        
        [self addOneChildViewController:viewController
                              WithTitle:title
                        normalImageInfo:normalImageInfo
                      selectedImageInfo:selectedImageInfo
                titlePositionAdjustment:titlePositionAdjustment
                            imageInsets:imageInsets
                              lottieURL:lottieURL
                        lottieSizeValue:lottieSizeValue
         
        ];
        if (!noNeedUIDesignCompatibility && CYL_IS_IOS_26) {
            if (!viewController.cyl_isPlaceholder && ![self isEqualViewController:viewController compairedViewController:CYLPlusChildViewController]) {
                CYLFlatDesignTabBarItem *tabItem = [pureCustomTabBar addItemWithTitle:title
                                                                      tabBarItemImage:normalImageInfo
                                                              tabBarItemSelectedImage:selectedImageInfo
                                                                                index:idx
                                                              titlePositionAdjustment:titlePositionAdjustment
                                                                          imageInsets:imageInsets
                                                                            lottieURL:lottieURL
                                                                      lottieSizeValue:lottieSizeValue];
                [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabButton:tabItem];
            }
        }
        
        [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabBarController:self];
        idx++;
    }
    
    if (!noNeedUIDesignCompatibility && CYL_IS_IOS_26) {
        pureCustomTabBar.delegate = self;
        [self setUpTabBar:pureCustomTabBar];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.f) {
        CYL_DEPRECATED_DECLARATIONS_PUSH
        [self.tabBar setSelectedImageTintColor:tintColor];
        CYL_DEPRECATED_DECLARATIONS_POP
    }
    self.tabBar.tintColor = tintColor;
}

/**
 *  lazy load tabItemPlaceholderImage
 *
 *  @return UIImage
 */
- (UIImage *)tabItemPlaceholderImage {
    if (_tabItemPlaceholderImage == nil) {
        _tabItemPlaceholderImage = [UIImage cyl_tabItemPlaceholderImage];
    }
    return _tabItemPlaceholderImage;
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
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(NSURL *)lottieURL
                  lottieSizeValue:(NSValue *)lottieSizeValue {
    viewController.tabBarItem.title = title;
    UIImage *normalImage = [UIImage cyl_imageNamed:normalImageInfo];
    viewController.tabBarItem.image = normalImage;

    UIImage *selectedImage = [UIImage cyl_imageNamed:selectedImageInfo];;
    viewController.tabBarItem.selectedImage = selectedImage;

    if (self.shouldCustomizeImageInsets || ([self isNOTEmptyForImageInsets:imageInsets])) {
        UIEdgeInsets insets = (([self isNOTEmptyForImageInsets:imageInsets]) ? imageInsets : self.imageInsets);
        viewController.tabBarItem.imageInsets = insets;
    }
    if (self.shouldCustomizeTitlePositionAdjustment || [self isNOTEmptyForTitlePositionAdjustment:titlePositionAdjustment]) {
        UIOffset offset = (([self isNOTEmptyForTitlePositionAdjustment:titlePositionAdjustment]) ? titlePositionAdjustment : self.titlePositionAdjustment);
        viewController.tabBarItem.titlePositionAdjustment = offset;
    }
    if (lottieURL) {
        [self.lottieURLs addObject:lottieURL];
        [viewController.tabBarItem cyl_setLottieURL:lottieURL];

        NSValue *tureLottieSizeValue = [CYLConstants cyl_getTureLottieSizeValue:lottieSizeValue fromNormalImage:normalImage];
        [self.lottieSizes addObject:tureLottieSizeValue];
        [viewController.tabBarItem cyl_setLottieSizeValue:tureLottieSizeValue];
    }
    [self addChildViewController:viewController];
}



- (UIImage *)getImageFromImageInfo:(id)imageInfo {
    UIImage *image = [UIImage cyl_getImageFromImageInfo:imageInfo];
    return image;
}

- (BOOL)shouldCustomizeImageInsets {
    BOOL shouldCustomizeImageInsets = [self isNOTEmptyForImageInsets:self.imageInsets];
    return shouldCustomizeImageInsets;
}

- (BOOL)shouldCustomizeTitlePositionAdjustment {
    BOOL shouldCustomizeTitlePositionAdjustment = [self isNOTEmptyForTitlePositionAdjustment:self.titlePositionAdjustment];
    return shouldCustomizeTitlePositionAdjustment;
}

- (BOOL)isNOTEmptyForImageInsets:(UIEdgeInsets)imageInsets {
    if (imageInsets.top != 0 || imageInsets.left != 0 || imageInsets.bottom != 0 || imageInsets.right != 0) {
        return YES;
    }
    return NO;
}

- (BOOL)isNOTEmptyForTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    if (titlePositionAdjustment.horizontal != 0 || titlePositionAdjustment.vertical != 0) {
        return YES;
    }
    return NO;
}

- (BOOL)isNOTEmptyForSize:(UIOffset)titlePositionAdjustment {
    if (titlePositionAdjustment.horizontal != 0 || titlePositionAdjustment.vertical != 0) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark - KVO Method

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != CYLTabImageViewDefaultOffsetContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == CYLTabImageViewDefaultOffsetContext) {
        CGFloat tabImageViewDefaultOffset = [change[NSKeyValueChangeNewKey] floatValue];
        [self offsetTabBarTabImageViewToFit:tabImageViewDefaultOffset];
    }
}

- (void)offsetTabBarTabImageViewToFit:(CGFloat)tabImageViewDefaultOffset {
    if (self.shouldCustomizeImageInsets) {
        return;
    }
    NSArray<UITabBarItem *> *tabBarItems = self.tabBar.items;
    [tabBarItems enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIEdgeInsets imageInset = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);
        obj.imageInsets = imageInset;
        if (!self.shouldCustomizeTitlePositionAdjustment) {
            obj.titlePositionAdjustment = UIOffsetMake(0, MAXFLOAT);
        }
    }];
}

#pragma mark - delegate
- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController {
//    [viewController.view layoutIfNeeded];
    [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController shouldSelect:YES];
}

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController
                                            shouldSelect:(BOOL)shouldSelect {
    [[viewController.tabBarItem cyl_tabButton] cyl_setShouldNotSelect:!shouldSelect];
    if (!shouldSelect) {
        return;
    }
    UIButton *plusButton = CYLExternPlusButton;
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (!CYLPlusChildViewController) {
        return;
    }
    BOOL isCurrentViewController = [self isEqualViewController:viewController compairedViewController:CYLPlusChildViewController];
    BOOL shouldConfigureSelectionStatus = (!isCurrentViewController);
    if (plusButton.selected) {
        plusButton.selected = NO;
    }
    
    if (!shouldConfigureSelectionStatus) {
#if __has_include(<Lottie/Lottie.h>)
        if ([self.tabBar isKindOfClass:[CYLTabBar class]]) {
            [self.tabBar cyl_stopAnimationOfAllLottieView];
        }
#else
#endif
    }
}

- (BOOL)isEqualViewController:(UIViewController *)viewController compairedViewController:(UIViewController *)compairedViewController {
    if ([viewController isEqual:compairedViewController]) {
        return YES;
    }
    if ([[viewController cyl_getViewControllerInsteadOfNavigationController] isEqual:[compairedViewController cyl_getViewControllerInsteadOfNavigationController]]) {
        return YES;
    }
    return NO;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (viewController.cyl_isPlaceholder == YES) {
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
    return viewController != self.selectedViewController;
    
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
}

- (BOOL)isLottieEnabled {
#if __has_include(<Lottie/Lottie.h>)
    NSInteger lottieURLCount = self.lottieURLs.count;
    BOOL isLottieEnabled = lottieURLCount > 0 ;
    BOOL isLottieEnabledFromAttributes = NO;
    if (self.tabBarItemsAttributes && self.tabBarItemsAttributes.count > 0) {
        @try {
            isLottieEnabledFromAttributes = self.tabBarItemsAttributes[0][CYLTabBarLottieURL];
        } @catch (NSException *exception) {
        }
    }
    return isLottieEnabled || isLottieEnabledFromAttributes;
#else
    return NO;
#endif
}
 

- (void)didSelectControl:(UIControl *)control {
    
    SEL actin = @selector(tabBarController:didSelectControl:);
    
    BOOL shouldSelectViewController =  YES;
    @try {
        shouldSelectViewController = (!control.cyl_shouldNotSelect) && (!control.hidden) ;
    } @catch (NSException *exception) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
    }
    UIControl *contentControl = control;
    UIControl *selectedContentControl = nil;
    if ([self.tabBar isKindOfClass:[CYLTabBar class]]) {
        selectedContentControl = [self.tabBar cyl_selectedContentControlFromContentControl:control];
        if (![control cyl_isPlusControl]) {
            [self.tabBar cyl_setSelectedControl:selectedContentControl  ?: contentControl];
        } else {
            [self.tabBar cyl_setSelectedControl:CYLExternPlusButton];
        }
        
        if (shouldSelectViewController) {
            //TODO:  pure tabbar
            [self.tabBar.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.selected = NO;
            }];
            [self.tabBar.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.selected = NO;
            }];
            contentControl.selected = YES;
            selectedContentControl.selected = YES;
            BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
            BOOL isLottieEnabled = [self isLottieEnabled];
            if ( isLottieEnabled && !isChildViewControllerPlusButton && ![CYLConstants isUsedLiquidGlass]) {
                //TODO:  selected content, double add
                [self addLottieImageWithControl:contentControl animation:YES];
            }
        }
    }
    if ([self.delegate respondsToSelector:actin] && shouldSelectViewController) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [self.delegate performSelector:actin withObject:self withObject:control ?: self.selectedViewController.cyl_tabButton];
         );
    }
}

- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation {
    [self addLottieImageWithControl:control lottieURL:nil lottieSizeValue:nil animation:animation];
}

- (void)addLottieImageWithControl:(UIControl *)control
                        lottieURL:(NSURL *)lottieURL
                  lottieSizeValue:(NSValue *)theLottieSizeValue
                        animation:(BOOL)animation {
    [self addLottieImageWithControl:control
                          lottieURL:lottieURL
                    lottieSizeValue:theLottieSizeValue
                          animation:animation
                    defaultSelected:NO];
}

//TODO:  selected content, double add
- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
    if ([CYLConstants isUsedLiquidGlass]) {
        [self addLottieImageWithControl:control lottieURL:nil lottieSizeValue:nil animation:animation defaultSelected:defaultSelected];
    } else {
        NSUInteger index = [self.tabBar.cyl_subTabBarButtonsWithoutPlusButton indexOfObject:control];
        if (NSNotFound == index) {
            return;
        }
        if (control.cyl_isPlusButton) {
            return;
        }
        NSURL *lottieURL = self.lottieURLs[index];
        NSValue *lottieSizeValue = self.lottieSizes[index];
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize];
        if (animation) {
            [self.tabBar cyl_animationLottieImageWithSelectedControl:control lottieURL:lottieURL size:lottieSize defaultSelected:defaultSelected];
        }
    }
}
    
//TODO:  selected content, double add
- (void)addLottieImageWithControl:(UIControl *)control
                              lottieURL:(NSURL *)theLottieURL
                  lottieSizeValue:(NSValue *)theLottieSizeValue
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
    UIControl *contentControl = control;
    UIControl *selectedContentControl;
    //FIXME:  必须为 cyl_subTabBarButtonsWithoutPlusButton （不能 cyl_subTabBarButtons）否则Lottie选中动画不显示，因为Lottie文件数量与tabbaritems 的数量少一个。
    //TODO: selectedContentControl不对，plusButton 下一个会添加失败，添加的是 plusButton对应的lottie， 顺延了。
    if (control.cyl_isPlusControl) {
        return;
    }
    

    NSURL *lottieURL = theLottieURL;
    NSValue *lottieSizeValue = theLottieSizeValue;

    @try {
        NSUInteger index = [self.tabBar.cyl_subTabBarButtons indexOfObject:contentControl];
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
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
    }
    
    CGSize lottieSize = [lottieSizeValue CGSizeValue];
    [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize];
    
    if (![self.tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    selectedContentControl = [self.tabBar cyl_selectedContentControlFromContentControl:contentControl];

    if (selectedContentControl) {
        [selectedContentControl cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize];
    }
    
    if (animation) {
        [self.tabBar cyl_animationLottieImageWithSelectedControl:contentControl lottieURL:lottieURL size:lottieSize defaultSelected:defaultSelected];
        if (selectedContentControl) {
            [self.tabBar cyl_animationLottieImageWithSelectedControl:selectedContentControl lottieURL:lottieURL size:lottieSize defaultSelected:defaultSelected];
        }
    }
}

- (id)rootViewController {
    CYLTabBarController *tabBarController = nil;
     
    UIViewController *rootViewController = [CYLGetRootViewController() cyl_getViewControllerInsteadOfNavigationController];;
    if ([rootViewController isKindOfClass:[CYLTabBarController class]]) {
        tabBarController = (CYLTabBarController *)rootViewController;
    }
    return tabBarController;
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


- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItemAt:(NSInteger)index {
    [self setSelectedIndex:index];
    [self tabChangedToSelectedIndex:index
                            viewController:self.selectedViewController
                                   control:tabBar.tabBarItems[index]];
}

#pragma mark - Override selectedViewController (User initiated)

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    [super setSelectedViewController:selectedViewController];
//    [self.tabBar layoutIfNeeded];
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
    
}

#pragma mark - Override selectedIndex (Programmatic changes)

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    if ([self.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        CYLFlatDesignTabBar *tabBar = (CYLFlatDesignTabBar *)self.tabBar;
        [tabBar setSelectedIndex:selectedIndex];
    }
    // 代码切换 tab 时会触发
    [self tabChangedToSelectedIndex:selectedIndex viewController:nil control:nil];
}
    
    
- (CGSize)visiableTabBarSize {
    return self.cyl_tabBarController.tabBar.cyl_boundsSize;
}
    
@end

@implementation NSObject (CYLTabBarControllerReferenceExtension)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController {
    //OBJC_ASSOCIATION_ASSIGN instead of OBJC_ASSOCIATION_RETAIN_NONATOMIC to avoid retain circle
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
    if (tabBarController && [tabBarController isKindOfClass:[CYLTabBarController class]]) {
        return tabBarController;
    }
    if ([self isKindOfClass:[UIViewController class]] && [(UIViewController *)self parentViewController]) {
        tabBarController = [[(UIViewController *)self parentViewController] cyl_tabBarController];
        if ([tabBarController isKindOfClass:[CYLTabBarController class]]) {
            return tabBarController;
        }
    }

    UIViewController *rootViewController = [CYLGetRootViewController() cyl_getViewControllerInsteadOfNavigationController];;
    if ([rootViewController isKindOfClass:[CYLTabBarController class]]) {
        tabBarController = (CYLTabBarController *)rootViewController;
    }
    return tabBarController;
}
    
@end
