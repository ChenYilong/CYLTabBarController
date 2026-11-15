//
//  CYLTabBar.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The Objective-C shell of `CYLTabBar` (docs/Swift-Migration.md, step 51): the implementation is Swift
//      (`Swift/CYLTabBar+CYLImplementation.swift`). The class stays declared in Objective-C because `CYLTabBarController.h`
//      and `CYLPlusButton.h` name it; this file keeps the overrides and the public accessors, each a one-line forward to a
//      `cyl_tabBar…` method of the Swift extension, and the iOS 27.1 hinge interaction, which needs the iOS 27.1 SDK.
// [CN] `CYLTabBar` 的 Objective-C 外壳（docs/Swift-Migration.md，第 51 步）：实现位于 Swift（`Swift/CYLTabBar+CYLImplementation.swift`）。
//      类仍在 Objective-C 中声明，因为 `CYLTabBarController.h` 与 `CYLPlusButton.h` 引用了它；本文件保留重写方法与公开存取方法（每个都是一行
//      转发到 Swift 扩展的 `cyl_tabBar…` 方法），以及需要 iOS 27.1 SDK 的 iOS 27.1 铰链交互。

#import "CYLTabBar.h"
#import "CYLConstants.h"

/*!
 * [EN] The tab bar is the delegate of the Liquid Glass gestures it tracks (`-gestureRecognizerShouldBegin:`).
 * [CN] TabBar 是其跟踪的液态玻璃手势的代理（`-gestureRecognizerShouldBegin:`）。
 */
@interface CYLTabBar () <UIGestureRecognizerDelegate>
@end

/*!
 * [EN] Implemented in Swift/CYLTabBar+CYLImplementation.swift.
 * [CN] 在 Swift/CYLTabBar+CYLImplementation.swift 中实现。
 */
@interface CYLTabBar (CYLTabBarImplementation)
- (void)cyl_tabBarSharedInit;
- (void)cyl_tabBarDealloc;
- (CGSize)cyl_tabBarSizeThatFits:(CGSize)sizeThatFits;
- (void)cyl_tabBarLayoutSubviews;
- (void)cyl_tabBarSyncTintColor:(nullable UIColor *)tintColor;
- (void)cyl_tabBarSyncUnselectedItemTintColor:(nullable UIColor *)color previous:(nullable UIColor *)previous;
- (void)cyl_tabBarSyncBarTintColor:(nullable UIColor *)color previous:(nullable UIColor *)previous;
- (void)cyl_tabBarSyncBackgroundImage:(nullable UIImage *)image previous:(nullable UIImage *)previous;
- (void)cyl_tabBarSyncShadowImage:(nullable UIImage *)image previous:(nullable UIImage *)previous;
- (void)cyl_tabBarSyncBarStyle:(UIBarStyle)barStyle previous:(UIBarStyle)previous;
- (void)cyl_tabBarWillBeginCustomizing;
- (void)cyl_tabBarDidBeginCustomizing;
- (void)cyl_tabBarDidEndCustomizing;
- (nullable UIView *)cyl_tabBarHitTest:(CGPoint)point
                             withEvent:(nullable UIEvent *)event
                          superHitTest:(UIView * _Nullable (NS_NOESCAPE ^)(CGPoint point))superHitTest;
- (void)cyl_tabBarWillAddSubview:(UIView *)view;
- (BOOL)cyl_tabBarAddScrollEdgeElementContainerInteraction:(id<UIInteraction>)interaction;
- (BOOL)cyl_tabBarRemoveScrollEdgeElementContainerInteraction:(id<UIInteraction>)interaction;
- (void)cyl_tabBarWillAddGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (BOOL)cyl_tabBarGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
- (nullable NSString *)cyl_tabBarContext;
- (void)cyl_tabBarSetContext:(nullable NSString *)context;
- (NSArray<UIControl *> *)cyl_tabBarTabBarButtonArray;
- (void)cyl_tabBarSetTabBarButtonArray:(nullable NSArray<UIControl *> *)tabBarButtonArray;
- (CGFloat)cyl_tabBarTabBarItemWidth;
- (void)cyl_tabBarSetTabBarItemWidth:(CGFloat)tabBarItemWidth;
- (CGFloat)cyl_tabBarTabImageViewDefaultOffset;
- (UIEdgeInsets)cyl_tabBarItemEdgeInsets;
- (void)cyl_tabBarSetItemEdgeInsets:(UIEdgeInsets)itemEdgeInsets;
- (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)cyl_tabBarPlusButton;
- (void)cyl_tabBarSetPlusButton:(nullable CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton;
- (NSUInteger)cyl_tabBarPlusButtonIndex;
- (void)cyl_tabBarReloadTabButtons;
- (BOOL)cyl_tabBarHasPlusButton;
- (BOOL)cyl_tabBarHasPlusChildViewController;
- (BOOL)cyl_tabBarIsPlusButtonLayoutCentered;
- (nullable CYLTabBarController *)cyl_tabBarOwningTabBarController;
@end

@implementation CYLTabBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self cyl_tabBarSharedInit];
        [self cyl_keepStackedItemLayoutOnHingedDevice];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self cyl_tabBarSharedInit];
        [self cyl_keepStackedItemLayoutOnHingedDevice];
    }
    return self;
}

- (void)dealloc {
    [self cyl_tabBarDealloc];
}

/*!
 * FIX: issue #680
 * [EN] Liquid Glass only. When the iPhone Duo is in landscape with a compact height (e.g. folded), UIKit switches the
 *      tab items to the compact inline layout: icon on the left, title on the right, 36 pt high. CYLTabBarController
 *      lays out Lottie icons, badges and the plus button for the stacked layout, so their centres no longer match.
 *      On a device with a hinge, this keeps the tab bar's vertical size class regular, so the items stay stacked
 *      (icon above title) as in portrait. The hinge is found with `UIHingeInteraction`, which only reports a hinge on
 *      foldable devices; every other device and the FlatDesign style are unchanged. Objective-C: it needs the iOS 27.1 SDK.
 * [CN] 仅液态玻璃样式。iPhone Duo 横屏且高度为 compact（如折叠时）时，UIKit 把 Tab 按钮切换为紧凑横排布局：
 *      图标在左、标题在右，高 36pt。CYLTabBarController 的 Lottie 图标、角标、加号按钮都按上下布局计算，中心点因此错位。
 *      在有铰链的设备上，把 TabBar 的垂直 size class 固定为 regular，按钮保持与竖屏一致的上下结构（图标在上、标题在下）。
 *      通过 `UIHingeInteraction` 判断是否有铰链（只有可折叠设备才会返回铰链），其他设备和扁平样式不受影响。保留为 Objective-C：需要 iOS 27.1 SDK。
 */
- (void)cyl_keepStackedItemLayoutOnHingedDevice {
#if defined(__IPHONE_27_1) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_27_1
    if (@available(iOS 27.1, *)) {
        if (![CYLConstants isLiquidGlassActive]) { return; }
        __weak __typeof(self) weakSelf = self;
        UIHingeInteraction *hingeInteraction = [[UIHingeInteraction alloc] initWithUpdateHandler:^(UIHingeInteraction *interaction, UIHingeInteractionUpdate *update) {
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self || !update.hinge) { return; }
            // Reading an unset override throws, so check `containsTrait:` first. Hinge angle updates can be frequent.
            if (![self.traitOverrides containsTrait:UITraitVerticalSizeClass.class]) {
                self.traitOverrides.verticalSizeClass = UIUserInterfaceSizeClassRegular;
            }
        }];
        [self addInteraction:hingeInteraction];
    }
#endif
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return NO;
}

#pragma mark - Overrides

- (CGSize)sizeThatFits:(CGSize)size {
    return [self cyl_tabBarSizeThatFits:[super sizeThatFits:size]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self cyl_tabBarLayoutSubviews];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    [self cyl_tabBarSyncTintColor:tintColor];
}

- (void)setUnselectedItemTintColor:(UIColor *)unselectedItemTintColor {
    UIColor *previous = self.unselectedItemTintColor;
    [super setUnselectedItemTintColor:unselectedItemTintColor];
    [self cyl_tabBarSyncUnselectedItemTintColor:unselectedItemTintColor previous:previous];
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    UIColor *previous = self.barTintColor;
    [super setBarTintColor:barTintColor];
    [self cyl_tabBarSyncBarTintColor:barTintColor previous:previous];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    UIImage *previous = self.backgroundImage;
    [super setBackgroundImage:backgroundImage];
    [self cyl_tabBarSyncBackgroundImage:backgroundImage previous:previous];
}

- (void)setShadowImage:(UIImage *)shadowImage {
    UIImage *previous = self.shadowImage;
    [super setShadowImage:shadowImage];
    [self cyl_tabBarSyncShadowImage:shadowImage previous:previous];
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    UIBarStyle previous = self.barStyle;
    [super setBarStyle:barStyle];
    [self cyl_tabBarSyncBarStyle:barStyle previous:previous];
}

- (void)beginCustomizingItems:(NSArray<UITabBarItem *> *)items {
    [self cyl_tabBarWillBeginCustomizing];
    [super beginCustomizingItems:items];
    [self cyl_tabBarDidBeginCustomizing];
}

- (BOOL)endCustomizingAnimated:(BOOL)animated {
    BOOL changed = [super endCustomizingAnimated:animated];
    [self cyl_tabBarDidEndCustomizing];
    return changed;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return [self cyl_tabBarHitTest:point withEvent:event superHitTest:^UIView *(CGPoint superPoint) {
        return [super hitTest:superPoint withEvent:event];
    }];
}

- (void)addSubview:(UIView *)view {
    [self cyl_tabBarWillAddSubview:view];
    [super addSubview:view];
}

- (void)addInteraction:(id<UIInteraction>)interaction {
    if (![self cyl_tabBarAddScrollEdgeElementContainerInteraction:interaction]) {
        [super addInteraction:interaction];
    }
}

- (void)removeInteraction:(id<UIInteraction>)interaction {
    if (![self cyl_tabBarRemoveScrollEdgeElementContainerInteraction:interaction]) {
        [super removeInteraction:interaction];
    }
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    [self cyl_tabBarWillAddGestureRecognizer:gestureRecognizer];
    [super addGestureRecognizer:gestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return [self cyl_tabBarGestureRecognizerShouldBegin:gestureRecognizer];
}

#pragma mark - Public API

- (NSString *)context { return [self cyl_tabBarContext]; }
- (void)setContext:(NSString *)context { [self cyl_tabBarSetContext:context]; }
- (NSArray<UIControl *> *)tabBarButtonArray { return [self cyl_tabBarTabBarButtonArray]; }
- (void)setTabBarButtonArray:(NSArray<UIControl *> *)tabBarButtonArray { [self cyl_tabBarSetTabBarButtonArray:tabBarButtonArray]; }
- (CGFloat)tabBarItemWidth { return [self cyl_tabBarTabBarItemWidth]; }
- (void)setTabBarItemWidth:(CGFloat)tabBarItemWidth { [self cyl_tabBarSetTabBarItemWidth:tabBarItemWidth]; }
- (CGFloat)tabImageViewDefaultOffset { return [self cyl_tabBarTabImageViewDefaultOffset]; }
- (UIEdgeInsets)cyl_itemEdgeInsets { return [self cyl_tabBarItemEdgeInsets]; }
- (void)setCyl_itemEdgeInsets:(UIEdgeInsets)itemEdgeInsets { [self cyl_tabBarSetItemEdgeInsets:itemEdgeInsets]; }
- (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton { return [self cyl_tabBarPlusButton]; }
- (void)setPlusButton:(CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton { [self cyl_tabBarSetPlusButton:plusButton]; }
- (NSUInteger)plusButtonIndex { return [self cyl_tabBarPlusButtonIndex]; }
- (void)cyl_reloadTabButtons { [self cyl_tabBarReloadTabButtons]; }
- (BOOL)hasPlusButton { return [self cyl_tabBarHasPlusButton]; }
- (BOOL)hasPlusChildViewController { return [self cyl_tabBarHasPlusChildViewController]; }
- (BOOL)isPlusButtonLayoutCentered { return [self cyl_tabBarIsPlusButtonLayoutCentered]; }
- (CYLTabBarController *)tabBarController { return [self cyl_tabBarOwningTabBarController]; }

@end
