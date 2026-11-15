import { cyl_localizationKey } from 'cyltabbar';

/**
 * [EN] The rows of the example's tab pages, as DemoCatalog.kt of the Android port: every tab shows the same demo
 *      sections (iOS CYLTabBarDemoSection, CYLSettingsSection), then its own badge rows (item 51).
 * [CN] 示例 Tab 页面的行，对应 Android 端 DemoCatalog.kt：每个 Tab 显示相同的演示分组（iOS CYLTabBarDemoSection、CYLSettingsSection），
 *      然后是自己的角标行（第 51 项）。
 */
export interface DemoRow {
  /** [EN] Stable id, used by the UI tests (`cyl-row-<id>`). [CN] 稳定 id，供 UI 测试使用。 */
  id: string;
  title: string;
  subtitle?: string;
  /** [EN] A badge sample row (its index), shown on the row's icon. [CN] 角标样例行（索引），显示在行图标上。 */
  badgeRow?: number;
  action: () => void;
}

export interface DemoSection {
  title: string;
  rows: DemoRow[];
}

/**
 * [EN] A standardAppearance theme (iOS UITabBarAppearance; Android applyAppearance in DemoCatalog.kt).
 * [CN] standardAppearance 主题（iOS UITabBarAppearance；Android DemoCatalog.kt 的 applyAppearance）。
 */
export interface DemoAppearance {
  name: string;
  background: ResourceColor;
  shadow: ResourceColor;
  normal: ResourceColor;
  selected: ResourceColor;
  /** [EN] The centered capsule behind the selected tab. [CN] 选中 Tab 后的居中胶囊。 */
  capsule?: ResourceColor;
}

export const DEMO_APPEARANCES: DemoAppearance[] = [
  { name: cyl_localizationKey('原始'), background: '#F8F8F8', shadow: '#33000000', normal: '#808080', selected: '#FF8000' },
  { name: cyl_localizationKey('深色'), background: '#141414', shadow: '#00000000', normal: '#C0C0C0', selected: '#FFFFFF' },
  { name: cyl_localizationKey('居中胶囊'), background: '#F8F8F8', shadow: '#1F000000', normal: '#808080', selected: '#FF2D55', capsule: '#33FF2D55' },
  { name: cyl_localizationKey('绿色描边'), background: '#FFFFFF', shadow: '#34C759', normal: '#808080', selected: '#34C759' },
];

/** [EN] Title offsets the title offset row cycles through (vp). [CN] 标题偏移行循环使用的偏移（vp）。 */
export const DEMO_TITLE_OFFSETS: number[] = [0, -4, 4];

/** [EN] The page identifiers of the four tabs. [CN] 四个 Tab 的页面 identifier。 */
export const DEMO_HOME: string = 'home';
export const DEMO_CITY: string = 'city';
export const DEMO_MESSAGE: string = 'message';
export const DEMO_ME: string = 'CYLMineViewController';

/** [EN] The language row's choices: '' follows the system. [CN] 语言行的选项：'' 跟随系统。 */
export const DEMO_LANGUAGES: string[] = ['', 'en-Latn-US', 'zh-Hans-CN'];
export const DEMO_LANGUAGE_NAMES: string[] = [cyl_localizationKey('跟随系统'), 'English', '简体中文'];
