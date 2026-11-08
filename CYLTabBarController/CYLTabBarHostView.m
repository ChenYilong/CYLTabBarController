//
//  CYLTabBarHostView.m
//  CYLTabBarController
//
//  v1.100.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 2026/11/08.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarHostView.h"
#import "CYLTabBarController.h"

/// [EN] The pages of the configuration's tabs, in order, without the plus button's placeholder page (Liquid Glass).
/// [CN] 配置中各 Tab 的页面，按顺序，不含 PlusButton 的占位页面（液态玻璃）。
static NSArray<UIViewController *> *CYLTabBarHostPages(UITabBarController *tabBarController) {
    NSMutableArray<UIViewController *> *pages = [NSMutableArray array];
    // [EN] The plus button's own page is not one of the configuration's tabs. [CN] PlusButton 自己的页面不属于配置中的 Tab。
    UIViewController *plusPage = [tabBarController isKindOfClass:[CYLTabBarController class]]
        ? [CYLPlusButton plusChildViewControllerForTabBarContext:((CYLTabBarController *)tabBarController).context] : nil;
    for (UIViewController *viewController in tabBarController.viewControllers) {
        if (!viewController.cyl_isPlaceholder && viewController != plusPage) {
            [pages addObject:viewController];
        }
    }
    return pages;
}

/// [EN] The room left above the icons for a badge. [CN] 图标上方为角标留出的空间。
static const CGFloat CYLTabBarHostBadgeRoom = 8;

#if CYL_FLATDESIGN_AVAILABLE
@interface CYLTabBarHostView () <CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate>
#else
@interface CYLTabBarHostView () <CYLTabBarControllerDelegate>
#endif
@property (nonatomic, strong, readwrite, nullable) CYLTabBarController *tabBarController;
@property (nonatomic, assign, readwrite) CGFloat preferredHeight;
@end

@implementation CYLTabBarHostView {
    /// [EN] Bumped by every new configuration, so a slow image load of an older one is dropped. [CN] 每份新配置加一，较早配置的慢速图片加载结果会被丢弃。
    NSUInteger _generation;
    /// [EN] The configuration with its images loaded, waiting for a window and a width. [CN] 已加载图片、等待 window 与宽度的配置。
    NSDictionary<NSString *, id> *_pendingConfiguration;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _selectedIndex = -1;
        _badgeValues = @[];
        _touchableRects = @[];
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _selectedIndex = -1;
        _badgeValues = @[];
        _touchableRects = @[];
    }
    return self;
}

- (void)dealloc {
    [self removeTabBarController];
}

#pragma mark - Configuration

- (void)setConfiguration:(NSDictionary<NSString *, id> *)configuration {
    _configuration = [configuration copy];
    _generation++;
    _pendingConfiguration = nil;
    if (!_configuration) {
        [self removeTabBarController];
        return;
    }
    NSUInteger generation = _generation;
    NSDictionary *source = _configuration;
    UIImage * (^resolver)(id) = self.imageResolver;
    // [EN] Image loads can be slow (a dev server, a big file): never on the main queue. [CN] 图片加载可能较慢（开发服务器、大文件）：不在主队列进行。
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *resolved = [CYLTabBarHostView configurationWithImagesOf:source resolver:resolver];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self->_generation) {
                return;
            }
            self->_pendingConfiguration = resolved;
            [self buildTabBarControllerIfReady];
        });
    });
}

- (BOOL)setConfigurationJSON:(NSString *)JSON {
    NSData *data = [JSON dataUsingEncoding:NSUTF8StringEncoding];
    id parsed = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
    if (![parsed isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    self.configuration = parsed;
    return YES;
}

+ (id)imageForValue:(id)value resolver:(UIImage * (^)(id))resolver {
    UIImage *image = resolver ? resolver(value) : nil;
    if (image) {
        return image;
    }
    if (![value isKindOfClass:[NSString class]]) {
        return value;
    }
    NSURL *URL = [NSURL URLWithString:value];
    // [EN] A URL (a scheme of two letters or more, so "C:" style paths are not taken for one). [CN] URL（scheme 至少两个字母）。
    if (URL.scheme.length < 2) {
        return value;
    }
    NSData *data = [NSData dataWithContentsOfURL:URL];
    image = data ? [UIImage imageWithData:data scale:UIScreen.mainScreen.scale] : nil;
    return image ?: value;
}

+ (NSDictionary *)attributes:(NSDictionary *)attributes withImagesResolvedBy:(UIImage * (^)(id))resolver {
    NSMutableDictionary *result = [attributes mutableCopy];
    for (NSString *key in @[ CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLPlusButtonBackgroundImage ]) {
        if (result[key]) {
            result[key] = [self imageForValue:result[key] resolver:resolver];
        }
    }
    return result;
}

+ (NSDictionary *)configurationWithImagesOf:(NSDictionary *)configuration resolver:(UIImage * (^)(id))resolver {
    NSMutableDictionary *result = [configuration mutableCopy];
    id items = configuration[CYLTabBarControllerTabBarItemsAttributes];
    if ([items isKindOfClass:[NSArray class]]) {
        NSMutableArray *resolvedItems = [NSMutableArray array];
        [(NSArray *)items enumerateObjectsUsingBlock:^(id item, NSUInteger index, BOOL *stop) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                [resolvedItems addObject:item];
                return;
            }
            NSMutableDictionary *attributes = [[self attributes:item withImagesResolvedBy:resolver] mutableCopy];
            // [EN] Pages are looked up by page ID: a tab with neither a page ID nor an identifier would get no page, and no
            //      tab. The host's pages are empty anyway, so it gets one of its own; the identifier reported stays empty.
            // [CN] 页面按页面 ID 查找：既没有页面 ID 也没有 identifier 的 Tab 得不到页面，也就不会显示。宿主的页面本来就是空的，因此为它
            //      指定一个页面 ID；回调中的 identifier 仍为空。
            if ([attributes[CYLTabBarItemPageIdentifier] length] == 0 && [attributes[CYLTabBarItemIdentifier] length] == 0) {
                attributes[CYLTabBarItemPageIdentifier] = [NSString stringWithFormat:@"CYLTabBarHostView-tab-%lu", (unsigned long)index];
            }
            [resolvedItems addObject:attributes];
        }];
        result[CYLTabBarControllerTabBarItemsAttributes] = resolvedItems;
    }
    id plusButton = configuration[CYLTabBarControllerPlusButton];
    if ([plusButton isKindOfClass:[NSDictionary class]]) {
        result[CYLTabBarControllerPlusButton] = [self attributes:plusButton withImagesResolvedBy:resolver];
    }
    return result;
}

#pragma mark - The tab bar controller

- (void)didMoveToWindow {
    [super didMoveToWindow];
    // [EN] Back in a window (a recycled or moved view): rejoin the view controller hierarchy. [CN] 重新进入 window（被复用或移动的视图）：重新加入视图控制器层级。
    CYLTabBarController *tabBarController = _tabBarController;
    if (self.window && tabBarController && !tabBarController.parentViewController) {
        UIViewController *parent = [self cyl_hostViewController];
        [parent addChildViewController:tabBarController];
        [tabBarController didMoveToParentViewController:parent];
    }
    [self buildTabBarControllerIfReady];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self buildTabBarControllerIfReady];
    // [EN] The tab bar is laid out by the controller's view, after this view: lay it out now, or a resize (Flutter sets
    //      the preferred height) leaves `touchableRects` and the height measured on the old frame.
    // [CN] TabBar 由 controller 的视图在本视图之后布局：在这里先完成布局，否则尺寸变化（Flutter 设置所需高度）后，`touchableRects` 与高度仍按旧
    //      frame 计算。
    [_tabBarController.view layoutIfNeeded];
    [self updatePreferredHeight];
}

- (void)buildTabBarControllerIfReady {
    if (!_pendingConfiguration || !self.window || CGRectGetWidth(self.bounds) <= 0) {
        return;
    }
    NSMutableDictionary *configuration = [_pendingConfiguration mutableCopy];
    _pendingConfiguration = nil;
    [self removeTabBarController];
    // [EN] Every tab bar keeps its own plus button: a context of its own unless the configuration gives one.
    // [CN] 每个 TabBar 保留自己的 PlusButton：配置没有给出 context 时使用自己的 context。
    if (![configuration[CYLTabBarControllerContext] isKindOfClass:[NSString class]]) {
        configuration[CYLTabBarControllerContext] = [NSString stringWithFormat:@"CYLTabBarHostView-%p", self];
    }
    // [EN] The pages belong to the host: each tab gets an empty, transparent one. [CN] 页面由宿主绘制：每个 Tab 得到一个透明的空页面。
    configuration[CYLTabBarControllerPageResolver] = ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
        UIViewController *page = [[UIViewController alloc] init];
        page.view.backgroundColor = UIColor.clearColor;
        return page;
    };
    configuration[CYLTabBarControllerPageLookupOrder] = @[ CYLTabBarPageSourceResolver ];
    if ([configuration[CYLTabBarControllerPlusButton] isKindOfClass:[NSDictionary class]]) {
        __weak __typeof(self) weakSelf = self;
        configuration[CYLTabBarControllerPlusButtonAction] = ^(CYLPlusButton *plusButton) {
            void (^didTapPlusButton)(void) = weakSelf.didTapPlusButton;
            !didTapPlusButton ?: didTapPlusButton();
        };
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:configuration];
    if (tabBarController.viewControllers.count == 0) {
        return;
    }
    tabBarController.delegate = self;
    tabBarController.view.backgroundColor = UIColor.clearColor;
    tabBarController.view.frame = self.bounds;
    tabBarController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIViewController *parent = [self cyl_hostViewController];
    [parent addChildViewController:tabBarController];
    [self addSubview:tabBarController.view];
    [tabBarController didMoveToParentViewController:parent];
    __weak __typeof(self) weakHost = self;
    tabBarController.cyl_didLongPressControlBlock = ^(CYLTabBarController *controller, UIControl *control) {
        [weakHost didLongPressControl:control];
    };
    self.tabBarController = tabBarController;
    [self applySelectedIndex];
    [self applyBadgeValues];
    [self setNeedsLayout];
}

- (void)removeTabBarController {
    CYLTabBarController *tabBarController = _tabBarController;
    if (!tabBarController) {
        return;
    }
    [tabBarController willMoveToParentViewController:nil];
    [tabBarController.view removeFromSuperview];
    [tabBarController removeFromParentViewController];
    _tabBarController = nil;
    [self updateTouchableRects];
}

- (UIViewController *)cyl_hostViewController {
    for (UIResponder *responder = self.nextResponder; responder; responder = responder.nextResponder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return self.window.rootViewController;
}

#pragma mark - Touches

static BOOL CYLTabBarHostRectsContainPoint(NSArray<NSValue *> *rects, CGPoint point);

/// [EN] The plus button and the badges rise above the bar and the view: a touch there belongs to the tab bar, which hit-tests
///      its plus button outside its bounds. [CN] PlusButton 与角标会高出 TabBar 与视图：落在那里的触摸属于 TabBar，TabBar 会在其边界之外检测 PlusButton。
///      With `heightIncludesOverflow`, a touch in the transparent strip above the bar, away from the plus button and its
///      badge, goes to the views below.
///      [CN] `heightIncludesOverflow` 时，落在 TabBar 上方透明区域、且不在 PlusButton 与其角标上的触摸交给下方的视图。
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UITabBar *tabBar = _tabBarController.tabBar;
    BOOL takesTouches = tabBar && !self.hidden && self.alpha > 0.01 && self.userInteractionEnabled;
    // [EN] Above the bar, inside this view or not: the controller's view would hand the touch to a page, so the tab bar is
    //      asked directly. [CN] TabBar 上方（无论是否在本视图内）：controller 的视图会把触摸交给页面，因此直接询问 TabBar。
    if (takesTouches && !CGRectContainsPoint([tabBar convertRect:tabBar.bounds toView:self], point)) {
        UIView *hit = [tabBar hitTest:[self convertPoint:point toView:tabBar] withEvent:event];
        if (hit) {
            return hit;
        }
    }
    if (takesTouches && self.heightIncludesOverflow && !CYLTabBarHostRectsContainPoint(self.touchableRects, point)) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

static BOOL CYLTabBarHostRectsContainPoint(NSArray<NSValue *> *rects, CGPoint point) {
    for (NSValue *rect in rects) {
        if (CGRectContainsPoint(rect.CGRectValue, point)) {
            return YES;
        }
    }
    return NO;
}

/// [EN] The tab bar, and the plus button with what sits on it (its badge), in the view's coordinates.
/// [CN] TabBar，以及 PlusButton 与其上的内容（角标），视图坐标。
- (NSArray<NSValue *> *)currentTouchableRects {
    UITabBar *tabBar = _tabBarController.tabBar;
    if (!tabBar) {
        return @[];
    }
    NSMutableArray<NSValue *> *rects = [NSMutableArray arrayWithObject:[NSValue valueWithCGRect:[tabBar convertRect:tabBar.bounds toView:self]]];
    UIView *plusButton = [CYLPlusButton plusButtonForTabBarContext:_tabBarController.context];
    if ([plusButton isDescendantOfView:tabBar] && !plusButton.hidden) {
        CGRect frame = plusButton.bounds;
        for (UIView *subview in plusButton.subviews) {
            if (!subview.hidden && subview.alpha > 0.01) {
                frame = CGRectUnion(frame, subview.frame);
            }
        }
        [rects addObject:[NSValue valueWithCGRect:[plusButton convertRect:frame toView:self]]];
    }
    return rects;
}

- (void)updateTouchableRects {
    NSArray<NSValue *> *rects = [self currentTouchableRects];
    if ([rects isEqualToArray:_touchableRects]) {
        return;
    }
    _touchableRects = [rects copy];
    !self.touchableRectsDidChange ?: self.touchableRectsDidChange(_touchableRects);
}

#pragma mark - Selection and badges

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [self applySelectedIndex];
}

- (void)applySelectedIndex {
    NSArray<UIViewController *> *pages = CYLTabBarHostPages(_tabBarController);
    if (_selectedIndex < 0 || _selectedIndex >= (NSInteger)pages.count) {
        return;
    }
    UIViewController *page = pages[(NSUInteger)_selectedIndex];
    if (_tabBarController.selectedViewController != page) {
        _tabBarController.selectedViewController = page;
    }
}

- (void)setBadgeValues:(NSArray<NSString *> *)badgeValues {
    _badgeValues = [badgeValues copy] ?: @[];
    [self applyBadgeValues];
}

- (void)applyBadgeValues {
    NSArray<NSString *> *badgeValues = _badgeValues;
    // [EN] Badges sit on the tab buttons, which exist once the tab bar is laid out. [CN] 角标位于 Tab 按钮上，TabBar 布局后按钮才存在。
    NSString *plusButtonBadgeValue = _plusButtonBadgeValue ?: @"";
    CYLBadgeAnimationType animationType = (CYLBadgeAnimationType)_badgeAnimationType;
    [_tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *tabBarController) {
        [CYLTabBarHostPages(tabBarController) enumerateObjectsUsingBlock:^(UIViewController *page, NSUInteger index, BOOL *stop) {
            id value = index < badgeValues.count ? badgeValues[index] : @"";
            NSString *text = [value isKindOfClass:[NSString class]] ? value : @"";
            if (text.length == 0) {
                [page cyl_clearBadge];
            } else if ([text isEqualToString:@"dot"]) {
                [page cyl_showBadge];
            } else {
                [page cyl_showBadgeValue:text animationType:animationType];
            }
        }];
        CYLPlusButton *plusButton = [CYLPlusButton plusButtonForTabBarContext:tabBarController.context];
        if (!plusButton) {
            return;
        }
        if (plusButtonBadgeValue.length == 0) {
            [plusButton cyl_clearBadge];
        } else if ([plusButtonBadgeValue isEqualToString:@"dot"]) {
            [plusButton cyl_showBadge];
        } else {
            [plusButton cyl_showBadgeValue:plusButtonBadgeValue animationType:animationType];
        }
    }];
}

- (void)setPlusButtonBadgeValue:(NSString *)plusButtonBadgeValue {
    _plusButtonBadgeValue = [plusButtonBadgeValue copy];
    [self applyBadgeValues];
}

- (void)didLongPressControl:(UIControl *)control {
    if (!self.didLongPressTab) {
        return;
    }
    NSString *identifier = control.cyl_tabBarItemIdentifier ?: @"";
    NSString *title = control.cyl_tabBarItemDisplayName ?: @"";
    NSInteger index = -1;
    if (!control.cyl_isPlusControl) {
        NSArray<UIViewController *> *pages = CYLTabBarHostPages(_tabBarController);
        for (NSUInteger i = 0; i < pages.count; i++) {
            if (identifier.length > 0 && [pages[i].cyl_tabBarItemIdentifier isEqualToString:identifier]) {
                index = (NSInteger)i;
                break;
            }
        }
    }
    self.didLongPressTab(index, identifier, title);
}

#pragma mark - Height

- (void)updatePreferredHeight {
    UITabBar *tabBar = _tabBarController.tabBar;
    if (!tabBar || CGRectGetHeight(tabBar.frame) <= 0) {
        return;
    }
    [self updateTouchableRects];
    CGFloat height = CGRectGetHeight(tabBar.frame);
    if (self.heightIncludesOverflow) {
        CGFloat overflow = CYLTabBarHostBadgeRoom;
        UIView *plusButton = [CYLPlusButton plusButtonForTabBarContext:_tabBarController.context];
        if ([plusButton isDescendantOfView:tabBar]) {
            overflow = MAX(overflow, -CGRectGetMinY([plusButton convertRect:plusButton.bounds toView:tabBar]));
        }
        height += overflow;
    }
    height = ceil(height);
    if (fabs(height - _preferredHeight) < 0.5) {
        return;
    }
    self.preferredHeight = height;
    !self.preferredHeightDidChange ?: self.preferredHeightDidChange(height);
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [_tabBarController updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSUInteger index = [CYLTabBarHostPages(tabBarController) indexOfObject:viewController];
    if (index == NSNotFound) {
        // [EN] The plus button's own page: index -1 and the plus button's identifier. [CN] PlusButton 自己的页面：下标 -1 与 PlusButton 的标识。
        CYLTabBarController *controller = _tabBarController;
        if (viewController && viewController == [CYLPlusButton plusChildViewControllerForTabBarContext:controller.context]) {
            NSString *identifier = [CYLPlusButton plusButtonForTabBarContext:controller.context].cyl_tabBarItemIdentifier ?: @"";
            !self.didSelectTab ?: self.didSelectTab(-1, identifier);
        }
        return;
    }
    !self.didSelectTab ?: self.didSelectTab((NSInteger)index, viewController.cyl_tabBarItemIdentifier ?: @"");
}

@end
