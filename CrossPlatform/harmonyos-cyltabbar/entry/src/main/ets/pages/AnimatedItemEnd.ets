import {
  CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines, CYLAnimatedItemView, CYLLocalizedString, CYLLottieIcon
} from 'cyltabbar';

/**
 * [EN] `showsImageWhenAnimationEnds` (docs/Animated-Item.md, "Still image after the animation ends"): a CYLAnimatedItemView
 *      playing a Lottie file once; when lottie reports the end, the still image replaces the last frame. "Replay" plays it
 *      again, the switch turns the still image off, and the counter shows each `onAnimationEnd`.
 * [CN] `showsImageWhenAnimationEnds`（docs/Animated-Item.md，“动画结束后显示静态图片”）：只播放一次 Lottie 文件的 CYLAnimatedItemView；
 *      lottie 报告结束时，静态图片替换最后一帧。“重新播放”再次播放，开关关闭静态图片，计数显示每次 `onAnimationEnd`。
 */
@Entry
@Component
struct AnimatedItemEnd {
  @State showsImage: boolean = true;
  @State restartToken: number = 0;
  @State ended: number = 0;

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
      loops: context.loops,
      registerReplay: (replay: () => void) => context.setRestartHandler(replay),
      onLoaded: () => context.onLoaded(),
      onEnded: () => context.onEnded(),
      onLoadError: (_message: string) => context.onFailed(),
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
        Text(CYLLocalizedString('Still image after the animation ends'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .minFontSize(12)
          .maxFontSize(17)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      CYLAnimatedItemView({
        isBare: true,
        image: $r('app.media.home_highlight'),
        animationUrl: 'lottie/green_lottie_tab_home.json',
        iconSize: 96,
        isItemSelected: true,
        animationRestartToken: this.restartToken,
        showsImageWhenAnimationEnds: this.showsImage,
        onAnimationEnd: () => {
          this.ended += 1;
        },
        animationBuilder: (context: CYLAnimatedItemAnimationContext) => {
          this.engine(context)
        },
      })
        .margin({ top: 48 })
        .id('cyl-animated-item-end')
        .accessibilityGroup(true)
        .accessibilityText(CYLLocalizedString('Still image after the animation ends'))

      Text(CYLLocalizedString('Animation ended: %d').replace('%d', `${this.ended}`))
        .fontSize(15)
        .margin({ top: 24 })
        .id('cyl-animated-item-end-count')

      Button(CYLLocalizedString('Replay'))
        .margin({ top: 24 })
        .id('cyl-animated-item-end-replay')
        .accessibilityText(CYLLocalizedString('Replay'))
        .onClick(() => {
          this.restartToken += 1;
        })

      Row() {
        Text(this.showsImage ? CYLLocalizedString('Show the still image when it ends: on')
          : CYLLocalizedString('Show the still image when it ends: off'))
          .fontSize(15)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.showsImage })
          .onChange((isOn: boolean) => {
            this.showsImage = isOn;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24 })
      .id('cyl-animated-item-end-switch')
      .accessibilityGroup(true)
      .accessibilityText(this.showsImage ? CYLLocalizedString('Show the still image when it ends: on')
        : CYLLocalizedString('Show the still image when it ends: off'))
      .onClick(() => {
        this.showsImage = !this.showsImage;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.cyl_grouped_background'))
  }
}
