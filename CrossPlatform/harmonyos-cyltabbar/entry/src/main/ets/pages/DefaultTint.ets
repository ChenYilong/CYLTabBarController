import {
  CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines, CYLAnimatedItemView, CYLLocalizedString, CYLLottieIcon
} from 'cyltabbar';

/**
 * [EN] The built-in default tint (docs/Animated-Item.md, "Tint"): four CYLAnimatedItemView with no tint property set. A file detected as
 *      one color (the camera) is drawn in the built-in color of its state and color mode (normal: the label color, selected: the system accent),
 *      so it stays visible in dark mode; a multi-color file keeps its own colors. Open it with `cylScreen default-tint`, in dark mode
 *      with `--ps cylColorMode dark`.
 * [CN] 内置默认着色（docs/Animated-Item.md，“Tint”）：四个未设置任何着色属性的 CYLAnimatedItemView。被识别为单色的文件（相机）按其状态与颜色模式
 *      使用内置颜色（常态：标签色，选中：系统强调色），因此在深色模式下仍然可见；多色文件保持自身颜色。用 `cylScreen default-tint` 打开，
 *      深色模式加 `--ps cylColorMode dark`。
 */
@Entry
@Component
struct DefaultTint {
  aboutToAppear(): void {
    CYLAnimatedItemEngines.register('Lottie');
  }

  @Builder
  engine(context: CYLAnimatedItemAnimationContext) {
    CYLLottieIcon({
      path: context.url,
      iconSize: context.size,
      speed: context.speed,
      selected: context.selected,
      replayToken: context.restartToken,
      loops: true,
      registerReplay: (replay: () => void) => context.setRestartHandler(replay),
      onLoaded: () => context.onLoaded(),
      onEnded: () => context.onEnded(),
      onLoadError: (_message: string) => context.onFailed(),
    })
  }

  @Builder
  item(id: string, url: string, selected: boolean, caption: string) {
    Column({ space: 8 }) {
      CYLAnimatedItemView({
        isBare: true,
        animationUrl: url,
        iconSize: 64,
        isItemSelected: selected,
        animationBuilder: (context: CYLAnimatedItemAnimationContext) => {
          this.engine(context)
        },
      })
        .id(id)
      Text(caption)
        .fontSize(13)
        .fontColor($r('app.color.cyl_label'))
    }
    .layoutWeight(1)
    .accessibilityGroup(true)
    .accessibilityText(caption)
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('Default tint'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      Text(CYLLocalizedString('One color file: the built-in tint'))
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ top: 24, bottom: 12 })
      Row() {
        this.item('cyl-default-tint-one-normal', 'lottie/default_tint_one_color.json', false, CYLLocalizedString('normal'))
        this.item('cyl-default-tint-one-selected', 'lottie/default_tint_one_color.json', true, CYLLocalizedString('selected'))
      }
      .width('100%')

      Text(CYLLocalizedString('Multi-color file: its own colors'))
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ top: 32, bottom: 12 })
      Row() {
        this.item('cyl-default-tint-multi-normal', 'lottie/default_tint_multi_color.json', false, CYLLocalizedString('normal'))
        this.item('cyl-default-tint-multi-selected', 'lottie/default_tint_multi_color.json', true, CYLLocalizedString('selected'))
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.cyl_grouped_background'))
  }
}
