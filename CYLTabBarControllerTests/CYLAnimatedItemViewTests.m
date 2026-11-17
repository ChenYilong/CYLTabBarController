//
//  CYLAnimatedItemViewTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import "../CYLTabBarController/CYLAnimatedItem/CYLAnimatedItemView.h"
#if CYL_ANIMATION_ENGINE_AVAILABLE
#import "../CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimatorRegistry.h"
#endif

// [EN] Declared in CYLTabBarItemAnimatorRegistry.h (the engine), not in the umbrella header.
// [CN] 声明于 CYLTabBarItemAnimatorRegistry.h（引擎），不在总头文件中。
FOUNDATION_EXTERN BOOL CYLTabBarItemAnimationURLMayBeLottie(NSURL *_Nullable URL, BOOL acceptsDotLottie);

#if CYL_ANIMATION_ENGINE_AVAILABLE
/*
 * [EN] An animator that only matches by extension, for the registry's engine status. [CN] 只按扩展名匹配的 animator，用于注册表的引擎状态。
 */
@interface CYLAnimatedItemStatusAnimator : NSObject <CYLTabBarItemAnimator>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSArray<NSString *> *fileExtensions;
@property (nonatomic, assign) CYLTabBarItemAnimatorPriority priority;
@end

@implementation CYLAnimatedItemStatusAnimator
+ (instancetype)animatorWithIdentifier:(NSString *)identifier extensions:(NSArray<NSString *> *)extensions priority:(CYLTabBarItemAnimatorPriority)priority {
    CYLAnimatedItemStatusAnimator *animator = [[self alloc] init];
    animator.identifier = identifier;
    animator.fileExtensions = extensions;
    animator.priority = priority;
    return animator;
}
- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    return [self.fileExtensions containsObject:URL.pathExtension.lowercaseString];
}
- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    return nil;
}
- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return nil;
}
@end
#endif

#if CYL_ANIMATION_ENGINE_AVAILABLE
/*
 * [EN] A player that records calls. [CN] 记录调用的播放器。
 */
@interface CYLAnimatedItemFakePlayer : NSObject <CYLTabBarItemAnimationPlayer>
@property (nonatomic, weak, nullable) UIView *animationView;
@property (nonatomic, strong) NSMutableArray<NSString *> *calls;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat animationSpeed;
@property (nonatomic, assign) BOOL loops;
@end

@implementation CYLAnimatedItemFakePlayer
- (instancetype)init {
    if (self = [super init]) {
        _calls = [NSMutableArray array];
        _animationSpeed = 1;
    }
    return self;
}
- (void)play { [self.calls addObject:@"play"]; }
- (void)stop { [self.calls addObject:@"stop"]; }
- (void)showLastFrame { [self.calls addObject:@"last"]; }
@end

/*
 * [EN] An animation source for ".fake" files: stands for any animator of the engine. [CN] 处理 ".fake" 文件的动画来源：代表引擎中的任意 animator。
 */
@interface CYLAnimatedItemFakeSource : NSObject <CYLTabBarItemAnimationViewMaking>
@property (nonatomic, strong) NSMapTable<UIView *, CYLAnimatedItemFakePlayer *> *players;
@end

@implementation CYLAnimatedItemFakeSource
- (instancetype)init {
    if (self = [super init]) {
        _players = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}
- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    if (![URL.pathExtension isEqualToString:@"fake"]) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    CYLAnimatedItemFakePlayer *player = [[CYLAnimatedItemFakePlayer alloc] init];
    player.animationView = view;
    [self.players setObject:player forKey:view];
    return view;
}
- (id<CYLTabBarItemAnimationPlayer>)playerForView:(UIView *)view {
    return view ? [self.players objectForKey:view] : nil;
}
- (BOOL)isAnimationView:(UIView *)view {
    return [self playerForView:view] != nil;
}
@end

/*
 * [EN] A source whose views wait for a download. [CN] 视图需要等待下载的来源。
 */
@interface CYLAnimatedItemDownloadingSource : CYLAnimatedItemFakeSource
@end

@implementation CYLAnimatedItemDownloadingSource
- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    UIView *view = [super animationViewWithURL:URL size:size contentMode:contentMode];
    if (view) {
        CYLTabBarItemAnimationMarkLoading(view);
    }
    return view;
}
@end
#endif

/*
 * [EN] A tag as another repository would write it: a delete accessory, a badge read with the title, a state hook.
 * [CN] 其他仓库会这样写的标签：删除附加图标、随标题朗读的角标、状态钩子。
 */
@interface CYLAnimatedItemTestTag : CYLAnimatedItemView
@property (nonatomic, copy, nullable) NSString *badge;
@property (nonatomic, assign) NSInteger stateChanges;
@end

@implementation CYLAnimatedItemTestTag
- (void)setBadge:(NSString *)badge {
    _badge = [badge copy];
    [self updateItemAccessibility];
}
- (NSString *)itemAccessibilityLabel {
    return self.badge ? [NSString stringWithFormat:@"%@, %@", self.title, self.badge] : self.title;
}
- (void)itemStateDidChange {
    self.stateChanges += 1;
}
@end

@interface CYLAnimatedItemViewTests : XCTestCase <CYLAnimatedItemViewDelegate>
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@end

@implementation CYLAnimatedItemViewTests

- (void)setUp {
    [super setUp];
    self.events = [NSMutableArray array];
}

- (UIImage *)icon {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(20, 20)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor blueColor] setFill];
        [context fillRect:CGRectMake(0, 0, 20, 20)];
    }];
}

- (void)testHorizontalLayoutPutsTheTitleAfterTheIcon {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.title = @"Home";
    item.image = [self icon];
    [item layoutIfNeeded];
    XCTAssertGreaterThanOrEqual(CGRectGetMinX(item.titleLabel.frame), CGRectGetMaxX(item.imageView.frame));
    XCTAssertEqualWithAccuracy(CGRectGetMidY(item.imageView.frame), 22, 1);
    XCTAssertEqualObjects(item.accessibilityLabel, @"Home");
    XCTAssertTrue(item.accessibilityTraits & UIAccessibilityTraitButton);
    CGSize fitting = [item sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    XCTAssertGreaterThan(fitting.width, 20);
}

- (void)testVerticalLayoutPutsTheIconAboveTheTitle {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    item.axis = CYLAnimatedItemAxisVertical;
    item.title = @"Empty";
    item.image = [self icon];
    [item layoutIfNeeded];
    XCTAssertGreaterThanOrEqual(CGRectGetMinY(item.titleLabel.frame), CGRectGetMaxY(item.imageView.frame));
    XCTAssertEqualWithAccuracy(CGRectGetMidX(item.imageView.frame), 100, 1);
}

- (void)testSelectedImageStateHookAndTraits {
    CYLAnimatedItemTestTag *item = [[CYLAnimatedItemTestTag alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UIImage *selected = [self icon];
    item.title = @"Tag";
    item.image = [self icon];
    item.selectedImage = selected;
    item.selected = YES;
    XCTAssertEqual(item.imageView.image, selected);
    XCTAssertEqual(item.stateChanges, 1);
    XCTAssertTrue(item.accessibilityTraits & UIAccessibilityTraitSelected);
    item.badge = @"3 new";
    XCTAssertEqualObjects(item.accessibilityLabel, @"Tag, 3 new");
}

#if CYL_ANIMATION_ENGINE_AVAILABLE
- (void)testPlaysAnyAnimationOfTheSource {
    CYLAnimatedItemFakeSource *source = [[CYLAnimatedItemFakeSource alloc] init];
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = source;
    item.image = [self icon];
    item.animationLoops = YES;
    item.animationSpeed = 2;
    item.animationURL = [NSURL URLWithString:@"https://example.com/home.fake"];
    XCTAssertTrue(item.isAnimationReady);
    XCTAssertTrue(item.imageView.hidden);
    CYLAnimatedItemFakePlayer *player = (CYLAnimatedItemFakePlayer *)item.animationPlayer;
    XCTAssertTrue(player.loops);
    XCTAssertEqual(player.animationSpeed, 2);
    player.progress = 0.7;
    [item restartAnimation];
    XCTAssertEqual(player.progress, 0, @"Play all restarts from 0");
    item.animationRestingProgress = 1;
    [item stopAnimation];
    XCTAssertEqualObjects(player.calls, (@[ @"play", @"stop" ]));
    XCTAssertEqual(player.progress, 1);
    [item showAnimationLastFrame];
    XCTAssertEqualObjects(player.calls.lastObject, @"last");
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.unknown"];
    XCTAssertFalse(item.isAnimationReady, @"an unknown file falls back to the image");
    XCTAssertFalse(item.imageView.hidden);
}

- (void)testTheSharedEngineIsTheDefaultSource {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] init];
    XCTAssertEqual(item.animationSource, [CYLTabBarItemAnimationFactory sharedFactory]);
}

- (void)testOnlyAnUnplayableAnimationFileShowsThePlaceholder {
    UIImage *placeholder = [self icon];
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemFakeSource alloc] init];
    item.placeholderImage = placeholder;
    item.title = @"Home";
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.json"];
    [item layoutIfNeeded];
    XCTAssertFalse(item.isAnimationReady);
    XCTAssertEqual(item.imageView.image, placeholder, @"no static image, the file cannot play: the placeholder");
    XCTAssertFalse(item.imageView.hidden);
    XCTAssertGreaterThan(CGRectGetWidth(item.imageView.frame), 0);
    XCTAssertNoThrow([item playAnimation]);
    XCTAssertNoThrow([item restartAnimation]);
    XCTAssertNoThrow([item stopAnimation]);
    item.animationURL = [NSURL URLWithString:@"https://example.com/home.fake"];
    XCTAssertTrue(item.isAnimationReady);
    XCTAssertTrue(item.imageView.hidden, @"the animation wins once it can play");
    item.placeholderImage = [[UIImage alloc] init];
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.json"];
    CYLAnimatedItemView *titleOnly = [[CYLAnimatedItemView alloc] init];
    titleOnly.title = @"Home";
    XCTAssertTrue(CGSizeEqualToSize([titleOnly sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)],
                                    [item sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)]), @"an empty placeholder shows none");
}

- (void)testTheDefaultPlaceholderIsATabIconSizedTemplate {
    UIImage *placeholder = CYLAnimatedItemView.defaultPlaceholderImage;
    if (!placeholder) {
        return; // [EN] The test host may not copy CYLAnimatedItem.bundle. [CN] 测试宿主可能未拷贝 CYLAnimatedItem.bundle。
    }
    XCTAssertTrue(CGSizeEqualToSize(placeholder.size, CGSizeMake(25, 25)));
    XCTAssertEqual(placeholder.renderingMode, UIImageRenderingModeAlwaysTemplate);
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] init];
    XCTAssertEqual(item.placeholderImage, placeholder);
}

- (void)testBothWithAnUnplayableFileShowTheImage {
    UIImage *icon = [self icon];
    CYLAnimatedItemView *imageOnly = [[CYLAnimatedItemView alloc] init];
    imageOnly.title = @"Home";
    imageOnly.image = icon;
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemFakeSource alloc] init];
    item.title = @"Home";
    item.image = icon;
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.json"];
    [item layoutIfNeeded];
    XCTAssertFalse(item.imageView.hidden);
    XCTAssertEqual(item.imageView.image, icon);
    XCTAssertTrue(CGSizeEqualToSize([imageOnly sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)],
                                    [item sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)]), @"the same layout as the image alone");
}

- (void)testBothWithAPlayableFilePreferTheAnimation {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemFakeSource alloc] init];
    item.title = @"Home";
    item.image = [self icon];
    item.animationURL = [NSURL URLWithString:@"https://example.com/home.fake"];
    [item layoutIfNeeded];
    XCTAssertTrue(item.isAnimationReady);
    XCTAssertTrue(item.imageView.hidden, @"the static image waits under the animation");
    XCTAssertTrue(CGRectEqualToRect(item.animationView.frame, item.imageView.frame), @"the animation takes the icon's place");
}

- (void)testAMissingLocalFileShowsThePlaceholderWithoutAskingTheEngine {
    CYLAnimatedItemFakeSource *source = [[CYLAnimatedItemFakeSource alloc] init];
    UIImage *placeholder = [self icon];
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = source;
    item.placeholderImage = placeholder;
    NSString *missing = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl-missing-home.fake"];
    [[NSFileManager defaultManager] removeItemAtPath:missing error:NULL];
    item.animationURL = [NSURL fileURLWithPath:missing];
    XCTAssertEqual(source.players.count, 0u, @"a missing file never reaches the engine");
    XCTAssertEqual(item.imageView.image, placeholder);
    NSString *empty = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl-empty-home.fake"];
    [[NSData data] writeToFile:empty atomically:YES];
    item.animationURL = [NSURL fileURLWithPath:empty];
    XCTAssertEqual(source.players.count, 0u, @"an empty file is missing too");
    NSString *full = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl-full-home.fake"];
    [[@"{}" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:full atomically:YES];
    item.animationURL = [NSURL fileURLWithPath:full];
    XCTAssertTrue(item.isAnimationReady);
}

- (void)testAFailureReportedLaterShowsThePlaceholderOrTheImage {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemFakeSource alloc] init];
    UIImage *placeholder = [self icon];
    item.placeholderImage = placeholder;
    item.animationURL = [NSURL URLWithString:@"https://example.com/home.fake"];
    XCTAssertTrue(item.isAnimationReady);
    CYLTabBarItemAnimationReportFailure(item.animationView, [NSError errorWithDomain:@"CYLTest" code:1 userInfo:nil]);
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertFalse(item.isAnimationReady, @"a corrupted file or a failed download drops the animation");
    XCTAssertEqual(item.imageView.image, placeholder);
    XCTAssertFalse(item.imageView.hidden);
    UIImage *image = [self icon];
    item.image = image;
    item.animationURL = [NSURL URLWithString:@"https://example.com/other.fake"];
    CYLTabBarItemAnimationReportFailure(item.animationView, nil);
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertEqual(item.imageView.image, image, @"with a static image, the image is the fallback");
}

- (void)testWithAStaticImageAMissingFileShowsTheImageNotThePlaceholder {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemFakeSource alloc] init];
    UIImage *image = [self icon];
    item.image = image;
    item.placeholderImage = [self icon];
    NSString *missing = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl-missing-with-image.fake"];
    [[NSFileManager defaultManager] removeItemAtPath:missing error:NULL];
    item.animationURL = [NSURL fileURLWithPath:missing];
    XCTAssertEqual(item.imageView.image, image, @"the placeholder is only for an item without a static image");
    item.animationURL = [NSURL URLWithString:@"https://example.com/home.unknown"];
    XCTAssertEqual(item.imageView.image, image);
}

- (void)testWhileARemoteFileDownloadsTheStaticImageOrThePlaceholderShows {
    UIImage *image = [self icon];
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemDownloadingSource alloc] init];
    item.image = image;
    item.animationURL = [NSURL URLWithString:@"https://example.com/home.fake"];
    XCTAssertTrue(CYLTabBarItemAnimationIsLoading(item.animationView));
    XCTAssertEqual(item.imageView.image, image, @"downloading: the static image");
    XCTAssertFalse(item.imageView.hidden);
    CYLTabBarItemAnimationReportLoaded(item.animationView);
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertTrue(item.imageView.hidden, @"downloaded: the animation");

    UIImage *placeholder = [self icon];
    CYLAnimatedItemView *bare = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    bare.animationSource = [[CYLAnimatedItemDownloadingSource alloc] init];
    bare.placeholderImage = placeholder;
    bare.animationURL = [NSURL URLWithString:@"https://example.com/home.fake"];
    XCTAssertEqual(bare.imageView.image, placeholder, @"downloading without a static image: the placeholder");
    XCTAssertFalse(bare.imageView.hidden);
    CYLTabBarItemAnimationReportFailure(bare.animationView, nil);
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertFalse(bare.isAnimationReady, @"a failed download drops the animation");
    XCTAssertEqual(bare.imageView.image, placeholder);
}

- (void)testAFailureOfAnOldAnimationIsIgnored {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.animationSource = [[CYLAnimatedItemFakeSource alloc] init];
    item.animationURL = [NSURL URLWithString:@"https://example.com/a.fake"];
    UIView *old = item.animationView;
    item.animationURL = [NSURL URLWithString:@"https://example.com/b.fake"];
    [item addSubview:old];
    CYLTabBarItemAnimationReportFailure(old, nil);
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertTrue(item.isAnimationReady, @"the current animation stays");
    [old removeFromSuperview];
}

#else
- (void)testWithoutTheEngineBothShowTheImage {
    UIImage *icon = [self icon];
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.image = icon;
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.json"];
    [item layoutIfNeeded];
    XCTAssertFalse(item.imageView.hidden);
    XCTAssertEqual(item.imageView.image, icon);
    XCTAssertGreaterThan(CGRectGetWidth(item.imageView.frame), 0);
}

- (void)testWithoutTheEngineOnlyAnAnimationShowsThePlaceholder {
    UIImage *placeholder = [self icon];
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.placeholderImage = placeholder;
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.json"];
    [item layoutIfNeeded];
    XCTAssertEqual(item.imageView.image, placeholder);
    XCTAssertGreaterThan(CGRectGetWidth(item.imageView.frame), 0);
}

- (void)testWithoutTheEngineOnlyTheStaticImageShows {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.image = [self icon];
    item.animationURL = [NSURL fileURLWithPath:@"/tmp/home.json"];
    [item playAnimation];
    XCTAssertFalse(item.isAnimationReady);
    XCTAssertNil(item.animationView);
    XCTAssertFalse(item.imageView.hidden);
    XCTAssertNotNil(item.animationURL, @"kept for when an animation subspec is added");
}

#endif
- (void)testAccessoryIsPlacedAndReachableFromVoiceOver {
    CYLAnimatedItemView *item = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    item.delegate = self;
    item.title = @"Tag";
    UIButton *delete = [UIButton buttonWithType:UIButtonTypeSystem];
    delete.accessibilityLabel = @"Delete";
    item.accessoryView = delete;
    [item layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(delete.frame), 200, 0.5, @"trailing by default");
    [self cyl_sendTouchUpInsideTo:delete];
    XCTAssertEqualObjects(self.events, (@[ @"accessory" ]));
    UIAccessibilityCustomAction *action = item.accessibilityCustomActions.lastObject;
    XCTAssertEqualObjects(action.name, @"Delete");
    [self cyl_sendTouchUpInsideTo:item];
    XCTAssertEqualObjects(self.events.lastObject, @"tap");
    item.dragEnabled = YES;
    XCTAssertTrue(item.panGestureRecognizer.enabled);
}

#pragma mark - Helpers

/*
 * [EN] Runs the touch-up-inside actions of `control`. These are logic tests without a host app, so there is no
 *      UIApplication and -sendActionsForControlEvents: delivers nothing; the targets are called directly instead.
 * [CN] 执行 `control` 的 touch-up-inside 事件。本测试是没有宿主 App 的逻辑测试，没有 UIApplication，
 *      -sendActionsForControlEvents: 不会派发任何事件，因此直接调用各 target。
 */
- (void)cyl_sendTouchUpInsideTo:(UIControl *)control {
    for (id target in control.allTargets) {
        for (NSString *name in [control actionsForTarget:target forControlEvent:UIControlEventTouchUpInside]) {
            SEL action = NSSelectorFromString(name);
            IMP imp = [target methodForSelector:action];
            ((void (*)(id, SEL, id))imp)(target, action, control);
        }
    }
}

#pragma mark - CYLAnimatedItemViewDelegate

- (void)animatedItemViewDidTap:(CYLAnimatedItemView *)itemView {
    [self.events addObject:@"tap"];
}

- (void)animatedItemViewDidTapAccessory:(CYLAnimatedItemView *)itemView {
    [self.events addObject:@"accessory"];
}

#pragma mark - A file Lottie cannot play (the Lottie animator takes every other file)

/*!
 * [EN] The Lottie animator takes every file no other animator takes. A picture or a broken file used to get an empty
 *      Lottie view that hid the static image (found by CollectionViewClassifyMenu's tests with Lottie linked); it now asks
 *      CYLTabBarItemAnimationURLMayBeLottie first, which needs no Lottie and is tested here.
 * [CN] Lottie animator 接收其他 animator 都不处理的文件。图片或损坏的文件以前会得到一个空的 Lottie 视图并遮住静态图片（CollectionViewClassifyMenu
 *      在链接 Lottie 时的测试发现）；现在它先调用 CYLTabBarItemAnimationURLMayBeLottie，该函数不需要 Lottie，在这里测试。
 */
- (void)testOnlyALottieDocumentIsTakenByTheLottieAnimator {
    NSString *folder = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    XCTAssertTrue([[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL]);
    NSURL * (^write)(NSString *, NSData *) = ^NSURL *(NSString *name, NSData *data) {
        NSString *path = [folder stringByAppendingPathComponent:name];
        XCTAssertTrue([data writeToFile:path atomically:YES]);
        return [NSURL fileURLWithPath:path];
    };
    NSData *lottie = [@"{\"v\": \"5.7.4\", \"fr\": 30, \"ip\": 0, \"op\": 30, \"w\": 24, \"h\": 24, \"layers\": []}" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue(CYLTabBarItemAnimationURLMayBeLottie(write(@"home.json", lottie), NO));
    XCTAssertTrue(CYLTabBarItemAnimationURLMayBeLottie(write(@"home-without-extension", lottie), NO), @"the content decides, not the name");
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie(write(@"home.png", UIImagePNGRepresentation([self icon])), YES), @"a picture");
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie(write(@"broken.json", [@"{\"v\": " dataUsingEncoding:NSUTF8StringEncoding]), YES));
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie(write(@"other.json", [@"{\"name\": \"home\"}" dataUsingEncoding:NSUTF8StringEncoding]), YES),
                   @"JSON that is not an animation");
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie([NSURL fileURLWithPath:[folder stringByAppendingPathComponent:@"missing.json"]], YES));
    const unsigned char zip[] = { 'P', 'K', 3, 4, 0, 0, 0, 0 };
    NSURL *dotLottie = write(@"home.lottie", [NSData dataWithBytes:zip length:sizeof(zip)]);
    XCTAssertTrue(CYLTabBarItemAnimationURLMayBeLottie(dotLottie, YES), @"a .lottie archive with Lottie 4");
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie(dotLottie, NO), @"Lottie 2 cannot play a .lottie archive");
    XCTAssertTrue(CYLTabBarItemAnimationURLMayBeLottie([NSURL URLWithString:@"https://example.com/home.json"], NO), @"remote: judged once downloaded");
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie(nil, YES));
    // [EN] The cache follows the file: a picture replaced by an animation is taken. [CN] 缓存跟随文件：图片被替换为动画后会被接收。
    NSURL *changing = write(@"changing.json", [@"{}" dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertFalse(CYLTabBarItemAnimationURLMayBeLottie(changing, NO));
    write(@"changing.json", lottie);
    XCTAssertTrue(CYLTabBarItemAnimationURLMayBeLottie(changing, NO));
    [[NSFileManager defaultManager] removeItemAtPath:folder error:NULL];
}

#pragma mark - Several engines: status, missing engines, conflicts

#if CYL_ANIMATION_ENGINE_AVAILABLE
/*!
 * [EN] Several engines in one registry: the integrator sees which are in, which known ones are missing (with the pod to
 *      add), and the conflicts; a change posts a notification. Uses its own registry, so the shared one is untouched.
 * [CN] 一个注册表中的多个引擎：接入方可以看到哪些已接入、哪些已知引擎缺少（以及需要加入的 pod）和冲突；变化时发送通知。使用独立的注册表，
 *      不影响共享注册表。
 */
- (void)testTheRegistryReportsEveryEngineAndTheMissingOnes {
    CYLTabBarItemAnimatorRegistry *registry = [[CYLTabBarItemAnimatorRegistry alloc] init];
    XCTAssertEqualObjects([registry registeredIdentifiers], @[]);
    XCTAssertEqualObjects([registry missingKnownIdentifiers], (@[ @"Lottie", @"PAG", @"Rive", @"SVGA", @"GIF" ]));

    XCTestExpectation *changed = [self expectationForNotification:CYLTabBarItemAnimatorRegistryDidChangeNotification object:registry handler:^BOOL(NSNotification *note) {
        return [note.userInfo[CYLTabBarItemAnimatorRegistryIdentifierKey] isEqualToString:@"PAG"];
    }];
    [registry registerAnimator:[CYLAnimatedItemStatusAnimator animatorWithIdentifier:@"PAG" extensions:@[ @"pag" ] priority:CYLTabBarItemAnimatorPriorityDefault]];
    [self waitForExpectations:@[ changed ] timeout:1];
    [registry registerAnimator:[CYLAnimatedItemStatusAnimator animatorWithIdentifier:@"Lottie" extensions:@[ @"json", @"lottie" ] priority:CYLTabBarItemAnimatorPriorityFallback]];
    [registry registerAnimator:[CYLAnimatedItemStatusAnimator animatorWithIdentifier:@"Rive" extensions:@[ @"riv" ] priority:CYLTabBarItemAnimatorPriorityDefault]];

    XCTAssertEqualObjects([registry registeredIdentifiers], (@[ @"PAG", @"Rive", @"Lottie" ]), @"lookup order: priority, then registration");
    XCTAssertTrue([registry isAnimatorRegisteredWithIdentifier:@"Rive"]);
    XCTAssertFalse([registry isAnimatorRegisteredWithIdentifier:@"SVGA"]);
    XCTAssertEqualObjects([registry missingKnownIdentifiers], (@[ @"SVGA", @"GIF" ]));
    XCTAssertEqualObjects([registry conflictDescriptions], @[]);

    NSString *report = [registry registrationReport];
    XCTAssertTrue([report containsString:@"3 registered"], @"%@", report);
    XCTAssertTrue([report containsString:@"✅ Rive"], @"%@", report);
    XCTAssertTrue([report containsString:@".json .lottie"], @"%@", report);
    XCTAssertTrue([report containsString:@"pod 'CYLAnimatedItem/SVGA'"], @"%@", report);
    XCTAssertFalse([report containsString:@"➖ PAG"], @"%@", report);

    [registry unregisterAnimatorWithIdentifier:@"Rive"];
    XCTAssertEqualObjects([registry missingKnownIdentifiers], (@[ @"Rive", @"SVGA", @"GIF" ]));
}

/*!
 * [EN] Two engines of the same priority that claim one extension are a conflict (the +load order decides, and it is not
 *      fixed); another priority settles it. [CN] 相同优先级的两个引擎声明同一扩展名即为冲突（由不固定的 +load 顺序决定）；不同优先级即可解决。
 */
- (void)testTwoEnginesClaimingOneExtensionAtOnePriorityAreAConflict {
    CYLTabBarItemAnimatorRegistry *registry = [[CYLTabBarItemAnimatorRegistry alloc] init];
    [registry registerAnimator:[CYLAnimatedItemStatusAnimator animatorWithIdentifier:@"GIF" extensions:@[ @"gif" ] priority:CYLTabBarItemAnimatorPriorityDefault]];
    [registry registerAnimator:[CYLAnimatedItemStatusAnimator animatorWithIdentifier:@"MyGIF" extensions:@[ @"GIF", @"webp" ] priority:CYLTabBarItemAnimatorPriorityDefault]];
    NSArray<NSString *> *conflicts = [registry conflictDescriptions];
    XCTAssertEqual(conflicts.count, 1u);
    XCTAssertTrue([conflicts.firstObject containsString:@"GIF and MyGIF both claim .gif"], @"%@", conflicts);
    XCTAssertTrue([[registry registrationReport] containsString:@"⚠️"]);

    [registry registerAnimator:[CYLAnimatedItemStatusAnimator animatorWithIdentifier:@"MyGIF" extensions:@[ @"gif" ] priority:10]];
    XCTAssertEqualObjects([registry conflictDescriptions], @[]);
    XCTAssertEqualObjects([[registry animatorForURL:[NSURL fileURLWithPath:@"/tmp/a.gif"]] identifier], @"MyGIF", @"the higher priority wins");
}
#endif

@end
