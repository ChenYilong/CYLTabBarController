#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CYLTabBarController/CYLTabBarController.h>
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>
#endif

#import <React/RCTViewComponentView.h>
#import <react/renderer/components/CyltabbarViewSpec/Props.h>

using namespace facebook::react;

// [EN] Native unit tests of the React Native iOS animation view (`CyltabbarAnimationView`, CyltabbarAnimationView.mm):
//      `selected`, `playing`, the restart token and `drivesAnimationPlayback`, through the props Fabric hands to
//      `updateProps:oldProps:` and the commands. The animation library is replaced by a fake factory and player, so the
//      tests count what the bridge asks the player to do; they say nothing about what Lottie, PAG, SVGA or Rive draw
//      (docs/Animated-Item.md).
// [CN] React Native iOS 动画视图（`CyltabbarAnimationView`，CyltabbarAnimationView.mm）的原生单元测试：`selected`、`playing`、重播 token
//      与 `drivesAnimationPlayback`，通过 Fabric 交给 `updateProps:oldProps:` 的属性与命令。动画库由假工厂与假播放器代替，因此测试统计的是
//      桥接要求播放器做了什么，不涉及 Lottie、PAG、SVGA、Rive 实际绘制什么（见 docs/Animated-Item.md）。

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

#pragma mark - Tests 测试

@interface CyltabbarAnimationViewTests : XCTestCase
@end

@implementation CyltabbarAnimationViewTests {
  RCTViewComponentView *_bridge;
  CYLFakeBridgeFactory *_factory;
  NSObject *_item;
  std::shared_ptr<const CyltabbarAnimationViewProps> _props;
}

- (void)setUp {
  _factory = [[CYLFakeBridgeFactory alloc] init];
  Class bridgeClass = NSClassFromString(@"CyltabbarAnimationView");
  XCTAssertNotNil(bridgeClass, @"CyltabbarAnimationView is linked into the host app");
  _bridge = [[bridgeClass alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
  _item = [_bridge valueForKey:@"_item"];
  XCTAssertNotNil(_item, @"the view has an item only when CYLAnimatedItem is in the build");
  [_item setValue:_factory forKey:@"animationSource"];
  _props = std::make_shared<const CyltabbarAnimationViewProps>();
}

/// [EN] Hands a changed copy of the current props to the view, as Fabric does. [CN] 像 Fabric 一样把修改后的属性副本交给视图。
- (void)update:(void (^)(CyltabbarAnimationViewProps &props))change {
  auto next = std::make_shared<CyltabbarAnimationViewProps>(*_props);
  change(*next);
  auto old = _props;
  _props = next;
  [_bridge updateProps:next oldProps:old];
}

/// [EN] Sets the source and waits for the main queue turn that reports `onAnimationLoaded`. [CN] 设置 source，并等待报告 `onAnimationLoaded` 的主队列循环。
- (void)loadSource {
  [self update:^(CyltabbarAnimationViewProps &props) { props.source = "https://example.com/icon.fake"; }];
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

- (void)testDefaultPropsDriveThePlaybackAndStartUnselected {
  CyltabbarAnimationViewProps defaults;
  XCTAssertTrue(defaults.drivesAnimationPlayback, @"the codegen default of drivesAnimationPlayback is true");
  XCTAssertFalse(defaults.selected);
  XCTAssertFalse(defaults.playing);
  XCTAssertEqual(defaults.animationRestartToken, 0);
}

- (void)testSelectedPlaysAndUnselectedRestsWhenTheBridgeDrivesPlayback {
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  XCTAssertEqualObjects([_item valueForKey:@"drivesAnimationPlayback"], @YES);
  XCTAssertEqual(player.playCount, 0, @"unselected: nothing plays");
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  XCTAssertEqualObjects([_item valueForKey:@"selected"], @YES);
  XCTAssertEqual(player.playCount, 1);
  XCTAssertTrue(player.isPlaying);
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = false; }];
  XCTAssertEqualObjects([_item valueForKey:@"selected"], @NO);
  XCTAssertFalse(player.isPlaying, @"unselected stops");
  XCTAssertEqualWithAccuracy(player.progress, 0, 0.0001, @"and rests at the resting progress");
}

- (void)testASelectedItemThatBecomesReadyPlays {
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  [self loadSource];
  XCTAssertEqual(_factory.player.playCount, 1, @"selected before the animation is in place, played once it is");
}

- (void)testUnrelatedPropChangesDoNotReplayASelectedItem {
  [self loadSource];
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationSpeed = 1.5; }];
  XCTAssertEqual(_factory.player.playCount, 1, @"only a change of selected applies the selection rule");
}

- (void)testPlayingDrivesThePlayerAndBlocksTheSelectionRule {
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  // [EN] Loading an unselected item already rested it once (the selection rule), so count from here.
  // [CN] 加载未选中的条目时已让它静止过一次（选中规则），因此从这里开始计数。
  const NSInteger stopsAtStart = player.stopCount;
  [self update:^(CyltabbarAnimationViewProps &props) { props.playing = true; }];
  XCTAssertEqual(player.playCount, 1);
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  XCTAssertEqual(player.playCount, 1, @"playing true: the selection rule does not play it again");
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = false; }];
  XCTAssertEqual(player.stopCount, stopsAtStart, @"nor stop it");
  [self update:^(CyltabbarAnimationViewProps &props) { props.playing = false; }];
  XCTAssertEqual(player.stopCount, stopsAtStart + 1);
  XCTAssertFalse(player.isPlaying);
}

- (void)testSelectedAndPlayingInOneUpdateEndPlaying {
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = false; props.playing = true; }];
  XCTAssertTrue(player.isPlaying, @"playing wins over the unselected rest");
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; props.playing = false; }];
  XCTAssertFalse(player.isPlaying, @"playing false stops, whatever the selection");
}

- (void)testTheRestartTokenAtCreationIsNotARestart {
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 5; }];
  [self loadSource];
  XCTAssertEqual([self restartToken], 0, @"the first token the view sees is its creation value");
  XCTAssertEqual(_factory.player.playCount, 0);
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 5; props.iconSize = 20; }];
  XCTAssertEqual([self restartToken], 0, @"the same token again is not a restart");
}

- (void)testAChangedRestartTokenRestartsExactlyOnce {
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 5; }];
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 6; }];
  XCTAssertEqual([self restartToken], 1);
  XCTAssertEqual(player.playCount, 1);
  XCTAssertEqualWithAccuracy(player.progress, 0, 0.0001, @"a restart plays from progress 0");
  // [EN] Not iconSize: a new icon size reloads the animation, a new player. [CN] 不用 iconSize：新的图标尺寸会重新加载动画，即新的播放器。
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 6; props.animationSpeed = 1.5; }];
  XCTAssertEqual([self restartToken], 1, @"a prop change that keeps the token is not a restart");
  XCTAssertEqual(player.playCount, 1);
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 7; }];
  XCTAssertEqual([self restartToken], 2);
  XCTAssertEqual(player.playCount, 2);
}

- (void)testSpeedAndLoopsReachThePlayerOnlyWhenTheBridgeDrivesPlayback {
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationSpeed = 2; props.animationLoops = true; }];
  XCTAssertEqualWithAccuracy(player.animationSpeed, 2, 0.0001);
  XCTAssertTrue(player.loops);
  [self update:^(CyltabbarAnimationViewProps &props) { props.drivesAnimationPlayback = false; }];
  NSInteger speedSets = player.speedSetCount;
  NSInteger loopsSets = player.loopsSetCount;
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationSpeed = 3; props.animationLoops = false; }];
  XCTAssertEqual(player.speedSetCount, speedSets, @"host-driven: the speed is not pushed");
  XCTAssertEqual(player.loopsSetCount, loopsSets, @"host-driven: the loops are not pushed");
  XCTAssertEqualWithAccuracy(player.animationSpeed, 2, 0.0001);
  XCTAssertTrue(player.loops);
}

- (void)testHostDrivenSelectionDoesNotPlayButPlayingRestartAndCommandsStillDo {
  [self update:^(CyltabbarAnimationViewProps &props) { props.drivesAnimationPlayback = false; props.selected = true; }];
  XCTAssertEqualObjects([_item valueForKey:@"drivesAnimationPlayback"], @NO);
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  XCTAssertEqual(player.playCount, 0, @"host-driven: a selected item that becomes ready does not play");
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = false; }];
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  XCTAssertEqual(player.playCount, 0, @"host-driven: selection does not play");
  XCTAssertEqual(player.stopCount, 0, @"nor stop");
  [self update:^(CyltabbarAnimationViewProps &props) { props.playing = true; }];
  XCTAssertEqual(player.playCount, 1, @"playing still plays on the host's request");
  [self update:^(CyltabbarAnimationViewProps &props) { props.playing = false; }];
  XCTAssertEqual(player.stopCount, 1);
  [_bridge handleCommand:@"play" args:@[]];
  XCTAssertEqual(player.playCount, 2, @"the play command reaches the player");
  [_bridge handleCommand:@"stopAtProgress" args:@[ @0.5 ]];
  XCTAssertEqual(player.stopCount, 2);
  XCTAssertEqualWithAccuracy(player.progress, 0.5, 0.0001);
  [_bridge handleCommand:@"restart" args:@[]];
  XCTAssertEqual(player.playCount, 3, @"the restart command plays");
  XCTAssertEqual([self restartToken], 1);
  [self update:^(CyltabbarAnimationViewProps &props) { props.animationRestartToken = 1; }];
  XCTAssertEqual(player.playCount, 4, @"a restart token change still plays");
  XCTAssertEqual([self restartToken], 2);
}

- (void)testSwitchingBackToTheBridgeAppliesTheSelectionRuleAgain {
  [self update:^(CyltabbarAnimationViewProps &props) { props.drivesAnimationPlayback = false; }];
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  XCTAssertEqual(player.playCount, 0);
  [self update:^(CyltabbarAnimationViewProps &props) { props.drivesAnimationPlayback = true; props.selected = false; }];
  [self update:^(CyltabbarAnimationViewProps &props) { props.selected = true; }];
  XCTAssertEqual(player.playCount, 1);
}

- (void)testTheEndOfAPlayOncePassIsKeptEvenWhenHostDriven {
  [self update:^(CyltabbarAnimationViewProps &props) { props.drivesAnimationPlayback = false; }];
  [self loadSource];
  CYLFakeBridgePlayer *player = _factory.player;
  XCTAssertNotNil(player.onEnded, @"the item owns the player's end callback");
}

@end
