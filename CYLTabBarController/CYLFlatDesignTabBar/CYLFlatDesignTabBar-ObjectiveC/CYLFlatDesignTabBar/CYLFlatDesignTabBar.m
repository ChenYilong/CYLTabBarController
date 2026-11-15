//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The Objective-C shell of `CYLFlatDesignTabBar` (docs/Swift-Migration.md, step 50): the implementation is Swift
//      (`Swift/CYLFlatDesignTabBar+CYLImplementation.swift`). The class stays declared in Objective-C because
//      `CYLTabBarController.h` adopts `CYLFlatDesignTabBarDelegate`, which its interface names; this file keeps the
//      overrides and the public accessors, each a one-line forward to a `cyl_flatDesign…` method of the Swift extension.
// [CN] `CYLFlatDesignTabBar` 的 Objective-C 外壳（docs/Swift-Migration.md，第 50 步）：实现位于 Swift
//      （`Swift/CYLFlatDesignTabBar+CYLImplementation.swift`）。类仍在 Objective-C 中声明，因为 `CYLTabBarController.h` 遵守其接口引用的
//      `CYLFlatDesignTabBarDelegate`；本文件保留重写方法与公开存取方法，每个都是一行转发到 Swift 扩展的 `cyl_flatDesign…` 方法。

#import "CYLFlatDesignTabBar.h"
#import "CYLFlatDesignTabBarItem.h"

// [EN] Declared in CYLFlatDesignTabBarItem.h; the item is Swift (step 49), so the C constant is defined here.
// [CN] 在 CYLFlatDesignTabBarItem.h 中声明；item 已是 Swift（第 49 步），因此 C 常量定义在这里。
NSString *const CYLFlatDesignTabBarItemDidChange = @"CYLFlatDesignTabBarItemDidChange";

/*!
 * [EN] Implemented in Swift/CYLFlatDesignTabBar+CYLImplementation.swift.
 * [CN] 在 Swift/CYLFlatDesignTabBar+CYLImplementation.swift 中实现。
 */
@interface CYLFlatDesignTabBar (CYLFlatDesignTabBarImplementation)
- (void)cyl_flatDesignCommonInit;
- (CGSize)cyl_flatDesignSizeThatFits:(CGSize)sizeThatFits;
- (void)cyl_flatDesignLayoutSubviews;
- (nullable UIView *)cyl_flatDesignHitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;
- (CYLFlatDesignTabBarItem *)cyl_flatDesignAddItemWithTitle:(nullable NSString *)title
                                            tabBarItemImage:(nullable id)tabBarItemImage
                                    tabBarItemSelectedImage:(nullable id)tabBarItemSelectedImage
                                                      index:(NSInteger)index
                                    titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                                imageInsets:(UIEdgeInsets)imageInsets
                                             lottieFilePath:(nullable NSString *)lottieFilePath
                                            lottieSizeValue:(nullable NSValue *)lottieSizeValue;
- (NSArray<CYLFlatDesignTabBarButton *> *)cyl_flatDesignTabBarButtons;
- (nullable id<CYLFlatDesignTabBarDelegate>)cyl_flatDesignDelegate;
- (void)cyl_flatDesignSetDelegate:(nullable id<CYLFlatDesignTabBarDelegate>)delegate;
- (nullable NSArray<CYLFlatDesignTabBarItem *> *)cyl_flatDesignItems;
- (void)cyl_flatDesignSetItems:(nullable NSArray<CYLFlatDesignTabBarItem *> *)items;
- (nullable CYLFlatDesignTabBarItem *)cyl_flatDesignSelectedItem;
- (void)cyl_flatDesignSetSelectedItem:(nullable CYLFlatDesignTabBarItem *)selectedItem;
- (NSUInteger)cyl_flatDesignSelectedIndex;
- (void)cyl_flatDesignSetSelectedIndex:(NSUInteger)selectedIndex;
- (nullable UITabBarAppearance *)cyl_flatDesignStandardAppearance;
- (void)cyl_flatDesignSetStandardAppearance:(nullable UITabBarAppearance *)standardAppearance;
- (nullable UIColor *)cyl_flatDesignTintColor;
- (void)cyl_flatDesignSetTintColor:(nullable UIColor *)tintColor;
- (nullable UIColor *)cyl_flatDesignBarTintColor;
- (void)cyl_flatDesignSetBarTintColor:(nullable UIColor *)barTintColor;
- (nullable UIImage *)cyl_flatDesignBackgroundImage;
- (void)cyl_flatDesignSetBackgroundImage:(nullable UIImage *)backgroundImage;
- (nullable UIImage *)cyl_flatDesignShadowImage;
- (void)cyl_flatDesignSetShadowImage:(nullable UIImage *)shadowImage;
- (BOOL)cyl_flatDesignUseLayoutSafeAreaInsets;
- (void)cyl_flatDesignSetUseLayoutSafeAreaInsets:(BOOL)useLayoutSafeAreaInsets;
- (BOOL)cyl_flatDesignRespectsVerticalStatusBarSafeArea;
- (void)cyl_flatDesignSetRespectsVerticalStatusBarSafeArea:(BOOL)respectsVerticalStatusBarSafeArea;
- (nullable NSString *)cyl_flatDesignContext;
- (void)cyl_flatDesignSetContext:(nullable NSString *)context;
- (BOOL)cyl_flatDesignHasPlusButton;
- (BOOL)cyl_flatDesignHasPlusChildViewController;
@end

@implementation CYLFlatDesignTabBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self cyl_flatDesignCommonInit];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self cyl_flatDesignSizeThatFits:[super sizeThatFits:size]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self cyl_flatDesignLayoutSubviews];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    // [CN] FIX: issue #662 iPhone Duo 折叠/展开、横竖屏切换时安全区会变化（如右侧 84pt 的竖向状态栏），需重新排列按钮
    // [EN] FIX: issue #662 The safe area changes when an iPhone Duo folds/unfolds or rotates (e.g. the 84pt vertical status
    //      bar on the right), so the buttons need to be laid out again.
    [self setNeedsLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    // [CN] RTL（如阿语）切换布局方向后需重新排列按钮
    // [EN] After switching the layout direction for RTL (e.g. Arabic), the buttons need to be laid out again.
    if (previousTraitCollection.layoutDirection != self.traitCollection.layoutDirection) {
        [self setNeedsLayout];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return [self cyl_flatDesignHitTest:point withEvent:event];
}

#pragma mark - Public API

- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue {
    return [self cyl_flatDesignAddItemWithTitle:title tabBarItemImage:tabBarItemImage tabBarItemSelectedImage:tabBarItemSelectedImage
                                          index:index titlePositionAdjustment:titlePositionAdjustment imageInsets:imageInsets
                                 lottieFilePath:lottieFilePath lottieSizeValue:lottieSizeValue];
}

- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarButtons { return [self cyl_flatDesignTabBarButtons]; }
- (id<CYLFlatDesignTabBarDelegate>)delegate { return [self cyl_flatDesignDelegate]; }
- (void)setDelegate:(id<CYLFlatDesignTabBarDelegate>)delegate { [self cyl_flatDesignSetDelegate:delegate]; }
- (NSArray<CYLFlatDesignTabBarItem *> *)items { return [self cyl_flatDesignItems]; }
- (void)setItems:(NSArray<CYLFlatDesignTabBarItem *> *)items { [self cyl_flatDesignSetItems:items]; }
/*!
 * [EN] Same as `tabBarButtons`, for compatibility with CYLTabBar; setting it sets `items`.
 * [CN] 与 `tabBarButtons` 相同，用于兼容 CYLTabBar；设置时设置 `items`。
 */
- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarItems { return [self cyl_flatDesignTabBarButtons]; }
- (void)setTabBarItems:(NSArray *)tabBarItems { [self cyl_flatDesignSetItems:tabBarItems]; }
- (CYLFlatDesignTabBarItem *)selectedItem { return [self cyl_flatDesignSelectedItem]; }
- (void)setSelectedItem:(CYLFlatDesignTabBarItem *)selectedItem { [self cyl_flatDesignSetSelectedItem:selectedItem]; }
- (NSUInteger)selectedIndex { return [self cyl_flatDesignSelectedIndex]; }
- (void)setSelectedIndex:(NSUInteger)selectedIndex { [self cyl_flatDesignSetSelectedIndex:selectedIndex]; }
- (UITabBarAppearance *)standardAppearance { return [self cyl_flatDesignStandardAppearance]; }
- (void)setStandardAppearance:(UITabBarAppearance *)standardAppearance { [self cyl_flatDesignSetStandardAppearance:standardAppearance]; }
- (UIColor *)tintColor { return [self cyl_flatDesignTintColor]; }
- (void)setTintColor:(UIColor *)tintColor { [self cyl_flatDesignSetTintColor:tintColor]; }
- (UIColor *)barTintColor { return [self cyl_flatDesignBarTintColor]; }
- (void)setBarTintColor:(UIColor *)barTintColor { [self cyl_flatDesignSetBarTintColor:barTintColor]; }
- (UIImage *)backgroundImage { return [self cyl_flatDesignBackgroundImage]; }
- (void)setBackgroundImage:(UIImage *)backgroundImage { [self cyl_flatDesignSetBackgroundImage:backgroundImage]; }
- (UIImage *)shadowImage { return [self cyl_flatDesignShadowImage]; }
- (void)setShadowImage:(UIImage *)shadowImage { [self cyl_flatDesignSetShadowImage:shadowImage]; }
- (BOOL)useLayoutSafeAreaInsets { return [self cyl_flatDesignUseLayoutSafeAreaInsets]; }
- (void)setUseLayoutSafeAreaInsets:(BOOL)useLayoutSafeAreaInsets { [self cyl_flatDesignSetUseLayoutSafeAreaInsets:useLayoutSafeAreaInsets]; }
- (BOOL)respectsVerticalStatusBarSafeArea { return [self cyl_flatDesignRespectsVerticalStatusBarSafeArea]; }
- (void)setRespectsVerticalStatusBarSafeArea:(BOOL)respects { [self cyl_flatDesignSetRespectsVerticalStatusBarSafeArea:respects]; }
- (NSString *)context { return [self cyl_flatDesignContext]; }
- (void)setContext:(NSString *)context { [self cyl_flatDesignSetContext:context]; }
- (BOOL)hasPlusButton { return [self cyl_flatDesignHasPlusButton]; }
- (BOOL)hasPlusChildViewController { return [self cyl_flatDesignHasPlusChildViewController]; }

@end
