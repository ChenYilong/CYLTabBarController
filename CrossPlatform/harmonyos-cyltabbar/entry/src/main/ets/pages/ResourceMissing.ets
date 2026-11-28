import {
  CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines, CYLAnimatedItemView, CYLLocalizedString, CYLLottieIcon
} from 'cyltabbar';
import { CYLAnimatedItemRive } from 'cylanimateditem_rive';

/**
 * [EN] `onResourceMissing` and `CYLAnimatedItemEngines.resourceMissingListener` (docs/Animated-Item.md): one CYLAnimatedItemView
 *      per file type, each pointed at a file that does not exist. SVGA, Lottie and Rive have their engine registered (SVGA by
 *      cyltabbar by default), so the engine reports the missing file ("not found"); GIF and PAG have none registered here, so the
 *      item reports "engine library missing"; a file of no known type reports "decode failed". Each line shows the item callback
 *      and the global listener.
 * [CN] `onResourceMissing` 与 `CYLAnimatedItemEngines.resourceMissingListener`（docs/Animated-Item.md）：每种文件类型一个
 *      CYLAnimatedItemView，各指向一个不存在的文件。SVGA（cyltabbar 默认注册）、Lottie 与 Rive 已注册引擎，由引擎报告文件缺失（"not found"）；
 *      GIF、PAG 在此没有注册，条目报告 "engine library missing"；不属于任何已知类型的文件报告 "decode failed"。每一行显示条目回调与全局监听。
 */
const CYL_MISSING_FILES: string[] = [
  'missing/cyl_missing.gif',
  'missing/cyl_missing.svga',
  'missing/cyl_missing.pag',
  'missing/cyl_missing.json',
  'missing/cyl_missing.riv',
  'missing/cyl_missing.xyz',
];

@Entry
@Component
struct ResourceMissing {
  @State itemLines: string[] = [];
  @State globalLines: string[] = [];

  aboutToAppear(): void {
    CYLAnimatedItemEngines.register('Lottie');
    CYLAnimatedItemRive.register();
    CYLAnimatedItemEngines.resourceMissingListener = (resource: string, reason: string) => {
      this.note(false, `${resource}: ${reason}`);
    };
  }

  /**
   * [EN] The items call back while the page is still being built; a state change during the build is ignored, so it is deferred.
   * [CN] 条目在页面构建期间回调；构建期间的状态变化会被忽略，所以延后一拍。
   */
  private note(item: boolean, text: string): void {
    setTimeout(() => {
      if (item) {
        this.itemLines = this.itemLines.concat([text]);
      } else {
        this.globalLines = this.globalLines.concat([text]);
      }
    }, 0);
  }

  aboutToDisappear(): void {
    CYLAnimatedItemEngines.resourceMissingListener = undefined;
  }

  @Builder
  engine(context: CYLAnimatedItemAnimationContext) {
    CYLLottieIcon({
      path: context.url,
      iconSize: context.size,
      speed: context.speed,
      selected: context.selected,
      replayToken: context.restartToken,
      loops: context.loops,
      registerReplay: (replay: () => void) => context.setRestartHandler(replay),
      onLoaded: () => context.onLoaded(),
      onEnded: () => context.onEnded(),
      onLoadError: (_message: string) => context.onFailed('not found'),
    })
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text('onResourceMissing')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      Row() {
        ForEach(CYL_MISSING_FILES, (file: string) => {
          CYLAnimatedItemView({
            isBare: true,
            image: $r('app.media.home_highlight'),
            animationUrl: file,
            iconSize: 40,
            isItemSelected: true,
            onResourceMissing: (resource: string, reason: string) => {
              this.note(true, `${resource}: ${reason}`);
            },
            animationBuilder: (context: CYLAnimatedItemAnimationContext) => {
              this.engine(context)
            },
          })
            .margin({ left: 6, right: 6 })
        }, (file: string) => file)
      }
      .margin({ top: 24 })

      // [EN] Inline, not an @Builder with plain parameters: a builder does not refresh when these lists change. [CN] 内联而不是带普通参数的 @Builder：列表变化时 builder 不会刷新。
      Text('onResourceMissing')
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ top: 16 })
      ForEach(this.itemLines, (value: string, index: number) => {
        Text(value)
          .fontSize(13)
          .margin({ top: 2 })
          .id(`cyl-missing-item-${index}`)
      }, (value: string, index: number) => `item-${index}-${value}`)

      Text('resourceMissingListener')
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ top: 16 })
      ForEach(this.globalLines, (value: string, index: number) => {
        Text(value)
          .fontSize(13)
          .margin({ top: 2 })
          .id(`cyl-missing-global-${index}`)
      }, (value: string, index: number) => `global-${index}-${value}`)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.cyl_grouped_background'))
  }
}
