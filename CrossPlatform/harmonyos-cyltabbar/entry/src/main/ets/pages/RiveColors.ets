import { CYLAnimatedItemView, CYLLocalizedString } from 'cyltabbar';
import { CYLAnimatedItemPlayer } from 'cylanimateditem';
import { CYLAnimatedItemRive } from 'cylanimateditem_rive';

/**
 * [EN] The data-bound .riv that ships in @ohos/rive 1.0.4's rawfile (Rive's runtime test file, MIT): artboard-1 fills its
 *      rectangle from the color property `color` of its default view model (vm1).
 * [CN] @ohos/rive 1.0.4 的 rawfile 自带的数据绑定 .riv（Rive 运行时的测试文件，MIT）：artboard-1 用其默认视图模型（vm1）的颜色属性 `color` 填充矩形。
 */
const CYL_RIVE_COLORS_URL: string = 'data_binding_test.riv#artboard=artboard-1';
const CYL_RIVE_COLORS_PROPERTY: string = 'color';
const CYL_RIVE_COLORS_RED: string = '#FF3B30';
const CYL_RIVE_COLORS_BLUE: string = '#007AFF';

/**
 * [EN] Rive colors (docs/Animated-Item.md, "Colors"): a CYLAnimatedItemView playing a data-bound .riv. "Red" and "Blue" call
 *      the player's `applyColors` with view model property path -> color; "File's colors" passes undefined, which restores
 *      the file's own color. The device check of the Rive colors hook.
 * [CN] Rive 颜色（docs/Animated-Item.md，“颜色”）：播放数据绑定 .riv 的 CYLAnimatedItemView。“红色”与“蓝色”以视图模型属性路径 -> 颜色调用
 *      播放器的 `applyColors`；“文件颜色”传入 undefined，恢复文件自身的颜色。Rive 颜色钩子的真机检查。
 */
@Entry
@Component
struct RiveColors {
  @State colorText: string = '';
  private player: CYLAnimatedItemPlayer | undefined = undefined;

  aboutToAppear(): void {
    CYLAnimatedItemRive.register();
  }

  private applyColor(color: string | undefined): void {
    this.colorText = color ?? '';
    const player = this.player;
    if (player === undefined || !player.supportsColors) {
      return;
    }
    player.applyColors(color === undefined ? undefined : new Map<string, string>([[CYL_RIVE_COLORS_PROPERTY, color]]));
  }

  @Builder
  colorButton(title: string, id: string, color: string | undefined) {
    Button(title)
      .margin({ left: 6, right: 6 })
      .id(id)
      .accessibilityText(title)
      .onClick(() => this.applyColor(color))
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('Rive colors'))
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

      CYLAnimatedItemView({
        isBare: true,
        image: $r('app.media.home_highlight'),
        animationUrl: CYL_RIVE_COLORS_URL,
        iconSize: 200,
        isItemSelected: true,
        onAnimationPlayer: (player: CYLAnimatedItemPlayer | undefined) => {
          this.player = player;
          if (player !== undefined && this.colorText.length > 0) {
            this.applyColor(this.colorText);
          }
        },
      })
        .margin({ top: 32 })
        .id('cyl-rive-colors-item')
        .accessibilityGroup(true)
        .accessibilityText(CYLLocalizedString('Rive colors'))

      Text(this.colorText.length > 0 ? CYLLocalizedString('Color: %@', this.colorText)
        : CYLLocalizedString('The file\'s colors'))
        .fontSize(15)
        .margin({ top: 24 })
        .id('cyl-rive-colors-state')

      Row() {
        this.colorButton(CYLLocalizedString('Red'), 'cyl-rive-colors-red', CYL_RIVE_COLORS_RED)
        this.colorButton(CYLLocalizedString('Blue'), 'cyl-rive-colors-blue', CYL_RIVE_COLORS_BLUE)
        this.colorButton(CYLLocalizedString('The file\'s colors'), 'cyl-rive-colors-reset', undefined)
      }
      .margin({ top: 24 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.cyl_grouped_background'))
  }
}
