import { CYLLocalizedString } from 'cyltabbar';

/**
 * [EN] The random colors of the "Flat Design" button's breathing dot (the Objective-C Example's `-showBadge` with a
 *      random `cylBadgeBackgroundColor`). [CN] 「Flat Design」按钮呼吸红点的随机颜色。
 */
const DEMO_DOT_COLORS: string[] = ['#FF3B30', '#FF9500', '#34C759', '#007AFF', '#AF52DE', '#FF2D55'];

/**
 * [EN] Item 7: the Home navigation bar's "Flat Design" button (CYLHomeViewController's left bar button): the title and a
 *      breathing dot in a random color; a tap replaces the tab bar with a new FlatDesign one. One accessibility element,
 *      read "Flat Design, button. Double tap to use the FlatDesign tab bar".
 * [CN] 第 7 项：首页导航栏的「Flat Design」按钮（CYLHomeViewController 的左侧按钮）：标题与随机颜色的呼吸红点；点击后用新的扁平样式
 *      TabBar 替换当前 TabBar。整体为一个无障碍元素。
 */
@Component
export struct DemoFlatDesignButton {
  onTap: () => void = () => {};
  @State private dotOpacity: number = 1;
  private dotColor: string = DEMO_DOT_COLORS[Math.floor(Math.random() * DEMO_DOT_COLORS.length)];

  build() {
    Row({ space: 4 }) {
      Text(CYLLocalizedString('FlatDesign'))
        .fontSize(13)
        .fontColor('#007AFF')
      Circle()
        .width(8)
        .height(8)
        .fill(this.dotColor)
        .opacity(this.dotOpacity)
        .accessibilityLevel('no')
        .onAppear(() => {
          // [EN] `CYLBadgeAnimationTypeBreathe`: fades in and out without end. [CN] 呼吸动画：无限次淡入淡出。
          this.getUIContext().animateTo({ duration: 1200, iterations: -1, playMode: PlayMode.Alternate }, () => {
            this.dotOpacity = 0.2;
          });
        })
    }
    .accessibilityGroup(true)
    .accessibilityText(CYLLocalizedString('FlatDesign'))
    .accessibilityDescription(CYLLocalizedString('FlatDesign扁平设计样式'))
    .id('cyl-nav-flat-design')
    .onClick(() => this.onTap())
  }
}
