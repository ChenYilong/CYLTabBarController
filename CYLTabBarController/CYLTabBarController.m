//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.10.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
#import <objc/runtime.h>

NSString *const CYLTabBarItemTitle = @"CYLTabBarItemTitle";
NSString *const CYLTabBarItemImage = @"CYLTabBarItemImage";
NSString *const CYLTabBarItemSelectedImage = @"CYLTabBarItemSelectedImage";

NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
NSString *const CYLTabBarItemWidthDidChangeNotification = @"CYLTabBarItemWidthDidChangeNotification";
static void * const CYLSwappableImageViewDefaultOffsetContext = (void*)&CYLSwappableImageViewDefaultOffsetContext;

@interface NSObject (CYLTabBarControllerItemInternal)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController;

@end

@interface CYLTabBarController () <UITabBarControllerDelegate>

@property (nonatomic, assign, getter=isObservingSwappableImageViewDefaultOffset) BOOL observingSwappableImageViewDefaultOffset;

@end
@implementation CYLTabBarController

@synthesize viewControllers = _viewControllers;

#pragma mark -
#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // 处理tabBar，使用自定义 tabBar 添加 发布按钮
    [self setUpTabBar];
    // KVO注册监听
    if (!self.isObservingSwappableImageViewDefaultOffset) {
        [self.tabBar addObserver:self forKeyPath:@"swappableImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:CYLSwappableImageViewDefaultOffsetContext];
        self.observingSwappableImageViewDefaultOffset = YES;
    }
    self.delegate = self;
}

//Fix issue #93
- (void)viewDidLayoutSubviews {
    [self.tabBar layoutSubviews];
}

- (void)viewWillLayoutSubviews {
    if (!self.tabBarHeight) {
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
    // KVO反注册
    if (self.isObservingSwappableImageViewDefaultOffset) {
        [self.tabBar removeObserver:self forKeyPath:@"swappableImageViewDefaultOffset"];
    }
}

#pragma mark -
#pragma mark - public Methods

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    if (self = [super init]) {
        _tabBarItemsAttributes = tabBarItemsAttributes;
        self.viewControllers = viewControllers;
    }
    return self;
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
   return [[self alloc] initWithViewControllers:viewControllers tabBarItemsAttributes:tabBarItemsAttributes];
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

- (UIWindow *)rootWindow {
    UIWindow *result = nil;
    
    do {
        if ([self.appDelegate respondsToSelector:@selector(window)]) {
            result = [self.appDelegate window];
        }
        
        if (result) {
            break;
        }
    } while (NO);
    
    return result;
}

#pragma mark -
#pragma mark - Private Methods

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 */
- (void)setUpTabBar {
    [self setValue:[[CYLTabBar alloc] init] forKey:@"tabBar"];
}

- (void)setViewControllers:(NSArray *)viewControllers {
    if (_viewControllers && _viewControllers.count) {
        for (UIViewController *viewController in _viewControllers) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
        }
    }
    if (viewControllers && [viewControllers isKindOfClass:[NSArray class]]) {
        if ((!_tabBarItemsAttributes) || (_tabBarItemsAttributes.count != viewControllers.count)) {
            [NSException raise:@"CYLTabBarController" format:@"The count of CYLTabBarControllers is not equal to the count of tabBarItemsAttributes.【Chinese】设置_tabBarItemsAttributes属性时，请确保元素个数与控制器的个数相同，并在方法`-setViewControllers:`之前设置"];
        }
        
        if (CYLPlusChildViewController) {
            NSMutableArray *viewControllersWithPlusButton = [NSMutableArray arrayWithArray:viewControllers];
            [viewControllersWithPlusButton insertObject:CYLPlusChildViewController atIndex:CYLPlusButtonIndex];
            _viewControllers = [viewControllersWithPlusButton copy];
        } else {
            _viewControllers = [viewControllers copy];
        }
        CYLTabbarItemsCount = [viewControllers count];
        CYLTabBarItemWidth = ([UIScreen mainScreen].bounds.size.width - CYLPlusButtonWidth) / (CYLTabbarItemsCount);
        NSUInteger idx = 0;
        for (UIViewController *viewController in _viewControllers) {
            NSString *title = nil;
            id normalImageInfo = nil;
            id selectedImageInfo = nil;
            if (viewController != CYLPlusChildViewController) {
                title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                normalImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemImage];
                selectedImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage];
            } else {
                idx--;
            }
            
            [self addOneChildViewController:viewController
                                  WithTitle:title
                            normalImageInfo:normalImageInfo
                          selectedImageInfo:selectedImageInfo];
            [viewController cyl_setTabBarController:self];
            idx++;
        }
    } else {
        for (UIViewController *viewController in _viewControllers) {
            [viewController cyl_setTabBarController:nil];
        }
        _viewControllers = nil;
    }
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
                selectedImageInfo:(id)selectedImageInfo {
    viewController.tabBarItem.title = title;
    if (normalImageInfo) {
        UIImage *normalImage = [self getImageFromImageInfo:normalImageInfo];
        normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        viewController.tabBarItem.image = normalImage;
    }
    if (selectedImageInfo) {
        UIImage *selectedImage = [self getImageFromImageInfo:selectedImageInfo];
        selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        viewController.tabBarItem.selectedImage = selectedImage;
    }
    if (self.shouldCustomizeImageInsets) {
        viewController.tabBarItem.imageInsets = self.imageInsets;
    }
    if (self.shouldCustomizeTitlePositionAdjustment) {
        viewController.tabBarItem.titlePositionAdjustment = self.titlePositionAdjustment;
    }
    [self addChildViewController:viewController];
}

- (UIImage *)getImageFromImageInfo:(id)imageInfo {
    UIImage *image = nil;
    if ([imageInfo isKindOfClass:[NSString class]]) {
        image = [UIImage imageNamed:imageInfo];
    } else if ([imageInfo isKindOfClass:[UIImage class]]) {
        image = (UIImage *)imageInfo;
    }
    return image;
}

- (BOOL)shouldCustomizeImageInsets {
    BOOL shouldCustomizeImageInsets = self.imageInsets.top != 0.f || self.imageInsets.left != 0.f || self.imageInsets.bottom != 0.f || self.imageInsets.right != 0.f;
    return shouldCustomizeImageInsets;
}

- (BOOL)shouldCustomizeTitlePositionAdjustment {
    BOOL shouldCustomizeTitlePositionAdjustment = self.titlePositionAdjustment.horizontal != 0.f || self.titlePositionAdjustment.vertical != 0.f;
    return shouldCustomizeTitlePositionAdjustment;
}

#pragma mark -
#pragma mark - KVO Method

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != CYLSwappableImageViewDefaultOffsetContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == CYLSwappableImageViewDefaultOffsetContext) {
        CGFloat swappableImageViewDefaultOffset = [change[NSKeyValueChangeNewKey] floatValue];
        [self offsetTabBarSwappableImageViewToFit:swappableImageViewDefaultOffset];
    }
}

- (void)offsetTabBarSwappableImageViewToFit:(CGFloat)swappableImageViewDefaultOffset {
    if (self.shouldCustomizeImageInsets) {
        return;
    }
    NSArray<UITabBarItem *> *tabBarItems = [self cyl_tabBarController].tabBar.items;
    [tabBarItems enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIEdgeInsets imageInset = UIEdgeInsetsMake(swappableImageViewDefaultOffset, 0, -swappableImageViewDefaultOffset, 0);
        obj.imageInsets = imageInset;
        if (!self.shouldCustomizeTitlePositionAdjustment) {
            obj.titlePositionAdjustment = UIOffsetMake(0, MAXFLOAT);
        }
    }];
}

#pragma mark - delegate

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger selectedIndex = tabBarController.selectedIndex;
    UIButton *plusButton = CYLExternPlusButton;
    BOOL shouldConfigureSelectionStatus = CYLPlusChildViewController && ((selectedIndex == CYLPlusButtonIndex) && (viewController != CYLPlusChildViewController));
    if (shouldConfigureSelectionStatus) {
        plusButton.selected = NO;
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [[self cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    return YES;
}

@end

#pragma mark - NSObject+CYLTabBarControllerItem

@implementation NSObject (CYLTabBarControllerItemInternal)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController {
    objc_setAssociatedObject(self, @selector(cyl_tabBarController), tabBarController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation NSObject (CYLTabBarController)

- (CYLTabBarController *)cyl_tabBarController {
    CYLTabBarController *tabBarController = objc_getAssociatedObject(self, @selector(cyl_tabBarController));
    if (tabBarController) {
        return tabBarController;
    }
    if ([self isKindOfClass:[UIViewController class]] && [(UIViewController *)self parentViewController]) {
        tabBarController = [[(UIViewController *)self parentViewController] cyl_tabBarController];
        return tabBarController;
    }
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    if ([window.rootViewController isKindOfClass:[CYLTabBarController class]]) {
        tabBarController = (CYLTabBarController *)window.rootViewController;
    }
    return tabBarController;
}

@end
