/**
 * [EN] The engine views of CYLAnimatedItemView: what an engine view gets (`CYLAnimatedItemEngineState`), where engines
 *      register their view (`CYLAnimatedItemEngineViews`), and the view the item shows by default
 *      (`CYLAnimatedItemEngineView`), which picks the registered view of the file's type. The component itself plays GIF
 *      and SVGA; the modules cylanimateditem_lottie, cylanimateditem_pag and cylanimateditem_rive register Lottie, PAG and
 *      Rive (an app adds only the modules of the libraries it uses, as the iOS subspecs). An app or library that passes its
 *      own `animationBuilder` keeps doing so; one that passes none gets these views.
 * [CN] CYLAnimatedItemView 的引擎视图：引擎视图得到的内容（`CYLAnimatedItemEngineState`）、引擎注册视图的位置
 *      （`CYLAnimatedItemEngineViews`），以及条目默认显示的视图（`CYLAnimatedItemEngineView`），它按文件类型选择已注册的视图。组件自身
 *      播放 GIF 与 SVGA；模块 cylanimateditem_lottie、cylanimateditem_pag、cylanimateditem_rive 注册 Lottie、PAG 与 Rive（App 只加入
 *      所用库的模块，与 iOS 子库相同）。传入自己 `animationBuilder` 的 App 或库保持不变；没有传入的使用这些视图。
 */
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';
import { CYLAnimatedItemEngineHost, CYLAnimatedItemPlayback, CYLAnimatedItemPlayer } from './CYLAnimatedItemPlayer';
import { CYLAnimatedItemTypeRegistry } from './CYLAnimatedItemTypes';

/**
 * [EN] What an engine view gets from its item: the file, the icon's size, the playback, and the callbacks. The item owns
 *      it, updates it in place and calls `changed()`; an engine view listens (`listen`) and reacts to each change (a new
 *      file, selection, speed, loop, restart) without being rebuilt. Plain listeners, not ArkUI state: the view is reached
 *      through a wrapped builder, where `@ObjectLink` / `@Watch` did not fire on the emulator (2026-11-22).
 * [CN] 引擎视图从条目得到的内容：文件、图标尺寸、播放设置与回调。条目持有它、原地更新并调用 `changed()`；引擎视图监听（`listen`）并响应每次变化
 *      （新文件、选中、速度、循环、重播），无需重建。使用普通监听而不是 ArkUI 状态：视图经由 wrapBuilder 到达，在模拟器上 `@ObjectLink` / `@Watch`
 *      没有触发（2026-11-22）。
 */
export class CYLAnimatedItemEngineState implements CYLAnimatedItemEngineHost {
  source: CYLAnimatedItemSource = new CYLAnimatedItemSource();
  /** [EN] The icon's width and height in vp. [CN] 图标的宽与高（vp）。 */
  width: number = 24;
  height: number = 24;
  selected: boolean = false;
  speed: number = 1;
  loops: boolean = false;
  /** [EN] Grows on every restart: the engine plays from progress 0. [CN] 每次重播时增长：引擎从进度 0 播放。 */
  restartToken: number = 0;
  /**
   * [EN] true (default): the engine view plays its player by the default rules (selected: once from the start; unselected:
   *      progress 0). false: it only hands its player out (`onPlayer`) and the host drives it.
   * [CN] true（默认）：引擎视图按默认规则播放（选中：从头一次；未选中：进度 0）。false：只交出播放器（`onPlayer`），由宿主驱动。
   */
  drivesPlayback: boolean = true;
  /** [EN] The tint of the animation (''): `CYLAnimatedItemView.animationTintColor`. [CN] 动画的着色（''）。 */
  tintColor: ResourceColor = '';
  onLoaded: () => void = () => {
  };
  onFailed: () => void = () => {
  };
  onEnded: () => void = () => {
  };
  onPlayer: (player: CYLAnimatedItemPlayer | undefined) => void = (_player: CYLAnimatedItemPlayer | undefined) => {
  };

  private listeners: (() => void)[] = [];

  /**
   * [EN] Calls `listener` after each change; returns the function that stops it. [CN] 每次变化后调用 `listener`；返回停止监听的函数。
   */
  listen(listener: () => void): () => void {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index >= 0) {
        this.listeners.splice(index, 1);
      }
    };
  }

  /** [EN] Called by the item after it changed the state. [CN] 条目修改 state 后调用。 */
  changed(): void {
    this.listeners.slice().forEach((listener: () => void) => listener());
  }

  /** [EN] The playback as the driver reads it. [CN] 驱动读取的播放设置。 */
  playback(): CYLAnimatedItemPlayback {
    return { selected: this.selected, speed: this.speed, loops: this.loops, restartToken: this.restartToken };
  }
}

/**
 * [EN] Where each engine registers the view that plays its type (a global `@Builder` taking the state, wrapped). Done by
 *      the engine's `register()` (`CYLAnimatedItemGIF.register()`, `CYLAnimatedItemLottie.register()`, ...), which also
 *      registers the type with `CYLAnimatedItemEngines`.
 * [CN] 每个引擎注册播放其类型的视图（接收 state 的全局 `@Builder`，经 wrapBuilder 包装）的位置。由引擎的 `register()` 完成，它同时向
 *      `CYLAnimatedItemEngines` 注册该类型。
 */
export class CYLAnimatedItemEngineViews {
  private static views: Map<string, WrappedBuilder<[CYLAnimatedItemEngineState]>> =
    new Map<string, WrappedBuilder<[CYLAnimatedItemEngineState]>>();

  /**
   * [EN] Registers `view` for `type` and registers the type (`CYLAnimatedItemEngines.register`).
   * [CN] 为 `type` 注册 `view`，并注册该类型（`CYLAnimatedItemEngines.register`）。
   */
  static register(type: string, view: WrappedBuilder<[CYLAnimatedItemEngineState]>, extensions?: string[],
    packageName?: string, nativeAbis?: string[]): void {
    CYLAnimatedItemEngineViews.views.set(type, view);
    CYLAnimatedItemTypeRegistry.register(type, extensions, packageName, nativeAbis);
  }

  static unregister(type: string): void {
    CYLAnimatedItemEngineViews.views.delete(type);
  }

  /** [EN] The view registered for `type`, or undefined. [CN] 为 `type` 注册的视图，没有时为 undefined。 */
  static viewFor(type: string): WrappedBuilder<[CYLAnimatedItemEngineState]> | undefined {
    return CYLAnimatedItemEngineViews.views.get(type);
  }

  static hasView(type: string): boolean {
    return CYLAnimatedItemEngineViews.views.has(type);
  }
}

/**
 * [EN] Engine views are created one at a time, CYL_CREATE_INTERVAL ms apart: a screen that created many in one frame decoded
 *      every GIF, SVGA, PAG and image on the main thread at once and froze (appfreeze THREAD_BLOCK_6S in
 *      ImageSourceNapi::Constructor; CollectionViewClassifyMenu issue Z5). The item shows its still image meanwhile.
 * [CN] 引擎视图逐个创建，间隔 CYL_CREATE_INTERVAL 毫秒：一帧内创建很多视图的页面会在主线程同时解码所有 GIF、SVGA、PAG 与图片而卡死
 *      （CollectionViewClassifyMenu 问题 Z5）。期间条目显示静态图片。
 */
const CYL_CREATE_INTERVAL: number = 50;
const cylCreateQueue: (() => void)[] = [];
let cylCreateTimer: number = -1;

function cylEnqueueCreate(create: () => void): void {
  cylCreateQueue.push(create);
  if (cylCreateTimer < 0) {
    cylCreateTimer = setInterval(() => {
      const next = cylCreateQueue.shift();
      next?.();
      if (cylCreateQueue.length === 0) {
        clearInterval(cylCreateTimer);
        cylCreateTimer = -1;
      }
    }, CYL_CREATE_INTERVAL);
  }
}

function cylDequeueCreate(create: () => void): void {
  const index = cylCreateQueue.indexOf(create);
  if (index >= 0) {
    cylCreateQueue.splice(index, 1);
  }
}

/**
 * [EN] The engine view the item shows when the app passes no `animationBuilder`: the view registered for the file's type,
 *      created in its turn (see CYL_CREATE_INTERVAL).
 * [CN] App 未传入 `animationBuilder` 时条目显示的引擎视图：为文件类型注册的视图，按顺序创建（见 CYL_CREATE_INTERVAL）。
 */
@Component
export struct CYLAnimatedItemEngineView {
  state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  @State private created: boolean = false;
  /** [EN] The file's type and the size, kept from the state so a new type or size rebuilds. [CN] 文件类型与尺寸，从 state 同步，类型或尺寸变化时重建。 */
  @State private type: string = '';
  @State private viewWidth: number = 0;
  @State private viewHeight: number = 0;
  private unlisten?: () => void;
  private create: () => void = () => {
    this.created = true;
  };

  aboutToAppear(): void {
    this.cylSync();
    this.unlisten = this.state.listen(() => this.cylSync());
    cylEnqueueCreate(this.create);
  }

  aboutToDisappear(): void {
    cylDequeueCreate(this.create);
    this.unlisten?.();
  }

  private cylSync(): void {
    this.type = this.state.source.type;
    this.viewWidth = this.state.width;
    this.viewHeight = this.state.height;
  }

  hasView(): boolean {
    return CYLAnimatedItemEngineViews.hasView(this.type);
  }

  view(): WrappedBuilder<[CYLAnimatedItemEngineState]> {
    return CYLAnimatedItemEngineViews.viewFor(this.type) ?? wrapBuilder(cylNoEngineView);
  }

  build() {
    Stack() {
      if (this.created && this.hasView()) {
        this.view().builder(this.state)
      }
    }
    .width(this.viewWidth)
    .height(this.viewHeight)
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no')
  }
}

@Builder
function cylNoEngineView(_state: CYLAnimatedItemEngineState) {
}
