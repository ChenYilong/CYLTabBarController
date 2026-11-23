#import "CyltabbarAnimationView.h"

// [EN] Objective-C++ has no `@import`, so the generated Swift header of CYLAnimatedItem cannot import SVGAPlayerLite itself: its
//      `SVGAPlayer` class must be declared first (the SVGA subspec only).
// [CN] Objective-C++ 没有 `@import`，CYLAnimatedItem 生成的 Swift 头文件无法自行导入 SVGAPlayerLite：必须先声明 `SVGAPlayer` 类（仅 SVGA 子库）。
#if __has_include(<SVGAPlayerLite/SVGAPlayer.h>)
#import <SVGAPlayerLite/SVGAPlayer.h>
#endif

#import <CYLTabBarController/CYLTabBarController.h>
// [EN] The animation view is a `CYLAnimatedItemView` (the cross-platform engine API, docs/Animated-Item.md, "Engine API across
//      platforms"), in the CYLAnimatedItem pod that comes with CYLTabBarController; its generated Swift header declares it
//      (docs/Swift-Migration.md). Without the pod the view stays empty.
// [CN] 动画视图是 `CYLAnimatedItemView`（跨端引擎 API，见 docs/Animated-Item.md「跨端引擎 API」），位于随 CYLTabBarController 提供的
//      CYLAnimatedItem pod 中，由其生成的 Swift 头文件声明（docs/Swift-Migration.md）。没有该 pod 时视图保持为空。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#define CYL_RN_ANIMATION_AVAILABLE 1
#elif __has_include("CYLAnimatedItem-Swift.h")
#import "CYLAnimatedItem-Swift.h"
#define CYL_RN_ANIMATION_AVAILABLE 1
#else
#define CYL_RN_ANIMATION_AVAILABLE 0
#endif
#if CYL_RN_ANIMATION_AVAILABLE && __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>
#endif

#import <React/RCTConversions.h>
#import <react/renderer/components/CyltabbarViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/CyltabbarViewSpec/EventEmitters.h>
#import <react/renderer/components/CyltabbarViewSpec/Props.h>
#import <react/renderer/components/CyltabbarViewSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

/**
 * [EN] An animation played by CYLTabBarController's engine through a `CYLAnimatedItemView`, the same contract as the Android
 *      view (`CyltabbarAnimationView.kt`): the props `source`, `playing`, `selected`, `animationSpeed`, `animationLoops`,
 *      `animationRestartToken`, `drivesAnimationPlayback`, `iconSize`, `tintColor`; the events `onAnimationLoaded`,
 *      `onAnimationFailed`, `onAnimationEnd`; the commands `play`, `stopAtProgress`, `restart`. No engine logic here. The
 *      restart token is read-only on iOS (`animationRestartToken` grows on every `restartAnimation()`), so a changed token calls
 *      `restartAnimation()`; the token the view is created with is not a restart.
 * [CN] 由 CYLTabBarController 引擎通过 `CYLAnimatedItemView` 播放的动画，契约与 Android 视图相同（`CyltabbarAnimationView.kt`）：
 *      属性 `source`、`playing`、`selected`、`animationSpeed`、`animationLoops`、`animationRestartToken`、`drivesAnimationPlayback`、
 *      `iconSize`、`tintColor`；事件 `onAnimationLoaded`、`onAnimationFailed`、`onAnimationEnd`；命令 `play`、`stopAtProgress`、`restart`。
 *      这里没有引擎逻辑。重播 token 在 iOS 上只读（每次 `restartAnimation()` 后 `animationRestartToken` 加一），因此 token 变化时调用
 *      `restartAnimation()`；创建视图时的 token 不算重播。
 */
@interface CyltabbarAnimationView () <RCTCyltabbarAnimationViewViewProtocol>
@end

@implementation CyltabbarAnimationView {
  NSString *_source;
  BOOL _playing;
#if CYL_RN_ANIMATION_AVAILABLE
  CYLAnimatedItemView *_item;
  BOOL _hasRestartToken;
  BOOL _selected;
  NSInteger _restartToken;
  CGFloat _iconSide;
#endif
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<CyltabbarAnimationViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const CyltabbarAnimationViewProps>();
    _props = defaultProps;
#if CYL_RN_ANIMATION_AVAILABLE
    [self setUpItem];
#endif
  }
  return self;
}

#if CYL_RN_ANIMATION_AVAILABLE
/// [EN] A file name of the main bundle becomes its file URL, the options (the fragment) kept.
/// [CN] 主 bundle 中的文件名转为其文件 URL，保留选项（fragment）。
static NSURL *CYLRNAnimationURL(NSString *source)
{
  NSURL *URL = [NSURL URLWithString:source];
  if (URL.scheme.length > 1) {
    return URL;
  }
  NSRange hash = [source rangeOfString:@"#"];
  NSString *file = hash.location == NSNotFound ? source : [source substringToIndex:hash.location];
  NSString *fragment = hash.location == NSNotFound ? nil : [source substringFromIndex:hash.location + 1];
  NSString *path = file.isAbsolutePath ? file : [[NSBundle mainBundle] pathForResource:file ofType:nil];
  if (!path) {
    return nil;
  }
  NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL fileURLWithPath:path] resolvingAgainstBaseURL:NO];
  components.percentEncodedFragment = fragment;
  return components.URL;
}

- (void)setUpItem
{
  __weak __typeof(self) weakSelf = self;
  _item = [[CYLAnimatedItemView alloc] initWithFrame:self.bounds];
  // [EN] Icon only; the view the host gives is the icon's frame. [CN] 只有图标；宿主给的视图就是图标的范围。
  _item.onAnimationEnd = ^{ [weakSelf emit:@"end"]; };
  _item.onAnimationLoaded = ^{
    // [EN] A selected item that becomes ready plays, as on Android. [CN] 就绪的选中条目开始播放，与 Android 一致。
    [weakSelf followSelection];
    [weakSelf emit:@"loaded"];
  };
  _item.onAnimationFailed = ^{ [weakSelf emit:@"failed"]; };
  [self addSubview:_item];
}

/// [EN] `loaded`, `failed` or `end`, sent as `onAnimationLoaded`, `onAnimationFailed` or `onAnimationEnd`. [CN] 发送对应的事件。
- (void)emit:(NSString *)name
{
  if (!_eventEmitter) {
    return;
  }
  auto emitter = std::static_pointer_cast<CyltabbarAnimationViewEventEmitter const>(_eventEmitter);
  if ([name isEqualToString:@"loaded"]) {
    emitter->onAnimationLoaded(CyltabbarAnimationViewEventEmitter::OnAnimationLoaded{});
  } else if ([name isEqualToString:@"failed"]) {
    emitter->onAnimationFailed(CyltabbarAnimationViewEventEmitter::OnAnimationFailed{});
  } else {
    emitter->onAnimationEnd(CyltabbarAnimationViewEventEmitter::OnAnimationEnd{});
  }
}

/// [EN] The icon fills the view, or is `iconSize` (points) when given. [CN] 图标铺满视图，给了 `iconSize`（点）时为该尺寸。
- (void)fitIcon
{
  CGSize size = _iconSide > 0 ? CGSizeMake(_iconSide, _iconSide) : self.bounds.size;
  if (size.width > 0 && size.height > 0 && !CGSizeEqualToSize(_item.iconSize, size)) {
    _item.iconSize = size;
  }
}

/// [EN] The default rule of the bridge (`drivesAnimationPlayback` true): selected plays from the resting frame, unselected
///      stops at the resting progress. `CYLAnimatedItemView` itself never plays on selection on iOS (the tab engine does).
/// [CN] 桥接的默认规则（`drivesAnimationPlayback` 为 true）：选中从静止帧开始播放，未选中停在静止进度。iOS 上 `CYLAnimatedItemView` 自身
///      不会因选中而播放（由 Tab 引擎播放）。
- (void)followSelection
{
  if (!_item.drivesAnimationPlayback || _playing) {
    return;
  }
  if (_selected) {
    [_item playAnimation];
  } else {
    [_item stopAnimation];
  }
}

/// [EN] The player of the current animation, nil until it is in place. [CN] 当前动画的播放器，就绪前为 nil。
- (id<CYLTabBarItemAnimationPlayer>)player
{
  return _item.animationPlayer;
}
#endif

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
#if CYL_RN_ANIMATION_AVAILABLE
  const auto &newProps = *std::static_pointer_cast<CyltabbarAnimationViewProps const>(props);
  _item.drivesAnimationPlayback = newProps.drivesAnimationPlayback;
  _item.animationSpeed = newProps.animationSpeed;
  _item.animationLoops = newProps.animationLoops;
  _iconSide = newProps.iconSize;
  [self fitIcon];
  [_item applyIconTintColor:RCTUIColorFromSharedColor(newProps.tintColor)];
  _item.selected = newProps.selected;
  const BOOL selectionChanged = newProps.selected != _selected;
  _selected = newProps.selected;
  if (_hasRestartToken && newProps.animationRestartToken != _restartToken) {
    [_item restartAnimation];
  }
  _hasRestartToken = YES;
  _restartToken = newProps.animationRestartToken;
  NSString *source = [NSString stringWithUTF8String:newProps.source.c_str()];
  if (![source isEqualToString:_source ?: @""]) {
    _source = source;
    _item.animationURL = source.length > 0 ? CYLRNAnimationURL(source) : nil;
  }
  if (selectionChanged) {
    [self followSelection];
  }
  if (newProps.playing != _playing) {
    _playing = newProps.playing;
    if (_playing) {
      [_item playAnimation];
    } else {
      [_item stopAnimation];
    }
  }
#endif
  [super updateProps:props oldProps:oldProps];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
#if CYL_RN_ANIMATION_AVAILABLE
  _item.frame = self.bounds;
  [self fitIcon];
#endif
}

#pragma mark - Commands 命令

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args
{
  RCTCyltabbarAnimationViewHandleCommand(self, commandName, args);
}

- (void)play
{
#if CYL_RN_ANIMATION_AVAILABLE
  [[self player] play];
#endif
}

- (void)stopAtProgress:(float)progress
{
#if CYL_RN_ANIMATION_AVAILABLE
  id<CYLTabBarItemAnimationPlayer> player = [self player];
  [player stop];
  if ([player respondsToSelector:@selector(setProgress:)]) {
    player.progress = progress;
  }
#endif
}

- (void)restart
{
#if CYL_RN_ANIMATION_AVAILABLE
  [_item restartAnimation];
#endif
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
#if CYL_RN_ANIMATION_AVAILABLE
  _item.animationURL = nil;
  _hasRestartToken = NO;
  _selected = NO;
#endif
  _source = nil;
  _playing = NO;
}

@end
