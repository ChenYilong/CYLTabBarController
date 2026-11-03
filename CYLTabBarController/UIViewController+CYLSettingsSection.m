//
//  UIViewController+CYLSettingsSection.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLSettingsSection.h"
#import "CYLLocalization.h"
#import "UIViewController+CYLMemoryWarning.h"
#import "UIViewController+CYLTabBarItemUpdate.h"

const NSInteger CYLSettingsSection = 0;

/// Rows of the settings section; the tab item update rows follow (`UIViewController+CYLTabBarItemUpdate.h`).
/// 设置分组的行；其后是更新 Tab 的若干行（`UIViewController+CYLTabBarItemUpdate.h`）。
typedef NS_ENUM(NSInteger, CYLSettingsRow) {
    CYLSettingsRowLanguage,
    CYLSettingsRowMemoryWarning,
    CYLSettingsRowTabBarItemUpdate,
};

@implementation UIViewController (CYLSettingsSection)

- (NSInteger)cyl_settingsRowCount {
    return CYLSettingsRowTabBarItemUpdate + [self cyl_tabBarItemUpdateRowCount];
}

- (UITableViewCell *)cyl_settingsCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == CYLSettingsRowMemoryWarning) {
        return [self cyl_memoryWarningCellForTableView:tableView];
    }
    if (indexPath.row >= CYLSettingsRowTabBarItemUpdate) {
        return [self cyl_tabBarItemUpdateCellForTableView:tableView row:indexPath.row - CYLSettingsRowTabBarItemUpdate];
    }
    return [self cyl_languageCellForTableView:tableView];
}

- (void)cyl_didSelectSettingsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == CYLSettingsRowMemoryWarning) {
        [self cyl_simulateMemoryWarningAndShowResult];
    } else if (indexPath.row >= CYLSettingsRowTabBarItemUpdate) {
        [self cyl_didSelectTabBarItemUpdateRow:indexPath.row - CYLSettingsRowTabBarItemUpdate];
        // The rows show which changes are on (a checkmark). 各行用勾号显示已应用的更改。
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        for (NSInteger row = CYLSettingsRowTabBarItemUpdate; row < [self cyl_settingsRowCount]; row++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:indexPath.section]];
        }
        [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self cyl_presentLanguagePicker];
    }
}

@end
