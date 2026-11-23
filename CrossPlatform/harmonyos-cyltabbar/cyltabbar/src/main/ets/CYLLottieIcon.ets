import lottie, { AnimationItem } from '@ohos/lottie';
import { LifecycleController } from 'cyldeallocblockexecutor';

let cylLottieCount: number = 0;

/**
 * [EN] A Lottie tab icon (CYLTabBarLottieFilePath, ported from CYLTabBarItemAnimation.kt): plays once from the start
 *      each time its tab becomes selected (and on a re-tap, `replayToken`), rests on the first frame while unselected.
 *      `path` is a rawfile path of the app (e.g. "lottie/green_lottie_tab_home.json"); `speed` is
 *      CYLTabBarControllerTabBarItemAnimationSpeed.
 * [CN] Lottie Tab 图标（CYLTabBarLottieFilePath，从 CYLTabBarItemAnimation.kt 迁移）：每次 Tab 变为选中（以及再次点击，`replayToken`）
 *      时从头播放一次；未选中时停在第一帧。`path` 为应用的 rawfile 路径；`speed` 即 CYLTabBarControllerTabBarItemAnimationSpeed。
 */
@Component
export struct CYLLottieIcon {
  @Prop @Watch('cylReload') path: string = '';
  iconSize: number = 26;
  /** [EN] Playback speed, applied live (B22). [CN] 播放速度，立即生效（B22）。 */
  @Prop @Watch('cylSpeedChanged') speed: number = 1;
  @Prop @Watch('cylUpdate') selected: boolean = false;
  @Prop @Watch('cylReplay') replayToken: number = 0;
  /**
   * [EN] Plays again from the start after each pass while the tab is selected (tabBarItemAnimationLoops); off by default.
   * [CN] Tab 选中期间每次播放结束后从头再次播放（tabBarItemAnimationLoops）；默认关闭。
   */
  @Prop @Watch('cylLoopsChanged') loops: boolean = false;
  /** [EN] The file is drawn (CYLAnimatedItemView shows it from here on). [CN] 文件已绘制（CYLAnimatedItemView 从此显示它）。 */
  /**
   * [EN] Hands the host this view's replay, called on each restart (CYLAnimatedItemView `setRestartHandler`, B23).
   * [CN] 把本视图的重播交给宿主，每次重播时调用（CYLAnimatedItemView `setRestartHandler`，B23）。
   */
  registerReplay: (replay: () => void) => void = (_replay: () => void) => {};
  onLoaded: () => void = () => {};
  /**
   * [EN] A play-once pass reached its last frame (lottie's "complete"; CYLAnimatedItemAnimationContext `onEnded`).
   * [CN] 只播放一次的一遍播放到最后一帧（lottie 的 "complete"；CYLAnimatedItemAnimationContext 的 `onEnded`）。
   */
  onEnded: () => void = () => {};
  /** [EN] The file cannot be loaded. [CN] 文件无法加载。 */
  onLoadError: (message: string) => void = (_message: string) => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private lottieItem?: AnimationItem;
  private name: string = '';
  private cylLifecycle: LifecycleController<CYLLottieIcon> | undefined = undefined;

  aboutToAppear(): void {
    this.cylLifecycle = new LifecycleController<CYLLottieIcon>(this);
    this.cylLifecycle.registry.addDeallocCallback<CYLLottieIcon>((owner: CYLLottieIcon) => owner.cylTeardown(), { key: 'cyl.lottie.teardown' });
    this.cylLifecycle.aboutToAppear();
    cylLottieCount += 1;
    this.name = `cyl-lottie-${cylLottieCount}`;
    this.registerReplay(() => this.cylReplay());
  }

  aboutToDisappear(): void {
    this.cylLifecycle?.aboutToDisappear();
  }

  // [EN] The teardown block (CYLDeallocBlockExecutor), run by `aboutToDisappear`. [CN] 销毁块（CYLDeallocBlockExecutor），由 `aboutToDisappear` 运行。
  private cylTeardown(): void {
    this.lottieItem?.destroy(this.name);
    this.lottieItem = undefined;
  }

  cylLoad(): void {
    this.lottieItem = lottie.loadAnimation({
      container: this.context,
      renderer: 'canvas',
      loop: this.loops,
      autoplay: false,
      name: this.name,
      path: this.path,
    });
    this.lottieItem.setSpeed(this.speed);
    this.lottieItem.addEventListener('DOMLoaded', () => {
      this.cylUpdate();
      this.onLoaded();
    });
    this.lottieItem.addEventListener('complete', () => {
      if (!this.loops) {
        this.onEnded();
      }
    });
    this.lottieItem.addEventListener('data_failed', () => this.onLoadError(`cannot load ${this.path}`));
  }

  cylSpeedChanged(): void {
    this.lottieItem?.setSpeed(this.speed);
  }

  /** [EN] A new path (e.g. the dark file after a color mode change) reloads the animation. [CN] 新路径（如切换深色模式后）重新加载动画。 */
  cylReload(): void {
    if (this.lottieItem !== undefined) {
      this.lottieItem.destroy(this.name);
      this.lottieItem = undefined;
      this.cylLoad();
    }
  }

  cylUpdate(): void {
    if (this.lottieItem === undefined) {
      return;
    }
    if (this.selected) {
      this.lottieItem.goToAndPlay(0, true);
    } else {
      this.lottieItem.goToAndStop(0, true);
    }
  }

  cylReplay(): void {
    if (this.selected) {
      this.lottieItem?.goToAndPlay(0, true);
    }
  }

  /** [EN] Applied to the animation already playing; turning it on replays a finished one. [CN] 对正在播放的动画生效；开启时重新播放已结束的动画。 */
  cylLoopsChanged(): void {
    const item = this.lottieItem;
    if (item === undefined) {
      return;
    }
    item.loop = this.loops;
    if (this.loops && this.selected && item.isPaused) {
      item.goToAndPlay(0, true);
    }
  }

  build() {
    Canvas(this.context)
      .width(this.iconSize)
      .height(this.iconSize)
      .onReady(() => this.cylLoad())
      // [EN] The canvas never takes the tab's taps (the Rive view of the Android port did). [CN] 画布不拦截 Tab 的点击。
      .hitTestBehavior(HitTestMode.Transparent)
      .accessibilityLevel('no')
  }
}
