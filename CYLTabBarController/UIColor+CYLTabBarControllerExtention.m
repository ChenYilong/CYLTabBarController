//
//  UIColor+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2019年 https://github.com/ChenYilong .All rights reserved.
//

#import "UIColor+CYLTabBarControllerExtention.h"

@implementation UIColor (CYLTabBarControllerExtention)

+ (UIColor *)cyl_systemRedColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemRedColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:0.23137254901960785
            blue:0.18823529411764706
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGreenColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGreenColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.20392156862745098
            green:0.7803921568627451
            blue:0.34901960784313724
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemBlueColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemBlueColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.0
            green:0.47843137254901963
            blue:1.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemOrangeColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemOrangeColor];
#else
#endif
    }
    
    return [UIColor
            colorWithRed:1.0
            green:0.5843137254901961
            blue:0.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemYellowColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemYellowColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:0.8
            blue:0.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemPinkColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemPinkColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:0.17647058823529413
            blue:0.3333333333333333
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemPurpleColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemPurpleColor];
#else
#endif
    }
    
    return [UIColor
            colorWithRed:0.6862745098039216
            green:0.3215686274509804
            blue:0.8705882352941177
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemTealColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemTealColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.35294117647058826
            green:0.7843137254901961
            blue:0.9803921568627451
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemIndigoColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemIndigoColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.34509803921568627
            green:0.33725490196078434
            blue:0.8392156862745098
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGrayColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGrayColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.5568627450980392
            green:0.5568627450980392
            blue:0.5764705882352941
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGray2Color {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGray2Color];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.6823529411764706
            green:0.6823529411764706
            blue:0.6980392156862745
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGray3Color {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGray3Color];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.7803921568627451
            green:0.7803921568627451
            blue:0.8
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGray4Color {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGray4Color];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.8196078431372549
            green:0.8196078431372549
            blue:0.8392156862745098
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGray5Color {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGray5Color];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.8980392156862745
            green:0.8980392156862745
            blue:0.9176470588235294
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGray6Color {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGray6Color];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.9490196078431372
            green:0.9490196078431372
            blue:0.9686274509803922
            alpha:1.0
            ];
}

#pragma mark Foreground colors

+ (UIColor *)cyl_labelColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor labelColor];
#else
#endif
    }
    
    return [UIColor
            colorWithRed:0.0
            green:0.0
            blue:0.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_secondaryLabelColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor secondaryLabelColor];
#else
#endif
    }
    
    return [UIColor
            colorWithRed:0.23529411764705882
            green:0.23529411764705882
            blue:0.2627450980392157
            alpha:0.6
            ];
}

+ (UIColor *)cyl_tertiaryLabelColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor tertiaryLabelColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.23529411764705882
            green:0.23529411764705882
            blue:0.2627450980392157
            alpha:0.3
            ];
}

+ (UIColor *)cyl_quaternaryLabelColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor quaternaryLabelColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.23529411764705882
            green:0.23529411764705882
            blue:0.2627450980392157
            alpha:0.18
            ];
}

/* Foreground color for standard system links.
 */
+ (UIColor *)cyl_linkColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor linkColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.0
            green:0.47843137254901963
            blue:1.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_placeholderTextColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor placeholderTextColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.23529411764705882
            green:0.23529411764705882
            blue:0.2627450980392157
            alpha:0.3
            ];
}

+ (UIColor *)cyl_separatorColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor separatorColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.23529411764705882
            green:0.23529411764705882
            blue:0.2627450980392157
            alpha:0.29
            ];
}

+ (UIColor *)cyl_opaqueSeparatorColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor opaqueSeparatorColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.7764705882352941
            green:0.7764705882352941
            blue:0.7843137254901961
            alpha:1.0
            ];
}

#pragma mark Background colors

+ (UIColor *)cyl_systemBackgroundColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemBackgroundColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:1.0
            blue:1.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_secondarySystemBackgroundColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor secondarySystemBackgroundColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.9490196078431372
            green:0.9490196078431372
            blue:0.9686274509803922
            alpha:1.0
            ];
}

+ (UIColor *)cyl_tertiarySystemBackgroundColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor tertiarySystemBackgroundColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:1.0
            blue:1.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_systemGroupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemGroupedBackgroundColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.9490196078431372
            green:0.9490196078431372
            blue:0.9686274509803922
            alpha:1.0
            ];
}

+ (UIColor *)cyl_secondarySystemGroupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor secondarySystemGroupedBackgroundColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:1.0
            blue:1.0
            alpha:1.0
            ];
}

+ (UIColor *)cyl_tertiarySystemGroupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor tertiarySystemGroupedBackgroundColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.9490196078431372
            green:0.9490196078431372
            blue:0.9686274509803922
            alpha:1.0
            ];
}

#pragma mark Fill colors

+ (UIColor *)cyl_systemFillColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor systemFillColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.47058823529411764
            green:0.47058823529411764
            blue:0.5019607843137255
            alpha:0.2
            ];
}

+ (UIColor *)cyl_secondarySystemFillColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor secondarySystemFillColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.47058823529411764
            green:0.47058823529411764
            blue:0.5019607843137255
            alpha:0.16
            ];
}

+ (UIColor *)cyl_tertiarySystemFillColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor tertiarySystemFillColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.4627450980392157
            green:0.4627450980392157
            blue:0.5019607843137255
            alpha:0.12
            ];
}

+ (UIColor *)cyl_quaternarySystemFillColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor quaternarySystemFillColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.4549019607843137
            green:0.4549019607843137
            blue:0.5019607843137255
            alpha:0.08
            ];
}

#pragma mark Other colors

+ (UIColor *)cyl_lightTextColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor lightTextColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:1.0
            green:1.0
            blue:1.0
            alpha:0.6
            ];
}

+ (UIColor *)cyl_darkTextColor {
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        return [UIColor darkTextColor];
#else
#endif
    }
    return [UIColor
            colorWithRed:0.0
            green:0.0
            blue:0.0
            alpha:1.0
            ];
}

#pragma mark - Deprecated API

//Apple remove this API in iOS13 beta 2
+ (UIColor *)cyl_systemBrownColor {
    return nil;
}

@end
