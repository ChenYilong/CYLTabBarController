#import "CyltabbarView.h"

#import <CYLTabBarController/CYLTabBarController.h>

#import <react/renderer/components/CyltabbarViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/CyltabbarViewSpec/EventEmitters.h>
#import <react/renderer/components/CyltabbarViewSpec/Props.h>
#import <react/renderer/components/CyltabbarViewSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@implementation CyltabbarView {
  CYLTabBarHostView *_hostView;
  NSString *_configurationJSON;
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
    // React Native does not clip: the plus button may rise above the bar. React Native 不裁剪：PlusButton 可以高出 TabBar。
    self.contentView = _hostView;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &newViewProps = *std::static_pointer_cast<CyltabbarViewProps const>(props);
  NSString *configuration = [NSString stringWithUTF8String:newViewProps.configuration.c_str()];
  if (![configuration isEqualToString:_configurationJSON ?: @""]) {
    _configurationJSON = configuration;
    [_hostView setConfigurationJSON:configuration];
  }
  _hostView.selectedIndex = newViewProps.selectedIndex;
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
  [super updateProps:props oldProps:oldProps];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  _configurationJSON = nil;
  _hostView.configuration = nil;
  _hostView.badgeValues = @[];
  _hostView.plusButtonBadgeValue = nil;
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
