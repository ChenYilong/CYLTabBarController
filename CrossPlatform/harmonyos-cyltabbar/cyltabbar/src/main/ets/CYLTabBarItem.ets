import { CYLOffset } from 'cylbadge';

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
  /** [EN] CYLTabBarItemDarkSelectedImage: the selected image in dark mode. [CN] 深色模式选中图片。 */
  darkSelectedImage?: ResourceStr;
  /** [EN] CYLTabBarLottieFilePath: a rawfile path of a Lottie JSON (shown instead of the images). [CN] Lottie JSON 的 rawfile 路径（代替图片显示）。 */
  lottieFilePath?: string;
  /** [EN] CYLTabBarLottieDarkFilePath: the Lottie JSON in dark mode. [CN] 深色模式的 Lottie JSON。 */
  lottieDarkFilePath?: string;
  /** [EN] CYLTabBarLottieSize (vp); the image size when unset. [CN] Lottie 尺寸（vp）；未设置时用图片尺寸。 */
  lottieSize?: number;
  /** [EN] CYLTabBarItemTitlePositionAdjustment (vp). [CN] 标题位置偏移（vp）。 */
  titlePositionAdjustment?: CYLTitleOffset;
  /**
   * [EN] CYLTabBarItemImageURL / CYLTabBarItemSelectedImageURL: icons from the network (http/https; the app needs
   *      ohos.permission.INTERNET), shown instead of image / selectedImage (-setTabBarItemIconWithURL:selectedURL:size:atIndex:).
   * [CN] 网络图标（http/https；应用需 ohos.permission.INTERNET），代替 image / selectedImage 显示。
   */
  imageURL?: string;
  selectedImageURL?: string;
  /** [EN] CYLTabBarGIFFilePath: a GIF (rawfile path or URL) shown as the tab's icon. [CN] 作为 Tab 图标显示的 GIF（rawfile 路径或 URL）。 */
  gifFilePath?: string;
  /**
   * [EN] FIX: issue #415. CYLTabBarSVGAFilePath: a rawfile path of an SVGA 2.x file (e.g. "svga/tab_home.svga"), shown instead
   *      of the images: it plays once when the tab is selected and shows its first frame otherwise; the image shows if it
   *      cannot load (CYLSVGAView).
   * [CN] FIX: issue #415。CYLTabBarSVGAFilePath：SVGA 2.x 文件的 rawfile 路径（如 "svga/tab_home.svga"），代替图片显示：Tab 选中时播放一次，
   *      否则显示第一帧；无法加载时显示图片（CYLSVGAView）。
   */
  svgaFilePath?: string;
  /** [EN] CYLTabBarSVGAURL: an SVGA file at an http(s) URL (ohos.permission.INTERNET); wins over svgaFilePath. [CN] http(s) 地址上的 SVGA 文件；优先于 svgaFilePath。 */
  svgaURL?: string;
  /** [EN] CYLTabBarSVGADarkFilePath: the SVGA file in dark mode. [CN] 深色模式的 SVGA 文件。 */
  svgaDarkFilePath?: string;
  /** [EN] CYLTabBarSVGADarkURL: the SVGA URL in dark mode. [CN] 深色模式的 SVGA 地址。 */
  svgaDarkURL?: string;
  /** [EN] CYLTabBarSVGASize (vp); the image size when unset. [CN] SVGA 尺寸（vp）；未设置时用图片尺寸。 */
  svgaSize?: number;
  /**
   * [EN] CYLTabBarRiveFilePath: a rawfile path of a .riv file, with Rive options in its fragment
   *      (`CYLTabBarAnimationURLWithOptions`), e.g. "rive/icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity&input=active"
   *      (a "?" query is read too).
   *      Shown instead of the image and played when the tab is selected (`CYLRiveIcon`); the image when it cannot load.
   * [CN] .riv 文件的 rawfile 路径，Rive 选项放在 fragment 中（也读取 "?" 查询参数）。代替图片显示，Tab 选中时播放（`CYLRiveIcon`）；无法加载时显示图片。
   */
  riveFilePath?: string;
  /**
   * [EN] CYLTabBarRiveDarkFilePath: the .riv file in dark mode. [CN] 深色模式的 .riv 文件。
   */
  riveDarkFilePath?: string;
  /**
   * [EN] CYLTabBarRiveSize (vp); the image size when unset. [CN] Rive 尺寸（vp）；未设置时用图片尺寸。
   */
  riveSize?: number;
  /** [EN] CYLTabBarItemTitleColor: this tab's title color while not selected. [CN] 未选中时此 Tab 的标题颜色。 */
  titleColor?: ResourceColor;
  /** [EN] CYLTabBarItemSelectedTitleColor. [CN] 选中时此 Tab 的标题颜色。 */
  selectedTitleColor?: ResourceColor;
  /**
   * [EN] CYLTabBarItemIconColor: this tab's icon color while not selected (iOS / Android, docs/Tab-Item-Colors.md); an
   *      animated icon with `tint=title` is drawn in it.
   * [CN] 未选中时此 Tab 的图标颜色（iOS / Android 同名键）；`tint=title` 的动效图标以此颜色绘制。
   */
  iconColor?: ResourceColor;
  /**
   * [EN] CYLTabBarItemSelectedIconColor: this tab's icon color while selected.
   * [CN] 选中时此 Tab 的图标颜色。
   */
  selectedIconColor?: ResourceColor;
  /**
   * [EN] CYLTabBarItemIconRenderingMode: how this tab's static icon is drawn (docs/Tab-Item-Colors.md, #787, as iOS and Android): 'template'
   *      tints it (unselected: iconColor, else the title color; selected: selectedIconColor, else the selected title color), 'original'
   *      never tints it, 'automatic' (default, also unset) tints only when an icon color is set. Case-insensitive; other values act as 'automatic'.
   * [CN] 此 Tab 静态图标的渲染方式（与 iOS、Android 一致）：'template' 着色（未选中：iconColor，否则标题色；选中：selectedIconColor，否则选中标题色），
   *      'original' 从不着色，'automatic'（默认，未设置时同）只有设置了图标颜色才着色。不区分大小写；其他值按 'automatic' 处理。
   */
  iconRenderingMode?: string;
  /** [EN] CYLTabBarItemBackgroundColor: the tab's background while not selected. [CN] 未选中时此 Tab 的背景色。 */
  backgroundColor?: ResourceColor;
  /** [EN] CYLTabBarItemSelectedBackgroundColor: the tab's background while selected. [CN] 选中时此 Tab 的背景色。 */
  selectedBackgroundColor?: ResourceColor;
  /**
   * [EN] `CYLFlatDesignTabBarItem.enabled`: false dims the tab and ignores its taps; true (default) when unset.
   * [CN] false 时 Tab 变暗且不响应点击；未设置时为 true。
   */
  enabled?: boolean;
  /**
   * [EN] `CYLFlatDesignTabBarItem.imagePositionAdjustment`: moves the icon. [CN] 移动图标。
   */
  imagePositionAdjustment?: CYLOffset;
  /**
   * [EN] `CYLFlatDesignTabBarItem.imageInsets`: insets of the icon inside its square, in vp. [CN] 图标在其方框内的内边距（vp）。
   */
  imageInsets?: CYLTabBarItemImageInsets;
  /**
   * [EN] `CYLFlatDesignTabBarItem.layoutCentered`: centers a lone title (no image) or a lone image (no title) in the tab.
   * [CN] 只有标题（无图片）或只有图片（无标题）时在 Tab 中居中。
   */
  layoutCentered?: boolean;
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
export const CYLTabBarItemIconColor: string = 'iconColor';
export const CYLTabBarItemSelectedIconColor: string = 'selectedIconColor';
export const CYLTabBarItemIconRenderingMode: string = 'iconRenderingMode';
export const CYLTabBarItemBackgroundColor: string = 'backgroundColor';
export const CYLTabBarItemSelectedBackgroundColor: string = 'selectedBackgroundColor';

/**
 * [EN] The icon insets of a tab (`UIEdgeInsets`), in vp. [CN] Tab 图标的内边距（`UIEdgeInsets`，vp）。
 */
export interface CYLTabBarItemImageInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}
