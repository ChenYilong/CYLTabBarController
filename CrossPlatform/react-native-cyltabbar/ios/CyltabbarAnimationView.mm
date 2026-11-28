#import "CyltabbarAnimationView.h"

#import <CYLTabBarController/CYLTabBarController.h>
// [EN] The classes translated to Swift (CYLTabBarHostView, step 36; the animation factory): the umbrella header does not
//      import the generated Swift header (docs/Swift-Migration.md).
// [CN] 已翻译为 Swift 的类（CYLTabBarHostView，第 36 步；动画工厂）：伞头文件不导入生成的 Swift 头文件（docs/Swift-Migration.md）。
#if __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#else
#import "CYLTabBarController-Swift.h"
#endif
#if __has_include(<CYLTabBarController/CYLTabBarItemAnimationFactory.h>)
#import <CYLTabBarController/CYLTabBarItemAnimationFactory.h>
#define CYL_RN_ANIMATION_AVAILABLE 1
#else
#define CYL_RN_ANIMATION_AVAILABLE 0
#endif

#import <react/renderer/components/CyltabbarViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/CyltabbarViewSpec/Props.h>
#import <react/renderer/components/CyltabbarViewSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@implementation CyltabbarAnimationView {
  NSString *_source;
  BOOL _playing;
  UIView *_animationView;
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
#endif

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<CyltabbarAnimationViewProps const>(props);
  NSString *source = [NSString stringWithUTF8String:newProps.source.c_str()];
  if (![source isEqualToString:_source ?: @""]) {
    _source = source;
    [self rebuild];
  }
  if (newProps.playing != _playing) {
    _playing = newProps.playing;
    [self applyPlaying];
  }
  [super updateProps:props oldProps:oldProps];
}

- (void)rebuild
{
  [_animationView removeFromSuperview];
  _animationView = nil;
#if CYL_RN_ANIMATION_AVAILABLE
  NSURL *URL = _source.length > 0 ? CYLRNAnimationURL(_source) : nil;
  CGSize size = self.bounds.size.width > 0 ? self.bounds.size : CGSizeMake(44, 44);
  UIView *view = URL ? [CYLTabBarItemAnimationFactory animationViewWithURL:URL size:size contentMode:UIViewContentModeScaleAspectFit] : nil;
  if (view) {
    view.frame = self.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:view];
    _animationView = view;
  }
#endif
  [self applyPlaying];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _animationView.frame = self.bounds;
}

- (void)applyPlaying
{
#if CYL_RN_ANIMATION_AVAILABLE
  id<CYLTabBarItemAnimationPlayer> player = [CYLTabBarItemAnimationFactory playerForView:_animationView];
  if (_playing) {
    [player play];
  } else {
    [player stop];
  }
#endif
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  [_animationView removeFromSuperview];
  _animationView = nil;
  _source = nil;
  _playing = NO;
}

@end
