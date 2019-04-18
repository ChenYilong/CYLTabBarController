//
//  CYLTabBar.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBar.h"
#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import "CYLConstants.h"
#import <objc/runtime.h>
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"

static void *const CYLTabBarContext = (void*)&CYLTabBarContext;

/**
 *  用 block 重写某个 class 的指定方法
 *  @param targetClass 要重写的 class
 *  @param targetSelector 要重写的 class 里的实例方法，注意如果该方法不存在于 targetClass 里，则什么都不做
 *  @param implementationBlock 该 block 必须返回一个 block，返回的 block 将被当成 targetSelector 的新实现，所以要在内部自己处理对 super 的调用，以及对当前调用方法的 self 的 class 的保护判断（因为如果 targetClass 的 targetSelector 是继承自父类的，targetClass 内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的 targetSelector，所以会产生预期之外的 class 的影响，例如 targetClass 传进来  UIButton.class，则最终可能会影响到 UIView.class），implementationBlock 的参数里第一个为你要修改的 class，也即等同于 targetClass，第二个参数为你要修改的 selector，也即等同于 targetSelector，第三个参数是 targetSelector 原本的实现，由于 IMP 可以直接当成 C 函数调用，所以可利用它来实现“调用 super”的效果，但由于 targetSelector 的参数个数、参数类型、返回值类型，都会影响 IMP 的调用写法，所以这个调用只能由业务自己写。
 *  解决方案来源声明。该解决方案及所使用的代码，来自于 QMUI iOS(https://github.com/QMUI/QMUI_iOS)。
 */
CG_INLINE BOOL
OverrideImplementation(Class targetClass, SEL targetSelector, id (^implementationBlock)(Class originClass, SEL originCMD, IMP originIMP)) {
    Method originMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (!originMethod) {
        return NO;
    }
    IMP originIMP = method_getImplementation(originMethod);
    method_setImplementation(originMethod, imp_implementationWithBlock(implementationBlock(targetClass, targetSelector, originIMP)));
    return YES;
}

@interface CYLTabBar ()

/** 发布按钮 */
@property (nonatomic, strong) UIButton<CYLPlusButtonSubclassing> *plusButton;
@property (nonatomic, assign) CGFloat tabBarItemWidth;
@property (nonatomic, copy) NSArray<UIControl *> *tabBarButtonArray;
@property (nonatomic, assign, getter=hasAddPlusButton) BOOL addPlusButton;

@end

@implementation CYLTabBar
@synthesize plusButton = _plusButton;

#pragma mark -
#pragma mark - LifeCycle Method

static CGFloat const CYLIPhoneXTabbarButtonHeight = 48;
static CGFloat const CYLIPhoneXTabbarButtonSafeAreaHeight = 35;

+ (void)load {
    /* 这个问题是iOS12.1出现的问题, iOS 12.1.1已修复，只要 UITabBar 是磨砂的，并且 push viewController 时 hidesBottomBarWhenPushed = YES 则手势返回的时候就会触发。(来源于QMUIKit的处理方式)*/
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.1") && CYL_SYSTEM_VERSION_LESS_THAN(@"12.1.1"))  {
            NSString *tabbarButtonString = [NSString stringWithFormat:@"U%@abB%@utton", @"IT", @"arB"];
            OverrideImplementation(NSClassFromString(tabbarButtonString), @selector(setFrame:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP originIMP) {
                return ^(UIView *selfObject, CGRect firstArgv) {
                    if ([selfObject isKindOfClass:originClass]) {
                        
                        // 如果发现即将要设置一个 size 为空的 frame，则屏蔽掉本次设置
                        if (!CGRectIsEmpty(selfObject.frame) && CGRectIsEmpty(firstArgv)) {
                            return;
                        }
                        
                        // 兼容 iOS 12 的 iPhoneX
                        CGFloat tabBarHeight = firstArgv.size.height;
                        CGFloat realTabBarHeight = CYLTabBarHeight ? (CYLTabBarHeight - CYLIPhoneXTabbarButtonSafeAreaHeight): CYLIPhoneXTabbarButtonHeight;
                        if (CYL_IS_IPHONE_X && (tabBarHeight != realTabBarHeight)) {
                            firstArgv.size.height = realTabBarHeight;
                        }
                    }
                    // call super
                    void (*originSelectorIMP)(id, SEL, CGRect);
                    originSelectorIMP = (void (*)(id, SEL, CGRect))originIMP;
                    originSelectorIMP(selfObject, originCMD, firstArgv);
                };
            });
        }
    });
}

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
        NSString *tabBarContext = self.tabBarContext;
        BOOL isFirstAdded = (_plusButton.superview == nil);
        
        BOOL isSameContext = [tabBarContext isEqualToString:self.context] && (tabBarContext && self.context);
        if (_plusButton && isSameContext && isFirstAdded) {
            [self addSubview:(UIButton *)_plusButton];
            [_plusButton cyl_setTabBarController: [self cyl_tabBarController]];
        }
        self.addPlusButton = YES;
    }
}

- (void)setContext:(NSString *)context {
    _context = context;
    self.plusButton = CYLExternPlusButton;
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
        sizeThatFits.height = [self cyl_tabBarController].tabBarHeight;
    }
    return sizeThatFits;
}

/**
 *  lazy load tabBarButtonArray
 *
 *  @return NSArray
 */
- (NSArray *)tabBarButtonArray {
    if (_tabBarButtonArray == nil) {
        _tabBarButtonArray = @[];
    }
    return _tabBarButtonArray;
}

- (NSString *)tabBarContext {
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
    NSString *tabBarContext = self.tabBarContext;
    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    BOOL isSameContext = [tabBarContext isEqualToString:self.context] && (tabBarContext && self.context);;//|| (!tabBarContext  && !self.context);
    if (_plusButton  &&  addedToTabBar && isSameContext) {
        return _plusButton;
    }
    return nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tabBarButtonArray = [self cyl_originalTabBarButtons];
    if (self.tabBarButtonArray.count == 0) {
        return;
    }
    [self setupTabImageViewDefaultOffset:self.tabBarButtonArray[0]];
    CGFloat tabBarWidth = self.bounds.size.width;
    CGFloat tabBarHeight = self.bounds.size.height;
    
    if (!CYLExternPlusButton) {
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
    CGFloat multiplierOfTabBarHeight = [self multiplierOfTabBarHeight:tabBarHeight];
    CGFloat constantOfPlusButtonCenterYOffset = [self constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    _plusButton.center = CGPointMake(tabBarWidth * 0.5, tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset);
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
        [self changeXForChildView:childView
                       childViewX:childViewX
                  tabBarItemWidth:tabBarItemWidth
                            index:visiableTabIndex
         ];
        //仅修改childView的x和宽度,yh值不变
    }];
    //bring the plus button to top
    [self bringSubviewToFront:_plusButton];
}

- (void)changeXForChildView:(UIControl *)childView
                 childViewX:(CGFloat)childViewX
            tabBarItemWidth:(CGFloat)tabBarItemWidth
                      index:(NSUInteger)index {
    //仅修改childView的x和宽度,yh值不变
    childView.frame = CGRectMake(childViewX,
                                 CGRectGetMinY(childView.frame),
                                 tabBarItemWidth,
                                 CGRectGetHeight(childView.frame)
                                 );
    [childView cyl_setTabBarItemVisibleIndex:index];
}

#pragma mark -
#pragma mark - Private Methods

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return NO;
}

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != CYLTabBarContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == CYLTabBarContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemWidthDidChangeNotification object:self];
        if (CYL_IS_IPHONE_X) {
            [self layoutIfNeeded];
        }
    }
}

- (void)dealloc {
    // KVO反注册
    [self removeObserver:self forKeyPath:@"tabBarItemWidth"];
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
    CGFloat multiplierOfTabBarHeight;
    if ([[self.plusButton class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
        multiplierOfTabBarHeight = [[self.plusButton class] multiplierOfTabBarHeight:tabBarHeight];
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    else if ([[self.plusButton class] respondsToSelector:@selector(multiplerInCenterY)]) {
        multiplierOfTabBarHeight = [[self.plusButton class] multiplerInCenterY];
    }
#pragma clang diagnostic pop
    
    else {
        CGSize sizeOfPlusButton = self.plusButton.frame.size;
        CGFloat heightDifference = sizeOfPlusButton.height - self.bounds.size.height;
        if (heightDifference < 0) {
            multiplierOfTabBarHeight = 0.5;
        } else {
            CGPoint center = CGPointMake(self.bounds.size.height * 0.5, self.bounds.size.height * 0.5);
            center.y = center.y - heightDifference * 0.5;
            multiplierOfTabBarHeight = center.y / self.bounds.size.height;
        }
    }
    return multiplierOfTabBarHeight;
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
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
            [NSException raise:NSStringFromClass([CYLTabBarController class]) format:@"If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
        }
        plusButtonIndex = CYLTabbarItemsCount * 0.5;
    }
    CGFloat childViewX = plusButtonIndex * CYLTabBarItemWidth;
    CGFloat tabBarItemWidth = CGRectGetWidth(self.plusButton.frame);
    [self changeXForChildView:self.plusButton
                   childViewX:childViewX
              tabBarItemWidth:tabBarItemWidth
                        index:plusButtonIndex
     ];
    CYLPlusButtonIndex = plusButtonIndex;
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
        return nil;
    }
    
    //2. 优先处理 PlusButton （包括其突出的部分）、TabBarItems 未凸出的部分
    //这一步主要是在处理只有两个 TabBarItems 的场景。
    // 2.1先考虑clipsToBounds情况：子view超出部分没有显示出来
    if (self.clipsToBounds && ![self pointInside:point withEvent:event]) {
        return nil;
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
    return nil;
}

// In iOS 11, UITabBarItem's have the title to the right of the icon in horizontally regular environments
// (i.e. the iPad).  In order to keep the title below the icon, it was necessary to subclass UITabBar and override
// traitCollection to make it horizontally compact.

- (UITraitCollection *)traitCollection {
    return [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
}

@end
