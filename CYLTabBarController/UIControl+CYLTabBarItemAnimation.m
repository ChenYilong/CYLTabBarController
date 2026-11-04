//
//  UIControl+CYLTabBarItemAnimation.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — Core's side of the tab icon animation: it only forwards to the injected
//      `CYLTabBarItemAnimationService`, so Core knows no animation library (dependency inversion), and a new library needs
//      no change here.
// [CN] Core 一侧的 Tab 图标动画：只转发给注入的 `CYLTabBarItemAnimationService`，因此 Core 不认识任何动画库（依赖反转），
//      新增动画库时这里无需修改。

#import "UIControl+CYLTabBarItemAnimation.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "CYLTabBarController.h"

#pragma mark - Service

static id<CYLTabBarItemAnimationService> CYLTabBarItemAnimationCurrentService = nil;

void CYLTabBarItemAnimationSetService(id<CYLTabBarItemAnimationService> service) {
    @synchronized ([UIControl class]) {
        CYLTabBarItemAnimationCurrentService = service;
    }
}

id<CYLTabBarItemAnimationService> CYLTabBarItemAnimationGetService(void) {
    @synchronized ([UIControl class]) {
        return CYLTabBarItemAnimationCurrentService;
    }
}

#pragma mark - Host

/// [EN] Core's side of the engine's needs: the tab bar's state, layout and notifications. [CN] Core 为引擎提供的能力：Tab 栏的状态、布局与通知。
@interface CYLTabBarItemAnimationCoreHost : NSObject <CYLTabBarItemAnimationHost>
@end

@implementation CYLTabBarItemAnimationCoreHost

- (BOOL)isPlusControl:(UIControl *)control {
    return [control cyl_isPlusControl];
}

- (BOOL)isAnimationView:(UIView *)animationView readyInControl:(UIControl *)control {
    CYLTabBarController *tabBarController = control.cyl_tabBarController;
    if (tabBarController.lottieURLs.count > 0) {
        return tabBarController.lottieViewAdded;
    }
    return animationView ? animationView.frame.size.width > 10 : NO;
}

- (CGSize)defaultAnimationSize {
    return CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
}

- (void)showAnimationView:(UIView *)animationView inControl:(UIControl *)control {
    [control cyl_replaceTabImageViewWithNewView:animationView show:YES];
}

- (void)replaceTrackedSubview:(UIView *)view withView:(UIView *)newView inSuperview:(UIView *)superview {
    [superview cyl_replaceTrackedSubview:view withView:newView];
}

- (void)animationViewDidAddInControl:(UIControl *)control {
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationViewDidAddNotification object:control];
}

- (void)animationWillPlayInControl:(UIControl *)control {
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:control];
}

@end

id<CYLTabBarItemAnimationHost> CYLTabBarItemAnimationDefaultHost(void) {
    static CYLTabBarItemAnimationCoreHost *host;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        host = [[CYLTabBarItemAnimationCoreHost alloc] init];
    });
    return host;
}

#pragma mark - Attributes

// [EN] FIX: issue #604 — Core's reading and writing of the animation keys of tab item attributes, kept here with Core's
//      other animation code rather than in CYLTabBarController.m.
// [CN] Core 对 Tab item 属性中动画 key 的读写，与 Core 其他动画代码放在一起，而不是放在 CYLTabBarController.m 中。

/// [EN] Shared by `CYLTabBarItemsAttributesAddingLottieFiles` ("json") and `CYLTabBarItemAttributesAddingAnimationFile`
///      (any library, #477).
/// [CN] 由 `CYLTabBarItemsAttributesAddingLottieFiles`（"json"）与 `CYLTabBarItemAttributesAddingAnimationFile`（任意动画库，#477）共用。
static NSArray<NSDictionary *> *CYLTabBarItemsAttributesAddingFilesOfType(NSArray<NSDictionary *> *attributes,
                                                                             NSArray<NSString *> *lottieFileNames,
                                                                             NSBundle *bundle,
                                                                             NSString *fileType,
                                                                             NSString *filePathKey,
                                                                             NSString *darkFilePathKey) {
    if (lottieFileNames.count == 0) {
        return attributes;
    }
    bundle = bundle ?: [NSBundle mainBundle];
    NSString *darkSuffix = [UIImage cyl_darkImageNameSuffix];
    NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:attributes.count];
    [attributes enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)stop;
        // FIX: issue #477 — an empty name or `NSNull` leaves that tab without an animation (it used to crash on NSNull).
        // 空名称或 `NSNull` 表示该 Tab 没有动画（以前遇到 NSNull 会崩溃）。
        id rawName = idx < lottieFileNames.count ? lottieFileNames[idx] : nil;
        NSString *name = [rawName isKindOfClass:[NSString class]] ? rawName : nil;
        NSString *path = name.length > 0 ? [bundle pathForResource:name ofType:fileType] : nil;
        if (!path) {
            [result addObject:item];
            return;
        }
        NSMutableDictionary *lottieItem = [item mutableCopy];
        lottieItem[filePathKey] = path;
        NSString *darkPath = darkSuffix.length > 0 ? [bundle pathForResource:[name stringByAppendingString:darkSuffix] ofType:fileType] : nil;
        if (darkPath) {
            lottieItem[darkFilePathKey] = darkPath;
        }
        [result addObject:[lottieItem copy]];
    }];
    return [result copy];
}

NSArray<NSDictionary *> *CYLTabBarItemsAttributesAddingLottieFiles(NSArray<NSDictionary *> *attributes,
                                                                    NSArray<NSString *> *lottieFileNames,
                                                                    NSBundle *bundle) {
    return CYLTabBarItemsAttributesAddingFilesOfType(attributes, lottieFileNames, bundle, @"json",
                                                        CYLTabBarLottieFilePath, CYLTabBarLottieDarkFilePath);
}

/// [EN] The format is read back by `CYLTabBarItemViewAnimator` (the `CYLTabBarItemAnimation` subspec).
/// [CN] 该格式由 `CYLTabBarItemViewAnimator`（`CYLTabBarItemAnimation` 子库）读取。
NSURL *CYLTabBarAnimationURLWithOptions(NSURL *fileURL, NSDictionary<CYLTabBarAnimationOption, NSString *> *options) {
    if (![fileURL isKindOfClass:[NSURL class]]) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:fileURL resolvingAgainstBaseURL:YES];
    if (!components) {
        return nil;
    }
    // [EN] "name=value&…", percent-encoded so that a name or a value may hold any character ("&", "=", "#", spaces…).
    //      Sorted by name, so the same options always give the same URL (it is also the key of its Dark Mode version).
    // [CN] 「名称=值&…」，经过百分号编码，名称和值可以包含任意字符（"&"、"="、"#"、空格等）。按名称排序，相同的选项总是得到相同的 URL
    //      （URL 也是其深色模式版本的 key）。
    NSMutableCharacterSet *allowed = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowed removeCharactersInString:@"&=+#?"];
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    // [EN] Only string names and values; anything else is ignored. [CN] 只接受字符串名称和值，其他类型忽略。
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if ([options isKindOfClass:[NSDictionary class]]) {
        for (id name in options) {
            id value = options[name];
            if ([name isKindOfClass:[NSString class]] && [(NSString *)name length] > 0 &&
                [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) {
                [names addObject:name];
            }
        }
    }
    [names sortUsingSelector:@selector(compare:)];
    for (NSString *name in names) {
        NSString *encodedName = [name stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        NSString *encodedValue = [options[name] stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        if (encodedName.length > 0 && encodedValue.length > 0) {
            [items addObject:[NSString stringWithFormat:@"%@=%@", encodedName, encodedValue]];
        }
    }
    components.percentEncodedFragment = items.count > 0 ? [items componentsJoinedByString:@"&"] : nil;
    return components.URL;
}

NSDictionary *CYLTabBarItemAttributesAddingAnimationFile(NSDictionary *attributes, NSString *fileName, NSBundle *bundle) {
    if (![attributes isKindOfClass:[NSDictionary class]] || ![fileName isKindOfClass:[NSString class]] || fileName.length == 0) {
        return attributes;
    }
    bundle = bundle ?: [NSBundle mainBundle];
    // [EN] FIX: issue #604 — the file extensions of the libraries in the build, in lookup order, so that a library added
    //      later works here with no change. "name.ext": that file; "name": the first extension whose file exists.
    // [CN] 构建中各动画库的文件扩展名（按查找顺序），以后新增的动画库在这里无需修改即可使用。「名称.扩展名」：该文件；「名称」：第一个存在对应
    //      文件的扩展名。
    NSArray<NSString *> *extensions = [CYLTabBarItemAnimationGetService() animationFileExtensions];
    NSString *extension = fileName.pathExtension.lowercaseString;
    NSString *name = fileName;
    NSString *fileType = nil;
    if (extension.length > 0 && [extensions containsObject:extension]) {
        name = fileName.stringByDeletingPathExtension;
        fileType = extension;
    } else {
        for (NSString *candidate in extensions) {
            if ([bundle pathForResource:fileName ofType:candidate]) {
                fileType = candidate;
                break;
            }
        }
    }
    if (!fileType) {
        return attributes;
    }
    NSArray<NSDictionary *> *result = CYLTabBarItemsAttributesAddingFilesOfType(@[attributes], @[name], bundle, fileType,
                                                                               CYLTabBarAnimationFilePath, CYLTabBarAnimationDarkFilePath);
    return result.firstObject ?: attributes;
}

NSArray<NSDictionary *> *CYLTabBarItemsAttributesAddingAnimationFiles(NSArray<NSDictionary *> *attributes,
                                                                       NSArray *fileNames,
                                                                       NSBundle *bundle) {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:attributes.count];
    [attributes enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)stop;
        id fileName = idx < fileNames.count ? fileNames[idx] : nil;
        [result addObject:[fileName isKindOfClass:[NSString class]] ? CYLTabBarItemAttributesAddingAnimationFile(item, fileName, bundle) : item];
    }];
    return [result copy];
}

/// FIX: issue #442 — registers the item's dark Lottie animation (`CYLTabBarLottieDarkURL`, else
/// `CYLTabBarLottieDarkFilePath`) for `lottieURL`, the light one. 为浅色动画 `lottieURL` 注册该 item 的深色 Lottie 动画。
static void CYLRegisterDarkLottieURLFromAttributes(NSURL *lottieURL, NSDictionary *attributes) {
    if (!lottieURL) {
        return;
    }
    // First: the #442 keys and whether their values are usable. Without any, and with nothing registered before for this
    // animation, nothing else runs. 首先判断 #442 新增的 key 是否存在、值是否有效；都没有且此前也未注册时，直接返回。
    // FIX: issue #604 — generic keys, or the keys of the libraries in the build (`CYLTabBarItemAttributesAnimationValue`).
    // 通用 key，或构建中各动画库的 key。
    id darkURLValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationDarkURL);
    id darkFilePathValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationDarkFilePath);
    id darkColorsValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationDarkColors);
    NSURL *darkLottieURL = [darkURLValue isKindOfClass:[NSURL class]] ? darkURLValue : nil;
    if (!darkLottieURL && [darkFilePathValue isKindOfClass:[NSString class]] && [(NSString *)darkFilePathValue length] > 0) {
        darkLottieURL = [CYLConstants cyl_getURLFromString:darkFilePathValue];
    }
    NSDictionary *darkColors = ([darkColorsValue isKindOfClass:[NSDictionary class]] && [(NSDictionary *)darkColorsValue count] > 0) ? darkColorsValue : nil;
    if (!darkLottieURL && !darkColors && ![CYLConstants cyl_hasDarkLottieForLottieURL:lottieURL]) {
        return;
    }
    // [EN] The dark version is played by the same library as the light one. [CN] 深色版本与浅色版本由同一个动画库播放。
    [CYLTabBarItemAnimationGetService() bindAnimationURL:darkLottieURL toAttributes:attributes];
    [CYLConstants cyl_registerDarkLottieURL:darkLottieURL forLottieURL:lottieURL];
    [CYLConstants cyl_registerLottieDarkColors:darkColors forLottieURL:lottieURL];
}

/*!
 * [EN] The animation file of a tab item (`…URL`, else `…FilePath`, with `filePath` set to the latter), bound to the
 *      library its keys choose (e.g. `CYLTabBarRiveURL`) rather than to its extension, with its Dark Mode version (#442).
 * [CN] Tab item 的动画文件（`…URL`，否则为 `…FilePath`，并把后者写入 `filePath`），绑定到其 key 选择的动画库（例如 `CYLTabBarRiveURL`），
 *      而不是由扩展名决定，并注册其深色模式版本（#442）。
 */
NSURL *CYLTabBarItemAnimationURLFromAttributes(NSDictionary *attributes, NSString * __autoreleasing *filePath) {
    id URLValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationURL);
    id filePathValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationFilePath);
    NSString *animationFilePath = [filePathValue isKindOfClass:[NSString class]] ? filePathValue : nil;
    if (filePath) {
        *filePath = animationFilePath;
    }
    NSURL *animationURL = [URLValue isKindOfClass:[NSURL class]] ? URLValue : [CYLConstants cyl_getURLFromString:animationFilePath];
    [CYLTabBarItemAnimationGetService() bindAnimationURL:animationURL toAttributes:attributes];
    CYLRegisterDarkLottieURLFromAttributes(animationURL, attributes);
    return animationURL;
}

id CYLTabBarItemAttributesAnimationValue(NSDictionary *attributes, NSString *genericKey) {
    if (![attributes isKindOfClass:[NSDictionary class]] || genericKey.length == 0) {
        return nil;
    }
    id value = attributes[genericKey];
    if (value) {
        return value;
    }
    // [EN] The key of the library the tab's keys choose, e.g. `CYLTabBarRiveURL`; never another library's key.
    // [CN] Tab 的 key 所选择的动画库的 key，例如 `CYLTabBarRiveURL`；不会取其他动画库的 key。
    NSString *key = [CYLTabBarItemAnimationGetService() attributeKeyForGenericKey:genericKey inAttributes:attributes];
    return key ? attributes[key] : nil;
}

#pragma mark - Categories

@implementation UIControl (CYLTabBarItemAnimation)

- (UIView *)cyl_tabBarItemAnimationView {
    return [CYLTabBarItemAnimationGetService() animationViewInControl:self];
}

- (BOOL)cyl_isTabBarItemAnimationReady {
    return [CYLTabBarItemAnimationGetService() isAnimationReadyInControl:self];
}

- (void)cyl_addTabBarItemAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    [CYLTabBarItemAnimationGetService() addAnimationWithURL:URL size:size contentMode:contentMode animationSpeed:0 toControl:self];
}

- (void)cyl_addTabBarItemAnimationWithURL:(NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode
                           animationSpeed:(CGFloat)animationSpeed {
    [CYLTabBarItemAnimationGetService() addAnimationWithURL:URL size:size contentMode:contentMode animationSpeed:animationSpeed toControl:self];
}

- (void)cyl_setTabBarItemAnimationSpeed:(CGFloat)animationSpeed {
    [CYLTabBarItemAnimationGetService() setAnimationSpeed:animationSpeed inControl:self];
}

- (void)cyl_reloadTabBarItemAnimationViewForCurrentStyle {
    [CYLTabBarItemAnimationGetService() reloadAnimationForCurrentStyleInControl:self];
}

- (void)cyl_playTabBarItemAnimationWithURL:(NSURL *)URL
                                      size:(CGSize)size
                           defaultSelected:(BOOL)defaultSelected
                               contentMode:(UIViewContentMode)contentMode {
    [CYLTabBarItemAnimationGetService() playAnimationWithURL:URL size:size defaultSelected:defaultSelected contentMode:contentMode inControl:self];
}

- (void)cyl_stopTabBarItemAnimation {
    [CYLTabBarItemAnimationGetService() stopAnimationInControl:self];
}

@end

@implementation UIView (CYLTabBarItemAnimation)

- (BOOL)cyl_isTabBarItemAnimationView {
    return [CYLTabBarItemAnimationGetService() isAnimationView:self];
}

@end

@implementation CYLTabBar (CYLTabBarItemAnimation)

- (void)cyl_playTabBarItemAnimationWithSelectedControl:(UIControl *)selectedControl
                                                   URL:(NSURL *)URL
                                                  size:(CGSize)size
                                       defaultSelected:(BOOL)defaultSelected
                                           contentMode:(UIViewContentMode)contentMode {
    if (!URL) {
        return;
    }
    // [CN] 统一使用CYLTabBarItemLottieAnimationPlayingNotification进行动画重置， 故删除手动重置。
    // [EN] Animation reset is handled uniformly via CYLTabBarItemLottieAnimationPlayingNotification, so the manual reset
    //      was removed.
    [selectedControl cyl_playTabBarItemAnimationWithURL:URL size:size defaultSelected:defaultSelected contentMode:contentMode];
}

- (void)cyl_stopAllTabBarItemAnimations {
    [self.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cyl_stopTabBarItemAnimation];
    }];
    [self.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cyl_stopTabBarItemAnimation];
    }];
}

@end
