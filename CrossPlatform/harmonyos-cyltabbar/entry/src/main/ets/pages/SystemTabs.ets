import { CYLLocalizedString } from 'cyltabbar';
/**
 * [EN] Items 45 and 46: the system tab bar (ArkUI `Tabs` with a bottom `TabBar`, the HarmonyOS counterpart of UITabBar)
 *      with the same four tabs, a badge on Messages: the comparison page of "和系统 UITabBar 比较". The system bar has no
 *      plus button, so none is drawn; the row with another plus button opens AnotherTabBar in the Liquid Glass style.
 * [CN] 第 45、46 项：系统 TabBar（ArkUI `Tabs` 底部 TabBar，即鸿蒙上的 UITabBar），同样四个 Tab，消息带角标：「和系统 UITabBar 比较」
 *      的对比页面。系统 TabBar 不支持加号按钮，因此不绘制；带另一个加号按钮的一行打开液态玻璃风格的 AnotherTabBar。
 */
interface SystemTab {
  title: Resource;
  image: Resource;
  selectedImage: Resource;
}

@Entry
@Component
struct SystemTabs {
  @State current: number = 0;
  private tabs: SystemTab[] = [
    { title: $r('app.string.tab_home'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight') },
    { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight') },
    { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), selectedImage: $r('app.media.message_highlight') },
    { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight') },
  ];

  @Builder
  tabBarItem(index: number) {
    Column() {
      Badge({ count: index === 2 ? 12 : 0, position: BadgePosition.RightTop, style: { badgeSize: 16, fontSize: 10 } }) {
        Image(this.current === index ? this.tabs[index].selectedImage : this.tabs[index].image)
          .width(26)
          .height(26)
      }
      Text(this.tabs[index].title)
        .fontSize(10)
        .margin({ top: 3 })
        .fontColor(this.current === index ? '#007AFF' : '#808080')
    }
    .id(`cyl-system-tab-${index}`)
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('和系统 UITabBar 比较'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)

          // One line, ending with an ellipsis (UINavigationBar): long titles wrapped to two lines.

          .maxLines(1)

          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          // [EN] One line: long titles shrink to 12 fp, then end with an ellipsis (issue list #26). [CN] 单行：长标题缩小到 12 fp，再以省略号结尾（问题 #26）。
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
      .backgroundColor('#F8F8F8')

      Stack({ alignContent: Alignment.Bottom }) {
        Tabs({ barPosition: BarPosition.End, index: this.current }) {
          ForEach(this.tabs, (tab: SystemTab, index: number) => {
            TabContent() {
              // [EN] The selected tab's localized title (issue list row 32). [CN] 选中 Tab 的本地化标题（问题清单第 32 行）。
              Text(this.tabs[this.current].title)
                .fontSize(18)
                .id('cyl-system-tabs-label')
            }
            .tabBar(this.tabBarItem(index))
          }, (tab: SystemTab, index: number) => `${index}`)
        }
        .onChange((index: number) => {
          this.current = index;
        })

      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
