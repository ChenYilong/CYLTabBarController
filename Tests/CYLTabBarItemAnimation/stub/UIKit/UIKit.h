// [EN] The few UIKit declarations the CYLTabBarItemAnimation sources use, so the tests build as a macOS command line tool
//      with Foundation only (see run.sh). Not a UIKit replacement. CoreGraphics' CGSize / CGRect come with Foundation.
// [CN] CYLTabBarItemAnimation 源码用到的少量 UIKit 声明，使测试可以只链接 Foundation、作为 macOS 命令行工具编译（见 run.sh）。并非 UIKit 的替代品。
//      CoreGraphics 的 CGSize / CGRect 随 Foundation 提供。
#pragma once
#import <Foundation/Foundation.h>
#if __has_include(<CoreGraphics/CoreGraphics.h>)
#import <CoreGraphics/CoreGraphics.h>
#endif

#ifndef NS_SWIFT_UI_ACTOR
#define NS_SWIFT_UI_ACTOR
#endif

typedef NS_ENUM(NSInteger, UIViewContentMode) {
    UIViewContentModeScaleToFill,
    UIViewContentModeScaleAspectFit,
    UIViewContentModeScaleAspectFill,
};

typedef NS_ENUM(NSInteger, UIUserInterfaceStyle) {
    UIUserInterfaceStyleUnspecified,
    UIUserInterfaceStyleLight,
    UIUserInterfaceStyleDark,
};

@interface UITraitCollection : NSObject
@property (nonatomic) UIUserInterfaceStyle userInterfaceStyle;
@end

@interface UIColor : NSObject
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection;
@end

typedef NS_OPTIONS(NSUInteger, UIViewAutoresizing) {
    UIViewAutoresizingNone = 0,
};

@interface UIView : NSObject
@property (nonatomic) CGRect frame;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) UIViewAutoresizing autoresizingMask;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic) CGFloat alpha;
@property (nonatomic, strong) UITraitCollection *traitCollection;
@property (nonatomic, weak, readonly) UIView *superview;
@property (nonatomic, readonly) NSArray<UIView *> *subviews;
- (void)addSubview:(UIView *)view;
- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview;
- (void)removeFromSuperview;
@property (nonatomic) UIViewContentMode contentMode;
@property (nonatomic, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property (nonatomic) BOOL translatesAutoresizingMaskIntoConstraints;
@property (nonatomic) BOOL clipsToBounds;
@end

@interface UIControl : UIView
@end
