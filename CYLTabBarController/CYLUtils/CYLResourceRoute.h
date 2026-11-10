//
//  CYLResourceRoute.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Resource routes: one string that says where a resource is (a configuration file, a folder of string tables…),
 *      built into the app or in its sandbox (e.g. downloaded at run time), the same on iOS, Android, React Native and
 *      Flutter (docs/Resource-Routes.md). The prefix decides, in this order:
 *
 *          bundle:<path>               the app's resources (Android: assets)
 *          sandbox:Documents/<path>    Documents (Android: filesDir)
 *          sandbox:Caches/<path>       Library/Caches (Android: cacheDir); sandbox:tmp/<path> the temporary folder
 *          sandbox:<path>              below the app's home folder (Android: the app's data folder)
 *          file:///<path>              a local file URL
 *          /<path>                     an absolute path
 *          ~/<path>                    the app's home folder
 *          <path>                      relative to `baseDirectory` (a configuration file's folder), else the app's resources
 *
 *      A query picks one file in that folder: `name`, and optionally `theme`, `version` and `format`, for files named
 *      `{name}[-{theme}][@{version}].{format}`. Without `version` the highest one wins; without `format` any format the
 *      configuration parser reads, preferring JSON, YAML, plist, XML, TOML, then the others:
 *
 *          sandbox:Caches/tabbar?name=tabbar&theme=dark&version=2.1&format=json  →  …/Caches/tabbar/tabbar-dark@2.1.json
 *          bundle:Configurations?name=tabbar                                     →  the highest tabbar[@version].{json,…}
 *
 *      The library never ships these resources: string tables and configuration files belong to the app.
 * [CN] 资源路由：用一个字符串说明资源（配置文件、字符串表所在目录等）的位置，可以是 App 内置资源，也可以在沙盒中（例如运行时下载），
 *      在 iOS、Android、React Native 与 Flutter 上规则相同（docs/Resource-Routes.md）。按上面的顺序由前缀判断：`bundle:` App 资源
 *      （Android：assets）、`sandbox:Documents/` Documents（Android：filesDir）、`sandbox:Caches/` Library/Caches（Android：
 *      cacheDir）、`sandbox:tmp/` 临时目录、`sandbox:<路径>` App 主目录之下、`file:` 文件 URL、`/` 绝对路径、`~/` App 主目录，
 *      其余相对于 `baseDirectory`（配置文件所在目录），否则相对于 App 资源。
 *      查询参数在该目录中选出唯一的文件：`name`，以及可选的 `theme`、`version`、`format`，对应文件名
 *      `{name}[-{theme}][@{version}].{format}`。不写 `version` 时取最高版本；不写 `format` 时为配置解析器支持的任意格式，依次优先
 *      JSON、YAML、plist、XML、TOML，再到其他格式（示例见上）。本库从不内置这些资源：字符串表与配置文件属于 App。
 */
@interface CYLResourceRoute : NSObject

/*!
 * [EN] The local path of `route`, or nil when it is empty or its query matches no file. Without a query the path is
 *      returned whether it exists or not (a folder may be created later).
 * [CN] `route` 对应的本地路径；为空或查询参数没有匹配的文件时为 nil。没有查询参数时，无论路径是否存在都会返回（目录可能稍后创建）。
 */
+ (nullable NSString *)pathForRoute:(NSString *)route baseDirectory:(nullable NSString *)baseDirectory;

/*!
 * [EN] The file of `directory` that matches `name`, `theme`, `version` and `format` (nil: any), as the route query.
 * [CN] `directory` 中与 `name`、`theme`、`version`、`format`（nil 表示任意）匹配的文件，规则与路由查询参数相同。
 */
+ (nullable NSString *)pathOfFileInDirectory:(NSString *)directory
                                        name:(NSString *)name
                                       theme:(nullable NSString *)theme
                                     version:(nullable NSString *)version
                                      format:(nullable NSString *)format;

@end

NS_ASSUME_NONNULL_END
