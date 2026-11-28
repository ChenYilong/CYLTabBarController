import { image } from '@kit.ImageKit';
import { LifecycleController } from 'cylutils';
import { http } from '@kit.NetworkKit';
import { CYLSVGAMovie, cylLoadSVGAMovie } from './CYLSVGAMovie';
import { cylDrawSVGAFrame } from './CYLSVGARenderer';

/**
 * [EN] The bytes of an SVGA file: an http(s) URL (the app needs ohos.permission.INTERNET), else a rawfile path of the app
 *      ("svga/tab_home.svga" in resources/rawfile).
 * [CN] SVGA 文件的字节：http(s) 地址（App 需要 ohos.permission.INTERNET），否则为 App 的 rawfile 路径（resources/rawfile 中的
 *      "svga/tab_home.svga"）。
 */
async function cylReadSVGA(context: Context, path: string): Promise<Uint8Array> {
  if (/^https?:\/\//.test(path)) {
    let request: http.HttpRequest;
    try {
      request = http.createHttp();
    } catch (error) {
      throw new Error(`CYLSVGA: no HTTP client: ${(error as Error).message}`);
    }
    try {
      const response = await request.request(path, { expectDataType: http.HttpDataType.ARRAY_BUFFER });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`CYLSVGA: loading ${path} failed with HTTP status ${response.responseCode}`);
      }
      return new Uint8Array(response.result as ArrayBuffer);
    } catch (error) {
      throw new Error(`CYLSVGA: loading ${path} failed: ${(error as Error).message}`);
    } finally {
      request.destroy();
    }
  }
  try {
    return await context.resourceManager.getRawFileContent(path);
  } catch (error) {
    throw new Error(`CYLSVGA: reading the rawfile ${path} failed: ${(error as Error).message}`);
  }
}

/**
 * [EN] The PNG images of the movie as pixel maps; a broken image is left out. [CN] 动画中的 PNG 图片转为 PixelMap；损坏的图片会被略过。
 */
async function cylDecodeBitmaps(movie: CYLSVGAMovie): Promise<Map<string, image.PixelMap>> {
  const bitmaps = new Map<string, image.PixelMap>();
  const keys = Array.from(movie.images.keys());
  for (const key of keys) {
    const bytes = movie.images.get(key);
    if (bytes === undefined) {
      continue;
    }
    try {
      const source = image.createImageSource(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength));
      bitmaps.set(key, await source.createPixelMap());
      await source.release();
    } catch (error) {
      // [EN] Skip a broken image. [CN] 略过损坏的图片。
    }
  }
  return bitmaps;
}

/**
 * [EN] FIX: issue #415. An SVGA 2.x tab icon (CYLTabBarSVGAFilePath / CYLTabBarSVGAURL) on an ArkUI Canvas: it plays once
 *      from the start each time its tab becomes selected (and on a re-tap, `replayToken`) and keeps the last frame; unselected,
 *      it shows the first frame (iOS `CYLSVGATabBarItemAnimator`, as CYLLottieIcon). Decorative for the screen reader (the
 *      tab reads its title), and transparent to taps.
 * [CN] FIX: issue #415。ArkUI Canvas 上的 SVGA 2.x Tab 图标（CYLTabBarSVGAFilePath / CYLTabBarSVGAURL）：每次 Tab 变为选中（以及再次点击，
 *      `replayToken`）时从头播放一次并停在最后一帧；未选中时显示第一帧（iOS `CYLSVGATabBarItemAnimator`，与 CYLLottieIcon 相同）。对屏幕阅读器
 *      是装饰（由 Tab 朗读标题），不拦截点击。
 */
@Component
export struct CYLSVGAView {
  @Prop @Watch('cylReload') path: string = '';
  iconSize: number = 26;
  @Prop @Watch('cylSelectedChanged') selected: boolean = false;
  /**
   * [EN] Each increase plays the animation again while selected (a re-tap), as CYLLottieIcon. [CN] 每次增加时在选中状态下重新播放（再次点击），与 CYLLottieIcon 相同。
   */
  @Prop @Watch('cylReplay') replayToken: number = 0;
  /**
   * [EN] Plays again from the start after each pass while the tab is selected (tabBarItemAnimationLoops); off by default.
   * [CN] Tab 选中期间每次播放结束后从头再次播放（tabBarItemAnimationLoops）；默认关闭。
   */
  @Prop @Watch('cylLoopsChanged') loops: boolean = false;
  /**
   * [EN] The file could not be loaded or decoded, with the reason. [CN] 文件无法加载或解码，附原因。
   */
  /** [EN] The file is drawn (CYLAnimatedItemView shows it from here on). [CN] 文件已绘制。 */
  onLoaded: () => void = () => {};
  /**
   * [EN] A play-once pass reached its last frame (CYLAnimatedItemAnimationContext `onEnded`). [CN] 只播放一次的一遍播放到最后一帧。
   */
  onEnded: () => void = () => {};
  onLoadError: (message: string) => void = (_message: string) => {
  };
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private movie: CYLSVGAMovie | undefined = undefined;
  private bitmaps: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private frame: number = 0;
  private timer: number = -1;
  /**
   * [EN] Hands the host this view's replay, called on each restart (CYLAnimatedItemView `setRestartHandler`, B23).
   * [CN] 把本视图的重播交给宿主，每次重播时调用（CYLAnimatedItemView `setRestartHandler`，B23）。
   */
  registerReplay: (replay: () => void) => void = (_replay: () => void) => {};

  private cylLifecycle: LifecycleController<CYLSVGAView> | undefined = undefined;

  aboutToAppear(): void {
    this.registerReplay(() => this.cylReplay());
    this.cylLifecycle = new LifecycleController<CYLSVGAView>(this);
    this.cylLifecycle.registry.addDeallocCallback<CYLSVGAView>((owner: CYLSVGAView) => owner.cylTeardown(), { key: 'cyl.svga.teardown' });
    this.cylLifecycle.aboutToAppear();
  }

  aboutToDisappear(): void {
    this.cylLifecycle?.aboutToDisappear();
  }

  // [EN] The teardown block (CYLDeallocBlockExecutor), run by `aboutToDisappear`. [CN] 销毁块（CYLDeallocBlockExecutor），由 `aboutToDisappear` 运行。
  private cylTeardown(): void {
    this.cylStop();
    this.bitmaps.forEach((bitmap: image.PixelMap) => {
      bitmap.release();
    });
    this.bitmaps.clear();
  }

  /** [EN] A new path (e.g. the dark file after a color mode change) reloads the animation. [CN] 新路径（如切换深色模式后）重新加载动画。 */
  cylReload(): void {
    this.cylStop();
    this.movie = undefined;
    this.cylLoad();
  }

  cylReplay(): void {
    if (this.selected) {
      this.cylPlayFromStart();
    }
  }

  /** [EN] Applied while playing; turning it on replays a finished animation. [CN] 播放中立即生效；开启时重新播放已结束的动画。 */
  cylLoopsChanged(): void {
    if (this.loops && this.selected && this.timer === -1) {
      this.cylPlayFromStart();
    }
  }

  cylSelectedChanged(): void {
    if (this.selected) {
      this.cylPlayFromStart();
    } else {
      this.cylStop();
      this.frame = 0;
      this.cylDraw();
    }
  }

  private async cylLoad(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined || this.path.length === 0) {
      return;
    }
    try {
      const movie = await cylLoadSVGAMovie(await cylReadSVGA(context, this.path));
      this.bitmaps = await cylDecodeBitmaps(movie);
      this.movie = movie;
      // [EN] As CYLLottieIcon: a selected tab plays from the start once loaded, the others rest on the first frame.
      // [CN] 与 CYLLottieIcon 相同：选中的 Tab 加载后从头播放，其他 Tab 停在第一帧。
      this.frame = 0;
      if (this.selected) {
        this.cylPlayFromStart();
      } else {
        this.cylDraw();
      }
      this.onLoaded();
    } catch (error) {
      this.onLoadError(`${(error as Error).message ?? error}`);
    }
  }

  private cylDraw(): void {
    if (this.movie !== undefined) {
      cylDrawSVGAFrame(this.context, this.movie, this.bitmaps, this.frame, this.iconSize, this.iconSize);
    }
  }

  private cylStop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private cylPlayFromStart(): void {
    const movie = this.movie;
    if (movie === undefined) {
      return;
    }
    this.cylStop();
    this.frame = 0;
    this.cylDraw();
    this.timer = setInterval(() => {
      this.frame += 1;
      if (this.frame >= movie.frames) {
        // [EN] Looping: back to the first frame; else rest on the last one. [CN] 循环时回到第一帧，否则停在最后一帧。
        this.frame = 0;
      } else if (this.frame >= movie.frames - 1 && !this.loops) {
        this.frame = movie.frames - 1;
        this.cylStop();
        this.cylDraw();
        this.onEnded();
        return;
      }
      this.cylDraw();
    }, 1000 / movie.fps);
  }

  build() {
    Canvas(this.context)
      .width(this.iconSize)
      .height(this.iconSize)
      .accessibilityLevel('no')
      // [EN] The canvas never takes the tab's taps, as CYLLottieIcon. [CN] 与 CYLLottieIcon 相同，画布不拦截 Tab 的点击。
      .hitTestBehavior(HitTestMode.Transparent)
      .onReady(() => {
        this.cylLoad();
      })
  }
}
