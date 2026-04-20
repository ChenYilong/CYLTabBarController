//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIView+CYLTabBarControllerExtention.h"
#import "CYLPlusButton.h"
#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif
#import "NSObject+CYLTabBarControllerExtention.h"
#import <objc/runtime.h>

@implementation UIView (CYLTabBarControllerExtention)

- (BOOL)cyl_isPlusButton {
    return [self isKindOfClass:[CYLExternPlusButton class]];
}

- (BOOL)cyl_isTabButton {
    BOOL isKindOfButton;
    // iOS 26 以前，保持原逻辑
    if (![CYLConstants isUsedLiquidGlass]) {
        //UIControl
        return [self cyl_isKindOfClass:[UIControl class]];
    }
    if (CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26) {
        //UITabButton
        isKindOfButton = [self isKindOfClass:[UIControl class]];
//        BOOL result = isKindOfButton && (self.hidden == NO);
        return isKindOfButton;
    }
    //UIControl
    return [self cyl_isKindOfClass:[UIControl class]];
}

- (BOOL)cyl_isPlatterView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
   
    BOOL isKindOfPlatterView = [classString hasSuffix:@"PlatterView"] && [classString hasPrefix:@"UIKit"];
    return isKindOfPlatterView;
}

- (BOOL)cyl_isPlatterPortalView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }

    BOOL isKindOfPlatterPortalView = [self cyl_isViewPortalView:self];
    
    return isKindOfPlatterPortalView && (self.hidden == NO);
}

- (BOOL)cyl_isViewPortalView:(UIView * _Nonnull)view {
    static Class portalViewClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        portalViewClass = NSClassFromString([@[@"_", @"UI", @"Portal", @"View"] componentsJoinedByString:@""]);
    });
    if ([view isKindOfClass:portalViewClass]) {
        return true;
    } else {
        return false;
    }
}

- (BOOL)cyl_isPlatterContentView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isKindOfContentView = [classString containsString:@"ContentView"]
    && ![classString containsString:@"Selected"];
    return isKindOfContentView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterSelectedContentView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterSelectedContentView = [classString hasSuffix:@"SelectedContentView"];
    return isPlatterSelectedContentView && (self.hidden == NO);
}


- (BOOL)cyl_isPlatterVisualProviderFloatingSelectedContentView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UITab"] && [classString containsString:@"VisualProvider"] && [classString containsString:@"_Floating"] && [classString containsString:@"SelectedContentView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterLiquidLensView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"] && [classString containsString:@"View"] && ![classString containsString:@"DestOutView"]&& ![classString containsString:@"BackdropView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL) cyl_isPlatterLiquidLensClearGlassView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"] && [classString hasSuffix:@"ClearGlassView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterLiquidLensTabSelectionView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UITab"] && [classString hasSuffix:@"SelectionView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}


- (BOOL)cyl_isPlatterLiquidLensBackdropView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"]  && [classString hasSuffix:@"BackdropView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}


- (BOOL)cyl_isPlatterDestOutView {
    if (![CYLConstants isUsedLiquidGlass]) {
        // iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"] && [classString containsString:@"View"]  && [classString containsString:@"DestOutView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isTabImageView {
    BOOL isKindOfImageView = [self cyl_isKindOfClass:[UIImageView class]];
    if (!isKindOfImageView) {
        return NO;
    }
    NSString *subString = [NSString stringWithFormat:@"%@cat%@ew", @"Indi" , @"orVi"];
    BOOL isBackgroundImage = [self cyl_classStringHasSuffix:subString];
    BOOL isTabImageView = !isBackgroundImage;
    return isTabImageView;
}

- (BOOL)cyl_isTabLabel {
    BOOL isKindOfLabel;
    // iOS 26 以前，保持原逻辑
    if (![CYLConstants isUsedLiquidGlass]) {
        return [self cyl_isKindOfClass:[UILabel class]];
    }
    NSString *classString = NSStringFromClass([self class]);
    isKindOfLabel = [classString hasSuffix:@"Label"] && [classString containsString:@"TabButton"] && [classString containsString:@"_UI"];
    return isKindOfLabel;
    
}

- (BOOL)cyl_isTabBadgeView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    NSString *tabBarClassString = [NSString stringWithFormat:@"%@IB%@", @"_U" , @"adg"];
    BOOL isTabBadgeView = [self cyl_classStringHasPrefix:tabBarClassString];;
    return isTabBadgeView;
}

- (BOOL)cyl_isTabBackgroundView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    NSString *tabBackgroundViewString = [NSString stringWithFormat:@"%@IB%@", @"_U" , @"arBac"];
    BOOL isTabBackgroundView = [self cyl_classStringHasPrefix:tabBackgroundViewString] && [self cyl_classStringHasSuffix:@"nd"];
    return isTabBackgroundView;
}

- (UIImageView *)cyl_tabImageView {
    UIImageView *imageView = nil;
    do {
        
        for (UIImageView *subview in self.cyl_allSubviews) {
            if ([subview cyl_isTabImageView]) {
                imageView = (UIImageView *)subview;
                break;
            }
        }
        if (self.cyl_imageViewInTabBarButton) {
            imageView = self.cyl_imageViewInTabBarButton;
            break;
        }
     } while (false);
     
    return imageView;
}
/*!
 * 只有在TabBar选中状态下才能取到 SwappableImageView
 */
- (UIImageView *)cyl_swappableImageViewViewInTabBarButton {
    if (![self isKindOfClass:[UIView class]]) {
        return nil;
    }
    
    UIImageView *imageView = nil;
    // ② 遍历 subviews 查找
    for (UIView *subview in self.subviews) {
        NSString *classString = NSStringFromClass(subview.class);
        
        // iOS10+ 官方使用 UITabBarSwappableImageView
        if ([classString hasSuffix:@"ImageView"] && [classString hasPrefix:@"UITabB"]) {
            return (UIImageView *)subview;
        }
    }

    return imageView;
}

/*!
 * 只有在TabBar选中状态下才能取到UITabBar+SwappableImageView, 未选中状态就使用这个。
 */
- (UIImageView *)cyl_otherImageViewViewInTabBarButton {
    if (![self isKindOfClass:[UIView class]]) {
        return nil;
    }
    
    UIImageView *imageView = nil;
    // ② 遍历 subviews 查找
    for (UIView *subview in self.subviews) {
        NSString *classString = NSStringFromClass(subview.class);
        
        // iOS10+ 官方使用 SwappableImageView
        if ([classString hasSuffix:@"ImageView"] && [classString hasPrefix:@"UITabB"]) {
            return (UIImageView *)subview;
        }
        
        // 过滤掉选中背景, UITabBar+SelectionIndicatorView
        if ([subview isKindOfClass:[UIImageView class]] &&
            ![classString containsString:@"SelectionIndicatorView"]) {
            imageView = (UIImageView *)subview;
        }
    }
    return imageView;
}

- (UIImageView *)cyl_imageViewInTabBarButton {
    if (![self isKindOfClass:[UIView class]]) {
        return nil;
    }
    
    UIImageView *imageView = nil;
    
    // ① 优先尝试 KVC 直接获取（iOS 13+ 常见）
    imageView = [self cyl_valueForKey:@"imageView"];
    if ([imageView isKindOfClass:[UIImageView class]]) {
        return imageView;
    }
    
    // ② 遍历 subviews 查找
    for (UIView *subview in self.subviews) {
        NSString *classString = NSStringFromClass(subview.class);
        
        // iOS10+ 官方使用 UITabBar+SwappableImageView
        if ([classString hasPrefix:@"UITabBar"] && [classString hasSuffix:@"SwappableImageView"]) {
            return (UIImageView *)subview;
        }
        
        // 过滤掉选中背景, UITabBar+SelectionIndicatorView
        if ([subview isKindOfClass:[UIImageView class]] &&
            ![classString hasSuffix:@"SelectionIndicatorView"]&& ![classString hasPrefix:@"UITabBar"]  ) {
            imageView = (UIImageView *)subview;
        }
    }
    
    return imageView;
}

- (NSArray *)cyl_allSubviews {
    __block NSArray* allSubviews = [NSArray arrayWithObject:self];
    [self.subviews enumerateObjectsUsingBlock:^(UIView* view, NSUInteger idx, BOOL*stop) {
        allSubviews = [allSubviews arrayByAddingObjectsFromArray:[view cyl_allSubviews]];
    }];
    return allSubviews;
}

- (UIView *)cyl_tabBadgeView {
    for (UIView *subview in self.cyl_allSubviews) {
        if ([subview cyl_isTabBadgeView]) {
            return (UIView *)subview;
        }
    }
    return nil;
}

- (UILabel *)cyl_tabLabel {
    for (UILabel *subview in self.cyl_allSubviews) {
        if ([subview cyl_isTabLabel]) {
            return (UILabel *)subview;
        }
    }
    return nil;
}

//UI+Visual+EffectView
- (BOOL)cyl_isTabEffectView {
    BOOL isClass = [self isMemberOfClass:[UIVisualEffectView class]];
    return isClass;
}

//_UI+Visual+EffectContentView
- (BOOL)cyl_isTabEffectContentView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    NSString *tabBackgroundViewString = [NSString stringWithFormat:@"%@IVisualE%@", @"_U" , @"ffectC"];
    BOOL isTabBackgroundView = [self cyl_classStringHasPrefix:tabBackgroundViewString] && [self cyl_classStringHasSuffix:@"entView"];
    return isTabBackgroundView;
}

//UIVisualEffectView
- (UIVisualEffectView *)cyl_tabEffectView {
    for (UIView *subview in self.subviews) {
        if ([subview cyl_isTabEffectView]) {
            return (UIVisualEffectView *)subview;
        }
    }
    return nil;
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
- (UIView *)cyl_tabBadgeBackgroundView {
    return [self cyl_tabBackgroundView];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP
- (UIImageView *)cyl_tabShadowImageView {
    if (@available(iOS 10.0, *)) {
        //iOS10及以上这样获取ShadowImageView：
        UIView *subview = [self cyl_tabBackgroundView];
        if (!subview) {
            return nil;
        }
        NSArray<__kindof UIView *> *backgroundSubviews = subview.subviews;
        //iOS13系统backgroundSubviews.count > 1可行，12及以下就不可行了
        if (backgroundSubviews.count >= 1) {
            for (UIView *subview in backgroundSubviews) {
                if (CGRectGetHeight(subview.bounds) <= 1.0 ) {
                    return (UIImageView *)subview;
                }
            }
        }
    } else {
        //iOS9这样获取ShadowImageView：
        for (UIView *subview in self.subviews) {
            if (CGRectGetHeight(subview.bounds) <= 1.0 ) {
                return (UIImageView *)subview;
            }
        }
    }
    return nil;
}

- (UIView *)cyl_tabBackgroundView {
    for (UIImageView *subview in self.subviews) {
        if ([subview cyl_isTabBackgroundView]) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

- (BOOL)cyl_isLottieAnimationView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    Class classType = nil;
#if __has_include(<Lottie/Lottie.h>)
    classType = [LOTAnimationView class];
#else
    classType = NSClassFromString(@"LOTAnimationView");
#endif
    BOOL isLottieAnimationView = ([self isKindOfClass:classType] || [self isMemberOfClass:classType]);
    return isLottieAnimationView;
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
- (UIView *)cyl_tabBadgeBackgroundSeparator {
    return [self cyl_tabShadowImageView];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP
- (BOOL)cyl_isKindOfClass:(Class)class {
    BOOL isKindOfClass = [self isKindOfClass:class];
    BOOL isClass = [self isMemberOfClass:class];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    BOOL isTabBarClass = [self cyl_isTabBarClass];
    return isTabBarClass;
}

- (BOOL)cyl_isTabBarClass {
    NSString *tabBarClassString = [NSString stringWithFormat:@"U%@a%@ar", @"IT" , @"bB"];
    BOOL isTabBarClass = [self cyl_classStringHasPrefix:tabBarClassString];
    return isTabBarClass;
}

- (BOOL)cyl_classStringHasPrefix:(NSString *)prefix {
    NSString *classString = NSStringFromClass([self class]);
    return [classString hasPrefix:prefix];
}

- (BOOL)cyl_classStringHasSuffix:(NSString *)suffix {
    NSString *classString = NSStringFromClass([self class]);
    return [classString hasSuffix:suffix];
}

+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius {
    UIView *defaultTabBadgePointView = [[UIView alloc] init];
    [defaultTabBadgePointView setTranslatesAutoresizingMaskIntoConstraints:NO];
    defaultTabBadgePointView.backgroundColor = color;
    defaultTabBadgePointView.layer.cornerRadius = radius;
    defaultTabBadgePointView.layer.masksToBounds = YES;
    defaultTabBadgePointView.hidden = YES;
    // Width constraint
    [defaultTabBadgePointView addConstraint:[NSLayoutConstraint constraintWithItem:defaultTabBadgePointView
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute: NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1
                                                                          constant:radius * 2]];
    // Height constraint
    [defaultTabBadgePointView addConstraint:[NSLayoutConstraint constraintWithItem:defaultTabBadgePointView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute: NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1
                                                                          constant:radius * 2]];
    return defaultTabBadgePointView;
}

/*!
 *  @warning 仅对 UIBarButtonItem、UITabBarItem 有效
 *   UIBarItem 本身没有 view 属性，只有子类 UIBarButtonItem 和 UITabBarItem 才有
 *   iOS11改成了类似懒加载机制，要等到UIBarButtonItem被展示后才能获取到_view
 */
- (UIView *)cyl_contentView {
    if ([self respondsToSelector:@selector(view)]) {
        return [self cyl_valueForKey:@"view"];
    }
    return nil;
}

- (void)cyl_addPlatterViewThenBringSubviewToFront:(UIView *)view {
    if (self.cyl_tabBarController.tabBar.cyl_platterContentView) {
        [self.cyl_tabBarController.tabBar.cyl_platterView addSubview:view];
    } else {
        [self addSubview:view];
    }
    [self cyl_bringSubviewToFront:view];
}

- (BOOL)cyl_isViewAddedToPlatterView:(UIView *)view {
    if (self.cyl_tabBarController.tabBar.cyl_platterContentView) {
        return [view.superview isEqual:(self.cyl_tabBarController.tabBar.cyl_platterContentView)];
    } else {
        return [view.superview isEqual:self];
    }
}

- (void)cyl_bringSubviewToFront:(UIView *)view {
    if (self.cyl_tabBarController.tabBar.cyl_platterView) {
        [self insertSubview:view belowSubview:self.cyl_tabBarController.tabBar.cyl_platterView];
    } else {
        [self cyl_bringSubviewToTop:view];
    }
}

- (void)cyl_bringSubviewToTop:(UIView *)view {
    
    [self addSubview:view];
    [self bringSubviewToFront:view];
    view.layer.zPosition = MAXFLOAT;
}

- (void)cyl_setHidden:(BOOL)hidden {
    if (hidden) {
        self.hidden = YES;
        self.alpha = 0.0f;
    } else {
        self.hidden = NO;
        self.alpha = 1.0f;
    }
}

// helper to get pre transform frame
- (CGRect)cyl_originalFrame {
   CGAffineTransform currentTransform = self.transform;
   self.transform = CGAffineTransformIdentity;
   CGRect originalFrame = self.frame;
   self.transform = currentTransform;

   return originalFrame;
}

// helper to get point offset from center
- (CGPoint)cyl_centerOffset:(CGPoint)thePoint {
    return CGPointMake(thePoint.x - self.center.x, thePoint.y - self.center.y);
}
// helper to get point back relative to center
- (CGPoint)cyl_pointRelativeToCenter:(CGPoint)thePoint {
  return CGPointMake(thePoint.x + self.center.x, thePoint.y + self.center.y);
}

// helper to get point relative to transformed coords
- (CGPoint)cyl_newPointInView:(CGPoint)thePoint {
    // get offset from center
    CGPoint offset = [self cyl_centerOffset:thePoint];
    // get transformed point
    CGPoint transformedPoint = CGPointApplyAffineTransform(offset, self.transform);
    // make relative to center
    return [self cyl_pointRelativeToCenter:transformedPoint];
}

// now get your corners
- (CGPoint)cyl_newTopLeft {
    CGRect frame = [self cyl_originalFrame];
    return [self cyl_newPointInView:frame.origin];
}

- (CGPoint)cyl_newTopRight {
    CGRect frame = [self cyl_originalFrame];
    CGPoint point = frame.origin;
    point.x += frame.size.width;
    return [self cyl_newPointInView:point];
}

- (CGPoint)cyl_newBottomLeft {
    CGRect frame = [self cyl_originalFrame];
    CGPoint point = frame.origin;
    point.y += frame.size.height;
    return [self cyl_newPointInView:point];
}

- (CGPoint)cyl_newBottomRight {
    CGRect frame = [self cyl_originalFrame];
    CGPoint point = frame.origin;
    point.x += frame.size.width;
    point.y += frame.size.height;
    return [self cyl_newPointInView:point];
}

- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    [self cyl_performSelector:aSelector withObject:nil];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object {
    if (aSelector == NULL) { return; }
    [self cyl_performSelector:aSelector withObject:object withObject:nil];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
    if (aSelector == NULL) { return; }
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [self performSelector:aSelector withObject:object1 withObject:object2];
     )
    return;
    
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    
     
    UIControl *selfControl = nil;
    
    
    if ([self cyl_isTabButton]) {
        selfControl = (UIControl *)self;
    } else if (self.superview && [self.superview cyl_isTabButton]) {
        selfControl = (UIControl *)self.superview;
    } else if (self.superview.superview && [self.superview.superview cyl_isTabButton]) {
        selfControl = (UIControl *)self.superview.superview;
    }
    
    
    if (![selfControl isKindOfClass:[UIControl class]]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [selfControl performSelector:aSelector withObject:object1 withObject:object2];
         )
        return;
    }
    if ([selfControl cyl_isPlatterSelectedControl]) {
        selectedControl = selfControl;
    } else {
        normalControl = selfControl;
    }
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     if (normalControl) {
         [normalControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = normalControl.cyl_platterSelectedControl;
         if (counterpart) {
             [counterpart performSelector:aSelector withObject:object1 withObject:object2];
         }
     } else if (selectedControl) {
         [selectedControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = selectedControl.cyl_platterNormalControl;
         if (counterpart) {
             [counterpart performSelector:aSelector withObject:object1 withObject:object2];
         }
     }
     );
}

- (id)cyl_invokeSelector:(SEL)selector
            withVAList:(va_list)args
         argumentCount:(NSUInteger)argumentCount {

    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    if (!signature) { return nil; }

    // ✅ Guard: explicit args in signature must match what caller provides
    NSUInteger expectedExplicitArgs = signature.numberOfArguments - 2; // minus self + _cmd
    NSUInteger safeArgCount = MIN(argumentCount, expectedExplicitArgs);

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = self;
    invocation.selector = selector;

    for (NSUInteger i = 0; i < safeArgCount; i++) {
        void *arg = va_arg(args, void *);
        [invocation setArgument:&arg atIndex:i + 2];
    }

    [invocation invoke];

    const char *returnType = signature.methodReturnType;
    if (strcmp(returnType, @encode(id)) == 0 || cyl_isObjectTypeEncoding(returnType)) {
        void *rawReturn = NULL;
        [invocation getReturnValue:&rawReturn];
        return (__bridge id)rawReturn;
    }
    return nil;
}

- (id)cyl_invokeSelector:(SEL)selector withArguments:(void *)firstArgument, ... {
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    if (!signature) { return nil; }

    NSUInteger totalArgs = signature.numberOfArguments;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = self;
    invocation.selector = selector;

    if (totalArgs > 2) {
        [invocation setArgument:&firstArgument atIndex:2];

        va_list args;
        va_start(args, firstArgument);
        for (NSUInteger i = 3; i < totalArgs; i++) {
            void *arg = va_arg(args, void *);
            [invocation setArgument:&arg atIndex:i];
        }
        va_end(args);
    }

    [invocation invoke];

    const char *returnType = signature.methodReturnType;
    if (strcmp(returnType, @encode(id)) == 0 || cyl_isObjectTypeEncoding(returnType)) {
        void *rawReturn = NULL;
        [invocation getReturnValue:&rawReturn];
        return (__bridge id)rawReturn;
    }
    return nil;
}

- (void)cyl_invokeSelector:(SEL)selector withPrimitiveReturnValue:(void *)returnValue {
    [self cyl_invokeSelector:selector withPrimitiveReturnValue:returnValue arguments:nil];
}

- (void)cyl_invokeSelector:(SEL)selector withPrimitiveReturnValue:(void *)returnValue arguments:(void *)firstArgument, ... {
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
    if (!methodSignature) { return; }
//    CYLAssert(methodSignature, @"NSObject (CYL)", @"- [%@ cyl_performSelector:@selector(%@)] 失败，方法不存在。", NSStringFromClass(self.class), NSStringFromSelector(selector));
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    
    if (firstArgument) {
        va_list valist;
        va_start(valist, firstArgument);
        [invocation setArgument:firstArgument atIndex:2];// 0->self, 1->_cmd
        
        void *currentArgument;
        NSInteger index = 3;
        while ((currentArgument = va_arg(valist, void *))) {
            [invocation setArgument:currentArgument atIndex:index];
            index++;
        }
        va_end(valist);
    }
    
    [invocation invoke];
    
    if (returnValue) {
        [invocation getReturnValue:returnValue];
    }
}

- (UIImage *)cyl_takeSnapshot {
    NSArray *withoutView = [NSArray new];
    UIView *platterView = self.cyl_tabBarController.tabBar.cyl_platterView;
    if (platterView) {
        withoutView = @[platterView];
    } else {
        return nil;
    }
    return [self cyl_takeSnapshotWithoutViews:withoutView];
}

- (UIImage *)cyl_takeSnapshotWithoutViews:(NSArray<UIView __kindof *> *)hideViews {
    // excluded view
    [hideViews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull hideView, NSUInteger idx, BOOL * _Nonnull stop) {
        [hideView cyl_setHidden:YES];
    }];
    

    UIImage *image ;
    // begin
    //size:指定建立出來的bitmap大小
    //opaque:true為透明,false為不透明 self.opaque
    //scale:縮放,0為不縮放
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0f);
    
    // draw view in that context.
    //afterScreenUpdates:是否重繪畫面
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    image = UIGraphicsGetImageFromCurrentImageContext();//取得UIGraphicsBeginImageContext所創的bitmap
    UIGraphicsEndImageContext();// //清除UIGraphicsBeginImageContext產生的context
    
    [hideViews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull hideView, NSUInteger idx, BOOL * _Nonnull stop) {
        [hideView cyl_setHidden:NO];
    }];
    
    
    return image;
}
/*!
 * if([UIScreen mainScreen].scale > 1)
    {
        thumbnailImage = [self thumbnailImage newSize:CGSizeMake(thumbnailImage.size.width/[UIScreen       mainScreen].scale, thumbnailImage.size.height/[UIScreen mainScreen].scale)];
    }
 */
- (UIImage *)cyl_resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);

    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();

    return newImage;
}


@end

