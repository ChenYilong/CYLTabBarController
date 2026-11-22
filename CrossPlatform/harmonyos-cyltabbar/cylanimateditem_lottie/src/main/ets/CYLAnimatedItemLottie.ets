/**
 * [EN] The Lottie engine of CYLAnimatedItemView (@ohos/lottie): a canvas per item, rawfile JSON or inline JSON, image
 *      assets ("u" + "p") found next to the JSON file or at the rawfile root; speed, loop, any progress and the end of a
 *      pass. `CYLAnimatedItemLottie.register()` once makes every `CYLAnimatedItemView` without an `animationBuilder` play
 *      Lottie files. Merged from cyltabbar's `CYLLottieIcon` (named animations destroyed by name, "complete" as the end,
 *      "data_failed") and CollectionViewClassifyMenu's `CYLLottiePlayer` / `CYLLottieIconView` (inline JSON, image
 *      assets, a progress asked for before the file loaded).
 * [CN] CYLAnimatedItemView 的 Lottie 引擎（@ohos/lottie）：每个条目一个画布，rawfile JSON 或内联 JSON，图片资源（"u" + "p"）在 JSON 文件旁或
 *      rawfile 根目录查找；速度、循环、任意进度与一遍结束。调用一次 `CYLAnimatedItemLottie.register()` 后，所有未传入 `animationBuilder` 的
 *      `CYLAnimatedItemView` 都播放 Lottie 文件。由 cyltabbar 的 `CYLLottieIcon` 与 CollectionViewClassifyMenu 的 `CYLLottiePlayer` /
 *      `CYLLottieIconView` 合并而来。
 */
import lottie, { AnimationItem } from '@ohos/lottie';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import {
  CYLAnimatedItemEngineBinding, CYLAnimatedItemEngineState, CYLAnimatedItemEngineViews, CYLAnimatedItemPlayer,
  CYLAnimatedItemSource, cylAnimatedItemParseHexColor
} from 'cylanimateditem';

let cylLottieCount: number = 0;

/**
 * [EN] The player of a Lottie item: `lottieItem` is @ohos/lottie's `AnimationItem`.
 * [CN] Lottie 条目的播放器：`lottieItem` 为 @ohos/lottie 的 `AnimationItem`。
 */
export class CYLAnimatedItemLottiePlayer extends CYLAnimatedItemPlayer {
  readonly lottieItem: AnimationItem;
  /** [EN] The animation's name, for `destroy(name)`. [CN] 动画名称，用于 `destroy(name)`。 */
  readonly name: string;
  /** [EN] A progress asked for before the file finished loading, applied once it has. [CN] 文件加载完成前请求的进度，加载后应用。 */
  private pendingProgress?: number;
  /** [EN] The colors applied (re-applied once the file has loaded). [CN] 已应用的颜色（文件加载完成后重新应用）。 */
  private colors?: Map<string, string>;
  /**
   * [EN] Loads the file again (set by the view): lottie-ohos cannot undo changeColor, so restoring the file's colors reloads.
   * [CN] 重新加载文件（由视图设置）：lottie-ohos 无法撤销 changeColor，因此恢复文件颜色时重新加载。
   */
  reload?: () => void;

  constructor(source: CYLAnimatedItemSource, item: AnimationItem, name: string) {
    super('Lottie', source);
    this.lottieItem = item;
    this.name = name;
    item.addEventListener('DOMLoaded', () => {
      const progress = this.pendingProgress;
      this.pendingProgress = undefined;
      if (progress !== undefined && this.lottieItem.isPaused) {
        this.stopAtProgress(progress);
      }
      this.applyColorsToItem();
    });
    item.addEventListener('complete', () => this.didEnd());
  }

  get isPlaying(): boolean {
    return !this.lottieItem.isPaused;
  }

  get progress(): number | undefined {
    const last = Math.max(1, this.lottieItem.totalFrames - 1);
    return Math.min(1, Math.max(0, this.lottieItem.currentFrame / last));
  }

  /** [EN] lottie-ohos recolors whole layers, not key paths. [CN] lottie-ohos 按整层改色，而非按 keypath。 */
  get supportsColors(): boolean {
    return true;
  }

  /**
   * [EN] lottie-ohos recolors whole layers, not key paths: the first color paints every layer (as Android does; moved from
   *      CYLTableViewPlaceHolder's Lottie animator). undefined restores the file's colors by loading it again.
   * [CN] lottie-ohos 按整层改色，而非按 keypath：第一个颜色绘制所有图层（与 Android 相同；从 CYLTableViewPlaceHolder 的 Lottie 动画器迁移）。
   *      undefined 时重新加载文件以恢复其颜色。
   */
  applyColors(colors: Map<string, string> | undefined): void {
    const hadColors = this.colors !== undefined;
    this.colors = colors !== undefined && colors.size > 0 ? colors : undefined;
    if (this.colors === undefined) {
      if (hadColors) {
        this.reload?.();
      }
      return;
    }
    this.applyColorsToItem();
  }

  private applyColorsToItem(): void {
    const colors = this.colors;
    if (colors === undefined || this.lottieItem.totalFrames <= 0) {
      return;
    }
    const first = Array.from(colors.values())[0];
    const color = first === undefined ? undefined : cylAnimatedItemParseHexColor(first);
    if (color !== undefined) {
      this.lottieItem.changeColor([color.red, color.green, color.blue, color.alpha / 255]);
    }
  }

  play(): void {
    this.pendingProgress = undefined;
    this.lottieItem.loop = this.loopsValue;
    this.lottieItem.setSpeed(this.speedValue);
    this.lottieItem.goToAndPlay(0, true);
  }

  stopAtProgress(progress: number): void {
    if (this.lottieItem.totalFrames <= 0) {
      this.pendingProgress = progress;
      return;
    }
    const last = Math.max(0, this.lottieItem.totalFrames - 1);
    this.lottieItem.goToAndStop(Math.min(1, Math.max(0, progress)) * last, true);
  }

  destroy(): void {
    super.destroy();
    // [EN] By name: lottie.destroy() without one destroys every animation of the app. [CN] 按名称：不带名称会销毁 App 的所有动画。
    this.lottieItem.destroy(this.name);
  }

  protected applySpeed(): void {
    this.lottieItem.setSpeed(this.speedValue);
  }

  protected applyLoops(): void {
    this.lottieItem.loop = this.loopsValue;
  }
}

/** [EN] The Lottie JSON of a source, or undefined. [CN] 来源的 Lottie JSON，没有时为 undefined。 */
function cylLottieData(context: Context, source: CYLAnimatedItemSource): Object | undefined {
  try {
    if (source.inlineJSON !== undefined) {
      return JSON.parse(source.inlineJSON) as Object;
    }
    const bytes = source.rawFileContent(context.resourceManager);
    if (bytes === undefined) {
      return undefined;
    }
    return JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as Object;
  } catch (e) {
    return undefined;
  }
}

/** [EN] The Lottie engine view. [CN] Lottie 引擎视图。 */
@Component
export struct CYLAnimatedItemLottieView {
  state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  private unlisten?: () => void;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context2D: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
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
      // [EN] A new file (e.g. the dark one after a color mode change). [CN] 新文件（如切换深色模式后的文件）。
      this.binding.release();
      this.cylLoad();
      return;
    }
    this.binding.update(this.state);
  }

  private cylLoad(): void {
    if (!this.canvasReady) {
      return;
    }
    const source = this.state.source;
    this.loadedUrl = source.url;
    const context = this.getUIContext().getHostContext();
    cylLottieCount += 1;
    const name = `cyl-animated-item-lottie-${cylLottieCount}`;
    if (/^https?:\/\//i.test(source.path)) {
      // [EN] A remote file: @ohos/lottie downloads it (cyltabbar's CYLLottieIcon passed every path this way).
      // [CN] 远程文件：由 @ohos/lottie 下载（cyltabbar 的 CYLLottieIcon 以这种方式传入所有路径）。
      const remote: AnimationItem = lottie.loadAnimation({
        container: this.context2D, renderer: 'canvas', loop: false, autoplay: false, name: name, path: source.path
      });
      remote.addEventListener('data_failed', () => this.binding.failed(this.state));
      this.cylReady(new CYLAnimatedItemLottiePlayer(source, remote, name));
      return;
    }
    const data = context === undefined ? undefined : cylLottieData(context, source);
    if (context === undefined || data === undefined) {
      this.binding.failed(this.state);
      return;
    }
    const directory = source.directory;
    const item: AnimationItem = lottie.loadAnimation({
      container: this.context2D,
      renderer: 'canvas',
      loop: false,
      autoplay: false,
      name: name,
      animationData: data,
      imageAssetDelegate: (imagePath: string, callback: (err: BusinessError, data: image.PixelMap) => void) => {
        const file = imagePath.split('/').pop() ?? imagePath;
        const candidates: string[] = [directory + imagePath, directory + file, file];
        for (const candidate of candidates) {
          try {
            const bytes = context.resourceManager.getRawFileContentSync(candidate);
            const imageSource = image.createImageSource(bytes.buffer as ArrayBuffer);
            imageSource.createPixelMap().then((pixelMap: image.PixelMap) => {
              imageSource.release();
              callback(new Error() as BusinessError, pixelMap);
            });
            return;
          } catch (e) {
            // [EN] Try the next location. [CN] 尝试下一个位置。
          }
        }
      }
    });
    item.addEventListener('data_failed', () => this.binding.failed(this.state));
    this.cylReady(new CYLAnimatedItemLottiePlayer(source, item, name));
  }

  /** [EN] Hands the player out; restoring colors reloads the file through it. [CN] 交出播放器；恢复颜色时通过它重新加载文件。 */
  private cylReady(player: CYLAnimatedItemLottiePlayer): void {
    player.reload = () => {
      this.binding.release();
      this.cylLoad();
    };
    this.binding.ready(this.state, player);
  }

  build() {
    Canvas(this.context2D)
      .width(this.state.width)
      .height(this.state.height)
      .onReady(() => {
        this.canvasReady = true;
        this.cylLoad();
      })
      // [EN] The canvas never takes the item's taps. [CN] 画布不拦截条目的点击。
      .hitTestBehavior(HitTestMode.Transparent)
      .accessibilityLevel('no')
  }
}

@Builder
function cylLottieEngineView(state: CYLAnimatedItemEngineState) {
  CYLAnimatedItemLottieView({ state: state })
}

/**
 * [EN] The Lottie engine: `register()` once (for example in `EntryAbility.onCreate`).
 * [CN] Lottie 引擎：调用一次 `register()`（例如在 `EntryAbility.onCreate` 中）。
 */
export class CYLAnimatedItemLottie {
  static register(): void {
    CYLAnimatedItemEngineViews.register('Lottie', wrapBuilder(cylLottieEngineView));
  }
}
