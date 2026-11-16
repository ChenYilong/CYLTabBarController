import { CYLTabBarStyleType, CYLTabButtonTapAnimationType } from 'cyltabbar';

/**
 * [EN] Item 49: the tab bar gallery (iOS CYLTabBarGalleryViewController, Android DemoGallery.kt): every scene is a tab bar
 *      built with the public API. A scene is data here; pages/GalleryScene builds it. Scenes that need a UIKit-only
 *      feature keep their row with the reason (as the Android gallery does).
 * [CN] 第 49 项：TabBar 场景展示：每个场景都是用公开 API 构建的 TabBar。场景在此为数据，由 pages/GalleryScene 构建。依赖 UIKit 专有功能的
 *      场景保留其行并说明原因（与 Android 相同）。
 */
export interface DemoGalleryScene {
  id: string;
  title: string;
  subtitle: string;
  /** [EN] Why it cannot be shown on HarmonyOS; undefined when it can. [CN] 鸿蒙上无法展示的原因。 */
  unavailable?: string;
  /** [EN] 'system' opens the ArkUI Tabs page instead of a CYLTabBarController. [CN] 'system' 打开 ArkUI Tabs 页面。 */
  system?: boolean;
  tabs?: number;
  style?: CYLTabBarStyleType;
  selected?: number;
  /** [EN] Badge per tab: '' dot, text, or undefined. [CN] 每个 Tab 的角标。 */
  badges?: (string | undefined)[];
  badgeColor?: string;
  tapAnimation?: CYLTabButtonTapAnimationType;
  /** [EN] Per-tab title colors (selected). [CN] 每个 Tab 的选中标题颜色。 */
  colors?: string[];
  backgrounds?: boolean;
  plus?: boolean;
  /** [EN] The plus button opens a menu instead of a page. [CN] 加号按钮打开菜单。 */
  plusMenu?: boolean;
  /** [EN] The identifier of a tab that opens a dialog instead of its page (cyl_customActionTabBarItemIdentifiers). [CN] 打开弹窗的 Tab。 */
  customAction?: string;
  insets?: number;
  lottie?: boolean;
  /** [EN] The middle tab pulses every 3 s until it is selected. [CN] 中间 Tab 每 3 秒跳动一次，直到被选中。 */
  suggest?: boolean;
  /** [EN] The fifth tab opens a menu of the other pages (issue #472). [CN] 第五个 Tab 打开其余页面的菜单。 */
  more?: boolean;
}

const LG = CYLTabBarStyleType.LiquidGlass;
const FD = CYLTabBarStyleType.FlatDesign;
const B = CYLTabButtonTapAnimationType.Bounce;

export interface DemoGallerySection {
  title: string;
  scenes: DemoGalleryScene[];
}

export const DEMO_GALLERY: DemoGallerySection[] = [
  { title: 'Basic', scenes: [
    { id: 'system-3', title: 'System tab bar style', subtitle: 'ArkUI Tabs, the system tab bar, for comparison', system: true },
    { id: 'like-system', title: 'CYLTabBarController like system style', subtitle: 'Three tabs; full width', tabs: 3 },
    { id: 'mix', title: 'Mix styled and system items', subtitle: 'Every tab bounces when tapped', tabs: 5, tapAnimation: B },
    { id: 'liquid-photo', title: 'CYLTabBarController with Liquid Glass', subtitle: '"Photo" opens a dialog (cyl_customActionTabBarItemIdentifiers)', tabs: 5, style: LG, customAction: 'photo' },
    { id: 'more-8', title: 'CYLTabBarController with 8 tabs', subtitle: 'Eight tabs, full width', tabs: 8 },
    { id: 'mix-8', title: 'Mix styled and system items with 8 tabs', subtitle: 'Eight tabs that bounce', tabs: 8, tapAnimation: B },
    { id: 'liquid-8', title: 'Liquid Glass with 8 tabs', subtitle: 'Eight tabs with Liquid Glass', tabs: 8, style: LG },
    { id: 'index-2', title: 'CYLTabBarController with non-zero default index', subtitle: 'selectedIndex = 2 after presenting', tabs: 5, selected: 2 },
    { id: 'flat-photo', title: 'Classic design on every system', subtitle: 'CYLTabBarStyleTypeFlatDesign; "Photo" opens a dialog', tabs: 5, style: FD, customAction: 'photo' },
    { id: 'liquid-badges', title: 'Liquid Glass with badges', subtitle: 'New, 99+, a blue 1, a dot, none', tabs: 5, style: LG, badges: ['new', '100', '1', '', undefined] },
    { id: 'system-more', title: 'System tab bar with "More"', subtitle: 'UIKit\'s "More" controller', unavailable: 'n/a on HarmonyOS: ArkUI Tabs has no automatic "More" tab; see "8 tabs without the system More"' },
  ] },
  { title: 'Embed', scenes: [
    { id: 'nav-embeds', title: 'A navigation bar above the tab bar controller', subtitle: 'One navigation bar for all tabs', tabs: 4 },
    { id: 'embeds-nav', title: 'CYLTabBarController embeds navigation stacks', subtitle: 'A navigation stack in every tab (cyl_pushViewController)', tabs: 4 },
  ] },
  { title: 'Animation', scenes: [
    { id: 'colors', title: 'Customize the selected color', subtitle: 'CYLTabBarItemSelectedTitleColor per tab', tabs: 4, colors: ['#FF3B30', '#34C759', '#007AFF', '#AF52DE'] },
    { id: 'spring', title: 'Spring animation', subtitle: 'A bounce on select and reselect', tabs: 4, tapAnimation: B },
    { id: 'backgrounds', title: 'Background color change', subtitle: 'CYLTabBarItemBackgroundColor / SelectedBackgroundColor', tabs: 4, backgrounds: true },
    { id: 'pressed', title: 'With a pressed effect', subtitle: 'Icons shrink and grow back on a tap', tabs: 4, tapAnimation: CYLTabButtonTapAnimationType.Scale },
    { id: 'suggest', title: 'Suggest a click', subtitle: 'The middle tab pulses every 3 s until it is selected', tabs: 5, suggest: true },
  ] },
  { title: 'Irregular', scenes: [
    { id: 'big-plus', title: 'A larger button in the middle', subtitle: 'A raised round CYLPlusButton', tabs: 4, plus: true },
  ] },
  { title: 'Customize click', scenes: [
    { id: 'plus-menu', title: 'Custom action for the button click', subtitle: 'The center button shows a menu instead of a page', tabs: 4, plus: true, plusMenu: true },
    { id: 'bubble', title: 'Add a special reminder bubble', subtitle: 'A NEW bubble above "Me"; "Photo" opens a dialog', tabs: 5, badges: [undefined, undefined, undefined, undefined, 'NEW'], customAction: 'photo' },
  ] },
  { title: 'Remind', scenes: [
    { id: 'system-remind', title: 'System remind style', subtitle: 'Badges on the ArkUI system tab bar', system: true },
    { id: 'imitate-remind', title: 'Imitate system remind style', subtitle: 'The same badges on CYLTabBarController', tabs: 4, badges: ['3', '', '100', undefined] },
    { id: 'remind-anim', title: 'Remind with animation', subtitle: 'The icon jumps when tapped and the badge bounces', tabs: 4, badges: ['3', undefined, '1', undefined], tapAnimation: B },
    { id: 'remind-gray', title: 'Customize remind style', subtitle: 'A gray bubble instead of the red badge', tabs: 4, badges: ['8', undefined, 'hot', undefined], badgeColor: '#8E8E93' },
  ] },
  { title: 'Lottie', scenes: [
    { id: 'lottie', title: 'Lottie', subtitle: 'Lottie tab icons that play on select', tabs: 4, lottie: true },
  ] },
  { title: 'New APIs', scenes: [
    { id: 'custom-action', title: 'Custom action on a regular tab', subtitle: 'cyl_customActionTabBarItemIdentifiers', tabs: 5, customAction: 'video' },
    { id: 'per-tab', title: 'Per-tab colors and backgrounds', subtitle: 'Every tab has its own title color and background', tabs: 4, colors: ['#FF9500', '#5856D6', '#FF2D55', '#34C759'], backgrounds: true },
    { id: 'accessibility', title: 'Accessibility identifiers', subtitle: 'Each tab has an id cyl-tab-<identifier> and a screen reader label', tabs: 5 },
    { id: 'centered-plus', title: 'Centered tabs around a plus button', subtitle: 'cyl_itemEdgeInsets packs the tabs around the plus button', tabs: 4, plus: true, insets: 30 },
    { id: 'insets', title: 'Edge insets', subtitle: 'cyl_itemEdgeInsets 16 vp at each end', tabs: 4, insets: 16 },
    { id: 'icon-rendering', title: 'Icon rendering mode (#787)', subtitle: 'Template / original icons', unavailable: 'n/a on HarmonyOS yet: tab icons are drawn as they are (no template tint)' },
  ] },
  { title: 'Liquid Glass robustness', scenes: [
    { id: 'plus-stand-in', title: 'Plus stand-in after an item image changes', subtitle: 'Liquid Glass only', unavailable: 'n/a on HarmonyOS: the stand-in exists because UIKit rebuilds the Liquid Glass tab bar; ArkUI updates the plus button in place' },
    { id: 'more-editing', title: 'More editing with 8 tabs', subtitle: 'UIKit\'s "More" editor', unavailable: 'n/a on HarmonyOS: the "More" editor (Edit, drag, Done) is UIKit API' },
  ] },
  { title: 'More than five tabs', scenes: [
    { id: 'more-menu', title: '8 tabs without the system "More"', subtitle: 'Issue #472: the fifth tab opens a menu of the other pages', tabs: 5, more: true },
  ] },
];
