import { router } from '@kit.ArkUI';
import { CYLLocalizedString } from 'cyltabbar';
import { CYLGlassDock, CYLGlassDockController, CYLGlassDockTab } from '../demo/CYLGlassDock';

/**
 * [EN] One colorful card behind the glass, so the see-through effect is visible. [CN] 玻璃后面的一张彩色卡片，用来展示透视效果。
 */
interface CYLGlassCard {
  title: string;
  colors: string[];
}

/**
 * [EN] Example page: the glass dock of harmonyos-liquid-glass-tabbar (CYLGlassDock) over colorful, scrolling content. Scroll
 *      with a finger to minimize the dock, scroll back or tap a ball to expand it; the moon button switches dark and light.
 *      The library's own Liquid Glass (CYLTabBarStyleType.LiquidGlass) keeps the iOS style; this page only shows the reference's
 *      glass. Pushed from the 同城 tab (row 液态玻璃：参考工程的透视效果).
 * [CN] 示例页：harmonyos-liquid-glass-tabbar 的玻璃底栏（CYLGlassDock）悬浮在彩色可滚动内容之上。手指滚动缩小底栏，反向滚动或点按球展开；
 *      月亮按钮切换深浅色。库自身的液态玻璃（CYLTabBarStyleType.LiquidGlass）保持 iOS 样式；本页只展示参考工程的玻璃。从「同城」Tab 推入。
 */
@Entry
@Component
struct LiquidGlassDock {
  private dockController: CYLGlassDockController = new CYLGlassDockController();
  private tabs: CYLGlassDockTab[] = [
    { key: 'home', label: CYLLocalizedString('首页'), icon: $r('app.media.home_normal'), selectedIcon: $r('app.media.home_highlight') },
    { key: 'city', label: CYLLocalizedString('同城'), icon: $r('app.media.fishpond_normal'), selectedIcon: $r('app.media.fishpond_highlight') },
    { key: 'message', label: CYLLocalizedString('消息'), icon: $r('app.media.message_normal'), selectedIcon: $r('app.media.message_highlight') },
    { key: 'me', label: CYLLocalizedString('我的'), icon: $r('app.media.account_normal'), selectedIcon: $r('app.media.account_highlight') },
  ];
  private cards: CYLGlassCard[] = [
    { title: 'Sunset', colors: ['#FF9A3C', '#FF3C6E'] }, { title: 'Ocean', colors: ['#00C6FB', '#005BEA'] },
    { title: 'Forest', colors: ['#43E97B', '#38A169'] }, { title: 'Grape', colors: ['#B465DA', '#6A3093'] },
    { title: 'Lemon', colors: ['#F9F047', '#F7B733'] }, { title: 'Coral', colors: ['#FF7EB3', '#FF758C'] },
    { title: 'Night', colors: ['#2C3E50', '#4CA1AF'] }, { title: 'Peach', colors: ['#FFB88C', '#DE6262'] },
    { title: 'Mint', colors: ['#A8E063', '#56AB2F'] }, { title: 'Sky', colors: ['#89F7FE', '#66A6FF'] },
    { title: 'Berry', colors: ['#F857A6', '#FF5858'] }, { title: 'Ink', colors: ['#434343', '#000000'] },
  ];
  @State selectedIndex: number = 0;
  @State playing: boolean = true;
  @State dark: boolean = true;

  @Builder
  card(item: CYLGlassCard) {
    Column() {
      Text(item.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      Image($r('app.media.home_select_cover'))
        .width(56)
        .height(56)
        .margin({ top: 12 })
    }
    .width('47%')
    .height(170)
    .borderRadius(18)
    .justifyContent(FlexAlign.Center)
    .linearGradient({ angle: 135, colors: [[item.colors[0], 0], [item.colors[1], 1]] })
    .margin({ bottom: 14 })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text(`‹ ${CYLLocalizedString('Back')}`)
            .fontSize(16)
            .fontColor('#0A84FF')
            .id('cyl-back')
            .onClick(() => router.back())
          Text(CYLLocalizedString('Liquid Glass (reference)'))
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.dark ? Color.White : Color.Black)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          SymbolGlyph(this.dark ? $r('sys.symbol.sun_max') : $r('sys.symbol.moon'))
            .fontSize(20)
            .fontColor(['#0A84FF'])
            .accessibilityText(CYLLocalizedString('Dark mode'))
            .id('cyl-glass-dock-dark')
            .onClick(() => {
              this.dark = !this.dark;
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })

        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(this.cards, (item: CYLGlassCard) => {
              this.card(item)
            }, (item: CYLGlassCard) => item.title)
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 180 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .onDidScroll((_x: number, y: number) => this.dockController.notifyScrollDelta(y))
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.dockController.notifyTouch(true);
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.dockController.notifyTouch(false);
          }
        })
        .id('cyl-glass-dock-page')
      }
      .width('100%')
      .height('100%')

      CYLGlassDock({
        controller: this.dockController,
        tabs: this.tabs,
        selectedIndex: this.selectedIndex,
        onTabChange: (index: number) => {
          this.selectedIndex = index;
        },
        songTitle: CYLLocalizedString('LiquidGlass'),
        songArtist: 'harmonyos-liquid-glass-tabbar',
        songCover: $r('app.media.home_select_cover'),
        isPlaying: this.playing,
        onPlayPause: () => {
          this.playing = !this.playing;
        },
        dark: this.dark,
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.dark ? Color.Black : '#F2F2F7')
  }
}
