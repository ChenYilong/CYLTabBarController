//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
#define kCYLBadgeDefaultFont ([UIFont boldSystemFontOfSize:9])

@interface CYLTabBarBadgeView : UIView

@property (nonatomic, assign) UIEdgeInsets badgeContentInset;

//@property (nonatomic, strong) UILabel *badgeLabel;

/*!
 * default is NSTextAlignmentCenter
 */
@property(nonatomic) NSTextAlignment textAlignment;

//@property (nonatomic, strong) UIColor *badgeTextColor;
/*!
 *  // default is labelColor
 */
@property(null_resettable, nonatomic,strong) UIColor *textColor;

/*!
 * //@property (nonatomic, copy) NSString *badgeValue;
 */
@property(nullable, nonatomic,copy) NSString *text; // default is nil

/*!
 * badgeTextFont;
 */
@property(null_resettable, nonatomic,strong) UIFont *font;// default is nil (system font 17 plain)

@end

NS_ASSUME_NONNULL_END
