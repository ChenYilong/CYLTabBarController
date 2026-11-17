import { Fit, Loop, RendererType, RiveAnimationView, ViewModelInstance, initializeRive } from '@ohos/rive';
import { deviceInfo } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

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
  const abis: string = deviceInfo.abiList ?? '';
  return abis.split(',').map((abi: string) => abi.trim()).indexOf('arm64-v8a') >= 0;
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
@Component
export struct CYLRiveIcon {
  @Prop @Watch('cylReload') path: string = '';
  iconSize: number = 26;
  @Prop @Watch('cylUpdate') selected: boolean = false;
  @Prop @Watch('cylReplay') replayToken: number = 0;
  onLoadError: (message: string) => void = () => {};
  /** [EN] The file is drawn (CYLAnimatedItemView shows it from here on). [CN] 文件已绘制。 */
  onLoaded: () => void = () => {};
  private riveView: RiveAnimationView | null = null;
  private bytes: ArrayBuffer | null = null;
  private options: Record<string, string> = {};
  private loaded: boolean = false;
  private deactivateTimer: number = -1;

  aboutToAppear(): void {
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
      || this.cylOption(CYLTabBarAnimationOptionRiveAnimation) !== undefined;
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

  private cylPlay(view: RiveAnimationView): void {
    this.cylCancelDeactivate();
    const animation = this.cylOption(CYLTabBarAnimationOptionRiveAnimation);
    if (animation !== undefined) {
      view.play(animation, Loop.ONESHOT);
      return;
    }
    view.play();
    const machine = this.cylStateMachine(view);
    const triggerInput = this.cylOption(CYLTabBarAnimationOptionRiveTriggerInput);
    if (triggerInput !== undefined && machine !== undefined) {
      try {
        view.fireState(machine, triggerInput);
      } catch (e) {
        // [EN] No such trigger. [CN] 没有该 trigger。
      }
      return;
    }
    const trigger = this.cylOption(CYLTabBarAnimationOptionRiveTriggerProperty);
    const instance = this.cylUsesLegacyRuntime() ? null : this.cylViewModel(view);
    if (trigger !== undefined && instance !== null) {
      try {
        instance.getTriggerProperty(trigger).trigger();
      } catch (e) {
        // [EN] No such trigger. [CN] 没有该 trigger。
      }
      return;
    }
    this.cylSetActive(view, true);
    const duration = this.cylDuration();
    if (duration > 0) {
      this.deactivateTimer = setTimeout(() => {
        this.deactivateTimer = -1;
        if (this.riveView === view) {
          this.cylSetActive(view, false);
        }
      }, duration * 1000);
    }
  }

  private cylStop(view: RiveAnimationView): void {
    this.cylCancelDeactivate();
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
