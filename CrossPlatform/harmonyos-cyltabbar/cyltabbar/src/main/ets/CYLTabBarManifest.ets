import { bundleManager } from '@kit.AbilityKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { CYLLocalizationLanguage } from './CYLLocalization';
import { CYLTabBarConfiguration, CYLTabBarConfigurationResult } from './CYLTabBarConfiguration';
import {
  CYLTabBarConfigurationError, CYLTabBarConfigurationErrorCode, CYLTabBarConfigurationFormat, CYLTabBarConfigurationParser
} from './CYLTabBarConfigurationParser';

/**
 * [EN] Tab bar manifests (CYLTabBarManifest.h, docs/Configuration-Manifest.md), ported from CYLTabBarManifest.kt: a
 *      versioned JSON (schemaVersion 1) with conditions / overrides, runtime eligibility, assets checked by SHA-256, and a
 *      loader that downloads a remote manifest into the cache with cache / embedded fallbacks. On HarmonyOS a route is a
 *      rawfile path (embedded) or a sandbox path; the platform name is "harmonyos". The app needs ohos.permission.INTERNET
 *      to load a remote manifest.
 * [CN] Tab 配置清单（从 CYLTabBarManifest.kt 迁移）：带版本的 JSON（schemaVersion 1），支持条件 / 覆盖、运行条件、按 SHA-256
 *      校验的资源，以及把远程清单下载到缓存、失败时回退到缓存或内置清单的加载器。鸿蒙上路由是 rawfile 路径（内置）或沙箱路径；
 *      平台名为 "harmonyos"。加载远程清单需要应用声明 ohos.permission.INTERNET。
 */

/** [EN] The manifest error codes, iOS raw values. [CN] 清单错误码，原始值与 iOS 相同。 */
export enum CYLTabBarManifestErrorCode {
  UnsupportedManifest = 12,
  NotEligible = 13,
  AssetInvalid = 14,
}

/** [EN] A manifest error (CYLTabBarConfigurationErrorDomain). [CN] 清单错误。 */
export class CYLTabBarManifestError extends Error {
  readonly code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
  }
}

/** [EN] CYLTabBarManifestSource. [CN] 清单来源。 */
export enum CYLTabBarManifestSource {
  None = 0,
  Remote = 1,
  Cache = 2,
  Embedded = 3,
}

const ASSET_NAME_PREFIX: string = 'cyl.asset.';
const ASSET_REFERENCE_PREFIX: string = 'asset:';
const RAWFILE_PREFIX: string = 'rawfile:';
const PLATFORM: string = CYLTabBarConfiguration.platform;

type CYLDictionary = Record<string, Object>;

function asDictionary(value: Object | undefined): CYLDictionary | undefined {
  return value !== undefined && value !== null && typeof value === 'object' && !Array.isArray(value) ? value as CYLDictionary : undefined;
}

function asList(value: Object | undefined): Object[] {
  return Array.isArray(value) ? value as Object[] : [];
}

function stringOf(container: Object | undefined, key: string): string | undefined {
  const value = asDictionary(container)?.[key];
  if (typeof value === 'number') {
    return `${value}`;
  }
  if (typeof value === 'string') {
    const text = value.trim();
    return text.length > 0 ? text : undefined;
  }
  return undefined;
}

function merge(base: Object | undefined, override: Object): Object {
  const a = asDictionary(base);
  const b = asDictionary(override);
  if (a === undefined || b === undefined) {
    return override;
  }
  const merged: CYLDictionary = {};
  Object.keys(a).forEach((key: string) => merged[key] = a[key]);
  Object.keys(b).forEach((key: string) => merged[key] = merge(a[key], b[key]));
  return merged;
}

function platformsOf(value: Object | undefined): string[] {
  const parts: string[] = Array.isArray(value) ? (value as Object[]).map((item: Object) => `${item}`) :
    typeof value === 'string' ? (value as string).split(',') : [];
  return parts.map((part: string) => part.trim().toLowerCase()).filter((part: string) => part.length > 0);
}

function allowsThisPlatform(value: Object | undefined): boolean {
  const platforms = platformsOf(value);
  return platforms.length === 0 || platforms.indexOf('all') >= 0 || platforms.indexOf(PLATFORM) >= 0;
}

function appVersion(): string {
  try {
    return bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName || '0';
  } catch (error) {
    return '0';
  }
}

function isoMillis(text: string): number | undefined {
  const time = Date.parse(text);
  return isNaN(time) ? undefined : time;
}

/** [EN] Joins and normalizes a relative path inside `root`; undefined when it leaves `root`. [CN] 规范化路径，越出根目录时为 undefined。 */
function pathInside(root: string, relative: string): string | undefined {
  const rootParts = root.split('/').filter((part: string) => part.length > 0 && part !== '.');
  const parts: string[] = [...rootParts];
  for (const part of relative.split('/')) {
    if (part === '' || part === '.') {
      continue;
    }
    if (part === '..') {
      if (parts.length <= rootParts.length) {
        return undefined;
      }
      parts.pop();
    } else {
      parts.push(part);
    }
  }
  return (root.startsWith('/') ? '/' : '') + parts.join('/');
}

/**
 * [EN] CYLManifestConditions: `device.os`, `app.version`, `percent` comparisons, `percent between A and B`,
 *      `device.language in [...]`, joined with `&&`; an unknown condition is false.
 * [CN] 条件表达式；未知条件为 false。
 */
class CYLManifestConditions {
  private static percentileValue?: number;
  static context?: Context;

  static holds(expression: string | undefined): boolean {
    if (expression === undefined || expression.trim().length === 0) {
      return false;
    }
    return expression.split('&&').every((part: string) => CYLManifestConditions.element(part.trim()));
  }

  private static unquoted(text: string): string {
    return text.trim().replace(/^['"]|['"]$/g, '');
  }

  private static compare(order: number, operator: string): boolean {
    switch (operator) {
      case '==': return order === 0;
      case '!=': return order !== 0;
      case '>=': return order >= 0;
      case '<=': return order <= 0;
      case '>': return order > 0;
      case '<': return order < 0;
      default: return false;
    }
  }

  private static percentile(): number {
    if (CYLManifestConditions.percentileValue !== undefined) {
      return CYLManifestConditions.percentileValue;
    }
    let value = Math.floor(Math.random() * 100);
    const context = CYLManifestConditions.context;
    if (context !== undefined) {
      try {
        const store = preferences.getPreferencesSync(context, { name: 'cyl_tabbar_manifest' });
        const saved = store.getSync('percentile', -1) as number;
        if (saved >= 0) {
          value = saved;
        } else {
          store.putSync('percentile', value);
          store.flush();
        }
      } catch (error) {
        // [EN] Not persisted: the value lasts for this run. [CN] 未能保存：本次运行内有效。
      }
    }
    CYLManifestConditions.percentileValue = value;
    return value;
  }

  private static element(text: string): boolean {
    const comparison = /^(device\.os|app\.version|percent)\s*(==|!=|>=|<=|>|<)\s*(.+)$/.exec(text);
    if (comparison !== null) {
      const value = CYLManifestConditions.unquoted(comparison[3]);
      const operator = comparison[2];
      if (comparison[1] === 'device.os') {
        const same = value.toLowerCase() === PLATFORM || value.toLowerCase() === 'harmony';
        return operator === '==' ? same : operator === '!=' ? !same : false;
      }
      if (comparison[1] === 'app.version') {
        return CYLManifestConditions.compare(CYLTabBarConfiguration.compareVersions(appVersion(), value), operator);
      }
      return CYLManifestConditions.compare(CYLManifestConditions.percentile() - (parseInt(value) || 0), operator);
    }
    const between = /^percent\s+between\s+(\d+)\s+and\s+(\d+)$/.exec(text);
    if (between !== null) {
      const p = CYLManifestConditions.percentile();
      return p >= parseInt(between[1]) && p <= parseInt(between[2]);
    }
    const language = /^device\.language\s+in\s+\[(.*)]$/.exec(text);
    if (language !== null) {
      const current = CYLLocalizationLanguage().toLowerCase();
      return language[1].split(',').map((item: string) => CYLManifestConditions.unquoted(item).toLowerCase())
        .some((item: string) => item.length > 0 && (current === item || current.startsWith(`${item}-`)));
    }
    console.warn(`CYLTabBarController manifest: unknown condition "${text}" is false`);
    return false;
  }
}

/**
 * [EN] CYLTabBarManifest. `baseDirectory` is a sandbox folder, or "rawfile:<folder>" for an embedded manifest.
 * [CN] CYLTabBarManifest。`baseDirectory` 是沙箱目录，或内置清单的 "rawfile:<目录>"。
 */
export class CYLTabBarManifest {
  /** [EN] +supportedSchemaVersion. [CN] 支持的 schemaVersion。 */
  static readonly supportedSchemaVersion: number = 1;
  readonly dictionary: CYLDictionary;
  readonly baseDirectory?: string;
  private readonly context: Context;

  private constructor(dictionary: CYLDictionary, baseDirectory: string | undefined, context: Context) {
    this.dictionary = dictionary;
    this.baseDirectory = baseDirectory;
    this.context = context;
  }

  /** [EN] identifier ("id"). [CN] 清单 id。 */
  get identifier(): string | undefined {
    return stringOf(this.dictionary, 'id');
  }

  /** [EN] version. [CN] 版本。 */
  get version(): string | undefined {
    return stringOf(this.dictionary, 'version');
  }

  /** [EN] +manifestWithDictionary:baseDirectory:error: (throws CYLTabBarManifestError). [CN] 由字典创建（失败时抛出）。 */
  static manifestWithDictionary(context: Context, dictionary: CYLDictionary, baseDirectory?: string): CYLTabBarManifest {
    if (asDictionary(dictionary['tabBar']) === undefined) {
      throw new CYLTabBarManifestError(CYLTabBarManifestErrorCode.UnsupportedManifest, 'Not a tab bar manifest: it has no "tabBar" dictionary.');
    }
    const rawSchema = dictionary['schemaVersion'];
    const schema = typeof rawSchema === 'number' ? rawSchema : typeof rawSchema === 'string' ? parseInt(rawSchema) : NaN;
    if (schema !== CYLTabBarManifest.supportedSchemaVersion) {
      throw new CYLTabBarManifestError(CYLTabBarManifestErrorCode.UnsupportedManifest,
        `schemaVersion ${rawSchema ?? '(missing)'} is not supported (this library reads ${CYLTabBarManifest.supportedSchemaVersion}).`);
    }
    CYLManifestConditions.context = context;
    let merged: CYLDictionary = dictionary;
    const overrides = asList(dictionary['overrides']);
    for (const condition of asList(dictionary['conditions'])) {
      const name = stringOf(condition, 'name');
      if (name === undefined || !CYLManifestConditions.holds(stringOf(condition, 'expression'))) {
        continue;
      }
      for (const override of overrides) {
        const values = asDictionary(override);
        if (values === undefined || stringOf(values, 'condition') !== name) {
          continue;
        }
        const copy: CYLDictionary = {};
        Object.keys(values).filter((key: string) => key !== 'condition').forEach((key: string) => copy[key] = values[key]);
        merged = merge(merged, copy) as CYLDictionary;
      }
    }
    return new CYLTabBarManifest(merged, baseDirectory, context);
  }

  /** [EN] +manifestWithRoute:error: a rawfile path (or an absolute sandbox path). [CN] 由路由创建：rawfile 路径或沙箱绝对路径。 */
  static manifestWithRoute(context: Context, route: string): CYLTabBarManifest {
    let dictionary: CYLDictionary;
    let base: string;
    if (route.startsWith('/')) {
      if (!fileIo.accessSync(route)) {
        throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.FileNotFound, `No manifest matches the route "${route}".`);
      }
      dictionary = CYLTabBarConfigurationParser.configurationWithString(fileIo.readTextSync(route), CYLTabBarConfigurationFormat.JSON);
      base = route.substring(0, route.lastIndexOf('/'));
    } else {
      dictionary = CYLTabBarConfiguration.configurationWithRawFile(context, route);
      base = RAWFILE_PREFIX + (route.lastIndexOf('/') >= 0 ? route.substring(0, route.lastIndexOf('/')) : '');
    }
    return CYLTabBarManifest.manifestWithDictionary(context, dictionary, base);
  }

  /** [EN] "sha256-" + base64url (no padding) of the SHA-256 of `data`. [CN] 资源的 hash 写法。 */
  static hashOf(data: Uint8Array): string {
    const md = cryptoFramework.createMd('SHA256');
    md.updateSync({ data: data });
    const digest = md.digestSync().data;
    const base64 = new util.Base64Helper().encodeToStringSync(digest);
    return 'sha256-' + base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  /** [EN] The reason the manifest cannot be used now, else undefined. [CN] 当前不能使用的原因。 */
  eligibilityError(nowMillis: number = Date.now()): CYLTabBarManifestError | undefined {
    const runtime = asDictionary(this.dictionary['runtime']);
    const app = appVersion();
    const minimum = stringOf(runtime, 'minAppVersion');
    const maximum = stringOf(runtime, 'maxAppVersion');
    const startText = stringOf(runtime, 'startTime');
    const endText = stringOf(runtime, 'endTime');
    const start = startText !== undefined ? isoMillis(startText) : undefined;
    const end = endText !== undefined ? isoMillis(endText) : undefined;
    let reason: string | undefined = undefined;
    if (!allowsThisPlatform(runtime?.['platforms'])) {
      reason = `runtime.platforms [${platformsOf(runtime?.['platforms']).join(', ')}] does not include ${PLATFORM}.`;
    } else if (minimum !== undefined && CYLTabBarConfiguration.compareVersions(app, minimum) < 0) {
      reason = `It needs app version ${minimum} or later (this app is ${app}).`;
    } else if (maximum !== undefined && CYLTabBarConfiguration.compareVersions(app, maximum) > 0) {
      reason = `It is for app version ${maximum} or earlier (this app is ${app}).`;
    } else if (start !== undefined && nowMillis < start) {
      reason = `It starts at ${startText}.`;
    } else if (end !== undefined && nowMillis >= end) {
      reason = `It ended at ${endText}.`;
    }
    return reason === undefined ? undefined : new CYLTabBarManifestError(CYLTabBarManifestErrorCode.NotEligible, reason);
  }

  /** [EN] -isEligibleAtDate:error:. [CN] 在该时间是否可用。 */
  isEligibleAtDate(nowMillis: number = Date.now()): boolean {
    return this.eligibilityError(nowMillis) === undefined;
  }

  private get assetsRoot(): string | undefined {
    const route = stringOf(this.dictionary['assets'], 'baseRoute') ?? '.';
    const base = this.baseDirectory;
    if (base === undefined) {
      return undefined;
    }
    return route === '.' ? base : base.startsWith(RAWFILE_PREFIX)
      ? RAWFILE_PREFIX + (pathInside(base.substring(RAWFILE_PREFIX.length), route) ?? '')
      : pathInside(base, route);
  }

  /** @internal [EN] The asset entries for this platform. [CN] 本平台的资源条目。 */
  assetEntries(): CYLDictionary[] {
    return asList(asDictionary(this.dictionary['assets'])?.['list']).map((entry: Object) => asDictionary(entry))
      .filter((entry: CYLDictionary | undefined) => entry !== undefined && stringOf(entry, 'key') !== undefined &&
        stringOf(entry, 'path') !== undefined && allowsThisPlatform(entry['platforms'])) as CYLDictionary[];
  }

  /** @internal [EN] The path of an entry: a sandbox path or "rawfile:<path>". [CN] 条目的路径。 */
  pathOfEntry(entry: CYLDictionary): string | undefined {
    const root = this.assetsRoot;
    const relative = stringOf(entry, 'path');
    if (root === undefined || relative === undefined) {
      return undefined;
    }
    if (root.startsWith(RAWFILE_PREFIX)) {
      const path = pathInside(root.substring(RAWFILE_PREFIX.length), relative);
      return path === undefined ? undefined : RAWFILE_PREFIX + path;
    }
    return pathInside(root, relative);
  }

  private read(path: string): Uint8Array | undefined {
    try {
      if (path.startsWith(RAWFILE_PREFIX)) {
        return this.context.resourceManager.getRawFileContentSync(path.substring(RAWFILE_PREFIX.length));
      }
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      const size = fileIo.statSync(path).size;
      const buffer = new ArrayBuffer(size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return new Uint8Array(buffer);
    } catch (error) {
      return undefined;
    }
  }

  private exists(path: string): boolean {
    if (path.startsWith(RAWFILE_PREFIX)) {
      return this.read(path) !== undefined;
    }
    try {
      return fileIo.accessSync(path) && fileIo.statSync(path).isFile();
    } catch (error) {
      return false;
    }
  }

  private get defaultTheme(): string | undefined {
    return stringOf(this.dictionary['themes'], 'default');
  }

  /** [EN] -pathOfAssetWithKey:theme:state: (state defaults to "normal"). [CN] 按 key、主题、状态查找资源路径。 */
  pathOfAssetWithKey(key: string, theme?: string, state?: string): string | undefined {
    const wantedState = state !== undefined && state.length > 0 ? state : 'normal';
    const themes = [theme !== undefined && theme.length > 0 ? theme : (this.defaultTheme ?? ''), this.defaultTheme ?? '', '*'];
    const entries = this.assetEntries();
    for (const attemptTheme of themes) {
      for (const attemptState of [wantedState, 'normal']) {
        for (const entry of entries) {
          const themeMatches = attemptTheme === '*' || (stringOf(entry, 'theme') ?? '') === attemptTheme;
          if (stringOf(entry, 'key') === key && themeMatches && (stringOf(entry, 'state') ?? 'normal') === attemptState) {
            const path = this.pathOfEntry(entry);
            if (path !== undefined && this.exists(path)) {
              return path;
            }
          }
        }
      }
    }
    return undefined;
  }

  /** [EN] -pathForAssetReference: "asset:<key>?theme=<t>&state=<s>". [CN] 解析资源引用。 */
  pathForAssetReference(reference: string): string | undefined {
    if (!reference.startsWith(ASSET_REFERENCE_PREFIX)) {
      return undefined;
    }
    const rest = reference.substring(ASSET_REFERENCE_PREFIX.length);
    const question = rest.indexOf('?');
    const key = question >= 0 ? rest.substring(0, question) : rest;
    if (key.length === 0) {
      return undefined;
    }
    const query = new Map<string, string>();
    if (question >= 0) {
      rest.substring(question + 1).split('&').forEach((pair: string) => {
        const equal = pair.indexOf('=');
        query.set(equal >= 0 ? pair.substring(0, equal) : pair, equal >= 0 ? decodeURIComponent(pair.substring(equal + 1)) : '');
      });
    }
    return this.pathOfAssetWithKey(key, query.get('theme'), query.get('state'));
  }

  /** [EN] The first missing or tampered asset, else undefined. [CN] 第一个缺失或 hash 不符的资源。 */
  assetError(): CYLTabBarManifestError | undefined {
    for (const entry of this.assetEntries()) {
      const path = this.pathOfEntry(entry);
      const data = path !== undefined ? this.read(path) : undefined;
      if (data === undefined) {
        return new CYLTabBarManifestError(CYLTabBarManifestErrorCode.AssetInvalid, `Asset ${stringOf(entry, 'path')} is missing.`);
      }
      const hash = stringOf(entry, 'hash');
      if (hash !== undefined && hash !== CYLTabBarManifest.hashOf(data)) {
        return new CYLTabBarManifestError(CYLTabBarManifestErrorCode.AssetInvalid, `Asset ${stringOf(entry, 'path')} does not match its hash.`);
      }
    }
    return undefined;
  }

  /** [EN] -verifyAssetsWithError: (throws the asset error). [CN] 校验资源（失败时抛出）。 */
  verifyAssetsWithError(): boolean {
    const error = this.assetError();
    if (error !== undefined) {
      throw error;
    }
    return true;
  }

  private resolved(value: Object | undefined, theme: string | undefined): Object | undefined {
    if (typeof value !== 'string' || !(value as string).startsWith('@')) {
      return value;
    }
    const list = asDictionary(asDictionary(this.dictionary['themes'])?.['list']);
    const name = (value as string).substring(1);
    const forTheme = theme !== undefined ? asDictionary(list?.[theme])?.[name] : undefined;
    const defaultName = this.defaultTheme;
    return forTheme ?? (defaultName !== undefined ? asDictionary(list?.[defaultName])?.[name] : undefined);
  }

  /** [EN] An image path as ArkUI reads it: "file://<sandbox path>" or "resource://RAWFILE/<path>". [CN] ArkUI 可读的图片路径。 */
  private imageURI(path: string): string {
    return path.startsWith(RAWFILE_PREFIX) ? 'resource://RAWFILE/' + path.substring(RAWFILE_PREFIX.length) : 'file://' + path;
  }

  private imagePath(value: Object | undefined, theme: string | undefined): string | undefined {
    const resolved = this.resolved(value, theme);
    if (typeof resolved !== 'string' || (resolved as string).length === 0) {
      return undefined;
    }
    let text = resolved as string;
    if (text.startsWith(ASSET_REFERENCE_PREFIX)) {
      if (theme !== undefined && text.indexOf('theme=') < 0) {
        text += (text.indexOf('?') >= 0 ? '&' : '?') + `theme=${theme}`;
      }
      const path = this.pathForAssetReference(text);
      return path === undefined ? undefined : this.imageURI(path);
    }
    const base = this.baseDirectory;
    if (base === undefined) {
      return text;
    }
    const path = base.startsWith(RAWFILE_PREFIX) ? RAWFILE_PREFIX + (pathInside(base.substring(RAWFILE_PREFIX.length), text) ?? '')
      : pathInside(base, text);
    return path !== undefined && this.exists(path) ? this.imageURI(path) : undefined;
  }

  private isForThisApp(item: CYLDictionary): boolean {
    if (!allowsThisPlatform(item['platforms'])) {
      return false;
    }
    const maximum = stringOf(item, 'maxAppVersion');
    return maximum === undefined || CYLTabBarConfiguration.compareVersions(appVersion(), maximum) <= 0;
  }

  /**
   * [EN] -configuration: the CYLTabBarController configuration of the manifest, its images in `theme` (default: the
   *      manifest's default theme; ArkUI reads one theme at a time).
   * [CN] 清单对应的 CYLTabBarController 配置，图片取 `theme` 主题（默认取清单的默认主题）。
   */
  configuration(theme?: string): CYLDictionary {
    const tabBar = asDictionary(this.dictionary['tabBar']) ?? {};
    const themes = asDictionary(this.dictionary['themes']);
    const themeList = asDictionary(themes?.['list']) ?? {};
    const themeName = theme ?? this.defaultTheme ?? Object.keys(themeList)[0];
    const configuration: CYLDictionary = {};
    const styleType = stringOf(tabBar, 'styleType');
    if (styleType !== undefined) {
      configuration['CYLTabBarControllerStyleType'] = styleType;
    }
    const sources = asList(tabBar['list']).map((item: Object) => asDictionary(item))
      .filter((item: CYLDictionary | undefined) => item !== undefined && item['visible'] !== false && this.isForThisApp(item)) as CYLDictionary[];
    configuration['CYLTabBarControllerTabBarItemsAttributes'] = sources.map((item: CYLDictionary) => {
      const attributes: CYLDictionary = {};
      const put = (key: string, value: Object | undefined) => {
        if (value !== undefined) {
          attributes[key] = value;
        }
      };
      put('CYLTabBarItemIdentifier', stringOf(item, 'key'));
      put('CYLTabBarItemTitle', stringOf(item, 'text'));
      put('CYLTabBarItemPageIdentifier', stringOf(item, 'pagePath'));
      put('CYLTabBarItemMinimumAppVersion', stringOf(item, 'minAppVersion'));
      const normal = this.imagePath(item['iconPath'], themeName);
      put('CYLTabBarItemImage', normal);
      put('CYLTabBarItemSelectedImage', this.imagePath(item['selectedIconPath'], themeName) ?? normal);
      return attributes as Object;
    });
    const barKeys: string[][] = [['color', 'CYLTabBarItemTitleColor'], ['selectedColor', 'CYLTabBarItemSelectedTitleColor'],
      ['backgroundColor', 'CYLTabBarBackgroundColor']];
    barKeys.forEach((pair: string[]) => {
      const value = this.resolved(tabBar[pair[0]], themeName);
      if (value !== undefined) {
        configuration[pair[1]] = value;
      }
    });
    if (themeName !== undefined && Object.keys(themeList).length > 0) {
      configuration['CYLTabBarControllerThemeIdentifier'] = themeName;
    }
    const mid = asDictionary(tabBar['midButton']);
    if (mid !== undefined && this.isForThisApp(mid)) {
      const plus: CYLDictionary = {};
      const put = (key: string, value: Object | undefined) => {
        if (value !== undefined) {
          plus[key] = value;
        }
      };
      put('CYLTabBarItemIdentifier', stringOf(mid, 'key'));
      put('CYLTabBarItemTitle', stringOf(mid, 'text'));
      put('CYLTabBarItemImage', this.imagePath(mid['iconPath'], themeName));
      put('CYLPlusButtonBackgroundImage', this.imagePath(mid['backgroundImage'], themeName));
      if (typeof mid['index'] === 'number') {
        plus['CYLPlusButtonIndexInTabBar'] = Math.floor(mid['index'] as number);
      }
      if (typeof mid['width'] === 'number' && typeof mid['height'] === 'number') {
        plus['CYLPlusButtonSize'] = `{${mid['width']}, ${mid['height']}}`;
      }
      if (stringOf(mid, 'action') !== 'callback') {
        put('CYLTabBarItemPageIdentifier', stringOf(mid, 'pagePath'));
      }
      configuration['CYLTabBarControllerPlusButton'] = plus;
      configuration['CYLTabBarControllerContext'] = 'CYLTabBarManifest:' + (this.identifier ?? 'manifest');
    }
    return configuration;
  }

  /**
   * [EN] -tabBarControllerWithError: what CYLTabBarController shows for the manifest (bind it to the component's
   *      props); throws NoPages when no tab is left.
   * [CN] 清单对应的 CYLTabBarController 内容（绑定到组件属性）；没有 Tab 时抛出 NoPages。
   */
  tabBarControllerWithError(darkMode: boolean = false, theme?: string): CYLTabBarConfigurationResult {
    const result = CYLTabBarConfiguration.resultWithConfiguration(this.configuration(theme), appVersion(), darkMode);
    if (result.items.length === 0) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.NoPages,
        'No tab of the manifest found its page: register the pages first (docs/Tab-Page-Registry.md).');
    }
    return result;
  }

  /** @internal [EN] A copy whose assets are in `folder`. [CN] 资源位于 `folder` 的副本。 */
  cachedCopy(folder: string): CYLTabBarManifest {
    const dictionary: CYLDictionary = {};
    Object.keys(this.dictionary).forEach((key: string) => dictionary[key] = this.dictionary[key]);
    const assets: CYLDictionary = {};
    const original = asDictionary(this.dictionary['assets']) ?? {};
    Object.keys(original).forEach((key: string) => assets[key] = original[key]);
    assets['baseRoute'] = '.';
    dictionary['assets'] = assets;
    return new CYLTabBarManifest(dictionary, folder, this.context);
  }
}

/** [EN] CYLTabBarManifestLoaderDelegate. [CN] 加载器代理。 */
export interface CYLTabBarManifestLoaderDelegate {
  /** [EN] -manifestLoader:shouldApplyManifest:source: (default true). [CN] 是否应用该清单。 */
  shouldApplyManifest?: (loader: CYLTabBarManifestLoader, manifest: CYLTabBarManifest, source: CYLTabBarManifestSource) => boolean;
  /** [EN] -manifestLoader:didApplyManifest:source:. [CN] 已应用清单。 */
  didApplyManifest?: (loader: CYLTabBarManifestLoader, manifest: CYLTabBarManifest, source: CYLTabBarManifestSource) => void;
  /** [EN] -manifestLoader:didFailWithError:fallbackSource:. [CN] 加载失败及回退来源。 */
  didFailWithError?: (loader: CYLTabBarManifestLoader, error: Error, fallbackSource: CYLTabBarManifestSource) => void;
}

/** [EN] CYLTabBarManifestCompletion. [CN] 加载完成回调。 */
export type CYLTabBarManifestCompletion = (manifest: CYLTabBarManifest | undefined, source: CYLTabBarManifestSource,
  error: Error | undefined) => void;

/**
 * [EN] CYLTabBarManifestLoader: downloads a manifest and its assets into `<cacheDir>/CYLTabBarManifest/<version>`;
 *      on failure, falls back as its "fallback.onError" says ("previous": the newest valid cached manifest, then the
 *      embedded one; "embedded"; "none").
 * [CN] 下载清单及其资源到缓存目录；失败时按 "fallback.onError" 回退（"previous"：最新的有效缓存，其次内置；"embedded"；"none"）。
 */
export class CYLTabBarManifestLoader {
  delegate?: CYLTabBarManifestLoaderDelegate;
  /** [EN] embeddedManifestRoute: a rawfile path. [CN] 内置清单的 rawfile 路径。 */
  embeddedManifestRoute?: string;
  /** [EN] date: the time used for eligibility (milliseconds; default now). [CN] 判断可用性的时间（毫秒）。 */
  date?: number;
  private readonly context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  private get cacheDirectory(): string {
    return `${this.context.cacheDir}/CYLTabBarManifest`;
  }

  private now(): number {
    return this.date ?? Date.now();
  }

  /** [EN] -cachedManifest: the newest cached manifest that is eligible and whose assets are valid. [CN] 最新的有效缓存清单。 */
  cachedManifest(): CYLTabBarManifest | undefined {
    let names: string[] = [];
    try {
      names = fileIo.listFileSync(this.cacheDirectory).filter((name: string) => !name.endsWith('.download'));
    } catch (error) {
      return undefined;
    }
    names.sort((a: string, b: string) => CYLTabBarConfiguration.compareVersions(b, a));
    for (const name of names) {
      const folder = `${this.cacheDirectory}/${name}`;
      const file = `${folder}/manifest.json`;
      try {
        if (!fileIo.accessSync(file)) {
          continue;
        }
        const dictionary = CYLTabBarConfigurationParser.configurationWithString(fileIo.readTextSync(file), CYLTabBarConfigurationFormat.JSON);
        const manifest = CYLTabBarManifest.manifestWithDictionary(this.context, dictionary, folder);
        if (manifest.isEligibleAtDate(this.now()) && manifest.assetError() === undefined) {
          return manifest;
        }
      } catch (error) {
        continue;
      }
    }
    return undefined;
  }

  private async download(url: string): Promise<Uint8Array> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, { expectDataType: http.HttpDataType.ARRAY_BUFFER });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.Network, `HTTP ${response.responseCode} for ${url}.`);
      }
      return new Uint8Array(response.result as ArrayBuffer);
    } finally {
      request.destroy();
    }
  }

  private removeFolder(path: string): void {
    try {
      if (fileIo.accessSync(path)) {
        fileIo.rmdirSync(path);
      }
    } catch (error) {
      // [EN] Nothing to remove. [CN] 无需删除。
    }
  }

  private writeFile(path: string, data: Uint8Array): void {
    const folder = path.substring(0, path.lastIndexOf('/'));
    fileIo.mkdirSync(folder, true);
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, data.buffer);
    fileIo.closeSync(file);
  }

  private async save(manifest: CYLTabBarManifest, url: string): Promise<CYLTabBarManifest> {
    const version = manifest.version ?? '0';
    if (version.indexOf('/') >= 0 || version.indexOf('..') >= 0) {
      throw new CYLTabBarManifestError(CYLTabBarManifestErrorCode.UnsupportedManifest, 'The manifest version is not a valid folder name.');
    }
    const folder = `${this.cacheDirectory}/${version}`;
    const staging = `${folder}.download`;
    this.removeFolder(staging);
    fileIo.mkdirSync(staging, true);
    const staged = manifest.cachedCopy(staging);
    const baseURL = stringOf(manifest.dictionary['assets'], 'baseURL') ?? url.substring(0, url.lastIndexOf('/') + 1);
    try {
      for (const entry of staged.assetEntries()) {
        const path = staged.pathOfEntry(entry);
        if (path === undefined) {
          throw new CYLTabBarManifestError(CYLTabBarManifestErrorCode.AssetInvalid, `Asset ${stringOf(entry, 'path')} is outside the assets folder.`);
        }
        const relative = (stringOf(entry, 'path') ?? '').replace(/^\.\//, '');
        const source = stringOf(entry, 'url') ??
          (/^https?:\/\//.test(relative) ? relative : baseURL + (baseURL.endsWith('/') ? '' : '/') + relative);
        let data: Uint8Array;
        try {
          data = await this.download(source);
        } catch (error) {
          throw new CYLTabBarManifestError(CYLTabBarManifestErrorCode.AssetInvalid, `Asset ${stringOf(entry, 'path')} could not be downloaded.`);
        }
        this.writeFile(path, data);
      }
      const assetError = staged.assetError();
      if (assetError !== undefined) {
        throw assetError;
      }
      this.writeFile(`${staging}/manifest.json`, new util.TextEncoder().encodeInto(JSON.stringify(staged.dictionary)));
      this.removeFolder(folder);
      fileIo.renameSync(staging, folder);
    } catch (error) {
      this.removeFolder(staging);
      throw error as Error;
    }
    return manifest.cachedCopy(folder);
  }

  /** [EN] -loadManifestWithURL:completion:. [CN] 加载远程清单。 */
  loadManifestWithURL(url: string, completion: CYLTabBarManifestCompletion): void {
    this.load(url).then((result: CYLManifestLoadResult) => this.finish(result, completion));
  }

  private async load(url: string): Promise<CYLManifestLoadResult> {
    const result: CYLManifestLoadResult = {};
    try {
      const data = await this.download(url);
      const dictionary = CYLTabBarConfigurationParser.configurationWithString(
        util.TextDecoder.create('utf-8').decodeToString(data), CYLTabBarConfigurationFormat.JSON);
      result.failed = dictionary;
      const manifest = CYLTabBarManifest.manifestWithDictionary(this.context, dictionary, undefined);
      const eligibility = manifest.eligibilityError(this.now());
      if (eligibility !== undefined) {
        throw eligibility;
      }
      result.remote = await this.save(manifest, url);
    } catch (error) {
      result.error = error instanceof Error ? error as Error
        : new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.Network, `${error}`);
    }
    return result;
  }

  private finish(result: CYLManifestLoadResult, completion: CYLTabBarManifestCompletion): void {
    const delegate = this.delegate;
    const remote = result.remote;
    if (remote !== undefined && (delegate?.shouldApplyManifest?.(this, remote, CYLTabBarManifestSource.Remote) ?? true)) {
      delegate?.didApplyManifest?.(this, remote, CYLTabBarManifestSource.Remote);
      completion(remote, CYLTabBarManifestSource.Remote, undefined);
      return;
    }
    const fallback = asDictionary(result.failed?.['fallback']);
    const policy = stringOf(fallback, 'onError') ?? 'previous';
    const embedded = this.embeddedManifestRoute ?? stringOf(fallback, 'embeddedRoute');
    let manifest: CYLTabBarManifest | undefined = undefined;
    let source = CYLTabBarManifestSource.None;
    if (policy === 'previous') {
      manifest = this.cachedManifest();
      source = manifest !== undefined ? CYLTabBarManifestSource.Cache : CYLTabBarManifestSource.None;
    }
    if (manifest === undefined && policy !== 'none' && embedded !== undefined) {
      try {
        manifest = CYLTabBarManifest.manifestWithRoute(this.context, embedded);
        source = CYLTabBarManifestSource.Embedded;
      } catch (error) {
        manifest = undefined;
      }
    }
    if (manifest !== undefined && !(delegate?.shouldApplyManifest?.(this, manifest, source) ?? true)) {
      manifest = undefined;
      source = CYLTabBarManifestSource.None;
    }
    const reason = result.error ?? new CYLTabBarManifestError(CYLTabBarManifestErrorCode.UnsupportedManifest, 'The manifest was refused.');
    delegate?.didFailWithError?.(this, reason, source);
    if (manifest !== undefined) {
      delegate?.didApplyManifest?.(this, manifest, source);
    }
    completion(manifest, source, reason);
  }
}

interface CYLManifestLoadResult {
  remote?: CYLTabBarManifest;
  failed?: CYLDictionary;
  error?: Error;
}
