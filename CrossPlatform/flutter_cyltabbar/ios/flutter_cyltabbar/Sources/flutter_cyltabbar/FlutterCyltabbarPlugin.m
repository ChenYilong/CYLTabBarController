#import "FlutterCyltabbarPlugin.h"

#import <CYLTabBarController/CYLTabBarController.h>
// [EN] CYLTabBarHostView is in Swift since step 36 of the migration; the umbrella header does not import the generated Swift
//      header (docs/Swift-Migration.md). CocoaPods: the framework or the static library's "Swift Compatibility Header";
//      Swift Package Manager: the module.
// [CN] 自迁移第 36 步起 CYLTabBarHostView 为 Swift；伞头文件不导入生成的 Swift 头文件。CocoaPods：framework 或静态库的
//      "Swift Compatibility Header"；Swift Package Manager：模块。
#if __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#elif __has_include("CYLTabBarController-Swift.h")
#import "CYLTabBarController-Swift.h"
#else
@import CYLTabBarController;
#endif
// [EN] The animation view is a `CYLAnimatedItemView` (the cross-platform engine API, docs/Animated-Item.md, "Engine API across
//      platforms"); the CYLAnimatedItem pod comes with CYLTabBarController. Without it the animation view stays empty.
// [CN] 动画视图是 `CYLAnimatedItemView`（跨端引擎 API，见 docs/Animated-Item.md「跨端引擎 API」）；CYLAnimatedItem pod 随 CYLTabBarController
//      一起提供。没有它时动画视图保持为空。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#define CYL_FLUTTER_ANIMATION_AVAILABLE 1
#elif __has_include("CYLAnimatedItem-Swift.h")
#import "CYLAnimatedItem-Swift.h"
#define CYL_FLUTTER_ANIMATION_AVAILABLE 1
#else
#define CYL_FLUTTER_ANIMATION_AVAILABLE 0
#endif
#if CYL_FLUTTER_ANIMATION_AVAILABLE
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayer.h>
#endif
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
        _hostView.didRequestLogin = ^(NSInteger index, NSString *identifier, NSString *title) {
            [weakChannel invokeMethod:@"onLoginRequest" arguments:@{ @"index" : @(index), @"identifier" : identifier, @"title" : title }];
        };
        _hostView.loginStateDidChange = ^(BOOL loggedIn) {
            [weakChannel invokeMethod:@"onLoginStateChange" arguments:@(loggedIn)];
        };
        _hostView.didApplyManifest = ^(NSString *source) {
            [weakChannel invokeMethod:@"onManifestApply" arguments:source];
        };
        _hostView.didPostLifecycleEvent = ^(NSString *name, NSString *userInfo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakChannel invokeMethod:@"onLifecycleEvent" arguments:@{@"name": name, @"userInfo": userInfo}];
            });
        };
        _hostView.didFailManifest = ^(NSString *message) {
            [weakChannel invokeMethod:@"onManifestFail" arguments:message];
        };
        [self applyLoggedIn:arguments[@"loggedIn"]];
        // [EN] Before the configuration, so it is built once, in this language. [CN] 在配置之前，使 TabBar 以该语言只创建一次。
        [self applyLanguage:arguments[@"language"]];
        _hostView.tabBarHidden = [arguments[@"tabBarHidden"] isKindOfClass:[NSNumber class]] && [arguments[@"tabBarHidden"] boolValue];
        _hostView.animationSpeed = [arguments[@"playbackSpeed"] isKindOfClass:[NSNumber class]] ? [arguments[@"playbackSpeed"] doubleValue] : 0;
        _hostView.animationLoops = [arguments[@"playbackLoops"] isKindOfClass:[NSNumber class]] && [arguments[@"playbackLoops"] boolValue];
        [self applyTitlePositionAdjustment:arguments[@"titlePositionAdjustment"]];
        id selectedIndex = arguments[@"selectedIndex"];
        _hostView.selectedIndex = [selectedIndex isKindOfClass:[NSNumber class]] ? [selectedIndex integerValue] : -1;
        id badgeValues = arguments[@"badgeValues"];
        _hostView.badgeValues = [badgeValues isKindOfClass:[NSArray class]] ? badgeValues : @[];
        id plusButtonBadgeValue = arguments[@"plusButtonBadgeValue"];
        _hostView.plusButtonBadgeValue = [plusButtonBadgeValue isKindOfClass:[NSString class]] ? plusButtonBadgeValue : nil;
        id badgeAnimation = arguments[@"badgeAnimation"];
        _hostView.badgeAnimationType = [badgeAnimation isKindOfClass:[NSNumber class]] ? [badgeAnimation integerValue] : 0;
        [self applyBadgeStyles:arguments[@"badgeStyles"]];
        [self applyPlusButtonBadge:arguments[@"plusButtonBadge"]];
        [self applyTabCoverImages:arguments[@"tabCoverImages"]];
        id configuration = arguments[@"configuration"];
        [_hostView setConfigurationJSON:[configuration isKindOfClass:[NSString class]] ? configuration : nil];
        // [EN] The manifest to download, after the configuration: the manifest's keys are under the app's own ones.
        // [CN] 要下载的清单，在配置之后：清单的键位于 App 自己的键之下。
        id manifestURL = arguments[@"manifestURL"];
        if ([manifestURL isKindOfClass:[NSString class]] && [(NSString *)manifestURL length] > 0) {
            _hostView.manifestURL = manifestURL;
        }
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

- (void)applyBadgeStyles:(id)value {
    _hostView.badgeAttributes = [value isKindOfClass:[NSArray class]] ? value : nil;
}

- (void)applyPlusButtonBadge:(id)value {
    _hostView.plusButtonBadgeAttributes = [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

/// [EN] [horizontal, vertical], or null for the configuration's offset. [CN] [水平, 垂直]；null 时使用配置中的偏移。
- (void)applyTitlePositionAdjustment:(id)value {
    NSArray *offset = [value isKindOfClass:[NSArray class]] ? value : nil;
    _hostView.titlePositionAdjustment = offset.count >= 2 && [offset[0] isKindOfClass:[NSNumber class]] && [offset[1] isKindOfClass:[NSNumber class]]
        ? [NSValue valueWithUIOffset:UIOffsetMake([offset[0] doubleValue], [offset[1] doubleValue])]
        : nil;
}

/// [EN] A language code, or null for the device language. [CN] 语言代码；null 表示设备语言。
- (void)applyLanguage:(id)value {
    _hostView.language = [value isKindOfClass:[NSString class]] && [value length] > 0 ? value : nil;
}

/// [EN] A bool sets the app's login state; null leaves it to the state the library cached. [CN] 布尔值设置 App 的登录状态；null 时使用库缓存的状态。
- (void)applyLoggedIn:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        _hostView.loggedIn = [value boolValue];
    } else {
        [_hostView resetLoggedIn];
    }
}

- (void)applyTabCoverImages:(id)value {
    _hostView.tabCoverImages = [value isKindOfClass:[NSArray class]] ? value : nil;
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
    } else if ([call.method isEqualToString:@"setBadgeStyles"]) {
        [self applyBadgeStyles:arguments];
    } else if ([call.method isEqualToString:@"setPlusButtonBadge"]) {
        [self applyPlusButtonBadge:arguments];
    } else if ([call.method isEqualToString:@"setTabCoverImages"]) {
        [self applyTabCoverImages:arguments];
    } else if ([call.method isEqualToString:@"setTitlePositionAdjustment"]) {
        [self applyTitlePositionAdjustment:arguments];
    } else if ([call.method isEqualToString:@"simulateMemoryWarning"]) {
        result([_hostView simulateMemoryWarning]);
        return;
    } else if ([call.method isEqualToString:@"setPlaybackSpeed"]) {
        _hostView.animationSpeed = [arguments isKindOfClass:[NSNumber class]] ? [arguments doubleValue] : 0;
    } else if ([call.method isEqualToString:@"setPlaybackLoops"]) {
        _hostView.animationLoops = [arguments isKindOfClass:[NSNumber class]] && [arguments boolValue];
    } else if ([call.method isEqualToString:@"setAnimationsPaused"]) {
        _hostView.animationsPaused = [arguments isKindOfClass:[NSNumber class]] && [arguments boolValue];
    } else if ([call.method isEqualToString:@"playAllAnimations"]) {
        [_hostView playAllAnimations];
    } else if ([call.method isEqualToString:@"setTabBarHidden"]) {
        _hostView.tabBarHidden = [arguments isKindOfClass:[NSNumber class]] && [arguments boolValue];
    } else if ([call.method isEqualToString:@"setLanguage"]) {
        [self applyLanguage:arguments];
    } else if ([call.method isEqualToString:@"setLoggedIn"]) {
        [self applyLoggedIn:arguments];
    } else if ([call.method isEqualToString:@"setManifestURL"]) {
        if ([arguments isKindOfClass:[NSString class]] && [(NSString *)arguments length] > 0) {
            _hostView.manifestURL = arguments;
        }
    } else {
        result(FlutterMethodNotImplemented);
        return;
    }
    result(nil);
}

@end

#pragma mark - The animation view

#if CYL_FLUTTER_ANIMATION_AVAILABLE
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

#endif

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

#if CYL_FLUTTER_ANIMATION_AVAILABLE
/// [EN] A color the Dart side sends: an ARGB integer (`Color.value`). [CN] Dart 一侧发送的颜色：ARGB 整数（`Color.value`）。
static UIColor *CYLFlutterColor(id value) {
    if (![value isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    uint32_t argb = (uint32_t)[value unsignedLongLongValue];
    return [UIColor colorWithRed:((argb >> 16) & 0xFF) / 255.0 green:((argb >> 8) & 0xFF) / 255.0
                            blue:(argb & 0xFF) / 255.0 alpha:((argb >> 24) & 0xFF) / 255.0];
}
#endif

/**
 * [EN] An animation played by CYLTabBarController's engine through a `CYLAnimatedItemView`, the same contract as the Android
 *      view (`CYLFlutterAnimationView.kt`). Channel `flutter_cyltabbar/CYLAnimationView/<id>`: the methods `setSource`,
 *      `setSelected`, `setAnimationSpeed`, `setAnimationLoops`, `setAnimationRestartToken`, `setDrivesAnimationPlayback`,
 *      `setPlaying`, `setIconSize`, `setTintColor`, `setItemBackgroundStyle`, `setItemBackgroundColor`, `setItemCornerRadius`,
 *      `setItemBorderWidth`, `setItemBorderColor` and the commands `play`, `stopAtProgress`, `restart`; it calls back
 *      `onAnimationLoaded`, `onAnimationFailed` and `onAnimationEnd`. No engine logic here. The restart token is read-only on
 *      iOS (`animationRestartToken` grows on every `restartAnimation()`), so a changed token calls `restartAnimation()`.
 * [CN] 由 CYLTabBarController 引擎通过 `CYLAnimatedItemView` 播放的动画，契约与 Android 视图相同（`CYLFlutterAnimationView.kt`）。
 *      通道 `flutter_cyltabbar/CYLAnimationView/<id>`：方法 `setSource`、`setSelected`、`setAnimationSpeed`、`setAnimationLoops`、
 *      `setAnimationRestartToken`、`setDrivesAnimationPlayback`、`setPlaying`、`setIconSize`、`setTintColor`，命令 `play`、
 *      `stopAtProgress`、`restart`；回调 `onAnimationLoaded`、`onAnimationFailed`、`onAnimationEnd`。这里没有引擎逻辑。重播 token 在 iOS 上
 *      只读（每次 `restartAnimation()` 后 `animationRestartToken` 加一），因此 token 变化时调用 `restartAnimation()`。
 */
@interface CYLFlutterAnimationView : NSObject <FlutterPlatformView>
@end

@implementation CYLFlutterAnimationView {
    CYLFlutterAnimationContainerView *_view;
    FlutterMethodChannel *_channel;
#if CYL_FLUTTER_ANIMATION_AVAILABLE
    CYLAnimatedItemView *_item;
    NSInteger _restartToken;
    CGFloat _iconSide;
    BOOL _selected;
    BOOL _playing;
    NSString *_image;
#endif
}

- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId arguments:(NSDictionary *)arguments registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    if (self = [super init]) {
        _view = [[CYLFlutterAnimationContainerView alloc] initWithFrame:frame];
        __weak __typeof(self) weakSelf = self;
        _view.layoutBlock = ^{
            [weakSelf layout];
        };
        NSString *name = [NSString stringWithFormat:@"flutter_cyltabbar/CYLAnimationView/%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:name binaryMessenger:registrar.messenger];
        [_channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [weakSelf handleMethodCall:call result:result];
        }];
#if CYL_FLUTTER_ANIMATION_AVAILABLE
        [self setUpItemWithArguments:arguments];
#endif
    }
    return self;
}

- (UIView *)view {
    return _view;
}

#if CYL_FLUTTER_ANIMATION_AVAILABLE
- (void)setUpItemWithArguments:(NSDictionary *)arguments {
    // [EN] The blocks hold the channel, not self: the channel does not own the item, so there is no cycle.
    // [CN] block 持有 channel 而不是 self：channel 不持有该条目，因此没有循环引用。
    FlutterMethodChannel *channel = _channel;
    __weak __typeof(self) weakSelf = self;
    _item = [[CYLAnimatedItemView alloc] initWithFrame:_view.bounds];
    // [EN] Icon only; the view the host gives is the icon's frame. [CN] 只有图标；宿主给的视图就是图标的范围。
    _item.onAnimationEnd = ^{ [channel invokeMethod:@"onAnimationEnd" arguments:nil]; };
    _item.onAnimationLoaded = ^{
        // [EN] A selected item that becomes ready plays, as on Android. [CN] 就绪的选中条目开始播放，与 Android 一致。
        [weakSelf followSelection];
        [channel invokeMethod:@"onAnimationLoaded" arguments:nil];
    };
    _item.onAnimationFailed = ^{ [channel invokeMethod:@"onAnimationFailed" arguments:nil]; };
    [_view addSubview:_item];
    if ([arguments[@"drivesAnimationPlayback"] isKindOfClass:[NSNumber class]]) {
        _item.drivesAnimationPlayback = [arguments[@"drivesAnimationPlayback"] boolValue];
    }
    if ([arguments[@"showsImageWhenAnimationEnds"] isKindOfClass:[NSNumber class]]) {
        _item.showsImageWhenAnimationEnds = [arguments[@"showsImageWhenAnimationEnds"] boolValue];
    }
    [self applyImage:[arguments[@"image"] isKindOfClass:[NSString class]] ? arguments[@"image"] : nil];
    if ([arguments[@"animationSpeed"] isKindOfClass:[NSNumber class]]) {
        _item.animationSpeed = [arguments[@"animationSpeed"] doubleValue];
    }
    if ([arguments[@"animationLoops"] isKindOfClass:[NSNumber class]]) {
        _item.animationLoops = [arguments[@"animationLoops"] boolValue];
    }
    // [EN] The token at creation is not a restart. [CN] 创建时的 token 不算重播。
    _restartToken = [arguments[@"animationRestartToken"] isKindOfClass:[NSNumber class]] ? [arguments[@"animationRestartToken"] integerValue] : 0;
    _iconSide = [arguments[@"iconSize"] isKindOfClass:[NSNumber class]] ? [arguments[@"iconSize"] doubleValue] : 0;
    UIColor *tint = CYLFlutterColor(arguments[@"tintColor"]);
    if (tint) {
        [_item applyIconTintColor:tint];
    }
    [self applyItemBackgroundStyle:arguments[@"itemBackgroundStyle"]];
    _item.itemBackgroundColor = CYLFlutterColor(arguments[@"itemBackgroundColor"]);
    [self applyItemCornerRadius:arguments[@"itemCornerRadius"]];
    [self applyItemBorderWidth:arguments[@"itemBorderWidth"]];
    _item.itemBorderColor = CYLFlutterColor(arguments[@"itemBorderColor"]);
    if ([arguments[@"selected"] isKindOfClass:[NSNumber class]]) {
        _selected = [arguments[@"selected"] boolValue];
        _item.selected = _selected;
    }
    [self fitIcon];
    NSString *source = [arguments[@"source"] isKindOfClass:[NSString class]] ? arguments[@"source"] : nil;
    [self applySource:source];
    if ([arguments[@"playing"] boolValue]) {
        _playing = YES;
        [_item playAnimation];
    }
}

/// [EN] `itemBackgroundStyle`: "liquidGlass", or anything else (nil, "flat") for flat. [CN] `itemBackgroundStyle`："liquidGlass"，其他值（nil、"flat"）为扁平。
- (void)applyItemBackgroundStyle:(id)style {
    _item.itemBackgroundStyle = [style isEqual:@"liquidGlass"] ? CYLAnimatedItemBackgroundStyleLiquidGlass : CYLAnimatedItemBackgroundStyleFlat;
}

/// [EN] `itemCornerRadius` in points (the core limits it to half the height; 1000 is the capsule constant); nil is not set.
/// [CN] `itemCornerRadius`（点；核心把它限制在半高以内，1000 是胶囊常量）；nil 表示未设置。
- (void)applyItemCornerRadius:(id)radius {
    _item.itemCornerRadiusNumber = [radius isKindOfClass:[NSNumber class]] ? radius : nil;
}

/// [EN] `itemBorderWidth` in points; nil is 0. [CN] `itemBorderWidth`（点）；nil 为 0。
- (void)applyItemBorderWidth:(id)width {
    _item.itemBorderWidth = [width isKindOfClass:[NSNumber class]] ? [width doubleValue] : 0;
}

/// [EN] The default rule of the bridge (`drivesAnimationPlayback` true): selected plays from the resting frame, unselected
///      stops at the resting progress. `CYLAnimatedItemView` itself never plays on selection on iOS (the tab engine does).
/// [CN] 桥接的默认规则（`drivesAnimationPlayback` 为 true）：选中从静止帧开始播放，未选中停在静止进度。iOS 上 `CYLAnimatedItemView` 自身
///      不会因选中而播放（由 Tab 引擎播放）。
- (void)followSelection {
    if (!_item.drivesAnimationPlayback || _playing) {
        return;
    }
    if (_selected) {
        [_item playAnimation];
    } else {
        [_item stopAnimation];
    }
}

/// [EN] Loads the still image of the `image` argument, resolved like `source` (`CYLFlutterAnimationURL`): a file name of the main
///      bundle, a path or a URL (a download, applied when it arrived if the image did not change meanwhile). With no image the end shows the library's placeholder (the HarmonyOS rule).
/// [CN] 加载 `image` 参数的静态图片，解析方式与 `source` 相同（`CYLFlutterAnimationURL`）：主 bundle 的文件名、路径或 URL
///      （下载完成时应用，期间图片未变化才应用）。
- (void)applyImage:(NSString *)image {
    _image = image;
    NSURL *URL = image.length > 0 ? CYLFlutterAnimationURL(image) : nil;
    if (!URL) {
        _item.image = nil;
    } else if (URL.isFileURL) {
        _item.image = [UIImage imageWithContentsOfFile:URL.path];
    } else {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:URL];
            UIImage *loaded = data ? [UIImage imageWithData:data] : nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && [strongSelf->_image isEqualToString:image]) {
                    strongSelf->_item.image = loaded;
                }
            });
        });
    }
}

- (void)applySource:(NSString *)source {
    _item.animationURL = source.length > 0 ? CYLFlutterAnimationURL(source) : nil;
}

/// [EN] The icon fills the view, or is `iconSize` (points) when given. [CN] 图标铺满视图，给了 `iconSize`（点）时为该尺寸。
- (void)fitIcon {
    CGSize size = _iconSide > 0 ? CGSizeMake(_iconSide, _iconSide) : _view.bounds.size;
    if (size.width > 0 && size.height > 0 && !CGSizeEqualToSize(_item.iconSize, size)) {
        _item.iconSize = size;
    }
}

/// [EN] The player of the current animation, nil until it is in place. [CN] 当前动画的播放器，就绪前为 nil。
- (id<CYLTabBarItemAnimationPlayer>)player {
    return _item.animationPlayer;
}
#endif

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
#if CYL_FLUTTER_ANIMATION_AVAILABLE
    id argument = call.arguments;
    NSString *method = call.method;
    if ([method isEqualToString:@"setSource"]) {
        [self applySource:[argument isKindOfClass:[NSString class]] ? argument : nil];
    } else if ([method isEqualToString:@"setSelected"]) {
        _selected = [argument boolValue];
        _item.selected = _selected;
        [self followSelection];
    } else if ([method isEqualToString:@"setAnimationSpeed"]) {
        _item.animationSpeed = [argument isKindOfClass:[NSNumber class]] ? [argument doubleValue] : 1;
    } else if ([method isEqualToString:@"setAnimationLoops"]) {
        _item.animationLoops = [argument boolValue];
    } else if ([method isEqualToString:@"setAnimationRestartToken"]) {
        NSInteger token = [argument isKindOfClass:[NSNumber class]] ? [argument integerValue] : 0;
        if (token != _restartToken) {
            _restartToken = token;
            [_item restartAnimation];
        }
    } else if ([method isEqualToString:@"setDrivesAnimationPlayback"]) {
        _item.drivesAnimationPlayback = [argument isKindOfClass:[NSNumber class]] ? [argument boolValue] : YES;
    } else if ([method isEqualToString:@"setShowsImageWhenAnimationEnds"]) {
        _item.showsImageWhenAnimationEnds = [argument isKindOfClass:[NSNumber class]] ? [argument boolValue] : NO;
    } else if ([method isEqualToString:@"setImage"]) {
        [self applyImage:[argument isKindOfClass:[NSString class]] ? argument : nil];
    } else if ([method isEqualToString:@"setPlaying"]) {
        _playing = [argument boolValue];
        if (_playing) {
            [_item playAnimation];
        } else {
            [_item stopAnimation];
        }
    } else if ([method isEqualToString:@"setIconSize"]) {
        _iconSide = [argument isKindOfClass:[NSNumber class]] ? [argument doubleValue] : 0;
        [self fitIcon];
    } else if ([method isEqualToString:@"setTintColor"]) {
        [_item applyIconTintColor:CYLFlutterColor(argument)];
    } else if ([method isEqualToString:@"setItemBackgroundStyle"]) {
        [self applyItemBackgroundStyle:argument];
    } else if ([method isEqualToString:@"setItemBackgroundColor"]) {
        _item.itemBackgroundColor = CYLFlutterColor(argument);
    } else if ([method isEqualToString:@"setItemCornerRadius"]) {
        [self applyItemCornerRadius:argument];
    } else if ([method isEqualToString:@"setItemBorderWidth"]) {
        [self applyItemBorderWidth:argument];
    } else if ([method isEqualToString:@"setItemBorderColor"]) {
        _item.itemBorderColor = CYLFlutterColor(argument);
    } else if ([method isEqualToString:@"play"]) {
        [[self player] play];
    } else if ([method isEqualToString:@"stopAtProgress"]) {
        id<CYLTabBarItemAnimationPlayer> player = [self player];
        [player stop];
        if ([player respondsToSelector:@selector(setProgress:)]) {
            player.progress = [argument isKindOfClass:[NSNumber class]] ? [argument doubleValue] : 0;
        }
    } else if ([method isEqualToString:@"restart"]) {
        [_item restartAnimation];
    } else {
        result(FlutterMethodNotImplemented);
        return;
    }
    result(nil);
#else
    result(FlutterMethodNotImplemented);
#endif
}

/// [EN] Keeps the icon at the view's size. [CN] 让图标保持与视图相同的尺寸。
- (void)layout {
#if CYL_FLUTTER_ANIMATION_AVAILABLE
    _item.frame = _view.bounds;
    [self fitIcon];
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
