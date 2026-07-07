//
//  CYLPlusButton.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import "UIViewController+CYLTabBarControllerExtention.h"

CGFloat CYLPlusButtonWidth = 0.0f;
CYLPlusButton<CYLPlusButtonSubclassing> *CYLExternPlusButton = nil;
UIViewController *CYLPlusChildViewController = nil;

@interface CYLPlusButton () 

@property (nonatomic, strong) UIImage *snapshot;

@property (nonatomic, weak) UIButton *contentView;
@property (nonatomic, weak) UIButton *selectedContentView;
@property (nonatomic, strong) UIImage *selectedContentImage;
@property (nonatomic, strong) UIImage *contentImage;

@end

@implementation CYLPlusButton
//@synthesize selected = _selected;
#pragma mark -
#pragma mark - public Methods

+ (void)registerPlusButton {
    if (![self conformsToProtocol:@protocol(CYLPlusButtonSubclassing)]) {
        return;
    }
    Class<CYLPlusButtonSubclassing> class = self;
    if ([[self class] respondsToSelector:@selector(plusChildViewController)]) {
        CYLPlusChildViewController = [class plusChildViewController];
         NSString *tabBarContext = [self matchedTabBarContext];
        if (tabBarContext && tabBarContext.length) {
            [CYLPlusChildViewController cyl_setContext:tabBarContext];
        }
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        CYLExternPlusButton = plusButton;
        CYLPlusButtonWidth = plusButton.frame.size.width;
        [[self class] addSelectViewControllerTarget:plusButton];
        //液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        if ([CYLConstants isLiquidGlassActive]) {
            //            plusButton.cyl_userInteractionDisabled = YES;
        }
        if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
            CYLPlusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
        } else {
#if defined(DEBUG) || defined(BETA)
            NSAssert(NO, @"[DEBUG INFO]If you want to add PlusChildViewController, you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO]如果你想使用PlusChildViewController样式，你必须同时在你自定义的plusButton中实现 `+indexOfPlusButtonInTabBar`，来指定plusButton的位置");
#endif
        }
    } else {
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        CYLExternPlusButton = plusButton;
        CYLPlusButtonWidth = plusButton.frame.size.width;
    }
}

+ (void)removePlusButton {
    if (CYLExternPlusButton) {
        if (CYLExternPlusButton.superview) {
            [CYLExternPlusButton removeFromSuperview];
        }
        CYLExternPlusButton = nil;
    }
    
    if (CYLPlusChildViewController) {
        [CYLPlusChildViewController willMoveToParentViewController:nil];
        [CYLPlusChildViewController.view removeFromSuperview];
        [CYLPlusChildViewController removeFromParentViewController];
        [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:NO];
        CYLPlusChildViewController = nil;
    }
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
+ (void)registerSubclass {
    [self registerPlusButton];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP
- (void)plusChildViewControllerButtonClicked:(UIButton<CYLPlusButtonSubclassing> *)sender {
    BOOL notNeedConfigureSelectionStatus = [[self class] respondsToSelector:@selector(shouldSelectPlusChildViewController)] && ![[self class] shouldSelectPlusChildViewController];
    if (notNeedConfigureSelectionStatus) {
        return;
    }
    CYLTabBarController *tabBarController = [sender cyl_tabBarController];
    NSInteger index = [tabBarController.viewControllers indexOfObject:CYLPlusChildViewController];
    if (NSNotFound != index && (index < tabBarController.viewControllers.count)) {
        [tabBarController setSelectedIndex:index];
        if (NO == sender.cyl_userInteractionDisabled) { 
            sender.selected = YES;
            [tabBarController tabChangedToControl:self];
        }
    }
}

#pragma mark -
#pragma mark - Private Methods

//- (void)setSelected:(BOOL)selected {
//    _selected = selected;
//    if (_selected) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
//    }
//}

+ (void)addSelectViewControllerTarget:(UIButton<CYLPlusButtonSubclassing> *)plusButton {
    id target = self;
    NSArray<NSString *> *selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    if (selectorNamesArray.count == 0) {
        target = plusButton;
        selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    }
    [selectorNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL selector =  NSSelectorFromString(obj);
        [plusButton removeTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    }];
    [plusButton addTarget:plusButton action:@selector(plusChildViewControllerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (BOOL)isLayoutCentered {
    if ((0 == [self constantOfPlusButtonCenterYOffsetForTabBarHeight]) && (0.5 == [self defaultMultiplierOfTabBarHeight])) {
        return YES;
    }
    return NO;
}

- (CGFloat)defaultMultiplierOfTabBarHeight {
    return [self multiplierOfTabBarHeight:self.cyl_tabBarController.tabBar.cyl_boundsSize.height plusButtonHeight:self.frame.size.height];
}

- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
    return [self multiplierOfTabBarHeight:tabBarHeight plusButtonHeight:self.frame.size.height];
}

- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight plusButtonHeight:(CGFloat)plusButtonHeight {
    CGFloat multiplierOfTabBarHeight;
    if ([[self class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
        multiplierOfTabBarHeight = [[self class] multiplierOfTabBarHeight:tabBarHeight];
    }
    
    CYL_DEPRECATED_DECLARATIONS_PUSH
    else if ([[self class] respondsToSelector:@selector(multiplerInCenterY)]) {
        multiplierOfTabBarHeight = [[self class] multiplerInCenterY];
    }
    CYL_DEPRECATED_DECLARATIONS_POP
    
    else {
        CGFloat heightDifference = plusButtonHeight - tabBarHeight;
        if (heightDifference < 0) {
            multiplierOfTabBarHeight = 0.5;
        } else {
            CGPoint center = CGPointMake(tabBarHeight* 0.5, tabBarHeight * 0.5);
            center.y = center.y - heightDifference * 0.5;
            multiplierOfTabBarHeight = center.y / tabBarHeight;
        }
    }
    return multiplierOfTabBarHeight;
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight {
    return [self constantOfPlusButtonCenterYOffsetForTabBarHeight:self.cyl_tabBarController.tabBar.cyl_boundsSize.height];
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    CGFloat constantOfPlusButtonCenterYOffset = 0.f;
    if ([[self class] respondsToSelector:@selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:)]) {
        constantOfPlusButtonCenterYOffset = [[self class] constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    }
    return constantOfPlusButtonCenterYOffset;
}

/**
 *  按钮选中状态下点击先显示normal状态的颜色，松开时再回到selected状态下颜色。
 *  重写此方法即不会出现上述情况，与 UITabBarButton 相似
 */
//- (void)setHighlighted:(BOOL)highlighted {}

- (CGRect)touchableRect {
    return self.frame;
}

- (UIImage *)getSnapshot {
//    return CYLExternPlusButton.imageView.image;
    if (_snapshot) {
        UIImage *originalImage = _snapshot;
        UIImage *newImage = originalImage;
        newImage =
        [UIImage imageWithCGImage:[originalImage CGImage]
                            scale:(originalImage.scale)
                      orientation:(originalImage.imageOrientation)];
        return newImage;
    }
    
    _snapshot = [self cyl_takeSnapshot];
    return _snapshot;
}

+ (UIButton *)selectedContentView {
    Class<CYLPlusButtonSubclassing> class = self;
    UIButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
    if (NO == plusButton.cyl_userInteractionDisabled) {
        // 不使用selected 以避免选中背景
        plusButton.highlighted = YES;
    }
    return plusButton;
}

- (UIButton *)selectedContentView {
    
    if (_selectedContentView) {
        return _selectedContentView;
    }
    
    if ([[self class] respondsToSelector:@selector(selectedContentView)]) {
        UIButton *button = [[self class] performSelector:@selector(selectedContentView)];
        if (button) {
            _selectedContentView = button;
            return _selectedContentView;
        }
    }
    UIButton *selectedContentView = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [selectedContentView setImage:([[self class] contentImage] ?: self.contentImage ?: UIImage.new) forState:UIControlStateNormal];
    [selectedContentView setImage:([[self class] selectedContentImage] ?: self.selectedContentImage ?: UIImage.new)
                         forState:UIControlStateHighlighted];
    CGRect bounds = self.bounds;
    selectedContentView.frame = ({
        CGRect frame = selectedContentView.frame;
        frame.size = CGSizeMake(bounds.size.width, bounds.size.height);
        frame;
    });
    selectedContentView.contentMode = UIViewContentModeCenter;
    selectedContentView.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    selectedContentView.translatesAutoresizingMaskIntoConstraints = NO;
    selectedContentView.userInteractionEnabled = false;
    [selectedContentView sizeToFit];
    if (NO == self.cyl_userInteractionDisabled) {
        // 不使用selected 以避免选中背景
        selectedContentView.highlighted = YES;
    }
    _selectedContentView = selectedContentView;
    return _selectedContentView;
}

+ (UIImage *)contentImage {
    return nil;
}

+ (UIImage *)selectedContentImage {
    return nil;
}

- (UIImage *)selectedContentImage {
    if (_selectedContentImage) {
        return _selectedContentImage;
    }
    UIImage *image = self.imageView.image;
    _selectedContentImage = image;
    return _selectedContentImage ;
}

- (UIImage *)contentImage {
    if (_contentImage) {
        return _contentImage;
    }

    UIImage *image = self.imageView.image;
    _contentImage = image;
    return _contentImage;
}

//+ (NSString *)tabBarContext {
//    return NSStringFromClass([CYLTabBarController class]);
//}

+ (BOOL)hasPlusButtonForTabBarContext:(NSString *)tabBarContext {
    NSString *matchedTabBarContext = self.matchedTabBarContext;
    BOOL isSameContext = [matchedTabBarContext isEqualToString:tabBarContext] && (matchedTabBarContext && tabBarContext);//|| (!tabBarContext  && !self.context);
    return isSameContext;
    
}

+ (BOOL)hasPlusChildViewControllerForTabBarContext:(NSString *)tabBarContext {
    NSString *context = CYLPlusChildViewController.cyl_context;
    BOOL isSameContext = ((context && tabBarContext) && [context isEqualToString:tabBarContext]);
    BOOL hasPlusChildViewController = CYLPlusChildViewController && isSameContext;//&& !isAdded;
    return hasPlusChildViewController;
}

+ (NSString *)matchedTabBarContext {
    NSString *matchedTabBarContext;
    SEL action = @selector(tabBarContext);
    if ([self respondsToSelector:action]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         matchedTabBarContext = [self performSelector:action];
         )
    }
    if (matchedTabBarContext && matchedTabBarContext.length > 0) {
        return matchedTabBarContext;
    }
    matchedTabBarContext = NSStringFromClass([CYLTabBarController class]);
    return matchedTabBarContext;
}

+ (NSUInteger)indexForTabbarItemsCount:(NSUInteger)tabbarItemsCount {
    NSUInteger plusButtonIndex = NSNotFound;

    if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
        plusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
    } else {
        if (tabbarItemsCount % 2 != 0) {
#if defined(DEBUG) || defined(BETA)
            NSAssert(NO, @"[DEBUG INFO]If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO] 如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置");
#endif
        } else {
            plusButtonIndex = tabbarItemsCount * 0.5;
        }
    }
    return plusButtonIndex;
}

@end
