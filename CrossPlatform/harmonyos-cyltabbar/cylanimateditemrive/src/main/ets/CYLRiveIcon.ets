import { CYLAnimatedItemEngineState, CYLAnimatedItemPlayer, CYLAnimatedItemSource } from 'cylanimateditem';
import { CYLAnimatedItemRiveView } from './CYLAnimatedItemRive';
import { CYLRiveLoopPolicy } from './CYLRiveLoopPolicy';

/*
 * [EN] Rive for HarmonyOS, shared by every library that plays .riv files (cyltabbar's tab icons, CYLAnimatedItemView items such
 *      as CYLTableViewPlaceHolder placeholders, CYLSearchViewController tags, CollectionViewClassifyMenu): the Rive options,
 *      `CYLRiveIcon` is a thin component over the engine (`CYLAnimatedItemRive.ets`, one copy of the Rive logic) and adds the loop policy. Moved from cyltabbar's CYLRiveTabBarItemAnimator
 *      (cyltabbar re-exports every name). Keys and options keep the iOS names.
 * [CN] 鸿蒙版 Rive，由所有播放 .riv 文件的库共用（cyltabbar 的 Tab 图标、CYLAnimatedItemView 条目，如 CYLTableViewPlaceHolder 的占位图、
 *      CYLSearchViewController 的标签、CollectionViewClassifyMenu）：Rive 选项、`CYLRiveIcon` 及其循环与重播修复只在这里维护一份。
 *      从 cyltabbar 的 CYLRiveTabBarItemAnimator 移来（cyltabbar 重新导出所有名称）。key 与选项沿用 iOS 名称。
 */

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
 * [EN] `CYLTabBarAnimationOptionRiveColor`: "#RRGGBB" or "#RRGGBBAA", set on the view model color "color" when the file
 *      loads (as iOS and Android).
 * [CN] "#RRGGBB" 或 "#RRGGBBAA"，文件加载时设置到 view model 颜色 "color"（与 iOS、Android 一致）。
 */
export const CYLTabBarAnimationOptionRiveColor: string = 'color';

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

export { cylRiveNextNumber } from './CYLAnimatedItemRiveOptions';
export { cylRiveRendererType, cylRiveIsSupported, cylEnsureRiveInitialized } from './CYLAnimatedItemRive';

/**
 * [EN] A Rive tab icon, props as before: built once per tab and driven through `selected`, `replayToken` and `loops`; a
 *      thin component over the engine view (`CYLAnimatedItemRiveView`, which holds all the Rive logic), it only decides when
 *      the engine's player plays or rests by `loopPolicy` (`CYLRiveLoopPolicy`). The engine never takes the tab's taps and is
 *      hidden from accessibility. A file that cannot load calls `onLoadError`, and the tab shows its image.
 * [CN] Rive Tab 图标，属性不变：每个 Tab 只创建一次，通过 `selected`、`replayToken` 与 `loops` 驱动；它是引擎视图（`CYLAnimatedItemRiveView`，
 *      包含全部 Rive 逻辑）之上的薄组件，只按 `loopPolicy`（`CYLRiveLoopPolicy`）决定引擎的播放器何时播放或静止。文件无法加载时调用 `onLoadError`，
 *      Tab 显示图片。
 */
@Component
export struct CYLRiveIcon {
  @Prop @Watch('cylReload') path: string = '';
  iconSize: number = 26;
  @Prop @Watch('cylUpdate') selected: boolean = false;
  @Prop @Watch('cylReplay') replayToken: number = 0;
  /** [EN] Plays again after each pass (see `loopPolicy`); off by default. [CN] 每次播放后再次播放（见 `loopPolicy`）；默认关闭。 */
  @Prop @Watch('cylLoopsChanged') loops: boolean = false;
  /**
   * [EN] When `loops` repeats the pass: `CYLRiveLoopPolicy.WhileSelected` (default, the tab bar: only while `selected`) or
   *      `CYLRiveLoopPolicy.WhilePlaying` (tags, placeholders: from the first play until `loops` goes off or the item is
   *      unselected after it was selected; a restart plays and loops again).
   * [CN] `loops` 在什么时候重复播放：`WhileSelected`（默认，Tab 栏：仅在 `selected` 期间）或 `WhilePlaying`（标签、占位图：从第一次播放起，
   *      直到 `loops` 关闭，或条目在被选中之后又取消选中；重播会再次播放并循环）。
   */
  @Prop loopPolicy: string = CYLRiveLoopPolicy.WhileSelected;
  onLoadError: (message: string) => void = () => {};
  /** [EN] Hands the host this view's replay, called on each restart. [CN] 把本视图的重播交给宿主，每次重播时调用。 */
  registerReplay: (replay: () => void) => void = (_replay: () => void) => {};
  /** [EN] The file is drawn. [CN] 文件已绘制。 */
  onLoaded: () => void = () => {};
  /** [EN] A play-once pass came to rest. [CN] 只播放一次的一遍播放停止。 */
  onEnded: () => void = () => {};
  private engine: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  private player?: CYLAnimatedItemPlayer;
  /** [EN] `selected` was true and has not gone false since. [CN] `selected` 曾为 true 且此后未变为 false。 */
  private wasSelected: boolean = false;
  /** [EN] WhilePlaying: the item was stopped and nothing has asked it to play since. [CN] WhilePlaying：条目已停止，此后没有再请求播放。 */
  private stopRequested: boolean = false;

  aboutToAppear(): void {
    this.registerReplay(() => this.cylReplay());
    const engine = this.engine;
    engine.drivesPlayback = false;
    engine.width = this.iconSize;
    engine.height = this.iconSize;
    engine.loops = this.loops;
    engine.source = CYLAnimatedItemSource.parse(this.path);
    engine.onPlayer = (player: CYLAnimatedItemPlayer | undefined) => {
      this.player = player;
      if (player !== undefined) {
        player.loops = this.loops;
        this.cylUpdate();
      }
    };
    engine.onLoaded = () => this.onLoaded();
    engine.onFailed = () => this.onLoadError('Rive file failed to load');
    engine.onEnded = () => this.onEnded();
  }

  /** [EN] A new path (the dark file after a color mode change) reloads the file. [CN] 新路径（如切换深色模式后）重新加载文件。 */
  cylReload(): void {
    this.engine.source = CYLAnimatedItemSource.parse(this.path);
    this.engine.changed();
  }

  cylLoopsChanged(): void {
    this.engine.loops = this.loops;
    if (this.player !== undefined) {
      this.player.loops = this.loops;
    }
  }

  /** [EN] Plays or rests by the loop policy (CYLRiveLoopPolicy.updateAction). [CN] 按循环策略播放或静止。 */
  cylUpdate(): void {
    const player = this.player;
    if (player === undefined) {
      return;
    }
    const action = CYLRiveLoopPolicy.updateAction(this.loopPolicy, this.selected, this.wasSelected, this.stopRequested);
    if (this.selected) {
      this.wasSelected = true;
      this.stopRequested = false;
    } else if (action === CYLRiveLoopPolicy.Stop) {
      this.wasSelected = false;
      this.stopRequested = true;
    }
    if (action === CYLRiveLoopPolicy.Play) {
      player.play();
    } else if (action === CYLRiveLoopPolicy.Stop) {
      player.stopAtProgress(0);
    }
  }

  /** [EN] A restart plays from the start (and loops again). [CN] 重播从头播放（并再次循环）。 */
  cylReplay(): void {
    const player = this.player;
    if (player !== undefined && (this.selected || this.loopPolicy === CYLRiveLoopPolicy.WhilePlaying)) {
      this.stopRequested = false;
      player.play();
    }
  }

  build() {
    CYLAnimatedItemRiveView({ state: this.engine })
  }
}
