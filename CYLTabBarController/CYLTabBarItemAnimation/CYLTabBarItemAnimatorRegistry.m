//
//  CYLTabBarItemAnimatorRegistry.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimatorRegistry.h"
#if __has_include("../CYLUtils/CYLAnimationKeys.h")
#import "../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif

NSNotificationName const CYLTabBarItemAnimatorRegistryDidChangeNotification = @"CYLTabBarItemAnimatorRegistryDidChangeNotification";
NSString *const CYLTabBarItemAnimatorRegistryIdentifierKey = @"CYLTabBarItemAnimatorRegistryIdentifierKey";

/// [EN] `+logsRegistrationReportOnLaunch`, default YES. [CN] `+logsRegistrationReportOnLaunch`，默认 YES。
static BOOL CYLTabBarItemAnimatorRegistryLogsOnLaunch = YES;

/// [EN] YES when `attributes` give a value for one of `animator`'s own keys. [CN] `attributes` 为 `animator` 自己的某个 key 提供了值时返回 YES。
static BOOL CYLTabBarItemAnimatorKeysHaveValue(id<CYLTabBarItemAnimator> animator, NSDictionary *attributes) {
    if (![animator respondsToSelector:@selector(attributeKeys)]) {
        return NO;
    }
    for (NSString *key in animator.attributeKeys.allValues) {
        if ([key isKindOfClass:[NSString class]] && key.length > 0 && attributes[key] != nil) {
            return YES;
        }
    }
    return NO;
}

static CYLTabBarItemAnimatorPriority CYLTabBarItemAnimatorPriorityOf(id<CYLTabBarItemAnimator> animator) {
    return [animator respondsToSelector:@selector(priority)] ? animator.priority : CYLTabBarItemAnimatorPriorityDefault;
}

@implementation CYLTabBarItemAnimatorRegistry {
    /// [EN] The animators in registration order; under `@synchronized (self)`. [CN] 按注册顺序保存的 animator；在 `@synchronized (self)` 下读写。
    NSMutableArray<id<CYLTabBarItemAnimator>> *_registeredAnimators;
    /// [EN] URL (absolute string) -> identifier of the animator a tab's keys chose for it; under `@synchronized (self)`.
    /// [CN] URL（absoluteString）-> Tab 的 key 为其选择的 animator 名称；在 `@synchronized (self)` 下读写。
    NSMutableDictionary<NSString *, NSString *> *_boundIdentifiers;
}

+ (instancetype)sharedRegistry {
    static CYLTabBarItemAnimatorRegistry *sharedRegistry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRegistry = [[self alloc] init];
#if defined(DEBUG)
        // [EN] Runs once the main queue runs, after every engine's +load registered itself.
        // [CN] 主队列开始运行后执行，此时每个引擎都已在 +load 中完成注册。
        dispatch_async(dispatch_get_main_queue(), ^{
            if (CYLTabBarItemAnimatorRegistryLogsOnLaunch) {
                NSLog(@"%@", [sharedRegistry registrationReport]);
            }
        });
#endif
    });
    return sharedRegistry;
}

- (instancetype)init {
    if (self = [super init]) {
        _registeredAnimators = [NSMutableArray array];
        _boundIdentifiers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Class methods (the shared registry) 类方法（共享注册表）

+ (void)registerAnimator:(id<CYLTabBarItemAnimator>)animator {
    [[self sharedRegistry] registerAnimator:animator];
}

+ (void)unregisterAnimatorWithIdentifier:(NSString *)identifier {
    [[self sharedRegistry] unregisterAnimatorWithIdentifier:identifier];
}

+ (NSArray<id<CYLTabBarItemAnimator>> *)animators {
    return [[self sharedRegistry] animators];
}

+ (id<CYLTabBarItemAnimator>)animatorWithIdentifier:(NSString *)identifier {
    return [[self sharedRegistry] animatorWithIdentifier:identifier];
}

+ (id<CYLTabBarItemAnimator>)animatorForURL:(NSURL *)URL {
    return [[self sharedRegistry] animatorForURL:URL];
}

+ (id<CYLTabBarItemAnimator>)animatorForAttributes:(NSDictionary *)attributes {
    return [[self sharedRegistry] animatorForAttributes:attributes];
}

+ (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes {
    return [[self sharedRegistry] attributeKeyForGenericKey:genericKey inAttributes:attributes];
}

+ (void)bindURL:(NSURL *)URL toAnimator:(id<CYLTabBarItemAnimator>)animator {
    [[self sharedRegistry] bindURL:URL toAnimator:animator];
}

+ (NSArray<NSString *> *)attributeKeysForGenericKey:(NSString *)genericKey {
    return [[self sharedRegistry] attributeKeysForGenericKey:genericKey];
}

+ (NSArray<NSString *> *)fileExtensions {
    return [[self sharedRegistry] fileExtensions];
}

+ (NSArray<NSString *> *)registeredIdentifiers {
    return [[self sharedRegistry] registeredIdentifiers];
}

+ (BOOL)isAnimatorRegisteredWithIdentifier:(NSString *)identifier {
    return [[self sharedRegistry] isAnimatorRegisteredWithIdentifier:identifier];
}

+ (NSArray<NSString *> *)missingKnownIdentifiers {
    return [[self sharedRegistry] missingKnownIdentifiers];
}

+ (NSArray<NSString *> *)conflictDescriptions {
    return [[self sharedRegistry] conflictDescriptions];
}

+ (NSString *)registrationReport {
    return [[self sharedRegistry] registrationReport];
}

+ (void)logRegistrationReport {
    NSLog(@"%@", [self registrationReport]);
}

+ (BOOL)logsRegistrationReportOnLaunch {
    return CYLTabBarItemAnimatorRegistryLogsOnLaunch;
}

+ (void)setLogsRegistrationReportOnLaunch:(BOOL)logsRegistrationReportOnLaunch {
    CYLTabBarItemAnimatorRegistryLogsOnLaunch = logsRegistrationReportOnLaunch;
}

#pragma mark - CYLTabBarItemAnimatorRegistering

- (void)registerAnimator:(id<CYLTabBarItemAnimator>)animator {
    if (![animator conformsToProtocol:@protocol(CYLTabBarItemAnimator)] || animator.identifier.length == 0) {
        return;
    }
    id<CYLTabBarItemAnimator> replaced = nil;
    @synchronized (self) {
        NSMutableArray<id<CYLTabBarItemAnimator>> *animators = _registeredAnimators;
        NSUInteger index = [animators indexOfObjectPassingTest:^BOOL(id<CYLTabBarItemAnimator> obj, NSUInteger idx, BOOL *stop) {
            return [obj.identifier isEqualToString:animator.identifier];
        }];
        if (index == NSNotFound) {
            [animators addObject:animator];
        } else {
            replaced = animators[index];
            [animators replaceObjectAtIndex:index withObject:animator];
        }
    }
#if defined(DEBUG)
    if (replaced && [replaced class] != [animator class]) {
        NSLog(@"⚠️ [CYLAnimatedItem] The animator %@ (%@) replaces %@ (%@), registered earlier with the same identifier.",
              animator.identifier, NSStringFromClass([animator class]), replaced.identifier, NSStringFromClass([replaced class]));
    }
    for (NSString *conflict in [self conflictDescriptionsForAnimator:animator]) {
        NSLog(@"⚠️ [CYLAnimatedItem] %@", conflict);
    }
#endif
    [self cyl_postDidChangeWithIdentifier:animator.identifier];
}

- (void)cyl_postDidChangeWithIdentifier:(NSString *)identifier {
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemAnimatorRegistryDidChangeNotification
                                                        object:self
                                                      userInfo:@{ CYLTabBarItemAnimatorRegistryIdentifierKey : identifier }];
}

- (void)unregisterAnimatorWithIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableArray<id<CYLTabBarItemAnimator>> *animators = _registeredAnimators;
        NSIndexSet *indexes = [animators indexesOfObjectsPassingTest:^BOOL(id<CYLTabBarItemAnimator> obj, NSUInteger idx, BOOL *stop) {
            return [obj.identifier isEqualToString:identifier];
        }];
        if (indexes.count == 0) {
            return;
        }
        [animators removeObjectsAtIndexes:indexes];
    }
    [self cyl_postDidChangeWithIdentifier:identifier];
}

- (NSArray<id<CYLTabBarItemAnimator>> *)animators {
    NSArray<id<CYLTabBarItemAnimator>> *animators;
    @synchronized (self) {
        animators = [_registeredAnimators copy];
    }
    // A stable sort: equal priorities keep their registration order. 稳定排序：相同优先级保持注册顺序。
    return [animators sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id<CYLTabBarItemAnimator> a, id<CYLTabBarItemAnimator> b) {
        CYLTabBarItemAnimatorPriority priorityA = CYLTabBarItemAnimatorPriorityOf(a);
        CYLTabBarItemAnimatorPriority priorityB = CYLTabBarItemAnimatorPriorityOf(b);
        if (priorityA == priorityB) {
            return NSOrderedSame;
        }
        return priorityA > priorityB ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (id<CYLTabBarItemAnimator>)animatorWithIdentifier:(NSString *)identifier {
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if ([animator.identifier isEqualToString:identifier]) {
            return animator;
        }
    }
    return nil;
}

- (id<CYLTabBarItemAnimator>)animatorForURL:(NSURL *)URL {
    if (!URL) {
        return nil;
    }
    // [EN] First: the library a tab's keys chose for this URL, if it is still registered.
    // [CN] 首先：Tab 的 key 为该 URL 选择的动画库（仍已注册时）。
    NSString *boundIdentifier;
    @synchronized (self) {
        boundIdentifier = _boundIdentifiers[URL.absoluteString];
    }
    id<CYLTabBarItemAnimator> boundAnimator = boundIdentifier ? [self animatorWithIdentifier:boundIdentifier] : nil;
    if (boundAnimator) {
        return boundAnimator;
    }
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if ([animator canAnimateFileAtURL:URL]) {
            return animator;
        }
    }
    return nil;
}

- (id<CYLTabBarItemAnimator>)animatorForAttributes:(NSDictionary *)attributes {
    if (![attributes isKindOfClass:[NSDictionary class]] || attributes.count == 0) {
        return nil;
    }
    id<CYLTabBarItemAnimator> chosen = nil;
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if (!CYLTabBarItemAnimatorKeysHaveValue(animator, attributes)) {
            continue;
        }
        if (!chosen) {
            chosen = animator;
            continue;
        }
#if defined(DEBUG)
        NSLog(@"[CYLTabBarController] A tab item uses the keys of both %@ and %@; %@ is used.", chosen.identifier, animator.identifier, chosen.identifier);
#endif
        break;
    }
    return chosen;
}

- (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes {
    id<CYLTabBarItemAnimator> animator = [self animatorForAttributes:attributes];
    if (genericKey.length == 0 || ![animator respondsToSelector:@selector(attributeKeys)]) {
        return nil;
    }
    NSString *key = animator.attributeKeys[genericKey];
    return ([key isKindOfClass:[NSString class]] && key.length > 0) ? key : nil;
}

- (void)bindURL:(NSURL *)URL toAnimator:(id<CYLTabBarItemAnimator>)animator {
    NSString *key = [URL isKindOfClass:[NSURL class]] ? URL.absoluteString : nil;
    if (key.length == 0) {
        return;
    }
    @synchronized (self) {
        _boundIdentifiers[key] = animator.identifier.length > 0 ? animator.identifier : nil;
    }
}

- (NSArray<NSString *> *)attributeKeysForGenericKey:(NSString *)genericKey {
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if (![animator respondsToSelector:@selector(attributeKeys)]) {
            continue;
        }
        NSString *key = animator.attributeKeys[genericKey];
        if ([key isKindOfClass:[NSString class]] && key.length > 0 && ![keys containsObject:key]) {
            [keys addObject:key];
        }
    }
    return [keys copy];
}

- (NSArray<NSString *> *)fileExtensions {
    NSMutableArray<NSString *> *extensions = [NSMutableArray array];
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if (![animator respondsToSelector:@selector(fileExtensions)]) {
            continue;
        }
        for (NSString *extension in animator.fileExtensions) {
            NSString *lowercaseExtension = [extension isKindOfClass:[NSString class]] ? extension.lowercaseString : nil;
            if (lowercaseExtension.length > 0 && ![extensions containsObject:lowercaseExtension]) {
                [extensions addObject:lowercaseExtension];
            }
        }
    }
    return [extensions copy];
}

#pragma mark - Engine status 引擎状态

/// [EN] `animator`'s file extensions, lowercased. [CN] `animator` 的文件扩展名（小写）。
static NSSet<NSString *> *CYLTabBarItemAnimatorExtensionsOf(id<CYLTabBarItemAnimator> animator) {
    NSMutableSet<NSString *> *extensions = [NSMutableSet set];
    if ([animator respondsToSelector:@selector(fileExtensions)]) {
        for (NSString *extension in animator.fileExtensions) {
            if ([extension isKindOfClass:[NSString class]] && extension.length > 0) {
                [extensions addObject:extension.lowercaseString];
            }
        }
    }
    return extensions;
}

- (NSArray<NSString *> *)registeredIdentifiers {
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        [identifiers addObject:animator.identifier];
    }
    return [identifiers copy];
}

- (BOOL)isAnimatorRegisteredWithIdentifier:(NSString *)identifier {
    return identifier.length > 0 && [self animatorWithIdentifier:identifier] != nil;
}

- (NSArray<NSString *> *)missingKnownIdentifiers {
    NSArray<NSString *> *registered = [self registeredIdentifiers];
    NSMutableArray<NSString *> *missing = [NSMutableArray array];
    for (NSString *type in CYLAnimationKnownTypes()) {
        if (![registered containsObject:type]) {
            [missing addObject:type];
        }
    }
    return [missing copy];
}

/// [EN] The conflict between `first` (registered or looked up first) and `second`, or nil: the same priority and a shared
///      file extension. [CN] `first`（先注册或先查找）与 `second` 的冲突，没有时为 nil：优先级相同且有共同的文件扩展名。
static NSString *CYLTabBarItemAnimatorConflict(id<CYLTabBarItemAnimator> first, id<CYLTabBarItemAnimator> second) {
    CYLTabBarItemAnimatorPriority priority = CYLTabBarItemAnimatorPriorityOf(first);
    if ([first.identifier isEqualToString:second.identifier] || CYLTabBarItemAnimatorPriorityOf(second) != priority) {
        return nil;
    }
    NSMutableSet<NSString *> *shared = [CYLTabBarItemAnimatorExtensionsOf(first) mutableCopy];
    [shared intersectSet:CYLTabBarItemAnimatorExtensionsOf(second)];
    if (shared.count == 0) {
        return nil;
    }
    NSString *list = [[shared.allObjects sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", ."];
    return [NSString stringWithFormat:@"%@ and %@ both claim .%@ at priority %ld: %@ plays these files (registered first), and the order of +load is not fixed. Give one of them another priority.",
            first.identifier, second.identifier, list, (long)priority, first.identifier];
}

/// [EN] The conflicts between `animator` and the other registered animators. [CN] `animator` 与其他已注册 animator 的冲突。
- (NSArray<NSString *> *)conflictDescriptionsForAnimator:(id<CYLTabBarItemAnimator>)animator {
    NSMutableArray<NSString *> *conflicts = [NSMutableArray array];
    for (id<CYLTabBarItemAnimator> other in [self animators]) {
        NSString *conflict = CYLTabBarItemAnimatorConflict(other, animator);
        if (conflict) {
            [conflicts addObject:conflict];
        }
    }
    return [conflicts copy];
}

- (NSArray<NSString *> *)conflictDescriptions {
    NSMutableArray<NSString *> *conflicts = [NSMutableArray array];
    NSArray<id<CYLTabBarItemAnimator>> *animators = [self animators];
    for (NSUInteger i = 0; i < animators.count; i++) {
        for (NSUInteger j = i + 1; j < animators.count; j++) {
            NSString *conflict = CYLTabBarItemAnimatorConflict(animators[i], animators[j]);
            if (conflict) {
                [conflicts addObject:conflict];
            }
        }
    }
    return [conflicts copy];
}

- (NSString *)registrationReport {
    NSArray<id<CYLTabBarItemAnimator>> *animators = [self animators];
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [lines addObject:[NSString stringWithFormat:@"[CYLAnimatedItem] Animation engines: %lu registered, in lookup order.", (unsigned long)animators.count]];
    for (id<CYLTabBarItemAnimator> animator in animators) {
        NSArray<NSString *> *extensions = [CYLTabBarItemAnimatorExtensionsOf(animator).allObjects sortedArrayUsingSelector:@selector(compare:)];
        NSString *files = extensions.count > 0 ? [@"." stringByAppendingString:[extensions componentsJoinedByString:@" ."]] : @"(none)";
        [lines addObject:[NSString stringWithFormat:@"  ✅ %@: %@, priority %ld, files %@",
                          animator.identifier, NSStringFromClass([animator class]), (long)CYLTabBarItemAnimatorPriorityOf(animator), files]];
    }
    for (NSString *type in [self missingKnownIdentifiers]) {
        NSString *subspec = CYLAnimationSubspecOfType(type) ?: type;
        [lines addObject:[NSString stringWithFormat:@"  ➖ %@: not in this build. To add it: pod 'CYLAnimatedItem/%@' (with the tab bar: pod 'CYLTabBarController/%@').",
                          type, subspec, subspec]];
    }
    for (NSString *conflict in [self conflictDescriptions]) {
        [lines addObject:[@"  ⚠️ " stringByAppendingString:conflict]];
    }
    return [lines componentsJoinedByString:@"\n"];
}

@end

#pragma mark - Lottie documents

/// [EN] The largest local file read to tell whether it is a Lottie document. [CN] 判断是否为 Lottie 文档时读取的最大本地文件。
static const unsigned long long CYLTabBarItemAnimationLottieMaximumFileSize = 32ull * 1024 * 1024;

BOOL CYLTabBarItemAnimationURLMayBeLottie(NSURL *URL, BOOL acceptsDotLottie) {
    if (!URL) {
        return NO;
    }
    if (!URL.isFileURL) {
        // [EN] Remote: judged once downloaded. [CN] 远程文件：下载后才能判断。
        return YES;
    }
    NSString *path = URL.path;
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    if (!attributes || ![attributes.fileType isEqualToString:NSFileTypeRegular]) {
        return NO;
    }
    unsigned long long size = attributes.fileSize;
    if (size < 2 || size > CYLTabBarItemAnimationLottieMaximumFileSize) {
        return NO;
    }
    static NSCache<NSString *, NSNumber *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 256;
    });
    NSString *cacheKey = [NSString stringWithFormat:@"%@|%llu|%f|%d", path, size,
                          attributes.fileModificationDate.timeIntervalSinceReferenceDate, acceptsDotLottie];
    NSNumber *cached = [cache objectForKey:cacheKey];
    if (cached) {
        return cached.boolValue;
    }
    BOOL isLottie = NO;
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:NULL];
    const unsigned char *bytes = data.bytes;
    if (data.length >= 2 && bytes[0] == 'P' && bytes[1] == 'K') {
        // [EN] A zip archive: a dotLottie file, which only Lottie 4 (LottieSwift) plays. [CN] zip 压缩包：dotLottie 文件，只有 Lottie 4（LottieSwift）能播放。
        isLottie = acceptsDotLottie;
    } else if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        isLottie = [object isKindOfClass:[NSDictionary class]] && [((NSDictionary *)object)[@"layers"] isKindOfClass:[NSArray class]];
    }
    [cache setObject:@(isLottie) forKey:cacheKey];
    return isLottie;
}
