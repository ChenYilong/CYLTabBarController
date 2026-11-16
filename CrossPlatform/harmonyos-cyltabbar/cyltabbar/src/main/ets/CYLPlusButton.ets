/**
 * [EN] The plus button (CYLPlusButton.h, the CYLPlusButton* keys of CYLTabBarController.h): an extra button in the tab bar,
 *      raised by centerYOffset, with an optional title aligned with the tab titles, and an optional page (a selectable
 *      plus button, +plusChildViewController).
 * [CN] 加号按钮（CYLPlusButton.h，及 CYLTabBarController.h 的 CYLPlusButton* 键）：TabBar 中的额外按钮，按 centerYOffset 上移，
 *      可带与 Tab 标题对齐的标题，可带页面（可选中的加号按钮，+plusChildViewController）。
 */
export interface CYLPlusButton {
  /** [EN] The image (CYLPlusButtonBackgroundImage / -setImage:). [CN] 图片。 */
  image?: ResourceStr;
  /** [EN] CYLPlusButtonBackgroundImage / -setBackgroundImage:: drawn behind the image. [CN] 图片下方的背景图。 */
  backgroundImage?: ResourceStr;
  /** [EN] The image while selected or pressed. [CN] 选中或按下时的图片。 */
  selectedImage?: ResourceStr;
  /** [EN] The title (-setTitle:forState:). [CN] 标题。 */
  title?: ResourceStr;
  /** [EN] +indexOfPlusButtonInTabBar / CYLPlusButtonIndexInTabBar; the middle when unset. [CN] 在 TabBar 中的位置；未设置时居中。 */
  index?: number;
  /** [EN] +constantOfPlusButtonCenterYOffsetForTabBarHeight: / CYLPlusButtonCenterYOffset (vp, negative is up). [CN] 中心 y 偏移（vp，负数向上）。 */
  centerYOffset?: number;
  /** [EN] CYLPlusButtonImageSize (vp). [CN] 图片尺寸（vp）。 */
  imageSize?: number;
  /** [EN] CYLPlusButtonAlignsTitle: the title on the line of the tab titles. [CN] 标题与 Tab 标题在同一行。 */
  alignsTitle?: boolean;
  /** [EN] CYLTabBarItemIdentifier of the plus button. [CN] 加号按钮的 identifier。 */
  identifier?: string;
  /** [EN] CYLPlusButtonShowsSelection / +plusChildViewController: the plus button selects a page. [CN] 加号按钮可选中并显示页面。 */
  selectable?: boolean;
  /** [EN] touchableAreaScale (issue #91): scales the touchable area around the center, 1 by default. [CN] 可点击区域绕中心的缩放，默认 1。 */
  touchableAreaScale?: number;
  /** [EN] touchableAreaOutsets (issue #91, vp). [CN] 可点击区域四周的扩展（vp）。 */
  touchableAreaOutsets?: CYLPlusButtonInsets;
  /** [EN] showsTouchableArea: a translucent overlay of the touchable area (debugging aid). [CN] 以半透明遮罩显示可点击区域（调试用）。 */
  showsTouchableArea?: boolean;
  /** [EN] touchableAreaColor; translucent red when unset. [CN] 遮罩颜色；未设置时为半透明红色。 */
  touchableAreaColor?: ResourceColor;
}

/** [EN] UIEdgeInsets of the touchable area (vp). [CN] 可点击区域的边距（vp）。 */
export interface CYLPlusButtonInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * [EN] How far (vp) the plus button rises above the top of the tab bar, 0 when it stays inside the bar. The tab bar is laid
 *      out over the pages, so an app keeps the end of a page clear of the raised button with this value (for example
 *      `List.contentEndOffset(cyl_plusButtonOverhang(plusButton))`, or a bottom padding). Same layout as the plus slot of
 *      CYLTabBarController: with an aligned title the image sits right above the title, whose top is at tabBarHeight - 17;
 *      otherwise the image (and a title under it, 14 vp) is centred in the bar and moved by centerYOffset. In Liquid Glass
 *      the content moves down by (capsule height 61 - tabBarHeight) / 2 inside the taller capsule: pass that as contentDy
 *      (the result is then measured from the capsule's top).
 * [CN] 加号按钮高出 TabBar 顶部的距离（vp），未高出时为 0。TabBar 覆盖在页面之上，App 可用此值让页面末尾避开凸起的按钮（例如
 *      `List.contentEndOffset(cyl_plusButtonOverhang(plusButton))` 或底部内边距）。与 CYLTabBarController 中加号槽位的布局相同：
 *      标题对齐时图片紧贴标题上方，标题顶部在 tabBarHeight - 17；否则图片（及其下方 14 vp 的标题）在 TabBar 中居中并按
 *      centerYOffset 移动。液态玻璃中内容在更高的胶囊内下移 (61 - tabBarHeight) / 2：将其作为 contentDy 传入（结果从胶囊顶部量起）。
 */
export function cyl_plusButtonOverhang(plusButton: CYLPlusButton | undefined, tabBarHeight: number = 49,
  contentDy: number = 0): number {
  if (plusButton === undefined) {
    return 0;
  }
  const imageSize = plusButton.imageSize ?? 54;
  if (plusButton.title !== undefined && plusButton.alignsTitle !== false) {
    return Math.max(0, imageSize - (tabBarHeight - 17) - contentDy);
  }
  const contentHeight = imageSize + (plusButton.title !== undefined ? 14 : 0);
  const top = contentDy + (tabBarHeight - contentHeight) / 2 + (plusButton.centerYOffset ?? 0);
  return Math.max(0, -top);
}
