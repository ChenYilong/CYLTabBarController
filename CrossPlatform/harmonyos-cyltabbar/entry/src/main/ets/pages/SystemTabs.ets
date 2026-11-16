import { CYLLocalizedString } from 'cyltabbar';
/**
 * [EN] Items 45 and 46: the system tab bar (ArkUI `Tabs` with a bottom `TabBar`, the HarmonyOS counterpart of UITabBar)
 *      with the same four tabs, a badge on Messages; `withPlus` adds another plus button: the system bar has none, so a
 *      floating button stands in (as the Android port's FloatingActionButton).
 * [CN] 第 45、46 项：系统 TabBar（ArkUI `Tabs` 底部 TabBar，即鸿蒙上的 UITabBar），同样四个 Tab，消息带角标；`withPlus` 加上另一个
 *      PlusButton：系统 TabBar 没有加号按钮，因此用悬浮按钮代替（与 Android 端的 FloatingActionButton 相同）。
 */
/**
 * [EN] The plus button's bottom margin (vp) in the Stack that ends above the gesture bar: its center sits about 14 vp
 *      above the tab icons' center line, so the button bulges over the bar's top edge (measured on the Mate-class
 *      emulator, 2026-11-16: 48 left it 40 vp above the icons).
 * [CN] 加号按钮在 Stack（底边位于手势条之上）中的下边距（vp）：其中心比 Tab 图标中心线高约 14 vp，使按钮凸出 TabBar 上沿
 *      （2026-11-16 在模拟器上测量：48 时比图标高 40 vp）。
 */
const CYL_SYSTEM_PLUS_BOTTOM: number = 18;

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
  /**
   * [EN] What the page shows: the selected tab's title (localized, issue list row 32), or the plus button's name after a tap.
   * [CN] 页面显示的内容：选中 Tab 的标题（已本地化，问题清单第 32 行），点按加号按钮后为其名称。
   */
  @State plusTapped: boolean = false;
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
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(this.withPlus ? CYLLocalizedString('Push To 系统 UITabBarController（另一个 PlusButton）') : CYLLocalizedString('和系统 UITabBar 比较'))
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

      Stack({ alignContent: Alignment.Bottom }) {
        Tabs({ barPosition: BarPosition.End, index: this.current }) {
          ForEach(this.tabs, (tab: SystemTab, index: number) => {
            TabContent() {
              Text(this.plusTapped ? CYLLocalizedString('Another plus button') : this.tabs[this.current].title)
                .fontSize(18)
                .id('cyl-system-tabs-label')
            }
            .tabBar(this.tabBarItem(index))
          }, (tab: SystemTab, index: number) => `${index}`)
        }
        .onChange((index: number) => {
          this.current = index;
          this.plusTapped = false;
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
          // [EN] FIX (screenshot of 2026-11-16): the plus button sits in the bar's middle slot (with four equal tabs the
          //      gap between Nearby and Messages is the bar's center) and bulges above the bar, as the raised plus button
          //      of the examples (AGENTS.md); it used to float 80 vp up, over the page. CYL_SYSTEM_PLUS_BOTTOM puts its
          //      center about 14 vp above the tab icons.
          // [CN] 修复（2026-11-16 截图）：加号按钮位于 TabBar 中间（四个等宽 Tab 时，同城与消息之间即为中心），并凸出 TabBar 上沿，
          //      与示例的凸起加号按钮相同（AGENTS.md）；此前悬浮在 80 vp 高处、压在页面上。CYL_SYSTEM_PLUS_BOTTOM 使其中心比 Tab 图标
          //      高约 14 vp。
          .margin({ bottom: CYL_SYSTEM_PLUS_BOTTOM })
          .accessibilityText(CYLLocalizedString('Another plus button'))
          .id('cyl-system-plus')
          .onClick(() => {
            this.plusTapped = true;
          })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
