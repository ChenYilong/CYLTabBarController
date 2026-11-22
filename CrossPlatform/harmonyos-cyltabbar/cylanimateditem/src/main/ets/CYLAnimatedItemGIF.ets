/**
 * [EN] The GIF engine of CYLAnimatedItemView: the frames ImageKit decodes, shown one at a time by a timed player (speed,
 *      loop, any progress, the end of a pass). No third-party library. `CYLAnimatedItemGIF.register()` makes items play
 *      ".gif" files. Moved from CollectionViewClassifyMenu's example (`CYLGIFPlayer`, `CYLGIFIconView`).
 * [CN] CYLAnimatedItemView 的 GIF 引擎：ImageKit 解码的帧，由定时播放器逐帧显示（速度、循环、任意进度、一遍结束）。不依赖第三方库。
 *      `CYLAnimatedItemGIF.register()` 使条目播放 ".gif" 文件。从 CollectionViewClassifyMenu 示例（`CYLGIFPlayer`、`CYLGIFIconView`）迁移而来。
 */
import { image } from '@kit.ImageKit';
import { CYLAnimatedItemEngineBinding, CYLAnimatedItemTimedPlayer } from './CYLAnimatedItemPlayer';
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';
import { CYLAnimatedItemEngineState, CYLAnimatedItemEngineViews } from './CYLAnimatedItemEngine';
import { cylGIFDelays, cylGIFDuration, cylGIFFrameIndex } from './CYLAnimatedItemGIFTiming';

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
  @ObjectLink @Watch('cylStateChanged') state: CYLAnimatedItemEngineState;
  @State private frame: image.PixelMap | undefined = undefined;
  private binding: CYLAnimatedItemEngineBinding = new CYLAnimatedItemEngineBinding();
  private loadedUrl: string = '';

  aboutToAppear(): void {
    this.cylLoad();
  }

  aboutToDisappear(): void {
    this.binding.release();
  }

  cylStateChanged(): void {
    if (this.state.source.url !== this.loadedUrl) {
      this.binding.release();
      this.frame = undefined;
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
    if (bytes === undefined) {
      this.binding.failed(this.state);
      return;
    }
    const imageSource = image.createImageSource(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer);
    imageSource.getDelayTimeList().then((delays: number[]) => {
      return imageSource.createPixelMapList().then((frames: image.PixelMap[]) => {
        imageSource.release();
        if (source.url !== this.loadedUrl) {
          frames.forEach((f: image.PixelMap) => f.release());
          return;
        }
        const player = new CYLAnimatedItemGIFPlayer(source, frames, delays);
        player.onFrame = (f: image.PixelMap) => {
          this.frame = f;
        };
        this.frame = frames.length > 0 ? frames[0] : undefined;
        this.binding.ready(this.state, player);
      });
    }).catch(() => {
      imageSource.release();
      this.binding.failed(this.state);
    });
  }

  build() {
    Stack() {
      if (this.frame !== undefined) {
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
