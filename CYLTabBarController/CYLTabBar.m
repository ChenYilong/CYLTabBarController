//
//  CYLTabBar.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBar.h"
#import "CYLTabBarController.h"
#import "CYLConstants.h"
#import "CYLTabBarController+CYLPrivate.h"
#import <objc/runtime.h>
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"

static void *const CYLTabBarContext = (void*)&CYLTabBarContext;
static void *const CYLTabBarAlpha = (void*)&CYLTabBarAlpha;
static void *const CYLTabBarItemTitleContext = (void*)&CYLTabBarItemTitleContext;
/// [EN] KVO context of the items' `badgeValue` (badge-changed animations). [CN] item 的 `badgeValue` 的 KVO context（角标变化动画）。
static void *const CYLTabBarItemBadgeValueContext = (void*)&CYLTabBarItemBadgeValueContext;


// Implemented in CYLTabBarController.m, issue #610 (and #22 for the pending blocks).
@interface CYLTabBarController (CYLTabControlActions)
- (void)cyl_bindTabControlActions;
- (void)cyl_runPendingReloadBadgesBlocksIfReady;
// [EN] Implemented in CYLTabBarController+CYLInteraction.m: a tab item's `badgeValue` changed.
// [CN] 在 CYLTabBarController+CYLInteraction.m 中实现：某个 Tab item 的 `badgeValue` 发生了变化。
- (void)cyl_tabBarItemBadgeValueDidChange:(UITabBarItem *)item;
// [EN] Implemented in CYLTabBarController.m: the plus button in the Liquid Glass layers, idempotent.
// [CN] 在 CYLTabBarController.m 中实现：液态玻璃图层中的 PlusButton，可重复调用。
- (void)cyl_layOutPlusButtonInLiquidGlassLayers;
@end

/// [EN] Key of the `hidden` value a view inserted by the library had before More editing hid it.
/// [CN] 「More」编辑隐藏本库插入的视图之前，该视图原来的 `hidden` 值的 key。
static const void *const CYLHiddenBeforeCustomizingKey = &CYLHiddenBeforeCustomizingKey;

// [EN] FIX: issue #152 / #535 — implemented in CYLTabBarController+CYLInteraction.m.
// [CN] FIX: issue #152 / #535 — 实现位于 CYLTabBarController+CYLInteraction.m。
@interface CYLTabBarController (CYLLiquidGlassTabGestures)
- (void)cyl_liquidGlassTabBarGestureRecognizerDidUpdate:(UIGestureRecognizer *)gestureRecognizer;
@end

@interface CYLTabBar () <UIGestureRecognizerDelegate>

/// [EN] YES between `-beginCustomizingItems:` and `-endCustomizingAnimated:` (More editing). Unlike `isCustomizing`, it is
///      already NO while UIKit animates the end of editing, so the layout requested then installs the views again.
/// [CN] 在 `-beginCustomizingItems:` 与 `-endCustomizingAnimated:` 之间为 YES（「More」编辑）。与 `isCustomizing` 不同，UIKit 播放结束
///      编辑的动画时它已是 NO，因此此时请求的布局会重新安装这些视图。
@property (nonatomic, assign) BOOL cyl_isCustomizingItems;

@property (nonatomic, strong) NSMutableSet<UIView *> *observedViews;
/// Whether the last layout found the tab buttons in the iOS 27.1 vertical bar, see `-cyl_refreshTabButtonsAfterVerticalBar`.
@property (nonatomic, assign) BOOL cyl_wasShowingVerticalBar;
/// The items whose `title` is observed, see `-cyl_observeItemTitles`.
@property (nonatomic, copy, nullable) NSArray<UITabBarItem *> *cyl_titleObservedItems;
/// Whether `-cyl_reloadTabButtons` has a reload scheduled.
@property (nonatomic, assign) BOOL cyl_isTabButtonsReloadPending;
/// Whether the scheduled reload also sets the items' titles again (after the vertical bar).
@property (nonatomic, assign) BOOL cyl_reloadSetsItemTitles;
/// While the reload sets the items' titles again: their `title` changes are not reloads to schedule.
@property (nonatomic, assign) BOOL cyl_isSettingItemTitles;
/// Receives the `UIScrollEdgeElementContainerInteraction`s added to the tab bar, see `-addInteraction:`.
@property (nonatomic, strong, nullable) UIView *cyl_scrollEdgeElementContainerView;
/// [EN] The x of the first slot and the gap between slots of the last layout with a plus button (0 unless centered).
/// [CN] 上次带 PlusButton 布局时第一个位置的 x 与位置间距（未居中时均为 0）。
@property (nonatomic, assign) CGFloat cyl_itemLayoutLeading;
@property (nonatomic, assign) CGFloat cyl_itemLayoutSpacing;
/// FIX: issue #488. The token of the block-based Lottie observer: `-removeObserver:self` cannot remove it.
@property (nonatomic, strong, nullable) id<NSObject> cyl_lottieAnimationPlayingObserver;
/// [EN] While the library sets a classic style for itself: not synced to the appearances. [CN] 本库自己设置经典样式期间：不同步到 appearance。
@property (nonatomic, assign) BOOL cyl_isSettingClassicStyleInternally;

@end

/// [CN] See `cyl_appliesCenterYOffsetWithoutTitle` in CYLPlusButton.h. 见 CYLPlusButton.h 中的 `cyl_appliesCenterYOffsetWithoutTitle`。
/// [EN] See `cyl_appliesCenterYOffsetWithoutTitle` in CYLPlusButton.h.
@interface CYLPlusButton (CYLTabBarLayout)
- (BOOL)cyl_isCenteredWithoutTitle;
- (CGPoint)cyl_alignedCenterForCenter:(CGPoint)center;
@end

/// [EN] Implemented in CYLTabBarController.m. [CN] 实现于 CYLTabBarController.m。
@interface CYLTabBarController (CYLOpaqueTabBarSafeAreaFix)
- (void)cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded;
@end

@implementation CYLTabBar
@synthesize plusButton = _plusButton;

#pragma mark -
#pragma mark - LifeCycle Method

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self = [self sharedInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self = [self sharedInit];
    }
    return self;
}

- (NSString *)context {
    return self.cyl_context;
}

- (void)setContext:(NSString *)context {
    self.cyl_context = context;
    [self setPlusButton:[CYLPlusButton plusButtonForOwner:self]];
}

- (instancetype)sharedInit {
    _syncsClassicStylesToAppearance = YES;
    // [CN] KVO注册监听
    // [EN] Register KVO observers
    _tabBarItemWidth = self.cyl_tabBarItemWidth;
    [self addObserver:self forKeyPath:@"tabBarItemWidth" options:NSKeyValueObservingOptionNew context:CYLTabBarContext];
    // Only with an animation library (#604, checked at runtime so that any library works): without one there is no
    // animation view to stop (#488). 仅在引入动画库时监听（#604，运行时判断，以支持任意动画库）：没有时没有需要停止的动画（#488）。
    if (CYLTabBarItemAnimationIsAvailable()) {
        __weak __typeof(self) weakSelf = self;
        void (^CYLTabBarItemAnimationPlayingNotificationBlock)(NSNotification *) = ^(NSNotification *notification) {
            __strong typeof(self) self = weakSelf;
            if (!self) {
                 return;
            }
            // Library-neutral (#604): every animation library (Lottie, PAG), from the `CYLTabBarItemAnimation` subspec.
            // 与动画库无关：所有动画库（Lottie、PAG），由 `CYLTabBarItemAnimation` 子库处理。
            if (CYLTabBarItemAnimationIsAvailable()) {
                [self cyl_stopAllTabBarItemAnimations];
            }
        };
        // FIX: issue #488 keep the token and remove it in `-dealloc`; it was dropped, so every tab bar (one per tab bar
        // controller, e.g. each time `window.rootViewController` is replaced) left an observer behind for good.
        // 保存 token 并在 `-dealloc` 中移除；以前直接丢弃，每个 TabBar（每次替换 `window.rootViewController` 都会新建）都会永久留下一个观察者。
        self.cyl_lottieAnimationPlayingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemAnimationPlayingNotification
                                                                                                    object:nil
                                                                                                     queue:[NSOperationQueue mainQueue]
                                                                                                usingBlock:CYLTabBarItemAnimationPlayingNotificationBlock];
    }
    [self cyl_keepStackedItemLayoutOnHingedDevice];
    return self;
}

#pragma mark - Stacked item layout on hinged devices (iOS 27.1+, iPhone Duo)
// MARK: Stacked item layout

/*!
 * FIX: issue #680
 * [EN] Liquid Glass only. When the iPhone Duo is in landscape with a compact height (e.g. folded), UIKit switches the
 *      tab items to the compact inline layout: icon on the left, title on the right, 36 pt high. CYLTabBarController
 *      lays out Lottie icons, badges and the plus button for the stacked layout, so their centres no longer match.
 *      On a device with a hinge, this keeps the tab bar's vertical size class regular, so the items stay stacked
 *      (icon above title) as in portrait. The hinge is found with `UIHingeInteraction`, which only reports a hinge on
 *      foldable devices; every other device and the FlatDesign style are unchanged.
 * [CN] 仅液态玻璃样式。iPhone Duo 横屏且高度为 compact（如折叠时）时，UIKit 把 Tab 按钮切换为紧凑横排布局：
 *      图标在左、标题在右，高 36pt。CYLTabBarController 的 Lottie 图标、角标、加号按钮都按上下布局计算，中心点因此错位。
 *      在有铰链的设备上，把 TabBar 的垂直 size class 固定为 regular，按钮保持与竖屏一致的上下结构（图标在上、标题在下）。
 *      通过 `UIHingeInteraction` 判断是否有铰链（只有可折叠设备才会返回铰链），其他设备和扁平样式不受影响。
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

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    if ([CYLConstants isLiquidGlassActive]) {
        //如果不是扁平设计风格，也就是液态玻璃不支持自定义高度， 液态玻璃系统样式是固定高度的。// Unless it's a flat design style—in which case Liquid Glass does not support custom heights—the Liquid Glass system style has a fixed height.
        return sizeThatFits;
    }

    CGFloat height = [self cyl_tabBarController].tabBarHeight + [self cyl_tabBarController].view.safeAreaInsets.bottom;
    if (height > 0) {
        sizeThatFits.height = height;
    }
    return sizeThatFits;
}

/**
 *  lazy load tabBarButtonArray
 *
 *  @return NSArray
 */
- (NSArray<UIControl *> *)tabBarButtonArray {
    if (_tabBarButtonArray == nil) {
        _tabBarButtonArray = @[];
    }
    return _tabBarButtonArray;
}

- (NSString *)matchedTabBarContext {
    // The context of the plus button registered for THIS tab bar's context (nil if there is none).
    NSString *matchedTabBarContext = [[[CYLPlusButton plusButtonForOwner:self] class] matchedTabBarContext];
    return matchedTabBarContext;
}

/*!
 * [EN] The plus button and its child view controller are bound to the CYLTabBarController (by its `context`), not to
 *      this tab bar. The tab bar finds them through the controller that owns it (`+[CYLPlusButton plusButtonForOwner:]`
 *      asks the tab bar's `delegate`), so it always agrees with `-[CYLTabBarController hasPlusButton]`, also when
 *      several plus buttons are registered (#414). Before the controller is set, its own `context` is used, which the
 *      controller copies to it.
 * [CN] PlusButton 及其子控制器绑定的是 CYLTabBarController（通过它的 `context`），而不是这个 TabBar。TabBar 通过拥有它的控制器
 *      找到它们（`+[CYLPlusButton plusButtonForOwner:]` 会询问 TabBar 的 `delegate`），因此始终与 `-[CYLTabBarController hasPlusButton]`
 *      一致，注册了多个时也是如此（#414）。控制器还没设置时，使用 TabBar 自己的 `context`，它是控制器复制过来的。
 */
- (BOOL)hasPlusButton {
    return [CYLPlusButton plusButtonForOwner:self] != nil;
}

- (BOOL)hasPlusChildViewController {
    return [CYLPlusButton plusChildViewControllerForOwner:self] != nil;
}

- (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton {
    if (![CYLPlusButton plusButtonForOwner:self] || !_plusButton) {
        return nil;
    }

    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    BOOL isSameContext = [self hasPlusButton];

    if (_plusButton  && addedToTabBar && isSameContext) {
        return _plusButton;
    }
    return nil;
}

- (void)setPlusButton:(CYLPlusButton<CYLPlusButtonSubclassing> *)plusButton {
    if (!plusButton) {
        return;
    }
    if (![self hasPlusButton]) {
        return;
    }
    _plusButton = plusButton;
    if (!self.isPlusButtonActive) {
        BOOL isFirstAdded = (_plusButton.superview == nil);
        BOOL isSameContext = [self hasPlusButton];
        if (_plusButton && isSameContext && isFirstAdded) {
            // [CN] TODO:  iOS26 考虑应该放进选中图层，而非粗暴放进最底层，这样未来可以 PlusButton 支持自定义index
            // [EN] TODO:  On iOS26, consider putting this into the selected layer instead of crudely putting it at the bottom,
            //      so that PlusButton can support a custom index in the future.
            [self cyl_addPlatterViewThenBringSubviewToFront:(UIButton *)_plusButton];
            self.plusButtonActive = YES;
            [_plusButton cyl_setTabBarController:[self cyl_tabBarController]];
        }
    }
}

- (void)presetUnselectedItemTintColor {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (self.unselectedItemTintColor) {
            return;
        }
        __block UIColor *tabLabelTextColor = nil;//for iOS13+
        tabLabelTextColor = [UIColor cyl_systemGrayColor];
        [self.tabBarButtonArray enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIControl *childView = obj;
            if (childView.selected) {
                return;
            }
            if (childView.cyl_tabEffectView && childView.cyl_tabLabel ) {
                tabLabelTextColor = childView.cyl_tabLabel.textColor;
            }
        }];
        
        if (@available(iOS 26.0, *)) {
            //fix #631
            [self.cyl_tabBarSubviews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj cyl_isTabLabel]) {
                        @try {
                            UILabel *label = (UILabel *)obj;
                            UIColor *color = label.textColor;
                            if (color && [color isKindOfClass:[UIColor class]]) {
                                tabLabelTextColor = label.textColor;
                                *stop = YES;
                                return;
                            }
                        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                            NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
                        }
                    }
                }];
            }];
        }
        // [EN] The color the items already show: not an app's style to sync. [CN] item 当前已显示的颜色：不是需要同步的 App 样式。
        self.cyl_isSettingClassicStyleInternally = YES;
        self.unselectedItemTintColor = tabLabelTextColor;
        self.cyl_isSettingClassicStyleInternally = NO;
    }
#endif
}

#pragma mark - Classic styles and UITabBarAppearance

/*!
 * [EN] Since iOS 13, once a tab bar uses `UITabBarAppearance` (any `standardAppearance = ...`), UIKit ignores the classic
 *      styles (`tintColor`, `barTintColor`, `unselectedItemTintColor`, `backgroundImage`, `shadowImage`, `barStyle`).
 *      Each classic setter therefore also writes its value into `standardAppearance` (and `scrollEdgeAppearance` when
 *      there is one), so both ways of styling keep working together. Only a value that changed is written. Not with
 *      Liquid Glass, where the system draws the bar, nor while `syncsClassicStylesToAppearance` is NO.
 * [CN] iOS 13 起，TabBar 一旦使用 `UITabBarAppearance`（任何 `standardAppearance = ...`），UIKit 就会忽略经典样式（`tintColor`、
 *      `barTintColor`、`unselectedItemTintColor`、`backgroundImage`、`shadowImage`、`barStyle`）。因此每个经典 setter 同时把值写入
 *      `standardAppearance`（存在 `scrollEdgeAppearance` 时也写入），两种设置方式可以同时使用。只写入发生变化的值。液态玻璃（由系统
 *      绘制 TabBar）以及 `syncsClassicStylesToAppearance` 为 NO 时不同步。
 */
- (BOOL)cyl_shouldSyncClassicStyle {
    if (@available(iOS 13.0, *)) {
        return self.syncsClassicStylesToAppearance && !self.cyl_isSettingClassicStyleInternally && ![CYLUtils isLiquidGlassActive];
    }
    return NO;
}

- (void)cyl_syncClassicStyleWithBarBlock:(nullable void (^)(UITabBarAppearance *appearance))barBlock
                               itemBlock:(nullable void (^)(UITabBarItemAppearance *itemAppearance))itemBlock API_AVAILABLE(ios(13.0)) {
    void (^apply)(UITabBarAppearance *) = ^(UITabBarAppearance *appearance) {
        if (barBlock) {
            barBlock(appearance);
        }
        if (itemBlock) {
            [appearance cyl_applyItemAppearanceWithBlock:itemBlock];
        }
    };
    UITabBarAppearance *standardAppearance = [self.standardAppearance copy];
    apply(standardAppearance);
    self.standardAppearance = standardAppearance;
    if (@available(iOS 15.0, *)) {
        if (self.scrollEdgeAppearance) {
            UITabBarAppearance *scrollEdgeAppearance = [self.scrollEdgeAppearance copy];
            apply(scrollEdgeAppearance);
            self.scrollEdgeAppearance = scrollEdgeAppearance;
        }
    }
}

/// [EN] `attributes` with the foreground color replaced (removed for nil). [CN] 替换（为 nil 时移除）前景色后的 `attributes`。
static NSDictionary<NSAttributedStringKey, id> *CYLTitleAttributesWithColor(NSDictionary<NSAttributedStringKey, id> *attributes, UIColor *_Nullable color) {
    NSMutableDictionary<NSAttributedStringKey, id> *result = [attributes mutableCopy] ?: [NSMutableDictionary dictionary];
    result[NSForegroundColorAttributeName] = color;
    return [result copy];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    if (!tintColor || ![self cyl_shouldSyncClassicStyle]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self cyl_syncClassicStyleWithBarBlock:nil itemBlock:^(UITabBarItemAppearance *itemAppearance) {
            itemAppearance.selected.iconColor = tintColor;
            itemAppearance.selected.titleTextAttributes = CYLTitleAttributesWithColor(itemAppearance.selected.titleTextAttributes, tintColor);
        }];
    }
}

- (void)setUnselectedItemTintColor:(UIColor *)unselectedItemTintColor {
    BOOL changed = !(unselectedItemTintColor == self.unselectedItemTintColor || [unselectedItemTintColor isEqual:self.unselectedItemTintColor]);
    [super setUnselectedItemTintColor:unselectedItemTintColor];
    if (!changed || ![self cyl_shouldSyncClassicStyle]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self cyl_syncClassicStyleWithBarBlock:nil itemBlock:^(UITabBarItemAppearance *itemAppearance) {
            itemAppearance.normal.iconColor = unselectedItemTintColor;
            itemAppearance.normal.titleTextAttributes = CYLTitleAttributesWithColor(itemAppearance.normal.titleTextAttributes, unselectedItemTintColor);
        }];
    }
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    BOOL changed = !(barTintColor == self.barTintColor || [barTintColor isEqual:self.barTintColor]);
    [super setBarTintColor:barTintColor];
    if (!changed || ![self cyl_shouldSyncClassicStyle]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self cyl_syncClassicStyleWithBarBlock:^(UITabBarAppearance *appearance) {
            appearance.backgroundColor = barTintColor;
        } itemBlock:nil];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    BOOL changed = (backgroundImage != self.backgroundImage);
    [super setBackgroundImage:backgroundImage];
    if (!changed || ![self cyl_shouldSyncClassicStyle]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self cyl_syncClassicStyleWithBarBlock:^(UITabBarAppearance *appearance) {
            appearance.backgroundImage = backgroundImage;
        } itemBlock:nil];
    }
}

- (void)setShadowImage:(UIImage *)shadowImage {
    BOOL changed = (shadowImage != self.shadowImage);
    [super setShadowImage:shadowImage];
    if (!changed || ![self cyl_shouldSyncClassicStyle]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self cyl_syncClassicStyleWithBarBlock:^(UITabBarAppearance *appearance) {
            appearance.shadowImage = shadowImage;
        } itemBlock:nil];
    }
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    BOOL changed = (barStyle != self.barStyle);
    [super setBarStyle:barStyle];
    if (!changed || ![self cyl_shouldSyncClassicStyle]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        [self cyl_syncClassicStyleWithBarBlock:^(UITabBarAppearance *appearance) {
            appearance.backgroundEffect = [UIBlurEffect effectWithStyle:(barStyle == UIBarStyleDefault) ? UIBlurEffectStyleSystemChromeMaterialLight : UIBlurEffectStyleSystemChromeMaterialDark];
        } itemBlock:nil];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self cyl_layoutTabBarSubviews];
    BOOL showsVerticalBar = [self cyl_verticalBarTabButtonAtIndex:0] != nil;
    if (self.cyl_wasShowingVerticalBar && !showsVerticalBar) {
        [self cyl_refreshTabButtonsAfterVerticalBar];
    }
    self.cyl_wasShowingVerticalBar = showsVerticalBar;
    [self cyl_observeItemTitles];
    // FIX: issue #610 — UIKit replaces the tab buttons when an item's image changes and lays out only the tab bar,
    // so bind the tap action here as well, not only in the controller's -viewDidLayoutSubviews. Done after the layout
    // above, which sets each new button's visible index (used to recognise the plus child view controller's button).
    // 修改 item 图片后 UIKit 会重建 Tab 按钮且只重新布局 TabBar，所以这里也要为新按钮添加点击事件。放在上面的布局之后，
    // 因为布局时才会设置新按钮的 visible index（用于识别加号子控制器对应的按钮）。
    [self.tabBarController cyl_bindTabControlActions];
    // FIX: issue #22
    // [EN] UIKit fills `items` during this layout, after the controller's `-viewDidLayoutSubviews`: run the blocks of
    //      `-performWhenTabBarItemsReady:` / `-reloadBadgesWithBlock:` now that they exist.
    // [CN] UIKit 在本次布局中（晚于控制器的 `-viewDidLayoutSubviews`）生成 `items`：此时执行
    //      `-performWhenTabBarItemsReady:` / `-reloadBadgesWithBlock:` 的 block。
    [self.tabBarController cyl_runPendingReloadBadgesBlocksIfReady];
    // The tab titles may have moved: lay the plus button out again so its title follows them
    // (`+alignsTitleWithTabBarItemTitles`).
    [[CYLPlusButton plusButtonForOwner:self] cyl_setNeedsTitleAlignment];
    [self cyl_fixTruncatedTabTitlesIfNeeded];
    [self cyl_runItemLayoutBlocks];
    // [EN] The bar is laid out again when it comes back after a pop: check the page's safe area under an opaque bar.
    // [CN] pop 返回后 TabBar 会重新布局：检查不透明 TabBar 下页面的安全区域。
    [self.tabBarController cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded];
    // [EN] The Liquid Glass selected layer can appear in a tab bar layout pass only: put the plus button's stand-in in it
    //      now rather than after a fixed delay. Idempotent; does nothing without Liquid Glass or a plus button.
    // [CN] 液态玻璃的选中层可能只在 TabBar 的布局中出现：此时就放入 PlusButton 的替身，而不是固定延迟之后。可重复调用；没有液态玻璃
    //      或 PlusButton 时不做任何事。
    // [EN] Only for the controller that owns this tab bar: `-tabBarController` can fall back to another controller.
    // [CN] 只针对拥有本 TabBar 的控制器：`-tabBarController` 可能回退到其他控制器。
    CYLTabBarController *owningTabBarController = self.tabBarController;
    if (owningTabBarController.cyl_tabBar == self) {
        [owningTabBarController cyl_layOutPlusButtonInLiquidGlassLayers];
        // [EN] A title changed in place lays out only the tab bar: update the tabs' accessibility labels here too.
        // [CN] 原地修改标题时只有 TabBar 重新布局：这里也更新 Tab 的无障碍 label。
        [owningTabBarController cyl_syncTabBarItemAccessibility];
    }
}

/*!
 * [EN] UIKit bug on iOS 13 and 14: a tab title styled through `UITabBarAppearance` with a font larger than the default
 *      (iOS 13), bold (iOS 13 and 14), or with a changed inline title color (iOS 14) keeps a too small width and is cut
 *      off ("Mi…"). After UIKit's
 *      layout, a title narrower than its text is widened to fit (at most the button's width) around the same center.
 *      Fixed by Apple in iOS 15; nothing is done there.
 * [CN] iOS 13、14 的 UIKit bug：通过 `UITabBarAppearance` 设置的 Tab 标题字号大于默认值（iOS 13）、为粗体（iOS 13、14），或修改了
 *      横向布局的标题颜色（iOS 14）时，宽度不足，被截断（“我…”）。在 UIKit 布局之后，宽度不足以显示文字的标题会以原中心加宽到合适宽度（不超过按钮宽度）。
 *      iOS 15 起系统已修复，不做处理。
 */
- (void)cyl_fixTruncatedTabTitlesIfNeeded {
    if (@available(iOS 15.0, *)) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        // [EN] Any title narrower than its text: on iOS 14 a changed inline title color cuts titles off too, not only bold.
        // [CN] 任何宽度不足以显示文字的标题：iOS 14 上修改横向布局的标题颜色同样会截断标题，不只是粗体。
        for (UIControl *tabButton in self.tabBarButtonArray) {
            UILabel *label = [tabButton cyl_tabLabel];
            if (!label || label.text.length == 0) {
                continue;
            }
            CGSize fittingSize = [label sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            if (fittingSize.width <= CGRectGetWidth(label.bounds) + 0.5) {
                continue;
            }
            CGPoint center = label.center;
            CGRect bounds = label.bounds;
            bounds.size.width = MIN(ceil(fittingSize.width), CGRectGetWidth(tabButton.bounds));
            label.bounds = bounds;
            label.center = center;
        }
    }
}

/// [EN] `-[UITabBarItem cyl_viewDidLayoutSubviewsBlock]` of every item, after the layout. [CN] 布局之后执行各 item 的 `cyl_viewDidLayoutSubviewsBlock`。
- (void)cyl_runItemLayoutBlocks {
    for (UITabBarItem *item in self.items) {
        void (^block)(UITabBarItem *, UIView *) = item.cyl_viewDidLayoutSubviewsBlock;
        UIView *view = block ? item.cyl_tabButton : nil;
        if (view) {
            block(item, view);
        }
    }
}

#pragma mark - More editing

/*!
 * [EN] More editing ("Edit" on the More page) lets the user drag items onto the tab bar, and UIKit moves and rebuilds the
 *      tab buttons. The views the library inserted into them (`-cyl_markAsInsertedForTabControl:`) and the plus button
 *      are hidden meanwhile, so none is left at a stale position, and they come back when editing ends; the next layout
 *      puts the plus button's stand-in in the new buttons. The library does not support More editing as such: this only
 *      keeps it from leaving views behind.
 * [CN] 「More」编辑（More 页面中的 "Edit"）允许用户把 item 拖到 TabBar 上，UIKit 会移动并重建 Tab 按钮。编辑期间隐藏本库插入其中的视图
 *      （`-cyl_markAsInsertedForTabControl:`）与 PlusButton，避免留在过时的位置；编辑结束后恢复，下一次布局会把 PlusButton 的替身放进
 *      新按钮。本库并不支持「More」编辑本身，这里只是避免它留下残留视图。
 */
- (void)beginCustomizingItems:(NSArray<UITabBarItem *> *)items {
    self.cyl_isCustomizingItems = YES;
    [self cyl_setInsertedViewsHiddenForCustomizing:YES];
    [super beginCustomizingItems:items];
}

- (BOOL)endCustomizingAnimated:(BOOL)animated {
    BOOL changed = [super endCustomizingAnimated:animated];
    self.cyl_isCustomizingItems = NO;
    [self cyl_setInsertedViewsHiddenForCustomizing:NO];
    [self setNeedsLayout];
    // [EN] Again after UIKit's end-of-editing pass, which can rebuild the buttons. [CN] UIKit 结束编辑的处理可能重建按钮，之后再布局一次。
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf setNeedsLayout];
    });
    return changed;
}

/// [EN] Hides (YES) or restores (NO) the plus button and every inserted view inside this tab bar, in one pass.
/// [CN] 一次性隐藏（YES）或恢复（NO）PlusButton 与本 TabBar 中所有被插入的视图。
- (void)cyl_setInsertedViewsHiddenForCustomizing:(BOOL)hidden {
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (UIView *view in [UIView cyl_insertedTabControlViews]) {
        if ([view isDescendantOfView:self]) {
            [views addObject:view];
        }
    }
    UIView *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if ([plusButton isDescendantOfView:self]) {
        [views addObject:plusButton];
    }
    for (UIView *view in views) {
        if (hidden) {
            if (!objc_getAssociatedObject(view, CYLHiddenBeforeCustomizingKey)) {
                objc_setAssociatedObject(view, CYLHiddenBeforeCustomizingKey, @(view.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            view.hidden = YES;
        } else {
            NSNumber *hiddenBefore = objc_getAssociatedObject(view, CYLHiddenBeforeCustomizingKey);
            if (hiddenBefore != nil) {
                view.hidden = hiddenBefore.boolValue;
                objc_setAssociatedObject(view, CYLHiddenBeforeCustomizingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}

#pragma mark - Item positioning (centered, item width, item spacing)

/*!
 * [EN] The classic tab bar lays its tab buttons out itself when there is a plus button, which used to fill the whole width
 *      and ignore `itemPositioning`, `itemWidth` and `itemSpacing`. They are read as UIKit reads them: the
 *      `standardAppearance` values (iOS 13+) when set, otherwise the tab bar's own properties.
 * [CN] 有 PlusButton 时，经典 TabBar 自行布局 Tab 按钮，以前总是铺满整个宽度，忽略了 `itemPositioning`、`itemWidth`、`itemSpacing`。
 *      这里按 UIKit 的方式读取：设置了 `standardAppearance` 中的值（iOS 13+）时使用它们，否则使用 TabBar 自身的属性。
 */
- (void)cyl_getItemPositioning:(UITabBarItemPositioning *)positioning itemWidth:(CGFloat *)itemWidth itemSpacing:(CGFloat *)itemSpacing {
    UITabBarItemPositioning resolvedPositioning = self.itemPositioning;
    CGFloat resolvedWidth = self.itemWidth;
    CGFloat resolvedSpacing = self.itemSpacing;
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = self.standardAppearance;
        if (appearance.stackedItemPositioning != UITabBarItemPositioningAutomatic) {
            resolvedPositioning = appearance.stackedItemPositioning;
        }
        if (appearance.stackedItemWidth > 0) {
            resolvedWidth = appearance.stackedItemWidth;
        }
        if (appearance.stackedItemSpacing > 0) {
            resolvedSpacing = appearance.stackedItemSpacing;
        }
    }
    // [EN] UIKit centers Automatic tabs in a regular horizontal size class (e.g. iPad): read it the same way, so a spacing
    //      alone keeps UIKit's centered layout there instead of filling with gaps.
    // [CN] UIKit 在 regular 水平尺寸类别（如 iPad）下把 Automatic 的 Tab 居中：这里按同样方式读取，因此只设置间距时，
    //      在那里仍保持 UIKit 的居中布局，而不是铺满加间隙。
    if (resolvedPositioning == UITabBarItemPositioningAutomatic &&
        self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        resolvedPositioning = UITabBarItemPositioningCentered;
    }
    *positioning = resolvedPositioning;
    *itemWidth = resolvedWidth;
    *itemSpacing = resolvedSpacing;
}

/*!
 * [EN] The horizontal layout of `count` tab buttons plus, when `plusWidth` > 0, one plus button slot: the x of the first
 *      slot (`leading`), the width of a tab slot and the gap between slots. Without centered positioning, an item width or
 *      an item spacing it is the previous layout: leading 0, no gap, the tabs sharing the width left by the plus button.
 *      Centered: the slots keep `itemWidth` (the shared width when 0) and `itemSpacing`, centered as a group; when they do
 *      not fit, the previous layout is used.
 * [CN] `count` 个 Tab 按钮（`plusWidth` > 0 时再加一个 PlusButton 位置）的横向布局：第一个位置的 x（`leading`）、Tab 位置的宽度、
 *      位置之间的间距。未设置居中、item 宽度或间距时与以前的布局相同：leading 为 0、无间距，各 Tab 平分 PlusButton 之外的宽度。
 *      居中时：各位置使用 `itemWidth`（为 0 时使用平分宽度）与 `itemSpacing`，整体居中；放不下时使用以前的布局。
 */
- (void)cyl_getItemLayoutForTabCount:(NSUInteger)count
                           plusWidth:(CGFloat)plusWidth
                             leading:(CGFloat *)leading
                           itemWidth:(CGFloat *)itemWidth
                             spacing:(CGFloat *)spacing {
    UIEdgeInsets edgeInsets = self.cyl_itemEdgeInsets;
    CGFloat availableWidth = MAX(0, self.cyl_boundsSize.width - edgeInsets.left - edgeInsets.right);
    CGFloat fillWidth = count > 0 ? (availableWidth - plusWidth) / count : 0;
    *leading = edgeInsets.left;
    *itemWidth = fillWidth;
    *spacing = 0;
    UITabBarItemPositioning positioning = UITabBarItemPositioningAutomatic;
    CGFloat customWidth = 0;
    CGFloat customSpacing = 0;
    [self cyl_getItemPositioning:&positioning itemWidth:&customWidth itemSpacing:&customSpacing];
    if (count == 0) {
        return;
    }
    NSUInteger slotCount = count + (plusWidth > 0 ? 1 : 0);
    BOOL centered = (positioning == UITabBarItemPositioningCentered) || customWidth > 0;
    if (!centered) {
        // [EN] A spacing alone fills the width with gaps between the slots; the tab bar shows through them, e.g. as
        //      separators between tabs that have a background color.
        // [CN] 只设置间距时，各位置铺满宽度且之间留有间隙；TabBar 的背景透过间隙显示，例如作为有背景色的 Tab 之间的分隔线。
        CGFloat gappedWidth = (availableWidth - plusWidth - customSpacing * (CGFloat)(slotCount - 1)) / count;
        if (customSpacing > 0 && gappedWidth > 0) {
            *itemWidth = gappedWidth;
            *spacing = customSpacing;
        }
        return;
    }
    CGFloat width = customWidth > 0 ? customWidth : fillWidth;
    CGFloat totalWidth = width * count + plusWidth + customSpacing * (CGFloat)(slotCount - 1);
    if (totalWidth > availableWidth + 0.5) {
        return;
    }
    *leading = edgeInsets.left + (availableWidth - totalWidth) * 0.5;
    *itemWidth = width;
    *spacing = customSpacing;
}

- (void)setCyl_itemEdgeInsets:(UIEdgeInsets)itemEdgeInsets {
    if (UIEdgeInsetsEqualToEdgeInsets(_cyl_itemEdgeInsets, itemEdgeInsets)) {
        return;
    }
    _cyl_itemEdgeInsets = itemEdgeInsets;
    [self setNeedsLayout];
}

/*!
 * [EN] Without a plus button UIKit lays the tab buttons out (and honors centered positioning itself). With
 *      `cyl_itemEdgeInsets` they are laid out here instead, between the insets, the same way as with a plus button.
 * [CN] 没有 PlusButton 时由 UIKit 布局 Tab 按钮（居中排列也由 UIKit 处理）。设置了 `cyl_itemEdgeInsets` 时改为在这里布局，
 *      排列在两端空白之间，与有 PlusButton 时的方式相同。
 */
- (void)cyl_layoutTabButtonsWithItemEdgeInsetsIfNeeded {
    UIEdgeInsets edgeInsets = self.cyl_itemEdgeInsets;
    UITabBarItemPositioning positioning = UITabBarItemPositioningAutomatic;
    CGFloat customWidth = 0;
    CGFloat customSpacing = 0;
    [self cyl_getItemPositioning:&positioning itemWidth:&customWidth itemSpacing:&customSpacing];
    // [EN] UIKit does not leave gaps between filled tabs, so a fill with spacing is laid out here too.
    // [CN] UIKit 铺满时不会在 Tab 之间留间隙，因此铺满加间距时同样在这里布局。
    BOOL fillsWithSpacing = customSpacing > 0 && customWidth == 0 && positioning != UITabBarItemPositioningCentered;
    if (((edgeInsets.left == 0 && edgeInsets.right == 0) && !fillsWithSpacing) || [CYLConstants isLiquidGlassActive]) {
        return;
    }
    NSArray<UIControl *> *tabButtons = self.tabBarButtonArray;
    CGFloat leading = 0, itemWidth = 0, spacing = 0;
    [self cyl_getItemLayoutForTabCount:tabButtons.count plusWidth:0 leading:&leading itemWidth:&itemWidth spacing:&spacing];
    [tabButtons enumerateObjectsUsingBlock:^(UIControl * _Nonnull tabButton, NSUInteger index, BOOL * _Nonnull stop) {
        [self changeXForChildView:tabButton
                       childViewX:leading + index * (itemWidth + spacing)
                  tabBarItemWidth:itemWidth
                            index:index];
    }];
}

- (void)cyl_layoutTabBarSubviews {
    self.tabBarButtonArray = [self cyl_originalTabBarButtons];
    
    [self presetUnselectedItemTintColor];
    if (self.tabBarButtonArray && self.tabBarButtonArray.count > 0) {
        [self setupTabImageViewDefaultOffset:self.tabBarButtonArray[0]];
    }
    
    // [CN] FIX: iOS15有时候会导致TaBar透明的问题 但是这样会导致无法主动让TabBar透明 考虑以后添加属性 // 现在通过判断isHidden来处理，如果隐藏了就不再修改alpha
    // [EN] FIX: On iOS15 this sometimes makes the TaBar transparent, but it then prevents making the TabBar transparent
    //      on purpose; consider adding a property later // Now handled by checking isHidden: if hidden, alpha is no
    //      longer modified
    if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.0") && ![CYLConstants isLiquidGlassActive]) {
        [self removeAlphaObserver];
        UIView *backgroundView = self.cyl_tabBackgroundView;
        UIView *shadowView = self.cyl_tabShadowImageView.subviews.firstObject;
        
        if (shadowView && ![self.observedViews containsObject:shadowView]) {
            [self.observedViews addObject:shadowView];
            [shadowView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:CYLTabBarAlpha];
        }
        if ([UITabBar appearance].backgroundImage) {
            UIView *imageView = backgroundView.cyl_imageView;
            if (imageView && ![self.observedViews containsObject:imageView]) {
                [self.observedViews addObject:imageView];
                [imageView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:CYLTabBarAlpha];
            }
        } else {
            UIView *effectView = backgroundView.cyl_tabEffectView;
            if (effectView && ![self.observedViews containsObject:effectView]) {
                [self.observedViews addObject:effectView];
                [effectView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:CYLTabBarAlpha];
            }
        }
    }
    if (!self.plusButtonActive) {
        [self cyl_layoutTabButtonsWithItemEdgeInsetsIfNeeded];
        if (self.didLayoutSubViewsBlock) {
            self.didLayoutSubViewsBlock(self);
        }
        return;
    }
    
    BOOL addedToTabBar = [_plusButton.superview isEqual:self];
    if (!addedToTabBar && self.hasPlusButton) {
        CGFloat leading = 0, itemWidth = 0, spacing = 0;
        [self cyl_getItemLayoutForTabCount:self.cyl_tabbarItemsCount plusWidth:0 leading:&leading itemWidth:&itemWidth spacing:&spacing];
        [self cyl_setTabBarItemWidth:itemWidth];
        [self.tabBarButtonArray enumerateObjectsUsingBlock:^(UIControl * _Nonnull childView, NSUInteger buttonIndex, BOOL * _Nonnull stop) {
            // [CN] 仅修改childView的x和宽度,yh值不变
            // [EN] Only change childView's x and width; the y and height values stay the same
            CGFloat childViewX = leading + buttonIndex * (self.cyl_tabBarItemWidth + spacing);
            [self changeXForChildView:childView
                           childViewX:childViewX
                      tabBarItemWidth:self.cyl_tabBarItemWidth
                                index:buttonIndex
            ];
        }];
        if (self.didLayoutSubViewsBlock) {
            self.didLayoutSubViewsBlock(self);
        }
        return;
    }
    CGFloat itemLeading = 0, layoutItemWidth = 0, itemSpacing = 0;
    [self cyl_getItemLayoutForTabCount:self.cyl_tabbarItemsCount plusWidth:self.cyl_plusButtonWidth
                               leading:&itemLeading itemWidth:&layoutItemWidth spacing:&itemSpacing];
    self.cyl_itemLayoutLeading = itemLeading;
    self.cyl_itemLayoutSpacing = itemSpacing;
    [self cyl_setTabBarItemWidth:layoutItemWidth];
   // [CN] plusButtonIndex内部调整 PlusButton 的中心坐标，不能直接修改 center，否则会造成点击动画时的闪动bug，需要借助坐标系转换。
   // [EN] plusButtonIndex adjusts the PlusButton's center internally. Do not modify center directly, otherwise the
   //      button flickers during the tap animation; use a coordinate-space conversion instead.
    NSUInteger plusButtonIndex = [self plusButtonIndex];
    // [EN] FIX: placeholder count mismatch — whether the plus button's slot is one of the tab buttons, read from
    //      `viewControllers`, not from `cyl_hasPlusChildViewController`: on Liquid Glass a plus button without a child view
    //      controller has a placeholder slot too, and every tab button after it got `cyl_tabBarItemVisibleIndex` + 1
    //      (`-[CYLTabBar cyl_selectedIndex]` returned the next tab's index).
    // [CN] FIX：占位导致的数量不匹配——PlusButton 的 slot 是否是 Tab 按钮之一，从 `viewControllers` 读取，而不是用
    //      `cyl_hasPlusChildViewController`：液态玻璃下没有子控制器的 PlusButton 同样有占位 slot，以前它之后的每个 Tab 按钮的
    //      `cyl_tabBarItemVisibleIndex` 都多 1（`-[CYLTabBar cyl_selectedIndex]` 返回下一个 Tab 的下标）。
    BOOL isPlusSlotAmongTabButtons = ([self cyl_plusButtonViewControllerIndexWithFallback:NSNotFound] != NSNotFound);
    [self.tabBarButtonArray enumerateObjectsUsingBlock:^(UIControl * _Nonnull childView, NSUInteger buttonIndex, BOOL * _Nonnull stop) {
        // [CN] 调整UITabBarItem的位置
        // [EN] Adjust the position of the UITabBarItem
        CGFloat childViewX;
        CGFloat visiableTabIndex = buttonIndex;
        CGFloat tabBarItemWidth = self.cyl_tabBarItemWidth;
        
        if (isPlusSlotAmongTabButtons) {
            if (buttonIndex <= plusButtonIndex) {
                childViewX = buttonIndex * self.cyl_tabBarItemWidth;
            } else {
                childViewX = (buttonIndex - 1) * self.cyl_tabBarItemWidth + self.cyl_plusButtonWidth;
            }
            if (buttonIndex == plusButtonIndex) {
                tabBarItemWidth = self.cyl_plusButtonWidth;
            }
        } else {
            if (buttonIndex >= plusButtonIndex) {
                childViewX = buttonIndex * self.cyl_tabBarItemWidth + self.cyl_plusButtonWidth;
                visiableTabIndex = buttonIndex  + 1;
            } else {
                childViewX = buttonIndex * self.cyl_tabBarItemWidth;
            }
        }
        
        // [EN] Centered positioning, item spacing (see `-cyl_getItemLayoutForTabCount:…`): 0 by default.
        // [CN] 居中与间距（见 `-cyl_getItemLayoutForTabCount:…`）：默认均为 0。
        NSUInteger slotIndex = isPlusSlotAmongTabButtons ? buttonIndex : (NSUInteger)visiableTabIndex;
        childViewX += self.cyl_itemLayoutLeading + slotIndex * self.cyl_itemLayoutSpacing;
        [childView cyl_setTabBarChildViewControllerIndex:buttonIndex];
        UIControl *selectedContentControl = [self cyl_selectedContentControlFromContentControl:childView];
        
        [selectedContentControl cyl_setTabBarChildViewControllerIndex:buttonIndex];
        // [CN] 仅修改childView的x和宽度,yh值不变
        // [EN] Only change childView's x and width; the y and height values stay the same
        [self changeXForChildView:childView
                       childViewX:childViewX
                  tabBarItemWidth:tabBarItemWidth
                            index:visiableTabIndex
        ];
    }];
    if (self.didLayoutSubViewsBlock) {
        self.didLayoutSubViewsBlock(self);
    }
}

/*!
 * [CN] iOS26+ 玻璃效果不能使用 frame 进行修改， 否则 会引发 手势的 lifted 状态变更后，点击后左右闪动bug。
 * [EN] On iOS26+ the glass effect must not be modified via frame, otherwise after the gesture's lifted state changes,
 *      a tap causes a left-right flicker bug.
 */
- (void)changeXForChildView:(UIControl *)childView
                 childViewX:(CGFloat)childViewX
            tabBarItemWidth:(CGFloat)tabBarItemWidth
                      index:(NSUInteger)index {
    if (![CYLConstants isLiquidGlassActive]) {
        // [CN] RTL（如阿语）下镜像 x 坐标，使第 0 个 Tab 位于最右侧
        // [EN] Mirror the x coordinate under RTL (e.g. Arabic) so that tab 0 is on the far right
        if ([self cyl_isRightToLeftLayout]) {
            childViewX = self.cyl_boundsSize.width - childViewX - tabBarItemWidth;
        }
        // [CN] 仅修改childView的x和宽度,yh值不变
        // [EN] Only change childView's x and width; the y and height values stay the same
        childView.frame = CGRectMake(childViewX,
                                     CGRectGetMinY(childView.frame),
                                     tabBarItemWidth,
                                     CGRectGetHeight(childView.frame)
                                     );
    }
    UIControl *selectedContentControl = [self cyl_selectedContentControlFromContentControl:childView];
    [childView cyl_setTabBarItemVisibleIndex:index];
    if (!selectedContentControl) { return; }
    // [CN] 只有玻璃效果有 selectedContentControl，所以可以代替玻璃效果判断。
    //非常重要的 transform 设置， 请勿删除， iOS26+ 玻璃效果+Lottie动画需要禁用形变，否则会引发手势的 lifted 状态变更后的闪动bug。因静态图片场景下不会引起异常， 故未判断是否为Lottie场景
    // [EN] Only the glass effect has selectedContentControl, so it can be used to detect the glass effect.
    //      Very important transform setting, do not delete. On iOS26+, glass effect + Lottie animation needs the
    //      transform disabled, otherwise a flicker bug occurs after the gesture's lifted state changes. Static images
    //      do not cause the problem, so there is no check for whether this is a Lottie scenario.
    selectedContentControl.transform = CGAffineTransformIdentity;//(1, 1);
}

#pragma mark - plusFrame and tabBarItemFrameWithIndex

- (CGFloat)tabItemWidth {
    return self.cyl_tabBarItemWidth;
}

- (CGFloat)plusWidth {
    return self.cyl_plusButtonWidth;
}

- (CGRect)plusFrame {
    CYLTabBarController *tabBarController = [self tabBarController];
    CGFloat tabBarHeight = tabBarController ? tabBarController.tabBarHeight : CYLTabBarHeight;
    return CGRectMake(CYLHalfOfDiff(CYLScreenWidth(), [self plusWidth]), 0, [self plusWidth], tabBarHeight);
}

//- (CGRect)tabBarItemFrameWithIndex:(NSInteger)index {
//    
//    NSInteger plusButtonIndex = 2;
////    CGFloat childViewX = plusButtonIndex * CYLTabBarItemWidth;
////    CGFloat tabBarItemWidth = CGRectGetWidth(self.plusButton.frame);
//    
//    CGFloat w = [self tabItemWidth];
//    CGFloat h = CYLTabBarHeight;
//    CGFloat x = 0;
//    if (index > 1) {
//        x = CYLScreenWidth() - w - (3 - index) * (w + CYLScaleValue(2));
//    } else {
//        x = index * (w + CYLScaleValue(2));
//    }
//    
//    CGFloat y = 0;
//    
//    return CGRectMake(x, y, w, h);
//}

#pragma mark -

#pragma mark -
#pragma mark - Private Methods

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return NO;
}

// [CN] KVO监听执行
// [EN] Handle KVO notifications
/*!
 [CN] //TODO:   iOS26 适配以下接口， 思路是监听， 特定窗口的缩小尺寸变动。执行隐藏和现实PlusButton操作。
 * 增加了类型为UITabBarController.MinimizeBehavior的tabBarMinimizeBehavior属性，用于设置 Tabbar 最小化时的行为。
增加了类型为UITabAccessory的bottomAccessory属性，用于在 Tabbar 的上方再添加一个 UITabAccessory（辅助内容）。
UISearchTab 会从 TabBar 分离出来单独显示。
 issue #13：tabBarMinimizeBehavior 现在通过 `-[CYLTabBarController cyl_tabBarMinimizeBehavior]` 设置；缩小时隐藏、显示 PlusButton 仍待适配。
 [EN] TODO:   Adapt to the following iOS26 APIs. The idea is to observe size changes when a specific window
      minimizes, and hide or show the PlusButton accordingly.
      Added the tabBarMinimizeBehavior property of type UITabBarController.MinimizeBehavior, which sets the
      behavior when the Tabbar is minimized.
      Added the bottomAccessory property of type UITabAccessory, which adds a UITabAccessory (accessory content)
      above the Tabbar.
      UISearchTab is separated from the TabBar and shown on its own.
      Issue #13: tabBarMinimizeBehavior is now set through `-[CYLTabBarController cyl_tabBarMinimizeBehavior]`; hiding
      and showing the PlusButton while minimized is still to do.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == CYLTabBarAlpha) {
        UIView *view = object;
        if (!view.isHidden) {
            if ([change[NSKeyValueChangeNewKey] floatValue] == 0) {
                view.alpha = 1;
            }
        }
        return;
    }
    if (context == CYLTabBarItemBadgeValueContext) {
        // [EN] A badge appeared or changed (not removed): the tab's animation may play its badge-changed animation.
        // [CN] 角标出现或变化（不是被移除）：该 Tab 的动画可以播放角标变化动画。
        id oldValue = change[NSKeyValueChangeOldKey];
        id newValue = change[NSKeyValueChangeNewKey];
        BOOL hasNewValue = [newValue isKindOfClass:[NSString class]];
        CYLTabBarController *tabBarController = [self tabBarController];
        if (hasNewValue && ![oldValue isEqual:newValue] && [object isKindOfClass:[UITabBarItem class]] &&
            [tabBarController respondsToSelector:@selector(cyl_tabBarItemBadgeValueDidChange:)]) {
            [tabBarController cyl_tabBarItemBadgeValueDidChange:(UITabBarItem *)object];
        }
        return;
    }
    if (context == CYLTabBarItemTitleContext) {
        id oldTitle = change[NSKeyValueChangeOldKey];
        id newTitle = change[NSKeyValueChangeNewKey];
        if (!self.cyl_isSettingItemTitles && ![oldTitle isEqual:newTitle] && [CYLConstants isLiquidGlassActive]) {
            [self cyl_reloadTabButtons];
        }
        return;
    }
    if (context == CYLTabBarContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemWidthDidChangeNotification object:self];
        if (@available(iOS 11.0, *)) {
            if (CYL_IS_IPHONE_X) {
                [self layoutIfNeeded];
            }
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc {
    if (_cyl_lottieAnimationPlayingObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_cyl_lottieAnimationPlayingObserver];
    }
    // [CN] KVO反注册
    // [EN] Unregister KVO observers
    [self cyl_removeObserver:self forKeyPath:@"tabBarItemWidth" context:CYLTabBarContext];
    [self removeAlphaObserver];
    [self cyl_stopObservingItemTitles];
}

/// It was never created: `-containsObject:` on nil is NO, so every layout pass added another `alpha` observer, and none
/// was ever removed.
/// 以前从未创建：对 nil 调用 `-containsObject:` 返回 NO，于是每次布局都会再添加一个 `alpha` 观察者，而且从不移除。
- (NSMutableSet<UIView *> *)observedViews {
    if (!_observedViews) {
        _observedViews = [NSMutableSet set];
    }
    return _observedViews;
}

- (void)removeAlphaObserver {
    // Not gated like the registration: `_observedViews` holds exactly the views observed, and the conditions there
    // (Liquid Glass) may have changed since; a view left observed messages this tab bar after it is deallocated.
    // 不像注册时那样加条件：`_observedViews` 正好是被观察的视图，而注册时的条件（Liquid Glass）之后可能已改变；
    // 漏掉的视图会在本 TabBar 释放后继续向它发消息。
    [_observedViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cyl_removeObserver:self forKeyPath:@"alpha" context:CYLTabBarAlpha];
    }];
    [_observedViews removeAllObjects];
}

- (void)setTabBarItemWidth:(CGFloat )tabBarItemWidth {
    if (_tabBarItemWidth != tabBarItemWidth) {
        [self willChangeValueForKey:@"tabBarItemWidth"];
        _tabBarItemWidth = tabBarItemWidth;
        [self didChangeValueForKey:@"tabBarItemWidth"];
    }
}

/*!
 * FIX: issue #257
 * [EN] Every assignment sent a KVO notification, and `CYLTabBarController` then wrote `imageInsets` and
 *      `titlePositionAdjustment` into every tab bar item again, which lays the tab bar out again. Notify only when the
 *      value really changes.
 * [CN] 以前每次赋值都会发出 KVO 通知，`CYLTabBarController` 随即重新写入所有 TabBarItem 的 `imageInsets` 和
 *      `titlePositionAdjustment`，这又会导致 TabBar 重新布局。现在只在值真正改变时才通知。
 */
- (void)setTabImageViewDefaultOffset:(CGFloat)tabImageViewDefaultOffset {
    if (tabImageViewDefaultOffset != 0.f && tabImageViewDefaultOffset != _tabImageViewDefaultOffset) {
        [self willChangeValueForKey:@"tabImageViewDefaultOffset"];
        _tabImageViewDefaultOffset = tabImageViewDefaultOffset;
        [self didChangeValueForKey:@"tabImageViewDefaultOffset"];
    }
}

- (BOOL)isPlusButtonLayoutCentered {
    return [self.plusButton isLayoutCentered];
}

- (CGFloat)multiplierOfTabBarHeight {
    
    return [[CYLPlusButton plusButtonForOwner:self] multiplierOfTabBarHeight:self.cyl_boundsSize.height];
}

//- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
//    CGFloat multiplierOfTabBarHeight;
//    if ([[self.plusButton class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
//        multiplierOfTabBarHeight = [[self.plusButton class] multiplierOfTabBarHeight:tabBarHeight];
//    }
//    
//    CYL_DEPRECATED_DECLARATIONS_PUSH
//    else if ([[self.plusButton class] respondsToSelector:@selector(multiplerInCenterY)]) {
//        multiplierOfTabBarHeight = [[self.plusButton class] multiplerInCenterY];
//    }
//    CYL_DEPRECATED_DECLARATIONS_POP
//    
//    else {
//        CGSize sizeOfPlusButton = self.plusButton.frame.size;
//        CGFloat heightDifference = sizeOfPlusButton.height - self.cyl_boundsSize.height;
//        if (heightDifference < 0) {
//            multiplierOfTabBarHeight = 0.5;
//        } else {
//            CGPoint center = CGPointMake(self.cyl_boundsSize.height * 0.5, self.cyl_boundsSize.height * 0.5);
//            center.y = center.y - heightDifference * 0.5;
//            multiplierOfTabBarHeight = center.y / self.cyl_boundsSize.height;
//        }
//    }
//    return multiplierOfTabBarHeight;
//}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight {
    return [self constantOfPlusButtonCenterYOffsetForTabBarHeight:self.cyl_boundsSize.height];
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    CGFloat constantOfPlusButtonCenterYOffset = 0.f;
    if ([[self.plusButton class] respondsToSelector:@selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:)]) {
        constantOfPlusButtonCenterYOffset = [[self.plusButton class] constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    }
    return constantOfPlusButtonCenterYOffset;
}

/*!
 * FIX: issue #515
 * [EN] The index in `viewControllers` of the plus button's placeholder or child view controller, or `fallback`.
 * [CN] PlusButton 的占位控制器或子控制器在 `viewControllers` 中的下标，没有时返回 `fallback`。
 */
- (NSUInteger)cyl_plusButtonViewControllerIndexWithFallback:(NSUInteger)fallback {
    NSArray<UIViewController *> *viewControllers = [self tabBarController].viewControllers;
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:self];
    NSUInteger index = [viewControllers indexOfObjectPassingTest:^BOOL(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        return viewController.cyl_isPlaceholder || (plusChildViewController && viewController == plusChildViewController);
    }];
    return index != NSNotFound ? index : fallback;
}

- (NSUInteger)plusButtonIndex {
    NSUInteger plusButtonIndex = NSNotFound;
//
//    if ([[self.plusButton class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
//        plusButtonIndex = [[self.plusButton class] indexOfPlusButtonInTabBar];
//    } else {
//        if (CYLTabbarItemsCount % 2 != 0) {
//#if defined(DEBUG) || defined(BETA)
//            NSAssert(NO, @"[DEBUG INFO]If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO] 如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置");
//#endif
//        } else {
//            plusButtonIndex = CYLTabbarItemsCount * 0.5;
//        }
//    }
    plusButtonIndex = [[self.plusButton class] indexForTabbarItemsCount:self.cyl_tabbarItemsCount];
    CGFloat tabBarWidth = self.cyl_boundsSize.width;
    CGFloat tabBarHeight = self.cyl_boundsSize.height;
    
    if (![CYLConstants isLiquidGlassActive]) {
        // [EN] FIX: placeholder count mismatch — with a plus child view controller, over its tab (the slot), which
        //      `-[CYLTabBarController setViewControllers:]` places by the same rule; without one, between the tabs as before.
        // [CN] FIX：占位导致的数量不匹配——有 PlusButton 子控制器时位于其 Tab（slot）上方，slot 由 `-[CYLTabBarController setViewControllers:]`
        //      按同一规则放置；没有时与以前一样位于 Tab 之间。
        plusButtonIndex = [self cyl_plusButtonViewControllerIndexWithFallback:plusButtonIndex];
        CGFloat multiplierOfTabBarHeight = [self multiplierOfTabBarHeight];
        CGFloat constantOfPlusButtonCenterYOffset = [self constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
        _plusButton.center = CGPointMake(tabBarWidth * 0.5, tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset);
        
        CGFloat childViewX = self.cyl_itemLayoutLeading + plusButtonIndex * (self.cyl_tabBarItemWidth + self.cyl_itemLayoutSpacing);
        CGFloat tabBarItemWidth = CGRectGetWidth(self.plusButton.frame);
        [self changeXForChildView:self.plusButton
                       childViewX:childViewX
                  tabBarItemWidth:tabBarItemWidth
                            index:plusButtonIndex
        ];
        CYLPlusButtonIndex = plusButtonIndex;
    } else {
        // FIX: issue #515
        // [EN] Liquid Glass: the plus button covers the tab item of its placeholder (or plus child view controller), which
        //      the tab bar controller puts in the middle. Use that tab's index, so the index stored on the plus button
        //      (used to select its child view controller) is the right one when `+indexOfPlusButtonInTabBar` returns
        //      another position.
        // [CN] 液态玻璃：PlusButton 覆盖其占位控制器（或 PlusButton 子控制器）对应的 TabBarItem，TabBarController 把它放在中间。
        //      这里使用该 Tab 的下标，使 PlusButton 上记录的下标（用于选中其子控制器）在 `+indexOfPlusButtonInTabBar` 返回其他位置时也正确。
        plusButtonIndex = [self cyl_plusButtonViewControllerIndexWithFallback:plusButtonIndex];
        CYLPlusButtonIndex = plusButtonIndex;
        // [CN] FIXME:  to delete 液态玻璃暂时不支持自定义PlusButton位置。
        // [EN] FIXME:  to delete Liquid Glass does not support a custom PlusButton position for now.
//        [self.plusButton cyl_setTabBarItemVisibleIndex:CYLPlusButtonIndex];
        
        // FIX: issue #653 — iOS 27.1 vertical bar (folded iPhone Duo, `allowsVerticalBar = YES`).
        // [EN] The system moves the tab buttons out of this bar into a vertical bar on the trailing edge, while the
        //      plus button stays here. Centre it on its placeholder tab button instead of the horizontal position.
        // [CN] 系统把 Tab 按钮移出本 TabBar，放进右侧竖向栏，而加号按钮仍在本 TabBar 上，需对齐到它的占位 Tab 按钮中心。
        UIView *verticalBarSlot = [self cyl_verticalBarTabButtonAtIndex:plusButtonIndex];
        // Issue #13: the minimized Liquid Glass tab bar (`cyl_tabBarMinimizeBehavior`, iOS 26+) is laid out as the
        // vertical bar is: the platter shrinks, so the height-based Y offset no longer fits; center on the slot instead.
        // [CN] issue #13：缩小后的液态玻璃 TabBar（`cyl_tabBarMinimizeBehavior`，iOS 26+）与竖向栏一样处理：platter 缩小后，
        //      按 TabBar 高度计算的 Y 轴偏移不再适用，改为居中于该 Tab。
        UIView *centeredSlot = verticalBarSlot ?: [self cyl_minimizedBarTabButtonAtIndex:plusButtonIndex];
        if (centeredSlot) {
            // Issue #636: centered on the slot, with or without a title, like a plus button without a title. The height
            // methods and the title alignment (`-cyl_alignedCenterForCenter:`) don't apply to the vertical bar, nor to
            // the minimized bar (issue #13).
            // 竖向栏与缩小后的 TabBar 中（issue #13），无论有没有标题，都与没有标题时一样居中于该 Tab；高度相关的代理方法和标题对齐都不适用。
            CGPoint slotCenter = [centeredSlot.superview convertPoint:centeredSlot.center toView:self];
            if (!CGPointEqualToPoint(self.plusButton.center, slotCenter)) {
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                self.plusButton.center = slotCenter;
                [CATransaction commit];
                // The vertical bar may lay out its buttons after this pass; check again on the next run loop.
                // 竖向栏可能在本次布局之后才排好按钮，下一个 run loop 再校正一次（位置不变时不会再次触发）。
                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf setNeedsLayout];
                });
            }
            [[CYLPlusButton plusButtonForOwner:self] cyl_setTabBarChildViewControllerIndex:plusButtonIndex];
            return plusButtonIndex;
        }
        
        UIView *platterView = self.cyl_contentView;
        
        // [CN] 系统默认参数
        // [EN] System default parameters
        CGFloat multiplierOfTabBarHeight =
        [self multiplierOfTabBarHeight];
        
        CGFloat constantOfPlusButtonCenterYOffset =
        [self constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
        
        // ===============================
        // [CN] 计算 platterView 中心
        // [EN] Compute the platterView center
        // ===============================
        CGPoint platterCenter =
        [platterView.superview convertPoint:platterView.center
                                     toView:self];
        
        // ===============================
        // [CN] 叠加系统默认 Y 逻辑
        // [EN] Add the system's default Y logic on top
        // ===============================
        CGFloat systemDefaultY =
        tabBarHeight * multiplierOfTabBarHeight
        + constantOfPlusButtonCenterYOffset;
        
        // A plus button without a title replaces the whole tab item: centered on the platter (the tab items' center),
        // not on the tab bar (`cyl_appliesCenterYOffsetWithoutTitle` in CYLPlusButton.h).
        // 没有标题的 PlusButton 替换整个 TabBarItem：居中于 platter（即 Tab 的中心），而不是 TabBar 的中心。
        if ([[CYLPlusButton plusButtonForOwner:self] cyl_isCenteredWithoutTitle]) {
            systemDefaultY = platterCenter.y;
        }
        
        // [CN] 计算最终中心
        // [EN] Compute the final center
        CGPoint finalCenter = CGPointMake(
                                          platterCenter.x ,
                                          systemDefaultY
                                          );
        // Issue #636: with the title in the tab item, the image above its title, on the title's vertical center line.
        // 标题由 TabBarItem 显示时：图片位于标题上方，与标题竖向中心线对齐。
        finalCenter = [[CYLPlusButton plusButtonForOwner:self] cyl_alignedCenterForCenter:finalCenter];
        
        // ===============================
        // [CN] 禁止隐式动画
        // [EN] Disable implicit animations
        // ===============================
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        self.plusButton.center = finalCenter;
        
        [CATransaction commit];
    }
    [[CYLPlusButton plusButtonForOwner:self] cyl_setTabBarChildViewControllerIndex:plusButtonIndex];

    return plusButtonIndex;
}

/*!
 * FIX: issue #653 (follow-up)
 * [EN] The iOS 27.1 vertical bar (folded iPhone Duo in landscape, `allowsVerticalBar = YES`) shows the tabs without
 *      titles. Back in the horizontal bar (e.g. rotated to portrait), the tabs kept that layout, without titles, until
 *      a tab was tapped. So when the tab buttons come back, every tab item is updated once, as a tap does: its title is
 *      set again and the tab buttons are laid out again. Runs on the next run loop and once more after the rotation.
 * [CN] iOS 27.1 竖向栏（iPhone Duo 折叠横屏，`allowsVerticalBar = YES`）中 Tab 不显示标题。回到横向栏（如转回竖屏）后，Tab 仍保持
 *      没有标题的布局，直到点击某个 Tab 才恢复。因此 Tab 按钮回到横向栏时，像点击一样把每个 TabBarItem 更新一次：重新设置标题，
 *      并重新布局 Tab 按钮。在下一个 run loop 执行，旋转动画结束后再执行一次。
 */
- (void)cyl_refreshTabButtonsAfterVerticalBar {
    [self cyl_reloadTabButtonsSettingItemTitles:YES];
}

- (void)cyl_reloadTabButtons {
    [self cyl_reloadTabButtonsSettingItemTitles:NO];
}

/*!
 * FIX: issue #601, #653
 * [EN] Lays the tab buttons out again, as a tap does, on the next run loop and once more 0.5 s later (after a rotation
 *      or an animated title change); calls made in the meantime are merged. `setsItemTitles` also sets every item's
 *      title again first, which the tabs coming back from the vertical bar need to show their titles. Does nothing
 *      while the tab buttons are in the iOS 27.1 vertical bar.
 * [CN] 像点击一样重新布局 Tab 按钮：下一个 run loop 执行一次，0.5 秒后（旋转或标题改变的动画之后）再执行一次；期间的多次调用会合并。
 *      `setsItemTitles` 为 YES 时先重新设置每个 item 的标题，从竖向栏返回的 Tab 需要这样才会显示标题。Tab 按钮位于 iOS 27.1
 *      竖向栏时不执行。
 */
- (void)cyl_reloadTabButtonsSettingItemTitles:(BOOL)setsItemTitles {
    self.cyl_reloadSetsItemTitles = self.cyl_reloadSetsItemTitles || setsItemTitles;
    if (self.cyl_isTabButtonsReloadPending) {
        return;
    }
    self.cyl_isTabButtonsReloadPending = YES;
    __weak typeof(self) weakSelf = self;
    void (^reload)(BOOL) = ^(BOOL isLast) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (![self cyl_verticalBarTabButtonAtIndex:0]) {
            if (self.cyl_reloadSetsItemTitles) {
                self.cyl_isSettingItemTitles = YES;
                for (UITabBarItem *item in self.items) {
                    NSString *title = item.title;
                    item.title = nil;
                    item.title = title;
                }
                self.cyl_isSettingItemTitles = NO;
            }
            NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:self];
            while (views.count > 0) {
                UIView *view = views.lastObject;
                [views removeLastObject];
                [view setNeedsLayout];
                [views addObjectsFromArray:view.subviews];
            }
            [self layoutIfNeeded];
        }
        if (isLast) {
            self.cyl_isTabButtonsReloadPending = NO;
            self.cyl_reloadSetsItemTitles = NO;
        }
    };
    dispatch_async(dispatch_get_main_queue(), ^{ reload(NO); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ reload(YES); });
}

/*!
 * FIX: issue #601
 * [EN] Observes the `title` of every item, so a title changed in place (e.g. `viewController.tabBarItem.title = ...`)
 *      reloads the tab buttons (`-cyl_reloadTabButtons`). Liquid Glass otherwise kept their previous layout: the plus
 *      button stayed where its tab was before, off its own title, until a tab was tapped.
 * [CN] 观察每个 item 的 `title`，原地修改标题（如 `viewController.tabBarItem.title = ...`）后重新加载 Tab 按钮
 *      （`-cyl_reloadTabButtons`）。否则液态玻璃保持原来的布局：PlusButton 停在它的 Tab 原来的位置，偏离自己的标题，直到点击某个 Tab。
 */
- (void)cyl_observeItemTitles {
    NSArray<UITabBarItem *> *items = self.items ?: @[];
    if ([items isEqualToArray:self.cyl_titleObservedItems ?: @[]]) {
        return;
    }
    [self cyl_stopObservingItemTitles];
    for (UITabBarItem *item in items) {
        [item addObserver:self forKeyPath:@"title" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:CYLTabBarItemTitleContext];
        [item addObserver:self forKeyPath:@"badgeValue" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:CYLTabBarItemBadgeValueContext];
    }
    self.cyl_titleObservedItems = items;
}

- (void)cyl_stopObservingItemTitles {
    for (UITabBarItem *item in _cyl_titleObservedItems) {
        [item removeObserver:self forKeyPath:@"title" context:CYLTabBarItemTitleContext];
        [item removeObserver:self forKeyPath:@"badgeValue" context:CYLTabBarItemBadgeValueContext];
    }
    _cyl_titleObservedItems = nil;
}

/*!
 * FIX: issue #653
 * [EN] Whether the system shows the tab buttons in the iOS 27.1 vertical bar (unfolded iPhone Duo in landscape,
 *      `allowsVerticalBar = YES`): the platter is no longer inside this tab bar.
 * [CN] 系统是否把 Tab 按钮放在 iOS 27.1 竖向栏中（iPhone Duo 展开横屏，`allowsVerticalBar = YES`）：platter 已不在本 TabBar 内。
 */
- (BOOL)cyl_showsVerticalBar {
    UIView *platterView = self.cyl_platterView;
    return platterView.window && platterView.window == self.window && ![platterView isDescendantOfView:self];
}

/*!
 * Issue #13
 * [EN] Whether the system shows this Liquid Glass tab bar minimized (`-[CYLTabBarController cyl_tabBarMinimizeBehavior]`
 *      is OnScrollDown or OnScrollUp, iOS 26+). UIKit has no public minimized state, so it is read from the geometry: on
 *      iPhone the platter (the glass capsule with the tab buttons) shrinks from almost the full width of the bar to a
 *      small capsule. Less than half the bar's width counts as minimized. NO in the vertical bar (issue #653).
 * [CN] 系统是否正以缩小状态显示本液态玻璃 TabBar（`-[CYLTabBarController cyl_tabBarMinimizeBehavior]` 为 OnScrollDown 或
 *      OnScrollUp，iOS 26+）。UIKit 没有公开的缩小状态，因此根据几何尺寸判断：iPhone 上 platter（承载 Tab 按钮的玻璃胶囊）
 *      会从接近 TabBar 全宽缩小为一个小胶囊，宽度不到 TabBar 一半即视为缩小。竖向栏中（issue #653）返回 NO。
 */
- (BOOL)cyl_showsMinimizedBar {
    if (![CYLConstants isLiquidGlassActive] || UIUserInterfaceIdiomPhone != self.traitCollection.userInterfaceIdiom) {
        return NO;
    }
    CYLTabBarMinimizeBehavior behavior = [self tabBarController].cyl_tabBarMinimizeBehavior;
    if (CYLTabBarMinimizeBehaviorOnScrollDown != behavior && CYLTabBarMinimizeBehaviorOnScrollUp != behavior) {
        return NO;
    }
    UIView *platterView = self.cyl_platterView;
    if (!platterView.window || ![platterView isDescendantOfView:self]) {
        return NO;
    }
    // [EN] In this bar's coordinates, so a scale transform counts too. [CN] 转换到本 TabBar 坐标系，缩放 transform 也会计入。
    CGFloat platterWidth = CGRectGetWidth([platterView convertRect:platterView.bounds toView:self]);
    CGFloat tabBarWidth = CGRectGetWidth(self.bounds);
    return platterWidth > 0 && tabBarWidth > 0 && platterWidth < tabBarWidth * 0.5;
}

/*!
 * Issue #13
 * [EN] The tab button at `index` while this tab bar is minimized (`-cyl_showsMinimizedBar`); nil otherwise.
 * [CN] 本 TabBar 处于缩小状态（`-cyl_showsMinimizedBar`）时第 `index` 个 Tab 按钮；其他情况返回 nil。
 */
- (UIView *)cyl_minimizedBarTabButtonAtIndex:(NSUInteger)index {
    if (![self cyl_showsMinimizedBar]) {
        return nil;
    }
    NSArray<UIControl *> *tabButtons = [self cyl_tabBarSubviews];
    if (index == NSNotFound || index >= tabButtons.count) {
        return nil;
    }
    return tabButtons[index];
}

/*!
 * FIX: issue #653
 * [EN] The tab button at `index` when the system shows the tab buttons in the iOS 27.1 vertical bar, i.e. when the
 *      platter is no longer inside this tab bar; nil otherwise.
 * [CN] iOS 27.1 竖向栏中（platter 已不在本 TabBar 内）第 `index` 个 Tab 按钮；其他情况返回 nil。
 */
- (UIView *)cyl_verticalBarTabButtonAtIndex:(NSUInteger)index {
    if (![self cyl_showsVerticalBar]) {
        return nil;
    }
    UIView *platterView = self.cyl_platterView;
    NSArray<UIControl *> *tabButtons = [self cyl_tabBarSubviews];
    if (index == NSNotFound || index >= tabButtons.count) {
        return nil;
    }
    UIView *tabButton = tabButtons[index];
    return [tabButton isDescendantOfView:platterView] ? tabButton : nil;
}

/*!
 * FIX: issue #653
 * [EN] The tab button (normal layer) under `windowPoint` while the tab buttons are shown in the iOS 27.1 vertical bar; nil otherwise.
 * [CN] iOS 27.1 竖向栏中，位于 `windowPoint`（窗口坐标）下的 Tab 按钮（常态图层）；其他情况返回 nil。
 */
- (UIControl *)cyl_verticalBarTabButtonAtWindowPoint:(CGPoint)windowPoint {
    if (![self cyl_verticalBarTabButtonAtIndex:0]) {
        return nil;
    }
    for (UIControl *tabButton in [self cyl_tabBarSubviews]) {
        CGPoint point = [tabButton convertPoint:windowPoint fromView:nil];
        if ([tabButton pointInside:point withEvent:nil]) {
            return tabButton;
        }
    }
    return nil;
}

/*!
 * FIX: issue #598
 * [EN] Vertical center of the part of `tabBarButton` that holds its content, in this tab bar's coordinates (the same
 *      value as `tabBarButton.center.y` while the button stays above the bottom safe area).
 *      On iOS 16, during a push (iPhone 12), the tab button was laid out stretched over the bottom safe area: its frame
 *      height went from 49 to 83, so `center.y` moved from 24.5 to 41.5. `tabImageViewDefaultOffset` came out ~8.5 pt too
 *      large, the image was moved down onto the title, and since the value is computed only once it stayed wrong.
 *      Leave out the part of the button inside the bottom safe area. Classic style only (no Liquid Glass, no FlatDesign).
 * [CN] `tabBarButton` 中承载内容那部分的垂直中心，使用本 TabBar 的坐标系（按钮位于底部安全区之上时，与
 *      `tabBarButton.center.y` 相同）。
 *      iOS 16（iPhone 12）push 过程中，Tab 按钮会被拉伸到底部安全区内：frame 高度由 49 变为 83，`center.y` 由 24.5 变为 41.5，
 *      计算出的 `tabImageViewDefaultOffset` 偏大约 8.5pt，图片被下移与文字重叠；该值只计算一次，因此会一直错误。
 *      这里排除按钮位于底部安全区内的部分。仅适用于经典样式（非液态玻璃、非扁平样式）。
 */
- (CGFloat)cyl_tabButtonContentCenterY:(UIView *)tabBarButton {
    // Classic style only. Liquid Glass (iOS 26+) lays the buttons out in its own platter, and FlatDesign does not use
    // `tabImageViewDefaultOffset` at all (it is applied only by the classic `-offsetTabBarTabImageViewToFit:`): keep the
    // previous value there. The superview check is a last line of defence for any other button layout.
    // 仅限经典样式：液态玻璃（iOS 26+）的按钮布局在 platter 中，扁平样式完全不使用 `tabImageViewDefaultOffset`
    // （仅由经典样式的 `-offsetTabBarTabImageViewToFit:` 使用），这两种情况保持原值。
    if ([CYLConstants isLiquidGlassActive] ||
        CYLTabBarStyleTypeFlatDesign == self.tabBarController.tabBarStyleType ||
        tabBarButton.superview != self) {
        return tabBarButton.center.y;
    }
    CGRect frame = tabBarButton.frame;
    CGFloat contentMaxY = CGRectGetHeight(self.bounds) - self.safeAreaInsets.bottom;
    if (CGRectGetMaxY(frame) <= contentMaxY || contentMaxY <= CGRectGetMinY(frame)) {
        return tabBarButton.center.y;
    }
    return (CGRectGetMinY(frame) + contentMaxY) * 0.5;
}

/*!
 * FIX: issue #257, issue #522
 * [EN] Measures, once, how far the image of an image-only tab (a tab button without a title label) has to move to be
 *      vertically centered; `CYLTabBarController` observes the result and moves the images of its image-only tabs.
 *      - The guard was `> 0`: a negative offset (an image below the center) was measured again on every layout pass
 *        (any layout of the screen, e.g. after setting a label's text on a page), each time from the image that the
 *        previous offset had already moved, so the icons jumped and the items were written again and again.
 *        Any non-zero offset now ends the measurement.
 *      - Nothing is measured when `CYLTabBarController.automaticallyAdjustsImageOnlyTabs` is NO.
 * [CN] 只测量一次纯图标 Tab（没有标题 label 的 Tab 按钮）的图片需要移动多少才能垂直居中；`CYLTabBarController` 监听该结果，
 *      并移动其纯图标 Tab 的图片。
 *      - 以前的判断是 `> 0`：偏移为负（图片低于中心）时，每次布局（屏幕上任何布局，例如在页面上给 label 赋值后）都会重新测量，
 *        且每次都基于已被上次偏移移动过的图片，于是图标跳动，item 被反复写入。现在任何非零偏移都会结束测量。
 *      - `CYLTabBarController.automaticallyAdjustsImageOnlyTabs` 为 NO 时不做测量。
 */
- (void)setupTabImageViewDefaultOffset:(UIView *)tabBarButton {
    if (self.tabImageViewDefaultOffset != 0.f) {
        return;
    }
    CYLTabBarController *tabBarController = self.tabBarController;
    if ([tabBarController isKindOfClass:[CYLTabBarController class]] && !tabBarController.automaticallyAdjustsImageOnlyTabs) {
        return;
    }
    __block BOOL shouldCustomizeImageView = YES;
    __block CGFloat tabImageViewDefaultOffset = 0.f;
    CGFloat tabButtonCenterY = [self cyl_tabButtonContentCenterY:tabBarButton];
    [tabBarButton.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj cyl_isTabLabel]) {
            shouldCustomizeImageView = NO;
        }
        CGFloat tabImageViewCenterY = obj.center.y;
        
        BOOL isTabImageView = [obj cyl_isTabImageView];
        if (isTabImageView) {
            tabImageViewDefaultOffset = (tabButtonCenterY - tabImageViewCenterY) * 0.5;
        }
        if (isTabImageView && tabImageViewDefaultOffset == 0.f) {
            shouldCustomizeImageView = NO;
        }
    }];
    if (shouldCustomizeImageView) {
        self.tabImageViewDefaultOffset = tabImageViewDefaultOffset;
    }
}

/*!
 * FIX: issue #653
 * [EN] `view.frame` converted from its superview's coordinate space to this tab bar's; `CGRectNull` if `view` is nil.
 * [CN] 将 `view.frame` 从其父视图坐标系转换到本 TabBar 坐标系；`view` 为 nil 时返回 `CGRectNull`。
 */
- (CGRect)cyl_convertFrameOfView:(UIView *)view {
    if (!view) {
        return CGRectNull;
    }
    UIView *superview = view.superview;
    if (!superview || superview == self) {
        return view.frame;
    }
    return [superview convertRect:view.frame toView:self];
}

/*!
 *  Capturing touches on a subview outside the frame of its superview.
 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // [CN] 1. 边界情况：不能响应点击事件
    // [EN] 1. Edge cases: cannot respond to tap events
    
    BOOL canNotResponseEvent = self.cyl_canNotResponseEvent;
    if (canNotResponseEvent) {
        return [super hitTest:point withEvent:event];
    }
    
    // [CN] 2. 优先处理 PlusButton （包括其突出的部分）、TabBarItems 未凸出的部分
    //这一步主要是在处理只有两个 TabBarItems 的场景。
    // 2.1先考虑clipsToBounds情况：子view超出部分没有显示出来
    // [EN] 2. First handle the PlusButton (including its protruding part) and the non-protruding part of TabBarItems
    //      This step mainly handles the case where there are only two TabBarItems.
    //      2.1 First consider the clipsToBounds case: the parts of subviews outside the bounds are not shown
    if (self.clipsToBounds && ![self pointInside:point withEvent:event]) {
        return [super hitTest:point withEvent:event];
    }
    
    // [EN] Guard: only with a plus button.
    // [CN] 仅在有 PlusButton 时处理。
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = self.plusButton;
    if (plusButton) {
        // [EN] FIX: issue #202 — a subview of the plus button that takes touches (a control, or a view with a gesture
        // recognizer) gets the touch first; it used to be swallowed by the plus button.
        // [CN] PlusButton 中自己接收触摸的子视图（控件，或带手势的视图）优先获得触摸；以前会被 PlusButton 拦截。
        UIView *plusButtonSubview = [plusButton hitTestInteractiveSubview:[plusButton convertPoint:point fromView:self] withEvent:event];
        if (plusButtonSubview) {
            return plusButtonSubview;
        }
        // [EN] FIX: issue #91 — the touchable area (`touchableAreaOutsets`, `touchableAreaScale`, or an overridden
        // `-touchableRect`) is in the plus button's superview coordinates. In Liquid Glass that superview is the platter,
        // not this tab bar, so convert it first (as for the tab buttons, #653). A point outside this tab bar still
        // reaches here, so an area above or below the bar takes the touch instead of the page behind.
        // [CN] 可点击区域位于 PlusButton 父视图坐标系；液态玻璃下父视图是 platter 而不是本 TabBar，需要先转换（与 #653 的 Tab 按钮相同）。
        // 本 TabBar 之外的点也会走到这里，因此 TabBar 上方或下方的扩展区域会接收点击，而不再穿透到后面的页面。
        CGRect plusButtonFrame = [plusButton touchableRectInView:self];
        BOOL isInPlusButtonFrame = CGRectContainsPoint(plusButtonFrame, point);
        if (isInPlusButtonFrame) {
            return plusButton;
        }
    }
    NSArray *tabBarButtons = self.tabBarButtonArray;
    if (self.tabBarButtonArray.count == 0) {
        tabBarButtons = [self cyl_visibleControls];
    }
    for (NSUInteger index = 0; index < tabBarButtons.count; index++) {
        UIControl *selectedTabBarButton = tabBarButtons[index];
        UIView *imageView;
        if (selectedTabBarButton && [selectedTabBarButton isKindOfClass:[UIControl class]] && [selectedTabBarButton respondsToSelector:@selector(cyl_getActualBadgeSuperView)]) {
            imageView = selectedTabBarButton.cyl_getActualBadgeSuperView;
        }
        
        // FIX: issue #653 — in Liquid Glass the tab buttons live in the platter, not in this tab bar, so their `frame`
        // is in the platter's coordinate space while `point` is in this tab bar's. On the unfolded iPhone Duo the platter
        // is centered with a large horizontal offset, so a tap on the 2nd tab hit-tested as another tab and a repeat tap on
        // the selected tab never called `tabBarController:didSelectControl:`. Convert both frames to this tab bar first.
        // 液态玻璃下 Tab 按钮在 platter 内，frame 是 platter 坐标，point 是本 TabBar 坐标；iPhone Duo 展开时 platter 居中、偏移较大，
        // 点击第 2 个 Tab 被识别为其他 Tab，导致选中状态下再次点击不回调 didSelectControl。这里先把 frame 转换到本 TabBar 坐标系。
        CGRect selectedTabBarButtonFrame = [self cyl_convertFrameOfView:selectedTabBarButton];
        CGRect imageViewFrame = [self cyl_convertFrameOfView:imageView];

        BOOL isTabBarButtonFrame = CGRectContainsPoint(selectedTabBarButtonFrame, point) || CGRectContainsPoint(imageViewFrame, point);
        if (isTabBarButtonFrame && !selectedTabBarButton.cyl_canNotResponseEvent) {
            return selectedTabBarButton;
        }
    }
    // [CN] CYLFlatDesignTabBar 已经封装在该类内部，不需要在这里处理
    // [EN] CYLFlatDesignTabBar is already handled inside that class, so there is no need to handle it here
    
    // [CN] 3. 最后处理 TabBarItems 凸出的部分、添加到 TabBar 上的自定义视图、点击到 TabBar 上的空白区域
    // [EN] 3. Finally handle the protruding parts of TabBarItems, custom views added to the TabBar, and taps on empty
    //      areas of the TabBar
    UIView *result = [super hitTest:point withEvent:event];
    if (result) {
        return result;
    }
    
    for (UIView *subview in self.subviews.reverseObjectEnumerator) {
        CGPoint subPoint = [subview convertPoint:point fromView:self];
        result = [subview hitTest:subPoint withEvent:event];
        if (result) {
            return result;
        }
    }
    return [super hitTest:point withEvent:event];
}

- (void)addSubview:(UIView *)view {
    if ([view cyl_isPlatterView]) {
        [self cyl_setPlatterView:view];
        UIView * container = view;
        // [CN] 从 PlatterView 中，找真正承载 UITabBarButton 的 ContentView
        // [EN] Find, inside the PlatterView, the ContentView that actually holds the UITabBarButton
        UIView *contentView = nil;
        for (UIView *sub in container.subviews) {
            if ([sub cyl_isPlatterContentView]) {
                contentView = sub;
                break;
            }
        }
        
        if (contentView) {
            [self cyl_setPlatterContentView:contentView];
        }
    }
    // [CN] 点击后的聚焦瞬间遮罩
    // [EN] Momentary focus overlay shown after a tap
    if ([view cyl_isPlatterPortalView]) {
        
        if (!self.cyl_portalView) {
            [self cyl_setPortalView:view];
        }
    }
    
    [super addSubview:view];
}

#pragma mark - Scroll edge element container (iOS 26+)

/*!
 * FIX: issue #662 — a frosted band above the tab bar hides the last rows of a list on iOS 27
 * [EN] Apps add a `UIScrollEdgeElementContainerInteraction` to the tab bar so a scroll view's bottom edge effect sits
 *      under it. UIKit sizes that effect from the tab bar AND its subviews. The raised plus button is a subview that
 *      sticks out above the tab bar (y < 0), so the effect started above the glass capsule and blurred the last rows.
 *      The interaction is now moved to an empty view with exactly the tab bar's bounds, so the effect matches the
 *      tab bar, as it does for tabs without the interaction. Nothing to change in the app. The interaction is not in
 *      the tab bar's `interactions`; remove it with `-removeInteraction:` on the tab bar as usual.
 * [CN] App 会给 TabBar 添加 `UIScrollEdgeElementContainerInteraction`，让滚动视图底部的边缘效果位于 TabBar 下方。UIKit 按
 *      TabBar 及其子视图计算该效果的范围。凸起的加号按钮是伸出 TabBar 上方（y < 0）的子视图，于是边缘效果从玻璃胶囊上方开始，
 *      模糊了列表最后几行。现在该交互被转移到一个与 TabBar bounds 完全相同的空视图上，边缘效果与 TabBar 一致，与未添加该交互的
 *      Tab 相同。App 无需修改代码。该交互不会出现在 TabBar 的 `interactions` 中；照常在 TabBar 上调用 `-removeInteraction:` 移除即可。
 */
- (BOOL)cyl_isScrollEdgeElementContainerInteraction:(id<UIInteraction>)interaction {
    if (@available(iOS 26.0, *)) {
        return [(NSObject *)interaction isKindOfClass:[UIScrollEdgeElementContainerInteraction class]];
    }
    return NO;
}

- (UIView *)cyl_scrollEdgeElementContainer {
    UIView *containerView = self.cyl_scrollEdgeElementContainerView;
    if (!containerView) {
        containerView = [[UIView alloc] initWithFrame:self.bounds];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        containerView.userInteractionEnabled = NO;
        containerView.backgroundColor = [UIColor clearColor];
        self.cyl_scrollEdgeElementContainerView = containerView;
    }
    if (containerView.superview != self) {
        [self insertSubview:containerView atIndex:0];
    }
    return containerView;
}

- (void)addInteraction:(id<UIInteraction>)interaction {
    if ([self cyl_isScrollEdgeElementContainerInteraction:interaction]) {
        [[self cyl_scrollEdgeElementContainer] addInteraction:interaction];
        return;
    }
    [super addInteraction:interaction];
}

- (void)removeInteraction:(id<UIInteraction>)interaction {
    UIView *containerView = self.cyl_scrollEdgeElementContainerView;
    if (containerView && interaction.view == containerView) {
        [containerView removeInteraction:interaction];
        return;
    }
    [super removeInteraction:interaction];
}

// [CN] 识别ContinuousSelection手势，需要代理长按等其他，处理PlusButton事件响应优先级为最优。
// [EN] Recognize the ContinuousSelection gesture; needs a delegate for long press etc., so that PlusButton event
//      handling gets the highest priority.
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (![CYLConstants isLiquidGlassActive] || ![self isKindOfClass:[CYLTabBar class]]) {
        [super addGestureRecognizer:gestureRecognizer];
        return;
    }
    if ([gestureRecognizer cyl_isContinuousGestureRecognizer]) {
        self.liquidGlassContinuousGestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [gestureRecognizer addTarget:self action:@selector(cyl_liquidGlassGestureRecognizerDidUpdate:)];
    }
    if ([gestureRecognizer cyl_isLongGestureRecognizer]) {
        self.liquidGlassLongGestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [gestureRecognizer addTarget:self action:@selector(cyl_liquidGlassGestureRecognizerDidUpdate:)];
    }
    [super addGestureRecognizer:gestureRecognizer];
}

/*!
 * FIX: issue #653 — plus button hidden while pressing or dragging in the iOS 27.1 vertical bar.
 * [EN] While a tab is pressed or dragged, UIKit shows a lifted copy of the tab platter in a portal view. With a
 *      horizontal tab bar that portal is added to this tab bar, below the plus button. In the vertical bar it is added
 *      to the tab bar controller's container view, above the branch that holds this tab bar, so it covered the plus
 *      button (only the plus cover in the selected layer stayed visible). Keep such portal views just below that branch.
 * [CN] 按住或拖拽 Tab 时，系统用 portal 视图显示抬起的 platter 副本。横向时该 portal 加在本 TabBar 上、位于加号按钮之下；
 *      竖向栏中它被加到 TabBarController 的容器视图上，位于本 TabBar 所在分支之上，遮住了加号按钮（只剩选中图层里的加号遮罩）。
 *      这里把这类 portal 视图移到该分支下方。
 */
- (void)cyl_liquidGlassGestureRecognizerDidUpdate:(UIGestureRecognizer *)gestureRecognizer {
    // [EN] FIX: issue #152 / #535 — in Liquid Glass these UIKit gestures receive every touch on the tab buttons, and a
    //      gesture added by the library does not: the long press, Reselect and DoubleTap are recognized from them.
    //      Every state is forwarded, before the checks below.
    // [CN] FIX: issue #152 / #535 — 液态玻璃下，Tab 按钮上的每次触摸都由这些系统手势接收，库自己添加的手势收不到：长按、Reselect
    //      与 DoubleTap 由它们识别。所有状态都转发，且在下方的判断之前。
    CYLTabBarController *owningTabBarController = [self tabBarController];
    if ([owningTabBarController respondsToSelector:@selector(cyl_liquidGlassTabBarGestureRecognizerDidUpdate:)]) {
        [owningTabBarController cyl_liquidGlassTabBarGestureRecognizerDidUpdate:gestureRecognizer];
    }
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan && gestureRecognizer.state != UIGestureRecognizerStateChanged) {
        return;
    }
    if (![self cyl_keepPlusButtonAbovePortalViewsInVerticalBar] || gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    // The portal is added by the lift animation, slightly after the gesture begins, and a finger held still sends no
    // further updates: keep checking while the gesture is active. 抬起动画稍后才添加 portal，手指不动时没有后续回调，因此手势进行中持续检查。
    [self cyl_keepPlusButtonAbovePortalViewsWhileGestureIsActive:gestureRecognizer];
}

- (void)cyl_keepPlusButtonAbovePortalViewsWhileGestureIsActive:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(self) weakSelf = self;
    __weak UIGestureRecognizer *weakGestureRecognizer = gestureRecognizer;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        UIGestureRecognizer *strongGestureRecognizer = weakGestureRecognizer;
        if (!strongSelf || !strongGestureRecognizer) {
            return;
        }
        [strongSelf cyl_keepPlusButtonAbovePortalViewsInVerticalBar];
        UIGestureRecognizerState state = strongGestureRecognizer.state;
        if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
            [strongSelf cyl_keepPlusButtonAbovePortalViewsWhileGestureIsActive:strongGestureRecognizer];
        }
    });
}

/// Returns NO when there is nothing to do (no plus button, or the tab buttons are not in the vertical bar).
- (BOOL)cyl_keepPlusButtonAbovePortalViewsInVerticalBar {
    if (!self.plusButton.superview || ![self cyl_verticalBarTabButtonAtIndex:0]) {
        return NO;
    }
    UIView *rootView = self.tabBarController.viewIfLoaded;
    for (UIView *child = self, *parent = self.superview; parent; child = parent, parent = parent.superview) {
        for (UIView *sibling in [parent.subviews copy]) {
            NSUInteger childIndex = [parent.subviews indexOfObject:child];
            NSUInteger siblingIndex = [parent.subviews indexOfObject:sibling];
            if (siblingIndex != NSNotFound && childIndex != NSNotFound && siblingIndex > childIndex && [sibling cyl_isPlatterPortalView]) {
                [parent insertSubview:sibling belowSubview:child];
            }
        }
        if (parent == rootView || parent == self.window) {
            break;
        }
    }
    return YES;
}

/*!
 * FIX: issue #653 — plus button does not respond in the iOS 27.1 vertical bar.
 * [EN] With a horizontal tab bar, UIKit's hit test reaches the plus button (via `-hitTest:withEvent:` above), so the
 *      touch goes to it and its `UIControlEventTouchUpInside` actions run. In the vertical bar this tab bar's container
 *      (`_UIBottomTabBarGroupView`) is 0 pt tall, so UIKit's hit test never reaches the plus button: the touch goes to
 *      the placeholder tab in the vertical bar and the plus button's actions (e.g. an app's own `-clickPublish`) never run.
 *      When that happens, send them here. Several gesture recognizers can ask during the same touch; the calls are
 *      coalesced to one per run loop turn.
 * [CN] 横向时系统 hitTest 能命中加号按钮（见上方 `-hitTest:withEvent:`），触摸交给加号按钮，触发其 TouchUpInside 事件。
 *      竖向栏中本 TabBar 所在容器 `_UIBottomTabBarGroupView` 高度为 0，系统 hitTest 命中不了加号按钮，触摸落到竖向栏的占位 Tab 上，
 *      加号按钮的点击事件（如 App 自己添加的 `-clickPublish`）不会执行，这里补发。同一次触摸可能有多个手势询问，同一 run loop 内只发送一次。
 */
- (void)cyl_sendPlusButtonActionsIfUnreachableForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    UIWindow *window = self.window;
    if (!plusButton || !window || !plusButton.enabled || !plusButton.userInteractionEnabled || plusButton.hidden) {
        return;
    }
    UIView *systemHitView = [window hitTest:[gestureRecognizer locationInView:window] withEvent:nil];
    if ([systemHitView isDescendantOfView:plusButton]) {
        return; // UIKit delivers the touch to the plus button itself. 系统会把触摸交给加号按钮，无需补发。
    }
    static BOOL isSendPending = NO;
    if (isSendPending) {
        return;
    }
    isSendPending = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        isSendPending = NO;
        [plusButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
}

- (CYLTabBarController *)tabBarController {
    // The owner (its `delegate`) first; the `-cyl_tabBarController` fallback walk only when it has none.
    if ([self.delegate isKindOfClass:[CYLTabBarController class]]) {
        return (CYLTabBarController *)self.delegate;
    }
    return self.cyl_tabBarController;
}

// [CN] 处理PlusButton事件响应优先级为最优。
// [EN] Give PlusButton event handling the highest priority.

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (![CYLConstants isLiquidGlassActive] || ![self isKindOfClass:[CYLTabBar class]]) {
        return YES;
    }
    CGPoint location = [gestureRecognizer locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:nil];
    if (!hitView) {
        // FIX: issue #653 — in the iOS 27.1 vertical bar the tab buttons are outside this tab bar, so the hit test
        // above finds nothing and a tap on the already selected tab never reached `-tabChangedToControl:`
        // (no `tabBarController:didSelectControl:` callback). Look the tab button up under the touch instead.
        // 竖向栏中 Tab 按钮不在本 TabBar 内，上面的 hitTest 为 nil，导致选中状态下再次点击不回调 didSelectControl，这里按触摸点查找 Tab 按钮。
        hitView = [self cyl_verticalBarTabButtonAtWindowPoint:[gestureRecognizer locationInView:nil]];
    }
    // [EN] FIX: issue #202 — on Liquid Glass a subview of the plus button that takes touches (e.g. an X button) got
    //      none: the hit test above returns it, but UIKit's selection gesture still began, selected the stand-in tab
    //      under the plus button and cancelled the subview's touch. Such a subview keeps the touch for itself.
    // [CN] 液态玻璃下，PlusButton 中自己接收触摸的子视图（例如 X 按钮）收不到触摸：上面的 hitTest 已返回它，但 UIKit 的选中手势仍会开始，
    //      选中 PlusButton 下方的替身 Tab 并取消该子视图的触摸。这样的子视图自己保留这次触摸。
    UIView *plusButtonView = self.plusButton;
    if (plusButtonView && hitView && hitView != plusButtonView && [hitView isDescendantOfView:plusButtonView]) {
        return NO;
    }
    SEL actin = @selector(tabChangedToControl:);
    CYLTabBarController *tabBarController = [self tabBarController];
    if (([hitView cyl_isTabButton] || [hitView isKindOfClass:[CYLPlusButton class]] ) && [tabBarController respondsToSelector:actin]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         UIControl *control = (UIControl *)hitView;
         // [EN] A plus button with a child view controller counts as selected while its page is: on Liquid Glass its
         //      `selected` flag is not set when it reports a tap (that left its stand-in with the old image after a theme
         //      change), and a second tap on it must still be reported.
         // [CN] 有子控制器的 PlusButton 在其页面被选中时视为已选中：液态玻璃下上报点击时不再设置它的 `selected`（否则换肤后替身会保留旧图片），
         //      而再次点击仍需上报。
         BOOL isSelected = control.selected;
         UIViewController *plusChildViewController = [control isKindOfClass:[CYLPlusButton class]] ? [CYLPlusButton plusChildViewControllerForOwner:self] : nil;
         if (!isSelected && plusChildViewController) {
             isSelected = [tabBarController.selectedViewController cyl_isEqualToViewController:plusChildViewController];
         }
         if (isSelected) {
             // [CN] FIX: iOS26 无法追加点击事件， 导致无法在选中状态下， 二次点击回调, 被系统手势拦截需要禁用特定手势，因为手势优先级高于 ControlEvents;
             // [EN] FIX: On iOS26 tap events cannot be added, so there is no callback for a second tap in the selected state;
             //      the system gesture intercepts it, so specific gestures must be disabled, because gestures take priority
             //      over ControlEvents;
             [tabBarController performSelector:actin withObject:control];
         }
         )
    }
    
    if ([hitView isKindOfClass:[CYLPlusButton class]] && ![CYLPlusButton plusChildViewControllerForOwner:self]) {
        // [CN] 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
        // 可在PlusButton初始化时设置 reportsTapsToDelegate = NO 来禁止该协议方法触发plusButton回调
        // [EN] Even if the PlusButton has its own tap event, tapping the PlusButton still triggers this delegate method.
        //      Set reportsTapsToDelegate = NO when creating the PlusButton to stop this protocol method from firing the
        //      plusButton callback
        if (CYLControlReportsTaps([CYLPlusButton plusButtonForOwner:self])) {
            if ([tabBarController respondsToSelector:actin]) {
                CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
                (
                 [tabBarController performSelector:actin withObject:[CYLPlusButton plusButtonForOwner:self]];
                 
                 )
            }
        }
        [self cyl_sendPlusButtonActionsIfUnreachableForGestureRecognizer:gestureRecognizer];
        return NO;
    }
    
    return YES;
}

@end

#pragma mark - Background, shadow and blur

@implementation UITabBar (CYLBarBackground)

- (nullable UIView *)cyl_backgroundView {
    return [self cyl_valueForKey:@"_backgroundView"];
}

- (nullable UIImageView *)cyl_shadowImageView {
    return self.cyl_tabShadowImageView;
}

- (nullable NSArray<UIVisualEffectView *> *)cyl_effectViews {
    NSMutableArray<UIVisualEffectView *> *effectViews = [NSMutableArray array];
    for (UIView *subview in self.cyl_backgroundView.subviews) {
        // [EN] Exactly UIVisualEffectView: the shadow is drawn by a subclass. [CN] 必须恰好是 UIVisualEffectView：阴影由其子类绘制。
        if ([subview isMemberOfClass:[UIVisualEffectView class]]) {
            [effectViews addObject:(UIVisualEffectView *)subview];
        }
    }
    return effectViews.count > 0 ? [effectViews copy] : nil;
}

- (nullable UIVisualEffectView *)cyl_effectView {
    UIVisualEffectView *visibleEffectView = nil;
    for (UIVisualEffectView *effectView in self.cyl_effectViews) {
        if (!effectView.hidden && effectView.alpha > 0.01) {
            visibleEffectView = effectView;
        }
    }
    return visibleEffectView;
}

/// [EN] Writes into `standardAppearance` and `scrollEdgeAppearance` (when there is one). [CN] 写入 `standardAppearance` 与 `scrollEdgeAppearance`（存在时）。
- (void)cyl_updateAppearancesWithBlock:(void (^)(UITabBarAppearance *appearance))block API_AVAILABLE(ios(13.0)) {
    UITabBarAppearance *standardAppearance = [self.standardAppearance copy];
    block(standardAppearance);
    self.standardAppearance = standardAppearance;
    if (@available(iOS 15.0, *)) {
        if (self.scrollEdgeAppearance) {
            UITabBarAppearance *scrollEdgeAppearance = [self.scrollEdgeAppearance copy];
            block(scrollEdgeAppearance);
            self.scrollEdgeAppearance = scrollEdgeAppearance;
        }
    }
}

- (nullable UIBlurEffect *)cyl_backgroundEffect {
    if (@available(iOS 13.0, *)) {
        return self.standardAppearance.backgroundEffect;
    }
    UIVisualEffect *effect = self.cyl_effectView.effect;
    return [effect isKindOfClass:[UIBlurEffect class]] ? (UIBlurEffect *)effect : nil;
}

- (void)cyl_setBackgroundEffect:(nullable UIBlurEffect *)backgroundEffect {
    if (@available(iOS 13.0, *)) {
        [self cyl_updateAppearancesWithBlock:^(UITabBarAppearance *appearance) {
            appearance.backgroundEffect = backgroundEffect;
        }];
        return;
    }
    for (UIVisualEffectView *effectView in self.cyl_effectViews) {
        effectView.effect = backgroundEffect;
    }
}

- (nullable UIColor *)cyl_effectForegroundColor {
    if (@available(iOS 13.0, *)) {
        return self.standardAppearance.backgroundColor;
    }
    return self.barTintColor;
}

- (void)cyl_setEffectForegroundColor:(nullable UIColor *)effectForegroundColor {
    if (@available(iOS 13.0, *)) {
        [self cyl_updateAppearancesWithBlock:^(UITabBarAppearance *appearance) {
            appearance.backgroundColor = effectForegroundColor;
        }];
        return;
    }
    self.barTintColor = effectForegroundColor;
}

@end
