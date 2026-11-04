//
//  CYLGalleryProvider.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLGalleryProvider.h"
#import <CYLTabBarController/CYLTabBarController.h>

/// [EN] The context of the gallery's tab bars: no plus button is registered for it. [CN] 图库 TabBar 的 context：没有为它注册 PlusButton。
static NSString *const CYLGalleryContext = @"CYLGallery";
/// [EN] The context of the irregular scenes, with their own plus button. [CN] 不规则场景的 context，带有自己的 PlusButton。
static NSString *const CYLGalleryIrregularContext = @"CYLGalleryIrregular";
/// [EN] Context of the plus button that has its own page (Liquid Glass stand-in scenes).
/// [CN] 拥有自己页面的 PlusButton 所属的 context（液态玻璃替身场景）。
static NSString *const CYLGalleryPlusPageContext = @"CYLGalleryPlusPage";

#pragma mark - Colors

static UIColor *CYLGalleryRGB(CGFloat red, CGFloat green, CGFloat blue) {
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0];
}

static UIColor *CYLGalleryGray(CGFloat white) {
    return [UIColor colorWithWhite:white / 255.0 alpha:1.0];
}

#pragma mark - Scene model

@interface CYLGalleryScene ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *subtitle;
@property (nonatomic, copy, readwrite) CYLGallerySceneBuilder builder;
@property (nonatomic, copy, readwrite, nullable) CYLGallerySceneDidPresent didPresent;
@property (nonatomic, assign, readwrite) BOOL pushes;
@end

@implementation CYLGalleryScene

+ (instancetype)sceneWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle
                       builder:(CYLGallerySceneBuilder)builder
                    didPresent:(nullable CYLGallerySceneDidPresent)didPresent {
    CYLGalleryScene *scene = [[self alloc] init];
    scene.title = title;
    scene.subtitle = subtitle;
    scene.builder = builder;
    scene.didPresent = didPresent;
    return scene;
}

+ (instancetype)sceneWithTitle:(NSString *)title subtitle:(NSString *)subtitle builder:(CYLGallerySceneBuilder)builder {
    return [self sceneWithTitle:title subtitle:subtitle builder:builder didPresent:nil];
}

/// [EN] A scene pushed onto the gallery's navigation controller. [CN] push 到图库导航控制器中的场景。
+ (instancetype)sceneWithTitle:(NSString *)title subtitle:(NSString *)subtitle pushingBuilder:(CYLGallerySceneBuilder)builder {
    CYLGalleryScene *scene = [self sceneWithTitle:title subtitle:subtitle builder:builder didPresent:nil];
    scene.pushes = YES;
    return scene;
}

@end

@interface CYLGallerySection ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSArray<CYLGalleryScene *> *scenes;
@end

@implementation CYLGallerySection

+ (instancetype)sectionWithTitle:(NSString *)title scenes:(NSArray<CYLGalleryScene *> *)scenes {
    CYLGallerySection *section = [[self alloc] init];
    section.title = title;
    section.scenes = scenes;
    return section;
}

@end

#pragma mark - Page

/*!
 * [EN] The page shown in every tab: a line of text that changes every two seconds, and a button that pops or dismisses.
 *      Tapping anywhere else pushes a detail page (or presents it without a navigation controller).
 * [CN] 每个 Tab 中显示的页面：每两秒更换一次的文字，以及返回或关闭的按钮。点击其他位置会 push 一个详情页（没有导航控制器时 present）。
 */
@interface CYLGalleryPageViewController : UIViewController
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *backgroundButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong, nullable) NSTimer *textTimer;
@end

@implementation CYLGalleryPageViewController

+ (NSArray<NSString *> *)lines {
    static NSArray<NSString *> *lines;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lines = @[ @"Tap a tab to switch pages.",
                   @"Tap the selected tab again to see its reselect behavior.",
                   @"Press and hold a tab to see its pressed animation.",
                   @"Tap anywhere on this page to push a detail page.",
                   @"Every tab bar here is built with the public API.",
                   @"Badges, colors and fonts can differ from tab to tab.",
                   @"The same code runs with and without Liquid Glass.",
                   @"Use the button below to go back to the gallery." ];
    });
    return lines;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
        return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? UIColor.systemBackgroundColor : CYLGalleryRGB(244, 245, 245);
    }];

    self.backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backgroundButton addTarget:self action:@selector(pushDetailPage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backgroundButton];

    self.textLabel = [[UILabel alloc] init];
    self.textLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    self.textLabel.textColor = UIColor.secondaryLabelColor;
    self.textLabel.numberOfLines = 0;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.text = [self randomLineExcluding:nil];
    [self.view addSubview:self.textLabel];

    UIColor *buttonColor = CYLGalleryGray(100);
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setTitle:@"  Click to pop or dismiss  " forState:UIControlStateNormal];
    [self.closeButton setTitleColor:buttonColor forState:UIControlStateNormal];
    self.closeButton.layer.borderWidth = 2;
    self.closeButton.layer.borderColor = buttonColor.CGColor;
    self.closeButton.layer.cornerRadius = 16;
    [self.closeButton addTarget:self action:@selector(popOrDismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textTimer invalidate];
    __weak __typeof(self) weakSelf = self;
    self.textTimer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer *timer) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            [timer invalidate];
            return;
        }
        strongSelf.textLabel.text = [strongSelf randomLineExcluding:strongSelf.textLabel.text];
        [strongSelf.view setNeedsLayout];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.textTimer invalidate];
    self.textTimer = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    self.backgroundButton.frame = bounds;
    CGFloat padding = 24;
    CGFloat labelWidth = CGRectGetWidth(bounds) - padding * 2;
    CGSize labelSize = [self.textLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    self.textLabel.frame = CGRectMake(padding, (CGRectGetHeight(bounds) - labelSize.height) / 2.0 - 24, labelWidth, labelSize.height);
    CGSize buttonSize = [self.closeButton sizeThatFits:bounds.size];
    self.closeButton.frame = CGRectMake((CGRectGetWidth(bounds) - buttonSize.width) / 2.0, CGRectGetHeight(bounds) - 120, buttonSize.width, 42);
}

- (NSString *)randomLineExcluding:(nullable NSString *)current {
    NSArray<NSString *> *lines = [CYLGalleryPageViewController lines];
    NSString *line = current;
    while (!line || [line isEqualToString:current ?: @""]) {
        line = lines[arc4random_uniform((uint32_t)lines.count)];
    }
    return line;
}

- (void)pushDetailPage {
    CYLGalleryPageViewController *detail = [[CYLGalleryPageViewController alloc] init];
    detail.title = @"Detail";
    detail.hidesBottomBarWhenPushed = YES;
    if (self.navigationController) {
        [self.navigationController pushViewController:detail animated:YES];
        return;
    }
    [self presentViewController:detail animated:YES completion:nil];
}

- (void)popOrDismiss {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - List page (reselect behavior)

/// [EN] A long list, to see `cyl_reselectBehavior` scroll it back to the top. [CN] 一个长列表，用于观察 `cyl_reselectBehavior` 滚动回顶部。
@interface CYLGalleryListViewController : UITableViewController
@end

@implementation CYLGalleryListViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"row"];
    cell.textLabel.text = [NSString stringWithFormat:@"Row %@: tap to push, tap the tab again to go back", @(indexPath.row + 1)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CYLGalleryPageViewController *page = [[CYLGalleryPageViewController alloc] init];
    page.title = [NSString stringWithFormat:@"Row %@", @(indexPath.row + 1)];
    [self.navigationController pushViewController:page animated:YES];
}

@end

#pragma mark - Navigation controller

/// [EN] Light navigation bar; pages pushed after the root hide the tab bar. [CN] 浅色导航栏；根页面之后 push 的页面隐藏 TabBar。
@interface CYLGalleryNavigationController : UINavigationController
@end

@implementation CYLGalleryNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *titleColor = CYLGalleryRGB(38, 38, 38);
    self.navigationBar.translucent = YES;
    self.navigationBar.tintColor = titleColor;
    self.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName : titleColor,
                                                NSFontAttributeName : [UIFont systemFontOfSize:16] };
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (![viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        viewControllerToPresent.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [super pushViewController:viewController animated:animated];
}

@end

#pragma mark - Tab button animations

static void CYLGalleryPlayKeyframes(UIView *view, NSString *keyPath, NSArray *values, NSTimeInterval duration) {
    if (!view) {
        return;
    }
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    animation.values = values;
    animation.duration = duration;
    animation.calculationMode = kCAAnimationCubic;
    [view.layer addAnimation:animation forKey:nil];
}

/// [EN] A springy scale on select and on reselect. [CN] 选中与重复点击时的弹性缩放。
@interface CYLGalleryBounceAnimation : NSObject <CYLTabButtonAnimation>
@end

@implementation CYLGalleryBounceAnimation

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLGalleryPlayKeyframes(iconView, @"transform.scale", @[ @1.0, @1.4, @0.9, @1.15, @0.95, @1.02, @1.0 ], 0.6);
}

- (void)cyl_playReselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [self cyl_playSelectAnimationWithTabButton:button iconView:iconView titleLabel:titleLabel];
}

@end

static const CGFloat CYLGalleryLargeIconScale = 1.15;

/// [EN] Icons drawn 15% larger; a press shrinks the icon to 80% and the release brings it back. [CN] 图标放大 15% 显示；按下缩小到 80%，抬起后恢复。
@interface CYLGalleryHighlightAnimation : NSObject <CYLTabButtonAnimation>
@end

@implementation CYLGalleryHighlightAnimation

- (void)cyl_playSelectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    iconView.transform = CGAffineTransformMakeScale(CYLGalleryLargeIconScale, CYLGalleryLargeIconScale);
}

- (void)cyl_playHighlightAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [UIView animateWithDuration:0.2 animations:^{
        iconView.transform = CGAffineTransformMakeScale(CYLGalleryLargeIconScale * 0.8, CYLGalleryLargeIconScale * 0.8);
    }];
}

- (void)cyl_playDehighlightAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    [UIView animateWithDuration:0.2 animations:^{
        iconView.transform = CGAffineTransformMakeScale(CYLGalleryLargeIconScale, CYLGalleryLargeIconScale);
    }];
}

@end

/// [EN] Press animation plus a full turn on reselect (the newer protocol hooks). [CN] 按下动画，加上重复点击时旋转一周（新增的协议方法）。
@interface CYLGalleryPressAndReselectAnimation : CYLTabButtonPressAnimation
@end

@implementation CYLGalleryPressAndReselectAnimation

- (void)cyl_playReselectAnimationWithTabButton:(UIControl *)button iconView:(UIView *)iconView titleLabel:(UILabel *)titleLabel {
    CYLGalleryPlayKeyframes(iconView, @"transform.rotation.z", @[ @0, @(M_PI), @(2 * M_PI) ], 0.5);
}

@end

/*!
 * [EN] When a badge appears, the icon jumps (badge-changed hook), built with `CYLTabButtonBlockAnimation`: only the block
 *      that is set plays, so selecting the tab plays nothing.
 * [CN] 角标出现时图标跳动（角标变化回调），用 `CYLTabButtonBlockAnimation` 实现：只有设置了的 block 会播放，选中 Tab 时不播放动画。
 */
static CYLTabButtonBlockAnimation *CYLGalleryBadgeJumpAnimation(void) {
    CYLTabButtonBlockAnimation *animation = [[CYLTabButtonBlockAnimation alloc] init];
    animation.badgeChangedAnimation = ^(UIControl *button, UIView *iconView, UIView *badgeView) {
        CYLGalleryPlayKeyframes(iconView, @"transform.translation.y", @[ @0, @(-8), @4, @(-4), @3, @(-2), @0 ], 0.6);
    };
    return animation;
}

/// [EN] When a badge appears, the badge itself scales in (badge-changed hook, `CYLTabButtonBlockAnimation`).
/// [CN] 角标出现时角标自身缩放弹出（角标变化回调，`CYLTabButtonBlockAnimation`）。
static CYLTabButtonBlockAnimation *CYLGalleryBadgeScaleAnimation(void) {
    CYLTabButtonBlockAnimation *animation = [[CYLTabButtonBlockAnimation alloc] init];
    animation.badgeChangedAnimation = ^(UIControl *button, UIView *iconView, UIView *badgeView) {
        CYLGalleryPlayKeyframes(badgeView ?: iconView, @"transform.scale", @[ @1.0, @1.4, @0.9, @1.15, @0.95, @1.02, @1.0 ], 0.6);
    };
    return animation;
}

#pragma mark - Irregular plus button

/*!
 * [EN] The large round center button of the irregular scenes: a teal circle with a light border, raised above the tab
 *      bar, that only responds inside its circle. A tap plays a ripple and shows an action sheet instead of selecting a
 *      page.
 * [CN] 不规则场景中的大号圆形中间按钮：带浅色描边的青色圆形，凸出于 TabBar 之上，只在圆形内响应点击。点击时播放波纹并弹出操作表，
 *      而不是选中某个页面。
 */
@interface CYLGalleryIrregularPlusButton : CYLPlusButton <CYLPlusButtonSubclassing>
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation CYLGalleryIrregularPlusButton

+ (id)plusButton {
    CGFloat diameter = 70;
    CYLGalleryIrregularPlusButton *button = [[self alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    UIView *circleView = [[UIView alloc] initWithFrame:button.bounds];
    circleView.userInteractionEnabled = NO;
    circleView.backgroundColor = CYLGalleryRGB(23, 149, 158);
    circleView.layer.cornerRadius = diameter / 2.0;
    circleView.layer.borderWidth = 3;
    circleView.layer.borderColor = CYLGalleryGray(235).CGColor;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightSemibold];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"camera.fill" withConfiguration:configuration]];
    iconView.tintColor = UIColor.whiteColor;
    iconView.center = CGPointMake(diameter / 2.0, diameter / 2.0);
    [circleView addSubview:iconView];
    [button addSubview:circleView];
    button.circleView = circleView;
    button.iconView = iconView;
    button.accessibilityLabel = @"Camera";
    [button addTarget:button action:@selector(galleryDidTap) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (NSString *)tabBarContext {
    return CYLGalleryIrregularContext;
}

+ (NSUInteger)indexOfPlusButtonInTabBar {
    return 2;
}

+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
    return 0.25;
}

+ (NSString *)tabBarItemIdentifier {
    return @"camera";
}

/// [EN] Only the circle responds. [CN] 只有圆形区域响应。
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGFloat radius = CGRectGetWidth(self.bounds) / 2.0;
    CGFloat dx = point.x - CGRectGetMidX(self.bounds);
    CGFloat dy = point.y - CGRectGetMidY(self.bounds);
    return sqrt(dx * dx + dy * dy) <= radius;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.2 animations:^{
        self.circleView.transform = highlighted ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    }];
}

- (void)galleryDidTap {
    [self playRipple];
    UIViewController *presenter = [self cyl_owningTabBarController];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:nil]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Select from album" style:UIAlertActionStyleDefault handler:nil]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        sheet.popoverPresentationController.sourceView = self;
        sheet.popoverPresentationController.sourceRect = self.bounds;
        [presenter presentViewController:sheet animated:YES completion:nil];
    });
}

/// [EN] A dot that grows over the circle and fades out. [CN] 一个小圆点放大覆盖圆形后淡出。
- (void)playRipple {
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
    dot.layer.cornerRadius = 1;
    dot.backgroundColor = CYLGalleryRGB(10, 66, 91);
    dot.alpha = 0.5;
    dot.center = CGPointMake(CGRectGetMidX(self.circleView.bounds), CGRectGetMidY(self.circleView.bounds));
    [self.circleView insertSubview:dot belowSubview:self.iconView];
    CGFloat scale = CGRectGetWidth(self.circleView.bounds) / 2.0;
    [UIView animateWithDuration:0.4 animations:^{
        dot.transform = CGAffineTransformMakeScale(scale, scale);
        dot.alpha = 0;
    } completion:^(BOOL finished) {
        [dot removeFromSuperview];
    }];
}

@end

#pragma mark - Helpers

/// [EN] Eight tabs: title, SF Symbol and identifier. [CN] 八个 Tab：标题、SF Symbol 与标识。
static NSArray<NSArray<NSString *> *> *CYLGalleryTabSpecs(void) {
    return @[ @[ @"Home", @"house", @"home" ],
              @[ @"Find", @"safari", @"find" ],
              @[ @"Photo", @"camera", @"photo" ],
              @[ @"Favor", @"heart", @"favor" ],
              @[ @"Me", @"person", @"me" ],
              @[ @"Message", @"message", @"message" ],
              @[ @"Shop", @"cart", @"shop" ],
              @[ @"Cardboard", @"shippingbox", @"cardboard" ] ];
}

/// [EN] A template SF Symbol, so per-tab icon colors apply. [CN] 模板 SF Symbol，单个 Tab 的图标颜色可以生效。
static UIImage *CYLGallerySymbol(NSString *name, BOOL filled, CGFloat pointSize) {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:pointSize];
    NSString *symbolName = filled ? [name stringByAppendingString:@".fill"] : name;
    UIImage *image = [UIImage systemImageNamed:symbolName withConfiguration:configuration] ?: [UIImage systemImageNamed:name withConfiguration:configuration];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

/// [EN] The pages of a scene, optionally each in a navigation controller. [CN] 场景中的页面，可选地分别放进导航控制器。
static NSArray<UIViewController *> *CYLGalleryPages(NSUInteger count, BOOL embedsInNavigation) {
    NSMutableArray<UIViewController *> *pages = [NSMutableArray array];
    NSArray<NSArray<NSString *> *> *specs = CYLGalleryTabSpecs();
    for (NSUInteger index = 0; index < count; index++) {
        CYLGalleryPageViewController *page = [[CYLGalleryPageViewController alloc] init];
        if (embedsInNavigation) {
            page.title = (index == 3) ? @"List" : specs[index][0];
            [pages addObject:[[CYLGalleryNavigationController alloc] initWithRootViewController:page]];
        } else {
            [pages addObject:page];
        }
    }
    return pages;
}

/*!
 * [EN] The attributes of `count` tabs. `showsTitles` NO gives image-only tabs; `extra` adds keys per tab (colors,
 *      fonts...) and can return nil.
 * [CN] `count` 个 Tab 的属性。`showsTitles` 为 NO 时为纯图标 Tab；`extra` 为每个 Tab 添加键（颜色、字体……），可以返回 nil。
 */
static NSArray<NSDictionary *> *CYLGalleryAttributes(NSUInteger count, BOOL showsTitles, CGFloat pointSize,
                                                     NSDictionary *_Nullable (^_Nullable extra)(NSUInteger index)) {
    NSMutableArray<NSDictionary *> *attributes = [NSMutableArray array];
    NSArray<NSArray<NSString *> *> *specs = CYLGalleryTabSpecs();
    for (NSUInteger index = 0; index < count; index++) {
        NSArray<NSString *> *spec = specs[index];
        NSMutableDictionary *item = [@{ CYLTabBarItemImage : CYLGallerySymbol(spec[1], NO, pointSize),
                                        CYLTabBarItemSelectedImage : CYLGallerySymbol(spec[1], YES, pointSize),
                                        CYLTabBarItemIdentifier : spec[2] } mutableCopy];
        if (showsTitles) {
            item[CYLTabBarItemTitle] = spec[0];
        }
        NSDictionary *more = extra ? extra(index) : nil;
        if (more) {
            [item addEntriesFromDictionary:more];
        }
        [attributes addObject:item];
    }
    return attributes;
}

static CYLTabBarController *CYLGalleryTabBarController(NSArray<UIViewController *> *pages, NSArray<NSDictionary *> *attributes,
                                                       CYLTabBarStyleType styleType, NSString *context) {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:pages
                                                                           tabBarItemsAttributes:attributes
                                                                                       styleType:styleType
                                                                                         context:context];
    // [EN] The controller is its own delegate, so its `-tabBarController:shouldSelectViewController:` runs the custom action
    //      (and login) checks before UIKit selects a tab, in every style. Cast to `id`: the delegate property also names
    //      the FlatDesign delegate protocol, whose methods are all optional.
    // [CN] 控制器作为自己的代理，其 `-tabBarController:shouldSelectViewController:` 会在 UIKit 选中 Tab 之前执行自定义操作（及登录）检查，
    //      适用于所有样式。转为 `id`：代理属性还要求扁平样式的代理协议，其方法都是可选的。
    tabBarController.delegate = (id)tabBarController;
    return tabBarController;
}

/// [EN] The system UITabBarController, for comparison. [CN] 系统 UITabBarController，用于对照。
static UITabBarController *CYLGallerySystemTabBarController(NSUInteger count) {
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    NSArray<UIViewController *> *pages = CYLGalleryPages(count, NO);
    NSArray<NSArray<NSString *> *> *specs = CYLGalleryTabSpecs();
    for (NSUInteger index = 0; index < count; index++) {
        NSArray<NSString *> *spec = specs[index];
        pages[index].tabBarItem = [[UITabBarItem alloc] initWithTitle:spec[0] image:CYLGallerySymbol(spec[1], NO, 20) selectedImage:CYLGallerySymbol(spec[1], YES, 20)];
    }
    tabBarController.viewControllers = pages;
    return tabBarController;
}

/// [EN] The dialog of a tab with a custom action; `dismissed` runs when any button closes it. [CN] 执行自定义操作的 Tab 弹出的对话框；任一按钮关闭它时执行 `dismissed`。
static void CYLGalleryPresentMoreFeatures(UIViewController *presenter, void (^dismissed)(void)) {
    if (!presenter || presenter.presentedViewController) {
        dismissed();
        return;
    }
    void (^handler)(UIAlertAction *) = ^(UIAlertAction *action) {
        dismissed();
    };
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"More features" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"About us" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:handler]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

/*!
 * [EN] Swaps the pages of the tabs at `first` and `second` while each tab keeps its title and icon, with
 *      `-replaceViewControllerAtIndex:withViewController:attributes:` (a spare page frees one slot first).
 * [CN] 交换 `first` 与 `second` 两个 Tab 的页面，各 Tab 保持自己的标题与图标，使用
 *      `-replaceViewControllerAtIndex:withViewController:attributes:`（先用一个临时页面腾出一个位置）。
 */
static BOOL CYLGallerySwapPages(CYLTabBarController *tabBarController, NSUInteger first, NSUInteger second) {
    NSArray<UIViewController *> *viewControllers = tabBarController.viewControllers;
    if (first >= viewControllers.count || second >= viewControllers.count || first == second) {
        return NO;
    }
    UIViewController *firstPage = viewControllers[first];
    UIViewController *secondPage = viewControllers[second];
    UIViewController *sparePage = [[UIViewController alloc] init];
    return [tabBarController replaceViewControllerAtIndex:first withViewController:sparePage attributes:nil] &&
           [tabBarController replaceViewControllerAtIndex:second withViewController:firstPage attributes:nil] &&
           [tabBarController replaceViewControllerAtIndex:first withViewController:secondPage attributes:nil];
}

/*!
 * [EN] The "Photo" tab opens a dialog instead of a page: with the library through `cyl_customActionTabBarItemIdentifiers`
 *      and `cyl_customTabActionHandler`.
 * [CN] "Photo" Tab 打开对话框而不是页面：通过本库的 `cyl_customActionTabBarItemIdentifiers` 与 `cyl_customTabActionHandler` 实现。
 */
static void CYLGalleryUseCustomActionForPhotoTab(CYLTabBarController *tabBarController) {
    tabBarController.cyl_customActionTabBarItemIdentifiers = @[ @"photo" ];
    tabBarController.cyl_customTabActionHandler = ^(CYLTabBarController *controller, UIViewController *viewController) {
        // [EN] Next run loop turn (outside the tap): "Photo" looks selected over the current page while the dialog is up,
        //      then everything is restored.
        // [CN] 在下一个 runloop（点击处理之外）执行：对话框显示期间，"Photo" 显示为选中而页面保持不变，关闭后全部恢复。
        __weak CYLTabBarController *weakController = controller;
        __weak UIViewController *weakPhotoPage = viewController;
        dispatch_async(dispatch_get_main_queue(), ^{
            CYLTabBarController *strongController = weakController;
            UIViewController *photoPage = weakPhotoPage;
            if (!strongController || !photoPage) {
                return;
            }
            NSUInteger photoIndex = [strongController.viewControllers indexOfObject:photoPage];
            NSUInteger currentIndex = strongController.selectedIndex;
            BOOL swapped = CYLGallerySwapPages(strongController, currentIndex, photoIndex);
            if (swapped) {
                strongController.selectedIndex = photoIndex;
            }
            CYLGalleryPresentMoreFeatures(strongController, ^{
                CYLTabBarController *restoringController = weakController;
                if (swapped && restoringController && CYLGallerySwapPages(restoringController, currentIndex, photoIndex)) {
                    restoringController.selectedIndex = currentIndex;
                }
            });
        });
    };
}

/// [EN] The same custom action for the system UITabBarController, through its delegate. [CN] 系统 UITabBarController 通过代理实现同样的自定义操作。
@interface CYLGallerySystemPhotoActionDelegate : NSObject <UITabBarControllerDelegate>
+ (instancetype)sharedDelegate;
@end

@implementation CYLGallerySystemPhotoActionDelegate

+ (instancetype)sharedDelegate {
    static CYLGallerySystemPhotoActionDelegate *sharedDelegate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDelegate = [[self alloc] init];
    });
    return sharedDelegate;
}

/// [EN] Swaps two tabs' pages while each keeps its title and icon (UITab entries on iOS 18+ when the controller uses them).
/// [CN] 交换两个 Tab 的页面，各 Tab 保持自己的标题与图标（iOS 18+ 且控制器使用 UITab 时交换 UITab）。
- (void)swapTabAtIndex:(NSUInteger)first withTabAtIndex:(NSUInteger)second inTabBarController:(UITabBarController *)tabBarController {
    if (@available(iOS 18.0, *)) {
        if (tabBarController.tabs.count > MAX(first, second)) {
            NSMutableArray<UITab *> *tabs = [tabBarController.tabs mutableCopy];
            [tabs exchangeObjectAtIndex:first withObjectAtIndex:second];
            tabBarController.tabs = tabs;
            UITab *firstTab = tabs[first];
            UITab *secondTab = tabs[second];
            NSString *title = firstTab.title;
            UIImage *image = firstTab.image;
            firstTab.title = secondTab.title;
            firstTab.image = secondTab.image;
            secondTab.title = title;
            secondTab.image = image;
            return;
        }
    }
    NSMutableArray<UIViewController *> *viewControllers = [tabBarController.viewControllers mutableCopy];
    if (MAX(first, second) >= viewControllers.count) {
        return;
    }
    [viewControllers exchangeObjectAtIndex:first withObjectAtIndex:second];
    [tabBarController setViewControllers:viewControllers animated:NO];
    UITabBarItem *firstItem = viewControllers[first].tabBarItem;
    viewControllers[first].tabBarItem = viewControllers[second].tabBarItem;
    viewControllers[second].tabBarItem = firstItem;
}

/// [EN] "Photo" looks selected over the current page while the dialog is up, then it is restored. [CN] 对话框显示期间 "Photo" 显示为选中且页面不变，关闭后恢复。
- (void)showPhotoActionAtIndex:(NSUInteger)photoIndex selectedIndex:(NSUInteger)currentIndex inTabBarController:(UITabBarController *)tabBarController {
    __weak UITabBarController *weakTabBarController = tabBarController;
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarController *strongTabBarController = weakTabBarController;
        if (!strongTabBarController) {
            return;
        }
        [self swapTabAtIndex:currentIndex withTabAtIndex:photoIndex inTabBarController:strongTabBarController];
        strongTabBarController.selectedIndex = photoIndex;
        CYLGalleryPresentMoreFeatures(strongTabBarController, ^{
            UITabBarController *restoringTabBarController = weakTabBarController;
            if (restoringTabBarController) {
                [self swapTabAtIndex:currentIndex withTabAtIndex:photoIndex inTabBarController:restoringTabBarController];
                restoringTabBarController.selectedIndex = currentIndex;
            }
        });
    });
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger photoIndex = [tabBarController.viewControllers indexOfObject:viewController];
    NSUInteger currentIndex = tabBarController.selectedIndex;
    if ([viewController.tabBarItem.title isEqualToString:@"Photo"] && photoIndex != NSNotFound &&
        currentIndex != NSNotFound && photoIndex != currentIndex) {
        [self showPhotoActionAtIndex:photoIndex selectedIndex:currentIndex inTabBarController:tabBarController];
        return NO;
    }
    return YES;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectTab:(UITab *)tab API_AVAILABLE(ios(18.0)) {
    NSUInteger photoIndex = [tabBarController.tabs indexOfObject:tab];
    NSUInteger currentIndex = tabBarController.selectedTab ? [tabBarController.tabs indexOfObject:tabBarController.selectedTab] : NSNotFound;
    if ([tab.title isEqualToString:@"Photo"] && photoIndex != NSNotFound && currentIndex != NSNotFound && photoIndex != currentIndex) {
        [self showPhotoActionAtIndex:photoIndex selectedIndex:currentIndex inTabBarController:tabBarController];
        return NO;
    }
    return YES;
}

@end

/// [EN] Runs `block` with each tab button once the tab bar has them. [CN] TabBar 的按钮就绪后，对每个 Tab 按钮执行 `block`。
static void CYLGalleryForEachTabButton(CYLTabBarController *tabBarController, void (^block)(UIControl *button, NSUInteger index)) {
    [tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *controller) {
        [controller.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger index, BOOL *stop) {
            UIControl *button = viewController.tabBarItem.cyl_tabButton ?: viewController.cyl_tabButton;
            if (button) {
                block(button, index);
            }
        }];
    }];
}

/// [EN] A speech bubble with its tail at the bottom right. [CN] 尾巴在右下角的气泡。
static UIImage *CYLGalleryBubbleImage(UIColor *color) {
    CGSize size = CGSizeMake(40, 34);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, 28) cornerRadius:8] fill];
        UIBezierPath *tail = [UIBezierPath bezierPath];
        [tail moveToPoint:CGPointMake(size.width - 22, 27)];
        [tail addLineToPoint:CGPointMake(size.width - 10, 27)];
        [tail addLineToPoint:CGPointMake(size.width - 16, size.height)];
        [tail closePath];
        [tail fill];
    }];
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 12, 25) resizingMode:UIImageResizingModeStretch];
}

/// [EN] A bubble with `text`, added above the right edge of `button`. [CN] 在 `button` 右上方添加一个带 `text` 的气泡。
static UIView *CYLGalleryAddBubble(UIView *button, NSString *text, UIColor *color, CGRect frame, UIFont *font) {
    UIImageView *bubble = [[UIImageView alloc] initWithImage:CYLGalleryBubbleImage(color)];
    bubble.frame = frame;
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = UIColor.whiteColor;
    [label sizeToFit];
    label.center = CGPointMake(CGRectGetWidth(frame) / 2.0, (CGRectGetHeight(frame) - 6) / 2.0);
    [bubble addSubview:label];
    button.clipsToBounds = NO;
    [button addSubview:bubble];
    return bubble;
}

/// [EN] The dark look of the background scenes: dark tabs, the selected one darker, white icons when selected. [CN] 背景色场景的深色外观。
static NSDictionary *CYLGalleryDarkTabAttributes(BOOL special) {
    if (special) {
        return @{ CYLTabBarItemIconColor : UIColor.whiteColor,
                  CYLTabBarItemSelectedIconColor : UIColor.whiteColor,
                  CYLTabBarItemBackgroundColor : CYLGalleryRGB(17, 86, 136),
                  CYLTabBarItemSelectedBackgroundColor : CYLGalleryRGB(22, 24, 25) };
    }
    return @{ CYLTabBarItemIconColor : CYLGalleryGray(165),
              CYLTabBarItemSelectedIconColor : UIColor.whiteColor,
              CYLTabBarItemBackgroundColor : CYLGalleryRGB(37, 39, 42),
              CYLTabBarItemSelectedBackgroundColor : CYLGalleryRGB(22, 24, 25) };
}

static void CYLGallerySetTabBarBackgroundColor(UITabBarController *tabBarController, UIColor *color) {
    UITabBarAppearance *appearance = [tabBarController.tabBar.standardAppearance copy] ?: [[UITabBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = color;
    appearance.shadowColor = UIColor.clearColor;
    tabBarController.tabBar.standardAppearance = appearance;
    tabBarController.tabBar.scrollEdgeAppearance = appearance;
}

static UIViewController *CYLGalleryEmbed(CYLTabBarController *tabBarController) {
    tabBarController.title = @"Example";
    return [[CYLGalleryNavigationController alloc] initWithRootViewController:tabBarController];
}

/// [EN] The look of the background scenes, image-only, the middle tab highlighted and larger. [CN] 背景色场景的外观：纯图标，中间 Tab 突出且更大。
static CYLTabBarController *CYLGalleryBackgroundTabBarController(void) {
    NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, NO, 22, ^NSDictionary *(NSUInteger index) {
        NSMutableDictionary *item = [CYLGalleryDarkTabAttributes(index == 2) mutableCopy];
        if (index == 2) {
            item[CYLTabBarItemImage] = CYLGallerySymbol(@"camera", NO, 28);
            item[CYLTabBarItemSelectedImage] = CYLGallerySymbol(@"camera", YES, 28);
        }
        return item;
    });
    // [EN] Full width (FlatDesign on iOS 26+): Liquid Glass draws its own selection and ignores tab backgrounds.
    // [CN] 全宽样式（iOS 26+ 为扁平样式）：液态玻璃自带选中效果，会忽略 Tab 的背景色。
    CYLTabBarController *tabBarController = CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLGalleryFullWidthStyle(), CYLGalleryContext);
    CYLGallerySetTabBarBackgroundColor(tabBarController, CYLGalleryRGB(37, 39, 42));
    return tabBarController;
}

/// [EN] Runs `block` every `interval` seconds while `tabBarController` is alive. [CN] 在 `tabBarController` 存活期间每 `interval` 秒执行一次 `block`。
static void CYLGalleryRepeat(CYLTabBarController *tabBarController, NSTimeInterval interval, void (^block)(CYLTabBarController *controller)) {
    __weak CYLTabBarController *weakTabBarController = tabBarController;
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval repeats:YES block:^(NSTimer *aTimer) {
        CYLTabBarController *strongTabBarController = weakTabBarController;
        if (!strongTabBarController) {
            [aTimer invalidate];
            return;
        }
        block(strongTabBarController);
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

/// [EN] The icon view of the tab at `index`. [CN] 第 `index` 个 Tab 的图标视图。
static UIView *CYLGalleryIconView(CYLTabBarController *tabBarController, NSUInteger index) {
    if (index >= tabBarController.viewControllers.count) {
        return nil;
    }
    UIViewController *viewController = tabBarController.viewControllers[index];
    UIControl *button = viewController.tabBarItem.cyl_tabButton ?: viewController.cyl_tabButton;
    return button.cyl_tabImageView;
}

/// [EN] The look of the tips and irregular scenes: white titles, teal when selected, on a dark teal bar. [CN] 提示与不规则场景的外观。
static NSDictionary *CYLGalleryTealTabAttributes(void) {
    UIColor *teal = CYLGalleryRGB(23, 149, 158);
    return @{ CYLTabBarItemTitleColor : UIColor.whiteColor,
              CYLTabBarItemSelectedTitleColor : teal,
              CYLTabBarItemIconColor : UIColor.whiteColor,
              CYLTabBarItemSelectedIconColor : teal };
}

static NSDictionary *CYLGalleryRedTabAttributes(void) {
    UIColor *gray = CYLGalleryGray(175);
    UIColor *red = CYLGalleryRGB(254, 73, 42);
    return @{ CYLTabBarItemTitleColor : gray,
              CYLTabBarItemSelectedTitleColor : red,
              CYLTabBarItemIconColor : gray,
              CYLTabBarItemSelectedIconColor : red };
}

/// [EN] iOS 26+ draws Liquid Glass by default; FlatDesign shows the full-width tab bar of the earlier systems. [CN] iOS 26+ 默认液态玻璃；扁平样式显示以前系统的全宽 TabBar。
static CYLTabBarStyleType CYLGalleryFullWidthStyle(void) {
    if (@available(iOS 26.0, *)) {
        return CYLTabBarStyleTypeFlatDesign;
    }
    return CYLTabBarStyleTypeDefault;
}

#pragma mark - Provider

#pragma mark - Plus button with a page (Liquid Glass robustness)

/*!
 * [EN] A plus button that selects its own page (`+plusChildViewController`), so on Liquid Glass the library puts its
 *      stand-in (built from `+selectedContentImage`) in the selected layer: the view that
 *      `-cyl_layOutPlusButtonInLiquidGlassLayers` installs on every layout pass.
 * [CN] 选中自己页面（`+plusChildViewController`）的 PlusButton，因此在液态玻璃下本库会把它的替身（由 `+selectedContentImage` 生成）放进
 *      选中层：即 `-cyl_layOutPlusButtonInLiquidGlassLayers` 在每次布局时安装的视图。
 */
@interface CYLGalleryPagePlusButton : CYLPlusButton <CYLPlusButtonSubclassing>
@end

@implementation CYLGalleryPagePlusButton

+ (id)plusButton {
    CYLGalleryPagePlusButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button setImage:[self contentImage] forState:UIControlStateNormal];
    [button setImage:[self selectedContentImage] forState:UIControlStateSelected];
    button.tintColor = UIColor.systemIndigoColor;
    button.frame = CGRectMake(0, 0, 64, 49);
    button.accessibilityLabel = @"Compose";
    return button;
}

+ (UIImage *)contentImage {
    return CYLGallerySymbol(@"plus.circle", NO, 30);
}

+ (UIImage *)selectedContentImage {
    return CYLGallerySymbol(@"plus.circle", YES, 30);
}

+ (UIViewController *)plusChildViewController {
    CYLGalleryPageViewController *page = [[CYLGalleryPageViewController alloc] init];
    page.title = @"Compose";
    return page;
}

+ (NSUInteger)indexOfPlusButtonInTabBar {
    return 2;
}

+ (NSString *)tabBarContext {
    return CYLGalleryPlusPageContext;
}

+ (NSString *)tabBarItemIdentifier {
    return @"compose";
}

@end

/// [EN] The views the library marked (`-cyl_markAsInsertedForTabControl:`) inside `tabBar`.
/// [CN] `tabBar` 中被本库标记（`-cyl_markAsInsertedForTabControl:`）的视图。
static NSArray<UIView *> *CYLGalleryMarkedViews(UIView *tabBar) {
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (UIView *view in [UIView cyl_insertedTabControlViews]) {
        if (tabBar && [view isDescendantOfView:tabBar]) {
            [views addObject:view];
        }
    }
    return views;
}

/// [EN] A bar button item that runs `handler`. [CN] 点击后执行 `handler` 的导航栏按钮。
static UIBarButtonItem *CYLGalleryBarButtonItem(NSString *title, void (^handler)(void)) {
    UIAction *action = [UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction *_Nonnull theAction) {
        handler();
    }];
    return [[UIBarButtonItem alloc] initWithPrimaryAction:action];
}

/// [EN] A star drawn in place of a tab's icon, which the library marks as inserted. [CN] 替换 Tab 图标的星形视图，本库会将其标记为插入视图。
static UIView *CYLGalleryStarView(void) {
    UIImageView *starView = [[UIImageView alloc] initWithImage:CYLGallerySymbol(@"star", YES, 22)];
    starView.tintColor = UIColor.systemOrangeColor;
    return starView;
}

@implementation CYLGalleryProvider

+ (NSArray<CYLGallerySection *> *)sections {
    return @[ [self basicSection], [self embedSection], [self animationSection], [self irregularSection],
              [self customClickSection], [self remindSection], [self lottieSection], [self newAPISection],
              [self liquidGlassRobustnessSection], [self moreThanFiveTabsSection] ];
}

#pragma mark Basic

+ (CYLTabBarController *)fullWidthTabBarControllerWithCount:(NSUInteger)count {
    return CYLGalleryTabBarController(CYLGalleryPages(count, NO), CYLGalleryAttributes(count, YES, 20, nil), CYLGalleryFullWidthStyle(), CYLGalleryContext);
}

+ (CYLTabBarController *)defaultTabBarControllerWithCount:(NSUInteger)count {
    return CYLGalleryTabBarController(CYLGalleryPages(count, NO), CYLGalleryAttributes(count, YES, 20, nil), CYLTabBarStyleTypeDefault, CYLGalleryContext);
}

+ (CYLGallerySection *)basicSection {
    CYLGallerySceneDidPresent selectThirdTab = ^(UIViewController *presented) {
        ((UITabBarController *)presented).selectedIndex = 2;
    };
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"UITabBarController style" subtitle:@"The system tab bar, for comparison" builder:^UIViewController *{
            return CYLGallerySystemTabBarController(5);
        }],
        [CYLGalleryScene sceneWithTitle:@"CYLTabBarController like system style" subtitle:@"Three tabs; full width on iOS 26 (FlatDesign)" builder:^UIViewController *{
            return [self fullWidthTabBarControllerWithCount:3];
        }],
        [CYLGalleryScene sceneWithTitle:@"Mix styled and system items" subtitle:@"Tabs 1, 3 and 5 bounce; tabs 2 and 4 are plain" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            for (NSUInteger index = 0; index < 5; index += 2) {
                tabBarController.viewControllers[index].cyl_tabButtonAnimation = [CYLGalleryBounceAnimation new];
            }
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"CYLTabBarController with Liquid Glass" subtitle:@"\"Photo\" opens a dialog (cyl_customActionTabBarItemIdentifiers)" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            CYLGalleryUseCustomActionForPhotoTab(tabBarController);
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"UITabBarController with 'More'" subtitle:@"Eight tabs; \"Photo\" opens a dialog (delegate)" builder:^UIViewController *{
            UITabBarController *tabBarController = CYLGallerySystemTabBarController(8);
            tabBarController.delegate = [CYLGallerySystemPhotoActionDelegate sharedDelegate];
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"CYLTabBarController with 'More'" subtitle:@"Eight tabs, full width" builder:^UIViewController *{
            return [self fullWidthTabBarControllerWithCount:8];
        }],
        [CYLGalleryScene sceneWithTitle:@"Mix styled and system items with 'More'" subtitle:@"Eight tabs; every other one bounces" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self fullWidthTabBarControllerWithCount:8];
            for (NSUInteger index = 0; index < 8; index += 2) {
                tabBarController.viewControllers[index].cyl_tabButtonAnimation = [CYLGalleryBounceAnimation new];
            }
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Liquid Glass with 'More'" subtitle:@"Eight tabs with Liquid Glass" builder:^UIViewController *{
            return [self defaultTabBarControllerWithCount:8];
        }],
        [CYLGalleryScene sceneWithTitle:@"UITabBarController with non-zero default index" subtitle:@"selectedIndex = 2 after presenting" builder:^UIViewController *{
            return CYLGallerySystemTabBarController(5);
        } didPresent:selectThirdTab],
        [CYLGalleryScene sceneWithTitle:@"CYLTabBarController with non-zero default index" subtitle:@"selectedIndex = 2 after presenting" builder:^UIViewController *{
            return [self fullWidthTabBarControllerWithCount:3];
        } didPresent:selectThirdTab],
        [CYLGalleryScene sceneWithTitle:@"Classic design on every system" subtitle:@"CYLTabBarStyleTypeFlatDesign, white bar; \"Photo\" opens a dialog" builder:^UIViewController *{
            CYLTabBarController *tabBarController = CYLGalleryTabBarController(CYLGalleryPages(5, NO), CYLGalleryAttributes(5, YES, 20, nil), CYLTabBarStyleTypeFlatDesign, CYLGalleryContext);
            CYLGallerySetTabBarBackgroundColor(tabBarController, UIColor.whiteColor);
            CYLGalleryUseCustomActionForPhotoTab(tabBarController);
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Liquid Glass with badges" subtitle:@"New, 99+, a blue 1, a dot, none; the selected tab hides its badge" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            [self addSystemBadgesToTabBarController:tabBarController];
            // [EN] The selected tab hides its badge; the others keep theirs. [CN] 选中的 Tab 隐藏角标，其他 Tab 保留。
            tabBarController.cyl_hidesBadgeOfSelectedTab = YES;
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"UITabBarController tab style" subtitle:@"UITab (iOS 18+), eight tabs, \"Favor\" selected" builder:^UIViewController *{
            return [self systemTabStyleTabBarController];
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Basic" scenes:scenes];
}

+ (void)addSystemBadgesToTabBarController:(UITabBarController *)tabBarController {
    NSArray<UIViewController *> *viewControllers = tabBarController.viewControllers;
    viewControllers[0].tabBarItem.badgeValue = @"New";
    viewControllers[1].tabBarItem.badgeValue = @"99+";
    viewControllers[2].tabBarItem.badgeValue = @"1";
    viewControllers[2].tabBarItem.badgeColor = UIColor.blueColor;
    viewControllers[3].tabBarItem.badgeValue = @"";
    viewControllers[4].tabBarItem.badgeValue = nil;
}

+ (UITabBarController *)systemTabStyleTabBarController {
    if (@available(iOS 18.0, *)) {
        UITabBarController *tabBarController = [[UITabBarController alloc] init];
        NSMutableArray<UITab *> *tabs = [NSMutableArray array];
        for (NSArray<NSString *> *spec in CYLGalleryTabSpecs()) {
            UITab *tab = [[UITab alloc] initWithTitle:spec[0] image:CYLGallerySymbol(spec[1], NO, 20) identifier:spec[2] viewControllerProvider:^UIViewController *(UITab *aTab) {
                return [[CYLGalleryPageViewController alloc] init];
            }];
            [tabs addObject:tab];
        }
        tabBarController.tabs = tabs;
        tabBarController.selectedTab = tabs[3];
        tabBarController.delegate = [CYLGallerySystemPhotoActionDelegate sharedDelegate];
        return tabBarController;
    }
    return CYLGallerySystemTabBarController(8);
}

#pragma mark Embed

+ (CYLGallerySection *)embedSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"UINavigationController embeds CYLTabBarController" subtitle:@"One navigation bar above the tab bar controller" builder:^UIViewController *{
            return CYLGalleryEmbed([self fullWidthTabBarControllerWithCount:3]);
        }],
        [CYLGalleryScene sceneWithTitle:@"CYLTabBarController embeds UINavigationController" subtitle:@"A navigation controller in every tab" builder:^UIViewController *{
            return CYLGalleryTabBarController(CYLGalleryPages(5, YES), CYLGalleryAttributes(5, YES, 20, nil), CYLTabBarStyleTypeDefault, CYLGalleryContext);
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Embed" scenes:scenes];
}

#pragma mark Animation

+ (CYLGallerySection *)animationSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"Customize the selected color" subtitle:@"CYLTabBarItemTitleColor / IconColor per tab" builder:^UIViewController *{
            NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, YES, 20, ^NSDictionary *(NSUInteger index) {
                return CYLGalleryRedTabAttributes();
            });
            return CYLGalleryEmbed(CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext));
        }],
        [CYLGalleryScene sceneWithTitle:@"Spring animation" subtitle:@"A CYLTabButtonAnimation that bounces on select and reselect" builder:^UIViewController *{
            NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, YES, 20, ^NSDictionary *(NSUInteger index) {
                return CYLGalleryRedTabAttributes();
            });
            CYLTabBarController *tabBarController = CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext);
            tabBarController.cyl_defaultTabButtonAnimation = [CYLGalleryBounceAnimation new];
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"Background color change" subtitle:@"CYLTabBarItemBackgroundColor / SelectedBackgroundColor" builder:^UIViewController *{
            return CYLGalleryEmbed(CYLGalleryBackgroundTabBarController());
        }],
        [CYLGalleryScene sceneWithTitle:@"With a pressed effect" subtitle:@"Larger icons that shrink while pressed (highlight hooks)" builder:^UIViewController *{
            CYLTabBarController *tabBarController = CYLGalleryBackgroundTabBarController();
            tabBarController.cyl_defaultTabButtonAnimation = [CYLGalleryHighlightAnimation new];
            CYLGalleryForEachTabButton(tabBarController, ^(UIControl *button, NSUInteger index) {
                button.cyl_tabImageView.transform = CGAffineTransformMakeScale(CYLGalleryLargeIconScale, CYLGalleryLargeIconScale);
            });
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"Suggest a click" subtitle:@"The middle tab pulses every 3 s until it is selected" builder:^UIViewController *{
            CYLTabBarController *tabBarController = CYLGalleryBackgroundTabBarController();
            CYLGalleryRepeat(tabBarController, 3, ^(CYLTabBarController *controller) {
                if (controller.selectedIndex == 2) {
                    return;
                }
                CYLGalleryPlayKeyframes(CYLGalleryIconView(controller, 2), @"transform.scale", @[ @1.15, @0.8, @1.15 ], 0.3);
            });
            return CYLGalleryEmbed(tabBarController);
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Animation" scenes:scenes];
}

#pragma mark Irregular

/// [EN] Four teal tabs and the large round center button. [CN] 四个青色 Tab 与大号圆形中间按钮。
+ (UIViewController *)irregularScene {
    [CYLGalleryIrregularPlusButton registerPlusButton];
    NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(4, YES, 20, ^NSDictionary *(NSUInteger index) {
        return CYLGalleryTealTabAttributes();
    });
    // [EN] Home, Find, Favor, Me around the button. [CN] 按钮两侧为 Home、Find、Favor、Me。
    NSMutableArray<NSDictionary *> *items = [attributes mutableCopy];
    NSArray<NSArray<NSString *> *> *specs = CYLGalleryTabSpecs();
    for (NSUInteger index = 2; index < 4; index++) {
        NSMutableDictionary *item = [items[index] mutableCopy];
        NSArray<NSString *> *spec = specs[index + 1];
        item[CYLTabBarItemTitle] = spec[0];
        item[CYLTabBarItemImage] = CYLGallerySymbol(spec[1], NO, 20);
        item[CYLTabBarItemSelectedImage] = CYLGallerySymbol(spec[1], YES, 20);
        item[CYLTabBarItemIdentifier] = spec[2];
        items[index] = item;
    }
    NSArray<UIViewController *> *pages = CYLGalleryPages(4, NO);
    CYLTabBarController *tabBarController = CYLGalleryTabBarController(pages, items, CYLTabBarStyleTypeDefault, CYLGalleryIrregularContext);
    for (UIViewController *page in pages) {
        page.cyl_tabButtonAnimation = [CYLGalleryBounceAnimation new];
    }
    CYLGallerySetTabBarBackgroundColor(tabBarController, CYLGalleryRGB(10, 66, 91));
    return CYLGalleryEmbed(tabBarController);
}

+ (CYLGallerySection *)irregularSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"A larger button in the middle" subtitle:@"A raised round CYLPlusButton that responds inside its circle" builder:^UIViewController *{
            return [self irregularScene];
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Irregular" scenes:scenes];
}

#pragma mark Customize click

+ (CYLGallerySection *)customClickSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"Custom action for the button click" subtitle:@"The center button shows an action sheet instead of a page" builder:^UIViewController *{
            return [self irregularScene];
        }],
        [CYLGalleryScene sceneWithTitle:@"Add a special reminder bubble" subtitle:@"A bubble above \"Me\"; \"Photo\" opens a dialog" builder:^UIViewController *{
            NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, YES, 20, ^NSDictionary *(NSUInteger index) {
                return CYLGalleryTealTabAttributes();
            });
            CYLTabBarController *tabBarController = CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext);
            tabBarController.cyl_defaultTabButtonAnimation = [CYLGalleryBounceAnimation new];
            CYLGallerySetTabBarBackgroundColor(tabBarController, CYLGalleryRGB(10, 66, 91));
            CYLGalleryUseCustomActionForPhotoTab(tabBarController);
            CYLGalleryForEachTabButton(tabBarController, ^(UIControl *button, NSUInteger index) {
                UIView *tabBar = button.superview;
                if (index != 4 || !tabBar) {
                    return;
                }
                // [EN] The bubble lives on the tab bar, not on the button, so it survives the page swaps of the "Photo" dialog.
                // [CN] 气泡加在 TabBar 上而不是按钮上，因此 "Photo" 对话框交换页面时不会丢失。
                CGFloat width = 120;
                CGRect buttonFrame = [button convertRect:button.bounds toView:tabBar];
                UIView *bubble = CYLGalleryAddBubble(tabBar, @"New version", [UIColor colorWithWhite:0 alpha:0.75],
                                                     CGRectMake(CGRectGetMaxX(buttonFrame) - width, CGRectGetMinY(buttonFrame) - 40, width, 36),
                                                     [UIFont systemFontOfSize:14]);
                bubble.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            });
            return CYLGalleryEmbed(tabBarController);
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Customize click" scenes:scenes];
}

#pragma mark Remind

/// [EN] The background look, with a badge on "Find" two seconds after it appears. [CN] 背景色外观，出现两秒后 "Find" 显示角标。
+ (UIViewController *)remindSceneWithBadge:(void (^)(CYLTabBarController *tabBarController))showBadge {
    CYLTabBarController *tabBarController = CYLGalleryBackgroundTabBarController();
    __weak CYLTabBarController *weakTabBarController = tabBarController;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CYLTabBarController *strongTabBarController = weakTabBarController;
        if (strongTabBarController) {
            showBadge(strongTabBarController);
        }
    });
    return CYLGalleryEmbed(tabBarController);
}

+ (CYLGallerySection *)remindSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"System remind style" subtitle:@"UITabBarItem badges on the system tab bar" builder:^UIViewController *{
            UITabBarController *tabBarController = CYLGallerySystemTabBarController(5);
            [self addSystemBadgesToTabBarController:tabBarController];
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Imitate system remind style" subtitle:@"The same badges on CYLTabBarController" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            [self addSystemBadgesToTabBarController:tabBarController];
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Remind with animation" subtitle:@"The icon jumps when the badge appears (CYLTabButtonBlockAnimation.badgeChangedAnimation)" builder:^UIViewController *{
            UINavigationController *navigationController = (UINavigationController *)[self remindSceneWithBadge:^(CYLTabBarController *tabBarController) {
                tabBarController.viewControllers[1].tabBarItem.badgeValue = @"1";
            }];
            ((CYLTabBarController *)navigationController.viewControllers.firstObject).cyl_defaultTabButtonAnimation = CYLGalleryBadgeJumpAnimation();
            return navigationController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Remind with animation (2)" subtitle:@"The badge scales in when it appears (CYLTabButtonBlockAnimation.badgeChangedAnimation)" builder:^UIViewController *{
            UINavigationController *navigationController = (UINavigationController *)[self remindSceneWithBadge:^(CYLTabBarController *tabBarController) {
                tabBarController.viewControllers[1].tabBarItem.badgeValue = @"1";
            }];
            ((CYLTabBarController *)navigationController.viewControllers.firstObject).cyl_defaultTabButtonAnimation = CYLGalleryBadgeScaleAnimation();
            return navigationController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Customize remind style" subtitle:@"A gray bubble instead of the red badge" builder:^UIViewController *{
            return [self remindSceneWithBadge:^(CYLTabBarController *tabBarController) {
                UIViewController *viewController = tabBarController.viewControllers[1];
                UIControl *button = viewController.tabBarItem.cyl_tabButton ?: viewController.cyl_tabButton;
                if (!button) {
                    return;
                }
                CGFloat midX = CGRectGetMidX(button.bounds);
                UIView *bubble = CYLGalleryAddBubble(button, @"1", UIColor.lightGrayColor, CGRectMake(midX + 2, -4, 30, 26), [UIFont systemFontOfSize:13]);
                CYLGalleryPlayKeyframes(bubble, @"transform.scale", @[ @1.0, @1.4, @0.9, @1.15, @0.95, @1.02, @1.0 ], 0.6);
            }];
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Remind" scenes:scenes];
}

#pragma mark Lottie

+ (CYLGallerySection *)lottieSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"Lottie" subtitle:@"The middle tab loops its Lottie animation until it is selected (CYLTabBarLottieLoopsWhenUnselected)" builder:^UIViewController *{
            UIColor *normal = CYLGalleryRGB(61, 206, 193);
            UIColor *selected = CYLGalleryRGB(252, 13, 27);
            NSURL *lottieURL = [[NSBundle mainBundle] URLForResource:@"tab_search_animate" withExtension:@"json"];
            NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, NO, 22, ^NSDictionary *(NSUInteger index) {
                NSMutableDictionary *item = [@{ CYLTabBarItemIconColor : normal, CYLTabBarItemSelectedIconColor : selected } mutableCopy];
                if (index == 2 && lottieURL) {
                    item[CYLTabBarLottieURL] = lottieURL;
                    item[CYLTabBarLottieSize] = [NSValue valueWithCGSize:CGSizeMake(33, 33)];
                    // [EN] Loops while unselected, pauses while selected. [CN] 未选中时循环播放，选中时暂停。
                    item[CYLTabBarLottieLoopsWhenUnselected] = @YES;
                }
                return item;
            });
            return CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext);
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Lottie" scenes:scenes];
}

#pragma mark New APIs

+ (CYLGallerySection *)newAPISection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"Reselect: pop to root, then scroll to top" subtitle:@"cyl_reselectBehavior = PopToRootThenScrollToTop" builder:^UIViewController *{
            NSMutableArray<UIViewController *> *pages = [NSMutableArray array];
            for (NSUInteger index = 0; index < 3; index++) {
                CYLGalleryListViewController *list = [[CYLGalleryListViewController alloc] initWithStyle:UITableViewStylePlain];
                list.title = CYLGalleryTabSpecs()[index][0];
                [pages addObject:[[CYLGalleryNavigationController alloc] initWithRootViewController:list]];
            }
            CYLTabBarController *tabBarController = CYLGalleryTabBarController(pages, CYLGalleryAttributes(3, YES, 20, nil), CYLTabBarStyleTypeDefault, CYLGalleryContext);
            tabBarController.cyl_reselectBehavior = CYLTabBarReselectBehaviorPopToRootThenScrollToTop;
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Press and reselect animations" subtitle:@"CYLTabButtonPressAnimation + a reselect turn" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            tabBarController.cyl_defaultTabButtonAnimation = [CYLGalleryPressAndReselectAnimation new];
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Custom action on a regular tab" subtitle:@"cyl_customActionTabBarItemIdentifiers + cyl_customTabActionHandler" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            CYLGalleryUseCustomActionForPhotoTab(tabBarController);
            return tabBarController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Per-tab colors, fonts and backgrounds" subtitle:@"Every tab has its own title color, font and background" builder:^UIViewController *{
            NSArray<UIColor *> *colors = @[ UIColor.systemRedColor, UIColor.systemOrangeColor, UIColor.systemGreenColor, UIColor.systemBlueColor, UIColor.systemPurpleColor ];
            NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, YES, 20, ^NSDictionary *(NSUInteger index) {
                UIColor *color = colors[index];
                return @{ CYLTabBarItemSelectedTitleColor : color,
                          CYLTabBarItemSelectedIconColor : color,
                          CYLTabBarItemTitleFont : [UIFont systemFontOfSize:10],
                          CYLTabBarItemSelectedTitleFont : [UIFont systemFontOfSize:11 weight:UIFontWeightBold],
                          CYLTabBarItemSelectedBackgroundColor : [color colorWithAlphaComponent:0.12] };
            });
            return CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext);
        }],
        [CYLGalleryScene sceneWithTitle:@"Accessibility identifiers" subtitle:@"Each tab is app.tabBars.buttons[\"home\"] etc. in UI tests" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            [tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *controller) {
                NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
                for (UIViewController *viewController in controller.viewControllers) {
                    [identifiers addObject:viewController.tabBarItem.accessibilityIdentifier ?: viewController.cyl_tabBarItemIdentifier ?: @"-"];
                }
                controller.navigationItem.title = [identifiers componentsJoinedByString:@", "];
            }];
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"Centered tabs around a plus button" subtitle:@"itemPositioning = Centered, itemWidth 64, itemSpacing 12" builder:^UIViewController *{
            UINavigationController *navigationController = (UINavigationController *)[self irregularScene];
            UITabBarController *tabBarController = (UITabBarController *)navigationController.viewControllers.firstObject;
            tabBarController.tabBar.itemPositioning = UITabBarItemPositioningCentered;
            tabBarController.tabBar.itemWidth = 64;
            tabBarController.tabBar.itemSpacing = 12;
            return navigationController;
        }],
        [CYLGalleryScene sceneWithTitle:@"Edge insets and gaps between tabs" subtitle:@"cyl_itemEdgeInsets 16 pt + itemSpacing 2 pt; classic tab bar (iOS 25 and earlier, or iOS 26 compatibility mode)" builder:^UIViewController *{
            NSArray<NSDictionary *> *attributes = CYLGalleryAttributes(5, NO, 22, ^NSDictionary *(NSUInteger index) {
                return CYLGalleryDarkTabAttributes(index == 2);
            });
            CYLTabBarController *tabBarController = CYLGalleryTabBarController(CYLGalleryPages(5, NO), attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext);
            if ([tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
                CYLTabBar *tabBar = (CYLTabBar *)tabBarController.tabBar;
                tabBar.cyl_itemEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
                tabBar.itemSpacing = 2;
            }
            CYLGallerySetTabBarBackgroundColor(tabBarController, UIColor.blackColor);
            return CYLGalleryEmbed(tabBarController);
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"New APIs" scenes:scenes];
}


#pragma mark Liquid Glass robustness

/// [EN] Four tabs around the plus button that has its own page. [CN] 拥有自己页面的 PlusButton 两侧的四个 Tab。
+ (CYLTabBarController *)plusPageTabBarController {
    [CYLGalleryPagePlusButton registerPlusButton];
    NSMutableArray<NSDictionary *> *attributes = [CYLGalleryAttributes(5, YES, 20, nil) mutableCopy];
    [attributes removeObjectAtIndex:2];
    NSMutableArray<UIViewController *> *pages = [CYLGalleryPages(5, NO) mutableCopy];
    [pages removeObjectAtIndex:2];
    return CYLGalleryTabBarController(pages, attributes, CYLTabBarStyleTypeDefault, CYLGalleryPlusPageContext);
}

/// [EN] Shows how many marked views the tab bar holds, in the navigation bar. [CN] 在导航栏中显示 TabBar 中被标记视图的数量。
+ (void)showMarkedViewCountOfTabBarController:(CYLTabBarController *)tabBarController {
    NSArray<UIView *> *views = CYLGalleryMarkedViews(tabBarController.tabBar);
    NSUInteger hiddenCount = 0;
    for (UIView *view in views) {
        hiddenCount += view.hidden ? 1 : 0;
    }
    tabBarController.navigationItem.title = [NSString stringWithFormat:@"%lu marked, %lu hidden", (unsigned long)views.count, (unsigned long)hiddenCount];
}

+ (CYLGallerySection *)liquidGlassRobustnessSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"Selected control with bounds checks" subtitle:@"cyl_selectedControl falls back in order; \"Read\" shows its index and class" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            __weak CYLTabBarController *weakTabBarController = tabBarController;
            void (^read)(void) = ^{
                CYLTabBarController *controller = weakTabBarController;
                if (![controller.tabBar isKindOfClass:[CYLTabBar class]]) {
                    return;
                }
                UIControl *selectedControl = [(CYLTabBar *)controller.tabBar cyl_selectedControl];
                controller.navigationItem.title = [NSString stringWithFormat:@"index %ld, %@", (long)[(CYLTabBar *)controller.tabBar cyl_selectedIndex],
                                                   selectedControl ? NSStringFromClass([selectedControl class]) : @"nil"];
            };
            tabBarController.navigationItem.rightBarButtonItem = CYLGalleryBarButtonItem(@"Read", read);
            [tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *controller) {
                read();
            }];
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"Out-of-range reads return nil" subtitle:@"Index 99 on the platter / tab button readers: nil, no exception" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            __weak CYLTabBarController *weakTabBarController = tabBarController;
            tabBarController.navigationItem.rightBarButtonItem = CYLGalleryBarButtonItem(@"Read 99", ^{
                CYLTabBarController *controller = weakTabBarController;
                if (![controller.tabBar isKindOfClass:[CYLTabBar class]]) {
                    return;
                }
                CYLTabBar *tabBar = (CYLTabBar *)controller.tabBar;
                NSArray<NSString *> *lines = @[
                    [NSString stringWithFormat:@"cyl_platterContentViewWithIndex: %@", (id)[tabBar cyl_platterContentViewWithIndex:99] ?: @"nil"],
                    [NSString stringWithFormat:@"cyl_platterSelectedContentViewWithIndex: %@", (id)[tabBar cyl_platterSelectedContentViewWithIndex:99] ?: @"nil"],
                    [NSString stringWithFormat:@"cyl_tabBarButtonWithTabIndex: %@", (id)[tabBar cyl_tabBarButtonWithTabIndex:99] ?: @"nil"],
                ];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Index 99" message:[lines componentsJoinedByString:@"\n"] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [controller presentViewController:alert animated:YES completion:nil];
            });
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"Marked views in tab buttons" subtitle:@"A star replaces Home's icon; \"Hide\" / \"Show\" toggles every marked view in one pass" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:5];
            __weak CYLTabBarController *weakTabBarController = tabBarController;
            [tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *controller) {
                UIControl *homeButton = controller.viewControllers.firstObject.cyl_tabButton;
                [homeButton cyl_replaceTabImageViewWithNewView:CYLGalleryStarView() show:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showMarkedViewCountOfTabBarController:controller];
                });
            }];
            tabBarController.navigationItem.rightBarButtonItem = CYLGalleryBarButtonItem(@"Hide / Show", ^{
                CYLTabBarController *controller = weakTabBarController;
                NSArray<UIView *> *views = CYLGalleryMarkedViews(controller.tabBar);
                BOOL hides = NO;
                for (UIView *view in views) {
                    hides = hides || !view.hidden;
                }
                for (UIView *view in views) {
                    view.hidden = hides;
                }
                [self showMarkedViewCountOfTabBarController:controller];
            });
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"Plus stand-in after an item image changes" subtitle:@"Select the plus tab, then \"Change image\": UIKit rebuilds the buttons and the stand-in moves to the new one (Liquid Glass)" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self plusPageTabBarController];
            __weak CYLTabBarController *weakTabBarController = tabBarController;
            __block BOOL usesAlternateImage = NO;
            tabBarController.navigationItem.rightBarButtonItem = CYLGalleryBarButtonItem(@"Change image", ^{
                usesAlternateImage = !usesAlternateImage;
                NSString *name = usesAlternateImage ? @"sun.max" : @"house";
                UITabBarItem *item = weakTabBarController.viewControllers.firstObject.tabBarItem;
                item.image = CYLGallerySymbol(name, NO, 20);
                item.selectedImage = CYLGallerySymbol(name, YES, 20);
            });
            return CYLGalleryEmbed(tabBarController);
        } didPresent:^(UIViewController *presentedViewController) {
            UINavigationController *navigationController = (UINavigationController *)presentedViewController;
            UITabBarController *tabBarController = (UITabBarController *)navigationController.viewControllers.firstObject;
            tabBarController.selectedIndex = 2;
        }],
        [CYLGalleryScene sceneWithTitle:@"Plus stand-in on first display and rotation" subtitle:@"The plus tab is selected at once; rotate the device: the stand-in follows layout, no fixed delay (Liquid Glass)" builder:^UIViewController *{
            CYLTabBarController *tabBarController = [self plusPageTabBarController];
            tabBarController.selectedIndex = 2;
            return CYLGalleryEmbed(tabBarController);
        }],
        [CYLGalleryScene sceneWithTitle:@"More editing with 8 tabs" subtitle:@"Pushed. More → Edit → drag → Done: the star (a marked view) hides while editing and comes back after" pushingBuilder:^UIViewController *{
            CYLTabBarController *tabBarController = [self defaultTabBarControllerWithCount:8];
            tabBarController.title = @"More editing";
            [tabBarController performWhenTabBarItemsReady:^(CYLTabBarController *controller) {
                UIControl *homeButton = controller.viewControllers.firstObject.cyl_tabButton;
                [homeButton cyl_replaceTabImageViewWithNewView:CYLGalleryStarView() show:YES];
            }];
            return tabBarController;
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"Liquid Glass robustness" scenes:scenes];
}


#pragma mark More than five tabs (issue #472)

/*!
 * [EN] Issue #472: more than five tabs without the system "More". UIKit adds "More" as soon as a tab bar controller has
 *      more than five view controllers, and it cannot be turned off; so the controller gets five, and the fifth tab is an
 *      overflow slot. Tapping it (or tapping it again while it is selected) runs a custom action that shows your own menu of the
 *      other pages; the chosen page is put in the slot with `-replaceViewControllerAtIndex:withViewController:attributes:`,
 *      with its own title and icon, and selected. While another tab is selected, the slot selects its page directly.
 * [CN] Issue #472：超过 5 个 Tab 而不出现系统的 "More"。TabBarController 的视图控制器超过 5 个时 UIKit 就会添加 "More"，且无法关闭；
 *      因此只给控制器 5 个，第 5 个 Tab 作为溢出位。点击它（或在它选中时再次点击）会执行自定义操作，弹出你自己的其他页面菜单；选中的页面通过
 *      `-replaceViewControllerAtIndex:withViewController:attributes:` 放进该位置（使用它自己的标题与图标）并选中。其他 Tab 选中时，
 *      点击溢出位直接选中其中的页面。
 */
+ (UIViewController *)overflowMenuScene {
    NSArray<NSArray<NSString *> *> *specs = CYLGalleryTabSpecs();
    NSMutableArray<NSDictionary *> *attributes = [CYLGalleryAttributes(4, YES, 20, nil) mutableCopy];
    [attributes addObject:@{ CYLTabBarItemTitle : @"More",
                             CYLTabBarItemImage : CYLGallerySymbol(@"ellipsis.circle", NO, 20),
                             CYLTabBarItemSelectedImage : CYLGallerySymbol(@"ellipsis.circle", YES, 20),
                             CYLTabBarItemIdentifier : @"overflow" }];
    NSMutableArray<UIViewController *> *pages = [CYLGalleryPages(4, NO) mutableCopy];
    CYLGalleryPageViewController *placeholder = [[CYLGalleryPageViewController alloc] init];
    [pages addObject:placeholder];
    // [EN] The pages that do not fit: Me, Message, Shop, Cardboard. [CN] 放不下的页面：Me、Message、Shop、Cardboard。
    NSMutableArray<UIViewController *> *overflowPages = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *overflowAttributes = [NSMutableArray array];
    for (NSUInteger index = 4; index < specs.count; index++) {
        [overflowPages addObject:[[CYLGalleryPageViewController alloc] init]];
        [overflowAttributes addObject:@{ CYLTabBarItemTitle : specs[index][0],
                                         CYLTabBarItemImage : CYLGallerySymbol(specs[index][1], NO, 20),
                                         CYLTabBarItemSelectedImage : CYLGallerySymbol(specs[index][1], YES, 20),
                                         CYLTabBarItemIdentifier : @"overflow" }];
    }
    CYLTabBarController *tabBarController = CYLGalleryTabBarController(pages, attributes, CYLTabBarStyleTypeDefault, CYLGalleryContext);
    tabBarController.cyl_customActionTabBarItemIdentifiers = @[ @"overflow" ];
    tabBarController.cyl_shouldPerformCustomTabActionHandler = ^BOOL(CYLTabBarController *controller, UIViewController *viewController) {
        NSUInteger index = [controller.viewControllers indexOfObject:viewController];
        if (index != 4) {
            return NO;
        }
        // [EN] The menu: from the placeholder, or when the slot is tapped again. [CN] 弹出菜单：溢出位还是占位页面，或再次点击该位置时。
        return viewController == placeholder || controller.selectedIndex == 4;
    };
    tabBarController.cyl_customTabActionHandler = ^(CYLTabBarController *controller, UIViewController *viewController) {
        UIAlertController *menu = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [overflowPages enumerateObjectsUsingBlock:^(UIViewController *page, NSUInteger index, BOOL *stop) {
            NSDictionary *pageAttributes = overflowAttributes[index];
            [menu addAction:[UIAlertAction actionWithTitle:pageAttributes[CYLTabBarItemTitle] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (controller.viewControllers[4] != page) {
                    [controller replaceViewControllerAtIndex:4 withViewController:page attributes:pageAttributes];
                }
                controller.selectedIndex = 4;
            }]];
        }];
        [menu addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        UIControl *slotButton = controller.viewControllers.lastObject.cyl_tabButton;
        menu.popoverPresentationController.sourceView = slotButton ?: controller.tabBar;
        menu.popoverPresentationController.sourceRect = (slotButton ?: controller.tabBar).bounds;
        [controller presentViewController:menu animated:YES completion:nil];
    };
    return tabBarController;
}

+ (CYLGallerySection *)moreThanFiveTabsSection {
    NSArray<CYLGalleryScene *> *scenes = @[
        [CYLGalleryScene sceneWithTitle:@"8 tabs without the system \"More\"" subtitle:@"Issue #472: the fifth tab opens your own menu of the other pages; the chosen page takes that slot with its own title and icon" builder:^UIViewController *{
            return [self overflowMenuScene];
        }],
        [CYLGalleryScene sceneWithTitle:@"For comparison: 8 tabs with the system \"More\"" subtitle:@"UIKit shows four tabs and \"More\" once there are more than five view controllers" builder:^UIViewController *{
            return [self fullWidthTabBarControllerWithCount:8];
        }],
    ];
    return [CYLGallerySection sectionWithTitle:@"More than five tabs" scenes:scenes];
}

@end
