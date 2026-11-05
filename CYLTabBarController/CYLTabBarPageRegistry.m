//
//  CYLTabBarPageRegistry.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarPageRegistry.h"
#import "CYLTabBarController.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>

#pragma mark - CYLTabBarPagePlaceholder

@implementation CYLTabBarPagePlaceholder

- (void)viewDidLoad {
    [super viewDidLoad];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    indicator.color = [UIColor grayColor];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:indicator];
    [NSLayoutConstraint activateConstraints:@[
        [indicator.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
        [indicator.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
    ]];
    [indicator startAnimating];
}

@end

#pragma mark - Page loading state

/// [EN] The pending load behind a placeholder; one per asynchronous factory call. [CN] 占位背后的待完成加载；每次调用异步工厂一个。
@interface CYLTabBarPageLoad : NSObject
@property (nonatomic, weak) UIViewController *placeholder;
@property (nonatomic, strong, nullable) UIViewController *page;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, copy, nullable) void (^handler)(UIViewController *placeholder);
@end

@implementation CYLTabBarPageLoad

/// [EN] Takes the delivered page, once, on the main thread; later calls are ignored. [CN] 在主线程接收交付的页面，只接收一次；之后的调用忽略。
- (void)finishWithPage:(UIViewController *)page {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishWithPage:page];
        });
        return;
    }
    if (self.finished) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🟡 CYLTabBarPageRegistry: the completion of an asynchronous page factory was called again; ignored.");
#endif
        return;
    }
    self.finished = YES;
    self.failed = (page == nil);
    self.page = page;
    UIViewController *placeholder = self.placeholder;
    if (self.handler && placeholder) {
        self.handler(placeholder);
    }
}

@end

static const void *CYLTabBarPageLoadKey = &CYLTabBarPageLoadKey;

@implementation UIViewController (CYLTabBarPageLoading)

- (CYLTabBarPageLoad *)cyl_pageLoad {
    return objc_getAssociatedObject(self, CYLTabBarPageLoadKey);
}

- (BOOL)cyl_isPendingPage {
    CYLTabBarPageLoad *load = [self cyl_pageLoad];
    return load != nil && !load.finished;
}

- (UIViewController *)cyl_loadedPage {
    CYLTabBarPageLoad *load = [self cyl_pageLoad];
    return load.finished ? load.page : nil;
}

- (BOOL)cyl_pageLoadFailed {
    CYLTabBarPageLoad *load = [self cyl_pageLoad];
    return load.finished && load.failed;
}

- (void (^)(UIViewController *))cyl_pageLoadHandler {
    return [self cyl_pageLoad].handler;
}

- (void)setCyl_pageLoadHandler:(void (^)(UIViewController *))handler {
    [self cyl_pageLoad].handler = handler;
}

@end

CYLTabBarPageSource const CYLTabBarPageSourceInstanceRegistry = @"instance";
CYLTabBarPageSource const CYLTabBarPageSourceResolver = @"resolver";
CYLTabBarPageSource const CYLTabBarPageSourceSharedRegistry = @"shared";
CYLTabBarPageSource const CYLTabBarPageSourceAutomaticRegistration = @"automatic";

/// [EN] A non-empty ID with surrounding spaces removed, or nil. [CN] 去掉首尾空白后的非空 ID，否则为 nil。
static NSString *_Nullable CYLPageIdentifierValue(id pageIdentifier) {
    if (![pageIdentifier isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *trimmed = [(NSString *)pageIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length > 0 ? trimmed : nil;
}

#pragma mark - CYLTabBarPageRequest

@implementation CYLTabBarPageRequest

+ (instancetype)requestWithPageIdentifier:(NSString *)pageIdentifier attributes:(NSDictionary<NSString *, id> *)attributes {
    CYLTabBarPageRequest *request = [[self alloc] init];
    request->_pageIdentifier = [pageIdentifier copy] ?: @"";
    NSMutableDictionary<NSString *, id> *publicAttributes = [NSMutableDictionary dictionary];
    if ([attributes isKindOfClass:[NSDictionary class]]) {
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
            // [EN] Private marker keys of the library start with "_". [CN] 库的私有标记键以 "_" 开头。
            if ([key isKindOfClass:[NSString class]] && ![key hasPrefix:@"_"]) {
                publicAttributes[key] = value;
            }
        }];
    }
    request->_attributes = [publicAttributes copy];
    id tabIdentifier = publicAttributes[CYLTabBarItemIdentifier];
    request->_tabIdentifier = [tabIdentifier isKindOfClass:[NSString class]] ? [tabIdentifier copy] : nil;
    id title = publicAttributes[CYLTabBarItemTitle];
    request->_title = [title isKindOfClass:[NSString class]] ? [title copy] : nil;
    id parameters = publicAttributes[CYLTabBarItemPageParameters];
    request->_parameters = [parameters isKindOfClass:[NSDictionary class]] ? [parameters copy] : @{};
    return request;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p page ID \"%@\" tab ID %@ title %@ parameters %@>", NSStringFromClass([self class]), self,
            _pageIdentifier, _tabIdentifier ?: @"nil", _title ?: @"nil", _parameters];
}

@end

#pragma mark - CYLTabBarSkippedTab

@implementation CYLTabBarSkippedTab

+ (instancetype)skippedTabWithReason:(CYLTabBarPageSkipReason)reason
                      pageIdentifier:(NSString *)pageIdentifier
                          attributes:(NSDictionary<NSString *, id> *)attributes
                              detail:(NSString *)detail {
    CYLTabBarSkippedTab *skipped = [[self alloc] init];
    skipped->_reason = reason;
    skipped->_pageIdentifier = [pageIdentifier copy];
    NSDictionary<NSString *, id> *copiedAttributes = [attributes isKindOfClass:[NSDictionary class]] ? [attributes copy] : nil;
    skipped->_attributes = copiedAttributes ?: @{};
    id title = skipped->_attributes[CYLTabBarItemTitle];
    skipped->_title = [title isKindOfClass:[NSString class]] ? [title copy] : nil;
    skipped->_detail = [detail copy];
    return skipped;
}

- (NSString *)description {
    static NSString *const names[] = { @"none", @"invalid tab", @"missing identifier", @"unregistered", @"excluded", @"provider failed" };
    NSUInteger index = (_reason >= CYLTabBarPageSkipReasonInvalidTab && _reason <= CYLTabBarPageSkipReasonProviderFailed) ? (NSUInteger)_reason : 0;
    return [NSString stringWithFormat:@"<%@ %p \"%@\" (page ID %@): %@%@>", NSStringFromClass([self class]), self, _title ?: @"",
            _pageIdentifier ?: @"missing", names[index], _detail ? [@" — " stringByAppendingString:_detail] : @""];
}

@end

#pragma mark - CYLTabBarPageRegistry

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

/// [EN] A provider that calls a factory with a typed request. [CN] 用类型化请求调用工厂的提供者。
static CYLTabBarPageProvider CYLProviderOfFactory(CYLTabBarPageFactory factory) {
    CYLTabBarPageFactory copiedFactory = [factory copy];
    CYLTabBarPageProvider provider = ^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        return copiedFactory([CYLTabBarPageRequest requestWithPageIdentifier:pageIdentifier attributes:tabAttributes]);
    };
    return [provider copy];
}

- (void)registerPageFactory:(CYLTabBarPageFactory)factory forPageIdentifier:(NSString *)pageIdentifier {
    if (!factory) {
        return;
    }
    [self registerPageProvider:CYLProviderOfFactory(factory) forPageIdentifier:pageIdentifier];
}

- (void)registerAsyncPageFactory:(CYLTabBarAsyncPageFactory)factory forPageIdentifier:(NSString *)pageIdentifier {
    if (!factory) {
        return;
    }
    [self registerPageProvider:CYLProviderOfAsyncFactory(factory) forPageIdentifier:pageIdentifier];
}

- (void)registerAsyncPageFactory:(CYLTabBarAsyncPageFactory)factory forPageIdentifiers:(NSArray<NSString *> *)pageIdentifiers {
    if (!factory || ![pageIdentifiers isKindOfClass:[NSArray class]]) {
        return;
    }
    CYLTabBarPageProvider provider = CYLProviderOfAsyncFactory(factory);
    for (NSString *pageIdentifier in pageIdentifiers) {
        [self registerPageProvider:provider forPageIdentifier:pageIdentifier];
    }
}

- (void)registerPageFactory:(CYLTabBarPageFactory)factory forPageIdentifiers:(NSArray<NSString *> *)pageIdentifiers {
    if (!factory || ![pageIdentifiers isKindOfClass:[NSArray class]]) {
        return;
    }
    CYLTabBarPageProvider provider = CYLProviderOfFactory(factory);
    for (NSString *pageIdentifier in pageIdentifiers) {
        [self registerPageProvider:provider forPageIdentifier:pageIdentifier];
    }
}

/*!
 * [EN] A provider that calls an asynchronous factory and returns its placeholder (the factory's, else a
 *      `CYLTabBarPagePlaceholder`) with the pending load attached; the completion finishes the load, once, on the main
 *      thread. A placeholder that is a tab bar controller or already has a parent is replaced by the built-in one.
 * [CN] 调用异步工厂并返回其占位（工厂返回的，否则为 `CYLTabBarPagePlaceholder`）的提供者，占位上附有待完成的加载；completion 在主线程
 *      完成该加载，且只完成一次。占位是 TabBarController 或已有父控制器时，改用内置占位。
 */
static CYLTabBarPageProvider CYLProviderOfAsyncFactory(CYLTabBarAsyncPageFactory factory) {
    CYLTabBarAsyncPageFactory copiedFactory = [factory copy];
    CYLTabBarPageProvider provider = ^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        CYLTabBarPageLoad *load = [[CYLTabBarPageLoad alloc] init];
        CYLTabBarPageCompletion completion = ^(UIViewController *_Nullable page) {
            [load finishWithPage:page];
        };
        UIViewController *placeholder = copiedFactory([CYLTabBarPageRequest requestWithPageIdentifier:pageIdentifier attributes:tabAttributes], completion);
        if (![placeholder isKindOfClass:[UIViewController class]] || [placeholder isKindOfClass:[UITabBarController class]]
            || placeholder.parentViewController || placeholder.presentingViewController) {
#if defined(DEBUG) || defined(BETA)
            if (placeholder) {
                NSLog(@"🟡 CYLTabBarPageRegistry: the placeholder of \"%@\" cannot be a tab (%@); CYLTabBarPagePlaceholder is used.", pageIdentifier, placeholder);
            }
#endif
            placeholder = [[CYLTabBarPagePlaceholder alloc] init];
        }
        load.placeholder = placeholder;
        objc_setAssociatedObject(placeholder, CYLTabBarPageLoadKey, load, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return placeholder;
    };
    return [provider copy];
}

/*!
 * [EN] The page of a `CYLTabBarPage` class: `+cylTabBarPageWithAttributes:`, else `-init`.
 * [CN] `CYLTabBarPage` 类的页面：`+cylTabBarPageWithAttributes:`，否则 `-init`。
 */
static CYLTabBarPageProvider CYLPageProviderOfClass(Class pageClass) {
    CYLTabBarPageProvider provider = ^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        if ([pageClass respondsToSelector:@selector(cylTabBarPageWithAttributes:)]) {
            return [(Class<CYLTabBarPage>)pageClass cylTabBarPageWithAttributes:tabAttributes];
        }
        return [[pageClass alloc] init];
    };
    return [provider copy];
}

/// [EN] The page ID a `CYLTabBarPage` class declares, or nil (also when it raises). [CN] `CYLTabBarPage` 类声明的页面 ID；没有（或抛出异常）则为 nil。
static NSString *_Nullable CYLPageIdentifierOfClass(Class pageClass) {
    if (!pageClass || !class_conformsToProtocol(pageClass, @protocol(CYLTabBarPage))
        || !class_getClassMethod(pageClass, @selector(cylTabBarPageIdentifier))) {
        return nil;
    }
    NSString *identifier = nil;
    @try {
        identifier = CYLPageIdentifierValue([(Class<CYLTabBarPage>)pageClass cylTabBarPageIdentifier]);
    } @catch (NSException *exception) {
        identifier = nil;
    }
    return identifier;
}

- (void)registerPageClass:(Class)pageClass {
    NSString *identifier = CYLPageIdentifierOfClass(pageClass);
    if (!identifier) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴 CYLTabBarPageRegistry: %@ does not adopt CYLTabBarPage with a page ID; not registered.", pageClass ? NSStringFromClass(pageClass) : @"nil");
#endif
        return;
    }
    [self registerPageProvider:CYLPageProviderOfClass(pageClass) forPageIdentifier:identifier];
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

#pragma mark - Automatic registration

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
        NSString *identifier = CYLPageIdentifierOfClass(pageClass);
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

/// [EN] The scan result; nil until the first use or after `+rescanPageClasses`. [CN] 扫描结果；首次使用前或 `+rescanPageClasses` 之后为 nil。
static NSDictionary<NSString *, Class> *_Nullable CYLScannedPageClasses = nil;

+ (NSDictionary<NSString *, Class> *)automaticallyRegisteredPageClasses {
    @synchronized (self) {
        NSDictionary<NSString *, Class> *pageClasses = CYLScannedPageClasses;
        if (!pageClasses) {
            pageClasses = CYLScanPageClasses();
            CYLScannedPageClasses = pageClasses;
        }
        return pageClasses ?: @{};
    }
}

+ (void)rescanPageClasses {
    @synchronized (self) {
        CYLScannedPageClasses = nil;
    }
}

+ (void)prepareAutomaticRegistrationInBackground {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        (void)self.automaticallyRegisteredPageClasses;
    });
}

+ (NSArray<CYLTabBarPageSource> *)defaultPageLookupOrder {
    return @[ CYLTabBarPageSourceInstanceRegistry, CYLTabBarPageSourceResolver, CYLTabBarPageSourceSharedRegistry,
              CYLTabBarPageSourceAutomaticRegistration ];
}

#pragma mark - Lookup

+ (NSString *)pageIdentifierOfTab:(NSDictionary<NSString *, id> *)tabAttributes {
    if (![tabAttributes isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in @[ CYLTabBarItemPageIdentifier, CYLTabBarItemIdentifier ]) {
        NSString *identifier = CYLPageIdentifierValue(tabAttributes[key]);
        if (identifier) {
            return identifier;
        }
    }
    return nil;
}

/*!
 * [EN] Calls a page provider. A provider is app code: an Objective-C exception it raises is caught (C12), and a result
 *      that is not a view controller, is a tab bar controller (no nested tab bars), already belongs to another container
 *      or is already used by another tab of this tab bar controller is refused (C13), so UIKit never moves or nests it.
 *      `problem` receives why, in English.
 * [CN] 调用页面提供者。提供者是 App 代码：它抛出的 Objective-C 异常会被捕获（C12）；结果不是视图控制器、是 TabBarController（不允许嵌套
 *      TabBar）、已属于其他容器或已被本 TabBarController 的其他 Tab 使用时会被拒绝（C13），因此 UIKit 不会移动或嵌套它。
 *      `problem` 收到英文原因。
 */
static UIViewController *_Nullable CYLCallPageProvider(CYLTabBarPageProvider provider, NSString *pageIdentifier, NSDictionary *attributes,
                                                       NSArray<UIViewController *> *usedPages, NSString *source, NSString *_Nullable *_Nonnull problem) {
    id page = nil;
    @try {
        page = provider(pageIdentifier, attributes);
    } @catch (NSException *exception) {
        *problem = [NSString stringWithFormat:@"%@ raised %@ (%@)", source, exception.name, exception.reason ?: @""];
        return nil;
    }
    if (!page) {
        *problem = [NSString stringWithFormat:@"%@ returned nil", source];
        return nil;
    }
    NSString *reason = nil;
    if (![page isKindOfClass:[UIViewController class]]) {
        reason = @"is not a view controller";
    } else if ([page isKindOfClass:[UITabBarController class]]) {
        reason = @"is a tab bar controller (tab bars cannot be nested)";
    } else if ([(UIViewController *)page parentViewController] || [(UIViewController *)page presentingViewController]) {
        reason = @"already belongs to another container (return a new page each time)";
    } else if ([usedPages indexOfObjectIdenticalTo:page] != NSNotFound) {
        reason = @"is already the page of another tab";
    }
    if (reason) {
        *problem = [NSString stringWithFormat:@"the page from %@ %@: %@", source, reason, page];
        return nil;
    }
    return page;
}

+ (NSArray<UIViewController *> *)pagesOfTabs:(NSArray<NSDictionary<NSString *, id> *> *)tabs
                                    registry:(id<CYLTabBarPageProviding>)registry
                                    resolver:(CYLTabBarPageProvider)resolver
                                 lookupOrder:(NSArray<CYLTabBarPageSource> *)lookupOrder
                                    keptTabs:(NSMutableArray<NSDictionary<NSString *, id> *> *)keptTabs
                                     skipped:(NSMutableArray<CYLTabBarSkippedTab *> *)skipped {
    NSArray<CYLTabBarPageSource> *order = [lookupOrder isKindOfClass:[NSArray class]] && lookupOrder.count > 0 ? lookupOrder : [self defaultPageLookupOrder];
    NSMutableArray<UIViewController *> *pages = [NSMutableArray array];
    if (![tabs isKindOfClass:[NSArray class]]) {
        return pages;
    }
    void (^skip)(CYLTabBarPageSkipReason, NSString *_Nullable, NSDictionary *_Nullable, NSString *_Nullable) =
        ^(CYLTabBarPageSkipReason reason, NSString *_Nullable pageIdentifier, NSDictionary *_Nullable attributes, NSString *_Nullable detail) {
            CYLTabBarSkippedTab *skippedTab = [CYLTabBarSkippedTab skippedTabWithReason:reason pageIdentifier:pageIdentifier attributes:attributes detail:detail];
            [skipped addObject:skippedTab];
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🔴 CYLTabBarController: the tab is skipped: %@. Register the ID with CYLTabBarPageRegistry or adopt CYLTabBarPage.", skippedTab);
#endif
        };
    for (id tab in tabs) {
        if (![tab isKindOfClass:[NSDictionary class]]) {
            skip(CYLTabBarPageSkipReasonInvalidTab, nil, nil, [NSString stringWithFormat:@"not a dictionary: %@", tab]);
            continue;
        }
        NSDictionary<NSString *, id> *attributes = tab;
        NSString *pageIdentifier = [self pageIdentifierOfTab:attributes];
        if (!pageIdentifier) {
            skip(CYLTabBarPageSkipReasonMissingIdentifier, nil, attributes, nil);
            continue;
        }
        UIViewController *page = nil;
        NSMutableArray<NSString *> *problems = [NSMutableArray array];
        BOOL found = NO;
        for (CYLTabBarPageSource source in order) {
            CYLTabBarPageProvider provider = nil;
            NSString *sourceName = source;
            if ([source isEqualToString:CYLTabBarPageSourceInstanceRegistry]) {
                provider = [registry pageProviderForPageIdentifier:pageIdentifier];
                sourceName = @"CYLTabBarControllerPageRegistry";
            } else if ([source isEqualToString:CYLTabBarPageSourceResolver]) {
                provider = resolver;
                sourceName = @"CYLTabBarControllerPageResolver";
            } else if ([source isEqualToString:CYLTabBarPageSourceSharedRegistry]) {
                provider = [self.sharedRegistry pageProviderForPageIdentifier:pageIdentifier];
                sourceName = @"sharedRegistry";
            } else if ([source isEqualToString:CYLTabBarPageSourceAutomaticRegistration]) {
                Class pageClass = self.automaticallyRegisteredPageClasses[pageIdentifier];
                if (pageClass) {
                    provider = CYLPageProviderOfClass(pageClass);
                    sourceName = NSStringFromClass(pageClass);
                }
            }
            if (!provider) {
                continue;
            }
            found = YES;
            NSString *problem = nil;
            page = CYLCallPageProvider(provider, pageIdentifier, attributes, pages, sourceName, &problem);
            if (page) {
                break;
            }
            if (problem) {
                [problems addObject:problem];
            }
        }
        if (!page) {
            skip(found ? CYLTabBarPageSkipReasonProviderFailed : CYLTabBarPageSkipReasonUnregistered, pageIdentifier, attributes,
                 problems.count > 0 ? [problems componentsJoinedByString:@"; "] : nil);
            continue;
        }
        NSString *title = attributes[CYLTabBarItemTitle];
        UIViewController *content = [page isKindOfClass:[UINavigationController class]] ? [(UINavigationController *)page viewControllers].firstObject : page;
        if ([title isKindOfClass:[NSString class]] && content && !content.navigationItem.title) {
            content.navigationItem.title = title;
        }
        [pages addObject:page];
        [keptTabs addObject:attributes];
    }
    return pages;
}

@end
