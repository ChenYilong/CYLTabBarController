//
//  CYLTabBarPageRegistry.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarPageRegistry.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>

@implementation CYLTabBarPageRegistry {
    NSMutableDictionary<NSString *, CYLTabBarPageProvider> *_providers;
}

+ (CYLTabBarPageRegistry *)sharedRegistry {
    static CYLTabBarPageRegistry *sharedRegistry = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRegistry = [[CYLTabBarPageRegistry alloc] init];
    });
    return sharedRegistry;
}

- (instancetype)init {
    if (self = [super init]) {
        _providers = [NSMutableDictionary dictionary];
    }
    return self;
}

/// [EN] A non-empty ID with surrounding spaces removed, or nil. [CN] 去掉首尾空白后的非空 ID，否则为 nil。
static NSString *_Nullable CYLPageIdentifierValue(id pageIdentifier) {
    if (![pageIdentifier isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *trimmed = [(NSString *)pageIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length > 0 ? trimmed : nil;
}

- (void)registerPageProvider:(CYLTabBarPageProvider)provider forPageIdentifier:(NSString *)pageIdentifier {
    NSString *identifier = CYLPageIdentifierValue(pageIdentifier);
    if (!identifier || !provider) {
        return;
    }
    @synchronized (self) {
        _providers[identifier] = [provider copy];
    }
}

- (void)registerPageProvider:(CYLTabBarPageProvider)provider forPageIdentifiers:(NSArray<NSString *> *)pageIdentifiers {
    if (![pageIdentifiers isKindOfClass:[NSArray class]]) {
        return;
    }
    for (NSString *pageIdentifier in pageIdentifiers) {
        [self registerPageProvider:provider forPageIdentifier:pageIdentifier];
    }
}

- (void)unregisterPageIdentifier:(NSString *)pageIdentifier {
    NSString *identifier = CYLPageIdentifierValue(pageIdentifier);
    if (!identifier) {
        return;
    }
    @synchronized (self) {
        [_providers removeObjectForKey:identifier];
    }
}

- (void)removeAllPageProviders {
    @synchronized (self) {
        [_providers removeAllObjects];
    }
}

- (CYLTabBarPageProvider)pageProviderForPageIdentifier:(NSString *)pageIdentifier {
    NSString *identifier = CYLPageIdentifierValue(pageIdentifier);
    if (!identifier) {
        return nil;
    }
    @synchronized (self) {
        return _providers[identifier];
    }
}

- (NSArray<NSString *> *)registeredPageIdentifiers {
    @synchronized (self) {
        return [_providers.allKeys sortedArrayUsingSelector:@selector(compare:)];
    }
}

/// [EN] Whether a loaded image belongs to the system (not scanned). [CN] 已加载的镜像是否属于系统（不扫描）。
static BOOL CYLIsSystemImage(const char *path) {
    return path == NULL || strstr(path, "/System/Library/") != NULL || strstr(path, "/usr/lib/") != NULL
        || strstr(path, "/Developer/Library/") != NULL;
}

/*!
 * [EN] Scans the classes of the app's own images for `CYLTabBarPage`. `class_conformsToProtocol` and
 *      `class_getClassMethod` read the class without sending it a message, so no `+initialize` runs during the scan.
 * [CN] 在 App 自身镜像的类中查找 `CYLTabBarPage`。`class_conformsToProtocol` 与 `class_getClassMethod` 只读取类信息，不向类发送消息，
 *      扫描时不会触发 `+initialize`。
 */
static NSDictionary<NSString *, Class> *CYLScanPageClasses(void) {
    NSMutableArray<Class> *pageClasses = [NSMutableArray array];
    Protocol *pageProtocol = @protocol(CYLTabBarPage);
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imagePath = _dyld_get_image_name(index);
        if (CYLIsSystemImage(imagePath)) {
            continue;
        }
        unsigned int classCount = 0;
        const char **classNames = objc_copyClassNamesForImage(imagePath, &classCount);
        for (unsigned int classIndex = 0; classIndex < classCount; classIndex++) {
            Class aClass = objc_getClass(classNames[classIndex]);
            if (aClass && class_conformsToProtocol(aClass, pageProtocol)
                && class_getClassMethod(aClass, @selector(cylTabBarPageIdentifier))) {
                [pageClasses addObject:aClass];
            }
        }
        free(classNames);
    }
    [pageClasses sortUsingComparator:^NSComparisonResult(Class first, Class second) {
        return [NSStringFromClass(first) compare:NSStringFromClass(second)];
    }];
    NSMutableDictionary<NSString *, Class> *classesByIdentifier = [NSMutableDictionary dictionary];
    for (Class pageClass in pageClasses) {
        NSString *identifier = nil;
        @try {
            identifier = CYLPageIdentifierValue([(Class<CYLTabBarPage>)pageClass cylTabBarPageIdentifier]);
        } @catch (NSException *exception) {
            identifier = nil;
        }
        if (!identifier) {
            continue;
        }
        if (classesByIdentifier[identifier]) {
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🔴 CYLTabBarPageRegistry: %@ and %@ both claim the page ID \"%@\"; %@ is used.",
                  NSStringFromClass(classesByIdentifier[identifier]), NSStringFromClass(pageClass), identifier,
                  NSStringFromClass(classesByIdentifier[identifier]));
#endif
            continue;
        }
        classesByIdentifier[identifier] = pageClass;
    }
    return classesByIdentifier;
}

+ (NSDictionary<NSString *, Class> *)automaticallyRegisteredPageClasses {
    static NSDictionary<NSString *, Class> *pageClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pageClasses = CYLScanPageClasses();
    });
    return pageClasses;
}

@end
