#import "FlutterCyltabbarPlugin.h"

#import <CYLTabBarController/CYLTabBarController.h>
#if __has_include(<CYLTabBarController/CYLTabBarItemAnimationFactory.h>)
#import <CYLTabBarController/CYLTabBarItemAnimationFactory.h>
#define CYL_FLUTTER_ANIMATION_AVAILABLE 1
#elif __has_include("CYLTabBarItemAnimationFactory.h")
#import "CYLTabBarItemAnimationFactory.h"
#define CYL_FLUTTER_ANIMATION_AVAILABLE 1
#else
#define CYL_FLUTTER_ANIMATION_AVAILABLE 0
#endif

static NSString *const CYLFlutterViewType = @"flutter_cyltabbar/CYLTabBar";
static NSString *const CYLFlutterAssetPrefix = @"flutter-asset:";

/// A Flutter asset, its best resolution variant first ("2.0x/", "3.0x/"). Flutter asset，优先取最合适的分辨率版本。
static UIImage *CYLFlutterAssetImage(NSString *asset, NSObject<FlutterPluginRegistrar> *registrar) {
    NSString *directory = asset.stringByDeletingLastPathComponent;
    NSString *file = asset.lastPathComponent;
    for (NSInteger scale = (NSInteger)UIScreen.mainScreen.scale; scale >= 1; scale--) {
        NSString *variant = scale == 1 ? asset : [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.0x/%@", (long)scale, file]];
        NSString *path = [[NSBundle mainBundle] pathForResource:[registrar lookupKeyForAsset:variant] ofType:nil];
        NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
        UIImage *image = data ? [UIImage imageWithData:data scale:scale] : nil;
        if (image) {
            return image;
        }
    }
    return nil;
}

/// The platform view: a `CYLTabBarHostView` with a method channel. 平台视图：带 method channel 的 `CYLTabBarHostView`。
@interface CYLFlutterTabBarView : NSObject <FlutterPlatformView>
@end

@implementation CYLFlutterTabBarView {
    CYLTabBarHostView *_hostView;
    FlutterMethodChannel *_channel;
}

- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId arguments:(NSDictionary *)arguments registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        NSString *channelName = [NSString stringWithFormat:@"%@/%lld", CYLFlutterViewType, viewId];
        FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:registrar.messenger];
        _channel = channel;
        _hostView = [[CYLTabBarHostView alloc] initWithFrame:frame];
        // Flutter clips platform views: the widget also holds what rises above the bar. Flutter 会裁剪平台视图：组件高度包含高出 TabBar 的部分。
        _hostView.heightIncludesOverflow = YES;
        _hostView.imageResolver = ^UIImage *(id value) {
            if ([value isKindOfClass:[NSString class]] && [value hasPrefix:CYLFlutterAssetPrefix]) {
                return CYLFlutterAssetImage([value substringFromIndex:CYLFlutterAssetPrefix.length], registrar);
            }
            return nil;
        };
        __weak FlutterMethodChannel *weakChannel = channel;
        _hostView.didSelectTab = ^(NSInteger index, NSString *identifier) {
            [weakChannel invokeMethod:@"onTabSelect" arguments:@{ @"index" : @(index), @"identifier" : identifier }];
        };
        _hostView.didTapPlusButton = ^{
            [weakChannel invokeMethod:@"onPlusButtonPress" arguments:nil];
        };
        _hostView.preferredHeightDidChange = ^(CGFloat height) {
            [weakChannel invokeMethod:@"onTabBarLayout" arguments:@(height)];
        };
        // [EN] Dart hit-tests the platform view: only these rects take touches. [CN] Dart 对平台视图做命中测试：只有这些矩形接收触摸。
        _hostView.touchableRectsDidChange = ^(NSArray<NSValue *> *rects) {
            NSMutableArray<NSArray<NSNumber *> *> *values = [NSMutableArray arrayWithCapacity:rects.count];
            for (NSValue *value in rects) {
                CGRect rect = value.CGRectValue;
                [values addObject:@[ @(CGRectGetMinX(rect)), @(CGRectGetMinY(rect)), @(CGRectGetWidth(rect)), @(CGRectGetHeight(rect)) ]];
            }
            [weakChannel invokeMethod:@"onTouchableRects" arguments:values];
        };
        _hostView.didLongPressTab = ^(NSInteger index, NSString *identifier, NSString *title) {
            [weakChannel invokeMethod:@"onTabLongPress" arguments:@{ @"index" : @(index), @"identifier" : identifier, @"title" : title }];
        };
        id selectedIndex = arguments[@"selectedIndex"];
        _hostView.selectedIndex = [selectedIndex isKindOfClass:[NSNumber class]] ? [selectedIndex integerValue] : -1;
        id badgeValues = arguments[@"badgeValues"];
        _hostView.badgeValues = [badgeValues isKindOfClass:[NSArray class]] ? badgeValues : @[];
        id plusButtonBadgeValue = arguments[@"plusButtonBadgeValue"];
        _hostView.plusButtonBadgeValue = [plusButtonBadgeValue isKindOfClass:[NSString class]] ? plusButtonBadgeValue : nil;
        id badgeAnimation = arguments[@"badgeAnimation"];
        _hostView.badgeAnimationType = [badgeAnimation isKindOfClass:[NSNumber class]] ? [badgeAnimation integerValue] : 0;
        id configuration = arguments[@"configuration"];
        [_hostView setConfigurationJSON:[configuration isKindOfClass:[NSString class]] ? configuration : nil];
        __weak __typeof(self) weakSelf = self;
        [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [weakSelf handleMethodCall:call result:result];
        }];
    }
    return self;
}

- (UIView *)view {
    return _hostView;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    id arguments = call.arguments;
    if ([call.method isEqualToString:@"setConfiguration"]) {
        [_hostView setConfigurationJSON:[arguments isKindOfClass:[NSString class]] ? arguments : nil];
    } else if ([call.method isEqualToString:@"setSelectedIndex"]) {
        _hostView.selectedIndex = [arguments isKindOfClass:[NSNumber class]] ? [arguments integerValue] : -1;
    } else if ([call.method isEqualToString:@"setBadgeValues"]) {
        _hostView.badgeValues = [arguments isKindOfClass:[NSArray class]] ? arguments : @[];
    } else if ([call.method isEqualToString:@"setPlusButtonBadgeValue"]) {
        _hostView.plusButtonBadgeValue = [arguments isKindOfClass:[NSString class]] ? arguments : nil;
    } else if ([call.method isEqualToString:@"setBadgeAnimation"]) {
        _hostView.badgeAnimationType = [arguments isKindOfClass:[NSNumber class]] ? [arguments integerValue] : 0;
    } else {
        result(FlutterMethodNotImplemented);
        return;
    }
    result(nil);
}

@end

#pragma mark - The animation view

/// A file name of the main bundle becomes its file URL, the options (the fragment) kept. 主 bundle 中的文件名转为其文件 URL，保留选项（fragment）。
static NSURL *CYLFlutterAnimationURL(NSString *source) {
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

/// An animation played by CYLTabBarController's engine. 由 CYLTabBarController 引擎播放的动画。
@interface CYLFlutterAnimationContainerView : UIView
@property (nonatomic, copy) void (^layoutBlock)(void);
@end

@implementation CYLFlutterAnimationContainerView
- (void)layoutSubviews {
    [super layoutSubviews];
    !self.layoutBlock ?: self.layoutBlock();
}
@end

@interface CYLFlutterAnimationView : NSObject <FlutterPlatformView>
@end

@implementation CYLFlutterAnimationView {
    CYLFlutterAnimationContainerView *_view;
    UIView *_animationView;
    FlutterMethodChannel *_channel;
    NSString *_source;
    BOOL _playing;
}

- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId arguments:(NSDictionary *)arguments registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        _view = [[CYLFlutterAnimationContainerView alloc] initWithFrame:frame];
        __weak __typeof(self) weakSelf = self;
        _view.layoutBlock = ^{
            [weakSelf layout];
        };
        _source = [arguments[@"source"] isKindOfClass:[NSString class]] ? arguments[@"source"] : nil;
        _playing = [arguments[@"playing"] boolValue];
        NSString *name = [NSString stringWithFormat:@"flutter_cyltabbar/CYLAnimationView/%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:name binaryMessenger:registrar.messenger];
        [_channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [weakSelf handleMethodCall:call result:result];
        }];
    }
    return self;
}

- (UIView *)view {
    return _view;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"setSource"]) {
        _source = [call.arguments isKindOfClass:[NSString class]] ? call.arguments : nil;
        [self rebuild];
    } else if ([call.method isEqualToString:@"setPlaying"]) {
        _playing = [call.arguments boolValue];
        [self applyPlaying];
    } else {
        result(FlutterMethodNotImplemented);
        return;
    }
    result(nil);
}

/// [EN] Built once the view has a size (Flutter makes it with an empty frame). [CN] 视图有尺寸后才创建（Flutter 以空 frame 创建视图）。
- (void)layout {
    if (!_animationView && CGRectGetWidth(_view.bounds) > 0) {
        [self rebuild];
    }
    _animationView.frame = _view.bounds;
}

- (void)rebuild {
    [_animationView removeFromSuperview];
    _animationView = nil;
#if CYL_FLUTTER_ANIMATION_AVAILABLE
    NSURL *URL = _source.length > 0 ? CYLFlutterAnimationURL(_source) : nil;
    if (URL && CGRectGetWidth(_view.bounds) > 0) {
        UIView *view = [CYLTabBarItemAnimationFactory animationViewWithURL:URL size:_view.bounds.size contentMode:UIViewContentModeScaleAspectFit];
        if (view) {
            view.frame = _view.bounds;
            [_view addSubview:view];
            _animationView = view;
        }
    }
#endif
    [self applyPlaying];
}

- (void)applyPlaying {
#if CYL_FLUTTER_ANIMATION_AVAILABLE
    id<CYLTabBarItemAnimationPlayer> player = [CYLTabBarItemAnimationFactory playerForView:_animationView];
    if (_playing) {
        [player play];
    } else {
        [player stop];
    }
#endif
}

@end

@interface CYLFlutterAnimationViewFactory : NSObject <FlutterPlatformViewFactory>
@property (nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
@end

@implementation CYLFlutterAnimationViewFactory

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    return [[CYLFlutterAnimationView alloc] initWithFrame:frame viewId:viewId arguments:[args isKindOfClass:[NSDictionary class]] ? args : @{} registrar:self.registrar];
}

@end

#pragma mark - The factory and the plugin

@interface CYLFlutterTabBarViewFactory : NSObject <FlutterPlatformViewFactory>
@property (nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
@end

@implementation CYLFlutterTabBarViewFactory

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    return [[CYLFlutterTabBarView alloc] initWithFrame:frame viewId:viewId arguments:[args isKindOfClass:[NSDictionary class]] ? args : @{} registrar:self.registrar];
}

@end

@implementation FlutterCyltabbarPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    CYLFlutterTabBarViewFactory *factory = [[CYLFlutterTabBarViewFactory alloc] init];
    factory.registrar = registrar;
    [registrar registerViewFactory:factory withId:CYLFlutterViewType];
    CYLFlutterAnimationViewFactory *animationFactory = [[CYLFlutterAnimationViewFactory alloc] init];
    animationFactory.registrar = registrar;
    [registrar registerViewFactory:animationFactory withId:@"flutter_cyltabbar/CYLAnimationView"];
}

@end
