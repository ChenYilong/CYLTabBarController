//
//  CYLPlusButtonSubclass.m
//  CYLTabBarControllerDemo
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/24.
// [CN] Copyright (c) 2026年 https://github.com/ChenYilong . All rights reserved.
// [EN] Copyright (c) 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButtonSubclass.h"
#import "CYLMainRootViewController.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/UIColor+CYLTabBarControllerExtention.h>
#else
#import "UIColor+CYLTabBarControllerExtention.h"
#endif
@interface CYLPlusButtonSubclass () {
    CGFloat _buttonImageHeight;
}


@end

static CGFloat const CYLDemoPlusButtonWidth = 55;

@implementation CYLPlusButtonSubclass

#pragma mark -
#pragma mark - Life Cycle

+ (void)load {
    // [CN] 请在 `-[AppDelegate application:didFinishLaunchingWithOptions:]` 中进行注册，否则iOS10系统下存在Crash风险。
    // [EN] Register it in `-[AppDelegate application:didFinishLaunchingWithOptions:]`, otherwise there is a risk of
    //      crashing on iOS 10.
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

#pragma mark -
#pragma mark - CYLPlusButtonSubclassing Methods


// [CN] 上下结构的 button
// [EN] A button with a vertical (top/bottom) layout

/*!
 * [EN] 9.5 pt, or smaller when the localized title is wider than `width` (e.g. German, Russian), so it stays on one line.
 * [CN] 9.5 pt；本地化标题比 `width` 宽时（如德语、俄语）缩小字号，保证单行显示。
 */
+ (UIFont *)titleFontFittingWidth:(CGFloat)width {
    CGFloat const fontSize = 9.5;
    CGFloat titleWidth = [[self plusButtonTitle] sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]}].width;
    if (titleWidth <= width) {
        return [UIFont systemFontOfSize:fontSize];
    }
    return [UIFont systemFontOfSize:MAX(7, floor(fontSize * width / titleWidth * 10) / 10)];
}

+ (id)plusButton {
    // `[self alloc]`, not `CYLPlusButtonSubclass`: a subclass (`CYLSecondPlusButtonSubclass`) gets its own instance and its own icon.
    CYLPlusButtonSubclass *button = [[self alloc] init];
    UIImage *normalButtonImage = [self contentImage];
    UIImage *hlightButtonImage = [self selectedContentImage];
    
    [button setImage:normalButtonImage forState:UIControlStateNormal];
    [button setImage:hlightButtonImage forState:(UIControlStateHighlighted | UIControlStateSelected)];
    
    button.contentMode = UIViewContentModeCenter;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;

    // 选中后再按下（selected + highlighted）时的标题颜色
    UIColor *selectedHighlightedTitleColor = [UIColor cyl_systemGreenColor];
    // The plus button of THIS class's context. With several plus buttons `CYLExternPlusButton` is only the one registered last.
    CYLPlusButton *registeredPlusButton = [CYLPlusButton plusButtonForTabBarContext:[self matchedTabBarContext]];
    BOOL isSelectedAndHighlighted = (button.isSelected || button.isHighlighted) || ((registeredPlusButton.isSelected || registeredPlusButton.isHighlighted));

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        config.baseBackgroundColor = [UIColor clearColor];
        config.baseForegroundColor = isSelectedAndHighlighted ? selectedHighlightedTitleColor : [UIColor labelColor]; // [CN] ← 加这一行，控制图片 tint 和文字颜色
        // [EN] ← Add this line to control the image tint and text color

        // [CN] ===== 核心：图片在上，文字在下 =====
        // [EN] ===== Core: image on top, text below =====
        config.imagePlacement = NSDirectionalRectEdgeTop;
        //        config.imagePadding = 1.0;

        // 字体：译文较长时缩小，保证单行显示 / smaller for long translations, so the title stays on one line
        UIFont *font = [self titleFontFittingWidth:CYLDemoPlusButtonWidth];
        // configuration 模式下 `-setTitleColor:forState:` 不生效，
        // 颜色只能在 transformer 里给定。normal / selectedContentView 是两个独立实例，
        // 各自在构造时就把颜色定死，避免依赖构造后才变化的 state。
        config.titleTextAttributesTransformer =
        ^NSDictionary<NSAttributedStringKey,id> *(NSDictionary<NSAttributedStringKey,id> *attrs) {
            NSMutableDictionary *m = [attrs mutableCopy];
            m[NSFontAttributeName] = font;
            m[NSForegroundColorAttributeName] = isSelectedAndHighlighted ? selectedHighlightedTitleColor : [UIColor labelColor];
            return [m copy];
        };

        // The title gets the whole button width (the plain configuration adds leading/trailing insets).
        NSDirectionalEdgeInsets contentInsets = config.contentInsets;
        contentInsets.leading = 0;
        contentInsets.trailing = 0;
        config.contentInsets = contentInsets;
        config.titleLineBreakMode = NSLineBreakByClipping;
        button.configuration = config;

        // [CN] ===== 禁用高亮变暗效果 =====
        // [EN] ===== Disable the darkening effect on highlight =====
        button.configurationUpdateHandler = ^(UIButton *btn) {
            btn.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
            btn.imageView.alpha = 1.0;
        };

    } else
#endif
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // [CN] ===== iOS 15 以下：手动布局 =====
        // [EN] ===== Below iOS 15: manual layout =====
        button.adjustsImageWhenHighlighted = NO;
        button.backgroundColor = UIColor.clearColor;
        button.titleLabel.font = [self titleFontFittingWidth:CYLDemoPlusButtonWidth];
#pragma clang diagnostic pop
    }

    [button setTitle:[self plusButtonTitle] forState:UIControlStateNormal];
    [button setTitle:[self plusButtonTitle] forState:(UIControlStateSelected | UIControlStateHighlighted)];
    // [CN] iOS 15 以下走 titleColor，iOS 15+ 由上面的 transformer 接管（此处调用无副作用）
    // [EN] Below iOS 15 titleColor is used; on iOS 15+ the transformer above takes over (this call has no side effects)
    [button setTitleColor:selectedHighlightedTitleColor forState:(UIControlStateSelected | UIControlStateHighlighted)];
    // [CN] [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];   // ← 加这一行
    //    [button setTitleColor:[UIColor blackColor] forState:UIControlStateSelected]; // ← 加这一行
    //    [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted]; // ← 加这一行
    // [EN] [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];   // ← Add this line
    //      [button setTitleColor:[UIColor blackColor] forState:UIControlStateSelected]; // ← Add this line
    //      [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted]; // ← Add this line
    //    button.frame = CGRectMake(0.0, 0.0, 55, 80);
    button.bounds = CGRectMake(0.0, 0.0, CYLDemoPlusButtonWidth, 80);
    
    // if you use `+plusChildViewController`, do not add Target to plusButton.
    SEL action = @selector(clickPublish);
    [button removeTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:button action:action forControlEvents:UIControlEventTouchUpInside];
    
    // [EN] Every tap reaches `tabBarController:didSelectControl:`, which bumps the plus button's badge (#535,
    //      MainTabBarController.m). It used the deprecated `cyl_userInteractionDisabled`, set from the layout at creation:
    //      this raised button never reported, so the badge stayed at 1.
    // [CN] 每次点击都会到达 `tabBarController:didSelectControl:`，并增加 PlusButton 的角标（#535，MainTabBarController.m）。以前使用已废弃的
    //      `cyl_userInteractionDisabled`，并在创建时按布局决定：这个凸起的按钮从不上报，角标一直是 1。
    button.reportsTapsToDelegate = YES;
    
    // [CN] ===== iOS 15 以下：手动设置 imageView / titleLabel 位置 =====
    // [EN] ===== Below iOS 15: manually set the imageView / titleLabel positions =====
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
    if (@available(iOS 15.0, *)) {
        // [CN] iOS 15+ 由 UIButtonConfiguration 自动处理，无需手动布局
        // [EN] On iOS 15+ UIButtonConfiguration handles this automatically, no manual layout needed
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
    // [EN] Issue #91: a larger touchable area without changing the frame, e.g. the gap below a raised plus button, so a tap
    // there no longer falls through to the page behind. Positive values grow it outward. Shown and scaled at runtime by
    // the "PlusButton touchable area" row of the settings section.
    // [CN] Issue #91：不改变 frame 即可扩大点击范围，例如凸起 PlusButton 下方的间隙，点在那里不再穿透到后面的页面。正值向外扩展。
    // 设置分组中的「PlusButton 点击范围」行可在运行时显示并按倍数调整。
    button.touchableAreaOutsets = UIEdgeInsetsMake(0, 8, 12, 8);
    // [EN] Or scale the area around the center; while debugging, show the area.
    // [CN] 或以中心按倍数放大；调试时可显示可点击区域。
    // button.touchableAreaScale = 1.5;
    // button.showsTouchableArea = YES;
    return button;
}

/*
 
 + (id)plusButton {
 
 // Create a custom UIButton with title and add it to the center of our tab bar
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
 
 button.reportsTapsToDelegate = YES;
 return button;
 }
 
 */

#pragma mark -
#pragma mark - Event Response

//- (void)clickPublish {
//    CYLTabBarController *tabBarController = [self cyl_tabBarController];
//    UIViewController *viewController = tabBarController.selectedViewController;
//    CYL_DEPRECATED_DECLARATIONS_PUSH
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
//                                                             delegate:nil
//                                                    cancelButtonTitle:NSLocalizedString(@"取消", nil)
//                                               destructiveButtonTitle:nil
//                                                    otherButtonTitles:@"拍照", @"从相册选取", @"淘宝一键转卖", nil];
//    [actionSheet showInView:viewController.view];
//    CYL_DEPRECATED_DECLARATIONS_POP
//
//    [self addScaleAnimationOnView:self.imageView repeatCount:1];
// [CN] //暂时不推荐用旋转方式，badge也会旋转。
// [EN] //Rotation is not recommended for now, since the badge would rotate too.
//
////    [self addRotateAnimationOnPlusButton:self.imageView repeatCount:1];
//
//}
- (void)clickPublish {
    UIViewController *viewController = CYLGetRootViewController();
    
    // The new tab bar controller shows the OTHER plus button (another context): the title tells which.
    // 新的 TabBarController 显示 **另一个** PlusButton（另一个 context），标题会说明是哪一个。
    Class nextPlusButtonClass = [CYLPlusButtonSubclass alternatePlusButtonClassForOwner:self];
    NSString *nextPlusButtonTitle = [nextPlusButtonClass plusButtonTitle];
    
    UIAlertController *actionSheet = [UIAlertController
                                      alertControllerWithTitle:CYLLocalizedString(@"Switch Style 切换样式")
                                      message:[NSString stringWithFormat:CYLLocalizedString(@"PlusButton → 「%@」"), nextPlusButtonTitle]
                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"Liquid Glass液态玻璃")
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
        // handle choose

        CYLMainRootViewController *rootController = [CYLMainRootViewController currentRootViewController];
        [rootController createLiquidGlassTabBarWithPlusButtonClass:nextPlusButtonClass];

    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"FlatDesign扁平设计样式")
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
        // handle choose

        CYLMainRootViewController *rootController = [CYLMainRootViewController currentRootViewController];
        [rootController createFlatDesignTabBarWithPlusButtonClass:nextPlusButtonClass];

    }]];
    
    
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消")
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

// [CN] 缩放动画
// [EN] Scale animation
- (void)addScaleAnimationOnView:(UIView *)animationView repeatCount:(float)repeatCount {
    if ([CYLConstants isLiquidGlassActive]) {
        // [CN] 液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        // [EN] With the Liquid Glass effect, custom tap effects are not allowed; only the system glass effect can be used.
        return;
    }
    // [CN] 需要实现的帧动画，这里根据需求自定义
    // [EN] The keyframe animation to implement; customize it here as needed
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
        // [CN] 液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        // [EN] With the Liquid Glass effect, custom tap effects are not allowed; only the system glass effect can be used.
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

+ (UIViewController *)plusChildViewController {
    UIViewController *plusChildViewController = [[UIViewController alloc] init];
//    plusChildViewController.view.backgroundColor = [UIColor redColor];
    plusChildViewController.navigationItem.title = CYLLocalizedString(@"PlusChildViewController");
    UIViewController *plusChildNavigationController = [[UINavigationController alloc]
                                                   initWithRootViewController:plusChildViewController];
    plusChildNavigationController.title = NSLocalizedString(@"发布", nil);
    return plusChildNavigationController;
}

+ (NSUInteger)indexOfPlusButtonInTabBar {
    return 2;
}

/// The plus button's title stays on the same center line as the tab item titles, in every tab bar style.
+ (BOOL)alignsTitleWithTabBarItemTitles {
    return YES;
}

// #408: the plus button's identifier, read as `control.cyl_tabBarItemIdentifier` in `-tabBarController:didSelectControl:`.
// PlusButton 的标识，在 `-tabBarController:didSelectControl:` 中通过 `control.cyl_tabBarItemIdentifier` 读取。
+ (NSString *)tabBarItemIdentifier {
    return @"plus";
}

+ (BOOL)shouldSelectPlusChildViewController {
    BOOL isSelected = [CYLPlusButton plusButtonForTabBarContext:[self matchedTabBarContext]].selected;
    if  (isSelected) {
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"PlusButton is selected");
    } else {
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"PlusButton is not selected");
    }
    return YES;
}

//+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
//    return  0.5;
//}

+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    //    if (@available(iOS 13.0, *)) {
    //        return (CYL_IS_IPHONE_X ? - 6 : 4);
    //    }
    //    return 4;
    return -14;
}

//
//+ (NSString *)tabBarContext {
//    return NSStringFromClass([CYLMainRootViewController class]);
//}

+ (UIImage *)selectedContentImage {
    UIImage *hlightButtonImage = [UIImage imageNamed:@"post_highlight"];
    return hlightButtonImage ;
}

+ (UIImage *)contentImage {
    UIImage *normalButtonImage = [UIImage imageNamed:@"post_normal"];
    return normalButtonImage;
}

+ (NSString *)plusButtonTitle {
    return CYLLocalizedString(@"发布");
}

+ (Class)alternatePlusButtonClassForOwner:(id)owner {
    // The class of the plus button bound to the tab bar controller `owner` belongs to (by its context).
    Class currentPlusButtonClass = [[CYLPlusButton plusButtonForOwner:owner] class];
    BOOL isSecond = currentPlusButtonClass && [currentPlusButtonClass isSubclassOfClass:[CYLSecondPlusButtonSubclass class]];
    return isSecond ? [CYLPlusButtonSubclass class] : [CYLSecondPlusButtonSubclass class];
}

@end

#pragma mark - CYLSecondPlusButtonSubclass

@implementation CYLSecondPlusButtonSubclass

/*!
 * [EN] The context this plus button is bound to. A `CYLTabBarController` created with this `context` shows it; the
 *      others (context "CYLTabBarController") show `CYLPlusButtonSubclass`.
 * [CN] 这个 PlusButton 绑定的 context。用这个 `context` 创建的 `CYLTabBarController` 显示它，其他的（context 为 "CYLTabBarController"）显示 `CYLPlusButtonSubclass`。
 */
+ (NSString *)tabBarContext {
    return @"CYLSecondPlusButtonContext";
}

// #408: another context, another plus button, another identifier. 另一个 context 的 PlusButton，标识也不同。
+ (NSString *)tabBarItemIdentifier {
    return @"camera";
}

+ (NSString *)plusButtonTitle {
    return CYLLocalizedString(@"拍摄");
}

// Only the icon differs: a camera (SF Symbol, iOS 13+), the other plus button keeps the `post_*` images.
+ (UIImage *)cameraImageWithColor:(UIColor *)color {
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:34 weight:UIImageSymbolWeightMedium];
        UIImage *image = [UIImage systemImageNamed:@"camera.circle.fill" withConfiguration:configuration];
        return [image imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    return nil;
}

+ (UIImage *)contentImage {
    return [self cameraImageWithColor:[UIColor systemOrangeColor]] ?: [super contentImage];
}

+ (UIImage *)selectedContentImage {
    return [self cameraImageWithColor:[UIColor systemRedColor]] ?: [super selectedContentImage];
}

@end


#pragma mark - CYLCloseSubviewPlusButtonSubclass

/// [EN] Side of the X button, in points. [CN] X 按钮的边长（pt）。
static CGFloat const CYLCloseSubviewButtonSide = 22;
/// [EN] The X button's current color, shared with the copy shown in the Liquid Glass selected layer.
/// [CN] X 按钮当前的颜色，与液态玻璃选中图层中显示的副本共用。
static UIColor *CYLCloseSubviewCurrentColor = nil;

@interface CYLCloseSubviewPlusButtonSubclass ()

- (void)closeButtonTapped:(UIButton *)sender;

@end

@implementation CYLCloseSubviewPlusButtonSubclass

/*!
 * [EN] The context this plus button is bound to, different from the other two demo plus buttons.
 * [CN] 这个 PlusButton 绑定的 context，与 Demo 中另外两个 PlusButton 不同。
 */
+ (NSString *)tabBarContext {
    return @"CYLCloseSubviewPlusButtonContext";
}

+ (NSString *)tabBarItemIdentifier {
    return @"closeSubview";
}

+ (NSString *)plusButtonTitle {
    return CYLLocalizedString(@"子控件");
}

+ (UIColor *)currentCloseColor {
    return CYLCloseSubviewCurrentColor ?: [UIColor systemRedColor];
}

+ (UIImage *)closeImage {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:CYLCloseSubviewButtonSide weight:UIImageSymbolWeightBold];
    return [UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:configuration];
}

+ (id)plusButton {
    CYLCloseSubviewPlusButtonSubclass *button = [super plusButton];
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[[self closeImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    closeButton.tintColor = [self currentCloseColor];
    closeButton.accessibilityLabel = @"X";
    // [EN] A UIControl subview: the tab bar hands it its own touches (issue #202).
    // [CN] UIControl 子视图：TabBar 把它自己的触摸交给它（issue #202）。
    [closeButton addTarget:button action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button addSubview:closeButton];
    button->_closeButton = closeButton;
    return button;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // [EN] Top right, inside the bounds, above the image and the title.
    // [CN] 右上角，在按钮范围内，位于图片与标题之上。
    CGFloat side = CYLCloseSubviewButtonSide;
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - side, 0, side, side);
    [self bringSubviewToFront:self.closeButton];
}

- (void)closeButtonTapped:(UIButton *)sender {
    UIColor *color = [UIColor colorWithHue:(CGFloat)arc4random_uniform(360) / 360.0 saturation:0.85 brightness:0.9 alpha:1.0];
    CYLCloseSubviewCurrentColor = color;
    sender.tintColor = color;
    // [EN] The Liquid Glass selected layer shows another instance (`selectedContentView`): keep it in step.
    // [CN] 液态玻璃的选中图层显示的是另一个实例（`selectedContentView`）：同步它的颜色。
    UIButton *selectedContentView = self.selectedContentView;
    if ([selectedContentView isKindOfClass:[CYLCloseSubviewPlusButtonSubclass class]]) {
        ((CYLCloseSubviewPlusButtonSubclass *)selectedContentView).closeButton.tintColor = color;
    }
}

@end
