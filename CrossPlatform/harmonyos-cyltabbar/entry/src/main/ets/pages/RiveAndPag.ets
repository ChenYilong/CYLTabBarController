import { CYLAnimatedItemView, CYLLocalizedString } from 'cyltabbar';
import { CYLAnimatedItemRive } from 'cylanimateditem_rive';
import { CYLAnimatedItemPAG } from 'cylanimateditem_pag';

/**
 * [EN] "Rive and PAG": the menu button of the iOS Example (menu_button.riv, `isOpen`) and a PAG file, each as a CYLAnimatedItemView with the
 *      Rive and PAG engines registered, with and without a tint. A tint is a SRC_IN color layer over the engine view (an XComponent): the tinted
 *      items use `animationTint` in #RRGGBBAA. "Open" flips the selection of the menu button (hamburger <-> X); with "Loop" off a play
 *      must settle on the X or the hamburger, not snap. The PAG file is fetched by scripts/harmonyos-build.sh (scripts/fetch-animation-resources.py
 *      PAGResources), not kept in the repository: without it the PAG items show nothing, and the page says so. On the x86_64
 *      emulator the engines need the debug kit (`tools/cyl_hap_x86_64.py install`).
 * [CN] “Rive 与 PAG”：iOS Example 的菜单按钮（menu_button.riv，`isOpen`）与一个 PAG 文件，各作为注册了 Rive 与 PAG 引擎的 CYLAnimatedItemView，
 *      分别带与不带着色。着色是盖在引擎视图（XComponent）上的 SRC_IN 颜色层：着色的条目使用 #RRGGBBAA 的 `animationTint`。“开合”
 *      切换菜单按钮的选中状态（汉堡 <-> X）；“循环”关闭时，一次播放必须停在 X 或汉堡上，不能跳变。PAG 文件由 scripts/harmonyos-build.sh
 *      获取（scripts/fetch-animation-resources.py PAGResources），不保存在仓库中：没有它时 PAG 条目什么都不显示，页面会说明。
 *      x86_64 模拟器上引擎需要调试包（`tools/cyl_hap_x86_64.py install`）。
 */
const RIVE_MENU: string = 'rive/menu_button.riv#stateMachine=State%20Machine&input=isOpen';
const PAG_FILE: string = 'pag/demo.pag';
const TINT_RED: string = '#FF3B30FF';
const TINT_GREEN: string = '#34C759FF';

@Entry
@Component
struct RiveAndPag {
  @State open: boolean = false;
  @State loops: boolean = false;
  @State restartToken: number = 0;
  @State pagAvailable: boolean = true;

  aboutToAppear(): void {
    CYLAnimatedItemRive.register();
    CYLAnimatedItemPAG.register();
    try {
      const bytes = this.getUIContext().getHostContext()?.resourceManager.getRawFileContentSync(PAG_FILE);
      this.pagAvailable = bytes !== undefined && bytes.length > 0;
    } catch (e) {
      this.pagAvailable = false;
    }
  }

  @Builder
  caption(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor('#8A8A8E')
      .margin({ top: 24, bottom: 8 })
  }

  @Builder
  cell(id: string, url: string, tint: string, label: string) {
    Column({ space: 8 }) {
      CYLAnimatedItemView({
        isBare: true,
        animationUrl: url,
        iconSize: 72,
        isItemSelected: this.open,
        animationLoops: this.loops,
        animationRestartToken: this.restartToken,
        animationTint: tint,
      })
        .id(id)
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.cyl_label'))
    }
    .layoutWeight(1)
    .accessibilityGroup(true)
    .accessibilityText(label)
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('Rive and PAG'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      this.caption(CYLLocalizedString('Rive menu button (menu_button.riv, isOpen): plain and tinted'))
      Row() {
        this.cell('cyl-rive-menu-button', RIVE_MENU, '', CYLLocalizedString('plain'))
        this.cell('cyl-rive-menu-button-tint', RIVE_MENU, TINT_RED, CYLLocalizedString('tint #FF3B30FF'))
      }
      .width('100%')

      this.caption(CYLLocalizedString('PAG file: plain and tinted'))
      Row() {
        this.cell('cyl-pag-plain', PAG_FILE, '', CYLLocalizedString('plain'))
        this.cell('cyl-pag-tint', PAG_FILE, TINT_GREEN, CYLLocalizedString('tint #34C759FF'))
      }
      .width('100%')
      if (!this.pagAvailable) {
        Text(CYLLocalizedString('pag/demo.pag is missing: run scripts/fetch-animation-resources.py PAGResources, then build again'))
          .fontSize(12)
          .fontColor('#FF3B30')
          .margin({ top: 8 })
          .id('cyl-pag-missing')
      }

      Row({ space: 16 }) {
        Button(this.open ? CYLLocalizedString('Open: on') : CYLLocalizedString('Open: off'))
          .id('cyl-rive-toggle-open')
          .onClick(() => {
            this.open = !this.open;
          })
        Button(CYLLocalizedString('Replay'))
          .id('cyl-rive-replay')
          .onClick(() => {
            this.restartToken += 1;
          })
      }
      .margin({ top: 32 })

      Row() {
        Text(this.loops ? CYLLocalizedString('Loop: on') : CYLLocalizedString('Loop: off'))
          .fontSize(15)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.loops })
          .id('cyl-rive-loop')
          .onChange((isOn: boolean) => {
            this.loops = isOn;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24 })
      .accessibilityGroup(true)
      .accessibilityText(this.loops ? CYLLocalizedString('Loop: on') : CYLLocalizedString('Loop: off'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.cyl_grouped_background'))
  }
}
