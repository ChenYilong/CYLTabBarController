//
//  CYLAnimatedItemResources.m
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLAnimatedItemMacros.h"
#import "CYLAnimatedItemView.h"

/*
 * [EN] Looks for `CYLAnimatedItem.bundle` where each package manager puts it: next to the component's code (CocoaPods, a
 *      framework), in the app, and inside Swift Package Manager's resource bundle of CYLTabBarController.
 * [CN] 在各包管理器放置的位置查找 `CYLAnimatedItem.bundle`：组件代码旁（CocoaPods、framework）、App 内，以及 Swift Package Manager 中
 *      CYLTabBarController 的资源包内。
 */
NSBundle *CYLAnimatedItemResourceBundle(void) {
    static NSBundle *resourceBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray<NSBundle *> *containers = [NSMutableArray arrayWithObjects:[NSBundle bundleForClass:[CYLAnimatedItemView class]], [NSBundle mainBundle], nil];
        // [EN] Swift Package Manager: the resource bundle of the CYLAnimatedItemSwift target (before 2026-11-17 the bundle was in
        //      CYLTabBarControllerSwift's). [CN] Swift Package Manager：CYLAnimatedItemSwift target 的资源包（2026-11-17 之前在
        //      CYLTabBarControllerSwift 的资源包中）。
        for (NSString *packageName in @[@"CYLTabBarController_CYLAnimatedItemSwift", @"CYLTabBarController_CYLTabBarControllerSwift"]) {
            NSString *packagePath = [[NSBundle mainBundle] pathForResource:packageName ofType:@"bundle"];
            NSBundle *package = packagePath ? [NSBundle bundleWithPath:packagePath] : nil;
            if (package) {
                [containers addObject:package];
            }
        }
        for (NSBundle *container in containers) {
            NSString *path = [container pathForResource:@"CYLAnimatedItem" ofType:@"bundle"];
            if (path) {
                resourceBundle = [NSBundle bundleWithPath:path];
                break;
            }
        }
    });
    return resourceBundle;
}
