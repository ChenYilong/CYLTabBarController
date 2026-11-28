import { CYLLocalizedString } from 'cyltabbar';
import {
  cyl_popSelectTabBarChildViewControllerAtIndex, cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier,
  cyl_pushViewController, cyl_pushOrPopToViewController
} from 'cyltabbar';

/**
 * [EN] Item 48: the cyl_pop / cyl_push methods (DemoPopPushFragment of the Android port): pushed above the tab bar, it
 *      goes back and selects a tab, pushes a page, or pushes-or-pops to a page already in the stack.
 * [CN] 第 48 项：cyl_pop / cyl_push 方法：在 TabBar 之上 push 的页面，可返回并选中某个 Tab、push 页面，或 push / 返回到栈中已有的页面。
 */
interface PushParams {
  title: string;
  color: string;
}

const GREEN_PAGE: PushParams = { title: 'cyl_pushViewController', color: '#34C759' };

@Entry
@Component
struct PopPushDemo {
  @State result: string = '';

  @Builder
  row(id: string, title: string, action: () => void) {
    Text(title)
      .fontSize(15)
      .width('100%')
      .padding(14)
      .backgroundColor(Color.White)
      .border({ width: { bottom: 0.5 }, color: { bottom: '#E5E5E5' } })
      .id(`cyl-row-pop-push-${id}`)
      .onClick(action)
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('cyl_pop / cyl_push 系列方法演示'))
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

      Column() {
        this.row('select-index', CYLLocalizedString('cyl_popSelectTabBarChildViewControllerAtIndex: 1 (%@)', CYLLocalizedString('同城')),
          () => cyl_popSelectTabBarChildViewControllerAtIndex(1))
        this.row('select-identifier', CYLLocalizedString('cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier: message'),
          () => cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier('message'))
        this.row('push', CYLLocalizedString('cyl_pushViewController: a green page'),
          () => cyl_pushViewController('pages/TextPage', GREEN_PAGE))
        this.row('push-or-pop', CYLLocalizedString('cyl_pushOrPopToViewController: pages/Index (already in the stack: pops)'),
          () => cyl_pushOrPopToViewController('pages/Index', undefined, (popped: boolean) => this.result = `popped: ${popped}`))
        Text(this.result)
          .fontSize(13)
          .fontColor('#8A8A8E')
          .padding(14)
          .id('cyl-pop-push-result')
      }
      .layoutWeight(1)
      .backgroundColor('#F2F2F7')
    }
    .width('100%')
    .height('100%')
  }
}
