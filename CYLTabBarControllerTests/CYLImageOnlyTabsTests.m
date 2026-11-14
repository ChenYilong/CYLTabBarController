//
//  CYLImageOnlyTabsTests.m
//  CYLTabBarControllerTests
//
//  [EN] Image-only tabs (docs/Image-Only-Tabs.md): the app's own offsets and insets win, the automatic centering can be
//       turned off, and offsets and insets set after `-initWithViewControllers:tabBarItemsAttributes:` apply (#95).
//  [CN] 纯图标 Tab（docs/Image-Only-Tabs.md）：App 自己的偏移与内边距优先，自动居中可以关闭，`-initWithViewControllers:tabBarItemsAttributes:`
//       之后设置的偏移与内边距生效（#95）。
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import <objc/runtime.h>

@interface CYLImageOnlyTabsTests : XCTestCase
@end

@implementation CYLImageOnlyTabsTests

/// [EN] Two image-only tabs (the second with its own insets and offset) and one tab with a title.
/// [CN] 两个纯图标 Tab（第二个有自己的内边距与偏移）和一个有标题的 Tab。
- (NSArray<NSDictionary *> *)attributes {
    return @[
        @{ CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] },
        @{ CYLTabBarItemImage : [UIImage systemImageNamed:@"star"],
           CYLTabBarItemImageInsets : [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(2, 0, -2, 0)],
           CYLTabBarItemTitlePositionAdjustment : [NSValue valueWithUIOffset:UIOffsetMake(0, -7)] },
        @{ CYLTabBarItemTitle : @"Me", CYLTabBarItemImage : [UIImage systemImageNamed:@"person"] },
    ];
}

- (CYLTabBarController *)tabBarControllerInWindow:(void (^)(CYLTabBarController *tabBarController))beforeLayout {
    CYLTabBarController *tabBarController =
        [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new], [UIViewController new] ]
                                       tabBarItemsAttributes:[self attributes]];
    if (beforeLayout) {
        beforeLayout(tabBarController);
    }
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    [self layOut:tabBarController];
    objc_setAssociatedObject(self, _cmd, window, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return tabBarController;
}

- (void)layOut:(CYLTabBarController *)tabBarController {
    for (NSUInteger pass = 0; pass < 4; pass++) {
        [tabBarController.tabBar setNeedsLayout];
        [tabBarController.view layoutIfNeeded];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.15]];
    }
}

/// [EN] A tab's own `CYLTabBarItemImageInsets` and `CYLTabBarItemTitlePositionAdjustment` are kept by the centering.
/// [CN] Tab 自己的 `CYLTabBarItemImageInsets` 与 `CYLTabBarItemTitlePositionAdjustment` 不会被自动居中替换。
- (void)testAnItemsOwnInsetsAndOffsetAreKept {
    CYLTabBarController *tabBarController = [self tabBarControllerInWindow:nil];
    UITabBarItem *item = tabBarController.viewControllers[1].tabBarItem;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(item.imageInsets, UIEdgeInsetsMake(2, 0, -2, 0)), @"%@", NSStringFromUIEdgeInsets(item.imageInsets));
    XCTAssertTrue(UIOffsetEqualToOffset(item.titlePositionAdjustment, UIOffsetMake(0, -7)), @"%@", NSStringFromUIOffset(item.titlePositionAdjustment));
    UITabBarItem *titled = tabBarController.viewControllers[2].tabBarItem;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(titled.imageInsets, UIEdgeInsetsZero), @"a tab with a title is left alone");
}

/// [EN] `automaticallyAdjustsImageOnlyTabs = NO`: the image-only tab without its own values keeps UIKit's zero insets.
/// [CN] `automaticallyAdjustsImageOnlyTabs = NO`：没有自己设置值的纯图标 Tab 保持 UIKit 的零内边距。
- (void)testTurningTheCenteringOffKeepsUIKitsPosition {
    CYLTabBarController *tabBarController = [self tabBarControllerInWindow:^(CYLTabBarController *controller) {
        controller.automaticallyAdjustsImageOnlyTabs = NO;
    }];
    UITabBarItem *item = tabBarController.viewControllers[0].tabBarItem;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(item.imageInsets, UIEdgeInsetsZero), @"%@", NSStringFromUIEdgeInsets(item.imageInsets));
    XCTAssertTrue(UIOffsetEqualToOffset(item.titlePositionAdjustment, UIOffsetZero), @"%@", NSStringFromUIOffset(item.titlePositionAdjustment));
}

/// [EN] #95: `-updateImageInsets:` and `titlePositionAdjustment` after `-initWithViewControllers:tabBarItemsAttributes:`
///      reach the tabs; a tab's own insets still win, and `UIEdgeInsetsZero` gives the centering back.
/// [CN] #95：在 `-initWithViewControllers:tabBarItemsAttributes:` 之后调用 `-updateImageInsets:` 并设置 `titlePositionAdjustment`，
///      会作用到各 Tab；Tab 自己的内边距仍然优先，`UIEdgeInsetsZero` 恢复自动居中。
- (void)testInsetsAndOffsetSetAfterInitApply {
    CYLTabBarController *tabBarController = [self tabBarControllerInWindow:nil];
    UIEdgeInsets insets = UIEdgeInsetsMake(4, 0, -4, 0);
    [tabBarController updateImageInsets:insets];
    tabBarController.titlePositionAdjustment = UIOffsetMake(0, -3);
    [self layOut:tabBarController];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(tabBarController.imageInsets, insets));
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(tabBarController.viewControllers[0].tabBarItem.imageInsets, insets),
                  @"%@", NSStringFromUIEdgeInsets(tabBarController.viewControllers[0].tabBarItem.imageInsets));
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(tabBarController.viewControllers[2].tabBarItem.imageInsets, insets));
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(tabBarController.viewControllers[1].tabBarItem.imageInsets, UIEdgeInsetsMake(2, 0, -2, 0)),
                  @"a tab's own insets win");
    XCTAssertEqual(tabBarController.viewControllers[2].tabBarItem.titlePositionAdjustment.vertical, -3);
    [tabBarController updateImageInsets:UIEdgeInsetsZero];
    [self layOut:tabBarController];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(tabBarController.viewControllers[2].tabBarItem.imageInsets, UIEdgeInsetsZero),
                  @"zero insets are given back to the tab with a title");
}

/// [EN] A 30 pt image drawn as is (not a symbol). [CN] 原样绘制的 30pt 图片（不是系统符号）。
static UIImage *CYLImageOnlyTestsImage(void) {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(30, 30)];
    return [[renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [UIColor.redColor setFill];
        UIRectFill(CGRectMake(0, 0, 30, 30));
    }] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

/// [EN] Classic style (iOS 25 and earlier): image-only tabs are centered in the bar's content area, also with an opaque
///      `UITabBarAppearance` set after creation (the ObjC gallery's "3.3 Background color change").
/// [CN] 经典样式（iOS 25 及更早）：纯图标 Tab 在 TabBar 内容区内居中，创建后再设置不透明的 `UITabBarAppearance` 时也一样
///      （ObjC 图库「3.3 Background color change」）。
- (void)testImageOnlyTabsAreCenteredOnTheClassicStyle {
    if ([CYLConstants isLiquidGlassActive]) {
        return;
    }
    NSMutableArray *attributes = [NSMutableArray array];
    for (NSUInteger index = 0; index < 4; index++) {
        [attributes addObject:@{ CYLTabBarItemImage : CYLImageOnlyTestsImage() }];
    }
    CYLTabBarController *tabBarController =
        [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new], [UIViewController new], [UIViewController new] ]
                                       tabBarItemsAttributes:attributes];
    UITabBarAppearance *appearance = [tabBarController.tabBar.standardAppearance copy];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.darkGrayColor;
    tabBarController.tabBar.standardAppearance = appearance;
    tabBarController.tabBar.scrollEdgeAppearance = appearance;
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    [self layOut:tabBarController];
    NSUInteger checked = 0;
    for (UIControl *button in tabBarController.tabBar.subviews) {
        if (![button isKindOfClass:[UIControl class]]) {
            continue;
        }
        for (UIImageView *imageView in button.subviews) {
            if (![imageView isKindOfClass:[UIImageView class]] || CGRectGetHeight(imageView.frame) < 20) {
                continue;
            }
            checked++;
            XCTAssertEqualWithAccuracy(CGRectGetMidY(imageView.frame), CGRectGetMidY(button.bounds), 1.5,
                                       @"image %@ in button %@", NSStringFromCGRect(imageView.frame), NSStringFromCGRect(button.bounds));
        }
    }
    XCTAssertGreaterThan(checked, 0u);
}

@end
