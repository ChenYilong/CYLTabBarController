import { CYLPlusButton, CYLTabBarController, CYLTabBarItem, cylLocalizedString, cylResolveText } from 'cyltabbar';

/**
 * [EN] The demo: the tabs of the Objective-C example (Home, Nearby, Messages with a badge, Me with a dot) and a plus button
 *      "Post", every text from string resources copied from CYLTabBarController's localization files.
 * [CN] 演示：Objective-C 示例的 Tab（首页、同城、带角标的消息、带红点的我的）与 PlusButton「发布」，所有文字来自从 CYLTabBarController
 *      本地化文件复制来的字符串资源。
 */
function cylDemoItems(): CYLTabBarItem[] {
  const home = new CYLTabBarItem('home', $r('app.string.cyl_demo_home'), $r('sys.symbol.house'), $r('sys.symbol.house_fill'));
  const nearby = new CYLTabBarItem('nearby', $r('app.string.cyl_demo_nearby'), $r('sys.symbol.map'));
  const messages = new CYLTabBarItem('messages', $r('app.string.cyl_demo_messages'), $r('sys.symbol.message'), $r('sys.symbol.message_fill'));
  messages.badgeValue = '3';
  const me = new CYLTabBarItem('me', $r('app.string.cyl_demo_me'), $r('sys.symbol.person'));
  me.badgeValue = '';
  // [EN] FIX: issue #415: SVGA tab icons (resources/rawfile/svga, copied from Example-SwiftUI-Rive by scripts/sync-svga.py);
  //      the symbols show if a file cannot load. [CN] SVGA Tab 图标（resources/rawfile/svga，由 scripts/sync-svga.py 从
  //      Example-SwiftUI-Rive 复制）；文件无法加载时显示符号图标。
  home.svgaFilePath = 'svga/tab_home.svga';
  nearby.svgaFilePath = 'svga/tab_search.svga';
  messages.svgaFilePath = 'svga/tab_chat.svga';
  me.svgaFilePath = 'svga/tab_profile.svga';
  return [home, nearby, messages, me];
}

function cylDemoPlusButton(): CYLPlusButton {
  const plus = new CYLPlusButton();
  plus.identifier = 'CYLPlusButton';
  plus.image = $r('sys.symbol.plus_circle_fill');
  plus.title = $r('app.string.cyl_demo_post');
  return plus;
}

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State items: CYLTabBarItem[] = cylDemoItems();
  @State plusTaps: number = 0;

  private pageTitle(index: number): string {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return '';
    }
    return cylLocalizedString(context, $r('app.string.cyl_demo_page').id, cylResolveText(context, this.items[index].title));
  }

  @Builder
  page(index: number) {
    Column() {
      Text(this.pageTitle(index))
        .fontSize(24)
        .id(`CYLDemoPage_${this.items[index].identifier}`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      CYLTabBarController({
        items: this.items,
        plusButton: cylDemoPlusButton(),
        selectedIndex: $selectedIndex,
        pageBuilder: (index: number) => {
          this.page(index)
        },
        onPlusButtonTap: () => {
          this.plusTaps += 1;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
