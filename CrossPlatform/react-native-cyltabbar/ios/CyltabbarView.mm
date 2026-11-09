#import "CyltabbarView.h"

#import <CYLTabBarController/CYLTabBarController.h>

#import <react/renderer/components/CyltabbarViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/CyltabbarViewSpec/EventEmitters.h>
#import <react/renderer/components/CyltabbarViewSpec/Props.h>
#import <react/renderer/components/CyltabbarViewSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

static id CYLRNJSONObject(NSString *JSON);

@implementation CyltabbarView {
  CYLTabBarHostView *_hostView;
  NSString *_configurationJSON;
  NSString *_badgeStylesJSON;
  NSString *_plusButtonBadgeStyleJSON;
  /// [EN] The last memory warning request handled. [CN] 最近处理的内存警告请求。
  int _memoryWarningRequest;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<CyltabbarViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const CyltabbarViewProps>();
    _props = defaultProps;
    _hostView = [[CYLTabBarHostView alloc] initWithFrame:self.bounds];
    __weak __typeof(self) weakSelf = self;
    _hostView.didSelectTab = ^(NSInteger index, NSString *identifier) {
      [weakSelf emitTabSelectAtIndex:index identifier:identifier];
    };
    _hostView.didTapPlusButton = ^{
      [weakSelf emitPlusButtonPress];
    };
    _hostView.preferredHeightDidChange = ^(CGFloat height) {
      [weakSelf emitTabBarLayoutWithHeight:height];
    };
    _hostView.didLongPressTab = ^(NSInteger index, NSString *identifier, NSString *title) {
      [weakSelf emitTabLongPressAtIndex:index identifier:identifier title:title];
    };
    _hostView.didRequestLogin = ^(NSInteger index, NSString *identifier, NSString *title) {
      [weakSelf emitLoginRequestAtIndex:index identifier:identifier title:title];
    };
    _hostView.loginStateDidChange = ^(BOOL loggedIn) {
      [weakSelf emitLoginStateChange:loggedIn];
    };
    // React Native does not clip: the plus button may rise above the bar. React Native 不裁剪：PlusButton 可以高出 TabBar。
    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &newViewProps = *std::static_pointer_cast<CyltabbarViewProps const>(props);
  // [EN] Before the configuration: a new language would build that configuration's tab bar again.
  // [CN] 在配置之前：否则新的语言会把该配置的 TabBar 再创建一次。
  NSString *language = [NSString stringWithUTF8String:newViewProps.language.c_str()];
  _hostView.language = language.length > 0 ? language : nil;
  NSString *configuration = [NSString stringWithUTF8String:newViewProps.configuration.c_str()];
  if (![configuration isEqualToString:_configurationJSON ?: @""]) {
    _configurationJSON = configuration;
    [_hostView setConfigurationJSON:configuration];
  }
  _hostView.selectedIndex = newViewProps.selectedIndex;
  _hostView.tabBarHidden = newViewProps.tabBarHidden;
  // [EN] A new request simulates a memory warning once. [CN] 新的请求模拟一次内存警告。
  if (newViewProps.memoryWarningRequest > _memoryWarningRequest) {
    NSString *report = [_hostView simulateMemoryWarning];
    if (_eventEmitter) {
      std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
          ->onMemoryWarning(CyltabbarViewEventEmitter::OnMemoryWarning{.report = std::string(report.UTF8String)});
    }
  }
  _memoryWarningRequest = newViewProps.memoryWarningRequest;
  // [EN] After the selection: logging out may move it away from a tab that needs login. [CN] 在选中之后：退出登录可能使选中离开需要登录的 Tab。
  // [EN] -1: not set, the host uses the cached state. [CN] -1：未设置，宿主使用缓存的状态。
  if (newViewProps.loginState >= 0) {
    _hostView.loggedIn = newViewProps.loginState == 1;
  } else {
    [_hostView resetLoggedIn];
  }
  NSMutableArray<NSString *> *badgeValues = [NSMutableArray array];
  for (const auto &value : newViewProps.badgeValues) {
    [badgeValues addObject:[NSString stringWithUTF8String:value.c_str()]];
  }
  if (![badgeValues isEqualToArray:_hostView.badgeValues]) {
    _hostView.badgeValues = badgeValues;
  }
  _hostView.badgeAnimationType = newViewProps.badgeAnimation;
  NSString *plusButtonBadgeValue = [NSString stringWithUTF8String:newViewProps.plusButtonBadgeValue.c_str()];
  if (![plusButtonBadgeValue isEqualToString:_hostView.plusButtonBadgeValue ?: @""]) {
    _hostView.plusButtonBadgeValue = plusButtonBadgeValue;
  }
  NSString *badgeStyles = [NSString stringWithUTF8String:newViewProps.badgeStyles.c_str()];
  if (![badgeStyles isEqualToString:_badgeStylesJSON ?: @""]) {
    _badgeStylesJSON = badgeStyles;
    id parsed = CYLRNJSONObject(badgeStyles);
    _hostView.badgeAttributes = [parsed isKindOfClass:[NSArray class]] ? parsed : nil;
  }
  NSString *plusButtonBadgeStyle = [NSString stringWithUTF8String:newViewProps.plusButtonBadgeStyle.c_str()];
  if (![plusButtonBadgeStyle isEqualToString:_plusButtonBadgeStyleJSON ?: @""]) {
    _plusButtonBadgeStyleJSON = plusButtonBadgeStyle;
    id parsed = CYLRNJSONObject(plusButtonBadgeStyle);
    _hostView.plusButtonBadgeAttributes = [parsed isKindOfClass:[NSDictionary class]] ? parsed : nil;
  }
  NSMutableArray *coverImages = [NSMutableArray array];
  for (const auto &value : newViewProps.tabCoverImages) {
    NSString *image = [NSString stringWithUTF8String:value.c_str()];
    [coverImages addObject:image.length > 0 ? image : [NSNull null]];
  }
  if (![coverImages isEqualToArray:_hostView.tabCoverImages ?: @[]]) {
    _hostView.tabCoverImages = coverImages;
  }
  [super updateProps:props oldProps:oldProps];
}

/// [EN] A JSON string as an object, nil when empty or invalid. [CN] JSON 字符串转为对象，为空或无效时为 nil。
static id CYLRNJSONObject(NSString *JSON)
{
  NSData *data = [JSON dataUsingEncoding:NSUTF8StringEncoding];
  return data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  _configurationJSON = nil;
  _hostView.configuration = nil;
  _hostView.badgeValues = @[];
  _hostView.plusButtonBadgeValue = nil;
  _hostView.badgeAttributes = nil;
  _hostView.plusButtonBadgeAttributes = nil;
  _hostView.tabCoverImages = nil;
  [_hostView resetLoggedIn];
  _hostView.tabBarHidden = NO;
  _memoryWarningRequest = 0;
  _badgeStylesJSON = nil;
  _plusButtonBadgeStyleJSON = nil;
  _hostView.selectedIndex = -1;
}

#pragma mark - Touches

/// The plus button rises above this view: let the host view (its tab bar) take touches outside the bounds first.
/// PlusButton 高出本视图：边界之外的触摸先交给宿主视图（其 TabBar）。
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  if (!CGRectContainsPoint(self.bounds, point)) {
    UIView *hit = [_hostView hitTest:[self convertPoint:point toView:_hostView] withEvent:event];
    if (hit) {
      return hit;
    }
  }
  return [super hitTest:point withEvent:event];
}

#pragma mark - Events

- (void)updateEventEmitter:(EventEmitter::Shared const &)eventEmitter
{
  [super updateEventEmitter:eventEmitter];
  // The height may be known before the emitter is: send it now. 高度可能早于事件发送器确定：此时补发。
  if (_hostView.preferredHeight > 0) {
    [self emitTabBarLayoutWithHeight:_hostView.preferredHeight];
  }
}

- (void)emitTabSelectAtIndex:(NSInteger)index identifier:(NSString *)identifier
{
  if (!_eventEmitter) {
    return;
  }
  std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
      ->onTabSelect(CyltabbarViewEventEmitter::OnTabSelect{.index = (int)index, .identifier = std::string(identifier.UTF8String)});
}

- (void)emitTabLongPressAtIndex:(NSInteger)index identifier:(NSString *)identifier title:(NSString *)title
{
  if (!_eventEmitter) {
    return;
  }
  std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
      ->onTabLongPress(CyltabbarViewEventEmitter::OnTabLongPress{
          .index = (int)index, .identifier = std::string(identifier.UTF8String), .title = std::string(title.UTF8String)});
}

- (void)emitLoginRequestAtIndex:(NSInteger)index identifier:(NSString *)identifier title:(NSString *)title
{
  if (!_eventEmitter) {
    return;
  }
  std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
      ->onLoginRequest(CyltabbarViewEventEmitter::OnLoginRequest{
          .index = (int)index, .identifier = std::string(identifier.UTF8String), .title = std::string(title.UTF8String)});
}

- (void)emitLoginStateChange:(BOOL)loggedIn
{
  if (!_eventEmitter) {
    return;
  }
  std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
      ->onLoginStateChange(CyltabbarViewEventEmitter::OnLoginStateChange{.loggedIn = (bool)loggedIn});
}

- (void)emitPlusButtonPress
{
  if (!_eventEmitter) {
    return;
  }
  std::string context = std::string((_hostView.tabBarController.context ?: @"").UTF8String);
  std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
      ->onPlusButtonPress(CyltabbarViewEventEmitter::OnPlusButtonPress{.context = context});
}

- (void)emitTabBarLayoutWithHeight:(CGFloat)height
{
  if (!_eventEmitter) {
    return;
  }
  std::static_pointer_cast<CyltabbarViewEventEmitter const>(_eventEmitter)
      ->onTabBarLayout(CyltabbarViewEventEmitter::OnTabBarLayout{.height = height});
}

@end
