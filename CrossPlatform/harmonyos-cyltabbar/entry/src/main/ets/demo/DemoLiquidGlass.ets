import { CYLLocalizedString } from 'cyltabbar';

/**
 * [EN] Item 8: the Home navigation bar's "LiquidGlass" button (CYLHomeViewController's bar button "LiquidGlass"): a tap
 *      builds a new Liquid Glass tab bar. One accessibility element.
 * [CN] 第 8 项：首页导航栏的「LiquidGlass」按钮：点击后重新创建液态玻璃 TabBar。整体为一个无障碍元素。
 */
@Component
export struct DemoLiquidGlassButton {
  onTap: () => void = () => {};

  build() {
    Text(CYLLocalizedString('LiquidGlass'))
      .fontSize(15)
      .fontColor('#007AFF')
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(12)
      .backgroundColor('#1F007AFF')
      .position({ left: 120 })
      .accessibilityText(CYLLocalizedString('LiquidGlass'))
      .accessibilityDescription(CYLLocalizedString('Liquid Glass液态玻璃'))
      .id('cyl-nav-liquid-glass')
      .onClick(() => this.onTap())
  }
}
