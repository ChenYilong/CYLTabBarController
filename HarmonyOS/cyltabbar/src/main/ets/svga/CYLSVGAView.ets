import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { CYLSVGAMovie, cylLoadSVGAMovie } from './CYLSVGAMovie';
import { cylDrawSVGAFrame } from './CYLSVGARenderer';

/**
 * [EN] The bytes of an SVGA file: an http(s) URL (ohos.permission.INTERNET, declared by this module), else a rawfile path of the app
 *      ("svga/tab_home.svga" in resources/rawfile).
 * [CN] SVGA 文件的字节：http(s) 地址（ohos.permission.INTERNET，由本模块声明），否则为 App 的 rawfile 路径（resources/rawfile 中的
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
 * [EN] FIX: issue #415. An SVGA 2.x animation on an ArkUI Canvas, as a tab icon: it plays once when `selected` becomes true
 *      and keeps the last frame; unselected, it shows the first frame (iOS `CYLSVGATabBarItemAnimator`). Decorative for the
 *      screen reader: the tab reads its title.
 * [CN] FIX: issue #415。ArkUI Canvas 上的 SVGA 2.x 动画，用作 Tab 图标：`selected` 变为 true 时播放一次并停在最后一帧；未选中时
 *      显示第一帧（iOS `CYLSVGATabBarItemAnimator`）。对屏幕阅读器是装饰：由 Tab 朗读标题。
 */
@Component
export struct CYLSVGAView {
  @Prop path: string = '';
  @Prop @Watch('cylSelectedChanged') selected: boolean = false;
  @Prop iconSize: number = 26;
  /**
   * [EN] The file could not be loaded or decoded, with the reason. [CN] 文件无法加载或解码，附原因。
   */
  onLoadError: (message: string) => void = (_message: string) => {
  };
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private movie: CYLSVGAMovie | undefined = undefined;
  private bitmaps: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private frame: number = 0;
  private timer: number = -1;

  aboutToDisappear(): void {
    this.cylStop();
    this.bitmaps.forEach((bitmap: image.PixelMap) => {
      bitmap.release();
    });
    this.bitmaps.clear();
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
      // [EN] Selected at launch: rest on the last frame, as after playing. [CN] 启动时已选中：停在最后一帧，与播放后相同。
      this.frame = this.selected ? movie.frames - 1 : 0;
      this.cylDraw();
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
      if (this.frame >= movie.frames - 1) {
        this.frame = movie.frames - 1;
        this.cylStop();
      }
      this.cylDraw();
    }, 1000 / movie.fps);
  }

  build() {
    Canvas(this.context)
      .width(this.iconSize)
      .height(this.iconSize)
      .accessibilityLevel('no')
      .onReady(() => {
        this.cylLoad();
      })
  }
}
