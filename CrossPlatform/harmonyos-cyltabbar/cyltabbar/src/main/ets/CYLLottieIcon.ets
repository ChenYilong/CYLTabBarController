import lottie, { AnimationItem } from '@ohos/lottie';

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
  speed: number = 1;
  @Prop @Watch('cylUpdate') selected: boolean = false;
  @Prop @Watch('cylReplay') replayToken: number = 0;
  /** [EN] The file is drawn (CYLAnimatedItemView shows it from here on). [CN] 文件已绘制（CYLAnimatedItemView 从此显示它）。 */
  onLoaded: () => void = () => {};
  /** [EN] The file cannot be loaded. [CN] 文件无法加载。 */
  onLoadError: (message: string) => void = (_message: string) => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private lottieItem?: AnimationItem;
  private name: string = '';

  aboutToAppear(): void {
    cylLottieCount += 1;
    this.name = `cyl-lottie-${cylLottieCount}`;
  }

  aboutToDisappear(): void {
    this.lottieItem?.destroy(this.name);
    this.lottieItem = undefined;
  }

  cylLoad(): void {
    this.lottieItem = lottie.loadAnimation({
      container: this.context,
      renderer: 'canvas',
      loop: false,
      autoplay: false,
      name: this.name,
      path: this.path,
    });
    this.lottieItem.setSpeed(this.speed);
    this.lottieItem.addEventListener('DOMLoaded', () => {
      this.cylUpdate();
      this.onLoaded();
    });
    this.lottieItem.addEventListener('data_failed', () => this.onLoadError(`cannot load ${this.path}`));
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
