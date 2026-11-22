/**
 * [EN] The SVGA engine of CYLAnimatedItemView: SVGA 2.x files (a rawfile path or an http(s) URL) parsed and drawn on an
 *      ArkUI Canvas by the component's own decoder and renderer (svga/), driven by a timed player (speed, loop, any
 *      progress, the end of a pass). No third-party library. `CYLAnimatedItemSVGA.register()` makes items play ".svga"
 *      files. Moved from cyltabbar's CYLSVGAView and CYLTableViewPlaceHolder's CYLSVGAPlaceholderItemAnimator (the same
 *      decoder and renderer; progress 1 is the last frame).
 * [CN] CYLAnimatedItemView 的 SVGA 引擎：SVGA 2.x 文件（rawfile 路径或 http(s) 地址）由组件自带的解码器与渲染器（svga/）解析并绘制在
 *      ArkUI Canvas 上，由定时播放器驱动（速度、循环、任意进度、一遍结束）。不依赖第三方库。`CYLAnimatedItemSVGA.register()` 使条目播放
 *      ".svga" 文件。从 cyltabbar 的 CYLSVGAView 与 CYLTableViewPlaceHolder 的 CYLSVGAPlaceholderItemAnimator 迁移而来（同一解码器与渲染器；进度
 *      1 为最后一帧）。
 */
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { CYLAnimatedItemEngineBinding, CYLAnimatedItemTimedPlayer } from './CYLAnimatedItemPlayer';
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';
import { CYLAnimatedItemEngineState, CYLAnimatedItemEngineViews } from './CYLAnimatedItemEngine';
import { CYLSVGAMovie, cylLoadSVGAMovie } from './svga/CYLSVGAMovie';
import { cylDrawSVGAFrame } from './svga/CYLSVGARenderer';
import { cylSVGADurationMs, cylSVGAFrameAt } from './CYLAnimatedItemSVGATiming';

/**
 * [EN] The bytes of an SVGA file: an http(s) URL (the app needs ohos.permission.INTERNET), else the app's rawfile.
 * [CN] SVGA 文件的字节：http(s) 地址（App 需要 ohos.permission.INTERNET），否则为 App 的 rawfile。
 */
async function cylReadSVGA(context: Context, source: CYLAnimatedItemSource): Promise<Uint8Array | undefined> {
  if (/^https?:\/\//.test(source.path)) {
    let request: http.HttpRequest;
    try {
      request = http.createHttp();
    } catch (error) {
      return undefined;
    }
    try {
      const response = await request.request(source.path, { expectDataType: http.HttpDataType.ARRAY_BUFFER });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return undefined;
      }
      return new Uint8Array(response.result as ArrayBuffer);
    } finally {
      request.destroy();
    }
  }
  return source.rawFileContent(context.resourceManager);
}

/** [EN] The movie's PNG images as pixel maps; a broken image is left out. [CN] 动画中的 PNG 图片转为 PixelMap；损坏的图片会被略过。 */
async function cylDecodeSVGABitmaps(movie: CYLSVGAMovie): Promise<Map<string, image.PixelMap>> {
  const bitmaps = new Map<string, image.PixelMap>();
  for (const key of Array.from(movie.images.keys())) {
    const bytes = movie.images.get(key);
    if (bytes === undefined) {
      continue;
    }
    try {
      const imageSource = image.createImageSource(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer);
      bitmaps.set(key, await imageSource.createPixelMap());
      await imageSource.release();
    } catch (error) {
      // [EN] Skip a broken image. [CN] 略过损坏的图片。
    }
  }
  return bitmaps;
}

/**
 * [EN] The player of an SVGA movie: `onFrame` draws a frame.
 * [CN] SVGA 动画的播放器：`onFrame` 绘制一帧。
 */
export class CYLAnimatedItemSVGAPlayer extends CYLAnimatedItemTimedPlayer {
  readonly movie: CYLSVGAMovie;
  readonly bitmaps: Map<string, image.PixelMap>;
  onFrame?: (frame: number) => void;
  private shownFrame: number = -1;

  constructor(source: CYLAnimatedItemSource, movie: CYLSVGAMovie, bitmaps: Map<string, image.PixelMap>) {
    super('SVGA', source);
    this.movie = movie;
    this.bitmaps = bitmaps;
  }

  protected get durationMs(): number {
    return cylSVGADurationMs(this.movie.frames, this.movie.fps);
  }

  protected render(): void {
    const frame = cylSVGAFrameAt(this.movie.frames, this.progressValue);
    if (frame !== this.shownFrame) {
      this.shownFrame = frame;
      this.onFrame?.(frame);
    }
  }

  destroy(): void {
    super.destroy();
    this.onFrame = undefined;
    this.bitmaps.forEach((bitmap: image.PixelMap) => {
      bitmap.release();
    });
    this.bitmaps.clear();
  }
}

/** [EN] The SVGA engine view. [CN] SVGA 引擎视图。 */
@Component
export struct CYLAnimatedItemSVGAView {
  state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  private unlisten?: () => void;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private binding: CYLAnimatedItemEngineBinding = new CYLAnimatedItemEngineBinding();
  private loadedUrl: string = '';
  private canvasReady: boolean = false;

  aboutToAppear(): void {
    this.unlisten = this.state.listen(() => this.cylStateChanged());
  }

  aboutToDisappear(): void {
    this.unlisten?.();
    this.binding.release();
  }

  cylStateChanged(): void {
    if (this.state.source.url !== this.loadedUrl) {
      this.binding.release();
      if (this.canvasReady) {
        this.context.clearRect(0, 0, this.state.width, this.state.height);
        this.cylLoad();
      }
      return;
    }
    this.binding.update(this.state);
  }

  private cylLoad(): void {
    const source = this.state.source;
    this.loadedUrl = source.url;
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.binding.failed(this.state);
      return;
    }
    this.cylDecode(context, source).catch(() => {
      if (source.url === this.loadedUrl) {
        this.binding.failed(this.state);
      }
    });
  }

  private async cylDecode(context: Context, source: CYLAnimatedItemSource): Promise<void> {
    const bytes = await cylReadSVGA(context, source);
    if (bytes === undefined) {
      throw new Error('no bytes');
    }
    const movie = await cylLoadSVGAMovie(bytes);
    const bitmaps = await cylDecodeSVGABitmaps(movie);
    if (source.url !== this.loadedUrl) {
      bitmaps.forEach((bitmap: image.PixelMap) => bitmap.release());
      return;
    }
    const player = new CYLAnimatedItemSVGAPlayer(source, movie, bitmaps);
    player.onFrame = (frame: number) => {
      cylDrawSVGAFrame(this.context, movie, bitmaps, frame, this.state.width, this.state.height);
    };
    cylDrawSVGAFrame(this.context, movie, bitmaps, 0, this.state.width, this.state.height);
    this.binding.ready(this.state, player);
  }

  build() {
    Canvas(this.context)
      .width(this.state.width)
      .height(this.state.height)
      .accessibilityLevel('no')
      .hitTestBehavior(HitTestMode.Transparent)
      .onReady(() => {
        this.canvasReady = true;
        this.cylLoad();
      })
  }
}

@Builder
function cylSVGAEngineView(state: CYLAnimatedItemEngineState) {
  CYLAnimatedItemSVGAView({ state: state })
}

/**
 * [EN] The SVGA engine: `register()` once (for example in `EntryAbility.onCreate`) and items play SVGA files.
 * [CN] SVGA 引擎：调用一次 `register()`（例如在 `EntryAbility.onCreate` 中），条目即可播放 SVGA 文件。
 */
export class CYLAnimatedItemSVGA {
  static register(): void {
    CYLAnimatedItemEngineViews.register('SVGA', wrapBuilder(cylSVGAEngineView));
  }
}
