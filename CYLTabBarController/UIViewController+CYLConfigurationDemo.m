//
//  UIViewController+CYLConfigurationDemo.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLConfigurationDemo.h"
#import "CYLTabBarController.h"
#import "CYLLocalization.h"

NSString *const CYLSampleConfigurationURLString = @"https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations/cyl_tabbar_configuration.yaml";

static NSString *const CYLConfigurationDemoCellIdentifier = @"CYLConfigurationDemoCell";

@interface CYLTabBarController (CYLConfigurationDemo)
- (void)cyl_dismissConfigurationDemo;
@end

/// [EN] The text a page shows for its configuration file: the file itself, or the parsed dictionary for a binary file.
/// [CN] 页面显示的配置文件文本：文件本身；二进制文件则显示解析后的字典。
static NSString *CYLConfigurationSourceText(NSString *_Nullable path, NSDictionary *_Nullable configuration) {
    NSString *text = path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] : nil;
    if (text.length > 0) {
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
    for (NSString *name in names) {
        if (![name hasPrefix:@"."]) {
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

@implementation CYLTabBarController (CYLConfigurationDemo)

/// [EN] The Close button before iOS 14. [CN] iOS 14 之前的关闭按钮。
- (void)cyl_dismissConfigurationDemo {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
