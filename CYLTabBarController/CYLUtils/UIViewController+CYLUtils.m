//
//  UIViewController+CYLUtils.m
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLUtils.h"

@implementation UIViewController (CYLUtils)

- (UIViewController *)cyl_getViewControllerInsteadOfNavigationController {
    BOOL isNavigationController = [[self class] isSubclassOfClass:[UINavigationController class]];
    if (isNavigationController && ((UINavigationController *)self).viewControllers.count > 0) {
        return ((UINavigationController *)self).viewControllers[0];
    }
    return self;
}

@end
