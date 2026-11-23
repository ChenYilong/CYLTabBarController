#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CYLTabBarController/CYLTabBarController.h>
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>
#endif

// [EN] Native unit tests of the Flutter iOS animation view (`CYLFlutterAnimationView`, FlutterCyltabbarPlugin.m): `selected`,
//      `playing`, the restart token and `drivesAnimationPlayback`, through the same method channel calls the Dart widget
//      sends. The animation library is replaced by a fake factory and player, so the tests count what the bridge asks the
//      player to do; they say nothing about what Lottie, PAG, SVGA or Rive draw (docs/Animated-Item.md).
// [CN] Flutter iOS 动画视图（`CYLFlutterAnimationView`，FlutterCyltabbarPlugin.m）的原生单元测试：`selected`、`playing`、重播 token
//      与 `drivesAnimationPlayback`，通过 Dart 组件发送的同样的 method channel 调用。动画库由假工厂与假播放器代替，因此测试统计的是桥接
//      要求播放器做了什么，不涉及 Lottie、PAG、SVGA、Rive 实际绘制什么（见 docs/Animated-Item.md）。

#pragma mark - Fakes 假对象

/// [EN] A player that counts what it is asked. [CN] 统计被要求做了什么的播放器。
@interface CYLFakeBridgePlayer : NSObject <CYLTabBarItemAnimationPlayer>
@property (nonatomic, weak, readwrite, nullable) UIView *animationView;
@property (nonatomic, assign) NSInteger playCount;
@property (nonatomic, assign) NSInteger stopCount;
@property (nonatomic, assign) NSInteger speedSetCount;
@property (nonatomic, assign) NSInteger loopsSetCount;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat animationSpeed;
@property (nonatomic, assign) BOOL loops;
@property (nonatomic, assign, getter=isPlaying) BOOL playing;
@property (nonatomic, copy, nullable) void (^onEnded)(void);
@end

@implementation CYLFakeBridgePlayer
- (void)play { self.playCount += 1; self.playing = YES; }
- (void)showLastFrame {}
- (void)stop { self.stopCount += 1; self.playing = NO; }
- (void)setAnimationSpeed:(CGFloat)animationSpeed { _animationSpeed = animationSpeed; self.speedSetCount += 1; }
- (void)setLoops:(BOOL)loops { _loops = loops; self.loopsSetCount += 1; }
@end

/// [EN] Makes one view and one player for any URL. [CN] 为任意 URL 创建一个视图与一个播放器。
@interface CYLFakeBridgeFactory : NSObject <CYLTabBarItemAnimationViewMaking>
@property (nonatomic, strong, nullable) CYLFakeBridgePlayer *player;
@property (nonatomic, strong, nullable) UIView *view;
@end

@implementation CYLFakeBridgeFactory
- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.player = [[CYLFakeBridgePlayer alloc] init];
    self.player.animationView = self.view;
    return self.view;
}
- (id<CYLTabBarItemAnimationPlayer>)playerForView:(UIView *)view {
    return view == self.view ? self.player : nil;
}
- (BOOL)isAnimationView:(UIView *)view {
    return view != nil && view == self.view;
}
@end

/// [EN] A messenger that records the method names the native view calls on the Dart side. [CN] 记录原生视图调用 Dart 端的方法名的 messenger。
@interface CYLFakeMessenger : NSObject <FlutterBinaryMessenger>
@property (nonatomic, strong) NSMutableArray<NSString *> *sentMethods;
@end

@implementation CYLFakeMessenger
- (instancetype)init {
    if (self = [super init]) {
        _sentMethods = [NSMutableArray array];
    }
    return self;
}
- (void)sendOnChannel:(NSString *)channel message:(NSData *)message {
    FlutterMethodCall *call = [[FlutterStandardMethodCodec sharedInstance] decodeMethodCall:message];
    [self.sentMethods addObject:call.method];
}
- (void)sendOnChannel:(NSString *)channel message:(NSData *)message binaryReply:(FlutterBinaryReply)callback {
    [self sendOnChannel:channel message:message];
}
- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString *)channel binaryMessageHandler:(FlutterBinaryMessageHandler)handler {
    return 1;
}
- (void)cleanUpConnection:(FlutterBinaryMessengerConnection)connection {}
@end

/// [EN] Only `messenger` is read from the registrar by the animation view. [CN] 动画视图只读取 registrar 的 `messenger`。
@interface CYLFakeRegistrar : NSObject
@property (nonatomic, strong) CYLFakeMessenger *fakeMessenger;
@end

@implementation CYLFakeRegistrar
- (instancetype)init {
    if (self = [super init]) {
        _fakeMessenger = [[CYLFakeMessenger alloc] init];
    }
    return self;
}
- (NSObject<FlutterBinaryMessenger> *)messenger { return self.fakeMessenger; }
@end

/// [EN] The private class under test, called by selector only. [CN] 被测试的私有类，仅按选择器调用。
@protocol CYLFlutterAnimationViewUnderTest <NSObject>
- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId arguments:(NSDictionary *)arguments registrar:(id)registrar;
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result;
- (UIView *)view;
@end

#pragma mark - Tests 测试

@interface FlutterAnimationViewTests : XCTestCase
@end

@implementation FlutterAnimationViewTests {
    id<CYLFlutterAnimationViewUnderTest> _bridge;
    CYLFakeRegistrar *_registrar;
    CYLFakeBridgeFactory *_factory;
    NSObject *_item;
}

- (void)setUp {
    _factory = [[CYLFakeBridgeFactory alloc] init];
}

/// [EN] A bridge made with `arguments`, the fake factory in place, without a source yet. [CN] 用 `arguments` 创建桥接，已换上假工厂，尚无 source。
- (void)makeBridgeWithArguments:(NSDictionary *)arguments {
    Class bridgeClass = NSClassFromString(@"CYLFlutterAnimationView");
    XCTAssertNotNil(bridgeClass, @"CYLFlutterAnimationView is linked into the host app only when CYLAnimatedItem is in the build");
    _registrar = [[CYLFakeRegistrar alloc] init];
    _bridge = [(id<CYLFlutterAnimationViewUnderTest>)[bridgeClass alloc] initWithFrame:CGRectMake(0, 0, 40, 40) viewId:7 arguments:arguments registrar:_registrar];
    _item = [(NSObject *)_bridge valueForKey:@"_item"];
    XCTAssertNotNil(_item);
    [_item setValue:_factory forKey:@"animationSource"];
}

- (void)callMethod:(NSString *)method argument:(id)argument {
    XCTestExpectation *answered = [self expectationWithDescription:method];
    [_bridge handleMethodCall:[FlutterMethodCall methodCallWithMethodName:method arguments:argument]
                       result:^(id result) { XCTAssertNil(result, @"%@", method); [answered fulfill]; }];
    [self waitForExpectations:@[ answered ] timeout:1];
}

/// [EN] Sets the source and waits for the main queue turn that reports `onAnimationLoaded`. [CN] 设置 source，并等待报告 `onAnimationLoaded` 的主队列循环。
- (void)loadSource {
    [self callMethod:@"setSource" argument:@"https://example.com/icon.fake"];
    XCTAssertNotNil(_factory.player, @"the item asked the factory for the animation");
    [self spinMainQueue];
}

- (void)spinMainQueue {
    XCTestExpectation *turn = [self expectationWithDescription:@"main queue turn"];
    dispatch_async(dispatch_get_main_queue(), ^{ [turn fulfill]; });
    [self waitForExpectations:@[ turn ] timeout:1];
}

- (NSInteger)restartToken {
    return [[_item valueForKey:@"animationRestartToken"] integerValue];
}

- (void)testItemReportsLoadedThroughTheChannel {
    [self makeBridgeWithArguments:@{}];
    [self loadSource];
    XCTAssertTrue([_registrar.fakeMessenger.sentMethods containsObject:@"onAnimationLoaded"]);
}

- (void)testSelectedPlaysAndUnselectedRestsWhenTheBridgeDrivesPlayback {
    [self makeBridgeWithArguments:@{}];
    XCTAssertEqualObjects([_item valueForKey:@"drivesAnimationPlayback"], @YES, @"the default is true");
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    XCTAssertEqual(player.playCount, 0, @"unselected: nothing plays");
    [self callMethod:@"setSelected" argument:@YES];
    XCTAssertEqualObjects([_item valueForKey:@"selected"], @YES);
    XCTAssertEqual(player.playCount, 1);
    XCTAssertTrue(player.isPlaying);
    [self callMethod:@"setSelected" argument:@NO];
    XCTAssertEqualObjects([_item valueForKey:@"selected"], @NO);
    XCTAssertFalse(player.isPlaying, @"unselected stops");
    XCTAssertEqualWithAccuracy(player.progress, 0, 0.0001, @"and rests at the resting progress");
}

- (void)testASelectedItemThatBecomesReadyPlays {
    [self makeBridgeWithArguments:@{ @"selected" : @YES }];
    [self loadSource];
    XCTAssertEqual(_factory.player.playCount, 1, @"selected at creation, played once the animation is in place");
}

- (void)testPlayingDrivesThePlayerAndBlocksTheSelectionRule {
    [self makeBridgeWithArguments:@{}];
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    // [EN] Loading an unselected item already rested it once (the selection rule), so count from here.
    // [CN] 加载未选中的条目时已让它静止过一次（选中规则），因此从这里开始计数。
    const NSInteger stopsAtStart = player.stopCount;
    [self callMethod:@"setPlaying" argument:@YES];
    XCTAssertEqual(player.playCount, 1);
    XCTAssertEqualObjects([_item valueForKey:@"selected"], @NO);
    [self callMethod:@"setSelected" argument:@NO];
    XCTAssertEqual(player.stopCount, stopsAtStart, @"playing true: the selection rule does not stop it");
    [self callMethod:@"setSelected" argument:@YES];
    XCTAssertEqual(player.playCount, 1, @"nor play it again");
    [self callMethod:@"setPlaying" argument:@NO];
    XCTAssertEqual(player.stopCount, stopsAtStart + 1);
    XCTAssertFalse(player.isPlaying);
}

- (void)testTheRestartTokenAtCreationIsNotARestart {
    [self makeBridgeWithArguments:@{ @"animationRestartToken" : @5 }];
    [self loadSource];
    XCTAssertEqual([self restartToken], 0);
    XCTAssertEqual(_factory.player.playCount, 0);
    [self callMethod:@"setAnimationRestartToken" argument:@5];
    XCTAssertEqual([self restartToken], 0, @"the same token again is not a restart");
}

- (void)testAChangedRestartTokenRestartsExactlyOnce {
    [self makeBridgeWithArguments:@{ @"animationRestartToken" : @5 }];
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    [self callMethod:@"setAnimationRestartToken" argument:@6];
    XCTAssertEqual([self restartToken], 1);
    XCTAssertEqual(player.playCount, 1);
    XCTAssertEqualWithAccuracy(player.progress, 0, 0.0001, @"a restart plays from progress 0");
    [self callMethod:@"setAnimationRestartToken" argument:@6];
    XCTAssertEqual([self restartToken], 1);
    XCTAssertEqual(player.playCount, 1);
    [self callMethod:@"setAnimationRestartToken" argument:@7];
    XCTAssertEqual([self restartToken], 2);
    XCTAssertEqual(player.playCount, 2);
}

- (void)testSpeedAndLoopsReachThePlayerOnlyWhenTheBridgeDrivesPlayback {
    [self makeBridgeWithArguments:@{}];
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    [self callMethod:@"setAnimationSpeed" argument:@2];
    [self callMethod:@"setAnimationLoops" argument:@YES];
    XCTAssertEqualWithAccuracy(player.animationSpeed, 2, 0.0001);
    XCTAssertTrue(player.loops);
    [self callMethod:@"setDrivesAnimationPlayback" argument:@NO];
    NSInteger speedSets = player.speedSetCount;
    NSInteger loopsSets = player.loopsSetCount;
    [self callMethod:@"setAnimationSpeed" argument:@3];
    [self callMethod:@"setAnimationLoops" argument:@NO];
    XCTAssertEqual(player.speedSetCount, speedSets, @"host-driven: the speed is not pushed");
    XCTAssertEqual(player.loopsSetCount, loopsSets, @"host-driven: the loops are not pushed");
    XCTAssertEqualWithAccuracy(player.animationSpeed, 2, 0.0001);
    XCTAssertTrue(player.loops);
}

- (void)testHostDrivenSelectionDoesNotPlayButPlayingAndRestartStillDo {
    [self makeBridgeWithArguments:@{ @"drivesAnimationPlayback" : @NO, @"selected" : @YES }];
    XCTAssertEqualObjects([_item valueForKey:@"drivesAnimationPlayback"], @NO);
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    XCTAssertEqual(player.playCount, 0, @"host-driven: a selected item that becomes ready does not play");
    [self callMethod:@"setSelected" argument:@NO];
    [self callMethod:@"setSelected" argument:@YES];
    XCTAssertEqual(player.playCount, 0, @"host-driven: selection does not play");
    XCTAssertEqual(player.stopCount, 0, @"nor stop");
    [self callMethod:@"setPlaying" argument:@YES];
    XCTAssertEqual(player.playCount, 1, @"playing still plays on the host's request");
    [self callMethod:@"setPlaying" argument:@NO];
    XCTAssertEqual(player.stopCount, 1);
    [self callMethod:@"play" argument:nil];
    XCTAssertEqual(player.playCount, 2, @"the play command reaches the player");
    [self callMethod:@"setAnimationRestartToken" argument:@1];
    XCTAssertEqual(player.playCount, 3, @"a restart still plays");
    XCTAssertEqual([self restartToken], 1);
}

- (void)testSwitchingBackToTheBridgeAppliesTheSelectionRuleAgain {
    [self makeBridgeWithArguments:@{ @"drivesAnimationPlayback" : @NO }];
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    [self callMethod:@"setSelected" argument:@YES];
    XCTAssertEqual(player.playCount, 0);
    [self callMethod:@"setDrivesAnimationPlayback" argument:@YES];
    [self callMethod:@"setSelected" argument:@NO];
    [self callMethod:@"setSelected" argument:@YES];
    XCTAssertEqual(player.playCount, 1);
}

- (void)testThePlayCommandAndStopAtProgressReachThePlayer {
    [self makeBridgeWithArguments:@{ @"drivesAnimationPlayback" : @NO }];
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    [self callMethod:@"play" argument:nil];
    XCTAssertEqual(player.playCount, 1);
    [self callMethod:@"stopAtProgress" argument:@0.5];
    XCTAssertEqual(player.stopCount, 1);
    XCTAssertEqualWithAccuracy(player.progress, 0.5, 0.0001);
}

- (void)testTheEndOfAPlayOncePassIsForwardedEvenWhenHostDriven {
    [self makeBridgeWithArguments:@{ @"drivesAnimationPlayback" : @NO }];
    [self loadSource];
    CYLFakeBridgePlayer *player = _factory.player;
    XCTAssertNotNil(player.onEnded, @"the item owns the player's end callback");
    [self callMethod:@"setPlaying" argument:@YES];
    player.onEnded();
    [self spinMainQueue];
    XCTAssertTrue([_registrar.fakeMessenger.sentMethods containsObject:@"onAnimationEnd"]);
}

@end
