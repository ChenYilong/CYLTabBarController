//
//  UITableViewCell+CYLBadgeDemo.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Row height that leaves room above the 40 pt icon for its badge.
extern const CGFloat CYLDemoBadgeRowHeight;

@interface UITableViewCell (CYLBadgeDemo)

/// Shows the demo icon in the cell and a badge on it. Style and animation change with the row, so a table lists them all.
- (void)cyl_demo_showBadgeForRow:(NSInteger)row;

/// Title of the badge demo shown on `row`.
+ (NSString *)cyl_demo_badgeTitleForRow:(NSInteger)row;

/// Number of different badge demos.
+ (NSInteger)cyl_demo_badgeCount;

@end

NS_ASSUME_NONNULL_END
