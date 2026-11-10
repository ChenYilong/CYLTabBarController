//
//  CYLTabBarHostView.m
//  CYLTabBarController
//
//  v1.100.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 2026/11/08.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarHostView.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

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

NSString *const CYLTabBarHostBadgeValue = @"value";
NSString *const CYLTabBarHostBadgeColor = @"color";
NSString *const CYLTabBarHostBadgeAnimation = @"animation";
NSString *const CYLTabBarHostBadgeRadius = @"radius";
NSString *const CYLTabBarHostBadgeCenterOffset = @"centerOffset";

/// [EN] "#RRGGBB" / "#RRGGBBAA" or a UIColor; nil otherwise. [CN] "#RRGGBB" / "#RRGGBBAA" 或 UIColor；其他为 nil。
static UIColor *_Nullable CYLTabBarHostColor(id value) {
    if ([value isKindOfClass:[UIColor class]]) {
        return value;
    }
    if (![value isKindOfClass:[NSString class]] || ![value hasPrefix:@"#"]) {
        return nil;
    }
    NSString *hex = [value substringFromIndex:1];
    unsigned long long number = 0;
    if ((hex.length != 6 && hex.length != 8) || ![[NSScanner scannerWithString:hex] scanHexLongLong:&number]) {
        return nil;
    }
    CGFloat alpha = hex.length == 8 ? (number & 0xFF) / 255.0 : 1;
    unsigned long long rgb = hex.length == 8 ? number >> 8 : number;
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0 green:((rgb >> 8) & 0xFF) / 255.0 blue:(rgb & 0xFF) / 255.0 alpha:alpha];
}

/// [EN] A `CYLBadgeAnimationType` number or name; `fallback` otherwise. [CN] `CYLBadgeAnimationType` 数字或名称；其他为 `fallback`。
static CYLBadgeAnimationType CYLTabBarHostAnimation(id value, CYLBadgeAnimationType fallback) {
    if ([value isKindOfClass:[NSNumber class]] && [value unsignedIntegerValue] <= CYLBadgeAnimationTypeScaleOnce) {
        return (CYLBadgeAnimationType)[value unsignedIntegerValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSArray<NSString *> *names = @[ @"none", @"scale", @"shake", @"bounce", @"breathe", @"leftrightonce", @"rightleftonce",
                                        @"fadeinonce", @"rollingonce", @"scaleonce" ];
        NSUInteger index = [names indexOfObject:[value lowercaseString]];
        if (index != NSNotFound) {
            return (CYLBadgeAnimationType)index;
        }
    }
    return fallback;
}

/// [EN] Shows the badge `attributes` describe on `target` (a page or the plus button), its style first. [CN] 在 `target`（页面或 PlusButton）上显示 `attributes` 描述的角标，先设置样式。
static void CYLTabBarHostShowBadge(id<CYLBadgeProtocol> target, NSDictionary *attributes, CYLBadgeAnimationType animationType) {
    id value = attributes[CYLTabBarHostBadgeValue];
    NSString *text = [value isKindOfClass:[NSString class]] ? value : ([value isKindOfClass:[NSNumber class]] ? [value stringValue] : @"");
    UIColor *color = CYLTabBarHostColor(attributes[CYLTabBarHostBadgeColor]);
    if (color) {
        target.cyl_badgeBackgroundColor = color;
    }
    if ([attributes[CYLTabBarHostBadgeRadius] isKindOfClass:[NSNumber class]]) {
        target.cyl_badgeRadius = [attributes[CYLTabBarHostBadgeRadius] doubleValue];
    }
    id offset = attributes[CYLTabBarHostBadgeCenterOffset];
    if ([offset isKindOfClass:[NSArray class]] && [offset count] == 2) {
        target.cyl_badgeCenterOffset = CGPointMake([offset[0] doubleValue], [offset[1] doubleValue]);
    } else if ([offset isKindOfClass:[NSValue class]] && strcmp([offset objCType], @encode(CGPoint)) == 0) {
        target.cyl_badgeCenterOffset = [offset CGPointValue];
    }
    CYLBadgeAnimationType animation = CYLTabBarHostAnimation(attributes[CYLTabBarHostBadgeAnimation], animationType);
    if (text.length == 0) {
        [target cyl_clearBadge];
    } else if ([text isEqualToString:@"dot"]) {
        // [EN] A dot animates only with an animation of its own (`badgeAnimationType` is for text badges), as
        //      `cyl_showBadgeValue:@""`. [CN] 红点仅在自身指定动画时播放（`badgeAnimationType` 用于文字角标），与 `cyl_showBadgeValue:@""` 相同。
        if (!attributes[CYLTabBarHostBadgeAnimation] || animation == CYLBadgeAnimationTypeNone) {
            [target cyl_showBadge];
        } else {
            [target cyl_showBadgeValue:@"" animationType:animation];
        }
    } else {
        [target cyl_showBadgeValue:text animationType:animation];
    }
}

@implementation CYLTabBarHostView {
    /// [EN] Bumped by every new configuration, so a slow image load of an older one is dropped. [CN] 每份新配置加一，较早配置的慢速图片加载结果会被丢弃。
    NSUInteger _generation;
    /// [EN] The configuration with its images loaded, waiting for a window and a width. [CN] 已加载图片、等待 window 与宽度的配置。
    NSDictionary<NSString *, id> *_pendingConfiguration;
    /// [EN] `tabCoverImages` loaded (UIImage or NSNull), and the tab buttons now covered. [CN] 已加载的 `tabCoverImages`（UIImage 或 NSNull），以及当前被覆盖的 Tab 按钮。
    NSArray *_loadedTabCoverImages;
    NSMutableArray<NSArray *> *_coveredTabButtons; ///< [EN] @[button, cover, selected cover]. [CN] @[按钮, 覆盖视图, 选中覆盖视图]。
    NSUInteger _coverGeneration;
    /// [EN] The app set `loggedIn`. [CN] App 设置过 `loggedIn`。
    BOOL _loggedInSet;
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

/*!
 * [EN] An image loaded from a value (a file, an asset, a URL) is drawn as is, as an image name or a path in a configuration
 *      (#535): left automatic, the tab bar drew a full color icon as a gray template silhouette.
 * [CN] 由值（文件、asset、URL）加载的图片按原图绘制，与配置中的图片名或路径相同（#535）：保持 automatic 时，TabBar 会把全彩图标画成灰色模板剪影。
 */
static UIImage *CYLTabBarHostOriginalImage(UIImage *image) {
    return image.renderingMode == UIImageRenderingModeAutomatic ? [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] : image;
}

+ (id)imageForValue:(id)value resolver:(UIImage * (^)(id))resolver {
    UIImage *image = resolver ? resolver(value) : nil;
    if (image) {
        return CYLTabBarHostOriginalImage(image);
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
    return image ? CYLTabBarHostOriginalImage(image) : value;
}

+ (NSDictionary *)attributes:(NSDictionary *)attributes withImagesResolvedBy:(UIImage * (^)(id))resolver {
    NSMutableDictionary *result = [attributes mutableCopy];
    for (NSString *key in @[ CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage,
                             CYLPlusButtonBackgroundImage ]) {
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
    [self applyLayoutDirectionToTabBarController:tabBarController];
    if (_tabBarHidden) {
        [tabBarController setTabBarHidden:YES animated:NO];
    }
    if (_titlePositionAdjustment) {
        tabBarController.titlePositionAdjustment = _titlePositionAdjustment.UIOffsetValue;
    }
    UIViewController *parent = [self cyl_hostViewController];
    [parent addChildViewController:tabBarController];
    [self addSubview:tabBarController.view];
    [tabBarController didMoveToParentViewController:parent];
    __weak __typeof(self) weakHost = self;
    tabBarController.cyl_didLongPressControlBlock = ^(CYLTabBarController *controller, UIControl *control) {
        [weakHost didLongPressControl:control];
    };
    // [EN] The app's state once it set one; until then the cached one. [CN] App 设置过时使用其状态；之前使用缓存的状态。
    if (_loggedInSet) {
        tabBarController.cyl_loggedIn = _loggedIn;
    } else {
        _loggedIn = tabBarController.cyl_loggedIn;
    }
    !self.loginStateDidChange ?: self.loginStateDidChange(_loggedIn);
    // [EN] The app shows the login screen: the tab is not selected now (see `didRequestLogin`).
    // [CN] 由 App 展示登录界面：此时不选中该 Tab（见 `didRequestLogin`）。
    tabBarController.cyl_loginHandler = ^(CYLTabBarController *controller, UIViewController *viewController, CYLTabBarLoginCompletion completion) {
        completion(NO);
        __strong __typeof(weakHost) host = weakHost;
        if (!host.didRequestLogin) {
            return;
        }
        NSUInteger index = [CYLTabBarHostPages(controller) indexOfObject:viewController];
        host.didRequestLogin(index == NSNotFound ? -1 : (NSInteger)index, viewController.cyl_tabBarItemIdentifier ?: @"",
                             viewController.tabBarItem.title ?: @"");
    };
    self.tabBarController = tabBarController;
    [self applySelectedIndex];
    [self applyBadgeValues];
    [self applyTabCoverImages];
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
    if (!tabBar || _tabBarHidden) {
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

- (void)setLanguage:(NSString *)language {
    if (language == _language || [language isEqualToString:_language]) {
        return;
    }
    _language = [language copy];
    CYLSetLocalizationLanguage(_language);
    // [EN] Built again: the library's texts and the layout direction are set when the tab bar is created.
    // [CN] 重新创建：库的文字与布局方向在创建 TabBar 时设置。
    if (_tabBarController && _configuration) {
        self.configuration = _configuration;
    }
}

/// [EN] Right to left for a right-to-left language (e.g. Arabic), as the Objective-C example's `[UIView appearance]`.
/// [CN] 从右到左的语言（如阿拉伯语）使用从右到左布局，与 Objective-C 示例的 `[UIView appearance]` 相同。
- (void)applyLayoutDirectionToTabBarController:(CYLTabBarController *)tabBarController {
    BOOL rightToLeft = [NSLocale characterDirectionForLanguage:CYLLocalizationLanguage()] == NSLocaleLanguageDirectionRightToLeft;
    UISemanticContentAttribute attribute = rightToLeft ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeUnspecified;
    tabBarController.view.semanticContentAttribute = attribute;
    tabBarController.tabBar.semanticContentAttribute = attribute;
}

- (void)setTitlePositionAdjustment:(NSValue *)titlePositionAdjustment {
    // [EN] -isEqual:, not -isEqualToValue:, which crashes on nil. [CN] 使用 -isEqual:，-isEqualToValue: 遇到 nil 会崩溃。
    if (titlePositionAdjustment == _titlePositionAdjustment || [titlePositionAdjustment isEqual:_titlePositionAdjustment]) {
        return;
    }
    _titlePositionAdjustment = [titlePositionAdjustment copy];
    if (_titlePositionAdjustment) {
        _tabBarController.titlePositionAdjustment = _titlePositionAdjustment.UIOffsetValue;
    }
}

- (NSString *)simulateMemoryWarning {
    return CYLSimulateMemoryWarningReport(_tabBarController);
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    if (tabBarHidden == _tabBarHidden) {
        return;
    }
    _tabBarHidden = tabBarHidden;
    [_tabBarController setTabBarHidden:tabBarHidden animated:YES];
    [self updateTouchableRects];
}

- (void)resetLoggedIn {
    _loggedInSet = NO;
    _loggedIn = NO;
}

- (void)setLoggedIn:(BOOL)loggedIn {
    _loggedIn = loggedIn;
    _loggedInSet = YES;
    CYLTabBarController *controller = _tabBarController;
    if (!controller || controller.cyl_loggedIn == loggedIn) {
        return;
    }
    NSArray<UIViewController *> *pages = CYLTabBarHostPages(controller);
    UIViewController *before = controller.selectedViewController;
    controller.cyl_loggedIn = loggedIn;
    if (loggedIn) {
        // [EN] A selection the app set while logged out (it may come before the login state) is applied now.
        // [CN] App 在未登录时设置的选中（可能先于登录状态到达）现在生效。
        [self applySelectedIndex];
        return;
    }
    // [EN] Logging out moved the selection away from a tab that needs login: tell the app. [CN] 退出登录使选中离开了需要登录的 Tab：通知 App。
    UIViewController *after = controller.selectedViewController;
    NSUInteger index = [pages indexOfObject:after];
    if (after != before && index != NSNotFound) {
        _selectedIndex = (NSInteger)index;
        !self.didSelectTab ?: self.didSelectTab((NSInteger)index, after.cyl_tabBarItemIdentifier ?: @"");
    }
}

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
    // [EN] Never a tab that needs login while logged out, whatever the order the app sets the values in.
    // [CN] 未登录时不选中需要登录的 Tab，无论 App 以何种顺序设置这些值。
    if (!_tabBarController.cyl_loggedIn && [_tabBarController cyl_isLoginRequiredForViewController:page]) {
        return;
    }
    if (_tabBarController.selectedViewController != page) {
        _tabBarController.selectedViewController = page;
    }
}

- (void)setBadgeValues:(NSArray<NSString *> *)badgeValues {
    _badgeValues = [badgeValues copy] ?: @[];
    [self applyBadgeValues];
}

- (void)setBadgeAttributes:(NSArray *)badgeAttributes {
    _badgeAttributes = [badgeAttributes copy];
    [self applyBadgeValues];
}

- (void)setPlusButtonBadgeAttributes:(NSDictionary<NSString *, id> *)plusButtonBadgeAttributes {
    _plusButtonBadgeAttributes = [plusButtonBadgeAttributes copy];
    [self applyBadgeValues];
}

- (void)applyBadgeValues {
    // [EN] Badges sit on the tab buttons, which exist once the tab bar is laid out. The values are read when the block runs, as
    //      the Android host: a block that waited for a layout shows the current badges, never older ones.
    // [CN] 角标位于 Tab 按钮上，TabBar 布局后按钮才存在。与 Android 宿主相同，在 block 执行时读取值：等待布局的 block 显示当前的角标，
    //      而不是旧的。
    __weak __typeof(self) weakSelf = self;
    [_tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *tabBarController) {
        __strong __typeof(weakSelf) host = weakSelf;
        if (!host) {
            return;
        }
        NSArray<NSString *> *badgeValues = host->_badgeValues;
        NSArray *badgeAttributes = host->_badgeAttributes;
        NSDictionary *plusButtonBadge = host->_plusButtonBadgeAttributes.count > 0 ? host->_plusButtonBadgeAttributes : @{ CYLTabBarHostBadgeValue : host->_plusButtonBadgeValue ?: @"" };
        CYLBadgeAnimationType animationType = (CYLBadgeAnimationType)host->_badgeAnimationType;
        [CYLTabBarHostPages(tabBarController) enumerateObjectsUsingBlock:^(UIViewController *page, NSUInteger index, BOOL *stop) {
            NSDictionary *attributes = index < badgeAttributes.count && [badgeAttributes[index] isKindOfClass:[NSDictionary class]] ? badgeAttributes[index] : nil;
            if (attributes.count == 0) {
                id value = index < badgeValues.count ? badgeValues[index] : @"";
                attributes = @{ CYLTabBarHostBadgeValue : [value isKindOfClass:[NSString class]] ? value : @"" };
            }
            CYLTabBarHostShowBadge(page, attributes, animationType);
        }];
        CYLPlusButton *plusButton = [CYLPlusButton plusButtonForTabBarContext:tabBarController.context];
        if (plusButton) {
            CYLTabBarHostShowBadge(plusButton, plusButtonBadge, animationType);
        }
    }];
}

- (void)setTabCoverImages:(NSArray *)tabCoverImages {
    _tabCoverImages = [tabCoverImages copy];
    NSArray *values = _tabCoverImages ?: @[];
    UIImage * (^resolver)(id) = self.imageResolver;
    NSUInteger generation = ++_coverGeneration;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:values.count];
        for (id value in values) {
            id image = [CYLTabBarHostView imageForValue:value resolver:resolver];
            if ([image isKindOfClass:[NSString class]]) {
                image = [UIImage imageNamed:image];
            }
            [images addObject:[image isKindOfClass:[UIImage class]] ? image : [NSNull null]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self || generation != self->_coverGeneration) {
                return;
            }
            self->_loadedTabCoverImages = images;
            [self applyTabCoverImages];
        });
    });
}

/// [EN] Covers the tab buttons with the loaded images, removing the covers of an earlier list first.
/// [CN] 用已加载的图片覆盖 Tab 按钮，先移除之前列表的覆盖。
- (void)applyTabCoverImages {
    CYLTabBarController *controller = _tabBarController;
    if (!controller || !_loadedTabCoverImages) {
        return;
    }
    // [EN] Read when the block runs, as the badges. [CN] 与角标相同，在 block 执行时读取。
    [controller performWhenTabBarItemsReady:^(CYLTabBarController *tabBarController) {
        NSArray *images = self->_loadedTabCoverImages;
        for (NSArray *covered in self->_coveredTabButtons) {
            UIControl *button = covered[0];
            [covered[1] removeFromSuperview];
            [covered[2] removeFromSuperview];
            [button cyl_coverVisiableTabImageViewOrTabButton:YES contentNewView:covered[1] seclectContentNewView:covered[2]
                                                     offset:UIOffsetZero show:NO delayIfNeededForSeconds:0 completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {}];
        }
        self->_coveredTabButtons = [NSMutableArray array];
        [CYLTabBarHostPages(tabBarController) enumerateObjectsUsingBlock:^(UIViewController *page, NSUInteger index, BOOL *stop) {
            UIImage *image = index < images.count && [images[index] isKindOfClass:[UIImage class]] ? images[index] : nil;
            UIControl *button = page.cyl_tabButton;
            if (!image || !button) {
                return;
            }
            // [EN] A button holding the image, as the Objective-C example's `-selectedCover`: an image view here was taken
            //      for the tab's own icon by the views shown in place of it (a skin's network icons), and hidden on every
            //      selection change. [CN] 与 Objective-C 示例的 `-selectedCover` 相同，用按钮承载图片：使用 image view 时，替换图标的视图
            //      （皮肤的网络图标）会把它当成 Tab 自身的图标，在每次切换选中时将其隐藏。
            UIView * (^cover)(void) = ^UIView * {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [button setImage:image forState:UIControlStateNormal];
                button.frame = (CGRect){CGPointZero, image.size};
                button.contentMode = UIViewContentModeCenter;
                button.imageView.contentMode = UIViewContentModeScaleAspectFit;
                button.userInteractionEnabled = NO;
                // [EN] Decoration over the tab: VoiceOver reads the tab. [CN] Tab 上的装饰：VoiceOver 朗读 Tab 本身。
                button.accessibilityElementsHidden = YES;
                return button;
            };
            UIView *contentCover = cover();
            UIView *selectedCover = cover();
            [button cyl_coverVisiableTabImageViewOrTabButton:YES contentNewView:contentCover seclectContentNewView:selectedCover
                                                     offset:UIOffsetZero show:YES delayIfNeededForSeconds:0.1 completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {}];
            [self->_coveredTabButtons addObject:@[ button, contentCover, selectedCover ]];
        }];
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

/*!
 * [EN] The host is the tab bar controller's delegate, in place of the controller itself, which is its own delegate
 *      otherwise (as the Objective-C example's subclass is, calling `super`). The delegate methods the host does not
 *      handle go to the controller, so it keeps its own behavior: the tap recognizer, login and custom tab actions,
 *      placeholders, and the Liquid Glass lens decisions for the plus button's page.
 * [CN] 宿主代替 TabBarController 担任其 delegate；否则 controller 自己就是 delegate（Objective-C 示例的子类即如此，并调用 `super`）。宿主
 *      未处理的 delegate 方法交给 controller，使其保留自身行为：点击识别、登录与自定义 Tab 操作、占位控制器，以及 PlusButton 页面的液态玻璃放大镜判断。
 */
static BOOL CYLTabBarHostIsDelegateSelector(SEL selector) {
    for (Protocol *protocol in @[ @protocol(UITabBarControllerDelegate), @protocol(CYLTabBarControllerDelegate) ]) {
        if (protocol_getMethodDescription(protocol, selector, NO, YES).name || protocol_getMethodDescription(protocol, selector, YES, YES).name) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([super respondsToSelector:selector]) {
        return YES;
    }
    return CYLTabBarHostIsDelegateSelector(selector) && [_tabBarController respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    if (CYLTabBarHostIsDelegateSelector(selector) && [_tabBarController respondsToSelector:selector]) {
        return _tabBarController;
    }
    return [super forwardingTargetForSelector:selector];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    CYLTabBarController *controller = _tabBarController;
    // [EN] The plus button's own page is selected by the plus button (its page key), which the controller's check, made for
    //      tabs, refuses as the plus slot. [CN] PlusButton 自己的页面由 PlusButton 选中（其页面键）；controller 为 Tab 设计的检查会把它当作 PlusButton 的位置而拒绝。
    if (viewController && viewController == [CYLPlusButton plusChildViewControllerForTabBarContext:controller.context]) {
        [controller updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
        return YES;
    }
    return [controller tabBarController:tabBarController shouldSelectViewController:viewController];
}

/// [EN] Every tap on a tab, also on the selected one, as `-tabBarController:didSelectControl:` in the Objective-C example.
/// [CN] 每次点击 Tab（包括已选中的 Tab），与 Objective-C 示例中的 `-tabBarController:didSelectControl:` 相同。
- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
    CYLTabBarController *controller = _tabBarController;
    if (![control cyl_isTabButton] || [control cyl_isPlusControl]) {
        return;
    }
    UIViewController *selected = controller.selectedViewController;
    NSUInteger index = [CYLTabBarHostPages(controller) indexOfObject:selected];
    if (index != NSNotFound) {
        !self.didSelectTab ?: self.didSelectTab((NSInteger)index, selected.cyl_tabBarItemIdentifier ?: @"");
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    // [EN] The tabs are reported by `-tabBarController:didSelectControl:`; here only the plus button's own page: index -1
    //      and the plus button's identifier. [CN] Tab 由 `-tabBarController:didSelectControl:` 上报；这里只处理 PlusButton 自己的页面：下标 -1 与 PlusButton 的标识。
    CYLTabBarController *controller = _tabBarController;
    if (viewController && viewController == [CYLPlusButton plusChildViewControllerForTabBarContext:controller.context]) {
        NSString *identifier = [CYLPlusButton plusButtonForTabBarContext:controller.context].cyl_tabBarItemIdentifier ?: @"";
        !self.didSelectTab ?: self.didSelectTab(-1, identifier);
    }
}

@end
