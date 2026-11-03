//
//  UIBarItem+CYLUtils.m
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIBarItem+CYLUtils.h"
#import "NSObject+CYLUtils.h"

@implementation UIBarItem (CYLUtils)

/*!
 * [CN] @warning 仅对 UIBarButtonItem、UITabBarItem 有效
 *   UIBarItem 本身没有 view 属性，只有子类 UIBarButtonItem 和 UITabBarItem 才有
 *   iOS11改成了类似懒加载机制，要等到UIBarButtonItem被展示后才能获取到_view
 * [EN] @warning Only works for UIBarButtonItem and UITabBarItem
 *      UIBarItem itself has no view property; only its subclasses UIBarButtonItem and UITabBarItem do
 *      Since iOS11 this became lazily loaded; _view is only available after the UIBarButtonItem is displayed
 */
- (UIView *)cyl_view {
    if ([self respondsToSelector:@selector(view)]) {
        return [self cyl_valueForKey:@"view"];
    }
    return nil;
}

@end

@implementation UITabBarItem (CYLUtils)

/*!
 *     if ([classString isEqualToString:@"UITabBarButton"] || [classString isEqualToString:@"_UITabButton"]) {
 */
- (UIControl *)cyl_tabButton {
    UIControl *control;
    @try {
        control = (UIControl *)self.cyl_view;
        
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        // CYLUtils does not depend on CYLLocalization (Core): a literal format. CYLUtils 不依赖 Core 中的 CYLLocalization：使用字面量格式。
        NSLog(@"🔴 %@ (line %@): %@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    
    return control;
}

@end
