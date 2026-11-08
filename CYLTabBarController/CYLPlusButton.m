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
/// [EN] Implemented in UIControl+CYLBadgeExtention.m (issue #779). [CN] 在 UIControl+CYLBadgeExtention.m 中实现（issue #779）。
@interface UIControl (CYLPlusButtonBadgeLayers)
- (void)cyl_showBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue;
- (void)cyl_showBadgeValueInThisLayer:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue;
- (NSArray<UIControl *> *)cyl_badgeLayerControls;
@end

@interface CYLTabBar (CYLPlusButtonLayout)
- (BOOL)cyl_showsVerticalBar;
- (BOOL)cyl_showsMinimizedBar;
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

/*!
 * [EN] The width registered for `plusButton`'s context, after the button changed size (e.g. its image loaded later): the
 *      classic and Flat tab bars lay the tabs out with it, so a stale width put the plus button and its neighbours off
 *      their places.
 * [CN] PlusButton 尺寸变化后（例如图片之后才加载）更新其 context 登记的宽度：经典与扁平样式的 TabBar 用它布局各 Tab，过期的宽度会让
 *      PlusButton 及相邻的 Tab 偏离位置。
 */
static void CYLPlusButtonUpdateRegisteredWidth(CYLPlusButton *plusButton) {
    NSMutableDictionary<NSString *, CYLPlusButtonRegistration *> *registry = CYLPlusButtonRegistry();
    @synchronized (registry) {
        for (CYLPlusButtonRegistration *registration in registry.allValues) {
            if (registration.plusButton != plusButton && ![registration.boundCopies containsObject:plusButton]) {
                continue;
            }
            registration.plusButtonWidth = CGRectGetWidth(plusButton.bounds);
            if ([registration.context isEqualToString:CYLPlusButtonLatestContext]) {
                CYLPlusButtonWidth = registration.plusButtonWidth;
            }
        }
    }
}

@interface CYLPlusButton () 

@property (nonatomic, strong) UIImage *snapshot;

@property (nonatomic, weak) UIButton *contentView;
@property (nonatomic, weak) UIButton *selectedContentView;
@property (nonatomic, strong) UIImage *selectedContentImage;
@property (nonatomic, strong) UIImage *contentImage;
- (BOOL)cyl_alignsTitleWithTabBarItemTitles;
- (BOOL)cyl_drawsTitleOverBackgroundImage;
/// [EN] Issue #91: the overlay of `showsTouchableArea`, in the superview, under the plus button.
/// [CN] 可点击区域的调试覆盖层。
@property (nonatomic, strong, nullable) UIView *cyl_touchableAreaView;
/// [EN] Issue #152: the view controller selected on the last touch down, and whether there was one.
/// [CN] Issue #152：上次手指按下时选中的控制器，以及是否有按下。
@property (nonatomic, weak, nullable) UIViewController *cyl_selectedViewControllerAtTouchDown;
@property (nonatomic, assign) BOOL cyl_hasTouchDownForTabBarItemGesture;
/// [EN] Set while this class lays out its image and title (see `-cyl_layOutContentOnce:`).
/// [CN] 本类布置图片与标题期间为 YES（见 `-cyl_layOutContentOnce:`）。
@property (nonatomic, assign) BOOL cyl_isLayingOutContent;
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
/// [EN] From the image's bottom edge to the title's center line, measured before the title moved (#636). From the edge, not
///      the center, so an image set or replaced later keeps the distance. [CN] 从图片底边到标题中心线的距离，在标题移走前测得（#636）。
///      以底边而不是中心计算，之后设置或替换的图片保持同一距离。
static const void *CYLPlusButtonImageBottomToTitleKey = &CYLPlusButtonImageBottomToTitleKey;
/// [EN] The title style applied from the tab titles (`-cyl_applyTitleFont:normalColor:selectedColor:`).
/// [CN] 按 Tab 标题应用的标题样式（`-cyl_applyTitleFont:normalColor:selectedColor:`）。
static const void *CYLPlusButtonTitleStyleKey = &CYLPlusButtonTitleStyleKey;
/// [EN] The title font the app gave the plus button, before the tab titles' font was applied.
/// [CN] 应用 Tab 标题字体之前，App 为 PlusButton 设置的标题字体。
static const void *CYLPlusButtonOriginalTitleFontKey = &CYLPlusButtonOriginalTitleFontKey;
/// [EN] The tab titles' center line, in the plus button, while its title stays in the button and is aligned with them.
/// [CN] 标题留在按钮中并与 Tab 标题对齐时，Tab 标题的中心线（PlusButton 坐标系）。
static const void *CYLPlusButtonAlignedTitleCenterYKey = &CYLPlusButtonAlignedTitleCenterYKey;
/// [EN] Between the image and the title it sits above. [CN] 图片与其下方标题之间的间距。
static const CGFloat CYLPlusButtonImageToTitleSpacing = 2;
/// [EN] The images last set by `-cyl_updateTitle:image:selectedImage:` (a theme, `-updatePlusButtonWithAttributes:`).
/// [CN] 最近一次由 `-cyl_updateTitle:image:selectedImage:` 设置的图片（主题、`-updatePlusButtonWithAttributes:`）。
static const void *CYLPlusButtonUpdatedImageKey = &CYLPlusButtonUpdatedImageKey;
static const void *CYLPlusButtonUpdatedSelectedImageKey = &CYLPlusButtonUpdatedSelectedImageKey;

/// [EN] The center of `button`'s icon in `view`; NO while the icon is not laid out, or hidden: after the image is removed the
///      hidden image view keeps its old frame, and the two buttons would line up by something that is not drawn.
/// [CN] `button` 的图标中心在 `view` 中的坐标；图标尚未布局或已隐藏时返回 NO：图片移除后，隐藏的 imageView 仍保留旧 frame，两个按钮会按未绘制的内容对齐。
static BOOL CYLPlusButtonGetIconCenter(UIButton *button, UIView *view, CGPoint *center) {
    UIImageView *imageView = button.imageView;
    if (!imageView.superview || imageView.isHidden || CGRectIsEmpty(imageView.frame)) {
        return NO;
    }
    *center = [imageView.superview convertPoint:imageView.center toView:view];
    return YES;
}

/*!
 * FIX: issue #216
 * [EN] The center of the stand-in, in its superview. The agreement when the app asks for the title to be aligned with the
 *      tab titles (`+alignsTitleWithTabBarItemTitles`): the stand-in and the plus button line up by icon only, and their
 *      other subviews are not considered. The plus button then replaces only the tab's icon and is placed by its icon
 *      (`-cyl_alignedCenterForCenter:`), so its center says nothing about where the icon is, and the two buttons lay their
 *      icons out differently: aligning the centers left the parts above and in the glass about 5.67 pt apart. In any other
 *      layout, or without a laid out icon, the plus button's center.
 * [CN] 替身在其父视图中的中心。App 要求标题与 Tab 标题对齐时（`+alignsTitleWithTabBarItemTitles`）的约定：替身与 PlusButton 只对齐图标，不考虑其他
 *      子视图。此时 PlusButton 只替换 Tab 的图标，并按图标定位（`-cyl_alignedCenterForCenter:`），其中心不代表图标位置，两个按钮的图标布局也不同：
 *      只对齐中心时，玻璃上方与玻璃内的部分相差约 5.67 pt。其他布局，或图标尚未布局时，使用 PlusButton 的中心。
 */
static CGPoint CYLPlusButtonCenterOfStandIn(CYLPlusButton *plusButton, UIButton *standIn) {
    UIView *container = standIn.superview;
    CGPoint plusIcon = CGPointZero;
    CGPoint standInIcon = CGPointZero;
    // [EN] A button whose picture is its background image has no icon to line up: an empty image view still has a position,
    //      which put the stand-in 21 pt above the plus button. Its center is used instead.
    // [CN] 以背景图为图片的按钮没有可对齐的图标：空的 imageView 仍有位置，会让替身比 PlusButton 高 21 pt。此时使用按钮中心。
    if (![plusButton cyl_drawsTitleOverBackgroundImage] && [plusButton cyl_alignsTitleWithTabBarItemTitles] &&
        CYLPlusButtonGetIconCenter(plusButton, container, &plusIcon) &&
        CYLPlusButtonGetIconCenter(standIn, standIn, &standInIcon)) {
        return CGPointMake(plusIcon.x - (standInIcon.x - CGRectGetMidX(standIn.bounds)),
                           plusIcon.y - (standInIcon.y - CGRectGetMidY(standIn.bounds)));
    }
    return [container convertPoint:plusButton.center fromView:plusButton.superview];
}

/*!
 * [EN] YES when `plusButton` is in a Liquid Glass tab bar: Liquid Glass is active AND its tab bar controller is not the
 *      FlatDesign style (on iOS 26 `+isLiquidGlassActive` is YES with the FlatDesign tab bar too), as master's checks
 *      (`CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && [CYLConstants isLiquidGlassActive]`). The controller is
 *      found as in `-plusChildViewControllerSelected:`; NO when there is none.
 * [CN] `plusButton` 位于液态玻璃 TabBar 中时为 YES：液态玻璃处于活动状态，且其 TabBarController 不是扁平样式（iOS 26 上使用扁平样式
 *      TabBar 时 `+isLiquidGlassActive` 也为 YES），与 master 中的判断相同（`CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType &&
 *      [CYLConstants isLiquidGlassActive]`）。TabBarController 的查找方式与 `-plusChildViewControllerSelected:` 相同；找不到时为 NO。
 */
static BOOL CYLPlusButtonIsInLiquidGlassTabBar(CYLPlusButton *plusButton) {
    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    CYLTabBarController *tabBarController = [plusButton cyl_owningTabBarController] ?:
        [CYLTabBarController cyl_tabBarControllerForContext:[CYLPlusButton tabBarContextForOwner:plusButton]];
    return tabBarController && CYLTabBarStyleTypeFlatDesign != tabBarController.tabBarStyleType;
}

// [EN] Implemented in CYLTabBarController+CYLInteraction.m: the pressed (highlight / dehighlight) animation of a button.
// [CN] 在 CYLTabBarController+CYLInteraction.m 中实现：按钮的按下（highlight / dehighlight）动画。
@interface CYLTabBarController (CYLTabButtonHighlight)
- (void)cyl_tabButtonTouchDown:(UIControl *)control;
- (void)cyl_tabButtonTouchUp:(UIControl *)control;
@end

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

/*!
 * [EN] VoiceOver: the plus button is announced as selected while its page is shown, like a tab.
 * [CN] VoiceOver：PlusButton 对应的页面显示时，与 Tab 一样朗读为"已选中"。
 */
- (UIAccessibilityTraits)accessibilityTraits {
    UIAccessibilityTraits traits = [super accessibilityTraits] | UIAccessibilityTraitButton;
    return self.isSelected ? (traits | UIAccessibilityTraitSelected) : traits;
}

/*!
 * [EN] Defaults that system tab buttons already have: the iPad pointer hover effect (iOS 13.4+) and the Large Content
 *      Viewer (iOS 13+: with the largest text sizes, a long press shows the title and image in the middle of the screen).
 *      Set at creation, so the app can turn them off afterwards (`pointerInteractionEnabled = NO`,
 *      `showsLargeContentViewer = NO`).
 * [CN] 系统 Tab 按钮本来就有的默认行为：iPad 指针悬停效果（iOS 13.4+）与大内容查看器（iOS 13+：使用最大字号时，长按会在屏幕中央
 *      显示标题与图片）。在创建时设置，App 之后可以关闭（`pointerInteractionEnabled = NO`、`showsLargeContentViewer = NO`）。
 */
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self cyl_setUpTabLikeInteractions];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self cyl_setUpTabLikeInteractions];
    }
    return self;
}

- (void)cyl_setUpTabLikeInteractions {
    if (@available(iOS 13.4, *)) {
        self.pointerInteractionEnabled = YES;
    }
    if (@available(iOS 13.0, *)) {
        self.showsLargeContentViewer = YES;
        self.scalesLargeContentImage = YES;
    }
}

- (NSString *)largeContentTitle API_AVAILABLE(ios(13.0)) {
    NSString *title = [super largeContentTitle];
    return title.length > 0 ? title : self.accessibilityLabel;
}

- (UIImage *)largeContentImage API_AVAILABLE(ios(13.0)) {
    return [super largeContentImage] ?: self.currentImage;
}

/// [EN] The Large Content Viewer needs an interaction on an ancestor; add one to the bar when it has none.
/// [CN] 大内容查看器需要祖先视图上有对应的 interaction；所在的 TabBar 没有时为其添加一个。
- (void)cyl_installLargeContentViewerInteractionIfNeeded {
    if (@available(iOS 13.0, *)) {
        UIView *bar = self.superview;
        if (!bar || !self.showsLargeContentViewer) {
            return;
        }
        for (id<UIInteraction> interaction in bar.interactions) {
            if ([interaction isKindOfClass:[UILargeContentViewerInteraction class]]) {
                return;
            }
        }
        [bar addInteraction:[[UILargeContentViewerInteraction alloc] init]];
    }
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
 * [EN] Every image given to a plus button is drawn as is (`UIImageRenderingModeAlwaysOriginal`), in every style: never
 *      tinted by the tab bar's tint, by Liquid Glass's selected layer or by a button configuration, and not darkened while
 *      touched. This covers `-setImage:forState:`, `-setBackgroundImage:forState:`, `UIButtonConfiguration`
 *      (`image`, `background.image`), the stand-in in the lens (`-selectedContentView`, also when it is a plain `UIButton`)
 *      and `-cyl_updateTitle:image:selectedImage:`. Before, only the Liquid Glass layout with the title in the tab item
 *      (#636) did this, so the same icon could show in two colors.
 * [CN] 加载给 PlusButton 的所有图片在所有样式下都按原图绘制（`UIImageRenderingModeAlwaysOriginal`）：不会被 TabBar 的 tint、液态玻璃的选中图层或
 *      按钮 configuration 染色，按下时也不会变暗。适用于 `-setImage:forState:`、`-setBackgroundImage:forState:`、`UIButtonConfiguration`
 *      （`image`、`background.image`）、放大镜中的替身（`-selectedContentView`，包括普通 `UIButton`）以及 `-cyl_updateTitle:image:selectedImage:`。
 *      以前只有液态玻璃下标题由 TabBarItem 显示的布局（#636）这样处理，同一图标可能显示为两种颜色。
 */
static UIImage *CYLPlusButtonOriginalImage(UIImage *image) {
    if (!image || image.renderingMode == UIImageRenderingModeAlwaysOriginal) {
        return image;
    }
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

/// [EN] The last badge asked for, see `-cyl_showRequestedBadgeIfNeeded`. [CN] 最后一次请求的角标，见 `-cyl_showRequestedBadgeIfNeeded`。
static const void *CYLPlusButtonRequestedBadgeValueKey = &CYLPlusButtonRequestedBadgeValueKey;
static const void *CYLPlusButtonRequestedBadgeAnimationTypeKey = &CYLPlusButtonRequestedBadgeAnimationTypeKey;

/// [EN] See `-cyl_setBackgroundImageDidChangeHandler:`. [CN] 见 `-cyl_setBackgroundImageDidChangeHandler:`。
static const void *CYLPlusButtonBackgroundImageHandlerKey = &CYLPlusButtonBackgroundImageHandlerKey;

/// [EN] The selected images set on the plus button while it draws its normal image instead, see `-cyl_updateSelectedContentViewImage`.
/// [CN] PlusButton 改为绘制普通图片期间，保存设置给它的选中图片，见 `-cyl_updateSelectedContentViewImage`。
static const void *CYLPlusButtonKeptSelectedImagesKey = &CYLPlusButtonKeptSelectedImagesKey;

/// [EN] Whether two images draw the same picture: the same object, the same bitmap at the same size, or equal (e.g. the
///      same symbol). [CN] 两张图片是否绘制相同的内容：同一对象、相同尺寸的同一位图，或相等（例如同一 SF Symbol）。
static BOOL CYLPlusButtonImagesDrawTheSame(UIImage *image, UIImage *otherImage) {
    if (image == otherImage) {
        return YES;
    }
    if (!image || !otherImage || !CGSizeEqualToSize(image.size, otherImage.size)) {
        return NO;
    }
    return (image.CGImage && image.CGImage == otherImage.CGImage) || [image isEqual:otherImage];
}

/// [EN] The control states whose images a plus button (or its stand-in) can set. [CN] PlusButton（或其替身）可设置图片的状态。
static NSArray<NSNumber *> *CYLPlusButtonImageStates(void) {
    return @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected),
              @(UIControlStateSelected | UIControlStateHighlighted), @(UIControlStateDisabled) ];
}

/// [EN] Draws the images a button already has as is: a stand-in returned by `+selectedContentView` may be any UIButton.
/// [CN] 让按钮已有的图片按原图绘制：`+selectedContentView` 返回的替身可能是任意 UIButton。
static void CYLPlusButtonDrawImagesAsIs(UIButton *button) {
    for (NSNumber *state in CYLPlusButtonImageStates()) {
        UIControlState controlState = state.unsignedIntegerValue;
        UIImage *image = [button imageForState:controlState];
        if (image && image.renderingMode != UIImageRenderingModeAlwaysOriginal) {
            [button setImage:CYLPlusButtonOriginalImage(image) forState:controlState];
        }
        UIImage *backgroundImage = [button backgroundImageForState:controlState];
        if (backgroundImage && backgroundImage.renderingMode != UIImageRenderingModeAlwaysOriginal) {
            [button setBackgroundImage:CYLPlusButtonOriginalImage(backgroundImage) forState:controlState];
        }
    }
}

/*!
 * [EN] The states UIKit draws from another state's image when they have none, darkened (highlighted) or faded
 *      (disabled), mapped to the state whose image they show instead: highlighted and disabled show the normal image,
 *      selected and highlighted shows the selected one.
 * [CN] 没有图片时，系统会用其他状态的图片并加暗（高亮）或变淡（禁用）绘制的状态，以及改为显示其图片的状态：高亮与禁用显示普通图片，
 *      选中且高亮显示选中图片。
 */
static NSDictionary<NSNumber *, NSNumber *> *CYLPlusButtonDerivedImageStates(void) {
    return @{
        @(UIControlStateHighlighted): @(UIControlStateNormal),
        @(UIControlStateDisabled): @(UIControlStateNormal),
        @(UIControlStateSelected | UIControlStateHighlighted): @(UIControlStateSelected),
    };
}

/*!
 * [EN] Sets `image` for `state` (through `setter`, the superclass's), then gives every derived state that was never set
 *      on purpose the plain image of its source state, so UIKit never darkens or fades a plus button's image.
 *      `explicitStates` remembers the states set on purpose, one set for images and one for background images.
 * [CN] 为 `state` 设置 `image`（通过 `setter`，即父类方法），然后为每个未被主动设置过的派生状态设置其来源状态的原图，系统因此不会把 PlusButton
 *      的图片画暗或变淡。`explicitStates` 记录主动设置过的状态，图片与背景图片各一份。
 */
- (void)cyl_setImage:(UIImage *)image
            forState:(UIControlState)state
      explicitStates:(const void *)explicitStatesKey
              getter:(UIImage * (NS_NOESCAPE ^)(UIControlState state))getter
              setter:(void (NS_NOESCAPE ^)(UIImage *image, UIControlState state))setter {
    NSMutableSet<NSNumber *> *explicitStates = objc_getAssociatedObject(self, explicitStatesKey);
    if (!explicitStates) {
        explicitStates = [NSMutableSet set];
        objc_setAssociatedObject(self, explicitStatesKey, explicitStates, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [explicitStates addObject:@(state)];
    setter(CYLPlusButtonOriginalImage(image), state);
    [CYLPlusButtonDerivedImageStates() enumerateKeysAndObjectsUsingBlock:^(NSNumber *derived, NSNumber *source, BOOL *stop) {
        if ([explicitStates containsObject:derived]) {
            return;
        }
        // [EN] `getter` falls back like UIKit (e.g. no selected image: the normal one). [CN] `getter` 与系统一样回退（如没有选中图片时取普通图片）。
        setter(getter(source.unsignedIntegerValue), derived.unsignedIntegerValue);
    }];
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    static const void *CYLPlusButtonExplicitImageStatesKey = &CYLPlusButtonExplicitImageStatesKey;
    [objc_getAssociatedObject(self, CYLPlusButtonKeptSelectedImagesKey) removeObjectForKey:@(state)];
    [self cyl_setImage:image forState:state explicitStates:CYLPlusButtonExplicitImageStatesKey
                getter:^UIImage *(UIControlState aState) { return [super imageForState:aState]; }
                setter:^(UIImage *anImage, UIControlState aState) { [super setImage:anImage forState:aState]; }];
    if (state == UIControlStateNormal) {
        [self cyl_updateSelectedContentViewImageRemovingIfEmpty:(image == nil)];
        [self cyl_contentImageDidChange];
    }
}

- (UIImage *)imageForState:(UIControlState)state {
    NSDictionary<NSNumber *, UIImage *> *keptImages = objc_getAssociatedObject(self, CYLPlusButtonKeptSelectedImagesKey);
    return keptImages[@(state)] ?: [super imageForState:state];
}

- (void)cyl_removeImage {
    UIButton *standIn = (_selectedContentView != self) ? _selectedContentView : nil;
    for (NSNumber *imageState in CYLPlusButtonImageStates()) {
        [self setImage:nil forState:imageState.unsignedIntegerValue];
        [standIn setImage:nil forState:imageState.unsignedIntegerValue];
    }
    if (@available(iOS 15.0, *)) {
        if (self.configuration.image) {
            UIButtonConfiguration *configuration = self.configuration;
            configuration.image = nil;
            self.configuration = configuration;
        }
        if (standIn.configuration.image) {
            UIButtonConfiguration *configuration = standIn.configuration;
            configuration.image = nil;
            standIn.configuration = configuration;
        }
    }
    [self.superview setNeedsLayout];
}

/// [EN] Liquid Glass with a plus child view controller, see `-cyl_updateSelectedContentViewImage`. [CN] 液态玻璃且有 PlusButton 子控制器，见 `-cyl_updateSelectedContentViewImage`。
- (BOOL)cyl_standInShowsNormalImageOnly {
    return CYLPlusButtonIsInLiquidGlassTabBar(self) && [CYLPlusButton plusChildViewControllerForOwner:self] != nil;
}

/*!
 * FIX: issue #216
 * [EN] Liquid Glass with a plus child view controller only: the stand-in in the selected layer is a copy of the one real
 *      plus button, split by the glass (the real button above it, the stand-in in it), so both must show the same picture:
 *      the real button's normal image, in every state of the stand-in. A selected image set on the plus button stays on
 *      the plus button and is not used here. With two pictures the part of a network skin's icon above the glass came from
 *      one image and the part in the glass from another, and the icon looked cut. Idempotent: also run on every layout
 *      pass (`-cyl_layOutPlusButtonInLiquidGlassLayers`). FlatDesign and the classic style have no stand-in to keep in step.
 * [CN] 仅限液态玻璃且有 PlusButton 子控制器时：选中图层中的替身是唯一的真实 PlusButton 的副本，两者被玻璃分开（真实按钮在玻璃上方，替身在玻璃内），
 *      因此必须显示同一张图片：真实按钮普通状态的图片，替身所有状态都用它。设置给 PlusButton 的选中图片仍保留在 PlusButton 上，这里不使用。
 *      以前有两张图片时，网络皮肤图标在玻璃上方的部分来自一张图片，玻璃内的部分来自另一张，图标看起来被截断。可重复调用：每次布局时也会执行
 *      （`-cyl_layOutPlusButtonInLiquidGlassLayers`）。扁平样式与经典样式没有需要同步的替身。
 */
- (void)cyl_updateSelectedContentViewImage {
    [self cyl_updateSelectedContentViewImageRemovingIfEmpty:NO];
}

/// [EN] `removingIfEmpty`: the normal image was removed. The copies of it in the selected states go too, otherwise the old
///      picture stays on a selected plus button (and in its stand-in) with the title that came back.
/// [CN] `removingIfEmpty`：普通图片已被移除。选中状态下的副本也一并移除，否则选中的 PlusButton（及其替身）上仍留着旧图片，与回到按钮上的标题并存。
- (void)cyl_updateSelectedContentViewImageRemovingIfEmpty:(BOOL)removingIfEmpty {
    UIButton *standIn = (_selectedContentView != self) ? _selectedContentView : nil;
    if (!standIn || ![self cyl_standInShowsNormalImageOnly]) {
        return;
    }
    UIImage *image = [self imageForState:UIControlStateNormal];
    if (@available(iOS 15.0, *)) {
        image = self.configuration.image ?: image;
    }
    if (!image && !removingIfEmpty) {
        return;
    }
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = standIn.configuration;
        if (configuration && !CYLPlusButtonImagesDrawTheSame(configuration.image, image)) {
            configuration.image = image;
            standIn.configuration = configuration;
        }
    }
    for (NSNumber *imageState in CYLPlusButtonImageStates()) {
        UIControlState state = imageState.unsignedIntegerValue;
        if (!CYLPlusButtonImagesDrawTheSame([standIn imageForState:state], image)) {
            [standIn setImage:image forState:state];
        }
    }
    // [EN] The real button is selected while the stand-in shows, so it must draw the same picture too. A selected image
    //      of its own stays readable through `-imageForState:`. Without this, replacing only the normal image left the
    //      old selected image above the glass and the new image in it.
    // [CN] 显示替身时真实按钮处于选中状态，因此也必须绘制同一张图片。它自己的选中图片仍可通过 `-imageForState:` 读取。
    //      否则只替换普通图片时，玻璃上方仍是旧的选中图片，玻璃内却是新图片。
    NSMutableDictionary<NSNumber *, UIImage *> *keptImages = objc_getAssociatedObject(self, CYLPlusButtonKeptSelectedImagesKey);
    for (NSNumber *selectedState in @[ @(UIControlStateSelected), @(UIControlStateSelected | UIControlStateHighlighted) ]) {
        UIControlState state = selectedState.unsignedIntegerValue;
        UIImage *drawnImage = [super imageForState:state];
        if (!drawnImage || CYLPlusButtonImagesDrawTheSame(drawnImage, image)) {
            continue;
        }
        if (!keptImages) {
            keptImages = [NSMutableDictionary dictionary];
            objc_setAssociatedObject(self, CYLPlusButtonKeptSelectedImagesKey, keptImages, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!keptImages[selectedState]) {
            keptImages[selectedState] = drawnImage;
        }
        [super setImage:image forState:state];
    }
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    static const void *CYLPlusButtonExplicitBackgroundImageStatesKey = &CYLPlusButtonExplicitBackgroundImageStatesKey;
    [self cyl_setImage:image forState:state explicitStates:CYLPlusButtonExplicitBackgroundImageStatesKey
                getter:^UIImage *(UIControlState aState) { return [super backgroundImageForState:aState]; }
                setter:^(UIImage *anImage, UIControlState aState) { [super setBackgroundImage:anImage forState:aState]; }];
    if (state == UIControlStateNormal) {
        void (^handler)(void) = objc_getAssociatedObject(self, CYLPlusButtonBackgroundImageHandlerKey);
        if (image && handler) {
            handler();
        }
        [self cyl_contentImageDidChange];
    }
}

- (void)cyl_setBackgroundImageDidChangeHandler:(void (^)(void))handler {
    objc_setAssociatedObject(self, CYLPlusButtonBackgroundImageHandlerKey, handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/*!
 * [EN] Content that changed after the plus button was sized and placed: an image set, replaced or removed (e.g. loaded
 *      later from the network), or the title's font (the tab titles' one, `+alignsTitleWithTabBarItemTitles`). The
 *      button grows around its center when the content no longer fits (it never shrinks below a size the app set), and
 *      the tab bar places it again, so the layout follows the image (title in the tab item or not, `-cyl_hasImage`).
 *      Before it is first sized (still empty bounds), nothing to do.
 * [CN] PlusButton 确定尺寸与位置之后内容发生变化：设置、替换或移除图片（例如之后才从网络加载），或标题字体变化（使用 Tab 标题的字体，
 *      `+alignsTitleWithTabBarItemTitles`）。内容放不下时，按钮以中心为基准变大（不会小于 App 设置的尺寸），TabBar 重新放置它，布局随图片变化
 *      （标题是否由 TabBarItem 显示，见 `-cyl_hasImage`）。首次确定尺寸之前（bounds 仍为空）无需处理。
 */
- (void)cyl_growToFitContentIfNeeded {
    CGSize size = self.bounds.size;
    if (size.width <= 0 || size.height <= 0) {
        return;
    }
    CGSize fittingSize = [self sizeThatFits:CGSizeZero];
    if (fittingSize.width > size.width + 0.5 || fittingSize.height > size.height + 0.5) {
        CGPoint center = self.center;
        self.bounds = (CGRect){CGPointZero, CGSizeMake(MAX(size.width, fittingSize.width), MAX(size.height, fittingSize.height))};
        self.center = center;
        CYLPlusButtonUpdateRegisteredWidth(self);
    }
    [self setNeedsLayout];
    [self.superview setNeedsLayout];
}

- (void)setConfiguration:(UIButtonConfiguration *)configuration API_AVAILABLE(ios(15.0)) {
    if (configuration && ((configuration.image && configuration.image.renderingMode != UIImageRenderingModeAlwaysOriginal) ||
                          (configuration.background.image &&
                           configuration.background.image.renderingMode != UIImageRenderingModeAlwaysOriginal))) {
        configuration = [configuration copy];
        configuration.image = CYLPlusButtonOriginalImage(configuration.image);
        UIBackgroundConfiguration *background = [configuration.background copy];
        background.image = CYLPlusButtonOriginalImage(background.image);
        configuration.background = background;
    }
    UIButtonConfiguration *oldConfiguration = self.configuration;
    [super setConfiguration:configuration];
    // [EN] Only a new picture: the plus button sets its configuration too (e.g. without the title when it moves into the
    //      tab item, #636), and treating that as a new picture gave the title back, which moved it again, forever.
    //      A configuration hands back its images as new objects, so they are compared by what they draw.
    // [CN] 仅在图片变化时处理：PlusButton 自己也会设置 configuration（例如标题移到 TabBarItem 时去掉标题，#636），把它当作新图片会把标题还回去，
    //      标题随即再次移走，无限循环。configuration 返回的图片是新对象，因此按其绘制内容比较。
    if (!CYLPlusButtonImagesDrawTheSame(configuration.image, oldConfiguration.image) ||
        !CYLPlusButtonImagesDrawTheSame(configuration.background.image, oldConfiguration.background.image)) {
        [self cyl_updateSelectedContentViewImage];
        [self cyl_contentImageDidChange];
    }
}

/*!
 * [EN] The picture changed: room for it (`-cyl_growToFitContentIfNeeded`), and a badge already shown moves onto it (the
 *      badge's anchor follows the visible picture: the image, or the whole button for a background image). Only when a
 *      badge exists; never during layout.
 * [CN] 图片发生变化：留出空间（`-cyl_growToFitContentIfNeeded`），已显示的角标移到图片上（角标锚点跟随可见图片：图片本身，或背景图时为整个按钮）。
 *      仅在已有角标时处理；不会在布局期间执行。
 */
/*!
 * [EN] Liquid Glass, an image arriving while the plus button shows its own title: the title is about to move into the tab
 *      item (#636), so it gets back the font the app gave it, as a plus button with the image set at launch has when its
 *      title moves. Sized with the tab titles' font instead, the button came out 1 pt wider, and its image sat on half a
 *      point, which the badge's anchor rounded: 0.17 pt off. Buttons with a configuration keep their transformer.
 * [CN] 液态玻璃下，PlusButton 显示自己的标题时图片到来：标题即将移到 TabBarItem 中（#636），因此先恢复 App 设置的字体，与启动时就有图片的
 *      PlusButton 移走标题时一致。若按 Tab 标题的字体计算尺寸，按钮会宽 1 pt，图片落在半个点上，角标锚点取整后偏差 0.17 pt。使用 configuration
 *      的按钮保留其 transformer。
 */
- (void)cyl_restoreOriginalTitleFontBeforeTitleMoves {
    UIFont *originalFont = objc_getAssociatedObject(self, CYLPlusButtonOriginalTitleFontKey);
    if (!originalFont || ![CYLConstants isLiquidGlassActive] || ![self cyl_hasImage] || ![self cyl_alignsTitleWithTabBarItemTitles]) {
        return;
    }
    if (@available(iOS 15.0, *)) {
        if (self.configuration) {
            return;
        }
    }
    self.titleLabel.font = originalFont;
    objc_setAssociatedObject(self, CYLPlusButtonTitleStyleKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)cyl_contentImageDidChange {
    // [EN] With the title in the tab item (#636), the image-to-title distance was measured with the old picture: the title
    //      comes back to the button, so the next layout moves it again and measures with the new one, as for a picture
    //      set at launch (a 60 pt image replacing a 44 pt one sat 3 pt lower than the same image set at launch).
    // [CN] 标题已移到 TabBarItem 中时（#636），图片到标题的距离是用旧图片测量的：先把标题还给按钮，下一次布局重新移走并用新图片测量，
    //      与启动时就设置该图片一致（60 pt 图片替换 44 pt 图片后，比启动时就设置的同一图片低 3 pt）。
    [self cyl_returnTitleFromTabBarItem];
    [self cyl_restoreOriginalTitleFontBeforeTitleMoves];
    [self cyl_growToFitContentIfNeeded];
    if (objc_getAssociatedObject(self, NSSelectorFromString(@"cyl_badgeAnchorViewAlignedToView:"))) {
        [self cyl_refreshBadge];
    }
    [self cyl_showRequestedBadgeIfNeeded];
}

/*!
 * [EN] A badge asked for while the plus button had no picture is dropped once its layout retries run out, and the picture
 *      can arrive much later (e.g. from the network). The last request is kept and shown when the picture comes, so the
 *      badge ends on the picture as with a picture set at launch.
 * [CN] PlusButton 还没有图片时请求的角标，在布局重试用完后会被丢弃，而图片可能很久之后才到（例如来自网络）。这里保留最后一次请求，
 *      图片到达时再显示，使角标最终与启动时就有图片一样位于图片上。
 */
- (void)cyl_showBadgeValue:(NSString *)value animationTypeValue:(NSNumber *)animationTypeValue {
    objc_setAssociatedObject(self, CYLPlusButtonRequestedBadgeValueKey, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, CYLPlusButtonRequestedBadgeAnimationTypeKey, animationTypeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [super cyl_showBadgeValue:value animationTypeValue:animationTypeValue];
}

- (void)cyl_clearBadge {
    objc_setAssociatedObject(self, CYLPlusButtonRequestedBadgeValueKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [super cyl_clearBadge];
}

/// [EN] Also when the stand-in is made after the badge was asked for. [CN] 也包括在请求角标之后才创建替身的情况。
- (void)cyl_showRequestedBadgeIfNeeded {
    NSString *value = objc_getAssociatedObject(self, CYLPlusButtonRequestedBadgeValueKey);
    if (!value) {
        return;
    }
    NSNumber *animationType = objc_getAssociatedObject(self, CYLPlusButtonRequestedBadgeAnimationTypeKey);
    for (UIControl *control in [self cyl_badgeLayerControls]) {
        if (!control.cyl_badge.superview) {
            [control cyl_showBadgeValueInThisLayer:value animationTypeValue:animationType];
        }
    }
}

/*!
 * FIX: issue #779
 * [EN] The plus button's two layers: the real button, and on Liquid Glass with a stand-in, the stand-in in the selected layer.
 *      The glass splits the badge as it splits the icon: the real button draws the part above the glass, the stand-in the
 *      part in it. With the badge on the real button only, the part in the glass was blurred.
 * [CN] PlusButton 的两个图层：真实按钮，以及液态玻璃下选中图层中的替身。玻璃像分割图标一样分割角标：真实按钮绘制玻璃上方的部分，替身绘制
 *      玻璃内的部分。只在真实按钮上显示角标时，玻璃内的部分是模糊的。
 */
- (NSArray<UIControl *> *)cyl_badgeLayerControls {
    UIButton *standIn = _selectedContentView;
    return (standIn && standIn != self && CYLPlusButtonIsInLiquidGlassTabBar(self)) ? @[ self, standIn ] : @[ self ];
}

#pragma mark - Title alignment

/// `-layoutSubviews` of a subclass runs inside this call (and lays out the title after `super`), so the alignment comes
/// after every layout of the plus button, whatever the subclass does.
- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if (layer == self.layer) {
        [self cyl_layOutContentOnce:^{
            [self cyl_alignTitleWithTabBarItemTitlesIfNeeded];
        }];
    }
}

/*!
 * [EN] Runs `layout` unless this class is already laying out the image and title. The first read of `imageView` (or
 *      `titleLabel`) creates it and lays the button out again, which ran this class's layout again, endlessly: a stack
 *      overflow at launch (Example-Rive, a plus button made with `+cyl_plusButtonWithImage:…` and aligned titles). One
 *      flag for both the image-and-title layout and the title alignment: with one flag each, they ran nested in each
 *      other and moved the image back and forth forever.
 * [CN] 本类正在布置图片与标题时不再执行 `layout`。第一次读取 `imageView`（或 `titleLabel`）时系统会创建它并再次布局按钮，从而再次执行本类的布局，
 *      无限递归：启动时栈溢出（Example-Rive，使用 `+cyl_plusButtonWithImage:…` 并对齐标题的 PlusButton）。图片与标题布局、标题对齐共用一个标记：
 *      各用一个标记时，二者互相嵌套执行，图片被来回移动，无限布局。
 */
- (void)cyl_layOutContentOnce:(void (NS_NOESCAPE ^)(void))layout {
    if (self.cyl_isLayingOutContent) {
        return;
    }
    self.cyl_isLayingOutContent = YES;
    layout();
    self.cyl_isLayingOutContent = NO;
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
    }    // Issue #91: the touchable area overlay follows the plus button. 可点击区域的调试视图跟随 PlusButton。
    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
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
    }    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
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
    if (![plusButton cyl_standInFollowsPlusButton]) {
        return center;
    }
    return CYLPlusButtonCenterOfStandIn(plusButton, self);
}

/// [EN] The layouts whose stand-in stays on the plus button's position: the title in the tab item, no title, or a title
///      drawn over the background image (`-cyl_drawsTitleOverBackgroundImage`).
/// [CN] 替身保持在 PlusButton 位置的布局：标题由 TabBarItem 显示、没有标题，或标题画在背景图上（`-cyl_drawsTitleOverBackgroundImage`）。
/// [EN] Also whenever the app asks for the title to be aligned: a button whose image was removed keeps its title and shows
///      no icon, and without this the stand-in was left where the tab button's layout put it.
/// [CN] App 要求标题对齐时也如此：图片被移除的按钮保留标题且没有图标，否则替身会停留在 Tab 按钮布局给出的位置。
- (BOOL)cyl_standInFollowsPlusButton {
    return [self cyl_showsTitleInTabBarItem] || [self cyl_hasNoTitleInLiquidGlass] ||
           ([CYLConstants isLiquidGlassActive] && ([self cyl_drawsTitleOverBackgroundImage] || [self cyl_alignsTitleWithTabBarItemTitles]));
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
    if (![CYLConstants isLiquidGlassActive] || ![self cyl_viewControllerOfTabBarItem] || [self cyl_drawsTitleOverBackgroundImage] ||
        ![self cyl_hasImage]) {
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

/*!
 * [EN] A plus button drawn with a background image and no image (e.g. a circle with the title on it): its title is part
 *      of that picture, not a label beside an icon. Moved into the tab item, the button was placed by its empty image
 *      view, which sits at the title's leading edge: the circle moved right by half the title's width and down onto the
 *      tab titles' line, below the bar. Such a button keeps its title and is placed as in the other styles
 *      (`+multiplierOfTabBarHeight:`, `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`), centered on its tab.
 * [CN] 使用背景图片且没有图片的 PlusButton（例如标题画在圆形背景上）：标题是这张图的一部分，而不是图标旁的标签。标题移到 TabBarItem
 *      后，按钮按其空的 imageView 定位，而它位于标题的左边缘：圆形向右偏移标题宽度的一半，并向下落到 Tab 标题所在的线上、超出 TabBar。
 *      这种按钮保留自己的标题，与其他样式一样定位（`+multiplierOfTabBarHeight:`、`+constantOfPlusButtonCenterYOffsetForTabBarHeight:`），
 *      并居中于它的 Tab。
 */
- (BOOL)cyl_drawsTitleOverBackgroundImage {
    return [self backgroundImageForState:UIControlStateNormal] != nil && ![self cyl_hasImage];
}

/*!
 * [EN] Whether the plus button has an image to show (not empty). Without one (e.g. loaded later from the network) it keeps
 *      its own title: placing it by an empty `imageView` put it off its tab, and the distance to the title measured then
 *      stayed wrong once the image came.
 * [CN] PlusButton 是否有可显示的图片（非空）。没有时（例如之后才从网络加载）保留自己的标题：按空的 `imageView` 定位会偏离它的 Tab，
 *      且此时测得的到标题的距离在图片加载后仍然是错的。
 */
- (BOOL)cyl_hasImage {
    UIImage *image = [self imageForState:UIControlStateNormal];
    if (@available(iOS 15.0, *)) {
        image = image ?: self.configuration.image;
    }
    return image.size.width > 0 && image.size.height > 0;
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
        CGRect imageFrame = [imageView.superview convertRect:imageView.frame toView:self];
        CGRect titleFrame = [titleLabel.superview convertRect:titleLabel.frame toView:self];
        if ([objc_getAssociatedObject(self, @selector(cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:)) boolValue]) {
            [self cyl_getImageFrame:&imageFrame titleFrame:&titleFrame];
        }
        CGFloat imageBottomToTitle = CGRectGetMidY(titleFrame) - CGRectGetMaxY(imageFrame);
        NSString *title = self.currentTitle;
        objc_setAssociatedObject(self, CYLPlusButtonMovedTitleKey, title, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, CYLPlusButtonImageBottomToTitleKey, @(imageBottomToTitle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // The stand-in in the selected layer is a second plus button: it drops its title too, the tab item has it.
        [self cyl_updateTitleInTabBarItem];
        for (NSNumber *state in @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected),
                                  @(UIControlStateSelected | UIControlStateHighlighted)]) {
            UIControlState controlState = state.unsignedIntegerValue;
            [self setTitle:nil forState:controlState];
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

/*!
 * [EN] The title moved into the tab item (#636) comes back to the plus button when that layout no longer applies, e.g.
 *      its image was removed (`-cyl_hasImage`): the button would otherwise stay without a title.
 * [CN] 移到 TabBarItem 中的标题（#636）在该布局不再适用时回到 PlusButton，例如图片被移除（`-cyl_hasImage`）：否则按钮会一直没有标题。
 */
- (void)cyl_restoreTitleFromTabBarItemIfNeeded {
    if ([self cyl_showsTitleInTabBarItem]) {
        return;
    }
    [self cyl_returnTitleFromTabBarItem];
}

/// [EN] Gives the title moved into the tab item (#636) back to the plus button; nothing when it was not moved.
/// [CN] 把移到 TabBarItem 中的标题（#636）还给 PlusButton；未移走时不做处理。
- (void)cyl_returnTitleFromTabBarItem {
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    // [EN] The stand-in dropped its title too. Without an image it takes it back: otherwise a plus button that lost its image
    //      to a background image has no title through the lens. It has no say over the tab item, the plus button does.
    // [CN] 替身也去掉了自己的标题。没有图片时它要取回标题：否则因背景图片而失去图片的 PlusButton，透过放大镜看不到标题。替身不改动 TabBarItem，由 PlusButton 负责。
    BOOL isStandIn = [self cyl_isInPlatterSelectedLayer];
    if (movedTitle.length == 0 || (isStandIn && [self cyl_hasImage])) {
        return;
    }
    objc_setAssociatedObject(self, CYLPlusButtonMovedTitleKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, CYLPlusButtonImageBottomToTitleKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!isStandIn) {
        UITabBarItem *tabBarItem = [self cyl_viewControllerOfTabBarItem].tabBarItem;
        if ([tabBarItem.title isEqualToString:movedTitle]) {
            tabBarItem.title = nil;
        }
    }
    [self setTitle:movedTitle forState:UIControlStateNormal];
    [self setNeedsLayout];
    [self.superview setNeedsLayout];
}

/// Whether the tab bar shows its tab buttons in the iOS 27.1 vertical bar (unfolded iPhone Duo in landscape,
/// `allowsVerticalBar = YES`). 系统是否把 Tab 按钮放在 iOS 27.1 竖向栏中（iPhone Duo 展开横屏）。
- (BOOL)cyl_isInVerticalBar {
    UIView *tabBar = self.superview;
    return [tabBar isKindOfClass:[CYLTabBar class]] && [(CYLTabBar *)tabBar cyl_showsVerticalBar];
}

/// Issue #13: whether the tab bar is shown minimized (`cyl_tabBarMinimizeBehavior`, iOS 26+).
/// 系统是否正以缩小状态显示 TabBar（`cyl_tabBarMinimizeBehavior`，iOS 26+）。
- (BOOL)cyl_isInMinimizedBar {
    UIView *tabBar = self.superview;
    while (tabBar && ![tabBar isKindOfClass:[CYLTabBar class]]) {
        tabBar = tabBar.superview;
    }
    return [tabBar isKindOfClass:[CYLTabBar class]] && [(CYLTabBar *)tabBar cyl_showsMinimizedBar];
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
 * [EN] With the title in the tab item, the center (in the plus button's superview) that puts the image's bottom edge
 *      `CYLPlusButtonImageBottomToTitleKey` (measured before the title moved) above the tab titles' center line, and on the vertical center line of its own
 *      title, which the system lays out. Returns `center` in any other case, or while the titles are not laid out.
 * [CN] 标题由 TabBarItem 显示时，PlusButton 在其父视图中的中心：图片底边位于 Tab 标题中心线上方 `CYLPlusButtonImageBottomToTitleKey`（标题移走前测得）处，
 *      并与它自己的标题（由系统布局）竖向中心线对齐。其他情况，或标题尚未布局时，原样返回 `center`。
 */
- (CGPoint)cyl_alignedCenterForCenter:(CGPoint)center {
    UIView *container = self.superview;
    UIImageView *imageView = self.imageView;
    NSNumber *imageBottomToTitle = objc_getAssociatedObject(self, CYLPlusButtonImageBottomToTitleKey);
    if (!container || !imageView.superview || imageBottomToTitle == nil || [self cyl_isInPlatterSelectedLayer] ||
        ![self cyl_showsTitleInTabBarItem]) {
        return center;
    }
    // The iOS 27.1 vertical bar: centered on its tab item, as without a title (`-[CYLTabBar plusButtonIndex]`).
    // iOS 27.1 竖向栏：与没有标题时一样，居中于它的 TabBarItem（见 `-[CYLTabBar plusButtonIndex]`）。
    if ([self cyl_isInVerticalBar]) {
        return center;
    }
    // Issue #13: the minimized Liquid Glass bar, laid out as the vertical bar (`-[CYLTabBar plusButtonIndex]`).
    // issue #13：缩小后的液态玻璃 TabBar，与竖向栏相同处理（见 `-[CYLTabBar plusButtonIndex]`）。
    if ([self cyl_isInMinimizedBar]) {
        return center;
    }
    // The image's offset from the plus button's center. 图片中心相对 PlusButton 中心的偏移。
    CGRect imageFrame = [imageView.superview convertRect:imageView.frame toView:self];
    if ([objc_getAssociatedObject(self, @selector(cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:)) boolValue]) {
        CGRect titleFrame = CGRectZero;
        [self cyl_getImageFrame:&imageFrame titleFrame:&titleFrame];
    }
    CGFloat imageOffsetX = CGRectGetMidX(imageFrame) - CGRectGetMidX(self.bounds);
    CGFloat imageOffsetY = CGRectGetMidY(imageFrame) - CGRectGetMidY(self.bounds);
    // Its own title first (the tab item's), else the other tab titles, which share its center line.
    // 优先用它自己的标题（TabBarItem 的），没有时用其他 Tab 标题（中心线相同）。
    // FIX: issue #601
    // [EN] Both in the normal layer only: the titles and the plus button are not in the same layer, and a title of
    //      another layer (the selected layer, seen through the lens) does not convert to the plus button's position.
    // [CN] 两者都只取普通图层中的：标题与 PlusButton 不在同一个图层，其他图层（透过放大镜显示的选中图层）中的标题无法
    //      换算为 PlusButton 的位置。
    UILabel *ownTitleLabel = [self cyl_ownTitleLabelInTabBarItemNearX:center.x inView:container];
    UILabel *itemTitleLabel = ownTitleLabel;
    if (!itemTitleLabel) {
        for (UILabel *label in [self cyl_tabBarItemTitleLabels]) {
            if ([self cyl_isViewInNormalTabLayer:label]) {
                itemTitleLabel = label;
                break;
            }
        }
    }
    if (itemTitleLabel) {
        [itemTitleLabel.superview layoutIfNeeded];
        CGFloat itemTitleCenterY = [itemTitleLabel.superview convertPoint:itemTitleLabel.center toView:container].y;
        // [EN] With the image's current height, so a later or replaced image keeps its bottom edge where it was.
        // [CN] 使用图片当前的高度，之后设置或替换的图片底边位置不变。
        CGFloat imageToTitle = imageBottomToTitle.doubleValue + CGRectGetHeight(imageFrame) * 0.5;
        center.y = itemTitleCenterY - imageToTitle - imageOffsetY;
    }
    if (ownTitleLabel) {
        center.x = [ownTitleLabel.superview convertPoint:ownTitleLabel.center toView:container].x - imageOffsetX;
    }
    return center;
}

/*!
 * FIX: issue #601
 * [EN] The tab item's label that shows the plus button's title, in the normal layer, near `x` (the plus tab's center in
 *      `container`, the plus button's superview). The titles are not in the plus button's layer: Liquid Glass draws each
 *      one in the normal layer and again in the selected layer (through the lens), and while the plus child view
 *      controller is selected the normal one can be hidden. The first visible label with the title was then a copy of
 *      another layer, whose position does not convert to the plus button's: after "Change all network icons" and a tap
 *      on the plus button, the plus button moved to x = 0. Now only a label in the normal layer counts, hidden or not
 *      (it stays laid out), the nearest to `x`, and none farther than half its tab button's width: the plus button then
 *      keeps `x`.
 * [CN] 普通图层中显示 PlusButton 标题、且靠近 `x`（PlusButton 的 Tab 在 `container`，即 PlusButton 父视图中的中心）的 TabBarItem
 *      标签。标题与 PlusButton 不在同一个图层：液态玻璃在普通图层绘制每个标题，并在选中图层（透过放大镜）再绘制一次；选中
 *      PlusButton 子控制器时，普通图层的标题可能被隐藏。此前找到的第一个带该标题的可见标签因此是其他图层中的副本，其位置无法换算为
 *      PlusButton 的位置：点击「更换所有网络图标」后再点击 PlusButton，PlusButton 移到了 x = 0。现在只取普通图层中的标签（隐藏的
 *      也可以，它仍保持布局），取离 `x` 最近的一个，且距离不超过其 Tab 按钮宽度的一半；否则 PlusButton 保持 `x`。
 */
- (UILabel *)cyl_ownTitleLabelInTabBarItemNearX:(CGFloat)x inView:(UIView *)container {
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    UIView *systemTabBar = self.superview;
    while (systemTabBar && ![systemTabBar isKindOfClass:[UITabBar class]]) {
        systemTabBar = systemTabBar.superview;
    }
    if (movedTitle.length == 0 || !systemTabBar || !container) {
        return nil;
    }
    // [EN] FIX: placeholder count mismatch — first the tab button of the plus button's slot itself (its placeholder or
    //      plus child view controller, `-cyl_viewControllerOfTabBarItem`): `tabBarItem.cyl_tabButton` is that tab's
    //      button in the normal layer, so neither another layer's copy nor another tab with the same title can be taken.
    //      Searching the whole tab bar by text, below, is only the fallback while that button is not known yet.
    // [CN] FIX：占位导致的数量不匹配——先直接取 PlusButton 的 slot（占位控制器或 PlusButton 子控制器，`-cyl_viewControllerOfTabBarItem`）
    //      对应的 Tab 按钮：`tabBarItem.cyl_tabButton` 就是该 Tab 在普通图层中的按钮，既不会取到其他图层的副本，也不会取到同名的其他 Tab。
    //      下面按文字在整个 TabBar 中查找，只是该按钮尚不可知时的备选。
    UILabel *slotLabel = [self cyl_titleLabel:movedTitle inSlotTabButtonNearX:x inView:container];
    if (slotLabel) {
        return slotLabel;
    }
    UILabel *nearestLabel = nil;
    CGFloat nearestDistance = CGFLOAT_MAX;
    NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:systemTabBar];
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        // [EN] Not the plus button, nor anything in the selected layer. [CN] 跳过 PlusButton 及选中图层中的一切。
        if (view == self || view.cyl_isPlatterSelectedContentView) {
            continue;
        }
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            UIControl *tabButton = [self cyl_tabButtonOfTabBarItemTitleLabel:label];
            if ([label.text isEqualToString:movedTitle] && label.window && tabButton &&
                [self cyl_isViewInNormalTabLayer:label]) {
                CGFloat distance = fabs([label.superview convertPoint:label.center toView:container].x - x);
                if (distance <= CGRectGetWidth(tabButton.bounds) * 0.5 && distance < nearestDistance) {
                    nearestLabel = label;
                    nearestDistance = distance;
                }
            }
            continue;
        }
        [views addObjectsFromArray:view.subviews];
    }
    return nearestLabel;
}

/*!
 * [EN] The label showing `title` in the normal-layer tab button of the plus button's slot, within half that button's width
 *      of `x` (in `container`); nil when the slot's tab button is not known, not in the normal layer, or has no such label.
 *      A hidden label counts: it stays laid out while the plus child view controller is selected.
 * [CN] PlusButton 的 slot 在普通图层中的 Tab 按钮里显示 `title` 的标签，且与 `x`（在 `container` 中）的距离不超过该按钮宽度的一半；
 *      slot 的 Tab 按钮未知、不在普通图层或没有该标签时返回 nil。隐藏的标签也可以：选中 PlusButton 子控制器时它仍保持布局。
 */
- (UILabel *)cyl_titleLabel:(NSString *)title inSlotTabButtonNearX:(CGFloat)x inView:(UIView *)container {
    UIControl *slotTabButton = [self cyl_viewControllerOfTabBarItem].tabBarItem.cyl_tabButton;
    if (![slotTabButton isKindOfClass:[UIControl class]] || !slotTabButton.window || slotTabButton == (UIControl *)self) {
        return nil;
    }
    if ([CYLConstants isLiquidGlassActive] && !slotTabButton.cyl_isPlatterNormalControl) {
        return nil;
    }
    NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:slotTabButton];
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        if (view == self || view.cyl_isPlatterSelectedContentView) {
            continue;
        }
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if ([label.text isEqualToString:title]) {
                CGFloat distance = fabs([label.superview convertPoint:label.center toView:container].x - x);
                return (distance <= CGRectGetWidth(slotTabButton.bounds) * 0.5) ? label : nil;
            }
            continue;
        }
        [views addObjectsFromArray:view.subviews];
    }
    return nil;
}

/*!
 * FIX: issue #601
 * [EN] Whether `view` is in the normal layer of the tab buttons: under no Liquid Glass selected layer, and, with Liquid
 *      Glass, in a tab button of the normal layer (`-cyl_isPlatterNormalControl`). Always YES without Liquid Glass.
 * [CN] `view` 是否位于 Tab 按钮的普通图层：不在液态玻璃的选中图层之下，且液态玻璃下位于普通图层的 Tab 按钮
 *      （`-cyl_isPlatterNormalControl`）中。非液态玻璃时总是 YES。
 */
- (BOOL)cyl_isViewInNormalTabLayer:(UIView *)view {
    if (![CYLConstants isLiquidGlassActive]) {
        return YES;
    }
    for (UIView *ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
        if (ancestor.cyl_isPlatterSelectedContentView) {
            return NO;
        }
    }
    UIControl *tabButton = [self cyl_tabButtonOfTabBarItemTitleLabel:(UILabel *)view];
    return tabButton.cyl_isPlatterNormalControl;
}

/*!
 * [EN] Liquid Glass shows the plus button's stand-in (`-selectedContentView`) in the selected layer, another view
 *      hierarchy: keep it on the plus button's position (converted between the two layers) whenever the plus button moves.
 * [CN] 液态玻璃在选中图层（另一个视图层级）中显示 PlusButton 的替身（`-selectedContentView`）：PlusButton 每次移动时，通过坐标转换让替身
 *      保持在 PlusButton 的位置。
 */
- (void)cyl_moveSelectedContentViewWithPlusButton {
    if ([self cyl_standInFollowsPlusButton]) {
        [self cyl_placeSelectedContentView];
    }
}

/// [EN] Puts the stand-in in place (`CYLPlusButtonCenterOfStandIn()`). [CN] 放置替身（`CYLPlusButtonCenterOfStandIn()`）。
- (void)cyl_placeSelectedContentView {
    UIButton *selectedContentView = _selectedContentView;
    if (!selectedContentView.superview || !self.superview || selectedContentView == self) {
        return;
    }
    [selectedContentView layoutIfNeeded];
    CGPoint center = CYLPlusButtonCenterOfStandIn(self, selectedContentView);
    if (!CGPointEqualToPoint(center, selectedContentView.center)) {
        selectedContentView.center = center;
    }
    [self cyl_updateLiquidGlassMask];
}

//TODO:  update to layoutSubviewsOfSelectedContentView name
- (void)cyl_updateLiquidGlassMask {
    // showing selected plusbutton. you can update plusbutton focus, spotlight , in selected plusbutton
    //didShowSelectChildVIewControllerPlusbuttonDidAppear
    //layoutSubviewsOfSelectedContentView
    return;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    // [EN] The glass moves to or away from the plus button. [CN] 玻璃移到 PlusButton 上或离开。
    [self cyl_updateLiquidGlassMask];
}

/// See `+alignsTitleWithTabBarItemTitles`.
- (void)cyl_alignTitleWithTabBarItemTitlesIfNeeded {
    if (![self cyl_alignsTitleWithTabBarItemTitles]) {
        return;
    }
    [self cyl_restoreTitleFromTabBarItemIfNeeded];
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
        // The title's size changes with the font: room for it, then align it after the next layout.
        // 标题尺寸随字体变化：先留出空间，下次布局后再对齐。
        [self cyl_growToFitContentIfNeeded];
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
    // [EN] Recorded for the layout of `+cyl_plusButtonWithImage:…` (`-cyl_getImageFrame:titleFrame:`), which puts its
    //      image above this line; a new line lays the button out again, once.
    // [CN] 供 `+cyl_plusButtonWithImage:…` 的布局（`-cyl_getImageFrame:titleFrame:`）使用，图片放在这条线上方；线变化时重新布局一次。
    if (titleLabel.superview == self) {
        NSNumber *recorded = objc_getAssociatedObject(self, CYLPlusButtonAlignedTitleCenterYKey);
        if (recorded == nil || fabs(recorded.doubleValue - itemTitleCenter.y) >= 0.5) {
            objc_setAssociatedObject(self, CYLPlusButtonAlignedTitleCenterYKey, @(itemTitleCenter.y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self setNeedsLayout];
        }
    }
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
    if (!objc_getAssociatedObject(self, CYLPlusButtonOriginalTitleFontKey) && self.titleLabel.font) {
        objc_setAssociatedObject(self, CYLPlusButtonOriginalTitleFontKey, self.titleLabel.font, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if (label.text.length == 0) {
        return NO;
    }
    // [EN] A badge never sits right inside a control (it is on the badge's anchor or in the icon view), so a control's
    //      own label is not asked: a control's `cyl_badge` creates and pins that anchor, and doing so here, during the
    //      plus button's layout, laid it out again forever (e.g. a plus button whose image loads later).
    // [CN] 角标不会直接位于控件之中（它在角标锚点或图标视图上），因此不询问控件自身的标签：控件的 `cyl_badge` 会创建并约束该锚点，
    //      在 PlusButton 布局期间这样做会使其无限布局（例如图片之后才加载的 PlusButton）。
    if (![label.superview isKindOfClass:[UIControl class]] && label == (UILabel *)label.superview.cyl_badge) {
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
    [self cyl_updateLiquidGlassMask];
    // [EN] Issue #91: keep the touchable area overlay on the button.
    // [CN] 保持可点击区域覆盖层与按钮一致。
    if (_showsTouchableArea) {
        [self cyl_updateTouchableAreaView];
    }
    if (![objc_getAssociatedObject(self, @selector(cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:)) boolValue]) {
        return;
    }
    [self cyl_layOutContentOnce:^{
        [self cyl_layOutImageAndTitle];
    }];
}

- (void)cyl_layOutImageAndTitle {
    CGRect imageFrame = CGRectZero;
    CGRect titleFrame = CGRectZero;
    [self cyl_getImageFrame:&imageFrame titleFrame:&titleFrame];
    self.imageView.bounds = (CGRect){CGPointZero, imageFrame.size};
    self.imageView.center = CGPointMake(CGRectGetMidX(imageFrame), CGRectGetMidY(imageFrame));
    self.titleLabel.bounds = (CGRect){CGPointZero, titleFrame.size};
    self.titleLabel.center = CGPointMake(CGRectGetMidX(titleFrame), CGRectGetMidY(titleFrame));
}

/*!
 * [EN] The image above the title of `+cyl_plusButtonWithImage:…`, from the bounds and the title font alone, in the
 *      button's coordinates. Also what the title-in-tab-item layout (#636) measures, so the result never depends on
 *      when the measurement runs: an image set later is measured as the same image set at launch.
 * [CN] `+cyl_plusButtonWithImage:…` 中位于标题上方的图片：只由 bounds 与标题字体计算，坐标系为按钮。标题由 TabBarItem 显示的布局（#636）
 *      也测量这里的结果，因此与测量时机无关：之后设置的图片与启动时就设置的同一图片测量结果相同。
 */
- (void)cyl_getImageFrame:(CGRect *)imageFrame titleFrame:(CGRect *)titleFrame {
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat imageWidth = width * 0.7;
    CGFloat imageHeight = imageWidth * 0.9;
    CGFloat lineHeight = self.titleLabel.font.lineHeight;
    CGFloat verticalMargin = (CGRectGetHeight(self.bounds) - lineHeight - imageHeight) * 0.5;
    // [EN] The image keeps its natural size (UIButton's), centered where this layout puts the image box: resizing the
    //      image view made it ask UIButton for a layout, which put it back, forever (Flat, an image set later).
    // [CN] 图片保持其原始尺寸（与 UIButton 一致），居中于本布局的图片区域：修改图片视图的尺寸会让它请求 UIButton 重新布局，UIButton 又把它改回去，
    //      无限循环（扁平样式，之后才设置的图片）。
    CGSize imageSize = [self imageForState:UIControlStateNormal].size;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        imageSize = CGSizeMake(imageWidth, imageHeight);
    }
    CGPoint imageCenter = CGPointMake(width * 0.5, verticalMargin + imageHeight * 0.5);
    CGFloat titleCenterY = imageHeight + verticalMargin * 2 + lineHeight * 0.5 + 10;
    // [EN] Title aligned with the tab titles and kept in the button (FlatDesign, the classic tab bar): the title on their
    //      line and the image right above it, like a tab icon. Centered on the button instead, a 60 pt image covered
    //      its own title.
    // [CN] 标题与 Tab 标题对齐且留在按钮中时（扁平样式、经典 TabBar）：标题位于其中心线上，图片紧挨在标题上方，与 Tab 图标一致。若图片居中于按钮，
    //      60 pt 的图片会盖住自己的标题。
    NSNumber *alignedTitleCenterY = objc_getAssociatedObject(self, CYLPlusButtonAlignedTitleCenterYKey);
    if (alignedTitleCenterY != nil && ![self cyl_showsTitleInTabBarItem]) {
        titleCenterY = alignedTitleCenterY.doubleValue;
        imageCenter.y = titleCenterY - lineHeight * 0.5 - CYLPlusButtonImageToTitleSpacing - imageSize.height * 0.5;
    }
    *imageFrame = CGRectMake(imageCenter.x - imageSize.width * 0.5, imageCenter.y - imageSize.height * 0.5,
                             imageSize.width, imageSize.height);
    *titleFrame = CGRectMake(0, titleCenterY - lineHeight * 0.5, width, lineHeight);
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
    [self cyl_installLargeContentViewerInteractionIfNeeded];
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
    // [EN] The pressed animation (`CYLTabButtonAnimation` highlight / dehighlight), played by the tab bar controller.
    // [CN] 按下动画（`CYLTabButtonAnimation` 的 highlight / dehighlight），由 TabBarController 播放。
    [self addTarget:self action:@selector(cyl_tabButtonHighlightTouchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(cyl_tabButtonHighlightTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
}

- (void)cyl_tabButtonHighlightTouchDown {
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController];
    if ([tabBarController respondsToSelector:@selector(cyl_tabButtonTouchDown:)]) {
        [tabBarController cyl_tabButtonTouchDown:self];
    }
}

- (void)cyl_tabButtonHighlightTouchUp {
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController];
    if ([tabBarController respondsToSelector:@selector(cyl_tabButtonTouchUp:)]) {
        [tabBarController cyl_tabButtonTouchUp:self];
    }
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
    // [EN] Only the stand-in is shown highlighted. The registered plus button was highlighted here too and stayed so: UIKit
    //      then drew its image darkened (e.g. Example-PAG's circle above the glass while its page was selected).
    // [CN] 只有替身以高亮状态显示。原先这里也把已注册的 PlusButton 设为高亮且一直保持，系统因此把它的图片画暗（如 Example-PAG 选中
    //      其页面时，玻璃上方的圆形变暗）。
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
            CYLPlusButtonDrawImagesAsIs(button);
            _selectedContentView = button;
            // FIX: the plus button's stand-in kept the original image after a theme
            // [EN] Liquid Glass only (the stand-in is shown in the selected layer while the plus child view controller is
            //      selected). The class makes a new plus button, with the app's original images: a theme applied before
            //      the plus child was first selected (e.g. the theme restored at launch) left the stand-in with the old
            //      image over the themed plus button, which showed blurred through the glass around it. Give it the images
            //      set since then.
            // [CN] 仅液态玻璃（选中 PlusButton 子控制器时，选中图层显示替身）。类方法会新建一个 PlusButton，使用 App 原来的图片：在第一次选中
            //      PlusButton 子控制器之前应用的主题（例如启动时恢复的主题）使替身保持旧图片，盖在换肤后的 PlusButton 上，周围透过玻璃显示为模糊。
            //      这里为替身设置之后更新过的图片。
            if ([self cyl_standInShowsNormalImageOnly]) {
                [self cyl_updateSelectedContentViewImage];
            } else if (button != self && CYLPlusButtonIsInLiquidGlassTabBar(self)) {
                UIImage *image = objc_getAssociatedObject(self, CYLPlusButtonUpdatedImageKey);
                UIImage *selectedImage = objc_getAssociatedObject(self, CYLPlusButtonUpdatedSelectedImageKey);
                if (image) {
                    [button setImage:image forState:UIControlStateNormal];
                    [button setImage:(selectedImage ?: image) forState:UIControlStateHighlighted];
                }
                if (selectedImage) {
                    [button setImage:selectedImage forState:UIControlStateSelected];
                    [button setImage:selectedImage forState:UIControlStateHighlighted];
                }
            }
            [self cyl_showRequestedBadgeIfNeeded];
            return _selectedContentView;
        }
    }
    UIButton *selectedContentView = [UIButton buttonWithType:UIButtonTypeCustom];

    [selectedContentView setImage:CYLPlusButtonOriginalImage([[self class] contentImage] ?: self.contentImage ?: UIImage.new)
                         forState:UIControlStateNormal];
    [selectedContentView setImage:CYLPlusButtonOriginalImage([[self class] selectedContentImage] ?: self.selectedContentImage ?: UIImage.new)
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
    [self cyl_updateSelectedContentViewImage];
    [self cyl_showRequestedBadgeIfNeeded];
    return _selectedContentView;
}

- (NSString *)cyl_title {
    NSString *movedTitle = objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey);
    return movedTitle.length > 0 ? movedTitle : (self.currentTitle.length > 0 ? self.currentTitle : nil);
}

- (void)cyl_updateTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)selectedImage {
    // [EN] Also for the stand-in, which may be a plain UIButton. [CN] 替身可能是普通 UIButton，同样按原图绘制。
    image = CYLPlusButtonOriginalImage(image);
    selectedImage = CYLPlusButtonOriginalImage(selectedImage);
    if (title) {
        if (objc_getAssociatedObject(self, CYLPlusButtonMovedTitleKey)) {
            // [EN] Shown by the tab item under the plus button (#636): its title changes, the layout follows (#729).
            // [CN] 由 PlusButton 下方的 TabBarItem 显示（#636）：修改其标题，布局随之更新（#729）。
            objc_setAssociatedObject(self, CYLPlusButtonMovedTitleKey, title, OBJC_ASSOCIATION_COPY_NONATOMIC);
            [self cyl_updateTitleInTabBarItem];
        } else {
            BOOL hasSelectedTitle = [self titleForState:UIControlStateSelected] != nil;
            [self setTitle:title forState:UIControlStateNormal];
            if (hasSelectedTitle) {
                [self setTitle:title forState:UIControlStateSelected];
            }
            if (@available(iOS 15.0, *)) {
                UIButtonConfiguration *configuration = self.configuration;
                if (configuration) {
                    configuration.title = title;
                    self.configuration = configuration;
                }
            }
            // [EN] A longer title widens the plus button, around the same center. [CN] 标题变长时加宽 PlusButton，中心不变。
            CGSize fittingSize = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGRectGetHeight(self.bounds))];
            if (fittingSize.width > CGRectGetWidth(self.bounds)) {
                CGPoint center = self.center;
                self.bounds = (CGRect){CGPointZero, CGSizeMake(fittingSize.width, CGRectGetHeight(self.bounds))};
                self.center = center;
            }
        }
    }
    // [EN] A stand-in that shows the normal image only is updated below, not here. [CN] 只显示普通状态图片的替身在下面更新，不在这里。
    UIButton *standIn = (_selectedContentView != self && ![self cyl_standInShowsNormalImageOnly]) ? _selectedContentView : nil;
    for (UIButton *button in (standIn ? @[ self, standIn ] : @[ self ])) {
        if (image) {
            [button setImage:image forState:UIControlStateNormal];
            // [EN] The stand-in is shown highlighted, with the selected look. [CN] 替身以高亮状态显示选中样式。
            [button setImage:(button == self ? image : (selectedImage ?: image)) forState:UIControlStateHighlighted];
        }
        if (selectedImage) {
            [button setImage:selectedImage forState:UIControlStateSelected];
            if (button != self) {
                [button setImage:selectedImage forState:UIControlStateHighlighted];
            }
        }
    }
    [self cyl_updateSelectedContentViewImage];
    if (image) {
        self.contentImage = image;
        objc_setAssociatedObject(self, CYLPlusButtonUpdatedImageKey, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (selectedImage) {
        self.selectedContentImage = selectedImage;
        objc_setAssociatedObject(self, CYLPlusButtonUpdatedSelectedImageKey, selectedImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self cyl_setNeedsTitleAlignment];
    [self setNeedsLayout];
    [self.superview setNeedsLayout];
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

#pragma mark - A plus button from attributes (CYLTabBarControllerPlusButton)

/// [EN] Internal: the plus button's own page, found by `-initWithConfiguration:` (`CYLTabBarItemPageIdentifier`).
/// [CN] 内部使用：PlusButton 自己的页面，由 `-initWithConfiguration:` 查找（`CYLTabBarItemPageIdentifier`）。
NSString *const CYLConfigurationPlusButtonPageKey = @"CYLConfigurationPlusButtonPage";

static const void *CYLConfigurationPlusButtonEntryKey = &CYLConfigurationPlusButtonEntryKey;
static NSString *const CYLConfigurationPlusButtonAttributesKey = @"attributes";
static NSString *const CYLConfigurationPlusButtonActionKey = @"action";
static NSString *const CYLConfigurationPlusButtonContextKey = @"context";
static NSString *const CYLConfigurationPlusButtonDefaultContext = @"CYLTabBarController";

/*!
 * [EN] The plus button of `CYLTabBarControllerPlusButton`. Each registration makes a subclass of its own, which holds that
 *      configuration's attributes, action and context, and gets only the class methods its keys ask for: optional methods
 *      such as `+indexOfPlusButtonInTabBar` or `+plusChildViewController` change the library's behavior just by being
 *      there. So two configurations (two React Native or Flutter tab bars, two contexts) never share answers.
 * [CN] `CYLTabBarControllerPlusButton` 的 PlusButton。每次注册生成一个自己的子类，保存该配置的属性、点击回调与 context，并且只添加其键所需的
 *      类方法：`+indexOfPlusButtonInTabBar`、`+plusChildViewController` 等可选方法只要存在就会改变库的行为。因此两份配置（两个 React Native
 *      或 Flutter TabBar、两个 context）不会共用回答。
 */
@interface CYLConfigurationPlusButton : CYLPlusButton <CYLPlusButtonSubclassing>
@end

@implementation CYLConfigurationPlusButton

+ (NSDictionary *)cyl_configurationEntry {
    return objc_getAssociatedObject(self, CYLConfigurationPlusButtonEntryKey);
}

+ (NSDictionary<NSString *, id> *)cyl_configurationAttributes {
    return [self cyl_configurationEntry][CYLConfigurationPlusButtonAttributesKey];
}

+ (id)plusButton {
    NSDictionary<NSString *, id> *attributes = [self cyl_configurationAttributes];
    NSString *title = attributes[CYLTabBarItemTitle] ?: @"";
    UIImage *backgroundImage = attributes[CYLPlusButtonBackgroundImage];
    CYLConfigurationPlusButton *button;
    if ([backgroundImage isKindOfClass:[UIImage class]]) {
        // [EN] A title drawn on a background image, the button the size of the image (Example-PAG's "Menu").
        // [CN] 画在背景图上的标题，按钮与图片同样大小（Example-PAG 的「菜单」）。
        button = [[self alloc] init];
        [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        // [EN] The same image when highlighted, so the button does not darken on touch. [CN] 高亮时使用同一图片，按下时按钮不会变暗。
        [button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitle:attributes[CYLTabBarItemSelectedTitle] ?: title forState:UIControlStateSelected];
        [button sizeToFit];
    } else {
        button = [self cyl_plusButtonWithImage:attributes[CYLTabBarItemImage]
                                         title:title
                                 selectedTitle:attributes[CYLTabBarItemSelectedTitle]
                            selectedTitleColor:attributes[CYLTabBarItemSelectedTitleColor]];
    }
    UIColor *titleColor = attributes[CYLTabBarItemTitleColor];
    if ([titleColor isKindOfClass:[UIColor class]]) {
        [button setTitleColor:titleColor forState:UIControlStateNormal];
        [button setTitleColor:attributes[CYLTabBarItemSelectedTitleColor] ?: titleColor forState:UIControlStateSelected];
    }
    UIFont *font = attributes[CYLTabBarItemTitleFont];
    if ([font isKindOfClass:[UIFont class]]) {
        button.titleLabel.font = font;
    }
    if ([attributes[CYLPlusButtonKeepsTitleVisible] boolValue]) {
        button.cyl_keepShowingPlusButtonLabel = YES;
    }
    // [EN] Taps reach `cyl_configurationPlusButtonTapped` through the tab bar controller's tap report
    //      (`-cyl_sendDidSelectControl:`), once per tap in every style, also when its own page is selected by the system tab
    //      button under it (Liquid Glass). [CN] 点击通过 TabBarController 的点击上报（`-cyl_sendDidSelectControl:`）到达
    //      `cyl_configurationPlusButtonTapped`：所有样式下每次点击一次，包括其页面由其下方的系统 Tab 按钮选中时（液态玻璃）。
    return button;
}

+ (NSString *)tabBarContext {
    return [self cyl_configurationEntry][CYLConfigurationPlusButtonContextKey] ?: CYLConfigurationPlusButtonDefaultContext;
}

+ (BOOL)alignsTitleWithTabBarItemTitles {
    NSDictionary<NSString *, id> *attributes = [self cyl_configurationAttributes];
    if ([attributes[CYLPlusButtonAlignsTitle] isKindOfClass:[NSNumber class]]) {
        return [attributes[CYLPlusButtonAlignsTitle] boolValue];
    }
    return [attributes[CYLTabBarItemTitle] length] > 0 && !attributes[CYLPlusButtonBackgroundImage];
}

/// [EN] Asked at layout time: answered by this button's class, so by its own configuration. [CN] 布局时询问：由本按钮的类、即其自己的配置回答。
- (BOOL)cyl_alignsTitleWithTabBarItemTitles {
    return [[self class] alignsTitleWithTabBarItemTitles];
}

- (void)cyl_configurationPlusButtonTapped {
    void (^action)(CYLPlusButton *) = [[self class] cyl_configurationEntry][CYLConfigurationPlusButtonActionKey];
    !action ?: action(self);
}

/// [EN] Adds the optional class methods the attributes ask for. [CN] 添加属性所需的可选类方法。
+ (void)cyl_addClassMethodsForAttributes:(NSDictionary<NSString *, id> *)attributes {
    Class metaClass = object_getClass(self);
    if ([attributes[CYLPlusButtonIndexInTabBar] isKindOfClass:[NSNumber class]]) {
        NSUInteger index = [attributes[CYLPlusButtonIndexInTabBar] unsignedIntegerValue];
        class_addMethod(metaClass, @selector(indexOfPlusButtonInTabBar), imp_implementationWithBlock(^NSUInteger(id cls) {
            return index;
        }), "Q@:");
    }
    if ([attributes[CYLPlusButtonCenterYMultiplier] isKindOfClass:[NSNumber class]]) {
        CGFloat multiplier = [attributes[CYLPlusButtonCenterYMultiplier] doubleValue];
        class_addMethod(metaClass, @selector(multiplierOfTabBarHeight:), imp_implementationWithBlock(^CGFloat(id cls, CGFloat tabBarHeight) {
            return multiplier;
        }), "d@:d");
    }
    if ([attributes[CYLPlusButtonCenterYOffset] isKindOfClass:[NSNumber class]]) {
        CGFloat offset = [attributes[CYLPlusButtonCenterYOffset] doubleValue];
        class_addMethod(metaClass, @selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:), imp_implementationWithBlock(^CGFloat(id cls, CGFloat tabBarHeight) {
            return offset;
        }), "d@:d");
    }
    NSString *identifier = attributes[CYLTabBarItemIdentifier];
    if ([identifier isKindOfClass:[NSString class]] && identifier.length > 0) {
        class_addMethod(metaClass, @selector(tabBarItemIdentifier), imp_implementationWithBlock(^NSString *(id cls) {
            return identifier;
        }), "@@:");
    }
    UIViewController *page = attributes[CYLConfigurationPlusButtonPageKey];
    if ([page isKindOfClass:[UIViewController class]]) {
        class_addMethod(metaClass, @selector(plusChildViewController), imp_implementationWithBlock(^UIViewController *(id cls) {
            return page;
        }), "@@:");
    }
}

@end

@implementation CYLPlusButton (CYLConfigurationPlusButton)

+ (void)cyl_registerPlusButtonWithAttributes:(NSDictionary<NSString *, id> *)attributes
                                      action:(void (^)(CYLPlusButton *))action
                                     context:(NSString *)context {
    BOOL hasImage = [attributes[CYLTabBarItemImage] isKindOfClass:[UIImage class]]
        || [attributes[CYLPlusButtonBackgroundImage] isKindOfClass:[UIImage class]];
    if (!hasImage) {
        return;
    }
    static NSUInteger counter = 0;
    NSString *className = [NSString stringWithFormat:@"CYLConfigurationPlusButton_%lu", (unsigned long)++counter];
    Class class = objc_allocateClassPair([CYLConfigurationPlusButton class], className.UTF8String, 0);
    if (!class) {
        return;
    }
    objc_registerClassPair(class);
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    entry[CYLConfigurationPlusButtonAttributesKey] = [attributes copy];
    entry[CYLConfigurationPlusButtonContextKey] = context.length > 0 ? [context copy] : CYLConfigurationPlusButtonDefaultContext;
    if (action) {
        entry[CYLConfigurationPlusButtonActionKey] = [action copy];
    }
    objc_setAssociatedObject(class, CYLConfigurationPlusButtonEntryKey, [entry copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [(Class)class cyl_addClassMethodsForAttributes:attributes];
    [(Class)class registerPlusButton];
}

@end
