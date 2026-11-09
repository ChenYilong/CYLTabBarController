//
//  UIViewController+CYLMemoryWarning.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLMemoryWarning.h"
#import "CYLTabBarController.h"

static NSString *const CYLMemoryWarningCellIdentifier = @"CYLMemoryWarningCell";

/// The view controller itself, or the root of a navigation controller: the page a tab shows.
static UIViewController *CYLMemoryWarningRootViewController(UIViewController *viewController) {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController *)viewController).viewControllers.firstObject ?: viewController;
    }
    return viewController;
}

NSString *CYLSimulateMemoryWarningReport(CYLTabBarController *tabBarController) {
    NSArray<UIViewController *> *viewControllers = tabBarController.viewControllers;
    NSMutableArray<NSNumber *> *wasLoaded = [NSMutableArray arrayWithCapacity:viewControllers.count];
    for (UIViewController *viewController in viewControllers) {
        [wasLoaded addObject:@(CYLMemoryWarningRootViewController(viewController).isViewLoaded)];
    }
    [CYLTabBarController cyl_simulateMemoryWarningForTabBarController:tabBarController];
    NSMutableString *message = [NSMutableString string];
    if (!tabBarController) {
        [message appendString:CYLLocalizedString(@"不在 CYLTabBarController 中，没有可卸载的 Tab。")];
    } else if (!tabBarController.unloadsUnselectedViewsOnMemoryWarning) {
        [message appendString:CYLLocalizedString(@"unloadsUnselectedViewsOnMemoryWarning = NO，未卸载任何 Tab。")];
    }
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if (viewController.cyl_isPlaceholder) {
            return;
        }
        UIViewController *rootViewController = CYLMemoryWarningRootViewController(viewController);
        NSString *title = viewController.tabBarItem.title ?: rootViewController.title ?: NSStringFromClass([rootViewController class]);
        NSString *status;
        if (![wasLoaded[idx] boolValue]) {
            status = CYLLocalizedString(@"未加载");
        } else if (!rootViewController.isViewLoaded) {
            status = CYLLocalizedString(@"已卸载");
        } else if (viewController == tabBarController.selectedViewController) {
            status = CYLLocalizedString(@"保留：当前选中");
        } else if (tabBarController.unloadsUnselectedViewsOnMemoryWarning &&
                   ![tabBarController shouldUnloadViewOfViewController:viewController]) {
            status = CYLLocalizedString(@"保留：shouldUnload 返回 NO");
        } else {
            status = CYLLocalizedString(@"保留");
        }
        [message appendFormat:@"%@%@: %@", (message.length ? @"\n" : @""), title, status];
    }];
    return [message copy];
}

@implementation UIViewController (CYLMemoryWarning)

- (UITableViewCell *)cyl_memoryWarningCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLMemoryWarningCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLMemoryWarningCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"memorychip"];
        }
    }
    cell.textLabel.text = CYLLocalizedString(@"模拟内存警告");
    cell.detailTextLabel.text = CYLLocalizedString(@"卸载未选中的 Tab，切换时重新加载");
    return cell;
}

- (void)cyl_simulateMemoryWarningAndShowResult {
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
    NSString *message = CYLSimulateMemoryWarningReport(tabBarController);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"内存警告")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
