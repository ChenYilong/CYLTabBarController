//
//  CYLPlusButton.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import "UIViewController+CYLTabBarControllerExtention.h"

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
@end

@implementation CYLPlusButtonRegistration
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

@end

// FIX: issue #594 — implemented in CYLTabBarController.m. Declared here so a tap uses the same decision as
// `-setSelectedIndex:` (see `-plusChildViewControllerButtonClicked:`).
@interface CYLTabBarController (CYLPlusButtonSelection)
- (UIControl *)cyl_plusButtonControlIfSelectingPlusChildViewController:(UIViewController *)viewController;
@end

@implementation CYLPlusButton
//@synthesize selected = _selected;
#pragma mark -
#pragma mark - public Methods

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
         NSString *tabBarContext = registration.context;
        if (tabBarContext && tabBarContext.length) {
            [plusChildViewController cyl_setContext:tabBarContext];
        }
        CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        registration.plusButton = plusButton;
        registration.plusButtonWidth = plusButton.frame.size.width;
        [[self class] addSelectViewControllerTarget:plusButton];
        //液态玻璃效果，不允许点击后的特效， 仅能使用系统的玻璃效果。
        if ([CYLConstants isLiquidGlassActive]) {
            //            plusButton.cyl_userInteractionDisabled = YES;
        }
        if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
            // Not stored per context: it is `+indexOfPlusButtonInTabBar` of the class, which `+indexForTabbarItemsCount:` returns.
            CYLPlusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
        } else {
#if defined(DEBUG) || defined(BETA)
            NSAssert(NO, @"[DEBUG INFO]If you want to add PlusChildViewController, you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO]如果你想使用PlusChildViewController样式，你必须同时在你自定义的plusButton中实现 `+indexOfPlusButtonInTabBar`，来指定plusButton的位置");
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
    UIButton *plusButton = registration.plusButton;
    if (plusButton.superview) {
        [plusButton removeFromSuperview];
    }
    UIViewController *plusChildViewController = registration.plusChildViewController;
    if (plusChildViewController) {
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
    UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForTabBarContext:context];
    CYLTabBarController *tabBarController = [sender cyl_owningTabBarController];
    if (![tabBarController.cyl_context isEqualToString:context]) {
        tabBarController = [CYLTabBarController cyl_tabBarControllerForContext:context];
    }
    NSInteger index = plusChildViewController ? [tabBarController.viewControllers indexOfObject:plusChildViewController] : NSNotFound;
    if (!tabBarController || NSNotFound == index) {
        return;
    }
#if CYL_FLATDESIGN_AVAILABLE
    if ([tabBarController.cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
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
    [selectorNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight plusButtonHeight:(CGFloat)plusButtonHeight {
    CGFloat multiplierOfTabBarHeight;
    if ([[self class] respondsToSelector:@selector(multiplierOfTabBarHeight:)]) {
        multiplierOfTabBarHeight = [[self class] multiplierOfTabBarHeight:tabBarHeight];
    }
    
    CYL_DEPRECATED_DECLARATIONS_PUSH
    else if ([[self class] respondsToSelector:@selector(multiplerInCenterY)]) {
        multiplierOfTabBarHeight = [[self class] multiplerInCenterY];
    }
    CYL_DEPRECATED_DECLARATIONS_POP
    
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
    if ([[self class] respondsToSelector:@selector(constantOfPlusButtonCenterYOffsetForTabBarHeight:)]) {
        constantOfPlusButtonCenterYOffset = [[self class] constantOfPlusButtonCenterYOffsetForTabBarHeight:tabBarHeight];
    }
    return constantOfPlusButtonCenterYOffset;
}

/**
 *  按钮选中状态下点击先显示normal状态的颜色，松开时再回到selected状态下颜色。
 *  重写此方法即不会出现上述情况，与 UITabBarButton 相似
 */
//- (void)setHighlighted:(BOOL)highlighted {}

- (CGRect)touchableRect {
    return self.frame;
}

- (UIImage *)getSnapshot {
//    return [CYLPlusButton plusButtonForOwner:self].imageView.image;
    if (_snapshot) {
        UIImage *originalImage = _snapshot;
        UIImage *newImage = originalImage;
        newImage =
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
        // 不使用selected 以避免选中背景
        registeredPlusButton.highlighted = YES;
    }
    UIButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
    if (NO == plusButton.cyl_userInteractionDisabled) {
        // 不使用selected 以避免选中背景
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
        // 不使用selected 以避免选中背景
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
    return [self plusButtonForTabBarContext:[self tabBarContextForOwner:owner]];
}

+ (UIViewController *)plusChildViewControllerForOwner:(id)owner {
    return [self plusChildViewControllerForTabBarContext:[self tabBarContextForOwner:owner]];
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
            NSAssert(NO, @"[DEBUG INFO]If the count of CYLTabbarControllers is odd,you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】[DEBUG INFO] 如果CYLTabbarControllers的个数是奇数，你必须在你自定义的plusButton中实现`+indexOfPlusButtonInTabBar`，来指定plusButton的位置");
#endif
        } else {
            plusButtonIndex = tabbarItemsCount * 0.5;
        }
    }
    return plusButtonIndex;
}

@end
