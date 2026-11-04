//
//  UIViewController+CYLConfigurationDemo.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The URL of a sample configuration on GitHub, used by the demo's "load from a URL" action.
 * [CN] GitHub 上示例配置文件的 URL，用于演示中的“从网络 URL 加载”。
 */
FOUNDATION_EXTERN NSString *const CYLSampleConfigurationURLString;

/*!
 * [EN] A demo row of the settings section (see `UIViewController+CYLSettingsSection.h`): one configuration file creates a
 *      whole `CYLTabBarController` (`+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]`). The row offers
 *      the sample files, one per format (JSON, JSON5, JSONC, plist in XML, binary and OpenStep form, .strings, YAML, TOML,
 *      INI, .cfg, .properties, .env, XML), and a download from a URL
 *      (`+[CYLTabBarController loadTabBarControllerWithConfigurationURL:completion:]`). The tab bar controller it creates is
 *      presented full screen; every page shows the file it came from, and a Close button.
 * [CN] 设置分组中的一个演示行（见 `UIViewController+CYLSettingsSection.h`）：一个配置文件生成整个 `CYLTabBarController`
 *      （`+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]`）。该行提供各格式的示例文件（JSON、JSON5、JSONC、XML / 二进制 /
 *      OpenStep 格式的 plist、.strings、YAML、TOML、INI、.cfg、.properties、.env、XML），以及从 URL 下载
 *      （`+[CYLTabBarController loadTabBarControllerWithConfigurationURL:completion:]`）。生成的 TabBarController 全屏展示，每个页面显示其来源文件，
 *      并带有关闭按钮。
 */
@interface UIViewController (CYLConfigurationDemo)

/// [EN] The sample configuration files in the library's resource bundle, sorted by name. [CN] 本库资源包中的示例配置文件，按名称排序。
+ (NSArray<NSString *> *)cyl_sampleConfigurationFilePaths;

/// [EN] The cell of the demo row. [CN] 演示行的 cell。
- (UITableViewCell *)cyl_configurationDemoCellForTableView:(UITableView *)tableView;

/// [EN] Shows the choice of files (and the URL), then presents the tab bar controller created from it.
/// [CN] 显示文件（及 URL）选择，然后展示由其生成的 TabBarController。
- (void)cyl_presentConfigurationDemo;

@end

NS_ASSUME_NONNULL_END
