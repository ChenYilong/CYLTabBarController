/*
 * [EN] The Rive options, `CYLRiveIcon` and the Rive helpers moved to the `cylanimateditemrive` module (shared by every library
 *      that plays .riv files); they are re-exported here, so no cyltabbar API changed.
 * [CN] Rive 选项、`CYLRiveIcon` 与 Rive 辅助函数已移到 `cylanimateditemrive` 模块（所有播放 .riv 文件的库共用）；这里重新导出，
 *      因此 cyltabbar 的 API 没有变化。
 */
export {
  CYLTabBarAnimationOptionRiveArtboard,
  CYLTabBarAnimationOptionRiveStateMachine,
  CYLTabBarAnimationOptionRiveActiveProperty,
  CYLTabBarAnimationOptionRiveActiveDuration,
  CYLTabBarAnimationOptionRiveTriggerProperty,
  CYLTabBarAnimationOptionRiveInput,
  CYLTabBarAnimationOptionRiveTriggerInput,
  CYLTabBarAnimationOptionRiveAnimation,
  CYLTabBarAnimationOptionRiveLegacyRuntime,
  CYLTabBarAnimationOptionRiveNumberInput,
  CYLTabBarAnimationOptionRiveNumberValues,
  cylRiveNextNumber,
  cylRiveFileAndOptions,
  cylRiveRendererType,
  cylRiveIsSupported,
  cylEnsureRiveInitialized,
  CYLRiveIcon
} from 'cylanimateditemrive';


/*
 * [EN] Rive tab icons (iOS `CYLRiveTabBarItemAnimator` + `CYLRiveTabBarItemAnimationView`, Android
 *      `CYLRiveTabBarItemAnimationView`): a .riv file, an artboard and a state machine per tab, driven when the tab is
 *      selected. Keys and options keep the iOS names.
 * [CN] Rive Tab 图标（iOS `CYLRiveTabBarItemAnimator` + `CYLRiveTabBarItemAnimationView`，Android `CYLRiveTabBarItemAnimationView`）：
 *      每个 Tab 一个 .riv 文件、画板与状态机，Tab 选中时驱动。key 与选项沿用 iOS 名称。
 */

/**
 * [EN] `CYLTabBarRiveURL`: a .riv file at an http(s) URL or a rawfile path, with options in its fragment
 *      (`CYLTabBarAnimationURLWithOptions`, e.g. "rive/icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity"; a "?"
 *      query is read too).
 * [CN] .riv 文件的 http(s) 地址或 rawfile 路径，选项放在 fragment 中（也读取 "?" 查询参数）。
 */
export const CYLTabBarRiveURL: string = 'CYLTabBarRiveURL';
/**
 * [EN] `CYLTabBarRiveFilePath`: a rawfile path of a .riv file (the default artboard unless its options name one).
 * [CN] .riv 文件的 rawfile 路径（选项未指定时使用默认画板）。
 */
export const CYLTabBarRiveFilePath: string = 'CYLTabBarRiveFilePath';
/**
 * [EN] `CYLTabBarRiveSize`: the icon size in vp. [CN] 图标尺寸（vp）。
 */
export const CYLTabBarRiveSize: string = 'CYLTabBarRiveSize';
/**
 * [EN] `CYLTabBarRiveDarkURL`: the file in dark mode. [CN] 深色模式的文件地址。
 */
export const CYLTabBarRiveDarkURL: string = 'CYLTabBarRiveDarkURL';
/**
 * [EN] `CYLTabBarRiveDarkFilePath`: the rawfile path in dark mode. [CN] 深色模式的 rawfile 路径。
 */
export const CYLTabBarRiveDarkFilePath: string = 'CYLTabBarRiveDarkFilePath';
/**
 * [EN] `CYLTabBarAnimationOptionTint`: draws a tab's animation (any engine) in one color, like a tinted template image:
 *      "title" = the tab's title color for its state (selected / normal), or a fixed "#RRGGBB" / "#AARRGGBB", as on iOS
 *      and Android. In the animation path's options, e.g. "rive/icons.riv#artboard=CHAT&tint=title".
 * [CN] 以单一颜色绘制 Tab 的动画（任何引擎），与着色的模板图片一致："title" = Tab 当前状态（选中 / 普通）的标题颜色，或固定的
 *      "#RRGGBB" / "#AARRGGBB"，与 iOS、Android 相同。写在动画路径的选项中。
 */
export const CYLTabBarAnimationOptionTint: string = 'tint';
/**
 * [EN] `CYLTabBarAnimationOptionDarkTint`: the fixed tint in dark mode ("title" already follows the title colors).
 * [CN] 深色模式下的固定着色（"title" 已跟随标题颜色）。
 */
export const CYLTabBarAnimationOptionDarkTint: string = 'darkTint';
/** [EN] The "title" value of `CYLTabBarAnimationOptionTint`. [CN] `CYLTabBarAnimationOptionTint` 的 "title" 值。 */
export const CYLTabBarAnimationTintTitle: string = 'title';

/**
 * [EN] `CYLTabBarAnimationURLWithOptions`: a file path or URL with its options in its fragment ("name=value&…",
 *      percent-encoded, sorted by name), replacing a fragment it had, as on iOS and Android
 *      ("rive/icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity"). `cylRiveFileAndOptions` also reads options
 *      after "?", the form this function wrote before 2026-11-23 and the configuration files still use.
 * [CN] 把选项写入文件路径或地址的 fragment（「名称=值&…」，百分号编码，按名称排序），替换原有的 fragment，与 iOS、Android 相同。
 *      `cylRiveFileAndOptions` 也读取 "?" 之后的选项（本函数 2026-11-23 之前的写法，配置文件仍在使用）。
 */
export function CYLTabBarAnimationURLWithOptions(file: string, options: Record<string, string>): string {
  const hash = file.indexOf('#');
  const base = hash >= 0 ? file.substring(0, hash) : file;
  const pairs: string[] = Object.keys(options)
    .filter((key: string) => key.length > 0 && options[key] !== undefined && options[key].length > 0)
    .sort()
    .map((key: string) => `${encodeURIComponent(key)}=${encodeURIComponent(options[key])}`);
  return pairs.length > 0 ? `${base}#${pairs.join('&')}` : base;
}
