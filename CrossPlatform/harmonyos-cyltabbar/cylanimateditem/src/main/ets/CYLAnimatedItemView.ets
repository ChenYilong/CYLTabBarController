import { CYLAnimatedItemTypeRegistry } from './CYLAnimatedItemTypes';
import { CYLLiquidGlass } from './CYLLiquidGlass';
import { CYLAnimatedItemBackgroundStyle, CYLAnimatedItemBackgroundModifier } from './CYLAnimatedItemBackground';
import { LifecycleCenter, LifecycleController } from 'cyldeallocblockexecutor';
import { cylIsSymbolResource } from './CYLAnimatedItemResources';
import {
  CYLAnimatedItemCountdown, CYLAnimatedItemCountdownListener, CYLAnimatedItemCountdownStorage, CYLCountdownRunning, CYLCountdownFinished,
  CYLCountdownTickIntervalMillis, cylCountdownText, cylCountdownTitleWidth
} from './CYLAnimatedItemCountdown';
import { preferences } from '@kit.ArkData';
import { ApplicationStateChangeCallback, common } from '@kit.AbilityKit';
import BuildProfile from '../../../BuildProfile';
import { deviceInfo } from '@kit.BasicServicesKit';
import { CYLAnimatedItemEngineState, CYLAnimatedItemEngineView } from './CYLAnimatedItemEngine';
import { CYLAnimatedItemPlayer } from './CYLAnimatedItemPlayer';
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';
import { CYLAnimatedItemTintInput, CYLAnimatedItemTintResult, cylAnimatedItemResolveTint } from './CYLAnimatedItemColors';
import {
  CYLAnimatedItemMissingReporter, CYLAnimatedItemResourceMissingCallback, cylAnimatedItemResourceOf, CYL_RESOURCE_DECODE_FAILED,
  CYL_RESOURCE_ENGINE_LIBRARY_MISSING
} from './CYLAnimatedItemMissing';

/** [EN] `maxLines` for a title without a line limit (`titleLines` 0). [CN] 标题不限行数（`titleLines` 为 0）时的 `maxLines`。 */
const CYL_UNLIMITED_LINES: number = 1000;

/**
 * [EN] Icon beside the title (default) or above it. [CN] 图标在标题旁（默认）或上方。
 */
export enum CYLAnimatedItemAxis {
  Horizontal = 0,
  Vertical = 1
}

/**
 * [EN] Where the accessory sits: before the content, after it (default) or on the icon's top-trailing corner.
 * [CN] 附加图标的位置：内容之前、之后（默认）或图标右上角。
 */
export enum CYLAnimatedItemAccessoryPlacement {
  Leading = 0,
  Trailing = 1,
  TopTrailing = 2
}


/**
 * [EN] The look of `CYLAnimatedItemView`: the plain animated icon + title (default), or a countdown button, e.g. for "Get the
 *      SMS code" (iOS `CYLAnimatedItemStyle`).
 * [CN] `CYLAnimatedItemView` 的样式：普通的动效 icon + title（默认），或倒计时按钮，例如「获取验证码」（对应 iOS 的 `CYLAnimatedItemStyle`）。
 */
export enum CYLAnimatedItemStyle {
  Plain = 0,
  Countdown = 1
}

/**
 * [EN] Keeps a running countdown in the app's preferences, so it survives the app being ended in the background.
 * [CN] 把运行中的倒计时保存在 App 的 preferences 中，使其在 App 于后台被结束后仍然有效。
 */
class CYLAnimatedItemPreferencesStorage implements CYLAnimatedItemCountdownStorage {
  private store?: preferences.Preferences;

  constructor(context: Context) {
    try {
      this.store = preferences.getPreferencesSync(context, { name: 'CYLAnimatedItemCountdown' });
    } catch (error) {
      // [EN] Without preferences the countdown only loses the restart case. [CN] 没有 preferences 时只会丢失重启恢复。
    }
  }

  get(name: string): string | undefined {
    try {
      let value: preferences.ValueType | undefined = this.store?.getSync(name, '');
      return typeof value === 'string' && value.length > 0 ? value : undefined;
    } catch (error) {
      return undefined;
    }
  }

  set(name: string, value: string): void {
    try {
      this.store?.putSync(name, value);
      this.store?.flush();
    } catch (error) {
      // [EN] A failed write only loses the restart case. [CN] 写入失败只会丢失重启恢复。
    }
  }

  remove(name: string): void {
    try {
      this.store?.deleteSync(name);
      this.store?.flush();
    } catch (error) {
      // [EN] Nothing to drop. [CN] 没有可丢弃的内容。
    }
  }
}

/**
 * [EN] What the animation builder gets: the file, its size, the selection, and two callbacks the engine calls once the file
 *      is ready (`onLoaded`) or cannot play (`onFailed`, a corrupt file, a failed download). Until `onLoaded` the item keeps
 *      its static image (or the placeholder) under the animation; after `onFailed` it shows them again.
 * [CN] 动画 builder 得到的内容：文件、尺寸、选中状态，以及两个回调，引擎在文件就绪时调用 `onLoaded`，无法播放时（文件损坏、下载失败）调用
 *      `onFailed`。调用 `onLoaded` 之前，条目在动画下方保留静态图片（或占位图）；调用 `onFailed` 之后重新显示它们。
 */
export class CYLAnimatedItemAnimationContext {
  url: string = '';
  size: number = 24;
  selected: boolean = false;
  /**
   * [EN] The playback the engine applies (the item's `animationSpeed`, `animationLoops`, and `restartToken`, which grows
   *      on every restart: the engine plays from progress 0 when it changes). The item hands a new context to the builder
   *      whenever one of them changes, so the engine view gets them as props and needs no state of the host.
   * [CN] 引擎应用的播放设置（条目的 `animationSpeed`、`animationLoops`，以及每次重播都会增长的 `restartToken`：变化时引擎从进度 0 播放）。
   *      其中任一项变化时条目都会把新的 context 交给 builder，因此引擎视图通过 prop 获得它们，不需要宿主的状态。
   */
  speed: number = 1;
  loops: boolean = false;
  restartToken: number = 0;
  onLoaded: () => void = () => {
  };
  /** [EN] `reason` is optional: "decode failed" without one. [CN] `reason` 可省略：省略时为 "decode failed"。 */
  onFailed: (reason?: string) => void = (_reason?: string) => {
  };
  /**
   * [EN] Called by the engine when a play-once pass (`loops` off) reaches its end; the item then shows its still image
   *      (`showsImageWhenAnimationEnds`) and calls `onAnimationEnd`. An engine that cannot tell never calls it.
   * [CN] 只播放一次（`loops` 关闭）的一遍播放到结尾时由引擎调用；条目随即显示静态图片（`showsImageWhenAnimationEnds`）并调用
   *      `onAnimationEnd`。无法判断结束的引擎从不调用它。
   */
  onEnded: () => void = () => {
  };
  /**
   * [EN] The engine view registers how it replays (from progress 0); the item calls it each time `restartToken` grows.
   *      ArkUI copies a builder's values once when an arrow function wraps the builder (a host's `this`), so a prop
   *      alone may never see the new token (B23).
   * [CN] 引擎视图注册其重播方式（从进度 0 播放）；`restartToken` 每次增长时条目调用它。宿主用箭头函数包装 builder（绑定 `this`）时，
   *      ArkUI 只复制一次 builder 的值，因此仅靠 prop 可能永远看不到新标记（B23）。
   */
  setRestartHandler: (handler: () => void) => void = (_handler: () => void) => {
  };
}

/**
 * [EN] Imperative playback for a `CYLAnimatedItemView` (iOS / Android `restartAnimation`): pass one as `controller`, then
 *      call `restartAnimation()`, for example from `onItemTap`. The props `animationSpeed`, `animationLoops` and
 *      `animationRestartToken` do the same declaratively.
 * [CN] `CYLAnimatedItemView` 的命令式播放控制（iOS / Android 的 `restartAnimation`）：作为 `controller` 传入，然后调用 `restartAnimation()`，
 *      例如在 `onItemTap` 中。prop `animationSpeed`、`animationLoops` 与 `animationRestartToken` 以声明式实现相同功能。
 */
export class CYLAnimatedItemController {
  /** [EN] Set by the item it is attached to. [CN] 由所关联的条目设置。 */
  cylRestart: () => void = () => {
  };

  /** [EN] Plays the animation again from progress 0. [CN] 从进度 0 重新播放动画。 */
  restartAnimation(): void {
    this.cylRestart();
  }

  /** [EN] Set by the item it is attached to. [CN] 由所关联的条目设置。 */
  cylStartCountdown: (seconds: number) => void = (_seconds: number) => {
  };
  cylResetCountdown: () => void = () => {
  };
  cylRefreshCountdown: () => void = () => {
  };

  /**
   * [EN] Starts (or restarts) the countdown for `seconds` (0 or less: `countdownDuration`, e.g. the server's "retry after").
   *      The item must have `itemStyle` `CYLAnimatedItemStyle.Countdown`. [CN] 开始（或重新开始）`seconds` 秒的倒计时
   *      （0 或更小：使用 `countdownDuration`，例如服务器返回的「多少秒后重试」）。条目的 `itemStyle` 必须为 `CYLAnimatedItemStyle.Countdown`。
   */
  startCountdown(seconds: number = 0): void {
    this.cylStartCountdown(seconds);
  }

  /** [EN] Stops and shows the idle title, with no finish callback. [CN] 停止并显示待机标题，不触发结束回调。 */
  resetCountdown(): void {
    this.cylResetCountdown();
  }

  /** [EN] Reads the clock now (done by the item itself). [CN] 立即读取时钟（条目自己会做）。 */
  refreshCountdown(): void {
    this.cylRefreshCountdown();
  }
}

/**
 * [EN] The animation type of a file from its extension ("Lottie", "PAG", "Rive", "SVGA", "GIF", or a type an app
 *      registered with its extensions), or '' when unknown.
 * [CN] 根据扩展名得到文件的动画类型（"Lottie"、"PAG"、"Rive"、"SVGA"、"GIF"，或 App 连同扩展名注册的类型），未知时为 ''。
 */
export function cylAnimatedItemTypeOf(url: string): string {
  return CYLAnimatedItemTypeRegistry.typeOf(url);
}

/**
 * [EN] The animation engines an app registered, by type. The component depends on no animation library: an app (or a
 *      library such as cyltabbar) registers the types it can play and passes `animationBuilder`; a file of a type nobody
 *      registered shows the static image, or the placeholder, and debug builds log once which package to add. The
 *      counterpart of iOS `CYLTabBarItemAnimatorRegistry` / `CYLAnimationWarnMissingEngine()` and Android
 *      `CYLAnimationEngines`.
 * [CN] App 按类型注册的动画引擎。组件不依赖任何动画库：App（或 cyltabbar 这样的库）注册它能播放的类型并传入 `animationBuilder`；
 *      没有注册的类型显示静态图片或占位图，debug 构建会输出一次需要加入的包。对应 iOS 的 `CYLTabBarItemAnimatorRegistry` /
 *      `CYLAnimationWarnMissingEngine()` 与 Android 的 `CYLAnimationEngines`。
 */
export class CYLAnimatedItemEngines {
  private static warned: string[] = [];

  /**
   * [EN] Called when an animation file cannot be shown, with the file name or path as configured and a short reason ("not
   *      found", "unreadable", "decode failed", "engine library missing"): once per resource per item. The same call as
   *      `CYLAnimatedItemView.onResourceMissing`, for a host that holds no item (CYLPlaceholder's status bar). Nothing else
   *      changes. iOS and Android: `CYLAnimationEngines.resourceMissingListener`.
   * [CN] 动画文件无法显示时调用，参数为按配置给出的文件名或路径与简短原因：每个条目每个资源一次。与 `CYLAnimatedItemView.onResourceMissing`
   *      是同一次调用，供不持有条目的宿主使用（CYLPlaceholder 状态栏）。其他行为不变。
   */
  static resourceMissingListener: CYLAnimatedItemResourceMissingCallback | undefined = undefined;

  /**
   * [EN] Reads the device's ABIs (`deviceInfo.abiList`) once, so engines whose native library is not built for this device
   *      (PAG and Rive: arm64-v8a only) do not play on the x86_64 emulator: the item shows its still image instead of
   *      loading a missing .so and crashing.
   * [CN] 读取一次设备的 ABI（`deviceInfo.abiList`），使原生库没有为本设备构建的引擎（PAG 与 Rive：只有 arm64-v8a）在 x86_64 模拟器上不播放：
   *      条目显示静态图片，而不是加载缺失的 .so 并崩溃。
   */
  private static cylX86DebugEngines: string[] | undefined = undefined;

  /**
   * [EN] Turns on the engines of the x86_64 debug engine kit (`x86_64-debug-engines`, e.g. Rive built
   *      for x86_64) when `tools/cyl_hap_x86_64.py install` added it to this HAP, which it marks with the rawfile
   *      `cyl_x86_64_debug_engines.json`; those engines then also accept `x86_64`, in debug and release builds. A HAP
   *      installed without the kit changes nothing (PAG and Rive keep their still images on x86_64). Kept once found; returns the engines.
   *      CYLAnimatedItemView and CYLTabBarController call it. Owner's Plan 1: the debug-build guard was removed with
   *      the owner's approval (2026-11-23); the marker and the device's x86_64 ABI remain the guards.
   * [CN] 当 `tools/cyl_hap_x86_64.py install` 把 x86_64 调试引擎包（`x86_64-debug-engines`，例如为 x86_64 构建的 Rive）
   *      加入本 HAP（以 rawfile `cyl_x86_64_debug_engines.json` 标记）时，开启该包中的引擎，这些引擎随即也接受 `x86_64`。debug 与 release
   *      构建均适用；未安装该包的 HAP 不做任何改变（x86_64 上 PAG 与 Rive 保持静态图片）。找到后保留；返回这些引擎。
   */
  static loadX86_64DebugEngines(context: common.Context | undefined): string[] {
    if (CYLAnimatedItemEngines.cylX86DebugEngines !== undefined && CYLAnimatedItemEngines.cylX86DebugEngines.length > 0) {
      return CYLAnimatedItemEngines.cylX86DebugEngines.slice();
    }
    let engines: string[] = [];
    if (context !== undefined) {
      try {
        const bytes: Uint8Array = context.resourceManager.getRawFileContentSync('cyl_x86_64_debug_engines.json');
        let text: string = '';
        bytes.forEach((byte: number) => { text += String.fromCharCode(byte); });
        const parsed: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
        engines = (parsed['engines'] as string[] | undefined) ?? [];
      } catch (e) {
        engines = [];
      }
    }
    engines.forEach((type: string) => {
      const required: string[] = CYLAnimatedItemTypeRegistry.requiredNativeAbis(type);
      if (required.length > 0 && required.indexOf('x86_64') < 0) {
        CYLAnimatedItemTypeRegistry.setRequiredNativeAbis(type, required.concat(['x86_64']));
      }
    });
    if (engines.length > 0) {
      console.warn(`[CYLAnimatedItem] x86_64 debug engine kit active: ${engines.join(', ')}.`);
    }
    CYLAnimatedItemEngines.cylX86DebugEngines = engines;
    return engines.slice();
  }

  /** [EN] The engines `loadX86_64DebugEngines` turned on. [CN] `loadX86_64DebugEngines` 开启的引擎。 */
  static x86_64DebugEngines(): string[] {
    return (CYLAnimatedItemEngines.cylX86DebugEngines ?? []).slice();
  }

  private static cylReadDeviceAbis(): void {
    if (!CYLAnimatedItemTypeRegistry.hasDeviceAbis()) {
      CYLAnimatedItemTypeRegistry.setDeviceAbis((deviceInfo.abiList ?? '').split(','));
    }
  }

  /**
   * [EN] Sets the native ABIs the engine of `type` needs (one of them must be on the device); [] = any device. Built in:
   *      PAG and Rive need arm64-v8a (@tencent/libpag 4.4.31, @ohos/rive 1.0.4). Call it when a library version adds an ABI.
   * [CN] 设置 `type` 的引擎需要的原生 ABI（设备需具备其中之一）；[] 表示任何设备。内置：PAG 与 Rive 需要 arm64-v8a。库的新版本加入 ABI 时调用。
   */
  static setRequiredNativeAbis(type: string, abis: string[]): void {
    CYLAnimatedItemTypeRegistry.setRequiredNativeAbis(type, abis);
  }

  /** [EN] The native ABIs the engine of `type` needs; [] = any device. [CN] `type` 的引擎需要的原生 ABI；[] 表示任何设备。 */
  static requiredNativeAbis(type: string): string[] {
    return CYLAnimatedItemTypeRegistry.requiredNativeAbis(type);
  }

  /**
   * [EN] Whether this device can load the engine of `type` (false for PAG and Rive on the x86_64 emulator).
   * [CN] 本设备能否加载 `type` 的引擎（x86_64 模拟器上 PAG 与 Rive 为 false）。
   */
  static isSupportedOnDevice(type: string): boolean {
    CYLAnimatedItemEngines.cylReadDeviceAbis();
    return CYLAnimatedItemTypeRegistry.supportsDevice(type);
  }

  /** [EN] The device's ABIs (`deviceInfo.abiList`). [CN] 设备的 ABI（`deviceInfo.abiList`）。 */
  static deviceAbis(): string[] {
    CYLAnimatedItemEngines.cylReadDeviceAbis();
    return CYLAnimatedItemTypeRegistry.currentDeviceAbis();
  }

  /**
   * [EN] Overrides the device's ABIs (tests, e.g. ['x86_64'] on an arm64 device); undefined reads `deviceInfo.abiList` again.
   * [CN] 覆盖设备的 ABI（测试用，例如在 arm64 设备上设为 ['x86_64']）；undefined 表示重新读取 `deviceInfo.abiList`。
   */
  static setDeviceAbis(abis: string[] | undefined): void {
    CYLAnimatedItemTypeRegistry.setDeviceAbis(abis);
  }

  /**
   * [EN] Why `url` does not play on this device although its engine is registered (its native library is not built for the
   *      device's ABIs), or '' (it plays, or the engine is simply not registered).
   * [CN] 引擎已注册但 `url` 在本设备上不播放的原因（其原生库没有为设备的 ABI 构建），否则为 ''（能播放，或只是引擎未注册）。
   */
  static unsupportedReason(url: string): string {
    CYLAnimatedItemEngines.cylReadDeviceAbis();
    return CYLAnimatedItemTypeRegistry.unsupportedReason(url);
  }

  /**
   * [EN] Registers the engine of `type` ("Lottie", "PAG", "Rive", "SVGA", "GIF"). With `extensions`, an app can add its own
   *      type (`register('APNG', ['apng'])`, then `animationBuilder` draws it) or more extensions for a known type;
   *      `packageName` names what to add in the debug log; `nativeAbis` the native ABIs its library ships (see
   *      `setRequiredNativeAbis`).
   * [CN] 注册 `type` 的引擎（"Lottie"、"PAG"、"Rive"、"SVGA"、"GIF"）。传入 `extensions` 时，App 可以添加自己的类型（`register('APNG', ['apng'])`，
   *      再由 `animationBuilder` 绘制），或为已知类型添加扩展名；`packageName` 为 debug 日志中提示加入的包；`nativeAbis` 为其库提供的原生 ABI（见 `setRequiredNativeAbis`）。
   */
  static register(type: string, extensions?: string[], packageName?: string, nativeAbis?: string[]): void {
    CYLAnimatedItemTypeRegistry.register(type, extensions, packageName, nativeAbis);
  }

  /**
   * [EN] Unregisters the engine of `type`: its files show the static image again; a type an app added is forgotten.
   * [CN] 注销 `type` 的引擎：其文件重新显示静态图片；App 添加的类型被遗忘。
   */
  static unregister(type: string): void {
    CYLAnimatedItemTypeRegistry.unregister(type);
  }

  /** [EN] Whether the engine of `type` is registered. [CN] `type` 的引擎是否已注册。 */
  static isRegistered(type: string): boolean {
    return CYLAnimatedItemTypeRegistry.isRegistered(type);
  }

  /** [EN] The registered types. [CN] 已注册的类型。 */
  static registeredTypes(): string[] {
    return CYLAnimatedItemTypeRegistry.registeredTypes();
  }

  /** [EN] The known types nobody registered. [CN] 没有注册的已知类型。 */
  static missingTypes(): string[] {
    return CYLAnimatedItemTypeRegistry.missingTypes();
  }

  /** [EN] Whether a registered engine plays `url` (by its extension). [CN] 是否有已注册的引擎能播放 `url`（按扩展名）。 */
  static canPlay(url: string): boolean {
    CYLAnimatedItemEngines.cylReadDeviceAbis();
    return CYLAnimatedItemTypeRegistry.canPlay(url);
  }

  /**
   * [EN] In debug builds, logs once per type that `url` cannot play because its engine is not registered, with the package
   *      to add. Nothing in release builds, for an unknown type or when the engine is registered.
   * [CN] 在 debug 构建中，每种类型输出一次日志：`url` 因引擎未注册而无法播放，并给出需要加入的包。release 构建、未知类型或引擎已注册时不做任何事。
   */
  static warnMissingEngine(url: string): void {
    let name: string = cylAnimatedItemTypeOf(url);
    if (!BuildProfile.DEBUG || name.length === 0 || CYLAnimatedItemEngines.warned.indexOf(name) >= 0) {
      return;
    }
    if (CYLAnimatedItemEngines.isRegistered(name)) {
      let reason: string = CYLAnimatedItemEngines.unsupportedReason(url);
      if (reason.length > 0) {
        CYLAnimatedItemEngines.warned.push(name);
        console.warn(`[CYLAnimatedItem] ${name} animation (${url}) cannot play on this device: ${reason}. Showing the ` +
          `static image, or the placeholder without one. Test its playback on an arm64 device. Shown in debug builds only.`);
      }
      return;
    }
    CYLAnimatedItemEngines.warned.push(name);
    let packageName: string = '';
    for (let type of CYLAnimatedItemTypeRegistry.knownTypes()) {
      if (type.name === name) {
        packageName = type.packageName;
      }
    }
    console.warn(`[CYLAnimatedItem] ${name} animation (${url}) cannot play: no ${name} engine is registered. ` +
      `Showing the static image, or the placeholder without one. Add ${packageName} and call ` +
      `CYLAnimatedItemEngines.register('${name}') with an animationBuilder. Shown in debug builds only.`);
  }
}

/**
 * [EN] The color filter that paints a bitmap in `color` keeping each pixel's alpha (each channel = the color's component x
 *      the pixel's alpha; no offsets, so it does not depend on the channel range); the identity when `color` is '' or not
 *      a '#RRGGBB' / '#AARRGGBB' string. [CN] 以 `color` 绘制位图且保留每个像素透明度的颜色滤镜；color 为空或不是十六进制字符串时为恒等滤镜。
 */
export function cylIconColorFilter(color: ResourceColor): number[] {
  const identity: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  if (typeof color !== 'string' || !new RegExp('^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').test(color)) {
    return identity;
  }
  const hex = (color as string).replace('#', '');
  const argb = hex.length === 6 ? 'FF' + hex : hex;
  const c = (index: number): number => parseInt(argb.substring(index, index + 2), 16) / 255;
  return [0, 0, 0, c(2), 0, 0, 0, 0, c(4), 0, 0, 0, 0, c(6), 0, 0, 0, 0, c(0), 0];
}

/**
 * [EN] An icon + title view to reuse or wrap (CollectionViewClassifyMenu's tags, CYLSearchViewController's bar items,
 *      CYLTableViewPlaceHolder's placeholders): an icon that plays an animation file through `animationBuilder`, its static
 *      image, a title beside or below it, an optional accessory with its own tap, and gestures on the whole item (tap, long
 *      press, drag). What shows, as on iOS and Android: the animation when a registered engine can play it; otherwise, while
 *      it loads and after it fails, the static image (`image` / `selectedImage`); the placeholder only when there is no
 *      static image. It is one accessibility element: its text is `itemTitle` (or `itemAccessibilityText`), its description
 *      `itemDescription` plus, while selected, `selectedDescription` (localized by the caller, like every text it shows).
 * [CN] 可复用或包装的图标 + 标题视图（CollectionViewClassifyMenu 的标签、CYLSearchViewController 的栏目、CYLTableViewPlaceHolder 的占位图）：
 *      通过 `animationBuilder` 播放动画文件的图标、其静态图片、位于旁边或下方的标题、带独立点击的可选附加图标，以及整个条目的手势（点击、长按、拖拽）。
 *      显示规则与 iOS、Android 相同：已注册的引擎能播放时显示动画；否则在加载期间与失败之后显示静态图片（`image` / `selectedImage`）；只有没有静态图片时
 *      才显示占位图。它是一个无障碍元素：文本为 `itemTitle`（或 `itemAccessibilityText`），描述为 `itemDescription` 加上选中状态。
 */
let cylPausesWhileScrolling: boolean = false;
let cylScrollObserverNumber: number = 0;

/**
 * [EN] true: every animated item pauses while the user scrolls (the app reports the scrolling with `scrollStarted()` /
 *      `scrollStopped()` of a LifecycleController, or `cyl_reportScrollStarted()` of cyltabbar) and resumes afterwards. Read when
 *      an item appears. Module-level, because ArkTS keeps statics off structs. [CN] 为 true 时，用户滚动期间所有动画条目暂停，
 *      滚动结束后恢复。条目出现时读取。放在模块级，因为 ArkTS 不在 struct 上放静态成员。
 */
export function cylSetPausesWhileUserScrolls(enabled: boolean): void {
  cylPausesWhileScrolling = enabled;
}

export function cylPausesWhileUserScrolls(): boolean {
  return cylPausesWhileScrolling;
}

function cylNextScrollObserverNumber(): number {
  cylScrollObserverNumber += 1;
  return cylScrollObserverNumber;
}

@Component
export struct CYLAnimatedItemView {
  @Prop itemTitle: string = '';
  @Prop image: ResourceStr = '';
  @Prop selectedImage: ResourceStr = '';
  @Prop placeholderImage: ResourceStr = $r('app.media.cyl_animated_item_placeholder');
  @Prop @Watch('cylAnimationDidChange') animationUrl: string = '';
  @Prop @Watch('cylPlaybackDidChange') isItemSelected: boolean = false;
  /**
   * [EN] Playback speed of the animation, 1 by default (iOS / Android `animationSpeed`). [CN] 动画播放速度，默认 1（iOS / Android `animationSpeed`）。
   */
  @Prop @Watch('cylPlaybackDidChange') animationSpeed: number = 1;
  /**
   * [EN] Whether the animation repeats (iOS / Android `animationLoops`). [CN] 动画是否循环（iOS / Android `animationLoops`）。
   */
  @Prop @Watch('cylPlaybackDidChange') animationLoops: boolean = false;
  /**
   * [EN] Any change plays the animation again from progress 0 (declarative `restartAnimation`); see also `controller`.
   * [CN] 任何变化都会让动画从进度 0 重新播放（声明式的 `restartAnimation`）；另见 `controller`。
   */
  @Prop @Watch('cylPlaybackDidChange') animationRestartToken: number = 0;
  /**
   * [EN] Whether a play-once animation (`animationLoops` off) is replaced by the still image when it ends (iOS / Android
   *      `showsImageWhenAnimationEnds`): the animation is hidden and `selectedImage` / `image` (else the placeholder)
   *      shows. Off by default, so the last frame stays. The next play (a restart, a new selection) shows the animation
   *      again. Needs an engine that reports the end (`CYLAnimatedItemAnimationContext.onEnded`: Lottie and SVGA in cyltabbar).
   * [CN] 只播放一次的动画（`animationLoops` 关闭）结束时是否换成静态图片（iOS / Android 的 `showsImageWhenAnimationEnds`）：隐藏动画，
   *      显示 `selectedImage` / `image`（没有时为占位图）。默认关闭，保留最后一帧。下一次播放（重播、重新选中）重新显示动画。需要能报告结束的引擎
   *      （`CYLAnimatedItemAnimationContext.onEnded`：cyltabbar 中的 Lottie 与 SVGA）。
   */
  @Prop @Watch('cylEndImageDidChange') showsImageWhenAnimationEnds: boolean = false;
  /**
   * [EN] Called when a play-once animation ends (iOS / Android `animationEndListener`). [CN] 只播放一次的动画结束时调用。
   */
  onAnimationEnd?: () => void;
  /**
   * [EN] Called when the animation file cannot be shown, with the file name or path as configured (`animationUrl` without its
   *      `#` options) and a short reason: "not found", "unreadable", "decode failed" or "engine library missing". Once per
   *      resource per item; the item shows its image or the placeholder as before.
   *      `CYLAnimatedItemEngines.resourceMissingListener` hears the same call. iOS and Android: `onResourceMissing`.
   * [CN] 动画文件无法显示时调用，参数为按配置给出的文件名或路径（`animationUrl` 去掉 `#` 选项）与简短原因："not found"、"unreadable"、
   *      "decode failed"、"engine library missing"。每个条目每个资源一次；条目仍显示图片或占位图。
   *      `CYLAnimatedItemEngines.resourceMissingListener` 收到同一次调用。
   */
  onResourceMissing?: CYLAnimatedItemResourceMissingCallback;
  private cylMissingReporter: CYLAnimatedItemMissingReporter = new CYLAnimatedItemMissingReporter();
  /** [EN] The still image replaces the ended animation. [CN] 静态图片替换了已结束的动画。 */
  @State cylShowsImageAfterEnd: boolean = false;
  private cylLastSelected: boolean = false;
  /** [EN] Optional imperative control (`restartAnimation()`). [CN] 可选的命令式控制（`restartAnimation()`）。 */
  controller?: CYLAnimatedItemController;
  @State private cylControllerRestarts: number = 0;
  /** [EN] The engine view's replay (B23) and the token it last saw. [CN] 引擎视图的重播（B23）及其上次看到的标记。 */
  private cylRestartHandler?: () => void;
  private cylLastRestartToken: number = 0;
  private cylSetRestartHandler: (handler: () => void) => void = (handler: () => void) => {
    this.cylRestartHandler = handler;
  };
  @Prop isItemEnabled: boolean = true;
  @Prop axis: CYLAnimatedItemAxis = CYLAnimatedItemAxis.Horizontal;
  @Prop iconSize: number = 24;
  /**
   * [EN] The color of the static icon (`image` / `selectedImage` / the placeholder), as iOS tints template images: SVG
   *      and symbol images take it as their fill, bitmaps through an alpha-preserving color filter. '' (the default)
   *      keeps the image's own colors. A '#RRGGBB' / '#AARRGGBB' string tints bitmaps too; a resource color tints SVG
   *      only. [CN] 静态图标的颜色（如 iOS 的模板图着色）：SVG 与符号图作为填充色，位图通过保留透明度的颜色滤镜着色；''（默认）保留原色。
   */
  @Prop iconColor: ResourceColor = '';
  /**
   * [EN] The background: `flat` (default) fills the view with `itemBackgroundColor`; `liquidGlass` draws Liquid Glass (a blur
   *      with the tint `itemBackgroundColor`) clipped to `itemCornerRadius`; where `CYLLiquidGlass.isActive()` is false the style
   *      is ignored and the view stays flat. Setting any `item…` background property makes the view draw its background, corner
   *      radius and border (the countdown style keeps its own). Same names as iOS and Android.
   * [CN] 背景：`flat`（默认）用 `itemBackgroundColor` 填充；`liquidGlass` 绘制液态玻璃（带 `itemBackgroundColor` 着色的模糊），按
   *      `itemCornerRadius` 裁剪；`CYLLiquidGlass.isActive()` 为 false 时忽略该样式，保持扁平。设置任一 `item…` 背景属性后，视图绘制其
   *      背景、圆角与边框（倒计时样式保持自己的外观）。与 iOS、Android 同名。
   */
  @Prop itemBackgroundStyle: CYLAnimatedItemBackgroundStyle = CYLAnimatedItemBackgroundStyle.flat;
  /** [EN] The solid fill when flat, the glass tint when liquid glass; '' for none. A liquid glass color with alpha 0 ('#00000000', `Color.Transparent`) draws the default frosted tint, as ''. [CN] 扁平时的纯色填充，液态玻璃时的着色；'' 表示无。液态玻璃的颜色透明度为 0（'#00000000'、`Color.Transparent`）时使用默认的磨砂着色，与 '' 相同。 */
  @Prop itemBackgroundColor: ResourceColor = '';
  /**
   * [EN] The corner radius in vp: a larger value than half the height is a capsule (the platform clamps), 0 is square. -1 (the
   *      default) is not set: the Liquid Glass style is a capsule, so a host gets a capsule without setting anything and customizes
   *      it by setting this property; the flat style is square.
   * [CN] 圆角半径（vp）：大于半高的值为胶囊（平台会截断），0 为直角。-1（默认）表示未设置：液态玻璃样式为胶囊，宿主无需设置任何属性即可得到
   *      胶囊，要自定义时设置此属性即可；扁平样式为直角。
   */
  @Prop itemCornerRadius: number = -1;
  /**
   * [EN] The space between the outer border and the content on the left and right, in vp, on top of the padding. -1 (the default) is not set:
   *      the drawn Liquid Glass gets `CYLAnimatedItemLiquidGlassContentInset` (a capsule's round ends take room from the content), flat gets 0 (the
   *      view looks as before); 0 or more is explicit, also 0 on glass. The partner of `itemCornerRadius`: the same condition decides both.
   * [CN] 外侧边框与内容之间左右的间距（vp），叠加在 padding 之上。-1（默认）表示未设置：绘制液态玻璃时取 `CYLAnimatedItemLiquidGlassContentInset`
   *      （胶囊圆端会占去内容空间），扁平为 0（与以往相同）；0 及以上为显式值，玻璃上也可为 0。与 `itemCornerRadius` 一一对应：由同一条件决定两者。
   */
  @Prop itemContentHorizontalInset: number = -1;
  /** [EN] The border width in vp. [CN] 边框宽度（vp）。 */
  @Prop itemBorderWidth: number = 0;
  /** [EN] The border color; '' for none. [CN] 边框颜色；'' 表示无。 */
  @Prop itemBorderColor: ResourceColor = '';
  /**
   * [EN] The share of the color's alpha that tints a Liquid Glass: -1 (the default) is 0.75; 1 uses the color as it is (a selected tag keeps its
   *      full color, still glass). [CN] 颜色透明度中用于给液态玻璃着色的比例：-1（默认）为 0.75；1 表示按原色（选中的标签保持完整颜色，仍是玻璃）。
   */
  @Prop itemGlassTintAlpha: number = -1;
  /**
   * [EN] The color the animation is drawn in, as one color, like a tinted template image (iOS / Android
   *      `CYLTabBarAnimationOptionTint`); '' keeps the file's own colors. Any engine: a layer of this color is
   *      composited "source in" over the engine view, in its own offscreen group, so the shape takes the color and its
   *      alpha (a 60 % white tint draws a 60 % white icon, as Android's SRC_IN; "source atop" kept a white icon white).
   * [CN] 动画以单一颜色绘制时使用的颜色，与着色的模板图片一致（iOS / Android 的 `CYLTabBarAnimationOptionTint`）；'' 保留文件自身的颜色。
   *      适用于任何引擎：在引擎视图上方以 "source in" 合成一层该颜色，位于独立的离屏组中，因此图形取该颜色及其透明度（60% 白色的着色绘制出
   *      60% 白色的图标，与 Android 的 SRC_IN 一致；"source atop" 会让白色图标保持白色）。
   */
  @Prop animationTintColor: ResourceColor = '';
  /**
   * [EN] The unified animation tint, the same names and values as Rive's `tint` option (iOS `CYLTabBarAnimationOptionTint`): "title" draws
   *      the animation like a template image in the item's icon color (`iconColor`, which the host sets for the current state, so the
   *      selected state's when selected); "#RRGGBB" / "#RRGGBBAA" draws it in that fixed color on the unselected item, the selected item
   *      takes its icon color; '' (the default) is not set. A set value overrides the `tint` option of the animation source
   *      (`file#tint=title`); unset uses the option, and without one the file keeps its own colors. Without an icon color there is
   *      nothing to draw "title" in: no automatic recolor. Any engine, through the same layer as `animationTintColor` (which, when set,
   *      wins as the already resolved color). Reactive: setting or clearing it after the file loaded redraws.
   * [CN] 统一的动画着色，名称与取值同 Rive 的 `tint` 选项（iOS `CYLTabBarAnimationOptionTint`）："title" 像模板图片一样用条目的图标颜色
   *      （`iconColor`，由宿主按当前状态设置，因此选中时为选中状态的颜色）绘制动画；"#RRGGBB" / "#RRGGBBAA" 在未选中的条目上用该固定颜色绘制，
   *      选中的条目使用其图标颜色；''（默认）表示未设置。设置后覆盖动画来源的 `tint` 选项（`file#tint=title`）；未设置则使用该选项，
   *      都没有时文件保持自身颜色。没有图标颜色时 "title" 无颜色可用：不自动改色。适用于任何引擎，使用与 `animationTintColor` 相同的着色层
   *      （后者设置时作为已解析的颜色优先）。响应式：文件加载后设置或清除都会重绘。
   */
  @Prop @Watch('cylTintDidChange') animationTint: string = '';
  /**
   * [EN] The dark-mode color of a fixed `animationTint` ("#RRGGBB" / "#RRGGBBAA"; Rive's `darkTint` option); not needed for "title". A set
   *      value overrides the `darkTint` option of the source. The mode is the app's (`cyl_colorMode` in AppStorage, set by cyltabbar's
   *      `cyl_updateColorMode`; light when unset).
   * [CN] 固定 `animationTint` 在深色模式下的颜色（"#RRGGBB" / "#RRGGBBAA"；Rive 的 `darkTint` 选项）；"title" 不需要。设置后覆盖来源的
   *      `darkTint` 选项。模式取自 App（AppStorage 中的 `cyl_colorMode`，由 cyltabbar 的 `cyl_updateColorMode` 设置；未设置时为浅色）。
   */
  @Prop @Watch('cylTintDidChange') animationDarkTint: string = '';
  /** [EN] The app's color mode ('dark' / 'light'), the key cyltabbar's `CYLColorModeStorageKey` names. [CN] App 的颜色模式。 */
  @StorageProp('cyl_colorMode') @Watch('cylTintDidChange') private cylColorMode: string = 'light';
  private cylTintSource: CYLAnimatedItemSource | undefined = undefined;
  /**
   * [EN] The gap in vp between the icon and the title, and between an inline accessory and the rest (iOS `spacing`,
   *      Android `spacingDp`, the mini program's `titleSpacing`). Bug B21: it was declared but never read.
   * [CN] 图标与标题之间、行内附件与其余内容之间的间距（vp）（iOS `spacing`、Android `spacingDp`、小程序 `titleSpacing`）。问题 B21：此前声明了却从未使用。
   */
  @Prop spacing: number = 4;
  /**
   * [EN] The most lines of the title: 1 (the default) is one line with an ellipsis, 0 has no limit (as the mini
   *      program's `titleLines`). [CN] 标题的最大行数：1（默认）为单行加省略号，0 不限（与小程序的 `titleLines` 相同）。
   */
  @Prop titleLines: number = 1;
  @Prop titleFontSize: number = 14;
  @Prop titleColor: ResourceColor = '#333333';
  @Prop accessoryImage: ResourceStr = '';
  @Prop accessoryText: string = '';
  @Prop accessoryAccessibilityText: string = '';
  @Prop accessoryPlacement: CYLAnimatedItemAccessoryPlacement = CYLAnimatedItemAccessoryPlacement.Trailing;
  @Prop isDragEnabled: boolean = false;
  /**
   * [EN] The look: plain (default) or a countdown button (iOS `itemStyle`). Set the `countdown…` props, then call
   *      `controller.startCountdown()` (or set `startsCountdownOnTap`). The end is a time read from the local clock, so the
   *      seconds in the background count (FIX: issue #1 of SMSCodeButton); a clock past the longest duration, or set back to
   *      before the start, closes it; `countdownCacheKey` keeps it across a restart. While it runs the item is disabled.
   * [CN] 样式：普通（默认）或倒计时按钮（对应 iOS 的 `itemStyle`）。设置 `countdown…` prop 后调用 `controller.startCountdown()`
   *      （或设置 `startsCountdownOnTap`）。结束是从本地时钟读取的时间点，因此后台的秒数计入（修复 SMSCodeButton 的 issue #1）；时钟超过最长时长
   *      或被调回到开始之前时关闭；`countdownCacheKey` 使其在重启后继续。倒计时中条目不可用。
   */
  @Prop @Watch('cylCountdownKeyDidChange') itemStyle: CYLAnimatedItemStyle = CYLAnimatedItemStyle.Plain;
  /** [EN] The length in seconds, 60 by default. [CN] 总时长（秒），默认 60。 */
  @Prop countdownDuration: number = 60;
  /** [EN] The title before it starts (the default text is English; pass the app's localized text). [CN] 开始前的标题（默认文本为英文；请传入 App 本地化后的文本）。 */
  @Prop countdownIdleTitle: string = 'Get code';
  /** [EN] The title while counting: a format with one `%d` (or `%ld`), the seconds left. [CN] 倒计时中的标题：带一个 `%d`（或 `%ld`，剩余秒数）的格式。 */
  @Prop countdownRunningTitleFormat: string = '%d s left';
  /** [EN] The title once the time is up. [CN] 时间到之后的标题。 */
  @Prop countdownFinishedTitle: string = 'Resend';
  /** [EN] The icon while counting (e.g. a clock); '' keeps `image`. [CN] 倒计时中的图标（例如时钟）；'' 时保持 `image`。 */
  @Prop countdownImage: ResourceStr = '';
  /** [EN] The title color while counting. [CN] 倒计时中的标题颜色。 */
  @Prop countdownRunningTitleColor: ResourceColor = '#999999';
  /** [EN] The border color while it is not counting. [CN] 非倒计时状态下的边框颜色。 */
  @Prop countdownBorderColor: ResourceColor = '#07C160';
  /** [EN] Whether a tap starts the countdown after `onItemTap` (off by default). [CN] 点击是否在 `onItemTap` 之后开始倒计时（默认关闭）。 */
  @Prop startsCountdownOnTap: boolean = false;
  /**
   * [EN] A key that keeps the running countdown in the app's preferences, so a new item with the same key takes it up again
   *      after the app was ended in the background; '' keeps nothing. One key per thing counted, e.g. one per phone number.
   * [CN] 把运行中的倒计时保存到 App preferences 的 key，使 App 在后台被结束后，相同 key 的新条目接续倒计时；'' 表示不保存。
   *      每个被计时的对象一个 key，例如每个手机号一个。
   */
  @Prop @Watch('cylCountdownKeyDidChange') countdownCacheKey: string = '';
  /** [EN] The clock in epoch millis, for tests; undefined is `Date.now()`. [CN] 以 epoch 毫秒计的时钟，供测试使用；undefined 为 `Date.now()`。 */
  countdownClock?: () => number;
  onCountdownStart?: () => void;
  onCountdownTick?: (remainingSeconds: number) => void;
  onCountdownFinish?: () => void;
  @State private cylCountdownState: number = 0;
  @State private cylCountdownSeconds: number = 0;
  private cylCountdown?: CYLAnimatedItemCountdown;
  private cylCountdownTimer: number = -1;
  private cylForegroundCallback: ApplicationStateChangeCallback = {
    onApplicationForeground: () => {
      this.cylCountdown?.refresh();
    },
    onApplicationBackground: () => {
    }
  };
  @Prop itemAccessibilityText: string = '';
  @Prop itemDescription: string = '';
  @Prop selectedDescription: string = '';
  @Prop itemId: string = '';
  /**
   * [EN] Embedded in a host that is the touch target and the accessibility element (the tab bar's icon): no padding, no
   *      minimum height, no gestures and hidden from screen readers. [CN] 嵌入在作为触摸目标与无障碍元素的宿主中（TabBar 的图标）：
   *      无内边距、无最小高度、无手势，并对读屏隐藏。
   */
  @Prop isBare: boolean = false;
  /**
   * [EN] Sized by its content in both directions (B29), as in a stack (`CYLAnimatedItemStackView`); otherwise (default)
   *      the item fills its parent, as a `Flex` without a size does, which suits a tag in a fixed-size cell.
   * [CN] 两个方向都按内容决定尺寸（B29），用于堆叠（`CYLAnimatedItemStackView`）；否则（默认）条目与未设置尺寸的 `Flex` 一样填满父组件，适合固定尺寸单元格中的标签。
   */
  @Prop sizesToContent: boolean = false;
  @State animationLoaded: boolean = false;
  @State animationFailed: boolean = false;
  /**
   * [EN] The engine view of the animation. Default: the view an engine registered for the file's type
   *      (`CYLAnimatedItemEngineViews`: GIF and SVGA in this module, Lottie, PAG and Rive in cylanimateditem_lottie,
   *      cylanimateditem_pag and cylanimateditem_rive), which plays by the item's selection and playback. An app or library
   *      with its own engine views passes them here instead.
   * [CN] 动画的引擎视图。默认：引擎为文件类型注册的视图（`CYLAnimatedItemEngineViews`：本模块的 GIF 与 SVGA，cylanimateditem_lottie、
   *      cylanimateditem_pag、cylanimateditem_rive 中的 Lottie、PAG 与 Rive），按条目的选中状态与播放设置播放。有自己引擎视图的 App 或库
   *      在这里传入。
   */
  @BuilderParam animationBuilder: (context: CYLAnimatedItemAnimationContext) => void = this.cylEngineAnimation;
  /**
   * [EN] true (default): the default engine view plays its animation by the item's selection and playback. false: the host
   *      drives the player it gets in `onAnimationPlayer` (play, stop at a progress, speed, loop), as
   *      CollectionViewClassifyMenu's tags do.
   * [CN] true（默认）：默认引擎视图按条目的选中状态与播放设置播放动画。false：宿主驱动它在 `onAnimationPlayer` 中得到的播放器（播放、停在某进度、
   *      速度、循环），如 CollectionViewClassifyMenu 的标签。
   */
  @Prop @Watch('cylPlaybackDidChange') drivesAnimationPlayback: boolean = true;
  /**
   * [EN] The default engine view's player once it plays the file, undefined when it goes away.
   * [CN] 默认引擎视图播放文件时的播放器，视图消失时为 undefined。
   */
  onAnimationPlayer?: (player: CYLAnimatedItemPlayer | undefined) => void;
  /** [EN] What the default engine view reads, updated in place. [CN] 默认引擎视图读取的内容，原地更新。 */
  @State private cylEngineState: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  onItemTap?: () => void;
  onItemLongPress?: () => void;
  onAccessoryTap?: () => void;
  onItemDragStart?: () => void;
  onItemDragMove?: (dx: number, dy: number) => void;
  onItemDragEnd?: (dx: number, dy: number) => void;
  @State private animationContext: CYLAnimatedItemAnimationContext = new CYLAnimatedItemAnimationContext();

  private cylLifecycle: LifecycleController<CYLAnimatedItemView> | undefined = undefined;
  private cylScrollPaused: boolean = false;
  private cylStopScrollObserver: (() => void) | undefined = undefined;


  aboutToAppear(): void {
    this.cylLifecycle = new LifecycleController<CYLAnimatedItemView>(this);
    this.cylLifecycle.registry.addDeallocCallback<CYLAnimatedItemView>((owner: CYLAnimatedItemView) => owner.cylTeardown(), { key: 'cyl.animatedItem.teardown' });
    this.cylLifecycle.aboutToAppear();
    if (cylPausesWhileUserScrolls()) {
      this.cylStopScrollObserver = LifecycleCenter.whileUserScrolls(() => this.cylPauseAnimation(), () => this.cylResumeAnimation(),
        { key: `cyl.animatedItem.scroll.${cylNextScrollObserverNumber()}` });
    }
    CYLAnimatedItemEngines.loadX86_64DebugEngines(this.getUIContext().getHostContext());
    this.cylLastRestartToken = this.animationRestartToken + this.cylControllerRestarts;
    this.cylLastSelected = this.isItemSelected;
    if (this.controller) {
      this.controller.cylRestart = () => {
        this.cylControllerRestarts += 1;
        this.cylPlaybackDidChange();
      };
    }
    this.cylSetUpCountdown();
    this.cylAnimationDidChange();
  }

  aboutToDisappear(): void {
    this.cylLifecycle?.aboutToDisappear();
  }

  // [EN] The teardown block (CYLDeallocBlockExecutor), run by `aboutToDisappear`. [CN] 销毁块（CYLDeallocBlockExecutor），由 `aboutToDisappear` 运行。
  private cylTeardown(): void {
    this.cylPostAnimationEvent('cyl.animation.didStop');
    this.cylStopScrollObserver?.();
    this.cylStopCountdownTimer();
    try {
      this.getUIContext().getHostContext()?.getApplicationContext().off('applicationStateChange', this.cylForegroundCallback);
    } catch (error) {
      // [EN] No application context (a preview): nothing to remove. [CN] 没有 application context（预览）：没有可移除的内容。
    }
  }

  /**
   * [EN] Makes the countdown with the local clock and the app's preferences, and takes up a cached one. The app coming to
   *      the foreground reads the clock at once, so the seconds in the background count.
   * [CN] 以本地时钟与 App 的 preferences 创建倒计时，并接续缓存的倒计时。App 回到前台时立即读取时钟，因此后台的秒数计入。
   */
  private cylSetUpCountdown(): void {
    let listener: CYLAnimatedItemCountdownListener = {
      onChanged: () => {
        this.cylSyncCountdown();
      },
      onStarted: () => {
        this.onCountdownStart?.();
      },
      onTicked: (remainingSeconds: number) => {
        this.onCountdownTick?.(remainingSeconds);
      },
      onFinished: () => {
        this.onCountdownFinish?.();
      }
    };
    let context: Context | undefined = this.getUIContext().getHostContext();
    this.cylCountdown = new CYLAnimatedItemCountdown(
      () => this.countdownClock ? this.countdownClock() : Date.now(),
      context ? new CYLAnimatedItemPreferencesStorage(context) : undefined,
      listener);
    try {
      context?.getApplicationContext().on('applicationStateChange', this.cylForegroundCallback);
    } catch (error) {
      // [EN] No application context (a preview): the timer still reads the clock. [CN] 没有 application context（预览）：定时器仍会读取时钟。
    }
    if (this.controller) {
      this.controller.cylStartCountdown = (seconds: number) => {
        this.cylCountdown?.start(seconds > 0 ? seconds : this.countdownDuration);
      };
      this.controller.cylResetCountdown = () => {
        this.cylCountdown?.reset();
      };
      this.controller.cylRefreshCountdown = () => {
        this.cylCountdown?.refresh();
      };
    }
    this.cylCountdownKeyDidChange();
  }

  /** [EN] The cache key or the style changed: a countdown kept under the key is taken up. [CN] 缓存 key 或样式变化：接续保存在该 key 下的倒计时。 */
  cylCountdownKeyDidChange(): void {
    if (this.cylCountdown && this.itemStyle === CYLAnimatedItemStyle.Countdown) {
      this.cylCountdown.setCacheKey(this.countdownCacheKey);
    }
  }

  /** [EN] The state or the seconds changed: render, and run the timer only while counting. [CN] 状态或秒数变化：重新渲染，只在倒计时中运行定时器。 */
  private cylSyncCountdown(): void {
    if (!this.cylCountdown) {
      return;
    }
    this.cylCountdownState = this.cylCountdown.state;
    this.cylCountdownSeconds = this.cylCountdown.shownSeconds;
    if (this.cylCountdown.state === CYLCountdownRunning) {
      if (this.cylCountdownTimer < 0) {
        this.cylCountdownTimer = setInterval(() => {
          this.cylCountdown?.refresh();
        }, CYLCountdownTickIntervalMillis);
      }
    } else {
      this.cylStopCountdownTimer();
    }
  }

  private cylStopCountdownTimer(): void {
    if (this.cylCountdownTimer >= 0) {
      clearInterval(this.cylCountdownTimer);
      this.cylCountdownTimer = -1;
    }
  }

  cylIsCountdown(): boolean {
    return this.itemStyle === CYLAnimatedItemStyle.Countdown;
  }

  cylIsRunning(): boolean {
    return this.cylIsCountdown() && this.cylCountdownState === CYLCountdownRunning;
  }

  /** [EN] Enabled, and not counting down. [CN] 可用，且不在倒计时中。 */
  cylEnabled(): boolean {
    return this.isItemEnabled && !this.cylIsRunning();
  }

  /** [EN] The title: the item's, or the countdown's for the state. [CN] 标题：条目自己的，或倒计时在当前状态下的标题。 */
  cylTitleText(): string {
    if (!this.cylIsCountdown()) {
      return this.itemTitle;
    }
    if (this.cylCountdownState === CYLCountdownRunning) {
      return cylCountdownText(this.countdownRunningTitleFormat, this.cylCountdownSeconds);
    }
    return this.cylCountdownState === CYLCountdownFinished ? this.countdownFinishedTitle : this.countdownIdleTitle;
  }

  /** [EN] The widest title the countdown shows, so the item keeps its width. [CN] 倒计时会显示的最宽标题，使条目保持宽度。 */
  private cylCountdownMinWidth(): number {
    return this.cylIsCountdown() ?
      cylCountdownTitleWidth(this.countdownIdleTitle, this.countdownRunningTitleFormat, this.countdownFinishedTitle,
        this.countdownDuration, this.titleFontSize) : 0;
  }

  /** [EN] The inset really applied (vp). [CN] 实际应用的间距（vp）。 */
  private cylContentInset(): number {
    return CYLAnimatedItemBackgroundModifier.resolvedContentInset(this.itemBackgroundStyle, this.itemContentHorizontalInset);
  }

  private cylPadding(): Padding | number {
    const inset: number = this.cylContentInset();
    if (this.isBare) {
      return inset > 0 ? { top: 0, bottom: 0, left: inset, right: inset } : 0;
    }
    if (this.cylIsCountdown()) {
      return { top: 8, bottom: 8, left: 12 + inset, right: 12 + inset };
    }
    return inset > 0 ? { top: 4, bottom: 4, left: 4 + inset, right: 4 + inset } : 4;
  }

  /** [EN] A tap: the callback, then the countdown when `startsCountdownOnTap`. [CN] 点击：先回调，再在 `startsCountdownOnTap` 时开始倒计时。 */
  private cylHandleTap(): void {
    if (!this.cylEnabled()) {
      return;
    }
    this.onItemTap?.();
    if (this.cylIsCountdown() && this.startsCountdownOnTap) {
      this.cylCountdown?.start(this.countdownDuration);
    }
  }

  @Builder
  cylNoAnimation(context: CYLAnimatedItemAnimationContext) {
  }

  /** [EN] The default engine view (see `animationBuilder`). [CN] 默认引擎视图（见 `animationBuilder`）。 */
  @Builder
  cylEngineAnimation(context: CYLAnimatedItemAnimationContext) {
    CYLAnimatedItemEngineView({ state: this.cylEngineState })
  }

  /**
   * [EN] A new file starts over: not loaded, not failed; a type nobody registered says so in debug builds.
   * [CN] 新文件重新开始：未加载、未失败；没有注册的类型在 debug 构建中给出提示。
   */
  cylAnimationDidChange(): void {
    this.animationLoaded = false;
    this.animationFailed = false;
    this.cylShowsImageAfterEnd = false;
    this.cylUpdateContext();
    if (this.animationUrl.length > 0 && !CYLAnimatedItemEngines.canPlay(this.animationUrl)) {
      CYLAnimatedItemEngines.warnMissingEngine(this.animationUrl);
      // [EN] A known type without its engine (or its library for this device); a file of no known type cannot be decoded.
      // [CN] 已知类型缺少引擎（或其库没有为本设备构建）；不属于任何已知类型的文件无法解码。
      this.cylReportResourceMissing(this.animationUrl,
        cylAnimatedItemTypeOf(this.animationUrl).length > 0 ? CYL_RESOURCE_ENGINE_LIBRARY_MISSING : CYL_RESOURCE_DECODE_FAILED);
    }
  }

  /**
   * [EN] Tells `onResourceMissing` and `CYLAnimatedItemEngines.resourceMissingListener` that the file of `url` cannot be
   *      shown, once per resource. [CN] 通知 `onResourceMissing` 与 `CYLAnimatedItemEngines.resourceMissingListener`：`url` 的文件无法显示，每个资源一次。
   */
  cylReportResourceMissing(url: string, reason: string): void {
    this.cylMissingReporter.report(cylAnimatedItemResourceOf(url), reason, this.onResourceMissing,
      CYLAnimatedItemEngines.resourceMissingListener);
  }

  /**
   * [EN] The selection, speed, loops or a restart changed: the engine gets them in a new context, without reloading the
   *      file. [CN] 选中、速度、循环或重播发生变化：引擎通过新的 context 获得它们，不重新加载文件。
   */
  cylPlaybackDidChange(): void {
    this.cylUpdateContext();
    const token = this.animationRestartToken + this.cylControllerRestarts;
    // [EN] A new pass (a restart, a new selection) or looping shows the animation again. [CN] 新的一遍播放（重播、重新选中）或开启循环时重新显示动画。
    if (token !== this.cylLastRestartToken || this.isItemSelected !== this.cylLastSelected || this.animationLoops) {
      this.cylShowsImageAfterEnd = false;
    }
    this.cylLastSelected = this.isItemSelected;
    if (token !== this.cylLastRestartToken) {
      this.cylLastRestartToken = token;
      this.cylPostAnimationEvent('cyl.animation.didStart');
      this.cylRestartHandler?.();
    }
  }

  /**
   * [EN] Posts an animation event (AnimationEvents of the core library) to the observers of this item.
   * [CN] 向本控件的观察者发出动画事件（核心库的 AnimationEvents）。
   */
  cylPostAnimationEvent(name: string): void {
    // [EN] ArkTS: a typed record, not an object literal. [CN] ArkTS：使用带类型的 Record，而不是对象字面量。
    const info: Record<string, Object> = {};
    info['url'] = this.animationUrl;
    info['selected'] = this.isItemSelected;
    this.cylLifecycle?.registry.postLifecycleEvent(name, info);
  }

  /** [EN] Scrolling pauses the engine: posts didPause. [CN] 滚动暂停动画：发出 didPause。 */
  cylPauseAnimation(): void {
    if (this.cylScrollPaused) {
      return;
    }
    this.cylScrollPaused = true;
    this.cylUpdateContext();
    this.cylPostAnimationEvent('cyl.animation.didPause');
  }

  /** [EN] Scrolling ended: posts didResume. [CN] 滚动结束：发出 didResume。 */
  cylResumeAnimation(): void {
    if (!this.cylScrollPaused) {
      return;
    }
    this.cylScrollPaused = false;
    this.cylUpdateContext();
    this.cylPostAnimationEvent('cyl.animation.didResume');
  }

  private cylUpdateContext(): void {
    let context: CYLAnimatedItemAnimationContext = new CYLAnimatedItemAnimationContext();
    context.url = this.animationUrl;
    context.size = this.iconSize;
    context.selected = this.isItemSelected;
    // [EN] Speed 0 while paused by scrolling: every engine already applies the context's speed. [CN] 滚动暂停时速度为 0：各引擎本来就应用 context 的速度。
    context.speed = this.cylScrollPaused ? 0 : this.animationSpeed;
    context.loops = this.animationLoops;
    context.restartToken = this.animationRestartToken + this.cylControllerRestarts;
    context.setRestartHandler = this.cylSetRestartHandler;
    let url: string = this.animationUrl;
    context.onLoaded = () => {
      if (url === this.animationUrl) {
        this.animationLoaded = true;
      }
    };
    context.onFailed = (reason?: string) => {
      if (url === this.animationUrl) {
        this.animationFailed = true;
        this.cylReportResourceMissing(url, reason ?? CYL_RESOURCE_DECODE_FAILED);
      }
    };
    context.onEnded = () => {
      if (url !== this.animationUrl || this.animationLoops) {
        return;
      }
      if (this.showsImageWhenAnimationEnds) {
        this.cylShowsImageAfterEnd = true;
      }
      this.onAnimationEnd?.();
    };
    this.animationContext = context;
    this.cylUpdateEngineState(context);
  }

  /**
   * [EN] The color the animation is drawn in, '' for the file's own colors: `animationTintColor` when set; else `animationTint` /
   *      `animationDarkTint` over the source's `tint` / `darkTint` options (`cylAnimatedItemResolveTint`, with `iconColor`, the selection and
   *      the color mode). [CN] 动画的绘制颜色，'' 表示文件自身的颜色：设置了 `animationTintColor` 时用它；否则按 `animationTint` /
   *      `animationDarkTint` 覆盖来源的 `tint` / `darkTint` 选项解析（结合 `iconColor`、选中状态与颜色模式）。
   */
  cylAnimationTint(): ResourceColor {
    if (this.animationTintColor !== '') {
      return this.animationTintColor;
    }
    if (this.animationTint === '' && this.animationDarkTint === '' && this.animationUrl === '') {
      return '';
    }
    if (this.cylTintSource === undefined || this.cylTintSource.url !== this.animationUrl) {
      this.cylTintSource = CYLAnimatedItemSource.parse(this.animationUrl);
    }
    const input = new CYLAnimatedItemTintInput();
    input.propTint = this.animationTint;
    input.propDarkTint = this.animationDarkTint;
    input.optionTint = this.cylTintSource.option('tint') ?? '';
    input.optionDarkTint = this.cylTintSource.option('darkTint') ?? '';
    input.selected = this.isItemSelected;
    input.dark = this.cylColorMode === 'dark';
    input.hasIconColor = this.iconColor !== '';
    const result: CYLAnimatedItemTintResult = cylAnimatedItemResolveTint(input);
    if (result.kind === 'icon') {
      return this.iconColor;
    }
    return result.kind === 'fixed' ? result.color : '';
  }

  /** [EN] A tint input changed: the engine state follows (the layer itself reads the properties). [CN] 着色输入变化：引擎状态随之更新（着色层本身直接读取属性）。 */
  cylTintDidChange(): void {
    this.cylEngineState.tintColor = this.cylAnimationTint();
  }

  /**
   * [EN] The default engine view's state, updated in place so the engine view sees each change; a new file gets a new
   *      source. [CN] 默认引擎视图的 state，原地更新使引擎视图看到每次变化；新文件得到新的 source。
   */
  private cylUpdateEngineState(context: CYLAnimatedItemAnimationContext): void {
    const state = this.cylEngineState;
    if (state.source.url !== this.animationUrl) {
      state.source = CYLAnimatedItemSource.parse(this.animationUrl);
    }
    state.width = this.iconSize;
    state.height = this.iconSize;
    state.speed = context.speed;
    state.loops = context.loops;
    state.drivesPlayback = this.drivesAnimationPlayback;
    state.tintColor = this.cylAnimationTint();
    state.onLoaded = context.onLoaded;
    state.onFailed = context.onFailed;
    state.onEnded = context.onEnded;
    state.onPlayer = (player: CYLAnimatedItemPlayer | undefined) => this.onAnimationPlayer?.(player);
    // [EN] Last, so the engine view reads the playback above when it reacts. [CN] 最后设置，使引擎视图响应时读到上面的播放设置。
    state.selected = context.selected;
    state.restartToken = context.restartToken;
    state.changed();
  }

  /** [EN] Turned off: the animation shows again. [CN] 关闭时重新显示动画。 */
  cylEndImageDidChange(): void {
    if (!this.showsImageWhenAnimationEnds) {
      this.cylShowsImageAfterEnd = false;
    }
  }

  /** [EN] The animation is drawn and not replaced by the still image. [CN] 动画已绘制且未被静态图片替换。 */
  cylAnimationShows(): boolean {
    return this.cylMakesAnimation() && this.animationLoaded && !this.cylShowsImageAfterEnd;
  }

  /**
   * [EN] Whether an engine plays the file now (made and not failed). [CN] 是否有引擎正在播放该文件（已创建且未失败）。
   */
  cylMakesAnimation(): boolean {
    return this.animationUrl.length > 0 && !this.animationFailed && CYLAnimatedItemEngines.canPlay(this.animationUrl);
  }

  /**
   * [EN] The static image of the state, or '' when there is none. [CN] 当前状态的静态图片，没有时为 ''。
   */
  cylStaticImage(): ResourceStr {
    if (this.cylIsRunning() && !this.cylIsEmpty(this.countdownImage)) {
      return this.countdownImage;
    }
    if (this.isItemSelected && !this.cylIsEmpty(this.selectedImage)) {
      return this.selectedImage;
    }
    return this.image;
  }

  cylIsEmpty(image: ResourceStr): boolean {
    return typeof image === 'string' && (image as string).length === 0;
  }

  /**
   * [EN] What the icon shows under the animation: the static image, else the placeholder when there is an animation file
   *      that does not show (yet), else nothing.
   * [CN] 图标在动画下方显示的内容：静态图片；没有时，若有尚未显示的动画文件则显示占位图；否则不显示。
   */
  cylFallbackImage(): ResourceStr {
    let image: ResourceStr = this.cylStaticImage();
    if (!this.cylIsEmpty(image)) {
      return image;
    }
    let animationShows: boolean = this.cylAnimationShows();
    return (this.animationUrl.length > 0 && !animationShows) ? this.placeholderImage : '';
  }

  cylShowsIcon(): boolean {
    return !this.cylIsEmpty(this.cylFallbackImage()) || this.cylMakesAnimation();
  }

  cylAccessibilityText(): string {
    return this.itemAccessibilityText.length > 0 ? this.itemAccessibilityText : this.cylTitleText();
  }

  @Builder
  cylIcon() {
    Stack() {
      if (cylIsSymbolResource(this.cylFallbackImage())) {
        // [EN] A system symbol (`$r('sys.symbol.xmark')`): an Image draws nothing for it (B30), so it is a SymbolGlyph in
        //      `iconColor` (the theme's primary color without one). [CN] 系统符号（`$r('sys.symbol.xmark')`）：Image 不绘制它（B30），
        //      因此用 SymbolGlyph 按 `iconColor` 绘制（没有时为主题主色）。
        SymbolGlyph(this.cylFallbackImage() as Resource)
          .fontSize(this.iconSize)
          .fontColor([this.iconColor === '' ? $r('sys.color.font_primary') : this.iconColor])
          .width(this.iconSize)
          .height(this.iconSize)
          .opacity(this.cylAnimationShows() ? 0 : 1)
          .accessibilityLevel('no')
      } else if (!this.cylIsEmpty(this.cylFallbackImage())) {
        Image(this.cylFallbackImage())
          .width(this.iconSize)
          .height(this.iconSize)
          .fillColor(this.iconColor === '' ? undefined : this.iconColor)
          .colorFilter(new ColorFilter(cylIconColorFilter(this.iconColor)))
          .objectFit(ImageFit.Contain)
          .opacity(this.cylAnimationShows() ? 0 : 1)
          .accessibilityLevel('no')
      }
      if (this.cylMakesAnimation()) {
        Stack() {
        Column() {
          // [EN] One object literal whose fields read state: ArkUI passes it by reference, so the engine view gets new
          //      values (selection, speed, loops, restarts) as they change; a context object alone is rendered once.
          // [CN] 字段读取状态的单个对象字面量：ArkUI 按引用传递，引擎视图随变化获得新值（选中、速度、循环、重播）；单独的 context 对象只渲染一次。
          this.animationBuilder({
            url: this.animationUrl,
            size: this.iconSize,
            selected: this.isItemSelected,
            speed: this.animationSpeed,
            loops: this.animationLoops,
            restartToken: this.animationRestartToken + this.cylControllerRestarts,
            onLoaded: this.animationContext.onLoaded,
            onFailed: this.animationContext.onFailed,
            onEnded: this.animationContext.onEnded,
            setRestartHandler: this.cylSetRestartHandler
          })
        }
        .width(this.iconSize)
        .height(this.iconSize)
          if (this.cylAnimationTint() !== '') {
            // [EN] The tint: kept only where the animation draws, with the animation's alpha (source in).
            // [CN] 着色：只保留动画绘制的区域，并乘以动画的透明度（source in）。
            Column()
              .width(this.iconSize)
              .height(this.iconSize)
              .backgroundColor(this.cylAnimationTint())
              .blendMode(BlendMode.SRC_IN)
              .hitTestBehavior(HitTestMode.Transparent)
              .id('cyl-animated-item-tint')
          }
        }
        .width(this.iconSize)
        .height(this.iconSize)
        // [EN] An offscreen group, so the tint only meets the animation, never what is behind the item.
        // [CN] 离屏组，使着色只与动画合成，不影响条目背后的内容。
        .blendMode(this.cylAnimationTint() !== '' ? BlendMode.SRC_OVER : BlendMode.NONE, BlendApplyType.OFFSCREEN)
        .opacity(this.animationLoaded && !this.cylShowsImageAfterEnd ? 1 : 0)
        .accessibilityLevel('no')
      }
      if (this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.TopTrailing) {
        this.cylAccessory()
      }
    }
    .alignContent(Alignment.TopEnd)
  }

  @Builder
  cylAccessory() {
    if (!this.cylIsEmpty(this.accessoryImage) || this.accessoryText.length > 0) {
      Row() {
        if (!this.cylIsEmpty(this.accessoryImage)) {
          Image(this.accessoryImage).width(18).height(18).objectFit(ImageFit.Contain)
        } else {
          Text(this.accessoryText).fontSize(this.titleFontSize).fontColor(this.titleColor)
        }
      }
      .constraintSize({ minWidth: 44, minHeight: 44 })
      .justifyContent(FlexAlign.Center)
      // [EN] An inline accessory keeps `spacing` from the icon and title, as on Android (B21). [CN] 行内附件与图标、标题保持 `spacing`，与 Android 相同（B21）。
      .margin(!this.cylShowsIconOrTitle() ? 0 :
        this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Leading ?
          (this.axis === CYLAnimatedItemAxis.Vertical ? { bottom: this.spacing } : { right: this.spacing }) :
          this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Trailing ? this.cylLeadingGap(this.spacing) : 0)
      .accessibilityGroup(true)
      .accessibilityText(this.accessoryAccessibilityText.length > 0 ? this.accessoryAccessibilityText : this.accessoryText)
      .id(this.itemId.length > 0 ? `${this.itemId}-accessory` : '')
      .onClick(() => {
        if (this.isItemEnabled && this.onAccessoryTap) {
          this.onAccessoryTap();
        }
      })
    }
  }

  @Builder
  cylTitle() {
    if (this.cylTitleText().length > 0) {
      Text(this.cylTitleText())
        .fontSize(this.titleFontSize)
        .fontColor(this.cylIsRunning() ? this.countdownRunningTitleColor : this.titleColor)
        .constraintSize({ minWidth: this.cylCountdownMinWidth() })
        .maxLines(this.titleLines > 0 ? Math.floor(this.titleLines) : CYL_UNLIMITED_LINES)
        .textOverflow({ overflow: this.titleLines > 0 ? TextOverflow.Ellipsis : TextOverflow.None })
        .textAlign(this.axis === CYLAnimatedItemAxis.Vertical || this.cylIsCountdown() ? TextAlign.Center : TextAlign.Start)
        .margin(this.cylShowsIcon() ? this.cylLeadingGap(this.spacing) : 0)
        .accessibilityLevel('no')
    }
  }

  /** [EN] A gap before a part: above it on the vertical axis, before it on the horizontal one. [CN] 某部分之前的间距：纵向在其上方，横向在其前方。 */
  private cylLeadingGap(gap: number): Margin {
    return this.axis === CYLAnimatedItemAxis.Vertical ? { top: gap } : { left: gap };
  }

  /** [EN] Whether the icon or the title shows (an inline accessory keeps `spacing` from them). [CN] 是否显示图标或标题（行内附件与它们保持 `spacing`）。 */
  private cylShowsIconOrTitle(): boolean {
    return this.cylShowsIcon() || this.cylTitleText().length > 0;
  }

  @Builder
  cylContent() {
    if (this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Leading) {
      this.cylAccessory()
    }
    if (this.cylShowsIcon()) {
      this.cylIcon()
    }
    this.cylTitle()
    if (this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Trailing) {
      this.cylAccessory()
    }
  }

  /** [EN] Bare and only an icon: no title, no accessory. [CN] 纯图标模式且只有图标：没有标题和附件。 */
  private cylIsBareIcon(): boolean {
    return this.isBare && this.cylTitleText().length === 0 && this.cylIsEmpty(this.accessoryImage) && this.accessoryText.length === 0;
  }

  /**
   * [EN] Whether any `item…` background property is set. [CN] 是否设置了任一 `item…` 背景属性。
   */
  private cylUsesItemBackground(): boolean {
    return this.itemBackgroundStyle !== CYLAnimatedItemBackgroundStyle.flat || this.itemBackgroundColor !== '' ||
      this.itemCornerRadius >= 0 || this.itemBorderWidth > 0 || this.itemBorderColor !== '';
  }

  /**
   * [EN] Whether the Liquid Glass is drawn: the style asks for it and `CYLLiquidGlass.isActive()`. [CN] 是否绘制液态玻璃：样式要求且 `CYLLiquidGlass.isActive()`。
   */
  private cylItemGlassDrawn(): boolean {
    return CYLAnimatedItemBackgroundModifier.isGlassDrawn(this.itemBackgroundStyle);
  }

  /**
   * [EN] The corner radius: the host's value, else a capsule for the drawn Liquid Glass (the rule `0: automatic, a capsule` that
   *      CollectionViewClassifyMenu's tags had, moved here) and square for flat. [CN] 圆角：宿主设置的值，否则绘制液态玻璃时为胶囊
   *      （CollectionViewClassifyMenu 的标签曾有的「0 为自动，即胶囊」规则，移到这里），扁平时为直角。
   */
  private cylItemCornerRadius(): number {
    return CYLAnimatedItemBackgroundModifier.resolvedCornerRadius(this.itemBackgroundStyle, this.itemCornerRadius);
  }

  /**
   * [EN] The background color: the tint over the glass blur, else the solid fill, '' meaning transparent. [CN] 背景色：玻璃模糊之上的着色，否则为纯色填充；'' 表示透明。
   */
  private cylItemBackgroundColor(): ResourceColor {
    // [EN] The glass tint is translucent (and a default frosted tint when none is set): the shared rule of the modifier. [CN] 玻璃着色是半透明的（未设置时为默认磨砂着色）：与修饰器共用同一规则。
    if (this.cylItemGlassDrawn()) {
      return CYLAnimatedItemBackgroundModifier.glassTint(this.itemBackgroundColor !== '' ? this.itemBackgroundColor : Color.Transparent, this.itemGlassTintAlpha);
    }
    return this.itemBackgroundColor !== '' ? this.itemBackgroundColor : Color.Transparent;
  }

  build() {
    Flex({
      direction: this.axis === CYLAnimatedItemAxis.Vertical ? FlexDirection.Column : FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      this.cylContent()
    }
    .padding(this.cylPadding())
    .backgroundEffect(this.cylItemGlassDrawn() ?
      { radius: CYLLiquidGlass.BLUR_RADIUS, saturation: CYLLiquidGlass.BLUR_SATURATION, brightness: CYLLiquidGlass.LIGHT_BRIGHTNESS } :
      { radius: 0 })
    .backgroundColor(this.cylIsCountdown() ? '#F2F2F7' : this.cylItemBackgroundColor())
    .borderRadius(this.cylIsCountdown() ? 6 : this.cylItemCornerRadius())
    .borderWidth(this.cylIsCountdown() ? 0.5 : this.itemBorderWidth)
    .borderColor(this.cylIsRunning() ? '#C7C7CC' : (this.cylUsesItemBackground() && this.itemBorderColor !== '' ?
      this.itemBorderColor : this.countdownBorderColor))
    .clip(this.cylItemGlassDrawn())
    // [EN] A Flex without a size fills its parent. A bare icon (a host's tab icon, no title, no accessory) is exactly the
    //      icon, so a host can place things against its edges: the tab bar puts the badge at the icon's top-right, and an
    //      item as wide as the tab slot moved it to the icon's top-left (HarmonyOS issue list #51). `undefined` keeps the
    //      default size everywhere else.
    // [CN] 未设置尺寸的 Flex 会填满父组件。纯图标（宿主的 Tab 图标，无标题、无附件）的尺寸就是图标尺寸，宿主才能依据其边缘布局：TabBar 把角标放在
    //      图标右上角，而与 Tab 槽位同宽的条目把角标挪到了图标左上角（鸿蒙问题列表 #51）。其他情况为 `undefined`，保持默认尺寸。
    .width(this.cylIsBareIcon() ? this.iconSize : (this.sizesToContent ? 'auto' : undefined))
    .height(this.cylIsBareIcon() ? this.iconSize : (this.sizesToContent ? 'auto' : undefined))
    .opacity(this.cylEnabled() ? 1 : 0.5)
    .constraintSize({ minHeight: this.isBare ? 0 : 44 })
    .hitTestBehavior(this.isBare ? HitTestMode.None : HitTestMode.Default)
    .accessibilityLevel(this.isBare ? 'no-hide-descendants' : 'auto')
    .accessibilityGroup(true)
    .accessibilityText(this.cylAccessibilityText())
    .accessibilityDescription(this.isItemSelected && this.selectedDescription.length > 0 ?
      [this.itemDescription, this.selectedDescription].filter((part: string) => part.length > 0).join(', ') : this.itemDescription)
    .id(this.itemId)
    .onVisibleAreaChange([0.0, 0.01], (isVisible: boolean) => {
      this.cylLifecycle?.visibleAreaChanged(isVisible);
    })
    .onAttach(() => {
      this.cylLifecycle?.windowAttached();
    })
    .onDetach(() => {
      this.cylLifecycle?.windowDetached();
    })
    .onClick(() => {
      this.cylHandleTap();
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.cylEnabled() && this.onItemLongPress) {
            this.onItemLongPress();
          }
        })
    )
    .parallelGesture(
      PanGesture()
        .onActionStart(() => {
          if (this.isDragEnabled && this.onItemDragStart) {
            this.onItemDragStart();
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.isDragEnabled && this.onItemDragMove) {
            this.onItemDragMove(event.offsetX, event.offsetY);
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.isDragEnabled && this.onItemDragEnd) {
            this.onItemDragEnd(event.offsetX, event.offsetY);
          }
        })
    )
  }
}
