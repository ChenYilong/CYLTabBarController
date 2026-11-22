import { CYLAnimatedItemEngineState, CYLAnimatedItemSource } from 'cylanimateditem';
import { CYLAnimatedItemRiveView } from 'cylanimateditem_rive';


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
 * [EN] `CYLTabBarAnimationOptionRiveArtboard`: the artboard. [CN] 画板。
 */
export const CYLTabBarAnimationOptionRiveArtboard: string = 'artboard';
/**
 * [EN] `CYLTabBarAnimationOptionRiveStateMachine`: the state machine. [CN] 状态机。
 */
export const CYLTabBarAnimationOptionRiveStateMachine: string = 'stateMachine';
/**
 * [EN] `CYLTabBarAnimationOptionRiveActiveProperty`: the view model boolean set while the tab plays ("active").
 * [CN] Tab 播放期间设为 true 的 view model 布尔属性（"active"）。
 */
export const CYLTabBarAnimationOptionRiveActiveProperty: string = 'active';
/**
 * [EN] `CYLTabBarAnimationOptionRiveActiveDuration`: seconds the boolean stays true ("1"); "0" keeps it until stop.
 * [CN] 布尔值保持 true 的秒数（"1"）；"0" 表示保持到停止。
 */
export const CYLTabBarAnimationOptionRiveActiveDuration: string = 'duration';
/**
 * [EN] `CYLTabBarAnimationOptionRiveTriggerProperty`: a view model trigger fired instead. [CN] 改为触发的 view model trigger。
 */
export const CYLTabBarAnimationOptionRiveTriggerProperty: string = 'trigger';
/**
 * [EN] `CYLTabBarAnimationOptionRiveInput`: a state machine boolean input (legacy files). [CN] 状态机布尔输入（旧版文件）。
 */
export const CYLTabBarAnimationOptionRiveInput: string = 'input';
/**
 * [EN] `CYLTabBarAnimationOptionRiveTriggerInput`: a state machine trigger input (legacy files). [CN] 状态机 trigger 输入（旧版文件）。
 */
export const CYLTabBarAnimationOptionRiveTriggerInput: string = 'triggerInput';
/**
 * [EN] `CYLTabBarAnimationOptionRiveAnimation`: a linear animation played instead of a state machine. [CN] 改为播放的线性动画。
 */
export const CYLTabBarAnimationOptionRiveAnimation: string = 'animation';
/**
 * [EN] `CYLTabBarAnimationOptionRiveLegacyRuntime`: "1" plays the file with no view model. [CN] "1" 表示不使用 view model 播放。
 */
export const CYLTabBarAnimationOptionRiveLegacyRuntime: string = 'legacy';
/**
 * [EN] `CYLTabBarAnimationOptionRiveNumberInput`: a state machine number input set to the next of `values` on each play
 *      (house.riv: "Rooms").
 * [CN] 每次播放设为 `values` 中下一个值的状态机数字输入（house.riv："Rooms"）。
 */
export const CYLTabBarAnimationOptionRiveNumberInput: string = 'numberInput';
/**
 * [EN] `CYLTabBarAnimationOptionRiveNumberValues`: the values the number input steps through, "3,4,5,6", cycling; without it, +1.
 * [CN] 数字输入依次使用的值，"3,4,5,6"，循环；没有时 +1。
 */
export const CYLTabBarAnimationOptionRiveNumberValues: string = 'values';

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

/**
 * [EN] The file part and the options of a Rive URL. The options follow "#" (the fragment `CYLTabBarAnimationURLWithOptions`
 *      writes, as on iOS and Android, CYLTableViewPlaceHolder and the WeChat Mini Program) or "?" (the earlier HarmonyOS
 *      form, still in the configuration files), whichever comes first; pairs after both are read
 *      ("file.riv?artboard=CHAT#input=active").
 * [CN] Rive 地址的文件部分与选项。选项跟在 "#"（`CYLTabBarAnimationURLWithOptions` 写入的 fragment，与 iOS、Android、CYLTableViewPlaceHolder、
 *      微信小程序相同）或 "?"（鸿蒙之前的写法，配置文件仍在使用）之后，以先出现者为准；两者之后的键值对都会读取。
 */
/**
 * [EN] The "name=value" pairs after the first "?" or "#": split at "&", and at a "?" or "#" that starts the next group
 *      ("artboard=CHAT#input=active"), not one inside a value ("tint=#FF0000", a color written without encoding).
 * [CN] 第一个 "?" 或 "#" 之后的「名称=值」对：在 "&" 处分开，也在开始下一组的 "?" 或 "#" 处分开（"artboard=CHAT#input=active"），
 *      但不在值内部的 "#" 处分开（"tint=#FF0000"，未编码的颜色）。
 */
function cylRiveOptionPairs(text: string): string[] {
  const pairs: string[] = [];
  text.split('&').forEach((piece: string) => {
    let start = 0;
    for (let i = 1; i < piece.length; i++) {
      const c = piece.charAt(i);
      if ((c === '#' || c === '?') && piece.charAt(i - 1) !== '=') {
        pairs.push(piece.substring(start, i));
        start = i + 1;
      }
    }
    pairs.push(piece.substring(start));
  });
  return pairs;
}

export function cylRiveFileAndOptions(url: string): [string, Record<string, string>] {
  const options: Record<string, string> = {};
  const query = url.indexOf('?');
  const hash = url.indexOf('#');
  const at = query < 0 ? hash : (hash < 0 ? query : Math.min(query, hash));
  if (at < 0) {
    return [url, options];
  }
  cylRiveOptionPairs(url.substring(at + 1)).forEach((pair: string) => {
    const eq = pair.indexOf('=');
    if (eq > 0) {
      options[decodeURIComponent(pair.substring(0, eq))] = decodeURIComponent(pair.substring(eq + 1));
    }
  });
  return [url.substring(0, at), options];
}

/**
 * [EN] The Rive engine lives in the cylanimateditem_rive module (shared by every app that shows CYLAnimatedItemView); these
 *      names stay exported from cyltabbar for compatibility. `cylRiveNextNumber`: the number input's next value.
 * [CN] Rive 引擎位于 cylanimateditem_rive 模块（所有显示 CYLAnimatedItemView 的 App 共用）；为兼容起见，这些名称仍由 cyltabbar 导出。
 */
export { cylRiveRendererType, cylRiveIsSupported, cylEnsureRiveInitialized, cylRiveNextNumber } from 'cylanimateditem_rive';

/**
 * [EN] A Rive tab icon: a thin wrapper over cylanimateditem_rive's engine view (`CYLAnimatedItemRiveView`), which plays it
 *      (restart on every play, inputs, loop, the end of a pass, the artboard kept after reset; see CYLAnimatedItemRive.ets).
 *      Built once per tab and driven through `selected`, `replayToken` and `loops` (never rebuilt on a selection change, so
 *      no Rive surface is created again); it never takes the tab's taps and is hidden from accessibility. A file that cannot
 *      load calls `onLoadError`, and the tab shows its image.
 * [CN] Rive Tab 图标：cylanimateditem_rive 引擎视图（`CYLAnimatedItemRiveView`）的薄封装，由它播放（每次播放从头开始、输入、循环、一遍结束、
 *      reset 后保留画板；见 CYLAnimatedItemRive.ets）。每个 Tab 只创建一次，通过 `selected`、`replayToken` 与 `loops` 驱动（选中变化不会重建，
 *      因此不会再次创建 Rive surface）；不拦截 Tab 的点击，对无障碍隐藏。文件无法加载时调用 `onLoadError`，Tab 显示图片。
 */
@Component
export struct CYLRiveIcon {
  @Prop @Watch('cylReload') path: string = '';
  iconSize: number = 26;
  @Prop @Watch('cylUpdate') selected: boolean = false;
  @Prop @Watch('cylReplay') replayToken: number = 0;
  /**
   * [EN] Plays again after each pass while the tab is selected (docs/Animated-Item.md, the Rive loop); off by default.
   * [CN] Tab 选中期间，每次播放后再次播放（docs/Animated-Item.md，Rive 循环）；默认关闭。
   */
  @Prop @Watch('cylUpdate') loops: boolean = false;
  onLoadError: (message: string) => void = () => {};
  /**
   * [EN] Hands the host this view's replay, called on each restart (CYLAnimatedItemView `setRestartHandler`, B23).
   * [CN] 把本视图的重播交给宿主，每次重播时调用（CYLAnimatedItemView `setRestartHandler`，B23）。
   */
  registerReplay: (replay: () => void) => void = (_replay: () => void) => {};
  /** [EN] The file is drawn. [CN] 文件已绘制。 */
  onLoaded: () => void = () => {};
  /** [EN] A play-once pass (`loops` off) came to rest. [CN] 只播放一次（`loops` 关闭）的一遍播放停止。 */
  onEnded: () => void = () => {};
  private state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();

  aboutToAppear(): void {
    const state = this.state;
    state.source = CYLAnimatedItemSource.parse(this.path);
    state.width = this.iconSize;
    state.height = this.iconSize;
    state.selected = this.selected;
    state.loops = this.loops;
    state.onLoaded = () => this.onLoaded();
    state.onEnded = () => this.onEnded();
    state.onFailed = () => this.onLoadError('the Rive file could not be played: ' + this.path);
    this.registerReplay(() => this.cylReplay());
  }

  /** [EN] A new path (the dark file after a color mode change) reloads the file. [CN] 新路径（如切换深色模式后）重新加载文件。 */
  cylReload(): void {
    this.state.source = CYLAnimatedItemSource.parse(this.path);
    this.state.changed();
  }

  cylUpdate(): void {
    this.state.selected = this.selected;
    this.state.loops = this.loops;
    this.state.changed();
  }

  /** [EN] Plays from the start again, only while selected. [CN] 仅在选中时重新从头播放。 */
  cylReplay(): void {
    if (this.selected) {
      this.state.restartToken += 1;
      this.state.changed();
    }
  }

  build() {
    Stack() {
      CYLAnimatedItemRiveView({ state: this.state })
    }
    .width(this.iconSize)
    .height(this.iconSize)
    // [EN] The icon never takes the tab's taps and is not read on its own. [CN] 图标不拦截 Tab 的点击，也不单独朗读。
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no-hide-descendants')
  }
}
