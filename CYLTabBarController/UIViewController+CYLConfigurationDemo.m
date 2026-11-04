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

@interface UIViewController (CYLConfigurationDemoPrivate)
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
        [CYLTabBarController loadConfigurationWithURL:URL completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
            CYLTabBarController *tabBarController = configuration ? [CYLTabBarController tabBarControllerWithConfiguration:configuration] : nil;
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
    __weak CYLTabBarController *weakTabBarController = tabBarController;
    UIBarButtonItem *close = nil;
    if (@available(iOS 14.0, *)) {
        close = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"关闭")
                                                 image:nil
                                       primaryAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            [weakTabBarController dismissViewControllerAnimated:YES completion:nil];
        }]
                                                  menu:nil];
    } else {
        close = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"关闭") style:UIBarButtonItemStylePlain
                                                target:tabBarController action:@selector(cyl_dismissConfigurationDemo)];
    }
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
        @[ @"B7", @"NaN and Infinity insets" ], @[ @"B9", @"Unknown style" ], @[ @"C1", @"Missing view controller class" ],
        @[ @"C2", @"Class is not a view controller" ], @[ @"C3", @"A container as a tab" ], @[ @"B13", @"Invalid URLs and Lottie files" ],
        @[ @"B12", @"Duplicate identifiers" ], @[ @"B11", @"Misspelled keys" ], @[ @"A12", @"Truncated protobuf" ],
        @[ @"A12", @"Corrupted binary plist" ], @[ @"A14", @"XML external entity" ], @[ @"A2", @"Missing file" ],
        @[ @"E1", @"Created on a background thread" ], @[ @"C6", @"Non-controllers and duplicates (code)" ],
        @[ @"B18", @"Configuration is not a dictionary (code)" ], @[ @"C9", @"Empty view controller list (code)" ],
        @[ @"D3", @"HTTP 404" ], @[ @"D4", @"Unknown host" ], @[ @"D5", @"Server timeout (3 s)" ], @[ @"D10", @"Request cancelled" ],
        @[ @"D7", @"An HTML page (network)" ],
    ];
}

/// [EN] Two valid tabs, as JSON. [CN] 两个有效的 Tab（JSON）。
static NSString *const CYLEdgeCaseTabsJSON = @"[{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\"}, {\"CYLTabBarItemTitle\": \"Me\", \"CYLTabBarItemImage\": \"system:person\"}]";

/// [EN] Writes `data` to a temporary file and returns its path. [CN] 将 `data` 写入临时文件并返回路径。
static NSString *CYLEdgeCaseFile(NSString *name, NSData *data) {
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CYLConfigurationEdgeCases"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *path = [directory stringByAppendingPathComponent:name];
    [data writeToFile:path atomically:YES];
    return path;
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
        fromFile(@"yaml.json", CYLEdgeCaseData(@"CYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemImage: system:house\n  - CYLTabBarItemTitle: Me\n    CYLTabBarItemImage: system:person\n"));
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
        fromFile(@"types.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerContext\": [1, 2], \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": [\"a\", \"list\"], \"CYLTabBarItemImage\": null, \"CYLTabBarItemIdentifier\": 7}, \"not a tab\", {\"CYLTabBarItemTitle\": 42, \"CYLTabBarItemImage\": {\"a\": 1}}]}"));
    } else if ([title isEqualToString:@"NaN and Infinity insets"]) {
        fromFile(@"nan.yaml", CYLEdgeCaseData(@"CYLTabBarControllerImageInsets: \"{nan, 0, 0, 0}\"\nCYLTabBarControllerTitlePositionAdjustment: [1e999, -3]\nCYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n    CYLTabBarItemImage: system:house\n    CYLTabBarItemImageInsets: \"{inf, 0, -inf, 0}\"\n    CYLTabBarLottieSize: \"{-24, 0}\"\n"));
    } else if ([title isEqualToString:@"Unknown style"]) {
        fromFile(@"style.toml", CYLEdgeCaseData(@"CYLTabBarControllerStyleType = 99\n[[CYLTabBarControllerTabBarItemsAttributes]]\nCYLTabBarItemTitle = \"Home\"\nCYLTabBarItemImage = \"system:house\"\n"));
    } else if ([title isEqualToString:@"Missing view controller class"]) {
        fromFile(@"missing_class.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemViewControllerClass\": \"NoSuchViewController\", \"CYLTabBarItemNavigationControllerClass\": \"NoSuchNavigationController\"}]}"));
    } else if ([title isEqualToString:@"Class is not a view controller"]) {
        fromFile(@"not_a_controller.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerNavigationControllerClass\": \"UIViewController\", \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemViewControllerClass\": \"NSString\"}]}"));
    } else if ([title isEqualToString:@"A container as a tab"]) {
        fromFile(@"container.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Tabs\", \"CYLTabBarItemViewControllerClass\": \"UITabBarController\"}, {\"CYLTabBarItemTitle\": \"Alert\", \"CYLTabBarItemViewControllerClass\": \"UIAlertController\"}]}"));
    } else if ([title isEqualToString:@"Invalid URLs and Lottie files"]) {
        fromFile(@"urls.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\", \"CYLTabBarItemImageURL\": \"javascript:alert(1)\", \"CYLTabBarLottieURL\": \"ftp://example.com/a.json\", \"CYLTabBarLottieFilePath\": \"/no/such/animation.json\", \"CYLTabBarLottieDarkURL\": \"no_such_animation.json\"}]}"));
    } else if ([title isEqualToString:@"Duplicate identifiers"]) {
        fromFile(@"ids.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitle\": \"A\", \"CYLTabBarItemIdentifier\": \"tab\"}, {\"CYLTabBarItemTitle\": \"B\", \"CYLTabBarItemIdentifier\": \"tab\"}, {\"CYLTabBarItemTitle\": \"C\", \"CYLTabBarItemIdentifier\": \"tab\"}]}"));
    } else if ([title isEqualToString:@"Misspelled keys"]) {
        fromFile(@"typos.json", CYLEdgeCaseData(@"{\"CYLTabBarControllerContxt\": \"typo\", \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemTitel\": \"Typo\", \"CYLTabBarItemTitle\": \"Home\", \"CYLTabBarItemImage\": \"system:house\"}]}"));
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
        fromFile(@"xxe.xml", CYLEdgeCaseData(@"<?xml version=\"1.0\"?>\n<!DOCTYPE r [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]>\n<r><CYLTabBarControllerContext>&xxe;</CYLTabBarControllerContext><CYLTabBarControllerTabBarItemsAttributes><item CYLTabBarItemTitle=\"Home\" CYLTabBarItemImage=\"system:house\"/></CYLTabBarControllerTabBarItemsAttributes></r>"));
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
        fromURL([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/no_such_configuration.json"]], NO);
    } else if ([title isEqualToString:@"Unknown host"]) {
        fromURL([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://configuration.cyltabbarcontroller.invalid/tabbar.json"]], NO);
    } else if ([title isEqualToString:@"Server timeout (3 s)"]) {
        // 10.255.255.1 is not routed: the request can only time out. 10.255.255.1 不可路由：请求只会超时。
        fromURL([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://10.255.255.1/tabbar.json"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3], NO);
    } else if ([title isEqualToString:@"Request cancelled"]) {
        fromURL([NSURLRequest requestWithURL:[NSURL URLWithString:CYLSampleConfigurationURLString]], YES);
    } else if ([title isEqualToString:@"An HTML page (network)"]) {
        fromURL([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com/"]], NO);
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

@end

@implementation CYLTabBarController (CYLConfigurationDemo)

/// [EN] The Close button before iOS 14. [CN] iOS 14 之前的关闭按钮。
- (void)cyl_dismissConfigurationDemo {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
