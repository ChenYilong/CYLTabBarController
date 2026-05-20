//
//  CYLPlusButtonSubclass.m
//  CYLTabBarControllerDemo
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/24.
//  Copyright (c) 2026年 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButtonSubclass.h"
#import "CYLMainRootViewController.h"
@interface CYLPlusButtonSubclass () {
    CGFloat _buttonImageHeight;
}

@end

@implementation CYLPlusButtonSubclass

#pragma mark -
#pragma mark - Life Cycle

+ (void)load {
    //请在 `-[AppDelegate application:didFinishLaunchingWithOptions:]` 中进行注册，否则iOS10系统下存在Crash风险。
    //    [super registerPlusButton];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
        if (@available(iOS 15.0, *)) {
            // Use UIButtonConfiguration with a configurationUpdateHandler to avoid dimming on highlight
            self.configuration = [UIButtonConfiguration plainButtonConfiguration];
            __weak typeof(self) weakSelf = self;
            self.configurationUpdateHandler = ^(UIButton *button) {
                // Ensure the image does not dim when highlighted/selected
                button.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
                button.imageView.alpha = 1.0;
                // Keep any existing title alignment behavior
                weakSelf.titleLabel.textAlignment = NSTextAlignmentCenter;
            };
        } else {
            // Fallback on earlier iOS versions
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.adjustsImageWhenHighlighted = NO;
#pragma clang diagnostic pop
            
        }
#else
        // For SDKs earlier than iOS 15, keep the legacy property
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.adjustsImageWhenHighlighted = NO;
#pragma clang diagnostic pop
        
#endif
    }
    return self;
}

//上下结构的 button
/*
+ (id)plusButton {
CYLPlusButtonSubclass *button = [[CYLPlusButtonSubclass alloc] init];
UIImage *normalButtonImage = [self contentImage];
UIImage *hlightButtonImage = [self selectedContentImage];

[button setImage:normalButtonImage forState:UIControlStateNormal];
[button setImage:hlightButtonImage forState:UIControlStateHighlighted];
[button setImage:hlightButtonImage forState:UIControlStateSelected];

button.contentMode = UIViewContentModeCenter;
button.imageView.contentMode = UIViewContentModeScaleAspectFit;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
if (@available(iOS 15.0, *)) {
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.baseBackgroundColor = [UIColor clearColor];
    
    // ===== 核心：图片在上，文字在下 =====
    config.imagePlacement = NSDirectionalRectEdgeTop;
//        config.imagePadding = 1.0;
    
    // 字体
    UIFont *font = [UIFont systemFontOfSize:9.5];
    config.titleTextAttributesTransformer =
        ^NSDictionary<NSAttributedStringKey,id> *(NSDictionary<NSAttributedStringKey,id> *attrs) {
            NSMutableDictionary *m = [attrs mutableCopy];
            m[NSFontAttributeName] = font;
            return [m copy];
        };
    
    button.configuration = config;
    
    // ===== 禁用高亮变暗效果 =====
    button.configurationUpdateHandler = ^(UIButton *btn) {
        btn.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        btn.imageView.alpha = 1.0;
    };
    
} else
#endif
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // ===== iOS 15 以下：手动布局 =====
    button.adjustsImageWhenHighlighted = NO;
    button.backgroundColor = UIColor.clearColor;
    button.titleLabel.font = [UIFont systemFontOfSize:9.5];
#pragma clang diagnostic pop
}

[button setTitle:@"发布" forState:UIControlStateNormal];
[button setTitle:@"发布" forState:UIControlStateSelected];

//    button.frame = CGRectMake(0.0, 0.0, 55, 80);
button.bounds = CGRectMake(0.0, 0.0, 55, 80);

// if you use `+plusChildViewController`, do not addTarget to plusButton.
SEL action = @selector(clickPublish);
[button removeTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
[button addTarget:button action:action forControlEvents:UIControlEventTouchUpInside];

if (CYLPlusChildViewController && button.isLayoutCentered) {
    [button cyl_setUserInteractionDisabled:NO];
} else {
    [button cyl_setUserInteractionDisabled:YES];
}

// ===== iOS 15 以下：手动设置 imageView / titleLabel 位置 =====
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
if (@available(iOS 15.0, *)) {
    // iOS 15+ 由 UIButtonConfiguration 自动处理，无需手动布局
} else
#endif
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat const imageViewEdgeWidth  = self.cyl_tabBarController.visiableTabBarSize.width * 0.7;
    CGFloat const imageViewEdgeHeight = imageViewEdgeWidth * 0.9;
    CGFloat const centerOfView        = self.cyl_tabBarController.visiableTabBarSize.width * 0.5;
    CGFloat const labelLineHeight     = button.titleLabel.font.lineHeight;
    CGFloat const verticalMargin      = (self.cyl_tabBarController.visiableTabBarSize.height
                                         - labelLineHeight - imageViewEdgeHeight) * 0.5;
    
    CGFloat const centerOfImageView   = verticalMargin + imageViewEdgeHeight * 0.5;
    CGFloat const centerOfTitleLabel  = imageViewEdgeHeight + verticalMargin * 2
                                        + labelLineHeight * 0.5 + 5;
    
    button.imageView.bounds  = CGRectMake(0, 0, imageViewEdgeWidth, imageViewEdgeHeight);
    button.imageView.center  = CGPointMake(centerOfView, centerOfImageView);
    
    button.titleLabel.bounds = CGRectMake(0, 0,
                                          self.cyl_tabBarController.visiableTabBarSize.width,
                                          labelLineHeight);
    button.titleLabel.center = CGPointMake(centerOfView, centerOfTitleLabel);
#pragma clang diagnostic pop
}

return button;
}
*/
#pragma mark -
#pragma mark - CYLPlusButtonSubclassing Methods

/*
 *
 Create a custom UIButton with title and add it to the center of our tab bar
 *
 */
+ (id)plusButton {
    CYLPlusButtonSubclass *button = [[CYLPlusButtonSubclass alloc] init];
    UIImage *normalButtonImage = [self contentImage];
    UIImage *hlightButtonImage = [self selectedContentImage];
    
    [button setImage:normalButtonImage forState:UIControlStateNormal];
    [button setImage:hlightButtonImage forState:UIControlStateHighlighted];
    [button setImage:hlightButtonImage forState:UIControlStateSelected];
    //    [button setTintColor:[UIColor colorWithRed:0/255.0f green:255/255.0f blue:189/255.0f alpha:1]];
    button.contentMode = UIViewContentModeCenter;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
    if (@available(iOS 15.0, *)) {
        // Ensure configuration exists
        UIButtonConfiguration *config = button.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
        config.baseBackgroundColor = [UIColor clearColor];
        // ===== Highlight behavior (no dimming) =====
        __weak typeof(button) weakButton = button;
        UIButtonConfigurationUpdateHandler existingHandler = button.configurationUpdateHandler;
        button.configurationUpdateHandler = ^(UIButton *btn) {
            btn.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
            btn.imageView.alpha = 1.0;
        };
        
    } else
#endif
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // ===== iOS 15 以下：手动布局 =====
        button.adjustsImageWhenHighlighted = NO;
        button.backgroundColor = UIColor.clearColor;
        button.titleLabel.font = [UIFont systemFontOfSize:9.5];
#pragma clang diagnostic pop
    }
    button.titleLabel.font = [UIFont systemFontOfSize:9.5];
    [button sizeToFit]; // or set frame in this way `button.frame = CGRectMake(0.0, 0.0, 250, 100);`
    button.frame = CGRectMake(0.0, 0.0, 55, 59);
    button.bounds = CGRectMake(0.0, 0.0, 55, 59);
    
    
    // if you use `+plusChildViewController` , do not addTarget to plusButton.
    SEL action = @selector(clickPublish);
    [button removeTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:button action:action forControlEvents:UIControlEventTouchUpInside];
    
    if (CYLPlusChildViewController && button.isLayoutCentered) {
        [button cyl_setUserInteractionDisabled:NO];
    } else {
        button.cyl_shouldNotSelect = YES;
    }
    return button;
}

/*
 *
 Create a custom UIButton without title and add it to the center of our tab bar
 *
 */
//+ (id)plusButton
//{
//
//    UIImage *buttonImage = [UIImage imageNamed:@"hood.png"];
//    UIImage *highlightImage = [UIImage imageNamed:@"hood-selected.png"];
//
//    CYLPlusButtonSubclass* button = [CYLPlusButtonSubclass buttonWithType:UIButtonTypeCustom];
//
//    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
//    button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
//    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
//    [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
//    [button addTarget:button action:@selector(clickPublish) forControlEvents:UIControlEventTouchUpInside];
//
//    return button;
//}

#pragma mark -
#pragma mark - Event Response

//- (void)clickPublish {
//    CYLTabBarController *tabBarController = [self cyl_tabBarController];
//    UIViewController *viewController = tabBarController.selectedViewController;
//    CYL_DEPRECATED_DECLARATIONS_PUSH
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
//                                                             delegate:nil
//                                                    cancelButtonTitle:@"取消"
//                                               destructiveButtonTitle:nil
//                                                    otherButtonTitles:@"拍照", @"从相册选取", @"淘宝一键转卖", nil];
//    [actionSheet showInView:viewController.view];
//    CYL_DEPRECATED_DECLARATIONS_POP
//    
//    [self addScaleAnimationOnView:self.imageView repeatCount:1];
//    //暂时不推荐用旋转方式，badge也会旋转。
//    
////    [self addRotateAnimationOnPlusButton:self.imageView repeatCount:1];
//
//}
- (void)clickPublish {
    CYLTabBarController *tabBarController = [self cyl_tabBarController];
    UIViewController *viewController = tabBarController.selectedViewController;

    UIAlertController *actionSheet = [UIAlertController
                                      alertControllerWithTitle:@"发布"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"拍照"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
        // handle take photo
    }]];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"从相册选取"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
        // handle choose from album
    }]];



    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消"
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];

    // Fix for iPad — anchor to the bottom of the screen
    if (actionSheet.popoverPresentationController) {
        actionSheet.popoverPresentationController.sourceView = viewController.view;
        actionSheet.popoverPresentationController.sourceRect = CGRectMake(
            viewController.view.bounds.size.width / 2,  // center X
            viewController.view.bounds.size.height,     // bottom Y
            0,
            0
        );
        actionSheet.popoverPresentationController.permittedArrowDirections = 0; // no arrow
    }

    [viewController presentViewController:actionSheet animated:YES completion:nil];
    [self addScaleAnimationOnView:self.imageView repeatCount:1];
}

//缩放动画
- (void)addScaleAnimationOnView:(UIView *)animationView repeatCount:(float)repeatCount {
    if ([CYLConstants isLiquidGlassActive]) {
        //液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        return;
    }
    //需要实现的帧动画，这里根据需求自定义
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@1.0,@1.1,@0.9,@1.15,@0.95,@1.02,@1.0];
    animation.duration = 1;
    animation.repeatCount = repeatCount;
    animation.calculationMode = kCAAnimationCubic;
    [animationView.layer addAnimation:animation forKey:nil];
}

- (void)addRotateAnimationOnPlusButton:(UIView *)animationView repeatCount:(float)repeatCount {
    if ([CYLConstants isLiquidGlassActive]) {
        //液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        return;
    }
    NSLog(@"plusButton.frame = %@", NSStringFromCGRect(animationView.frame));
    
    [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        animationView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    } completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.70 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            animationView.layer.transform = CATransform3DMakeRotation(2 * M_PI, 0, 1, 0);
        } completion:nil];
    });
}

#pragma mark - UIActionSheetDelegate
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"buttonIndex = %@", @(buttonIndex));
}
#pragma clang diagnostic pop
#pragma mark - CYLPlusButtonSubclassing

//+ (UIViewController *)plusChildViewController {
//    UIViewController *plusChildViewController = [[UIViewController alloc] init];
//    plusChildViewController.view.backgroundColor = [UIColor redColor];
//    plusChildViewController.navigationItem.title = @"PlusChildViewController";
//    UIViewController *plusChildNavigationController = [[UINavigationController alloc]
//                                                   initWithRootViewController:plusChildViewController];
//    return plusChildNavigationController;
//}
//
//+ (NSUInteger)indexOfPlusButtonInTabBar {
//    return 2;
//}

+ (BOOL)shouldSelectPlusChildViewController {
    BOOL isSelected = CYLExternPlusButton.selected;
    if  (isSelected) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"PlusButton is selected");
    } else {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"PlusButton is not selected");
    }
    return YES;
}

//+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
//    return  0.2;
//}
//
//+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
//    if (@available(iOS 13.0, *)) {
//        return (CYL_IS_IPHONE_X ? - 6 : 4);
//    }
//    return 4;
//}

//
//+ (NSString *)tabBarContext {
//    return NSStringFromClass([CYLMainRootViewController class]);
//}

- (CGRect)touchableRect {
    return self.frame;
}

+ (UIImage *)selectedContentImage {
    UIImage *hlightButtonImage = [UIImage imageNamed:@"post_highlight"];
    return hlightButtonImage ;
}

+ (UIImage *)contentImage {
    UIImage *normalButtonImage = [UIImage imageNamed:@"post_normal"];
    return normalButtonImage;
}

@end

