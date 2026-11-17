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
    [delete sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqualObjects(self.events, (@[ @"accessory" ]));
    UIAccessibilityCustomAction *action = item.accessibilityCustomActions.lastObject;
    XCTAssertEqualObjects(action.name, @"Delete");
    [item sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertEqualObjects(self.events.lastObject, @"tap");
    item.dragEnabled = YES;
    XCTAssertTrue(item.panGestureRecognizer.enabled);
}

#pragma mark - CYLAnimatedItemViewDelegate

- (void)animatedItemViewDidTap:(CYLAnimatedItemView *)itemView {
    [self.events addObject:@"tap"];
}

- (void)animatedItemViewDidTapAccessory:(CYLAnimatedItemView *)itemView {
    [self.events addObject:@"accessory"];
}

@end
