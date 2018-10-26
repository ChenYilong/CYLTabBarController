//
//  CYLTabBar.m
//  CYLCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBar.h"
#import "CYLPlusButton.h"
#import "CYLTabBarController.h"

/**
 *  用 block 重写某个 class 的指定方法
 *  @param targetClass 要重写的 class
 *  @param targetSelector 要重写的 class 里的实例方法，注意如果该方法不存在于 targetClass 里，则什么都不做
 *  @param implementationBlock 该 block 必须返回一个 block，返回的 block 将被当成 targetSelector 的新实现，所以要在内部自己处理对 super 的调用，以及对当前调用方法的 self 的 class 的保护判断（因为如果 targetClass 的 targetSelector 是继承自父类的，targetClass 内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的 targetSelector，所以会产生预期之外的 class 的影响，例如 targetClass 传进来  UIButton.class，则最终可能会影响到 UIView.class），implementationBlock 的参数里第一个为你要修改的 class，也即等同于 targetClass，第二个参数为你要修改的 selector，也即等同于 targetSelector，第三个参数是 targetSelector 原本的实现，由于 IMP 可以直接当成 C 函数调用，所以可利用它来实现“调用 super”的效果，但由于 targetSelector 的参数个数、参数类型、返回值类型，都会影响 IMP 的调用写法，所以这个调用只能由业务自己写。
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


static void * const CYLTabBarContext = (void*)&CYLTabBarContext;

@interface CYLTabBar ()

/** 发布按钮 */
@property (nonatomic, strong) UIButton<CYLPlusButtonSubclassing> *plusButton;

@end

@implementation CYLTabBar
    
+ (void)load
{
    /* 这个问题是 iOS 12.1 Beta 2 的问题，只要 UITabBar 是磨砂的，并且 push viewController 时 hidesBottomBarWhenPushed = YES 则手势返回的时候就会触发。
    
    出现这个现象的直接原因是 tabBar 内的按钮 UITabBarButton 被设置了错误的 frame，frame.size 变为 (0, 0) 导致的。如果12.1正式版Apple修复了这个bug可以移除调这段代码(来源于QMUIKit的处理方式)*/
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            if (@available(iOS 12.1, *)) {
                OverrideImplementation(NSClassFromString(@"UITabBarButton"), @selector(setFrame:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP originIMP) {
                    return ^(UIView *selfObject, CGRect firstArgv) {
    
                        if ([selfObject isKindOfClass:originClass]) {
                            // 如果发现即将要设置一个 size 为空的 frame，则屏蔽掉本次设置
                            if (!CGRectIsEmpty(selfObject.frame) && CGRectIsEmpty(firstArgv)) {
                                return;
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

- (void)dealloc {
    // KVO反注册
    [self removeObserver:self forKeyPath:@"plusButton"];
}

- (instancetype)sharedInit {
    self.plusButton = CYLExternPlusButton;
    if (self.plusButton) {
        [self addSubview:(UIButton *)self.plusButton];
    }
    [self setNeedsLayout];
    // KVO注册
    [self addObserver:self forKeyPath:@"plusButton" options:NSKeyValueObservingOptionNew context:CYLTabBarContext];
    [self setBackgroundImage:[self imageWithColor:[UIColor whiteColor]]];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
//    if (!CYLExternPlusButton) {
//        return;
//    }
    CGFloat barWidth = self.frame.size.width;
    CGFloat barHeight = self.frame.size.height;
    
    CGFloat tabBarButtonW = (CGFloat) barWidth / [CYLTabBarController allItemsInTabBarCount];
    NSInteger buttonIndex = 0;
    CGFloat multiplerInCenterY;
    if ([[self.plusButton class] respondsToSelector:@selector(multiplerInCenterY)]) {
        multiplerInCenterY = [[self.plusButton class] multiplerInCenterY];
    } else {
        CGSize sizeOfPlusButton = self.plusButton.frame.size;
        CGFloat heightDifference = sizeOfPlusButton.height - self.bounds.size.height;
        if (heightDifference < 0) {
            multiplerInCenterY = 0.5;
        } else {
            CGPoint center = CGPointMake(self.bounds.size.height / 2.0f, self.bounds.size.height / 2.0f);
            center.y = center.y - heightDifference / 2.0f;
            multiplerInCenterY = center.y / self.bounds.size.height;
        }
    }
    
    self.plusButton.center = CGPointMake(barWidth * 0.5, barHeight * multiplerInCenterY);
    
    NSUInteger plusButtonIndex;
    if ([[self.plusButton class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
        if (CYLTabbarItemsCount % 2 == 0) {
            [NSException raise:@"CYLTabBarController" format:@"If the count of CYLTabbarControllers is not odd,there's no need to realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】如果CYLTabbarControllers的个数不是奇数，会自动居中，你无需在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
        }
        plusButtonIndex = [[self.plusButton class] indexOfPlusButtonInTabBar];
        //仅修改self.plusButton的x,ywh值不变
        self.plusButton.frame = CGRectMake(plusButtonIndex * tabBarButtonW,
                                           CGRectGetMinY(self.plusButton.frame),
                                           CGRectGetWidth(self.plusButton.frame),
                                           CGRectGetHeight(self.plusButton.frame)
                                           );
    } else {
        if (CYLTabbarItemsCount % 2 != 0) {
            [NSException raise:@"CYLTabBarController" format:@"If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
        }
        plusButtonIndex = CYLTabbarItemsCount / 2.0;
    }
    /* NOTE: If the `self.title of ViewController` and `the correct title of tabBarItemsAttributes` are different, Apple will delete the correct tabBarItem from subViews, and then trigger `-layoutSubviews`, therefore subViews will be in disorder. So we need to rearrange them.*/
    NSArray *sortedSubviews = [self.subviews sortedArrayUsingComparator:^NSComparisonResult(UIView * view1, UIView * view2) {
        CGFloat view1_x = view1.frame.origin.x;
        CGFloat view2_x = view2.frame.origin.x;
        if (view1_x > view2_x) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    for (UIView *childView in sortedSubviews) {
        //调整加号按钮后面的UITabBarItem的位置
        if ([childView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            if (buttonIndex == plusButtonIndex) {
                buttonIndex++;
            }
            //仅修改childView的x和宽度,yh值不变
            childView.frame = CGRectMake(buttonIndex * tabBarButtonW,
                                         CGRectGetMinY(childView.frame),
                                         tabBarButtonW,
                                         CGRectGetHeight(childView.frame)
                                         );
            buttonIndex++;
        }
    }
    //bring the plus button to top
    [self bringSubviewToFront:self.plusButton];
}

/**
 *  Capturing touches on a subview outside the frame of its superview
 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
        UIView *result = [super hitTest:point withEvent:event];
        if (result) {
            return result;
        } else {
            for (UIView *subview in self.subviews.reverseObjectEnumerator) {
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                result = [subview hitTest:subPoint withEvent:event];
                if (result) {
                    return result;
                }
            }
        }
    }
    return nil;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    NSParameterAssert(color != nil);
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)removePlusButton {
    CYLExternPlusButton = nil;
    [self.plusButton removeFromSuperview];
    self.plusButton = nil;
}

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != CYLTabBarContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == CYLTabBarContext) {
        //if ([keyPath isEqualToString:@"plusButton"]) {
        UIButton *newKey = change[NSKeyValueChangeNewKey];
        if((!newKey) || (newKey == [NSNull null])) {
            [self.plusButton removeFromSuperview];
        }
        [self layoutSubviews];
    }
}

@end
