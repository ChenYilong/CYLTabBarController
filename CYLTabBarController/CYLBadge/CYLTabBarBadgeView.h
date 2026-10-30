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

/*!
 * [EN] The text surface shared by every badge view: `UILabel` (the default badge) and `CYLTabBarBadgeView`
 *      (the Liquid Glass badge on iOS 27). The two classes are unrelated, so this protocol, rather than a
 *      cast to one of them, describes what `cyl_badge` is. Declarations match `UILabel`'s own.
 * [CN] 所有角标视图共有的文本接口：`UILabel`（默认角标）和 `CYLTabBarBadgeView`（iOS 27 液态玻璃角标）。
 *      这两个类没有继承关系，因此用协议而不是强制类型转换来描述 `cyl_badge` 的类型。声明与 `UILabel` 自身保持一致。
 */
@protocol CYLBadgeTextDisplaying <NSObject>

@property (nullable, nonatomic, copy) NSString *text;
@property (null_resettable, nonatomic, strong) UIFont *font;
@property (null_resettable, nonatomic, strong) UIColor *textColor;
@property (nonatomic) NSTextAlignment textAlignment;

@end

/// `UILabel` already implements everything in `CYLBadgeTextDisplaying`; this only declares the conformance.
@interface UILabel (CYLBadgeTextDisplaying) <CYLBadgeTextDisplaying>
@end

@interface CYLTabBarBadgeView : UIView <CYLBadgeTextDisplaying>

@property (nonatomic, assign) UIEdgeInsets badgeContentInset;

/*!
 * [EN] The label that draws the badge text.
 * [CN] 绘制角标文本的 Label。
 */
@property (nonatomic, strong, readonly) UILabel *badgeLabel;

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
