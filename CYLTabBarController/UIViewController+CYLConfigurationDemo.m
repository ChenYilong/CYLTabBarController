//
//  UIViewController+CYLConfigurationDemo.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLConfigurationDemo.h"
#import "CYLTabBarController.h"
#import "CYLLocalization.h"
#import <objc/runtime.h>

NSString *const CYLSampleConfigurationURLString = @"https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations/cyl_tabbar_configuration.yaml";

static NSString *const CYLConfigurationDemoCellIdentifier = @"CYLConfigurationDemoCell";

@interface CYLTabBarController (CYLConfigurationDemo)
- (void)cyl_dismissConfigurationDemo;
@end

@interface UINavigationController (CYLConfigurationTwoTabBarsDemo)
- (void)cyl_dismissTwoTabBarsDemo;
@end

@interface UIViewController (CYLConfigurationDemoPrivate)
- (void)cyl_presentTwoTabBarsDemo;
- (void)cyl_presentConfigurationDemoTabBarController:(nullable CYLTabBarController *)tabBarController
                                              source:(NSString *)source
                                          sourceText:(NSString *)sourceText
                                               error:(nullable NSError *)error;
@end

/// [EN] The text a page shows for its configuration file: the file itself, or the parsed dictionary for a binary file.
/// [CN] 页面显示的配置文件文本：文件本身；二进制文件则显示解析后的字典。
static NSString *CYLConfigurationSourceText(NSString *_Nullable path, NSDictionary *_Nullable configuration) {
    NSString *text = path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] : nil;
    // Binary data (a protobuf message can be valid UTF-8) is shown as the parsed dictionary.
    // 二进制数据（protobuf 消息也可能是合法的 UTF-8）显示为解析后的字典。
    NSMutableCharacterSet *binary = [NSMutableCharacterSet controlCharacterSet];
    [binary removeCharactersInString:@"\t\n\r"];
    if (text.length > 0 && [text rangeOfCharacterFromSet:binary].location == NSNotFound) {
        return text;
    }
    return configuration ? configuration.description : @"";
}

#pragma mark - Demo pages 演示页面

/// [EN] The title of a tab, from its configuration, or its page ID. [CN] Tab 的标题（来自其配置），否则为页面 ID。
static NSString *CYLConfigurationDemoTitle(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
    NSString *title = tabAttributes[CYLTabBarItemTitle];
    return [title isKindOfClass:[NSString class]] && title.length > 0 ? title : pageIdentifier;
}

/// [EN] A demo page: its title and a text, in a navigation controller. [CN] 演示页面：标题与一段文字，包裹在导航控制器中。
static UIViewController *CYLConfigurationDemoPage(NSString *title, NSString *text) {
    UIViewController *page = [[UIViewController alloc] init];
    page.navigationItem.title = title;
    if (@available(iOS 13.0, *)) {
        page.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        page.view.backgroundColor = [UIColor whiteColor];
    }
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = text;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [page.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerYAnchor constraintEqualToAnchor:page.view.centerYAnchor],
        [label.leadingAnchor constraintEqualToAnchor:page.view.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:page.view.trailingAnchor constant:-24],
    ]];
    return [[UINavigationController alloc] initWithRootViewController:page];
}

/*!
 * [EN] The pages of the sample files and the simulated failures, in the shared registry: "home", "message",
 *      "discover", "me", "tab" (one page per call), and "web", which shows the URL of its CYLTabBarItemPageParameters.
 *      An app registers its own pages the same way, once at launch (see docs/Tab-Page-Registry.md).
 * [CN] 示例文件与模拟意外情况使用的页面，注册到全局注册表："home"、"message"、"discover"、"me"、"tab"（每次调用创建一个页面），以及
 *      显示其 CYLTabBarItemPageParameters 中 URL 的 "web"。App 以同样的方式在启动时注册一次自己的页面（见 docs/Tab-Page-Registry.md）。
 */
static void CYLRegisterConfigurationDemoPages(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CYLTabBarPageRegistry *registry = CYLTabBarPageRegistry.sharedRegistry;
        [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
            return CYLConfigurationDemoPage(CYLConfigurationDemoTitle(pageIdentifier, tabAttributes), [NSString stringWithFormat:@"page ID: %@", pageIdentifier]);
        } forPageIdentifiers:@[ @"home", @"message", @"discover", @"me", @"tab" ]];
        [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
            NSDictionary *parameters = tabAttributes[CYLTabBarItemPageParameters];
            NSString *URLString = [parameters[@"url"] isKindOfClass:[NSString class]] ? parameters[@"url"] : @"(no url)";
            return CYLConfigurationDemoPage(CYLConfigurationDemoTitle(pageIdentifier, tabAttributes), [NSString stringWithFormat:@"page ID: %@\nCYLTabBarItemPageParameters.url:\n%@", pageIdentifier, URLString]);
        } forPageIdentifier:@"web"];
    });
}

@implementation UIViewController (CYLConfigurationDemo)

+ (NSArray<NSString *> *)cyl_sampleConfigurationFilePaths {
    NSString *directory = [CYLResourceBundle().resourcePath stringByAppendingPathComponent:@"Configurations"];
    NSArray<NSString *> *names = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL]
                                  sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    NSArray<NSString *> *extensions = [CYLTabBarConfigurationParser supportedPathExtensions];
    for (NSString *name in names) {
        // Configuration files only, not the .proto schema. 只列出配置文件，不包括 .proto 结构定义。
        if (![name hasPrefix:@"."] && [extensions containsObject:name.pathExtension.lowercaseString]) {
            [paths addObject:[directory stringByAppendingPathComponent:name]];
        }
    }
    return paths;
}

- (UITableViewCell *)cyl_configurationDemoCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLConfigurationDemoCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLConfigurationDemoCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"doc.text"];
        }
    }
    cell.textLabel.text = CYLLocalizedString(@"从配置文件创建 TabBarController");
    cell.detailTextLabel.text = CYLLocalizedString(@"一个文件生成整个 TabBar：可选 JSON、YAML、TOML、plist、XML、INI 等格式，或从网络 URL 加载。");
    return cell;
}

- (void)cyl_presentConfigurationDemo {
    CYLRegisterConfigurationDemoPages();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"选择配置文件")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSString *path in [UIViewController cyl_sampleConfigurationFilePaths]) {
        [sheet addAction:[UIAlertAction actionWithTitle:path.lastPathComponent style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSError *error = nil;
            CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfigurationFile:path error:&error];
            NSDictionary *configuration = [CYLTabBarController configurationWithContentsOfFile:path error:NULL];
            [weakSelf cyl_presentConfigurationDemoTabBarController:tabBarController
                                                            source:path.lastPathComponent
                                                        sourceText:CYLConfigurationSourceText(path, configuration)
                                                             error:error];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"从网络 URL 加载") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *URL = [NSURL URLWithString:CYLSampleConfigurationURLString];
        if (!URL) {
            return;
        }
        [CYLTabBarController loadConfigurationWithURL:URL completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
            CYLTabBarController *tabBarController = configuration ? [CYLTabBarController tabBarControllerWithConfiguration:configuration] : nil;
            if (tabBarController.viewControllers.count == 0) {
                tabBarController = nil;
            }
            [weakSelf cyl_presentConfigurationDemoTabBarController:tabBarController
                                                            source:URL.absoluteString
                                                        sourceText:CYLConfigurationSourceText(nil, configuration)
                                                             error:error];
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    // iPad: an action sheet needs an anchor. iPad 上的操作表需要锚点。
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    [self presentViewController:sheet animated:YES completion:nil];
}

/// [EN] Presents the created tab bar controller, each page showing its source, or an alert with the error.
/// [CN] 展示生成的 TabBarController（每个页面显示其来源），或用弹窗显示错误。
- (void)cyl_presentConfigurationDemoTabBarController:(nullable CYLTabBarController *)tabBarController
                                              source:(NSString *)source
                                          sourceText:(NSString *)sourceText
                                               error:(nullable NSError *)error {
    if (!tabBarController) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"无法创建 TabBarController")
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"关闭") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    for (UIViewController *viewController in tabBarController.viewControllers) {
        UIViewController *page = [viewController isKindOfClass:[UINavigationController class]]
            ? [(UINavigationController *)viewController viewControllers].firstObject
            : viewController;
        [self cyl_decorateConfigurationDemoPage:page tabBarController:tabBarController source:source sourceText:sourceText];
    }
    tabBarController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:tabBarController animated:YES completion:nil];
}

- (void)cyl_decorateConfigurationDemoPage:(nullable UIViewController *)page
                         tabBarController:(CYLTabBarController *)tabBarController
                                   source:(NSString *)source
                               sourceText:(NSString *)sourceText {
    if (!page) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        page.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        page.view.backgroundColor = [UIColor whiteColor];
    }
    // [EN] FIX: CI: -initWithTitle:image:primaryAction:menu: does not exist; target / action works on every iOS version.
    // [CN] 修复 CI：-initWithTitle:image:primaryAction:menu: 不存在；target / action 适用于所有 iOS 版本。
    // [EN] The bar button item keeps its target weak, so the tab bar controller is not retained.
    // [CN] UIBarButtonItem 弱引用 target，不会造成循环引用。
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"关闭")
                                                              style:UIBarButtonItemStylePlain
                                                             target:tabBarController
                                                             action:@selector(cyl_dismissConfigurationDemo)];
    page.navigationItem.leftBarButtonItem = close;

    UILabel *header = [[UILabel alloc] init];
    header.numberOfLines = 0;
    header.font = [UIFont boldSystemFontOfSize:15];
    header.text = [NSString stringWithFormat:CYLLocalizedString(@"本页由配置文件 %@ 创建："), source];
    UITextView *textView = [[UITextView alloc] init];
    textView.editable = NO;
    textView.text = sourceText;
    if (@available(iOS 13.0, *)) {
        textView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        textView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    } else {
        textView.font = [UIFont fontWithName:@"Menlo" size:12];
    }
    textView.layer.cornerRadius = 8;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ header, textView ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [page.view addSubview:stack];
    UILayoutGuide *guide = page.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-12],
    ]];
}

@end

#pragma mark - Simulated failures 模拟意外情况

static char CYLConfigurationEdgeCaseResultsKey;
static char CYLConfigurationEdgeCaseTableViewKey;

/// [EN] The cases: @[ID of docs/Configuration-File.md, title]. [CN] 各情况：@[docs/Configuration-File.md 中的编号, 标题]。
static NSArray<NSArray<NSString *> *> *CYLConfigurationEdgeCases(void) {
    return @[
        @[ @"A3", @"Empty file" ], @[ @"A4", @"Comments only" ], @[ @"A13", @"Malformed JSON" ], @[ @"A11", @"Top level is a list" ],
        @[ @"A7", @"YAML in a .json file" ], @[ @"A5", @"Not UTF-8" ], @[ @"A16", @"UTF-16 encoded" ], @[ @"A10", @"Nested 10,000 levels" ],
        @[ @"A9", @"A 6 MB file" ], @[ @"B1", @"No tabs" ], @[ @"D7", @"An HTML page (file)" ], @[ @"B5", @"Wrong types and null" ],
        @[ @"B7", @"NaN and Infinity insets" ], @[ @"B9", @"Unknown style" ], @[ @"C11", @"Unregistered page IDs" ],
        @[ @"C12", @"A page provider raises (code)" ], @[ @"C13", @"Pages that cannot be tabs (code)" ],
        @[ @"C14", @"Automatic registration (CYLTabBarPage)" ], @[ @"C15", @"Registry and resolver of wrong types" ],
        @[ @"C16", @"Two tab bars, one page ID" ], @[ @"C18", @"Lookup order and automatic registration" ],
        @[ @"B22", @"Other platforms and newer versions" ],
        @[ @"B23", @"Invalid platforms, versions and parameters" ], @[ @"B27", @"Reload with new tabs (code)" ],
        @[ @"C20", @"Asynchronous pages (code)" ], @[ @"B28", @"Animation keys, options and speed" ], @[ @"B13", @"Invalid URLs and Lottie files" ],
        @[ @"B12", @"Duplicate identifiers" ], @[ @"B11", @"Misspelled keys" ], @[ @"B19", @"Invalid colors and fonts" ], @[ @"B21", @"Empty strings" ],
        @[ @"A12", @"Truncated protobuf" ],
        @[ @"A12", @"Corrupted binary plist" ], @[ @"A14", @"XML external entity" ], @[ @"A2", @"Missing file" ],
        @[ @"E1", @"Created on a background thread" ], @[ @"C6", @"Non-controllers and duplicates (code)" ],
        @[ @"B18", @"Configuration is not a dictionary (code)" ], @[ @"C9", @"Empty view controller list (code)" ],
        @[ @"D3", @"HTTP 404" ], @[ @"D4", @"Unknown host" ], @[ @"D5", @"Server timeout (3 s)" ], @[ @"D10", @"Request cancelled" ],
        @[ @"C10", @"Request without a URL" ],
        @[ @"D7", @"An HTML page (network)" ],
    ];
}

/// [EN] The English name of a skip reason (an identifier, not translated). [CN] 跳过原因的英文名称（标识符，不翻译）。
static NSString *CYLSkipReasonName(CYLTabBarPageSkipReason reason) {
    switch (reason) {
        case CYLTabBarPageSkipReasonInvalidTab: return @"invalid tab";
        case CYLTabBarPageSkipReasonMissingIdentifier: return @"no page ID";
        case CYLTabBarPageSkipReasonUnregistered: return @"unregistered";
        case CYLTabBarPageSkipReasonExcluded: return @"excluded";
        case CYLTabBarPageSkipReasonProviderFailed: return @"provider failed";
    }
    return @"unknown";
}

/// [EN] Two valid tabs, as JSON. [CN] 两个有效的 Tab（JSON）。
static NSString *const CYLEdgeCaseTabsJSON = @"[{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemIdentifier\": \"home\"}, {\"CYLTabBarItemTitle\": \"Me\", \"CYLTabBarItemImage\": \"system:person\", \"CYLTabBarItemIdentifier\": \"me\"}]";

/// [EN] Writes `data` to a temporary file and returns its path. [CN] 将 `data` 写入临时文件并返回路径。
static NSString *CYLEdgeCaseFile(NSString *name, NSData *data) {
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CYLConfigurationEdgeCases"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *path = [directory stringByAppendingPathComponent:name];
    [data writeToFile:path atomically:YES];
    return path;
}

/// [EN] A request for a URL string, or a request without a URL when the string is not a URL (C10): never a nil URL.
/// [CN] URL 字符串对应的请求；字符串不是 URL 时为没有 URL 的请求（C10）：不会传入 nil URL。
static NSURLRequest *CYLEdgeCaseRequest(NSString *string, NSTimeInterval timeout) {
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        return [[NSURLRequest alloc] init];
    }
    return timeout > 0 ? [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout]
                       : [NSURLRequest requestWithURL:URL];
}

static NSData *CYLEdgeCaseData(NSString *text) {
    return [text dataUsingEncoding:NSUTF8StringEncoding];
}

@implementation UIViewController (CYLConfigurationEdgeCases)

+ (NSString *)cyl_configurationEdgeCaseSectionTitle {
    return CYLLocalizedString(@"配置文件：模拟意外情况");
}

- (NSInteger)cyl_configurationEdgeCaseRowCount {
    return (NSInteger)CYLConfigurationEdgeCases().count;
}

- (NSMutableDictionary<NSNumber *, NSString *> *)cyl_configurationEdgeCaseResults {
    NSMutableDictionary *results = objc_getAssociatedObject(self, &CYLConfigurationEdgeCaseResultsKey);
    if (!results) {
        results = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &CYLConfigurationEdgeCaseResultsKey, results, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return results;
}

- (UITableViewCell *)cyl_configurationEdgeCaseCellForTableView:(UITableView *)tableView row:(NSInteger)row {
    objc_setAssociatedObject(self, &CYLConfigurationEdgeCaseTableViewKey, tableView, OBJC_ASSOCIATION_ASSIGN);
    static NSString *const identifier = @"CYLConfigurationEdgeCaseCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle"];
        }
    }
    NSArray<NSArray<NSString *> *> *cases = CYLConfigurationEdgeCases();
    NSArray<NSString *> *edgeCase = (row >= 0 && row < (NSInteger)cases.count) ? cases[(NSUInteger)row] : @[ @"", @"" ];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ · %@", edgeCase[0], edgeCase[1]];
    cell.detailTextLabel.text = [self cyl_configurationEdgeCaseResults][@(row)];
    return cell;
}

- (void)cyl_runConfigurationEdgeCaseAtRow:(NSInteger)row {
    CYLRegisterConfigurationDemoPages();
    NSArray<NSArray<NSString *> *> *cases = CYLConfigurationEdgeCases();
    if (row < 0 || row >= (NSInteger)cases.count) {
        return;
    }
    NSString *caseID = cases[(NSUInteger)row][0];
    NSString *title = cases[(NSUInteger)row][1];
    NSString *items = CYLEdgeCaseTabsJSON;
    __weak typeof(self) weakSelf = self;
    void (^finish)(CYLTabBarController *, NSError *, NSString *) = ^(CYLTabBarController *tabBarController, NSError *error, NSString *source) {
        [weakSelf cyl_showConfigurationEdgeCaseRow:row title:[NSString stringWithFormat:@"%@ · %@", caseID, title]
                                  tabBarController:tabBarController error:error source:source];
    };
    void (^fromFile)(NSString *, NSData *) = ^(NSString *name, NSData *data) {
        NSString *path = CYLEdgeCaseFile(name, data);
        NSError *error = nil;
        CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfigurationFile:path error:&error];
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        finish(tabBarController, error, text.length > 2000 ? [[text substringToIndex:2000] stringByAppendingString:@"…"] : (text ?: @"(binary)"));
    };
    void (^fromURL)(NSURLRequest *, BOOL) = ^(NSURLRequest *request, BOOL cancel) {
        NSURLSessionDataTask *task = [CYLTabBarController loadTabBarControllerWithConfigurationURLRequest:request completion:^(CYLTabBarController *tabBarController, NSError *error) {
            finish(tabBarController, error, request.URL.absoluteString);
        }];
        if (cancel) {
            [task cancel];
        }
    };
    NSString *json = [NSString stringWithFormat:@"{\"CYLTabBarControllerTabBarItemsAttributes\": %@}", items];
    if ([title isEqualToString:@"Empty file"]) {
        fromFile(@"empty.json", [NSData data]);
    } else if ([title isEqualToString:@"Comments only"]) {
        fromFile(@"comments.yaml", CYLEdgeCaseData(@"# nothing but comments\n# 只有注释\n"));
    } else if ([title isEqualToString:@"Malformed JSON"]) {
        fromFile(@"malformed.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [ {\"CYLTabBarItemTitle\": \"Home\" "));
    } else if ([title isEqualToString:@"Top level is a list"]) {
        fromFile(@"list.json", CYLEdgeCaseData(items));
    } else if ([title isEqualToString:@"YAML in a .json file"]) {
        fromFile(@"yaml.json", CYLEdgeCaseData(@"CYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemIdentifier: home\n  - CYLTabBarItemTitle: Me\n    CYLTabBarItemImage: system:person\n    CYLTabBarItemIdentifier: me\n"));
    } else if ([title isEqualToString:@"Not UTF-8"]) {
        const uint8_t bytes[] = { '{', '"', 0xC3, 0x28, '"', ':', '1', '}' };
        fromFile(@"latin.json", [NSData dataWithBytes:bytes length:sizeof(bytes)]);
    } else if ([title isEqualToString:@"UTF-16 encoded"]) {
        NSMutableData *data = [NSMutableData dataWithBytes:"\xFF\xFE" length:2];
        [data appendData:[json dataUsingEncoding:NSUTF16LittleEndianStringEncoding]];
        fromFile(@"utf16.json", data);
    } else if ([title isEqualToString:@"Nested 10,000 levels"]) {
        NSString *open = [@"" stringByPaddingToLength:10000 withString:@"[" startingAtIndex:0];
        NSString *close = [@"" stringByPaddingToLength:10000 withString:@"]" startingAtIndex:0];
        fromFile(@"deep.json", CYLEdgeCaseData([NSString stringWithFormat:@"{\"CYLTabBarControllerTabBarItemsAttributes\": %@%@}", open, close]));
    } else if ([title isEqualToString:@"A 6 MB file"]) {
        NSMutableData *data = [NSMutableData dataWithLength:6 * 1024 * 1024];
        memset(data.mutableBytes, ' ', data.length);
        fromFile(@"huge.json", data);
    } else if ([title isEqualToString:@"No tabs"]) {
        fromFile(@"no_tabs.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerContext\": \"NoTabs\"}"));
    } else if ([title isEqualToString:@"An HTML page (file)"]) {
        fromFile(@"portal.xml", CYLEdgeCaseData(@"<html><head><title>Wi-Fi</title></head><body><form>Accept</form></body></html>"));
    } else if ([title isEqualToString:@"Wrong types and null"]) {
        fromFile(@"types.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerContext\": [1, 2], \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": [\"a\", \"list\"], \"CYLTabBarItemImage\": null, \"CYLTabBarItemIdentifier\": 7, \"CYLTabBarItemPageIdentifier\": \"home\"}, \"not a tab\", {\"CYLTabBarItemTitle\": 42, \"CYLTabBarItemImage\": {\"a\": 1}, \"CYLTabBarItemIdentifier\": \"me\"}]}"));
    } else if ([title isEqualToString:@"NaN and Infinity insets"]) {
        fromFile(@"nan.yaml", CYLEdgeCaseData(@"CYLTabBarControllerImageInsets: \"{nan, 0, 0, 0}\"\nCYLTabBarControllerTitlePositionAdjustment: [1e999, -3]\nCYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemIdentifier: home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemImageInsets: \"{inf, 0, -inf, 0}\"\n    CYLTabBarLottieSize: \"{-24, 0}\"\n"));
    } else if ([title isEqualToString:@"Unknown style"]) {
        fromFile(@"style.toml", CYLEdgeCaseData(@"CYLTabBarControllerStyleType = 99\n[[CYLTabBarControllerTabBarItemsAttributes]]\nCYLTabBarItemTitle = \"Home\"\nCYLTabBarItemIdentifier = \"home\"\nCYLTabBarItemImage = \"system:house\"\n"));
    } else if ([title isEqualToString:@"Unregistered page IDs"]) {
        // [EN] C11: "home" is registered; "no_such_page" and a tab without any ID are skipped.
        // [CN] C11："home" 已注册；"no_such_page" 与没有任何 ID 的 Tab 会被跳过。
        fromFile(@"unregistered.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemIdentifier\": \"home\"}, {\"CYLTabBarItemTitle\": \"Unknown\", \"CYLTabBarItemPageIdentifier\": \"no_such_page\"}, {\"CYLTabBarItemTitle\": \"No ID\"}]}"));
    } else if ([title isEqualToString:@"A page provider raises (code)"]) {
        CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
        [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
            [NSException raise:NSInternalInconsistencyException format:@"%@", @"a provider that raises"];
            return nil;
        } forPageIdentifier:@"raises"];
        finish([CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerPageRegistry : registry,
            CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"Raises", CYLTabBarItemPageIdentifier : @"raises" },
                                                          @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemIdentifier : @"home" } ],
        }], nil, @"provider of \"raises\": [NSException raise:...]");
    } else if ([title isEqualToString:@"Pages that cannot be tabs (code)"]) {
        // [EN] C13: nil, a string, a tab bar controller, a page inside another navigation controller and one page for two
        //      tabs are refused; only "home" stays.
        // [CN] C13：nil、字符串、TabBarController、已在其他导航控制器中的页面、两个 Tab 共用一个页面都会被拒绝；只保留 "home"。
        UIViewController *shared = [[UIViewController alloc] init];
        UIViewController *owned = [[UIViewController alloc] init];
        UINavigationController *owner = [[UINavigationController alloc] initWithRootViewController:owned];
        NSDictionary<NSString *, UIViewController *(^)(void)> *pages = @{
            @"nil" : ^UIViewController *(void) { return nil; },
            @"string" : ^UIViewController *(void) { return (UIViewController *)(id)@"not a page"; },
            @"tabBar" : ^UIViewController *(void) { return [[UITabBarController alloc] init]; },
            @"owned" : ^UIViewController *(void) { return owner.viewControllers.firstObject; },
            @"sharedA" : ^UIViewController *(void) { return shared; },
            @"sharedB" : ^UIViewController *(void) { return shared; },
        };
        CYLTabBarPageProvider resolver = ^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
            UIViewController *(^page)(void) = pages[pageIdentifier];
            return page ? page() : nil;
        };
        NSMutableArray<NSDictionary *> *attributes = [NSMutableArray array];
        for (NSString *pageIdentifier in @[ @"nil", @"string", @"tabBar", @"owned", @"sharedA", @"sharedB", @"home" ]) {
            [attributes addObject:@{ CYLTabBarItemTitle : pageIdentifier, CYLTabBarItemPageIdentifier : pageIdentifier }];
        }
        finish([CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerPageResolver : resolver,
            CYLTabBarControllerTabBarItemsAttributes : attributes,
        }], nil, @"CYLTabBarControllerPageResolver: nil, a string, a UITabBarController, a page inside a UINavigationController, one page for two tabs");
    } else if ([title isEqualToString:@"Automatic registration (CYLTabBarPage)"]) {
        // [EN] C14: "auto" and "conflict" come from classes that adopt CYLTabBarPage; no registration code.
        // [CN] C14："auto" 与 "conflict" 来自遵守 CYLTabBarPage 的类，无需注册代码。
        fromFile(@"automatic.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Auto\", \"CYLTabBarItemImage\": \"system:wand.and.stars\", \"CYLTabBarItemPageIdentifier\": \"auto\"}, {\"CYLTabBarItemTitle\": \"Conflict\", \"CYLTabBarItemImage\": \"system:exclamationmark.2\", \"CYLTabBarItemPageIdentifier\": \"conflict\"}]}"));
    } else if ([title isEqualToString:@"Registry and resolver of wrong types"]) {
        // [EN] C15: from a file, the registry and the resolver are strings: ignored with a warning; the shared registry is used.
        // [CN] C15：文件中的注册表与解析回调是字符串：忽略并输出警告；使用全局注册表。
        fromFile(@"wrong_registry.json", CYLEdgeCaseData([NSString stringWithFormat:@"{\"CYLTabBarControllerPageRegistry\": \"MyRegistry\", \"CYLTabBarControllerPageResolver\": \"resolve:\", \"CYLTabBarControllerTabBarItemsAttributes\": %@}", items]));
    } else if ([title isEqualToString:@"Two tab bars, one page ID"]) {
        [self cyl_presentTwoTabBarsDemo];
        [self cyl_configurationEdgeCaseResults][@(row)] = CYLLocalizedString(@"两个 TabBar 使用同一份配置，各自的注册表把相同的页面 ID 对应到不同页面。");
    } else if ([title isEqualToString:@"Lookup order and automatic registration"]) {
        // [EN] C18: "shared, bogus" keeps "shared" (the unknown entry is dropped with a warning) and "no" turns automatic
        //      registration off, so "home" (shared registry) stays, "auto" (a CYLTabBarPage class) and "maybe" are skipped
        //      and listed in `cyl_skippedTabs`.
        // [CN] C18："shared, bogus" 保留 "shared"（未知项丢弃并警告），"no" 关闭自动注册：因此 "home"（全局注册表）保留，"auto"
        //      （CYLTabBarPage 类）与 "maybe" 被跳过并记录在 `cyl_skippedTabs` 中。
        fromFile(@"lookup_order.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerPageLookupOrder\": \"shared, bogus\", \"CYLTabBarControllerAutomaticPageRegistration\": \"no\", \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemIdentifier\": \"home\"}, {\"CYLTabBarItemTitle\": \"Auto\", \"CYLTabBarItemPageIdentifier\": \"auto\"}, {\"CYLTabBarItemTitle\": \"Maybe\", \"CYLTabBarItemPageIdentifier\": \"maybe\"}]}"));
    } else if ([title isEqualToString:@"Reload with new tabs (code)"]) {
        // [EN] B27: a controller created from page IDs keeps its sources: `-reloadTabBarItemsWithAttributes:` creates the
        //      page of "message", reuses the page of "home" (same object, state kept) and skips "no_such_page".
        // [CN] B27：由页面 ID 创建的控制器保留页面来源：`-reloadTabBarItemsWithAttributes:` 创建 "message" 的页面、复用 "home" 的页面
        //      （同一对象，状态保留）、跳过 "no_such_page"。
        CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemImage : @"system:house", CYLTabBarItemIdentifier : @"home" },
                                                          @{ CYLTabBarItemTitle : @"Me", CYLTabBarItemImage : @"system:person", CYLTabBarItemIdentifier : @"me" } ],
        }];
        UIViewController *home = tabBarController.viewControllers.firstObject;
        [tabBarController reloadTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"Message", CYLTabBarItemImage : @"system:message", CYLTabBarItemIdentifier : @"message" },
                                                             @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemImage : @"system:house", CYLTabBarItemIdentifier : @"home" },
                                                             @{ CYLTabBarItemTitle : @"Unknown", CYLTabBarItemPageIdentifier : @"no_such_page" } ]];
        BOOL reused = tabBarController.viewControllers.count > 1 && tabBarController.viewControllers[1] == home;
        finish(tabBarController, nil, [NSString stringWithFormat:@"[tabBarController reloadTabBarItemsWithAttributes:@[message, home, no_such_page]]\n// home page reused: %@", reused ? @"YES" : @"NO"]);
    } else if ([title isEqualToString:@"Asynchronous pages (code)"]) {
        // [EN] C20: "later" delivers its page after 2 s (the placeholder is swapped), "never" delivers nil after 2 s (the tab
        //      is removed and listed in `cyl_skippedTabs`); the completion is called twice and off the main thread on purpose.
        // [CN] C20："later" 在 2 秒后交付页面（占位被换入），"never" 在 2 秒后交付 nil（该 Tab 被移除并记录在 `cyl_skippedTabs`）；
        //      故意在非主线程调用两次 completion。
        CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
        [registry registerAsyncPageFactory:^UIViewController *(CYLTabBarPageRequest *request, CYLTabBarPageCompletion completion) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                UIViewController *page = nil;
                if ([request.pageIdentifier isEqualToString:@"later"]) {
                    page = [[UIViewController alloc] init];
                    page.title = request.title;
                    page.view.backgroundColor = [UIColor systemGreenColor];
                }
                completion(page);
                completion(page);
            });
            return nil;
        } forPageIdentifiers:@[ @"later", @"never" ]];
        finish([CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerPageRegistry : registry,
            CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"Later", CYLTabBarItemImage : @"system:clock", CYLTabBarItemPageIdentifier : @"later" },
                                                          @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemImage : @"system:house", CYLTabBarItemIdentifier : @"home" },
                                                          @{ CYLTabBarItemTitle : @"Never", CYLTabBarItemImage : @"system:xmark", CYLTabBarItemPageIdentifier : @"never" } ],
        }], nil, @"registerAsyncPageFactory: \"later\" -> a page after 2 s, \"never\" -> nil after 2 s (the tab is removed)");
    } else if ([title isEqualToString:@"Animation keys, options and speed"]) {
        // [EN] B28 / B29: a Rive URL with options (a library that may not be installed: the tab then shows its image), a
        //      generic animation path of a missing file (dropped), options that are not a dictionary, an invalid speed and
        //      an invalid loop flag (ignored with warnings). The tabs are created in every case.
        // [CN] B28 / B29：带选项的 Rive URL（动画库可能未安装：Tab 显示图片）、指向不存在文件的通用动画路径（丢弃）、不是字典的选项、无效的
        //      速度与无效的循环开关（忽略并警告）。所有情况下 Tab 都会创建。
        fromFile(@"animation.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemAnimationSpeed\": \"fast\", \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarRiveURL\": \"https://example.com/icons.riv\", \"CYLTabBarAnimationOptions\": {\"artboard\": \"HOME\", \"input\": \"active\", \"duration\": 2, \"bad\": [1, 2]}}, {\"CYLTabBarItemTitle\": \"Me\", \"CYLTabBarItemImage\": \"system:person\", \"CYLTabBarItemIdentifier\": \"me\", \"CYLTabBarAnimationFilePath\": \"no_such_animation.pag\", \"CYLTabBarAnimationOptions\": \"not a dictionary\", \"CYLTabBarLottieLoopsWhenUnselected\": \"maybe\"}]}"));
    } else if ([title isEqualToString:@"Other platforms and newer versions"]) {
        // [EN] B22: "android only" and "version 999" are left out on iOS; the other two tabs stay.
        // [CN] B22："仅 Android" 与 "版本 999" 在 iOS 上不显示；其余两个 Tab 保留。
        fromFile(@"platforms.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemPlatforms\": [\"ios\", \"android\"]}, {\"CYLTabBarItemTitle\": \"Android only\", \"CYLTabBarItemIdentifier\": \"message\", \"CYLTabBarItemPlatforms\": \"android\"}, {\"CYLTabBarItemTitle\": \"Version 999\", \"CYLTabBarItemIdentifier\": \"discover\", \"CYLTabBarItemMinimumAppVersion\": \"999.0\"}, {\"CYLTabBarItemTitle\": \"Me\", \"CYLTabBarItemImage\": \"system:person\", \"CYLTabBarItemIdentifier\": \"me\", \"CYLTabBarItemMinimumAppVersion\": \"0.1\"}]}"));
    } else if ([title isEqualToString:@"Invalid platforms, versions and parameters"]) {
        // [EN] B23-B25: a number as platforms, "abc" as a version and a list as page parameters are ignored with warnings.
        // [CN] B23–B25：数字作为平台、"abc" 作为版本、数组作为页面参数，都会被忽略并输出警告。
        fromFile(@"invalid_remote.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemPlatforms\": 42, \"CYLTabBarItemMinimumAppVersion\": \"abc\"}, {\"CYLTabBarItemTitle\": \"Web\", \"CYLTabBarItemImage\": \"system:globe\", \"CYLTabBarItemPageIdentifier\": \"web\", \"CYLTabBarItemPageParameters\": [\"not\", \"a\", \"dictionary\"], \"CYLTabBarItemMinimumAppVersion\": \"2.x\"}]}"));
    } else if ([title isEqualToString:@"Invalid URLs and Lottie files"]) {
        fromFile(@"urls.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemImageURL\": \"javascript:alert(1)\", \"CYLTabBarLottieURL\": \"ftp://example.com/a.json\", \"CYLTabBarLottieFilePath\": \"/no/such/animation.json\", \"CYLTabBarLottieDarkURL\": \"no_such_animation.json\"}]}"));
    } else if ([title isEqualToString:@"Duplicate identifiers"]) {
        fromFile(@"ids.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"A\", \"CYLTabBarItemIdentifier\": \"tab\"}, {\"CYLTabBarItemTitle\": \"B\", \"CYLTabBarItemIdentifier\": \"tab\"}, {\"CYLTabBarItemTitle\": \"C\", \"CYLTabBarItemIdentifier\": \"tab\"}]}"));
    } else if ([title isEqualToString:@"Misspelled keys"]) {
        fromFile(@"typos.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerContxt\": \"typo\", \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitel\": \"Typo\", \"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemImage\": \"system:house\"}]}"));
    } else if ([title isEqualToString:@"Invalid colors and fonts"]) {
        fromFile(@"colors.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemTitleColor\": \"not a color\", \"CYLTabBarItemIconColor\": \"#12345\", \"CYLTabBarItemSelectedTitleColor\": \"#FF3B30\", \"CYLTabBarItemBackgroundColor\": 123, \"CYLTabBarItemTitleFont\": 0, \"CYLTabBarItemSelectedTitleFont\": \"NoSuchFont:12\", \"CYLTabBarItemAccessibilityLabel\": [1, 2]}, {\"CYLTabBarItemTitle\": \"Me\", \"CYLTabBarItemIdentifier\": \"me\", \"CYLTabBarItemImage\": \"system:person\", \"CYLTabBarItemTitleFont\": \"bold:12\", \"CYLTabBarItemSelectedIconColor\": \"#34C759\"}]}"));
    } else if ([title isEqualToString:@"Truncated protobuf"]) {
        const uint8_t bytes[] = { 0x0A, 0x40, 0x0A, 0x04, 'H', 'o', 'm', 'e' };
        fromFile(@"truncated.binpb", [NSData dataWithBytes:bytes length:sizeof(bytes)]);
    } else if ([title isEqualToString:@"Corrupted binary plist"]) {
        NSMutableData *data = [[NSPropertyListSerialization dataWithPropertyList:@{ @"a" : @[ @1 ] } format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL] mutableCopy];
        if (data.length > 9) {
            ((uint8_t *)data.mutableBytes)[data.length - 9] = 0xFF; // the offset table points past the end 偏移表越界
        }
        fromFile(@"corrupted.plist", data ?: [NSData data]);
    } else if ([title isEqualToString:@"XML external entity"]) {
        fromFile(@"xxe.xml", CYLEdgeCaseData(@"<?xml version=\"1.0\"?>\n<!DOCTYPE r [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]>\n<r><CYLTabBarControllerContext>&xxe;</CYLTabBarControllerContext><CYLTabBarControllerTabBarItemsAttributes><item CYLTabBarItemTitle=\"Home\" CYLTabBarItemIdentifier=\"home\" CYLTabBarItemImage=\"system:house\"/></CYLTabBarControllerTabBarItemsAttributes></r>"));
    } else if ([title isEqualToString:@"Missing file"]) {
        NSError *error = nil;
        CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfigurationFile:@"no_such_configuration.yaml" error:&error];
        finish(tabBarController, error, @"no_such_configuration.yaml");
    } else if ([title isEqualToString:@"Created on a background thread"]) {
        NSString *path = CYLEdgeCaseFile(@"background.json", CYLEdgeCaseData(json));
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            NSError *error = nil;
            CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfigurationFile:path error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(tabBarController, error, json);
            });
        });
    } else if ([title isEqualToString:@"Non-controllers and duplicates (code)"]) {
        UIViewController *page = [[UIViewController alloc] init];
        NSArray *attributes = [NSJSONSerialization JSONObjectWithData:CYLEdgeCaseData(items) options:0 error:NULL];
        finish([CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerViewControllers : @[ @"not a view controller", page, page ],
            CYLTabBarControllerTabBarItemsAttributes : attributes ?: @[],
        }], nil, @"CYLTabBarControllerViewControllers : @[ @\"not a view controller\", page, page ]");
    } else if ([title isEqualToString:@"Configuration is not a dictionary (code)"]) {
        id notADictionary = @[ @1, @2 ];
        finish([CYLTabBarController tabBarControllerWithConfiguration:notADictionary], nil, @"[CYLTabBarController tabBarControllerWithConfiguration:@[ @1, @2 ]]");
    } else if ([title isEqualToString:@"Empty view controller list (code)"]) {
        NSArray *attributes = [NSJSONSerialization JSONObjectWithData:CYLEdgeCaseData(items) options:0 error:NULL];
        finish([CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerViewControllers : @[],
            CYLTabBarControllerTabBarItemsAttributes : attributes ?: @[],
        }], nil, @"CYLTabBarControllerViewControllers : @[]");
    } else if ([title isEqualToString:@"HTTP 404"]) {
        fromURL(CYLEdgeCaseRequest(@"https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/no_such_configuration.json", 0), NO);
    } else if ([title isEqualToString:@"Unknown host"]) {
        fromURL(CYLEdgeCaseRequest(@"https://configuration.cyltabbarcontroller.invalid/tabbar.json", 0), NO);
    } else if ([title isEqualToString:@"Server timeout (3 s)"]) {
        // 10.255.255.1 is not routed: the request can only time out. 10.255.255.1 不可路由：请求只会超时。
        fromURL(CYLEdgeCaseRequest(@"https://10.255.255.1/tabbar.json", 3), NO);
    } else if ([title isEqualToString:@"Request cancelled"]) {
        fromURL(CYLEdgeCaseRequest(CYLSampleConfigurationURLString, 0), YES);
    } else if ([title isEqualToString:@"An HTML page (network)"]) {
        fromURL(CYLEdgeCaseRequest(@"https://example.com/", 0), NO);
    } else if ([title isEqualToString:@"Request without a URL"]) {
        // [EN] C10: a request without a URL (and, in code, a nil request or URL) gives a FileNotFound error.
        // [CN] C10：没有 URL 的请求（以及代码中传入 nil 请求或 URL）返回 FileNotFound 错误。
        fromURL([[NSURLRequest alloc] init], NO);
    } else if ([title isEqualToString:@"Empty strings"]) {
        // [EN] B21: empty URLs, Lottie files, image URLs, colors, fonts and platforms are left out; an empty page ID falls back to
        //      CYLTabBarItemIdentifier; the tabs stay.
        // [CN] B21：空的 URL、Lottie 文件、图片 URL、颜色、字体与平台会被忽略；空的页面 ID 改用 CYLTabBarItemIdentifier；Tab 保留。
        fromFile(@"empty_strings.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarLottieURL\": \"\", \"CYLTabBarLottieFilePath\": \"\", \"CYLTabBarItemImageURL\": \"\", \"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemPageIdentifier\": \"\", \"CYLTabBarItemTitleColor\": \"\", \"CYLTabBarItemTitleFont\": \"\"}, {\"CYLTabBarItemTitle\": \"Me\", \"CYLTabBarItemImage\": \"system:\", \"CYLTabBarItemIdentifier\": \"me\", \"CYLTabBarItemPlatforms\": \"\"}]}"));
    }
}

/// [EN] Shows the outcome in the row and in an alert ("View" opens a created controller). [CN] 在该行与弹窗中显示结果（“查看”打开创建的控制器）。
- (void)cyl_showConfigurationEdgeCaseRow:(NSInteger)row
                                   title:(NSString *)title
                        tabBarController:(nullable CYLTabBarController *)tabBarController
                                   error:(nullable NSError *)error
                                  source:(NSString *)source {
    NSString *result = tabBarController
        ? [NSString stringWithFormat:CYLLocalizedString(@"已安全创建 TabBarController：%@ 个 Tab"), @(tabBarController.viewControllers.count)]
        : [NSString stringWithFormat:@"❌ %@ (%ld)", error.localizedDescription ?: @"", (long)error.code];
    if (tabBarController) {
        result = [@"✅ " stringByAppendingString:result];
    }
    if (tabBarController.cyl_skippedTabs.count > 0) {
        // [EN] The tabs that got no page, with the reason (docs/Tab-Page-Registry.md). [CN] 没有页面的 Tab 及原因（docs/Tab-Page-Registry.md）。
        NSMutableArray<NSString *> *names = [NSMutableArray array];
        for (CYLTabBarSkippedTab *skipped in tabBarController.cyl_skippedTabs) {
            [names addObject:[NSString stringWithFormat:@"%@ (%@)", skipped.title ?: skipped.pageIdentifier ?: @"?", CYLSkipReasonName(skipped.reason)]];
        }
        result = [result stringByAppendingFormat:@"\n%@", [NSString stringWithFormat:CYLLocalizedString(@"跳过 %1$@ 个 Tab：%2$@"), @(names.count), [names componentsJoinedByString:@", "]]];
    }
    [self cyl_configurationEdgeCaseResults][@(row)] = result;
    UITableView *tableView = objc_getAssociatedObject(self, &CYLConfigurationEdgeCaseTableViewKey);
    if (tableView.window) {
        [tableView reloadData];
    }
    if (!self.view.window || self.presentedViewController) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:result preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"关闭") style:UIAlertActionStyleCancel handler:nil]];
    if (tabBarController.viewControllers.count > 0) {
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"查看") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf cyl_presentConfigurationDemoTabBarController:tabBarController source:title sourceText:source error:nil];
        }]];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

/*!
 * [EN] C16: two tab bar controllers on one screen, created from the same configuration: each passes its own
 *      CYLTabBarPageRegistry, so the same page IDs ("home", "me") give different pages (blue and orange). Both are child
 *      view controllers of one container.
 * [CN] C16：同一屏幕上的两个 TabBarController，由同一份配置创建：各自传入自己的 CYLTabBarPageRegistry，因此相同的页面 ID（"home"、"me"）
 *      得到不同的页面（蓝色与橙色）。两者都是同一个容器的子控制器。
 */
- (void)cyl_presentTwoTabBarsDemo {
    NSArray *items = @[ @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemImage : @"system:house", CYLTabBarItemIdentifier : @"home" },
                        @{ CYLTabBarItemTitle : @"Me", CYLTabBarItemImage : @"system:person", CYLTabBarItemIdentifier : @"me" } ];
    UIViewController *container = [[UIViewController alloc] init];
    if (@available(iOS 13.0, *)) {
        container.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        container.view.backgroundColor = [UIColor whiteColor];
    }
    NSArray<UIColor *> *colors = @[ [UIColor systemBlueColor], [UIColor systemOrangeColor] ];
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (NSUInteger index = 0; index < colors.count; index++) {
        UIColor *color = colors[index];
        NSString *name = index == 0 ? @"Tab bar A" : @"Tab bar B";
        CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
        [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
            UIViewController *page = [[UIViewController alloc] init];
            page.view.backgroundColor = [color colorWithAlphaComponent:0.25];
            UILabel *label = [[UILabel alloc] init];
            label.text = [NSString stringWithFormat:@"%@ · page ID \"%@\"", name, pageIdentifier];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [page.view addSubview:label];
            [NSLayoutConstraint activateConstraints:@[ [label.centerXAnchor constraintEqualToAnchor:page.view.centerXAnchor],
                                                       [label.centerYAnchor constraintEqualToAnchor:page.view.centerYAnchor] ]];
            return page;
        } forPageIdentifiers:@[ @"home", @"me" ]];
        CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
            CYLTabBarControllerTabBarItemsAttributes : items,
            CYLTabBarControllerPageRegistry : registry,
            CYLTabBarControllerContext : name,
        }];
        [container addChildViewController:tabBarController];
        tabBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [container.view addSubview:tabBarController.view];
        [tabBarController didMoveToParentViewController:container];
        [views addObject:tabBarController.view];
    }
    UILayoutGuide *safeArea = container.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [views[0].topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [views[0].leadingAnchor constraintEqualToAnchor:container.view.leadingAnchor],
        [views[0].trailingAnchor constraintEqualToAnchor:container.view.trailingAnchor],
        [views[1].topAnchor constraintEqualToAnchor:views[0].bottomAnchor constant:8],
        [views[1].heightAnchor constraintEqualToAnchor:views[0].heightAnchor],
        [views[1].leadingAnchor constraintEqualToAnchor:container.view.leadingAnchor],
        [views[1].trailingAnchor constraintEqualToAnchor:container.view.trailingAnchor],
        [views[1].bottomAnchor constraintEqualToAnchor:container.view.bottomAnchor],
    ]];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:container];
    container.navigationItem.title = CYLLocalizedString(@"两个 TabBar，同一个页面 ID");
    container.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"关闭")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:navigationController
                                                                                 action:@selector(cyl_dismissTwoTabBarsDemo)];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end

@implementation UINavigationController (CYLConfigurationTwoTabBarsDemo)

/// [EN] The Close button of the two-tab-bar demo. [CN] 两个 TabBar 演示页的关闭按钮。
- (void)cyl_dismissTwoTabBarsDemo {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

/// [EN] C14: registered automatically under "auto" by adopting CYLTabBarPage. [CN] C14：遵守 CYLTabBarPage，自动注册为 "auto"。
@interface CYLConfigurationDemoAutoPage : UIViewController <CYLTabBarPage>
@end

@implementation CYLConfigurationDemoAutoPage

+ (NSString *)cylTabBarPageIdentifier {
    return @"auto";
}

+ (UIViewController *)cylTabBarPageWithAttributes:(NSDictionary<NSString *, id> *)tabAttributes {
    return CYLConfigurationDemoPage(CYLConfigurationDemoTitle([self cylTabBarPageIdentifier], tabAttributes), [NSString stringWithFormat:@"%@\n+cylTabBarPageIdentifier = \"%@\"\n(CYLTabBarPage, no registration code)", NSStringFromClass(self), [self cylTabBarPageIdentifier]]);
}

@end

/// [EN] C14: two classes claim "conflict"; the first in class name order (A) is used, with a warning. [CN] C14：两个类都声明 "conflict"；按类名顺序使用第一个（A），并输出警告。
@interface CYLConfigurationDemoConflictPageA : UIViewController <CYLTabBarPage>
@end

@implementation CYLConfigurationDemoConflictPageA

+ (NSString *)cylTabBarPageIdentifier {
    return @"conflict";
}

+ (UIViewController *)cylTabBarPageWithAttributes:(NSDictionary<NSString *, id> *)tabAttributes {
    return CYLConfigurationDemoPage(CYLConfigurationDemoTitle([self cylTabBarPageIdentifier], tabAttributes), [NSString stringWithFormat:@"%@\n(used: first in class name order)", NSStringFromClass(self)]);
}

@end

@interface CYLConfigurationDemoConflictPageB : UIViewController <CYLTabBarPage>
@end

@implementation CYLConfigurationDemoConflictPageB

+ (NSString *)cylTabBarPageIdentifier {
    return @"conflict";
}

@end

@implementation CYLTabBarController (CYLConfigurationDemo)

/// [EN] The Close button of the configuration demo. [CN] 配置文件演示页的关闭按钮。
- (void)cyl_dismissConfigurationDemo {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
