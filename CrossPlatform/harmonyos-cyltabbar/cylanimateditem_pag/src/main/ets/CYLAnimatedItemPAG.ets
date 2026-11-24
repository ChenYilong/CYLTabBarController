/**
 * [EN] The PAG engine of CYLAnimatedItemView (@tencent/libpag ^4.4.31: 4.4.31 and 4.5.102 are both in use): libpag's `PAGView` with a rawfile PAG file. libpag has no
 *      playback speed on HarmonyOS, so the player drives the progress itself (`setProgress` + `flush` on a timer): speed,
 *      loop, any progress and the end of a pass. `CYLAnimatedItemPAG.register()` once makes every `CYLAnimatedItemView`
 *      without an `animationBuilder` play PAG files. libpag's native library is arm64-only: on an x86_64 emulator the type
 *      does not play (still image) unless the debug engine kit is installed (README "x86_64 emulator"). Moved from
 *      CollectionViewClassifyMenu's example (`CYLPAGPlayer`, `CYLPAGIconView`; cyltabbar had no PAG engine).
 * [CN] CYLAnimatedItemView 的 PAG 引擎（@tencent/libpag）：libpag 的 `PAGView` 与 rawfile 中的 PAG 文件。鸿蒙上 libpag 没有播放速度，因此播放器
 *      自行推进进度（定时调用 `setProgress` + `flush`）：速度、循环、任意进度与一遍结束。调用一次 `CYLAnimatedItemPAG.register()` 后，所有未传入
 *      `animationBuilder` 的 `CYLAnimatedItemView` 都播放 PAG 文件。libpag 的原生库只有 arm64：x86_64 模拟器上该类型不播放（显示静态图片），除非
 *      安装了调试引擎包。从 CollectionViewClassifyMenu 示例迁移而来（cyltabbar 没有 PAG 引擎）。
 */
import { PAGFile, PAGView, PAGViewController } from '@tencent/libpag';
import {
  CYLAnimatedItemEngineBinding, CYLAnimatedItemEngineState, CYLAnimatedItemEngineViews, CYLAnimatedItemSource,
  CYLAnimatedItemTimedPlayer,
  CYL_RESOURCE_DECODE_FAILED, CYL_RESOURCE_NOT_FOUND
} from 'cylanimateditem';

/**
 * [EN] The player of a PAG item: `pagController` is libpag's `PAGViewController`.
 * [CN] PAG 条目的播放器：`pagController` 为 libpag 的 `PAGViewController`。
 */
export class CYLAnimatedItemPAGPlayer extends CYLAnimatedItemTimedPlayer {
  readonly pagController: PAGViewController;

  constructor(source: CYLAnimatedItemSource, controller: PAGViewController) {
    super('PAG', source);
    this.pagController = controller;
  }

  protected get durationMs(): number {
    // [EN] libpag gives microseconds. [CN] libpag 返回微秒。
    return this.pagController.duration() / 1000;
  }

  protected render(): void {
    this.pagController.setProgress(this.progressValue);
    this.pagController.flush();
  }

  destroy(): void {
    super.destroy();
    this.pagController.release();
  }
}

/** [EN] The PAG engine view. [CN] PAG 引擎视图。 */
@Component
export struct CYLAnimatedItemPAGView {
  state: CYLAnimatedItemEngineState = new CYLAnimatedItemEngineState();
  private unlisten?: () => void;
  @State private controller: PAGViewController = new PAGViewController();
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
      this.controller = new PAGViewController();
      this.cylLoad();
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
    const file = PAGFile.LoadFromAssets(context.resourceManager, source.existingRawFilePath(context.resourceManager));
    if (file === null) {
      // [EN] No rawfile of that name: not found; a file PAG cannot open: decode failed. [CN] 没有该名称的 rawfile：not found；PAG 无法打开的文件：decode failed。
      this.binding.failed(this.state, source.rawFileContent(context.resourceManager) === undefined ? CYL_RESOURCE_NOT_FOUND : CYL_RESOURCE_DECODE_FAILED);
      return;
    }
    this.controller.setComposition(file);
    this.binding.ready(this.state, new CYLAnimatedItemPAGPlayer(source, this.controller));
  }

  build() {
    Stack() {
      PAGView({ controller: this.controller })
    }
    .width(this.state.width)
    .height(this.state.height)
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no')
  }
}

@Builder
function cylPAGEngineView(state: CYLAnimatedItemEngineState) {
  CYLAnimatedItemPAGView({ state: state })
}

/**
 * [EN] The PAG engine: `register()` once (for example in `EntryAbility.onCreate`). The type keeps its arm64-only ABI
 *      check (`CYLAnimatedItemEngines.isSupportedOnDevice('PAG')`).
 * [CN] PAG 引擎：调用一次 `register()`（例如在 `EntryAbility.onCreate` 中）。该类型保留 arm64 的 ABI 检查。
 */
export class CYLAnimatedItemPAG {
  static register(): void {
    CYLAnimatedItemEngineViews.register('PAG', wrapBuilder(cylPAGEngineView));
  }
}
