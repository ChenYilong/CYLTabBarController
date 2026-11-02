//
//  UIViewController+CYLMemoryWarningDemo.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLMemoryWarningDemo.h"
#import "CYLTabBarController.h"

const NSInteger CYLMemoryWarningDemoSection = 0;

static NSString *const CYLMemoryWarningDemoCellIdentifier = @"CYLMemoryWarningDemoCell";

/// The view controller itself, or the root of a navigation controller: the page a tab shows.
static UIViewController *CYLMemoryWarningDemoRootViewController(UIViewController *viewController) {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController *)viewController).viewControllers.firstObject ?: viewController;
    }
    return viewController;
}

@implementation UIViewController (CYLMemoryWarningDemo)

- (UITableViewCell *)cyl_memoryWarningDemoCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLMemoryWarningDemoCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLMemoryWarningDemoCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"memorychip"];
        }
    }
    cell.textLabel.text = @"模拟内存警告 Memory warning (#426)";
    cell.detailTextLabel.text = @"卸载未选中的 Tab，切换时重新加载";
    return cell;
}

- (void)cyl_showMemoryWarningDemo {
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
    NSArray<UIViewController *> *viewControllers = tabBarController.viewControllers;
    NSMutableArray<NSNumber *> *wasLoaded = [NSMutableArray arrayWithCapacity:viewControllers.count];
    for (UIViewController *viewController in viewControllers) {
        [wasLoaded addObject:@(CYLMemoryWarningDemoRootViewController(viewController).isViewLoaded)];
    }

    [CYLTabBarController cyl_simulateMemoryWarningForTabBarController:tabBarController];

    NSMutableString *message = [NSMutableString string];
    if (!tabBarController) {
        [message appendString:@"不在 CYLTabBarController 中，没有可卸载的 Tab。\nNot in a CYLTabBarController: no tabs to unload."];
    } else if (!tabBarController.unloadsUnselectedViewsOnMemoryWarning) {
        [message appendString:@"unloadsUnselectedViewsOnMemoryWarning = NO，未卸载任何 Tab。\nunloadsUnselectedViewsOnMemoryWarning is NO: no tab unloaded."];
    }
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if (viewController.cyl_isPlaceholder) {
            return;
        }
        UIViewController *rootViewController = CYLMemoryWarningDemoRootViewController(viewController);
        NSString *title = viewController.tabBarItem.title ?: rootViewController.title ?: NSStringFromClass([rootViewController class]);
        NSString *status;
        if (![wasLoaded[idx] boolValue]) {
            status = @"未加载 not loaded";
        } else if (!rootViewController.isViewLoaded) {
            status = @"已卸载 unloaded";
        } else if (viewController == tabBarController.selectedViewController) {
            status = @"保留：当前选中 kept: selected";
        } else if (tabBarController.unloadsUnselectedViewsOnMemoryWarning &&
                   ![tabBarController shouldUnloadViewOfViewController:viewController]) {
            status = @"保留：shouldUnload 返回 NO kept: shouldUnload returned NO";
        } else {
            status = @"保留 kept";
        }
        [message appendFormat:@"%@%@：%@", (message.length ? @"\n" : @""), title, status];
    }];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"内存警告 Memory warning"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
