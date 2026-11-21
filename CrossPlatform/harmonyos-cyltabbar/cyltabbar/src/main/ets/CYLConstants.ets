/**
 * [EN] CYLConstants (CYLConstants.h): the tab image placeholder size, the animation size helper, the dark Lottie
 *      registry (#442) and the "is a tab animation enabled" check. Lottie is always available on HarmonyOS (@ohos/lottie).
 * [CN] CYLConstants：Tab 图片占位尺寸、动画尺寸、深色 Lottie 注册表（#442）以及是否启用 Tab 动画的判断。
 */

/** [EN] CYLTabBarItemImagePlaceholderWidth (22 vp). [CN] Tab 图片占位宽度（22 vp）。 */
export let CYLTabBarItemImagePlaceholderWidth: number = 22;
/** [EN] CYLTabBarItemImagePlaceholderHeight (22 vp). [CN] Tab 图片占位高度（22 vp）。 */
export let CYLTabBarItemImagePlaceholderHeight: number = 22;

/** [EN] Sets the placeholder size (the Objective-C globals are writable). [CN] 设置占位尺寸。 */
export function cyl_setTabBarItemImagePlaceholderSize(width: number, height: number): void {
  CYLTabBarItemImagePlaceholderWidth = width;
  CYLTabBarItemImagePlaceholderHeight = height;
}

/**
 * [EN] CYLTabBarDefaultHeight: the tab bar's height when the app sets none (no `tabBarHeight`): 56 vp, the height of the
 *      HarmonyOS system tab bar (ArkUI `Tabs` with a bottom bar, its default `barHeight`), so a CYLTabBarController and a
 *      system tab bar are the same height, as on iOS (UITabBar's own height) and Android (the Material navigation bar).
 *      A `tabBarHeight` the app passes still wins. It was 49 vp (the iOS 49 pt) before 2026-11-22
 *      (docs/Cross-Platform-Components.md, "default tab bar height = the system tab bar's").
 * [CN] CYLTabBarDefaultHeight：App 未设置 `tabBarHeight` 时的 TabBar 高度：56 vp，即鸿蒙系统 TabBar（底部 TabBar 的 ArkUI `Tabs`，默认
 *      `barHeight`）的高度，使 CYLTabBarController 与系统 TabBar 等高，与 iOS（UITabBar 自身高度）、Android（Material 导航栏）一致。App 传入的
 *      `tabBarHeight` 仍然优先。2026-11-22 之前为 49 vp（iOS 的 49 pt）。
 */
export const CYLTabBarDefaultHeight: number = 56;

/** [EN] A size in vp. [CN] 尺寸（vp）。 */
export interface CYLSize {
  width: number;
  height: number;
}

/** [EN] The tab attribute keys that name an animation. [CN] 表示动画的 Tab 属性 key。 */
const CYLAnimationKeys: string[] = [
  'CYLTabBarLottieURL', 'CYLTabBarLottieFilePath', 'CYLTabBarAnimationURL', 'CYLTabBarAnimationFilePath',
  'CYLTabBarRiveURL', 'CYLTabBarRiveFilePath', 'CYLTabBarSVGAURL', 'CYLTabBarSVGAFilePath',
  'CYLTabBarPAGURL', 'CYLTabBarPAGFilePath', 'CYLTabBarGIFURL', 'CYLTabBarGIFFilePath'
];

export class CYLConstants {
  private static darkURLs: Map<string, string> = new Map<string, string>();
  private static darkColors: Map<string, Record<string, string>> = new Map<string, Record<string, string>>();

  private static isEmpty(size?: CYLSize): boolean {
    return size === undefined || (size.width === 0 && size.height === 0);
  }

  /** [EN] +cyl_tabBarItemAnimationSizeValue:fromNormalImage: size, else the image size, else the placeholder. [CN] 动画尺寸。 */
  static cyl_tabBarItemAnimationSizeValue(size?: CYLSize, normalImageSize?: CYLSize): CYLSize {
    if (!CYLConstants.isEmpty(size)) {
      return size as CYLSize;
    }
    if (!CYLConstants.isEmpty(normalImageSize)) {
      return normalImageSize as CYLSize;
    }
    return { width: CYLTabBarItemImagePlaceholderWidth, height: CYLTabBarItemImagePlaceholderHeight };
  }

  /** [EN] Deprecated: +cyl_getTureLottieSizeValue:fromNormalImage:. [CN] 已废弃。 */
  static cyl_getTureLottieSizeValue(size?: CYLSize, normalImageSize?: CYLSize): CYLSize {
    return CYLConstants.cyl_tabBarItemAnimationSizeValue(size, normalImageSize);
  }

  /** [EN] +cyl_registerDarkLottieURL:forLottieURL: (undefined removes it). [CN] 注册深色 Lottie（undefined 移除）。 */
  static cyl_registerDarkLottieURL(darkLottieURL: string | undefined, lottieURL: string): void {
    if (darkLottieURL === undefined) {
      CYLConstants.darkURLs.delete(lottieURL);
    } else {
      CYLConstants.darkURLs.set(lottieURL, darkLottieURL);
    }
  }

  /** [EN] +cyl_lottieURL:forTraitCollection: the dark version in dark mode. [CN] 深色模式下返回深色版本。 */
  static cyl_lottieURL(lottieURL: string | undefined, dark: boolean): string | undefined {
    if (lottieURL === undefined) {
      return undefined;
    }
    return dark ? (CYLConstants.darkURLs.get(lottieURL) ?? lottieURL) : lottieURL;
  }

  /** [EN] +cyl_registerLottieDarkColors:forLottieURL: keypath -> color (undefined removes them). [CN] 注册深色颜色。 */
  static cyl_registerLottieDarkColors(colors: Record<string, string> | undefined, lottieURL: string): void {
    if (colors === undefined) {
      CYLConstants.darkColors.delete(lottieURL);
    } else {
      CYLConstants.darkColors.set(lottieURL, colors);
    }
  }

  /** [EN] +cyl_lottieDarkColorsForLottieURL:. [CN] 已注册的深色颜色。 */
  static cyl_lottieDarkColorsForLottieURL(lottieURL: string): Record<string, string> | undefined {
    return CYLConstants.darkColors.get(lottieURL);
  }

  /** [EN] +cyl_hasDarkLottieURLs. [CN] 是否注册过深色 Lottie。 */
  static cyl_hasDarkLottieURLs(): boolean {
    return CYLConstants.darkURLs.size > 0 || CYLConstants.darkColors.size > 0;
  }

  /** [EN] +cyl_hasDarkLottieForLottieURL:. [CN] 该 Lottie 是否有深色版本或深色颜色。 */
  static cyl_hasDarkLottieForLottieURL(lottieURL: string): boolean {
    return CYLConstants.darkURLs.has(lottieURL) || CYLConstants.darkColors.has(lottieURL);
  }

  /** [EN] +isTabBarItemAnimationEnabledWithURLs:tabBarItemsAttributes: any URL, or any tab (#477) with an animation key. [CN] 是否启用 Tab 动画。 */
  static isTabBarItemAnimationEnabledWithURLs(urls: string[] | undefined,
    tabBarItemsAttributes: Record<string, Object>[] | undefined): boolean {
    if (urls !== undefined && urls.length > 0) {
      return true;
    }
    for (const attributes of tabBarItemsAttributes ?? []) {
      for (const key of CYLAnimationKeys) {
        if (attributes[key] !== undefined) {
          return true;
        }
      }
    }
    return false;
  }

  /** [EN] Deprecated: +isLottieEnabledFromlottieURLs:tabBarItemsAttributes:. [CN] 已废弃。 */
  static isLottieEnabledFromlottieURLs(urls: string[] | undefined,
    tabBarItemsAttributes: Record<string, Object>[] | undefined): boolean {
    return CYLConstants.isTabBarItemAnimationEnabledWithURLs(urls, tabBarItemsAttributes);
  }
}
