/**
 * [EN] The plus button (CYLPlusButton.h, the CYLPlusButton* keys of CYLTabBarController.h): an extra button in the tab bar,
 *      raised by centerYOffset, with an optional title aligned with the tab titles, and an optional page (a selectable
 *      plus button, +plusChildViewController).
 * [CN] 加号按钮（CYLPlusButton.h，及 CYLTabBarController.h 的 CYLPlusButton* 键）：TabBar 中的额外按钮，按 centerYOffset 上移，
 *      可带与 Tab 标题对齐的标题，可带页面（可选中的加号按钮，+plusChildViewController）。
 */
export interface CYLPlusButton {
  /** [EN] The image (CYLPlusButtonBackgroundImage / -setImage:). [CN] 图片。 */
  image: ResourceStr;
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
}
