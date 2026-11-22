import { CYLAnimatedItemEngineState, CYLAnimatedItemSource } from 'cylanimateditem';
import { CYLAnimatedItemLottieView } from 'cylanimateditem_lottie';

/**
 * [EN] A Lottie tab icon (CYLTabBarLottieFilePath, ported from CYLTabBarItemAnimation.kt): a thin wrapper over the Lottie
 *      engine view of `cylanimateditem_lottie` (`CYLAnimatedItemLottieView`), which plays it: once from the start each time
 *      its tab becomes selected (and on a re-tap, `replayToken`), resting on the first frame while unselected, with a live
 *      `speed` and an optional loop. `path` is a rawfile path of the app (e.g. "lottie/green_lottie_tab_home.json");
 *      `speed` is CYLTabBarControllerTabBarItemAnimationSpeed. No Lottie logic lives here any more.
 * [CN] Lottie Tab 图标（CYLTabBarLottieFilePath，从 CYLTabBarItemAnimation.kt 迁移）：`cylanimateditem_lottie` 的 Lottie 引擎视图
 *      （`CYLAnimatedItemLottieView`）的薄封装，由它播放：每次 Tab 变为选中（以及再次点击，`replayToken`）时从头播放一次，未选中时停在
 *      第一帧，`speed` 立即生效，可选循环。`path` 为应用的 rawfile 路径；`speed` 即 CYLTabBarControllerTabBarItemAnimationSpeed。
 *      这里不再有任何 Lottie 逻辑。
 */
@Component
export struct CYLLottieIcon {
  @Prop @Watch('cylReload') path: string = '';
  iconSize: number = 26;
  /** [EN] Playback speed, applied live (B22). [CN] 播放速度，立即生效（B22）。 */
  @Prop @Watch('cylUpdate') speed: number = 1;
  @Prop @Watch('cylUpdate') selected: boolean = false;
  @Prop @Watch('cylReplay') replayToken: number = 0;
  /**
   * [EN] Plays again from the start after each pass while the tab is selected (tabBarItemAnimationLoops); off by default.
   * [CN] Tab 选中期间每次播放结束后从头再次播放（tabBarItemAnimationLoops）；默认关闭。
   */
  @Prop @Watch('cylUpdate') loops: boolean = false;
  /**
   * [EN] Hands the host this view's replay, called on each restart (CYLAnimatedItemView `setRestartHandler`, B23).
   * [CN] 把本视图的重播交给宿主，每次重播时调用（CYLAnimatedItemView `setRestartHandler`，B23）。
   */
  registerReplay: (replay: () => void) => void = (_replay: () => void) => {};
  /** [EN] The file is drawn (CYLAnimatedItemView shows it from here on). [CN] 文件已绘制（CYLAnimatedItemView 从此显示它）。 */
  onLoaded: () => void = () => {};
  /**
   * [EN] A play-once pass reached its last frame (lottie's "complete"; CYLAnimatedItemAnimationContext `onEnded`).
   * [CN] 只播放一次的一遍播放到最后一帧（lottie 的 "complete"；CYLAnimatedItemAnimationContext 的 `onEnded`）。
   */
  onEnded: () => void = () => {};
  /** [EN] The file cannot be loaded. [CN] 文件无法加载。 */
  onLoadError: (message: string) => void = (_message: string) => {};
  private state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();

  aboutToAppear(): void {
    const state = this.state;
    state.source = CYLAnimatedItemSource.parse(this.path);
    state.width = this.iconSize;
    state.height = this.iconSize;
    state.selected = this.selected;
    state.speed = this.speed;
    state.loops = this.loops;
    state.onLoaded = () => this.onLoaded();
    state.onEnded = () => this.onEnded();
    state.onFailed = () => this.onLoadError(`cannot load ${this.path}`);
    this.registerReplay(() => this.cylReplay());
  }

  /** [EN] A new path (e.g. the dark file after a color mode change) reloads the animation. [CN] 新路径（如切换深色模式后）重新加载动画。 */
  cylReload(): void {
    this.state.source = CYLAnimatedItemSource.parse(this.path);
    this.state.changed();
  }

  /** [EN] Selection, speed and loop reach the engine view through the state. [CN] 选中、速度与循环通过 state 传给引擎视图。 */
  cylUpdate(): void {
    this.state.selected = this.selected;
    this.state.speed = this.speed;
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
      CYLAnimatedItemLottieView({ state: this.state })
    }
    .width(this.iconSize)
    .height(this.iconSize)
    // [EN] The icon never takes the tab's taps and is not read on its own. [CN] 图标不拦截 Tab 的点击，也不单独朗读。
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no-hide-descendants')
  }
}
