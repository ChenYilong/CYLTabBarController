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
 *  @warning 仅对 UIBarButtonItem、UITabBarItem 有效
 *   UIBarItem 本身没有 view 属性，只有子类 UIBarButtonItem 和 UITabBarItem 才有
 *   iOS11改成了类似懒加载机制，要等到UIBarButtonItem被展示后才能获取到_view
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
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    
    return control;
}

@end
