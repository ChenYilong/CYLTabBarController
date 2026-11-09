//
//  CYLTabBarManifest.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CYLTabBarController;

/// [EN] Where an applied manifest came from. [CN] 已生效清单的来源。
typedef NS_ENUM(NSInteger, CYLTabBarManifestSource) {
    /// [EN] Nothing was applied. [CN] 没有清单生效。
    CYLTabBarManifestSourceNone = 0,
    /// [EN] Downloaded now. [CN] 本次下载。
    CYLTabBarManifestSourceRemote = 1,
    /// [EN] The last verified manifest in the sandbox cache. [CN] 沙盒缓存中上一份已验证的清单。
    CYLTabBarManifestSourceCache = 2,
    /// [EN] The manifest built into the app (`fallback.embeddedRoute`). [CN] App 内置的清单（`fallback.embeddedRoute`）。
    CYLTabBarManifestSourceEmbedded = 3,
};

/*!
 * [EN] A tab bar manifest (docs/Configuration-Manifest.md): one file, after uni-app's `tabBar` / `midButton` / `theme.json`,
 *      Expo Updates' manifest (`id`, `version`, `assets[]` with SHA-256, the embedded fallback) and Firebase Remote
 *      Config's conditions, that describes the tab bar, the plus button, several themes and their images, the version,
 *      the platforms, the app versions and the time window it is for, and what to do when it cannot be used.
 *      `-configuration` turns it into the dictionary of `-[CYLTabBarController initWithConfiguration:]`.
 *      Icons are asset references, `asset:<key>?state=<normal|selected>&theme=<theme>`, found in `assets.list` under
 *      `assets.baseRoute` (a resource route that holds the version): one image per version, theme, tab and state.
 * [CN] TabBar 配置清单（docs/Configuration-Manifest.md）：参照 uni-app 的 `tabBar` / `midButton` / `theme.json`、Expo Updates 清单（`id`、
 *      `version`、带 SHA-256 的 `assets[]`、内置备用）与 Firebase Remote Config 的条件，用一个文件描述 TabBar、PlusButton、多套主题及其图片、
 *      版本、适用的平台、App 版本与时间段，以及无法使用时的处理。`-configuration` 把它转换为 `-[CYLTabBarController initWithConfiguration:]`
 *      的字典。图标写作资源引用 `asset:<key>?state=<normal|selected>&theme=<主题>`，在 `assets.baseRoute`（包含版本的资源路由）下的
 *      `assets.list` 中查找：每张图片由版本、主题、Tab 与状态唯一确定。
 */
@interface CYLTabBarManifest : NSObject

/// [EN] The manifest format this library reads: 1. [CN] 本库读取的清单格式版本：1。
@property (class, nonatomic, readonly) NSInteger supportedSchemaVersion;

/// [EN] The manifest as read, after the overrides of its matching conditions. [CN] 读取后的清单，已合并成立条件的覆盖项。
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *dictionary;
/// [EN] `id`. [CN] `id`。
@property (nonatomic, copy, readonly, nullable) NSString *identifier;
/// [EN] `version` (semantic versioning). [CN] `version`（语义化版本）。
@property (nonatomic, copy, readonly, nullable) NSString *version;
/// [EN] The folder its relative routes start from (the file's folder). [CN] 相对路由的起点（文件所在目录）。
@property (nonatomic, copy, readonly, nullable) NSString *baseDirectory;

/*!
 * [EN] A manifest from a dictionary; relative routes (`assets.baseRoute`, `localization.route`) start from `baseDirectory`.
 *      Returns nil and a `CYLTabBarConfigurationErrorDomain` error when it is not a manifest of a known `schemaVersion`.
 * [CN] 由字典创建清单；相对路由（`assets.baseRoute`、`localization.route`）以 `baseDirectory` 为起点。不是已知 `schemaVersion` 的清单时
 *      返回 nil 与 `CYLTabBarConfigurationErrorDomain` 错误。
 */
+ (nullable instancetype)manifestWithDictionary:(NSDictionary<NSString *, id> *)dictionary
                                  baseDirectory:(nullable NSString *)baseDirectory
                                          error:(NSError *_Nullable *_Nullable)error;

/// [EN] A manifest from a resource route (docs/Resource-Routes.md), e.g. @"bundle:Configurations/Manifests?name=cyl_tabbar_manifest".
/// [CN] 由资源路由创建清单（docs/Resource-Routes.md），例如 @"bundle:Configurations/Manifests?name=cyl_tabbar_manifest"。
+ (nullable instancetype)manifestWithRoute:(NSString *)route error:(NSError *_Nullable *_Nullable)error;

/*!
 * [EN] Whether this app may use it: `runtime.platforms` includes "ios" (or "all"), the app version is within
 *      `runtime.minAppVersion` / `maxAppVersion`, `date` is within `runtime.startTime` / `endTime`. NO with the reason in
 *      `error`.
 * [CN] 本 App 能否使用：`runtime.platforms` 包含 "ios"（或 "all"），App 版本在 `runtime.minAppVersion` / `maxAppVersion` 之内，`date` 在
 *      `runtime.startTime` / `endTime` 之内。不能使用时返回 NO，原因见 `error`。
 */
- (BOOL)isEligibleAtDate:(NSDate *)date error:(NSError *_Nullable *_Nullable)error;

/*!
 * [EN] Every asset of `assets.list` exists and matches its `hash` ("sha256-" and Base64URL, when given). NO with the first
 *      missing or changed asset in `error`.
 * [CN] `assets.list` 中每个资源都存在，并与其 `hash`（给出时，"sha256-" 加 Base64URL）一致。否则返回 NO，第一个缺失或被改动的资源见 `error`。
 */
- (BOOL)verifyAssetsWithError:(NSError *_Nullable *_Nullable)error;

/*!
 * [EN] The local path of the image of `key` in `theme` (nil: the current one, `themes.default`) and `state` ("normal" or
 *      "selected"), looked up as: this theme and state, this theme's "normal", the default theme's state, the default
 *      theme's "normal". nil when none exists.
 * [CN] `key` 在 `theme`（nil 表示 `themes.default`）与 `state`（"normal" 或 "selected"）下图片的本地路径，查找顺序：该主题与状态、该主题的
 *      "normal"、默认主题的该状态、默认主题的 "normal"，最后是任意主题（没有主题的清单）。都没有时为 nil。
 */
- (nullable NSString *)pathOfAssetWithKey:(NSString *)key theme:(nullable NSString *)theme state:(nullable NSString *)state;

/// [EN] The path an asset reference ("asset:home?state=selected") leads to, or nil. [CN] 资源引用（"asset:home?state=selected"）对应的路径，没有时为 nil。
- (nullable NSString *)pathForAssetReference:(NSString *)reference;

/*!
 * [EN] The dictionary of `-[CYLTabBarController initWithConfiguration:]`: `tabBar.list` → tabs (`key`, `text`,
 *      `pagePath`, icons, `platforms`, app versions; `visible: false` left out), `tabBar.midButton` → the plus button,
 *      `themes` → `CYLTabBarControllerThemes` (the `@name` colors, and every tab's image per theme), `tabBar.styleType`,
 *      `localization`.
 * [CN] `-[CYLTabBarController initWithConfiguration:]` 的字典：`tabBar.list` → Tab（`key`、`text`、`pagePath`、图标、`platforms`、App 版本；
 *      `visible: false` 的不包含），`tabBar.midButton` → PlusButton，`themes` → `CYLTabBarControllerThemes`（`@名称` 颜色，以及每个主题下
 *      每个 Tab 的图片），`tabBar.styleType`，`localization`。
 */
- (NSDictionary<NSString *, id> *)configuration;

/*!
 * [EN] A tab bar controller from `-configuration`; main thread only. nil and `CYLTabBarConfigurationErrorNoPages` when no
 *      tab finds its page (register the pages first, docs/Tab-Page-Registry.md).
 * [CN] 由 `-configuration` 创建 TabBarController；仅限主线程。没有 Tab 找到页面时返回 nil 与 `CYLTabBarConfigurationErrorNoPages`
 *      （请先注册页面，docs/Tab-Page-Registry.md）。
 */
- (nullable CYLTabBarController *)tabBarControllerWithError:(NSError *_Nullable *_Nullable)error;

@end

@class CYLTabBarManifestLoader;

/// [EN] The callbacks of a manifest loader, on the main queue. [CN] 清单加载器的回调，在主队列执行。
@protocol CYLTabBarManifestLoaderDelegate <NSObject>
@optional
/// [EN] Checked and about to be used; return NO to refuse it (e.g. the app's own rollout). [CN] 校验通过、即将使用；返回 NO 可以拒绝（例如 App 自己的灰度规则）。
- (BOOL)manifestLoader:(CYLTabBarManifestLoader *)loader shouldApplyManifest:(CYLTabBarManifest *)manifest source:(CYLTabBarManifestSource)source;
/// [EN] Applied. [CN] 已生效。
- (void)manifestLoader:(CYLTabBarManifestLoader *)loader didApplyManifest:(CYLTabBarManifest *)manifest source:(CYLTabBarManifestSource)source;
/// [EN] The remote manifest could not be used: why, and the source used instead (None: nothing). [CN] 远程清单无法使用：原因，以及改用的来源（None 表示没有）。
- (void)manifestLoader:(CYLTabBarManifestLoader *)loader didFailWithError:(NSError *)error fallbackSource:(CYLTabBarManifestSource)fallbackSource;
@end

/// [EN] The result of a load. [CN] 加载结果。
typedef void (^CYLTabBarManifestCompletion)(CYLTabBarManifest *_Nullable manifest, CYLTabBarManifestSource source, NSError *_Nullable error);

/*!
 * [EN] Downloads a manifest and its assets, checks them, keeps them in `sandbox:Caches/CYLTabBarManifest/<version>/`,
 *      and falls back as the manifest's `fallback.onError` says ("previous": the last verified cached manifest;
 *      "embedded": `embeddedManifestRoute`, else `fallback.embeddedRoute`; "none"). An asset without `url` is fetched
 *      next to the manifest: `<assets.baseURL or the manifest URL's folder>/<path>`.
 * [CN] 下载清单及其资源，校验后保存到 `sandbox:Caches/CYLTabBarManifest/<version>/`，并按清单的 `fallback.onError` 回退（"previous"：上一份已验证的
 *      缓存清单；"embedded"：`embeddedManifestRoute`，否则 `fallback.embeddedRoute`；"none"）。没有 `url` 的资源从清单旁边下载：
 *      `<assets.baseURL 或清单 URL 所在目录>/<path>`。
 */
@interface CYLTabBarManifestLoader : NSObject

@property (nonatomic, weak, nullable) id<CYLTabBarManifestLoaderDelegate> delegate;
/// [EN] The built-in manifest used when nothing else can be (default: the remote manifest's `fallback.embeddedRoute`). [CN] 其他都无法使用时的内置清单（默认：远程清单的 `fallback.embeddedRoute`）。
@property (nonatomic, copy, nullable) NSString *embeddedManifestRoute;
/// [EN] The date the time window is checked against (default: now; for tests). [CN] 检查时间段使用的日期（默认：现在；用于测试）。
@property (nonatomic, copy, nullable) NSDate *date;

/// [EN] The newest verified manifest in the cache, or nil. [CN] 缓存中最新的已验证清单，没有时为 nil。
- (nullable CYLTabBarManifest *)cachedManifest;

/// [EN] Loads `URL` (http, https or file), falling back as above. [CN] 加载 `URL`（http、https 或 file），按上述规则回退。
- (void)loadManifestWithURL:(NSURL *)URL completion:(CYLTabBarManifestCompletion)completion;

@end

NS_ASSUME_NONNULL_END
