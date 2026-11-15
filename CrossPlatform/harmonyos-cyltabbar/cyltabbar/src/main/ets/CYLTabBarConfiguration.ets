import { util } from '@kit.ArkTS';
import { CYLTabBarItemAttributes } from './CYLTabBarItem';
import { CYLOffset } from './CYLBadge';
import { CYLPlusButton } from './CYLPlusButton';
import {
  CYLTabBarConfigurationParser, CYLTabBarConfigurationFormat, CYLTabBarConfigurationError, CYLTabBarConfigurationErrorCode
} from './CYLTabBarConfigurationParser';

/**
 * [EN] A tab read from a configuration: its attributes plus the page to show (CYLTabBarItemPageIdentifier /
 *      CYLTabBarItemPageParameters).
 * [CN] 从配置读取的 Tab：属性以及要显示的页面。
 */
export interface CYLConfiguredTabBarItem extends CYLTabBarItemAttributes {
  pageIdentifier?: string;
  pageParameters?: Record<string, Object>;
}

/**
 * [EN] The plus button read from a configuration (CYLTabBarControllerPlusButton), with the page it selects
 *      (CYLTabBarItemPageIdentifier: the button is selectable and selects that page, as a tab's page).
 * [CN] 从配置读取的 PlusButton（CYLTabBarControllerPlusButton），以及它选中的页面（CYLTabBarItemPageIdentifier）。
 */
export interface CYLConfiguredPlusButton extends CYLPlusButton {
  pageIdentifier?: string;
  pageParameters?: Record<string, Object>;
}

/**
 * [EN] What a configuration sets on a CYLTabBarController (+[CYLTabBarController tabBarControllerWithConfiguration:]).
 * [CN] 配置对 CYLTabBarController 设置的内容。
 */
export interface CYLTabBarConfigurationResult {
  context?: string;
  styleType: string;
  items: CYLConfiguredTabBarItem[];
  titlePositionAdjustment: CYLOffset;
  tintColor?: string;
  unselectedColor?: string;
  backgroundColor?: string;
  themeIdentifier?: string;
  plusButton?: CYLConfiguredPlusButton;
}

/**
 * [EN] Turns a configuration image name into an image: "system:<SF Symbol>" names and plain names. [CN] 把配置中的图片名转为图片。
 */
export type CYLTabBarImageResolver = (name: string) => ResourceStr | undefined;

/**
 * [EN] CYLTabBarConfiguration (ported from CYLTabBarConfiguration.kt): reading configuration files and their values.
 *      The platform name is "harmonyos" (CYLTabBarItemPlatforms).
 * [CN] CYLTabBarConfiguration（从 CYLTabBarConfiguration.kt 迁移）：读取配置文件及其值。平台名为 "harmonyos"。
 */
export class CYLTabBarConfiguration {
  static readonly platform: string = 'harmonyos';
  static imageResolver: CYLTabBarImageResolver = (name: string) => name;

  /**
   * [EN] +configurationWithContentsOfFile: for a rawfile of the app (`context.resourceManager`). [CN] 读取应用 rawfile 中的配置文件。
   */
  static configurationWithRawFile(context: Context, path: string): Record<string, Object> {
    let bytes: Uint8Array;
    try {
      bytes = context.resourceManager.getRawFileContentSync(path);
    } catch (error) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.FileNotFound, `No file at ${path}.`);
    }
    const extension = path.substring(path.lastIndexOf('.') + 1);
    const text = util.TextDecoder.create('utf-8').decodeToString(bytes);
    return CYLTabBarConfigurationParser.configurationWithString(text, CYLTabBarConfigurationParser.formatForPathExtension(extension));
  }

  /** [EN] "{h, v}", [h, v] or {horizontal, vertical}. [CN] 偏移值。 */
  static offsetValue(value: Object | undefined): CYLOffset | undefined {
    const numbers = CYLTabBarConfiguration.numbers(value, 2, ['horizontal', 'vertical']);
    return numbers === undefined ? undefined : { horizontal: numbers[0], vertical: numbers[1] };
  }

  /** [EN] "#RRGGBB", "#RRGGBBAA" or "#RGB"; undefined when invalid. [CN] 颜色值；无效时为 undefined。 */
  static colorValue(value: Object | undefined): string | undefined {
    if (typeof value !== 'string') {
      return undefined;
    }
    const hex = value.trim().replace(/^#/, '');
    if (/^[0-9a-fA-F]{3}$/.test(hex)) {
      return `#${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}`;
    }
    if (/^[0-9a-fA-F]{6}$/.test(hex)) {
      return `#${hex}`;
    }
    if (/^[0-9a-fA-F]{8}$/.test(hex)) {
      return `#${hex.substring(6)}${hex.substring(0, 6)}`;
    }
    return undefined;
  }

  /** [EN] true / false, "yes" / "no", 1 / 0. [CN] 布尔值。 */
  static boolValue(value: Object | undefined): boolean | undefined {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'number') {
      return value !== 0;
    }
    if (typeof value === 'string') {
      const text = value.trim().toLowerCase();
      if (['true', 'yes', '1', 'on'].indexOf(text) >= 0) {
        return true;
      }
      if (['false', 'no', '0', 'off'].indexOf(text) >= 0) {
        return false;
      }
    }
    return undefined;
  }

  static numbers(value: Object | undefined, count: number, names: string[]): number[] | undefined {
    let parts: Object[] = [];
    if (typeof value === 'string') {
      parts = value.replace(/[{}\[\]]/g, '').split(',');
    } else if (Array.isArray(value)) {
      parts = value as Object[];
    } else if (value !== undefined && value !== null && typeof value === 'object') {
      const record = value as Record<string, Object>;
      parts = names.map((name: string) => record[name]);
    }
    const numbers = parts.map((part: Object) => Number(String(part).trim())).filter((n: number) => Number.isFinite(n));
    return numbers.length === count ? numbers : undefined;
  }

  /**
   * [EN] The plus button of CYLTabBarControllerPlusButton: CYLTabBarItemImage (required), CYLTabBarItemSelectedImage,
   *      CYLTabBarItemTitle, CYLPlusButtonIndexInTabBar, CYLPlusButtonCenterYOffset, CYLPlusButtonImageSize
   *      ("{55, 55}" or a number), CYLPlusButtonAlignsTitle, CYLTabBarItemIdentifier, CYLTabBarItemPageIdentifier and
   *      CYLTabBarItemPageParameters; undefined without an image or outside this platform (CYLTabBarItemPlatforms).
   * [CN] 解析 CYLTabBarControllerPlusButton：CYLTabBarItemImage（必需）及其余键；没有图片或不适用于本平台时为 undefined。
   */
  static plusButtonWithConfiguration(configuration: Record<string, Object>): CYLConfiguredPlusButton | undefined {
    const raw = configuration['CYLTabBarControllerPlusButton'];
    if (raw === null || raw === undefined || typeof raw !== 'object' || Array.isArray(raw)) {
      return undefined;
    }
    const button = raw as Record<string, Object>;
    const platforms = button['CYLTabBarItemPlatforms'];
    if (typeof platforms === 'string' &&
      platforms.split(',').map((p: string) => p.trim().toLowerCase()).indexOf(CYLTabBarConfiguration.platform) < 0) {
      return undefined;
    }
    const imageName = button['CYLTabBarItemImage'];
    const image = typeof imageName === 'string' ? CYLTabBarConfiguration.imageResolver(imageName) : undefined;
    if (image === undefined) {
      return undefined;
    }
    const selectedName = button['CYLTabBarItemSelectedImage'];
    const index = Number(button['CYLPlusButtonIndexInTabBar']);
    const offset = Number(button['CYLPlusButtonCenterYOffset']);
    const sizeValue = button['CYLPlusButtonImageSize'];
    const size = typeof sizeValue === 'number' ? [sizeValue, sizeValue]
      : CYLTabBarConfiguration.numbers(sizeValue, 2, ['width', 'height']);
    const pageIdentifier = typeof button['CYLTabBarItemPageIdentifier'] === 'string'
      ? button['CYLTabBarItemPageIdentifier'] as string : undefined;
    return {
      image: image,
      selectedImage: typeof selectedName === 'string' ? CYLTabBarConfiguration.imageResolver(selectedName) : undefined,
      title: typeof button['CYLTabBarItemTitle'] === 'string' ? button['CYLTabBarItemTitle'] as string : undefined,
      index: button['CYLPlusButtonIndexInTabBar'] !== undefined && Number.isInteger(index) ? index : undefined,
      centerYOffset: button['CYLPlusButtonCenterYOffset'] !== undefined && Number.isFinite(offset) ? offset : undefined,
      imageSize: size !== undefined ? Math.min(size[0], size[1]) : undefined,
      alignsTitle: CYLTabBarConfiguration.boolValue(button['CYLPlusButtonAlignsTitle']),
      identifier: typeof button['CYLTabBarItemIdentifier'] === 'string' ? button['CYLTabBarItemIdentifier'] as string : undefined,
      selectable: pageIdentifier !== undefined,
      pageIdentifier: pageIdentifier,
      pageParameters: button['CYLTabBarItemPageParameters'] as Record<string, Object> | undefined,
    };
  }

  /** [EN] "1.2.3" <= "1.10" compare. [CN] 版本比较。 */
  static compareVersions(a: string, b: string): number {
    const x = a.split('.').map((p: string) => Number(p) || 0);
    const y = b.split('.').map((p: string) => Number(p) || 0);
    for (let i = 0; i < Math.max(x.length, y.length); i++) {
      const d = (x[i] ?? 0) - (y[i] ?? 0);
      if (d !== 0) {
        return d;
      }
    }
    return 0;
  }

  /**
   * [EN] The tab bar of a configuration (CYLTabBarControllerTabBarItemsAttributes, the themes, the title adjustment), with
   *      the tabs of other platforms (CYLTabBarItemPlatforms) and newer app versions (CYLTabBarItemMinimumAppVersion) left
   *      out; throws NoTabs when none is left.
   * [CN] 配置中的 TabBar；去掉其他平台与更高应用版本的 Tab；没有 Tab 时抛出 NoTabs。
   */
  static resultWithConfiguration(configuration: Record<string, Object>, appVersion: string, darkMode: boolean): CYLTabBarConfigurationResult {
    const rawItems = configuration['CYLTabBarControllerTabBarItemsAttributes'];
    const items: CYLConfiguredTabBarItem[] = [];
    const seen: string[] = [];
    if (Array.isArray(rawItems)) {
      (rawItems as Object[]).forEach((raw: Object) => {
        if (raw === null || typeof raw !== 'object') {
          return;
        }
        const item = raw as Record<string, Object>;
        const platforms = item['CYLTabBarItemPlatforms'];
        if (typeof platforms === 'string' &&
          platforms.split(',').map((p: string) => p.trim().toLowerCase()).indexOf(CYLTabBarConfiguration.platform) < 0) {
          return;
        }
        const minimum = item['CYLTabBarItemMinimumAppVersion'];
        if (typeof minimum === 'string' && CYLTabBarConfiguration.compareVersions(appVersion, minimum) < 0) {
          return;
        }
        const identifier = typeof item['CYLTabBarItemIdentifier'] === 'string' ? item['CYLTabBarItemIdentifier'] as string : `${items.length}`;
        if (seen.indexOf(identifier) >= 0) {
          return;
        }
        seen.push(identifier);
        const image = item['CYLTabBarItemImage'];
        const selectedImage = item['CYLTabBarItemSelectedImage'];
        const configured: CYLConfiguredTabBarItem = {
          title: typeof item['CYLTabBarItemTitle'] === 'string' ? item['CYLTabBarItemTitle'] as string : undefined,
          selectedTitle: typeof item['CYLTabBarItemSelectedTitle'] === 'string' ? item['CYLTabBarItemSelectedTitle'] as string : undefined,
          image: typeof image === 'string' ? CYLTabBarConfiguration.imageResolver(image) : undefined,
          selectedImage: typeof selectedImage === 'string' ? CYLTabBarConfiguration.imageResolver(selectedImage) : undefined,
          identifier: identifier,
          lottieFilePath: typeof item['CYLTabBarLottieFilePath'] === 'string' ? item['CYLTabBarLottieFilePath'] as string : undefined,
          pageIdentifier: typeof item['CYLTabBarItemPageIdentifier'] === 'string' ? item['CYLTabBarItemPageIdentifier'] as string : undefined,
          pageParameters: item['CYLTabBarItemPageParameters'] as Record<string, Object> | undefined,
          titlePositionAdjustment: CYLTabBarConfiguration.offsetValue(item['CYLTabBarItemTitlePositionAdjustment']),
        };
        items.push(configured);
      });
    }
    if (items.length === 0) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.NoTabs, 'The configuration has no tab for this platform.');
    }
    const themes = configuration['CYLTabBarControllerThemes'] as Record<string, Object> | undefined;
    const themeIdentifier = (darkMode ? configuration['CYLTabBarControllerDarkThemeIdentifier'] : undefined)
      ?? configuration['CYLTabBarControllerThemeIdentifier'];
    const theme = themes !== undefined && typeof themeIdentifier === 'string'
      ? themes[themeIdentifier] as Record<string, Object> | undefined : undefined;
    const pick = (key: string): string | undefined =>
      CYLTabBarConfiguration.colorValue(theme?.[key]) ?? CYLTabBarConfiguration.colorValue(configuration[key]);
    return {
      context: typeof configuration['CYLTabBarControllerContext'] === 'string' ? configuration['CYLTabBarControllerContext'] as string : undefined,
      styleType: typeof configuration['CYLTabBarControllerStyleType'] === 'string' ? configuration['CYLTabBarControllerStyleType'] as string : 'default',
      items: items,
      titlePositionAdjustment: CYLTabBarConfiguration.offsetValue(configuration['CYLTabBarControllerTitlePositionAdjustment'])
        ?? { horizontal: 0, vertical: 0 },
      tintColor: pick('CYLTabBarItemSelectedTitleColor'),
      unselectedColor: pick('CYLTabBarItemTitleColor'),
      backgroundColor: pick('CYLTabBarBackgroundColor'),
      themeIdentifier: typeof themeIdentifier === 'string' ? themeIdentifier : undefined,
      plusButton: CYLTabBarConfiguration.plusButtonWithConfiguration(configuration),
    };
  }
}

export { CYLTabBarConfigurationFormat };
