import { CYLLocalizedString } from 'cyltabbar';
import { CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLTabBarStyleType } from 'cyltabbar';

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

interface AnotherTabBarParams {
  mode?: string;
  /**
   * [EN] 'liquidGlass': the system-style (Liquid Glass) tab bar of the row "Push To 系统 UITabBarController（另一个
   *      PlusButton）", as iOS (`+newLiquidGlassTabBarControllerWithPlusButtonClass:` with the other plus button class).
   * [CN] 'liquidGlass'：「Push To 系统 UITabBarController（另一个 PlusButton）」一行的系统风格（液态玻璃）TabBar，与 iOS 相同
   *      （`+newLiquidGlassTabBarControllerWithPlusButtonClass:`，使用另一个 PlusButton 类）。
   */
  style?: string;
}

const X_COLORS: string[] = ['#FF3B30', '#34C759', '#007AFF', '#AF52DE', '#FF9500'];

@Entry
@Component
struct AnotherTabBar {
  @State selectedIndex: number = 0;
  @State taps: number = 0;
  /**
   * [EN] '' square plus (item 47); 'same' the Example's plus button (item 52); 'close' the square plus with a tappable X
   *      (issue #202); 'late-*' the plus button image set 2 s later (item 31).
   * [CN] '' 方形加号；'same' 示例的加号；'close' 带可点击 X 的方形加号（issue #202）；'late-*' 2 秒后设置图片（第 31 项）。
   */
  @State mode: string = '';
  @State styleType: CYLTabBarStyleType = CYLTabBarStyleType.Default;
  @State plus: CYLPlusButton = SQUARE_PLUS;
  @State xColor: string = '#FF3B30';

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as AnotherTabBarParams;
    this.mode = params?.mode ?? '';
    this.styleType = params?.style === 'liquidGlass' ? CYLTabBarStyleType.LiquidGlass : CYLTabBarStyleType.Default;
    if (this.mode === 'same') {
      this.plus = { image: $r('app.media.post_normal'), selectedImage: $r('app.media.post_highlight'), title: $r('app.string.tab_post'), centerYOffset: -14, imageSize: 52, alignsTitle: true, identifier: 'plus' };
    } else if (this.mode.startsWith('late')) {
      this.plus = this.mode === 'late-load' || this.mode === 'late-background' ? { imageSize: 40, identifier: 'late' }
        : { image: $r('app.media.square_plus'), imageSize: 40, identifier: 'late' };
      setTimeout(() => {
        if (this.mode === 'late-load' || this.mode === 'late-replace') {
          this.plus = { image: $r('app.media.post_normal'), imageSize: 40, identifier: 'late' };
        } else if (this.mode === 'late-remove') {
          this.plus = { imageSize: 40, identifier: 'late' };
        } else {
          this.plus = { backgroundImage: $r('app.media.square_plus'), imageSize: 40, identifier: 'late' };
        }
      }, 2000);
    }
  }

  @Builder
  page(index: number, identifier: string) {
    Column() {
      Text(CYLLocalizedString('%@ · another context · plus taps: %@', identifier, this.taps))
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
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('Another plus button'))
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
      CYLTabBarController({
        tabBarStyleType: this.styleType,
        tabBarItemsAttributes: ANOTHER_TABS,
        plusButton: this.plus,
        selectedIndex: $selectedIndex,
        tintColor: '#FF9500',
        plusButtonAction: () => {
          this.taps += 1;
        },
        pageBuilder: (index: number, identifier: string) => {
          this.page(index, identifier)
        },
      })

      if (this.mode === 'close') {
        // [EN] Issue #202: a subview of the plus button that takes its own taps. [CN] 加号按钮上自己响应点击的子视图。
        Text('✕')
          .fontSize(12)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(this.xColor)
          .margin({ bottom: 36, left: 44 })
          .id('cyl-plus-close')
          .onClick(() => this.xColor = X_COLORS[Math.floor(Math.random() * X_COLORS.length)])
      }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
