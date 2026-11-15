/**
 * [EN] Items 45 and 46: the system tab bar (ArkUI `Tabs` with a bottom `TabBar`, the HarmonyOS counterpart of UITabBar)
 *      with the same four tabs, a badge on Messages; `withPlus` adds another plus button: the system bar has none, so a
 *      floating button stands in (as the Android port's FloatingActionButton).
 * [CN] 第 45、46 项：系统 TabBar（ArkUI `Tabs` 底部 TabBar，即鸿蒙上的 UITabBar），同样四个 Tab，消息带角标；`withPlus` 加上另一个
 *      PlusButton：系统 TabBar 没有加号按钮，因此用悬浮按钮代替（与 Android 端的 FloatingActionButton 相同）。
 */
interface SystemTabsParams {
  withPlus?: boolean;
}

interface SystemTab {
  title: Resource;
  image: Resource;
  selectedImage: Resource;
}

@Entry
@Component
struct SystemTabs {
  @State current: number = 0;
  @State label: string = 'Home';
  @State withPlus: boolean = false;
  private tabs: SystemTab[] = [
    { title: $r('app.string.tab_home'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight') },
    { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight') },
    { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), selectedImage: $r('app.media.message_highlight') },
    { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight') },
  ];

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as SystemTabsParams;
    this.withPlus = params?.withPlus === true;
  }

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
        Text('‹ Back')
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(this.withPlus ? 'System tab bar' : 'Tabs (system tab bar)')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor('#F8F8F8')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Stack({ alignContent: Alignment.Bottom }) {
        Tabs({ barPosition: BarPosition.End, index: this.current }) {
          ForEach(this.tabs, (tab: SystemTab, index: number) => {
            TabContent() {
              Text(this.label)
                .fontSize(18)
                .id('cyl-system-tabs-label')
            }
            .tabBar(this.tabBarItem(index))
          }, (tab: SystemTab, index: number) => `${index}`)
        }
        .onChange((index: number) => {
          this.current = index;
          this.label = ['Home', 'Nearby', 'Messages', 'Me'][index];
        })

        if (this.withPlus) {
          Button({ type: ButtonType.Circle }) {
            Text('+')
              .fontSize(28)
              .fontColor(Color.White)
          }
          .width(52)
          .height(52)
          .backgroundColor('#FF9500')
          .margin({ bottom: 80 })
          .id('cyl-system-plus')
          .onClick(() => {
            this.label = 'PlusButton';
          })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
