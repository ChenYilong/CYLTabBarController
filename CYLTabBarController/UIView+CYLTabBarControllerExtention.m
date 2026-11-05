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

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
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
    // A plus button of any registered context, not only the one registered last.
    return [CYLPlusButton isPlusButtonView:self];
}

- (BOOL)cyl_isRightToLeftLayout {
    return self.effectiveUserInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (BOOL)cyl_isTabButton {
    BOOL isKindOfButton;
    NSString *classString = NSStringFromClass([self class]);
    //fix issue #641
    BOOL isTabButton = [classString hasSuffix:@"BarButton"] && [classString hasPrefix:@"UITab"];
    if (isTabButton) { return isTabButton; }
    
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，保持原逻辑
        // [EN] Before iOS 26, keep the original logic
        //UIControl
        NSString *classString = NSStringFromClass([self class]);
        BOOL isTabButton = [classString hasSuffix:@"BarButton"] && [classString hasPrefix:@"UITab"];
        return isTabButton || [self cyl_isKindOfClass:[UIControl class]];
    }
    if (CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26) {
        //UITabButton
        isKindOfButton = [self isKindOfClass:[UIControl class]];
        //        BOOL result = isKindOfButton && (self.hidden == NO);
        return isKindOfButton;
    }
    // [CN] UIControl 扁平或者玻璃样式共用
    // [EN] UIControl is shared by the flat design and glass styles
    return [self isKindOfClass:[UIControl class]];
}

- (BOOL)cyl_isPlatterView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
   
    BOOL isKindOfPlatterView = [classString hasSuffix:@"PlatterView"] && [classString hasPrefix:@"UIKit"];
    return isKindOfPlatterView;
}

- (BOOL)cyl_isPlatterPortalView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }

    BOOL isKindOfPlatterPortalView = [self cyl_isViewPortalView:self];
    
    return isKindOfPlatterPortalView;
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
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isKindOfContentView = [classString containsString:@"ContentView"]
    && ![classString containsString:@"Selected"];
    return isKindOfContentView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterSelectedContentView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterSelectedContentView = [classString hasSuffix:@"SelectedContentView"];
    return isPlatterSelectedContentView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterVisualProviderFloatingSelectedContentView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UITab"] && [classString containsString:@"VisualProvider"] && [classString containsString:@"_Floating"] && [classString containsString:@"SelectedContentView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterLiquidLensView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"] && [classString containsString:@"View"] && ![classString containsString:@"DestOutView"]&& ![classString containsString:@"BackdropView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL) cyl_isPlatterLiquidLensClearGlassView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"] && [classString hasSuffix:@"ClearGlassView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterLiquidLensTabSelectionView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UITab"] && [classString hasSuffix:@"SelectionView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterLiquidLensBackdropView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"]  && [classString hasSuffix:@"BackdropView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isPlatterDestOutView {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] iOS 26 以前，或者UI兼容模式，不再继续判断逻辑
        // [EN] Before iOS 26, or in UI compatibility mode, skip the remaining checks
        return NO;
    }
    NSString *classString = NSStringFromClass([self class]);
    BOOL isPlatterLiquidLensView = [classString hasPrefix:@"_UI"] && [classString containsString:@"LiquidLens"] && [classString containsString:@"View"]  && [classString containsString:@"DestOutView"];
    
    return isPlatterLiquidLensView && (self.hidden == NO);
}

- (BOOL)cyl_isTabBarItemIconView {
    return [objc_getAssociatedObject(self, @selector(cyl_isTabBarItemIconView)) boolValue];
}

- (void)cyl_setTabBarItemIconView:(BOOL)tabBarItemIconView {
    objc_setAssociatedObject(self, @selector(cyl_isTabBarItemIconView), @(tabBarItemIconView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_isTabButtonCoverView {
    return [objc_getAssociatedObject(self, @selector(cyl_isTabButtonCoverView)) boolValue];
}

- (void)cyl_setTabButtonCoverView:(BOOL)tabButtonCoverView {
    objc_setAssociatedObject(self, @selector(cyl_isTabButtonCoverView), (tabButtonCoverView ? @YES : nil), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_isTabImageView {
    BOOL isKindOfImageView = [self cyl_isKindOfClass:[UIImageView class]];
    if (!isKindOfImageView) {
        return NO;
    }
    // [EN] Issue #601: a view shown in place of the icon, or inside one, is not the tab's icon.
    // [CN] 替换图标的视图（或其子视图）不是 Tab 的图标。
    for (UIView *view = (UIView *)self; view && ![view isKindOfClass:[UIControl class]]; view = view.superview) {
        if (view.cyl_isTabBarItemIconView) {
            return NO;
        }
    }
    NSString *subString = [NSString stringWithFormat:@"%@cat%@ew", @"Indi" , @"orVi"];
    BOOL isBackgroundImage = [self cyl_classStringHasSuffix:subString];
    BOOL isTabImageView = !isBackgroundImage;
    return isTabImageView;
}

- (BOOL)cyl_isTabLabel {
    BOOL isKindOfLabel;
    // [CN] iOS 26 以前，保持原逻辑
    // [EN] Before iOS 26, keep the original logic
    if (![CYLConstants isLiquidGlassActive]) {
        return [self cyl_isKindOfClass:[UILabel class]];
    }
    NSString *classString = NSStringFromClass([self class]);
    isKindOfLabel = [classString hasSuffix:@"Label"] && [classString containsString:@"TabButton"] && [classString containsString:@"_UI"];
    if (isKindOfLabel) {
        return isKindOfLabel;
    }
    return [self isKindOfClass:[UILabel class]];
    
}

- (BOOL)cyl_isButtonLabel {
    BOOL isButtonLabel;
    // [CN] iOS 26 以前，保持原逻辑
    // [EN] Before iOS 26, keep the original logic
    NSString *classString = NSStringFromClass([self class]);
    isButtonLabel = [classString hasSuffix:@"Label"] && [classString hasPrefix:@"UIButton"];
    return isButtonLabel;
    
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

- (nullable UIImageView *)cyl_imageView {
    for (UIImageView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

- (nullable UIImageView *)cyl_tabImageView {
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
 * [CN] 只有在TabBar选中状态下才能取到 SwappableImageView
 * [EN] SwappableImageView can only be obtained when the TabBar item is selected
 */
- (nullable UIImageView *)cyl_swappableImageViewViewInTabBarButton {
    if (![self isKindOfClass:[UIView class]]) {
        return nil;
    }
    
    UIImageView *imageView = nil;
    // [CN] ② 遍历 subviews 查找
    // [EN] ② Search through subviews
    for (UIView *subview in self.subviews) {
        NSString *classString = NSStringFromClass(subview.class);
        
        // [CN] iOS10+ 官方使用 UITabBarSwappableImageView
        // [EN] iOS10+ officially uses UITabBarSwappableImageView
        if ([classString hasSuffix:@"ImageView"] && [classString hasPrefix:@"UITabB"]) {
            return (UIImageView *)subview;
        }
    }

    return imageView;
}

/*!
 * [CN] 只有在TabBar选中状态下才能取到UITabBar+SwappableImageView, 未选中状态就使用这个。
 * [EN] UITabBar+SwappableImageView can only be obtained when the TabBar item is selected; use this one when it is
 *      not selected.
 */
- (UIImageView *)cyl_otherImageViewViewInTabBarButton {
    if (![self isKindOfClass:[UIView class]]) {
        return nil;
    }
    
    UIImageView *imageView = nil;
    // [CN] ② 遍历 subviews 查找
    // [EN] ② Search through subviews
    for (UIView *subview in self.subviews) {
        NSString *classString = NSStringFromClass(subview.class);
        
        // [CN] iOS10+ 官方使用 SwappableImageView
        // [EN] iOS10+ officially uses SwappableImageView
        if ([classString hasSuffix:@"ImageView"] && [classString hasPrefix:@"UITabB"]) {
            return (UIImageView *)subview;
        }
        
        // [CN] 过滤掉选中背景, UITabBar+SelectionIndicatorView
        // [EN] Filter out the selection background, UITabBar+SelectionIndicatorView
        if ([subview isKindOfClass:[UIImageView class]] &&
            ![classString containsString:@"SelectionIndicatorView"]) {
            imageView = (UIImageView *)subview;
        }
    }
    return imageView;
}

- (nullable UIImageView *)cyl_imageViewInTabBarButton {
    if (![self isKindOfClass:[UIView class]]) {
        return nil;
    }
    
    UIImageView *imageView = nil;
    
    // [CN] ① 优先尝试 KVC 直接获取（iOS 13+ 常见）
    // iOS 26+ 的 _UITabButton 没有 imageView 这个 KVC key，valueForKey: 会抛 NSUnknownKeyException。
    // 后面的子视图查找仍然适用，这里直接跳过。
    // [EN] ① First try to get it directly via KVC (common on iOS 13+)
    //      On iOS 26+, _UITabButton has no imageView KVC key, so valueForKey: throws NSUnknownKeyException.
    //      The subview search below still works, so skip this step here.
    if (![NSStringFromClass(self.class) isEqualToString:@"_UITabButton"]) {
        imageView = [self cyl_valueForKey:@"imageView"];
        if ([imageView isKindOfClass:[UIImageView class]]) {
            return imageView;
        }
    }
    
    // [CN] ② 遍历 subviews 查找
    // [EN] ② Search through subviews
    for (UIView *subview in self.subviews) {
        NSString *classString = NSStringFromClass(subview.class);
        
        // [CN] iOS10+ 官方使用 UITabBar+SwappableImageView
        // [EN] iOS10+ officially uses UITabBar+SwappableImageView
        if ([classString hasPrefix:@"UITabBar"] && [classString hasSuffix:@"SwappableImageView"]) {
            return (UIImageView *)subview;
        }
        
        // [CN] 过滤掉选中背景, UITabBar+SelectionIndicatorView
        // [EN] Filter out the selection background, UITabBar+SelectionIndicatorView
        // [EN] Not a view shown in place of the icon (issue #601). [CN] 不包括替换图标显示的视图。
        if ([subview isKindOfClass:[UIImageView class]] && !subview.cyl_isTabBarItemIconView &&
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

- (nullable UIView *)cyl_tabBadgeView {
    for (UIView *subview in self.cyl_allSubviews) {
        if ([subview cyl_isTabBadgeView]) {
            return subview;
        }
    }
    return nil;
}

- (nullable UILabel *)cyl_tabLabel {
    //`cyl_allSubviews` holds UIViews: iterate them as UIView, not UILabel, and cast once, after `cyl_isTabLabel`.
    for (UIView *subview in self.cyl_allSubviews) {
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
- (nullable UIVisualEffectView *)cyl_tabEffectView {
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
- (nullable UIImageView *)cyl_tabShadowImageView {
    if (@available(iOS 10.0, *)) {
        // [CN] iOS10及以上这样获取ShadowImageView：
        // [EN] On iOS10 and later, get the ShadowImageView like this:
        UIView *subview = [self cyl_tabBackgroundView];
        if (!subview) {
            return nil;
        }
        NSArray<__kindof UIView *> *backgroundSubviews = subview.subviews;
        // [CN] iOS13系统backgroundSubviews.count > 1可行，12及以下就不可行了
        // [EN] backgroundSubviews.count > 1 works on iOS13, but not on iOS12 and earlier
        if (backgroundSubviews.count >= 1) {
            for (UIView *subview in backgroundSubviews) {
                if (CGRectGetHeight(subview.bounds) <= 1.0 ) {
                    return (UIImageView *)subview;
                }
            }
        }
    } else {
        // [CN] iOS9这样获取ShadowImageView：
        // [EN] On iOS9, get the ShadowImageView like this:
        for (UIView *subview in self.subviews) {
            if (CGRectGetHeight(subview.bounds) <= 1.0 ) {
                return (UIImageView *)subview;
            }
        }
    }
    return nil;
}

- (nullable UIView *)cyl_tabBackgroundView {
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
    // Prefer Objective-C Lottie class when available at compile time
    Class swiftCompatClass = NSClassFromString(@"LOTAnimationView");
    if (swiftCompatClass) {
        classType = swiftCompatClass;
    }
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
    // Avoid sending messages to a forward-declared class; resolve at runtime instead
    NSString *swiftCompatClassString = @"CYLCompatibleLOTAnimationView";

    if ( [NSStringFromClass([self class]) containsString:swiftCompatClassString]) {
        return YES;
    }
#endif

    if (!classType) {
        return NO;
    }
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

/*!
 * [CN] @warning 仅对 UIBarButtonItem、UITabBarItem 有效
 *   UIBarItem 本身没有 view 属性，只有子类 UIBarButtonItem 和 UITabBarItem 才有
 *   iOS11改成了类似懒加载机制，要等到UIBarButtonItem被展示后才能获取到_view
 * [EN] @warning Only works for UIBarButtonItem and UITabBarItem
 *      UIBarItem itself has no view property; only its subclasses UIBarButtonItem and UITabBarItem do
 *      Since iOS11 this works like lazy loading: _view is only available after the UIBarButtonItem is displayed
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

- (nullable UIImage *)cyl_takeSnapshot {
    UIView *platterView = self.cyl_tabBarController.tabBar.cyl_platterView;
    if (!platterView) {
        return nil;
    }
    return [self cyl_takeSnapshotWithoutViews:@[platterView]];
}

- (nullable UIImage *)cyl_takeSnapshotWithoutViews:(NSArray<UIView __kindof *> *)hideViews {
    CGSize size = self.bounds.size;
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }
    // Hide the excluded views, then restore each one: a view that was hidden already must stay hidden.
    // 隐藏要排除的视图，之后逐个恢复：原本就隐藏的视图必须保持隐藏。
    NSMutableArray<UIView *> *viewsToRestore = [NSMutableArray arrayWithCapacity:hideViews.count];
    for (UIView *hideView in hideViews) {
        if (!hideView.isHidden) {
            [viewsToRestore addObject:hideView];
            [hideView cyl_setHidden:YES];
        }
    }
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    }];
    for (UIView *hideView in viewsToRestore) {
        [hideView cyl_setHidden:NO];
    }
    return image;
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius {
    // FIX: issue #653 — fixed frame instead of width/height constraints (constraints inside a tab button break
    // the iOS 27.1 vertical bar, see `_CYLTabButtonLayoutTracker` in UIControl+CYLTabBarControllerExtention.m).
    UIView *defaultTabBadgePointView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, radius * 2, radius * 2)];
    defaultTabBadgePointView.translatesAutoresizingMaskIntoConstraints = YES;
    defaultTabBadgePointView.backgroundColor = color;
    defaultTabBadgePointView.layer.cornerRadius = radius;
    defaultTabBadgePointView.layer.masksToBounds = YES;
    defaultTabBadgePointView.hidden = YES;
    return defaultTabBadgePointView;
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP


#pragma mark - Views inserted into tab buttons

/// [EN] Key of the weak control a marked view was inserted for. [CN] 被标记视图所属控件（弱引用）的 key。
static const void *const CYLInsertedForTabControlKey = &CYLInsertedForTabControlKey;

/// [EN] Every marked view, held weakly. [CN] 所有被标记的视图（弱引用）。
static NSHashTable<UIView *> *CYLInsertedTabControlViewTable(void) {
    static NSHashTable<UIView *> *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = [NSHashTable weakObjectsHashTable];
    });
    return table;
}

- (void)cyl_markAsInsertedForTabControl:(UIControl *)control {
    [self cyl_setWeakAssociatedObject:control forKey:CYLInsertedForTabControlKey];
    if (control) {
        [CYLInsertedTabControlViewTable() addObject:self];
    } else {
        [CYLInsertedTabControlViewTable() removeObject:self];
    }
}

- (UIControl *)cyl_insertedForTabControl {
    return [self cyl_weakAssociatedObjectForKey:CYLInsertedForTabControlKey];
}

+ (NSArray<UIView *> *)cyl_insertedTabControlViews {
    return CYLInsertedTabControlViewTable().allObjects;
}

@end

@implementation UIView (CYLTabBarMetrics)

- (NSUInteger)cyl_tabbarItemsCount {
    NSNumber *count = objc_getAssociatedObject(self, @selector(cyl_tabbarItemsCount));
    return count != nil ? count.unsignedIntegerValue : CYLTabbarItemsCount;
}

- (void)cyl_setTabbarItemsCount:(NSUInteger)tabbarItemsCount {
    objc_setAssociatedObject(self, @selector(cyl_tabbarItemsCount), @(tabbarItemsCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CYLTabbarItemsCount = tabbarItemsCount;
}

- (CGFloat)cyl_tabBarItemWidth {
    NSNumber *width = objc_getAssociatedObject(self, @selector(cyl_tabBarItemWidth));
    return width != nil ? width.doubleValue : CYLTabBarItemWidth;
}

- (void)cyl_setTabBarItemWidth:(CGFloat)tabBarItemWidth {
    objc_setAssociatedObject(self, @selector(cyl_tabBarItemWidth), @(tabBarItemWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CYLTabBarItemWidth = tabBarItemWidth;
}

/*!
 * [EN] The index of the plus button's slot (its placeholder or plus child view controller) in the `viewControllers` of
 *      the tab bar controller this view belongs to, or NSNotFound. The slot is inserted by one rule in
 *      `-[CYLTabBarController setViewControllers:]`; reading its index here keeps every style in step with it.
 * [CN] PlusButton 的 slot（占位控制器或 PlusButton 子控制器）在本视图所属 TabBarController 的 `viewControllers` 中的下标，没有时返回
 *      NSNotFound。slot 只由 `-[CYLTabBarController setViewControllers:]` 按一条规则插入；这里直接读取其下标，所有样式都与之保持一致。
 */
static NSUInteger CYLPlusSlotIndexOfOwner(UIView *owner) {
    CYLTabBarController *tabBarController = [owner cyl_owningTabBarController];
    if (!tabBarController) {
        return NSNotFound;
    }
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:tabBarController];
    return [tabBarController.viewControllers indexOfObjectPassingTest:^BOOL(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        UIViewController *contentViewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
        return viewController.cyl_isPlaceholder || contentViewController.cyl_isPlaceholder ||
               (plusChildViewController && (viewController == plusChildViewController || contentViewController == plusChildViewController));
    }];
}

- (NSUInteger)cyl_plusButtonIndex {
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton) {
        return CYLPlusButtonIndex;
    }
    // [EN] FIX: placeholder count mismatch — with a slot, its real index: Liquid Glass keeps it in the middle whatever
    //      `+indexOfPlusButtonInTabBar` returns, and an odd tab count without one has no `+indexForTabbarItemsCount:`.
    //      Without a slot (classic style, no plus child view controller) the plus button sits between the tabs, as before.
    // [CN] FIX：占位导致的数量不匹配——有 slot 时返回其真实下标：液态玻璃无论 `+indexOfPlusButtonInTabBar` 返回什么都放在中间，
    //      Tab 数为奇数且未实现该方法时 `+indexForTabbarItemsCount:` 没有结果。没有 slot 时（经典样式且无 PlusButton 子控制器），
    //      PlusButton 位于 Tab 之间，与以前一致。
    NSUInteger slotIndex = CYLPlusSlotIndexOfOwner(self);
    if (slotIndex != NSNotFound) {
        return slotIndex;
    }
    return [[plusButton class] indexForTabbarItemsCount:self.cyl_tabbarItemsCount];
}

- (CGFloat)cyl_plusButtonWidth {
    return [CYLPlusButton plusButtonWidthForOwner:self];
}

@end

