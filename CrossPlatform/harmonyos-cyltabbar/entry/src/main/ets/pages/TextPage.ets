import { CYLLocalizedString } from 'cyltabbar';
/**
 * [EN] A pushed page with a colored background and a title (the CYLBaseViewController, CYLDetailsViewController and
 *      testPush pages the badge rows push; TextPageFragment.kt). `hidesNavigationBar` hides the bar (Discover).
 * [CN] 被 push 的页面：带背景色与标题（角标行 push 的 CYLBaseViewController、CYLDetailsViewController、testPush；TextPageFragment.kt）。
 *      `hidesNavigationBar` 隐藏导航栏（发现页）。
 */
interface TextPageParams {
  title: string;
  color: string;
  hidesNavigationBar?: boolean;
}

@Entry
@Component
struct TextPage {
  @State params: TextPageParams = { title: '', color: '#FFFFFF' };

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as TextPageParams;
    if (params !== undefined) {
      this.params = params;
    }
  }

  build() {
    Column() {
      if (this.params.hidesNavigationBar !== true) {
        Row() {
          Text('‹ ' + CYLLocalizedString('Back'))
            .fontSize(16)
            .fontColor('#007AFF')
            .id('cyl-back')
            .onClick(() => this.getUIContext().getRouter().back())
          Text(this.params.title)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)

            // One line, ending with an ellipsis (UINavigationBar): long titles wrapped to two lines.

            .maxLines(1)

            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 52 })
        }
        .height(44)
        .width('100%')
        .padding({ left: 12 })
        .backgroundColor('#F8F8F8')
      }
      Column() {
        Text(this.params.title)
          .fontSize(20)
          .fontColor(Color.White)
          .id('cyl-text-page-title')
        if (this.params.hidesNavigationBar === true) {
          Button(CYLLocalizedString('Back'))
            .margin({ top: 24 })
            .id('cyl-back')
            .onClick(() => this.getUIContext().getRouter().back())
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.params.color)
    }
    .width('100%')
    .height('100%')
  }
}
