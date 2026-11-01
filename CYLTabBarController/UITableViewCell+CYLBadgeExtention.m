//
//  UITableViewCell+CYLBadgeExtention.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UITableViewCell+CYLBadgeExtention.h"
#import "UIView+CYLBadgeExtention.h"

const CGFloat CYLBadgeRowHeight = 60;
static const CGFloat CYLBadgeIconSide = 30;

@implementation UITableViewCell (CYLBadgeExtention)

+ (NSArray<NSDictionary *> *)cyl_badgeItems {
    static NSArray *items;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        items = @[
            // Styles
            @{@"title": @"Red dot",                @"value": @"",    @"animation": @(CYLBadgeAnimationTypeNone)},
            @{@"title": @"Number",                 @"value": @"8",   @"animation": @(CYLBadgeAnimationTypeNone)},
            @{@"title": @"Number above maximum",   @"value": @"100", @"animation": @(CYLBadgeAnimationTypeNone), @"maximum": @99},
            @{@"title": @"New",                    @"value": @"new", @"animation": @(CYLBadgeAnimationTypeNone)},
            @{@"title": @"Other text",             @"value": @"hot", @"animation": @(CYLBadgeAnimationTypeNone)},
            // Appearance
            @{@"title": @"Custom colors",          @"value": @"5",   @"animation": @(CYLBadgeAnimationTypeNone), @"color": @YES},
            @{@"title": @"Border",                 @"value": @"5",   @"animation": @(CYLBadgeAnimationTypeNone), @"border": @YES},
            @{@"title": @"Center offset",          @"value": @"",    @"animation": @(CYLBadgeAnimationTypeNone), @"offset": @YES},
            @{@"title": @"Red dot radius",         @"value": @"",    @"animation": @(CYLBadgeAnimationTypeNone), @"radius": @6},
            @{@"title": @"Corner radius",          @"value": @"new", @"animation": @(CYLBadgeAnimationTypeNone), @"corner": @3},
            // Repeating animations
            @{@"title": @"Scale",                  @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeScale)},
            @{@"title": @"Shake",                  @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeShake)},
            @{@"title": @"Bounce",                 @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeBounce)},
            @{@"title": @"Breathe",                @"value": @"",    @"animation": @(CYLBadgeAnimationTypeBreathe)},
            // Once animations
            @{@"title": @"Left to right once",     @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeLeftRightOnce)},
            @{@"title": @"Right to left once",     @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeRightLeftOnce)},
            @{@"title": @"Fade in once",           @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeFadeInOnce)},
            @{@"title": @"Rolling once",           @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeRollingOnce)},
            @{@"title": @"Scale once",             @"value": @"3",   @"animation": @(CYLBadgeAnimationTypeScaleOnce)},
        ];
    });
    return items;
}

/// The app icon drawn at 30 x 30 pt with rounded corners, which leaves 15 pt above it in a 60 pt row. The badge sits on
/// the icon's top-right corner, so it needs that room to stay inside the row, animations included.
+ (UIImage *)cyl_badgeIcon {
    static UIImage *icon;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage *image = [UIImage imageNamed:@"DemoIcon"];
        CGRect rect = CGRectMake(0, 0, CYLBadgeIconSide, CYLBadgeIconSide);
        icon = [[[UIGraphicsImageRenderer alloc] initWithSize:rect.size] imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:6] addClip];
            [image drawInRect:rect];
        }];
    });
    return icon;
}

+ (NSString *)cyl_badgeTitleForRow:(NSInteger)row {
    NSDictionary *item = [self cyl_badgeItems][row % [self cyl_badgeStyleCount]];
    return [NSString stringWithFormat:@"%@. %@", @(row + 1), item[@"title"]];
}

+ (NSInteger)cyl_badgeStyleCount {
    return [self cyl_badgeItems].count;
}

- (void)cyl_showBadgeForRow:(NSInteger)row {
    NSDictionary *item = [UITableViewCell cyl_badgeItems][row % [UITableViewCell cyl_badgeStyleCount]];
    UIImageView *iconView = self.imageView;
    iconView.image = [UITableViewCell cyl_badgeIcon];
    iconView.clipsToBounds = NO;

    // Cells are reused: clear the badge and reset every option before the next one.
    [iconView cyl_clearBadge];
    iconView.cyl_badgeBackgroundColor = [UIColor redColor];
    iconView.cyl_badgeTextColor = [UIColor whiteColor];
    iconView.cyl_badgeBorderColor = nil;
    iconView.cyl_badgeBorderWidth = 0;
    iconView.cyl_badgeCenterOffset = CGPointZero;
    iconView.cyl_badgeRadius = 0;
    iconView.cyl_badgeCornerRadius = 0;
    iconView.cyl_badgeMaximumBadgeNumber = 99;
    if (item[@"maximum"]) {
        iconView.cyl_badgeMaximumBadgeNumber = [item[@"maximum"] integerValue];
    }
    if (item[@"color"]) {
        iconView.cyl_badgeBackgroundColor = [UIColor purpleColor];
        iconView.cyl_badgeTextColor = [UIColor yellowColor];
    }
    if (item[@"border"]) {
        iconView.cyl_badgeBorderColor = [UIColor whiteColor];
        iconView.cyl_badgeBorderWidth = 2;
    }
    if (item[@"offset"]) {
        iconView.cyl_badgeCenterOffset = CGPointMake(-8, 8);
    }
    if (item[@"radius"]) {
        iconView.cyl_badgeRadius = [item[@"radius"] floatValue];
    }
    if (item[@"corner"]) {
        iconView.cyl_badgeCornerRadius = [item[@"corner"] floatValue];
    }
    // Options must be set before showing the badge.
    [iconView cyl_showBadgeValue:item[@"value"] animationType:(CYLBadgeAnimationType)[item[@"animation"] integerValue]];
}

@end

static NSString *const CYLBadgeHelperCellIdentifier = @"CYLBadgeHelperCell";

@implementation CYLBadgeHelperTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Badge", @"Title of the badge list");
    self.tableView.rowHeight = CYLBadgeRowHeight;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CYLBadgeHelperCellIdentifier];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [UITableViewCell cyl_badgeStyleCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLBadgeHelperCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    [cell cyl_showBadgeForRow:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[tableView cellForRowAtIndexPath:indexPath].imageView cyl_clearBadge];
}

@end

@implementation UIViewController (CYLBadgeExtention)

- (void)cyl_addBadgeHelperTable {
    CYLBadgeHelperTableViewController *badgeHelper = [[CYLBadgeHelperTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self addChildViewController:badgeHelper];
    badgeHelper.view.frame = self.view.bounds;
    badgeHelper.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:badgeHelper.view];
    [badgeHelper didMoveToParentViewController:self];
}

@end

