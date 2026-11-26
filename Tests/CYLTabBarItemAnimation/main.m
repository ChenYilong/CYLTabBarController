//
//  main.m
//  CYLTabBarItemAnimation tests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Several animation libraries registered at once (as several pods do in `+load`), each tab configured with the keys of
//      one of them: the tab must be played by that library only, and read only that library's keys. Rive is the real
//      `CYLTabBarItemViewAnimator`; Lottie and PAG are stand-ins with their real keys, extensions and priorities.
// [CN] 同时注册多个动画库（与多个 pod 在 `+load` 中注册相同），每个 Tab 只用其中一个动画库的 key 配置：该 Tab 必须只由这个动画库播放，并且只读取
//      这个动画库的 key。Rive 使用真实的 `CYLTabBarItemViewAnimator`；Lottie 与 PAG 是替身，key、扩展名与优先级与真实的相同。

#import <UIKit/UIKit.h>
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationFactory.h"
#import "CYLTabBarItemAnimationEngine.h"
#import "CYLTabBarItemViewAnimator.h"

// [EN] The keys, with their real values. [CN] 各 key，取值与真实的相同。
static NSString *const CYLTabBarAnimationURL = @"CYLTabBarAnimationURL";
static NSString *const CYLTabBarAnimationSize = @"CYLTabBarAnimationSize";
static NSString *const CYLTabBarAnimationDarkURL = @"CYLTabBarAnimationDarkURL";
static NSString *const CYLTabBarLottieURL = @"CYLTabBarLottieURL";
static NSString *const CYLTabBarLottieSize = @"CYLTabBarLottieSize";
static NSString *const CYLTabBarPAGURL = @"CYLTabBarPAGURL";
static NSString *const CYLTabBarPAGSize = @"CYLTabBarPAGSize";
static NSString *const CYLTabBarRiveURL = @"CYLTabBarRiveURL";
static NSString *const CYLTabBarRiveSize = @"CYLTabBarRiveSize";
static NSString *const CYLTabBarRiveDarkURL = @"CYLTabBarRiveDarkURL";
typedef NSString *CYLTabBarAnimationOption;

// [EN] Core helpers (Swift in the library), from CYLCoreStandIns.m. [CN] Core 辅助函数（库中为 Swift），来自 CYLCoreStandIns.m。
id CYLTabBarItemAttributesAnimationValue(NSDictionary *attributes, NSString *genericKey);
NSURL *CYLTabBarAnimationURLWithOptions(NSURL *fileURL, NSDictionary<CYLTabBarAnimationOption, NSString *> *options);

static int CYLFailures = 0;
static int CYLChecks = 0;
#define CHECK(condition, description) do { \
    CYLChecks++; \
    if (!(condition)) { CYLFailures++; printf("FAIL: %s (%s:%d)\n", description, __FILE__, __LINE__); } \
    else { printf("ok:   %s\n", description); } \
} while (0)

#pragma mark - Stand-ins

/// [EN] Stands for the animated item component's `CYLAnimationEngines` (Swift, found by the engine at run time): records the calls the
///      engine makes for a tab's missing resource. [CN] 代表动效组件的 `CYLAnimationEngines`（Swift，引擎在运行时查找）：记录引擎为 Tab 缺失的资源所做的调用。
@interface CYLAnimationEngines : NSObject
+ (NSMutableArray<NSArray *> *)calls;
+ (void)cyl_reportTabAnimationFailureOfURL:(NSURL *)URL error:(nullable NSError *)error owner:(id)owner;
+ (void)cyl_reportTabAnimationNotMadeForURL:(NSURL *)URL owner:(id)owner;
@end
@implementation CYLAnimationEngines
+ (NSMutableArray<NSArray *> *)calls {
    static NSMutableArray<NSArray *> *calls;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ calls = [NSMutableArray array]; });
    return calls;
}
+ (void)cyl_reportTabAnimationFailureOfURL:(NSURL *)URL error:(NSError *)error owner:(id)owner {
    [[self calls] addObject:@[ @"failure", URL, error ?: [NSNull null], owner ]];
}
+ (void)cyl_reportTabAnimationNotMadeForURL:(NSURL *)URL owner:(id)owner {
    [[self calls] addObject:@[ @"notMade", URL, owner ]];
}
@end

/// [EN] Like Lottie: the fallback, takes every file. [CN] 与 Lottie 相同：兜底，接收所有文件。
@interface CYLTestLottieAnimator : NSObject <CYLTabBarItemAnimator>
@end
@implementation CYLTestLottieAnimator
- (NSString *)identifier { return @"Lottie"; }
- (CYLTabBarItemAnimatorPriority)priority { return CYLTabBarItemAnimatorPriorityFallback; }
- (NSArray<NSString *> *)fileExtensions { return @[ @"json", @"lottie" ]; }
- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{ CYLTabBarAnimationURL : CYLTabBarLottieURL, CYLTabBarAnimationSize : CYLTabBarLottieSize };
}
- (BOOL)canAnimateFileAtURL:(NSURL *)URL { return URL != nil; }
- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode { return nil; }
- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view { return nil; }
@end

/// [EN] Like PAG: only ".pag". [CN] 与 PAG 相同：只接收 ".pag"。
@interface CYLTestPAGAnimator : NSObject <CYLTabBarItemAnimator>
@end
@implementation CYLTestPAGAnimator
- (NSString *)identifier { return @"PAG"; }
- (NSArray<NSString *> *)fileExtensions { return @[ @"pag" ]; }
- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{ CYLTabBarAnimationURL : CYLTabBarPAGURL, CYLTabBarAnimationSize : CYLTabBarPAGSize };
}
- (BOOL)canAnimateFileAtURL:(NSURL *)URL { return [URL.pathExtension.lowercaseString isEqualToString:@"pag"]; }
- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode { return nil; }
- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view { return nil; }
@end

/// [EN] Stands in for Rive's Swift view: records what it was made with and what it played.
/// [CN] Rive Swift 视图的替身：记录创建参数与播放调用。
@interface CYLTestRiveView : UIView <CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding>
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *options;
@property (nonatomic, assign) NSInteger plays;
@property (nonatomic, assign) NSInteger stops;
@end
static CYLTestRiveView *CYLLastRiveView;
@implementation CYLTestRiveView
+ (UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                    options:(NSDictionary<NSString *, NSString *> *)options
                                                                contentMode:(UIViewContentMode)contentMode {
    CYLTestRiveView *view = [[self alloc] init];
    view.fileURL = fileURL;
    view.options = options;
    CYLLastRiveView = view;
    return view;
}
- (void)cyl_playAnimationView { self.plays++; }
- (void)cyl_showAnimationViewLastFrame {}
- (void)cyl_stopAnimationView { self.stops++; }
@end

/// [EN] Like the SVGA view: seeks, loops and changes its rate. [CN] 与 SVGA 视图相同：能定位、循环并改变速率。
@interface CYLTestSeekableView : UIView <CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding>
@property (nonatomic, assign) CGFloat progressValue;
@property (nonatomic, assign) CGFloat speedValue;
@property (nonatomic, assign) BOOL loopsValue;
@end
@implementation CYLTestSeekableView
+ (UIView<CYLTabBarItemAnimationPlayableView> *)cyl_animationViewWithFileURL:(NSURL *)fileURL
                                                                    options:(NSDictionary<NSString *, NSString *> *)options
                                                                contentMode:(UIViewContentMode)contentMode {
    return [[self alloc] init];
}
- (void)cyl_playAnimationView {}
- (void)cyl_showAnimationViewLastFrame {}
- (void)cyl_stopAnimationView {}
- (void)cyl_setAnimationViewLoops:(BOOL)loops { self.loopsValue = loops; }
- (CGFloat)cyl_animationViewProgress { return self.progressValue; }
- (void)cyl_setAnimationViewProgress:(CGFloat)progress { self.progressValue = progress; }
- (void)cyl_setAnimationViewSpeed:(CGFloat)speed { self.speedValue = speed; }
@end

/// [EN] Adopts only one of the two protocols: refused as a view provider. [CN] 只遵守两个协议之一：不能作为视图 provider。
@interface CYLTestNotAProvider : UIView <CYLTabBarItemAnimationPlayableView>
@end
@implementation CYLTestNotAProvider
- (void)cyl_playAnimationView {}
- (void)cyl_showAnimationViewLastFrame {}
- (void)cyl_stopAnimationView {}
@end

#pragma mark - What Core provides (fakes)

/// [EN] Core's service slot, as in Swift/UIControl+CYLTabBarItemAnimation.swift; the real engine fills it in +load.
/// [CN] Core 的服务槽位，与 Swift/UIControl+CYLTabBarItemAnimation.swift 相同；真正的引擎在 +load 中填入。
static id<CYLTabBarItemAnimationService> CYLTestCurrentService;
void CYLTabBarItemAnimationSetService(id<CYLTabBarItemAnimationService> service) {
    CYLTestCurrentService = service;
}
id<CYLTabBarItemAnimationService> CYLTabBarItemAnimationGetService(void) {
    return CYLTestCurrentService;
}

/// [EN] A tab bar that records what the engine asked of it. [CN] 记录引擎调用的 Tab 栏替身。
@interface CYLTestHost : NSObject <CYLTabBarItemAnimationHost>
@property (nonatomic, assign) BOOL plus;
@property (nonatomic, assign) BOOL ready;
@property (nonatomic, strong) UIView *shownView;
@property (nonatomic, assign) NSInteger willPlays;
@property (nonatomic, assign) NSInteger trackedReplacements;
@end
@implementation CYLTestHost
- (BOOL)isPlusControl:(UIControl *)control { return self.plus; }
- (BOOL)isAnimationView:(UIView *)animationView readyInControl:(UIControl *)control { return self.ready && animationView != nil; }
- (CGSize)defaultAnimationSize { return CGSizeMake(28, 28); }
- (void)showAnimationView:(UIView *)animationView inControl:(UIControl *)control {
    [control addSubview:animationView];
    self.shownView = animationView;
}
- (void)replaceTrackedSubview:(UIView *)view withView:(UIView *)newView inSuperview:(UIView *)superview { self.trackedReplacements++; }
- (void)animationViewDidAddInControl:(UIControl *)control {}
- (void)animationWillPlayInControl:(UIControl *)control { self.willPlays++; }
@end

/// [EN] One light animation with a dark version. [CN] 一个带深色版本的浅色动画。
@interface CYLTestStyleSource : NSObject <CYLTabBarItemAnimationStyleSource>
@property (nonatomic, strong) NSURL *lightURL;
@property (nonatomic, strong) NSURL *darkURL;
@end
@implementation CYLTestStyleSource
- (BOOL)hasStyleVariants { return self.darkURL != nil; }
- (BOOL)hasStyleVariantForURL:(NSURL *)URL { return self.darkURL != nil && [URL isEqual:self.lightURL]; }
- (NSURL *)URL:(NSURL *)URL forTraitCollection:(UITraitCollection *)traitCollection {
    BOOL dark = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    return (dark && [self hasStyleVariantForURL:URL]) ? self.darkURL : URL;
}
- (NSDictionary<NSString *, UIColor *> *)darkColorsForURL:(NSURL *)URL { return nil; }
@end

id<CYLTabBarItemAnimationStyleSource> CYLTabBarItemAnimationDefaultStyleSource(void) {
    return [[CYLTestStyleSource alloc] init];
}
id<CYLTabBarItemAnimationHost> CYLTabBarItemAnimationDefaultHost(void) {
    return [[CYLTestHost alloc] init];
}

/// [EN] Core's style registry, from CYLCoreStandIns.m. [CN] Core 的风格注册表，来自 CYLCoreStandIns.m。
@interface CYLTabBarItemAnimationStyleRegistry : NSObject <CYLTabBarItemAnimationStyleSource>
- (void)registerDarkURL:(NSURL *)darkURL forURL:(NSURL *)URL;
- (void)registerDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forURL:(NSURL *)URL;
@end

/// [EN] An existing local file, as the engine requires. [CN] 引擎要求的本地已存在文件。
static NSURL *CYLTestFile(NSString *name) {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    [@"test" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    return [NSURL fileURLWithPath:path];
}

#pragma mark - Tests

static NSString *CYLIdentifier(id<CYLTabBarItemAnimator> animator) {
    return animator ? animator.identifier : @"(none)";
}

static void CYLRegisterAll(id<CYLTabBarItemAnimator> rive) {
    // [EN] Pods load in no fixed order: Rive first, Lottie last here. [CN] pod 的加载顺序不固定：这里先注册 Rive，最后注册 Lottie。
    [CYLTabBarItemAnimatorRegistry registerAnimator:rive];
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[CYLTestPAGAnimator alloc] init]];
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[CYLTestLottieAnimator alloc] init]];
}

int main(void) {
    @autoreleasepool {
        CYLTabBarItemViewAnimator *rive = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"Rive"
                                                                                fileExtensions:@[ @"RIV" ]
                                                                                 attributeKeys:@{ CYLTabBarAnimationURL : CYLTabBarRiveURL,
                                                                                                  CYLTabBarAnimationSize : CYLTabBarRiveSize,
                                                                                                  CYLTabBarAnimationDarkURL : CYLTabBarRiveDarkURL }
                                                                                  viewProvider:[CYLTestRiveView class]];
        CYLRegisterAll(rive);
        CHECK([[[CYLTabBarItemAnimatorRegistry animators] valueForKey:@"identifier"] isEqual:(@[ @"Rive", @"PAG", @"Lottie" ])],
              "lookup order: priority, then registration order; Lottie (the fallback) last");

        NSURL *cdnFile = [NSURL URLWithString:@"https://cdn.example.com/icons?id=42"];   // no extension
        NSURL *riv = [NSURL fileURLWithPath:@"/tmp/icons.riv"];
        NSURL *pag = [NSURL fileURLWithPath:@"/tmp/like.pag"];
        NSURL *json = [NSURL fileURLWithPath:@"/tmp/home.json"];
        NSNumber *riveSize = @30;
        NSNumber *lottieSize = @99;

        printf("\n# Three libraries registered, each tab configured with one of them\n");
        NSDictionary *riveTab = @{ CYLTabBarRiveURL : cdnFile, CYLTabBarRiveSize : riveSize };
        NSDictionary *pagTab = @{ CYLTabBarPAGURL : pag };
        NSDictionary *lottieTab = @{ CYLTabBarLottieURL : json, CYLTabBarLottieSize : lottieSize };
        NSDictionary *staticTab = @{ @"CYLTabBarItemTitle" : @"Static", @"CYLTabBarItemImage" : @"home" };
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForAttributes:riveTab]) isEqual:@"Rive"], "Rive's keys choose Rive");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForAttributes:pagTab]) isEqual:@"PAG"], "PAG's keys choose PAG");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForAttributes:lottieTab]) isEqual:@"Lottie"], "Lottie's keys choose Lottie");
        CHECK([CYLTabBarItemAnimatorRegistry animatorForAttributes:staticTab] == nil, "a static tab chooses no library");
        CHECK([CYLTabBarItemAttributesAnimationValue(riveTab, CYLTabBarAnimationURL) isEqual:cdnFile], "Core reads the Rive tab's URL from CYLTabBarRiveURL");
        CHECK([CYLTabBarItemAttributesAnimationValue(riveTab, CYLTabBarAnimationSize) isEqual:riveSize], "Core reads the Rive tab's size from CYLTabBarRiveSize");
        CHECK([CYLTabBarItemAttributesAnimationValue(lottieTab, CYLTabBarAnimationSize) isEqual:lottieSize], "Core reads the Lottie tab's size from CYLTabBarLottieSize");
        CHECK(CYLTabBarItemAttributesAnimationValue(staticTab, CYLTabBarAnimationURL) == nil, "a static tab has no animation");

        printf("\n# The keys decide, not the file extension\n");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:cdnFile]) isEqual:@"Lottie"], "unbound, a file without an extension goes to the fallback");
        [CYLTabBarItemAnimatorRegistry bindURL:cdnFile toAnimator:[CYLTabBarItemAnimatorRegistry animatorForAttributes:riveTab]];
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:cdnFile]) isEqual:@"Rive"], "bound by Rive's keys: Rive plays it, not Lottie");
        NSURL *pagNamedJSON = [NSURL fileURLWithPath:@"/tmp/exported.json"];
        [CYLTabBarItemAnimatorRegistry bindURL:pagNamedJSON toAnimator:[CYLTabBarItemAnimatorRegistry animatorForAttributes:@{ CYLTabBarPAGURL : pagNamedJSON }]];
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:pagNamedJSON]) isEqual:@"PAG"], "a .json file under a PAG key is played by PAG");
        [CYLTabBarItemAnimatorRegistry bindURL:pagNamedJSON toAnimator:nil];
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:pagNamedJSON]) isEqual:@"Lottie"], "unbinding (generic keys) gives the decision back to the file");

        printf("\n# Generic keys: the file's extension decides, as before\n");
        CHECK([CYLTabBarItemAnimatorRegistry animatorForAttributes:@{ CYLTabBarAnimationURL : riv }] == nil, "generic keys choose no library by themselves");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:riv]) isEqual:@"Rive"], ".riv -> Rive (extensions are case-insensitive)");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:pag]) isEqual:@"PAG"], ".pag -> PAG");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForURL:json]) isEqual:@"Lottie"], ".json -> Lottie");
        CHECK([CYLTabBarItemAttributesAnimationValue((@{ CYLTabBarAnimationURL : riv, CYLTabBarAnimationSize : riveSize }), CYLTabBarAnimationSize) isEqual:riveSize],
              "a generic key is read first");

        printf("\n# No mixing of libraries' keys\n");
        CHECK(CYLTabBarItemAttributesAnimationValue((@{ CYLTabBarRiveURL : riv, CYLTabBarLottieSize : lottieSize }), CYLTabBarAnimationSize) == nil,
              "a Rive tab does not pick up a stray Lottie size");
        NSDictionary *twoLibraries = @{ CYLTabBarLottieURL : json, CYLTabBarRiveURL : riv };
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForAttributes:twoLibraries]) isEqual:@"Rive"], "keys of two libraries: the first in lookup order (logged in DEBUG)");
        CHECK([CYLTabBarItemAttributesAnimationValue(twoLibraries, CYLTabBarAnimationURL) isEqual:riv], "...and only its URL is read");

        printf("\n# Only some of the libraries installed\n");
        [CYLTabBarItemAnimatorRegistry unregisterAnimatorWithIdentifier:@"Rive"];
        [CYLTabBarItemAnimatorRegistry unregisterAnimatorWithIdentifier:@"Lottie"];
        CHECK([CYLTabBarItemAnimatorRegistry animatorForAttributes:riveTab] == nil, "Rive's keys without the Rive pod choose nothing");
        CHECK(CYLTabBarItemAttributesAnimationValue(riveTab, CYLTabBarAnimationURL) == nil, "...so the tab shows its images");
        CHECK([CYLTabBarItemAnimatorRegistry animatorForURL:cdnFile] == nil, "a URL bound to a library that is gone goes to no other library");
        CHECK([CYLIdentifier([CYLTabBarItemAnimatorRegistry animatorForAttributes:pagTab]) isEqual:@"PAG"], "the installed library still plays its tabs");
        CYLRegisterAll(rive);

        printf("\n# A tab's options in its URL, through the view animator (Rive's way)\n");
        NSDictionary *options = @{ @"artboard" : @"LIKE/STAR", @"stateMachine" : @"State Machine 1", @"input" : @"a&b=c#d" };
        NSURL *optionURL = CYLTabBarAnimationURLWithOptions(riv, options);
        CHECK([optionURL.pathExtension isEqual:@"riv"], "options keep the file's extension, so generic keys still find Rive");
        CHECK([CYLTabBarAnimationURLWithOptions(riv, @{}) isEqual:riv], "no options: the same file URL");
        CHECK(CYLTabBarAnimationURLWithOptions(nil, options) == nil, "no file: nil");
        UIView *view = [rive animationViewWithURL:optionURL size:CGSizeMake(32, 32) contentMode:UIViewContentModeScaleAspectFit];
        CHECK([view isKindOfClass:[CYLTestRiveView class]], "the view comes from the named provider");
        CHECK([CYLLastRiveView.fileURL isEqual:riv], "the provider gets the file without its options");
        CHECK([CYLLastRiveView.options isEqual:options], "the options round-trip, including '/', '&', '=', '#' and spaces");
        CHECK(view.frame.size.width == 32 && view.frame.size.height == 32, "the view animator sets the view's size");
        CYLTabBarItemViewAnimator *noProvider = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"None"
                                                                                       fileExtensions:@[ @"none" ]
                                                                                        attributeKeys:nil
                                                                                         viewProvider:(Class<CYLTabBarItemAnimationViewProviding>)[CYLTestNotAProvider class]];
        CHECK(noProvider.viewProvider == nil, "a class given at initialization that does not adopt the protocol is refused");
        id<CYLTabBarItemAnimationPlayer> player = [rive playerForAnimationView:view];
        [player play];
        [player stop];
        CHECK(CYLLastRiveView.plays == 1 && CYLLastRiveView.stops == 1, "the forwarding player plays and stops the view");
        CHECK([rive playerForAnimationView:[[UIView alloc] init]] == nil, "a plain view gets no player");
        rive.viewProvider = (Class<CYLTabBarItemAnimationViewProviding>)[CYLTestNotAProvider class];
        CHECK(rive.viewProvider == [CYLTestRiveView class], "a class that does not adopt the provider protocol is refused");
        rive.viewProvider = nil;
        CHECK(rive.viewProvider == [CYLTestRiveView class], "nil goes back to the default provider");
        CHECK(![rive canAnimateFileAtURL:json] && [rive canAnimateFileAtURL:optionURL], "the view animator takes its own extension only");

        printf("\n# Injected registries are independent (no global state)\n");
        CYLTabBarItemAnimatorRegistry *isolated = [[CYLTabBarItemAnimatorRegistry alloc] init];
        CHECK(isolated != [CYLTabBarItemAnimatorRegistry sharedRegistry] && [isolated animators].count == 0,
              "a new registry starts empty, apart from the shared one");
        [isolated registerAnimator:[[CYLTestPAGAnimator alloc] init]];
        CHECK([CYLIdentifier([isolated animatorForAttributes:pagTab]) isEqual:@"PAG"] && [isolated animatorForAttributes:riveTab] == nil,
              "an injected registry only knows its own animators");
        CHECK([isolated animatorForURL:cdnFile] == nil, "bindings in the shared registry do not leak into another one");
        CHECK([[CYLTabBarItemAnimatorRegistry animators] count] == 3, "registering into another registry leaves the shared one unchanged");
        CHECK([CYLTabBarItemAnimatorRegistry sharedRegistry] == [CYLTabBarItemAnimatorRegistry sharedRegistry], "the class methods use one shared registry");

        printf("\n# The factory works over the registry it is given\n");
        CYLTabBarItemAnimationFactory *emptyFactory = [[CYLTabBarItemAnimationFactory alloc] initWithRegistry:[[CYLTabBarItemAnimatorRegistry alloc] init]];
        CHECK([emptyFactory animationViewWithURL:optionURL size:CGSizeMake(24, 24) contentMode:UIViewContentModeScaleAspectFit] == nil,
              "a factory over an empty registry makes no view, whatever is registered elsewhere");
        CYLTabBarItemAnimatorRegistry *riveOnly = [[CYLTabBarItemAnimatorRegistry alloc] init];
        [riveOnly registerAnimator:rive];
        CYLTabBarItemAnimationFactory *riveFactory = [[CYLTabBarItemAnimationFactory alloc] initWithRegistry:riveOnly];
        CHECK(riveFactory.registry == riveOnly, "the factory keeps the injected registry");
        UIView *madeView = [riveFactory animationViewWithURL:optionURL size:CGSizeMake(24, 24) contentMode:UIViewContentModeScaleAspectFit];
        CHECK([madeView isKindOfClass:[CYLTestRiveView class]] && madeView.frame.size.width == 24 && !madeView.userInteractionEnabled,
              "the injected registry's animator makes the view, set up by the factory");
        CHECK([riveFactory playerForView:madeView] != nil && [riveFactory isAnimationView:madeView], "the made view has its player");
        CHECK(![riveFactory isAnimationView:[[UIView alloc] init]], "a plain view is no animation view");
        CHECK([CYLTabBarItemAnimationFactory sharedFactory].registry == [CYLTabBarItemAnimatorRegistry sharedRegistry],
              "the shared factory uses the shared registry");

        printf("\n# The engine, over injected fakes only (no Core)\n");
        CHECK([(id)CYLTabBarItemAnimationGetService() isKindOfClass:[CYLTabBarItemAnimationEngine class]],
              "the engine injects itself into Core's service slot at +load");
        CYLTestHost *host = [[CYLTestHost alloc] init];
        CYLTestStyleSource *styleSource = [[CYLTestStyleSource alloc] init];
        CYLTabBarItemAnimationEngine *engine = [[CYLTabBarItemAnimationEngine alloc] initWithRegistry:riveOnly
                                                                                              factory:riveFactory
                                                                                          styleSource:styleSource
                                                                                                 host:host];
        NSURL *lightFile = CYLTestFile(@"cyl-engine-light.riv");
        NSURL *darkFile = CYLTestFile(@"cyl-engine-dark.riv");
        UIControl *tab = [[UIControl alloc] init];
        [engine addAnimationWithURL:lightFile size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:tab];
        UIView *added = [engine animationViewInControl:tab];
        CHECK(added != nil && added == host.shownView, "the engine makes the view with the injected factory and the host shows it");
        CHECK(added.frame.size.width == 28, "without a size, the host's default size is used");
        CHECK([CYLLastRiveView.fileURL isEqual:lightFile], "no dark version: the light file is played");
        [engine addAnimationWithURL:lightFile size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:tab];
        CHECK(tab.subviews.count == 1, "adding again keeps the one view");
        CHECK(![engine isAnimationReadyInControl:tab], "readiness is the host's decision (not ready)");
        host.ready = YES;
        CHECK([engine isAnimationReadyInControl:tab], "readiness is the host's decision (ready)");
        [engine playAnimationWithURL:lightFile size:CGSizeZero defaultSelected:NO contentMode:UIViewContentModeScaleAspectFit inControl:tab];
        CHECK(host.willPlays == 1 && ((CYLTestRiveView *)added).plays == 1, "play: the host tells the other tabs, then the player plays");
        [engine stopAnimationInControl:tab];
        CHECK(((CYLTestRiveView *)added).stops == 1, "stop goes through the player");
        CHECK([[engine attributeKeyForGenericKey:CYLTabBarAnimationURL inAttributes:riveTab] isEqual:CYLTabBarRiveURL],
              "attribute keys come from the injected registry");
        CHECK([engine attributeKeyForGenericKey:CYLTabBarAnimationURL inAttributes:pagTab] == nil,
              "a library missing from the injected registry is not chosen");

        UIControl *plusButton = [[UIControl alloc] init];
        host.plus = YES;
        [engine addAnimationWithURL:lightFile size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:plusButton];
        CHECK(plusButton.subviews.count == 0, "the host's plus button gets no animation");
        host.plus = NO;

        printf("\n# A tab's missing resource is reported to CYLAnimationEngines, found at run time\n");
        NSMutableArray<NSArray *> *engineCalls = [CYLAnimationEngines calls];
        [engineCalls removeAllObjects];
        UIControl *missingTab = [[UIControl alloc] init];
        NSURL *missingFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl-engine-missing.riv"]];
        [[NSFileManager defaultManager] removeItemAtURL:missingFile error:NULL];
        [engine addAnimationWithURL:missingFile size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:missingTab];
        CHECK(engineCalls.count == 1 && [engineCalls[0][0] isEqual:@"notMade"] && [engineCalls[0][1] isEqual:missingFile] && engineCalls[0][2] == missingTab,
              "a local file that is not there is reported for its tab button");
        [engineCalls removeAllObjects];
        [engine addAnimationWithURL:nil size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:missingTab];
        [engine addAnimationWithURL:[NSURL URLWithString:@"https://example.com/remote.riv"] size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:missingTab];
        CHECK(engineCalls.count == 0, "no URL and a remote URL report nothing on the tab path");
        UIControl *failingTab = [[UIControl alloc] init];
        [engine addAnimationWithURL:lightFile size:CGSizeZero contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:failingTab];
        UIView *failingView = [engine animationViewInControl:failingTab];
        CHECK(failingView != nil && engineCalls.count == 0, "a made view reports nothing");
        NSError *parseError = [NSError errorWithDomain:@"CYLTest" code:7 userInfo:nil];
        CYLTabBarItemAnimationReportFailure(failingView, parseError);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        // [EN] Every engine this process made hears the notification (each observes it); the one that finds the tab button reports it for the button,
        //      another one that cannot reaches the view itself. Every report names the file and the error; at least one is for the tab button.
        // [CN] 本进程创建的每个引擎都会收到该通知（各自都在观察）；找到 Tab 按钮的引擎为按钮报告，找不到的引擎则为视图本身报告。每次报告都带有文件与错误；至少有一次是为 Tab 按钮。
        BOOL allForTheTab = engineCalls.count >= 1;
        BOOL oneForTheButton = NO;
        for (NSArray *call in engineCalls) {
            allForTheTab = allForTheTab && [call[0] isEqual:@"failure"] && [call[1] isEqual:lightFile] && call[2] == parseError;
            oneForTheButton = oneForTheButton || call[3] == failingTab;
        }
        allForTheTab = allForTheTab && oneForTheButton;
        CHECK(allForTheTab, "a late failure reports the file the view was made for, with its error, for its tab button");

        printf("\n# Dark Mode through the injected style source (#442)\n");
        styleSource.lightURL = lightFile;
        styleSource.darkURL = darkFile;
        UIControl *darkTab = [[UIControl alloc] init];
        darkTab.traitCollection = [[UITraitCollection alloc] init];
        darkTab.traitCollection.userInterfaceStyle = UIUserInterfaceStyleDark;
        [engine addAnimationWithURL:lightFile size:CGSizeMake(30, 30) contentMode:UIViewContentModeScaleAspectFit animationSpeed:0 toControl:darkTab];
        UIView *darkView = [engine animationViewInControl:darkTab];
        CHECK(darkView && [CYLLastRiveView.fileURL isEqual:darkFile], "a dark style plays the dark version");
        darkTab.traitCollection.userInterfaceStyle = UIUserInterfaceStyleLight;
        [engine reloadAnimationForCurrentStyleInControl:darkTab];
        UIView *lightView = [engine animationViewInControl:darkTab];
        CHECK(lightView != darkView && [((CYLTestRiveView *)lightView).fileURL isEqual:lightFile],
              "a style change swaps in the light version");
        CHECK(darkTab.subviews.count == 1 && darkView.superview == nil, "the old view is removed");
        CHECK(host.trackedReplacements == 1, "the host moves its layout tracking to the new view");
        CHECK(lightView.frame.size.width == 30, "the new view keeps the size");

        printf("\n# The forwarding player: progress and speed only when the view offers them\n");
        CYLTabBarItemViewAnimator *svga = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"SVGA"
                                                                                fileExtensions:@[ @"svga" ]
                                                                                 attributeKeys:@{ CYLTabBarAnimationURL : CYLTabBarAnimationURL }
                                                                                  viewProvider:[CYLTestSeekableView class]];
        CYLTestSeekableView *seekable = [[CYLTestSeekableView alloc] init];
        id<CYLTabBarItemAnimationPlayer> seekPlayer = [svga playerForAnimationView:seekable];
        CHECK([(id)seekPlayer respondsToSelector:@selector(setProgress:)] && [(id)seekPlayer respondsToSelector:@selector(progress)],
              "a view with both progress methods gives its player progress");
        CHECK([(id)seekPlayer respondsToSelector:@selector(setAnimationSpeed:)], "a view with a rate gives its player animationSpeed");
        CHECK([(id)seekPlayer respondsToSelector:@selector(setLoops:)], "a view that loops itself gives its player loops");
        seekPlayer.progress = 0.4;
        CHECK(seekable.progressValue > 0.39 && seekable.progressValue < 0.41 && seekPlayer.progress > 0.39, "progress reaches the view and reads back");
        seekPlayer.progress = 7;
        CHECK(seekable.progressValue == 1, "progress is clamped to 0...1");
        seekPlayer.animationSpeed = 2.5;
        CHECK(seekable.speedValue == 2.5 && seekPlayer.animationSpeed == 2.5, "the speed reaches the view");
        seekPlayer.animationSpeed = 0;
        CHECK(seekable.speedValue == 2.5, "a speed that is not positive is ignored");
        seekPlayer.loops = YES;
        CHECK(seekable.loopsValue, "loops reach the view");
        id<CYLTabBarItemAnimationPlayer> plainPlayer = [rive playerForAnimationView:[[CYLTestRiveView alloc] init]];
        CHECK(![(id)plainPlayer respondsToSelector:@selector(setProgress:)] && ![(id)plainPlayer respondsToSelector:@selector(setAnimationSpeed:)],
              "a view without them keeps the host's fallback (no progress, no speed)");

        printf("\n# Core's style registry: instance state, no global dictionaries\n");
        CYLTabBarItemAnimationStyleRegistry *styles = [[CYLTabBarItemAnimationStyleRegistry alloc] init];
        CYLTabBarItemAnimationStyleRegistry *otherStyles = [[CYLTabBarItemAnimationStyleRegistry alloc] init];
        CHECK(![styles hasStyleVariants], "a new style registry has no variants");
        [styles registerDarkURL:darkFile forURL:lightFile];
        CHECK([styles hasStyleVariants] && [styles hasStyleVariantForURL:lightFile], "a dark version makes a variant");
        CHECK(![otherStyles hasStyleVariants], "registrations stay in their own instance");
        UITraitCollection *darkTraits = [[UITraitCollection alloc] init];
        darkTraits.userInterfaceStyle = UIUserInterfaceStyleDark;
        UITraitCollection *lightTraits = [[UITraitCollection alloc] init];
        lightTraits.userInterfaceStyle = UIUserInterfaceStyleLight;
        CHECK([[styles URL:lightFile forTraitCollection:darkTraits] isEqual:darkFile], "dark traits: the dark version");
        CHECK([[styles URL:lightFile forTraitCollection:lightTraits] isEqual:lightFile], "light traits: the light animation");
        CHECK([[styles URL:darkFile forTraitCollection:darkTraits] isEqual:darkFile], "an URL without a dark version is kept");
        UIColor *color = [[UIColor alloc] init];
        NSDictionary *mixedColors = @{ @"Fill 1" : color, @"" : color, @"Fill 2" : (id)@"not a color" };
        [styles registerDarkColors:mixedColors forURL:riv];
        CHECK([[styles darkColorsForURL:riv] isEqual:(@{ @"Fill 1" : color })], "only non-empty keypath -> color pairs are kept");
        [styles registerDarkURL:nil forURL:lightFile];
        CHECK(![styles hasStyleVariantForURL:lightFile], "nil clears a dark version");
    }
    printf("\n%d checks, %d failures\n", CYLChecks, CYLFailures);
    return CYLFailures == 0 ? 0 : 1;
}
