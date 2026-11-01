//
//  UITableViewCell+CYLBadgeDemo.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UITableViewCell+CYLBadgeDemo.h"
#import <CYLTabBarController/CYLTabBarController.h>

const CGFloat CYLDemoBadgeRowHeight = 60;
static const CGFloat CYLDemoIconSide = 40;

@implementation UITableViewCell (CYLBadgeDemo)

+ (NSArray<NSDictionary *> *)cyl_demo_badgeItems {
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

/// The app icon drawn at 40 x 40 pt with rounded corners. At full size it fills the row, and the badge, which sits on
/// the icon's top-right corner, ends up under the row above.
+ (UIImage *)cyl_demo_icon {
    static UIImage *icon;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage *image = [UIImage imageNamed:@"DemoIcon"];
        CGRect rect = CGRectMake(0, 0, CYLDemoIconSide, CYLDemoIconSide);
        icon = [[[UIGraphicsImageRenderer alloc] initWithSize:rect.size] imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8] addClip];
            [image drawInRect:rect];
        }];
    });
    return icon;
}

+ (NSString *)cyl_demo_badgeTitleForRow:(NSInteger)row {
    NSDictionary *item = [self cyl_demo_badgeItems][row % [self cyl_demo_badgeCount]];
    return [NSString stringWithFormat:@"%@. %@", @(row + 1), item[@"title"]];
}

+ (NSInteger)cyl_demo_badgeCount {
    return [self cyl_demo_badgeItems].count;
}

- (void)cyl_demo_showBadgeForRow:(NSInteger)row {
    NSDictionary *item = [UITableViewCell cyl_demo_badgeItems][row % [UITableViewCell cyl_demo_badgeCount]];
    UIImageView *iconView = self.imageView;
    iconView.image = [UITableViewCell cyl_demo_icon];
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
