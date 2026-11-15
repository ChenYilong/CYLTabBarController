import { CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton } from 'cyltabbar';

/**
 * [EN] Item 47 and the Messages badge rows: a pushed CYLTabBarController of another context, with a square orange plus
 *      button (DemoCatalog.kt `squarePlus`, iOS CYLPlusButtonSubclass of another context).
 * [CN] 第 47 项与消息页角标行：push 另一个 context 的 CYLTabBarController，使用橙色方形加号按钮（DemoCatalog.kt `squarePlus`）。
 */
const ANOTHER_TABS: CYLTabBarItemAttributes[] = [
  { title: $r('app.string.tab_home'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight'), identifier: 'home' },
  { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), selectedImage: $r('app.media.message_highlight'), identifier: 'message' },
  { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight'), identifier: 'city' },
  { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight'), identifier: 'me' },
];

const SQUARE_PLUS: CYLPlusButton = {
  image: $r('app.media.square_plus'),
  imageSize: 40,
  centerYOffset: 0,
  identifier: 'SquarePlus',
};

@Entry
@Component
struct AnotherTabBar {
  @State selectedIndex: number = 0;
  @State taps: number = 0;

  @Builder
  page(index: number, identifier: string) {
    Column() {
      Text(`${identifier} · another context · plus taps: ${this.taps}`)
        .fontSize(16)
        .id(`cyl-another-page-${identifier}`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('‹ Back')
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text('Another plus button')
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

      CYLTabBarController({
        tabBarItemsAttributes: ANOTHER_TABS,
        plusButton: SQUARE_PLUS,
        selectedIndex: $selectedIndex,
        tintColor: '#FF9500',
        plusButtonAction: () => {
          this.taps += 1;
        },
        pageBuilder: (index: number, identifier: string) => {
          this.page(index, identifier)
        },
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
