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
}

/**
 * [EN] The keys of the iOS library, for code that keeps the attributes as dictionaries (CYLTabBarItem* constants).
 * [CN] iOS 库的键名（CYLTabBarItem* 常量），供以字典保存属性的代码使用。
 */
export const CYLTabBarItemTitle: string = 'title';
export const CYLTabBarItemSelectedTitle: string = 'selectedTitle';
export const CYLTabBarItemImage: string = 'image';
export const CYLTabBarItemSelectedImage: string = 'selectedImage';
export const CYLTabBarItemIdentifier: string = 'identifier';
