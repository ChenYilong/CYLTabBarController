import { CYLAnimatedItemView, CYLLocalizedString } from 'cyltabbar';
import { CYLAnimatedItemBackgroundStyle } from 'cylanimateditem';

/**
 * [EN] `itemContentHorizontalInset` left unset (docs/Animated-Item.md): the space between an item's content and the edge of its background.
 *      Unset it is the library's default for the style: a glass item gets the glass content inset, a flat item none. Four items, flat and
 *      Liquid Glass, normal and selected, each with an icon and a title, so the screenshots show the default inset of every case.
 * [CN] 未设置 `itemContentHorizontalInset`（docs/Animated-Item.md）：条目内容与其背景边缘的间距。未设置时为该样式的库默认值：玻璃条目使用玻璃内容
 *      间距，扁平条目没有。四个条目：扁平与液态玻璃，常态与选中，各带图标与标题，截图显示每种情况的默认间距。
 */
@Entry
@Component
struct ContentInset {
  @Builder
  cell(id: string, style: CYLAnimatedItemBackgroundStyle, selected: boolean, label: string) {
    Column({ space: 8 }) {
      CYLAnimatedItemView({
        itemTitle: label,
        image: $r('app.media.fishpond_normal'),
        iconSize: 24,
        isItemSelected: selected,
        itemBackgroundStyle: style,
        itemBackgroundColor: style === CYLAnimatedItemBackgroundStyle.flat ? '#E5E5EA' : '',
        itemCornerRadius: 22,
      })
        .id(id)
    }
    .layoutWeight(1)
    .accessibilityGroup(true)
    .accessibilityText(label)
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('Content inset'))
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

      Text(CYLLocalizedString('Flat: itemContentHorizontalInset unset'))
        .fontSize(13)
        .fontColor('#3C3C43')
        .margin({ top: 24, bottom: 12 })
      Row() {
        this.cell('cyl-inset-flat-normal', CYLAnimatedItemBackgroundStyle.flat, false, CYLLocalizedString('Normal'))
        this.cell('cyl-inset-flat-selected', CYLAnimatedItemBackgroundStyle.flat, true, CYLLocalizedString('Selected'))
      }
      .width('100%')

      Text(CYLLocalizedString('Liquid Glass: itemContentHorizontalInset unset'))
        .fontSize(13)
        .fontColor('#3C3C43')
        .margin({ top: 32, bottom: 12 })
      Row() {
        this.cell('cyl-inset-glass-normal', CYLAnimatedItemBackgroundStyle.liquidGlass, false, CYLLocalizedString('Normal'))
        this.cell('cyl-inset-glass-selected', CYLAnimatedItemBackgroundStyle.liquidGlass, true, CYLLocalizedString('Selected'))
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 160, colors: [['#FFB199', 0], ['#7EC8E3', 0.5], ['#C3AED6', 1]] })
  }
}
