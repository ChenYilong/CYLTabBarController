//
//  CYLPlusButton.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import <objc/runtime.h>
#import "CYLTabBarController.h"
#import "UIViewController+CYLTabBarControllerExtention.h"

/// [CN] See `-[CYLTabBar plusButtonIndex]`. 见 `-[CYLTabBar plusButtonIndex]`。
/// [EN] See `-[CYLTabBar plusButtonIndex]`.
@interface CYLTabBar (CYLPlusButtonLayout)
- (BOOL)cyl_showsVerticalBar;
@end

CGFloat CYLPlusButtonWidth = 0.0f;
CYLPlusButton<CYLPlusButtonSubclassing> *CYLExternPlusButton = nil;
UIViewController *CYLPlusChildViewController = nil;

#pragma mark - Registry: context -> plus button

/*!
 * [EN] What `+registerPlusButton` registers for one context. The globals above used to be the only plus button, so a
 *      second `+registerPlusButton` overwrote the first, and every tab bar controller then looked at the second one:
 *      with two contexts, `-hasPlusButton` was NO for the first tab bar controller (issues #414, #489).
 * [CN] `+registerPlusButton` 为一个 context 注册的内容。上面的全局变量曾经是唯一的 PlusButton，第二次 `+registerPlusButton`
 *      会覆盖第一次，之后所有 TabBarController 都看到第二个：有两个 context 时，第一个 TabBarController 的 `-hasPlusButton` 为 NO（issue #414、#489）。
 */
@interface CYLPlusButtonRegistration : NSObject
@property (nonatomic, copy) NSString *context;
@property (nonatomic, strong) CYLPlusButton<CYLPlusButtonSubclassing> *plusButton;
@property (nonatomic, strong, nullable) UIViewController *plusChildViewController;
@property (nonatomic, assign) CGFloat plusButtonWidth;
@property (nonatomic, assign) Class plusButtonClass;
/// The tab bar controller that uses `plusButton` / `plusChildViewController` themselves (weak: free again once it is gone).
@property (nonatomic, weak) CYLTabBarController *claimingTabBarController;
/// Plus buttons and plus child view controllers made for the other tab bar controllers of this context (weak).
@property (nonatomic, strong) NSHashTable *boundCopies;
@end

@implementation CYLPlusButtonRegistration
- (instancetype)init {
    if (self = [super init]) {
        _boundCopies = [NSHashTable weakObjectsHashTable];
    }
    return self;
}
@end

/*!
 * [EN] The plus button (and plus child view controller) ONE tab bar controller shows, kept on that controller. A view has
 *      one superview and a view controller one parent, so tab bar controllers that share a context cannot share the
 *      registered instances: the first one uses them, each other one gets its own from `+plusButton` /
 *      `+plusChildViewController` of the registered class.
 * [CN] **一个** TabBarController 展示的 PlusButton（及子控制器），保存在该控制器上。一个 View 只能有一个父视图，一个 ViewController
 *      只能有一个父控制器，所以共用 context 的多个 TabBarController 无法共用已注册的实例：第一个使用它们，其余每个用注册类的
 *      `+plusButton` / `+plusChildViewController` 各自创建一份。
 */
@interface CYLPlusButtonBinding : NSObject
@property (nonatomic, weak) CYLPlusButtonRegistration *registration;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, assign) Class plusButtonClass;
@property (nonatomic, strong) CYLPlusButton<CYLPlusButtonSubclassing> *plusButton;
@property (nonatomic, strong, nullable) UIViewController *plusChildViewController;
@end

@implementation CYLPlusButtonBinding
@end

static NSMutableDictionary<NSString *, CYLPlusButtonRegistration *> *CYLPlusButtonRegistry(void) {
    static NSMutableDictionary<NSString *, CYLPlusButtonRegistration *> *registry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registry = [NSMutableDictionary dictionary];
    });
    return registry;
}

/// The context of the plus button registered last, nil if it was removed. What the globals above describe.
static NSString *CYLPlusButtonLatestContext = nil;

static CYLPlusButtonRegistration *CYLPlusButtonRegistrationForContext(NSString *context) {
    if (!context) {
        return nil;
    }
    NSMutableDictionary *registry = CYLPlusButtonRegistry();
    @synchronized (registry) {
        return registry[context];
    }
}

/// Points the globals at `registration` (nil clears them).
static void CYLPlusButtonMirrorLegacyGlobals(CYLPlusButtonRegistration *registration) {
    CYLPlusButtonLatestContext = registration.context;
    CYLExternPlusButton = registration.plusButton;
    CYLPlusChildViewController = registration.plusChildViewController;
    CYLPlusButtonWidth = registration.plusButtonWidth;
}

@interface CYLPlusButton () 

@property (nonatomic, strong) UIImage *snapshot;

@property (nonatomic, weak) UIButton *contentView;
@property (nonatomic, weak) UIButton *selectedContentView;
@property (nonatomic, strong) UIImage *selectedContentImage;
@property (nonatomic, strong) UIImage *contentImage;
/// [EN] Issue #91: the overlay of `showsTouchableArea`, in the superview, under the plus button.
/// [CN] 可点击区域的调试覆盖层。
@property (nonatomic, strong, nullable) UIView *cyl_touchableAreaView;
/// [EN] Issue #152: the view controller selected on the last touch down, and whether there was one.
/// [CN] Issue #152：上次手指按下时选中的控制器，以及是否有按下。
@property (nonatomic, weak, nullable) UIViewController *cyl_selectedViewControllerAtTouchDown;
@property (nonatomic, assign) BOOL cyl_hasTouchDownForTabBarItemGesture;
- (void)cyl_tabBarItemGestureTouchDown;
- (void)cyl_tabBarItemGestureTouchUpInside;

@end

// FIX: issue #594 — implemented in CYLTabBarController.m. Declared here so a tap uses the same decision as
// `-setSelectedIndex:` (see `-plusChildViewControllerButtonClicked:`).
@interface CYLTabBarController (CYLPlusButtonSelection)
- (UIControl *)cyl_plusButtonControlIfSelectingPlusChildViewController:(UIViewController *)viewController;
// FIX: issue #152 — implemented in CYLTabBarController.m (`CYLTabBarController (CYLTabBarItemGesture)`).
- (void)cyl_recognizePlusButtonTap:(UIControl *)plusButton selectedViewControllerAtTouchDown:(nullable UIViewController *)selectedViewController;
#if CYL_FLATDESIGN_AVAILABLE
// FIX: issue #610 — implemented in CYLTabBarController.m.
- (void)cyl_flatDesignReportDidSelectControl:(UIControl *)control;
#endif
@end

/// Issue #636: the title moved into the tab item, and the image-to-title distance measured before (see
/// `-cyl_showsTitleInTabBarItem`).
static const void *CYLPlusButtonMovedTitleKey = &CYLPlusButtonMovedTitleKey;
static const void *CYLPlusButtonImageToTitleKey = &CYLPlusButtonImageToTitleKey;

@implementation CYLPlusButton
//@synthesize selected = _selected;
// [EN] Custom getter and setter: no automatic ivar.
// [CN] 自定义了 getter 与 setter，不会自动合成实例变量。
@synthesize touchableAreaScale = _touchableAreaScale;

/*!
 * [EN] VoiceOver: an icon-only plus button was read as its image's file name (or not at all). It is read as its title, or
 *      as "plus button" in the app's language when it has none; an `accessibilityLabel` set by the app still wins.
 * [CN] VoiceOver：仅有图标的 PlusButton 会被读成图片文件名（或不读）。现在朗读其标题；没有标题时朗读 App 语言的“加号按钮”；
 *      App 自行设置的 `accessibilityLabel` 仍然优先。
 */
- (NSString *)accessibilityLabel {
    NSString *label = objc_getAssociatedObject(self, @selector(accessibilityLabel));
    if (label.length > 0) {
        return label;
    }
    NSString *title = self.currentTitle ?: objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey) ?: self.titleLabel.text;
    return title.length > 0 ? title : CYLLocalizedString(@"加号按钮");
}

- (void)setAccessibilityLabel:(NSString *)accessibilityLabel {
    objc_setAssociatedObject(self, @selector(accessibilityLabel), accessibilityLabel, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
#pragma mark -
#pragma mark - public Methods

+ (instancetype)cyl_plusButtonWithImage:(UIImage *)image
                                  title:(NSString *)title
                          selectedTitle:(NSString *)selectedTitle
                     selectedTitleColor:(UIColor *)selectedTitleColor {
    CYLPlusButton *button = [[self alloc] init];
    [button setImage:image forState:UIControlStateNormal];
    // An explicit highlighted image is drawn as is, so the button does not darken on touch.
    [button setImage:image forState:UIControlStateHighlighted];
    // Issue #636: Liquid Glass with a title, the selected states too, so the selected plus button is not dimmed either.
    // 液态玻璃下有标题时（issue #636）选中状态也显式设置，选中后不会变暗。
    if ([CYLConstants isLiquidGlassActive] && title.length > 0) {
        [button setImage:image forState:UIControlStateSelected];
        [button setImage:image forState:(UIControlStateSelected | UIControlStateHighlighted)];
    }
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont systemFontOfSize:10];
    [button setTitle:CYLLocalizedString(title) forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [button setTitle:CYLLocalizedString(selectedTitle ?: title) forState:UIControlStateSelected];
    [button setTitleColor:selectedTitleColor ?: [UIColor blueColor] forState:UIControlStateSelected];
    objc_setAssociatedObject(button, @selector(cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [button sizeToFit];
    return button;
}

#pragma mark - Image rendering

/*!
 * Issue #636
 * [EN] With the title in the tab item (`-cyl_showsTitleInTabBarItem`), the plus button's icon is drawn as is
 *      (`UIImageRenderingModeAlwaysOriginal`): an image with the default rendering mode can be tinted, e.g. by the tab
 *      bar's tint or by Liquid Glass in the selected layer, so the stand-in seen through the lens and the plus button
 *      showed the same icon in different colors. Other plus buttons keep their images as set.
 * [CN] 标题由 TabBarItem 显示时（`-cyl_showsTitleInTabBarItem`），PlusButton 的图标按原图绘制（`UIImageRenderingModeAlwaysOriginal`）：
 *      默认渲染模式的图片可能被染色（如 TabBar 的 tint，或液态玻璃选中图层），导致放大镜中的替身与 PlusButton 的同一图标颜色不一致。
 *      其他 PlusButton 保持原样。
 */
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    if ([self cyl_showsTitleInTabBarItem]) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    [super setImage:image forState:state];
}

#pragma mark - Title alignment

/// `-layoutSubviews` of a subclass runs inside this call (and lays out the title after `super`), so the alignment comes
/// after every layout of the plus button, whatever the subclass does.
- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if (layer == self.layer) {
        [self cyl_alignTitleWithTabBarItemTitlesIfNeeded];
    }
}

- (BOOL)cyl_alignsTitleWithTabBarItemTitles {
    Class plusButtonClass = [self class];
    return [plusButtonClass respondsToSelector:@selector(alignsTitleWithTabBarItemTitles)] &&
           [(Class<CYLPlusButtonSubclassing>)plusButtonClass alignsTitleWithTabBarItemTitles];
}

- (void)cyl_setNeedsTitleAlignment {
    if ([self cyl_alignsTitleWithTabBarItemTitles]) {
        [self setNeedsLayout];
    }
}

/// The title colors are resolved for the tab titles' appearance: resolve them again when Dark Mode changes (before
/// iOS 17, where the reference title's trait changes are not observed).
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self cyl_setNeedsTitleAlignment];
        }
    }
}

/// Moving the plus button does not lay it out again, but moves its title off the tab titles' line: e.g. after the Flat
/// style's tab bar height changes, the plus button is re-centered on its placeholder tab after the tab bar's layout.
- (void)setCenter:(CGPoint)center {
    center = [self cyl_centerOfStandInForCenter:center];
    BOOL moved = !CGPointEqualToPoint(center, self.center);
    [super setCenter:center];
    if (moved) {
        [self cyl_setNeedsTitleAlignment];
        [self cyl_moveSelectedContentViewWithPlusButton];
    }
}

- (void)setFrame:(CGRect)frame {
    BOOL moved = !CGRectEqualToRect(frame, self.frame);
    [super setFrame:frame];
    if (moved) {
        [self cyl_setNeedsTitleAlignment];
        // A stand-in placed by frame (e.g. by the tab button layout tracker) goes back onto the plus button's position.
        CGPoint center = [self cyl_centerOfStandInForCenter:self.center];
        if (!CGPointEqualToPoint(center, self.center)) {
            [super setCenter:center];
        }
    }
}

/*!
 * FIX: issue #636
 * [EN] With a plus child view controller, Liquid Glass shows this plus button's stand-in (`-selectedContentView`) in the
 *      selected layer, through the lens. Its center must be the plus button's, converted from the other layer; the tab
 *      button layout tracker re-centered it on the tab icon after `CYLTabBarController` had placed it, so the lens showed
 *      the plus image off the plus button. Returns `center` for any other view.
 * [CN] 有 PlusButton 子控制器时，液态玻璃在选中图层（透过放大镜）显示 PlusButton 的替身（`-selectedContentView`）。替身中心必须与
 *      PlusButton 一致（在两个图层之间坐标转换）；`CYLTabBarController` 设置之后，Tab 按钮布局跟踪又会把它重新居中到 Tab 图标上，
 *      导致放大镜里的加号图片偏离 PlusButton。对其他视图原样返回 `center`。
 */
- (CGPoint)cyl_centerOfStandInForCenter:(CGPoint)center {
    if (!self.superview || ![CYLConstants isLiquidGlassActive] || ![self cyl_isInPlatterSelectedLayer]) {
        return center;
    }
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton || plusButton == self || !plusButton.superview || ![CYLPlusButton plusChildViewControllerForOwner:self]) {
        return center;
    }
    if (![plusButton cyl_showsTitleInTabBarItem] && ![plusButton cyl_hasNoTitleInLiquidGlass]) {
        return center;
    }
    return [self.superview convertPoint:plusButton.center fromView:plusButton.superview];
}

#pragma mark - Liquid Glass: the title in the tab item (issue #636)


/*!
 * FIX: issue #636
 * [EN] Liquid Glass, a plus button with a title, and `+alignsTitleWithTabBarItemTitles` returning YES; with or without
 *      its own view controller (without one, the tab item under the plus button is a placeholder's). A plus button without
 *      a title keeps covering the whole tab item. Laid over the whole tab item, the plus button's own title could not match the tab titles: Liquid
 *      Glass draws them in two layers (normal, and selected through the lens), through the glass, and the lens showed the
 *      plus button's stand-in (`-selectedContentView`) as a smaller copy. Instead, the title moves into the tab item under
 *      the plus button (`tabBarItem.title` of `-cyl_viewControllerOfTabBarItem`), which the system draws in both layers
 *      with the tab font, position and colors, and the plus button keeps only its image, in place of the tab icon.
 * [CN] 液态玻璃下，PlusButton 有标题，且 `+alignsTitleWithTabBarItemTitles` 返回 YES；有无子控制器均可（没有子控制器时，PlusButton
 *      下方是占位控制器的 TabBarItem）。没有标题的 PlusButton 仍覆盖整个 TabBarItem。PlusButton 覆盖整个 TabBarItem
 *      时，其自带标题无法与 Tab 标题一致：液态玻璃在两个图层（普通图层，以及透过放大镜显示的选中图层）中透过玻璃绘制 Tab 标题，放大镜中
 *      显示的是 PlusButton 的替身（`-selectedContentView`），会变成更小的副本。现在标题改由 PlusButton 下方的 TabBarItem 显示（
 *      `-cyl_viewControllerOfTabBarItem` 的 `tabBarItem.title`），系统在两个图层中以 Tab 的字体、位置和颜色绘制；PlusButton 只保留图片，替换 Tab 的图标。
 */
- (BOOL)cyl_showsTitleInTabBarItem {
    if (![CYLConstants isLiquidGlassActive] || ![self cyl_viewControllerOfTabBarItem]) {
        return NO;
    }
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    if (movedTitle.length == 0 && self.currentTitle.length == 0) {
        return NO;
    }
    UIView *systemTabBar = self.superview;
    while (systemTabBar && ![systemTabBar isKindOfClass:[UITabBar class]]) {
        systemTabBar = systemTabBar.superview;
    }
    return systemTabBar != nil;
}

/// The view controller of the tab item under the plus button: the plus button's own, else the placeholder.
/// PlusButton 下方 TabBarItem 的控制器：PlusButton 的子控制器，没有时为占位控制器。
- (UIViewController *)cyl_viewControllerOfTabBarItem {
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:self];
    if (plusChildViewController) {
        return plusChildViewController;
    }
    for (UIViewController *viewController in [self cyl_owningTabBarController].viewControllers) {
        if (viewController.cyl_isPlaceholder) {
            return viewController;
        }
    }
    return nil;
}

- (void)cyl_layOutForTitleInTabBarItem {
    UIImageView *imageView = self.imageView;
    if (!imageView.superview) {
        return;
    }
    if (!objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey)) {
        // Measured while the title is still laid out, so the image keeps the distance from the title it has in the Flat
        // style, where the whole plus button is centered on its tab item.
        UILabel *titleLabel = self.titleLabel;
        CGFloat imageToTitle = [titleLabel.superview convertPoint:titleLabel.center toView:self].y -
                               [imageView.superview convertPoint:imageView.center toView:self].y;
        NSString *title = self.currentTitle;
        objc_setAssociatedObject(self, CYLPlusButtonMovedTitleKey, title, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, CYLPlusButtonImageToTitleKey, @(imageToTitle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // The stand-in in the selected layer is a second plus button: it drops its title too, the tab item has it.
        [self cyl_updateTitleInTabBarItem];
        for (NSNumber *state in @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected),
                                  @(UIControlStateSelected | UIControlStateHighlighted)]) {
            UIControlState controlState = state.unsignedIntegerValue;
            [self setTitle:nil forState:controlState];
            // The images set before this mode applied are drawn as is too (see `-setImage:forState:`).
            UIImage *image = [self imageForState:controlState];
            if (image && image.renderingMode != UIImageRenderingModeAlwaysOriginal) {
                [self setImage:image forState:controlState];
            }
        }
        if (@available(iOS 15.0, *)) {
            UIButtonConfiguration *configuration = self.configuration;
            if (configuration) {
                configuration.title = nil;
                configuration.attributedTitle = nil;
                self.configuration = configuration;
            }
        }
        [self setNeedsLayout];
        [self.superview setNeedsLayout];
        return;
    }
    // The stand-in is placed from the plus button (`-cyl_moveSelectedContentViewWithPlusButton`).
    if ([self cyl_isInPlatterSelectedLayer]) {
        return;
    }
    // New view controllers bring a new placeholder, without the title. 重设子控制器后占位控制器是新的，没有标题。
    [self cyl_updateTitleInTabBarItem];
    // Recompute the center without the title (also done by the tab bar, `-cyl_alignedCenterForCenter:`).
    // 去掉标题后重新计算中心（TabBar 布局时也会计算）。
    if (!self.superview) {
        return;
    }
    CGPoint center = [self cyl_alignedCenterForCenter:self.center];
    if (fabs(center.x - self.center.x) >= 0.5 || fabs(center.y - self.center.y) >= 0.5) {
        self.center = center;
    }
}

/// Whether the tab bar shows its tab buttons in the iOS 27.1 vertical bar (unfolded iPhone Duo in landscape,
/// `allowsVerticalBar = YES`). 系统是否把 Tab 按钮放在 iOS 27.1 竖向栏中（iPhone Duo 展开横屏）。
- (BOOL)cyl_isInVerticalBar {
    UIView *tabBar = self.superview;
    return [tabBar isKindOfClass:[CYLTabBar class]] && [(CYLTabBar *)tabBar cyl_showsVerticalBar];
}

/// Issue #636: the moved title in the tab item under the plus button (a new placeholder doesn't have it yet).
/// 在 PlusButton 下方的 TabBarItem 中显示移过去的标题（新的占位控制器还没有标题）。
- (void)cyl_updateTitleInTabBarItem {
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    // The stand-in in the selected layer shares the tab item with the plus button. 选中图层中的替身与 PlusButton 共用 TabBarItem。
    if (movedTitle.length == 0 || [self cyl_isInPlatterSelectedLayer]) {
        return;
    }
    UITabBarItem *tabBarItem = [self cyl_viewControllerOfTabBarItem].tabBarItem;
    if (tabBarItem && ![tabBarItem.title isEqualToString:movedTitle]) {
        tabBarItem.title = movedTitle;
    }
}

/*!
 * FIX: issue #636
 * [EN] With the title in the tab item, the center (in the plus button's superview) that puts the image `imageToTitle`
 *      (measured before the title moved) above the tab titles' center line, and on the vertical center line of its own
 *      title, which the system lays out. Returns `center` in any other case, or while the titles are not laid out.
 * [CN] 标题由 TabBarItem 显示时，PlusButton 在其父视图中的中心：图片位于 Tab 标题中心线上方 `imageToTitle`（标题移走前测得）处，
 *      并与它自己的标题（由系统布局）竖向中心线对齐。其他情况，或标题尚未布局时，原样返回 `center`。
 */
- (CGPoint)cyl_alignedCenterForCenter:(CGPoint)center {
    UIView *container = self.superview;
    UIImageView *imageView = self.imageView;
    NSNumber *imageToTitle = objc_getAssociatedObject(self, CYLPlusButtonImageToTitleKey);
    if (!container || !imageView.superview || imageToTitle == nil || [self cyl_isInPlatterSelectedLayer] ||
        ![self cyl_showsTitleInTabBarItem]) {
        return center;
    }
    // The iOS 27.1 vertical bar: centered on its tab item, as without a title (`-[CYLTabBar plusButtonIndex]`).
    // iOS 27.1 竖向栏：与没有标题时一样，居中于它的 TabBarItem（见 `-[CYLTabBar plusButtonIndex]`）。
    if ([self cyl_isInVerticalBar]) {
        return center;
    }
    // The image's offset from the plus button's center. 图片中心相对 PlusButton 中心的偏移。
    CGPoint imageCenter = [imageView.superview convertPoint:imageView.center toView:self];
    CGFloat imageOffsetX = imageCenter.x - CGRectGetMidX(self.bounds);
    CGFloat imageOffsetY = imageCenter.y - CGRectGetMidY(self.bounds);
    // Its own title first (the tab item's), else the other tab titles, which share its center line.
    // 优先用它自己的标题（TabBarItem 的），没有时用其他 Tab 标题（中心线相同）。
    UILabel *ownTitleLabel = [self cyl_ownTitleLabelInTabBarItem];
    UILabel *itemTitleLabel = ownTitleLabel ?: [self cyl_tabBarItemTitleLabels].firstObject;
    if (itemTitleLabel) {
        [itemTitleLabel.superview layoutIfNeeded];
        CGFloat itemTitleCenterY = [itemTitleLabel.superview convertPoint:itemTitleLabel.center toView:container].y;
        center.y = itemTitleCenterY - imageToTitle.doubleValue - imageOffsetY;
    }
    if (ownTitleLabel) {
        center.x = [ownTitleLabel.superview convertPoint:ownTitleLabel.center toView:container].x - imageOffsetX;
    }
    return center;
}

/// The tab item's label that shows the plus button's title, in the normal layer. 普通图层中显示 PlusButton 标题的 TabBarItem 标签。
- (UILabel *)cyl_ownTitleLabelInTabBarItem {
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    UIView *systemTabBar = self.superview;
    while (systemTabBar && ![systemTabBar isKindOfClass:[UITabBar class]]) {
        systemTabBar = systemTabBar.superview;
    }
    if (movedTitle.length == 0 || !systemTabBar) {
        return nil;
    }
    NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:systemTabBar];
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        if (view == self || view.cyl_isPlatterSelectedContentView) {
            continue;
        }
        if ([view isKindOfClass:[UILabel class]] && [((UILabel *)view).text isEqualToString:movedTitle] && !view.hidden &&
            view.window) {
            return (UILabel *)view;
        }
        [views addObjectsFromArray:view.subviews];
    }
    return nil;
}

/*!
 * [EN] Liquid Glass shows the plus button's stand-in (`-selectedContentView`) in the selected layer, another view
 *      hierarchy: keep it on the plus button's position (converted between the two layers) whenever the plus button moves.
 * [CN] 液态玻璃在选中图层（另一个视图层级）中显示 PlusButton 的替身（`-selectedContentView`）：PlusButton 每次移动时，通过坐标转换让替身
 *      保持在 PlusButton 的位置。
 */
- (void)cyl_moveSelectedContentViewWithPlusButton {
    UIButton *selectedContentView = _selectedContentView;
    if (!selectedContentView.superview || !self.superview || selectedContentView == self) {
        return;
    }
    // Only for the layouts of this change: the title in the tab item, or no title.
    if (![self cyl_showsTitleInTabBarItem] && ![self cyl_hasNoTitleInLiquidGlass]) {
        return;
    }
    CGPoint center = [selectedContentView.superview convertPoint:self.center fromView:self.superview];
    if (!CGPointEqualToPoint(center, selectedContentView.center)) {
        selectedContentView.center = center;
    }
}

/// See `+alignsTitleWithTabBarItemTitles`.
- (void)cyl_alignTitleWithTabBarItemTitlesIfNeeded {
    if (![self cyl_alignsTitleWithTabBarItemTitles]) {
        return;
    }
    if ([self cyl_showsTitleInTabBarItem]) {
        [self cyl_layOutForTitleInTabBarItem];
        return;
    }
    if (self.currentTitle.length == 0 && self.currentAttributedTitle.length == 0) {
        return;
    }
    NSArray<UILabel *> *itemTitleLabels = [self cyl_tabBarItemTitleLabels];
    UILabel *itemTitleLabel = itemTitleLabels.firstObject;
    if (!itemTitleLabel) {
        return;
    }
    [self cyl_observeAppearanceOfTabBarItemTitleLabel:itemTitleLabel];
    UIColor *normalColor = nil;
    UIColor *selectedColor = nil;
    [self cyl_getTitleColorsOfTabBarItemTitleLabels:itemTitleLabels normalColor:&normalColor selectedColor:&selectedColor];
    if ([self cyl_applyTitleFont:itemTitleLabel.font normalColor:normalColor selectedColor:selectedColor]) {
        // The title's size changes with the font: align it after the next layout.
        return;
    }
    UILabel *titleLabel = self.titleLabel;
    if (!titleLabel.superview || ![self cyl_isVisibleView:titleLabel upTo:self]) {
        return;
    }
    // The plus button can be laid out before the tab button whose title it follows (e.g. right after the Flat style's
    // tab bar height changed): finish that layout first, so the title is read where it ends up.
    [itemTitleLabel.superview layoutIfNeeded];
    // Different hierarchies: convert the item title's center into the coordinate space the title label is laid out in.
    CGPoint itemTitleCenter = [itemTitleLabel.superview convertPoint:itemTitleLabel.center toView:titleLabel.superview];
    CGPoint titleCenter = titleLabel.center;
    if (fabs(titleCenter.y - itemTitleCenter.y) < 0.5) {
        return;
    }
    titleLabel.center = CGPointMake(titleCenter.x, itemTitleCenter.y);
    // With UIButtonConfiguration the title sits in a container that clips to the button. A tall tab bar (e.g. the Flat
    // style's adjustable height) can need the title below the button's bottom edge: let those containers show it.
    for (UIView *view = titleLabel.superview; view && view != self; view = view.superview) {
        CGRect titleFrame = [titleLabel.superview convertRect:titleLabel.frame toView:view];
        if (view.clipsToBounds && !CGRectContainsRect(view.bounds, titleFrame)) {
            view.clipsToBounds = NO;
        }
    }
}

/*!
 * [EN] Gives the title the tab item titles' font and colors: `normalColor` when the plus button is not selected,
 *      `selectedColor` when it is. A nil color keeps the one applied before (e.g. no tab title is selected while the plus
 *      button's own view controller is). Works for a button with or without `UIButtonConfiguration`, whose title
 *      attributes come from `titleTextAttributesTransformer` (`-setTitleColor:forState:` does not apply there).
 *      Returns YES when something changed, so the title is aligned on the next layout, with its new size.
 * [CN] 让标题使用 TabBarItem 标题的字体和颜色：未选中时为 `normalColor`，选中时为 `selectedColor`。颜色为 nil 时保留之前的颜色
 *      （例如 PlusButton 自身的子控制器被选中时，没有选中的 Tab 标题）。同时支持使用与未使用 `UIButtonConfiguration` 的按钮
 *      （前者的标题属性来自 `titleTextAttributesTransformer`，`-setTitleColor:forState:` 不生效）。有变化时返回 YES，
 *      以便下次布局时按新的尺寸对齐。
 */
- (BOOL)cyl_applyTitleFont:(UIFont *)font normalColor:(UIColor *)normalColor selectedColor:(UIColor *)selectedColor {
    static const void *CYLPlusButtonTitleStyleKey = &CYLPlusButtonTitleStyleKey;
    NSDictionary *applied = objc_getAssociatedObject(self, CYLPlusButtonTitleStyleKey);
    UIFont *titleFont = font ?: applied[@"font"];
    UIColor *selectedTitleColor = selectedColor ?: applied[@"selected"] ?: normalColor ?: applied[@"normal"];
    // Liquid Glass shows the selected plus button through the lens with a copy of it in the selected layer
    // (`-selectedContentView`, highlighted rather than selected), like the tabs' selected-layer titles: always selected.
    UIColor *titleColor = [self cyl_isInPlatterSelectedLayer] ? selectedTitleColor : (normalColor ?: applied[@"normal"]);
    if (!titleFont || !titleColor || !selectedTitleColor) {
        return NO;
    }
    NSDictionary *style = @{@"font": titleFont, @"normal": titleColor, @"selected": selectedTitleColor};
    if ([style isEqualToDictionary:applied]) {
        return NO;
    }
    objc_setAssociatedObject(self, CYLPlusButtonTitleStyleKey, style, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = self.configuration;
        if (configuration) {
            __weak typeof(self) weakSelf = self;
            configuration.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *attributes) {
                NSMutableDictionary<NSAttributedStringKey, id> *titleAttributes = [attributes mutableCopy];
                titleAttributes[NSFontAttributeName] = titleFont;
                titleAttributes[NSForegroundColorAttributeName] = weakSelf.isSelected ? selectedTitleColor : titleColor;
                return [titleAttributes copy];
            };
            self.configuration = configuration;
            return YES;
        }
    }
    self.titleLabel.font = titleFont;
    [self setTitleColor:titleColor forState:UIControlStateNormal];
    [self setTitleColor:selectedTitleColor forState:UIControlStateSelected];
    [self setTitleColor:selectedTitleColor forState:(UIControlStateSelected | UIControlStateHighlighted)];
    [self setNeedsLayout];
    return YES;
}

/// Every visible, non-empty tab item title in the tab bar the plus button is in, in view order; empty when there is none.
- (NSArray<UILabel *> *)cyl_tabBarItemTitleLabels {
    Class flatDesignTabBarClass = NSClassFromString(@"CYLFlatDesignTabBar");
    UIView *tabBar = self.superview;
    while (tabBar && ![tabBar isKindOfClass:[UITabBar class]] &&
           !(flatDesignTabBarClass && [tabBar isKindOfClass:flatDesignTabBarClass])) {
        tabBar = tabBar.superview;
    }
    NSMutableArray<UILabel *> *labels = [NSMutableArray array];
    if (tabBar) {
        [self cyl_collectTabBarItemTitleLabelsInView:tabBar tabBar:tabBar into:labels];
    }
    return labels;
}

- (void)cyl_collectTabBarItemTitleLabelsInView:(UIView *)view tabBar:(UIView *)tabBar into:(NSMutableArray<UILabel *> *)labels {
    for (UIView *subview in view.subviews) {
        if (subview == self || subview.hidden || subview.alpha < 0.01) {
            continue;
        }
        if ([subview isKindOfClass:[UILabel class]] && [self cyl_isTabBarItemTitleLabel:(UILabel *)subview tabBar:tabBar]) {
            [labels addObject:(UILabel *)subview];
            continue;
        }
        [self cyl_collectTabBarItemTitleLabelsInView:subview tabBar:tabBar into:labels];
    }
}

/*!
 * [EN] The colors the tab item titles are shown in.
 *      - Liquid Glass: every tab has a title in the normal layer, drawn through the glass in the system label color
 *        whatever its `textColor` says, and one in the selected layer (`-cyl_isPlatterSelectedControl`) in the selected
 *        color, shown through the lens.
 *      - The system tab bar and the Flat style: titles are drawn in their `textColor`. The unselected tabs are the
 *        majority, so their color is the most common one; the selected color is the one of a title whose tab button is
 *        selected, else any other color.
 *      A color that cannot be told stays nil.
 * [CN] TabBarItem 标题实际显示的颜色。液态玻璃：每个 Tab 在普通层有一个标题，透过玻璃以系统 label 颜色绘制（与其 `textColor` 无关），
 *      在选中层（`-cyl_isPlatterSelectedControl`）还有一个使用选中颜色的标题，透过放大镜显示。系统 TabBar 与扁平样式：按 `textColor`
 *      绘制；未选中的 Tab 占多数，出现最多的颜色即未选中颜色；选中颜色取所在按钮为选中状态的标题颜色，否则取其他颜色。无法判断的颜色为 nil。
 */
- (void)cyl_getTitleColorsOfTabBarItemTitleLabels:(NSArray<UILabel *> *)labels
                                      normalColor:(UIColor **)normalColor
                                    selectedColor:(UIColor **)selectedColor {
    UIView *systemTabBar = self.superview;
    while (systemTabBar && ![systemTabBar isKindOfClass:[UITabBar class]]) {
        systemTabBar = systemTabBar.superview;
    }
    if ([CYLConstants isLiquidGlassActive] && systemTabBar) {
        if (@available(iOS 13.0, *)) {
            *normalColor = [self cyl_color:[UIColor labelColor] resolvedForLabel:labels.firstObject];
        }
        for (UILabel *label in labels) {
            if ([[self cyl_tabButtonOfTabBarItemTitleLabel:label] cyl_isPlatterSelectedControl]) {
                *selectedColor = [self cyl_shownTextColorOfLabel:label];
                break;
            }
        }
        return;
    }
    NSCountedSet<UIColor *> *colors = [NSCountedSet set];
    NSMapTable<UILabel *, UIColor *> *shownColors = [NSMapTable strongToStrongObjectsMapTable];
    for (UILabel *label in labels) {
        UIColor *color = [self cyl_shownTextColorOfLabel:label];
        if (color) {
            [colors addObject:color];
            [shownColors setObject:color forKey:label];
        }
    }
    UIColor *mostCommonColor = nil;
    for (UIColor *color in colors) {
        if (!mostCommonColor || [colors countForObject:color] > [colors countForObject:mostCommonColor]) {
            mostCommonColor = color;
        }
    }
    *normalColor = mostCommonColor;
    for (UILabel *label in labels) {
        UIColor *color = [shownColors objectForKey:label];
        if (color && ![color isEqual:mostCommonColor] &&
            (!*selectedColor || [self cyl_tabButtonOfTabBarItemTitleLabel:label].isSelected)) {
            *selectedColor = color;
        }
    }
}

/// The label's text color as it is drawn. A tint color placeholder (a label colored with the tint) resolves against the
/// view that draws it, so on the plus button it would become the plus button's tint: use the label's tint instead.
- (UIColor *)cyl_shownTextColorOfLabel:(UILabel *)label {
    UIColor *color = label.textColor;
    if (color && [NSStringFromClass([color class]) containsString:@"TintColor"]) {
        color = label.tintColor;
    }
    return [self cyl_color:color resolvedForLabel:label];
}

/// The color as the label shows it: Liquid Glass gives the tab content its own light or dark appearance, depending on
/// what is behind the glass, while the plus button outside the glass keeps the app's.
- (UIColor *)cyl_color:(UIColor *)color resolvedForLabel:(UILabel *)label {
    if (@available(iOS 13.0, *)) {
        return [color resolvedColorWithTraitCollection:label.traitCollection];
    }
    return color;
}

/// Liquid Glass switches the tab content between light and dark with what is behind the glass, without laying the plus
/// button out: follow the reference title's appearance (iOS 17+, which Liquid Glass needs anyway).
- (void)cyl_observeAppearanceOfTabBarItemTitleLabel:(UILabel *)label {
    if (@available(iOS 17.0, *)) {
        static const void *CYLObservedTitleLabelKey = &CYLObservedTitleLabelKey;
        if (objc_getAssociatedObject(self, CYLObservedTitleLabelKey) == label) {
            return;
        }
        objc_setAssociatedObject(self, CYLObservedTitleLabelKey, label, OBJC_ASSOCIATION_ASSIGN);
        __weak typeof(self) weakSelf = self;
        [label registerForTraitChanges:@[[UITraitUserInterfaceStyle class]]
                           withHandler:^(__kindof id<UITraitEnvironment> traitEnvironment, UITraitCollection *previousCollection) {
            [weakSelf setNeedsLayout];
        }];
    }
}

/// Whether the view is in Liquid Glass's selected layer (shown through the lens), at any depth.
- (BOOL)cyl_isInPlatterSelectedLayer {
    for (UIView *view = self.superview; view; view = view.superview) {
        if ([view cyl_isPlatterSelectedContentView]) {
            return YES;
        }
    }
    return NO;
}

/// The tab button a tab item title belongs to.
- (UIControl *)cyl_tabButtonOfTabBarItemTitleLabel:(UILabel *)label {
    return [label.superview cyl_nearestControlBelowView:nil];
}

/// A tab item's title: has text, sits in a tab button that is not a placeholder, and is not a badge.
- (BOOL)cyl_isTabBarItemTitleLabel:(UILabel *)label tabBar:(UIView *)tabBar {
    if (label.text.length == 0 || label == (UILabel *)label.superview.cyl_badge) {
        return NO;
    }
    UIControl *tabButton = [label.superview cyl_nearestControlBelowView:tabBar];
    return tabButton && !tabButton.cyl_isPlaceholder && ![CYLPlusButton isPlusButtonView:tabButton];
}

- (BOOL)cyl_isVisibleView:(UIView *)view upTo:(UIView *)ancestor {
    for (UIView *current = view; current && current != ancestor; current = current.superview) {
        if (current.hidden || current.alpha < 0.01) {
            return NO;
        }
    }
    return YES;
}

/// The image-above-title layout of `+cyl_plusButtonWithImage:…`; other plus buttons keep UIButton's layout.
- (void)layoutSubviews {
    [super layoutSubviews];
    // [EN] Issue #91: keep the touchable area overlay on the button.
    // [CN] 保持可点击区域覆盖层与按钮一致。
    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
    }
    if (![objc_getAssociatedObject(self, @selector(cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:)) boolValue]) {
        return;
    }
    CGFloat imageWidth = CGRectGetWidth(self.bounds) * 0.7;
    CGFloat imageHeight = imageWidth * 0.9;
    CGFloat centerX = CGRectGetWidth(self.bounds) * 0.5;
    CGFloat lineHeight = self.titleLabel.font.lineHeight;
    CGFloat verticalMargin = (CGRectGetHeight(self.bounds) - lineHeight - imageHeight) * 0.5;
    self.imageView.bounds = CGRectMake(0, 0, imageWidth, imageHeight);
    self.imageView.center = CGPointMake(centerX, verticalMargin + imageHeight * 0.5);
    self.titleLabel.bounds = CGRectMake(0, 0, CGRectGetWidth(self.bounds), lineHeight);
    self.titleLabel.center = CGPointMake(centerX, imageHeight + verticalMargin * 2 + lineHeight * 0.5 + 10);
}

+ (void)registerPlusButton {
    if (![self conformsToProtocol:@protocol(CYLPlusButtonSubclassing)]) {
        return;
    }
    Class<CYLPlusButtonSubclassing> class = self;
    CYLPlusButtonRegistration *registration = [[CYLPlusButtonRegistration alloc] init];
    registration.context = [self matchedTabBarContext];
    registration.plusButtonClass = self;
    if ([[self class] respondsToSelector:@selector(plusChildViewController)]) {
        UIViewController *plusChildViewController = [class plusChildViewController];
        registration.plusChildViewController = plusChildViewController;
        [plusChildViewController cyl_setContext:registration.context];
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        registration.plusButton = plusButton;
        registration.plusButtonWidth = plusButton.frame.size.width;
        [[self class] addSelectViewControllerTarget:plusButton];
        // [CN] 液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        // [EN] With the Liquid Glass effect, custom tap effects are not allowed; only the system glass effect can be used.
        if ([CYLConstants isLiquidGlassActive]) {
            //            plusButton.cyl_userInteractionDisabled = YES;
        }
        if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
            // Not stored per context: it is `+indexOfPlusButtonInTabBar` of the class, which `+indexForTabbarItemsCount:` returns.
            CYLPlusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
        } else {
#if defined(DEBUG) || defined(BETA)
            NSAssert(NO, CYLLocalizedString(@"[DEBUG INFO] 如果你想使用 PlusChildViewController 样式，你必须同时在你自定义的 plusButton 中实现 `+indexOfPlusButtonInTabBar`，来指定 plusButton 的位置。"));
#endif
        }
    } else {
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        registration.plusButton = plusButton;
        registration.plusButtonWidth = plusButton.frame.size.width;
    }
    NSMutableDictionary *registry = CYLPlusButtonRegistry();
    @synchronized (registry) {
        registry[registration.context] = registration;
        CYLPlusButtonMirrorLegacyGlobals(registration);
    }
}

+ (void)removePlusButton {
    NSString *context = [self matchedTabBarContext];
    // `CYLPlusButton` itself has no `+tabBarContext`: as before, remove the plus button the globals point at.
    if (!CYLPlusButtonRegistrationForContext(context) && self == [CYLPlusButton class] && CYLPlusButtonLatestContext) {
        context = CYLPlusButtonLatestContext;
    }
    [self removePlusButtonForTabBarContext:context];
}

+ (void)removePlusButtonForTabBarContext:(NSString *)tabBarContext {
    CYLPlusButtonRegistration *registration = nil;
    NSMutableDictionary *registry = CYLPlusButtonRegistry();
    @synchronized (registry) {
        registration = tabBarContext ? registry[tabBarContext] : nil;
        if (!registration) {
            return;
        }
        [registry removeObjectForKey:tabBarContext];
        if ([CYLPlusButtonLatestContext isEqualToString:tabBarContext]) {
            CYLPlusButtonMirrorLegacyGlobals(nil);
        }
    }
    // The registered instances, and the copies made for the other tab bar controllers of this context.
    NSMutableArray *removed = [NSMutableArray arrayWithArray:registration.boundCopies.allObjects];
    if (registration.plusButton) {
        [removed addObject:registration.plusButton];
    }
    if (registration.plusChildViewController) {
        [removed addObject:registration.plusChildViewController];
    }
    for (id object in removed) {
        if ([object isKindOfClass:[UIView class]]) {
            [(UIView *)object removeFromSuperview];
            continue;
        }
        UIViewController *plusChildViewController = object;
        [plusChildViewController willMoveToParentViewController:nil];
        [plusChildViewController.view removeFromSuperview];
        [plusChildViewController removeFromParentViewController];
        [plusChildViewController cyl_setPlusViewControllerEverAdded:NO];
    }
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
+ (void)registerSubclass {
    [self registerPlusButton];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP
- (void)plusChildViewControllerButtonClicked:(UIButton<CYLPlusButtonSubclassing> *)sender {
    BOOL notNeedConfigureSelectionStatus = [[self class] respondsToSelector:@selector(shouldSelectPlusChildViewController)] && ![[self class] shouldSelectPlusChildViewController];
    if (notNeedConfigureSelectionStatus) {
        return;
    }
    // The plus button and its child view controller are bound to a tab bar controller by context: the one the tapped
    // button is in, else the most recently active one with that context. Any style, system or flat design (#650). It
    // used `-cyl_tabBarController`, which only knows the system styles and fell back to the root controller.
    // PlusButton 及其子控制器通过 context 绑定到 TabBarController：被点击的按钮所在的那个，否则取该 context 最近活跃的那个。
    // 任意样式，系统或扁平（#650）。原先用的 `-cyl_tabBarController` 只查系统样式，找不到时回退到根控制器。
    NSString *context = [CYLPlusButton tabBarContextForOwner:sender];
    CYLTabBarController *tabBarController = [sender cyl_owningTabBarController];
    if (![tabBarController.cyl_context isEqualToString:context]) {
        tabBarController = [CYLTabBarController cyl_tabBarControllerForContext:context];
    }
    // That controller's own plus child view controller (tab bar controllers sharing a context each have one).
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:tabBarController];
    NSInteger index = plusChildViewController ? [tabBarController.viewControllers indexOfObject:plusChildViewController] : NSNotFound;
    if (!tabBarController || NSNotFound == index) {
        return;
    }
#if CYL_FLATDESIGN_AVAILABLE
    if ([tabBarController.cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        // FIX: issue #610 reported through `tabBarController:didSelectControl:` like the other styles, before selecting
        // (as for the tab buttons). 与其他样式一样回调 `tabBarController:didSelectControl:`，先回调再选中（与 Tab 按钮一致）。
        [tabBarController cyl_flatDesignReportDidSelectControl:sender];
        [(CYLFlatDesignTabBar *)tabBarController.cyl_tabBar setSelectedIndex:index];
        [tabBarController setSelectedViewController:plusChildViewController];
        return;
    }
#endif
    [tabBarController setSelectedIndex:index];
    // FIX: issue #594 — when the tab bar controller has a plus button with a child view controller,
    // `-setSelectedIndex:` (the path also used for selection in code) already selected the plus button and reported
    // it through `tabBarController:didSelectControl:`. Calling `-tabChangedToControl:` again would report every tap
    // twice. Otherwise keep the previous behavior.
    BOOL selectedBySetSelectedIndex =
        ([tabBarController cyl_plusButtonControlIfSelectingPlusChildViewController:plusChildViewController] == sender);
    if (!selectedBySetSelectedIndex && NO == sender.cyl_userInteractionDisabled) {
        sender.selected = YES;
        [tabBarController tabChangedToControl:sender];
    }
}

#pragma mark -
#pragma mark - Private Methods

//- (void)setSelected:(BOOL)selected {
//    _selected = selected;
//    if (_selected) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
//    }
//}

+ (void)addSelectViewControllerTarget:(UIButton<CYLPlusButtonSubclassing> *)plusButton {
    id target = self;
    NSArray<NSString *> *selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    if (selectorNamesArray.count == 0) {
        target = plusButton;
        selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    }
    // [EN] FIX: issue #152 — keep the tab bar item gesture action (`-cyl_tabBarItemGestureTouchUpInside`).
    // [CN] 保留 TabBarItem 手势的事件（`-cyl_tabBarItemGestureTouchUpInside`）。
    NSString *gestureAction = NSStringFromSelector(@selector(cyl_tabBarItemGestureTouchUpInside));
    [selectorNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:gestureAction]) {
            return;
        }
        SEL selector =  NSSelectorFromString(obj);
        [plusButton removeTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    }];
    [plusButton addTarget:plusButton action:@selector(plusChildViewControllerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (BOOL)isLayoutCentered {
    if ((0 == [self constantOfPlusButtonCenterYOffsetForTabBarHeight]) && (0.5 == [self defaultMultiplierOfTabBarHeight])) {
        return YES;
    }
    return NO;
}

- (CGFloat)defaultMultiplierOfTabBarHeight {
    return [self multiplierOfTabBarHeight:self.cyl_tabBarController.tabBar.cyl_boundsSize.height plusButtonHeight:self.frame.size.height];
}

- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
    return [self multiplierOfTabBarHeight:tabBarHeight plusButtonHeight:self.frame.size.height];
}

/// Liquid Glass and no title: the plus button replaces the whole tab item. 液态玻璃下没有标题：PlusButton 替换整个 TabBarItem。
- (BOOL)cyl_hasNoTitleInLiquidGlass {
    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    return movedTitle.length == 0 && self.currentTitle.length == 0 && self.currentAttributedTitle.length == 0;
}

- (BOOL)cyl_appliesCenterYOffsetWithoutTitle {
    return [objc_getAssociatedObject(self, @selector(cyl_appliesCenterYOffsetWithoutTitle)) boolValue];
}

- (void)cyl_setAppliesCenterYOffsetWithoutTitle:(BOOL)appliesCenterYOffsetWithoutTitle {
    objc_setAssociatedObject(self, @selector(cyl_appliesCenterYOffsetWithoutTitle), @(appliesCenterYOffsetWithoutTitle),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.superview setNeedsLayout];
}

/// Centered on the tab item, the height methods ignored (see `cyl_appliesCenterYOffsetWithoutTitle`).
/// 居中于 TabBarItem，忽略高度相关的代理方法（见 `cyl_appliesCenterYOffsetWithoutTitle`）。
- (BOOL)cyl_isCenteredWithoutTitle {
    return [self cyl_hasNoTitleInLiquidGlass] && !self.cyl_appliesCenterYOffsetWithoutTitle;
}

- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight plusButtonHeight:(CGFloat)plusButtonHeight {
    CGFloat multiplierOfTabBarHeight;
    if ([self cyl_isCenteredWithoutTitle]) {
        multiplierOfTabBarHeight = 0.5;
    }
    else if ([[self class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
        multiplierOfTabBarHeight = [[self class] multiplierOfTabBarHeight:tabBarHeight];
    }
    
    CYL_DEPRECATED_DECLARATIONS_PUSH
    else if ([[self class] respondsToSelector:@selector(multiplerInCenterY)]) {
        multiplierOfTabBarHeight = [[self class] multiplerInCenterY];
    }
    CYL_DEPRECATED_DECLARATIONS_POP
    
    else if (![CYLConstants isLiquidGlassActive]) {
        // The system tab bar (iOS 25 and earlier, and UI compatibility mode on iOS 26): center the plus button on the tab
        // items, the way the Flat style places it. The branch below lifts a plus button taller than the items so that
        // its bottom meets theirs, which put it 16.5 pt higher than in the Flat style with the same plus button.
        // `cyl_boundsSize` of the system tab bar already excludes the bottom safe area, so 0.5 is the items' center.
        multiplierOfTabBarHeight = 0.5;
    }
    else {
        CGFloat heightDifference = plusButtonHeight - tabBarHeight;
        if (heightDifference < 0) {
            multiplierOfTabBarHeight = 0.5;
        } else {
            CGPoint center = CGPointMake(tabBarHeight* 0.5, tabBarHeight * 0.5);
            center.y = center.y - heightDifference * 0.5;
            multiplierOfTabBarHeight = center.y / tabBarHeight;
        }
    }
    return multiplierOfTabBarHeight;
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight {
    return [self constantOfPlusButtonCenterYOffsetForTabBarHeight:self.cyl_tabBarController.tabBar.cyl_boundsSize.height];
}

- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    CGFloat constantOfPlusButtonCenterYOffset = 0.f;
    if ([self cyl_isCenteredWithoutTitle]) {
        return constantOfPlusButtonCenterYOffset;
    }
    if ([[self class] respondsToSelector:@selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:)]) {
        constantOfPlusButtonCenterYOffset = [[self class] constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    }
    return constantOfPlusButtonCenterYOffset;
}

/**
 * [CN] 按钮选中状态下点击先显示normal状态的颜色，松开时再回到selected状态下颜色。
 *  重写此方法即不会出现上述情况，与 UITabBarButton 相似
 * [EN] When the button is selected, a tap first shows the normal-state color, then returns to the selected-state color
 *      on release. Overriding this method avoids that, similar to UITabBarButton.
 */
//- (void)setHighlighted:(BOOL)highlighted {}

- (CGRect)touchableRect {
    CGRect rect = self.frame;
    CGFloat scale = MAX(_touchableAreaScale, 1.0);   // 0 (never set) and values below 1 count as 1
    if (scale > 1.0) {
        rect = CGRectInset(rect, -CGRectGetWidth(rect) * (scale - 1.0) / 2.0, -CGRectGetHeight(rect) * (scale - 1.0) / 2.0);
    }
    UIEdgeInsets outsets = _touchableAreaOutsets;
    return UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(-outsets.top, -outsets.left, -outsets.bottom, -outsets.right));
}

/// [EN] YES when `view`, or a superview of it below `plusButton`, takes touches itself (issue #202).
/// [CN] `view` 或它在 `plusButton` 之下的某个父视图自己接收触摸时为 YES（issue #202）。
static BOOL CYLPlusButtonSubviewTakesTouches(UIView *view, UIView *plusButton) {
    for (UIView *current = view; current && current != plusButton; current = current.superview) {
        if ([current isKindOfClass:[UIControl class]] && ((UIControl *)current).enabled) {
            return YES;
        }
        for (UIGestureRecognizer *gestureRecognizer in current.gestureRecognizers) {
            if (gestureRecognizer.enabled) {
                return YES;
            }
        }
    }
    return NO;
}

- (UIView *)hitTestInteractiveSubview:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha < 0.01 || !self.userInteractionEnabled) {
        return nil;
    }
    // [EN] Front to back. Each subview hit-tests in its own bounds, so a subview outside the plus button is found too.
    // [CN] 从前往后。每个子视图在自身范围内做 hitTest，因此超出 PlusButton 的子视图也能命中。
    for (UIView *subview in self.subviews.reverseObjectEnumerator) {
        UIView *hitView = [subview hitTest:[subview convertPoint:point fromView:self] withEvent:event];
        if (hitView && CYLPlusButtonSubviewTakesTouches(hitView, self)) {
            return hitView;
        }
    }
    return nil;
}

- (CGRect)touchableRectInView:(UIView *)view {
    CGRect rect = [self touchableRect];
    UIView *superview = self.superview;
    if (!view || !superview || superview == view) {
        return rect;
    }
    return [superview convertRect:rect toView:view];
}

#pragma mark - Touchable area (issue #91)

/*!
 * [EN] The whole touchable area counts as inside the button. The tab bars return the plus button from their hit test
 *      for a point in that area, but UIControl only sends `UIControlEventTouchUpInside` when the touch ends inside
 *      `-pointInside:withEvent:`; without this, a tap in the extra area ended as `TouchUpOutside` and did nothing.
 * [CN] 整个可点击区域都算作按钮内部。TabBar 的 hitTest 会把该区域内的点交给 PlusButton，但 UIControl 只有在触摸结束于
 *      `-pointInside:withEvent:` 之内时才发送 `UIControlEventTouchUpInside`；否则点在扩展区域内会变成 `TouchUpOutside`，不会触发点击。
 */
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([super pointInside:point withEvent:event]) {
        return YES;
    }
    UIView *superview = self.superview;
    if (!superview) {
        return NO;
    }
    CGRect touchableRect = [self convertRect:[self touchableRect] fromView:superview];
    return CGRectContainsPoint(touchableRect, point);
}

- (void)setTouchableAreaOutsets:(UIEdgeInsets)touchableAreaOutsets {
    _touchableAreaOutsets = touchableAreaOutsets;
    [self cyl_updateTouchableAreaView];
}

- (void)setTouchableAreaScale:(CGFloat)touchableAreaScale {
    _touchableAreaScale = MAX(touchableAreaScale, 1.0);
    [self cyl_updateTouchableAreaView];
}

- (CGFloat)touchableAreaScale {
    return MAX(_touchableAreaScale, 1.0);
}

- (void)setShowsTouchableArea:(BOOL)showsTouchableArea {
    _showsTouchableArea = showsTouchableArea;
    [self cyl_updateTouchableAreaView];
}

- (void)setTouchableAreaColor:(UIColor *)touchableAreaColor {
    _touchableAreaColor = touchableAreaColor;
    [self cyl_updateTouchableAreaView];
}

/// [EN] Adds, moves or removes the overlay so it always covers `-touchableRect`.
/// [CN] 添加、移动或移除覆盖层，使其始终覆盖可点击区域。
- (void)cyl_updateTouchableAreaView {
    UIView *superview = self.superview;
    if (!_showsTouchableArea || !superview) {
        [self.cyl_touchableAreaView removeFromSuperview];
        self.cyl_touchableAreaView = nil;
        return;
    }
    UIView *areaView = self.cyl_touchableAreaView;
    if (!areaView) {
        areaView = [[UIView alloc] init];
        areaView.userInteractionEnabled = NO;   // never takes a touch 不响应点击
        areaView.layer.borderWidth = 1.0;
        areaView.accessibilityElementsHidden = YES;
        self.cyl_touchableAreaView = areaView;
    }
    UIColor *color = _touchableAreaColor ?: [[UIColor systemRedColor] colorWithAlphaComponent:0.3];
    areaView.backgroundColor = color;
    areaView.layer.borderColor = [color colorWithAlphaComponent:1.0].CGColor;
    if (areaView.superview != superview) {
        [areaView removeFromSuperview];
        [superview insertSubview:areaView belowSubview:self];
    }
    areaView.frame = [self touchableRect];
    areaView.hidden = self.hidden || self.alpha < 0.01;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self cyl_updateTouchableAreaView];
    [self cyl_addTabBarItemGestureTargetsIfNeeded];
}

#pragma mark - Tab bar item gestures (issue #152)

/*!
 * [EN] Issue #152: the plus button reports its taps for the tab bar item gestures itself, the same way in every style.
 *      The actions only record and forward; they change nothing else, and are added once.
 * [CN] Issue #152：PlusButton 自己为 TabBarItem 手势上报点击，所有样式方式一致。这些事件只记录与转发，不改变其他行为，只添加一次。
 */
- (void)cyl_addTabBarItemGestureTargetsIfNeeded {
    NSString *touchUpInside = NSStringFromSelector(@selector(cyl_tabBarItemGestureTouchUpInside));
    if ([[self actionsForTarget:self forControlEvent:UIControlEventTouchUpInside] containsObject:touchUpInside]) {
        return;
    }
    [self addTarget:self action:@selector(cyl_tabBarItemGestureTouchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(cyl_tabBarItemGestureTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
}

- (void)cyl_tabBarItemGestureTouchDown {
    self.cyl_selectedViewControllerAtTouchDown = [self cyl_owningTabBarController].selectedViewController;
    self.cyl_hasTouchDownForTabBarItemGesture = YES;
}

- (void)cyl_tabBarItemGestureTouchUpInside {
    UIViewController *selectedViewController = self.cyl_hasTouchDownForTabBarItemGesture ? self.cyl_selectedViewControllerAtTouchDown : nil;
    self.cyl_hasTouchDownForTabBarItemGesture = NO;
    self.cyl_selectedViewControllerAtTouchDown = nil;
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController];
    if ([tabBarController respondsToSelector:@selector(cyl_recognizePlusButtonTap:selectedViewControllerAtTouchDown:)]) {
        [tabBarController cyl_recognizePlusButtonTap:self selectedViewControllerAtTouchDown:selectedViewController];
    }
}

- (void)removeFromSuperview {
    [self.cyl_touchableAreaView removeFromSuperview];
    [super removeFromSuperview];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
    }
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
    }
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
    }
}

- (UIImage *)getSnapshot {
//    return [CYLPlusButton plusButtonForOwner:self].imageView.image;
    if (_snapshot) {
        UIImage *originalImage = _snapshot;
        UIImage *newImage =
        [UIImage imageWithCGImage:[originalImage CGImage]
                            scale:(originalImage.scale)
                      orientation:(originalImage.imageOrientation)];
        return newImage;
    }
    
    _snapshot = [self cyl_takeSnapshot];
    return _snapshot;
}

+ (UIButton *)selectedContentView {
    Class<CYLPlusButtonSubclassing> class = self;
    CYLPlusButton *registeredPlusButton = [CYLPlusButton plusButtonForTabBarContext:[self matchedTabBarContext]];
    if (registeredPlusButton) {
        // [CN] 不使用selected 以避免选中背景
        // [EN] Do not use selected, to avoid the selected background
        registeredPlusButton.highlighted = YES;
    }
    UIButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
    if (NO == plusButton.cyl_userInteractionDisabled) {
        // [CN] 不使用selected 以避免选中背景
        // [EN] Do not use selected, to avoid the selected background
        plusButton.highlighted = YES;
    }
    return plusButton;
}

- (UIButton *)selectedContentView {
    
    if (_selectedContentView) {
        return _selectedContentView;
    }
    
    if ([[self class] respondsToSelector:@selector(selectedContentView)]) {
        UIButton *button = [[self class] performSelector:@selector(selectedContentView)];
        if (button) {
            _selectedContentView = button;
            return _selectedContentView;
        }
    }
    UIButton *selectedContentView = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [selectedContentView setImage:([[self class] contentImage] ?: self.contentImage ?: UIImage.new) forState:UIControlStateNormal];
    [selectedContentView setImage:([[self class] selectedContentImage] ?: self.selectedContentImage ?: UIImage.new)
                         forState:UIControlStateHighlighted];
    CGRect bounds = self.bounds;
    selectedContentView.frame = ({
        CGRect frame = selectedContentView.frame;
        frame.size = CGSizeMake(bounds.size.width, bounds.size.height);
        frame;
    });
    selectedContentView.contentMode = UIViewContentModeCenter;
    selectedContentView.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // FIX: issue #653 — placed by frame (see `_CYLTabButtonLayoutTracker`), not by Auto Layout.
    selectedContentView.translatesAutoresizingMaskIntoConstraints = YES;
    selectedContentView.userInteractionEnabled = false;
    [selectedContentView sizeToFit];
    if (NO == self.cyl_userInteractionDisabled) {
        // [CN] 不使用selected 以避免选中背景
        // [EN] Do not use selected, to avoid the selected background
        selectedContentView.highlighted = YES;
    }
    _selectedContentView = selectedContentView;
    return _selectedContentView;
}

- (void)setTabLabelHidden:(BOOL)hidden {
    if (![CYLConstants isLiquidGlassActive]) {
        return;
    }
    // The plus button of this button's own context (`self` may be any registered one).
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton || ![CYLPlusButton plusChildViewControllerForOwner:self]) {
        return;
    }
    if (plusButton.cyl_keepShowingPlusButtonLabel) {
        return;
    }
    if (!plusButton.cyl_tabLabel || 0 == plusButton.cyl_tabLabel.text.length ) {
        return;
    }
    [plusButton.cyl_tabLabel cyl_setHidden:hidden];
    [plusButton.selectedContentView.cyl_tabLabel cyl_setHidden:!hidden];
}

+ (UIImage *)contentImage {
    return nil;
}

+ (UIImage *)selectedContentImage {
    return nil;
}

- (UIImage *)selectedContentImage {
    if (_selectedContentImage) {
        return _selectedContentImage;
    }
    UIImage *image = self.imageView.image;
    _selectedContentImage = image;
    return _selectedContentImage ;
}

- (UIImage *)contentImage {
    if (_contentImage) {
        return _contentImage;
    }

    UIImage *image = self.imageView.image;
    _contentImage = image;
    return _contentImage;
}

//+ (NSString *)tabBarContext {
//    return NSStringFromClass([CYLTabBarController class]);
//}

+ (BOOL)hasPlusButtonForTabBarContext:(NSString *)tabBarContext {
    return [self plusButtonForTabBarContext:tabBarContext] != nil;
}

+ (BOOL)hasPlusChildViewControllerForTabBarContext:(NSString *)tabBarContext {
    return [self plusChildViewControllerForTabBarContext:tabBarContext] != nil;
}

#pragma mark - Plus buttons by context

+ (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButtonForTabBarContext:(NSString *)tabBarContext {
    return CYLPlusButtonRegistrationForContext(tabBarContext).plusButton;
}

+ (UIViewController *)plusChildViewControllerForTabBarContext:(NSString *)tabBarContext {
    return CYLPlusButtonRegistrationForContext(tabBarContext).plusChildViewController;
}

+ (CGFloat)plusButtonWidthForTabBarContext:(NSString *)tabBarContext {
    return CYLPlusButtonRegistrationForContext(tabBarContext).plusButtonWidth;
}

+ (CYLPlusButtonRegistration *)registrationOfPlusButtonView:(UIView *)view {
    if (!view) {
        return nil;
    }
    // The registered instance itself; otherwise the most specific registered class `view` is a kind of. A plus button
    // class may inherit from another registered one (a second plus button that only changes the icon), and an instance
    // of it that is not the registered one, such as the selected-state copy `+selectedContentView` creates, is also a
    // kind of the parent class.
    // 先找已注册的实例本身；否则取 `view` 所属的、最具体的已注册类。一个 PlusButton 类可能继承自另一个已注册的类（只改了图标的
    // 第二个 PlusButton），它的实例如果不是已注册的那个（例如 `+selectedContentView` 创建的选中态副本），同时也是父类的实例。
    CYLPlusButtonRegistration *mostSpecific = nil;
    NSMutableDictionary *registry = CYLPlusButtonRegistry();
    @synchronized (registry) {
        for (CYLPlusButtonRegistration *registration in registry.allValues) {
            if (registration.plusButton == (id)view) {
                return registration;
            }
            Class plusButtonClass = registration.plusButtonClass;
            if (!plusButtonClass || ![view isKindOfClass:plusButtonClass]) {
                continue;
            }
            if (!mostSpecific || [plusButtonClass isSubclassOfClass:mostSpecific.plusButtonClass]) {
                mostSpecific = registration;
            }
        }
    }
    return mostSpecific;
}

+ (BOOL)isPlusButtonView:(UIView *)view {
    return [self registrationOfPlusButtonView:view] != nil;
}

+ (CYLPlusButtonRegistration *)registrationOfPlusChildViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    UIViewController *inner = [viewController cyl_getViewControllerInsteadOfNavigationController];
    NSMutableDictionary *registry = CYLPlusButtonRegistry();
    @synchronized (registry) {
        for (CYLPlusButtonRegistration *registration in registry.allValues) {
            UIViewController *child = registration.plusChildViewController;
            if (child && (child == viewController || child == inner)) {
                return registration;
            }
        }
    }
    return nil;
}

/*!
 * [EN] Which context `owner` belongs to. A plus button and a plus child view controller know their own (the registry).
 *      Anything else takes the context of the CYLTabBarController it belongs to, found by the same lookup as
 *      `-cyl_tabBarController` but for any style (`-cyl_owningTabBarController`): a tab bar asks its `delegate`, a view
 *      goes up its responder chain, a view controller up its parents. If it is in none: a tab bar not attached yet uses
 *      its own context (copied from its controller), anything else the most recently active controller's, and only when
 *      no tab bar controller exists yet the context registered last (what the globals describe).
 * [CN] `owner` 属于哪个 context。PlusButton 和 PlusButton 子控制器通过注册表知道自己的 context。其他对象取它所属
 *      CYLTabBarController 的 context，查找方式与 `-cyl_tabBarController` 相同但不限样式（`-cyl_owningTabBarController`）：
 *      TabBar 询问它的 `delegate`，View 沿响应链向上，ViewController 沿父控制器链向上。都不在时：尚未挂上的 TabBar 用自己的 context
 *      （从控制器复制而来），其他对象取最近活跃控制器的 context，只有还没有任何 TabBarController 时才取最后注册的 context（全局变量描述的那个）。
 */
+ (NSString *)tabBarContextForOwner:(id)owner {
    NSString *context = nil;
    if ([owner isKindOfClass:[UIView class]]) {
        context = [self registrationOfPlusButtonView:owner].context;
    } else if ([owner isKindOfClass:[UIViewController class]]) {
        context = [self registrationOfPlusChildViewController:owner].context;
    }
    if (context) {
        return context;
    }
    CYLTabBarController *tabBarController = [owner cyl_owningTabBarController];
    if (tabBarController) {
        return tabBarController.cyl_context;
    }
    // A tab bar that is not attached to its controller yet (`-[CYLTabBar setContext:]` asks for its plus button right
    // then) carries the context the controller copied to it; never take another controller's context for it.
    // 尚未挂到控制器上的 TabBar（`-[CYLTabBar setContext:]` 此时就会查询 PlusButton）带有控制器复制给它的 context，不能取其他控制器的。
    BOOL isTabBar = [owner isKindOfClass:[UITabBar class]];
#if CYL_FLATDESIGN_AVAILABLE
    isTabBar = isTabBar || [owner isKindOfClass:[CYLFlatDesignTabBar class]];
#endif
    if (isTabBar) {
        return [owner cyl_context];
    }
    // Nothing to go by: the most recently active controller, else the context registered last.
    return [CYLTabBarController cyl_activeTabBarController].cyl_context ?: CYLPlusButtonLatestContext;
}

+ (CYLPlusButton<CYLPlusButtonSubclassing> *)plusButtonForOwner:(id)owner {
    CYLTabBarController *tabBarController = [owner cyl_owningTabBarController];
    if (tabBarController) {
        return [self bindingForTabBarController:tabBarController].plusButton;
    }
    return [self plusButtonForTabBarContext:[self tabBarContextForOwner:owner]];
}

+ (UIViewController *)plusChildViewControllerForOwner:(id)owner {
    CYLTabBarController *tabBarController = [owner cyl_owningTabBarController];
    if (tabBarController) {
        return [self bindingForTabBarController:tabBarController].plusChildViewController;
    }
    return [self plusChildViewControllerForTabBarContext:[self tabBarContextForOwner:owner]];
}

/*!
 * [EN] The plus button `tabBarController` shows: its binding, made the first time it is asked and kept while the
 *      registration of its context is the same class. nil when nothing is registered for its context.
 * [CN] `tabBarController` 展示的 PlusButton：它的绑定，第一次查询时创建，只要其 context 注册的仍是同一个类就保持不变。
 *      其 context 没有注册时返回 nil。
 */
+ (CYLPlusButtonBinding *)bindingForTabBarController:(CYLTabBarController *)tabBarController {
    NSString *context = tabBarController.cyl_context;
    CYLPlusButtonRegistration *registration = CYLPlusButtonRegistrationForContext(context);
    if (!registration) {
        return nil;
    }
    static char CYLPlusButtonBindingKey;
    CYLPlusButtonBinding *binding = objc_getAssociatedObject(tabBarController, &CYLPlusButtonBindingKey);
    // Kept across a new `+registerPlusButton` of the same class: this controller keeps showing the one it has.
    if (binding && [binding.context isEqualToString:context] && binding.plusButtonClass == registration.plusButtonClass) {
        return binding;
    }
    // Its context changed: free the registered instances of the old one for another controller.
    if (binding.registration.claimingTabBarController == tabBarController) {
        binding.registration.claimingTabBarController = nil;
    }
    binding = [[CYLPlusButtonBinding alloc] init];
    binding.registration = registration;
    binding.context = context;
    binding.plusButtonClass = registration.plusButtonClass;
    CYLTabBarController *claimingTabBarController = registration.claimingTabBarController;
    if (!claimingTabBarController || claimingTabBarController == tabBarController) {
        registration.claimingTabBarController = tabBarController;
        binding.plusButton = registration.plusButton;
        binding.plusChildViewController = registration.plusChildViewController;
    } else {
        [self makeOwnPlusButtonForBinding:binding registration:registration];
    }
    objc_setAssociatedObject(tabBarController, &CYLPlusButtonBindingKey, binding, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return binding;
}

/// Another tab bar controller of the context already uses the registered instances: make this one its own.
+ (void)makeOwnPlusButtonForBinding:(CYLPlusButtonBinding *)binding registration:(CYLPlusButtonRegistration *)registration {
    Class<CYLPlusButtonSubclassing> plusButtonClass = registration.plusButtonClass;
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [plusButtonClass plusButton];
    // A `+plusButton` that returns one shared instance cannot give another: share it, as before.
    if (!plusButton || plusButton == registration.plusButton) {
        binding.plusButton = registration.plusButton;
        binding.plusChildViewController = registration.plusChildViewController;
        return;
    }
    binding.plusButton = plusButton;
    [registration.boundCopies addObject:plusButton];
    if (!registration.plusChildViewController) {
        return;
    }
    UIViewController *plusChildViewController = [plusButtonClass plusChildViewController];
    if (!plusChildViewController || plusChildViewController == registration.plusChildViewController) {
        // Same: a shared plus child view controller stays shared.
        binding.plusChildViewController = registration.plusChildViewController;
    } else {
        binding.plusChildViewController = plusChildViewController;
        [plusChildViewController cyl_setContext:registration.context];
        [registration.boundCopies addObject:plusChildViewController];
    }
    [(Class)plusButtonClass addSelectViewControllerTarget:plusButton];
}

+ (CGFloat)plusButtonWidthForOwner:(id)owner {
    return [self plusButtonWidthForTabBarContext:[self tabBarContextForOwner:owner]];
}

+ (NSString *)matchedTabBarContext {
    NSString *matchedTabBarContext;
    SEL action = @selector(tabBarContext);
    if ([self respondsToSelector:action]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         matchedTabBarContext = [self performSelector:action];
         )
    }
    if (matchedTabBarContext && matchedTabBarContext.length > 0) {
        return matchedTabBarContext;
    }
    matchedTabBarContext = NSStringFromClass([CYLTabBarController class]);
    return matchedTabBarContext;
}

+ (NSUInteger)indexForTabbarItemsCount:(NSUInteger)tabbarItemsCount {
    NSUInteger plusButtonIndex = NSNotFound;

    if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
        plusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
    } else {
        if (tabbarItemsCount % 2 != 0) {
#if defined(DEBUG) || defined(BETA)
            NSAssert(NO, CYLLocalizedString(@"[DEBUG INFO] 如果 CYLTabBarController 的子控制器个数是奇数，你必须在你自定义的 plusButton 中实现 `+indexOfPlusButtonInTabBar`，来指定 plusButton 的位置。"));
#endif
        } else {
            plusButtonIndex = tabbarItemsCount * 0.5;
        }
    }
    return plusButtonIndex;
}

@end
