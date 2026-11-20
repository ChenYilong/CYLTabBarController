// [EN] The few UIKit declarations the CYLTabBarItemAnimation sources use, so the tests build as a macOS command line tool
//      with Foundation only (see run.sh). Not a UIKit replacement. CoreGraphics' CGSize / CGRect come with Foundation.
// [CN] CYLTabBarItemAnimation 源码用到的少量 UIKit 声明，使测试可以只链接 Foundation、作为 macOS 命令行工具编译（见 run.sh）。并非 UIKit 的替代品。
//      CoreGraphics 的 CGSize / CGRect 随 Foundation 提供。
#pragma once
#import <Foundation/Foundation.h>
#if __has_include(<CoreGraphics/CoreGraphics.h>)
#import <CoreGraphics/CoreGraphics.h>
#endif
// [EN] Real Core Animation layers (macOS has QuartzCore): the engine sizes and orders its tint overlay with them.
// [CN] 真实的 Core Animation 图层（macOS 自带 QuartzCore）：引擎用它们设置着色叠加图层的尺寸与层级。
#import <QuartzCore/QuartzCore.h>

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
+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (UIColor *)colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *traitCollection))dynamicProvider;
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection;
@property (nonatomic, readonly) CGColorRef CGColor;
@end

typedef struct UIEdgeInsets {
    CGFloat top, left, bottom, right;
} UIEdgeInsets;

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
@property (nonatomic, readonly) CALayer *layer;
@end

// [EN] Declared for CYLAnimatedItemView.h, which the tab bar's Swift interface imports. [CN] 供 CYLAnimatedItemView.h 使用（TabBar 的 Swift 接口会导入它）。
@interface UILabel : UIView
@end

@interface UIGestureRecognizer : NSObject
@end

@interface UILongPressGestureRecognizer : UIGestureRecognizer
@end

@interface UIPanGestureRecognizer : UIGestureRecognizer
@end

@interface UITabBarItemStateAppearance : NSObject
@end

@interface UITabBarItemAppearance : NSObject
@end

// [EN] Only declared: CYLTabBarControllerTypedefs.h (imported by CYLSwiftInterface.h) names it in block typedefs. [CN] 仅声明：CYLTabBarControllerTypedefs.h（由 CYLSwiftInterface.h 导入）在 block typedef 中用到它。
@interface UIViewController : NSObject
@end

@interface UIControl : UIView
@end

// [EN] Used by the engine's late-failure fallback (the tab's image view). [CN] 供引擎的延迟失败回退使用（Tab 的图片视图）。
typedef NS_ENUM(NSInteger, UIImageRenderingMode) {
    UIImageRenderingModeAutomatic,
    UIImageRenderingModeAlwaysOriginal,
    UIImageRenderingModeAlwaysTemplate,
};

@interface UIImage : NSObject
- (UIImage *)imageWithRenderingMode:(UIImageRenderingMode)renderingMode;
@end

@interface UIImageView : UIView
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *tintColor;
@end
