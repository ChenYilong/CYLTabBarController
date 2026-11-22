/**
 * [EN] The GIF engine of CYLAnimatedItemView: the frames ImageKit decodes, shown one at a time by a timed player (speed,
 *      loop, any progress, the end of a pass). No third-party library. `CYLAnimatedItemGIF.register()` makes items play
 *      ".gif" files. Moved from CollectionViewClassifyMenu's example (`CYLGIFPlayer`, `CYLGIFIconView`). A file ImageKit
 *      only partly understands still shows (CYLTableViewPlaceHolder 3fe1896d, 76762c6a): a truncated file drops its
 *      incomplete last frame; when the frames do not decode, the first frame shows as a still; when that fails too, ArkUI's
 *      Image decodes and plays a cache copy; only then does the item report a failure (its still image stays).
 * [CN] CYLAnimatedItemView 的 GIF 引擎：ImageKit 解码的帧，由定时播放器逐帧显示（速度、循环、任意进度、一遍结束）。不依赖第三方库。
 *      `CYLAnimatedItemGIF.register()` 使条目播放 ".gif" 文件。从 CollectionViewClassifyMenu 示例（`CYLGIFPlayer`、`CYLGIFIconView`）迁移而来。
 *      ImageKit 只能部分解码的文件仍会显示（CYLTableViewPlaceHolder 3fe1896d、76762c6a）：截断的文件丢弃不完整的最后一帧；帧无法解码时显示首帧
 *      静态图；首帧也失败时由 ArkUI 的 Image 解码并播放缓存副本；这些都失败才报告失败（条目保留其静态图片）。
 */
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { CYLAnimatedItemEngineBinding, CYLAnimatedItemTimedPlayer } from './CYLAnimatedItemPlayer';
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';
import { CYLAnimatedItemEngineState, CYLAnimatedItemEngineViews } from './CYLAnimatedItemEngine';
import {
  cylGIFCacheFileName, cylGIFDelays, cylGIFDuration, cylGIFFrameIndex, cylGIFHasTrailer, cylGIFUsableFrameCount
} from './CYLAnimatedItemGIFTiming';

/**
 * [EN] The player of a GIF: its decoded frames (`gifFrames`) and their delays; `onFrame` shows a frame.
 * [CN] GIF 的播放器：解码的帧（`gifFrames`）及其延时；`onFrame` 显示一帧。
 */
export class CYLAnimatedItemGIFPlayer extends CYLAnimatedItemTimedPlayer {
  readonly gifFrames: image.PixelMap[];
  /** [EN] Milliseconds each frame stays. [CN] 每帧停留的毫秒数。 */
  readonly gifDelays: number[];
  onFrame?: (frame: image.PixelMap) => void;
  private total: number = 0;
  private shownIndex: number = -1;

  constructor(source: CYLAnimatedItemSource, frames: image.PixelMap[], delays: number[]) {
    super('GIF', source);
    this.gifFrames = frames;
    this.gifDelays = cylGIFDelays(frames.length, delays);
    this.total = cylGIFDuration(this.gifDelays);
  }

  protected get durationMs(): number {
    return this.total;
  }

  protected render(): void {
    const index = cylGIFFrameIndex(this.gifDelays, this.progressValue);
    if (index >= 0 && index !== this.shownIndex) {
      this.shownIndex = index;
      this.onFrame?.(this.gifFrames[index]);
    }
  }

  destroy(): void {
    super.destroy();
    this.onFrame = undefined;
    this.gifFrames.forEach((frame: image.PixelMap) => {
      frame.release();
    });
  }
}

/** [EN] The GIF engine view. [CN] GIF 引擎视图。 */
@Component
export struct CYLAnimatedItemGIFView {
  state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  private unlisten?: () => void;
  @State private frame: image.PixelMap | undefined = undefined;
  /** [EN] The "file://" cache copy ArkUI's Image draws when ImageKit cannot decode the file, else ''. [CN] ImageKit 无法解码时由 ArkUI Image 绘制的缓存副本（"file://"），否则为 ''。 */
  @State private systemImagePath: string = '';
  private binding: CYLAnimatedItemEngineBinding = new CYLAnimatedItemEngineBinding();
  private loadedUrl: string = '';

  aboutToAppear(): void {
    this.unlisten = this.state.listen(() => this.cylStateChanged());
    this.cylLoad();
  }

  aboutToDisappear(): void {
    this.unlisten?.();
    this.binding.release();
  }

  cylStateChanged(): void {
    if (this.state.source.url !== this.loadedUrl) {
      this.binding.release();
      this.frame = undefined;
      this.systemImagePath = '';
      this.cylLoad();
      return;
    }
    this.binding.update(this.state);
  }

  private cylLoad(): void {
    const source = this.state.source;
    this.loadedUrl = source.url;
    const context = this.getUIContext().getHostContext();
    const bytes = context === undefined ? undefined : source.rawFileContent(context.resourceManager);
    if (context === undefined || bytes === undefined) {
      this.binding.failed(this.state);
      return;
    }
    this.cylDecode(source, bytes, context.cacheDir).catch(() => {
      if (source.url === this.loadedUrl) {
        this.binding.failed(this.state);
      }
    });
  }

  /**
   * [EN] Decodes with fallbacks: every frame (a truncated file without its last, incomplete one), else the first frame as a
   *      still, else ArkUI's Image on a cache copy (no player control), else a failure.
   * [CN] 带回退的解码：所有帧（截断的文件去掉不完整的最后一帧），否则首帧静态图，否则 ArkUI Image 绘制缓存副本（不受播放器控制），否则失败。
   */
  private async cylDecode(source: CYLAnimatedItemSource, bytes: Uint8Array, cacheDir: string): Promise<void> {
    const buffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
    const imageSource = image.createImageSource(buffer);
    let frames: image.PixelMap[] = [];
    let delays: number[] = [];
    try {
      try {
        frames = await imageSource.createPixelMapList();
        const usable = cylGIFUsableFrameCount(frames.length, cylGIFHasTrailer(bytes));
        while (frames.length > usable) {
          frames.pop()?.release();
        }
        if (frames.length > 1) {
          delays = await imageSource.getDelayTimeList().catch((): number[] => []);
        }
      } catch (e) {
        frames = [];
      }
      if (frames.length === 0) {
        try {
          frames = [await imageSource.createPixelMap()];
        } catch (e) {
          frames = [];
        }
      }
    } finally {
      imageSource.release();
    }
    if (source.url !== this.loadedUrl) {
      frames.forEach((f: image.PixelMap) => f.release());
      return;
    }
    if (frames.length > 0) {
      const player = new CYLAnimatedItemGIFPlayer(source, frames, delays);
      player.onFrame = (f: image.PixelMap) => {
        this.frame = f;
      };
      this.frame = frames[0];
      this.binding.ready(this.state, player);
      return;
    }
    const path = cacheDir + '/' + cylGIFCacheFileName(source.url, bytes.length);
    try {
      if (!fileIo.accessSync(path)) {
        const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(file.fd, buffer);
        } finally {
          fileIo.closeSync(file);
        }
      }
    } catch (e) {
      this.binding.failed(this.state);
      return;
    }
    this.systemImagePath = 'file://' + path;
    this.binding.ready(this.state, new CYLAnimatedItemGIFPlayer(source, [], []));
  }

  build() {
    Stack() {
      if (this.systemImagePath !== '') {
        // [EN] ImageKit could not decode it: ArkUI's Image decodes and plays the copy (it ignores the player's controls).
        //      When it fails too, the item reports the failure and keeps its still image (CYLTableViewPlaceHolder 3fe1896d).
        // [CN] ImageKit 无法解码：由 ArkUI Image 解码并播放副本（不受播放器控制）。它也失败时条目报告失败并保留静态图片。
        Image(this.systemImagePath)
          .width(this.state.width)
          .height(this.state.height)
          .objectFit(ImageFit.Contain)
          .accessibilityLevel('no')
          .onError(() => {
            this.systemImagePath = '';
            this.binding.release();
            this.binding.failed(this.state);
          })
      } else if (this.frame !== undefined) {
        Image(this.frame)
          .width(this.state.width)
          .height(this.state.height)
          .objectFit(ImageFit.Contain)
          .accessibilityLevel('no')
      }
    }
    .width(this.state.width)
    .height(this.state.height)
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no')
  }
}

@Builder
function cylGIFEngineView(state: CYLAnimatedItemEngineState) {
  CYLAnimatedItemGIFView({ state: state })
}

/**
 * [EN] The GIF engine: `register()` once (for example in `EntryAbility.onCreate`) and items play GIF files.
 * [CN] GIF 引擎：调用一次 `register()`（例如在 `EntryAbility.onCreate` 中），条目即可播放 GIF 文件。
 */
export class CYLAnimatedItemGIF {
  static register(): void {
    CYLAnimatedItemEngineViews.register('GIF', wrapBuilder(cylGIFEngineView));
  }
}
