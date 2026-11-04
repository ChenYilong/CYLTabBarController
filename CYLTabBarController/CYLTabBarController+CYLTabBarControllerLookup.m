//
//  CYLTabBarController+CYLTabBarControllerLookup.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Finding a CYLTabBarController: the registry of live tab bar controllers, tab item identifiers (#408), the selected index without the plus button (#515), the active tab bar controller, and the `cyl_tabBarController` lookups of NSObject and UIViewController.
//      Split out of CYLTabBarController.m without changes.
// [CN] 查找 CYLTabBarController：存活的 TabBarController 注册表、Tab item 标识（#408）、不含 PlusButton 的选中索引（#515）、当前活跃的 TabBarController，以及 NSObject 与 UIViewController 的 `cyl_tabBarController` 查找。
//      从 CYLTabBarController.m 中拆分出来，内容未改动。

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"



#if CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#import "CYLFlatDesignTabBar.h"

#else
#endif


//#import "CYLFlatDesignTabBarItem.h"
//#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
//#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
//#import "CYLFlatDesignTabBarHideTabBar.h"


#if CYL_FLATDESIGN_AVAILABLE
//#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLFlatDesignTabBarItem.h>
#import <CYLTabBarController/UINavigationController+CYLFlatDesignTabBarPrivate.h>
#import <CYLTabBarController/_CYLFlatDesignTabBarParallaxOverlayView.h>
#import <CYLTabBarController/CYLFlatDesignTabBarHideTabBar.h>
#endif


#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
//#import <CYLTabBarController/UIImage+CYLTabBarControllerExtention.h>
//#import <CYLTabBarController/NSObject+CYLTabBarControllerExtention.h>
#else
//#import "CYLTabBarController.h"
//#import "UIImage+CYLTabBarControllerExtention.h"
//#import "NSObject+CYLTabBarControllerExtention.h"
#endif
#import "CYLTabBarController+CYLPrivate.h"

#pragma mark - Live tab bar controllers (most recently active last)

/*!
 * [EN] Every CYLTabBarController that has view controllers, held WEAKLY and ordered by when it last appeared: the last
 *      one is the most recently active. A controller joins at the bottom when it gets its view controllers, moves to the
 *      top in `-viewWillAppear:`, and drops out by itself when it is deallocated. This replaces "the root view
 *      controller" as the answer when nothing more specific is known: with several tab bar controllers (a pushed or
 *      presented one, #414), the root one is often not the one in use.
 * [CN] 所有已设置 viewControllers 的 CYLTabBarController，**弱引用** 保存，按最后一次显示的先后排序：最后一个就是最近活跃的。
 *      控制器在设置 viewControllers 时加入到最底部，在 `-viewWillAppear:` 时移到最顶部，释放后自动移除。
 *      在没有更具体信息时，用它代替“根控制器”作为答案：存在多个 TabBarController 时（push 或 present 出来的，#414），
 *      根控制器往往不是正在使用的那个。
 */
static NSPointerArray *CYLTabBarControllerActivationStack(void) {
    static NSPointerArray *stack;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stack = [NSPointerArray weakObjectsPointerArray];
    });
    return stack;
}

/// Removes `tabBarController`, and the entries of deallocated controllers (their weak pointers are NULL).
static void CYLTabBarControllerActivationStackRemove(NSPointerArray *stack, CYLTabBarController *tabBarController) {
    for (NSInteger index = (NSInteger)stack.count - 1; index >= 0; index--) {
        void *pointer = [stack pointerAtIndex:index];
        if (!pointer || pointer == (__bridge void *)tabBarController) {
            [stack removePointerAtIndex:index];
        }
    }
}

/// `object` is a CYLTabBarController that `matcher` accepts (any one when `matcher` is nil).
static BOOL CYLTabBarControllerMatches(id object, CYLTabBarControllerMatcher matcher) {
    return [object isKindOfClass:[CYLTabBarController class]] && (!matcher || matcher(object));
}

/// The style family a lookup asks for: flat design (`CYLTabBarStyleTypeFlatDesign`), or the system styles (any other
/// value: Default, System, LiquidGlass, as `-cyl_isSystemStyleTabBar` counts them).
static CYLTabBarControllerMatcher CYLTabBarControllerMatcherForStyleType(CYLTabBarStyleType styleType) {
    BOOL wantsFlatDesign = (CYLTabBarStyleTypeFlatDesign == styleType);
    return ^BOOL(CYLTabBarController *tabBarController) {
        return wantsFlatDesign == (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType);
    };
}

/// Unwraps the weak box stored by `-cyl_setTabBarController:` / `-cylflatdesign_setTabBarController:`.
static id CYLTabBarControllerFromWeakBox(id box) {
    id (^block)(void) = box;
    return block ? block() : nil;
}

/// The reference set on `object` with `-cyl_setTabBarController:` or `-cylflatdesign_setTabBarController:`, if accepted.
static CYLTabBarController *CYLTabBarControllerExplicitReference(id object, CYLTabBarControllerMatcher matcher) {
    id tabBarController = CYLTabBarControllerFromWeakBox(objc_getAssociatedObject(object, @selector(cyl_tabBarController)));
    if (CYLTabBarControllerMatches(tabBarController, matcher)) {
        return tabBarController;
    }
#if CYL_FLATDESIGN_AVAILABLE
    tabBarController = CYLTabBarControllerFromWeakBox(objc_getAssociatedObject(object, @selector(cylflatdesign_tabBarController)));
    if (CYLTabBarControllerMatches(tabBarController, matcher)) {
        return tabBarController;
    }
#endif
    return nil;
}

/// The controller of a tab bar (system or flat design): its `delegate`, which the controller sets to itself. Known even
/// before the tab bar is in the controller's view, where the responder chain could not reach it.
static CYLTabBarController *CYLTabBarControllerOwningTabBar(UIResponder *responder) {
    id delegate = nil;
    if ([responder isKindOfClass:[UITabBar class]]) {
        delegate = ((UITabBar *)responder).delegate;
    }
#if CYL_FLATDESIGN_AVAILABLE
    else if ([responder isKindOfClass:[CYLFlatDesignTabBar class]]) {
        delegate = ((CYLFlatDesignTabBar *)responder).delegate;
    }
#endif
    return [delegate isKindOfClass:[CYLTabBarController class]] ? delegate : nil;
}

@implementation CYLTabBarController (CYLTabBarItemIdentifier)

/// This tab bar controller's plus button (its own copy with several tab bar controllers), if any.
- (UIControl *)cyl_identifiedPlusButton {
    return [self hasPlusButton] ? [self cyl_contextPlusButton] : nil;
}

/// The identifier of one of this controller's tabs: the one set, else the default. 已设置的标识，否则为默认值。
- (NSString *)cyl_tabBarItemIdentifierForViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    NSString *identifier = objc_getAssociatedObject(viewController, @selector(cyl_tabBarItemIdentifier));
    return identifier ?: [self cyl_defaultTabBarItemIdentifierForViewController:viewController];
}

+ (NSString *)cyl_defaultTabBarItemIdentifierForClass:(Class)aClass {
    // Swift classes are named "Module.Class"; the module is dropped. Swift 类名形如「模块.类名」，去掉模块名。
    NSString *name = aClass ? NSStringFromClass(aClass) : @"";
    NSRange dot = [name rangeOfString:@"." options:NSBackwardsSearch];
    return dot.location == NSNotFound ? name : [name substringFromIndex:NSMaxRange(dot)];
}

- (NSString *)cyl_defaultTabBarItemIdentifierForViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < viewControllers.count; i++) {
        UIViewController *tab = viewControllers[i];
        if (tab == viewController || [tab cyl_getViewControllerInsteadOfNavigationController] == viewController) {
            index = i;
            break;
        }
    }
    if (index == NSNotFound) {
        return nil;
    }
    UIViewController *tab = viewControllers[index];
    // The plus child view controller is the plus button's tab. PlusButton 子控制器即 PlusButton 对应的 Tab。
    if ([tab cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]] && [self cyl_identifiedPlusButton]) {
        return [self cyl_identifiedPlusButton].cyl_tabBarItemIdentifier;
    }
    Class contentClass = [[tab cyl_getViewControllerInsteadOfNavigationController] class];
    NSString *identifier = [CYLTabBarController cyl_defaultTabBarItemIdentifierForClass:contentClass];
    // The next tabs of the same class: "_2", "_3"... 后续同类的 Tab 依次加 "_2"、"_3"……
    NSUInteger occurrence = 1;
    for (NSUInteger i = 0; i < index; i++) {
        if ([[viewControllers[i] cyl_getViewControllerInsteadOfNavigationController] class] == contentClass) {
            occurrence++;
        }
    }
    return occurrence == 1 ? identifier : [NSString stringWithFormat:@"%@_%lu", identifier, (unsigned long)occurrence];
}

- (NSString *)cyl_selectedTabBarItemIdentifier {
    return [self cyl_tabBarItemIdentifierForViewController:self.selectedViewController];
}

- (NSUInteger)cyl_indexOfTabBarItemIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return NSNotFound;
    }
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        if ([[self cyl_tabBarItemIdentifierForViewController:viewControllers[index]] isEqualToString:identifier]) {
            return index;
        }
    }
    return NSNotFound;
}

- (UIViewController *)cyl_viewControllerWithTabBarItemIdentifier:(NSString *)identifier {
    NSUInteger index = [self cyl_indexOfTabBarItemIdentifier:identifier];
    return index == NSNotFound ? nil : self.viewControllers[index];
}

- (UIViewController *)cyl_selectTabBarItemWithIdentifier:(NSString *)identifier {
    NSUInteger index = [self cyl_indexOfTabBarItemIdentifier:identifier];
    if (index == NSNotFound) {
        return nil;
    }
    self.selectedIndex = index;
    return self.viewControllers[index];
}

- (NSArray<NSString *> *)cyl_tabBarItemIdentifiers {
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (UIViewController *viewController in self.viewControllers) {
        NSString *identifier = [self cyl_tabBarItemIdentifierForViewController:viewController];
        if (identifier) {
            [identifiers addObject:identifier];
        }
    }
    NSString *plusButtonIdentifier = [self cyl_identifiedPlusButton].cyl_tabBarItemIdentifier;
    if (plusButtonIdentifier && ![identifiers containsObject:plusButtonIdentifier]) {
        [identifiers addObject:plusButtonIdentifier];
    }
    return [identifiers copy];
}

- (UIControl *)cyl_controlWithTabBarItemIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    UIControl *plusButton = [self cyl_identifiedPlusButton];
    if ([plusButton.cyl_tabBarItemIdentifier isEqualToString:identifier]) {
        return plusButton;
    }
    return [self cyl_viewControllerWithTabBarItemIdentifier:identifier].cyl_tabButton;
}

@end

#pragma mark - Selected index without the plus button (issue #515)

@implementation CYLTabBarController (CYLSelectedIndexIgnoringPlusButton)

/// [EN] YES for the plus button's child view controller or placeholder. [CN] PlusButton 的子控制器或占位控制器时为 YES。
- (BOOL)cyl_isPlusButtonViewController:(UIViewController *)viewController {
    if (viewController.cyl_isPlaceholder || [viewController cyl_getViewControllerInsteadOfNavigationController].cyl_isPlaceholder) {
        return YES;
    }
    if (![self hasPlusButton] || ![self hasPlusChildViewController]) {
        return NO;
    }
    UIViewController *plusChildViewController = [self cyl_contextPlusChildViewController];
    return plusChildViewController && viewController == plusChildViewController;
}

- (NSArray<UIViewController *> *)cyl_viewControllersIgnoringPlusButton {
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (UIViewController *viewController in self.viewControllers) {
        if (![self cyl_isPlusButtonViewController:viewController]) {
            [viewControllers addObject:viewController];
        }
    }
    return [viewControllers copy];
}

- (NSUInteger)cyl_selectedIndexForIndexIgnoringPlusButton:(NSUInteger)index {
    NSArray<UIViewController *> *viewControllers = self.cyl_viewControllersIgnoringPlusButton;
    if (index >= viewControllers.count) {
        return NSNotFound;
    }
    return [self.viewControllers indexOfObject:viewControllers[index]];
}

- (NSUInteger)cyl_selectedIndexIgnoringPlusButton {
    UIViewController *selectedViewController = self.selectedViewController;
    if (!selectedViewController) {
        return NSNotFound;
    }
    return [self.cyl_viewControllersIgnoringPlusButton indexOfObject:selectedViewController];
}

- (void)cyl_setSelectedIndexIgnoringPlusButton:(NSUInteger)selectedIndexIgnoringPlusButton {
    NSUInteger selectedIndex = [self cyl_selectedIndexForIndexIgnoringPlusButton:selectedIndexIgnoringPlusButton];
    if (selectedIndex == NSNotFound) {
        return;
    }
    self.selectedIndex = selectedIndex;
}

@end

@implementation CYLTabBarController (CYLActiveTabBarController)

+ (void)cyl_registerTabBarController:(CYLTabBarController *)tabBarController {
    if (!tabBarController) {
        return;
    }
    NSPointerArray *stack = CYLTabBarControllerActivationStack();
    @synchronized (stack) {
        for (NSUInteger index = 0; index < stack.count; index++) {
            if ([stack pointerAtIndex:index] == (__bridge void *)tabBarController) {
                return;     // already known: keep its place
            }
        }
        [stack insertPointer:(__bridge void *)tabBarController atIndex:0];
    }
}

+ (void)cyl_markTabBarControllerActive:(CYLTabBarController *)tabBarController {
    if (!tabBarController) {
        return;
    }
    NSPointerArray *stack = CYLTabBarControllerActivationStack();
    @synchronized (stack) {
        CYLTabBarControllerActivationStackRemove(stack, tabBarController);
        [stack addPointer:(__bridge void *)tabBarController];
    }
}

+ (CYLTabBarController *)cyl_tabBarControllerForContext:(NSString *)context matching:(CYLTabBarControllerMatcher)matcher {
    NSPointerArray *stack = CYLTabBarControllerActivationStack();
    @synchronized (stack) {
        for (NSInteger index = (NSInteger)stack.count - 1; index >= 0; index--) {
            CYLTabBarController *tabBarController = (__bridge CYLTabBarController *)[stack pointerAtIndex:index];
            if (!tabBarController) {
                continue;
            }
            if (context && ![tabBarController.cyl_context isEqualToString:context]) {
                continue;
            }
            if (!CYLTabBarControllerMatches(tabBarController, matcher)) {
                continue;
            }
            return tabBarController;
        }
    }
    return nil;
}

+ (CYLTabBarController *)cyl_tabBarControllerForContext:(NSString *)context {
    return [self cyl_tabBarControllerForContext:context matching:nil];
}

+ (CYLTabBarController *)cyl_activeTabBarController {
    // The most recently active one is the context lookup without a context.
    return [self cyl_tabBarControllerForContext:nil];
}

/// Every control under `view` that hosts a Lottie view: the tab buttons of any style (Liquid Glass has a normal and a
/// selected one per tab, flat design has its own buttons).
static void CYLCollectLottieTabButtons(UIView *view, NSMutableArray<UIControl *> *tabButtons) {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIControl class]] && ((UIControl *)subview).cyl_tabBarItemAnimationView) {
            [tabButtons addObject:(UIControl *)subview];
            continue;
        }
        CYLCollectLottieTabButtons(subview, tabButtons);
    }
}

/// One line per tab: badge shown or not, then each Lottie view's `animationSpeed`.
static NSString *CYLTabBarStateDescription(CYLTabBarController *tabBarController) {
    if (!tabBarController) {
        return @"no active CYLTabBarController";
    }
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@ (%@)", NSStringFromClass([tabBarController class]), tabBarController.cyl_context ?: @"default context"];
    [tabBarController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        [description appendFormat:@"\n  tab %@: badge %@", @(idx), [viewController cyl_isShowBadge] ? @"shown" : @"hidden"];
    }];
    NSMutableArray<UIControl *> *tabButtons = [NSMutableArray array];
    CYLCollectLottieTabButtons(tabBarController.cyl_tabBar ?: tabBarController.tabBar, tabButtons);
    for (UIControl *tabButton in tabButtons) {
        UIView *lottieView = tabButton.cyl_tabBarItemAnimationView;
        id speed = [lottieView respondsToSelector:NSSelectorFromString(@"animationSpeed")] ? [lottieView valueForKey:@"animationSpeed"] : @"?";
        [description appendFormat:@"\n  Lottie view in %@ at x = %.0f: animationSpeed %@", NSStringFromClass([tabButton class]), CGRectGetMinX([tabButton convertRect:tabButton.bounds toView:nil]), speed];
    }
    if (tabButtons.count == 0) {
        [description appendString:@"\n  no Lottie views (Lottie not integrated or not configured)"];
    }
    return description;
}

+ (void)cyl_simulateMemoryWarning {
    [self cyl_simulateMemoryWarningForTabBarController:[self cyl_activeTabBarController]];
}

+ (void)cyl_simulateMemoryWarningForTabBarController:(CYLTabBarController *)tabBarController {
    UIApplication *application = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:application];
    if ([application.delegate respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)]) {
        [application.delegate applicationDidReceiveMemoryWarning:application];
    }
    // A real memory warning also calls `-didReceiveMemoryWarning` on the view controllers; the notification does not.
    [tabBarController didReceiveMemoryWarning];
    // Log on the next run loop pass, after whatever the warning released has been released.
    __weak CYLTabBarController *weakTabBarController = tabBarController;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"⚠️ Simulated memory warning (issues #426, #428). Tab bar state afterwards:\n%@", CYLTabBarStateDescription(weakTabBarController));
    });
}

@end

@implementation NSObject (CYLTabBarControllerReferenceExtension)

- (void)cyl_setTabBarController:(nullable CYLTabBarController *)tabBarController {
    id __weak weakObject = tabBarController;
    id (^block)(void) = ^{ return weakObject; };
    objc_setAssociatedObject(self, @selector(cyl_tabBarController),
                             block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 * [EN] The one lookup behind `-cyl_tabBarController` (system styles), `-cylflatdesign_tabBarController` (flat design),
 *      `-cyl_tabBarControllerForStyleType:` and `-cyl_owningTabBarController` (any style, which the plus button registry
 *      uses to find an object's context). `matcher` picks which controllers count (nil: any). In order:
 *      0. a tab bar controller that counts is its own;
 *      1. a reference set explicitly with `-cyl_setTabBarController:` or `-cylflatdesign_setTabBarController:`;
 *      2. where the object is: a view goes up its responder chain, through the tab bar it is in (its `delegate`), to the
 *         view controller that owns it; a view controller goes up its parents. So a tab button, the plus button or a view
 *         in a tab finds its own controller, not the root one;
 *      3. if `fallsBackToActive`, the most recently active one (`+cyl_activeTabBarController`), then the root view
 *         controller, as before.
 * [CN] `-cyl_tabBarController`（系统样式）、`-cylflatdesign_tabBarController`（扁平样式）、`-cyl_tabBarControllerForStyleType:`
 *      和 `-cyl_owningTabBarController`（任意样式，PlusButton 注册表用它确定对象的 context）共用的查找。`matcher` 决定哪些控制器符合（nil 表示任意）。顺序：
 *      0. 符合条件的 TabBarController 就是它自己；
 *      1. 通过 `-cyl_setTabBarController:` 或 `-cylflatdesign_setTabBarController:` 显式设置的引用；
 *      2. 对象所在的位置：View 沿响应链向上，经过它所在的 TabBar（其 `delegate`），到拥有它的 ViewController；ViewController
 *         沿父控制器链向上。因此 Tab 按钮、PlusButton 或 Tab 页面内的 View 找到的是自己的控制器，而不是根控制器；
 *      3. 若 `fallsBackToActive`，取最近活跃的那个（`+cyl_activeTabBarController`），最后才是根控制器（与以前一致）。
 */
- (CYLTabBarController *)cyl_tabBarControllerMatching:(CYLTabBarControllerMatcher)matcher fallsBackToActive:(BOOL)fallsBackToActive {
    // 0. A tab bar controller it accepts is its own: `-visiableTabBarSize` and the `CYL_IS_IPHONE_X` /
    //    `CYL_NoNeed_UIDesignRequiresCompatibility` macros ask `self.cyl_tabBarController` from inside it. Asking an
    //    ancestor or the root instead gave a pushed tab bar controller the outer one's values.
    //    匹配的 TabBarController 就是它自己：`-visiableTabBarSize` 和 `CYL_IS_IPHONE_X` 等宏在控制器内部使用
    //    `self.cyl_tabBarController`。以前取的是上层或根控制器，push 出来的 TabBarController 会拿到外层的值。
    if (CYLTabBarControllerMatches(self, matcher)) {
        return (CYLTabBarController *)self;
    }
    // 1. An explicit reference.
    CYLTabBarController *tabBarController = CYLTabBarControllerExplicitReference(self, matcher);
    if (tabBarController) {
        return tabBarController;
    }
    // 2. Where it is. A view: up its responder chain, through the tab bar it is in (whose `delegate` is the controller),
    //    to the view controller that owns it. A view controller, or that one: up its parents.
    UIViewController *viewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        viewController = ((UIViewController *)self).parentViewController;
    } else if ([self isKindOfClass:[UIView class]]) {
        UIResponder *responder = (UIView *)self;
        for (; responder && ![responder isKindOfClass:[UIViewController class]]; responder = responder.nextResponder) {
            tabBarController = CYLTabBarControllerOwningTabBar(responder);
            if (CYLTabBarControllerMatches(tabBarController, matcher)) {
                return tabBarController;
            }
        }
        viewController = (UIViewController *)responder;
    }
    for (; viewController; viewController = viewController.parentViewController) {
        if (CYLTabBarControllerMatches(viewController, matcher)) {
            return (CYLTabBarController *)viewController;
        }
        tabBarController = CYLTabBarControllerExplicitReference(viewController, matcher);
        if (tabBarController) {
            return tabBarController;
        }
    }
    if (!fallsBackToActive) {
        return nil;
    }
    // 3. Nothing more specific: the most recently active one, not a singleton-like root; the root only when none is known.
    tabBarController = [CYLTabBarController cyl_tabBarControllerForContext:nil matching:matcher];
    if (tabBarController) {
        return tabBarController;
    }
    UIViewController *rootViewController = [CYLGetRootViewController() cyl_getViewControllerInsteadOfNavigationController];
    return CYLTabBarControllerMatches(rootViewController, matcher) ? (CYLTabBarController *)rootViewController : nil;
}

- (CYLTabBarController *)cyl_owningTabBarController {
    // Only where it is: callers decide what to fall back to (the plus button registry must not take another
    // controller's context for a tab bar that is not attached yet).
    return [self cyl_tabBarControllerMatching:nil fallsBackToActive:NO];
}

- (CYLTabBarController *)cyl_tabBarControllerForStyleType:(CYLTabBarStyleType)styleType {
    return [self cyl_tabBarControllerMatching:CYLTabBarControllerMatcherForStyleType(styleType) fallsBackToActive:YES];
}

- (CYLTabBarController *)cyl_tabBarController {
    // System styles (everything but flat design). Falls back to the most recently active one, then the root, as the
    // root fallback did before (#414: with several tab bar controllers the root one is often not the one in use).
    // 系统样式（除扁平样式外）。回退到最近活跃的那个，最后才是根控制器（#414：存在多个 TabBarController 时根控制器往往不是正在使用的那个）。
    return [self cyl_tabBarControllerForStyleType:CYLTabBarStyleTypeDefault];
}

#pragma mark - @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)
// MARK: @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)

#if CYL_FLATDESIGN_AVAILABLE


- (void)cylflatdesign_setTabBarController:(UIViewController *)tabBarController {
    // The property is declared `weak` in the header, so store a weak box instead of
    // retaining the tab bar controller directly. A strong reference here creates a
    // retain cycle (tab bar controller -> child view controller -> tab bar controller)
    // and the whole FlatDesign tab tree is never deallocated after it is popped (#661).
    UIViewController *tabBarController_ = tabBarController;
    objc_setAssociatedObject(self, @selector(cylflatdesign_tabBarController), [self cyl_cylflatdesign_weakBoxWithTarget:tabBarController_], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return;
    }
    if (referenceViewController.cyl_getViewControllerInsteadOfNavigationController) {
        objc_setAssociatedObject(referenceViewController.cyl_getViewControllerInsteadOfNavigationController, @selector(cylflatdesign_tabBarController), [self cyl_cylflatdesign_weakBoxWithTarget:tabBarController_], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    /*!
     *     if ((![tabBarController isKindOfClass:[CYLFlatDesignUIViewController class]]) && (![tabBarController.cyl_getViewControllerInsteadOfNavigationController isKindOfClass:[CYLFlatDesignUIViewController class]]))  {
     return;
     }
     CYLFlatDesignUIViewController *flatDesignTabViewController = nil;
     if ([tabBarController isKindOfClass:[CYLFlatDesignUIViewController class]]) {
     flatDesignTabViewController = (CYLFlatDesignUIViewController *)tabBarController;
     } else if ([tabBarController.cyl_getViewControllerInsteadOfNavigationController isKindOfClass:[CYLFlatDesignUIViewController class]]) {
     flatDesignTabViewController = (CYLFlatDesignUIViewController *)tabBarController.cyl_getViewControllerInsteadOfNavigationController;
     }
     [flatDesignTabViewController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull childViewController, NSUInteger idx, BOOL * _Nonnull stop) {
     objc_setAssociatedObject(childViewController, @selector(cylflatdesign_tabBarController), tabBarController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
     objc_setAssociatedObject(childViewController.cyl_getViewControllerInsteadOfNavigationController, @selector(cylflatdesign_tabBarController), tabBarController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
     }];
     *
     */
}

/// Wraps `target` in a block that only holds it weakly, matching `cyl_setTabBarController:`.
/// The block itself is retained by the associated object, but the target is not.
- (id)cyl_cylflatdesign_weakBoxWithTarget:(UIViewController *)target {
    id __weak weakTarget = target;
    return ^{ return weakTarget; };
}

/*!
 * [EN] Flat design. The same lookup as `-cyl_tabBarController`, `-cyl_tabBarControllerForStyleType:` with
 *      `CYLTabBarStyleTypeFlatDesign`, with two differences kept from before: an explicit reference
 *      (`-cylflatdesign_setTabBarController:`) is returned as it is, and there is no fallback: nil when the object is not
 *      inside a flat design tab bar controller (callers use that to tell whether they are).
 * [CN] 扁平样式。与 `-cyl_tabBarController` 使用同一个查找（`-cyl_tabBarControllerForStyleType:`，传 `CYLTabBarStyleTypeFlatDesign`），
 *      保留以前的两点不同：显式设置的引用（`-cylflatdesign_setTabBarController:`）原样返回；没有回退：对象不在扁平样式的
 *      TabBarController 内时返回 nil（调用方依此判断是否在其中）。
 */
- (UIViewController __kindof *)cylflatdesign_tabBarController {
    UIViewController *viewController = CYLTabBarControllerFromWeakBox(objc_getAssociatedObject(self, @selector(cylflatdesign_tabBarController)));
    if (viewController) {
        return viewController;
    }
    return [self cyl_tabBarControllerMatching:CYLTabBarControllerMatcherForStyleType(CYLTabBarStyleTypeFlatDesign) fallsBackToActive:NO];
}


/*!
 * - (CYLFlatDesignUIViewController *)cyl_nearestParentViewControllerThatIsKindOf:(Class)c {
 UIViewController *controller = self.parentViewController;
 while (controller && ![controller isKindOfClass:c]) {
 controller = controller.parentViewController;
 }
 if (controller && [controller isKindOfClass:c]) {
 return (CYLFlatDesignUIViewController *)controller;
 }
 return nil;
 }
 */
- (UIViewController __kindof *)cyl_nearestParentViewControllerThatIsKindOf:(Class)c {
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    UIViewController *controller = referenceViewController.parentViewController;
    while (controller && ![controller isKindOfClass:c]) {
        controller = controller.parentViewController;
    }
    
    if (controller && [controller isKindOfClass:c]) {
        return (UIViewController *)controller;
    }
    return nil;
}
#endif

@end
