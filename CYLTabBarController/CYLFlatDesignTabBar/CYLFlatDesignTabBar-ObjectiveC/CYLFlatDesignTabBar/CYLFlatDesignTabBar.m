//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBar.h"
#import "CYLFlatDesignTabBarItem.h"
#import "CYLTabBarController.h"
//#import "CYLFlatDesignUIViewController.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/UIControl+CYLTabBarControllerExtention.h>
#else
#import "CYLTabBarController.h"
#import "UIControl+CYLTabBarControllerExtention.h"

#endif
// Private header of the pod: the library-neutral tab icon animation (#604). 本 pod 的私有头文件：与动画库无关的 Tab 图标动画（#604）。
#import "UIControl+CYLTabBarItemAnimation.h"
#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
#import "_CYLFlatDesignTabBarParallaxOverlayView.h"

@interface CYLFlatDesignTabBar ()

// _UIBackground
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIVisualEffectView *backgroundEffectView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *shadowImageView;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, weak, readonly, nullable) UITabBarController *tabBarController;
/*!
 * @property (nonatomic, weak, readonly, nullable) CYLFlatDesignUIViewController *customTabBarController;

 */
@property (nonatomic, weak) UIButton<CYLPlusButtonSubclassing> *plusButton;

@end

// Implemented in CYLFlatDesignTabBarButton.m: refreshes the button from its item and the bar's appearance.
// 在 CYLFlatDesignTabBarButton.m 中实现：根据 item 与 TabBar 的 appearance 刷新按钮。
@interface CYLFlatDesignTabBarButton (CYLFlatDesignAppearance)
- (void)_updateTabBarButton;
@end

// FIX: issue #610 — implemented in CYLTabBarController.m.
@interface CYLTabBarController (CYLFlatDesignPlusButtonReport)
- (void)cyl_flatDesignReportDidSelectControl:(UIControl *)control;
- (void)cyl_flatDesignPlusButtonTouchUpInside:(UIControl *)plusButton;
@end

// [EN] Implemented in CYLTabBarController+CYLInteraction.m: the pressed (highlight / dehighlight) animation of a button.
// [CN] 在 CYLTabBarController+CYLInteraction.m 中实现：按钮的按下（highlight / dehighlight）动画。
@interface CYLTabBarController (CYLTabButtonHighlight)
- (void)cyl_tabButtonTouchDown:(UIControl *)control;
- (void)cyl_tabButtonTouchUp:(UIControl *)control;
@end


@implementation CYLFlatDesignTabBar {
    NSInteger _selectedItemIndex;
    NSMutableArray *_buttons;
    /// FIX: issue #488. The token of the block-based Lottie observer: `-removeObserver:self` cannot remove it.
    id<NSObject> _lottieAnimationPlayingObserver;
    /// The appearance the bar was last drawn with (`-_effectiveAppearance`), to refresh only when it changes.
    /// 上次绘制所用的 appearance（`-_effectiveAppearance`），仅在改变时刷新。
    id _appliedAppearance;
    /// The top hairline drawn for `UIBarAppearance.shadowColor` when there is no shadow image.
    /// 没有阴影图片时，按 `UIBarAppearance.shadowColor` 绘制的顶部细线。
    UIView *_appearanceShadowLineView;
}
//@synthesize context = _context;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // [CN] 引入CYLFlatDesignTabBar，即表示同意 hook push行为
        // [EN] Importing CYLFlatDesignTabBar means you agree to hooking the push behavior.
        [UINavigationController cyl_navigationBarActionHook];
        [self commonInit];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabBarItemDidChange:) name:CYLFlatDesignTabBarItemDidChange object:nil];
        // [CN] 仅在引入动画库时监听（#604，运行时判断，以支持任意动画库）。
        // [EN] Observe only with an animation library (#604, checked at runtime so that any library works).
        if (CYLTabBarItemAnimationIsAvailable()) {
            __weak __typeof(self) weakSelf = self;
            void (^CYLTabBarItemAnimationPlayingNotificationBlock)(NSNotification *) = ^(NSNotification *notification) {
                __strong typeof(self) self = weakSelf;
                if (!self) {
                     return;
                }
                // Library-neutral (#604): every animation library (Lottie, PAG). 与动画库无关：所有动画库（Lottie、PAG）。
                [self stopAllTabBarItemAnimations];
            };
            // FIX: issue #488 keep the token, see `-dealloc`. 保存 token，见 `-dealloc`。
            _lottieAnimationPlayingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemAnimationPlayingNotification
                                                                                                object:nil
                                                                                                 queue:[NSOperationQueue mainQueue]
                                                                                            usingBlock:CYLTabBarItemAnimationPlayingNotificationBlock];
        }
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    
    CGFloat height = self.contentView.frame.size.height;
    if (height > 0) {
        sizeThatFits.height = height;
    }
    return sizeThatFits;
}

- (void)dealloc {
    // A block-based observer is only removed by its token.  基于 block 的观察者只能通过 token 移除。
    if (_lottieAnimationPlayingObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_lottieAnimationPlayingObserver];
    }
    @try {
        // [CN] iOS9之后， 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
        // [EN] No longer required since iOS 9, so it is not core logic; consider removing it in the future.
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
}

- (void)_tabBarItemDidChange:(NSNotification *)note {
    if (_items == nil || _items.count == 0) { return; }
    CYLFlatDesignTabBarItem *changedItem = [note object];
    NSInteger itemIndex = [_items indexOfObject:changedItem];
    if (itemIndex != NSNotFound) {
        CYLFlatDesignTabBarButton *tabBarButton = _buttons[itemIndex];
        tabBarButton.tabBarItem = changedItem;
        // The selected item's own `standardAppearance` styles the whole bar. 选中 item 自身的 `standardAppearance` 作用于整个 TabBar。
        [self _updateAppearanceIfNeeded];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateLayout];
    // The tab titles move with the tab bar height (which can change at any time in the Flat style): lay the plus button
    // out again so its title follows them (`+alignsTitleWithTabBarItemTitles`).
    [[CYLPlusButton plusButtonForOwner:self] cyl_setNeedsTitleAlignment];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    // [CN] FIX: issue #662 iPhone Duo 折叠/展开、横竖屏切换时安全区会变化（如右侧 84pt 的竖向状态栏），需重新排列按钮
    // [EN] FIX: issue #662 The safe area changes when an iPhone Duo folds/unfolds or rotates (e.g. the 84pt
    //      vertical status bar on the right), so the buttons need to be laid out again.
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

- (void)commonInit {
    _selectedItemIndex = -1;
    // VoiceOver announces its buttons as tabs ("tab, 2 of 5"). VoiceOver 将其中的按钮朗读为标签页。
    self.accessibilityTraits |= UIAccessibilityTraitTabBar;
    _buttons = [NSMutableArray array];
    
    _backgroundView = [[UIView alloc] init];
    _backgroundView.clipsToBounds = NO;

    [self addSubview:_backgroundView];
    
    _backgroundImageView = [[UIImageView alloc] init];
    _backgroundView.clipsToBounds = NO;

    [_backgroundView addSubview:_backgroundImageView];
    
    _contentView = [[UIView alloc] init];
    _contentView.clipsToBounds = NO;
    [self addSubview:_contentView];
    
    self.barTintColor = [UIColor clearColor];
    self.tintColor = [UIColor systemBlueColor];
    // FIX: issue #662 (iPhone Duo follow-up, PR #665)
    // [CN] 与头文件声明的默认值保持一致（default is YES）。
    // 按钮必须避开左右安全区：iPhone Duo（iOS 27.1 SDK）右侧有 84pt 的竖向状态栏，
    // 若忽略，最后一个 Tab 会被盖住，并在 push/pop 转场中被裁掉一截。
    // [EN] Keep consistent with the default value declared in the header (default is YES).
    //      Buttons must avoid the left/right safe areas: iPhone Duo (iOS 27.1 SDK) has an 84pt vertical status bar on the right;
    //      if ignored, the last tab gets covered and part of it is clipped during push/pop transitions.
    _useLayoutSafeAreaInsets = YES;
    // [CN] FIX: issue #672 默认忽略竖向状态栏（iPhone Duo 折叠竖屏右侧竖列）产生的单侧安全区，保持按钮居中
    // [EN] FIX: issue #672 By default, ignore the one-sided safe area created by the vertical status bar
    //      (the right-side column on a folded iPhone Duo in portrait) and keep the buttons centered.
    _respectsVerticalStatusBarSafeArea = NO;
}

#pragma mark - Setter & Getter

- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue {
    return [[CYLFlatDesignTabBarItem alloc] initWithTitle:title
                                                    image:tabBarItemImage
                                            selectedImage:tabBarItemSelectedImage
                                                    index:index
                                  titlePositionAdjustment:titlePositionAdjustment
                                  imagePositionAdjustment:UIOffsetZero
                                              imageInsets:imageInsets
                                           lottieFilePath:lottieFilePath
                                          lottieSizeValue:lottieSizeValue];
    
     
}

- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarButtons {
    return [_buttons copy];
}

- (void)setDelegate:(id<CYLFlatDesignTabBarDelegate>)delegate {
    if (_delegate != delegate) {
        if (_delegate) {
            // 系统 UITabBarController 也是不允许修改的
            //FIXME:  to delete cylflatdesign_tabBarController
            /*!
             *             if (self.tabBarController || self.customTabBarController) {
            #if defined(DEBUG) || defined(BETA)
                            NSAssert(NO, CYLLocalizedString(@"不允许更改由 tabBarController 管理的 tabBar 的代理"));
            #endif
                            return;
                        }

             */
            if (self.tabBarController) {
#if defined(DEBUG) || defined(BETA)
                NSAssert(NO, CYLLocalizedString(@"不允许更改由 tabBarController 管理的 tabBar 的代理"));
#endif
                return;
            }

        }
        _delegate = delegate;
    }
}

- (void)setItems:(NSArray<CYLFlatDesignTabBarItem *> *)items {
    if (![_items isEqualToArray:items]) {
        if (self.selectedItem && ![items containsObject:self.selectedItem]) {
            _selectedItemIndex = -1;
        }
        _items = [items copy];
        [self _reloadItems];
    }
}

- (NSArray<CYLFlatDesignTabBarButton *> *)tabBarItems {
    return self.tabBarButtons;
}

- (void)setTabBarItems:(NSArray<CYLFlatDesignTabBarItem *> *)tabBarItems {
    [self setItems:tabBarItems];
}

- (void)setSelectedItem:(CYLFlatDesignTabBarItem *)selectedItem {
    if (selectedItem) {
        NSInteger index = [self.items indexOfObject:selectedItem];
        if (index != NSNotFound && _selectedItemIndex != index) {
            [self _setSelectedIndex:index];
        }
    } else {
        if (self.selectedItem) {
            CYLFlatDesignTabBarButton *selectedButton = _buttons[_selectedItemIndex];
//            selectedButton.tabBarItem = selectedItem;
            selectedButton.selected = NO;
            _selectedItemIndex = -1;
        }
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [self _setSelectedIndex:selectedIndex];
}

- (CYLFlatDesignTabBarItem *)selectedItem {
    if (_selectedItemIndex >= 0 && _selectedItemIndex < _items.count) {
        return [_items objectAtIndex:_selectedItemIndex];
    }
    return nil;
}

- (void)setTintColor:(UIColor *)tintColor {
    if (_tintColor != tintColor) {
        _tintColor = tintColor;
        for (CYLFlatDesignTabBarButton *button in _buttons) {
            button.tintColor = tintColor;
        }
    }
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (_barTintColor != barTintColor) {
        _barTintColor = barTintColor;
        [self _updateBackground];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    if (_backgroundImage != backgroundImage) {
        _backgroundImage = backgroundImage;
        [self _updateBackground];
    }
}

- (void)setShadowImage:(UIImage *)shadowImage {
    if (_shadowImage != shadowImage) {
        _shadowImage = shadowImage;
        [self _updateBackground];
    }
}

- (void)setStandardAppearance:(UITabBarAppearance *)standardAppearance {
    if (_standardAppearance != standardAppearance) {
        _standardAppearance = [standardAppearance copy];
        [self _updateAppearanceIfNeeded];
    }
}

#pragma mark - UITabBarAppearance mapping

/*!
 * [EN] The appearance the bar is drawn with: the selected item's own one, else `standardAppearance`; nil before iOS 13
 *      or when neither is set (the flat design look and `barTintColor` / `backgroundImage` / `shadowImage`).
 * [CN] TabBar 绘制所用的 appearance：选中 item 自身的，否则为 `standardAppearance`；iOS 13 以前或二者都未设置时为 nil
 *      （使用扁平样式外观及 `barTintColor` / `backgroundImage` / `shadowImage`）。
 */
- (nullable UITabBarAppearance *)_effectiveAppearance API_AVAILABLE(ios(13.0)) {
    return self.selectedItem.standardAppearance ?: _standardAppearance;
}

/// Redraws the background and every button when the effective appearance changed. 有效 appearance 改变时重绘背景与所有按钮。
- (void)_updateAppearanceIfNeeded {
    id appearance = nil;
    if (@available(iOS 13.0, *)) {
        appearance = [self _effectiveAppearance];
    }
    if (appearance == _appliedAppearance) {
        return;
    }
    _appliedAppearance = appearance;
    [self _updateBackground];
    for (CYLFlatDesignTabBarButton *button in _buttons) {
        [button _updateTabBarButton];
    }
    [self setNeedsLayout];
}

- (void)_setBackgroundEffect:(nullable UIVisualEffect *)effect {
    if (!effect) {
        [_backgroundEffectView removeFromSuperview];
        _backgroundEffectView = nil;
        return;
    }
    if (!_backgroundEffectView) {
        _backgroundEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    } else {
        _backgroundEffectView.effect = effect;
    }
    [_backgroundView insertSubview:_backgroundEffectView atIndex:0];
}

- (void)_setShadowImage:(nullable UIImage *)shadowImage tintColor:(nullable UIColor *)tintColor {
    if (!shadowImage) {
        [_shadowImageView removeFromSuperview];
        _shadowImageView = nil;
        return;
    }
    if (!_shadowImageView) {
        _shadowImageView = [[UIImageView alloc] init];
    }
    _shadowImageView.image = shadowImage;
    _shadowImageView.tintColor = tintColor;
    [_backgroundView addSubview:_shadowImageView];
}

- (void)_setShadowLineColor:(nullable UIColor *)color {
    if (!color) {
        [_appearanceShadowLineView removeFromSuperview];
        _appearanceShadowLineView = nil;
        return;
    }
    if (!_appearanceShadowLineView) {
        _appearanceShadowLineView = [[UIView alloc] init];
    }
    _appearanceShadowLineView.backgroundColor = color;
    [_backgroundView addSubview:_appearanceShadowLineView];
}

/*!
 * [EN] Draws the background and the top shadow, from the effective `UITabBarAppearance` if there is one, else from the
 *      flat design properties (unchanged behavior: an image hides the blur; otherwise `barTintColor` over a blur).
 * [CN] 绘制背景与顶部阴影：有有效的 `UITabBarAppearance` 时按其绘制，否则按扁平样式属性（行为不变：有背景图时不显示模糊，
 *      否则在模糊之上显示 `barTintColor`）。
 */
- (void)_updateBackground {
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [self _effectiveAppearance];
        if (appearance) {
            [self _setBackgroundEffect:appearance.backgroundEffect];
            _backgroundImageView.image = appearance.backgroundImage;
            _backgroundImageView.contentMode = appearance.backgroundImageContentMode;
            _backgroundImageView.backgroundColor = appearance.backgroundColor ?: [UIColor clearColor];
            UIImage *shadowImage = appearance.shadowImage;
            [self _setShadowImage:shadowImage tintColor:appearance.shadowColor];
            [self _setShadowLineColor:shadowImage ? nil : appearance.shadowColor];
            [self setNeedsLayout];
            return;
        }
    }
    _backgroundImageView.image = _backgroundImage;
    _backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    if (_backgroundImage) {
        [self _setBackgroundEffect:nil];
        _backgroundImageView.backgroundColor = [UIColor clearColor];
    } else {
        _backgroundImageView.backgroundColor = self.barTintColor;
        [self _setBackgroundEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    }
    [self _setShadowImage:_shadowImage tintColor:nil];
    [self _setShadowLineColor:nil];
    [self setNeedsLayout];
}

- (void)setRespectsVerticalStatusBarSafeArea:(BOOL)respectsVerticalStatusBarSafeArea {
    if (_respectsVerticalStatusBarSafeArea != respectsVerticalStatusBarSafeArea) {
        _respectsVerticalStatusBarSafeArea = respectsVerticalStatusBarSafeArea;
        [self setNeedsLayout];
    }
}

- (void)setUseLayoutSafeAreaInsets:(BOOL)useLayoutSafeAreaInsets {
    if (_useLayoutSafeAreaInsets != useLayoutSafeAreaInsets) {
        _useLayoutSafeAreaInsets = useLayoutSafeAreaInsets;
        [self setNeedsLayout];
    }
}

- (void)setContext:(NSString *)context {
    _context = context;
    self.cyl_context = context;
}

#pragma mark - Private

/// [EN] Touch down / up on a tab button: the pressed animation of the tab bar controller.
/// [CN] 手指按下 / 抬起 Tab 按钮：TabBarController 的按下动画。
- (void)_tabBarDidTouchDownButton:(CYLFlatDesignTabBarButton *)tabBarButton {
    UITabBarController *owningTabBarController = self.tabBarController;
    if (!tabBarButton.cyl_isPlaceholder && [owningTabBarController isKindOfClass:[CYLTabBarController class]] &&
        [owningTabBarController respondsToSelector:@selector(cyl_tabButtonTouchDown:)]) {
        [(CYLTabBarController *)owningTabBarController cyl_tabButtonTouchDown:tabBarButton];
    }
}

- (void)_tabBarDidTouchUpButton:(CYLFlatDesignTabBarButton *)tabBarButton {
    UITabBarController *owningTabBarController = self.tabBarController;
    if (!tabBarButton.cyl_isPlaceholder && [owningTabBarController isKindOfClass:[CYLTabBarController class]] &&
        [owningTabBarController respondsToSelector:@selector(cyl_tabButtonTouchUp:)]) {
        [(CYLTabBarController *)owningTabBarController cyl_tabButtonTouchUp:tabBarButton];
    }
}

- (void)_tabBarDidSelectButton:(CYLFlatDesignTabBarButton *)tabBarButton {
    NSInteger selectedIndex = [_buttons indexOfObject:tabBarButton];
    CYLFlatDesignTabBarItem *item = self.items[selectedIndex];
    //    tabBarButton.tabBarItem = item;
    
    if (!item.isEnabled) { return; }

    // FIX: issue #19 — a tab that needs login, tapped while logged out: the button is not selected (no Lottie or
    // selection animation), the tap is not reported as a selection, and the login starts instead.
    // 需要登录的 Tab 在未登录时被点击：按钮不会被选中（不播放 Lottie 与选中动画），不作为选中上报，改为发起登录。
    CYLTabBarController *loginTabBarController = [self cyl_owningTabBarController];
    if (loginTabBarController && !tabBarButton.cyl_isPlaceholder &&
        selectedIndex < (NSInteger)loginTabBarController.viewControllers.count &&
        [loginTabBarController cyl_interceptLoginIfNeededForViewController:loginTabBarController.viewControllers[(NSUInteger)selectedIndex]]) {
        return;
    }
    // [EN] A custom action tab (CYLCustomTabAction): not selected, not reported as a selection; its action runs instead.
    // [CN] 使用自定义点击操作的 Tab（CYLCustomTabAction）：不选中、不作为选中上报，改为执行对应操作。
    if (loginTabBarController && !tabBarButton.cyl_isPlaceholder &&
        selectedIndex < (NSInteger)loginTabBarController.viewControllers.count &&
        [loginTabBarController cyl_performCustomTabActionIfNeededForViewController:loginTabBarController.viewControllers[(NSUInteger)selectedIndex]]) {
        return;
    }
    
    // FIX: issue #610
    // [EN] Report the tap through `tabBarController:didSelectControl:`, as the other styles do, here where every tab
    //      button tap arrives: the selection below takes one of three paths (UIKit's private `_tabBarItemClicked`, the
    //      library's `_cyltabBarItemClicked:`, or `_setSelectedIndex:` without a tab bar controller), and only one of them
    //      reported it. The button under the plus button (a plus button with a child view controller, tapped outside its
    //      own outline) reports the plus button, which is what the user tapped.
    // [CN] 与其他样式一样，通过 `tabBarController:didSelectControl:` 上报点击。放在每次点击 Tab 按钮都会经过的这里：下面的选中逻辑
    //      有三条路径（UIKit 私有的 `_tabBarItemClicked`、本库的 `_cyltabBarItemClicked:`、没有 TabBarController 时的
    //      `_setSelectedIndex:`），以前只有其中一条会回调。PlusButton 下方的占位按钮（有子控制器的 PlusButton，点在其轮廓外）上报的是
    //      PlusButton，即用户点击的按钮。
    UITabBarController *owningTabBarController = self.tabBarController;
    if ([owningTabBarController isKindOfClass:[CYLTabBarController class]] &&
        [owningTabBarController respondsToSelector:@selector(cyl_flatDesignReportDidSelectControl:)]) {
        UIControl *control = tabBarButton;
        if (tabBarButton.cyl_isPlaceholder) {
            // Only a plus button with a child view controller selects a tab from here; one without has its own action,
            // which reports it (`-cyl_flatDesignPlusButtonTouchUpInside:`). 只有带子控制器的 PlusButton 会在这里选中 Tab；
            // 没有子控制器的 PlusButton 有自己的事件，由 `-cyl_flatDesignPlusButtonTouchUpInside:` 上报。
            control = (self.plusButton && [self hasPlusChildViewController]) ? self.plusButton : nil;
        }
        if (control) {
            [(CYLTabBarController *)owningTabBarController cyl_flatDesignReportDidSelectControl:control];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
        [self.delegate tabBar:self didSelectItem:item];
    }
    
    //FIXME:  to delete cylflatdesign_tabBarController
    NSString *clickSelectorFromString = [NSString stringWithFormat:@"%@BarItem%@", @"_tab", @"Clicked"];
    
    if (self.tabBarController) {
        // [CN] 系统方法
        // [EN] System method
        SEL sel = NSSelectorFromString(clickSelectorFromString);
        // [EN] FIX: placeholder count mismatch — the system item of this button's view controller, not
        //      `tabBar.items[selectedIndex]`: the system tab bar has no item for a placeholder slot, and a plus child view
        //      controller's item is appended at its end, so the indexes after the slot differ (the last one was out of range).
        // [CN] FIX：占位导致的数量不匹配——取该按钮对应控制器的系统 item，而不是 `tabBar.items[selectedIndex]`：系统 TabBar 中没有
        //      占位 slot 的 item，PlusButton 子控制器的 item 被追加在末尾，因此 slot 之后的下标不一致（最后一个会越界）。
        UITabBarItem *systemItem = item.childViewController.tabBarItem;
        if (![self.tabBarController.tabBar.items containsObject:systemItem]) {
            systemItem = nil;
        }
        if (systemItem && [self.tabBarController respondsToSelector:sel]) {
            //FIXME:  to delete cylflatdesign_tabBarController
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             [self.tabBarController performSelector:sel withObject:systemItem];
             );
        } else {
            // [CN] 容错处理, 防止版本系统修改方法名称
            // [EN] Fault tolerance, in case a system version renames the method
            SEL customSEL = NSSelectorFromString(@"_cyltabBarItemClicked:");
            if ([self.tabBarController respondsToSelector:customSEL]) {
                CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
                (
                 [self.tabBarController performSelector:customSEL withObject:item];
                 );
            } else {
                [self _setSelectedIndex:selectedIndex];
            }
        }
    } else {
        [self _setSelectedIndex:selectedIndex];
    }
}

- (UITabBarController *)tabBarController {
    if ([self.delegate isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)self.delegate;
        return tabBarController;
    }
    return nil;
}

/*!
 * - (CYLFlatDesignUIViewController *)customTabBarController {
    if ([self.delegate isKindOfClass:[CYLFlatDesignUIViewController class]]) {
       return (CYLFlatDesignUIViewController *)self.delegate;
   }
   return nil;
}
 */

- (void)_reloadItems {
    // remove old
    for (CYLFlatDesignTabBarButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    // add tabBarButton
    for (NSInteger index = 0; index < self.items.count; index++) {
        CYLFlatDesignTabBarItem *item = self.items[index];
        CYLFlatDesignTabBarButton *button = [[CYLFlatDesignTabBarButton alloc] initWithTabBarItem:item];
        // [CN] FIXME:  to delete ， 二选一， weak。
        // [EN] FIXME:  to delete, choose one of the two, weak.
//        item.tabBarButton = button;
//        [button setTabBarItem:item];
        button.tintColor = self.tintColor;
        button.selected = (item == self.selectedItem);
        [button addTarget:self action:@selector(_tabBarDidSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        // [EN] The pressed animation, forwarded to the tab bar controller at touch time (it may not be set yet here).
        // [CN] 按下动画，在触摸时转给 TabBarController（此时可能尚未设置）。
        [button addTarget:self action:@selector(_tabBarDidTouchDownButton:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(_tabBarDidTouchUpButton:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        // [CN] TODO:  对齐方案， 最简单。 移除PlusButton对应的item， 重新从 self.contentView 插入对齐。
        // [EN] TODO:  Alignment approach, the simplest one: remove the item corresponding to the PlusButton and re-insert
        //      it into self.contentView for alignment.
        button.clipsToBounds = NO;
        [self.contentView insertSubview:button atIndex:0];
        [_buttons addObject:button];
    }
    // A different item may be selected now. 现在选中的可能是另一个 item。
    [self _updateAppearanceIfNeeded];
    [self setNeedsLayout];
}

- (void)_setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedItemIndex != selectedIndex) {
        // [CN] 统一使用CYLTabBarItemLottieAnimationPlayingNotification进行动画重置， 故删除手动重置。
        // [EN] Animation reset is handled uniformly via CYLTabBarItemLottieAnimationPlayingNotification,
        //      so the manual reset was removed.
//         [self stopAnimationOfAllLottieView];
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemAnimationPlayingNotification object:self];
        _selectedItemIndex = selectedIndex;
        for (NSInteger i = 0; i < _buttons.count; i++) {
            CYLFlatDesignTabBarButton *tabBarButton = _buttons[i];
            tabBarButton.selected = (i == selectedIndex);
        }
        // The newly selected item may bring its own appearance. 新选中的 item 可能有自己的 appearance。
        [self _updateAppearanceIfNeeded];
    }
}

- (void)_updateLayout {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    // background
    _backgroundView.frame = self.bounds;
    
    _backgroundImageView.frame = _backgroundView.bounds;
    if (_backgroundEffectView) {
        _backgroundEffectView.frame = _backgroundView.bounds;
    }
    
    // [CN] 像素比例取自当前 trait，而非 UIScreen.mainScreen（iPhone Duo 内外屏可能不同）
    // [EN] The pixel scale is taken from the current trait rather than UIScreen.mainScreen
    //      (the inner and outer screens of an iPhone Duo may differ).
    CGFloat displayScale = self.traitCollection.displayScale > 0 ? self.traitCollection.displayScale : 1.0;
    CGFloat hairlineHeight = 1.0 / displayScale;
    if (_shadowImageView) {
        CGFloat shadowImageHeight = hairlineHeight;
        // An appearance's shadow image keeps its own height, as on `UITabBar`. appearance 的阴影图片保持自身高度，与 `UITabBar` 相同。
        if (_appliedAppearance && _shadowImageView.image.size.height > 0) {
            shadowImageHeight = _shadowImageView.image.size.height;
        }
        _shadowImageView.frame = CGRectMake(0, -shadowImageHeight, CGRectGetWidth(_backgroundView.frame), shadowImageHeight);
    }
    if (_appearanceShadowLineView) {
        _appearanceShadowLineView.frame = CGRectMake(0, -hairlineHeight, CGRectGetWidth(_backgroundView.frame), hairlineHeight);
    }
    
    // [CN] 放在UITabBarController里
    // [EN] Placed in UITabBarController
    UIEdgeInsets layoutInsets = [self _safeAreaInsetsForLayout];
    CGFloat contentHeight = CGRectGetHeight(self.bounds) - layoutInsets.bottom;
//    if (self.useLayoutSafeAreaInsets) {
//        contentHeight = CGRectGetHeight(self.bounds);
//    }
    self.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), contentHeight);
    
    NSInteger itemCount = self.items.count;
    if (itemCount == 0) { return; }
    if (_buttons.count != itemCount) { return; }

    CGFloat contentWidth = CGRectGetWidth(self.contentView.frame);
    UIEdgeInsets buttonInsets = [self _horizontalButtonInsetsFromSafeAreaInsets:layoutInsets];
    CGFloat leftInset = buttonInsets.left;
    CGFloat rightInset = buttonInsets.right;
    contentWidth -= (leftInset + rightInset);
    
// [CN] 系统间距
// [EN] System spacing
//    CGFloat margin = 2.0;
//    CGFloat buttonSpace = 4.0;
//    CGFloat buttonY = 1.0;
    
    CGFloat margin = 0.0;
    CGFloat buttonSpace = 0.0;
    CGFloat buttonY = 0.0;
    CGFloat buttonWidth = 0;
    if (itemCount == 1) {
        buttonWidth = contentWidth - margin * 2;
    } else {
        buttonWidth = (contentWidth - margin * 2 - (itemCount - 1) * buttonSpace) / itemCount;
    }
    // `UITabBarAppearance.stackedItemPositioning == .centered`: items of `stackedItemWidth` (or an equal share), spaced by
    // `stackedItemSpacing`, centered; when they do not fit, they fill the width as before.
    // `stackedItemPositioning` 为 `.centered` 时：item 宽度为 `stackedItemWidth`（或平分宽度），间距为 `stackedItemSpacing`，
    // 整体居中；放不下时与之前一样铺满宽度。
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [self _effectiveAppearance];
        if (appearance.stackedItemPositioning == UITabBarItemPositioningCentered) {
            CGFloat centeredSpace = MAX(appearance.stackedItemSpacing, 0);
            CGFloat centeredWidth = appearance.stackedItemWidth > 0 ? appearance.stackedItemWidth : (contentWidth - (itemCount - 1) * centeredSpace) / itemCount;
            CGFloat totalWidth = itemCount * centeredWidth + (itemCount - 1) * centeredSpace;
            if (centeredWidth > 0 && totalWidth <= contentWidth) {
                buttonWidth = centeredWidth;
                buttonSpace = centeredSpace;
                margin = (contentWidth - totalWidth) / 2;
            }
        }
    }
    CGFloat buttonHeight = CGRectGetHeight(self.contentView.frame) - buttonY;
    BOOL isRightToLeft = [self cyl_isRightToLeftLayout];

    for (NSInteger i = 0; i < self.items.count; i++) {
        CYLFlatDesignTabBarButton *button = _buttons[i];
        //        button.tabBarItem = self.items[i];
        [button setTabBarItem:self.items[i]];
        
        // [CN] RTL（如阿语）下按钮从右到左排列，第 0 个 Tab 位于最右侧
        // [EN] In RTL (e.g. Arabic), buttons are laid out right to left, and tab 0 is on the far right.
        NSInteger visibleIndex = isRightToLeft ? (itemCount - 1 - i) : i;
        CGFloat buttonX = margin + visibleIndex * (buttonWidth + buttonSpace);
        buttonX += leftInset;
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
    }
    if ([self hasPlusButton]) {
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = (CYLPlusButton<CYLPlusButtonSubclassing> *)[CYLPlusButton plusButtonForOwner:self];
        CGFloat tabBarHeight = self.contentView.frame.size.height;
        CGFloat constantOfPlusButtonCenterYOffset = [plusButton constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
        plusButton.layer.contentsGravity = kCAGravityCenter;

        if (@available(iOS 13.0, *)) {
            plusButton.layer.contentsScale = CYLGetRootWindow().windowScene.screen.scale;
        }
        
//        plusButton.clipsToBounds = NO;
//        [self.contentView cyl_bringSubviewToTop:plusButton];
        self.plusButton = plusButton;
        // FIX: issue #610 a plus button without a child view controller has no action here: report its taps through
        // `tabBarController:didSelectControl:` too. 没有子控制器的 PlusButton 在这里没有事件：同样回调 `tabBarController:didSelectControl:`。
        UITabBarController *owningTabBarController = self.tabBarController;
        SEL plusButtonTapSelector = @selector(cyl_flatDesignPlusButtonTouchUpInside:);
        if ([owningTabBarController isKindOfClass:[CYLTabBarController class]] &&
            ![CYLPlusButton plusChildViewControllerForOwner:owningTabBarController] &&
            [owningTabBarController respondsToSelector:plusButtonTapSelector]) {
            [plusButton removeTarget:owningTabBarController action:plusButtonTapSelector forControlEvents:UIControlEventTouchUpInside];
            [plusButton addTarget:owningTabBarController action:plusButtonTapSelector forControlEvents:UIControlEventTouchUpInside];
        }
        // [CN] FIXME:  to delete 自定义的index。
        // [EN] FIXME:  to delete the custom index.
//        [self cyl_replace];(
        // [EN] Never index past this tab bar's own buttons: the plus button index comes from the tab items count, which may
        //      describe another tab bar or be stale while the items change.
        // [CN] 不能越过本 TabBar 自己的按钮取下标：PlusButton 的 index 来自 Tab 数量，可能描述的是另一个 TabBar，或在 items 变化时已过期。
        NSUInteger plusButtonIndex = self.cyl_plusButtonIndex;
        if (plusButtonIndex >= _buttons.count) {
            return;
        }
        CYLFlatDesignTabBarButton *plusButtonIndexPlaceholder = _buttons[plusButtonIndex];
        if (![plusButtonIndexPlaceholder.tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
            return;
        }
        __weak __typeof(self) weakSelf = self;
        /*!
                                               *
                                                      if multiplierOfTabBarHeight * TabBarHeight + constantOfPlusButtonCenterYOffset == 0.5 * TabBarHeight + plusButtonoffsetY;
                                                      plusButtonoffsetY = fabsf(multiplierOfTabBarHeight -0.5) * tabBarHeight + constantOfPlusButtonCenterYOffset
                                                      CGFloat plusButtonoffsetY = multiplierOfTabBarHeight * TabBarHeight
                                               */
        UIOffset plusButtonoffset =  UIOffsetMake(0, constantOfPlusButtonCenterYOffset);
        // FIX: issue #662 — the plus button is placed by frame (`cyl_coverVisiableTabImageViewOrTabButton:` tracks it, see
        // `CYLTabButtonLayoutTracker`). Turning `translatesAutoresizingMaskIntoConstraints` off here on every layout left it
        // in Auto Layout with no constraints, so a later layout pass could restore a stale frame: after the iPhone Duo was
        // folded, tapping other tabs moved the plus button down.
        // 加号按钮由 frame 定位（见 `CYLTabButtonLayoutTracker`）。此处每次布局都关闭 translatesAutoresizingMaskIntoConstraints，
        // 使其处于无约束的 Auto Layout 中，之后的布局可能恢复旧 frame：iPhone Duo 折叠后点击其他 Tab，加号按钮会下移。
        self.plusButton.translatesAutoresizingMaskIntoConstraints = YES;
        
        [plusButtonIndexPlaceholder cyl_coverVisiableTabImageViewOrTabButton:YES
                                                        contentNewView:self.plusButton
                                                 seclectContentNewView:self.plusButton
                                                                offset:plusButtonoffset
                                                                  show:YES
                                               delayIfNeededForSeconds:0.1
                                                            completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull newView) {
               __strong typeof(self) self = weakSelf;
               if (!self) {
                   return;
               }
            [newView layoutIfNeeded];
            [tabBarButton cyl_setIsPlaceholder:YES];

//            [tabBarButton cyl_bringSubviewToTop:newView];
//            tabBarButton.userInteractionEnabled = NO;
//               if (isReplaced && show && newView) {
//                   [self.viewControllers[0] cyl_clearBadge];
//       //            [tabBarButton.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//       //                if (![obj isKindOfClass:[newView class]]) {
//       //                    [obj cyl_setHidden:show];
//       //                }
//       //            }];
//       //            [tabBarButton insertSubview:tabBarButton.cyl_lottieAnimationView belowSubview:selectedTabButton];
//       //            [tabBarButton bringSubviewToFront:newView];
//                   [tabBarButton cyl_bringSubviewToTop:newView];
//                   if (![CYLConstants isLiquidGlassActive]) {
// [CN] // LiquidGlass 已经自带缩放动画， 无需缩放
// [EN] // LiquidGlass already has a built-in scale animation, so no scaling is needed
//                       [self addOnceScaleAnimationOnView:newView];
//                   }
//               }
        }];
        
//        self.plusButton.center = CGPointMake(tabBarWidth * 0.5, tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset);
    }
}

/*!
 * FIX: issue #662 (push/pop follow-up, PR #665): the tab bar's height shrinks during push/pop, then recovers.
 * [EN] Safe area insets used to lay out the content (bottom: content height; left/right: button row).
 *      During a FlatDesign push/pop the bar is moved into `_CYLFlatDesignTabBarParallaxOverlayView` on the
 *      page's view, inside `selectedViewController`. That page carries the bottom
 *      `additionalSafeAreaInsets` (= tabBarHeight) that CYLTabBarController gives `selectedViewController`,
 *      so the bar's own `safeAreaInsets.bottom` grows from 34 to 34 + 49 = 83, the bar's whole height,
 *      and the content collapsed vertically until the bar went back to the tab bar controller's view.
 *      Its left/right insets also change every frame as the page slides (iPhone Duo's 84 pt trailing
 *      status column). While in the overlay, the insets are read live from the tab bar controller's view,
 *      the bar's home, where it sits along the bottom edge at full width: the same insets it has in place,
 *      always current (nothing is cached), and unaffected by the page's extra inset.
 * [CN] 用于布局内容的安全区（bottom 决定内容高度，left/right 决定按钮行）。
 *      push/pop 转场时 TabBar 被移到 `selectedViewController` 内页面视图上的 `_CYLFlatDesignTabBarParallaxOverlayView`。
 *      该页面带有 CYLTabBarController 给 `selectedViewController` 设置的底部 `additionalSafeAreaInsets`（= tabBarHeight），
 *      TabBar 自身的 `safeAreaInsets.bottom` 会从 34 变成 34 + 49 = 83（即整个 TabBar 高度），
 *      内容高度因此被压缩，直到 TabBar 回到 TabBarController 的 view 上才恢复。
 *      左右安全区也会随页面滑动逐帧变化（iPhone Duo 右侧 84pt 竖向状态栏）。
 *      位于 overlay 中时，实时读取 TabBar 的原宿主 TabBarController.view 的安全区（TabBar 在其中贴底、满宽），
 *      与原位置一致、始终最新（不缓存），且不受页面额外 inset 影响。
 * 状态 / Status (iPhone Duo): 展开（内屏）push/pop 高度不变，符合预期；折叠（外屏）仍反馈会变矮后恢复，
 *      原因尚未定位，见 CYLTabBarController.m `-_logTabBarClippingInParallaxOverlay`（DEBUG 诊断）。
 *      Unfolded: height stays put, as expected. Folded: still reported to shrink and recover; cause not yet
 *      located, see the DEBUG diagnostic `-_logTabBarClippingInParallaxOverlay` in CYLTabBarController.m.
 */
/*!
 * FIX: issue #672
 * [EN] Left/right insets the button row keeps clear of. A vertical status bar (folded iPhone Duo held
 *      upright: status column on the right) insets one side only, while a landscape notch insets both.
 *      The one-sided inset is ignored unless `respectsVerticalStatusBarSafeArea` is YES, so the row stays
 *      centered on screen by default.
 * [CN] 按钮行需要避开的左右安全区。竖向状态栏（iPhone Duo 折叠且竖屏：状态栏位于右侧竖列）只在一侧产生安全区，
 *      横屏刘海则两侧都有。除非 `respectsVerticalStatusBarSafeArea` 为 YES，否则忽略单侧安全区，默认保持按钮行居中。
 */
- (UIEdgeInsets)_horizontalButtonInsetsFromSafeAreaInsets:(UIEdgeInsets)safeAreaInsets {
    if (!self.useLayoutSafeAreaInsets) {
        return UIEdgeInsetsZero;
    }
    BOOL isOneSided = (safeAreaInsets.left > 0) != (safeAreaInsets.right > 0);
    if (isOneSided && !self.respectsVerticalStatusBarSafeArea) {
        return UIEdgeInsetsZero;
    }
    return UIEdgeInsetsMake(0, safeAreaInsets.left, 0, safeAreaInsets.right);
}

- (UIEdgeInsets)_safeAreaInsetsForLayout {
    UIView *homeView = self.tabBarController.viewIfLoaded;
    BOOL isInParallaxOverlay = [self.superview isKindOfClass:[_CYLFlatDesignTabBarParallaxOverlayView class]];
    if (isInParallaxOverlay && homeView.window) {
        UIEdgeInsets homeInsets = homeView.safeAreaInsets;
        return UIEdgeInsetsMake(0, homeInsets.left, MIN(homeInsets.bottom, CGRectGetHeight(self.bounds)), homeInsets.right);
    }
    UIEdgeInsets safeAreaInsets = self.safeAreaInsets;
    return UIEdgeInsetsMake(0, safeAreaInsets.left, safeAreaInsets.bottom, safeAreaInsets.right);
}

//- (UIButton *)selectedCover {
////    if (_selectedCover) {
////        return _selectedCover;
////    }
//    UIButton *selectedCover = [UIButton buttonWithType:UIButtonTypeCustom];
//    
//    UIImage *image = [UIImage imageNamed:@"home_select_cover"];
//    [selectedCover setImage:image forState:UIControlStateNormal];
//    selectedCover.frame = ({
//        CGRect frame = selectedCover.frame;
//        frame.size = CGSizeMake(image.size.width, image.size.height);
//        frame;
//    });
//    selectedCover.contentMode = UIViewContentModeCenter;
//    selectedCover.imageView.contentMode = UIViewContentModeScaleAspectFit;
//
//    selectedCover.translatesAutoresizingMaskIntoConstraints = NO;
//    // selectedCover.userInteractionEnabled = false;
////    _selectedCover = selectedCover;
//    return selectedCover;
//}

/*!
 * FIX: issue #604
 * [EN] Stops the animations of every tab, whatever their library (Lottie or PAG, each a `CYLTabBarItemAnimator`).
 * [CN] 停止所有 Tab 的动画，与动画库无关（Lottie 或 PAG，均为 `CYLTabBarItemAnimator`）。
 */
- (void)stopAllTabBarItemAnimations {
    // FIX: issue #604 — only with the `CYLTabBarItemAnimation` subspec. 仅在包含 `CYLTabBarItemAnimation` 子库时。
    if (!CYLTabBarItemAnimationIsAvailable()) {
        return;
    }
    [self.tabBarItems enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cyl_stopTabBarItemAnimation];
    }];
}

/// [EN] Kept for compatibility; any animation library (#604). [CN] 为兼容而保留；适用于任意动画库（#604）。
- (void)stopAnimationOfAllLottieView {
    [self stopAllTabBarItemAnimations];
}

#pragma mark - plusFrame and tabBarItemFrameWithIndex
/*!
 *

 *  Capturing touches on a subview outside the frame of its superview.
 
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    [CN] //1. 边界情况：不能响应点击事件
    [EN] //1. Edge case: cannot respond to tap events
    
    BOOL canNotResponseEvent = self.cyl_canNotResponseEvent;
    if (canNotResponseEvent) {
        return [super hitTest:point withEvent:event];
    }
    
    [CN] //2. 优先处理 PlusButton （包括其突出的部分）、TabBarItems 未凸出的部分
    //这一步主要是在处理只有两个 TabBarItems 的场景。
    // 2.1先考虑clipsToBounds情况：子view超出部分没有显示出来
    [EN] //2. First handle the PlusButton (including its protruding part) and the non-protruding parts of the TabBarItems
         //This step mainly handles the case with only two TabBarItems.
         // 2.1 First consider clipsToBounds: the parts of subviews outside the bounds are not displayed
    if (self.clipsToBounds && ![self pointInside:point withEvent:event]) {
        return [super hitTest:point withEvent:event];
    }
    
    if (self.plusButton) {
        CGRect plusButtonFrame = [self.plusButton touchableRect];
        BOOL isInPlusButtonFrame = CGRectContainsPoint(plusButtonFrame, point);
        if (isInPlusButtonFrame) {
            return self.plusButton;
        }
    }
    NSArray *tabBarButtons = self.tabBarButtonArray;
    if (self.tabBarButtonArray.count == 0) {
        tabBarButtons = [self cyl_visibleControls];
    }
    for (NSUInteger index = 0; index < tabBarButtons.count; index++) {
        UIView *selectedTabBarButton = tabBarButtons[index];
        CGRect selectedTabBarButtonFrame = selectedTabBarButton.frame;
        BOOL isTabBarButtonFrame = CGRectContainsPoint(selectedTabBarButtonFrame, point);
        if (isTabBarButtonFrame && !selectedTabBarButton.hidden) {
            return selectedTabBarButton;
        }
    }
    [CN] //CYLFlatDesignTabBar 已经封装在该类内部，不需要在这里处理
    [EN] //CYLFlatDesignTabBar is already encapsulated inside this class, no need to handle it here
    
    [CN] //3. 最后处理 TabBarItems 凸出的部分、添加到 TabBar 上的自定义视图、点击到 TabBar 上的空白区域
    [EN] //3. Finally handle the protruding parts of TabBarItems, custom views added to the TabBar,
         and taps on empty areas of the TabBar
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
 */
// [CN] 如果imageView超出TabBar范围，增加imageView响应区域
// [EN] If the imageView extends beyond the TabBar, enlarge the imageView's touch area
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // [CN] 1. 边界情况：不能响应点击事件
    // [EN] 1. Edge case: cannot respond to tap events
    
    BOOL canNotResponseEvent = self.cyl_canNotResponseEvent;
    if (canNotResponseEvent) {
        return [super hitTest:point withEvent:event];
    }
    
    // [CN] 2. 优先处理 PlusButton （包括其突出的部分）、TabBarItems 未凸出的部分
    //这一步主要是在处理只有两个 TabBarItems 的场景。
    // 2.1先考虑clipsToBounds情况：子view超出部分没有显示出来
    // [EN] 2. First handle the PlusButton (including its protruding part) and the non-protruding parts of the TabBarItems
    //      This step mainly handles the case with only two TabBarItems.
    //      2.1 First consider clipsToBounds: the parts of subviews outside the bounds are not displayed
    if (self.clipsToBounds && ![self pointInside:point withEvent:event]) {
        return [super hitTest:point withEvent:event];
    }
    
    UIButton<CYLPlusButtonSubclassing> *plusButton = self.plusButton;
    // [EN] Guard: only with a plus button.
    // [CN] 仅在有 PlusButton 时处理。
    if (plusButton) {
        // [EN] FIX: issue #202 — a subview of the plus button that takes touches (a control, or a view with a gesture
        // recognizer) gets the touch first; it used to be swallowed by the plus button.
        // [CN] PlusButton 中自己接收触摸的子视图（控件，或带手势的视图）优先获得触摸；以前会被 PlusButton 拦截。
        if ([plusButton isKindOfClass:[CYLPlusButton class]]) {
            UIView *plusButtonSubview = [(CYLPlusButton *)plusButton hitTestInteractiveSubview:[plusButton convertPoint:point fromView:self] withEvent:event];
            if (plusButtonSubview) {
                return plusButtonSubview;
            }
        }
        // [EN] FIX: issue #91 — `-touchableRect` is in the plus button's SUPERVIEW coordinates (by default its frame, grown by
        // `touchableAreaOutsets` / `touchableAreaScale`). It used to be converted from the plus button's own coordinates,
        // which added the frame's origin twice and moved the area away from the button.
        // [CN] `-touchableRect` 位于 PlusButton 父视图坐标系（默认为 frame，按 `touchableAreaOutsets` / `touchableAreaScale` 扩大）。
        // 以前按 PlusButton 自身坐标系转换，frame 的原点被加了两次，可点击区域偏离按钮。
        CGRect plusButtonFrameToSuperview = CGRectZero;
        if ([plusButton isKindOfClass:[CYLPlusButton class]]) {
            plusButtonFrameToSuperview = [(CYLPlusButton *)plusButton touchableRectInView:self];
        } else {
            CGRect touchableRect = [plusButton respondsToSelector:@selector(touchableRect)] ? [plusButton touchableRect] : plusButton.frame;
            plusButtonFrameToSuperview = plusButton.superview ? [plusButton.superview convertRect:touchableRect toView:self] : touchableRect;
        }

        BOOL isInPlusButtonFrame = CGRectContainsPoint(plusButtonFrameToSuperview, point);
        // [EN] With a plus child view controller, a touch inside the bar keeps going to the tab button under the plus button
        // (as before); a touch in the part of the area outside the bar (the raised part, or the extra area) goes to the
        // plus button, which selects the child view controller. It used to fall through to the page behind (#91).
        // [CN] 有 PlusButton 子控制器时，TabBar 内的点击仍交给 PlusButton 下方的 Tab 按钮（与以前一致）；可点击区域中位于 TabBar 之外的部分
        // （凸起部分或扩展区域）交给 PlusButton，由它选中子控制器。以前会穿透到后面的页面（#91）。
        BOOL isOutsideBar = ![self pointInside:point withEvent:event];
        if (isInPlusButtonFrame && (![self hasPlusChildViewController] || isOutsideBar)) {
            return plusButton;
        }
        BOOL isInPlusButtonSuperFrame = CGRectContainsPoint(self.plusButton.superview.frame, point);
        if (isInPlusButtonSuperFrame && self.plusButton.superview.cyl_isPlaceholder && self.plusButton.superview.cyl_canNotResponseEvent && !self.plusButton.cyl_canNotResponseEvent) {
            // [CN] 防止误触PlusButton轮廓外， 且在tabBarButton范围内。否则， 会切换到PlusButton 对应的空白placeholder vc上。
            // [EN] Prevent accidental taps outside the PlusButton outline but within the tabBarButton. Otherwise it would switch
            //      to the blank placeholder VC corresponding to the PlusButton.
            return self.plusButton;
        }
    }
    for (CYLFlatDesignTabBarButton *selectedTabBarButton in self.tabBarButtons) {
        CGRect imageRect = [selectedTabBarButton.actualBadgeSuperView convertRect:selectedTabBarButton.imageView.bounds toView:self];
        BOOL isTabBarButtonFrame = (CGRectContainsPoint(selectedTabBarButton.frame, point) || CGRectContainsPoint(imageRect, point));
        if (isTabBarButtonFrame && !selectedTabBarButton.cyl_canNotResponseEvent) {
            return selectedTabBarButton;
        }
        // [CN] 防止误触PlusButton轮廓外， 且在tabBarButton范围内。否则， 会切换到PlusButton 对应的空白placeholder vc上。已经在(self.plusButton)判断逻辑内处理， 这里无需重复处理。
        // [EN] Prevent accidental taps outside the PlusButton outline but within the tabBarButton. Otherwise it would switch
        //      to the blank placeholder VC corresponding to the PlusButton. This is already handled in the (self.plusButton)
        //      check, so there is no need to repeat it here.
        //        else if (selectedTabBarButton.cyl_isPlaceholder && (self.plusButton)) {
        //            return self.plusButton;
        //        }
    }
    
    // [CN] 3. 最后处理 TabBarItems 凸出的部分、添加到 TabBar 上的自定义视图、点击到 TabBar 上的空白区域
    // [EN] 3. Finally handle the protruding parts of TabBarItems, custom views added to the TabBar,
    //      and taps on empty areas of the TabBar
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

- (CGFloat)tabItemWidth {
    [self cyl_setTabBarItemWidth:(CYLScreenWidth() - self.cyl_plusButtonWidth) / self.cyl_tabbarItemsCount];
    //        CYLTabBarItemWidth = (tabBarWidth) / CYLTabbarItemsCount;
    return self.cyl_tabBarItemWidth;
}

- (CGFloat)plusWidth {
    return self.cyl_plusButtonWidth;
}

//- (CGRect)plusFrame {
//    return CGRectMake(CYLHalfOfDiff(CYLScreenWidth(), [self plusWidth]), 0, [self plusWidth], CYLTabBarHeight);
//}

- (CGRect)tabBarItemFrameWithIndex:(NSInteger)index {
    CGFloat w = [self tabItemWidth];
    // The height of the controller that owns this tab bar, not the global another controller may have written.
    // 拥有本 TabBar 的控制器的高度，而不是可能被其他控制器改写的全局变量。
    // `self.tabBarController` is never set for a flat design tab bar: the owner is found through its `delegate`.
    // 扁平样式 TabBar 的 `self.tabBarController` 从未被赋值：通过它的 `delegate` 找到拥有它的控制器。
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController];
    CGFloat h = tabBarController ? tabBarController.tabBarHeight : CYLTabBarHeight;
    CGFloat x = 0;
    if (index > 1) {
        x = CYLScreenWidth() - w - (3 - index) * (w + CYLScaleValue(2));
    } else {
        x = index * (w + CYLScaleValue(2));
    }
    CGFloat y = 0;
    
    return CGRectMake(x, y, w, h);
}

/*!
 * [EN] A standalone tab bar: one the app added to a page by itself (e.g. the FlatDesign demo page), not the tab bar of a
 *      CYLTabBarController (whose `delegate` is that controller). The owner lookup walks up from such a bar to the
 *      CYLTabBarController the page is in, and used to give it that controller's plus button: its index belongs to the
 *      other tab bar, so `_buttons[plusButtonIndex]` crashed with "index 2 beyond bounds [0 .. 1]" (popping back from a
 *      four-tab page), and the shared plus button would be moved out of the controller's own tab bar.
 * [CN] 独立 TabBar：App 自己添加到页面上的 TabBar（如扁平风格演示页），而不是某个 CYLTabBarController 的 TabBar（其 `delegate`
 *      就是该控制器）。从这种 TabBar 向上查找会找到页面所在的 CYLTabBarController，以前会拿到那个控制器的 PlusButton：其 index
 *      属于另一个 TabBar，所以 `_buttons[plusButtonIndex]` 数组越界崩溃（从四个 Tab 的页面返回时 "index 2 beyond bounds [0 .. 1]"），
 *      而且共享的 PlusButton 会被移出控制器自己的 TabBar。
 */
- (BOOL)cyl_isStandaloneTabBar {
    if ([self.delegate isKindOfClass:[CYLTabBarController class]]) {
        return NO;
    }
    // [EN] Not inside any CYLTabBarController (not attached yet): keep the context lookup.
    // [CN] 不在任何 CYLTabBarController 中（尚未挂上）：保留按 context 查找。
    return [self cyl_owningTabBarController] != nil;
}

- (BOOL)hasPlusButton {
    // Bound to the CYLTabBarController that owns this tab bar, see `-[CYLTabBar hasPlusButton]`.
    // 绑定的是拥有本 TabBar 的 CYLTabBarController，见 `-[CYLTabBar hasPlusButton]`。
    if ([self cyl_isStandaloneTabBar]) {
        return NO;
    }
    return [CYLPlusButton plusButtonForOwner:self] != nil;
}

- (BOOL)hasPlusChildViewController {
    if ([self cyl_isStandaloneTabBar]) {
        return NO;
    }
    return [CYLPlusButton plusChildViewControllerForOwner:self] != nil;
}

@end
