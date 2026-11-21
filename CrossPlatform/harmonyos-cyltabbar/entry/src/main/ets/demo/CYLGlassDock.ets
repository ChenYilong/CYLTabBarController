/**
 * [EN] Example only (the library's Liquid Glass keeps the iOS style): a glass dock ported from harmonyos-liquid-glass-tabbar
 *      (https://github.com/DUDUXXR2/harmonyos-liquid-glass-tabbar, MIT, by DUDUXXR2, GlassDockBar.ets), to show its see-through
 *      Liquid Glass on HarmonyOS: a tab capsule, a search ball and a mini music bar, each its own glass, over the page; on a
 *      finger scroll the dock minimizes into one row of three shapes in one animateTo, and expands again.
 *      The reference paints the glass with HDS system material (API 24+). This example targets API 12 to 21, so the glass is
 *      the closest equivalent there: a strong, saturated background blur, a light or dark tint, a convex rim, a specular band,
 *      a light spot following the finger and a press swell. TODO: the system material and its refraction need SDK 6.1.1
 *      (API 24) and an API 24+ emulator image (docs/HarmonyOS-Liquid-Glass-Parity.md).
 * [CN] 仅用于示例（库的液态玻璃保持 iOS 样式）：移植自 harmonyos-liquid-glass-tabbar（https://github.com/DUDUXXR2/harmonyos-liquid-glass-tabbar，
 *      MIT，作者 DUDUXXR2，GlassDockBar.ets）的玻璃底栏，用来展示其在鸿蒙上的透视液态玻璃：页签胶囊、搜索球与迷你音乐条，各自独立的玻璃，
 *      悬浮在页面之上；手指滚动时底栏用一个 animateTo 收成一行三段，再展开。参考工程用 HDS 系统材质（API 24 起）。本示例面向 API 12 到 21，
 *      因此玻璃用其中最接近的效果：强且饱和的背景模糊、浅色或深色着色、立体描边、高光带、跟随手指的光斑与按压膨胀。TODO：系统材质及其折射需要
 *      SDK 6.1.1（API 24）与 API 24+ 的模拟器镜像（docs/HarmonyOS-Liquid-Glass-Parity.md）。
 */
import { curves } from '@kit.ArkUI';
import { CYLLocalizedString } from 'cyltabbar';

/**
 * [EN] The reference's DockBarTokens (vp). [CN] 参考工程的 DockBarTokens（vp）。
 */
export class CYLGlassDockTokens {
  static readonly BALL_DIAMETER: number = 56;
  static readonly TAB_SLOT_WIDTH: number = 62;
  static readonly TAB_ICON_SIZE: number = 24;
  static readonly TAB_LABEL_SIZE: number = 11;
  static readonly TAB_LABEL_GAP: number = 2;
  static readonly COLLAPSED_ICON_DY: number = 8;
  static readonly BAR_BOTTOM_MARGIN: number = 24;
  static readonly BAR_SIDE_MARGIN: number = 11;
  static readonly TAB_RIGHT_RESERVE: number = 63;
  static readonly MUSIC_BAR_HEIGHT_DOUBLE: number = 44;
  static readonly TAB_ROW_HEIGHT_DOUBLE: number = 56;
  static readonly ROW_HEIGHT_COLLAPSED: number = 42;
  static readonly COLLAPSED_EDGE_MARGIN: number = 22;
  static readonly COLLAPSED_GAP: number = 5;
  static readonly MUSIC_BOTTOM_EXPANDED: number = 92;
  static readonly MIN_BAR_SCROLL: number = 8;
  static readonly MORPH_DURATION: number = 300;
  static readonly SELECTED_COLOR: string = '#FF375F';
}

/**
 * [EN] One tab of the dock. [CN] 底栏的一个页签。
 */
export interface CYLGlassDockTab {
  key: string;
  label: string;
  icon: Resource;
  selectedIcon: Resource;
}

/**
 * [EN] The page tells the dock about scrolling and the finger (the reference's DockBarController).
 * [CN] 页面把滚动与手指状态报给底栏（参考工程的 DockBarController）。
 */
export class CYLGlassDockController {
  notifyScrollDelta: (delta: number) => void = (_delta: number) => {};
  notifyTouch: (down: boolean) => void = (_down: boolean) => {};
}

/**
 * [EN] The glass of every dock shape (API 21 equivalent of the reference's HDS material): a strong blur with boosted saturation,
 *      a translucent tint (light or dark), a soft material shadow; the radius makes a capsule or a ball.
 * [CN] 底栏每块玻璃的材质（参考工程 HDS 材质在 API 21 上的等价物）：强模糊并提高饱和度、半透明着色（浅色或深色）、柔和的材质阴影；圆角形成胶囊或球。
 */
export class CYLGlassSurfaceModifier implements AttributeModifier<RowAttribute> {
  height: number;
  dark: boolean;
  pressed: number;

  constructor(height: number, dark: boolean, pressed: number) {
    this.height = height;
    this.dark = dark;
    this.pressed = pressed;
  }

  applyNormalAttribute(instance: RowAttribute): void {
    instance.backgroundEffect({ radius: 48, saturation: 2.0, brightness: this.dark ? 0.8 : 1.12 });
    instance.backgroundColor(this.dark ? '#2E000000' : '#1AFFFFFF');
    instance.borderRadius(this.height / 2);
    instance.shadow({ radius: 24, color: this.dark ? '#59000000' : '#26000000', offsetY: 8 });
    instance.scale({ x: 1 + 0.03 * this.pressed, y: 1 + 0.03 * this.pressed });
  }
}

@Component
export struct CYLGlassDock {
  controller: CYLGlassDockController | null = null;
  tabs: CYLGlassDockTab[] = [];
  @Prop selectedIndex: number = 0;
  onTabChange: (index: number) => void = (_index: number) => {};
  @Prop songTitle: string = '';
  @Prop songArtist: string = '';
  songCover: ResourceStr = '';
  @Prop isPlaying: boolean = false;
  onPlayPause: () => void = () => {};
  onNext: () => void = () => {};
  onSearchClick: () => void = () => {};
  @Prop dark: boolean = false;

  @State private pageW: number = 0;
  @State private pageH: number = 0;
  @State private barCollapsed: boolean = false;
  @State private dockOnlySelected: boolean = false;
  /** [EN] Which shape is pressed (0 tabs, 1 ball, 2 music) and how much (spring). [CN] 按下的形状与按压程度（弹簧）。 */
  @State private pressedShape: number = -1;
  @State private pressAmount: number = 0;
  @State private lightX: number = 0;
  private barScrollAccum: number = 0;
  private barSwitchedByThisGesture: boolean = false;
  private fingerOnPage: boolean = false;

  aboutToAppear(): void {
    if (this.controller !== null) {
      this.controller.notifyScrollDelta = (delta: number) => this.onPageScrollDelta(delta);
      this.controller.notifyTouch = (down: boolean) => this.onPageTouch(down);
    }
  }

  // MARK: - Geometry (two states) 几何（两种状态）

  private dockRowHeight(): number {
    return this.barCollapsed ? CYLGlassDockTokens.ROW_HEIGHT_COLLAPSED : CYLGlassDockTokens.TAB_ROW_HEIGHT_DOUBLE;
  }

  private musicBarRowHeight(): number {
    return this.barCollapsed ? CYLGlassDockTokens.ROW_HEIGHT_COLLAPSED : CYLGlassDockTokens.MUSIC_BAR_HEIGHT_DOUBLE;
  }

  private ballDiameter(): number {
    return this.barCollapsed ? CYLGlassDockTokens.ROW_HEIGHT_COLLAPSED : CYLGlassDockTokens.TAB_ROW_HEIGHT_DOUBLE;
  }

  private ballX(): number {
    const margin = this.barCollapsed ? CYLGlassDockTokens.COLLAPSED_EDGE_MARGIN : CYLGlassDockTokens.BAR_SIDE_MARGIN;
    return this.pageW - margin - this.ballDiameter();
  }

  private musicBarW(): number {
    if (!this.barCollapsed) {
      return this.pageW - 2 * CYLGlassDockTokens.BAR_SIDE_MARGIN;
    }
    return this.pageW - 2 * CYLGlassDockTokens.COLLAPSED_EDGE_MARGIN - 2 * CYLGlassDockTokens.ROW_HEIGHT_COLLAPSED
      - 2 * CYLGlassDockTokens.COLLAPSED_GAP;
  }

  private musicBarX(): number {
    return this.barCollapsed
      ? CYLGlassDockTokens.COLLAPSED_EDGE_MARGIN + CYLGlassDockTokens.ROW_HEIGHT_COLLAPSED + CYLGlassDockTokens.COLLAPSED_GAP
      : CYLGlassDockTokens.BAR_SIDE_MARGIN;
  }

  private musicBarY(): number {
    const bottom = this.barCollapsed ? CYLGlassDockTokens.BAR_BOTTOM_MARGIN : CYLGlassDockTokens.MUSIC_BOTTOM_EXPANDED;
    return this.pageH - bottom - this.musicBarRowHeight();
  }

  private capsuleX(): number {
    return this.barCollapsed ? CYLGlassDockTokens.COLLAPSED_EDGE_MARGIN : CYLGlassDockTokens.BAR_SIDE_MARGIN;
  }

  private capsuleW(): number {
    return this.barCollapsed ? this.dockRowHeight() : this.capsuleExpandedW();
  }

  /** [EN] Page width minus the ball's reserve (63) minus 11 vp at each side (reference). [CN] 页宽减去球的预留（63）再减两侧各 11 vp（参考工程）。 */
  private capsuleExpandedW(): number {
    return this.pageW - CYLGlassDockTokens.TAB_RIGHT_RESERVE - 2 * CYLGlassDockTokens.BAR_SIDE_MARGIN;
  }

  private rowY(): number {
    return this.pageH - CYLGlassDockTokens.BAR_BOTTOM_MARGIN - this.dockRowHeight();
  }

  // MARK: - Collapse / expand 收起 / 展开

  /** [EN] The one entry of the morph (reference setBarCollapsed). [CN] 形变的唯一入口（参考工程 setBarCollapsed）。 */
  setBarCollapsed(collapsed: boolean): void {
    if (this.barCollapsed === collapsed) {
      return;
    }
    this.dockOnlySelected = collapsed;
    this.getUIContext().animateTo({ duration: CYLGlassDockTokens.MORPH_DURATION, curve: Curve.EaseInOut }, () => {
      this.barCollapsed = collapsed;
    });
  }

  private onPageScrollDelta(delta: number): void {
    if (!this.fingerOnPage || this.barSwitchedByThisGesture) {
      return;
    }
    if (this.barCollapsed) {
      if (delta < 0) {
        this.setBarCollapsed(false);
        this.barSwitchedByThisGesture = true;
      }
      return;
    }
    if (delta <= 0) {
      this.barScrollAccum = 0;
      return;
    }
    this.barScrollAccum += delta;
    if (this.barScrollAccum >= CYLGlassDockTokens.MIN_BAR_SCROLL) {
      this.setBarCollapsed(true);
      this.barSwitchedByThisGesture = true;
    }
  }

  private onPageTouch(down: boolean): void {
    this.fingerOnPage = down;
    if (!down) {
      this.barScrollAccum = 0;
      this.barSwitchedByThisGesture = false;
    }
  }

  // MARK: - Press and light 按压与光

  private press(shape: number, event: TouchEvent): void {
    if (event.touches.length > 0) {
      this.lightX = event.touches[0].x;
    }
    if (event.type === TouchType.Down) {
      this.pressedShape = shape;
      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 320, 16) }, () => {
        this.pressAmount = 1;
      });
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 260, 14) }, () => {
        this.pressAmount = 0;
      });
    }
  }

  private pressOf(shape: number): number {
    return this.pressedShape === shape ? this.pressAmount : 0;
  }

  /**
   * [EN] The light of a glass shape, under its content: a specular band along the top edge, a glow along the bottom, a bright
   *      outer rim with a faint dark inner line (convex), and a light spot where the finger is.
   * [CN] 一块玻璃的光，位于其内容之下：上边缘高光带、下边缘反光、明亮的外描边与淡淡的内侧暗线（立体感），以及手指处的光斑。
   */
  @Builder
  glassLight(height: number, shape: number) {
    Stack()
      .width('100%')
      .height('100%')
      .borderRadius(height / 2)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: this.dark
          ? [['#33FFFFFF', 0], ['#0AFFFFFF', 0.35], ['#00FFFFFF', 0.6], ['#14FFFFFF', 1]]
          : [['#80FFFFFF', 0], ['#1AFFFFFF', 0.35], ['#00FFFFFF', 0.6], ['#26FFFFFF', 1]],
      })
      .border({ width: 1, color: this.dark ? '#4DFFFFFF' : '#B3FFFFFF' })
      .outline({ width: 0.5, color: '#26000000', radius: height / 2 })
      .position({ x: 0, y: 0 })
      .hitTestBehavior(HitTestMode.None)
    Stack()
      .width('100%')
      .height('100%')
      .borderRadius(height / 2)
      .radialGradient({
        center: [this.lightX, height * 0.35],
        radius: height * 1.6,
        colors: [['#66FFFFFF', 0], ['#1AFFFFFF', 0.45], ['#00FFFFFF', 1]],
      })
      .opacity(this.pressOf(shape))
      .position({ x: 0, y: 0 })
      .hitTestBehavior(HitTestMode.None)
  }

  // MARK: - Shapes 形状

  private tabColor(index: number): ResourceColor {
    return this.selectedIndex === index ? CYLGlassDockTokens.SELECTED_COLOR : (this.dark ? '#F2F2F7' : '#1C1C1E');
  }

  private tabDx(index: number): number {
    if (!this.barCollapsed || this.selectedIndex !== index) {
      return 0;
    }
    return (this.tabs.length / 2 - index - 0.5) * CYLGlassDockTokens.TAB_SLOT_WIDTH;
  }

  private tabsShift(): number {
    return this.barCollapsed ? CYLGlassDockTokens.ROW_HEIGHT_COLLAPSED / 2 - this.capsuleExpandedW() / 2 : 0;
  }

  @Builder
  tabCapsule() {
    Row() {
      this.glassLight(this.dockRowHeight(), 0)
      Row() {
        ForEach(this.tabs, (item: CYLGlassDockTab, index: number) => {
          Column({ space: CYLGlassDockTokens.TAB_LABEL_GAP }) {
            Image(this.selectedIndex === index ? item.selectedIcon : item.icon)
              .width(CYLGlassDockTokens.TAB_ICON_SIZE)
              .height(CYLGlassDockTokens.TAB_ICON_SIZE)
              .objectFit(ImageFit.Contain)
              .draggable(false)
            Text(item.label)
              .fontSize(CYLGlassDockTokens.TAB_LABEL_SIZE)
              .fontColor(this.tabColor(index))
              .maxLines(1)
              .opacity(this.barCollapsed ? 0 : 1)
          }
          .width(CYLGlassDockTokens.TAB_SLOT_WIDTH)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .translate({ x: this.tabDx(index), y: this.barCollapsed ? CYLGlassDockTokens.COLLAPSED_ICON_DY : 0 })
          .scale(this.barCollapsed ? { x: 21 / 24, y: 21 / 24 } : { x: 1, y: 1 })
          .opacity(this.dockOnlySelected && this.selectedIndex !== index ? 0 : 1)
          .accessibilityGroup(true)
          .accessibilityText(item.label)
          .accessibilityDescription(this.selectedIndex === index ? CYLLocalizedString('选中') : '')
          .id(`cyl-glass-dock-tab-${item.key}`)
          .onClick(() => {
            if (this.barCollapsed) {
              this.setBarCollapsed(false);
              return;
            }
            if (this.selectedIndex !== index) {
              this.onTabChange(index);
            }
          })
        }, (item: CYLGlassDockTab) => item.key)
      }
      .width(this.capsuleExpandedW())
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .position({ x: this.tabsShift(), y: 0 })
    }
    .width(this.capsuleW())
    .height(this.dockRowHeight())
    .attributeModifier(new CYLGlassSurfaceModifier(this.dockRowHeight(), this.dark, this.pressOf(0)))
    .position({ x: this.capsuleX(), y: this.rowY() })
    .onTouch((event: TouchEvent) => this.press(0, event))
    .id('cyl-glass-dock-tabs')
  }

  @Builder
  searchBall() {
    Row() {
      this.glassLight(this.ballDiameter(), 1)
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(this.ballDiameter() / 2)
        .fontColor([this.dark ? '#F2F2F7' : '#1C1C1E'])
    }
    .width(this.ballDiameter())
    .height(this.ballDiameter())
    .justifyContent(FlexAlign.Center)
    .attributeModifier(new CYLGlassSurfaceModifier(this.ballDiameter(), this.dark, this.pressOf(1)))
    .position({ x: this.ballX(), y: this.rowY() })
    .onTouch((event: TouchEvent) => this.press(1, event))
    .accessibilityText(CYLLocalizedString('Search'))
    .id('cyl-glass-dock-search')
    .onClick(() => {
      if (this.barCollapsed) {
        this.setBarCollapsed(false);
        return;
      }
      this.onSearchClick();
    })
  }

  @Builder
  musicBar() {
    Row() {
      this.glassLight(this.musicBarRowHeight(), 2)
      Row({ space: 8 }) {
        Image(this.songCover)
          .width(26)
          .height(26)
          .borderRadius(5)
          .objectFit(ImageFit.Cover)
        Column({ space: 1 }) {
          Text(this.songTitle)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.dark ? '#F2F2F7' : '#1C1C1E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.songArtist)
            .fontSize(10)
            .fontColor(this.dark ? '#B3F2F2F7' : '#B31C1C1E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
          .fontSize(20)
          .fontColor([this.dark ? '#F2F2F7' : '#1C1C1E'])
          .accessibilityText(this.isPlaying ? CYLLocalizedString('Pause') : CYLLocalizedString('Play'))
          .onClick(() => this.onPlayPause())
        SymbolGlyph($r('sys.symbol.forward_end_fill'))
          .fontSize(20)
          .fontColor([this.dark ? '#F2F2F7' : '#1C1C1E'])
          .accessibilityText(CYLLocalizedString('Next track'))
          .onClick(() => this.onNext())
      }
      .width('100%')
      .height('100%')
      .padding({ left: 8, right: 14 })
      .position({ x: 0, y: 0 })
    }
    .width(this.musicBarW())
    .height(this.musicBarRowHeight())
    .attributeModifier(new CYLGlassSurfaceModifier(this.musicBarRowHeight(), this.dark, this.pressOf(2)))
    .position({ x: this.musicBarX(), y: this.musicBarY() })
    .onTouch((event: TouchEvent) => this.press(2, event))
    .id('cyl-glass-dock-music')
  }

  build() {
    Stack() {
      if (this.pageH > 0 && this.tabs.length > 0) {
        this.tabCapsule()
        this.searchBall()
        this.musicBar()
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .onAreaChange((_old: Area, area: Area) => {
      this.pageW = Number(area.width);
      this.pageH = Number(area.height);
    })
  }
}
