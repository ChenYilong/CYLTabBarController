/**
 * [EN] The Rive engine of CYLAnimatedItemView (@ohos/rive): a .riv rawfile with its options ("#artboard=CHAT&stateMachine=..."),
 *      played from the start on every play: a linear `animation` restarts; a `triggerInput` restarts the state machine
 *      and fires a frame later; a boolean (`input` or the view model's `active`) goes false, then true; a `numberInput`
 *      steps through `values`; a view model `trigger` fires; a state machine without inputs restarts. With loops on it
 *      plays again after each pass; a play-once pass reports its end when the view stops playing. No playback speed and no
 *      progress (@ohos/rive has neither). `CYLAnimatedItemRive.register()` once makes every CYLAnimatedItemView without an
 *      `animationBuilder` play Rive files where @ohos/rive has its native library (arm64-v8a, or the x86_64 debug kit).
 *
 *      Moved from cyltabbar's CYLRiveIcon (CYLRiveTabBarItemAnimator.ets), which already carried every fix the dependents
 *      kept in their own Rive players: the Canvas renderer on the emulator (CYLTableViewPlaceHolder E7), `initializeRive()`
 *      once, the named artboard selected again after `reset()` (CollectionViewClassifyMenu icons.riv, CYLTableViewPlaceHolder
 *      2394e3d8), the state machine played by name (c4fb1cb8), the wait for @ohos/rive to build the file after
 *      `setRiveBytes()` (5b7af8c4, cf5ea470), the play-once end (5dfd3077), restarts and loops by replay (9378da47), taps
 *      passed through (fff727fb), and no Rive without its native library (E15).
 * [CN] CYLAnimatedItemView 的 Rive 引擎（@ohos/rive）：带选项的 .riv rawfile，每次播放都从头开始：线性 `animation` 重新开始；`triggerInput`
 *      先重新开始状态机，一帧之后触发；布尔值（`input` 或 view model 的 `active`）先 false 后 true；`numberInput` 依次使用 `values`；view model
 *      `trigger` 触发；没有输入的状态机重新开始。开启循环时每遍之后再次播放；只播放一次的一遍在视图停止播放时报告结束。没有播放速度与进度
 *      （@ohos/rive 都不提供）。调用一次 `CYLAnimatedItemRive.register()` 后，在 @ohos/rive 有原生库的设备上（arm64-v8a，或 x86_64 调试包），所有未传入
 *      `animationBuilder` 的 CYLAnimatedItemView 都播放 Rive 文件。
 *
 *      从 cyltabbar 的 CYLRiveIcon（CYLRiveTabBarItemAnimator.ets）迁移而来，它已包含各依赖方在自己的 Rive 播放器中保留的全部修复。
 */
import { Fit, Loop, RendererType, RiveAnimationView, SMINumber, ViewModelInstance, initializeRive } from '@ohos/rive';
import { deviceInfo } from '@kit.BasicServicesKit';
import { LifecycleController } from 'cyldeallocblockexecutor';
import {
  CYLAnimatedItemEngineBinding, CYLAnimatedItemEngineState, CYLAnimatedItemEngineViews, CYLAnimatedItemEngines,
  CYLAnimatedItemPlayer, CYLAnimatedItemSource, cylAnimatedItemARGBInteger, cylAnimatedItemParseHexColor
} from 'cylanimateditem';
import { CYLAnimatedItemRiveOption, cylRiveActiveDuration, cylRiveNextNumber, cylRiveUsesLegacyRuntime } from './CYLAnimatedItemRiveOptions';

/** [EN] The native ABI of @ohos/rive 1.0.4. [CN] @ohos/rive 1.0.4 的原生 ABI。 */
const CYL_RIVE_ABI: string = 'arm64-v8a';
/** [EN] Seconds of a loop pass when the file gives none. [CN] 文件未给出时一次循环的秒数。 */
const CYL_RIVE_LOOP_SECONDS: number = 1.5;
/** [EN] The pause after a boolean goes back to false, before the next pass. [CN] 布尔值恢复为 false 后、下一次播放前的停顿。 */
const CYL_RIVE_LOOP_PAUSE_SECONDS: number = 0.4;
/** [EN] A frame later: the state machine sees the reset or the false first. [CN] 一帧之后：状态机先看到重置或 false。 */
const CYL_RIVE_NEXT_FRAME_MS: number = 50;
/** [EN] A held input's off time before it goes on again, outside a loop. [CN] 循环之外，保持的输入重新打开前的关闭时间。 */
const CYL_RIVE_INPUT_OFF_MS: number = 150;
/** [EN] Time for the first frame to be drawn before a loaded file pauses. [CN] 加载的文件暂停前绘制第一帧的时间。 */
const CYL_RIVE_FIRST_FRAME_MS: number = 100;
/** [EN] How often a play-once pass is checked for its end. [CN] 检查只播放一次的播放是否结束的间隔。 */
const CYL_RIVE_END_WATCH_MS: number = 50;
/** [EN] Frames a play waits for @ohos/rive to build the file. [CN] 播放等待 @ohos/rive 建好文件的最大帧数。 */
const CYL_RIVE_FILE_WAIT_FRAMES: number = 60;

/**
 * [EN] The renderer for this device. On the HarmonyOS emulator @ohos/rive's default GPU renderer crashes the whole emulator
 *      (CYLTableViewPlaceHolder E7), so the emulator uses the Canvas renderer; real devices keep the GPU renderer.
 * [CN] 本设备使用的渲染器。鸿蒙模拟器上 @ohos/rive 默认的 GPU 渲染器会使整个模拟器崩溃，因此模拟器使用 Canvas 渲染器；真机保留 GPU 渲染器。
 */
export function cylRiveRendererType(): RendererType {
  return deviceInfo.productModel === 'emulator' ? RendererType.Canvas : RendererType.Rive;
}

/**
 * [EN] Whether @ohos/rive can run here: the engine registry decides (arm64-v8a; x86_64 too with the x86_64
 *      debug engine kit). Elsewhere a Rive view crashed the app later (CYLTableViewPlaceHolder E15).
 * [CN] @ohos/rive 能否在此运行：由引擎注册表决定（arm64-v8a；安装了 x86_64 调试引擎包时也包括 x86_64）。
 */
export function cylRiveIsSupported(): boolean {
  return CYLAnimatedItemEngines.isSupportedOnDevice('Rive');
}

let cylRiveInitialized: boolean = false;

/** [EN] `initializeRive()` once per process; throws where @ohos/rive cannot run. [CN] 每个进程只调用一次 `initializeRive()`；无法运行时抛出异常。 */
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
 * [EN] The player of a Rive item: `riveView` is @ohos/rive's view, its file already set. Created right after
 *      `setRiveBytes()`: it rests on the first frame until the first play.
 * [CN] Rive 条目的播放器：`riveView` 为已设置文件的 @ohos/rive 视图。在 `setRiveBytes()` 之后立即创建：第一次播放前停在第一帧。
 */
export class CYLAnimatedItemRivePlayer extends CYLAnimatedItemPlayer {
  riveView: RiveAnimationView | null;
  /** [EN] Played and not stopped since (the tab's "selected"). [CN] 已播放且之后未停止（相当于 Tab 的“选中”）。 */
  private active: boolean = false;
  private endWatchTimer: number = -1;
  private startPending: boolean = false;
  private deactivateTimer: number = -1;
  private loopTimer: number = -1;
  private restingAfterLoad: boolean = false;
  private hasPlayed: boolean = false;
  private fileWaits: number = 0;
  /** [EN] The colors asked for (applied once the view model exists). [CN] 请求的颜色（视图模型存在后应用）。 */
  private requestedColors?: Map<string, string>;
  private originalColors: Map<string, number> = new Map<string, number>();
  private overriddenColorPaths: Set<string> = new Set<string>();

  constructor(source: CYLAnimatedItemSource, view: RiveAnimationView) {
    super('Rive', source);
    this.riveView = view;
    this.cylRestUntilPlayed(view);
  }

  /** [EN] @ohos/rive has no playback speed. [CN] @ohos/rive 没有播放速度。 */
  get supportsSpeed(): boolean {
    return false;
  }

  /** [EN] @ohos/rive exposes no progress. [CN] @ohos/rive 不提供进度。 */
  get supportsProgress(): boolean {
    return false;
  }

  /** [EN] View model color properties. [CN] 视图模型的颜色属性。 */
  get supportsColors(): boolean {
    return true;
  }

  /**
   * [EN] View model color property path -> color; undefined restores the file's colors. Files without a view model keep
   *      theirs. Moved from CYLTableViewPlaceHolder's Rive animator (iOS CYLPlaceholderRiveItemAnimationView.applyAnimationColors).
   * [CN] 视图模型颜色属性路径 -> 颜色；undefined 恢复文件的颜色。没有视图模型的文件保持原色。从 CYLTableViewPlaceHolder 的 Rive 动画器迁移。
   */
  applyColors(colors: Map<string, string> | undefined): void {
    this.requestedColors = colors !== undefined && colors.size > 0 ? colors : undefined;
    const view = this.riveView;
    if (view !== null) {
      this.cylApplyRequestedColors(view);
    }
  }

  private cylApplyRequestedColors(view: RiveAnimationView): void {
    const instance = this.cylViewModel(view);
    if (instance === null) {
      return;
    }
    const colors = this.requestedColors;
    if (colors !== undefined) {
      colors.forEach((text: string, path: string) => {
        const color = cylAnimatedItemParseHexColor(text);
        if (color === undefined) {
          return;
        }
        try {
          const property = instance.getColorProperty(path);
          if (!this.originalColors.has(path)) {
            this.originalColors.set(path, property.value);
          }
          property.value = cylAnimatedItemARGBInteger(color);
          this.overriddenColorPaths.add(path);
        } catch (e) {
          // [EN] No such color property. [CN] 没有该颜色属性。
        }
      });
      return;
    }
    this.overriddenColorPaths.forEach((path: string) => {
      const original = this.originalColors.get(path);
      if (original !== undefined) {
        try {
          instance.getColorProperty(path).value = original;
        } catch (e) {
          // [EN] No such color property. [CN] 没有该颜色属性。
        }
      }
    });
    this.overriddenColorPaths.clear();
  }

  get isPlaying(): boolean {
    try {
      return this.riveView?.isPlaying() ?? false;
    } catch (e) {
      return false;
    }
  }

  play(): void {
    const view = this.riveView;
    if (view === null) {
      return;
    }
    this.active = true;
    this.cylPlay(view);
  }

  /**
   * [EN] 1 (the end of the selected state): the boolean on, nothing restarted; otherwise stopped and the boolean off.
   * [CN] 1（选中状态的结尾）：布尔值打开，不重新开始；否则停止并关闭布尔值。
   */
  stopAtProgress(progress: number): void {
    const view = this.riveView;
    if (view === null) {
      return;
    }
    this.active = false;
    this.cylCancelTimers();
    if (progress >= 1) {
      this.cylSetActive(view, true);
      return;
    }
    if (this.option(CYLAnimatedItemRiveOption.ANIMATION) !== undefined) {
      view.stop();
      return;
    }
    this.cylSetActive(view, false);
  }

  destroy(): void {
    this.active = false;
    this.cylCancelTimers();
    this.riveView = null;
    super.destroy();
  }

  /** [EN] Turning loop on replays a selected item; off lets the pass finish. [CN] 开启循环时重播选中的条目；关闭时让这一遍播放完。 */
  protected applyLoops(): void {
    const view = this.riveView;
    if (!this.loopsValue) {
      this.cylCancelLoop();
    } else if (view !== null && this.active && this.loopTimer < 0) {
      this.cylPlay(view);
    }
  }

  private option(name: string): string | undefined {
    const value = this.source.option(name);
    return value !== undefined && value.length > 0 ? value : undefined;
  }

  private cylUsesLegacyRuntime(): boolean {
    return cylRiveUsesLegacyRuntime((name: string) => this.option(name));
  }

  private cylStateMachine(view: RiveAnimationView): string | undefined {
    const named = this.option(CYLAnimatedItemRiveOption.STATE_MACHINE);
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
      const input = this.option(CYLAnimatedItemRiveOption.INPUT);
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
      instance.getBooleanProperty(this.option(CYLAnimatedItemRiveOption.ACTIVE_PROPERTY) ?? 'active').value = value;
    } catch (e) {
      // [EN] No such property: nothing to drive, as on iOS. [CN] 没有该属性：与 iOS 相同，不驱动。
    }
  }

  /** [EN] Whether the state machine has the input (an unknown answer counts as yes). [CN] 状态机是否有该输入（无法判断时视为有）。 */
  private cylHasInput(view: RiveAnimationView, machine: string, input: string): boolean {
    try {
      const found = view.getStateMachines().find((instance) => instance.name === machine);
      return found === undefined ? true : found.inputNames.includes(input);
    } catch (e) {
      return true;
    }
  }

  /**
   * [EN] Rests on the first frame until the first play: a file whose state machine moves by itself (shapes.riv, truck.riv)
   *      does not run from load. Only the file controller pauses: the view's `pause()` also stops its renderer, after which
   *      a state machine crept one frame per input.
   * [CN] 第一次播放前停在第一帧：状态机会自行运动的文件不再从加载起就运动。只暂停文件控制器：视图的 `pause()` 还会停止渲染器。
   */
  private cylRestUntilPlayed(view: RiveAnimationView): void {
    this.hasPlayed = false;
    this.restingAfterLoad = false;
    setTimeout(() => {
      if (!this.hasPlayed && this.riveView === view) {
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
   * [EN] `reset()` keeping the item's artboard: @ohos/rive 1.0.4's `reset()` selects the file's first artboard, so an item
   *      with "artboard=CHAT" played the default one after its first play (CollectionViewClassifyMenu icons.riv,
   *      CYLTableViewPlaceHolder 2394e3d8).
   * [CN] 保留条目画板的 `reset()`：@ohos/rive 1.0.4 的 `reset()` 会选中文件的第一个画板，因此带 "artboard=CHAT" 的条目首次播放后变成默认画板。
   */
  private cylReset(view: RiveAnimationView): void {
    view.reset();
    const artboard = this.option(CYLAnimatedItemRiveOption.ARTBOARD);
    if (artboard !== undefined && view.getArtboardName() !== artboard) {
      view.setArtboardName(artboard);
    }
  }

  /**
   * [EN] Plays the state machine by name: an unnamed `play()` also starts the artboard's linear animations, and a looping one
   *      kept `isPlaying()` true, so a play-once pass never ended (CYLTableViewPlaceHolder c4fb1cb8).
   * [CN] 按名字播放状态机：不带名字的 `play()` 还会启动画板的线性动画，循环的线性动画使 `isPlaying()` 一直为 true，只播放一次的一遍永不结束。
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
    // [EN] setRiveBytes() returns before @ohos/rive builds the file (about a frame later on the x86_64 emulator): a play in
    //      between selected no artboard and was lost. Wait for the file, a frame at a time (5b7af8c4, cf5ea470).
    // [CN] setRiveBytes() 返回时 @ohos/rive 还没有建好文件：这期间的播放选不到画板而丢失。逐帧等待文件。
    if ((view.controller === null || view.controller.file === null) && this.fileWaits < CYL_RIVE_FILE_WAIT_FRAMES) {
      this.fileWaits++;
      this.deactivateTimer = setTimeout(() => {
        this.deactivateTimer = -1;
        if (this.riveView === view && this.active) {
          this.cylPlay(view);
        }
      }, CYL_RIVE_NEXT_FRAME_MS);
      return;
    }
    this.fileWaits = 0;
    this.hasPlayed = true;
    // [EN] Colors asked for before the file was built. [CN] 文件建好之前请求的颜色。
    if (this.requestedColors !== undefined) {
      this.cylApplyRequestedColors(view);
    }
    if (this.restingAfterLoad) {
      // [EN] Resumed where it rests, then played as usual; only the state machine (an unnamed play() also starts the
      //      linear animations, which override the machine). [CN] 从静止处恢复，然后照常播放；只恢复状态机。
      this.restingAfterLoad = false;
      const machineName = this.option(CYLAnimatedItemRiveOption.ANIMATION) === undefined ? this.cylStateMachine(view) : undefined;
      if (machineName !== undefined) {
        view.play(machineName, undefined, undefined, true, false);
      }
    }
    const animation = this.option(CYLAnimatedItemRiveOption.ANIMATION);
    const machine = animation === undefined ? this.cylStateMachine(view) : undefined;
    const triggerInput = this.option(CYLAnimatedItemRiveOption.TRIGGER_INPUT);
    const trigger = this.option(CYLAnimatedItemRiveOption.TRIGGER_PROPERTY);
    const instance = this.cylUsesLegacyRuntime() ? null : this.cylViewModel(view);
    const legacyInput = this.option(CYLAnimatedItemRiveOption.INPUT);
    const numberInput = this.option(CYLAnimatedItemRiveOption.NUMBER_INPUT);
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
        cylRiveNextNumber(this.option(CYLAnimatedItemRiveOption.NUMBER_VALUES), this.cylNumberValue(view, machine, numberInput)));
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
      const duration = cylRiveActiveDuration(this.option(CYLAnimatedItemRiveOption.ACTIVE_DURATION));
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
        // [EN] Half a loop pass while looping a held input, so the machine spends real time closed; otherwise a frame.
        // [CN] 循环保持的输入时为半个循环周期，使状态机真正停留在关闭状态；否则为一帧。
      }, this.loopsValue && duration <= 0 ? CYL_RIVE_LOOP_SECONDS * 500 : CYL_RIVE_INPUT_OFF_MS);
    } else {
      this.cylReset(view);
      view.play();
    }
    this.cylScheduleLoop(view, trigger !== undefined || triggerInput !== undefined);
    this.cylWatchForEnd(view);
  }

  /**
   * [EN] Watches a play-once pass for its end (as Android's CYLAnimatedItemView): `isPlaying()` goes false after it was seen
   *      true, once the pass has started; never while looping, stopped or replaced (CYLTableViewPlaceHolder 5dfd3077).
   * [CN] 监视只播放一次的一遍播放何时结束：这一遍开始后，`isPlaying()` 先为 true 再变为 false 即为结束；循环、停止或视图被替换时从不结束。
   */
  private cylWatchForEnd(view: RiveAnimationView): void {
    this.cylCancelEndWatch();
    if (this.loopsValue) {
      return;
    }
    let seenPlaying = false;
    this.endWatchTimer = setInterval(() => {
      if (this.loopsValue || !this.active || this.riveView !== view) {
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
        this.didEnd();
      }
    }, CYL_RIVE_END_WATCH_MS);
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

  /** [EN] Whether a play restarts the file (no usable input, trigger, named animation or view model). [CN] 一次播放是否重新开始文件。 */
  private cylRestartsOnPlay(view: RiveAnimationView): boolean {
    if (this.option(CYLAnimatedItemRiveOption.ANIMATION) !== undefined) {
      return false;
    }
    const machine = this.cylStateMachine(view);
    if (machine === undefined) {
      return true;
    }
    if (!this.cylUsesLegacyRuntime() && this.cylViewModel(view) !== null) {
      return false;
    }
    const inputs = [CYLAnimatedItemRiveOption.TRIGGER_INPUT, CYLAnimatedItemRiveOption.NUMBER_INPUT, CYLAnimatedItemRiveOption.INPUT]
      .map((key: string) => this.option(key)).filter((name: string | undefined) => name !== undefined) as string[];
    return !inputs.some((name: string) => this.cylHasInput(view, machine, name));
  }

  /** [EN] The next pass while looping. [CN] 循环时的下一次播放。 */
  private cylScheduleLoop(view: RiveAnimationView, isTrigger: boolean): void {
    if (!this.loopsValue) {
      return;
    }
    const duration = cylRiveActiveDuration(this.option(CYLAnimatedItemRiveOption.ACTIVE_DURATION));
    const seconds = !isTrigger && duration > 0 ? duration + CYL_RIVE_LOOP_PAUSE_SECONDS : CYL_RIVE_LOOP_SECONDS;
    this.loopTimer = setTimeout(() => {
      this.loopTimer = -1;
      if (this.loopsValue && this.riveView === view && this.active) {
        // [EN] A file still moving on its own is not cut short: check again after another pass. [CN] 仍在自行运动的文件不被打断：再等一次检查。
        if (this.cylRestartsOnPlay(view) && view.isPlaying()) {
          this.cylScheduleLoop(view, isTrigger);
        } else {
          this.cylPlay(view);
        }
      }
    }, seconds * 1000);
  }

  private cylCancelTimers(): void {
    this.cylCancelDeactivate();
    this.cylCancelLoop();
    this.cylCancelEndWatch();
  }

  private cylCancelEndWatch(): void {
    if (this.endWatchTimer >= 0) {
      clearInterval(this.endWatchTimer);
      this.endWatchTimer = -1;
    }
  }

  private cylCancelLoop(): void {
    if (this.loopTimer >= 0) {
      clearTimeout(this.loopTimer);
      this.loopTimer = -1;
    }
  }

  private cylCancelDeactivate(): void {
    this.startPending = false;
    if (this.deactivateTimer >= 0) {
      clearTimeout(this.deactivateTimer);
      this.deactivateTimer = -1;
    }
  }
}

/**
 * [EN] The Rive engine view: built once per item and driven through its state (never rebuilt on a selection change, so no
 *      Rive surface is created again); it never takes taps and is hidden from accessibility (the item reads instead).
 * [CN] Rive 引擎视图：每个条目只创建一次，通过 state 驱动（选中变化不会重建，因此不会再次创建 Rive surface）；不拦截点击，对无障碍隐藏（由条目朗读）。
 */
@Component
export struct CYLAnimatedItemRiveView {
  state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  private unlisten?: () => void;
  private cylLifecycle: LifecycleController<CYLAnimatedItemRiveView> | undefined = undefined;
  private binding: CYLAnimatedItemEngineBinding = new CYLAnimatedItemEngineBinding();
  private riveView: RiveAnimationView | null = null;
  private bytes: ArrayBuffer | null = null;
  private loadedUrl: string = '';
  private loaded: boolean = false;
  private unusable: boolean = false;

  aboutToAppear(): void {
    this.cylLifecycle = new LifecycleController<CYLAnimatedItemRiveView>(this);
    this.cylLifecycle.registry.addDeallocCallback<CYLAnimatedItemRiveView>((owner: CYLAnimatedItemRiveView) => owner.cylTeardown(), { key: 'cyl.rive.teardown' });
    this.cylLifecycle.aboutToAppear();
    this.unlisten = this.state.listen(() => this.cylStateChanged());
    try {
      cylEnsureRiveInitialized();
    } catch (e) {
      this.unusable = true;
      this.binding.failed(this.state);
      return;
    }
    this.cylReadFile();
  }

  aboutToDisappear(): void {
    this.cylLifecycle?.aboutToDisappear();
  }

  // [EN] The teardown block (CYLDeallocBlockExecutor), run by `aboutToDisappear`. [CN] 销毁块（CYLDeallocBlockExecutor），由 `aboutToDisappear` 运行。
  private cylTeardown(): void {
    this.unlisten?.();
    this.binding.release();
    this.riveView = null;
  }

  cylStateChanged(): void {
    if (this.unusable) {
      return;
    }
    if (this.state.source.url !== this.loadedUrl) {
      // [EN] A new file (the dark one after a color mode change). [CN] 新文件（如切换深色模式后的文件）。
      this.binding.release();
      this.loaded = false;
      this.cylReadFile();
      return;
    }
    this.binding.update(this.state);
  }

  private cylReadFile(): void {
    const source = this.state.source;
    this.loadedUrl = source.url;
    this.bytes = null;
    if (/^https?:\/\//i.test(source.path)) {
      // [EN] @ohos/rive reads bytes only; remote files are not supported yet. [CN] @ohos/rive 只读取字节；尚不支持远程文件。
      this.binding.failed(this.state);
      return;
    }
    const context = this.getUIContext().getHostContext();
    const content = context === undefined ? undefined : source.rawFileContent(context.resourceManager);
    if (content === undefined) {
      this.binding.failed(this.state);
      return;
    }
    this.bytes = content.buffer.slice(content.byteOffset, content.byteOffset + content.byteLength) as ArrayBuffer;
    this.cylLoadIfPossible();
  }

  private cylLoadIfPossible(): void {
    const view = this.riveView;
    const source = this.state.source;
    if (view === null || this.bytes === null || this.loaded) {
      return;
    }
    const option = (name: string): string | undefined => {
      const value = source.option(name);
      return value !== undefined && value.length > 0 ? value : undefined;
    };
    try {
      view.setRiveBytes(this.bytes, option(CYLAnimatedItemRiveOption.ARTBOARD), option(CYLAnimatedItemRiveOption.ANIMATION),
        option(CYLAnimatedItemRiveOption.STATE_MACHINE), true, true, Fit.CONTAIN, undefined, Loop.AUTO);
      this.loaded = true;
      this.binding.ready(this.state, new CYLAnimatedItemRivePlayer(source, view));
    } catch (e) {
      this.binding.failed(this.state);
    }
  }

  build() {
    Stack() {
      if (!this.unusable) {
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
    }
    .width(this.state.width)
    .height(this.state.height)
    // [EN] The icon never takes the item's taps and is not read on its own. [CN] 图标不拦截条目的点击，也不单独朗读。
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no-hide-descendants')
  }
}

@Builder
function cylRiveEngineView(state: CYLAnimatedItemEngineState) {
  CYLAnimatedItemRiveView({ state: state })
}

/**
 * [EN] The Rive engine: `register()` once (for example in `EntryAbility.onCreate`). Rive files play only where @ohos/rive
 *      has its native library (arm64-v8a); elsewhere items show their still image.
 * [CN] Rive 引擎：调用一次 `register()`（例如在 `EntryAbility.onCreate` 中）。Rive 文件只在 @ohos/rive 有原生库的设备上播放（arm64-v8a）；
 *      其他设备上条目显示静态图片。
 */
export class CYLAnimatedItemRive {
  static register(): void {
    CYLAnimatedItemEngineViews.register('Rive', wrapBuilder(cylRiveEngineView), undefined, undefined, [CYL_RIVE_ABI]);
  }
}
