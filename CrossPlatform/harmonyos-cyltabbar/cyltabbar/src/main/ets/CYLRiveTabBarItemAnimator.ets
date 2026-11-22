import { Fit, Loop, RendererType, RiveAnimationView, SMINumber, ViewModelInstance, initializeRive } from '@ohos/rive';
import { deviceInfo } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { CYLAnimatedItemEngines } from 'cylanimateditem';

/*
 * [EN] Rive tab icons (iOS `CYLRiveTabBarItemAnimator` + `CYLRiveTabBarItemAnimationView`, Android
 *      `CYLRiveTabBarItemAnimationView`): a .riv file, an artboard and a state machine per tab, driven when the tab is
 *      selected. Keys and options keep the iOS names.
 * [CN] Rive Tab 图标（iOS `CYLRiveTabBarItemAnimator` + `CYLRiveTabBarItemAnimationView`，Android `CYLRiveTabBarItemAnimationView`）：
 *      每个 Tab 一个 .riv 文件、画板与状态机，Tab 选中时驱动。key 与选项沿用 iOS 名称。
 */

/**
 * [EN] `CYLTabBarRiveURL`: a .riv file at an http(s) URL or a rawfile path, with options in its query
 *      (`CYLTabBarAnimationURLWithOptions`, e.g. "rive/icons.riv?artboard=CHAT&stateMachine=CHAT_Interactivity").
 * [CN] .riv 文件的 http(s) 地址或 rawfile 路径，选项放在查询参数中。
 */
export const CYLTabBarRiveURL: string = 'CYLTabBarRiveURL';
/**
 * [EN] `CYLTabBarRiveFilePath`: a rawfile path of a .riv file (the default artboard unless the query names one).
 * [CN] .riv 文件的 rawfile 路径（查询参数未指定时使用默认画板）。
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
 *      and Android. In the animation path's query, e.g. "rive/icons.riv?artboard=CHAT&tint=title".
 * [CN] 以单一颜色绘制 Tab 的动画（任何引擎），与着色的模板图片一致："title" = Tab 当前状态（选中 / 普通）的标题颜色，或固定的
 *      "#RRGGBB" / "#AARRGGBB"，与 iOS、Android 相同。写在动画路径的查询参数中。
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
 * [EN] The value after `current` in the `values` option ("3,4,5,6"), cycling (an unknown value starts the list); without
 *      values, `current + 1`. As on iOS, Android and the WeChat Mini Program.
 * [CN] `values` 选项（"3,4,5,6"）中 `current` 之后的值，循环（未知值从列表开头开始）；没有值时为 `current + 1`。与 iOS、Android、微信小程序一致。
 */
export function cylRiveNextNumber(values: string | undefined, current: number | undefined): number {
  const list: number[] = (values ?? '').split(',').map((value: string) => value.trim()).filter((value: string) => value !== '')
    .map((value: string) => Number(value)).filter((value: number) => Number.isFinite(value));
  if (list.length === 0) {
    return (current ?? 0) + 1;
  }
  const index = current === undefined ? -1 : list.indexOf(current);
  return list[(index + 1) % list.length];
}

/**
 * [EN] `CYLTabBarAnimationURLWithOptions`: a file path or URL with its options as a query, as on iOS and Android.
 * [CN] 把选项作为查询参数附加到文件路径或地址，与 iOS、Android 相同。
 */
export function CYLTabBarAnimationURLWithOptions(file: string, options: Record<string, string>): string {
  const pairs: string[] = Object.keys(options)
    .filter((key: string) => options[key] !== undefined && options[key].length > 0)
    .map((key: string) => `${encodeURIComponent(key)}=${encodeURIComponent(options[key])}`);
  return pairs.length > 0 ? `${file}${file.includes('?') ? '&' : '?'}${pairs.join('&')}` : file;
}

/**
 * [EN] The file part and the options of a Rive URL. [CN] Rive 地址的文件部分与选项。
 */
export function cylRiveFileAndOptions(url: string): [string, Record<string, string>] {
  const options: Record<string, string> = {};
  const at = url.indexOf('?');
  if (at < 0) {
    return [url, options];
  }
  url.substring(at + 1).split('&').forEach((pair: string) => {
    const eq = pair.indexOf('=');
    if (eq > 0) {
      options[decodeURIComponent(pair.substring(0, eq))] = decodeURIComponent(pair.substring(eq + 1));
    }
  });
  return [url.substring(0, at), options];
}

/**
 * [EN] The renderer for this device. On the HarmonyOS emulator, @ohos/rive's default GPU renderer (`RendererType.Rive`)
 *      crashes the whole emulator (its GPU thread stalls, then a minidump; CYLTableViewPlaceHolder E7), so the emulator
 *      uses the Canvas renderer; real devices keep the GPU renderer.
 * [CN] 本设备使用的渲染器。鸿蒙模拟器上 @ohos/rive 默认的 GPU 渲染器会使整个模拟器崩溃，因此模拟器使用 Canvas 渲染器；真机保留 GPU 渲染器。
 */
export function cylRiveRendererType(): RendererType {
  return deviceInfo.productModel === 'emulator' ? RendererType.Canvas : RendererType.Rive;
}

let cylRiveInitialized: boolean = false;

/**
 * [EN] Whether @ohos/rive can run on this device. @ohos/rive 1.0.4 ships its native library (`libohos_rive.so`) for
 *      `arm64-v8a` only; on an x86_64 emulator a Rive view crashes the app later ("Accessing released C++ object:
 *      RiveArtboardRenderer", CYLTableViewPlaceHolder's HarmonyOS issue E15). Without `arm64-v8a` a Rive tab shows its
 *      image instead.
 * [CN] 本设备能否运行 @ohos/rive。@ohos/rive 1.0.4 只为 `arm64-v8a` 提供原生库（`libohos_rive.so`）；在 x86_64 模拟器上 Rive 视图稍后会使
 *      App 崩溃（“Accessing released C++ object: RiveArtboardRenderer”，CYLTableViewPlaceHolder 鸿蒙问题 E15）。没有 `arm64-v8a` 时
 *      Rive Tab 显示其图片。
 */
export function cylRiveIsSupported(): boolean {
  // [EN] The engine registry decides (arm64-v8a; x86_64 too in debug builds with the x86_64 debug engine kit,
  //      CYLAnimatedItemEngines.loadX86_64DebugEngines). [CN] 由引擎注册表决定（arm64-v8a；debug 构建安装了 x86_64 调试引擎包时也包括 x86_64）。
  return CYLAnimatedItemEngines.isSupportedOnDevice('Rive');
}

/**
 * [EN] `initializeRive()` once per process; throws where @ohos/rive cannot run (`cylRiveIsSupported()`).
 * [CN] 每个进程只调用一次 `initializeRive()`；@ohos/rive 无法运行时抛出异常（`cylRiveIsSupported()`）。
 */
export function cylEnsureRiveInitialized(): void {
  if (!cylRiveIsSupported()) {
    throw new Error('@ohos/rive has no native library for this device (' + (deviceInfo.abiList ?? '') + ')');
  }
  if (!cylRiveInitialized) {
    initializeRive();
    cylRiveInitialized = true;
  }
}

/**
 * [EN] A Rive tab icon. It is built once per tab and driven through `selected` and `replayToken` (never rebuilt on a
 *      selection change, so no Rive surface is created again); it never takes the tab's taps (the Android Rive view
 *      swallowed them) and is hidden from accessibility (the tab reads instead). Selecting the tab plays it: the view
 *      model's `active` boolean (or `trigger`), or, for legacy files, the state machine `input` / `triggerInput` or the
 *      linear `animation`; unselected, the boolean goes back to false. A file that cannot load calls `onLoadError`, and
 *      the tab shows its image.
 * [CN] Rive Tab 图标。每个 Tab 只创建一次，通过 `selected` 与 `replayToken` 驱动（选中变化不会重建，因此不会再次创建 Rive surface）；
 *      不拦截 Tab 的点击（Android 的 Rive 视图曾吞掉点击），对无障碍隐藏（由 Tab 朗读）。选中 Tab 时播放：view model 的 `active` 布尔值
 *      （或 `trigger`），旧版文件则用状态机 `input` / `triggerInput` 或线性 `animation`；未选中时布尔值恢复为 false。文件无法加载时调用
 *      `onLoadError`，Tab 显示图片。
 */
/** [EN] Seconds of a loop pass when the file gives none. [CN] 文件未给出时一次循环的秒数。 */
const CYL_RIVE_LOOP_SECONDS: number = 1.5;
/** [EN] The pause after a boolean goes back to false, before the next pass. [CN] 布尔值恢复为 false 后、下一次播放前的停顿。 */
const CYL_RIVE_LOOP_PAUSE_SECONDS: number = 0.4;
/** [EN] A frame later: the state machine sees the reset or the false first. [CN] 一帧之后：状态机先看到重置或 false。 */
const CYL_RIVE_NEXT_FRAME_MS: number = 50;
/** [EN] A held input's off time before it goes on again, outside a loop: more than one frame on a slow device. [CN] 循环之外，保持的输入重新打开前的关闭时间：大于慢设备的一帧。 */
const CYL_RIVE_INPUT_OFF_MS: number = 150;
/** [EN] Time for the first frame to be drawn before a loaded file pauses. [CN] 加载的文件暂停前绘制第一帧的时间。 */
const CYL_RIVE_FIRST_FRAME_MS: number = 100;
/** [EN] How often a play-once pass is checked for its end. [CN] 检查只播放一次的播放是否结束的间隔。 */
const CYL_RIVE_END_WATCH_MS: number = 50;

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
  @Prop @Watch('cylLoopsChanged') loops: boolean = false;
  onLoadError: (message: string) => void = () => {};
  /**
   * [EN] Hands the host this view's replay, called on each restart (CYLAnimatedItemView `setRestartHandler`, B23).
   * [CN] 把本视图的重播交给宿主，每次重播时调用（CYLAnimatedItemView `setRestartHandler`，B23）。
   */
  registerReplay: (replay: () => void) => void = (_replay: () => void) => {};
  /** [EN] The file is drawn (CYLAnimatedItemView shows it from here on). [CN] 文件已绘制。 */
  onLoaded: () => void = () => {};
  /**
   * [EN] A play-once pass (`loops` off) came to rest: the view stopped playing after it was seen playing, as Android's
   *      Rive `isPlaying` (CYLAnimatedItemAnimationContext `onEnded`).
   * [CN] 只播放一次（`loops` 关闭）的一遍播放停止：视图在播放之后停止播放，与 Android 的 Rive `isPlaying` 相同（CYLAnimatedItemAnimationContext 的 `onEnded`）。
   */
  onEnded: () => void = () => {};
  private endWatchTimer: number = -1;
  /** [EN] A timer will still start the pass (an input set or a trigger fired a frame later). [CN] 计时器稍后才开始这一遍播放（一帧之后设置输入或触发 trigger）。 */
  private startPending: boolean = false;
  private riveView: RiveAnimationView | null = null;
  private bytes: ArrayBuffer | null = null;
  private options: Record<string, string> = {};
  private loaded: boolean = false;
  private deactivateTimer: number = -1;
  private loopTimer: number = -1;
  /** [EN] Paused on its first frame after load, not played yet. [CN] 加载后暂停在第一帧、尚未播放。 */
  private restingAfterLoad: boolean = false;
  private hasPlayed: boolean = false;

  aboutToAppear(): void {
    this.registerReplay(() => this.cylReplay());
    try {
      cylEnsureRiveInitialized();
    } catch (e) {
      this.onLoadError(`${e}`);
      return;
    }
    this.cylReadFile();
  }

  aboutToDisappear(): void {
    this.cylCancelDeactivate();
    this.cylCancelLoop();
    this.cylCancelEndWatch();
    this.riveView = null;
  }

  private cylOption(name: string): string | undefined {
    const value: string | undefined = this.options[name];
    return value !== undefined && value.length > 0 ? value : undefined;
  }

  private cylReadFile(): void {
    const parts = cylRiveFileAndOptions(this.path);
    this.options = parts[1];
    const file = parts[0];
    if (file.startsWith('http://') || file.startsWith('https://')) {
      this.onLoadError('Rive URLs are not supported on HarmonyOS yet');
      return;
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const content: Uint8Array = context.resourceManager.getRawFileContentSync(file);
      this.bytes = content.buffer.slice(content.byteOffset, content.byteOffset + content.byteLength);
      this.cylLoadIfPossible();
    } catch (e) {
      this.onLoadError(`${e}`);
    }
  }

  /** [EN] A new path (the dark file after a color mode change) reloads the file. [CN] 新路径（如切换深色模式后）重新加载文件。 */
  cylReload(): void {
    this.loaded = false;
    this.bytes = null;
    this.cylReadFile();
  }

  private cylLoadIfPossible(): void {
    const view = this.riveView;
    if (view === null || this.bytes === null || this.loaded) {
      return;
    }
    try {
      view.setRiveBytes(this.bytes, this.cylOption(CYLTabBarAnimationOptionRiveArtboard),
        this.cylOption(CYLTabBarAnimationOptionRiveAnimation), this.cylOption(CYLTabBarAnimationOptionRiveStateMachine),
        true, true, Fit.CONTAIN, undefined, Loop.AUTO);
      this.loaded = true;
      this.cylRestUntilPlayed(view);
      this.cylUpdate();
      this.onLoaded();
    } catch (e) {
      this.onLoadError(`${e}`);
    }
  }

  private cylUsesLegacyRuntime(): boolean {
    return this.cylOption(CYLTabBarAnimationOptionRiveLegacyRuntime) === '1'
      || this.cylOption(CYLTabBarAnimationOptionRiveInput) !== undefined
      || this.cylOption(CYLTabBarAnimationOptionRiveTriggerInput) !== undefined
      || this.cylOption(CYLTabBarAnimationOptionRiveAnimation) !== undefined
      || this.cylOption(CYLTabBarAnimationOptionRiveNumberInput) !== undefined;
  }

  private cylDuration(): number {
    const value = Number(this.cylOption(CYLTabBarAnimationOptionRiveActiveDuration) ?? '1');
    return Number.isFinite(value) && value >= 0 ? value : 1;
  }

  private cylStateMachine(view: RiveAnimationView): string | undefined {
    const named = this.cylOption(CYLTabBarAnimationOptionRiveStateMachine);
    if (named !== undefined) {
      return named;
    }
    const machines = view.getStateMachines();
    return machines.length > 0 ? machines[0].name : undefined;
  }

  private cylViewModel(view: RiveAnimationView): ViewModelInstance | null {
    try {
      const machines = view.getStateMachines();
      return machines.length > 0 ? machines[0].viewModelInstance : null;
    } catch (e) {
      return null;
    }
  }

  /** [EN] Sets the boolean (view model property or state machine input); a missing one is skipped. [CN] 设置布尔值；不存在时跳过。 */
  private cylSetActive(view: RiveAnimationView, value: boolean): void {
    if (this.cylUsesLegacyRuntime()) {
      const input = this.cylOption(CYLTabBarAnimationOptionRiveInput);
      const machine = this.cylStateMachine(view);
      if (input !== undefined && machine !== undefined) {
        try {
          view.setBooleanState(machine, input, value);
        } catch (e) {
          // [EN] No such input: nothing to drive, as on iOS. [CN] 没有该输入：与 iOS 相同，不驱动。
        }
      }
      return;
    }
    const instance = this.cylViewModel(view);
    if (instance === null) {
      return;
    }
    try {
      instance.getBooleanProperty(this.cylOption(CYLTabBarAnimationOptionRiveActiveProperty) ?? 'active').value = value;
    } catch (e) {
      // [EN] No such property: nothing to drive, as on iOS. [CN] 没有该属性：与 iOS 相同，不驱动。
    }
  }

  /**
   * [EN] Whether the state machine has the input (an unknown answer counts as yes). [CN] 状态机是否有该输入（无法判断时视为有）。
   */
  private cylHasInput(view: RiveAnimationView, machine: string, input: string): boolean {
    try {
      const found = view.getStateMachines().find((instance) => instance.name === machine);
      return found === undefined ? true : found.inputNames.includes(input);
    } catch (e) {
      return true;
    }
  }

  /**
   * [EN] Plays from the start (docs/Animated-Item.md, the Rive loop): a linear animation restarts; a trigger restarts the state
   *      machine, then fires a frame later (check.riv stayed on its finished check); a boolean goes false, then true a frame
   *      later, so every play is a transition (a held one used to play once); a state machine without the input restarts
   *      (house.riv). With `loops` on, it plays again after each pass.
   * [CN] 从头播放（docs/Animated-Item.md，Rive 循环）：线性动画重新开始；trigger 先重新开始状态机，一帧之后再触发（check.riv 停在完成的对勾上）；布尔值先设为
   *      false，一帧之后设为 true，每次播放都是一次状态切换（保持的布尔值以前只播放一次）；没有该输入的状态机重新开始（house.riv）。开启 `loops` 时，
   *      每次播放后再次播放。
   */
  /**
   * [EN] Rests on the first frame until the first play (docs/Animated-Item.md): a file whose state machine moves by itself
   *      (shapes.riv, truck.riv) no longer runs from load. The machine is created (autoplay) so its inputs can be read, then
   *      paused once drawn.
   * [CN] 在第一次播放之前停在第一帧：状态机会自行运动的文件（shapes.riv、truck.riv）不再从加载起就运动。状态机先创建（autoplay）以便读取输入，
   *      绘制后再暂停。
   */
  private cylRestUntilPlayed(view: RiveAnimationView): void {
    this.hasPlayed = false;
    this.restingAfterLoad = false;
    setTimeout(() => {
      if (!this.hasPlayed && this.riveView === view) {
        // [EN] The file controller only, as on Android: the view's `pause()` also stops its renderer, after which a state
        //      machine crept one frame per input (menu_button.riv never reached its X on Android).
        // [CN] 与 Android 相同，只暂停文件控制器：视图的 `pause()` 还会停止渲染器，之后状态机每次输入只前进一帧。
        if (view.controller !== null) {
          view.controller.pauseAllAnimations();
        } else {
          view.pause();
        }
        this.restingAfterLoad = true;
      }
    }, CYL_RIVE_FIRST_FRAME_MS);
  }

  /**
   * [EN] `reset()` keeping the item's artboard. @ohos/rive 1.0.4's `RiveAnimationView.reset()` selects the file's first
   *      artboard (`RiveArtboardRenderer.reset()` calls `selectArtboard()` without a name), so an item with
   *      "?artboard=CHAT" played the default artboard after its first play and kept it (CollectionViewClassifyMenu,
   *      icons.riv dark tags: every item turned into "refresh"). The named artboard is selected again.
   * [CN] 保留条目画板的 `reset()`。@ohos/rive 1.0.4 的 `RiveAnimationView.reset()` 会选中文件的第一个画板（`RiveArtboardRenderer.reset()`
   *      调用不带名字的 `selectArtboard()`），因此带 "?artboard=CHAT" 的条目首次播放后变成默认画板并一直保持。这里重新选中指定画板。
   */
  private cylReset(view: RiveAnimationView): void {
    view.reset();
    const artboard = this.cylOption(CYLTabBarAnimationOptionRiveArtboard);
    if (artboard !== undefined && artboard.length > 0 && view.getArtboardName() !== artboard) {
      view.setArtboardName(artboard);
    }
  }

  /**
   * [EN] Plays the state machine by name. An unnamed `play()` also starts the artboard's linear animations (see the resume
   *      above); a looping one kept `isPlaying()` true for good, so a play-once pass never ended and `onEnded` never came
   *      (house.riv on the HarmonyOS emulator: a state machine and a linear animation still playing 10 s after the pass).
   * [CN] 按名字播放状态机。不带名字的 `play()` 还会启动画板的线性动画（见上方的恢复）；循环的线性动画使 `isPlaying()` 一直为 true，
   *      只播放一次的一遍永不结束，`onEnded` 也就从不调用（鸿蒙模拟器上的 house.riv：一遍之后 10 秒仍有一个状态机和一个线性动画在播放）。
   */
  private cylPlayMachine(view: RiveAnimationView, machine: string | undefined): void {
    if (machine !== undefined) {
      view.play(machine, undefined, undefined, true);
    } else {
      view.play();
    }
  }

  private cylPlay(view: RiveAnimationView): void {
    this.cylCancelDeactivate();
    this.cylCancelLoop();
    this.hasPlayed = true;
    if (this.restingAfterLoad) {
      // [EN] Resumed where it rests (no settling), then played as usual. Only the state machine: an unnamed `play()` also
      //      starts the artboard's linear animations, which override the machine (Android, menu_button.riv).
      // [CN] 从静止处恢复（不重新定位），然后照常播放。只恢复状态机：不带名字的 `play()` 还会启动画板的线性动画并覆盖状态机（Android，menu_button.riv）。
      this.restingAfterLoad = false;
      const machineName = this.cylOption(CYLTabBarAnimationOptionRiveAnimation) === undefined ? this.cylStateMachine(view) : undefined;
      if (machineName !== undefined) {
        view.play(machineName, undefined, undefined, true, false);
      }
    }
    const animation = this.cylOption(CYLTabBarAnimationOptionRiveAnimation);
    const machine = animation === undefined ? this.cylStateMachine(view) : undefined;
    const triggerInput = this.cylOption(CYLTabBarAnimationOptionRiveTriggerInput);
    const trigger = this.cylOption(CYLTabBarAnimationOptionRiveTriggerProperty);
    const instance = this.cylUsesLegacyRuntime() ? null : this.cylViewModel(view);
    const legacyInput = this.cylOption(CYLTabBarAnimationOptionRiveInput);
    const numberInput = this.cylOption(CYLTabBarAnimationOptionRiveNumberInput);
    if (animation !== undefined) {
      this.cylReset(view);
      view.play(animation, Loop.ONESHOT);
    } else if (triggerInput !== undefined && machine !== undefined && this.cylHasInput(view, machine, triggerInput)) {
      this.cylReset(view);
      this.cylPlayMachine(view, machine);
      this.startPending = true;
      this.deactivateTimer = setTimeout(() => {
        this.deactivateTimer = -1;
        this.startPending = false;
        if (this.riveView === view) {
          try {
            view.fireState(machine, triggerInput);
          } catch (e) {
            // [EN] No such trigger. [CN] 没有该 trigger。
          }
        }
      }, CYL_RIVE_NEXT_FRAME_MS);
    } else if (numberInput !== undefined && machine !== undefined && this.cylHasInput(view, machine, numberInput)) {
      // [EN] The next value: house.riv moves only when Rooms changes. [CN] 下一个值：house.riv 只在 Rooms 变化时运动。
      this.cylPlayMachine(view, machine);
      view.setNumberState(machine, numberInput,
        cylRiveNextNumber(this.cylOption(CYLTabBarAnimationOptionRiveNumberValues), this.cylNumberValue(view, machine, numberInput)));
    } else if (trigger !== undefined && instance !== null) {
      this.cylPlayMachine(view, machine);
      try {
        instance.getTriggerProperty(trigger).trigger();
      } catch (e) {
        // [EN] No such trigger. [CN] 没有该 trigger。
      }
    } else if (instance !== null || (legacyInput !== undefined && machine !== undefined
      && this.cylHasInput(view, machine, legacyInput))) {
      this.cylPlayMachine(view, machine);
      this.cylSetActive(view, false);
      const duration = this.cylDuration();
      this.startPending = true;
      this.deactivateTimer = setTimeout(() => {
        this.deactivateTimer = -1;
        this.startPending = false;
        if (this.riveView !== view) {
          return;
        }
        this.cylSetActive(view, true);
        if (duration > 0) {
          this.deactivateTimer = setTimeout(() => {
            this.deactivateTimer = -1;
            if (this.riveView === view) {
              this.cylSetActive(view, false);
            }
          }, duration * 1000);
        }
        // [EN] Half a loop pass while looping a held input, so the machine spends real time closed (as Android and the mini
        //      program); otherwise a frame. [CN] 循环保持的输入时为半个循环周期，使状态机真正停留在关闭状态（与 Android、小程序相同）；否则为一帧。
      }, this.loops && duration <= 0 ? CYL_RIVE_LOOP_SECONDS * 500 : CYL_RIVE_INPUT_OFF_MS);
    } else {
      this.cylReset(view);
      view.play();
    }
    this.cylScheduleLoop(view, trigger !== undefined || triggerInput !== undefined);
    this.cylWatchForEnd(view);
  }

  /**
   * [EN] Watches a play-once pass for its end (as Android's CYLAnimatedItemView): the end is when `isPlaying()` goes false
   *      after it was seen true, once the pass has started; never while looping, unselected or replaced.
   * [CN] 监视只播放一次的一遍播放何时结束（与 Android 的 CYLAnimatedItemView 相同）：这一遍开始后，`isPlaying()` 先为 true 再变为 false
   *      即为结束；循环、未选中或视图被替换时从不结束。
   */
  private cylWatchForEnd(view: RiveAnimationView): void {
    this.cylCancelEndWatch();
    if (this.loops) {
      return;
    }
    let seenPlaying = false;
    this.endWatchTimer = setInterval(() => {
      if (this.loops || !this.selected || this.riveView !== view) {
        this.cylCancelEndWatch();
        return;
      }
      if (this.startPending) {
        return;
      }
      let playing = false;
      try {
        playing = view.isPlaying();
      } catch (e) {
        this.cylCancelEndWatch();
        return;
      }
      if (playing) {
        seenPlaying = true;
      } else if (seenPlaying) {
        this.cylCancelEndWatch();
        this.onEnded();
      }
    }, CYL_RIVE_END_WATCH_MS);
  }

  private cylCancelEndWatch(): void {
    if (this.endWatchTimer >= 0) {
      clearInterval(this.endWatchTimer);
      this.endWatchTimer = -1;
    }
  }

  /** [EN] A number input's value, undefined when unknown. [CN] 数字输入的值，无法读取时为 undefined。 */
  private cylNumberValue(view: RiveAnimationView, machine: string, input: string): number | undefined {
    try {
      const found = view.getStateMachines().find((instance) => instance.name === machine);
      const value = found?.inputByName(input);
      return value instanceof SMINumber ? value.value : undefined;
    } catch (e) {
      return undefined;
    }
  }

  /**
   * [EN] Whether a play restarts the file (no usable input or trigger, no named animation, no view model).
   * [CN] 一次播放是否重新开始文件（没有可用的输入或 trigger、没有命名动画、没有 view model）。
   */
  private cylRestartsOnPlay(view: RiveAnimationView): boolean {
    if (this.cylOption(CYLTabBarAnimationOptionRiveAnimation) !== undefined) {
      return false;
    }
    const machine = this.cylStateMachine(view);
    if (machine === undefined) {
      return true;
    }
    if (!this.cylUsesLegacyRuntime() && this.cylViewModel(view) !== null) {
      return false;
    }
    const inputs = [CYLTabBarAnimationOptionRiveTriggerInput, CYLTabBarAnimationOptionRiveNumberInput, CYLTabBarAnimationOptionRiveInput]
      .map((key: string) => this.cylOption(key)).filter((name: string | undefined) => name !== undefined) as string[];
    return !inputs.some((name: string) => this.cylHasInput(view, machine, name));
  }

  /** [EN] The next pass while looping. [CN] 循环时的下一次播放。 */
  private cylScheduleLoop(view: RiveAnimationView, isTrigger: boolean): void {
    if (!this.loops) {
      return;
    }
    const duration = this.cylDuration();
    const seconds = !isTrigger && duration > 0 ? duration + CYL_RIVE_LOOP_PAUSE_SECONDS : CYL_RIVE_LOOP_SECONDS;
    this.loopTimer = setTimeout(() => {
      this.loopTimer = -1;
      if (this.loops && this.riveView === view && this.selected) {
        // [EN] A file still moving on its own (shapes.riv, truck.riv) is not cut short: check again after another pass.
        // [CN] 仍在自行运动的文件（shapes.riv、truck.riv）不被打断：再等一次检查。
        if (this.cylRestartsOnPlay(view) && view.isPlaying()) {
          this.cylScheduleLoop(view, isTrigger);
        } else {
          this.cylPlay(view);
        }
      }
    }, seconds * 1000);
  }

  cylLoopsChanged(): void {
    const view = this.riveView;
    if (!this.loops) {
      this.cylCancelLoop();
    } else if (view !== null && this.loaded && this.selected && this.loopTimer < 0) {
      this.cylPlay(view);
    }
  }

  private cylCancelLoop(): void {
    if (this.loopTimer >= 0) {
      clearTimeout(this.loopTimer);
      this.loopTimer = -1;
    }
  }

  private cylStop(view: RiveAnimationView): void {
    this.cylCancelDeactivate();
    this.cylCancelLoop();
    this.cylCancelEndWatch();
    if (this.cylOption(CYLTabBarAnimationOptionRiveAnimation) !== undefined) {
      view.stop();
      return;
    }
    this.cylSetActive(view, false);
  }

  cylUpdate(): void {
    const view = this.riveView;
    if (view === null || !this.loaded) {
      return;
    }
    if (this.selected) {
      this.cylPlay(view);
    } else {
      this.cylStop(view);
    }
  }

  cylReplay(): void {
    const view = this.riveView;
    if (view !== null && this.loaded && this.selected) {
      this.cylPlay(view);
    }
  }

  private cylCancelDeactivate(): void {
    this.startPending = false;
    if (this.deactivateTimer >= 0) {
      clearTimeout(this.deactivateTimer);
      this.deactivateTimer = -1;
    }
  }

  build() {
    Stack() {
      RiveAnimationView({
        riveAutoPlay: false,
        touchPassThrough: true,
        rendererType: cylRiveRendererType(),
        onReady: (view: RiveAnimationView) => {
          this.riveView = view;
          this.cylLoadIfPossible();
        }
      })
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
    }
    .width(this.iconSize)
    .height(this.iconSize)
    // [EN] The icon never takes the tab's taps and is not read on its own. [CN] 图标不拦截 Tab 的点击，也不单独朗读。
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no-hide-descendants')
  }
}
