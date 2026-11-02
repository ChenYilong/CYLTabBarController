//
//  UITableViewCell+CYLBadgeExtention.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UITableViewCell+CYLBadgeExtention.h"
#import "UIView+CYLBadgeExtention.h"
#import "CAAnimation+CYLBadgeExtention.h"
#import "CYLTabBarController.h"

const CGFloat CYLBadgeRowHeight = 60;
static const CGFloat CYLBadgeIconSide = 30;
/// Key of the animations added here with the `CAAnimation+CYLBadgeExtention` factories (not by an animation type).
static NSString *const CYLBadgeHelperAnimationKey = @"cyl.badge.helper";

// Item keys.
static NSString *const CYLBadgeItemTitle = @"title";
static NSString *const CYLBadgeItemValue = @"value";
static NSString *const CYLBadgeItemAnimationType = @"animationType";
/// One of the names handled by `CYLBadgeHelperAnimation()`: an animation built with a `CAAnimation` factory.
static NSString *const CYLBadgeItemFactoryAnimation = @"factoryAnimation";
static NSString *const CYLBadgeItemMaximum = @"maximum";
static NSString *const CYLBadgeItemColors = @"colors";
static NSString *const CYLBadgeItemFont = @"font";
static NSString *const CYLBadgeItemBorder = @"border";
static NSString *const CYLBadgeItemDynamicBorder = @"dynamicBorder";
static NSString *const CYLBadgeItemRadius = @"radius";
static NSString *const CYLBadgeItemMargin = @"margin";
static NSString *const CYLBadgeItemCornerRadius = @"cornerRadius";
static NSString *const CYLBadgeItemReduceMotion = @"reduceMotion";
static NSString *const CYLBadgeItemPosition = @"position";

// Factory animations.
static NSString *const CYLBadgeRotationForever = @"rotationForever";
static NSString *const CYLBadgeSpringForever = @"springForever";
static NSString *const CYLBadgeShakeThreeTimes = @"shakeThreeTimes";
static NSString *const CYLBadgeBounceThreeTimes = @"bounceThreeTimes";
static NSString *const CYLBadgeScaleThreeTimes = @"scaleThreeTimes";
static NSString *const CYLBadgeBlinkThreeTimes = @"blinkThreeTimes";
static NSString *const CYLBadgeFlipTwice = @"flipTwice";
static NSString *const CYLBadgeSpringOnce = @"springOnce";

// Positions other than the default top-right corner.
static NSString *const CYLBadgeTopLeft = @"topLeft";
static NSString *const CYLBadgeBottomLeft = @"bottomLeft";
static NSString *const CYLBadgeBottomRight = @"bottomRight";

/// The animation called `name`, sized for `badge`; nil for an unknown name.
static CAAnimation *CYLBadgeHelperAnimation(NSString *name, UIView *badge) {
    CGSize size = badge.bounds.size;
    if ([name isEqualToString:CYLBadgeRotationForever]) {
        return [CAAnimation cyl_rotationAnimationWithDuration:2 degree:2 * M_PI direction:CYLAxisZ repeatCount:HUGE_VALF];
    }
    if ([name isEqualToString:CYLBadgeSpringForever]) {
        CAAnimation *animation = [CAAnimation cyl_springAnimationForDuration:1];
        animation.repeatCount = HUGE_VALF;
        return animation;
    }
    if ([name isEqualToString:CYLBadgeShakeThreeTimes]) {
        return [CAAnimation cyl_shakeAnimationRepeatTimes:3 duration:1 offset:size.width / 4];
    }
    if ([name isEqualToString:CYLBadgeBounceThreeTimes]) {
        return [CAAnimation cyl_bounceAnimationRepeatTimes:3 duration:1 offset:size.height / 4];
    }
    if ([name isEqualToString:CYLBadgeScaleThreeTimes]) {
        return [CAAnimation cyl_scaleAnimationFromScale:1.4 toScale:0.6 duration:1 repeatTimes:3];
    }
    if ([name isEqualToString:CYLBadgeBlinkThreeTimes]) {
        return [CAAnimation cyl_opacityTimesAnimationRepeatTimes:3 duration:0.8];
    }
    if ([name isEqualToString:CYLBadgeFlipTwice]) {
        return [CAAnimation cyl_rotationAnimationWithDuration:1 degree:M_PI direction:CYLAxisY repeatCount:2];
    }
    if ([name isEqualToString:CYLBadgeSpringOnce]) {
        return [CAAnimation cyl_springAnimationForDuration:0.6];
    }
    return nil;
}

/// Center offset that moves the badge from the icon's top-right corner, where it is centered at (width + 2, 0), to `position`.
static CGPoint CYLBadgeHelperCenterOffset(NSString *position) {
    CGFloat toLeft = -(CYLBadgeIconSide + 4);
    if ([position isEqualToString:CYLBadgeTopLeft]) {
        return CGPointMake(toLeft, 0);
    }
    if ([position isEqualToString:CYLBadgeBottomLeft]) {
        return CGPointMake(toLeft, CYLBadgeIconSide);
    }
    if ([position isEqualToString:CYLBadgeBottomRight]) {
        return CGPointMake(0, CYLBadgeIconSide);
    }
    return CGPointZero;
}

/// Border color that follows Dark Mode: black in light mode, white in dark mode.
static UIColor *CYLBadgeHelperDynamicBorderColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            BOOL isDark = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
            return isDark ? [UIColor whiteColor] : [UIColor blackColor];
        }];
    }
    return [UIColor blackColor];
}

@implementation UITableViewCell (CYLBadgeExtention)

/*!
 * Every badge style and animation, in display order:
 * 1. top-right corner, animated: animations that repeat forever, then ones that repeat a few times, then ones that play once;
 * 2. top-right corner, not animated: styles and appearance options;
 * 3. the other corners: top-left, bottom-left, bottom-right.
 */
+ (NSArray<NSDictionary *> *)cyl_badgeItems {
    static NSArray *items;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        items = @[
            // 1.1 Animations that repeat forever: `CYLBadgeAnimationType`
            @{CYLBadgeItemTitle: @"Scale (forever)",   CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeScale)},
            @{CYLBadgeItemTitle: @"Shake (forever)",   CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeShake)},
            @{CYLBadgeItemTitle: @"Bounce (forever)",  CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeBounce)},
            @{CYLBadgeItemTitle: @"Breathe (forever)", CYLBadgeItemValue: @"",  CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeBreathe)},
            @{CYLBadgeItemTitle: @"Shake, stops with Reduce Motion", CYLBadgeItemValue: @"3",
              CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeShake), CYLBadgeItemReduceMotion: @YES},
            // 1.2 Animations that repeat forever: `CAAnimation+CYLBadgeExtention` factories
            @{CYLBadgeItemTitle: @"Rotation (forever)", CYLBadgeItemValue: @"new", CYLBadgeItemFactoryAnimation: CYLBadgeRotationForever},
            @{CYLBadgeItemTitle: @"Spring (forever)",   CYLBadgeItemValue: @"3",   CYLBadgeItemFactoryAnimation: CYLBadgeSpringForever},
            // 1.3 Animations that repeat a few times
            @{CYLBadgeItemTitle: @"Shake ×3 (cyl_shakeAnimationRepeatTimes)",   CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeShakeThreeTimes},
            @{CYLBadgeItemTitle: @"Bounce ×3 (cyl_bounceAnimationRepeatTimes)", CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeBounceThreeTimes},
            @{CYLBadgeItemTitle: @"Scale ×3",  CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeScaleThreeTimes},
            @{CYLBadgeItemTitle: @"Blink ×3",  CYLBadgeItemValue: @"",  CYLBadgeItemFactoryAnimation: CYLBadgeBlinkThreeTimes},
            @{CYLBadgeItemTitle: @"Flip ×2",   CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeFlipTwice},
            // 1.4 Animations that play once
            @{CYLBadgeItemTitle: @"Left to right once", CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeLeftRightOnce)},
            @{CYLBadgeItemTitle: @"Right to left once", CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeRightLeftOnce)},
            @{CYLBadgeItemTitle: @"Fade in once",       CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeFadeInOnce)},
            @{CYLBadgeItemTitle: @"Rolling once",       CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeRollingOnce)},
            @{CYLBadgeItemTitle: @"Scale once",         CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeScaleOnce)},
            @{CYLBadgeItemTitle: @"Spring once",        CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeSpringOnce},
            // 2.1 Styles, no animation
            @{CYLBadgeItemTitle: @"Red dot",              CYLBadgeItemValue: @""},
            @{CYLBadgeItemTitle: @"Number",               CYLBadgeItemValue: @"8"},
            @{CYLBadgeItemTitle: @"Number above maximum", CYLBadgeItemValue: @"100"},
            @{CYLBadgeItemTitle: @"Custom maximum (9)",   CYLBadgeItemValue: @"10", CYLBadgeItemMaximum: @9},
            @{CYLBadgeItemTitle: @"New",                  CYLBadgeItemValue: @"new"},
            @{CYLBadgeItemTitle: @"NEW",                  CYLBadgeItemValue: @"NEW"},
            @{CYLBadgeItemTitle: @"Other text",           CYLBadgeItemValue: @"hot"},
            // 2.2 Appearance, no animation
            @{CYLBadgeItemTitle: @"Custom colors",        CYLBadgeItemValue: @"5",   CYLBadgeItemColors: @YES},
            @{CYLBadgeItemTitle: @"Custom font",          CYLBadgeItemValue: @"5",   CYLBadgeItemFont: @YES},
            @{CYLBadgeItemTitle: @"Border",               CYLBadgeItemValue: @"5",   CYLBadgeItemBorder: @YES},
            @{CYLBadgeItemTitle: @"Border following Dark Mode", CYLBadgeItemValue: @"5", CYLBadgeItemDynamicBorder: @YES},
            @{CYLBadgeItemTitle: @"Red dot radius",       CYLBadgeItemValue: @"",    CYLBadgeItemRadius: @6},
            @{CYLBadgeItemTitle: @"Margin",               CYLBadgeItemValue: @"5",   CYLBadgeItemMargin: @14},
            @{CYLBadgeItemTitle: @"Corner radius",        CYLBadgeItemValue: @"new", CYLBadgeItemCornerRadius: @3},
            // 3. Other corners
            @{CYLBadgeItemTitle: @"Top left",     CYLBadgeItemValue: @"5", CYLBadgeItemPosition: CYLBadgeTopLeft},
            @{CYLBadgeItemTitle: @"Bottom left",  CYLBadgeItemValue: @"5", CYLBadgeItemPosition: CYLBadgeBottomLeft},
            @{CYLBadgeItemTitle: @"Bottom right", CYLBadgeItemValue: @"5", CYLBadgeItemPosition: CYLBadgeBottomRight},
        ];
    });
    return items;
}

/// The app icon drawn at 30 x 30 pt with rounded corners, which leaves 15 pt above and below it in a 60 pt row. The badge
/// sits on one of the icon's corners, so it needs that room to stay inside the row, animations included.
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

+ (NSDictionary *)cyl_badgeItemForRow:(NSInteger)row {
    NSArray<NSDictionary *> *items = [self cyl_badgeItems];
    return items[(NSUInteger)MAX(row, 0) % items.count];
}

+ (NSString *)cyl_badgeTitleForRow:(NSInteger)row {
    return [NSString stringWithFormat:@"%@. %@", @(row + 1), [self cyl_badgeItemForRow:row][CYLBadgeItemTitle]];
}

+ (NSInteger)cyl_badgeStyleCount {
    return (NSInteger)[self cyl_badgeItems].count;
}

- (void)cyl_showBadgeForRow:(NSInteger)row {
    NSDictionary *item = [UITableViewCell cyl_badgeItemForRow:row];
    UIImageView *iconView = self.imageView;
    iconView.image = [UITableViewCell cyl_badgeIcon];
    iconView.clipsToBounds = NO;
    // Lay out the icon now, so the badge is created right away and a factory animation can be added to it.
    [self layoutIfNeeded];

    // Cells are reused: clear the badge, stop the previous row's animation (showing a badge without an animation type
    // does not remove it) and reset every option before the next one.
    [iconView.cyl_badge.layer removeAllAnimations];
    [iconView cyl_clearBadge];
    iconView.cyl_badgeBackgroundColor = item[CYLBadgeItemColors] ? [UIColor purpleColor] : [UIColor redColor];
    iconView.cyl_badgeTextColor = item[CYLBadgeItemColors] ? [UIColor yellowColor] : [UIColor whiteColor];
    iconView.cyl_badgeFont = item[CYLBadgeItemFont] ? [UIFont italicSystemFontOfSize:12] : [UIFont boldSystemFontOfSize:9];
    iconView.cyl_badgeBorderColor = nil;
    iconView.cyl_badgeBorderWidth = 0;
    if (item[CYLBadgeItemBorder]) {
        iconView.cyl_badgeBorderColor = [UIColor whiteColor];
        iconView.cyl_badgeBorderWidth = 2;
    }
    if (item[CYLBadgeItemDynamicBorder]) {
        iconView.cyl_badgeBorderColor = CYLBadgeHelperDynamicBorderColor();
        iconView.cyl_badgeBorderWidth = 2;
    }
    iconView.cyl_badgeCenterOffset = CYLBadgeHelperCenterOffset(item[CYLBadgeItemPosition]);
    iconView.cyl_badgeRadius = [item[CYLBadgeItemRadius] floatValue];
    iconView.cyl_badgeMargin = item[CYLBadgeItemMargin] ? [item[CYLBadgeItemMargin] floatValue] : 8;
    iconView.cyl_badgeCornerRadius = [item[CYLBadgeItemCornerRadius] floatValue];
    iconView.cyl_badgeMaximumBadgeNumber = item[CYLBadgeItemMaximum] ? [item[CYLBadgeItemMaximum] integerValue] : 99;
    iconView.cyl_badgeRespectsReduceMotion = [item[CYLBadgeItemReduceMotion] boolValue];
    // Options must be set before showing the badge.
    CYLBadgeAnimationType animationType = (CYLBadgeAnimationType)[item[CYLBadgeItemAnimationType] unsignedIntegerValue];
    [iconView cyl_showBadgeValue:item[CYLBadgeItemValue] animationType:animationType];

    UIView *badge = iconView.cyl_badge;
    CAAnimation *animation = badge ? CYLBadgeHelperAnimation(item[CYLBadgeItemFactoryAnimation], badge) : nil;
    if (animation) {
        [badge.layer addAnimation:animation forKey:CYLBadgeHelperAnimationKey];
    }
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
    // Demo (issues #426, #428): a tap also simulates a memory warning and logs the tab bar's state afterwards, to check
    // that the tab Lottie icons keep their speed and the badges stay. 演示：点击同时模拟内存警告并输出之后的 TabBar 状态。
    [CYLTabBarController cyl_simulateMemoryWarning];
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

