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

// [EN] The Core functions under test, extracted by run.sh. [CN] 被测试的 Core 函数，由 run.sh 提取。
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

/// [EN] Adopts only one of the two protocols: refused as a view provider. [CN] 只遵守两个协议之一：不能作为视图 provider。
@interface CYLTestNotAProvider : UIView <CYLTabBarItemAnimationPlayableView>
@end
@implementation CYLTestNotAProvider
- (void)cyl_playAnimationView {}
- (void)cyl_showAnimationViewLastFrame {}
- (void)cyl_stopAnimationView {}
@end

#pragma mark - The service Core talks to

/// [EN] Forwards to the registry exactly as `CYLTabBarItemAnimationEngine` does. [CN] 与 `CYLTabBarItemAnimationEngine` 一样转发给注册表。
@interface CYLTestService : NSObject
- (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes;
@end
@implementation CYLTestService
- (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes {
    return [CYLTabBarItemAnimatorRegistry attributeKeyForGenericKey:genericKey inAttributes:attributes];
}
@end
CYLTestService *CYLTabBarItemAnimationGetService(void);
CYLTestService *CYLTabBarItemAnimationGetService(void) {
    static CYLTestService *service;
    if (!service) {
        service = [[CYLTestService alloc] init];
    }
    return service;
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
                                                                         viewProviderClassName:@"CYLTestRiveView"];
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
    }
    printf("\n%d checks, %d failures\n", CYLChecks, CYLFailures);
    return CYLFailures == 0 ? 0 : 1;
}
