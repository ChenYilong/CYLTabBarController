/**
 * [EN] A tab of the tab bar: iOS `CYLTabBarItemTitle`, `CYLTabBarItemImage`, `CYLTabBarItemSelectedImage`,
 *      `CYLTabBarItemIdentifier` and the badge (`-cyl_showBadgeValue:`). Texts are string resources, so they follow the
 *      language of the device.
 * [CN] TabBar 中的一个 Tab：对应 iOS 的 `CYLTabBarItemTitle`、`CYLTabBarItemImage`、`CYLTabBarItemSelectedImage`、
 *      `CYLTabBarItemIdentifier` 与角标（`-cyl_showBadgeValue:`）。文字使用字符串资源，跟随设备语言。
 */
export class CYLTabBarItem {
  /**
   * [EN] The stable identifier: UI tests find the tab by the id "CYLTabBarItem_<identifier>".
   * [CN] 稳定的标识：UI 测试通过 id "CYLTabBarItem_<identifier>" 找到该 Tab。
   */
  identifier: string = '';
  title: ResourceStr = '';
  image?: ResourceStr;
  selectedImage?: ResourceStr;
  /**
   * [EN] The badge: undefined for none, "" for a red dot, a number ("3", "99+") or a text ("NEW").
   * [CN] 角标：undefined 表示无，"" 表示红点，数字（"3"、"99+"）或文本（"NEW"）。
   */
  badgeValue?: string;
  /**
   * [EN] What the screen reader reads instead of the title, as iOS `CYLTabBarItemAccessibilityLabel`.
   * [CN] 屏幕阅读器代替标题朗读的内容，对应 iOS 的 `CYLTabBarItemAccessibilityLabel`。
   */
  accessibilityLabel?: ResourceStr;
  /**
   * [EN] FIX: issue #415. An SVGA 2.x icon in the app's rawfile folder ("svga/tab_home.svga"), iOS `CYLTabBarSVGAFilePath`:
   *      it plays once when the tab is selected and shows its first frame otherwise. `image` shows if it cannot load.
   * [CN] FIX: issue #415。App rawfile 目录中的 SVGA 2.x 图标（"svga/tab_home.svga"），对应 iOS `CYLTabBarSVGAFilePath`：Tab 选中时
   *      播放一次，否则显示第一帧。无法加载时显示 `image`。
   */
  svgaFilePath?: string;
  /**
   * [EN] An SVGA icon at an http(s) URL, iOS `CYLTabBarSVGAURL` (ohos.permission.INTERNET, declared by this module); wins over
   *      `svgaFilePath`.
   * [CN] http(s) 地址上的 SVGA 图标，对应 iOS `CYLTabBarSVGAURL`（ohos.permission.INTERNET，由本模块声明）；优先于 `svgaFilePath`。
   */
  svgaURL?: string;
  /**
   * [EN] The side of the SVGA icon in vp, iOS `CYLTabBarSVGASize`. [CN] SVGA 图标的边长（vp），对应 iOS `CYLTabBarSVGASize`。
   */
  svgaSize: number = 26;

  constructor(identifier: string, title: ResourceStr, image?: ResourceStr, selectedImage?: ResourceStr) {
    this.identifier = identifier;
    this.title = title;
    this.image = image;
    this.selectedImage = selectedImage;
  }
}

/**
 * [EN] The plus button: iOS `CYLPlusButton` (`+plusButton`, `+indexOfPlusButtonInTabBar`). Without a title the screen reader
 *      reads "Plus button" in the device language.
 * [CN] PlusButton：对应 iOS 的 `CYLPlusButton`（`+plusButton`、`+indexOfPlusButtonInTabBar`）。没有标题时，屏幕阅读器以设备语言朗读
 *      “加号按钮”。
 */
export class CYLPlusButton {
  identifier: string = 'CYLPlusButton';
  image?: ResourceStr;
  title?: ResourceStr;
  /**
   * [EN] Its place among the tabs; by default the middle. [CN] 在 Tab 之间的位置；默认居中。
   */
  index: number = -1;
  accessibilityLabel?: ResourceStr;
}

/**
 * [EN] The colors of the bar: iOS `tintColor`, `unselectedItemTintColor`, the bar background and the badge color.
 * [CN] TabBar 的颜色：对应 iOS 的 `tintColor`、`unselectedItemTintColor`、TabBar 背景与角标颜色。
 */
export class CYLTabBarAppearance {
  tintColor: ResourceColor = '#007AFF';
  unselectedItemTintColor: ResourceColor = '#8E8E93';
  backgroundColor: ResourceColor = '#F9F9F9';
  badgeColor: ResourceColor = '#FF3B30';
  plusButtonColor: ResourceColor = '#007AFF';
}
