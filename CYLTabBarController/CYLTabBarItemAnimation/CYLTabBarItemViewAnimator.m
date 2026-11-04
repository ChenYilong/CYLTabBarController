//
//  CYLTabBarItemViewAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemViewAnimator.h"

/*!
 * [EN] The options in `URL`'s fragment, as written by `CYLTabBarAnimationURLWithOptions()` ("name=value&…",
 *      percent-encoded).
 * [CN] `URL` 的 fragment 中的选项，格式与 `CYLTabBarAnimationURLWithOptions()` 写入的相同（「名称=值&…」，百分号编码）。
 */
static NSDictionary<NSString *, NSString *> *CYLTabBarItemAnimationOptionsFromURL(NSURL *URL) {
    NSString *fragment = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES].percentEncodedFragment;
    NSMutableDictionary<NSString *, NSString *> *options = [NSMutableDictionary dictionary];
    for (NSString *item in [fragment componentsSeparatedByString:@"&"]) {
        NSRange separator = [item rangeOfString:@"="];
        if (separator.location == NSNotFound || separator.location == 0) {
            continue;
        }
        NSString *name = [[item substringToIndex:separator.location] stringByRemovingPercentEncoding];
        NSString *value = [[item substringFromIndex:NSMaxRange(separator)] stringByRemovingPercentEncoding];
        if (name.length > 0 && value.length > 0) {
            options[name] = value;
        }
    }
    return [options copy];
}

/// [EN] `URL` without its fragment: the animation file itself. [CN] 去掉 fragment 的 `URL`，即动画文件本身。
static NSURL *CYLTabBarItemAnimationFileURLFromURL(NSURL *URL) {
    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    components.fragment = nil;
    return components.URL ?: URL;
}

/// [EN] Plays any `CYLTabBarItemAnimationPlayableView`. [CN] 播放任意 `CYLTabBarItemAnimationPlayableView`。
@interface CYLTabBarItemPlayableViewPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLTabBarItemPlayableViewPlayer {
    /// [EN] Whether the dark colors are applied now. [CN] 当前是否已应用深色颜色。
    BOOL _darkColorsApplied;
}

- (id<CYLTabBarItemAnimationPlayableView>)playableView {
    UIView *view = self.animationView;
    return [view conformsToProtocol:@protocol(CYLTabBarItemAnimationPlayableView)] ? (id<CYLTabBarItemAnimationPlayableView>)view : nil;
}

- (void)play {
    [self.playableView cyl_playAnimationView];
}

- (void)showLastFrame {
    [self.playableView cyl_showAnimationViewLastFrame];
}

- (void)stop {
    [self.playableView cyl_stopAnimationView];
}

- (void)applyDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors traitCollection:(UITraitCollection *)traitCollection {
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    if (darkColors.count == 0 || ![view respondsToSelector:@selector(cyl_applyAnimationViewColors:)]) {
        return;
    }
    BOOL dark = NO;
    if (@available(iOS 13.0, *)) {
        dark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    if (_darkColorsApplied == dark) {
        return;
    }
    _darkColorsApplied = dark;
    if (!dark) {
        [view cyl_applyAnimationViewColors:nil];
        return;
    }
    NSMutableDictionary<NSString *, UIColor *> *colors = [NSMutableDictionary dictionaryWithCapacity:darkColors.count];
    [darkColors enumerateKeysAndObjectsUsingBlock:^(NSString *path, UIColor *color, BOOL *stop) {
        (void)stop;
        if ([path isKindOfClass:[NSString class]] && [color isKindOfClass:[UIColor class]]) {
            UIColor *resolvedColor = color;
            if (@available(iOS 13.0, *)) {
                resolvedColor = [color resolvedColorWithTraitCollection:traitCollection];
            }
            colors[path] = resolvedColor;
        }
    }];
    [view cyl_applyAnimationViewColors:colors];
}

@end

@implementation CYLTabBarItemViewAnimator {
    NSString *_identifier;
    NSArray<NSString *> *_fileExtensions;
    NSDictionary<NSString *, NSString *> *_attributeKeys;
    /// [EN] The class given at initialization. [CN] 初始化时传入的类。
    Class<CYLTabBarItemAnimationViewProviding> _defaultViewProvider;
    /// [EN] The injected provider; nil: the default. [CN] 注入的 provider；nil 表示默认值。
    Class<CYLTabBarItemAnimationViewProviding> _injectedViewProvider;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                    fileExtensions:(NSArray<NSString *> *)fileExtensions
                     attributeKeys:(NSDictionary<NSString *, NSString *> *)attributeKeys
                      viewProvider:(Class<CYLTabBarItemAnimationViewProviding>)viewProvider {
    if (self = [super init]) {
        _identifier = [identifier copy];
        NSMutableArray<NSString *> *extensions = [NSMutableArray arrayWithCapacity:fileExtensions.count];
        for (NSString *extension in fileExtensions) {
            [extensions addObject:extension.lowercaseString];
        }
        _fileExtensions = [extensions copy];
        _attributeKeys = [attributeKeys copy] ?: @{};
        _defaultViewProvider = [viewProvider conformsToProtocol:@protocol(CYLTabBarItemAnimationViewProviding)] ? viewProvider : nil;
    }
    return self;
}

- (Class<CYLTabBarItemAnimationViewProviding>)viewProvider {
    if (_injectedViewProvider) {
        return _injectedViewProvider;
    }
    return _defaultViewProvider;
}

- (void)setViewProvider:(Class<CYLTabBarItemAnimationViewProviding>)viewProvider {
    _injectedViewProvider = [viewProvider conformsToProtocol:@protocol(CYLTabBarItemAnimationViewProviding)] ? viewProvider : nil;
}

#pragma mark - CYLTabBarItemAnimationFileMatching

- (NSString *)identifier {
    return _identifier;
}

- (NSArray<NSString *> *)fileExtensions {
    return _fileExtensions;
}

- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return _attributeKeys;
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    // [EN] `pathExtension` leaves out the fragment (the options). [CN] `pathExtension` 不包含 fragment（选项）。
    NSString *extension = URL.pathExtension.lowercaseString;
    return extension.length > 0 && [_fileExtensions containsObject:extension];
}

#pragma mark - CYLTabBarItemAnimationViewFactory

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    Class<CYLTabBarItemAnimationViewProviding> provider = self.viewProvider;
    if (!URL || !provider) {
        return nil;
    }
    UIView<CYLTabBarItemAnimationPlayableView> *view = [provider cyl_animationViewWithFileURL:CYLTabBarItemAnimationFileURLFromURL(URL)
                                                                                      options:CYLTabBarItemAnimationOptionsFromURL(URL)
                                                                                  contentMode:contentMode];
    view.frame = CGRectMake(0, 0, size.width, size.height);
    return view;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    // [EN] Every playable view plays the same way, whichever view animator recognizes it.
    // [CN] 所有可播放视图的播放方式相同，无论由哪个视图 animator 识别。
    return [view conformsToProtocol:@protocol(CYLTabBarItemAnimationPlayableView)] ? [[CYLTabBarItemPlayableViewPlayer alloc] initWithAnimationView:view] : nil;
}

@end
