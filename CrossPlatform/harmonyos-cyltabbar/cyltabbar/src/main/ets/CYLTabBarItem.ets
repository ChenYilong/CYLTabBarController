import { CYLOffset } from './CYLBadge';

/**
 * [EN] The attributes of one tab, the CYLTabBarItem* keys of the iOS library (CYLTabBarController.h) as typed fields:
 *      CYLTabBarItemTitle -> title, CYLTabBarItemSelectedTitle -> selectedTitle, CYLTabBarItemImage -> image,
 *      CYLTabBarItemSelectedImage -> selectedImage, CYLTabBarItemIdentifier -> identifier.
 * [CN] 单个 Tab 的属性，即 iOS 库（CYLTabBarController.h）的 CYLTabBarItem* 键对应的类型化字段：
 *      CYLTabBarItemTitle -> title、CYLTabBarItemSelectedTitle -> selectedTitle、CYLTabBarItemImage -> image、
 *      CYLTabBarItemSelectedImage -> selectedImage、CYLTabBarItemIdentifier -> identifier。
 */
export interface CYLTabBarItemAttributes {
  /** [EN] CYLTabBarItemTitle. [CN] 标题。 */
  title?: ResourceStr;
  /** [EN] CYLTabBarItemSelectedTitle: the title while selected (title when unset). [CN] 选中时的标题（未设置时用 title）。 */
  selectedTitle?: ResourceStr;
  /** [EN] CYLTabBarItemImage. [CN] 图片。 */
  image?: ResourceStr;
  /** [EN] CYLTabBarItemSelectedImage (image when unset). [CN] 选中图片（未设置时用 image）。 */
  selectedImage?: ResourceStr;
  /** [EN] CYLTabBarItemIdentifier: a stable name of the tab. [CN] Tab 的稳定名字。 */
  identifier?: string;
  /** [EN] CYLTabBarItemDarkImage: the image in dark mode. [CN] 深色模式图片。 */
  darkImage?: ResourceStr;
  /** [EN] CYLTabBarLottieFilePath: a rawfile path of a Lottie JSON (shown instead of the images). [CN] Lottie JSON 的 rawfile 路径（代替图片显示）。 */
  lottieFilePath?: string;
  /** [EN] CYLTabBarLottieSize (vp); the image size when unset. [CN] Lottie 尺寸（vp）；未设置时用图片尺寸。 */
  lottieSize?: number;
  /** [EN] CYLTabBarItemTitlePositionAdjustment (vp). [CN] 标题位置偏移（vp）。 */
  titlePositionAdjustment?: CYLTitleOffset;
  /** [EN] CYLTabBarItemTitleColor: this tab's title color while not selected. [CN] 未选中时此 Tab 的标题颜色。 */
  titleColor?: ResourceColor;
  /** [EN] CYLTabBarItemSelectedTitleColor. [CN] 选中时此 Tab 的标题颜色。 */
  selectedTitleColor?: ResourceColor;
  /** [EN] CYLTabBarItemBackgroundColor: the tab's background while not selected. [CN] 未选中时此 Tab 的背景色。 */
  backgroundColor?: ResourceColor;
  /** [EN] CYLTabBarItemSelectedBackgroundColor: the tab's background while selected. [CN] 选中时此 Tab 的背景色。 */
  selectedBackgroundColor?: ResourceColor;
}

/** [EN] UIOffset (CYLOffset). [CN] 偏移。 */
export type CYLTitleOffset = CYLOffset;

/**
 * [EN] The keys of the iOS library, for code that keeps the attributes as dictionaries (CYLTabBarItem* constants).
 * [CN] iOS 库的键名（CYLTabBarItem* 常量），供以字典保存属性的代码使用。
 */
export const CYLTabBarItemTitle: string = 'title';
export const CYLTabBarItemSelectedTitle: string = 'selectedTitle';
export const CYLTabBarItemImage: string = 'image';
export const CYLTabBarItemSelectedImage: string = 'selectedImage';
export const CYLTabBarItemIdentifier: string = 'identifier';
export const CYLTabBarItemTitleColor: string = 'titleColor';
export const CYLTabBarItemSelectedTitleColor: string = 'selectedTitleColor';
export const CYLTabBarItemBackgroundColor: string = 'backgroundColor';
export const CYLTabBarItemSelectedBackgroundColor: string = 'selectedBackgroundColor';
